#!/usr/bin/env python3
"""
ProcessorFuzz 独立测试用例处理脚本
功能：生成初始测试用例 -> 变异测试用例 -> 预处理生成.S和.hex -> 验证基本格式有效性
"""

import os
import logging
import sys
import subprocess
from datetime import datetime
from copy import deepcopy
from mutation.mutator import rvMutator, simInput
from mutation.inst_generator import rvInstGenerator, PREFIX, MAIN, SUFFIX
from execution.preprocessor import rvPreProcessor  # 导入预处理类

# 模板版本映射（与preprocessor.py保持一致）
templates = ['p-m', 'p-s', 'p-u', 'v-u']
V_U = 3  # 对应v-u模板

# 简化日志设置
def setup_logging(debug):
    level = logging.DEBUG if debug else logging.INFO
    logging.basicConfig(
        format="%(asctime)s %(levelname)-8s %(message)s",
        level=level,
        datefmt="%a, %d %b %Y %H:%M:%S"
    )

# 简化输出目录创建
def create_output(prefix="mutation_output_"):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_dir = f"{prefix}{timestamp}"
    os.makedirs(output_dir, exist_ok=True)
    os.makedirs(os.path.join(output_dir, "tests"), exist_ok=True)  # 预处理输出目录
    return output_dir

