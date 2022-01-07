pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
-- P2
-- by PAK-9

#include poly.lua

-- music(0)

local SEG_LEN = 10
local NUM_SEGS = 0
local DRAW_DIST = 40
local CANVAS_SIZE = 128
local ROAD_WIDTH = 40 -- half
local CAM_HEIGHT = 17
local CAM_DEPTH = 0.75; -- 1 / tan((100/2) * pi/180)  (fov is 100)
local sPointsX = {}
local sPointsY = {}
local sPointsZ = {}
local sPointsC = {}
local LastY = 0

local Position = 0

local PlayerX = 0 -- -1 to 1 TODO: maybe don't make relative to road width
local PlayerXd = 0
local PlayerY = 0
local PlayerYd = 0
local PlayerVl = 0
local PlayerDrift = 0
local PlayerAir = 0

local sScreenShake = {0,0}

function BayerRectV( x1, y1, x2, y2, c1, c2 )

    grad={ 0, 0x0208, 0x0A0A, 0x1A4A, 0x5A5A, 0xDA7A, 0xFAFA, 0xFBFE, 0xFFFF }
    col = bor( c1 << 4, c2 );
    h=y2-y1
    for i = 1,#grad do
        fillp(grad[i])
        rectfill( x1, flr(y1), x2, y1+flr(h/#grad), col )
        y1 = y1 + h/#grad;
    end

end

function AddSeg( c, y )
    NUM_SEGS+=1
    add( sPointsC, c )
    add( sPointsX, 0 )
    add( sPointsY, y )
    add( sPointsZ, NUM_SEGS * SEG_LEN + 1 )
end

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

function AddCurve( enter, hold, exit, c, y )

    tot=(enter+hold+exit)

    for i=1,enter do
    AddSeg( easein( 0, c, i/enter ), easeinout( LastY,y,i/tot ) )
    end
    for i=1,hold do
    AddSeg( c, easeinout( LastY,y,(i+enter)/tot ) )
    end
    for i=1,exit do
    AddSeg( easeout(c, 0, i/exit ), easeinout( LastY,y,(i+enter+hold)/tot ) )
    end
    LastY=y

end

function AddStraight( n, y )
    for i=1,n do
    AddSeg( 0, easeinout( LastY, y, i/n ) )
    end
    LastY=y
end

function InitSegments()

    LastY = 0
    
    AddStraight( 10, 0 )
    AddStraight( 20, 40 )
    AddCurve( 10,10,10,1, -20 )
    AddStraight( 20, 0 )
    AddCurve( 10,10,20,-1, 20 )
    AddStraight( 20, 0 )
    --AddStraight( 10 )
    AddCurve( 6,20,15,-2, -50 )
    AddStraight( 10, 20 )
    AddStraight( 4, 0 )
    --AddCurve( 4,10,4,4 )

end

function _init()

    -- draw black pixels
    palt(0, false)
    -- don't draw tan pixels
    palt(15, true)

    InitSegments()

end

function constedits()
    if btn(2) then -- up
        CAM_HEIGHT=CAM_HEIGHT+1
    elseif btn(3) then -- down
        CAM_HEIGHT=CAM_HEIGHT-1
    end
    
    if btn(0) then -- left
        CAM_DEPTH=CAM_DEPTH+0.05
    elseif btn(1) then -- right
        CAM_DEPTH=CAM_DEPTH-0.05
    end

    Position=Position+2

end

function _update()

    -- screenshake

    sScreenShake[1] = -sScreenShake[1]*0.8
    sScreenShake[2] = -sScreenShake[2]*0.8
    if( abs( sScreenShake[1] ) + abs( sScreenShake[2] ) < 1 ) then
        sScreenShake = {0,0}
    end
    camera(sScreenShake[1],sScreenShake[2])

    -- player input/movement

    lpdpos=LoopedTrackPos(Position)
    playerseg = DepthToSegIndex(lpdpos)
    nxtseg=(playerseg)%NUM_SEGS + 1
    posinseg=1-(playerseg*SEG_LEN-lpdpos)/SEG_LEN
    
    -- input
    if PlayerAir == 0 then
        if btn(2) then -- up
            -- PlayerVl=PlayerVl+1
        elseif btn(3) then -- down
            if abs( PlayerXd ) > 0.1 then
                PlayerDrift=sgn(PlayerXd)
            else
                PlayerVl=PlayerVl-0.08
            end
        end

        if btn(4) then -- z / btn1
            PlayerVl=PlayerVl+0.1
        end
        PlayerVl=PlayerVl*0.99

        if btn(0) then -- left
            PlayerXd-= (0.04 + -PlayerDrift*0.04) * PlayerVl*0.1
        elseif btn(1) then -- right
            PlayerXd+= (0.04 + PlayerDrift*0.04) * PlayerVl*0.1
        end
        PlayerXd=PlayerXd*0.9
    end
    PlayerX+=sPointsC[playerseg]*0.6*PlayerVl*0.01
    PlayerX+=PlayerXd*0.3

    if abs( PlayerXd ) < 0.08 then
        PlayerDrift=0
    end

    finalvel = PlayerVl*0.6
    Position=Position+finalvel
    if Position > SEG_LEN*NUM_SEGS then
        Position -= SEG_LEN*NUM_SEGS
    end

    ground = lerp( sPointsY[playerseg], sPointsY[nxtseg], posinseg)
    PlayerY=max(PlayerY+PlayerYd, ground)
    if( PlayerY == ground ) then
        if PlayerYd < -2 and PlayerAir > 4 then
            sScreenShake = {2,7}
        end
        nposinseg=1-(playerseg*SEG_LEN-(lpdpos+finalvel ))/SEG_LEN
        nground = lerp( sPointsY[playerseg], sPointsY[nxtseg], nposinseg )
        PlayerYd = ( nground - ground ) - 0.4
        
        PlayerAir = 0
    else
        PlayerYd=PlayerYd-0.7
        PlayerAir = PlayerAir + 1
    end

--constedits()
end

function RenderHorizon()

    BayerRectV( -10, 64, 138, 74, 3, 13 )
    sspr( 0,24,48,16, 40, 48 )

end

function RenderSky()
    rectfill( -10, 0, 128, 44, 12 ) -- block out
    BayerRectV( -10, 40, 138, 64, 6, 12 )
end

function RenderPoly4( v1, v2, v3, v4, c )

    polyfill({{x=v1[1],y=v1[2]},{x=v2[1],y=v2[2]},{x=v3[1],y=v3[2]}},c)
    polyfill({{x=v1[1],y=v1[2]},{x=v4[1],y=v4[2]},{x=v3[1],y=v3[2]}},c)

end

function RenderSeg( x1, y1, w1, x2, y2, w2, idx )

    -- Edge
    if idx % 4 > 1 then
        fillp(0)
        col = 6
    else
        fillp(0x5A5A)
        col = 0x42
    end
    edgew1=w1*1.2
    edgew2=w2*1.2
    RenderPoly4( {x1-edgew1,y1},{x1-w1,y1},{x2-w2,y2},{x2-edgew2,y2}, col )
    RenderPoly4( {x1+w1,y1},{x1+edgew1,y1},{x2+edgew2,y2},{x2+w2,y2}, col )

    if idx % 8 > 3 then
        fillp(0)
        col = 3
    else
        fillp(0x5A5A)
        col = 0x3B
    end
    -- Grass
    RenderPoly4( {-10,y2},{-10,y1},{x1-edgew1,y1},{x2-edgew2,y2}, col )
    RenderPoly4( {138,y2},{138,y1},{x1+edgew1,y1},{x2+edgew2,y2}, col )

    -- Road
    if idx % 2 == 0 then
        fillp(0)
        col = 5
    else
        fillp(0x5A5A)
        col = 0x5D
        --fillp(0)
        --col = 13
    end
    RenderPoly4( {x1-w1,y1},{x1+w1,y1},{x2+w2,y2},{x2-w2,y2}, col )

     -- Lanes
     
     -- centre
     --[[
     if idx % 4 > 2 then
        fillp(0)
        col = 9
        lanew=0.02
        RenderPoly4( {x1-w1*lanew,y1},{x1+w1*lanew,y1},{x2+w2*lanew,y2},{x2-w2*lanew,y2}, col )
    end
    --]]

    -- edge
    if idx % 2 > 0 then
        fillp(0)
        col = 6
        dst1=0.86
        dst2=0.9
        RenderPoly4( {x1-w1*dst1,y1},{x1-w1*dst2,y1},{x2-w2*dst2,y2},{x2-w2*dst1,y2}, col )
        RenderPoly4( {x1+w1*dst2,y1},{x1+w1*dst1,y1},{x2+w2*dst1,y2},{x2+w2*dst2,y2}, col )
    end

end -- RenderSeg

function _draw()
	cls()
	
    RenderSky()
    RenderHorizon()
    RenderRoad()
    RenderPlayer()
    RenderHUD()

    print( flr(stat(1)*100).."%", 2,2,3 )
    print(tostr( flr(stat(0)) ) .."/2048k", 2,10,3 )
    --print( flr(stat(0)), 30,2,3 )
    --print(flr(DRAW_DIST), 2,30,3 )
    --print(CAM_DEPTH, 2,30,3 )
    --print(CAM_HEIGHT, 2,50,3 )
    print(PlayerAir, 2,30,3 )

    --BayerRectV( 20,20, 100,100, 4, 7)

end

function RenderHUD()

    -- print(tostr(PlayerVl),2,20,4)
    --print(tostr(LoopedTrackPos(Position)),2,20,4)
    --print(tostr(DRAW_DIST),2,20,4)

end

function RenderPlayer()

    if PlayerDrift != 0 then
    spr( 9, 64 - 24 + PlayerDrift * 0, 100, 6, 3, PlayerDrift > 0 )
    elseif PlayerXd > 0.07 or PlayerXd < -0.07 then
    spr( 4, 44, 100, 5, 3, PlayerXd > 0 )
    else
    spr( 0, 48, 100, 4, 3 )
    end

end

function LoopedTrackPos(z)
    lps=flr(z/(SEG_LEN*NUM_SEGS))
    return z-SEG_LEN*NUM_SEGS*lps
end

function DepthToSegIndex(z)
  return flr(z/SEG_LEN) % NUM_SEGS + 1;
end

function RenderRoad()
    
    --Position=-10
    lpdpos=LoopedTrackPos(Position)
    startseg = DepthToSegIndex(lpdpos)
    
    loopoff=0

    psx = {}
    psy = {}
    psw = {}

    xoff = 0
    posinseg=1-(startseg*SEG_LEN-lpdpos)/SEG_LEN
    dxoff = - sPointsC[startseg] * posinseg
    miny=1000
   
    for i = 0, DRAW_DIST - 1 do

        camx = PlayerX * ROAD_WIDTH

        for j = 1, 2 do

            segidx = (startseg - 1 + ( j - 1 ) + i) % NUM_SEGS + 1

            -- Projection

            pcamx = sPointsX[segidx] - camx - xoff - dxoff * (j-1);
            pcamy = sPointsY[segidx] - ( CAM_HEIGHT + PlayerY );
            pcamz = sPointsZ[segidx] - (lpdpos - loopoff);

            pscreenscale = CAM_DEPTH/pcamz;
            psx[j] = flr((CANVAS_SIZE/2) + (pscreenscale * pcamx  * CANVAS_SIZE/2));
            psy[j] = flr((CANVAS_SIZE/2) - (pscreenscale * pcamy  * CANVAS_SIZE/2));
            psw[j] = flr((pscreenscale * ROAD_WIDTH * CANVAS_SIZE/2));

            if j == 1 and segidx == NUM_SEGS then
                loopoff+=NUM_SEGS*SEG_LEN
            end
        end

        xoff = xoff + dxoff
        dxoff = dxoff + sPointsC[segidx]

        if ( psy[1] < 128 or psy[2] < 128 ) and ( psy[1] >= psy[2]  ) and ( psy[1] <= miny+1 ) then
            RenderSeg( psx[1], psy[1], psw[1], psx[2], psy[2], psw[2], segidx )
        end

        miny=min(psy[2],miny)
    end

    --print(tostr(psy[1]),2,40,4)
    --print(tostr(psy[2]),20,40,4)

end -- RenderRoad













__gfx__
fffffffeeeeeeeeeeeeeeeeeeffffffffffffffff11eeeeeeeeeeeeeeeeeefffffffffffffffffffffffffe1eeeeeeeeeeeeeeeeeeffffffffffffffffffffff
ffffff5eeeeeeeeeeeeeeeeee5fffffffffffffddddeddd5555555555d555dfffffffffffffffffffff1dddd1eeeeee55555555dddddffffffffffffffffffff
ffff155ddd555555555555ddd551ffffffff8ddddd0dddddddddddddddddd66fffffffffffffffffdddddddde0eddddddddd666666666fffffffffffffffffff
fff555dddddddddddddddddddd555fffffff1155d5e6666666666dddddddddddffffffff8e8e8e1d5ddddddd5ee6666666ddddddddddddffffffffffffffffff
ff15e6666666666666666666666e51ffffff21555edddddddddddddddddddddddfffffffe800e811155d5dd5eeeddddddddddddd66666666ffffffffffffffff
ff0d8dddddddddddddddddddddd8d0ffffff2115ee666666666666666666666dddffffff8e108e8e11151de0eedddd66666666ddd5555555dfffffffffffffff
ffd86666666666666666666666668dffffff22eeedddd55555dddddd5555555555ddffffe001e8e8e8111d5eee66dd5555d5dddd55556666660000ffffffffff
ff8dddd55555dddddddd55555dddd8ffffff00eedd555555666666666666000000000fff80000e8e8e8e15eeeedd555556666666000000000000000fffffffff
f866666666666666666666666666668fffff022e6ee000000000000000000000000000ff10000218e811e8eeee666666000000000000022222000000ffffffff
fee00000000000000000000000000eefffff002eee00000022222222222222222000000f100001212e818e88eeeeeee00002222222222222222eeeeeffffffff
fe0000022222222222222222200000efffff0002e000222222222222222222222eeeeeee005002121218e8e0e8eeee00002222222eeeeeeeeeeeeeeeffffffff
e000022222222222222222222220000effff0002eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeef015012121212e00008e8000eeeeeeeeeeeeeed44877888effffffff
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffff0002eeeeeeeeeeeeddddddddd448877888eeff1102121212120000e8eeeeeeeee4ddddddddd4487d222effffffff
ee888877844dddddddddd448778888eefffff000ee888778844dddddddddd448878222eeffff002121212101010e8ee8877844dddd555dd442dd222effffffff
ee888877844dddddddddd448778888eefffff000ee222dd2244d5555555dd4422d2222eeffffff00121212010008eee88dd244d555555deeeeeeeeeeffffffff
ee2222dd244dd555555dd442dd2222eefffff000ee222dd2244d555eeeeeeeeeeeeeeeeefffffff000212101d0008ee22dd244eeeeeeeeeeeee22222ffffffff
ee2222dd244dd555555dd442dd2222eeffffff00eeeeeeeeeeeeeeeeeeeeeeeeeeeee222fffffffff0021201d0002eeeeeeeeeeeee22222222222225ffffffff
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffffff00eeee2222222222222222222222222222ffffffffff00010150002eeeee2222222222222d6d555555ffffffff
22222222222222222222222222222222ffffff002222222222222222225555d6d5555555ffffffffffff000100002222222222255555555d06500000ffffffff
22222222222222222222222222222222fffffff055555555d6d555555555556065555550fffffffffffff00005002222555d6d555550000d6d000000ffffffff
55555555d6d5555555555d6d55555555fffffff05555555560600000000000d6d0000000fffffffffffffff055002555555d0600000000000000000fffffffff
00000000606000000000060600000000fffffff000000000d6d000000000000000000000ffffffffffffffff51002000000d6d0000000000000fffffffffffff
f0000000d6d0000000000d6d0000000fffffffff0000000000000000000000000000000fffffffffffffffffff000000000000000000ffffffffffffffffffff
f000000000000000000000000000000ffffffffff0000000000ffffffffffffffffffffffffffffffffffffffffff00000000fffffffffffffffffffffffffff
fffffffffffffff7ddffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff75dffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff75dffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff75dffffffffff55fffdffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffff6d5dfffffffff5551ff5ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffff6555ffdffffff5111ff56fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffff51d551115ffffff5151ff55fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffdfffd16555111ffffff51116d51fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffddf6d16155111dd6d6551116651fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffddd5f5d1d5551116d6d65515166516ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffff5fddd5d1d1d5111116ddd61115166515ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fff656d5d55151d55511161ddd15111d651166df6dffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff5d5dd5d15151d51511161d1d11151111111ddd66ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff56dd11d155d1d11511161d1d1111111111dddddd151fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
dd565d15d11dd1d11511161d1d5511111111115ddd66d5d6ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
5d5d5666666dd5d11115155515515115111151ddddd66dd6ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000007777770077000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000007777770087788770077000000077770000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000007700770087708770077000000977907700000000000000000000000
00000000000000000000000000000000000000000000000000000000000000077000770087788770087777800a77000000977a97700000000000000000000000
00000000000000000000000000000000000000000000000000000000000000077000770087708770087789770a77000000977b97700000000000000000000000
00000000000000000000000000000000000000000000000000000000000000077070770087798770a877a8770a7777770c977097700000000000000000000000
0000000000000088c088c00000000000000000000000000000000000000000077777770087777770a88998800a8888880c977777700000000000000000000000
0000000000000077ce77ce0000000000000000000000000000000000000000977787770088aa8800a99ba990ca9999990c999999000000000000000000000000
0000000000000077ce77ceaaaaaae000000000000000007777770000000000977888770088888800a99ab990caaaaaa00caaaaaa000000000000000000000000
00000000000000778877ce7777770077000000770000007700770000000000988808880b99bb9900aaccaa00cbb00000ecbbbbbb000000000000000000000000
00000000000000777777ce77e0000077000000770000007788770000000000988999880b99999900aabbaa00cbbbbbb0ecccccc0000000000000000000000000
0000000000000077ce77ce77aae00077000000770000007799770000000000999099900baa0baa0dbbddbb00cc000000edd0edd0000000000000000000000000
0000000000000077ee77ee77770000770000007700000077aa77000000000b990ab9900baaaaaa0dbbccbb00cccccc00edddddd0000000000000000000000000
000000000000000000000077aaaae07700000077000000777777000000000baaaaaaa00bb00bb00dcc0dcc00dd000000ee00ee00000000000000000000000000
000000000000000000000077777700777777007777770088cc88000000000baaa0aaa0dbbbbbb00dccdecc00dddddd00eeeeee00000000000000000000000000
0000000000000000000000000000008888880088888800888888000000000baabbbaa0dcc0dcc00dd00dd000ee00000000000000000000000000000000000000
0000000000000000000000000000009999990099999900999999000000000bbbcbbb00dccedcc00dd00dd000eeeeee0000000000000000000000000000000000
00000000000000000000000000000000000000aaaaaa00aaaaaa000000000bbcccbb00dcccccc00eeee000000000000000000000000000000000000000000000
00000000000000000000000000000000000000bbbbbb00bbbbbb000000000cccdccc00dd00dd000ee00ee0000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000cccccc000000000ccdedcc00dddddd000ee00ee0000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000dddddd000000000dde0edd00ee00ee0000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000ee000ee00eeeeee0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000eee0e0e0eee00ee00000eee00ee00000eee0eee00ee00ee00000eee000000000000000000000000000000000000
00000000000000000000000000000000000000e00e0e00e00e00000000e00e0000000e0e00e00e000e0e00000e0e000000000000000000000000000000000000
00000000000000000000000000000000000000e00eee00e00eee000000e00eee00000eee00e00e000e0e0eee0eee000000000000000000000000000000000000
00000000000000000000000000000000000000e00e0e00e0000e000000e0000e00000e0000e00e000e0e00000e0e000000000000000000000000000000000000
00000000000000000000000000000000000000e00e0e0eee0ee000000eee0ee000000e000eee00ee0ee000000eee000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000cc00ccc00cc0ccc00000ccc00cc00000ccc0ccc0ccc0ccc00000c0c00cc0c0c0000000000000000000000000000000
0000000000000000000000000000000000c0c00c00c000c00000000c00c0c00000ccc0c000c0000c000000c0c0c0c0c0c0000000000000000000000000000000
0000000000000000000000000000000000c0c00c00c000cc0000000c00c0c00000c0c0cc00cc000c000000ccc0c0c0c0c0000000000000000000000000000000
0000000000000000000000000000000000c0c00c00c000c00000000c00c0c00000c0c0c000c0000c00000000c0c0c0c0c0000000000000000000000000000000
0000000000000000000000000000000000c0c0ccc00cc0ccc000000c00cc000000c0c0ccc0ccc00c000000ccc0cc000cc0000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000008808800000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000088888780000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000088888880000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000008888800000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000888000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
0110000000472004620c3400c34318470004311842500415003700c30500375183750c3000c3751f4730c375053720536211540114330c37524555247120c3730a470163521d07522375164120a211220252e315
01100000183732440518433394033c65539403185432b543184733940318433394033c655306053940339403184733940318423394033c655394031845321433184733940318473394033c655394033940339403
01100000247552775729755277552475527755297512775524755277552b755277552475527757297552775720755247572775524757207552475227755247522275526757297552675722752267522975526751
01100000001750c055003550c055001750c055003550c05500175180650c06518065001750c065003650c065051751106505365110650c17518075003650c0650a145160750a34516075111451d075113451d075
011000001b5771f55722537265171b5361f52622515265121b7771f76722757267471b7461f7362271522712185771b5571d53722517187361b7261d735227122454527537295252e5171d73514745227452e745
01100000275422754227542275422e5412e5452b7412b5422b5452b54224544245422754229541295422954224742277422e7422b7422b5422b5472954227542295422b742307422e5422e7472b547305462e742
0110000030555307652e5752b755295622e7722b752277622707227561297522b072295472774224042275421b4421b5451b5421b4421d542295471d442295422444624546245472444727546275462944729547
0110000000200002000020000200002000020000200002000020000200002000020000200002000020000200110171d117110171d227131211f227130371f2370f0411b1470f2471b35716051221571626722367
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002e775000002e1752e075000002e1752e77500000
__music__
00 00044208
00 00044108
00 00010304
00 00010304
01 00010203
00 00010203
00 00010305
00 00010306
00 00010305
00 00010306
00 00010245
02 00010243

