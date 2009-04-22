# Tim Henderson
# proc_manager.s handles loading and executing programs
#

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

#     .text
#     # load_process(start_addr) --> v0 = pcb_addr
# load_process:
# {
#     lw      $a0 default_data_amt
#     call    new_proc            # make a new processs
#     
#     add     $v0 $s0 $0          # move the pcb addr into the return reg
#     return
#     .data
# default_data_amt: .word 0x00004000
# }

    .text
#load_first_process()
load_first_process:
{
    @pcb_space = $s0
    @pid = $s1
    @h = $s2
    @err = $s3
    @mem_id = $s4
    @khcb_addr = $s5
    
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