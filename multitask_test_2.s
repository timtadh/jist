#include stdlib.s

.data
format_str: .asciiz "                            Process 2 count: "

.text
print_test:
{
    #stackprint
    addu $s0 $a0 $zero
    la $a0 format_str
    call print
    addu $a0 $s0 $zero
    call print_int
    li $a0 10
    call print_char
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
        
#         sem_wait
        addu $a0 @loopvar $zero
        call print_test
        addi @loopvar @loopvar 1
        
        #stackprint
        wait
#         sem_signal
        
        li $a0 10
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
