#include stdlib.s
#include sys_macros.m
#include temporary_memory_manager.s

.data
mtt_str_1: .asciiz "Look at me! I'm multitasking!"
mtt_str_2: .asciiz "Look at me again! I'm still multitasking!"

#format of a linked list:
#   @ll: info block containing [head][greatest element number]
#   @h: head: [value][next address]
ll_init:    #a0 = value to init @h to
{
##define ll_init
    # @size = $s0
    # @ll = $t1
    # @h = $t0
    # @initval = $s1
    # add $s1 $a0 $zero
    
    # li @size 2
    # allocate_array @size @ll
    # allocate_array @size @h
    # sw @h 0(@ll)
    # sw $zero 4(@ll)
    # sw @initval 0(@h)
    # sw $zero 4(@h)
    # 
    # add $v0 @h $zero
    # add $v1 @ll $zero
##end    
    return
}

ll_append:
{
    return
}

ll_print:
{
    @addr = $s0
    add @addr $a0 $zero
    
    print_again:
        lw $s1 0($s0)
        beqz $s0 done_printing
        add $a0 $s1 $zero
        call print_int
        li $a0 10
        call print_char
        lw $s0 4($s0)
        b print_again
    done_printing:
    return
}

.text
.globl main
main:
{
    #li $a0 42
    call ll_init
    # add $a0 $v0 $zero
    # call ll_print
    # addi $a1 $zero 43
    # call ll_append
    
    # la $a0 mtt_str_1
    # call print
    # wait
    # la $a0 mtt_str_2
    # call print
    # wait
    # exit
}