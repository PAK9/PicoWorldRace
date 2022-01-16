function lerp( a,b,f )
return a+(b-a)*f
end

function easein( a, b, fact )
return a + (b-a)*fact*fact
end

function easeout( a, b, fact )
return a + (b-a)*(1-(1-fact)*(1-fact))
end

function easeinout( a, b, fact )
    if fact <= 0.5 then
        return easein(a,lerp(a,b,0.5),fact*2)
    else
        return easeout(lerp(a,b,0.5),b,(fact-0.5)*2)
    end
end