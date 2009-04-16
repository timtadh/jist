# Tim Henderson
# start.s - header for user programs

#include stdlib.s

    .data
__msg: .asciiz "\nmy procedure\n"

    .text
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
    
    
#     enable_interrupts
#     enable_clock_interrupt
#     load_user_programs
#     la      $s0  user_program_locations
#     lw      $t0  0($s0)
#     add     $a0  $t0  $0
#     call    load_process
    load_user_programs
    la      $s0  user_program_locations
    lw      $s1  0($s0)
#     jr      $s1
#     
#     disable_clock_interrupt
#     enable_clock_interrupt
    exit
#     j       $s1                 # start main program
    
