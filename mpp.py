#!/usr/bin/python
"""
MIPS Preprocessor
by Steve Johnson

==INCLUDING FILES==
#include your_file.s

==DEFINING MACROS==
#define macro_name [global]
    move %1, %2
#end

Put %n in macros to specify where parameters go.
Add 'global' to the #define line if this macro should be accessible from all other files.

==CALLING MACROS==
    macro_name a b

Yes, you can call a macro from within a macro. Just don't do it recursively, or else.
"""

import string, sys

global_macros = {}
included = []

def rep_line(line, local_macros):
    #Check for macros, handle macro-in-macro if necessary.
    #Hopefully they aren't cyclical.
    global global_macros
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
                arg_num = len(linesplit) - 1
                arg_list_string = ' '.join(linesplit[1:])
                arg_list = [t.strip() for t in arg_list_string.split(' ')]
                while arg_num > 0:
                    print arg_list, linesplit
                    mtext = mtext.replace("%"+str(arg_num), arg_list[arg_num-1])
                    arg_num -= 1
                out_lines.append(mtext)
            else:
                out_lines.append(mtext)
        else:
            out_lines.append(line+'\n')
    else:
        out_lines.append(line+'\n')
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
    s = ""
    in_lines = []
    for line in f1:
        stripped = line.strip()
        if stripped.startswith("#include"):
            linesplit = stripped.split()
            arg = ' '.join(linesplit[1:])
            if arg not in included:
                included.append(arg)
                f3 = open(arg, 'r')
                text = '\n###'+arg+'###\n' + f3.read()
                text = text + '\n###end '+arg+'###\n'
                f3.close()
                in_lines.append(text)
        else:
            in_lines.append(line)
    in_text = ''.join(in_lines)
    in_lines = in_text.split('\n')
    for line in in_lines:
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
        for old, new in replacements:
            s = s.replace(old, new)
    f1.close()
    f2 = open(out, 'w')
    f2.write(s)
    f2.close()

if __name__ == "__main__":
    process(sys.argv[1], sys.argv[2])
