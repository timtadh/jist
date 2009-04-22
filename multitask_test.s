#include stdlib.s
#include sys_macros.m

.data
mtt_str_1: .asciiz "mtt1-a"
mtt_str_2: .asciiz "mtt1-b"

.globl main
.text
main:
{
    la $a0 mtt_str_1
    call println
    wait
    la $a0 mtt_str_2
    call println
    wait
    exit
}
