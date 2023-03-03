import os
from os.path import isdir
import sys

if len(sys.argv) > 1:
    if os.path.isdir(sys.argv[1]):
        print("true")
    else:
        print("false")

