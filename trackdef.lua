-- curve guide: -- y = #segs in/hold/out, x=c
-- T - trivial
-- E - Easy (not constant input)
-- M - medium (constant input)
-- H - hard (just possible at top)
-- D - Drift required
-- X - Not (not possible at top)
 --    1|1.5| 2 |2.5
-- 10  T| M | H | H 
-- 20  E| M | H | D 
-- 30  E| M | D | X 
-- 40  E| M | D | X 

-- 1. SPDEF 2. NumSegs 3. End Y 4. 1Straight/2Curve [5. C InSegs 6. C OutSegs 7. C]

function WeightSegLen()
    w=rnd(1)
    return ((w*1.4)*(w*1.4))*0.5
end

-- ysc 
function BuildCustomTrack( theme, ysc, cmax, seed )
    
    sptd=SPTHMDEF[theme]
    len=30
    srand(seed)
    yn=0
    ydelt=0
    for n=1,len do
        slen=WeightSegLen()
        ydelt=ydelt+(rnd(80)-40)*ysc*max(slen-0.2,1)
        yn=(yn+ydelt)
        --yn=yn+(-yn)*(1-(n-1)/(len-1))
        yn=lerp( yn, 0, 1-(1-(n-1)/(len-1))  )
        --y=yn*min(abs(sin((n-1)/(len-1)*0.5))*1.4,1)
        --y=yn*(1-(n-1)/(len-1))
        y=yn
        if rnd(4)<2 or n==1 or n==len then
            --straight
            sptn=sptd[flr(rnd(#sptd-2))+3]
            cnt=slen*40+10
            AddStraight( cnt, y, sptn )
        else
            --curve
            c=(rnd(cmax-0.6)+0.6)
            if rnd(1)>0.5 then
                c=-c
            end
            if c > 0.8 then
                sptn=sptd[1]
            elseif c < -0.8 then
                sptn=sptd[2]
            else
                sptn=sptd[flr(rnd(#sptd-2))+3]
            end
            cnt=slen*20+4
            cntin=WeightSegLen()*30+4
            cntout=WeightSegLen()*30+4
            AddCurve(cntin,cnt,cntout,c,y,sptn)
        end
    end
end