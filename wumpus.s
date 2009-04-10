#include stdlib.s

.data
wdata:      .space 16   #for locations, etc.
str_buf:    .space 100
act_choice: .asciiz "Shoot or move? (s or m)\n? "
lose_msg:   .asciiz "HA HA HA - YOU LOSE!"
win_msg:    .asciiz "HEE HEE HEE - THE WUMPUS'LL GET YOU NEXT TIME!"
ask_instr:  .asciiz "Show instructions? (y/n)\n? "
comma:      .asciiz ", "
prompt:     .asciiz "\n? "
move_msg:   .asciiz "Choose a room: "
wrooms:      .byte 2,5,8,    1,3,10,     2,4,12,     3,5,14,     1,4,6
            .byte 5,7,15,   6,8,17,     1,7,9,      8,10,18,    2,9,11
            .byte 10,12,19, 3,11,13,    12,14,20,   4,13,15,    6,14,16
            .byte 15,17,20, 7,16,18,    9,17,19,    11,18,20,   13,16,19
intro2: .ascii "Wumpus:\n"
        .ascii "    The wumpus is not bothered by hazards. (He has sucker feet and is too big\n"
        .ascii "    for a bat to lift.)  Usually he is asleep.  two things wake him up: you \n"
        .ascii "    shooting an arrow or you entering his room. If the wumpus wakes he moves \n"
        .ascii "    (p=.75) one room or stays still (p=.25).  After that, if he is where you\n"
        .ascii "    are, he eats you up and you lose!\n\n"
        .ascii "YOU\n"
        .ascii "    Each turn you may move or shoot a crooked arrow.\n"
        .ascii "    Moving: You can move one room (thru one tunnel).\n"
        .ascii "    Arrows: You have 5 arrows. You lose when you run out.\n"
        .ascii "        Each arrow can go from 1 to 5 rooms. You aim by telling the computer the\n"
        .ascii "        room number you want the arrow to go to. If the arrow can't go that way \n"
        .ascii "        (no tunnel) it moves at random to the next room.\n"
        .ascii "        If the arrow hits the wumpus, you win.\n"
        .ascii "        If the arrow hits you, you lose.\n\n"
        .asciiz "Hit Return.\n"
intro:  .ascii  "WELCOME TO HUNT THE WUMPUS!\n"
        .ascii  "   The Wumpus lives in a cave of 20 rooms. Each room has 3 tunnels leading to \n"
        .ascii  "   other rooms. (Look at a dodecahedron to see how this works-if you don't know\n"
        .ascii  "   what a dodecahedron is, ask someone.)\n\n"
        .ascii "HAZARDS\n"
        .ascii "Bottomless Pits:\n"
        .ascii "    Two rooms have bottomless pits in them. If you go there, you fall into the \n"
        .ascii "    pit (& lose!)\n"
        .ascii "Super Bats:\n"
        .ascii "    Two other rooms have Super Bats. If you go there, a bat grabs you and takes\n"
        .ascii "    you to some other room at random. (which may be troublesome)\n\n"
        .asciiz "Hit Return.\n"
.text

#define qprint_char
    li $a0 %1
    call print_char
#end

#define get_char
    call read_char
    add $a0 $v0 $zero
    call print_char
    qprint_char 10
#end

#define qprint_string
    la $a0 %1
    call print
#end

#define clear_console
    li $t9 24
    li $a0 10
    clear_loop:
        exec print_char
        addi $t9 $t9 -1
        bgtz $t9 clear_loop
#end
    

# fastrand limit
#   returns:
#       v0: random number
#       stores last number in wdata[0]
fastrand:
{
    la $t4 wdata
    lb $t0 0($t4)
    li $t2 33614
    multu $t0 $t2
    mflo $t1
    srl $t1 $t1 1
    mfhi $t3
    addu $t0 $t1 $t3
    bltz $t0 overflow
        b limit
    overflow:
        sll $t0 $t0 1
        srl $t0 $t0 1
        addiu $t0 1
    limit:
    sb $t0 0($t4)
    div $t0 $a0
    mfhi $v0
    return
}

