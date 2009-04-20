
#include stdlib.s
    .globl main
    .data
msg_str: .asciiz "adder entered"
    .text
main:
{
    @addr = $s0
    @end = $t1
    @amt = $s1
    
    sbrk_imm   1024 @addr 
    addu    @end @addr 1024
    subu    @end @end @addr
    sra     @end @end 2
    addu    $a0 @addr $0
    addu    $a1 @end $0
    call    initialize_heap
    println_hex msg @addr
    
    addu    @amt $0 4
#     sw      @amt 16(@addr) #hack to check last word is moved
    print_hcb @addr
    
    addu    $a0 @amt $0
    addu    $a1 @addr $0
    call    move_hcb_up
    addu    @addr $v0 $0
    
    print_hcb @addr
    
    exit
    .data
    msg: .asciiz "addr = "
    .text
}
#     addu    $s0 $0 4
#     addu    $a0 $s0 $0
#     call    alloc   #$s0 $s1
#     addu    $s1 $v0 $0
#     call print_hcb
#     exit
# end of add2.asm.
