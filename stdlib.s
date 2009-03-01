# get_int dest
#define get_int global
    exec    get_int
    add     %1 $v0 $0
#end


# print_int i
#define print_int global
    quickstore %1
    __save_args
    quickrestore %1
    move $a0, %1
    li $v0, 1
    syscall
    __restore_args
#end

# print msg_label
#     msg_label = the label that holds the addr of the message
#define print global
    la      $a0 %1
    exec    print
#end

# println msg_label
#     msg_label = the label that holds the addr of the message
#define println global
    la      $a0 %1
    exec    print
    la      $a0 newline
    exec    print
#end

# printint reg
#     reg = register where your int is
#define printint global
    quickstore %1
    __save_args
    quickrestore %1
    move $a0, %1
    li $v0, 1
    syscall
    la      $a0, newline
    li      $v0, 4              # 4 is the print_string syscall.
    syscall                     # do the syscall.
    __restore_args
#end


# put array_addr index reg
#     array_addr = the address of the array
#     index = what index
#     reg = the register you want to save
#define put global
    quickstore %1
    quickstore %2
    quickstore %3
    __save_args
    quickrestore %3
    quickrestore %2
    quickrestore %1
    add     $a3 %2  $0
    mul     $a3 $a3 4
    addu    $a3 $a3 %1
    sw      %3  0($a3)
    __restore_args
#end

# get array_addr index reg
#     array_addr = the address of the array
#     index = what index
#     reg = the register you want to load into
#define get global
    quickstore %1
    quickstore %2
    quickstore %3
    __save_args
    quickrestore %3
    quickrestore %2
    quickrestore %1
    add     $a3 %2  $0
    mul     $a3 $a3 4
    addu    $a3 $a3 %1
    lw      %3  0($a3)
    quickstore %3
    __restore_args
    quickrestore %3
#end


# print_arr array_addr size
#     array_addr = the address of the array
#     size = the size of the array
#define print_arr global
    quickstore %1
    quickstore %2
    __save_args
    quickrestore %2
    quickrestore %1
    print   sbracket_l
    add     $a3 $0 $0
    beq     %2 $0 end_loop
loop:
    get     %1 $a3 $a2
    print_int $a2
    
    add     $a3 $a3 1
    beq     $a3 %2 end_loop
    print   comma
    
    j       loop
end_loop:
    println sbracket_r
    __restore_args
#end

# print_hex_digit reg
#     reg = contains the digit your want to print in first nibble
#define print_hex_digit local

    quickstore %1
    __save_args
    quickrestore %1
    
    andi    $a0 %1 0x000f
    #if $a0 >= 10
    li      $a1 10
    bge     $a0 $a1 bigger_than_10
    li      $a1 0x30 # 0 in ascii
    j       print_digit
bigger_than_10:
    li      $a1 0x57 # a - 10 in ascii
print_digit:
    add     $a0 $a0 $a1
    li      $v0, 11             # 4 is the print_char syscall.
    syscall                     # do the syscall.
    
    __restore_args
#end

    .data
ox: .asciiz "0x"

# print_hex reg
#     reg = the word you want to print
#define print_hex global
    print   ox
    quickstore %1
    __save_args
    quickrestore %1
    
    
    add     $a0 %1 $0
    add     $a1 $0 8
    
loop:
    beq     $a1 $0 loop_end
    
    lui     $a2 0xf000
    and     $a2 $a0 $a2
    srl     $a2 $a2 28
    #printint $a2
    print_hex_digit $a2
    sll     $a0 $a0 4
    
    sub     $a1 $a1 1
    j       loop
loop_end:
    __restore_args
#end

    .text
print:
{
    li      $v0, 4              # 4 is the print_string syscall.
    syscall                     # do the syscall.
    return
}

println:
{
    li      $v0, 4              # 4 is the print_string syscall.
    syscall                     # do the syscall.
    la      $a0, newline
    li      $v0, 4              # 4 is the print_string syscall.
    syscall            
    return
}

    .text
# print_hex_digit digit
#     digit = contains the digit your want to print in first nibble
print_hex_digit:
{
    andi    $s0 $a0 0x000f
    #if $a0 >= 10
    li      $s1 10
    bge     $s0 $s1 bigger_than_10
    li      $s1 0x30 # 0 in ascii
    j       print_digit
bigger_than_10:
    li      $s1 0x57 # a - 10 in ascii
print_digit:
    add     $a0 $s0 $s1
    li      $v0, 11             # 4 is the print_char syscall.
    syscall                     # do the syscall.
    return
}
    .text
print_hex:
{
    add     $s0 $a0 $0
    la      $a0 ox
    exec    print
    add     $s1 $0 8
    
loop:
    beq     $s1 $0 loop_end
    
    lui     $a0 0xf000
    and     $a0 $s0 $a0
    srl     $a0 $a0 28
    #printint $a2
    call    print_hex_digit
    sll     $s0 $s0 4
    
    sub     $s1 $s1 1
    j       loop
loop_end:
    return
}

get_int:
{
    li $v0, 5
    syscall
    return
}


