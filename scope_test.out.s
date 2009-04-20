    #scope test not real program
    
    
    #    @a = $t0
    #        @b = $t0
    #        @a = $t2
    #        @longc = $t3
    addu $t1 $t0 $t3 # ::-> addu $t1 @b $t3  # ::-> addu $t1 @b @longc
    #            @scope3 = $t4
    addu $t4 $t3 $t2 #test of $t4  # ::-> addu @scope3 $t3 $t2
    ################ start mactest ################
    #    @t = $t0
    #    @arg = @a
    addu $t0 $t0 $t0  # ::-> addu @t @t @t
    addu $t2 $t2 $t2  # ::-> addu @a @a @a
    addu $t2 # ::-> addu @arg
    lw  $t0 0($t2) # ::-> lw  @t 0($t2)
    ################# end mactest #################
    
    #addu @longc @a @a
    
    #    @start = $t9
    #    @start_ = $t1
    
    addu    $t9 $t1 # ::-> addu    @start $t1  # ::-> addu    @start @start_