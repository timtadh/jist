#include stdlib.s

.data
prompt:     .asciiz "? "
get_move:   .asciiz "Shoot or move? (s or m)"
lose_msg:   .asciiz "HA HA HA - YOU LOSE!"
win_msg:    .asciiz "HEE HEE HEE - THE WUMPUS'LL GET YOU NEXT TIME!"
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
        .ascii "        (no tunnel) it movesat random to the next room.\n"
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
.globl main
main:
    addi $a0 $zero 10
    exec print_char
    exec print_char
    exec print_char
    exec print_char
    exec print_char
    exec print_char
    exec print_char
    exec print_char
    exec print_char
    la $a0 intro
    exec print
    exec readln
    la $a0 intro2
    exec print
    exec readln
    exit