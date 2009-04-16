
#include stdlib.s
    .globl main
    .data
msg_str: .asciiz "adder entered"
    .text
main:
#     sbrk_imm   1024 $t0 
#     addu    $t1 $t0 1024
#     subu    $t1 $t1 $t0
#     sra     $t1 $t1 2
# #     initialize_heap $t0 $t1
# #     # 
# #     print_hcb
# #     # 
#     addu    $s0 $0 4
#     call print_hcb
# #     alloc   $s0 $s1
#     call print_hcb
    exit
# end of add2.asm.
