#Daniel DeCovnick 
#include stdlib.s

.data
read_buffer:    .space 256
prompt_start:   .asciiz "Enter program number to run, or 0 to exit, or w to wait:"
bye_bye:        .asciiz "Shell Exiting. Goodbye.\n"
nl:          .asciiz "\n"
.text
.globl main
main:
{
loop:
    call    prompt
    beq     $v0 $zero end
    addu    $a0 $v0 $zero
    call    run_program
    b       loop
end:
    la $a0 bye_bye
    call print
    wait
    exit
}
.text
prompt:
{
top:
    la     $a0 prompt_start
    call   print
    la     $a0 read_buffer
    add    $s0 $a0 $zero
    call   readln
    lb     $a0 0($s0)
#     call   print_char
    li     $t0 119 # the letter w
    beq    $a0 $t0 hold
    add    $a0 $s0 $zero
    call   atoi
    return
hold:
    wait
    b top
}