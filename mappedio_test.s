#Steve Johnson
#a test of memory-mapped IO

#include stdlib.s

.data
read_buffer: .word 256
.text
.globl main
main:
{
    addi $s0 $zero 10
    la $s1 read_buffer #s1 = buffer position
read_again:
    call read_char
    add $a0 $zero $v0
    add $s1 $zero $v0
    call write_char # Echo... echo... echo... echo...
    bne $v0 $s0 read_again
end_read:
    exit
}
