
# save_stack(sp) --> $v0 = mem_id
save_stack:
{
    @stackheap = $s0
    @stack_top = $s1
    @curaddr = $s2
    @count = $s3
    @amt = $s4
    @mem_id = $s5
    @hcb_addr = $s6
    @sp = $s7
    
    @loc = $t0
    @err = $t1
    
    addu    @sp $a0 $0
    
    {
        khcb_getaddr @hcb_addr
        
        addu    @loc $0 0x3
        get     @loc $0 @hcb_addr @stackheap @err
        bne     @err $0 stack_addr_error
        
        
        addu    @loc $0 0x4
        get     @loc $0 @hcb_addr @stack_top @err
        bne     @err $0 stack_top_error
    }
    
    
    subu    @amt @stack_top @sp
    srl     @amt @amt 2             #div @amt by 4
    
    println_hex amt_msg @amt
    println_hex stacktop_msg @stack_top
    println_hex sp_msg @sp
    
    addu    $a0 @amt $0
    addu    $a1 @stackheap $0
    call    alloc
    addu    @mem_id $v0 $0
    addu    @stackheap $v1 $0
    
    {
        khcb_getaddr @hcb_addr
        
        addu    @loc $0 0x3
        put     @loc $0 @hcb_addr @stackheap @err
        bne     @err $0 stack_addr_error
    }
    
    addu    @curaddr @stack_top $0
    subu    @count @amt 0x1
    println_hex sp_msg @sp
    println_hex curaddr_msg @curaddr
    println_hex count_msg @count
    {
    loop:
        bge     @sp @curaddr endloop
        {
            @temp = $t0
            @err = $t1
            @pr_temp = $s4
            
#             println_hex sp_msg @sp
#             println_hex curaddr_msg @curaddr
#             println_hex count_msg @count
#             println_hex s4_msg @pr_temp
            
            lw      @temp 0(@curaddr)
            addu    @pr_temp @temp $0
            put     @count @mem_id @stackheap @temp @err
            bne     @err $0 stack_save_error
            
            
            subu    @curaddr @curaddr 0x4
            subu    @count @count 0x1
        }
        j   loop
    endloop:
    }
    
    addu    $v0 @mem_id $0
    return
    
    stack_addr_error:
        println stack_addr_error_msg
        return
    stack_top_error:
        println stack_addr_error_msg
        return
    stack_save_error:
        println stack_save_error_msg
        return
    
    .data
    stack_addr_error_msg: .asciiz "get stackheap address failed in save_stack"
    stack_top_error_msg: .asciiz "get stack top address failed in save_stack"
    stack_save_error_msg: .asciiz "saving the stack failed"
    s4_msg: .asciiz " stackspot = "
    count_msg: .asciiz " count = "
    curaddr_msg: .asciiz " curaddr = "
    sp_msg: .asciiz "\n sp = "
    amt_msg: .asciiz " amt = "
    stacktop_msg: .asciiz " stacktop = "
    .text
}

# restore_stack(mem_id, sp) --> Null
restore_stack:
{
    @stackheap = $s0
    @stack_top = $s1
    @curaddr = $s2
    @count = $s3
    @amt = $s4
    @mem_id = $s5
    @hcb_addr = $s6
    @sp = $s7
    @loc = $t0
    @err = $t1
    
    addu    @mem_id $a0 $0
    addu    @sp $a1 $0
    
    {
        khcb_getaddr @hcb_addr
        
        addu    @loc $0 0x3
        get     @loc $0 @hcb_addr @stackheap @err
        bne     @err $0 stack_addr_error
        
        
        addu    @loc $0 0x4
        get     @loc $0 @hcb_addr @stack_top @err
        bne     @err $0 stack_top_error
        
    }
    
    println_hex mem_id_msg @mem_id
    print_hcb @stackheap
    
    blocksize @mem_id @stackheap @amt @err
    bne     @err $0 stack_top_error
    
    addu    @curaddr @stack_top $0
    subu    @count @amt 0x1
    println_hex sp_msg @sp
    println_hex curaddr_msg @curaddr
    println_hex count_msg @count
    {
    loop:
        bge     @sp @curaddr endloop
        {
            @temp = $t0
            @err = $t1
            @pr_temp = $s4
            
#             println_hex sp_msg @sp
#             println_hex curaddr_msg @curaddr
#             println_hex count_msg @count
#             println_hex s4_msg @pr_temp
            
            get     @count @mem_id @stackheap @temp @err
            bne     @err $0 stack_save_error
            sw      @temp 0(@curaddr)
            addu    @pr_temp @temp $0
            
            subu    @curaddr @curaddr 0x4
            subu    @count @count 0x1
        }
        j   loop
    endloop:
    }
    
    addu    $a0 @mem_id $0
    addu    $a1 @stackheap $0
    call    free
    addu    @stackheap $v0 $0
    
    {
        khcb_getaddr @hcb_addr
        
        addu    @loc $0 0x3
        put     @loc $0 @hcb_addr @stackheap @err
        bne     @err $0 stack_addr_error
    }
    
    print_hcb @stackheap
    
    return
    
    stack_addr_error:
        println stack_addr_error_msg
        return
    stack_top_error:
        println stack_addr_error_msg
        return
    stack_save_error:
        println stack_save_error_msg
        return
    
    .data
    stack_addr_error_msg: .asciiz "get stackheap address failed in restore_stack"
    stack_top_error_msg: .asciiz "get stack top address failed in restore_stack"
    stack_save_error_msg: .asciiz "restoring the stack failed"
    s4_msg: .asciiz " stackspot = "
    count_msg: .asciiz " count = "
    curaddr_msg: .asciiz " curaddr = "
    sp_msg: .asciiz "\n sp = "
    amt_msg: .asciiz " amt = "
    stacktop_msg: .asciiz " stacktop = "
    hcb_msg: .asciiz " hcb_addr = "
    mem_id_msg: .asciiz " mem_id = "
    .text
}

