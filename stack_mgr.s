{
#include stdlib.s
#include sys_macros.m
.data
#Format of saved stack array:
#   0: Available
#   1: PID
#   2: $fp
#   3: $sp
_saved_stacks: .space 256
_current_stack: .word 0
.text

init_stack:
{
    return
}

close_stack:
{
    return
}

change_stack:
{

}

}