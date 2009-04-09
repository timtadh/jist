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
    la $a0 read_buffer
    call readln
    
    la $a0 read_buffer
    call println
    
    exit
}
