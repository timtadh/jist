# Tim Henderson
# start.s - header for user programs

#include stdlib.s

# KERNEL STATIC HEAP DATA mem_id = 0
# -----------------------------------------
# | loc | data                            |
# -----------------------------------------
# |   0 | next pid                        |
# -----------------------------------------
# | ... | ....                            |
# -----------------------------------------

    .text
init_kernel:
{
    @hcb_addr = $s0
    @khcb_addr_loc = $s1
    @mem_id = $s2
    @loc = $t0
    @err = $t1
    
    sbrk_imm 4096 @hcb_addr
    li      $a1 1024
    add     $a0 @hcb_addr $zero
    call    initialize_heap
    
    addu    $a0 $0 0x10
    addu    $a1 @hcb_addr $zero
    call    alloc
    addu    @mem_id $v0 $zero
    addu    @hcb_addr $v1 $zero
    
    khcb_writeback @hcb_addr
    
    addu    @loc $0 $0
    put     @loc @mem_id @hcb_addr $0 @err
    
    addu    $v0 @mem_id $zero
    
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
    
