#include stdlib.s

.data
mtt_str_1: .asciiz "mtt1-a"
mtt_str_2: .asciiz "mtt1-b"
format_str: .asciiz "mt1: %d\n"

.text
print_test:
{
    store_arg $a0
    la $a0 format_str
    call printf
    return
}

.globl main
.text
main:
{
    @loopvar = $s0
    li @loopvar 0
    loop:
        addu $a0 @loopvar $zero
        call print_test
        addi $s0 @loopvar 1
        #wait
    b loop
}
