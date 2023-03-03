import os
import sys

if len(sys.argv) > 1:
    os.makedirs(sys.argv[1], exist_ok=True)
