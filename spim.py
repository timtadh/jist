#!/usr/bin/python

'''
This is meant to be used to build a full mips program from multiple file sources. The labels
"__start" and "main" should be in the first file. The exception handler at ".text 0x80000180"
should be the last thing in the last file.
'''

import sys, os, shutil
import subprocess
import string
import mpp

kernel_files = [
    'kernel.s'
]

if __name__ != '__main__': sys.exit(0)

if len(sys.argv) < 2:
    print "Usage: python spim.py [--stripcomments] file1.s file2.s file3.s ... fileN.s"
    sys.exit(0)

filenames = sys.argv[1:]
if filenames[0] == '--stripcomments':
    strip_comments = True
    filenames = filenames[1:]
else:
    strip_comments = True
filenames_processed = []
files = []

if os.path.exists('build'):
    for f in os.listdir('build'):
        os.remove(os.path.join('build', f))
    os.rmdir('build')
    os.makedirs('build')

kernel_started = False

for filename in filenames:
    new_path = os.path.join('build', filename.split('/')[-1])
    if filename not in kernel_files:
        mpp.process(filename, new_path, replace_labels=True)
    elif not kernel_started:
        kernel_started = True
        mpp.make_kernel_macros()
        mpp.process(filename, new_path, True, False, True, True)
    else:
        mpp.process(filename, new_path, True, False, True, True)
    filenames_processed.append(new_path)

for filename in filenames_processed:
    f = open(filename, 'r')
    t = '#'*12 + ' ' + filename + ' ' + '#'*12 + '\n'
    t += f.read()
    t += '\n' + '#'*12 + ' ' + filename + ' ' + '#'*12 + '\n'
    files.append(t)
    f.close()

s = '\n\n'.join(files)
out_path = os.path.join('build', '__spim_py_out')
f = open(out_path, 'w')
f.write(s)
f.close()

mpp.process(out_path, out_path)

subprocess.check_call(["spim", "-ne",  "-mio",  out_path])
#subprocess.check_call(["spim", "-ne", out_path])
