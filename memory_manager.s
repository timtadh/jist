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
# | Size in Words of Control Block    | -> includes the first 5 words
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

# load_hcb hcb_addr
#     loads the HCB into $s0 - $s5 see the comments for what is in what reg
#define load_hcb local
    lw      $s1 0(%1)          # load the size_HCB into $s1
    lw      $s2 4(%1)          # load the next_id into $s2
    lw      $s3 8(%1)          # load the top into $s3
    lw      $s4 12(%1)         # load the free into $s4
    lw      $s5 16(%1)         # load the len_list into $s5
#end

# save_hcb hcb_addr
#     save the HCB
#     assumes the variables are in the same position that load_hcb left them
#define save_hcb local
    sw      $s1 0(%1)           # save the size_HCB
    sw      $s2 4(%1)           # save the next_id
    sw      $s3 8(%1)           # save the top
    sw      $s4 12(%1)          # save the free
    sw      $s5 16(%1)          # save the len_list
#end

# calctop dst hcb_addr size_HCB amt_freed
#     dst : the register you want the result stored in
#     hcb_addr : a register with the addr of the hcb in it
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
    subu    %1 %1 4             # subtract 4 to get the actual last addr
#end

.text
.globl initialize_heap
# initialize_heap(addr, len) --> Null
#     start = the start address
#     len = the length of the heap in words
#     initializes the heap and put the addr of the HCB in HCB_ADDR
initialize_heap:
{
    @hcb_addr = $s0
    @heap_len = $s1
    @hcb_len = $s2
    
    addu    @hcb_addr $a0 $0
    addu    @heap_len $a1 $0    # length of heap into @heap_len
    println_hex addr_msg @hcb_addr
    
    li      @hcb_len 5               # the HCB start out as five words long
    sw      @hcb_len 0(@hcb_addr)    # store the size of HCB in words in the HCB
    
    {
        @mem_id = $t1
        li      @mem_id 5               # the first memory id is one
        sw      @mem_id 4(@hcb_addr)    # store the next memory id in the HCB
    }
    
    @free = $t1
    sub     @free @heap_len @hcb_len # subtract the size of the hcb from the size of the heap
    sw      @free 12(@hcb_addr)   
    
    @top = $t0
    calctop @top @hcb_addr @hcb_len @free     # calculate the addr at the top of the heaps
    sw      @top 8($s0)          # put the top into the HCB
    
    sw      $0 16($s0)          # the intial size of the list is 0 so store it in the HCB
    
    return
    .data
    addr_msg: .asciiz " init_heap addr: "
    .text
}

.text
# add_to_hcb(mem_addr, mem_size, hcb_addr) --> $v0 = mem_id
.globl add_hcb_item
add_hcb_item:
{
    @hcb_addr = $s0
    @hcb_size = $s1
    @hcb_next_id = $s2
    @hcb_top = $s3 
    @hcb_free = $s4
    @hcb_len_list = $s5
    
    @mem_addr = $s6
    @mem_size = $s7
    @mem_id = $t1
    
    @end_list = $t0
    
    addu    @mem_addr $a0 $0
    addu    @mem_size $a1 $0
    addu    @hcb_addr $a2 $0
    
    load_hcb @hcb_addr
    addu    @mem_id @hcb_next_id $0
    addu    @hcb_next_id @hcb_next_id 1           # next_id += 1
    addu    @hcb_len_list @hcb_len_list 1           # len_list += 1
    
    addu    @end_list @hcb_size $0          # move size_HCB into $t0
    addu    @hcb_size @hcb_size 3           # size_HCB += 3
    subu    @hcb_free @hcb_free 3
    
    sll     @end_list @end_list 2
        # add the size of the hcb to the addr
    addu    @end_list @hcb_addr @end_list
    save_hcb @hcb_addr
    
    sw      @mem_id   0(@end_list)          # sw      mem_id 0(end_list)
    sw      @mem_addr 4(@end_list)          # sw      addr 4(end_list)
    sw      @mem_size 8(@end_list)          # sw      size 8(end_list)
    
    addu    $v0 @mem_id $0          # return mem_id
    return
    
    .data
    addr_msg: .asciiz "         addhcb -> addr = "
    amt_msg:  .asciiz "         addhcb -> amt = "
    size_msg:  .asciiz "         addhcb -> size = "
    .text
}

