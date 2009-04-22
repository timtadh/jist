
.text
zero_stack:
{
    @stackheap = $s0
    @stack_top = $s1
    @curaddr = $s2
    @count = $s3
    @amt = $s4
    @mem_id = $s5
    @hcb_addr = $s6
    
    
    {
        @loc = $t0
        @err = $t1
        khcb_getaddr @hcb_addr
        
        addu    @loc $0 0x3
        get     @loc $0 @hcb_addr @stackheap @err
        bne     @err $0 stack_addr_error
        
        
        addu    @loc $0 0x4
        get     @loc $0 @hcb_addr @stack_top @err
        bne     @err $0 stack_top_error
    }
    
    {
        @loc = $t0
        @err = $t1
        
        khcb_getaddr @hcb_addr
        addu    @loc $0 0x3
        put     @loc $0 @hcb_addr @stackheap @err
        bne     @err $0 stack_addr_error
    }
    
    addu    @curaddr @stack_top $0
    addu    @count $0 $0
    {
    loop:
        bgt     $sp @curaddr endloop
        {
            @temp = $t0
            @err = $t1
            
#             sw      $0 0(@curaddr)
            
#             println_hex curaddr_msg @curaddr
#             println_hex sp_msg $sp
            
            subu    @curaddr @curaddr 0x4
            addu    @count @count 0x1
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
    curaddr_msg: .asciiz "curaddr = "
    sp_msg: .asciiz "sp = "
    .text
    return
}

.text
proc:
{
    @stack_id = $s0
    @loc = $t0
    @err = $t1
    @hcb_addr = $s1
    @stackheap = $s2
    call save_stack
    addu @stack_id $v0 $0
    
    khcb_getaddr @hcb_addr
    
    addu    @loc $0 0x3
    get     @loc $0 @hcb_addr @stackheap @err
    
    print_hcb @stackheap
    
    call    zero_stack
    
    addu    $a0 @stack_id $0
    call restore_stack
    
    print_hcb @stackheap
    
    call    zero_stack
    
    
    return
}

.text
temp:
{
    call    zero_stack 
    call proc
    return
}

    .globl main
    .text
main:
{
    call    temp
    println msg
    exit
    .data
    msg: .asciiz "end aowfiejwe"
    .text
}

