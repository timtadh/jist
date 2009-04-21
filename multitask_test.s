#include stdlib.s
#include sys_macros.m
#include temporary_memory_manager.s

.data
mtt_str_1: .asciiz "Look at me! I'm multitasking!"
mtt_str_2: .asciiz "Look at me again! I'm still multitasking!"

.text
#format of a linked list:
#   @ll: info block containing [head][greatest element number]
#   @h: head: [value][next address]
ll_init:    #a0 = value to init @h to
{
    @size = $s0
    @ll = $t1
    @initval = $s1
    add $s1 $a0 $zero
    
    li @size 2
    allocate_array @size $t0
    sw @initval 0($t0)
    sw $zero 4($t0)
    
    add $v0 $t0 $zero
    return
}
.text
ll_append:
{
    @size = $s0
    @new = $t0
    @newval = $t2
    @thisnode = $s1
    add @thisnode $a0 $zero
    add @newval $a1 $zero
    
    li @size 2
    allocate_array @size @new
    
    lw $t3 4(@thisnode)
    loop:
        beqz $t3 found_end
        add @thisnode $t3 $zero
        lw $t3 4(@thisnode)
        b loop
    found_end:
    
    sw @new 4(@thisnode)
    sw @newval 0(@new)
    sw $zero 4(@new)
    
    add $v0 @new $zero
    return
}
.text
ll_next:    #@h @current
{
    @head = $s0
    @current = $s1
    add @head $a0 $zero
    add @current $a1 $zero
    
    lw $v1 4(@current)
    beqz $v1 return_head
    lw $v0 0($v1)
    return
    
    return_head:
    add $v1 @head $zero
    lw $v0 0($v1)
    return
}
.text
ll_print:
{
    @addr = $s0
    add @addr $a0 $zero
    
    print_again:
        beqz $s0 done_printing
        lw $s1 0($s0)
        add $a0 $s1 $zero
        call print_int
        li $a0 10
        call print_char
        lw $s0 4($s0)
        b print_again
    done_printing:
    return
}

.globl main
.text
main:
{
    li $a0 42
    call ll_init
    add $a0 $v0 $zero
    add $s0 $v0 $zero
    addi $a1 $zero 43
    call ll_append
    add $a0 $s0 $zero
    addi $a1 $zero 44
    call ll_append
    
    #add $s1 $v0 $zero
    add $a0 $s0 $zero
    call ll_print
    
    add $a0 $s0 $zero
    add $a1 $s0 $zero
    call ll_next
    
    add $a0 $v0 $zero
    add $s1 $v1 $zero
    call print_int
    li $a0 32
    call print_char
    
    add $a0 $s0 $zero
    add $a1 $s1 $zero
    call ll_next
    add $a0 $v0 $zero
    add $s1 $v1 $zero
    call print_int
    li $a0 32
    call print_char
    
    add $a0 $s0 $zero
    add $a1 $s1 $zero
    call ll_next
    add $a0 $v0 $zero
    add $s1 $v1 $zero
    call print_int
    li $a0 32
    call print_char
    
    add $a0 $s0 $zero
    add $a1 $s1 $zero
    call ll_next
    add $a0 $v0 $zero
    add $s1 $v1 $zero
    call print_int
    li $a0 32
    call print_char
    
    add $a0 $s0 $zero
    add $a1 $s1 $zero
    call ll_next
    add $a0 $v0 $zero
    add $s1 $v1 $zero
    call print_int
    li $a0 32
    call print_char
    
    add $a0 $s0 $zero
    add $a1 $s1 $zero
    call ll_next
    add $a0 $v0 $zero
    add $s1 $v1 $zero
    call print_int
    li $a0 32
    call print_char
    
    li $a0 10
    call print_char
    exit
    
    # la $a0 mtt_str_1
    # call print
    # wait
    # la $a0 mtt_str_2
    # call print
    # wait
    # exit
}