# coverage/corpus_manager.py
import os
from mutation.mutator import simInput

class CorpusManager:
    def __init__(self, corpus_dir, max_size=1000):
        self.corpus_dir = corpus_dir
        self.max_size = max_size
        self.corpus = []

    def add_test(self, sim_input):
        # Add test to corpus if it improves coverage (from Fuzzer.py's `cNum` logic)
        if len(self.corpus) >= self.max_size:
            self.corpus.pop(0)
        self.corpus.append(sim_input)
        sim_input.save(f"{self.corpus_dir}/id_{len(self.corpus)}.si")

    def select_seed(self):
        # Select a random seed from the corpus for mutation
        return random.choice(self.corpus) if self.corpus else None