import sys
import os

file_names = os.listdir(sys.argv[1])
res = ';'.join(file_names)
print(res)


