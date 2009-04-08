#Steve Johnson
#a test of memory-mapped IO

#include mappedio.s

.globl main
main:
{
#    call read_char
#    store_arg $v0
    addi $a0 $zero 97
#    store_arg $a0
    call write_char
    addi $a0 $zero 98
    call write_char
}
