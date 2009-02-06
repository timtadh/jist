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


"""
    number_user_programs $dst
    user_program $dst x
"""

import string, sys, re

global_macros = {}
kernel_macros = {}
max_user_programs = 16
main_count = 0
label_inc = 0
main_labels = list()

def make_kernel_macros():
    '''creates specialized macros'''
    global kernel_macros
    
    number_user_programs = ' '*4 + '#'*16 + ' start number_user_programs ' + '#'*16 + '\n'
    number_user_programs += ' '*4 + 'li      %1 @main_count@'
    number_user_programs += ' '*4 + '#'*17 + ' end number_user_programs ' + '#'*17 + '\n'
    number_user_programs = ''.join(process_lines(number_user_programs.split('\n'), False))
    
    load_user_programs = ' '*4 + '#'*16 + ' start load_user_programs ' + '#'*16 + '\n'
    load_user_programs += ' '*4 + '__save_frame\n'
    load_user_programs += ' '*4 + 'la      $s0 user_program_locations\n'
    for i in range(main_count):
        load_user_programs += ' '*4 + 'la      $s1 @main_labels['+str(i)+']@\n'
        load_user_programs += ' '*4 + 'sw      $s1 '+str(i*4)+'($s0)\n'
    load_user_programs += ' '*4 + '__restore_frame\n'
    load_user_programs += ' '*4 + '#'*17 + ' end load_user_programs ' + '#'*17 + '\n'
    load_user_programs = ''.join(process_lines(load_user_programs.split('\n'), False))
    
    kernel_macros.update({'number_user_programs':number_user_programs, 
                          'load_user_programs':load_user_programs})

def post_process_kernel_macro(macro_text):
    '''to be called after arg replacement is finished'''
    r = re.compile(r'\@.*\@')
    exprs = r.findall(macro_text)
    for expr in exprs:
        exec "rep = " + expr[1:-1] in globals()
        macro_text = macro_text.replace(expr, str(rep))
    return macro_text

#if specified, rename all the labels so they don't conflict with
#tim&steve's kernel labels
def substitute_labels(s):
    global main_count, label_inc
    replacements = []
    line_list = s.split('\n')
    for line in line_list:
        linestrip = line.strip()
        if len(linestrip) > 0:
            if linestrip[-1] == ':' and linestrip[0] in string.ascii_letters:
                if linestrip[:-1] == 'main':
                    replacements.append((linestrip[:-1], linestrip[:-1]+'_'+str(main_count)))
                    main_labels.append(linestrip[:-1]+'_'+str(main_count))
                    main_count += 1
                    if main_count >= max_user_programs:
                        raise Exception, "to many user programs added"
                else:
                    replacements.append((linestrip[:-1], linestrip[:-1]+"_u"+str(label_inc)))
                    label_inc += 1
    for old, new in replacements:
        s = s.replace(old, new)
    return s

def rep_line(line, local_macros, use_kernel_macros):
    #process macros
    global global_macros
    out_lines = []
    linesplit = line.split()
    if len(linesplit) > 0:
        mtext = ""
        name = linesplit[0]
        #See if first keyword is a local or global macro, set mtext if found
        if string.lower(name) in global_macros.keys():
            mtext = global_macros[name]
        if string.lower(name) in local_macros.keys():
            mtext = local_macros[name]
        if use_kernel_macros and string.lower(name) in kernel_macros.keys():
            mtext = kernel_macros[name]
            
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
            if use_kernel_macros and string.lower(name) in kernel_macros.keys():
                mtext = post_process_kernel_macro(mtext)
            #append macro text (possibly transformed) to output
            out_lines.append(mtext)
        else:
            out_lines.append(line+'\n')
    else:
        out_lines.append(line+'\n')
    return out_lines

def process_lines(in_lines, use_kernel_macros):
    global global_macros
    in_macro = False
    is_global = False
    out_lines = list()
    local_macros = dict()
    macro_name = ""
    for line in in_lines:
        line.strip()
        if line.startswith('#define'):
            #start defining macro, get its name and init a list of its lines
            if in_macro: print "Macro error."
            in_macro = True
            linesplit = line.split()
            macro_name = string.lower(linesplit[1])
            is_global = False
            start_text = ' '*4 + '#'*16 + ' start ' + macro_name + ' ' + '#'*16 + '\n'
            if len(linesplit) > 2 and string.lower(linesplit[2]) == 'global':
                is_global = True
            if is_global:
                global_macros[macro_name] = [start_text]
            else:
                local_macros[macro_name] = [start_text]
        elif line.startswith('#end'):
            #concatenate the lines and stop defining the macro
            in_macro = False
            end_text = ' '*4 + '#'*17 + ' end ' + macro_name + ' ' + '#'*17 + '\n'
            if macro_name in local_macros:
                local_macros[macro_name].append(end_text)
                local_macros[macro_name] = "".join(local_macros[macro_name])
            if macro_name in global_macros:
                global_macros[macro_name].append(end_text)
                global_macros[macro_name] = "".join(global_macros[macro_name])
        else:
            if in_macro:
                #check for macro-in-macro
                if macro_name in local_macros.keys():
                    local_macros[macro_name] += rep_line(line, local_macros, use_kernel_macros)
                if macro_name in global_macros.keys():
                    global_macros[macro_name] += rep_line(line, local_macros, use_kernel_macros)
            else:
                #check for regular ol' macro
                out_lines += rep_line(line, local_macros, use_kernel_macros)
    return out_lines

def process(path, out, replace_labels=False, use_kernel_macros=False):
    global global_macros
    
    included = []
    
    f1 = open(path, 'r')
    #local_macros = {}
    #out_lines = []
    #in_macro = False
    #macro_name = ""
    #is_global = False
    
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
    out_lines = process_lines(in_lines, use_kernel_macros)
    
    s = ''.join(out_lines)
    if replace_labels: s = substitute_labels(s)
    
    f1.close()
    #write giant string to file
    f2 = open(out, 'w')
    f2.write(s)
    f2.close()
    
    #make_kernel_macros()
    #print kernel_macros['load_user_programs']
    #print main_labels
    #print global_macros

if __name__ == "__main__":
    #if called from the cl, process with default args
    try:
        process(sys.argv[1], sys.argv[2])
    except:
        print "use 'python mpp.py in_file out_file"
