from cocotb.decorators import coroutine
from cocotb.triggers import RisingEdge, Timer
from cocotb import fork
from common.utils import debug_print
from src.reader.tile_reader import tileSrcReader
from src.adapters.tile_adapter import tileAdapter

# Constants from original RTLSim.host
SUCCESS = 0
ASSERTION_FAIL = 1
TIME_OUT = 2
ILL_MEM = -1
DRAM_BASE = 0x80000000

class RTL_Simulator:
    def __init__(self, dut, toplevel, debug=False, max_cycles=6000, rtl_sig_file=None):
        self.dut = dut
        self.toplevel = toplevel
        self.debug = debug
        self.max_cycles = max_cycles
        self.rtl_sig_file = rtl_sig_file
        self.coverage = 0

        # Initialize TileLink adapter (from rvRTLhost)
        source_info = f'infos/{toplevel}_info.txt'
        reader = tileSrcReader(source_info)
        paths = reader.return_map()
        port_names = paths['port_names']
        monitor = (paths['monitor_pc'][0], paths['monitor_valid'][0])
        self.adapter = tileAdapter(dut, port_names, monitor, debug)

    @coroutine
    def run_test(self, rtl_input, iteration, assert_intr=False):
        """Merged from rvRTLhost.run_test and original RTL_Simulator.run_test"""
        debug_print(f"[RTL_Simulator] Starting simulation (test {iteration})", self.debug)

        # Load bootrom and test memory (from rvRTLhost)
        bootrom_addrs, memory = self._set_bootrom()
        self._load_test_memory(memory, rtl_input)

        # Clock generation (from rvRTLhost)
        clk = self.dut.clock
        clk_driver = fork(self._clock_gen(clk))
        yield self._reset(clk, self.dut.metaReset, self.dut.reset)

        # Initialize simulation signals
        self.dut.eos = 0
        self.dut.iteration = iteration

        # Handle interrupts (from rvRTLhost)
        ints = self._parse_interrupts(rtl_input.intrfile) if assert_intr else {}
        self.adapter.start(memory, ints)

        # Run simulation loop (merged logic)
        clkedge = RisingEdge(clk)
        tohost_addr = rtl_input.symbols['tohost']
        timeout = False

        for cycle in range(self.max_cycles):
            yield clkedge

            # Check for end-of-simulation (from rvRTLhost)
            if self.dut.eos.value == 1:
                break
            if cycle % 100 == 0:
                self.adapter.probe_tohost(tohost_addr)
            if cycle == self.max_cycles - 1:
                timeout = True

        # Cleanup (from rvRTLhost)
        self.dut.eos = 1
        yield self.adapter.stop()
        clk_driver.kill()

        # Collect coverage and results (merged)
        self.coverage = self._get_covsum()
        mem_check = self._check_memory_access(memory, bootrom_addrs)

        if not mem_check:
            return (ILL_MEM, self.coverage)
        if timeout:
            return (TIME_OUT, self.coverage)
        if self.adapter.check_assert():
            return (ASSERTION_FAIL, self.coverage)

        # Save signature (from rvRTLhost)
        self._save_signature(
            memory,
            rtl_input.symbols['begin_signature'],
            rtl_input.symbols['end_signature'],
            self._get_data_sections(rtl_input.symbols)
        )
        return (SUCCESS, self.coverage)

    # Helper methods from rvRTLhost
    def _set_bootrom(self):
        bootrom = [
            0x00000297, 0x02028593, 0xf1402573, 0x0182b283,
            0x00028067, 0x00000000, 0x80000000, 0x00000000,
            0x00000000, 0x00000000, 0x00000000, 0x00000000,
            0x00000000, 0x00000000, 0x00000000, 0x00000000
        ]
        memory = {}
        bootrom_addrs = []
        for i in range(0, len(bootrom), 2):
            addr = 0x10000 + i * 4
            bootrom_addrs.append(addr)
            memory[addr] = (bootrom[i+1] << 32) | bootrom[i]
        return (bootrom_addrs, memory)

    def _load_test_memory(self, memory, rtl_input):
        with open(rtl_input.hexfile, 'r') as f:
            lines = f.readlines()
        symbols = rtl_input.symbols
        for i, addr in enumerate(range(symbols['_start'], symbols['_end_main'] + 36, 8)):
            memory[addr] = int(lines[i], 16)
        # Load data sections
        offset = 0
        for n in range(6):
            start = symbols[f'_random_data{n}']
            end = symbols[f'_end_data{n}']
            for i, addr in enumerate(range(start // 8 * 8, end // 8 * 8, 8)):
                memory[addr] = rtl_input.data[i + offset]
            offset += (end - start) // 8

    @coroutine
    def _clock_gen(self, clock, period=2):
        while True:
            clock <= 1
            yield Timer(period / 2, "ns")
            clock <= 0
            yield Timer(period / 2, "ns")

    @coroutine
    def _reset(self, clock, metaReset, reset, timer=5):
        clkedge = RisingEdge(clock)
        metaReset <= 1
        for _ in range(timer):
            yield clkedge
        metaReset <= 0
        reset <= 1
        for _ in range(timer):
            yield clkedge
        reset <= 0

    def _parse_interrupts(self, intrfile):
        ints = {}
        with open(intrfile, 'r') as f:
            for line in f:
                addr, val = line.split(':')
                ints[int(addr, 16)] = int(val, 2)
        return ints

    def _check_memory_access(self, memory, bootrom_addrs):
        for addr in memory:
            if addr not in bootrom_addrs and addr < DRAM_BASE:
                return False
        return True

    def _get_data_sections(self, symbols):
        return [
            (symbols[f'_random_data{n}'], symbols[f'_end_data{n}'])
            for n in range(6)
        ]

    def _save_signature(self, memory, sig_start, sig_end, data_addrs):
        if not self.rtl_sig_file:
            return
        with open(self.rtl_sig_file, 'w') as f:
            # Main signature
            for addr in range(sig_start, sig_end, 16):
                f.write(f"{memory[addr+8]:016x}{memory[addr]:016x}\n")
            # Data sections
            for start, end in data_addrs:
                for addr in range(start, end, 16):
                    f.write(f"{memory[addr+8]:016x}{memory[addr]:016x}\n")

    def _get_covsum(self):
        cov_mask = (1 << len(self.dut.io_covSum)) - 1
        return self.dut.io_covSum.value & cov_mask