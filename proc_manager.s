# Tim Henderson
# proc_manager.s handles loading and executing programs
#

#include proc_storage.s

    .ktext
    # load_process(start_addr) --> v0 = pcb_addr
load_process:
{
    lw      $a0 default_data_amt
    call    new_proc            # make a new processs
    
    add     $v0 $s0 $0          # move the pcb addr into the return reg
    return
    .kdata
default_data_amt: .word 0x00004000
}