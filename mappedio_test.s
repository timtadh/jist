#Steve Johnson
#a test of memory-mapped IO

#include stdlib.s

.data
read_buffer:    .space 256
ask_num:        .asciiz "Enter a number: "
ask_str:        .asciiz "\nEnter a string: "
ask_char:       .asciiz "Enter a character: "
test_fmt_str:   .asciiz "n1: %d. n2: %x.\n%%%f\nYour character: %c\nYour string: %s\n"
nl:          .asciiz "\n"
.text
.globl main
main:
{
    la $a0 ask_num
    exec print
    la $a0 read_buffer
    exec read_int
    add $s0 $v0 $zero
    
    la $a0 ask_num
    exec print
    la $a0 read_buffer
    exec read_int
    add $s1 $v0 $zero
    
    la $a0 ask_char
    exec print
    la $a0 read_buffer
    exec read_char
    add $s2 $v0 $zero
    add $a0 $s2 $zero
    exec print_char
    
    la $a0 ask_str
    exec print
    la $a0 read_buffer
    exec readln
    la $s3 read_buffer
    
    store_arg $s3
    store_arg $s2
    store_arg $s1
    store_arg $s0
    la $a0 test_fmt_str
    exec printf
    
    
    # read_again:
    #     _read_char $s0
    #     add $a0 $s0 $zero
    #     exec print_int
    #     addi $a0 $zero 10
    #     _write_char $a0
    #     bnez $s0 read_again
    
    exit
}
