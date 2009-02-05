# Tim Henderson
# proc_storage.s handles storing proccess in PCBs

# Proccess Control Block Structure:
# --------------------
# | Process State    |
# --------------------
# | Process Number   |
# --------------------
# | Nice Level       |
# --------------------
# | Program Counter  |
# --------------------
# | Base Address     |
# | Top Address      |
# --------------------
# | at               |
# | sp               |
# | fp               |
# | gp               |
# | ra               |
# | v0               |
# | v1               |
# | a0               |
# | ...              |
# | a3               |
# | t0               |
# | ...              |
# | t9               |
# | s0               |
# | ...              |
# | s7               |
# --------------------

create_pcb:
    nop
save_proc:
    nop
restore_proc:
    nop
proc_status:
    nop
proc_nice:
    nop