# get_hcb_item(index, hcb_addr) --> $v0 = addr, $v1 = error
#     index : the index the element you want
#     addr : the address of the element
#     error : 0 if not error, error number otherwise
get_hcb_item:
{
    @hcb_addr = $s0
    @hcb_size = $s1
    @hcb_next_id = $s2
    @hcb_top = $s3 
    @hcb_free = $s4
    @hcb_len_list = $s5
    
    @index = $s7
    
    @i_byte = $t0
    @temp   = $t1
    
    add     @index $a0 $0          # $s7 = index
    addu    @hcb_addr $a1 $0
    
    load_hcb @hcb_addr
    
    ble     @index @hcb_len_list index_in_list
    #index not in list
        add     $v0 $0 $0           # addr = 0
        addi    $v1 $0 1            # error = 1
        j       end
    index_in_list:
        mul     @temp @index 3      # because the item size is 3 words
        addi    @i_byte @temp 5     # i_bytes = index + 5
        sll     @i_byte @i_byte 2   # mul by 4
        add     $v0 @hcb_addr @i_byte   # addr = hcb_addr + i_bytes
        add     $v1 $0 $0               # error = 0 (success!)
end:
    return
}


# del_hcb_item(index, addr) --> $v0 = error
#     mem_id : the mem_id you want to remove from the list
#     error : 0 if success error code otherwise
del_hcb_item:
{
# load_hcb
# to_addr, err = \
#         get_hcb_list_elem(mem_id)
# if err: jump get_hcb_list_elem_error
# from_addr = to_addr + 3*4
# hcbtop  last_addr HCB_ADDR size_HCB
# while (from_addr <= last_addr)
# {
#     lw      temp 0(from_addr)
#     sw      temp 0(to_addr)
#     from_addr += 4
#     to_addr += 4
# }
# len_list -= 1
# size_HCB -= 3
# free += 3
# save_hcb
    @hcb_addr = $s0
    @hcb_size = $s1
    @hcb_next_id = $s2
    @hcb_top = $s3 
    @hcb_free = $s4
    @hcb_len_list = $s5
    
    @item_size = $s6
    @index = $s7
    
    @to_addr = $t0
    @from_addr = $t1
    @last_addr = $t2
    @temp = $t3
    
    addu    @index $a0 $0          # put the index into $s7
    addu    @hcb_addr $a1 $0
    
    
    addu    $a0 @index $0
    call    get_hcb_item
#     if err: jump del_hcb_list_elem_error
    bne     $v1 $0 del_hcb_list_elem_error
    addu    @to_addr $v0 $0          # to_addr = $t0
    
    lw      @item_size 8(@to_addr) 
    
    load_hcb @hcb_addr
    addu    @from_addr @to_addr 12   # from_addr = to_addr + 3*4
    sll     @last_addr @hcb_size 2
    addu    @last_addr @hcb_addr @last_addr
    loop:
    #     if from_addr > last_addr: jump del_hcb_list_elem_loop_end
        beq     @from_addr @last_addr loop_end
        lw      @temp 0(@from_addr)          # lw      temp 0(from_addr)
        sw      @temp 0(@to_addr)            # sw      temp 0(to_addr)
        addu    @from_addr @from_addr 4      # from_addr += 4
        addu    @to_addr @to_addr 4          # to_addr += 4
        j       loop
    loop_end:
        subu    @hcb_len_list @hcb_len_list 1   # len_list -= 1
        subu    @hcb_size @hcb_size 3           # size_HCB -= 3
        addu    @hcb_free @hcb_free 3           # free += 3
        addu    @hcb_free @hcb_free @item_size
        save_hcb @hcb_addr
        add     $v0 $0 $0           # error = 0 success!
        return
    .data
    del_error_msg: .asciiz "del error"
    del_index_msg: .asciiz "del index = "
    hcb_addr_start_msg: .asciiz "HCB address start_addr = "
    hcb_addr_end_msg: .asciiz "HCB address end_addr = "
    index_addr_msg: .asciiz "Index address = "
    new_index_msg: .asciiz "new index = "
    old_index_msg: .asciiz "old index = "
    msg: .asciiz "here"
    .text
    del_hcb_list_elem_error:
        la      $a0 del_error_msg
        call    println
        addi    $v0 $0 1            # move error = 1 to output
        j       end
    end:
    return
}

