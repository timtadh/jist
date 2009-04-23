# Tim Henderson
# start.s - header for user programs

#include stdlib.s

# KERNEL STATIC HEAP DATA mem_id = 0
# -----------------------------------------
# | loc | data                            |
# -----------------------------------------
# |   0 | next pid                        |
# -----------------------------------------
# |   1 | context_mgr linked list         |
# -----------------------------------------
# |   2 | current PID                     |
# -----------------------------------------
# |   3 | stack heap                      |
# -----------------------------------------
# |   4 | original sp                     |
# -----------------------------------------

    .text
init_kernel:
{
    @hcb_addr = $s0
    @khcb_addr_loc = $s1
    @mem_id = $s2
    @loc = $t0
    @err = $t1
    @temp = $t2
    
    @stack_hcb = $s3
    
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
    
    lui     @temp 0x0001
    sbrk    @temp @stack_hcb
    li      $a1 0x4000
    add     $a0 @stack_hcb $zero
    call    initialize_heap
    
    khcb_getaddr @hcb_addr
    
    addu    @loc $0 0x3
    put     @loc $0 @hcb_addr @stack_hcb @err
    addu    @loc $0 0x3
    get     @loc $0 @hcb_addr @stack_hcb @err
    
    println_hex stack_hcb_msg @stack_hcb
    
    addu    $v0 @mem_id $zero
    
    return
    .data
    stack_hcb_msg: .asciiz " stack_hcb = "
    .text
}
    .text
    .globl __start

__start:
{
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
    @loc = $t0 
    @sp = $s0
    @hcb_addr = $s1
    @err = $t1
    addu @sp $sp $0
#     lui     @sp 0x7fff
#     ori     @sp @sp 0xffff
    call init_kernel
    
    khcb_getaddr @hcb_addr
    
    addu    @loc $0 0x4
    put     @loc $0 @hcb_addr @sp @err
    addu    @loc $0 0x4
    get     @loc $0 @hcb_addr @sp @err
    
    println_hex stack_pointer_msg @sp
    
    call load_first_process
    call make_space_for_new_process
    
    #sneaky kernel macros:
#     load_user_programs
    
    disable_clock_interrupt
    #sneaky kernel macros:
    load_user_programs
    load_first_program
    jr      $s1
    
    
    #la      $s0  user_program_locations
    #lw      $s1  12($s0)
#     
#     enable_clock_interrupt
    exit
    .data
    stack_pointer_msg: .asciiz " sp = "
    .text
}
#     j       $s1                 # start main program
    
