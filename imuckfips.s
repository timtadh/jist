# Steve Johnson
# This is an interactive Brainf*ck interpreter.

@LEFT   = 60
@RIGHT  = 62
@PLUS   = 43
@MINUS  = 45
@PERIOD = 46
@COMMA  = 44
@LEFTB  = 91
@RIGHTB = 93
@ESC    = 27
@LF     = 10

    .data
header:         .ascii  "Welcome to iMuckfips, the interactive Muckfips prompt!\n"
                .asciiz  "Enter a program. Press Return to show the output buffer, Esc to quit."
program_text:   .space 4048
output_buffer:  .space 4048
array:          .space 4048

    .text

print_output:
{
    sb $zero 0($a0)
    la $a0 output_buffer
    call print
    la $v0 output_buffer
    return
}

    .globl main
main:
{
    println header
    @tptr = $s0
    @dptr = $s1
    @bracketcount = $s2
    @input = $s3
    @temp = $s4
    @comp = $s5
    @state = $s6
    @optr = $s7
    
    la @tptr program_text
    la @dptr array
    la @optr output_buffer
    
    loop:
        bnez @state in_from_buffer
            _read_char @input
            addu @comp $zero @ESC
            bne @input @comp not_exit
                li $a0 10
                call print_char
                exit
            not_exit:
            
            _write_char @input
            
            addu @comp $zero @LF
            bne @input @comp end_input
                addu $a0 @optr $zero
                call print_output
                addu @optr $v0 $zero
            sb @input 0(@tptr)
            
            b end_input
        in_from_buffer:
            lb @input 0(@tptr)
            li @state 0
        end_input:
        
        addu @comp $zero @PLUS
        bne @input @comp not_plus
            lb @temp 0(@dptr)
            addi @temp @temp 1
            sb @temp 0(@dptr)
            
            addi @tptr @tptr 1
            b loop
        not_plus:
        
        addu @comp $zero @MINUS
        bne @input @comp not_minus
            lb @temp 0(@dptr)
            addi @temp @temp -1
            sb @temp 0(@dptr)
            
            addi @tptr @tptr 1
            b loop
        not_minus:
        
        addu @comp $zero @RIGHT
        bne @input @comp not_right
            addi @dptr @dptr 1
            
            addi @tptr @tptr 1
            b loop
        not_right:
        
        addu @comp $zero @LEFT
        bne @input @comp not_left
            addi @dptr @dptr -1
            
            addi @tptr @tptr 1
            b loop
        not_left:
        
        addu @comp $zero @PERIOD
        bne @input @comp not_period
            lb @temp 0(@dptr)
            sb @temp 0(@optr)
            addi @optr @optr 1
            
            addi @tptr @tptr 1
            b loop
        not_period:
        
        addu @comp $zero @COMMA
        bne @input @comp not_comma
            _read_char @temp
            sb @temp 0(@dptr)
            
            addi @tptr @tptr 1
            b loop
        not_comma:
        
        addu @comp $zero @RIGHTB
        bne @input @comp not_rightb
        {
            li $a0 10
            call print_char
            println program_text
            
            lb @temp 0(@dptr)
            beqz @temp bracket_done
                li @bracketcount 1
                bracket_loop:
                    addi @tptr @tptr -1
                    lb @temp 0(@tptr)
                    addu @comp $zero @LEFTB
                    bne @temp @comp not_leftb
                        addi @bracketcount @bracketcount -1
                    not_leftb:
                    addu @comp $zero @RIGHTB
                    bne @temp @comp not_rightb
                        addi @bracketcount @bracketcount 1
                    not_rightb:
                bgtz @bracketcount bracket_loop
            bracket_done:
            addi @tptr @tptr 1
            b loop
        }
        not_rightb:
        addi @tptr @tptr 1
    b loop
    quitmf:
    exit
}