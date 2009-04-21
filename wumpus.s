#include stdlib.s
#include sys_macros.m

.data
wdata:      .space 7    #for locations, etc.
adjrooms:   .space 3
str_buf:    .space 100
act_choice: .asciiz "Shoot or move? (s or m)\n? "
death_w:    .asciiz "OM NOM NOM, WUMPUS HUNGRY!!! (you die)\n"
death_p:    .asciiz "AAAAAaaaaaaaahhhhh... *splat*\n"
win_msg:    .asciiz "*Whoosh!* *splat* MMRRROOOWWWWWWW! *thud* (you win)"
ask_instr:  .asciiz "Show instructions? (y/n)\n? "
comma:      .asciiz ", "
prompt:     .asciiz "\n? "
room_msg:   .asciiz "Current room: "
move_msg:   .asciiz "\nAdjacent rooms: "
w_msg:      .asciiz "I smell a wumpus!\n"
p_msg:      .asciiz "I feel a draft.\n"
b_msg:      .asciiz "Bats nearby!\n"
msg_fly:    .asciiz "\nYou are grabbed by a giant bat and flown to another room..."
wump_move:  .asciiz "You woke the wumpus! He has moved to another room..."
wump_kill:  .asciiz "Thou hast slain the mighty wumpus!"
wrooms:     .byte 2,5,8,    1,3,10,     2,4,12,     3,5,14,     1,4,6
            .byte 5,7,15,   6,8,17,     1,7,9,      8,10,18,    2,9,11
            .byte 10,12,19, 3,11,13,    12,14,20,   4,13,15,    6,14,16
            .byte 15,17,20, 7,16,18,    9,17,19,    11,18,20,   13,16,19

intro2: .ascii "Wumpus:\n"
        .ascii "    The wumpus is not bothered by hazards. (He has sucker feet and is too big\n"
        .ascii "    for a bat to lift.)  Usually he is asleep.  two things wake him up: you \n"
        .ascii "    shooting an arrow or you entering his room. If the wumpus wakes he moves \n"
        .ascii "    (p=.75) one room or stays still (p=.25).  After that, if he is where you\n"
        .ascii "    are, he eats you up and you lose!\n\n"
        .ascii "YOU:\n"
        .ascii "    Each turn you may move or shoot a crooked arrow.\n"
        .ascii "    Moving: You can move one room (thru one tunnel).\n"
        .ascii "    Arrows: You have 5 arrows. You lose when you run out.\n"
        .ascii "        Each arrow can go from 1 to 5 rooms. You aim by telling the computer the\n"
        .ascii "        room number you want the arrow to go to. If the arrow can't go that way \n"
        .ascii "        (no tunnel) it moves at random to the next room.\n"
        .ascii "        If the arrow hits the wumpus, you win.\n"
        .ascii "        If the arrow hits you, you lose.\n\n"
        .asciiz "Hit Return to continue.\n"
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
        .asciiz "Press q to quit at any time. Hit Return to continue.\n"
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

#define load_data
    la $s7 wdata
    #DOES NOT LOAD PLAYER POSITION - ON PURPOSE
    lb $s1 1($s7)
    lb $s2 2($s7)
    lb $s3 3($s7)
    lb $s4 4($s7)
    lb $s5 5($s7)
    lb $s6 6($s7)
#end

#define print_debug
    la $s7 wdata
    li $s0 6
    debugprint:
        addi $s0 $s0 -1
        addi $s7 $s7 1
        lb $a0 0($s7)
        addi $a0 $a0 1  #positions start at 0 internally, 1 externally
        call print_int
        qprint_char 32
        bgtz $s0 debugprint
    skipdebug:
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
    @i = $s0
    @player = $s1
    @wumpus = $s2
    @pit_1 = $s3
    @pit_2 = $s4
    @bat_1 = $s5
    @bat_2 = $s6
    
    li @i 0
    rebuild:
        addi @i @i 1
        #player
        li $a0 20
        call fastrand
        add @player $v0 $zero
        
        #wumpus
        choose 20 $s2
        beq @wumpus @player rebuild
        #pit 1
        choose 20 $s3
        beq @pit_1 @wumpus rebuild
        beq @pit_1 @player rebuild 
        #pit 2
        choose 20 $s4
        beq @pit_2 @pit_1 rebuild
        beq @pit_2 @wumpus rebuild
        beq @pit_2 @player rebuild
        #bat 1
        choose 20 $s5
        beq @bat_1 @pit_2 rebuild
        beq @bat_1 @pit_1 rebuild
        beq @bat_1 @wumpus rebuild
        beq @bat_1 @player rebuild
        #bat 2
        choose 20 $s6
        beq @bat_2 @bat_1 rebuild
        beq @bat_2 @pit_2 rebuild
        beq @bat_2 @pit_1 rebuild
        beq @bat_2 @wumpus rebuild
        beq @bat_2 @player rebuild
    success:
        return
}

