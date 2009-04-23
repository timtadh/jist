#Steve Johnson
#a test of memory-mapped IO
#actually not, this file is junk

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
    addu    $s0 $0 0x1
    addu    $s1 $0 0x2
    addu    $s2 $0 0x3
    addu    $s3 $0 0x4
    addu    $s4 $0 0x5
    addu    $s5 $0 0x6
    addu    $s6 $0 0x7
    addu    $s7 $0 0x8
    __save_frame
    wait
    exit
}
