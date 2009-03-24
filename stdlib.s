


    .text
# print msg_addr
#     msg_addr = address of the msg
print:
{
    li      $v0, 4              # 4 is the print_string syscall.
    syscall                     # do the syscall.
    return
}

    .text
# println msg_addr
#     msg_addr = address of the msg
println:
{
    li      $v0, 4              # 4 is the print_string syscall.
    syscall                     # do the syscall.
    la      $a0, newline
    li      $v0, 4              # 4 is the print_string syscall.
    syscall            
    return
    
    .data
newline: .asciiz "\n"
}


    .text
# print_arr array_addr size
#     array_addr = the address of the array
#     size = the size of the array
print_array:
{
    add     $s0 $a0 $0
    add     $s1 $a1 $0
    la      $a0 sbracket_l
    exec    print
    add     $s2 $0 $0
    beq     $s1 $0 end_loop
loop:
    add     $a0 $s0 $0
    add     $a1 $s2 $0
    exec    get
    add     $a0 $v0 $0
    exec    print_int
    
    add     $s2 $s2 1
    beq     $s2 $s1 end_loop
    la      $a0 comma
    exec    print
    
    j       loop
end_loop:
    la      $a0 sbracket_r
    exec    println
    return
    .data
comma: .asciiz ", "
sbracket_l: .asciiz "["
sbracket_r: .asciiz "]"
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
# print_hex reg
#     reg = the word you want to print
print_hex:
{
    add     $s0 $a0 $0
    la      $a0 ox
    call    print
    add     $s1 $0 8
    
loop:
    beq     $s1 $0 loop_end
    
    lui     $a0 0xf000
    and     $a0 $s0 $a0
    srl     $a0 $a0 28
    call    print_hex_digit
    sll     $s0 $s0 4
    
    sub     $s1 $s1 1
    j       loop
loop_end:
    return
    .data
ox: .asciiz "0x"
}

    .text
println_hex:
{
    call    print_hex
    li      $a0 10
    li      $v0 11             # 4 is the print_char syscall.
    syscall                     # do the syscall.
    return
}

    .text
get_int:
{
    li $v0, 5
    syscall
    return
}

    .text
# print_int i
print_int:
{
    li $v0, 1
    syscall
    return
}

    .text
# println_int i
println_int:
{
    li      $v0 1
    syscall
    la      $a0 newline
    li      $v0 4              # 4 is the print_string syscall.
    syscall                     # do the syscall.
    return
    .data
newline: .asciiz "\n"
}

    .text
# put array_addr index reg --> Null
#     array_addr = the address of the array
#     index = what index
#     reg = the register you want to save
put:
{
    add     $a3 $a1 $0
    mul     $a3 $a3 4
    addu    $a3 $a3 $a0
    sw      $a2  0($a3)
    return
}

    .text
# get array_addr index --> $v0 = the value from the array
#     array_addr = the address of the array
#     index = what index
get:
{
    add     $a3 $a1 $0
    mul     $a3 $a3 4
    addu    $a3 $a3 $a0
    lw      $v0 0($a3)
    return
}