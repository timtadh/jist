#include stdlib.s
#include sys_macros.m
#include temporary_memory_manager.s

.data
mtt_str_1: .asciiz "Look at me! I'm multitasking!"
mtt_str_2: .asciiz "Look at me again! I'm still multitasking!"

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