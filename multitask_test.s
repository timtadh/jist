#include stdlib.s

.data
format_str: .asciiz "mt1: "
dbg_str_1: .asciiz "$fp: "
dbg_str_2: .asciiz "$sp: "

#define stackprint
    addu $s7 $fp $zero
    println_hex dbg_str_1 $s7
    addu $s7 $sp $zero
    println_hex dbg_str_2 $s7
#end

.text
print_test:
{
    #stackprint
    addu $s0 $a0 $zero
    println_hex format_str $s0
    return
}

.globl main
.text
main:
{
    @loopvar = $s5
    li @loopvar 0
    loop:
        
        #stackprint
        
        addu $a0 @loopvar $zero
        call print_test
        addi @loopvar @loopvar 1
        
        #stackprint
        wait
        
        li $a0 3
        beq @loopvar $a0 killme
    b loop
    
    killme:
    exit
}
