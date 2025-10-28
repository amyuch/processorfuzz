# Mutation phases (from mutator.py)
GENERATION = 0
MUTATION = 1
MERGE = 2

# Simulation states (from RTLSim/host.py)
SUCCESS = 0
TIME_OUT = 1
ASSERTION_FAIL = 2
ILL_MEM = 3

# Processor types
ROCKET = "RocketTile"
BOOM = "BoomTile"
BLACK_PARROT = "BlackParrotTile"

# Test templates (from mutator.py)
TEMPLATES = ["p-m", "p-s", "p-u", "v-u"]
P_M = 0
P_S = 1
P_U = 2
V_U = 3

# Coverage constants
COVERAGE_DB_VERSION = "1.0"