load_adjacent_rooms:
{
    li $t1 3
    la $t0 wrooms
    mul $t1 $t1 $a0
    add $t0 $t0 $t1
    li $t1 3
    la $t2 adjrooms
    
    another_room:
        lb $t3 0($t0)
        sb $t3 0($t2)
        addi $t0 $t0 1
        addi $t2 $t2 1
        addi $t1 $t1 -1
    bgez $t1 another_room
    return
}

check_status:
{
    load_data
    #s1: player pos
    #s2: wumpus pos
    #s3: pit 1
    #s4: pit 2
    #s5: bat 1
    #s6: bat 2
    #s7: data array address
    
    beq $s1 $s2 wump_death
    beq $s1 $s3 pit_death
    beq $s1 $s4 pit_death
    
    beq $s1 $s5 omgbat
    beq $s1 $s6 omgbat
    
    return
    
    omgbat:
    la $a0 msg_fly
    call print
    choose 20 $t0
    sb $t0 1($s7)
    return
    
    pit_death:
        la $a0 death_p
        b game_over
    wump_death:
        la $a0 death_w
    game_over:
    call print
    exit
}

#define print_status
    qprint_char 10
    load_data
    
    add $a0 $s1 $zero
    call load_adjacent_rooms
    
    la $s7 adjrooms
    li $s8 3

    another_room:
        lb $s0 0($s7)
        addi $s0 $s0 -1
        bne $s0 $s2 nowumpus
            la $a0 w_msg
            call print
        nowumpus:

        bne $s0 $s3 nopit1
            la $a0 p_msg
            call print
        nopit1:

        bne $s0 $s4 nopit2
            la $a0 p_msg
            call print
        nopit2:

        bne $s0 $s5 nobat1
            la $a0 b_msg
            call print
        nobat1:

        bne $s0 $s6 nobat2
            la $a0 b_msg
            call print
        nobat2:
        addi $s7 $s7 1
        addi $s8 $s8 -1
    bgtz $s8 another_room
#end

#define print_rooms
    la $a0 room_msg
    call print
    addi $a0 $s1 1
    call print_int
    
    add $a0 $s1 $zero
    call load_adjacent_rooms
    
    qprint_string move_msg

    la $s0 adjrooms
    lb $a0 0($s0)
    add $s6 $v0 $zero
    call print_int
    qprint_string comma
    lb $a0 1($s0)
    call print_int
    qprint_string comma
    lb $a0 2($s0)
    call print_int
#end

#define do_move
{
    move_again:
    print_rooms
    qprint_string prompt

    la $a0 str_buf
    call read_int
    add $s7 $v0 $zero
    
    add $a0 $s1 $zero
    call load_adjacent_rooms
    la $s0 adjrooms
    lb $a0 0($s0)
    beq $v0 $a0 in_ok
    lb $a0 1($s0)
    beq $v0 $a0 in_ok
    lb $a0 2($s0)
    beq $v0 $a0 in_ok
    
    b move_again
    in_ok:
        addi $s7 $s7 -1
        la $s0 wdata
        sb $s7 1($s0)
        b mainloop
}
#end

#define do_shoot
{
    shoot_again:
    print_rooms
    qprint_string prompt

    la $a0 str_buf
    call read_int
    add $s7 $v0 $zero
    
    add $a0 $s1 $zero
    call load_adjacent_rooms
    la $s0 adjrooms
    lb $a0 0($s0)
    beq $v0 $a0 in_ok
    lb $a0 1($s0)
    beq $v0 $a0 in_ok
    lb $a0 2($s0)
    beq $v0 $a0 in_ok
    
    b shoot_again
    in_ok:
        addi $s0 $s7 -1
        load_data
        beq $s0 $s2 kill_the_wumpus
        _wumpus_move:
            choose 20 $s2
            beq $s2 $s3 _wumpus_move
            beq $s2 $s4 _wumpus_move
            beq $s2 $s5 _wumpus_move
            beq $s2 $s6 _wumpus_move
            sb $s2 2($s7)
            qprint_string wump_move
        b mainloop
        kill_the_wumpus:
            qprint_string wump_kill
            call readln
            b main
}
#end

.globl main
main:
{
    li $s0 10
    la $t0 wdata    #seed random number generator
    sb $s0 0($t0)
    
    wait
    
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
    mainloop:
        print_debug
        call check_status
        print_status
        print_rooms
        qprint_char 10
        
        la $a0 act_choice
        call print
        get_char
        li $t0 113  #q
        beq $t0 $v0 userquit
        li $t0 109  #m
        beq $t0 $v0 usermove
        li $t0 115  #s
        beq $t0 $v0 usershoot
        b mainloop
        usermove:
            do_move
            b mainloop
        usershoot:
            do_shoot
            b mainloop
    userquit:
        exit
}
