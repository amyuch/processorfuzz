import os
import subprocess
from common.utils import debug_print
from common.constants import SUCCESS, TIME_OUT

class ISA_Simulator:
    def __init__(self, debug=False, spike_path="spike"):
        self.debug = debug
        self.spike_path = spike_path  # Path to Spike ISA simulator

    def run_test(self, isa_input, out_dir, it, assert_intr=False):
        """Run test on Spike and generate trace log"""
        isa_log = f"{out_dir}/trace/isa_{it}.log"
        debug_print(f"Running ISA test {it} -> {isa_log}", self.debug)

        # Command to run Spike with trace generation
        cmd = [
            self.spike_path,
            "--log", isa_log,
            "--isa=rv64g",  # RISC-V ISA configuration
            isa_input.elf_path  # Path to compiled ELF
        ]

        # Execute Spike
        try:
            result = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                timeout=30  # Prevent hanging
            )
        except subprocess.TimeoutExpired:
            debug_print(f"ISA simulation timed out (test {it})", self.debug)
            return (TIME_OUT, None)

        # Check for errors
        if result.returncode != 0:
            debug_print(
                f"ISA simulation failed (test {it}): {result.stderr.decode()}",
                self.debug
            )
            return (result.returncode, None)

        # Process log into CSV (from spike_log_to_trace_csv)
        isa_csv = f"{out_dir}/trace/isa_{it}.csv"
        self._log_to_csv(isa_log, isa_csv)
        return (SUCCESS, isa_csv)

    def _log_to_csv(self, log_path, csv_path):
        """Convert Spike log to CSV trace (simplified version)"""
        with open(log_path, "r") as log_fd, open(csv_path, "w") as csv_fd:
            csv_fd.write("pc,inst,rd,rd_val\n")  # CSV header
            for line in log_fd:
                if "core   0: 0x" in line:  # Extract instruction entries
                    parts = line.strip().split()
                    pc = parts[2]
                    inst = parts[3]
                    rd = parts[5] if len(parts) > 5 else "x0"
                    rd_val = parts[7] if len(parts) > 7 else "0"
                    csv_fd.write(f"{pc},{inst},{rd},{rd_val}\n")