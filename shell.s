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
    wait
    exit
}
