# Tim Henderson
# proc_storage.s handles storing proccess in PCBs
#
# procedures availble:
#     create_pcb() return $v0 -> addr of pcb
#     save_proc(pcb_addr, nice, status)  -> Null
#     new_proc(pcb_address  program_start  program_len) -> Null
#     restore_proc(pcb_address) -> $v0 = program_start  $v1 = program_end
#     proc_number(pcb_address) -> v0 = proc_number
#     proc_status(pcb_address) -> v0 = proc_status
#     proc_nice(pcb_address) -> v0 = proc_nice
#
# Proccess Control Block Structure:
# --------------------
# | State            | 0
# --------------------
# | Process Number   | 1
# --------------------
# | Program Counter  | 2
# --------------------
# | HCB Address      | 3
# | Base Data Addr   | 4
# | Top Data Addr    | 5
# --------------------
# | at               | 6
# | sp               | 7
# | fp               | 8
# | gp               | 9
# | ra               | 10
# | v0               | 11
# | v1               | 12
# | a0               | 13
# | ...              |
# | a3               | 16
# | t0               | 17
# | ...              |
# | t9               | 26
# | s0               | 27
# | ...              |
# | s7               | 34
# --------------------

# states:
# 0 -> new
# 1 -> ready
# 2 -> running
# 3 -> waiting
# 4 -> halted
# 5 -> marked for clean up

#include memory_manager.s

    .kdata
pcb_size: .word 0x8c            # 140 = 35 * 4
next_proc_num: .word 0x0        # start proccess number at 0

    .ktext
    # create_pcb() return $v0 -> addr of pcb
create_pcb:
    sbrk_addr pcb_size $v0
    return

    # save_proc(pcb_addr, status)  -> Null
save_proc:
    addu    $t0  $a0  0         # move the address of the PCB to $t0
    
    sw      $a1  0($t0)         # save the status into the pcb
    
    mfc0    $t1  $14            # get the EPC register
    sw      $t1  8($t0)         # save the program counter number in the pcb
    
    lw      $t1  __save_HCB_ADDR
    sw      $t1  12($t0)        # save the hcb_addr into the pcb
    
    lw      $t1  __save_at      # load the saved $at reg
    sw      $t1  24($t0)        # save it in the PCB
    
    lw      $t1  __save_sp      # load the saved stack pointer
    sw      $t1  28($t0)        # save it in the PCB
    
    lw      $t1  __save_fp      # load the saved frame pointer
    sw      $t1  32($t0)        # save it in the PCB
    
    lw      $t1  __save_gp      # load the saved global pointer
    sw      $t1  36($t0)        # save it in the PCB
    
    lw      $t1  __save_ra      # load the saved return address pointer
    sw      $t1  40($t0)        # save it in the PCB
    
    lw      $t1  __save_v0      # load the saved $v0
    sw      $t1  44($t0)        # save it in the PCB
    
    lw      $t1  __save_v1      # load the saved $v1
    sw      $t1  48($t0)        # save it in the PCB
    
    lw      $t1  __save_a0      # load the saved $a0
    sw      $t1  52($t0)        # save it in the PCB
    
    lw      $t1  __save_a1      # load the saved $a1
    sw      $t1  56($t0)        # save it in the PCB
    
    lw      $t1  __save_a2      # load the saved $a2
    sw      $t1  60($t0)        # save it in the PCB
    
    lw      $t1  __save_a3      # load the saved $a3
    sw      $t1  64($t0)        # save it in the PCB
    
    lw      $t1  __save_t0      # load the saved $t0
    sw      $t1  68($t0)        # save it in the PCB
    
    lw      $t1  __save_t1      # load the saved $t1
    sw      $t1  72($t0)        # save it in the PCB
    
    lw      $t1  __save_t2      # load the saved $t2
    sw      $t1  76($t0)        # save it in the PCB
    
    lw      $t1  __save_t3      # load the saved $t3
    sw      $t1  80($t0)        # save it in the PCB
    
    sw      $t4  84($t0)        # save $t4 in the PCB
    sw      $t5  88($t0)        # save $t5 in the PCB
    sw      $t6  92($t0)        # save $t6 in the PCB
    sw      $t7  96($t0)        # save $t7 in the PCB
    sw      $t8  100($t0)        # save $t8 in the PCB
    sw      $t9  104($t0)       # save $t9 in the PCB
    
    lw      $t1  __save_s0      # load the saved $s0
    sw      $t1  108($t0)       # save it in the PCB
    
    lw      $t1  __save_s1      # load the saved $s1
    sw      $t1  112($t0)       # save it in the PCB
    
    lw      $t1  __save_s2      # load the saved $s2
    sw      $t1  116($t0)       # save it in the PCB
    
    lw      $t1  __save_s3      # load the saved $s3
    sw      $t1  120($t0)       # save it in the PCB
    
    sw      $s4  124($t0)       # save $s4 in the PCB
    sw      $s5  128($t0)       # save $s5 in the PCB
    sw      $s6  132($t0)       # save $s6 in the PCB
    sw      $s7  136($t0)       # save $s7 in the PCB
    
    return
    
