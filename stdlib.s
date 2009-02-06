#This block will look empty on compile because it used to be full of macro definitions.
#define get_int global
        li $v0, 5
        syscall
        move %1, $v0
#end

#define print_int global
        move $a0, %1
        li $v0, 1
        syscall
#end

#define test
        #%1 %2 %3
#end