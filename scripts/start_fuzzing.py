import time
import random
from mutation.mutator import rvMutator
from execution.test_executor import TestExecutor
from coverage.corpus_manager import CorpusManager
from coverage.coverage_tracker import CoverageTracker
from common.config import parse_args
from common.constants import ROCKET, BOOM
from common.utils import debug_print

def main():
    args = parse_args()
    debug_print(f"Starting fuzzing with config: {args}", args.debug)

    # Initialize components
    mutator = rvMutator(
        max_data_seeds=args.max_data,
        corpus_size=args.corpus_size,
        no_guide=args.no_guide
    )
    corpus = CorpusManager(
        corpus_dir=f"{args.out}/corpus",
        max_size=args.corpus_size
    )
    coverage_tracker = CoverageTracker(
        out_dir=args.out,
        multicore=args.multicore > 1
    )

    # Initialize DUT and executor (simplified for example)
    dut = None  # In real use, load Verilated DUT
    executor = TestExecutor(
        dut, args.toplevel, args.out, debug=args.debug
    )

    # Fuzzing loop
    start_time = time.time()
    for it in range(args.num_iter):
        # 1. Generate/mutate test
        sim_input, data = mutator.get(it)
        debug_print(f"Generated test {it}", args.debug)

        # 2. Execute test
        mismatch, coverage = executor.execute(sim_input, data, it)

        # 3. Update coverage and corpus
        coverage_tracker.update_from_rtl(coverage)
        current_score = coverage_tracker.get_coverage_score()
        debug_print(
            f"Iteration {it}: Coverage={current_score:.2f}%, Mismatch={mismatch}",
            args.debug
        )

        # Save to corpus if new coverage is found
        if coverage > 0:
            corpus.add_test(sim_input)

    # Finalize
    if args.multicore > 1:
        coverage_tracker.aggregate_multicore(proc_num=0)
    print(f"Fuzzing complete. Final coverage: {coverage_tracker.get_coverage_score():.2f}%")

if __name__ == "__main__":
    main()