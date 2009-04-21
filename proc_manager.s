# Tim Henderson
# proc_manager.s handles loading and executing programs
#

#include proc_storage.s
#include context_mgr.s

    .text
new_pid:
{
    @khcb_addr = $s0
    @dest = $s1
    @err = $s2
    khcb_getaddr @khcb_getaddr
    
    addu @mem_id $zero $zero
    get $zero $zero @khcb_addr @dest @err
    
    addi $v0 @dest 1
    bnez @err HOLYSHIT
    b NOITSOK
    HOLYSHIT:
        li $v0 10
        syscall
    NOITSOK:
    return
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
load_first_process:
{
    @hcb_addr = $s0
    @pid = $s1
    @h = $s2
    @err = $s3
    addu @hcb_addr $a0 $zero
    sbrk_imm 0x8c @hcb_addr
    
    call new_pid
    
    addu @pid $v0 $zero
    addu $a0 @pid $zero
    addu $a1 @hcb_addr $zero
    call ll_init 
    addu @h $v0 $zero
    
    addi $t9 $zero 1
    put $t9 $zero @hcb_addr @h @err
    bnez @err ERRORD
    addi $t9 $zero 2
    put $t9 $zero @hcb_addr @pid @err
    bnez @err ERRORD
    
    return
    
    ERRORD:
    li $v0 10
    syscall
    
    .data
default_data_amt: .word 0x00004000
}