class TestCaseProcessor:
    def __init__(self, output_dir=None, debug=False, cc="riscv64-unknown-elf-gcc", elf2hex="elf2hex", template_dir="./Template"):
        setup_logging(debug)
        self.debug = debug
        self.output_dir = output_dir or create_output()
        self.template_dir = template_dir
        self.cc = cc
        self.elf2hex = elf2hex
        
        # 初始化变异器、指令生成器和预处理器
        self.mutator = rvMutator(
            max_data_seeds=20,
            corpus_size=100,
            no_guide=False
        )
        self.inst_generator = rvInstGenerator(isa='RV64G')
        self.preprocessor = rvPreProcessor(
            cc=cc,
            elf2hex=elf2hex,
            template=template_dir,
            out_base=self.output_dir,
            proc_num=0
        )

    def generate_initial_test(self, test_name="initial_test", template_version=0):
        logging.info("开始生成初始测试用例...")
        
        # 生成前缀、主序列、后缀的 Word 实例
        prefix_words = [self.inst_generator.get_word(PREFIX) for _ in range(5)]
        main_words = [self.inst_generator.get_word(MAIN) for _ in range(15)]
        suffix_words = [self.inst_generator.get_word(SUFFIX) for _ in range(3)]
        
        # 计算最大标签值
        max_prefix_label = len(prefix_words) - 1 if prefix_words else 0
        max_main_label = len(main_words) - 1 if main_words else 0
        max_suffix_label = len(suffix_words) - 1 if suffix_words else 0
        
        # 填充所有 Word 实例
        for word in prefix_words:
            self.inst_generator.populate_word(word, max_prefix_label, PREFIX)
        for word in main_words:
            self.inst_generator.populate_word(word, max_main_label, MAIN)
        for word in suffix_words:
            self.inst_generator.populate_word(word, max_suffix_label, SUFFIX)
        
        # 添加随机数据种子
        data_seed = self.mutator.add_data()
        
        # 生成 simInput 实例
        sim_input = simInput(
            prefix=prefix_words,
            words=main_words,
            suffix=suffix_words,
            ints=[0] * sum(word.len_insts for word in main_words),
            data_seed=data_seed,
            template=template_version
        )
        
        # 保存测试用例
        output_path = os.path.join(self.output_dir, f"{test_name}.si")
        sim_input.save(output_path, data=self.mutator.random_data[data_seed])
        logging.info(f"初始测试用例已保存至: {output_path}")
        return output_path, sim_input, data_seed

    def mutate_test_case(self, input_path, mutate_name="mutated_test", mutate_count=3):
        if not os.path.exists(input_path):
            logging.error(f"输入测试用例不存在: {input_path}")
            return None

        logging.info(f"开始对测试用例进行{mutate_count}次变异...")
        mutated_results = []  # 存储(路径, sim_input, data_seed)
        
        for i in range(mutate_count):
            # 读取原始测试用例
            sim_input, data, _ = self.mutator.read_siminput(input_path)
            data_seed = sim_input.get_seed()
            
            # 执行变异操作
            mutated_main = self.mutator.mutate_words(
                seed_words=sim_input.words,
                part=MAIN,
                max_num=20
            )
            sim_input.words = mutated_main
            sim_input.num_words = len(mutated_main)
            
            # 保存变异结果
            output_path = os.path.join(
                self.output_dir,
                f"{mutate_name}_{i+1}.si"
            )
            sim_input.save(output_path, data=data)
            mutated_results.append((output_path, sim_input, data_seed))
            logging.debug(f"变异测试用例 {i+1} 已保存至: {output_path}")
        
        logging.info(f"完成{mutate_count}次变异")
        return mutated_results

    def preprocess_test_case(self, sim_input, data_seed, it=0):
        """调用预处理生成.S和.hex文件"""
        data = self.mutator.random_data.get(data_seed, [])
        if not data:
            logging.error("缺少测试数据，预处理失败")
            return None, None
        
        # 检查是否需要中断配置
        has_intr = any(INT != 0 for INT in sim_input.ints)
        
        try:
            # 调用预处理方法生成文件
            isa_input, rtl_input, symbols = self.preprocessor.process(
                sim_input=sim_input,
                data=data,
                intr=has_intr,
                it=it,
                run_elf=None
            )
            
            if not isa_input or not rtl_input:
                logging.warning("预处理未生成有效输出")
                return None, None
            
            asm_path = os.path.join(
                self.output_dir, "tests", 
                f".input_{it}{sim_input.name_suffix}.S"
            )
            hex_path = os.path.join(
                self.output_dir, "tests", 
                f".input_{it}{sim_input.name_suffix}.hex"
            )
            
            # 验证文件生成
            if os.path.exists(asm_path) and os.path.exists(hex_path):
                logging.info(f"预处理成功: {asm_path} 和 {hex_path}")
                return asm_path, hex_path
            else:
                logging.error("预处理文件生成失败")
                return None, None
                
        except Exception as e:
            logging.error(f"预处理过程出错: {str(e)}")
            return None, None

    def validate_test_case(self, test_path, asm_path=None, hex_path=None):
        """验证测试用例及预处理文件有效性"""
        # 验证原始测试用例
        if not os.path.exists(test_path):
            logging.error(f"验证失败：测试用例不存在 {test_path}")
            return False

        try:
            sim_input, data, _ = self.mutator.read_siminput(test_path)
            asm_code = "\n".join(sim_input.get_insts())
            valid_instructions = ["add", "sub", "lw", "sw", "jal", "beq", "addi"]
            has_valid = any(inst in asm_code for inst in valid_instructions)
            
            if not has_valid:
                logging.warning(f"测试用例可能无效（未找到常见指令）: {test_path}")
                return False
        except Exception as e:
            logging.error(f"测试用例验证失败: {str(e)}")
            return False

        # 验证预处理文件
        if asm_path and os.path.exists(asm_path):
            with open(asm_path, "r") as f:
                asm_content = f.read()
                if "_fuzz_main:" not in asm_content:
                    logging.warning(f"汇编文件缺少主函数标记: {asm_path}")
                    return False
        elif asm_path:
            logging.warning(f"汇编文件不存在: {asm_path}")
            return False

        if hex_path and os.path.exists(hex_path):
            with open(hex_path, "r") as f:
                hex_content = f.read()
                if not hex_content.strip():
                    logging.warning(f"HEX文件内容为空: {hex_path}")
                    return False
        elif hex_path:
            logging.warning(f"HEX文件不存在: {hex_path}")
            return False

        logging.info(f"测试用例及预处理文件验证通过: {test_path}")
        return True

    def run(self, initial_name="initial", mutate_count=3, template_version=0):
        """执行完整流程：生成 -> 变异 -> 预处理 -> 验证"""
        try:
            # 1. 生成初始测试用例
            initial_path, initial_sim, initial_seed = self.generate_initial_test(
                initial_name, template_version
            )
            if not initial_path:
                raise Exception("生成初始测试用例失败")
            
            # 2. 预处理初始测试用例
            initial_asm, initial_hex = self.preprocess_test_case(
                initial_sim, initial_seed, it=0
            )

            # 3. 变异测试用例
            mutated_results = self.mutate_test_case(initial_path, mutate_count=mutate_count)
            if not mutated_results:
                raise Exception("变异过程失败")
            
            # 4. 预处理所有变异用例
            mutated_asm_hex = []
            for i, (mut_path, mut_sim, mut_seed) in enumerate(mutated_results, 1):
                asm, hex_file = self.preprocess_test_case(mut_sim, mut_seed, it=i)
                mutated_asm_hex.append((asm, hex_file))

            # 5. 验证所有测试用例
            all_valid = True
            # 验证初始用例
            if not self.validate_test_case(initial_path, initial_asm, initial_hex):
                all_valid = False
            # 验证变异用例
            for (mut_path, _, _), (asm, hex_file) in zip(mutated_results, mutated_asm_hex):
                if not self.validate_test_case(mut_path, asm, hex_file):
                    all_valid = False
            
            if all_valid:
                logging.info("所有测试用例处理完成且验证通过")
                return 0
            else:
                logging.warning("部分测试用例验证未通过")
                return 1
        except Exception as e:
            logging.error(f"流程执行失败: {str(e)}")
            return 2

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="ProcessorFuzz测试用例处理工具")
    parser.add_argument("--output", help="指定输出目录")
    parser.add_argument("--debug", action="store_true", help="启用调试日志")
    parser.add_argument("--mutate-count", type=int, default=3, help="变异次数")
    parser.add_argument("--template", type=int, default=0, 
                      help=f"模板版本 (0: p-m, 1: p-s, 2: p-u, 3: v-u)")
    parser.add_argument("--cc", default="riscv64-unknown-elf-gcc", help="RISC-V编译器路径")
    parser.add_argument("--elf2hex", default="elf2hex", help="elf2hex工具路径")
    parser.add_argument("--template-dir", default="./Template", help="模板文件目录")
    args = parser.parse_args()

    processor = TestCaseProcessor(
        output_dir=args.output,
        debug=args.debug,
        cc=args.cc,
        elf2hex=args.elf2hex,
        template_dir=args.template_dir
    )
    sys.exit(processor.run(
        mutate_count=args.mutate_count,
        template_version=args.template
    ))