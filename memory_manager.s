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

# del_hcb_list_elem(index, addr) --> $v0 = error
#     mem_id : the mem_id you want to remove from the list
#     error : 0 if success error code otherwise
#define del_hcb local
    #     index = $s7
    #     to_addr = $t0
    #     from_addr = $t1
    #     last_addr = $t2
    #     temp = $t3
    #     err = $v1
    #     HCB_ADDR = $s0
    #     size_HCB = $s1
    #     free = $s4
    #     len_list = $s5
    #     -------------------------------
    #     load_hcb
    #     to_addr, err = get_hcb_list_elem(mem_id)
    #     if err: jump get_hcb_list_elem_error
    #     from_addr = to_addr + 3*4
    #     hcbtop  last_addr HCB_ADDR size_HCB
    #     while (from_addr <= last_addr)
    #     {
    #         lw      temp 0(from_addr)
    #         sw      temp 0(to_addr)
    #         from_addr += 4
    #         to_addr += 4
    #     }
    #     len_list -= 1
    #     size_HCB -= 3
    #     free += 3
    #     save_hcb
        __save_frame
        addu    $s7 $a0 $0          # put the index into $s7
        addu    $s0 $a1 $0
#         {
#             ##print_hcb
#             load_hcb
#             la      $a0 del_index_msg
#             call    print
#             addu    $a0 $s7 $0
#             call    println_hex
#             la      $a0 hcb_addr_start_msg
#             call    print
#             addu    $a0 $s0 $0
#             call    println_hex
#             la      $a0 hcb_addr_end_msg
#             call    print
#             addu    $t2 $s1 $0          # last_addr = size_HCB
#             hcbtop  $a0 $s0 $t2         # get the hcbtop using a macro, last_addr = $t2
#             call    println_hex
#             la      $a0 index_addr_msg
#             call    print
#             addu    $a0 $s7 $0
#             get_hcb
#             addu    $a0 $v0 $0
#             quickstore $a0
#             call    println_hex
#             la      $a0 old_index_msg
#             call    print
#             quickrestore $t0
#             quickstore $t0
#             lw      $a0 0($t0)
#             call    println_hex
#             lw      $a0 48($t0)
#             call    println_hex
#             
#             
#             #call    println_hex
#         }
        load_hcb $s0
        addu    $a0 $s7 $0
        get_hcb
        #call get_hcb_list_elem      # get the addr of the element
    #     if err: jump del_hcb_list_elem_error
        bne     $v1 $0 del_hcb_list_elem_error
        addu    $t0 $v0 $0          # to_addr = $t0
        addu    $t1 $t0 12          # from_addr = to_addr + 3*4
        addu    $t2 $s1 $0          # last_addr = size_HCB
        hcbtop  $t2 $s0 $t2         # get the hcbtop using a macro, last_addr = $t2
    loop:
    #     if from_addr > last_addr: jump del_hcb_list_elem_loop_end
        bgt     $t1 $t2 loop_end
        lw      $t3 0($t1)          # lw      temp 0(from_addr)
        sw      $t3 0($t0)          # sw      temp 0(to_addr)
        addu    $t1 $t1 4           # from_addr += 4
        addu    $t0 $t0 4           # to_addr += 4
        j       loop
    loop_end:
        subu    $s5 $s5 1           # len_list -= 1
        subu    $s1 $s1 3           # size_HCB -= 3
        addu    $s4 $s4 3           # free += 3
        save_hcb $s0
        
        add     $v0 $0 $0           # error = 0 success!
        j       end
    .data
    del_error_msg: .asciiz "del error"
    del_index_msg: .asciiz "del index = "
    hcb_addr_start_msg: .asciiz "HCB address start_addr = "
    hcb_addr_end_msg: .asciiz "HCB address end_addr = "
    index_addr_msg: .asciiz "Index address = "
    new_index_msg: .asciiz "new index = "
    old_index_msg: .asciiz "old index = "
    .text
    del_hcb_list_elem_error:
        la      $a0 del_error_msg
        call    println
        addi    $v0 $0 1            # move error = 1 to output
        j       end
    end:
