# Tim Henderson
# stack_mgr.s handles stack saving and loading

# getstackinfo khcb_addr stackheap stack_top tempreg errorlabel
#     khbc_addr = the address of the kernel static heap. Note it must be in an $s reg
#     stackheap = where you want to place the stackheap addr. Note it must be in an $s reg
#     stack_top = where you want to place the stack_top addr. Note it must be in an $s reg
#     tempreg = any temporary register you don't care about
#     errorlabel = label you want to jump to on error
#
#define getstackinfo
    @khcb_addr = %1
    @stackheap = %2
    @stack_top = %3
    @err = %4
    @errorlabel = %5
    
    geti    0x3 $0 @khcb_addr @stackheap @err
    bne     @err $0 @errorlabel
    
    geti    0x4 $0 @khcb_addr @stack_top @err
    bne     @err $0 @errorlabel
#end

# stackheap_writeback stackheap khbc_addr tempreg errorlabel
#     stackheap = where you want to place the stackheap addr. Note it must be in an $s reg
#     khbc_addr = the address of the kernel static heap. Note it must be in an $s reg
#     tempreg = any temporary register you don't care about
#     errorlabel = label you want to jump to on error
#     
#define stackheap_writeback
    @stackheap = %1
    @khcb_addr = %2
    @err = %3
    @errorlabel = %4
    
    puti    0x3 $0 @khcb_addr @stackheap @err
    bne     @err $0 stack_addr_error
#end

# stackheap_alloc stack_id amt stackheap khbc_addr tempreg errorlabel
#     stack_id = where you want to place the stack_id addr. Note it must be in an $s reg
#     amt = amount of memory you want to alloc
#     stackheap = where you want to place the stackheap addr. Note it must be in an $s reg
#     khbc_addr = the address of the kernel static heap. Note it must be in an $s reg
#     tempreg = any temporary register you don't care about
#     errorlabel = label you want to jump to on error
#
#define stackheap_alloc
    @stack_id = %1
    @amt = %2
    @stackheap = %3
    @khcb_addr = %4
    @err = %5
    @errorlabel = %6
    
    addu    $a0 @amt $0
    addu    $a1 @stackheap $0
    call    alloc
    addu    @stack_id $v0 $0
    addu    @stackheap $v1 $0
    
    stackheap_writeback @stackheap @khcb_addr @err @errorlabel
#end


# stackheap_free stack_id stackheap khbc_addr tempreg errorlabel
#     stack_id = where you want to place the stack_id addr. Note it must be in an $s reg
#     stackheap = where you want to place the stackheap addr. Note it must be in an $s reg
#     khbc_addr = the address of the kernel static heap. Note it must be in an $s reg
#     tempreg = any temporary register you don't care about
#     errorlabel = label you want to jump to on error
#
#define stackheap_free
    @stack_id = %1
    @stackheap = %2
    @khbc_addr = %3
    @err = %4
    @errorlabel = %5
    
    addu    $a0 @stack_id $0
    addu    $a1 @stackheap $0
    call    free
    addu    @stackheap $v0 $0
    
    stackheap_writeback @stackheap @khcb_addr @err @errorlabel
#end

# save_stack(sp) --> $v0 = mem_id
save_stack:
{
    @stackheap = $s0
    @stack_top = $s1
    @curaddr = $s2
    @count = $s3
    @amt = $s4
    @stack_id = $s5
    @khcb_addr = $s6
    @sp = $s7
    
    @loc = $t0
    @err = $t1
    
    addu    @sp $a0 $0
    
    khcb_getaddr @khcb_addr
    getstackinfo @khcb_addr @stackheap @stack_top @err stack_addr_error
    
    
    subu    @amt @stack_top @sp
    srl     @amt @amt 2             #div @amt by 4
    stackheap_alloc @stack_id @amt @stackheap @khcb_addr @err stack_alloc_error
    
#     println_hex amt_msg @amt
#     println_hex stacktop_msg @stack_top
#     println_hex sp_msg @sp
    
    
    addu    @curaddr @stack_top $0
    subu    @count @amt 0x1
#     println_hex sp_msg @sp
#     println_hex curaddr_msg @curaddr
#     println_hex count_msg @count
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
            put     @count @stack_id @stackheap @temp @err
            bne     @err $0 stack_save_error
            
            
            subu    @curaddr @curaddr 0x4
            subu    @count @count 0x1
        }
        j   loop
    endloop:
    }
    
    addu    $v0 @stack_id $0
    return
    
    stack_addr_error:
        println stack_addr_error_msg
        return
    stack_alloc_error:
        println stack_addr_error_msg
        return
    stack_save_error:
        println stack_save_error_msg
        return
    
    .data
    stack_addr_error_msg: .asciiz "get stackheap address failed in save_stack"
    stack_top_error_msg: .asciiz "writing the new stackheap address back failed. save_stack"
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
    @stack_id = $s5
    @khcb_addr = $s6
    @sp = $s7
    @loc = $t0
    @err = $t1
    
    addu    @stack_id $a0 $0
    addu    @sp $a1 $0
    
    khcb_getaddr @khcb_addr
    getstackinfo @khcb_addr @stackheap @stack_top @err stack_addr_error
    
    # println_hex mem_id_msg @stack_id
    # print_hcb @stackheap
    
    blocksize @stack_id @stackheap @amt @err
    bne     @err $0 blocksize_error
    
    addu    @curaddr @stack_top $0
    subu    @count @amt 0x1
#     println_hex sp_msg @sp
#     println_hex curaddr_msg @curaddr
#     println_hex count_msg @count
    {
    loop:
        bge     @sp @curaddr endloop
        {
            @temp = $t0
            @err = $t1
            @pr_temp = $s4
            
            # println_hex sp_msg @sp
            # println_hex curaddr_msg @curaddr
            # println_hex count_msg @count
            # println_hex s4_msg @pr_temp
            
            get     @count @stack_id @stackheap @temp @err
            bne     @err $0 stack_save_error
            sw      @temp 0(@curaddr)
            addu    @pr_temp @temp $0
            
            subu    @curaddr @curaddr 0x4
            subu    @count @count 0x1
        }
        j   loop
    endloop:
    }
    
    khcb_getaddr @khcb_addr
    stackheap_free @stack_id @stackheap @khcb_addr @err stack_alloc_error
#     print_hcb @stackheap
    
    return
    
    stack_addr_error:
        println stack_addr_error_msg
        return
    stack_alloc_error:
        println stack_alloc_error_msg
        return
    stack_save_error:
        println stack_save_error_msg
        return
    blocksize_error:
        println blocksize_error_msg
        return
    
    .data
    stack_addr_error_msg: .asciiz "get stackheap address failed in restore_stack"
    stack_alloc_error_msg: .asciiz "writing the new stackheap address back failed. restore_stack"
    stack_save_error_msg: .asciiz "restoring the stack failed"
    blocksize_error_msg: .asciiz "blocksize failed in restore_stack"
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


# save_stack(sp) --> $v0 = mem_id
zero_stack:
{
    @stackheap = $s0
    @stack_top = $s1
    @curaddr = $s2
    @count = $s3
    @amt = $s4
    @stack_id = $s5
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
            
            sw      $0 0(@curaddr)
            
            
            subu    @curaddr @curaddr 0x4
            subu    @count @count 0x1
        }
        j   loop
    endloop:
    }
    
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

