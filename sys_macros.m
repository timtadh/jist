# Tim Henderson
# System Macros for jist
# Meant to be available to every program for jist

#define __save_frame local
    addu    $fp $sp $0          # move the frame pointer to point at top of frame
    subu    $sp $sp 36          # move the stack pointer down 36
    sw      $ra 36($sp)         # save the return address
    sw      $s0 32($sp)         # save registers $s0 - $s7
    sw      $s1 28($sp)
    sw      $s2 24($sp)
    sw      $s3 20($sp)
    sw      $s4 16($sp)
    sw      $s5 12($sp)
    sw      $s6 8($sp)
    sw      $s7 4($sp)
#end

#define __restore_frame global
    lw      $ra 36($sp)         # load the return address
    lw      $s0 32($sp)         # load registers $s0 - $s7
    lw      $s1 28($sp)
    lw      $s2 24($sp)
    lw      $s3 20($sp)
    lw      $s4 16($sp)
    lw      $s5 12($sp)
    lw      $s6 8($sp)
    lw      $s7 4($sp)
    addu    $sp $fp $0          # move the stack pointer to point at top of frame
    addu    $fp $fp 36          # move the frame pointer up 36
#end

# call label
# a generalized way to call procedures
#define call global
    __save_frame
    jal     %1
    __restore_frame
#end
