# Tim Henderson
# interrupt handler

    .kdata
__save_gp:  .word 0
__save_sp:  .word 0
__save_fp:  .word 0
__save_ra:  .word 0

    .ktext
save_state:
    sw      $gp __save_gp       # save the pointer registers
    sw      $sp __save_sp
    sw      $fp __save_fp
    sw      $ra __save_ra
    
    subu    $sp $sp 32          # move sp to the end of the kernel frame
    addu    $fp $sp 32          # point the frame pointer to the top of frame
    sw      $t0 0($fp)          # save $t0 - $t3
    sw      $t1 4($fp)
    sw      $t2 8($fp)
    sw      $t3 12($fp)
    sw      $s0 16($fp)         # save $s0 - $s3
    sw      $s1 20($fp)
    sw      $s2 24($fp)
    sw      $s3 28($fp)
    
    j       save_state_return
    
restore_state:
    lw      $t0 0($fp)          # restore $t0 - $t3
    lw      $t1 4($fp)
    lw      $t2 8($fp)
    lw      $t3 12($fp)
    lw      $s0 16($fp)         # restore $s0 - $s3
    lw      $s1 20($fp)
    lw      $s2 24($fp)
    lw      $s3 28($fp)
    
    lw      $gp __save_gp       # load the pointer registers
    lw      $sp __save_sp
    lw      $fp __save_fp
    lw      $ra __save_ra
    
    j       restore_state_return

    .kdata
__int_msg: .asciiz "interrupt handler entered\n"

    .ktext
interrupt_handler:
    la      $a0, __int_msg      # load the addr of exception_msg into $a0.
    li      $v0, 4              # 4 is the print_string syscall.
    syscall                     # do the syscall.
    j       save_state
save_state_return:
    j       restore_state
restore_state_return:
    j       interrupt_return