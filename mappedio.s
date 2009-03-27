# mappedio.s
# Daniel DeCovnick
# created 2/9/09
# rewritten 3/19/09

# read_char() --> $v0 = typed. 
#     
#     typed : the key that was typed. Blocks until a key is typed. 
read_char:
    ## PSUEDOCODE for this function
#     store 2 to 0xffff0000
#     load 0xffff0000
#	  if (0xffff0000 & 1)
#		load 0xffff0004 into $v0
#       return
#	  else
#		loop
        lw    $t0 $0           # create the address we need to read - start by zeroing it out
	lui   $t0 0xffff	   # and put on the first 16 bits
	lw    $t1 $0           # 
	addi  $t1 2            # $t1 = 2
	sw    $t0 $t1          # sets the interrupt enable
blocking_read_loop:	 
	andi  $t2 $t0 1        # read it, and it with 1, store in another temp.
	beq   $0 $t2 blocking_read_loop # if the LSB is 0, go back to the top
#	addi  $t0 $0 4         # else, add 4 to $t0 (one word off 0xffff0000 - 0xffff0004) - removed to access by offset
	lw    $v0 4($t0)          # load it into the return register
	
	return				   #return from function call

# write_char(char in $a0) --> Null. 
#     
#     char : the character to print. Blocks until a character is written.
write_char:
    ## PSUEDOCODE for this function
#     load 0xffff0006
#	  if (0xffff0000 & 1)
#		load 0xffff0004 into $v0
#       return
#	  else
#		jump back to the top.
        lw    $t0 $0           # create the address we need to read - start by zeroing it out
	lui   $t0 0xffff	   # and put on the first 16 bits. we get 0xffff0000 here.
	addi  $t0 8
        lw    $t2 $0
        addi  $t2 $t2 2
        sw    $t0 $t1
blocking_write_loop:
	andi  $t1 $t0 1         # and it with 1, store in itself temp.
	beq   $0  $t1 blocking_write_loop # if the LSB is 0, go back a bit
#	addi  $t0 $t0 4        # else, add 4 to $t1 (one word off 0xffff0008 - 0xffff000c) - removed since we can access by offset
	lw    $v0 4($t1)       # load it into the return register 
	
	return				   #return from function call

# end write_char

