# Tim Henderson
# stack.s an implementation of a stack in mips
# to use include it the data section you want eg
# 
#   .data
#   #include stack.s

# stack structure
# --------------------
# | size of stack    | 0
# -------------------- 
# | top of stack     | 4
# --------------------
# |                  | 8
# | stuff            | ...
# |                  | 4 + size * 4
# --------------------
# when top of stack == 8 + size * 4 stack is full
# if top of stack > 8 + size * 4 then there is an overflow
# if top of stack == 8 then the stack is empty
# when you add an element to the stack it works like this
# addu  $s0 addr_of_stack $0
# sw    elem top($s0)
# addu  top

# stack_new(start_size) --> $v0 = stack_addr
stack_new:
{
    mul     $t0 $a0 4           # multiply the number of words they want in the stack
                                # by 4
    addu    $t0 $t0 8           # add 8 to the size of stack the user wants
    sbrk    $t0 $s0             # alloc the memory
    
    sw      $a0 0($s0)          # save the size of the stack
    li      $t0 8               # since this is a new stack, top starts at 8
    sw      $t0 4($s0)          # save the top of the stack
    
    addu    $v0 $s0 $0          # move the addr of the stack into $v0 the return reg
    return
}

# stack_push(stack_addr, word_to_push) --> $v0 = success
#       success : 1 if the push succeeded
#                 0 if the push failed
stack_push:
{
    addu    $s0 $a0 $0          # move the addr of the stack to $s0
    addu    $s7 $a1 $0          # move the word you want to add to $s7
    lw      $s1 0($s0)          # load the size of the stack into $s1
    lw      $s2 4($s0)          # load the top of the stack into $s2
    
    # if $s2 >= 8 + $s1 * 4 then stack is full of overflowing so fail
    mul     $t0 $s1 4           # multiply the size of the stack by 4
    addu    $t0 $t0 8           # add 8
    bge     $s2 $t0 stack_push_fail
                                # if $s2 >= $t0 jump stack_push_fail
    
    addu    $t0 $s0 $s2         # add the top of the stack to addr of the stack
    sw      $s7 0($t0)          # save the word into the stack
    
    addi    $s2 $s2 1           # increment the top of the stack
    sw      $s2 4($s0)          # save the top of the stack into the control part
                                # of the stack
    
    addi    $v0 $0 1            # put 1 (for success) into out reg
    return

    stack_push_fail:
        add    $v0 $0 $0            # put 0 (for failure) into out reg
        return
}

