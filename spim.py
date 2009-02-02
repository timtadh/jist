#!/usr/bin/python

'''
This is meant to be used to build a full mips program from multiple file sources. The labels
"__start" and "main" should be in the first file. The exception handler at ".ktext 0x80000180"
should be the last thing in the last file.
'''

import sys
import subprocess

if __name___ != '__main__': sys.exit(0)

if len(sys.argv) < 2:
    print "Usage: python spim.py file1.s file2.s file3.s ... fileN.s"
    sys.exit(0)

filenames = sys.argv[1:]
files = []

for filename in filenames:
    f = open(filename, 'r')
    t = '#'*12 + ' ' + filename + ' ' + '#'*12 + '\n'
    t += f.read()
    t += '#'*12 + ' ' + filename + ' ' + '#'*12 + '\n'
    files.append()
    f.close()

s = '\n\n'.join(files)

f = open('__spim_py_out', 'w')
f.write(s)
f.close()

print subprocess.check_call(["spim", "-ne",  "-mio",  "__spim_py_out"])
