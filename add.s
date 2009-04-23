
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
    @mem_id0 = $s2
    @mem_id1 = $s3
    @mem_id2 = $s4
    @loc = $s5
    @index = $t2
    @val = $s6
    @err = $t4
    
    
    li      $v0 9               # system call code for sbrk
    addi    $a0 $0 0x400        # amount
    syscall                     # make the call
    addu    @addr $v0 $0
    addu    $a0 @addr $0
    addu    $a1 $0    0x100
    call    initialize_heap
    println_hex addr_msg @addr
    
    
    enable_interrupts
    enable_clock_interrupt
    
    addu    @amt $0 4
#     sw      @amt 16(@addr) #hack to check last word is moved
    print_hcb @addr
    
    enable_clock_interrupt
    
    addu    $a0 @amt $0
    addu    $a1 @addr $0
    call    alloc
    addu    @mem_id0 $v0 $0
    addu    @addr $v1 $0
    
    print_hcb @addr
    enable_clock_interrupt
    enable_clock_interrupt
    
    addu    @amt $0 17
#     alloc(amt, addr) --> $v0 = mem_id, $v1 = hcb_addr
    addu    $a0 @amt $0
    addu    $a1 @addr $0
    call    alloc
    addu    @mem_id1 $v0 $0
    addu    @addr $v1 $0
    
    print_hcb @addr
    
    enable_clock_interrupt
    enable_clock_interrupt
    
    addu    @amt $0 14
    
    addu    $a0 @amt $0
    addu    $a1 @addr $0
    call    alloc
    addu    @mem_id2 $v0 $0
    addu    @addr $v1 $0
    
    print_hcb @addr
    
    addu    @val $0 0x14
    addu    @loc $0 $0
    put @loc @mem_id0 @addr @val @err
    get @loc @mem_id0 @addr @val @err
    println_hex val_msg $s6
    
    addu    @val $0 0x15
    addu    @loc $0 0x1
    put @loc @mem_id0 @addr @val @err
    get @loc @mem_id0 @addr @val @err
    println_hex val_msg @val
    
    addu    @loc $0 $0
    get @loc @mem_id0 @addr @val @err
    println_hex val_msg @val
    
    addu    @val $0 0x17
    addu    @loc $0 0x3
    put @loc @mem_id1 @addr @val @err
    get @loc @mem_id1 @addr @val @err
    println_hex val_msg @val
    
    {
        addu    $a0 @mem_id0 $0
        addu    $a1 @addr $0
        call    free
        addu    @addr $v0 $0
        
        print_hcb @addr
    }
    addu    @loc $0 $0
    get @loc @mem_id0 @addr @val @err
    println_hex val_msg @val
    {
        addu    $a0 @mem_id2 $0
        addu    $a1 @addr $0
        call    free
        addu    @addr $v0 $0
        
        print_hcb @addr
    }
#     
    {
        addu    $a0 @mem_id1 $0
        addu    $a1 @addr $0
        call    free
        addu    @addr $v0 $0
        
        print_hcb @addr
    }
    
    addu    @amt $0 7
#     sw      @amt 16(@addr) #hack to check last word is moved
    print_hcb @addr
    
    
    addu    $a0 @amt $0
    addu    $a1 @addr $0
    call    alloc
    addu    @mem_id0 $v0 $0
    addu    @addr $v1 $0
    
    print_hcb @addr
    
    
    addu    @amt $0 19
#     alloc(amt, addr) --> $v0 = mem_id, $v1 = hcb_addr
    addu    $a0 @amt $0
    addu    $a1 @addr $0
    call    alloc
    addu    @mem_id1 $v0 $0
    addu    @addr $v1 $0
    
    print_hcb @addr
    
    
    addu    @amt $0 11
    
    addu    $a0 @amt $0
    addu    $a1 @addr $0
    call    alloc
    addu    @mem_id2 $v0 $0
    addu    @addr $v1 $0
    
    print_hcb @addr
    
    addu    @val $0 0x14
    addu    @loc $0 $0
    put @loc @mem_id1 @addr @val @err
    get @loc @mem_id1 @addr @val @err
    println_hex val_msg $s6
    
    addu    @val $0 0x1123
    addu    @loc $0 0x1
    put @loc @mem_id2 @addr @val @err
    get @loc @mem_id2 @addr @val @err
    println_hex val_msg @val
    
    addu    @loc $0 $0
    get @loc @mem_id1 @addr @val @err
    println_hex val_msg @val
    
    addu    @val $0 0x17
    addu    @loc $0 0x3
    put @loc @mem_id1 @addr @val @err
    get @loc @mem_id1 @addr @val @err
    println_hex val_msg @val
    
    {
        addu    $a0 @mem_id0 $0
        addu    $a1 @addr $0
        call    free
        addu    @addr $v0 $0
        
        print_hcb @addr
    }
    addu    @loc $0 $0
    get @loc @mem_id0 @addr @val @err
    println_hex val_msg @val
    {
        addu    $a0 @mem_id2 $0
        addu    $a1 @addr $0
        call    free
        addu    @addr $v0 $0
        
        print_hcb @addr
    }
    
    addu    @amt $0 11
    
    addu    $a0 @amt $0
    addu    $a1 @addr $0
    call    alloc
    addu    @mem_id2 $v0 $0
    addu    @addr $v1 $0
    
    print_hcb @addr
#     
    {
        addu    $a0 @mem_id1 $0
        addu    $a1 @addr $0
        call    free
        addu    @addr $v0 $0
        
        print_hcb @addr
    }
    
    
    addu    @val $0 0x1123
    addu    @loc $0 0x1
    put @loc @mem_id2 @addr @val @err
    get @loc @mem_id2 @addr @val @err
    println_hex val_msg @val
    
    {
        addu    $a0 @mem_id2 $0
        addu    $a1 @addr $0
        call    free
        addu    @addr $v0 $0
        
        print_hcb @addr
    }
    
#     print_hcb @addr
#     
#     addu    @index $0 1
#     {
#         @item_addr = $t3
#         @err = $t4
#         addu    $a0 @index $0
#         addu    $a1 @addr $0
#         call    get_hcb_item
#         addu    @item_addr $v0 $0
#         addu    @err $v1 $0
#         
#         bne     @err $0 error
#         addu    $a0 @item_addr $0
#         call    print_hcb_item
#         j       endblock
#         error:
#             println error_msg
#     endblock:
#     }
#     
#     
# #     del_hcb_item(index, addr) --> $v0 = error
#     addu    @index $0 2
#     {
#         @err = $t4
#         addu    $a0 @index $0
#         addu    $a1 @addr $0
#         call    del_hcb_item
#         addu    @err $v0 $0
#         println_hex err_equal_msg @err
#     }
#     
#     print_hcb @addr
    
    exit
    .data
    addr_msg: .asciiz "addr = "
    error_msg: .asciiz "error"
    err_equal_msg: .asciiz " error = "
    found_msg: .asciiz " found = "
    index_msg: .asciiz " index = "
    mem_id_msg: .asciiz " mem_id = "
    val_msg: .asciiz " val = "
    .text
}
#     addu    $s0 $0 4
#     addu    $a0 $s0 $0
#     call    alloc   #$s0 $s1
#     addu    $s1 $v0 $0
#     call print_hcb
#     exit
# end of add2.asm.