# move_hcb_up(amt, addr) --> $v0 = new_addr
#     amt : amt you want to move the HCB up in words
#     moves the HCB up by amt in words
#     save the new location of HCB in HCB_ADDR
.text
.globl move_hcb_up
move_hcb_up:
{
# while (hcb_addr <= move_from_addr)
# {
#     move_to_addr = move_to_addr+4
#     lw      temp 0(move_from_addr)
#     sw      temp 0(move_to_addr)
#     move_from_addr = move_from_addr-4
# }
# sw      move_to_addr HCB_ADDR
    @hcb_addr = $s0
    
    @amt = $s7
    @move_from = $s1
    @move_to = $s2
    @temp = $s3
    
    addu    @amt $a0 $0          # move the amt to $s7
    addu    @hcb_addr $a1 $0 
    sll     @amt @amt 2          # multiply the amt by 4
    
    load_hcb  @hcb_addr
    addu    @move_from $s1 0x0
    sll     @move_from @move_from 2
    addu    @move_from @hcb_addr @move_from
    addu    @move_to @move_from @amt
    addu    @move_to @move_to 0x4
loop:
#   if hcb_addr < move_from_addr: jump loop_end
    bgt    @hcb_addr @move_from loop_end
        subu    @move_to @move_to 4
        lw      @temp 0(@move_from)
        sw      @temp 0(@move_to)
        subu    @move_from @move_from 4
    j   loop
loop_end:
    
    addu    $v0 @move_to $0
    return
    .data
    amt_msg: .asciiz "amount = "
    .text
}

.text
.globl compact
# # compact (mem_id, hole_addr, hole_size, hcb_addr) --> new_hcb_addr
compact:
{
        @hcb_addr = $s0
        @hcb_size = $s1
        
        @from_addr = $s2
        @to_addr = $s3
        @last_addr = $s4
        @count = $s5
        
        @hole_addr = $s6
        @hole_size = $s7
        
        @temp = $t0
        @count_temp = $t1
        @x = $t2
        @remainder = $t3
        @temp_addr = $t4
        
        @memid_loc = $t8
        @mem_id = $t9
        
        addu    @mem_id $a0 $0
        addu    @hole_addr $a1 $0          # $s6 = hole_addr
        addu    @hole_size $a2 $0          # $s7 = hole_size
        addu    @hcb_addr  $a3 $0
        
        li      $t8 0x1
        init_varstore $t8
        
        li      @memid_loc 0x1
        var_store @memid_loc @mem_id
        
#         println_hex hole_size_msg @hole_size
#         println_hex hole_addr_msg @hole_addr
#         println_hex hcb_addr_msg @hcb_addr
        
        load_hcb @hcb_addr          # load the control block
        sll     @hole_size @hole_size 2
        addu    @from_addr @hole_size $0           # move hole_size into $t0
        addu    @from_addr @from_addr @hole_addr
        addu    @to_addr @hole_addr $0          # to_addr = $t1
        
        #calculate the top of hcb
        addu    @last_addr @hcb_size $0          # move size_HCB into $t2
        sll     @last_addr @last_addr 2
        addu    @last_addr @hcb_addr @last_addr
        
        addu    @count $0 $0
        
#         println_hex count_msg @count
#         println_hex from_addr_msg @from_addr
#         println_hex to_addr_msg @to_addr
#         println_hex last_addr_msg @last_addr
        
        {
        loop:
    #   if from_addr > last_addr: jump compact_loop_end
        bgt     @from_addr @last_addr loop_end
            lw      @temp 0(@from_addr)          # lw  temp 0(from_addr)
            sw      @temp 0(@to_addr)          # sw  temp 0(to_addr)
        #         if (from_addr == hcb_addr)
            {
            bne     @from_addr @hcb_addr endif
                addu    @hcb_addr @to_addr $0          # hcb_addr = to_addr
            endif:
            }
            
            addu    @x $0 0x5
            {
            ble     @count @x endif
                subu    @count_temp @count @x
                addu    @x $0 0x3
                div     @count_temp @x
                mfhi    @remainder
                addu    @x $0 0x1
                bne     @remainder @x endif
                
                subu    @temp_addr @to_addr 0x4
                lw      @temp 0(@temp_addr)     #load the mem_id
                
                li      @memid_loc 0x1
                var_restore @mem_id @memid_loc 
                
                blt     @temp @mem_id endif
                
                lw      @temp 0(@to_addr)
                subu    @temp @temp @hole_size
                sw      @temp 0(@to_addr)
            endif:
            }
            addu    @to_addr @to_addr 4           # to_addr += 4
            addu    @from_addr @from_addr 4           # from_addr += 4
            {
            ble     @to_addr @hcb_addr endif
                addu    @count @count 0x1
            endif:
            }
#             println_hex count_msg @count
#             println_hex from_addr_msg @from_addr
#             println_hex to_addr_msg @to_addr
#             println_hex last_addr_msg @last_addr
            j       loop
        loop_end:
        }
        addu    $v0 @hcb_addr $0
        return
    .data
    hcb_addr_msg: .asciiz "hcb_addr = "
    hole_addr_msg: .asciiz "hole_addr = "
    hole_size_msg: .asciiz "hole_size = "
    to_addr_msg: .asciiz "to_addr = "
    from_addr_msg: .asciiz "from_addr = "
    last_addr_msg: .asciiz "last_addr = "
    count_msg: .asciiz "\ncount = "
    .text
}