#             la      $a0 new_index_msg
#             call    print
#             quickrestore $t0
#             lw      $a0 0($t0)
#             call    println_hex
    __restore_frame
#end

# # compact (hole_addr, hole_size, hcb_addr) --> new_hcb_addr
# #define compact local
#     #     from_addr = $t0
#     #     to_addr = $t1
#     #     last_addr = $t2
#     #     temp = $t3
#     #     hcb_addr = $s0
#     #     while (from_addr <= last_addr)
#     #     {
#     #         lw  temp 0(from_addr)
#     #         sw  temp 0(to_addr)
#     #         if (from_addr == hcb_addr)
#     #         {
#     #             hcb_addr = to_addr
#     #             sw  hcb_addr HCB_ADDR
#     #         }
#     #         to_addr += 4
#     #         from_addr += 4
#     #     }
#     .text
#         addu    $s6 $a0 $0          # $s6 = hole_addr
#         addu    $s7 $a1 $0          # $s7 = hole_size
#         addu    $s0 $a2 $0
#         la      $a0 hole_addr_msg
#         call    print
#         addu    $a0 $s6 $0
#         call    println_hex
#         la      $a0 hole_size_msg
#         call    print
#         addu    $a0 $s7 $0
#         call    println_hex
#         #call    println_hex
#         load_hcb $s0                # load the control block
#         addu    $t0 $s7 $0           # move hole_size into $t0
#         words_to_bytes $t0          # convert hole_size to bytes
#         addu    $t1 $s6 $0          # to_addr = $t1
#         addu    $t2 $s1 $0          # move size_HCB into $t0
#         hcbtop  $t2 $s0 $t2         # last_addr = $t1
#     compact_loop:
#     #   if from_addr > last_addr: jump compact_loop_end
#         bgt     $t0 $t2 compact_loop_end
#         lw      $t3 0($t0)          # lw  temp 0(from_addr)
#         sw      $t3 0($t1)          # sw  temp 0(to_addr)
#     #         if (from_addr == hcb_addr)
#         bne     $t0 $s0 compact_loop_endif
#         addu    $s0 $t1 $0          # hcb_addr = to_addr
#     compact_loop_endif:
#         addu    $t1 $t1 4           # to_addr += 4
#         addu    $t0 $t0 4           # from_addr += 4
#     compact_loop_end:
#         j       end
#     .data
#     hole_addr_msg: .asciiz "hole_addr = "
#     hole_size_msg: .asciiz "hole_size = "
#     .text
# end:
#         addu    $v0 $s0 $0
# #end

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
.globl add_to_hcb
add_to_hcb:
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
#     move_to_addr = move_from_addr+amt
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
    addu    @move_from $s1 $0
    sll     @move_from @move_from 2
    addu    @move_from @hcb_addr @move_from
    addu    @move_to @move_from @amt
