# Tim Henderson
# interrupt handler

    .kdata
__int_msg: .asciiz "interrupt handler entered\n"

    .ktext
interrupt_handler:
    la      $a0, __int_msg  # load the addr of exception_msg into $a0.
    li      $v0, 4              # 4 is the print_string syscall.
    syscall                     # do the syscall.
    
    j       $k0