# Tim Henderson
# start.s - header for user programs

#include proc_manager.s
#include stdlib.s

    .kdata
__msg: .asciiz "\nmy procedure\n"

    .ktext
proc:
    load_arg 1 $a0
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
    
    mfc0    $t0, $12            # load the status register
    ori     $t0, $t0, 0x1       # enable the interrupts
    mtc0    $t0, $12            # push the changes back to the co-proc
    
#     mfc0    $t0, $9             # get the current clock value
#     add     $t0, $t0, 1         # add 2
#     mtc0    $t0, $11            # push to compare

{
    .kdata
empty: .asciiz ""
    .ktext
    la      $a0 print
    call    print_hex
    la      $a0 empty
    call    println
}
    
    #call    print_hex
    
    wait
    
    
    load_user_programs
    la      $t0  user_program_locations
    lw      $a0  12($t0)
    #call    print_hex
    
    
    la      $t0  user_program_locations
    lw      $t0  12($t0)
    j       $t0                 # start main program
    
