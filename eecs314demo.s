    .text
    .globl main
main:
    #add.s
    la $a0 user_program_locations
    lw $a0 8($a0)
    call make_new_background_process
    
    wait
    
    #wumpus.s
    la $a0 user_program_locations
    lw $a0 12($a0)
    call make_new_background_process
    
    wait
    
    #muckfips.s
    la $a0 user_program_locations
    lw $a0 16($a0)
    call make_new_background_process
    
    wait
    wait
    
    #imuckfips.s
    la $a0 user_program_locations
    lw $a0 20($a0)
    call make_new_background_process
    
    wait
    
    #multitask_demo.s
    la $a0 user_program_locations
    lw $a0 24($a0)
    call make_new_background_process
    
    exit