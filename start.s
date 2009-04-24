# Tim Henderson & Steve Johnson
# start.s is the entry point for the whole system

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
    
    #Allocate memory for the heap and pass it to initialize_heap
    sbrk_imm 4096 @hcb_addr
    li      $a1 1024
    add     $a0 @hcb_addr $zero
    call    initialize_heap
    
    #Allocate memory for kernel static space
    addu    $a0 $0 0x10
    addu    $a1 @hcb_addr $zero
    call    alloc
    addu    @mem_id $v0 $zero
    addu    @hcb_addr $v1 $zero
    khcb_writeback @hcb_addr
    
    #Set next_pid to zero
    puti    0 @mem_id @hcb_addr $0 @err
    
    #Initialize the stackheap
    lui     @temp 0x0001
    sbrk    @temp @stack_hcb
    li      $a1 0x4000
    add     $a0 @stack_hcb $zero
    call    initialize_heap
    khcb_getaddr @hcb_addr
    
    puti    3 $0 @hcb_addr @stack_hcb @err
    
    #geti    3 $0 @hcb_addr @stack_hcb @err
    #println_hex stack_hcb_msg @stack_hcb
    
    #return the mem_id of the static data block
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
    @loc = $t0 
    @sp = $s0
    @hcb_addr = $s1
    @err = $t1
    
    #init stack pointer and kernel data
    lui     @sp 0x7fff
    ori     @sp @sp 0xfffc
    call init_kernel
    
    #store the stack pointer in static kernel data
    khcb_getaddr @hcb_addr
    puti    4 $0 @hcb_addr @sp @err
    
    #addu    @loc $0 0x4
    #get     @loc $0 @hcb_addr @sp @err
    #println_hex stack_pointer_msg @sp
    
    #initialize space for first process
    call init_context_manager
    
    #sneaky kernel macros
    load_user_programs
    
    number_user_programs
    println_hex numprogs_msg $s1
    
    #start whatever program is in the jistfile
    load_first_program
    jr      $s1
    kill_jist
    
    .data
    stack_pointer_msg: .asciiz " sp = "
    numprogs_msg: .asciiz " num programs = "
    .text
}

