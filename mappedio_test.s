#Steve Johnson
#a test of memory-mapped IO

#include stdlib.s

.data
read_buffer: .space 256
test_buffer: .asciiz "Hey hey, it works!"
nl:          .asciiz "\n"
.text
.globl main
main:
{
    # la $a0 read_buffer
    # call readln
    # 
    # la $a0 read_buffer
    # call println
    # 
    # la $a0 test_buffer
    # call println
    # 
    # addi $a0 $zero -1054
    # call print_int
    
    exec read_int
    add $a0 $v0 $zero
    exec print_int
    
    la $a0 nl
    exec print
    
    exit
}
