# Tim Henderson
# proc_manager.s handles loading and executing programs
#

#include proc_storage.s

    .ktext
    # load_process(start_addr) --> v0 = pcb_addr
load_process:
    call create_pcb             # create a process control block
    add     $s0 $v0 $0          # save the pcb addr in $s0
    
    addu    $a2 $0 0xffff       # put a random value into arg3 because this isn't yet supported
                                # and may never be
    add     $a1 $a0 $0          # move start_addr into arg2
    add     $a0 $s0 $0          # move pcb_addr into arg1
    call new_proc               # make a new processs
    
    add     $v0 $s0 $0          # move the pcb addr into the return reg
    return
    