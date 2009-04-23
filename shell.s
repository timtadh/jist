#Daniel DeCovnick 
#include stdlib.s

.data
read_buffer:    .space 256
prompt_start:   .asciiz "Enter program number to run (based on the order in the jistfile) or 0 to exit:"
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
    la     $a0 prompt_start
    call   print
    la     $a0 read_buffer
    call   read_int
    return
}
.text
run_program:
{
    @choice = $s0
    addu    @choice $zero $a0
    addi    @choice @choice -1
    sll     @choice @choice 2
    la      $a0 user_program_locations
    addu    $a0 $a0 @choice
    lw      $a0 0($a0)
    call    make_new_background_process
    wait
    return
}