#scope test not real program

#define mactest
    @t = $t0
    addu @t @t @t
    addu %1 %1 %1
    lw  @t 0(%1)
#end

@a = $t0
    {
        @b = $t0
        @a = $t2
        @longc = $t3
        addu $t1 @b @longc
        {
            @scope3 = $t4
            addu @scope3 @longc @a #test of @scope3
        }
        mactest @a
        
    }
    #addu @longc @a @a