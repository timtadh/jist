# Tim Henderson
# interrupt handler

# #     .globl __save_gp
# #     .globl __save_sp
# #     .globl __save_fp
# #     .globl __save_ra
# #     .globl __save_t0
# #     .globl __save_t1
# #     .globl __save_t2
# #     .globl __save_t3
# #     .globl __save_s0
# #     .globl __save_s1
# #     .globl __save_s2
# #     .globl __save_s3
    .kdata
__save_gp:  .word 0
__save_sp:  .word 0
__save_fp:  .word 0
__save_ra:  .word 0
__save_t0:  .word 0
__save_t1:  .word 0
__save_t2:  .word 0
__save_t3:  .word 0
__save_s0:  .word 0
__save_s1:  .word 0
__save_s2:  .word 0
__save_s3:  .word 0
__save_HCB_ADDR: .word 0

__k_HCB_ADDR: .word 0


    .ktext
save_state:
{
    sw      $gp __save_gp       # save the pointer registers
    sw      $sp __save_sp
    sw      $fp __save_fp
    sw      $ra __save_ra
    
    sw      $t0 __save_t0       # save $t0 - $t3
    sw      $t1 __save_t1
    sw      $t2 __save_t2
    sw      $t3 __save_t3
    sw      $s0 __save_s0       # save $s0 - $s3
    sw      $s1 __save_s1
    sw      $s2 __save_s2
    sw      $s3 __save_s3
    
    #load kernel heap address
    lw      $t0 HCB_ADDR
    sw      $t0 __save_HCB_ADDR
    lw      $t0 __k_HCB_ADDR
    sw      $t0 HCB_ADDR
    
    j       save_state_return
}
    
restore_state:
{
    #load user heap address
    lw      $t0 HCB_ADDR
    sw      $t0 __k_HCB_ADDR
    lw      $t0 __save_HCB_ADDR
    sw      $t0 HCB_ADDR

    sw      $t0 __save_t0       # load $t0 - $t3
    sw      $t1 __save_t1
    sw      $t2 __save_t2
    sw      $t3 __save_t3
    sw      $s0 __save_s0       # load $s0 - $s3
    sw      $s1 __save_s1
    sw      $s2 __save_s2
    sw      $s3 __save_s3
    
    lw      $gp __save_gp       # load the pointer registers
    lw      $sp __save_sp
    lw      $fp __save_fp
    lw      $ra __save_ra
    
    j       restore_state_return
}

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