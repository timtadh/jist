# Tim Henderson
# start.s - header for user programs

#include stdlib.s
    .text
init_kernel:
{
    @hcb_addr = $s0
    sbrk_imm 4096 @hcb_addr
    li $a1 1024
    add $a0 @hcb_addr $zero
    call initialize_heap
    
    li $a0 16
    addu $a1 @hcb_addr $zero
    call alloc
    
    @khcb_addr_loc = $s2
    la  @khcb_addr_loc  KHCB_ADDR
    sw  @hcb_addr_loc   0(@khcb_addr)
    
    return
}
    .text
    .globl __start

__start:
#     enable_interrupts
#     enable_clock_interrupt
#     load_user_programs
#     la      $s0  user_program_locations
#     lw      $t0  0($s0)
#     add     $a0  $t0  $0
#     call    load_process
#     load_user_programs
#     la      $s0  user_program_locations
#     lw      $s1  4($s0)
    
    exec init_kernel
    
    #sneaky kernel macros:
    load_user_programs
    load_first_program
    jr      $s1
    
    #la      $s0  user_program_locations
    #lw      $s1  12($s0)
#     
#     disable_clock_interrupt
#     enable_clock_interrupt
    exit
#     j       $s1                 # start main program
    
