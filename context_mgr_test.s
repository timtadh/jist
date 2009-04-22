.text
main:
{
    {
        @hcb_addr = $s0
        @khcb_addr_loc = $s1
        @mem_id = $s2
        @loc = $t0
        @err = $t1
    
        sbrk_imm 4096 @hcb_addr
        li      $a1 1024
        add     $a0 @hcb_addr $zero
        call    initialize_heap
    
        addu    $a0 $0 0x10
        addu    $a1 @hcb_addr $zero
        call    alloc
        addu    @mem_id $v0 $zero
        addu    @hcb_addr $v1 $zero
    
        khcb_writeback_2 @hcb_addr
    
        addu    @loc $0 $0
        put     @loc @mem_id @hcb_addr $0 @err
    }
    {
        @head = $s0
        @current = $s1
        @counter = $s2
        @khcb_addr = $s3
        addu $a0 $zero 1
        addu $a1 $zero 11
        call ll_init
        addu @head $v0 $zero
        
        addu $a0 @head $zero
        addu $a1 $zero 2
        addu $a2 $zero 22
        call ll_append
        
        addu $a0 @head $zero
        addu $a1 $zero 3
        addu $a2 $zero 33
        call ll_append
        addu @current $v0 $zero
        
        addu $a0 @head $zero
        addu $a1 $zero 4
        addu $a2 $zero 44
        call ll_append
        
        khcb_getaddr_2 @khcb_addr
        print_hcb @khcb_addr
        
        addu $a0 @head $zero
        addu $a1 @current $zero
        call ll_remove
        addu @head $v0 $zero
        
        khcb_getaddr_2 @khcb_addr
        print_hcb @khcb_addr
        
        addu $a0 @head $zero
        call ll_print
        
        li @counter 10
        addu @current @head $zero
        loop:
            addu $a0 @head $zero
            addu $a1 @current $zero
            call ll_next
            addu @current $v0 $zero
            addu $a0 @current $zero
            call print_int
            
            li $a0 32
            call print_char
            addi @counter @counter -1
        bgtz @counter loop
        li $a0 10
        call print_char
        exit
    }
}