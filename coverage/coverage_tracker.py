import os
import json
from common.utils import save_file

class CoverageTracker:
    def __init__(self, out_dir, multicore=False):
        self.out_dir = out_dir
        self.multicore = multicore
        self.coverage_db = {}  # { "csr_0x123": True, ... }

    def update_from_rtl(self, rtl_coverage):
        """Merge new coverage data from RTL simulation"""
        for addr, accessed in rtl_coverage.items():
            if accessed:
                self.coverage_db[addr] = True

    def aggregate_multicore(self, proc_num):
        """Aggregate coverage from parallel workers"""
        if not self.multicore:
            return

        # Load worker's coverage data
        worker_cov_path = f"{self.out_dir}/covmap-{proc_num}/coverage.json"
        if not os.path.exists(worker_cov_path):
            return

        with open(worker_cov_path, "r") as f:
            worker_cov = json.load(f)

        # Merge into global DB
        self.update_from_rtl(worker_cov)

        # Save merged data
        global_cov_path = f"{self.out_dir}/coverage/global_coverage.json"
        with open(global_cov_path, "w") as f:
            json.dump(self.coverage_db, f)

    def get_coverage_score(self):
        """Calculate coverage score (percentage of unique addresses)"""
        total_tracked = len(self.coverage_db)
        if total_tracked == 0:
            return 0
        return len([v for v in self.coverage_db.values() if v]) / total_tracked * 100

    def save_coverage(self, proc_num):
        """Save coverage data for a worker"""
        if self.multicore:
            cov_dir = f"{self.out_dir}/covmap-{proc_num}"
            os.makedirs(cov_dir, exist_ok=True)
            with open(f"{cov_dir}/coverage.json", "w") as f:
                json.dump(self.coverage_db, f)