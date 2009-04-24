#Steve Johnson, Tim Henderson, & Dan DeCovnick

#include mappedio.s

# println_addr msg reg offset
#define println_addr global
    la      $a0 %1
    call    print
    lw      $a0 %3(%2)
    call    println_hex
#end

# println_hex msg reg
#define println_hex global
    la      $a0 %1
    call    print
    addu    $a0 %2 $0
    call    println_hex
#end

# println msg
#define println global
    la      $a0 %1
    call    println
#end

# print_hcb hcb_addr
#define print_hcb global
    addu    $a0 %1 $0
    call    print_hcb
#end


# printblock mem_id hcb_addr
#define printblock global
    addu    $a0 %1 $0
    addu    $a1 %2 $0
    call    printblock
#end

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
print_char:
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
    add $t2 $zero $zero    #value to check against
read_again:
    @in_char = $t3
    @test_char = $t2
    
    _read_char @in_char
    _write_char @in_char #echo
    
    addi @test_char $zero 10
    beq @in_char @test_char end_read
    
    li @test_char 127
    beq @in_char @test_char _delete
    b _other
    
    _delete:
        addi @test_char $zero 94
        _write_char @test_char
        addi @test_char $zero 72
        _write_char @test_char
        addi $a0 $a0 -1
        b read_again
    _other:
        sb @in_char 0($a0)
        addi $a0 $a0 1
        b read_again
end_read:
    sb $zero 0($a0)
    return
}

# print msg_addr
#     msg_addr = address of the msg
print:
{
    @outchar = $t3
    write_again:
        lbu @outchar 0($a0)
        addi $a0 $a0 1
        beqz @outchar end_write
        _write_char @outchar
        b write_again
    end_write:
    return
}

# print msg_addr
#     msg_addr = address of the msg
println:
{
    @out_char = $t3
    write_again:
        lbu @out_char 0($a0)
        addi $a0 $a0 1
        beqz @out_char end_write
        _write_char @out_char
        b write_again
    end_write:
    li @out_char 10
    _write_char @out_char
    return
}

# print_int int
#       int = integer to print
.data
p_int_buf: .space 11
.text
print_int:
{
    @saved = $t2
    @out_char = $t3
    @ten = $t4
    @bufferpos_1 = $t5
    @bufferpos_2 = $t6
    @neg_sign = $t7
    
    add @saved $a0 $zero    #copy integer to t2
    li @ten 10
    la @bufferpos_1 p_int_buf    #init buffer in t5
    addu @bufferpos_2 @bufferpos_1 $zero   #copy to t6

    li @neg_sign 0          #init negative bit to zero
    
    bnez @saved do_digit   #check for zero
        li @saved 48
        _write_char @saved
        return
    
    bgez @saved do_digit   #set negative bit if necessary, otherwise skip
    addi @neg_sign $zero 1

    sub @saved $zero $a0   #make number positive
    add $a0 @saved $zero
    do_digit:
        #This loop actually stores the number characters *backwards.*.
        #It is faster that way.
        blez @saved end_digits              #stop when t2 == 0
        div @saved @ten                     #t2 / 10
        mfhi @out_char                      #t3 = t2 % 10
        mflo @saved                         #t2 = t2 / 10
        addi @out_char @out_char 48         #t3 = t3 + 48 (48 = '0')
        sb @out_char 0(@bufferpos_2)        #store t3 in buffer
        addi @bufferpos_2 @bufferpos_2 1    #move forward in buffer
        b do_digit
    end_digits:
        sb $zero 0(@bufferpos_2)            #terminate the string just in case

        beqz @neg_sign write_again          #print negative sign if necessary
        li @out_char 45                     #45 = '-'
        _write_char @out_char
    write_again:
        addi @bufferpos_2 @bufferpos_2 -1   #step backwards until t6 <= t5
        lbu @out_char 0(@bufferpos_2)
        blt @bufferpos_2 @bufferpos_1 end_write
        _write_char @out_char
        b write_again
    end_write:
    
    return
}

