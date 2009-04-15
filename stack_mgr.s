#include stdlib.s
#include sys_macros.m

.data
#Format of saved stack array, by word:
#   0: Available
#   1: PID
#   2: $fp
#   3: $sp
_saved_stacks:  .word 0             #need to use .word to make it align properly
                .space 252          #number of array spots * 16 - 4
                .word 2, 0, 0, 0    #terminates array
_current_stack: .word 0
.text

_find_stack:
{
    la $s3 _saved_stacks
    add $s1 $a0 $zero
    addi $s2 $zero 2
    #find the PID in the array
    _next_item:
        lw $s0 4($s3)
        beq $s0 $s1 _slot_found
        lw $s0 0($s3)
        beq $s0 $s2 _not_found
        addi $s3 $s3 16
        b _next_item
    _slot_found:
    add $v0 $s3 $zero
    return
    
    _not_found:
    add $v0 $zero $zero
    return
}

#define _find_free_space
    #find a free slot in the array
    la $v0 _saved_stacks
    addi $t1 $zero 2
    _next_item:
        lw $t0 0($v0)
        beqz $t0 _slot_found
        beq $t0 $t1 _not_found
        addi $v0 $v0 16
        b _next_item
    _slot_found:
    return
    
    _not_found:
    add $v0 $zero $zero
    return
#end

#save_stack PID $fp $sp
#   Finds an available slot and stores PID($a0), $fp($a1), and $sp($a2)
save_stack:
{
    #find a free slot in the array
    la $v0 _saved_stacks
    addi $t1 $zero 2
    _next_item:
        lw $t0 0($v0)
        beqz $t0 _slot_found
        addi $v0 $v0 16
        b _next_item
    _slot_found:
    
    addi $t0 $zero 1
    sw $t0 0($v0)   #used = 1
    sw $a0 4($v0)   #PID = $a0
    sw $a1 8($v0)   #$fp = $a1
    sw $a2 12($v0)  #$sp = $a2
    return
}

#init_stack PID
#   v0 = fp
#   v1 = sp
init_stack:
{
    addi $v0 $a0 100
    addi $v1 $a0 1000
    return
}

#change_stack PID $fp $sp
#   v0 = fp
#   v1 = sp
change_stack:
{
    #save old stack if there is one
    add $s0 $a0 $zero
    la $s2 _current_stack
    lw $s1 0($s2)
    beqz $s1 _skip_save
        add $a0 $s1 $zero
        exec save_stack
    _skip_save:
    
    #find the old stack, load if necessary
    
    add $a0 $s0 $zero
    call _find_stack
    beqz $v0 _new_stack
        add $s4 $v0 $zero
        lw $v0 8($s4)
        lw $v1 12($s4)
        sw $zero 0($s4)   #old stack slot is now available
        b _update_current
    _new_stack:
        add $a0 $s0 $zero
        call init_stack
    _update_current:
    #update current_stack so next call of change_stack will work
    la $t2 _current_stack
    sw $s0 0($t2)   #current_stack = PID
    return
}

print_stack:
{
    la $s2 _saved_stacks
    add $s0 $zero $zero
    addi $s1 $zero 2
    print_again:
        lw $a0 0($s2)
        call print_int
        li $a0 32
        call print_char
        lw $a0 4($s2)
        call print_int
        li $a0 32
        call print_char
        lw $a0 8($s2)
        call print_int
        li $a0 32
        call print_char
        lw $a0 12($s2)
        call print_int
        li $a0 10
        call print_char
        lw $s0 0($s2)
        addi $s2 $s2 16
    bne $s0 $s1 print_again
    li $a0 10
    call print_char
    return
}

#define print_current_stack
    la $t0 _current_stack
    lw $a0 0($t0)
    call print_int
    li $a0 10
    call print_char
#end

.text
.globl main
main:
    addi $a0 $zero 1
    call change_stack
    call print_stack
    
    addi $a0 $zero 2    #2 is the NEW PID
    addi $a1 $zero 11   #11 is the OLD FRAME POINTER for stack 1 to be saved
    addi $a2 $zero 111  #111 is the OLD STACK POINTER for stack 1  to be saved
    call change_stack
    call print_stack
    
    addi $a0 $zero 1
    addi $a1 $zero 22
    addi $a2 $zero 222
    call change_stack
    call print_stack
    
    addi $a0 $zero 3
    addi $a1 $zero 12
    addi $a2 $zero 121
    call change_stack
    call print_stack
    
    addi $a0 $zero 4
    addi $a1 $zero 33
    addi $a2 $zero 333
    call change_stack
    call print_stack
    exit