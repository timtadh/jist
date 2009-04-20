#scope test not real program

@a = $t0
    {
        @b = $t0
        @longc = $t3
        addu $t1 @b @longc
        {
            @scope3 = $t4
            addu @scope3 @longc @b #test of @scope3
        }
    }
    #addu @longc @a @a