#Steve Johnson and Tim Henderson

#include mappedio.s

    .text

# read_char
#       reads a character from the console into $v0. Blocking.
read_char:
{
    _read_char $v0
    return
}

# write_char char
#       Writes char ($a0) to the console. Blocking.
write_char:
{
    _write_char $a0
    return
}

# readln buffer_addr
#       buffer_addr: address of a buffer to write the string to
readln:
{
    #10 = LF
    #27 = control
    #68 = left
    add $t2 $zero $zero    #value to chck against
read_again:
    _read_char $t3
    _write_char $t3 #echo
    
    addi $t2 $zero 10
    beq $t3 $t2 end_read
    
    li $t2 127
    beq $t3 $t2 _delete
    b _other
    
    _delete:
        addi $t2 $zero 94
        _write_char $t2
        addi $t2 $zero 72
        _write_char $t2
        addi $a0 $a0 -1
        b read_again
    _other:
        sb $t3 0($a0)
        addi $a0 $a0 1
        b read_again
end_read:
    #sb $zero 0($a0)
    return
}

# print msg_addr
#     msg_addr = address of the msg
print:
{
write_again:
    lbu $t3 0($a0)
    addi $a0 $a0 1
    beqz $t3 end_write
    _write_char $t3
    b write_again
end_write:
    return
}

# print msg_addr
#     msg_addr = address of the msg
println:
{
write_again:
    lbu $t3 0($a0)
    addi $a0 $a0 1
    beqz $t3 end_write
    _write_char $t3
    b write_again
end_write:
    addi $t3 $zero 10
    _write_char $t3
    return
}

# print_int int
#       int = integer to print
.data
p_int_buf: .space 256
.text
print_int:
{
    #t0-t1: used by _write_char
    #t2: modifiedcopy of variable
    #t3: character to write or store in buffer
    #t4: the number 10
    #t5-t6: buffer positons
    #t7: negativity
    add $t2 $a0 $zero   #copy integer to t2
    addi $t4 $zero 10   #put 10 in t4 to use in division later
    la $t5 p_int_buf    #init buffer in t5
    add $t6 $t5 $zero   #copy to t6

    add $t7 $zero $zero #init negative bit to zero
    bgez $t2 do_digit   #set negative bit if necessary, otherwise skip
    addi $t7 $zero 1

    sub $t2 $zero $a0   #make number positive
    add $a0 $t2 $zero

do_digit:
    #This loop actually stores the number characters *backwards.*.
    #It is faster that way.
    blez $t2 end_digits #stop when t2 == 0
    div $t2 $t4         #t2 / 10
    mfhi $t3            #t3 = t2 % 10
    mflo $t2            #t2 = t2 / 10
    addi $t3 $t3 48     #t3 = t3 + 48 (48 = '0')
    sb $t3 0($t6)       #store t3 in buffer
    addi $t6 $t6 1      #move forward in buffer
    b do_digit
end_digits:
    sb $zero 0($t6)     #terminate the string just in case

    beqz $t7 write_again    #print negative sign if necessary
    addi $t3 $zero 45       #45 = '-'
    _write_char $t3
write_again:
    addi $t6 $t6 -1     #step backwards until t6 <= t5
    lbu $t3 0($t6)
    blt $t6 $t5 end_write
    _write_char $t3
    b write_again
end_write:
    
    return
}

.data
r_int_buf: .space 30
.text
read_int:
{
    la $a0 r_int_buf        #get a string from the console
    call readln
    
    #t0: result
    #t1: 45 ('0') or 10 (LF)
    #t2: negative flag
    #t3: current char
    #t4: read buffer address
    
    la $t4 r_int_buf        #init buffer position
    add $t0 $zero $zero     #init result
    
    addi $t1 $zero 45       #t5 = '-'
    lb $t3 0($t4)           #check for negativity
    add $t2 $zero $zero
    bne $t3 $t1 end_neg_check
        addi $t2 $zero 1    #set bit if negative
    end_neg_check:
    
    addi $t1 $zero 10       #t1 = LF
    read:
        lb $t3 0($t4)
        addi $t4 $t4 1
        
        beqz $t3 end_read   #end if zero since string is null-terminated
        addi $t3 $t3 -48    #subtract 48 to get real decimal value
        
        bltz $t3 read       #skip if out of range
        bgt $t3 $t1 read
        
        mul $t0 $t0 $t1     #t0 = t0 * 10
        add $t0 $t0 $t3     #t0 = t0 + t3
        b read
    end_read:
    bnez $t2 neg_yes
        add $v0 $t0 $zero
        b neg_no
    neg_yes:
        sub $v0 $zero $t0
    neg_no:
    return
}

# printf msg_addr
#   msg_addr = address of the msg
#   use store_arg to store all arguments
printf:
{
    #s0: buffer
    #s1: current char
    #s2: 37 ('%')
    #s3: format code identifier ('d', 'c', 'x', etc)
    #s4: current argument number
    
    add $s0 $a0 $zero
    addi $s2 $zero 37   #37 = '%'
    addi $s4 $zero 1
write_again:
    lbu $s1 0($s0)
    addi $s0 $s0 1
    beqz $s1 end_write
    
    beq $s1 $s2 format_pattern
        _write_char $s1
        b end_format_pattern
    format_pattern:
        lbu $s1 0($s0)
        addi $s0 $s0 1
        beqz $s1 end_write
        
        addi $s3 $zero 100  #d
        beq $s1 $s3 _dec
        addi $s3 $zero 120  #x
        beq $s1 $s3 _lhex
        addi $s3 $zero 99  #c
        beq $s1 $s3 _char
        addi $s3 $zero 115  #s
        beq $s1 $s3 _str
        beq $s1 $s2 _percent #%
        b _other
        
        _dec:
            load_arg_by_reg $s4 $a0
            exec print_int
            addi $s4 $s4 1
            b end_format_pattern
        _lhex:
            load_arg_by_reg $s4 $a0
            call print_hex
            b end_format_pattern
        _char:
            load_arg_by_reg $s4 $a0
            _write_char $a0
            addi $s4 $s4 1
            b end_format_pattern
        _str:
            load_arg_by_reg $s4 $a0
            exec print
            addi $s4 $s4 1
            b end_format_pattern
        _percent:
            _write_char $s1
            addi $s4 $s4 1
            b end_format_pattern
        _other:
            _write_char $s2
            _write_char $s1
            b write_again
    end_format_pattern:
    b write_again
end_write:
    return
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
    _write_char $a0
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
    _write_char $a0
    return
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