# new_proc(pcb_address data_amt) -> Null
#     data_amt = the amount of room this proccess gets for its heap and stack. static can't change.
new_proc:
{
    call create_pcb             # create a process control block
    add     $s0 $v0 $0          # save the pcb addr into $s0
    
    
    lw      $t1 next_proc_num   # load the next proccess number into $t1
    sw      $t1 4($s0)          # save the proc number in the pcb
    addi    $t1 $t1 1           # increment the next_proc_num
    sw      $t1 next_proc_num   # save it
    
    mfc0    $t1 $14             # get the EPC register
    sw      $t1 8($s0)          # save the program counter number in the pcb
    
    mul     $t1 $a0 4
    sbrk    $t1 $t0
    
    sw      $t0 16($s0)         # save the start of the data in the pcb
    addu    $t0 $t1 $t0
    sw      $t0 20($s0)         # save the end of the data in the pcb
    
    addu    $a0 $s0 $0          # load pcb_addr into arg1
    li      $a1 0               # load a default status of 0 "new" into arg2
    call    save_proc
    
    return
}
    
    # restore_proc(pcb_address) -> $v0 = program_start  $v1 = program_end
restore_proc:
    addu    $t0  $a0  0         # move the address of the PCB to $t0
    
    sw      $t1  8($t0)         # get the program counter from pcb
    mtc0    $t1  $14            # save it in the EPC register in the co-proc
    
    lw      $t1  12($t0)        # load the hcb_addr into the pcb
    sw      $t1  __save_HCB_ADDR
    
    lw      $v0  16($t0)        # load the start of the data from the pcb
    lw      $v1  20($t0)        # load the end of the data from the pcb
    
    lw      $t1  24($t0)        # load the saved $at reg
    sw      $t1  __save_at      # 
    
    lw      $t1  28($t0)        # load the saved stack pointer
    sw      $t1  __save_sp      # save it into its imm location
    
    lw      $t1  32($t0)        # load the saved frame pointer
    sw      $t1  __save_fp      # save it into its imm location
    
    lw      $t1  36($t0)        # load the saved global pointer
    sw      $t1  __save_gp      # 
    
    lw      $t1  40($t0)        # load the saved return address pointer
    sw      $t1  __save_ra      # 
    
    lw      $t1  44($t0)        # load the saved $v0
    sw      $t1  __save_v0      # 
    
    lw      $t1  48($t0)        # load the saved $v1
    sw      $t1  __save_v1      # 
    
    lw      $t1  52($t0)        # load the saved $a0
    sw      $t1  __save_a0      # 
    
    lw      $t1  56($t0)        # load the saved $a1
    sw      $t1  __save_a1      # 
    
    lw      $t1  60($t0)        # load the saved $a2
    sw      $t1  __save_a2      # 
    
    lw      $t1  64($t0)        # load the saved $a3
    sw      $t1  __save_a3      # 
    
    lw      $t1  68($t0)        # load the saved $t0
    sw      $t1  __save_t0      #
    
    lw      $t1  72($t0)        # load the saved $t1
    sw      $t1  __save_t1      # 
    
    lw      $t1  76($t0)        # load the saved $t2
    sw      $t1  __save_t2      #
    
    lw      $t1  80($t0)        # load the saved $t3
    sw      $t1  __save_t3      # 
    
    lw      $t4  84($t0)        # load $t4 from the PCB
    lw      $t5  88($t0)        # load $t5 from the PCB
    lw      $t6  92($t0)        # load $t6 from the PCB
    lw      $t7  96($t0)        # load $t7 from the PCB
    lw      $t8  100($t0)        # load $t8 from the PCB
    lw      $t9  104($t0)       # load $t9 from the PCB
    
    lw      $t1  108($t0)       # load the saved $s0
    sw      $t1  __save_s0      # 
    
    lw      $t1  __save_s1      # load the saved $s1
    sw      $t1  112($t0)       #
    
    lw      $t1  116($t0)       # load the saved $s2
    sw      $t1  __save_s2      # 
    
    lw      $t1  120($t0)       # load the saved $s3
    sw      $t1  __save_s3      # 
    
    lw      $s4  124($t0)       # load $s4 from the PCB
    lw      $s5  128($t0)       # load $s5 from the PCB
    lw      $s6  132($t0)       # load $s6 from the PCB
    lw      $s7  136($t0)       # load $s7 from the PCB
    
    return
    
    # proc_number(pcb_address) -> v0 = proc_number
proc_number:
    addu    $t0  $a0  0         # move the address of the PCB to $t0
    sw      $v0  4($t0)         # save the proc number in the pcb
    
    return
    
    # proc_status(pcb_address) -> v0 = proc_status
proc_status:
    addu    $t0  $a0  0         # move the address of the PCB to $t0
    lw      $v0  0($t0)         # load the nice and status from the pcb
    return
