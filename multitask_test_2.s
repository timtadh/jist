#include stdlib.s

.data
mtt_str_1: .asciiz "mtt1-a"
mtt_str_2: .asciiz "mtt1-b"
format_str: .asciiz "mt2: %d\n"

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
    li $s0 0
    loop:
        addu $a0 $s0 $zero
        call print_test
        addi $s0 $s0 1
        wait
    b loop
}
