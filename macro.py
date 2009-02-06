# Steve Johnson
# Macro preprocessor for spim

'''
Generic macro engine.

#include your_file.s

.text 0x00400000
.globl main

#define get_int global
        li $v0, 5
        syscall
        move %1, $v0
#end

#define print_int local
        move $a0, #1
        li $v0, 1
        syscall
#end

main:
        get_int $t0     #You can even put comments after them!
        get_int $t1
        
        add $t2, $t0, $t1
        
        print_int $t2
        
        li  $v0, 10
        syscall

'''

import string, sys

global_macros = {}
included = []

def rep_line(line, local_macros):
    out_lines = list()
    linesplit = line.split()
    if len(linesplit) > 0:
        mtext = ""
        if string.lower(linesplit[0]) in global_macros.keys():
            mtext = global_macros[linesplit[0]]
        if string.lower(linesplit[0]) in local_macros.keys():
            mtext = local_macros[linesplit[0]]
        if mtext != "":
            if len(linesplit) > 1:
                arg_num = 0
                for arg in linesplit[1:]:
                    arg_num += 1
                    mtext = mtext.replace("%"+str(arg_num), arg)
                out_lines.append(mtext)
            else:
                out_lines.append(mtext)
        else:
            out_lines.append(line)
    else:
        out_lines.append(line)
    return out_lines

def process(path, out, replace_labels=False):
    global global_macros, included
    
    if path in included: return
    
    f1 = open(path, 'r')
    local_macros = {}
    out_lines = []
    in_macro = False
    macro_name = ""
    is_global = False
    for line in f1:
        line.strip()
        if line.startswith("#include"):
            linesplit = line.split()
            arg = ' '.join(linesplit[1:])
            if arg not in included:
                included.append(arg)
                f3 = open(arg, 'r')
                text = '\n###'+arg+'###\n' + f3.read()
                text = text + '\n###end '+arg+'###\n'
                f3.close()
                out_lines.append(text)
        elif line.startswith('#define'):
            if in_macro: print "Macro error."
            in_macro = True
            linesplit = line.split()
            macro_name = string.lower(linesplit[1])
            is_global = False
            if len(linesplit) > 2 and string.lower(linesplit[2]) == 'global':
                is_global = True
            if is_global:
                global_macros[macro_name] = []
            else:
                local_macros[macro_name] = []
        elif line.startswith('#end'):
            in_macro = False
            if macro_name in local_macros:
                local_macros[macro_name] = "".join(local_macros[macro_name])
            if macro_name in global_macros:
                global_macros[macro_name] = "".join(global_macros[macro_name])
        else:
            if in_macro:
                if macro_name in local_macros.keys():
                    local_macros[macro_name] += rep_line(line, local_macros)
                if macro_name in global_macros.keys():
                    global_macros[macro_name] += rep_line(line, local_macros)
            else:
                out_lines += rep_line(line, local_macros)
    s = ''.join(out_lines)
    replacements = []
    label_inc = 0
    if replace_labels:
        line_list = s.split('\n')
        for line in line_list:
            linestrip = line.strip()
            if len(linestrip) > 0:
                if linestrip[-1] == ':' \
                        and linestrip[0] in string.ascii_letters:
                    replacements.append(
                        (linestrip[:-1], linestrip[:-1]+"_u"+str(label_inc))
                    )
                    label_inc += 1
        print replacements
        for old, new in replacements:
            s = s.replace(old, new)
    f1.close()
    f2 = open(out, 'w')
    f2.write(s)
    f2.close()

if __name__ == "__main__":
    process(sys.argv[1], sys.argv[2])