# find_index(mem_id, addr) --> $v0 = found?, $v2 = index if found
#     mem_id : the memory_id you want to find the addr
#     found? : zero if not found one if found
#     index : the index in the hcb list of that mem_id's control block

.text
.globl find_index
find_index:
{
    @l = $s0
    @r = $s1
    @m = $s2
    @cur_id = $s3
    @item_addr = $s4
    @len = $s5
    @hcb_addr = $s6
    @mem_id = $s7
    
    @err = $v1
    
    addu    @mem_id $a0 $0
    addu    @hcb_addr $a1 $0
    load_hcb @hcb_addr
    
    add     @l $0 $0           # l = 0
    add     @r @len $0          # r = len_list
loop:
#     if l > r: jump find_index_loop_end
    bgt     @l @r loop_end
    sub     @m @r @l           # m = r - l
    sra     @m @m 1            # div m by 2
    add     @m @m @l           # m = m + l
    
    addu    $a0 @m $0
    addu    $a1 @hcb_addr $0
    call    get_hcb_item
    addu    @item_addr $v0 $0
    
    bne     @err $0 loop_end
    lw      @cur_id 0(@item_addr)
    

#     if cur_id == mem_id
    beq     @cur_id @mem_id index_found
    #     if cur_id > mem_id: jump find_index_val_gt_mem_id
        bgt     @cur_id @mem_id curid_gt_memid
    #     else: cur_id < mem_id
        addi    @l @m 1           # l = m + 1
        j       loop
    curid_gt_memid:
        sub     @r @m 1           # r = m - 1
        j       loop

index_found:
    addu    $v0 $0 1            # found = 1
    addu    $v1 @m $0           # return index = m
    return
loop_end:
    add     $v0 $0 $0           # found = 0
    add     $v1 $0 $0           # index = 0
    return
    
.data
start_msg: .asciiz "find index start"
m_msg: .asciiz "m = "
id_msg: .asciiz "id = "
cid_msg: .asciiz "cid = "
mem_id_msg: .asciiz "mem_id = "
bigger_msg: .asciiz "cid is bigger than m"
smaller_msg: .asciiz "cid is smaller than m"
len_msg: .asciiz "length of list = "
found_msg: .asciiz "found!!"
notfound_msg: .asciiz "not found :'("

.text
}
    
