# Steve Johnson
# Brainf*ck interpreter for a program stored in static data
# safe for multitasking

@LEFT   = 60
@RIGHT  = 62
@PLUS   = 43
@MINUS  = 45
@PERIOD = 46
@COMMA  = 44
@LEFTB  = 91
@RIGHTB = 93

    .data
header:         .asciiz "Welcome to Muckfips. Your program will now be executed."

program_text:   .asciiz ">+++++++++[<++++++++>-]<.>+++++++[<++++>-]<+.+++++++..+++.>>>++++++++[<++++>-]<.>>>++++++++++[<+++++++++>-]<---.<<<<.+++.------.--------.>>+.-----------------------."

array:          .space 1024
    .text
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
    
    la @tptr program_text
    la @dptr array
    
    loop:
        lb @input 0(@tptr)
        beqz @input quitmf
        
        #addu $a0 @input $zero
        #call print_char
        
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
            lb $a0 0(@dptr)
            call print_char
            
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
        
        addu @comp $zero @LEFTB
        bne @input @comp not_leftb
            #do nothing
            addi @tptr @tptr 1
            b loop
        not_leftb:
        
        addu @comp $zero @RIGHTB
        bne @input @comp not_rightb
        {
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