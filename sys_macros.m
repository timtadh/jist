# Tim Henderson
# System Macros for jist
# Meant to be available to every program for jist

#define __save_frame global
    sw      $fp 0($sp)          # save the old frame pointer
    addu    $fp $sp $0          # move the frame pointer to point at top of frame
    subu    $sp $sp 44          # move the stack pointer down 44
    sw      $fp 40($sp)         # save the old stack pointer
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
    subu    $sp $fp 44          # move the stack pointer to the orginal unmodified bottom
    lw      $ra 36($sp)         # load the return address
    lw      $s0 32($sp)         # load registers $s0 - $s7
    lw      $s1 28($sp)
    lw      $s2 24($sp)
    lw      $s3 20($sp)
    lw      $s4 16($sp)
    lw      $s5 12($sp)
    lw      $s6 8($sp)
    lw      $s7 4($sp)
    lw      $fp 44($sp)         # load the old frame pointer
    lw      $sp 40($sp)         # load the old stack pointer
#end

# store_arg arg
#     arg : the register you would like to store on frame
#define store_arg global
    sw      %1 0($sp)
    subu    $sp $sp 4           # move the stack pointer down 4
#end

# load_arg arg_num destination
#     arg_num : the number of the argument you want it must an immediate value
#     destination : register you want your argument in
#     temp_reg : this macro requires a temporary register
#     args number works like this
#     store_arg $t3  --> arg 3
#     store_arg $s3  --> arg 2
#     store_arg $v1  --> arg 1
#     call my_procedure
#define load_arg global
    li      %2 %1
    mul     %2 %2 4
    addu    %2 $fp %2
    lw      %2 0(%2)
#end

# call label
#     label : label you are jumping to
#define call global
    __save_frame
    jal     %1
    __restore_frame
#end

# __min_save
#     most minimal stack frame save
#define __min_save
    sw      $fp 0($sp)          # save the old frame pointer
    addu    $fp $sp $0          # move the frame pointer to point at top of frame
    subu    $sp $sp 12          # move the stack pointer down 32
    sw      $fp 8($sp)         # save the old stack pointer
    sw      $ra 4($sp)         # save the return address
#end

# __min_restore
#     most minimal stack frame restore
#define __min_restore
    subu    $sp $fp 12           # move the stack pointer to the orginal unmodified bottom
    lw      $ra 4($sp)         # save the return address
    lw      $fp 12($sp)         # load the old frame pointer
    lw      $sp 8($sp)         # load the old stack pointer
#end


# exec label
#     label : label you are jumping to
# like call but more minimal stack save
#define exec global
    __min_save
    jal     %1
    __min_restore
#end

#define return global
    jr      $ra
#end

# __save_args
#     this macro saves $a0, $a1, $a2, $a3, $v0, $v1 on the stack
#define __save_args global
    sw      $fp 0($sp)          # save the old frame pointer
    addu    $fp $sp $0          # move the frame pointer to point at top of frame
    subu    $sp $sp 32          # move the stack pointer down 32
    sw      $fp 28($sp)         # save the old stack pointer
    sw      $a0 24($sp)         # save $a0
    sw      $a1 20($sp)         # save $a1
    sw      $a2 16($sp)         # save $a2
    sw      $a3 12($sp)         # save $a3
    sw      $v0 8($sp)          # save $v0
    sw      $v1 4($sp)          # save $v1
#end

# __restore_args
#     this macro restores $a0, $a1, $a2, $a3, $v0, $v1 on the stack
#define __restore_args global
    subu    $sp $fp 32          # move the stack pointer to the orginal unmodified bottom
    lw      $a0 24($sp)         # load $a0
    lw      $a1 20($sp)         # load $a1
    lw      $a2 16($sp)         # load $a2
    lw      $a3 12($sp)         # load $a3
    lw      $v0 8($sp)          # load $v0
    lw      $v1 4($sp)          # load $v1
    lw      $fp 32($sp)         # load the old frame pointer
    lw      $sp 28($sp)         # load the old stack pointer
#end

# quickstore reg
#     reg : the register you want to store
#     stores one register on the static heap (use with quickrestore)
#define quickstore global
    sw      %1 0($gp)           # save %1 at the current $gp location
    addu    $gp $gp 4           # increment $gp by 4
#end

# quickrestore dst
#     dst : the destination you want the restored value placed
#     restores one register from the static heap (use with quickstore)
#define quickrestore global
    subu    $gp $gp 4           # decrement $gp by 4
    lw      %1 0($gp)           # save %1 at the current $gp location
#end

# sbrk_imm amt dst
#     amt : the amount of memory you want, must be an immediate value
#define sbrk_imm global
    __save_args
    li      $v0 9               # system call code for sbrk
    addi    $a0 $0 %1           # amount
    syscall                     # make the call
    quickstore $v0
    __restore_args
    quickrestore %2
#end

# sbrk_addr addr dst
#     addr : location in memory whos value equals the amount of memory you 
#            want to allocate
#define sbrk_addr global
    __save_args
    li      $v0 9               # system call code for sbrk
    lw      $a0 %1              # amount
    syscall                     # make the call
    quickstore $v0
    __restore_args
    quickrestore %2
#end

# sbrk reg dst
#     reg : stored in the reg should be the amount of memory you want to allocate
#define sbrk global
    quickstore %1
    __save_args
    quickrestore %1
    li      $v0 9               # system call code for sbrk
    add     $a0 %1 $0           # amount
    syscall                     # make the call
    quickstore $v0
    __restore_args
    quickrestore %2
#end


#define exit global
    li      $v0, 10             # syscall code 10 is for exit.
    syscall                     # make the syscall.
#end


#define wait global
    la      $k0 wait_return
    subu    $k0 $k0 4
    mtc0    $k0 $14
    la      $k0 exception_handler
    jr      $k0
wait_return:
#end

#define disable_interrupts global
    mfc0    $t0 $12             # load the status register
    lui     $t1 0xffff
    ori     $t1 0xfffc
    and     $t0 $t0 $t1         # enable the interrupts
    mtc0    $t0 $12             # push the changes back to the co-proc
    nop
    nop
#end

#define enable_interrupts global
    mfc0    $t0, $12            # load the status register
    lui     $t1 0xffff
    ori     $t1 0xfffd
    and     $t0 $t0 $t1         # enable the interrupts
    ori     $t0, $t0, 0x1       # set exception level to 0 this re-enables interrupts
    mtc0    $t0, $12            # push the changes back to the co-proc
    nop
    nop
#end

#define enable_clock_interrupt global
    mfc0    $t0, $9             # get the current clock value
    add     $t0, $t0, 1         # add 1
    mtc0    $t0, $11            # push to compare
#end

