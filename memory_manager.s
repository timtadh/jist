# Tim Henderson
# memory_manager.s a module to manage the OS memory use instead of the sbrk macro in sys_macros.m
#     however we still need sbrk macro because this module relies on it.

# Structure of memory in spim
# -------------------------
# |      Kernel Data      | -> starts at 0x90000000
# -------------------------
# |     Kernel Program    | -> starts at 0x80000000
# ------------------------- 
# |                       | -> starts at 0x7fffffff
# |         Stack         |
# |                       | -> $fp denotes bottom of current stack frame
# ------------------------- -> $sp denotes top of stack
# |           |           |
# |          \|/          |
# |                       |
# |                       |
# |       free space      |
# |                       |
# |                       |
# |          /|\          |
# |           |           |
# -------------------------
# |                       |
# |         Heap          |
# |                       |
# ------------------------- -> sbrk syscall allocates memory in the heap
# |        Static         |
# ------------------------- -> $gp
# |       User Data       | -> starts at 0x10000000
# -------------------------
# |      User Program     | -> starts at 0x40000000
# -------------------------
# |       Reserved        | -> starts at 0x00000000
# -------------------------

# HOW THE MEMORY ALLOCATOR WILL WORK
# the memory allocator will be a way to manage the memory in the heap while the sbrk syscall
# allocates memory in the heap it cannot free memory. Thus the operating system needs a way
# to free and compact the heap when blocks of memory are released by either the OS or
# a user program.
#
# A program will request memory by asks for x number of words. the programs will not be able to
# request by number of bytes. The user programs will not get back the address of the memory instead
# they will get back a unique identifier for there memory. When they want a word from their memory
# their programs will use a global macro that will be part of this library. ie they will pass the 
# macro their memory id and the word they want (ie 0, 1, 2, 3 ... n) and the system will return the
# value of the word in from their memory block.
#
# The memory manager will allow users to free memory when they are done with it. When a piece of 
# memory is free the heap will be compacted by the memory manager so that their will be no empty 
# space. This is the reason that the user will never be given the address of their memory. The 
# address will not remain constant so the users cannot have them.
#
# At the very top of the heap will be a control structure. in essance it will be a assending sorted
# list of memory blocks in use sorted by the memory id number. It will look like this.
#
# Structure of Heap Control Block(HCB)
# -------------------------------------
# | The Sorted List Inside the Block  |
# | --------------------------------- |
# | | Size in Words of the Block    | |
# | | Address of the Memory Block   | |
# | | Memory id N                   | |
# | --------------------------------- |
# | --------------------------------- |
# | |                               | |
# | |             ...               | |
# | |                               | |
# | --------------------------------- |
# | --------------------------------- |
# | | Size in Words of the Block    | |
# | | Address of the Memory Block   | |
# | | Memory id 0                   | |
# | --------------------------------- |
# -------------------------------------
# | Length of List                    | -> the length of the sorted list
# -------------------------------------
# | Freed Space in Words              | -> How many words of free space are there above the HCB
# -------------------------------------
# |                                   | -> ie what is the farthest the heap can grow with doing
# | Address of the Top of the Heap    |    another sbrk call. this includes the space that the 
# |                                   |    Heap Control Block is occupying
# -------------------------------------
# | Next Memory id                    |
# -------------------------------------
# | Size in Words of Control Block    |
# -------------------------------------
#
# The heap control block will grow in size as the number of blocks in the heap grows and it will 
# shrink at as blocks of memory are free. There will be a special label called HCB_ADDR which will
# store the start of the heap control block. This will make it quicker to access the block. That
# way the memory manager doesn't have to walk the entire heap to get to the control block.

# Structure of Heap
# ------------------------------ -> Top of Heap
# |                            |
# |        Freed Space         |
# |                            |
# ------------------------------
# | -------------------------- |
# | | Heap Control Block(HCB)| |
# | -------------------------- | -> HCB_ADDR
# ------------------------------ 
# | Memory Block N             |
# ------------------------------
# | Memory Block N-1           |
# ------------------------------
# |                            |
# |            ....            |
# |                            |
# ------------------------------
# | Memory Block 1             |
# ------------------------------
# | Memory Block 0             |
# ------------------------------ -> Bottom of Heap

# words_to_bytes words
#     words : the number of words in a reg
#
#     it puts the result in the same register you got it from
#define words_to_bytes local
    mul     %1 %1 4             # multiply the number of words by four and store in same reg
#end

# calctop dst hcb_addr size_HCB amt_freed
#     dst : the register you want the result stored in
#     hcb_addr : a register with the size of the hcb in it
#     size_HCB : the size of the hcb in words it should be in a reg
#     amt_freed : how much space above the control block is their in words also in reg
#
#     calculates the addr of the top of the heap
#     MODIFIES: size_HCB and amt_freed registers
#
#define calctop local
    words_to_bytes %3           # multiply the size of the hcb by 4 and store in size
    words_to_bytes %4           # multiply the amt of freed space by for and store in amt
    addu    %1 %2 %3            # add the size of the hcb to the addr
    addu    %1 %1 %4            # add amt to the addr
#end

    .ktext
# initialize_heap() --> Null
#     initializes the heap and put the addr of the HCB in HCB_ADDR
initialize_heap:
    sbrk_imm    20 $s0          # request just enough memory to put the HCB in
    sw      $s0 HCB_ADDR        # store the location of the HCB in the HCB_ADDR label
    
    li      $s1 5               # the HCB start out as three words long
    sw      $s1 0($s0)          # store the size of HCB in words in the HCB
    
    li      $t0 1               # the first memory id is one
    sw      $t0 4($s0)          # store the next memory id in the HCB
    
    li      $t1 0               # store the amt of freed space in $t1
    
    calctop $t0 $s0 $s1 $t1     # calculate the addr at the top of the heap
    sw      $t0 8($s0)          # stop the top into the HCB
    
    sw      $0 12($s0)          # store the initial amount, zero, of freed space in the HCB
    
    sw      $0 16($s0)          # the intial size of the list is 0 so store it in the HCB
    
    return

# alloc(amt) --> $v0 = mem_id
#     amt : the amount in words of memory you are requesting
#     mem_id : the id you will use to access your memory
alloc:
    addu    $s7 $a0 $0          # move the amt to $s7
    
    lw      $s0 HCB_ADDR        # load the address of the HCB into $s0
    lw      $s1 12($s0)         # load the current amount of free space into $s1
    
    
## PSUEDOCODE for ths stuff
#     size_hcb_bytes = size_HCB
#     words_to_bytes size_hcb_bytes
#     end_list = HCB_ADDR + size_hcb_bytes
#     
#     if free < amt:
#         amt_requested = 3 + amt - free
#         free = 0
#     if free >= amt:
#         amt_requested = 0
#         free = free - amt
#     top = top + amt_requested
#     len_list += 1
#     size_HCB += 3
#     
#     amt_in_bytes = amt_requested
#     words_to_bytes amt_in_bytes
#     sbrk amt_in_bytes addr
#     
#     sw      next_id 0(end_list)
#     add     $s6 next_id $0  so you can return it to the user
#     next_id += 1
#     sw      HCB_ADDR 4(end_list)
#     sw      amt 8(end_list)
#     
#     move_hcb_up(amt)
#     
#     return $s6
    
    return