.text
.globl alloc
# alloc(amt, addr) --> $v0 = mem_id, $v1 = hcb_addr
#     amt : the amount in words of memory you are requesting
#     mem_id : the id you will use to access your memory
alloc:
{
        ## PSUEDOCODE for this function
#     size_hcb_bytes = size_HCB
#     words_to_bytes size_hcb_bytes
#     end_list = HCB_ADDR + size_hcb_bytes
#     
#     if free < amt:
#         amt_requested = 3 + amt - free
#         free = 0
#     else if free >= amt:
#         amt_requested = 0
#         free = free - amt
#     top = top + amt_requested
#     save_hcb
#     
#     if amt_requested != 0: raise error
#     
#     $s6 = add_hcb_list_elem(HCB_ADDR, amt)
#     
#     move_hcb_up(amt)
#     
#     return $s6
    @hcb_addr = $s0
    @hcb_size = $s1
    @hcb_next_id = $s2
    @hcb_top = $s3 
    @hcb_free = $s4
    @hcb_len_list = $s5
    
    @mem_id = $s6
    @amt = $s7
    
    addu    @amt $a0 $0                 # move the amt to $s7
    addu    @hcb_addr $a1 $0
    
#     println start_msg
    
    
    load_hcb  @hcb_addr                 # load the HCB into $s0 - $s5 see macro
    
    blt     @hcb_free @amt alloc_free_lt_amt
    #                                   # if free < amt: jump alloc_free_lt_amt
    
    @amt_requested = $t1
    addu    @amt_requested $0 $0 
    subu    @hcb_free @hcb_free @amt                 # free = free - amt
    
    j       alloc_end_if
alloc_free_lt_amt:
    addu    @amt_requested @amt 3        # amt_requested = 3 + amt
    subu    @amt_requested @amt_requested @hcb_free  
    addu    @hcb_free $0 $0              # free = 0
alloc_end_if:
    addu    @hcb_top @hcb_top $t1        # top = top + amt_requested #top = $s3
    
    bne     @amt_requested $0 error      # if amt_requested != 0: jump error
    
    save_hcb @hcb_addr
    
    
    addu    $a0 @hcb_addr $0
    addu    $a1 @amt $0
    addu    $a2 @hcb_addr $0
    call    add_hcb_item
    addu    @mem_id $v0 $0
    
    addu    $a0 @amt $0
    addu    $a1 @hcb_addr $0
    call    move_hcb_up
    addu    @hcb_addr $v0 $0
    
    addu    $v0 @mem_id $0
    addu    $v1 @hcb_addr $0
    return

error:
    la      $a0 error_msg
    call    println
    exit
    .data
    .globl start_msg
error_msg: .asciiz "Out of memory.\n"
start_msg: .asciiz "start alloc.\n"
addr_msg: .asciiz "->addr = "
    .text
}

.text

# free(mem_id, hcb_addr) --> $v0 = hcb_addr
free:
{
        @hcb_addr = $s0
        @mem_id = $s1
        @item_addr = $s2
        @found = $s5
        @index = $s6
        
        @hole_size = $t3
        @hole_addr = $t5
        @err = $t4
        
        addu    @mem_id $a0 $0
        addu    @hcb_addr $a1 $0
        
#         println_hex mem_id_msg @mem_id
        addu $a0 @mem_id $0
        addu $a1 @hcb_addr $0
        call find_index
        addu @found $v0 $0
        addu @index $v1 $0
        
#         println_hex found_msg @found
#         println_hex index_msg @index
        
        beq     @found $0 index_not_found
        
        addu    $a0 @index $0
        addu    $a1 @hcb_addr $0
        call    get_hcb_item
        addu    @item_addr $v0 $0
        addu    @err $v1 $0
        
        bne     @err $0 get_hcb_error
        
#         println_hex err_equal_msg @err
        
#         addu    $a0 @item_addr $0
#         call    print_hcb_item
        
        lw      @hole_addr 4(@item_addr)
        lw      @hole_size 8(@item_addr)
        
        addu    $a0 @mem_id $0
        addu    $a1 @hole_addr $0
        addu    $a2 @hole_size $0
        addu    $a3 @hcb_addr $0
        call    compact
        addu    @hcb_addr $v0 $0
        
#         print_hcb @hcb_addr
        
        addu    $a0 @index $0
        addu    $a1 @hcb_addr $0
        call    del_hcb_item
        addu    @err $v0 $0
        bne     @err $0 del_hcb_error
#         println_hex err_equal_msg @err
        
#         print_hcb @hcb_addr
        
        
        addu    $v0 @hcb_addr $0
        return
        
        
    get_hcb_error:
        la      $a0 error_msg2
        call    println
        addu    $v0 @hcb_addr $0
        return
    del_hcb_error:
        la      $a0 error_msg3
        call    println
        addu    $v0 @hcb_addr $0
        return
    index_not_found:
        la      $a0 error_msg
        call    println
        addu    $v0 @hcb_addr $0
        return
        
        .data
    error_msg: .asciiz "Index not found\n"
    error_msg2: .asciiz "Error in get hcb item\n"
    error_msg3: .asciiz "Error in del hcb item\n"
    index_msg: .asciiz "index = "
    id_msg: .asciiz "id = "
    amt_msg: .asciiz "amt = "
    freed_msg: .asciiz "freed\n"
    addr_msg: .asciiz "addr = "
    err_equal_msg: .asciiz " error = "
    found_msg: .asciiz " found = "
    mem_id_msg: .asciiz " mem_id = "
        .text
}