loop:
#   if hcb_addr < move_from_addr: jump loop_end
    bgt     @hcb_addr @move_from loop_end
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

    
    # find_index(mem_id, addr) --> $v0 = found?, $v2 = index if found
    #     mem_id : the memory_id you want to find the addr
    #     found? : zero if not found one if found
    #     index : the index in the hcb list of that mem_id's control block
    
    .text
    .globl find_index
    find_index:
    {
    #     l = $s0
    #     r = $s1
    #     len_list = $s5
    #     m = $s2
    #     addr = $s4
    #     err = $v1
    #     val = $s3
    #     mem_id = $s7
    #     temp = $t2
    #     ----------------------------------
    #     l = 0
    #     r = len_list
    #     while (l <= r) 
    #     {
    #         m = l + (r - l) / 2  // Note: not (l + r) / 2  may overflow!!
    #         addr, err = get_hcb_list_elem(m)
    #         if err: break;
    #         lw  val 0(addr)
    #         if (val > mem_id)
    #             r = m - 1
    #         else if (val < mem_id)
    #             l = m + 1
    #         else
    #             return 1, addr, m // found
    #     }
    #     return 0, 0, 0 // not found
        add     $s7 $a0 $0          # mem_id = $s7
        #la      $a0 start_msg
        #call    println
#         la      $a0 id_msg
#         call    print
#         add     $a0 $s7 $0          # arg1 = m
#         call    println_hex
        load_hcb $a1
        la      $a0 len_msg
        call    print
        add     $a0 $s5 $0
        call    println_hex
        add     $s0 $0 $0           # l = 0
        add     $s1 $s5 $0          # r = len_list
    find_index_loop:
    #     if l > r: jump find_index_loop_end
        bgt     $s0 $s1 find_index_loop_end
        sub     $s2 $s1 $s0         # m = r - l
        li      $t2 2               # temp = 2
        div     $s2 $s2 $t2         # m = m/2
        add     $s2 $s2 $s0         # m = m + l
#         la      $a0 m_msg
#         call    print
#         add     $a0 $s2 $0          # arg1 = m
#         call    println_hex
        add     $a0 $s2 $0
        #call    get_hcb_list_elem   # get the addr of that list element
#         get_hcb
    #     if err != 0: jump find_index_loop_end (ie there was an error return not found)
        bne     $v1 $0 find_index_loop_end
        add     $s4 $v0 $0          # addr = $v0 (the address returned by get_hcb_list_elem)
        lw      $s3 0($s4)          # val = 0(addr of the element) ie the mem_id of m
#         la      $a0 cid_msg
#         call    print
#         add     $a0 $s3 $0          # arg1 = m
#         call    println_hex
        #lw      $s3 0($s4)          # val = 0(addr of the element) ie the mem_id of m
    #     if val = mem_id: jump find_index_found
        beq     $s3 $s7 find_index_found
    #     if val > mem_id: jump find_index_val_gt_mem_id
        bgt     $s3 $s7 find_index_val_gt_mem_id
    #     else: val < mem_id
#         la      $a0 bigger_msg
#         call    println
        addi    $s0 $s2 1           # l = m + 1
        j       find_index_loop
    find_index_val_gt_mem_id:
#         la      $a0 smaller_msg
#         call    println
        sub     $s1 $s2 1           # r = m - 1
        j       find_index_loop
    find_index_found:
#         la      $a0 m_msg
#         call    print
#         add     $a0 $s2 $0          # arg1 = m
#         call    println_hex
        addi    $v0 $0 1            # found = 1
        add     $v1 $0 $s2          # return index = m
        return
    find_index_loop_end:
        add     $v0 $0 $0           # found = 0
        add     $v1 $0 $0           # index = 0
        return
        
    .data
    start_msg: .asciiz "find index start"
    m_msg: .asciiz "m = "
    id_msg: .asciiz "id = "
    cid_msg: .asciiz "cid = "
    bigger_msg: .asciiz "cid is bigger than m"
    smaller_msg: .asciiz "cid is smaller than m"
    len_msg: .asciiz "length of list = "
    
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
    
    println start_msg
    
    
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
    call    add_to_hcb
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
    
    # free(mem_id) --> Null
    #     finds the mem_id using the mem_id find_mem_id method DONE
    #     get the amount to free
    #     Removes the mem_id from the HCB list DONE
    #     Subtracts 1 from the size of the HCB list DONE
    #     Adjusts the HCB's size DONE
    #     freed += 3 for the amount taken off the HCB DONE
    #     freed += amt freed
    #     saves the HCB
    #     compacts the heap using the compact method DONE
#     .globl free
#     free:
#     {
#     #     mem_id = $s7
#     #     index = $s6
#     #     found = $v0
#     #     addr = $t0
#     #     err = $v1
#     #     block_addr = $s0, $s7
#     #     block_amt = $s1, $s6
#     #     free = $s4
#     #     -----------------------------------------
#     #     found, index = find_index(mem_id)
#     #     if not found: jump free_error
#     #     addr, err = get_hcb_list_elem(index)
#     #     if err: jump free_error
#     #     lw block_addr 4(addr)
#     #     lw block_amt 8(addr)
#     #     del_hcb_list_elem(index)
#     #     $s7 = block_addr
#     #     $s6 = block_amt
#     #     load_hcb
#     #     free += block_amt
#     #     save_hcb
#     #     compact(block_addr, block_amt)
#         addu    $s7 $a0 $0          # mem_id = $s7
#         la      $a0 id_msg
#         call    print
#         add     $a0 $s7 $0
#         call    println_hex
#         add     $a0 $s7 $0
#         call    find_index
#         beqz    $v0 free_error2      # if not found: jump free_error
#         addu    $s6 $v1 $0          # index = $s6
#         la      $a0 index_msg
#         call    print
#         add     $a0 $s6 $0
#         call    println_hex
#         addu    $a0 $s6 $0
#         #call    get_hcb_list_elem   # get_hcb_list_elem(index)s
#         
#         addu    $a0 $s6 $0
#         get_hcb
#         
#         bne     $v1 $0 free_error   # if err: jump free_error
#         addu    $t0 $v0 $0          # addr = $t0
#         lw      $s0 4($t0)          # block_addr = $s0
#         lw      $s1 8($t0)          # block_amt = $s1
#         
#         la      $a0 amt_msg
#         call    print
#         add     $a0 $s0 $0
#         call    println_hex
#         
#         addu    $a0 $s6 $0
#         del_hcb
#         #call    del_hcb_list_elem   # del_hcb_list_elem(index)
#         #call    println_hex
#         
#         addu    $s7 $s0 $0          # $s7 = block_addr
#         addu    $s6 $s1 $0          # $s6 = block_amt
#         
#         la      $a0 amt_msg
#         call    print
#         add     $a0 $s6 $0
#         call    println_hex
#         
#         load_hcb 
#         addu    $s4 $s4 $s6         # free += block_amt
#         save_hcb
#         
#         
#         addu    $a0 $s7 $0
#         addu    $a1 $s6 $0
#         compact             # compact(block_addr, block_amt)
# #         la      $a0 freed_msg
# #         call    println
#         return
#     free_error:
#         la      $a0 error_msg
#         call    println
#         return
#     free_error2:
#         la      $a0 error_msg2
#         call    println
#         return
#     
#         .data
#     error_msg: .asciiz "Get HCB error\n"
#     error_msg2: .asciiz "Find Index Error in Free\n"
#     index_msg: .asciiz "index = "
#     id_msg: .asciiz "id = "
#     amt_msg: .asciiz "amt = "
#     freed_msg: .asciiz "freed\n"
#         .text
#     }
#     
#     # get_addr(id) --> $v0 = found?, $v1 = addr
#     get_addr:
#     {
#         addu    $s7 $a0 $0          # mem_id = $s7
#         call    find_index
#         beqz    $v0 id_not_found      # if not found: jump free_error
#         addu    $s6 $v1 $0          # index = $s6
#         addu    $a0 $s6 $0
#         get_hcb
#         bne     $v1 $0 hcb_error   # if err: jump free_error
#         addu    $s0 $v0 $0          # addr = $s0
#         lw      $s1 4($s0)          # load the address of the memory into $s1
#         
#         addu    $v0 $0 1
#         addu    $v1 $s1 $0
#         return
#         
#     id_not_found:
#         la      $a0 id_not_found_msg
#         call    println
#         addu    $v0 $0 $0
#         addu    $v1 $0 $0
#         return
#     hcb_error:
#         la      $a0 hcb_error_msg
#         call    println
#         addu    $v0 $0 $0
#         addu    $v1 $0 $0
#         .data
#     id_not_found_msg: .asciiz "Could not find id"
#     hcb_error_msg: .asciiz "Could not get hcb element for index"
#         .text
#         return
#     }













