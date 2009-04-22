# Tim Henderson
# proc_manager.s handles loading and executing programs
#

#include proc_storage.s

    .text
new_pid:
{
    @khcb_addr = $s0
    @dest = $s1
    @err = $s2
    khcb_getaddr @khcb_addr
    
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
    
    @temp = $t9
    addi    @temp   $zero 1
    put     @temp   $zero @khcb_addr @h @err
    bnez    @err    ERRORD
    
    addi    @temp   $zero 2
    put     @temp   $zero @khcb_addr @pid @err
    bnez    @err    ERRORD
    
    return
    
    ERRORD:
    la $a0 error_msg
    call println
    li $v0 10
    syscall
    
    .data
default_data_amt: .word 0x00004000
error_msg: .asciiz "load_first_process failed"
    .text
}