.text
read_int:
{
    add $s0 $a0 $zero
    call readln             #get a string from the console
    
    add $a0 $s0 $zero
    call atoi               #call atoi to scan an int
    return                  #atoi puts the result into $v0 - return here
}

.text
atoi:
{     
    #t0: result
    #t1: 45 ('-') or 10 (LF)
    #t2: negative flag
    #t3: current char
    #t4: read buffer address
    
    add $t4 $a0 $zero       #init buffer position
    add $t0 $zero $zero     #init result
    
    addi $t1 $zero 45       #t1 = '-'
    lb $t3 0($t4)           #check for negativity
    add $t2 $zero $zero     #zero out t2
    bne $t3 $t1 end_neg_check
        addi $t2 $zero 1    #set bit in t2 if negative
    end_neg_check:
    
    addi $t1 $zero 10       #t1 = LF
    read:
        lb $t3 0($t4)       #grab a byte from the buffer
        addi $t4 $t4 1      #increment
        
        beqz $t3 end_read   #end if zero since string is null-terminated
        addi $t3 $t3 -48    #subtract 48 to get real decimal value
        
        bltz $t3 read       #skip if out of range
        bgt $t3 $t1 read    #else grab a byte again
        
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
    
    @buffer = $s0
    @this_char = $s1
    @percent = $s2
    @fmt = $s3
    @argnum = $s4
    
    add @buffer $a0 $zero
    addi @percent $zero 37      #37 = '%' stored here 'permanently' for speed
    addi @argnum $zero 1
    
    write_again:
        #read, move pointer, check for zero
        lbu @this_char 0(@buffer)
        addi @buffer @buffer 1
        beqz @this_char end_write
        
        beq @this_char @percent format_pattern  #if not %:
            _write_char @this_char      #   write char verbatim
            b end_format_pattern        #   read again
        format_pattern:                 #else:
            lbu @this_char 0(@buffer)   #   read format code
            addi @buffer @buffer 1      #   bump pointer
            
            beqz @this_char _zero       #end of string
            li @fmt 100                 #d
            beq @this_char @fmt _dec
            li @fmt 120                 #x
            beq @this_char @fmt _lhex
            li @fmt 99                  #c
            beq @this_char @fmt _char
            li @fmt 115                 #s
            beq @this_char @fmt _str
            b _other                #everything else
            
            #formula for these: load arg, call function, bump arg number, loop
            _dec:
                load_arg_by_reg @argnum $a0
                exec print_int
                addi @argnum @argnum 1
                b end_format_pattern
            _lhex:
                load_arg_by_reg @argnum $a0
                call print_hex
                addi @argnum @argnum 1
                b end_format_pattern
            _char:
                load_arg_by_reg @argnum $a0
                _write_char $a0
                addi @argnum @argnum 1
                b end_format_pattern
            _str:
                load_arg_by_reg @argnum $a0
                exec print
                addi @argnum @argnum 1
                b end_format_pattern
            _other:
                _write_char @percent
                _write_char @this_char
                b write_again
            _zero:
                _write_char @percent
                b end_write
        end_format_pattern:
        b write_again
    end_write:
    return
}


    .text
# print_hex_digit digit
#     digit = contains the digit your want to print in first nibble
print_hex_digit:
{
    @this_char = $s0
    @const = $s1
    andi    @this_char $a0 0x000f
    #if $a0 >= 10
    li      @const 10
    bge     @this_char @const bigger_than_10
    li      @const 0x30 # 0 in ascii
    j       print_digit
bigger_than_10:
    li      @const 0x57 # a - 10 in ascii
print_digit:
    add     $a0 @this_char @const
    _write_char $a0
    return
}
    .text