#define choose
    addi $a0 $zero %1
    call fastrand
    add %2 $v0 $zero
#end

start_game:
{
    #s0: iteration count
    #s1: player pos
    #s2: wumpus pos
    #s3: pit 1
    #s4: pit 2
    #s5: bat 1
    #s6: bat 2
    li $s0 0
    rebuild:
        addi $s0 $s0 1
        #player
        li $a0 20
        call fastrand
        add $s1 $v0 $zero
        
        #wumpus
        choose 20 $s2
        beq $s2 $s1 rebuild
        #pit 1
        choose 20 $s3
        beq $s3 $s2 rebuild
        beq $s3 $s1 rebuild 
        #pit 2
        choose 20 $s4
        beq $s4 $s3 rebuild
        beq $s4 $s2 rebuild
        beq $s4 $s1 rebuild
        #bat 1
        choose 20 $s5
        beq $s5 $s4 rebuild
        beq $s5 $s3 rebuild
        beq $s5 $s2 rebuild
        beq $s5 $s1 rebuild
        #bat 2
        choose 20 $s6
        beq $s6 $s5 rebuild
        beq $s6 $s4 rebuild
        beq $s6 $s3 rebuild
        beq $s6 $s2 rebuild
        beq $s6 $s1 rebuild
    success:
        return
}

get_room:
{
    la $t0 wrooms
    li $t1 3
    mul $t1 $t1 $a0
    add $t0 $t0 $t1
    lb $v0 0($t0)
    #add $a0 $v0 $zero
    #call print_int
    lb $v1 1($t0)
    lb $t9 2($t0)
    return
}

.globl main
main:
    li $s0 10
    la $t0 wdata    #seed random number generator
    sb $s0 0($t0)
    clear_console
    
    la $a0 ask_instr    #ask y/n for instructions
    call print
    get_char
    addi $t0 $zero 121
    bne $v0 $t0 init_game
        clear_console
        la $a0 intro
        exec print
        exec readln
        clear_console
        la $a0 intro2
        exec print
        exec readln
        clear_console
    init_game:
        exec start_game
        la $s7 wdata
        sb $s1 1($s7)
        sb $s2 2($s7)
        sb $s3 3($s7)
        sb $s4 4($s7)
        sb $s5 5($s7)
        sb $s6 6($s7)
        li $s0 6
    mainloop:
        la $s7 wdata
        li $s0 6
        debugprint:
            addi $s0 $s0 -1
            addi $s7 $s7 1
            lb $a0 0($s7)
            call print_int
            qprint_char 32
            bgez $s0 debugprint
        qprint_char 10
        skipdebug:
        
        la $s7 wdata
        lb $s1 1($s7)
        lb $s2 2($s7)
        lb $s3 3($s7)
        lb $s4 4($s7)
        lb $s5 5($s7)
        lb $s6 6($s7)
        
        #s0: iteration count
        #s1: player pos
        #s2: wumpus pos
        #s3: pit 1
        #s4: pit 2
        #s5: bat 1
        #s6: bat 2
        
        la $a0 act_choice
        call print
        get_char
        li $t0 113  #q
        beq $t0 $v0 userquit
        li $t0 109
        beq $t0 $v0 usermove
        b mainloop
        usermove:
            la $s0 wdata
            sb $s1 1($s0)
            qprint_string move_msg
            add $a0 $s1 $zero
            call get_room
            add $a0 $v0 $zero
            add $s6 $v0 $zero
            call print_int
            qprint_string comma
            add $a0 $v1 $zero
            add $s7 $v1 $zero
            call print_int
            qprint_string comma
            add $a0 $t9 $zero
            add $s8 $t9 $zero
            call print_int
            qprint_string prompt
            
            la $a0 str_buf
            call read_int
            beq $v0 $s6 in_ok
            beq $v0 $s7 in_ok
            beq $v0 $s8 in_ok
            qprint_char 10
            b usermove
            in_ok:
                addi $v0 $v0 -1
                sb $v0 1($s0)
                b mainloop
        b mainloop
    userquit:
        exit
