# Daniel DeCovnick & Steve Johnson
# mappedio.s
# Global macros for reading and writing using mmio

# _read_char dest
#     Waits for keyboard input and stores one character in dest. Blocking.
#define _read_char global
    li  $t0 0xffff0000                  #init t0 to base address for mmio registers
blocking_read_loop:
    lw   $t1 0($t0)                     #load address of status reg
    andi $t1 $t1 1                      #check status
    beq  $t1 $zero blocking_read_loop   #loop if not ready
    lw   %1 4($t0)                      #save return value
#end

# _write_char char
#     char : the character to print. Blocks until a character is written.
#define _write_char global
    li  $t0 0xffff0008                  #init t0 to base address for mmio registers
blocking_write_loop:
    lw   $t1 0($t0)                     #get contents of status reg
    andi $t1 $t1 1                      #get ready bit
    beq  $t1 $zero blocking_write_loop  #loop if not ready
    sw   %1 4($t0)                     #store output into the tx register
#end