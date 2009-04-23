# Steve Johnson
# proc_manager.s handles loading and executing programs

#include proc_storage.s

    .text
new_pid:
{
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
#load_first_process()
load_first_process:
{
    @pid = $s0
    @h = $s1
    @err = $s2
    @mem_id = $s3
    @khcb_addr = $s4
    
    khcb_getaddr @khcb_addr
    
    addu    $a0 $0 50
    addu    $a1 @khcb_addr $zero
    call    alloc
    addu    @mem_id $v0 $zero
    addu    @khcb_addr $v1 $zero
    
    khcb_writeback @khcb_addr
    
    call new_pid
    addu @pid $v0 $zero
    addu $a0 @pid $zero
    addu $a1 @mem_id $zero
    call ll_init
    addu @h $v0 $zero
    
    puti    1   $zero @khcb_addr @h @err
    bnez    @err    lfp_err
    
    puti    2   $zero @khcb_addr @pid @err
    bnez    @err    lfp_err
    
    #addu $a0 @h $zero
    #call ll_print
    
    la $t0 current_pcb
    sw @mem_id 0($t0)
    la $t0 current_pid
    sw @pid 0($t0)
    
    return
    
    lfp_err:
        println error_msg
        li $v0 10
        syscall
    
    .data
default_data_amt: .word 0x00004000
error_msg: .asciiz "load_first_process failed"
    .text
}

#make_new_background_process(program_counter)
make_new_background_process:
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
    
    khcb_getaddr @khcb_addr
    
    addu    $a0 $0 50
    addu    $a1 @khcb_addr $zero
    call    alloc
    addu    @pcb_id $v0 $zero
    addu    @khcb_addr $v1 $zero
    
    khcb_writeback @khcb_addr
    
    call get_cmgr_head
    addu @h $v0 $zero
    
    call new_pid
    addu @pid $v0 $zero
    
    addu $a0 @h $zero
    addu $a1 @pid $zero
    addu $a2 @pcb_id $zero
    call ll_append
    
    subu    @pc @pc 4
    mtc0    @pc $14
    println_hex pc_msg @pc
    
    addu $a0 @pcb_id $zero
    li $a1 0
    call save_proc
    
    {
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
error_msg: .asciiz "load_first_process failed"
pc_msg: .asciiz "Spawning new process at PC = "
    .text
}