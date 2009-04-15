{
#include stdlib.s
#include sys_macros.m
.data
#Format of saved stack array, by word:
#   0: Available
#   1: PID
#   2: $fp
#   3: $sp
_saved_stacks: .space 1024
_current_stack: .word -1
.text

#define _find_stack
    la $v0 _saved_stacks
    #find the PID in the array
    _next_item:
        lw $t0 4($v0)
        beq $t0 %1 _slot_found
        addi $v0 $v0 16
        b _next_item
    _slot_found:
#end

#save_stack PID $fp $sp
#   Finds an available slot and stores PID($a0), $fp($a1), and $sp($a2)
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
    sw $zero 0($t2) #available = 0
    sw $a0 4($t2)   #PID = $a0
    sw $a1 8($t2)   #$fp = $a1
    sw $a2 12($t2)  #$sp = $a2
    return
}

#change_stack PID $fp $sp
change_stack:
{
    #save old stack if there is one
    add $s0 $a0 $zero
    la $t2 _current_stack
    lw $s1 0($t2)
    bltz $t0 _skip_save
        add $a0 $s1 $zero
        exec save_stack
    _skip_save:
    
    #find slot for new stack, fill it
    add $a0 $s0 $zero
    _find_stack $a0
    lw $fp 8($v0)
    lw $sp 12($v0)
    li $t0 1
    sw $t0 0($v0)   #old stack slot is now available
    
    #update current_stack so next call of change_stack will work
    la $t2 _current_stack
    sw $a0 0($t2)   #current_stack = PID
    return
}

}