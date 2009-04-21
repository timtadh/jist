#include stdlib.s
#include sys_macros.m
#include temporary_memory_manager.s

.text
#format of a linked list:
#   @h: head: [process num][next address][pcb mem_id]

#ll_init(initial_pid, initial_pcb)
ll_init:
{
    @size = $s0
    @initval = $s1
    @initpcb = $s2
    @h = $t0
    add @initival $a0 $zero
    add @initpcb $a1 $zero
    
    li @size 3
    allocate_array @size @h
    sw @initval 0(@h)
    sw $zero 4(@h)
    sw @initpcb 8(@h)
    
    add $v0 @h $zero
    return
}

.text
#ll_append(some_node, new_pid, new_pcb_mem_id)
ll_append:
{
    @size = $s0
    @new = $t0
    @newval = $t2
    @nextnode = $t3
    @newpcb = $t4
    @thisnode = $t5
    
    add @thisnode $a0 $zero
    add @newval $a1 $zero
    add @newpcb $a2 $zero
    
    li @size 3
    allocate_array @size @new
    
    lw @nextnode 4(@thisnode)
    loop:
        beqz @nextnode found_end
        add @thisnode @nextnode $zero
        lw @nextnode 4(@thisnode)
        b loop
    found_end:
    
    sw @new 4(@thisnode)
    sw @newval 0(@new)
    sw $zero 4(@new)
    sw @newpcb 8(@new)
    
    add $v0 @new $zero
    return
}
.text
#ll_next(list_head, current_node)
#   v0 = pcb mem_id
#
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
    lw $v0 8($v1)
    return
}

.text
#ll_remove(list_head, to_remove)
ll_remove:
{
    @head = $s0
    @to_remove = $s0
    add @head $a0 $zero
    add @to_remove $a1 $zero
    
    loop:
        beqz @head found_end
        lw $t0 4(@head)
        bne $t0 @to_remove not_found_yet
            lw $t0 4(@to_remove)
            sw $t0 4(@head)
            return
        not_found_yet:
            add $t0 @head $zero
    found_end:
    
    #fail silently
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
