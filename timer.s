# Tim Henderson
# timer.s - example of doing timer based interrupts
# run -> spim -ne -mio timer.s

    .text
    .globl __start
__start:
    mfc0    $t0, $12            # load the status register
    ori     $t0, $t0, 0x1       # enable the interrupts
    mtc0    $t0, $12            # push the changes back to the co-proc
    
    mfc0    $t0, $9             # get the current clock value
    add     $t0, $t0, 2         # add 1
    mtc0    $t0, $11            # push to compare
    
    j main                      # start main program

    .globl main
main:
    # print hello world to the console
    la      $a0, hello_msg      # load the addr of hello_msg into $a0.
    li      $v0, 4              # 4 is the print_string syscall.
    syscall
    
    # waste sometime
    li      $t1, 0xf000         # initialize loop counter
loop:
    addi    $t1, $t1, -1        # decrement every loop
    bgez    $t1, loop           # if $t1 > 0: jump loop
    
    jal     print_status        # print status reg
    jal     print_newline       # print a newline afterwards
    
    j       exit                # exit program
    
print_newline:
    la      $a0, newline
    li      $v0, 4              # 4 is the print_string syscall.
    syscall                     # do the syscall.
    j       $ra

print_status:
    mfc0    $a0, $12            # status register in $a0
    li      $v0, 1              # print it
    syscall
    j       $ra
    
exit:
    li      $v0, 10             # syscall code 10 is for exit.
    syscall                     # make the syscall.
    
    ## Data for the program:
    .data
hello_msg:
    .asciiz "Hello World\n"
newline:
    .asciiz "\n"


# end of add2.asm.


    .kdata                      # stores the save values of these reg's since the stack
                                # may be unsafe
save0:  .word 0
save1:  .word 0
exception_msg: .asciiz "exception handler entered\n"

    
    .ktext 0x80000180           # must go at this address
exception_handler:              # exception handler
    # first store state
    .set noat                   # stops spim from complaining that you are touching $at
    move    $k1, $at            # save the $at reg in $k1
    .set at                     # re-ables $at complaints
    sw      $a0, save0          # save $a0, $a1
    sw      $a1, save1
    
    # print a message to the screen
    la      $a0, exception_msg  # load the addr of exception_msg into $a0.
    li      $v0, 4              # 4 is the print_string syscall.
    syscall                     # do the syscall.
    
exception_finished:
    mfc0    $k0, $14            # get the EPC register
    addiu   $k0, $k0, 4         # increment it (so we don't keep repeating the same instruction
    mtc0    $k0, $14            # push it back to the EPC
    
    mtc0    $0, $13             # clear cause reg
    mfc0    $a0, $12            # get status register
    xori    $a0, $a0, 0x2       # set exception level to 0 this re-enables interrupts
    mtc0    $a0, $12            # push status register
    
    # restore state
    lw      $a0, save0          # load $a0, $a1
    lw      $a1, save1
    .set noat
    move    $at, $k1            # restore $at
    .set at

    eret                        # return from exception handler
