{
#include stdlib.s
#include sys_macros.m
.data
#Format of saved stack array, by word:
#   0: Available
#   1: PID
#   2: $fp
#   3: $sp
_saved_stacks: .space 256
_current_stack: .word 0
.text

#init_stack PID
#   Finds an available slot and stores PID ($a0), $fp, and $sp
save_stack:
{
    li $t1 1
    la $t2 _saved_stacks
    #find a free slot in the array
    _next_item:
        lw $t0 0($t2)
        beq $t0 $t1 _slot_found
        addi $t2 $t2 16
        b _next_item
    _slot_found:
    sw $t1 0($t2)
    sw $a0 4($t2)
    sw $fp 8($t2)
    sw $sp 12($t2)
    return
}

close_stack:
{
    return
}

change_stack:
{
    return
}

}