# print_hex reg
#     reg = the word you want to print
print_hex:
{
    @this_char = $s0
    @temp = $s1
    
    add     @this_char $a0 $0
    la      $a0 ox
    call    print
    add     @temp $0 8
    
loop:
    beq     @temp $0 loop_end
    
    lui     $a0 0xf000
    and     $a0 @this_char $a0
    srl     $a0 $a0 28
    call    print_hex_digit
    sll     @this_char @this_char 4
    
    sub     @temp @temp 1
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

# print_hcb (hcb_addr) --> Null
print_hcb:
{
        @hcb_addr = $s0
        addu    @hcb_addr $a0 $0
        println_hex  hcb_addr_msg @hcb_addr
        println_addr size_HCB_msg @hcb_addr 0
        println_addr next_id_msg  @hcb_addr 4
        println_addr top_msg      @hcb_addr 8
        println_addr freed_msg    @hcb_addr 12
        println_addr len_list_msg @hcb_addr 16
        
        @count = $s1
        @cur_addr = $s2
        lw      @count 16(@hcb_addr) #init count to length of list
        addu    @cur_addr @hcb_addr 20
    loop:
        beq     @count $0 loop_end
        
#         println_hex count_msg @count
        println_addr mem_id_msg @cur_addr 0
        println_addr addr_msg   @cur_addr 4
        println_addr amt_msg    @cur_addr 8
        
        subu    @count @count 0x1
        addu    @cur_addr @cur_addr 0xc
        j       loop
    loop_end:
        println empty
        return
        .data
        hcb_msg: .asciiz "\nHCB:"
        hcb_addr_msg: .asciiz "    HCB address = "
        size_HCB_msg: .asciiz "    size_HCB = "
        next_id_msg: .asciiz "    next_id = "
        top_msg: .asciiz "    top = "
        freed_msg: .asciiz "    freed = "
        len_list_msg: .asciiz "    len_list = "
        mem_id_msg: .asciiz "\n    mem_id = "
        addr_msg: .asciiz "    addr = "
        amt_msg: .asciiz "    amt = "
        count_msg: .asciiz "\n    count = "
        empty: .asciiz "\n"
        .text
}
.text
# print_hcb_item(addr) --> Null
print_hcb_item:
{
    @addr = $s0
    addu    @addr $a0 $0
    
    println_addr mem_id_msg @addr 0
    println_addr addr_msg   @addr 4
    println_addr amt_msg    @addr 8
    
    return
    .data
    mem_id_msg: .asciiz "\n    mem_id = "
    addr_msg: .asciiz "    addr = "
    amt_msg: .asciiz "    amt = "
    .text
}

#println_2regs reg1 msg reg2
#define println_2regs
    addu    $a0 %1 $0
    call    print_int
    la      $a0 %2
    call    print
    addu    $a0 %3 $0
    call    println_hex
#end

.text
# printblock(mem_id, hcb_addr) --> Null
printblock:
{
    @hcb_addr = $s0
    @mem_id = $s1
    @blocksize = $s3
    @count = $s4
    
    @err = $t0
    
    addu    @mem_id $a0 $0
    addu    @hcb_addr $a1 $0
    
    blocksize @mem_id @hcb_addr @blocksize @err
    bne     @err $0 blocksize_error
    println_hex blocksize_msg @blocksize
    
    {
    loop:
        bge     @count @blocksize loopend
        {
            @temp = $s5
            
            get     @count @mem_id @hcb_addr @temp @err
            bne     @err $0 blocksize_error
            println_2regs @count equal_msg @temp
        }
        addu    @count @count 0x1
        j       loop
    loopend:
    }
    
    return
    
    blocksize_error:
    println blocksize_error_msg
    return
    
    .data
    equal_msg: .asciiz " = "
    blocksize_msg: .asciiz "blocksize = "
    blocksize_error_msg: .asciiz "blocksize error"
    .text
}
.text
run_program:
{
    @choice = $s0
    addu    @choice $zero $a0
    addi    @choice @choice -1
    sll     @choice @choice 2
    la      $a0 user_program_locations
    addu    $a0 $a0 @choice
    lw      $a0 0($a0)
    call    load_process
    wait
    return
}