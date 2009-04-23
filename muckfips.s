    .data
str_1:  .asciiz "Proc_1"    
str_2:  .asciiz "Proc_2"
str_3:  .asciiz "Proc_3"

    .text
proc_1:
{
    println str_1
    call proc_2
    return
}

    .text
proc_2:
{
    println str_2
    return
}

    .text
proc_3:
{
    println str_3
    return
}


    .text
    .globl main
main:
    call proc_1
    call proc_3
    exit