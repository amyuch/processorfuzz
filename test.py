#!/usr/bin/env python3
"""
ProcessorFuzz 独立测试用例处理脚本
功能：生成初始测试用例 -> 变异测试用例 -> 验证基本格式有效性
"""

import os
import logging
import sys
from datetime import datetime
from mutation.mutator import rvMutator, simInput  # 关键：导入 simInput 类
from mutation.inst_generator import rvInstGenerator, PREFIX, MAIN, SUFFIX  # 导入必要的常量

# 简化日志设置（避免依赖 scripts.lib）
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
    return output_dir

class TestCaseProcessor:
    def __init__(self, output_dir=None, debug=False):
        setup_logging(debug)
        self.debug = debug
        self.output_dir = output_dir or create_output()
        # 初始化变异器和指令生成器
        self.mutator = rvMutator(
            max_data_seeds=20,
            corpus_size=100,
            no_guide=False
        )
        self.inst_generator = rvInstGenerator(isa='RV64G')

    def generate_initial_test(self, test_name="initial_test"):
        logging.info("开始生成初始测试用例...")
        
        # 生成前缀、主序列、后缀的 Word 实例
        prefix_words = [self.inst_generator.get_word(PREFIX) for _ in range(5)]
        main_words = [self.inst_generator.get_word(MAIN) for _ in range(15)]
        suffix_words = [self.inst_generator.get_word(SUFFIX) for _ in range(3)]
        
        # 计算最大标签值（用于合法跳转目标生成）
        max_prefix_label = len(prefix_words) - 1 if prefix_words else 0
        max_main_label = len(main_words) - 1 if main_words else 0
        max_suffix_label = len(suffix_words) - 1 if suffix_words else 0
        
        # 关键修改：填充所有 Word 实例（替换占位符并标记为 populated）
        for word in prefix_words:
            self.inst_generator.populate_word(word, max_prefix_label, PREFIX)
        for word in main_words:
            self.inst_generator.populate_word(word, max_main_label, MAIN)
        for word in suffix_words:
            self.inst_generator.populate_word(word, max_suffix_label, SUFFIX)
        
        # 添加随机数据种子
        data_seed = self.mutator.add_data()
        
        # 生成 simInput 实例（使用填充后的 Word 列表）
        sim_input = simInput(
            prefix=prefix_words,
            words=main_words,
            suffix=suffix_words,
            ints=[0] * sum(word.len_insts for word in main_words),  # 按实际指令长度生成中断标记
            data_seed=data_seed,
            template=0
        )
        
        # 保存测试用例
        output_path = os.path.join(self.output_dir, f"{test_name}.si")
        sim_input.save(output_path, data=self.mutator.random_data[data_seed])
        logging.info(f"初始测试用例已保存至: {output_path}")
        return output_path

    def mutate_test_case(self, input_path, mutate_name="mutated_test", mutate_count=3):
        """对现有测试用例进行多次变异（修正 simInput 处理）"""
        if not os.path.exists(input_path):
            logging.error(f"输入测试用例不存在: {input_path}")
            return None

        logging.info(f"开始对测试用例进行{mutate_count}次变异...")
        mutated_paths = []
        
        for i in range(mutate_count):
            # 读取原始测试用例
            sim_input, data, _ = self.mutator.read_siminput(input_path)
            
            # 执行变异操作（随机替换/添加指令）
            mutated_main = self.mutator.mutate_words(
                seed_words=sim_input.words,
                part=MAIN,  # 使用常量 MAIN
                max_num=20  # 变异后最多保留20条指令
            )
            sim_input.words = mutated_main
            sim_input.num_words = len(mutated_main)
            
            # 保存变异结果
            output_path = os.path.join(
                self.output_dir,
                f"{mutate_name}_{i+1}.si"
            )
            sim_input.save(output_path, data=data)
            mutated_paths.append(output_path)
            logging.debug(f"变异测试用例 {i+1} 已保存至: {output_path}")
        
        logging.info(f"完成{mutate_count}次变异，结果路径: {mutated_paths}")
        return mutated_paths

    def validate_test_case(self, test_path):
        """验证测试用例格式有效性"""
        if not os.path.exists(test_path):
            logging.error(f"验证失败：测试用例不存在 {test_path}")
            return False

        logging.info(f"验证测试用例格式: {test_path}")
        try:
            # 读取测试用例
            sim_input, data, _ = self.mutator.read_siminput(test_path)
            # 生成汇编指令文本
            asm_code = "\n".join(sim_input.get_insts())
            
            # 保存汇编代码用于检查
            asm_path = os.path.splitext(test_path)[0] + ".S"
            with open(asm_path, "w") as f:
                f.write(asm_code)
            
            # 简单验证：检查是否包含有效指令
            valid_instructions = ["add", "sub", "lw", "sw", "jal", "beq", "addi"]
            has_valid = any(inst in asm_code for inst in valid_instructions)
            
            if has_valid:
                logging.info(f"测试用例格式验证通过: {test_path}")
                return True
            else:
                logging.warning(f"测试用例可能无效（未找到常见指令）: {test_path}")
                return False
        except Exception as e:
            logging.error(f"验证失败: {str(e)}")
            return False

    def run(self, initial_name="initial", mutate_count=3):
        """执行完整流程：生成 -> 变异 -> 验证"""
        try:
            # 1. 生成初始测试用例
            initial_path = self.generate_initial_test(initial_name)
            if not initial_path:
                raise Exception("生成初始测试用例失败")
            
            # 2. 变异测试用例
            mutated_paths = self.mutate_test_case(initial_path, mutate_count=mutate_count)
            if not mutated_paths:
                raise Exception("变异过程失败")
            
            # 3. 验证所有测试用例
            all_valid = True
            for path in [initial_path] + mutated_paths:
                if not self.validate_test_case(path):
                    all_valid = False
            
            if all_valid:
                logging.info("所有测试用例处理完成且验证通过")
                return 0  # 成功返回码
            else:
                logging.warning("部分测试用例验证未通过")
                return 1  # 警告返回码
        except Exception as e:
            logging.error(f"流程执行失败: {str(e)}")
            return 2  # 错误返回码

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="ProcessorFuzz测试用例处理工具")
    parser.add_argument("--output", help="指定输出目录")
    parser.add_argument("--debug", action="store_true", help="启用调试日志")
    parser.add_argument("--mutate-count", type=int, default=3, help="变异次数")
    args = parser.parse_args()

    processor = TestCaseProcessor(
        output_dir=args.output,
        debug=args.debug
    )
    sys.exit(processor.run(mutate_count=args.mutate_count))