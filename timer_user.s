# Tim Henderson
# timer_user.s - example of doing timer based interrupts
# spim.py timer_user.s exception_handler.s

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
