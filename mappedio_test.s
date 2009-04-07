#Steve Johnson
#a test of memory-mapped IO

#include stdlib.s

.globl main
main:
{
    call read_char
    la $a0, 0($v0)
    call println
}