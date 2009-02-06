# Tim Henderson
# timer_user.s - example of doing timer based interrupts

#define test
    nop
#end

    .ktext
    .globl __start
__start:
    test
    mfc0    $t0, $12            # load the status register
    ori     $t0, $t0, 0x1       # enable the interrupts
    mtc0    $t0, $12            # push the changes back to the co-proc
    
    mfc0    $t0, $9             # get the current clock value
    add     $t0, $t0, 2         # add 1
    mtc0    $t0, $11            # push to compare
    
    lui     $t0 0x0040
    ori     $t0 0x0000
    
    j       $t0                 # start main program
