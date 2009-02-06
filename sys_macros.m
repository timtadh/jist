# Tim Henderson
# System Macros for jist
# Meant to be available to every program for jist

#define __save_frame global
    addu    $fp $sp $0          # move the frame pointer to point at top of frame
    subu    $sp $sp 36          # move the stack pointer down 36
    sw      $ra 36($sp)         # save the return address
    sw      $s0 32($sp)         # save registers $s0 - $s7
    sw      $s1 28($sp)
    sw      $s2 24($sp)
    sw      $s3 20($sp)
    sw      $s4 16($sp)
    sw      $s5 12($sp)
    sw      $s6 8($sp)
    sw      $s7 4($sp)
#end

#define __restore_frame global
    subu    $sp $fp 36          # move the stack pointer to the orginal unmodified bottom
    lw      $ra 36($sp)         # load the return address
    lw      $s0 32($sp)         # load registers $s0 - $s7
    lw      $s1 28($sp)
    lw      $s2 24($sp)
    lw      $s3 20($sp)
    lw      $s4 16($sp)
    lw      $s5 12($sp)
    lw      $s6 8($sp)
    lw      $s7 4($sp)
    addu    $sp $fp $0          # move the stack pointer to point at top of frame
    addu    $fp $fp 36          # move the frame pointer up 36
#end

# store_arg arg
# arg : the register you would like to store on frame
#define store_arg global
    sw      %1 0($sp)
    subu    $sp $sp 4           # move the stack pointer down 4
#end

# load_arg arg_num destination temp_reg
# arg_num : the number of the argument you want it must an immediate value
# destination : register you want your argument in
# temp_reg : this macro requires a temporary register
# args number works like this
# store_arg $t3  --> arg 3
# store_arg $s3  --> arg 2
# store_arg $v1  --> arg 1
# call my_procedure
#define load_arg global
    li      %2 %1
    mul     %2 %2 4
    addu    %3 $fp %2
    lw      %2 0(%3)
#end

# call label num_stored_args
# label : label you are jumping to
# note when you use this you cannot pass args in $a3 that is reserved to passing
# a generalized way to call procedures
#define call global
    __save_frame
    jal     %1
    __restore_frame
#end

#define return global
    jr      $ra
#end
