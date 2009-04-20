    addu $t1 $t0 $t3 # orgline = addu $t1 @b @longc
    addu $t4 $t3 $t2 #test of @scope3 # orgline = addu @scope3 @longc @a #test of @scope3
    addu $t0 $t0 $t0 # orgline = addu @t @t @t
    addu $t2 $t2 $t2 # orgline = addu @a @a @a
    lw  $t0 0($t2) # orgline = lw  @t 0(@a) # orgline = lw  $t0 0(@a) # orgline = lw  @t 0(@a)