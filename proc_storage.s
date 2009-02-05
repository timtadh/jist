# Tim Henderson
# proc_storage.s handles storing proccess in PCBs

# Proccess Control Block Structure:
# --------------------
# | Nice   | State   | 1
# --------------------
# | Process Number   | 2
# --------------------
# | Program Counter  | 3
# --------------------
# | Base Address     | 4
# | Top Address      | 5
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

    .kdata
pcb_size: .word 0x88            # 136 = 34 * 4
next_proc_num: .word 0x0        # start proccess number at 0

    .ktext
    # create_pcb
create_pcb:
    li      $v0, 9              # system call code for sbrk
    lw      $a0, pcb_size       # amount
    syscall                     # make the call
    
    jr      $ra

    # save_proc(pcb_address, program_start, program_len)
save_proc:    
    addu    $t0, $a0, 0         # move the address of the PCB to $t0
    lui     $t1, 5              # set the default nice level to 5
    ori     $t1, $t1, 0         # load the state "new" into the lower part of $t1
    sw      $t1, 0($t0)         # save the nice and state into the pcb
    
    lw      $t1, next_proc_num  # load the next proccess number into $t1
    sw      $t1, 4($t0)         # save the proc number in the pcb
    
    mfc0    $t1, $14            # get the EPC register
    addu    $t1, $t1, 4         # add 4 to it so we don't execute the same instruction twice
    sw      $t1, 8($t0)         # save the program counter number in the pcb
    
    sw      $a1, 12($t0)        # save the start of the program in the pcb
    
    addu    $t1, $a1, $a2       # add the length of the program to where it starts
    sw      $t1, 16($t0)        # save the end of the program in the pcb
    
    sw      $k1, 20($t0)        # save $at into the PCB ($at is saved to $k1
                                #   at the start of the interrupt)
    
    lw      $t1, __save_sp      # load the saved stack pointer
    sw      $t1, 24($t0)        # save it in the PCB
    
    lw      $t1, __save_fp      # load the saved frame pointer
    sw      $t1, 28($t0)        # save it in the PCB
    
    lw      $t1, __save_gp      # load the saved global pointer
    sw      $t1, 32($t0)        # save it in the PCB
    
    lw      $t1, __save_ra      # load the saved return address pointer
    sw      $t1, 36($t0)        # save it in the PCB
    
    lw      $t1, __save_v0      # load the saved $v0
    sw      $t1, 40($t0)        # save it in the PCB
    
    lw      $t1, __save_v1      # load the saved $v1
    sw      $t1, 44($t0)        # save it in the PCB
    
    lw      $t1, __save_a0      # load the saved $a0
    sw      $t1, 48($t0)        # save it in the PCB
    
    lw      $t1, __save_a1      # load the saved $a1
    sw      $t1, 52($t0)        # save it in the PCB
    
    lw      $t1, __save_a2      # load the saved $a2
    sw      $t1, 56($t0)        # save it in the PCB
    
    lw      $t1, __save_a3      # load the saved $a3
    sw      $t1, 60($t0)        # save it in the PCB
    
    lw      $t1, __save_t0      # load the saved $t0
    sw      $t1, 64($t0)        # save it in the PCB
    
    lw      $t1, __save_t1      # load the saved $t1
    sw      $t1, 68($t0)        # save it in the PCB
    
    lw      $t1, __save_t2      # load the saved $t2
    sw      $t1, 72($t0)        # save it in the PCB
    
    lw      $t1, __save_t3      # load the saved $t3
    sw      $t1, 76($t0)        # save it in the PCB
    
    
    
restore_proc:
    nop
proc_status:
    nop
proc_nice:
    nop