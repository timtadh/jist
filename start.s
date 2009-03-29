# Tim Henderson
# start.s - header for user programs

#include proc_manager.s
#include stdlib.s

    .kdata
__msg: .asciiz "\nmy procedure\n"

    .ktext
proc:
    load_arg 3 $a0
    #li      $a0 15
    li       $v0 1
    syscall
    
    la      $a0, __msg          # load the addr of hello_msg into $a0.
    li      $v0, 4              # 4 is the print_string syscall.
    #syscall
    return
    
    .globl __start
__start:
    #add     $fp $sp $0
    li      $t0 5
    store_arg $t0
    li      $t0 13
    store_arg $t0
    li      $t0 15
    store_arg $t0
    call    proc
    
    la      $a0 __msg
    li      $v0, 4              # 4 is the print_string syscall.
    syscall
    
   # enable_interrupts
    #enable_clock_interrupt
{
    .kdata
empty: .asciiz ""
    .ktext
    la      $a0 print
    call    print_hex
    la      $a0 empty
    call    println
}
    la      $t0 kernel_data
    la      $t1 kernel_data_end
    subu    $t1 $t1 $t0
    sra     $t1 $t1 2
    initialize_heap $t0 $t1
    addu    $t0 $0 4
    alloc   $t0 $t0
    #free    $t0
    #call    print_hex
    #call    proc
    #wait
    #wait
    la      $a0, __msg          # load the addr of hello_msg into $a0.
    li      $v0, 4              # 4 is the print_string syscall.
    syscall
{
    disable_interrupts
    lui     $t1 0xffff
    ori     $t1 0xffff          # initialize loop counter
loop:
    addi    $t1, $t1, -1        # decrement every loop
    bgez    $t1, loop           # if $t1 > 0: jump loop
    enable_interrupts
}
    la      $a0, __msg          # load the addr of hello_msg into $a0.
    li      $v0, 4              # 4 is the print_string syscall.
    syscall
    load_user_programs
    la      $t0  user_program_locations
    lw      $t0  0($t0)
    add     $a0  $t0  $0
    call    load_process
    la      $t0  user_program_locations
    lw      $t0  0($t0)
    
    enable_clock_interrupt
    j       $t0                 # start main program
    
