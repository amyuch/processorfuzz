import os
import subprocess
import random
from shutil import copyfile
from mutation.mutator import simInput, templates, V_U  # Supplement V_U constant definition
# from common.utils import debug_print

class rvPreProcessor():
    def __init__(self, cc, elf2hex, template='Template', out_base='.', proc_num=0):
        self.cc = cc
        self.elf2hex = elf2hex
        self.template = template
        self.base = out_base
        self.proc_num = proc_num
        self.er_num = 0
        self.cc_args = [
            cc, '-march=rv64g', '-mabi=lp64', '-static', '-mcmodel=medany',
            '-fvisibility=hidden', '-nostdlib', '-nostartfiles',
            '-I', os.path.join(template, 'include'),  # Use os.path.join to optimize path
            '-T', os.path.join(template, 'include', 'link.ld')
        ]

        self.elf2hex_args = [elf2hex, '--bit-width', '64', '--input']

    def debug_print(self, message):
        if self.debug:
            print(message)

    def get_symbols(self, elf_name, sym_name):
        """Extract symbol table from ELF file"""
        with open(sym_name, 'w') as fd:
            subprocess.call(['nm', elf_name], stdout=fd)
        
        symbols = {}
        with open(sym_name, 'r') as fd:
            for line in fd.readlines():
                parts = line.split()
                if len(parts) >= 3:
                    addr = parts[0]
                    symbol = parts[2].rstrip()  # Remove trailing newline
                    symbols[symbol] = int(addr, 16)
        return symbols

    def write_isa_intr(self, isa_input, rtl_input, epc):
        """Generate interrupt file for ISA simulator"""
        with open(rtl_input.intrfile, 'r') as fd:
            tuples = [line.split(':') for line in fd.readlines()]
        
        # TODO, assert interrupt multiple time
        assert len(tuples) == 1, 'Interrupt must be asserted only once'
        val = int(tuples[0][1], 2)
        
        with open(isa_input.intrfile, 'w') as fd:
            fd.write(f'{epc:016x}:{val:04b}\n')

    # def write_isa_intr(self, isa_input, rtl_input, pc_list):
    #     """
    #     Translate the RTL interrupt file into an ISA interrupt file.

    #     pc_list : iterable with the exact PC values that must receive
    #             an interrupt (one entry per interrupt declared in the
    #             RTL file).
    #     """
    #     with open(rtl_input.intrfile) as fin:
    #         tuples = [ln.strip().split(':') for ln in fin if ln.strip()]

    #     if not tuples:                      # nothing to do
    #         open(isa_input.intrfile, 'w').close()
    #         return

    #     codes = [int(tp[1], 2) for tp in tuples]

    #     if len(codes) != len(pc_list):
    #         raise ValueError(
    #             f'RTL file contains {len(codes)} interrupts, '
    #             f'but {len(pc_list)} PCs were supplied'
    #         )

    #     with open(isa_input.intrfile, 'w') as fout:
    #         for pc, code in zip(pc_list, codes):
    #             fout.write(f'{pc:016x}:{code:04b}\n')

    def process(self, sim_input: simInput, data: list, intr: bool, it, run_elf, num_data_sections=6):
        """Process input to generate test files, return inputs for ISA and RTL simulators"""
        section_size = len(data) // num_data_sections

        # Input validity check
        assert data, 'Empty data cannot be processed'
        assert (section_size & (section_size - 1)) == 0, \
            'Number of memory blocks should be power of 2'

        # Get template version and build test template path
        version = sim_input.get_template()
        test_template = os.path.join(self.template, f'rv64-{templates[version]}.S')

        # Build compile arguments (including interrupt and version related configurations)
        if intr:
            DINTR = ['-DINTERRUPT']
        else:
            DINTR = []
        extra_args = DINTR + ['-I', os.path.join(self.template, 'include', 'p')]

        # V_U version special configuration
        if version in [V_U]:
            rand = data[0] & 0xffffffff
            extra_args = DINTR + [
                f'-DENTROPY=0x{rand:08x}', '-std=gnu99', '-O2',
                '-I', os.path.join(self.template, 'include', 'v'),
                os.path.join(self.template, 'include', 'v', 'string.c'),
                os.path.join(self.template, 'include', 'v', 'vm.c')
            ]

        # Generate output file paths (use os.path.join to ensure cross-platform compatibility)
        test_dir = os.path.join(self.base, 'tests')
        os.makedirs(test_dir, exist_ok=True)  # Ensure directory exists

        si_name = os.path.join(test_dir, f'.input_{it}{sim_input.name_suffix}.si')
        asm_name = os.path.join(test_dir, f'.input_{it}{sim_input.name_suffix}.S')
        elf_name = os.path.join(test_dir, f'.input_{it}{sim_input.name_suffix}.elf')
        hex_name = os.path.join(test_dir, f'.input_{it}{sim_input.name_suffix}.hex')
        sym_name = os.path.join(test_dir, f'.input_{it}{sim_input.name_suffix}.symbols')
        rtl_intr_name = os.path.join(test_dir, f'.input_{it}{sim_input.name_suffix}.rtl.intr')
        isa_intr_name = os.path.join(test_dir, f'.input_{it}{sim_input.name_suffix}.isa.intr')

        # Extract instructions and interrupt information from simulation input
        prefix_insts = sim_input.get_prefix()
        insts = sim_input.get_insts()
        suffix_insts = sim_input.get_suffix()
        sim_input_ints = sim_input.ints.copy()

        ints = []
        for inst in insts[:-1]:
            INT = sim_input_ints.pop(0)
            if 'la' in inst:
                ints.append(INT)
                ints.append(0)
            else:
                ints.append(INT)

        # Save simulation input
        sim_input.save(si_name, data)

        # Generate assembly file
        with open(test_template, 'r') as fd:
            template_lines = fd.readlines()

        assembly = []
        for line in template_lines:
            assembly.append(line)
            # Insert prefix instructions
            if '_fuzz_prefix:' in line:
                for inst in prefix_insts:
                    assembly.append(f'{inst};\n')
            # Insert main instructions
            if '_fuzz_main:' in line:
                for inst in insts:
                    assembly.append(f'{inst};\n')
            # Insert suffix instructions (including randomized illegal patterns)
            if '_fuzz_suffix:' in line:
                for inst in suffix_insts:
                    a = random.randint(0, 7)
                    # Randomly insert fnmadd.s instruction with illegal frm field
                    if "fnmadd.s" in inst and a == 6:
                        assembly.append(".word 0xa106e5cf;\n")
                    assembly.append(f'{inst};\n')
            # Insert data sections
            for n in range(num_data_sections):
                start = n * section_size
                end = start + section_size
                if f'_random_data{n}' in line:
                    k = 0
                    for i in range(start, end, 2):
                        label = ''
                        if i > start + 2 and i < end - 4:
                            label = f'd_{n}_{k}:'
                            k += 1
                        assembly.append(
                            f'{label:<16}.dword 0x{data[i]:016x}, 0x{data[i+1]:016x}\n'
                        )

        with open(asm_name, 'w') as fd:
            fd.writelines(assembly)

        # Compile to generate ELF file
        cc_args = self.cc_args + extra_args + [asm_name, '-o', elf_name]
        cc_ret = -1

        if run_elf:
            # Directly copy existing ELF file
            copyfile(run_elf, elf_name)
            cc_ret = 0
        else:
            # Compile until success or non out-of-memory error
            while True:
                cc_ret = subprocess.call(cc_args)
                if cc_ret != -9:  # -9 indicates OS terminated process due to out of memory
                    break

        # If compilation succeeds, generate subsequent files
        if cc_ret == 0:
            # Generate hex image
            elf2hex_args = self.elf2hex_args + [elf_name, '--output', hex_name]
            subprocess.call(elf2hex_args)
            # Extract symbol table
            symbols = self.get_symbols(elf_name, sym_name)

            # Generate interrupt file (if needed)
            if intr:
                fuzz_main = symbols['_fuzz_main']
                with open(rtl_intr_name, 'w') as fd:
                    for i, INT in enumerate(ints):
                        if INT:
                            fd.write(f'{fuzz_main + 4 * i:016x}:{INT:04b}\n')

            # Determine maximum cycle count (V_U version needs longer cycles)
            max_cycles = 6000
            if version in [V_U]:
                max_cycles = 200000

            # Instantiate simulator input objects
            from execution.isa_simulator import isaInput
            from execution.rtl_simulator import rtlInput
            isa_input = isaInput(elf_name, isa_intr_name)
            rtl_input = rtlInput(hex_name, rtl_intr_name, data, symbols, max_cycles)
        else:
            isa_input = None
            rtl_input = None
            symbols = None

        return (isa_input, rtl_input, symbols)