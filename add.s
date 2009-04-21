
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
    @index = $t2
    
    sbrk_imm   1024 @addr 
    addu    @end @addr 1024
    subu    @end @end @addr
    sra     @end @end 2
    addu    $a0 @addr $0
    addu    $a1 @end $0
    call    initialize_heap
    println_hex addr_msg @addr
    
    addu    @amt $0 4
#     sw      @amt 16(@addr) #hack to check last word is moved
    print_hcb @addr
    
    
    addu    $a0 @amt $0
    addu    $a1 @addr $0
    call    alloc
    addu    @mem_id0 $v0 $0
    addu    @addr $v1 $0
    
    print_hcb @addr
    
    
#     alloc(amt, addr) --> $v0 = mem_id, $v1 = hcb_addr
    addu    $a0 @amt $0
    addu    $a1 @addr $0
    call    alloc
    addu    @mem_id1 $v0 $0
    addu    @addr $v1 $0
    
    print_hcb @addr
    
    addu    $a0 @amt $0
    addu    $a1 @addr $0
    call    alloc
    addu    @mem_id2 $v0 $0
    addu    @addr $v1 $0
    
    print_hcb @addr
    
    {
        @found = $s5
        @index = $s6
        @item_addr = $s1
        @hole_size = $t3
        @hole_addr = $t5
        @err = $t4
        @mem_id = @mem_id1
        
        println_hex mem_id_msg @mem_id
        addu $a0 @mem_id $0
        addu $a1 @addr $0
        call find_index
        addu @found $v0 $0
        addu @index $v1 $0
        
        println_hex found_msg @found
        println_hex index_msg @index
        
        addu    $a0 @index $0
        addu    $a1 @addr $0
        call    get_hcb_item
        addu    @item_addr $v0 $0
        addu    @err $v1 $0
        println_hex err_equal_msg @err
        
        addu    $a0 @item_addr $0
        call    print_hcb_item
        
        lw      @hole_addr 4(@item_addr)
        lw      @hole_size 8(@item_addr)
        
        addu    $a0 @mem_id $0
        addu    $a1 @hole_addr $0
        addu    $a2 @hole_size $0
        addu    $a3 @addr $0
        call    compact
        addu    @addr $v0 $0
        
        addu    $a0 @index $0
        addu    $a1 @addr $0
#         call    del_hcb_item
        addu    @err $v0 $0
        println_hex err_equal_msg @err
        
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
    .text
}
#     addu    $s0 $0 4
#     addu    $a0 $s0 $0
#     call    alloc   #$s0 $s1
#     addu    $s1 $v0 $0
#     call print_hcb
#     exit
# end of add2.asm.
