
function WeightSegLen()
    w=rnd(1)
    -- tend towards shorter
    return ((w*1.4)*(w*1.4))*0.5
end

function CalcYdelt( ysc, len )
    return (rnd(200)-100)*ysc*((len-10)/100)
    --return 100*ysc*((len)/100)
end

-- ysc 
function BuildCustomTrack( theme, ysc, cmax, seed )

    len=30
    srand(seed)
    y=0
    for n=1,len do
        slen=WeightSegLen()
        if rnd(4)<2 or n==1 or n==len then
            --straight
            sptn=flr(rnd(#SPDEF[theme]-2))+3
            cnt=slen*30+10
            y=(y+CalcYdelt(ysc,cnt))
            y=lerp( y, 0, 1-(1-(n-1)/(len-1)))
            AddStraight( cnt, y, sptn )
        else
            --curve
            c=rnd(cmax)+0.2
            if rnd(1)>0.5 then
                c=-c
            end
            if c > 0.85 then
                sptn=1 -- right turns are spdef 2
            elseif c < -0.85 then
                sptn=2 -- left turns are spdef 1
            else
                -- random pick of all other spdefs
                sptn=flr(rnd(#SPDEF[theme]-2))+3
            end
            --clen=flr((2-rnd(cmax))*20)+4
            cnt=flr((2-rnd(cmax))*(slen+rnd(1))*18)+6
            cntin=flr((2-rnd(cmax))*(slen+rnd(1))*18)+6
            cntout=flr((2-rnd(cmax))*(slen+rnd(1))*18)+6
            y=(y+CalcYdelt(ysc,cnt+cntin+cntout))
            y=lerp( y, 0, 1-(1-(n-1)/(len-1)))
            AddCurve(cntin,cnt,cntout,c,y,sptn)
        end
    end

    -- tokens
    -- its always 4 groups of 5

    --AddTokens( 10, -0.8, 5 )

    for i=1,1 do
        sttkn=(NumSegs-200)/4*i
        xx=rnd(0.7)-0.35
        AddTokens( flr(sttkn), xx, 5 )
    end

end