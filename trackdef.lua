
function WeightSegLen()
    w=rnd(1)
    -- tend towards shorter
    return ((w*1.4)*(w*1.4))*0.5
end

function CalcYdelt( ysc, len )
    --return (rnd(200)-100)*ysc*((len-10)/100)
    return 100*ysc*((len)/100)
end

function BuildCustomTrack( theme, ysc, cmax, seed )

    len=28
    srand(seed)
    for n=1,len do
        slen=WeightSegLen()
        if rnd(4)<2 or n==1 or n==len then
            --straight
            sptn=flr(rnd(#SPDEF[theme]-2))+3
            cnt=slen*30+10
            AddStraight( cnt, 0, sptn )
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
            AddCurve(cntin,cnt,cntout,c,0,sptn)
        end
    end

    -- y values
    ydelt1=0 -- first derivative
    ydelt2=0 -- second derivative
    y=0
    for i=1,NumSegs do
        ydelt2=ydelt2+rnd(1)-0.5
        ydelt2=ydelt2*0.9

        ydelt1=ydelt1+ydelt2
        ydelt1=ydelt1*0.9

        y=y+ydelt1
        sPointsY[i]=y*sin(i/NumSegs*0.5)*ysc
    end

    -- tokens
    -- its always 4 groups of 5

    for i=1,4 do
        sttkn=(NumSegs-200)/4*i
        xx=rnd(0.7)-0.35
        AddTokens( flr(sttkn), xx, 5 )
    end

end

function BuildPreviewTrack( theme )

    AddCurve(10,10,10,2,0,1)
    AddCurve(10,10,10,2,0,1)
    AddCurve(10,10,10,2,0,1)
end