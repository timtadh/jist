# Steve Johnson
# proc_manager.s handles loading and executing programs

# load_process is probably the most interesting thing in here.

#include proc_storage.s

    .text
new_pid:
{
    # Summary:
    #   Loads last PID generated, makes a new one, saves the result
    @khcb_addr = $s0
    @next_pid = $s1
    @err = $s2
    @pid = $s3
    khcb_getaddr @khcb_addr
    
    get $zero $zero @khcb_addr @next_pid @err
    bnez @err newpid_err
    
    addu @pid @next_pid $0
    addu @next_pid @next_pid 0x1
    put  $zero $zero @khcb_addr @next_pid @err
    addu $v0 @pid $zero
    bnez @err newpid_err
    return
    
    newpid_err:
        println errmsg
        li $v0 10
        syscall
.data
    errmsg: .asciiz "error in new_pid"
.text
}

    .text
get_cmgr_head:
{
    # Summary:
    #   Loads the address of the head of the context manager linked list
    @khcb_addr = $s0
    @h = $s1
    @err = $s2
    khcb_getaddr @khcb_addr
    
    geti 1 $zero @khcb_addr @h @err
    bnez @err ch_err
    
    addu $v0 @h $zero
    return
    
    ch_err:
        println errmsg
        li $v0 10
        syscall
.data
    errmsg: .asciiz "error in get_cmgr_head"
.text
}

    .text
#init_context_manager()
init_context_manager:
{
    @pid = $s0
    @h = $s1
    @err = $s2
    @pcb_id = $s3
    @khcb_addr = $s4
    
    #Initialize a PCB on the kernel heap
    khcb_getaddr @khcb_addr
    alloci 50 @khcb_addr @pcb_id
    khcb_writeback @khcb_addr
    
    #Get a new PID
    call new_pid
    addu @pid $v0 $zero
    
    #Initialize the linked list with the new values
    addu $a0 @pid $zero
    addu $a1 @pcb_id $zero
    call ll_init
    addu @h $v0 $zero
    
    #Put the list head and current PID into kernel static space
    puti    1   $zero @khcb_addr @h @err
    bnez    @err    lfp_err
    
    puti    2   $zero @khcb_addr @pid @err
    bnez    @err    lfp_err
    
    #Store PCB and PID in other static data areas
    #to initialize parts of the interrupt handler
    la $t0 current_pcb
    sw @pcb_id 0($t0)
    la $t0 current_pid
    sw @pid 0($t0)
    
    return
    
    lfp_err:
        println error_msg
        li $v0 10
        syscall
    
    .data
default_data_amt: .word 0x00004000
error_msg: .asciiz "init_context_manager failed"
    .text
}

#load_process(program_counter)
load_process:
{
    @pid = $s0
    @h = $s1
    @err = $s2
    @pcb_id = $s3
    @khcb_addr = $s4
    @pc = $s5
    @sp = $s6
    @stack_id = $s7
    
    addu @pc $a0 $zero
    
    #Initialize a PCB on the kernel heap
    khcb_getaddr @khcb_addr
    alloci 50 @khcb_addr @pcb_id
    khcb_writeback @khcb_addr
    
    #Get the list head
    call get_cmgr_head
    addu @h $v0 $zero
    
    #And a new PID
    call new_pid
    addu @pid $v0 $zero
    
    #Append the new data to the context manager linked list
    addu $a0 @h $zero
    addu $a1 @pid $zero
    addu $a2 @pcb_id $zero
    call ll_append
    
    #Initialize the program counter and print a status message
    subu    @pc @pc 4
    mtc0    @pc $14
    println_hex pc_msg @pc
    
    #Save the procedure so it will be loaded normally by the interrupt handler
    addu $a0 @pcb_id $zero
    li $a1 0
    call save_proc
    
    {
        #Put some sane values in stack storage
        khcb_getaddr @khcb_addr
        geti 4 $zero @khcb_addr @sp @err
        addu    $a0 @sp $zero
        call save_stack
        addu    @stack_id $v0 $zero
        puti    4 @pcb_id @khcb_addr @stack_id @err
        puti    7 @pcb_id @khcb_addr @sp @err
    }
    
    #addu $a0 @h $zero
    #call ll_print
    
    return
    
    lfp_err:
        println error_msg
        li $v0 10
        syscall
    
    .data
default_data_amt: .word 0x00004000
error_msg: .asciiz "load_process failed"
pc_msg: .asciiz "Spawning new process at PC = "
    .text
}