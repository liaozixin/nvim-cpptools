import os
from os.path import isdir
import sys

if os.path.isdir(sys.argv[1]):
    print("true")
else:
    print("false")

