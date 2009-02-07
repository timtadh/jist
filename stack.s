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

# new_stack(start_size) --> $v0 = stack_addr
new_stack:
    addu    $t0 $a0 8           # add 8 to the size of stack the user wants
    sbrk    $t0 $s0             # alloc the memory
    
    sw      $a0 0($s0)          # save the size of the stack
    li      $t0 8               # since this is a new stack, top starts at 8
    sw      $t0 4($s0)          # save the top of the stack
    
    addu    $v0 $s0 $0          # move the addr of the stack into $v0 the return reg
    return