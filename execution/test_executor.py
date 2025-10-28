from cocotb.decorators import coroutine
from .isa_simulator import ISA_Simulator
from .rtl_simulator import RTL_Simulator
from .trace_comparison import trace_compare
from common.constants import SUCCESS

class TestExecutor:
    def __init__(self, dut, toplevel, out_dir, debug=False):
        self.dut = dut
        self.toplevel = toplevel
        self.out_dir = out_dir
        self.debug = debug
        self.isa_sim = ISA_Simulator(debug=debug)
        self.rtl_sim = RTL_Simulator(dut, toplevel, debug=debug)

    @coroutine
    def execute(self, sim_input, data, it, assert_intr=False):
        """Execute test on ISA and RTL simulators, return mismatch + coverage"""
        # 1. Run ISA simulation
        isa_result, isa_csv = self.isa_sim.run_test(
            sim_input.isa_input, self.out_dir, it, assert_intr
        )
        if isa_result != SUCCESS:
            return (False, 0)  # ISA failed; skip RTL

        # 2. Run RTL simulation
        rtl_result, coverage = yield self.rtl_sim.run_test(
            sim_input.rtl_input, it
        )
        if rtl_result != SUCCESS:
            return (False, coverage)  # RTL failed; no mismatch

        # 3. Compare traces
        rtl_log = f"{self.out_dir}/trace/rtl_{it}.log"
        mismatch = trace_compare(isa_csv, rtl_log, self.toplevel)
        return (mismatch == -1, coverage)  # True if mismatch