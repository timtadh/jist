'''
Generic macro engine.

.text 0x00400000
.globl main

#start_macro get_int
        li $v0, 5
        syscall
        move %1, $v0
#end_macro

#start_macro print_int
        move $a0, #1
        li $v0, 1
        syscall
#end_macro

main:
        get_int $t0     #You can even put comments after them!
        get_int $t1
        
        add $t2, $t0, $t1
        
        print_int $t2
        
        li  $v0, 10
        syscall

'''

import string, sys

def process(path, out):
    f = open(path, 'r')
    macros = {}
    out_lines = []
    in_macro = False
    macro_name = ""
    for line in f:
        line.strip()
        if line.startswith('#start_macro'):
            if in_macro: print "Macro error."
            in_macro = True
            macro_name = string.lower(line.split()[-1])
            macros[macro_name] = []
        elif line.startswith('#end_macro'):
            in_macro = False
            macros[macro_name] = "".join(macros[macro_name])
        else:
            if in_macro:
                macros[macro_name].append(line)
            else:
                linesplit = line.split()
                if len(linesplit) > 0:
                    if string.lower(linesplit[0]) in macros.keys():
                        mtext = macros[linesplit[0]]
                        if len(linesplit) > 1:
                            arg_num = 0
                            for arg in linesplit[1:]:
                                arg_num += 1
                                mtext = mtext.replace("%"+str(arg_num), arg)
                            out_lines.append(mtext)
                        else:
                            out_line = macros[mtext]
                    else:
                        out_lines.append(line)
                else:
                    out_lines.append(line)
                    
    f.close()
    f = open(out, 'w')
    f.write(''.join(out_lines))
    f.close()

if __name__ == "__main__":
    process(sys.argv[1], sys.argv[2])