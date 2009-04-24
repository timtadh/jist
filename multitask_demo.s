# Steve Johnson
# simple demo for multitasking
    .globl main
main:
{
    li $a0 1
    call run_program
    li $a0 2
    call run_program
    exit
}