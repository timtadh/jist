# Steve Johnson
# simple demo for multitasking
    .globl main
main:
{
    la $a0 user_program_locations
    lw $a0 0($a0)
    call make_new_background_process
    
    la $a0 user_program_locations
    lw $a0 4($a0)
    call make_new_background_process
    
    exit
}