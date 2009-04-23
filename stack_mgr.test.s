# Tim Henderson
# Test of the stack manager

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
    @loc = $t0
    @err = $t1
    
    addu    @mem_id $a0 $0
    
    {
        khcb_getaddr @hcb_addr
        
        addu    @loc $0 0x3
        get     @loc $0 @hcb_addr @stackheap @err
        bne     @err $0 stack_addr_error
        
        
        addu    @loc $0 0x4
        get     @loc $0 @hcb_addr @stack_top @err
        bne     @err $0 stack_top_error
    }
    
    addu    @curaddr @stack_top $0
    addu    @count $0 $0
    {
    loop:
        bge     @curaddr $sp endloop
        {
            @temp = $t0
            @err = $t1
            
            sw      $0 0(@curaddr)
            
            addu    @curaddr @curaddr 0x4
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
    stack_save_error_msg: .asciiz "restoring the stack failed"
    .text
}

.text
proc:
{
    @stack_id = $s0
    @loc = $t0
    @hcb_addr = $s1
    @stackheap = $s2
    @blocksize = $s3
    @err = $s4
    @sp = $s5
    
    # addu    @sp $sp $0
    # 
    # addu    $a0 @sp $0
    # call save_stack
    # addu @stack_id $v0 $0
    wait
    khcb_getaddr @hcb_addr
    
    addu    @loc $0 0x3
    get     @loc $0 @hcb_addr @stackheap @err
    
    print_hcb @stackheap
    
#     blocksize @stack_id @stackheap @blocksize @err
     
    # 
    # call    zero_stack
    # 
    # addu    $a0 @stack_id $0
    # addu    $a1 @sp $0
    # call    restore_stack
    # 
    # print_hcb @stackheap
        
    return
    .data
    error_msg: .asciiz "error = "
    blocksize_msg: .asciiz "blocksize = "
    .text
}

.text
temp:
{
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

