# Steve Johnson
# context_mgr.s
# These functions keep track of PIDs and PCBs for currently running processes
#   using a circular linked list formatted like this:
#   @h: head: [next address][process num][pcb mem_id]

# _new_ll_node:
#     Allocate space for a new node
# 
# ll_init:
#     Initialize the linked list with the given values at the head
# 
# ll_append:
#     Append a new node with the given values
# 
# ll_next:
#     Get the next list item after the given item. Loop to head if at the list end.
# 
# ll_find_pid:
#     Linearly searches the list for the given PID.
# 
# ll_remove:
#     Remove an item from the list
# 
# ll_print:
#     Print out the list

.text

#define _new_ll_node local
    #Load kernel heap control block
    @khcb_addr = $s3
    khcb_getaddr @khcb_addr
    
    #Load third item (head of the context manager list) from static data
    li $a0 3
    addu $a1 @khcb_addr $zero
    
    #Make some space for the new node
    call alloc
    addu    %1 $v0 $zero
    
    #Write the KHCB back to its static memory location
    addu    @khcb_addr $v1 $zero
    khcb_writeback @khcb_addr
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
    
    #Allocate space for a new node, store its address in @h
    _new_ll_node @h
    
    #Put the given parameters into kernel static data
    khcb_getaddr @khcb_addr
    puti 0 @h @khcb_addr $zero @err
    puti 1 @h @khcb_addr @initval @err
    puti 2 @h @khcb_addr @initpcb @err
    
    #Return the head of the new linked lists
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
    
    #Allocate space for a new node
    _new_ll_node @new
    
    #Traverse the list to find the end (denoted by zero)
    khcb_getaddr @khcb_addr
    geti 0 @thisnode @khcb_addr @nextnode @err
    loop:
        beqz @nextnode found_end
        addu @thisnode @nextnode $zero
        geti 0 @thisnode @khcb_addr @nextnode @err
        khcb_getaddr @khcb_addr
        b loop
    found_end:
    
    khcb_getaddr @khcb_addr
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
    
    #return current_node.next unless current_node.next == NULL, in which case return head
    khcb_getaddr @khcb_addr
    geti 0 @current @khcb_addr $v0 @err
    beqz $v0 return_head
        return
    return_head:
        addu $v0 @head $zero
    return
}

.text
#ll_find_pid(list_head, to_find)
ll_find_pid:
{
    @head = $s0
    @to_find = $s1
    @khcb_addr = $s2
    @err = $s3
    @next = $s4
    @temp = $s5
    @temp2 = $s6

    add @head $a0 $zero
    add @to_find $a1 $zero

    khcb_getaddr @khcb_addr
    
    geti 1 @head @khcb_addr @temp @err
    beq @temp @to_find head_case

    loop:
        beqz @head found_end
        geti 0 @head @khcb_addr @next @err
        geti 1 @head @khcb_addr @temp @err

        bne @temp @to_find not_found_yet
            addu $v0 @head $zero
            return
        not_found_yet:
            addu @head @next $zero
            b loop

    head_case:
        addu $v0 @head $zero
        return

    found_end:
        kill_jist
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
    @head_o = $s6
    
    add @head $a0 $zero
    add @to_remove $a1 $zero
    addu @head_o @head $zero
    
    khcb_getaddr @khcb_addr
    beq @head @to_remove head_case
    
    #println_hex msg $s1
    
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
            khcb_writeback @temp
            addu $v0 @head_o $zero
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
        khcb_writeback @temp
        addu $v0 @head $zero
        return
    
    head_only:
        la $a0 _quit_msg
        call println
        li $v0 10
        syscall
    
    found_end:
        println errorstr
        kill_jist
        return
.data
errorstr: .asciiz "bloody death in ll_remove\n"
msg: .asciiz "to remove: "
_quit_msg: .asciiz "All programs have exited. Closing Jist."
}

.text
ll_print:
{
    @mem_id = $s0
    @val = $s1
    @khcb_addr = $s2
    @err = $s3
    add @mem_id $a0 $zero
    
    println header
    
    print_again:
        beqz @mem_id done_printing
        khcb_getaddr @khcb_addr
        
        geti 2 @mem_id @khcb_addr $a0 @err
        store_arg $a0
        geti 1 @mem_id @khcb_addr $a0 @err
        store_arg $a0
        geti 0 @mem_id @khcb_addr $a0 @err
        store_arg $a0
        store_arg @mem_id
        
        la $a0 fmt_str
        call printf
        
        geti 0 @mem_id @khcb_addr @mem_id @err
        b print_again
    done_printing:
    return
.data
header: .asciiz "\nProcess List:"
fmt_str: .asciiz "  kheap mem_id: %d      next: %d        pid: %d         pcb_mem_id: %d\n"
}