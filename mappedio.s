# mappedio.s
# Daniel DeCovnick
# created 2/9/09
# rewritten 3/19/09

# read_char() --> $v0 = typed. 
#     
#     typed : the key that was typed. Blocks until a key is typed. 
read_char:
{
    ## PSUEDOCODE for this function
#     store 2 to 0xffff0000
#     load 0xffff0000
#     if (0xffff0000 & 1)
#       load 0xffff0004 into $v0
#       return
#     else
#       loop


    lui  $t0 0xffff # init t0 to base address for mmio registers
blocking_read_loop:
    lw   $t3 0($t0)
    bnez $t3 blocking_read_loop
    lw   $v0 4($t0)
    return
}


#       add   $t0 $zero $zero  # create the address we need to read - start by zeroing it out
#       lui   $t0 0xffff       # and put on the first 16 bits
#        addi  $t1 $zero 2      # $t1 = 2
#        sw    $t1 0($t0)       # sets the interrupt enable: 0xffff0000 = 0000 0000 0000 0000 0000 0000 0000 0010
#        add   $t2 $zero $zero  # zero out the test reg
#blocking_read_loop:  
#        andi  $t2 $t0 1        # read it, and it with 1, store in the test reg.
#        beq   $zero $t2 blocking_read_loop # if the LSB is 0, go back to the top: we only get anywhere if $t2 = 0000 0000 0000 0000 0000 0000 0000 0001
#        lw    $v0 4($t0)       # load 0xffff0004 into the return register
#    
#        return                 #return from function call
#}

# write_char(char in $a0) --> Null. 
#     
#     char : the character to print. Blocks until a character is written.
write_char:
{

    #load_arg 1 $t1     # get arg
    li  $t0 0xffff0008    # init t0 to base address for mmio registers
blocking_write_loop:
    lw   $t3 0($t0)
    andi $t3 $t3 1       # get ready bit
    beq  $t3 $zero blocking_write_loop
    sw   $a0 4($t0)     # store output into the tx register
    return
}
















    ## PSUEDOCODE for this function
#     load 0xffff0008
#     if (0xffff0008 & 1)
#       load 0xffff000c into $a0
#       return
#     else
#       jump back to the top.
#        add   $t0 $zero $zero # create the address we need to read - start by zeroing it out
#        lui   $t0 0xffff      # and put on the first 16 bits. we get 0xffff0000 here.
#        addi  $t2 $zero 2     # set mask to 2
#        sw    $t2 8($t0)      # write the interrupt enable: 0xffff0008 = 0000 0000 0000 0000 0000 0000 0000 0010
#        add   $t1 $zero $zero # zero out the test reg
#blocking_write_loop:
#	lw    $t3 0($t0)      #load contents of $t0
#        andi  $t1 $t3 1         # and it with 1, store in the test reg.
#        beqz  $t1 blocking_write_loop # if the LSB is 0, go back a bit: we only get anywhere if $t1 = 0000 0000 0000 0000 0000 0000 0000 0001
#        #load_arg 0 $a0
#        sw    $a0 12($t0)       # store it into the tx register 
    
#        return                 #return from function call
#}

# end write_char

