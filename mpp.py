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

==USING MACROS IN MACROS==
You can use macros inside other macros as long as the first is defined above the second.
"""

import string, sys

global_macros = {}

def rep_line(line, local_macros):
    #process macros
    global global_macros
    out_lines = []
    linesplit = line.split()
    if len(linesplit) > 0:
        mtext = ""
        #See if first keyword is a local or global macro, set mtext if found
        if string.lower(linesplit[0]) in global_macros.keys():
            mtext = global_macros[linesplit[0]]
        if string.lower(linesplit[0]) in local_macros.keys():
            mtext = local_macros[linesplit[0]]
        #if keyword is a macro...
        if mtext != "":
            #if macro has arguments...
            if len(linesplit) > 1:
                #walk comma-delimited arg list
                arg_num = len(linesplit) - 1
                arg_list_string = ' '.join(linesplit[1:])
                arg_list = [t.strip() for t in arg_list_string.split(' ')]
                while arg_num > 0:
                    #replace expression with argument
                    mtext = mtext.replace("%"+str(arg_num), arg_list[arg_num-1])
                    arg_num -= 1
            #append macro text (possibly transformed) to output
            out_lines.append(mtext)
        else:
            out_lines.append(line+'\n')
    else:
        out_lines.append(line+'\n')
    return out_lines

def process(path, out, replace_labels=False):
    global global_macros
    
    included = []
    
    f1 = open(path, 'r')
    local_macros = {}
    out_lines = []
    in_macro = False
    macro_name = ""
    is_global = False
    
    #process includes
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
    
    #process macros
    for line in in_lines:
        line.strip()
        if line.startswith('#define'):
            #start defining macro, get its name and init a list of its lines
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
            #concatenate the lines and stop defining the macro
            in_macro = False
            if macro_name in local_macros:
                local_macros[macro_name] = "".join(local_macros[macro_name])
            if macro_name in global_macros:
                global_macros[macro_name] = "".join(global_macros[macro_name])
        else:
            if in_macro:
                #check for macro-in-macro
                if macro_name in local_macros.keys():
                    local_macros[macro_name] += rep_line(line, local_macros)
                if macro_name in global_macros.keys():
                    global_macros[macro_name] += rep_line(line, local_macros)
            else:
                #check for regular ol' macro
                out_lines += rep_line(line, local_macros)
    s = ''.join(out_lines)
    
    #if specified, rename all the labels so they don't conflict with
    #tim&steve's kernel labels
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
    #write giant string to file
    f2 = open(out, 'w')
    f2.write(s)
    f2.close()

if __name__ == "__main__":
    #if called from the cl, process with default args
    try:
        process(sys.argv[1], sys.argv[2])
    except:
        print "use 'python mpp.py in_file out_file"
