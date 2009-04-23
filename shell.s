#Daniel DeCovnick 
#include stdlib.s

.data
read_buffer:    .space 256
prompt_start:   .asciiz "Enter program number to run, or 0 or q to exit, or w to wait:"
hello:          .asciiz "Welcome to the Jist Shell.\n"
bye_bye:        .asciiz "Shell Exiting. Goodbye.\n"
nl:          .asciiz "\n"
.text
.globl main
main:
{
    la      $a0 hello
    call    print
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
    println mpstr
    la     $a0 prompt_start
    call   print
    la     $a0 read_buffer
    add    $s0 $a0 $zero
    call   readln
    lb     $a0 0($s0)
#     call   print_char
    li     $t0 119 # the letter w
    beq    $a0 $t0 hold
    li     $t0 113 #the letter q
    beq    $a0 $t0 end
    add    $a0 $s0 $zero
    call   atoi
    return
hold:
    wait
    b top
end:
    la $a0 bye_bye
    call print
    wait
    exit
}