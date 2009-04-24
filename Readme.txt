Flow of control:
start.s
    program text
    kernel.s
    interrupt_handler.s
    stack_mgr.s
    interrupt_handler.s
    context_mgr.s
    interrupt_handler.s
    stack_mgr.s
    interrupt_handler.s
    program text
    Repeat...

System files:
    context_mgr.s
        Linked list implementation for context switching. Also handles system exit.
    interrupt_handler.s
        Scheduler, glues everything together, probably wont't make sense
    jistfile
        List of user programs to load
    kernel.s
        Exception handler, master system #include list, other stuff
    kernel_data.s
        Miscellaneous locations of things
    mappedio.s
        Macros for memory-mapped I/O
    memory_manager.s
        Functions for managing heaps
    mpp.py
        The generic part of the preprocessor. Probably won't make sense.
    proc_manager.s
        Functions for loading processes
    proc_storage.s
        Functions for PCB handling
    run.sh
        Shell script shortcut to run the whole shebang
    spim.py
        The Jist-specific part of the preprocessor.
    stack_mgr.s
        Handles stack allocations, saves, and restores.
    start.s
        Initialization code.

User programs:
    context_mgr_test.s:
        Old test code for the context manager.
    heap_test.s:
        Rigorous test of memory_manager.s.
    muckfips.s, imuckfips.s:
        Brainf*ck interpreter in static-data and interactive versions.
    multitask_demo.s
        Demonstrates concurrent subprocesses
    shell.s
        Program launcher
    stack_mgr_test.s
        Rigorous test of stack_mgr.s
    user_heap_test.s
        Test code for user heaps
    wumpus.s
        A game of Hunt the Wumpus
Note that it is not a good idea to run more than one instance of any given user program at a time, as many of them use static data which will become corrupted. We are working to correct this problem. In other words, you can run Wumpus and multitask_demo.s at the same time, but not two Wumpuses.
