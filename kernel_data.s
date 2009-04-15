# Tim Henderson
# labels for general kernel data

    .globl  proc_limit
    .globl  proc_list
    .globl  user_program_locations
    .globl  kernel_data
    .globl  kernel_data_end
    .globl  HCB_ADDR
    .data 
user_program_locations:
            #repeat 16
            .word   0
HCB_ADDR:   .word   0
proc_limit: .word   0x80
proc_list:
            #repeat 128
            .word   0
kernel_data:
    #repeat 540
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
kernel_data_end:
