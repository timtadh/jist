#include stdio.s

.data
intro:  .ascii  "WELCOME TO HUNT THE WUMPUS!\n"
        .ascii  "   The Wumpus lives in a cave of 20 rooms. Each room has 3 tunnels leading to other rooms.\n"
        .ascii  "   (Look at a dodecahedron to see how this works-if you don't know what a dodecahedron is, ask someone.)\n\n"
        
        .ascii "HAZARDS\n"
        .ascii "Bottomless Pits:\n"
        .ascii "    Two rooms have bottomless pits in them. If you go there, you fall into the pit (& lose!)\n"
        .ascii "Super Bats:\n"
        .ascii "    Two other rooms have Super Bats. If you go there, a bat grabs you and takes you to some other room at random. (which may be troublesome)\n\n"
        .asciiz "Hit Return."
.text
.globl main
main:
    la $a0 intro
    exec println
    exit