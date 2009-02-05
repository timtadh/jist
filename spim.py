#!/usr/bin/python

'''
This is meant to be used to build a full mips program from multiple file sources. The labels
"__start" and "main" should be in the first file. The exception handler at ".ktext 0x80000180"
should be the last thing in the last file.
'''

import sys
import subprocess
import string
import macro

label_replace_exclude = [
    'start.s',
    'interrupt_handler.s',
    'exception_handler.s'
]

if __name__ != '__main__': sys.exit(0)

if len(sys.argv) < 2:
    print "Usage: python spim.py file1.s file2.s file3.s ... fileN.s"
    sys.exit(0)

filenames = sys.argv[1:]
filenames_processed = []
files = []

def process_labels(path_in, path_out):
    f1 = open(path_in, 'r')
    s = f1.read()
    f1.seek(0)
    f2 = open(path_out, 'w')
    replacements = []
    label_inc = 0
    for line in f1:
        linestrip = line.strip()
        if len(linestrip) > 0:
            if linestrip[-1] == ':' and linestrip[0] in string.ascii_letters:
                replacements.append(
                    (linestrip[:-1], linestrip[:-1]+"_u"+str(label_inc))
                )
                label_inc += 1
    print replacements
    for repl in replacements:
        s = s.replace(repl[0], repl[1])
    f2.write(s)

for filename in filenames:
    if filename not in label_replace_exclude:
        new_name = '__spim_py_'+filename
        process_labels(filename, new_name)
        filenames_processed.append(new_name)
    else:
        filenames_processed.append(filename)

for filename in filenames_processed:
    f = open(filename, 'r')
    t = '#'*12 + ' ' + filename + ' ' + '#'*12 + '\n'
    t += f.read()
    t += '\n' + '#'*12 + ' ' + filename + ' ' + '#'*12 + '\n'
    files.append(t)
    f.close()

s = '\n\n'.join(files)
f = open('__spim_py_out', 'r+')
f.write(s)
f.close()

macro.process('__spim_py_out', '__spim_py_out')

subprocess.check_call(["spim", "-ne",  "-mio",  "__spim_py_out"])
