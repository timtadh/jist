.data
FAKE_KHCB_ADDR: .word 0

_quit_msg: .asciiz "All programs have exited. Closing jist."

.text
#define khcb_writeback_2
    @khcb_addr = $t0
    @val = %1
    la  @khcb_addr  FAKE_KHCB_ADDR
    sw  @val   0(@khcb_addr)
#end

#define khcb_getaddr_2
    @khcb_addr = $t0
    @hcb_addr = %1
    la  @khcb_addr  FAKE_KHCB_ADDR
    lw  @hcb_addr   0(@khcb_addr)
#end

.text
#format of a linked list:
#   @h: head: [process num][next address][pcb mem_id]


#define _new_ll_node local
    @khcb_addr = $s3
    khcb_getaddr_2 @khcb_addr
    li $a0 3
    addu $a1 @khcb_addr $zero
    call alloc
    addu    %1 $v0 $zero
    addu    @khcb_addr $v1 $zero
    khcb_writeback_2 @khcb_addr
#end

#ll_init(initial_pid, initial_pcb)
    .text
ll_init:
{
    @initval    = $s1
    @initpcb    = $s2
    @khcb_addr  = $s3
    @h          = $s4
    @err        = $s5
    add @initval $a0 $zero
    add @initpcb $a1 $zero
    
    _new_ll_node @h
    
    khcb_getaddr_2 @khcb_addr
    puti 0 @h @khcb_addr $zero @err
    puti 1 @h @khcb_addr @initval @err
    puti 2 @h @khcb_addr @initpcb @err
    
    add $v0 @h $zero
    return
}

.text
#ll_append(some_node, new_pid, new_pcb_mem_id)
ll_append:
{
    @size = $s0
    @new = $s1
    @newval = $s2
    @khcb_addr = $s3
    @nextnode = $s4
    @newpcb = $s5
    @thisnode = $s6
    @err = $s7
    
    add @thisnode $a0 $zero
    add @newval $a1 $zero
    add @newpcb $a2 $zero
    
    _new_ll_node @new
    
    khcb_getaddr_2 @khcb_addr
    geti 0 @thisnode @khcb_addr @nextnode @err
    loop:
        beqz @nextnode found_end
        addu @thisnode @nextnode $zero
        geti 0 @thisnode @khcb_addr @nextnode @err
        khcb_getaddr_2 @khcb_addr
        b loop
    found_end:
    
    khcb_getaddr_2 @khcb_addr
    puti 0 @thisnode @khcb_addr @new @err
    puti 0 @new @khcb_addr $zero @err
    puti 1 @new @khcb_addr @newval @err
    puti 2 @new @khcb_addr @newpcb @err
    
    add $v0 @new $zero
    return
}
.text
#ll_next(list_head, current_node)
#   v0 = mem_id
ll_next:    #@h @current
{
    @head = $s0
    @current = $s1
    @khcb_addr = $s2
    @err = $s3
    
    add @head $a0 $zero
    add @current $a1 $zero
    
    khcb_getaddr_2 @khcb_addr
    geti 0 @current @khcb_addr $v0 @err
    beqz $v0 return_head
        return
    return_head:
        addu $v0 @head $zero
    return
}

.text
#ll_remove(list_head, to_remove)
ll_remove:
{
    @head = $s0
    @to_remove = $s1
    @khcb_addr = $s2
    @err = $s3
    @next = $s4
    @temp = $s5
    
    add @head $a0 $zero
    add @to_remove $a1 $zero
    
    beq @head @to_remove head_case
    
    khcb_getaddr_2 @khcb_addr
    geti 0 @head @khcb_addr @temp @err
    beqz @temp tail_case
    
    loop:
        beqz @head found_end
        geti 0 @head @khcb_addr @next @err
        
        bne @next @to_remove not_found_yet
            geti 0 @to_remove @khcb_addr @temp @err
            puti 0 @head @khcb_addr @temp @err
            
            addu $a0 @to_remove $zero
            addu $a1 @khcb_addr $zero
            call free
            addu @temp $v0 $zero
            khcb_writeback_2 @temp
            addu $v0 @head $zero
            return
        not_found_yet:
            addu @head @next $zero
            b loop
    
    head_case:
    geti 0 @head @khcb_addr @temp @err
    beqz @temp head_only
    addu @head @temp $zero
    
    addu $a0 @to_remove $zero
    addu $a1 @khcb_addr $zero
    call free
    addu @temp $v0 $zero
    khcb_writeback_2 @temp
    addu $v0 @head $zero
    return
    
    head_only:
    la $a0 _quit_msg
    call println
    li $v0 10
    syscall
    
    tail_case:
    
    found_end:
    li $v0 10
    syscall     #DIE DIE DIE
    return
}

.text
ll_print:
{
    @mem_id = $s0
    @val = $s1
    @khcb_addr = $s2
    @err = $s3
    add @mem_id $a0 $zero
    
    print_again:
        beqz @mem_id done_printing
        khcb_getaddr_2 @khcb_addr
        
        addu $a0 @mem_id $zero
        call print_int
        li $a0 32
        call print_char
        
        geti 0 @mem_id @khcb_addr $a0 @err
        call print_int
        li $a0 32
        call print_char
        
        geti 1 @mem_id @khcb_addr $a0 @err
        call print_int
        li $a0 32
        call print_char
        
        geti 2 @mem_id @khcb_addr $a0 @err
        call print_int
        li $a0 10
        call print_char
        
        geti 0 @mem_id @khcb_addr @mem_id @err
        b print_again
    done_printing:
    return
}