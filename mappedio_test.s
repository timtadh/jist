#Steve Johnson
#a test of memory-mapped IO

#include stdlib.s

.data
read_buffer:    .space 256
ask_num:        .asciiz "Enter a number: "
test_fmt_str:   .asciiz "n1: %d. n2: %d.\n"
nl:          .asciiz "\n"
.text
.globl main
main:
{
    la $a0 ask_num
    exec print
    exec read_int
    add $s0 $v0 $zero
    
    la $a0 ask_num
    exec print
    exec read_int
    add $s1 $v0 $zero
    
    store_arg $s1
    store_arg $s0
    la $a0 test_fmt_str
    exec printf
    
    exit
}