.text
.globl __getword
# __getword(loc, mem_id, hcb_addr) --> $v0 = error, $v1 = val
__getword:
{
    @hcb_addr = $s0
    @mem_id = $s1
    @loc = $s2
    @index = $s3
    @item_addr = $s4
    @block_size = $s5
    
    @word_addr = $s6
    
    @found = $t0
    @err = $t1
    @value = $t2
    
    addu    @loc $a0 $0
    addu    @mem_id $a1 $0
    addu    @hcb_addr $a2 $0
    
    addu $a0 @mem_id $0
    addu $a1 @hcb_addr $0
    call find_index
    addu @found $v0 $0
    addu @index $v1 $0
    
    beq     @found $0 index_not_found
    
    addu    $a0 @index $0
    addu    $a1 @hcb_addr $0
    call    get_hcb_item
    addu    @item_addr $v0 $0
    addu    @err $v1 $0
    
    bne     @err $0 get_hcb_error
    
    lw      @block_size 8(@item_addr)
    bge     @loc @block_size loc_error
    blt     @loc $0 loc_error
    
    sll     @loc @loc 2     #mul by 4
    lw      @word_addr 4(@item_addr)
    addu    @word_addr @word_addr @loc
    
    lw      @value 0(@word_addr)
    
    addu    $v0 $0 $0  #error = 0
    addu    $v1 @value $0
    return
    
    index_not_found:
        la      $a0 error_msg
        call    println
        addu    $v0 $0 0x1
        addu    $v1 $0 $0
        return
    get_hcb_error:
        la      $a0 error_msg2
        call    println
        addu    $v0 $0 0x2
        addu    $v1 $0 $0
        return
    loc_error:
        la      $a0 error_msg3
        call    println
        addu    $v0 $0 0x3
        addu    $v1 $0 $0
        return
        
    .data
    error_msg: .asciiz "Memory id not found\n"
    error_msg2: .asciiz "Error in get hcb item\n"
    error_msg3: .asciiz "location not in range 0-(n-1)\n"
    .text
}

.text
.globl __putword
# __putword(value, loc, mem_id, hcb_addr) --> $v0 = error
__putword:
{
    @hcb_addr = $s0
    @mem_id = $s1
    @loc = $s2
    @index = $s3
    @item_addr = $s4
    @block_size = $s5
    
    @word_addr = $s6
    @value = $s7
    
    @found = $t0
    @err = $t1
    
    addu    @value $a0 $0
    addu    @loc $a1 $0
    addu    @mem_id $a2 $0
    addu    @hcb_addr $a3 $0
    
    addu $a0 @mem_id $0
    addu $a1 @hcb_addr $0
    call find_index
    addu @found $v0 $0
    addu @index $v1 $0
    
    beq     @found $0 index_not_found
    
    addu    $a0 @index $0
    addu    $a1 @hcb_addr $0
    call    get_hcb_item
    addu    @item_addr $v0 $0
    addu    @err $v1 $0
    
    bne     @err $0 get_hcb_error
    
    lw      @block_size 8(@item_addr)
    bge     @loc @block_size loc_error
    blt     @loc $0 loc_error
    
    sll     @loc @loc 2     #mul by 4
    lw      @word_addr 4(@item_addr)
    addu    @word_addr @word_addr @loc
    sw      @value 0(@word_addr)
    
    addu    $v0 $0 $0  #error = 0
    addu    $v1 @value $0
    return
    
    index_not_found:
        la      $a0 error_msg
        call    println
        addu    $v0 $0 0x1
        addu    $v1 $0 $0
        return
    get_hcb_error:
        la      $a0 error_msg2
        call    println
        addu    $v0 $0 0x2
        addu    $v1 $0 $0
        return
    loc_error:
        la      $a0 error_msg3
        call    println
        addu    $v0 $0 0x3
        addu    $v1 $0 $0
        return
        
    .data
    error_msg: .asciiz "Memory id not found\n"
    error_msg2: .asciiz "Error in get hcb item\n"
    error_msg3: .asciiz "location not in range 0-(n-1)\n"
    word_addr_msg: .asciiz "word address = "
    .text
}





