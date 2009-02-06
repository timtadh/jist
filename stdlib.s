#define get_int global
        li $v0, 5
        syscall
        move %1, $v0
#end

#define print_int
        move $a0, %1
        li $v0, 1
        syscall
#end