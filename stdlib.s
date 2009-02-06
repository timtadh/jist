# get_int dest
#define get_int global
        li $v0, 5
        syscall
        move %1, $v0
#end

# fgets space, size
#define fgets global
        la $a0, %1
        li $a1, %2
        li $v0, 8
        syscall
#end

# print_int i
#define print_int global
        move $a0, %1
        li $v0, 1
        syscall
#end

# exit
#define exit global
        li  $v0, 10
        syscall
#end