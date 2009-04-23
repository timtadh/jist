    .data
str_1:  .asciiz "Proc_1"    
str_2:  .asciiz "Proc_2"
str_3:  .asciiz "Proc_3"

    .text
proc_1:
{
    wait
    println str_1
    #wait
    call proc_2
    wait
    return
}

    .text
proc_2:
{
    #wait
    println str_2
    exit
    wait
    return
}

    .text
proc_3:
{
    wait
    println str_3
    wait
    return
}


    .text
    .globl main
main:
    call proc_1
    wait
    call proc_3
    wait
    exit