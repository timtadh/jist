# Tim Henderson
# labels for general kernel data

    .globl  proc_limit
    .globl  proc_list
    .globl  user_program_locations
    .globl  KHCB_ADDR
    .globl  KMSG
    .data 
user_program_locations:
            #repeat 16
            .word   0
KHCB_ADDR:  .word   0
KMSG:       .word   0
proc_limit: .word   0x80
proc_list:
            #repeat 128
            .word   0
