#Steve Johnson
#a test of memory-mapped IO

#include stdlib.s

.data
read_buffer:
#repeat 8
.word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
test_text: .asciiz "Fuck you, world!"
.text
.globl main
main:
{
    addi $s0 $zero 10
    la $s1 read_buffer #s1 = buffer position
read_again:
    call read_char
    add $a0 $zero $v0
    sw $v0 0($s1)
    addi $s1 $s1 4
    call write_char # Echo... echo... echo... echo...
    bne $v0 $s0 read_again
    sw $zero 0($s1)
    
    la $s1 read_buffer
write_again:
    lw $a0 0($s1)
    addi $s1 $s1 4
    beqz $a0 end_write
    call write_char # Echo... echo... echo... echo...
    b write_again
end_write:
    exit
}
