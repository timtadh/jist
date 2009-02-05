'''
Generic macro engine.

#start_macro get_int
#        li $v0, 5
#        syscall
#        move %(reg)s, $v0
#end_macro

call_macro get_int dict(reg='$t0')
'''

import string, re

r = re.compile(r'\%[0-9]+')

#print r.findall("%29 %30")

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
            macro_name = line.split()[-1]
            macros[macro_name] = []
        elif line.startswith('#end_macro'):
            in_macro = False
            macros[macro_name] = "".join(macros[macro_name])
        else:
            if in_macro:
                macros[macro_name].append(line)
            else:
                linesplit = line.split()
                if len(linesplit) > 1:
                    if string.lower(linesplit[0]) == 'call':
                        out_line = '!macro error!'
                        if len(linesplit) > 2:
                            args = eval(' '.join(linesplit[2:]))
                            if type(args) == type([]):
                                out_line = macros[linesplit[1]] % tuple(args)
                            elif type(args) == type({}):
                                out_line = macros[linesplit[1]] % args
                            elif type(args) == type(''):
                                out_line = macros[linesplit[1]] % \
                                        tuple([eval(s) for s in linesplit[2:]])
                        else:
                            out_line = macros[linesplit[1]]
                        out_lines.append(out_line)
                    else:
                        out_lines.append(line)
                else:
                    out_lines.append(line)
                    
    f.close()
    f = open(out, 'w')
    f.write(''.join(out_lines))
    f.close()

if __name__ == "__main__":
    process('test.asm', 'test_2.asm')