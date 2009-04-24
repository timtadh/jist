# Steve Johnson
# simple demo for multitasking
.data
count_string_1: .asciiz "Process 1 count: "
count_string_2: .asciiz "                      Process 2 count: "

.text
    .globl main
main:
{
    la $a0 process_1
    call load_process
    
    la $a0 process_2
    call load_process
    exit
}

.text
print_test:
{
    addu $s0 $a0 $zero
    addu $a0 $a1 $zero
    call print
    addu $a0 $s0 $zero
    call print_int
    li $a0 10
    call print_char
    return
}
.text
process_1:
{
    @loopvar = $s0
    li @loopvar 0
    loop:
        addu $a0 @loopvar $zero
        la $a1 count_string_1
        call print_test
        addi @loopvar @loopvar 1
        wait
        li $a0 3
        beq @loopvar $a0 killme
    b loop
    
    killme:
    exit
}
.text
process_2:
{
    @loopvar = $s0
    li @loopvar 0
    loop:
        addu $a0 @loopvar $zero
        la $a1 count_string_2
        call print_test
        addi @loopvar @loopvar 1
        wait
        li $a0 10
        beq @loopvar $a0 killme
    b loop
    
    killme:
    exit
}
