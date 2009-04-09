# allocate_array size_reg dst
#     size_reg = size of array
#define allocate_array local
    li      $v0 9               # system call code for sbrk
    addu    $a0 %1 0x1          # amount + 1
    sll     $a0 $a0 2           # mul amt by 4
    syscall                     # make the call
    addu    %2 $v0 $0           # move to dst
    sw      %1 0(%2)            # store size of array in first slot 
#end

# get error value addr index
#define get local
    lw      $t0 0(%3)           # $t0 = size
    addu    $t1 %4 0x1          # $t1 = index + 1
    bgt     $t1 $t0 toobig      # if index >= size: j toobig
    sll     $t1 $t1 2           # mul index by 4
    addu    $t1 %3 $t1          # index = addr + index
    lw      %2 0($t1)           # lw  value from index
    addu    %1 $0 $0            # error = 0
    b       end
toobig:
    addu    %1 $0 0x1           # error = 1
    addu    %2 $0 $0            # value = 0
end:
#end

# put error value addr index
#define put local
    lw      $t0 0(%3)           # $t0 = size
    addu    $t1 %4 0x1          # $t1 = index + 1
    bgt     $t1 $t0 toobig      # if index >= size: j toobig
    sll     $t1 $t1 2           # mul index by 4
    addu    $t1 %3 $t1          # index = addr + index
    sw      %2 0($t1)           # lw  value from index
    addu    %1 $0 $0            # error = 0
    b       end
toobig:
    addu    %1 $0 0x1           # error = 1
end:
#end