# labels for general kernel data
    .globl  user_program_locations
    .globl  KHCB_ADDR
    .globl  KMSG
    .globl  current_pcb
    .globl  current_pid
    .data 
user_program_locations:
            #repeat 40
            .word   0

KHCB_ADDR:  .word   0
KMSG:       .word   0

#Check out this sneaky MPP-generated macro that isn't ever defined in MIPS code.
#It just gives you a string that lists all the available programs and their slot numbers.
#That's how we have that snazzy console.
mpstr:
magic_prompt_string

current_pcb:    .word   0
current_pid:    .word   0
