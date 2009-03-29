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
    
    la      $t0 kernel_data
    la      $t1 kernel_data_end
    subu    $t1 $t1 $t0
    sra     $t1 $t1 2
    initialize_heap $t0 $t1
    addu    $s0 $0 4
    alloc   $s0 $s1
    alloc   $s0 $s2
    alloc   $s0 $s3
    alloc   $s0 $s4
    alloc   $s0 $s5
    free    $s1
    free    $s2
    free    $s3
    free    $s4
    free    $s5
    
    load_user_programs
    la      $s0  user_program_locations
    lw      $t0  0($s0)
    add     $a0  $t0  $0
    call    load_process
    la      $s0  user_program_locations
    lw      $s1  0($s0)
    
    disable_clock_interrupt
    enable_clock_interrupt
    j       $s1                 # start main program
    
