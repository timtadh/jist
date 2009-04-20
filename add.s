
#include stdlib.s
    .globl main
    .data
msg_str: .asciiz "adder entered"
    .text
main:
    sbrk_imm   1024 $t0 
    addu    $t1 $t0 1024
    subu    $t1 $t1 $t0
    sra     $t1 $t1 2
    addu    $a0 $t0 $0
    addu    $a1 $t1 $0
    call    initialize_heap
    
    call    print_hcb
    call    print_hcb
    addu    $s0 $0 4
    addu    $a0 $s0 $0
    call    alloc   #$s0 $s1
    addu    $s1 $v0 $0
    call print_hcb
    exit
# end of add2.asm.
