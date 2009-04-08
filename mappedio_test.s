#Steve Johnson
#a test of memory-mapped IO

#include mappedio.s

.globl main
main:
{
    call read_char
#    store_arg $v0
    add $a0 $zero $v0
#    store_arg $a0
    call write_char # Echo... echo... echo... echo...
    addi $a0 $zero 98
    call write_char # pick a char and write it. 
}
