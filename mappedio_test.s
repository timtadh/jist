#Steve Johnson
#a test of memory-mapped IO

#include stdlib.s

.data
read_buffer:
#repeat 8
.word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.text
.globl main
main:
{
    addi $s0 $zero 10
    la $s1 read_buffer #s1 = buffer position
read_again:
    call read_char
    add $a0 $zero $v0
    sb $v0 0($s1)
    addi $s1 $s1 1
    call write_char # Echo... echo... echo... echo...
    bne $v0 $s0 read_again
    sb $zero 0($s1)
    
    la $s1 read_buffer
write_again:
    lbu $a0 0($s1)
    addi $s1 $s1 1
    beqz $a0 end_write
    call write_char # Echo... echo... echo... echo...
    b write_again
end_write:
    exit
}
