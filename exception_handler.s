# Tim Henderson
# A generalized exception handler adapted from exception.s


    .kdata                      # stores the save values of these reg's since the stack
                                # may be unsafe
__m1_:  .asciiz "  Exception "
__m2_:  .asciiz " occurred and ignored\n"
__e0_:  .asciiz "  [Interrupt] \n"
__e1_:  .asciiz "  [TLB]"
__e2_:  .asciiz "  [TLB]"
__e3_:  .asciiz "  [TLB]"
__e4_:  .asciiz "  [Address error in inst/data fetch] \n"
__e5_:  .asciiz "  [Address error in store] \n"
__e6_:  .asciiz "  [Bad instruction address] \n"
__e7_:  .asciiz "  [Bad data address] \n"
__e8_:  .asciiz "  [Error in syscall] \n"
__e9_:  .asciiz "  [Breakpoint] \n"
__e10_: .asciiz "  [Reserved instruction] "
__e11_: .asciiz ""
__e12_: .asciiz "  [Arithmetic overflow] "
__e13_: .asciiz "  [Trap] "
__e14_: .asciiz ""
__e15_: .asciiz "  [Floating point] "
__e16_: .asciiz ""
__e17_: .asciiz ""
__e18_: .asciiz "  [Coproc 2]"
__e19_: .asciiz ""
__e20_: .asciiz ""
__e21_: .asciiz ""
__e22_: .asciiz "  [MDMX]"
__e23_: .asciiz "  [Watch]"
__e24_: .asciiz "  [Machine check]"
__e25_: .asciiz ""
__e26_: .asciiz ""
__e27_: .asciiz ""
__e28_: .asciiz ""
__e29_: .asciiz ""
__e30_: .asciiz "  [Cache]"
__e31_: .asciiz ""
__excp: .word __e0_, __e1_, __e2_, __e3_, __e4_, __e5_, __e6_, __e7_, __e8_, __e9_
    .word __e10_, __e11_, __e12_, __e13_, __e14_, __e15_, __e16_, __e17_, __e18_,
    .word __e19_, __e20_, __e21_, __e22_, __e23_, __e24_, __e25_, __e26_, __e27_,
    .word __e28_, __e29_, __e30_, __e31_
save0:  .word 0
save1:  .word 0
save2:  .word 0
exception_msg: .asciiz "exception handler entered\n"

    
    .ktext 0x80000180           # must go at this address
exception_handler:              # exception handler
    # first store state
    .set noat                   # stops spim from complaining that you are touching $at
    move    $k1, $at            # save the $at reg in $k1
    .set at                     # re-ables $at complaints
    sw      $a0, save0          # save $a0, $a1, $v0
    sw      $a1, save1
    sw      $v0, save2
    
    # print a message to the screen
    la      $a0, exception_msg  # load the addr of exception_msg into $a0.
    li      $v0, 4              # 4 is the print_string syscall.
    syscall                     # do the syscall.
    
    mfc0    $k0 $13             # Cause register
    srl     $a0 $k0 2           # Extract ExcCode Field
    andi    $a0 $a0 0x1f
    
    beqz    $a0 interrupt_handler
    
    li      $v0 1               # syscall 1 (print_int)
    syscall

    li      $v0 4               # syscall 4 (print_str)
    andi    $a0 $k0 0x3c        # print what exception was called
    lw      $a0 __excp($a0)
    nop
    syscall
    

interrupt_return:
exception_finished:
    mfc0    $k0, $14            # get the EPC register
    addiu   $k0, $k0, 4         # increment it (so we don't keep repeating the same instruction
    mtc0    $k0, $14            # push it back to the EPC
    
    mtc0    $0, $13             # clear cause reg
    mfc0    $k0, $12            # get status register
    xori    $k0, $k0, 0x2       # set exception level to 0 this re-enables interrupts
    mtc0    $k0, $12            # push status register
    
    # restore state
    lw      $a0, save0          # load $a0, $a1, $v0
    lw      $a1, save1
    lw      $v0, save2
    .set noat
    move    $at, $k1            # restore $at
    .set at

    eret                        # return from exception handler
