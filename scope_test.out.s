#scope test not real program

#@a = $t0
#        @b = $t0
#        @longc = $t3
        addu $t1 $t0 $t3 # orgline = addu $t1 @b @longc
#            @scope3 = $t4
            addu $t4 $t3 $t0 #test of @scope3 # orgline = addu @scope3 @longc @b #test of @scope3
    #addu @longc @a @a