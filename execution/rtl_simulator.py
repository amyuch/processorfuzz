from cocotb.decorators import coroutine
from cocotb.triggers import RisingEdge, Timer
from RTLSim.host import SUCCESS, TIME_OUT, ASSERTION_FAIL, ILL_MEM
from common.utils import debug_print

class RTL_Simulator:
    def __init__(self, dut, toplevel, debug=False, max_cycles=6000):
        self.dut = dut  # Device under test (Verilated model)
        self.toplevel = toplevel
        self.debug = debug
        self.max_cycles = max_cycles
        self.coverage = 0  # Track coverage from RTL signals

    @coroutine
    def run_test(self, rtl_input, iteration):
        """Run test on RTL simulator and return result + coverage"""
        debug_print(f"Starting RTL simulation (test {iteration})", self.debug)

        # Initialize memory and signals
        self._load_memory(rtl_input.memory)
        self.dut.reset = 1  # Assert reset
        yield Timer(10, "ns")
        self.dut.reset = 0  # Deassert reset

        # Run simulation
        cycle = 0
        timeout = False
        while cycle < self.max_cycles:
            yield RisingEdge(self.dut.clock)
            cycle += 1

            # Check for end-of-simulation signal
            if self.dut.eos.value == 1:
                break
            if cycle == self.max_cycles - 1:
                timeout = True

        # Collect coverage (simplified: count unique CSR accesses)
        self.coverage = self._collect_coverage()

        # Determine result
        if timeout:
            return (TIME_OUT, self.coverage)
        if self._check_assertions():
            return (ASSERTION_FAIL, self.coverage)
        if not self._check_memory_access():
            return (ILL_MEM, self.coverage)
        return (SUCCESS, self.coverage)

    def _load_memory(self, memory):
        """Load test data into RTL memory"""
        for addr, value in memory.items():
            self.dut.memory[addr] = value  # Assume memory is a Verilated array

    def _collect_coverage(self):
        """Extract coverage from RTL (e.g., CSR access bits)"""
        # In real implementation, read coverage registers/instrumented signals
        return sum(self.dut.coverage_signals.value)  # Simplified example

    def _check_assertions(self):
        """Check for RTL assertion failures"""
        return self.dut.assertion_failed.value == 1

    def _check_memory_access(self):
        """Verify all accesses are within DRAM"""
        return self.dut.illegal_memory_access.value == 0