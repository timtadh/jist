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

kernel_files = ['kernel.s']
start_files = ['sys_macros.m']
end_files = ['kernel.s']

if __name__ != '__main__': sys.exit(0)

if len(sys.argv) < 2:
    help_string = """Usage: python spim.py [options] [extra files]

Options:
--stripcomments or -s:
    Strip comments from output file

--jistfile or -j:
    Load program list from file 'jistfile'

--out or -o:
    Specify an output file (untested)"""
    print help_string
    sys.exit(0)

first_prog = 0

def process_jistfile(jf_path):
    global first_prog
    location_table = {}
    load_location = 0
    filenames = start_files[:]
    f = open(jf_path, 'r')
    for line in f:
        try:
            left, right = [s.strip() for s in line.split(":")]
            if left == 'init_with':
                first_prog = location_table[right]
        except:
            s = line.strip()
            if s != '':
                filenames.append(s)
                location_table[s] = load_location
                load_location += 4
    f.close()
    filenames.extend(end_files)
    return filenames

cstrip = False
out_path = os.path.join('build', '__spim_py_out')
filenames = []

next_is_output = False
for arg in sys.argv[1:]:
    if next_is_output:
        next_is_output = False
        out_path = arg
    else:
        if arg == '--stripcomments' or arg == '-s':
            cstrip = True
        elif arg == '--jistfile' or arg == '-f':
            filenames = process_jistfile('jistfile')
        elif arg == '--out' or arg == '-o':
            next_is_output = True
        else:
            filenames.append(arg)
filenames_processed = []
files = []

if os.path.exists('build'):
    for f in os.listdir('build'):
        os.remove(os.path.join('build', f))
    os.rmdir('build')
os.makedirs('build')

kernel_started = False
prompt_strings = [str(i)+": " + os.path.splitext(s)[0] + r"\n" for i, s in zip(range(len(filenames)), filenames)][1:-1]

for filename in filenames:
    new_path = os.path.join('build', filename.split('/')[-1])
    if filename not in kernel_files:
        mpp.process(filename, new_path, replace_labels=True, cstrip=cstrip, first=first_prog, ps=prompt_strings)
    elif not kernel_started:
        kernel_started = True
        mpp.make_kernel_macros()
        mpp.process(filename, new_path, True, False, True, cstrip)
    else:
        mpp.process(filename, new_path, True, False, True, cstrip)
    filenames_processed.append(new_path)

for filename in filenames_processed:
    f = open(filename, 'r')
    t = f.read()
    if not cstrip:
        t = '#'*12 + ' ' + filename + ' ' + '#'*12 + '\n' + t
        t += '\n' + '#'*12 + ' ' + filename + ' ' + '#'*12 + '\n'
    files.append(t)
    f.close()

s = '\n\n'.join(files)
f = open(out_path, 'w')
f.write(s)
f.close()

mpp.process(out_path, out_path)

subprocess.check_call(["spim", "-ne", "-mio", "-stext", "1048576", out_path])
#subprocess.check_call(["spim", "-ne", out_path])
