#include stdlib.s

.data
format_str: .asciiz "mt1: "
dbg_str_1: .asciiz "$fp: "
dbg_str_2: .asciiz "$sp: "

#define stackprint
    addu $s7 $fp $zero
    println_hex dbg_str_1 $s7
    addu $s7 $sp $zero
    println_hex dbg_str_2 $s7
#end

.text
print_test:
{
    #stackprint
    addu $s0 $a0 $zero
    println_hex format_str $s0
    return
}

.globl main
.text
main:
{
    @hcb_addr = $s0
    @loopvar = $s5
    
    li      $v0 9               # system call code for sbrk
    addi    $a0 $0 4096           # amount
    syscall                     # make the call
    addu    @hcb_addr $v0 $0
    li      $a1 1024
    addu    $a0 @hcb_addr $0
    call    initialize_heap
    
    addu    $a0 @hcb_addr $0
    call    putuserheap
    
    addu    @hcb_addr $0 $0
    println_hex hcb_msg @hcb_addr
    
    call    getuserheap
    addu    @hcb_addr $v0 $0
    println_hex hcb_msg @hcb_addr
    
    li @loopvar 0
    loop:
        
        #stackprint
        
        addu $a0 @loopvar $zero
        call print_test
        addi @loopvar @loopvar 1
        
        #stackprint
        wait
        
        li $a0 3
        beq @loopvar $a0 killme
    b loop
    
    killme:
    
    call    getuserheap
    addu    @hcb_addr $v0 $0
    println_hex hcb_msg @hcb_addr
    
    exit
    
    .data
        hcb_msg: .asciiz " hcb_addr = "
    .text
}
