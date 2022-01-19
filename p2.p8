pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
-- P2
-- by PAK-9

#include poly.lua
#include utility.lua
#include renderutils.lua
#include debug.lua
#include particle.lua
#include trackdef.lua

-- music(0)

local Frame = 0

local SEG_LEN = 10
local DRAW_DIST = 40
local CANVAS_SIZE = 128
local ROAD_WIDTH = 46 -- half
local CAM_HEIGHT = 17
local CAM_DEPTH = 0.75; -- 1 / tan((100/2) * pi/180)  (fov is 100)

-- 1. Road col1 2. Road col2 3. Road pat 4. Ground col1 5. Ground col2(x2) 6. Edge col1 7. Edge col2(x2) 8. Lane pat
-- Road patterns: 1. alternating stripes 2. random patches
-- Lane patterns: 1. edges 2. centre alternating
local THEMEDEF = {
    { 5, 0x5D, 1, 3, 0x3B, 6, 0x42, 1 }, -- Green raceway
    { 5, 0x65, 2, 6, 0x76, 6, 0x15, 2 }, -- Snowy
}

local Theme = 1

local NumSegs = 0
local sPointsX = {}
local sPointsY = {}
local sPointsZ = {}
local sPointsC = {}

local NUM_LAPS = 3


-- sprite definitions (the bottom of the sprite should be on the ground)
-- 1.sx, 2.sy, 3.sw, 4.sh, 5.scalemin, 6.scalemax, 7.flip, 8.hitbox min, 9.hitbox max (0-1)
local SDEF = { 
    { 48, 24, 8, 8, 1.4, 1.4, 0, 0, 1 }, -- 1. chevron r
    { 48, 24, 8, 8, 1.4, 1.4, 1, 0, 1 }, -- 2. chevron l
    { 57, 35, 7, 5, 0.4, 0.6, 0, 0, 0 }, -- 3. grass
    { 56, 24, 10, 11, 2.5, 4.5, 0, 0.2, 0.8 }, -- 4. tree
    { 48, 32, 8, 8, 0.5, 0.8, 0, 0, 0 }, -- 5. shrub
    { 0, 40, 16, 11, 4, 4, 0, 0.1, 0.9 }, -- 6. bilboard
    { 0, 0, 32, 24, 1, 1, 0, 0, 0 }, -- 7. opponent car
    { 36, 0, 36, 24, 1, 1, 0, 0, 0 }, -- 8. opponent car l
    { 36, 0, 36, 24, 1, 1, 1, 0, 0 }, -- 9. opponent car r
    { 23, 40, 7, 7, 1, 1, 0, 0, 0 }, -- 10. token
    { 122, 25, 6, 6, 1, 1, 0, 0, 0 }, -- 11. gantry section
    { 103, 25, 18, 15, 1, 1, 0, 0, 0 }, -- 12. start/end banner left
    { 103, 25, 18, 15, 1, 1, 1, 0, 0 }, -- 13. start/end banner right
}
-- sprite pattern definitions
-- when conflict first is used
-- index in SDEF, interval, minx (*roadw), maxx (*roadw), rand l/r
local SPDEF = {
    { { 1, 3, -1.6, -1.6, 0 }, { 4, 2, 2, 8, 1 }, { 3, 1, 1.5, 2, 1 }  }, --  1. chevron r, trees, grass
    { { 2, 3, 1.6, 1.6, 0 }, { 4, 2, 2, 8, 1 }, { 3, 1, 1.5, 2, 1 }  }, --  2. chevron l, trees, grass
    { { 4, 2, 1.5, 8, 1 }, { 5, 3, 2, 4, 1 }, { 3, 1, 1.4, 3, 1 } }, -- 3. trees, shrubs, grass
    { { 6, 18, 2, 2, 0 }, { 4, 2, 1.5, 8, 1 }, { 5, 3, 2, 4, 1 }, { 3, 1, 1.4, 3, 1 } }, -- 4. billboard, trees, shrubs, grass   
}

local sSprite = {}
local sSpriteX = {}
local sSpriteSc = {} -- scale
local SpriteCollideRect = {}

local sTokensX = {}
local sTokensExist = {}
local NumTokens = 0

-- numeric font definitions {sx,sy,sw,sh}
NFDEF = {{ 111, 116, 12, 11 },  -- 0
        { 2, 116, 4, 11 }, -- 1
        { 7, 116, 12, 11 }, -- etc..
        { 20, 116, 12, 11 },
        { 33, 116, 12, 11 },
        { 46, 116, 12, 11 },
        { 59, 116, 12, 11 },
        { 72, 116, 12, 11 },
        { 85, 116, 12, 11 },
        { 98, 116, 12, 11 }, -- 9 
        { 10, 104, 12, 11}} -- G (for the countdown)

local LastY = 0 -- last y height when building a track

local Position = 0 -- current position around the track

local PlayerX = 0 -- -1 to 1 TODO: maybe don't make relative to road width
local PlayerXd = 0
local PlayerY = 0
local PlayerYd = 0
local PlayerVl = 0
local PlayerVf = 0
local PlayerDrift = 0
local PlayerAir = 0
local PlayerSeg = 0 -- current player segment
local PlayerLap = 0
local PlayerStandF = 0 -- final standing

local RecoverStage = 0 -- 1. pause 2. lerp to track 3. flash
local RecoverTimer = 0
local InvincibleTime = 0

local OpptPos = {}
local OpptLap = {}
local OpptSeg = {}
local OpptX = {}
local OpptV = {}
local RubberBand = 0

local HznOffset = 0

local HUD_HEIGHT = 16

local sScreenShake = {0,0}

-- 1. countdown 2. race 3. end standing 4. Summary UI
local RaceState = 1
local RaceStateTimer = 0
local RaceCompleteTime = 0
local RaceCompletePos = 0 -- player standing

function LoopedTrackPos(z)
    lps=flr(z/(SEG_LEN*NumSegs))
    return z-SEG_LEN*NumSegs*lps
end

function DepthToSegIndex(z)
  return flr(z/SEG_LEN) % NumSegs + 1;
end

function AddSeg( c, y )
    NumSegs+=1
    add( sPointsC, c )
    add( sPointsX, 0 )
    add( sPointsY, y )
    add( sPointsZ, NumSegs * SEG_LEN + 1 )
    add( sTokensX, 0 )
    add( sTokensExist, 0 )
end

function AddSprites( n, p )

    for i = 1, n do

        if p == 0 then
            add( sSprite, 0 )
            add( sSpriteX, 0 )
            add( sSpriteSc, 0 )
        else
            srand( #sSprite )
            added = false
            for j = 1, #SPDEF[p] do
                if #sSprite % SPDEF[p][j][2] == 0 then
                    -- index in SDEF, interval, minx (*roadw), maxx (*roadw), rand l/r
                    xrand = 1
                    if SPDEF[p][j][5] == 1 and rnd( 30000 ) > 15000 then
                        xrand = -1
                    end
                    spindex=SPDEF[p][j][1]
                    add( sSprite, spindex )
                    add( sSpriteX, ( SPDEF[p][j][3] + rnd( SPDEF[p][j][4] - SPDEF[p][j][3] ) ) * xrand )
                    add( sSpriteSc, 0.3*(SDEF[spindex][5]+rnd(SDEF[spindex][6]-SDEF[spindex][5])) )
                    added = true
                    break
                end
            end
            if added == false then
                add( sSprite, 0 )
                add( sSpriteX, 0 )
                add( sSpriteSc, 0 )
            end
        end
    end

end

function AddCurve( enter, hold, exit, c, y, sprp )

    tot=(enter+hold+exit)
    AddSprites( tot, sprp )

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

function AddStraight( n, y, sprp )
    
    AddSprites( n, sprp )
    for i=1,n do
        AddSeg( 0, easeinout( LastY, y, i/n ) )
    end
    LastY=y
end

function AddTokens( seg, x, n )
    for i=1,n do
        idx=seg + i*2-1
        sTokensX[idx] = x
        sTokensExist[idx]=1
    end
    NumTokens += n
end

function InitSegments( tsdef )

    for i=1,#TRACKSEGDEF[tsdef] do
        tsegdef=TRACKSEGDEF[tsdef][i]
        if tsegdef[4] == 1 then
            AddStraight( tsegdef[2], tsegdef[3], tsegdef[1] )
        elseif tsegdef[4] == 2 then
            AddCurve( tsegdef[5], tsegdef[2], tsegdef[6], tsegdef[7], tsegdef[3], tsegdef[1] )
        end
    end

end

function DEBUG_INITSEG()

    LastY = 0
    
    AddStraight( 40, 0, 3 )
    --AddStraight( 40, 0, 4 )
    AddCurve( 40,40,40,-2.5, 0, 1 )
    --[[
    AddStraight( 14, 30, 3 )
    AddStraight( 10, -10, 3 )
    AddStraight( 20, 0, 4 )
    AddCurve( 10,10,10, 0.6, -20, 4 )
    AddStraight( 10, -10, 3 )
    AddCurve( 10,10,10, -0.6, 0, 4 )
    AddCurve( 10,20,10, 1.6, 50, 2 )
    AddStraight( 40, 0, 3 )
    --]]
    AddTokens( 90, -0.6, 5 )
end

function InitOps()
    for i=1,8 do
        OpptPos[i] = SEG_LEN+SEG_LEN *  i
        OpptX[i]=((i%2)*2-1)*0.2
        OpptV[i]=0
        OpptLap[i]=1
    end
    RubberBand = 0
end

function InitRace()

    NumTokens=0

    InitSegments(1)
    assert( #sPointsC > 1 )
    InitOps()
    RaceStateTimer = time()
    RaceState = 2
    
    Position = SEG_LEN
    PlayerX = -0.2 -- -1 to 1 TODO: maybe don't make relative to road width
    PlayerXd = 0
    PlayerY = 0
    PlayerYd = 0
    PlayerVl = 0
    PlayerVf = 0
    PlayerDrift = 0
    PlayerAir = 0
    PlayerSeg = 0 -- current player segment
    PlayerLap = 3

    RecoverStage = 0 -- 1. pause 2. lerp to track 3. flash
    RecoverTimer = 0
    InvincibleTime = 0
end

function _init()

    -- draw black pixels
    palt(0, false)
    -- don't draw tan pixels
    palt(15, true)

    InitParticles()

    InitRace()

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

    Position=Position+5

end

function UpdateRaceInput()

    if RaceState != 2 then return end

    if btn(3) then -- down
        if abs( PlayerXd ) > 0.1 then
            PlayerDrift=sgn(PlayerXd)
        else
            PlayerVl=PlayerVl-0.08
        end
    end

    if btn(4) then -- z / btn1
        PlayerVl=PlayerVl+0.14
    end

    if btn(0) then -- left
        PlayerXd-= (0.04 + -PlayerDrift*0.02) * (1-PlayerVl*0.002)*min(PlayerVl*0.25,1)
    elseif btn(1) then -- right
        PlayerXd+= (0.04 + PlayerDrift*0.02) * (1-PlayerVl*0.002)*min(PlayerVl*0.25,1)
    end

end

function UpdatePlayer()

    if InvincibleTime-time() < 0 then
        InvincibleTime = 0
    end

    if PlayerAir == 0 then
        if RecoverStage == 0 and RaceState < 3 then
            UpdateRaceInput()
        elseif RaceState >= 3 then
             PlayerVl=PlayerVl+0.01
        end
        drftslw=(1-abs(PlayerDrift)*0.005)
        if abs( PlayerX*ROAD_WIDTH ) > ROAD_WIDTH then
            PlayerVl=PlayerVl*0.96*drftslw
            PlayerXd=PlayerXd*0.85
        else
            PlayerVl=PlayerVl*0.99*drftslw
            PlayerXd=PlayerXd*0.9
        end
    end
    if PlayerVl < 0.02 then
        PlayerVl = 0
    end

    PlayerVf = PlayerVl*0.6
    Position=Position+PlayerVf
    if Position > SEG_LEN*NumSegs then
        Position -= SEG_LEN*NumSegs
        PlayerLap += 1
    end

    PlayerSeg=DepthToSegIndex(Position)

    nxtseg=(PlayerSeg)%NumSegs + 1
    posinseg=1-(PlayerSeg*SEG_LEN-Position)/SEG_LEN

    if abs( PlayerXd ) < 0.01 then
        PlayerXd = 0
    end
    PlayerX+=sPointsC[PlayerSeg]*0.6*PlayerVl*0.01
    PlayerX+=PlayerXd*0.3

    if abs( PlayerXd ) < 0.08 then
        PlayerDrift=0
    end

    HznOffset = HznOffset + sPointsC[PlayerSeg] * 0.14 * (PlayerVf+0.1)

     -- jumps / player y

    ground = lerp( sPointsY[PlayerSeg], sPointsY[nxtseg], posinseg)
    PlayerY=max(PlayerY+PlayerYd, ground)
    if( PlayerY == ground ) then
        if PlayerYd < -3 and PlayerAir > 4 then
            sScreenShake = {2,7}
            AddParticle( 6, 52, 122 )
            AddParticle( 7, 78, 126 )
            AddParticle( 1, 52, 122 )
            AddParticle( 2, 78, 122 )
        end
        nposinseg=1-(PlayerSeg*SEG_LEN-(Position+PlayerVf ))/SEG_LEN
        nground = lerp( sPointsY[PlayerSeg], sPointsY[nxtseg], nposinseg )
        PlayerYd = ( nground - ground ) - 0.4
        
        PlayerAir = 0
    else
        PlayerYd=PlayerYd-0.7
        PlayerAir = PlayerAir + 1
    end

    -- particles

    if RecoverStage < 2 then
        if abs( PlayerX*ROAD_WIDTH ) > ROAD_WIDTH and PlayerAir == 0 then
            dirtfq=flr(7-min( PlayerVf, 6 ))
            if Frame%dirtfq == 0 then
                srand(Frame)
                AddParticle( 3, 64 + rnd(32)-16, 124 + rnd( 2 ) )
            end
            if Frame%(dirtfq*4) == 0 then
                sScreenShake[1] = 2 * PlayerVf * 0.1
                sScreenShake[2] = 1 * PlayerVf * 0.1
            end
        else
            if Frame%4 == 0 then
                if PlayerDrift < 0 then
                    AddParticle( 1, 58 - rnd( 4 ), 120 + rnd( 2 ) )
                elseif PlayerDrift > 0 then
                    AddParticle( 2, 70 + rnd( 4 ), 120 + rnd( 2 ) )
                end
            end
        end
    end
end

function UpdateRecover()
    
    if RecoverStage == 0 then
        return
    else
        
        t1=1.5
        t2=2.5
        t3=3.5
        if RecoverStage == 1 then

            srand( time() )
            if Frame%2==0 then
                AddParticle( 8, 64 + rnd(8)-4, 98 + rnd( 2 ) )
            end
            if Frame%4==0 then
                AddParticle( 9, 64 + rnd(8)-4, 88 + rnd( 8 ) )
            end

            if time() - RecoverTimer >= t1 then
                RecoverStage = 2
                ClearParticles()
            end
        elseif RecoverStage == 2 then
            instage=(time()-RecoverTimer-t1)/(t2-t1)
            PlayerVl=8
            PlayerX=lerp(PlayerX,0,instage)
            if time() - RecoverTimer >= t2 then
                RecoverStage = 3
                InvincibleTime=time()+1
            end
        elseif RecoverStage == 3 then
            PlayerX = 0
            if time() - RecoverTimer >= t3 then
                RecoverStage = 0
            end
        end
    end

end

function UpdateOpts()
    
    rbandnxt=0
    for i=1,#OpptPos do

        OpptPos[i]=OpptPos[i]+OpptV[i]
        if OpptPos[i] > SEG_LEN*NumSegs then
            OpptPos[i] -= SEG_LEN*NumSegs
            OpptLap[i] += 1
        end
        OpptSeg[i]=DepthToSegIndex(OpptPos[i])
        plsegoff1=(OpptSeg[i]-PlayerSeg)%NumSegs+1

        rbrange=20
        rbandnxt=max(rbandnxt, max(rbrange - plsegoff1,0)/rbrange )

        if RaceState > 1 then
            opspd=0.1
            if RaceState >= 3 then
                opspd=0.01
            end
            OpptV[i]=OpptV[i]+opspd+RubberBand*PlayerVl*0.01+i*0.02
            OpptV[i]=OpptV[i]*0.95
                        
            if plsegoff1 < 20 and abs( PlayerX - OpptX[i] ) > 0.05 and RecoverStage == 0 then
                OpptX[i] = min( max( OpptX[i] + 0.01 * sgn( PlayerX - OpptX[i] ), -0.8 ), 0.8 )
            end
        end
        
        

        
    end
    RubberBand = rbandnxt
end

function AddCollisionParticles()
    AddParticle( 4, 64 + rnd(32)-16, 96 + rnd( 8 ) )
    AddParticle( 5, 64 + rnd(32)-16, 96 + rnd( 8 ) )
    AddParticle( 6, 64 + rnd(16)-8, 102 - rnd( 8 ) )
    AddParticle( 7, 54 + rnd(32)-16, 102 + rnd( 8 ) )
    AddParticle( 7, 64 + rnd(16)-8, 102 - rnd( 8 ) )
    AddParticle( 6, 74 + rnd(32)-16, 102 + rnd( 8 ) )
end

function UpdateCollide()

    if InvincibleTime > 0 or RecoverStage > 0 then
        return
    end

    nxtseg=(PlayerSeg)%NumSegs + 1

    -- opponents

    carlen=5

    ground = lerp( sPointsY[PlayerSeg], sPointsY[nxtseg], posinseg)
    for i=1,#OpptPos do

        opposl = LoopedTrackPos( OpptPos[i] )

        if ( Position + PlayerVf ) > ( opposl - carlen + OpptV[i] ) and
           ( Position + PlayerVf ) < ( opposl + OpptV[i] ) and
            ROAD_WIDTH * abs( PlayerX - OpptX[i] ) < 8 and
            ( PlayerY-ground ) < 2 then
        
            PlayerVl = OpptV[i] * 0.9
            PlayerXd = -sgn(PlayerX) * 0.2

            sScreenShake[1] = 6
            sScreenShake[2] = 2

            AddCollisionParticles()

        end
    end

    -- tokens

    if sTokensX[nxtseg] != 0 and sTokensExist[nxtseg] != 0 then
        hitbox=0.2
        if PlayerDrift != 0 then
            hitbox=0.25
        end
        if abs( PlayerX - sTokensX[nxtseg] ) < hitbox and 
            ( Position + carlen + PlayerVf ) > PlayerSeg*SEG_LEN then
            sTokensExist[nxtseg] = 0
        end
    end

    -- sprites

    if sSprite[nxtseg] > 0 and ( Position + carlen + PlayerVf ) > PlayerSeg*SEG_LEN then

        sdef1=SDEF[sSprite[nxtseg]]        
        -- work out the range of pixels in the source sprite that we overlap

        -- these are roughly where the player is in screenspace x normalised
        plx1n=0.375
        plx2n=0.625

        --DebugPrint(SpriteCollideRect[1] )
        --DebugPrint(SpriteCollideRect[3] )
        --DebugPrint(SpriteCollideRect[3] - SpriteCollideRect[1] )

        -- where is the player in the sprite screenspace rect
        --inrect1n=lerp( SpriteCollideRect[1], SpriteCollideRect[1] + SpriteCollideRect[3], 48/SpriteCollideRect[3])
        
        --inrect1n=SpriteCollideRect[1]+(48-SpriteCollideRect[1])/SpriteCollideRect[3]
        --inrect2n=SpriteCollideRect[1]+(80-SpriteCollideRect[1])/SpriteCollideRect[3]

        --sx2ss=SpriteCollideRect[1]+SpriteCollideRect[3];
        inrect1n=SpriteCollideRect[1]+(48-SpriteCollideRect[1])/SpriteCollideRect[3]

        --DebugPrint(inrect1n)
        --DebugPrint(inrect2n)

        --it1=sdef1[3]*inrect1n
        --it2=sdef1[3]*inrect2n

        --sspr(it1,sdef1[2]+sdef1[4],it2-it1,1,1,1,it2-it1,1)

        --for colit=flr(it1), flr(it2) do
            --DebugPrint(sget(sdef1[1]+colit,sdef1[2]+sdef1[4]))
        --end

        --colrect = SpriteCollideRect
        --colrect[1] = SpriteCollideRect[3] + SpriteCollideRect[3] * sdef1[8]
        --colrect[3] = SpriteCollideRect[3] * sdef1[8]

        --[[
        if abs( PlayerX - sSpriteX[nxtseg] ) < sSpriteSc[nxtseg] * 0.5 and
            
        then

            if PlayerVf < 2 then
                sScreenShake[1] = 3
                sScreenShake[2] = 1
                PlayerVl = PlayerVl * 0.5
                PlayerXd = -sgn(PlayerX) * 0.2
                InvincibleTime=time()+1
                AddParticle( 4, 64 + rnd(32)-16, 96 + rnd( 8 ) )
                AddParticle( 5, 64 + rnd(32)-16, 96 + rnd( 8 ) )
            else

                sScreenShake[1] = 8
                sScreenShake[2] = 3

                PlayerXd = sgn(PlayerX) * 0.2
                PlayerVl = 0.5
                RecoverStage = 1
                RecoverTimer = time()
                AddCollisionParticles()
            end
        end
        --]]
    end

end

function UpdateRaceState()
--    DebugPrint( time() - RaceStateTimer )
    if RaceState==1 and (time() - RaceStateTimer) > 3 then
        RaceState=2
        RaceStateTimer=time()
    elseif RaceState==2 and PlayerLap == NUM_LAPS+1 then
        RaceState=3
        RaceCompleteTime=RaceStateTimer
        RaceCompletePos=GetPlayerStanding()
        RaceStateTimer=time()
    end
end

function _update()

    DebugUpdate()
    Frame=Frame+1

    -- screenshake

    sScreenShake[1] = -sScreenShake[1]*0.8
    sScreenShake[2] = -sScreenShake[2]*0.8
    if( abs( sScreenShake[1] ) + abs( sScreenShake[2] ) < 1 ) then
        sScreenShake = {0,0}
    end
    -- camera(sScreenShake[1],sScreenShake[2])

    UpdatePlayer()
    UpdateRecover()
    UpdateCollide()
    UpdateOpts()
    UpdateParticles()
    UpdateRaceState()
    --constedits()
end

function HrzSprite( x, sx, sy, f )
 sspr( 0,24,48,16, (HznOffset + x) % 256 - 128, 64 - flr( sy * 16 ), sx * 48, sy * 16, f )
end

function RenderHorizon()

    fillp(0)
    rectfill( -10, 74, 138, 128, 3 ) -- block out
    BayerRectV( -10, 64, 138, 74, 3, 13 )
    HrzSprite(10, 1.0, 0.7, true)
    HrzSprite(64, 0.3, 1.5, false)
    HrzSprite(60, 2.3, 0.3, false)
    HrzSprite(128, 1, 1, false)
    HrzSprite(178, 1.5, 0.5, true)
    --[[
    hznoff =  HznOffset % 256 - 128
    BayerRectV( -10, 64, 138, 74, 3, 13 )
    sspr( 0,24,48,16, hznoff, 48, 48, 16 )
    sspr( 0,24,48,16, hznoff + 40, 56, 24, 8 )
    sspr( 0,24,48,16, hznoff + 90, 56, 24, 8 )
    sspr( 0,24,48,16, hznoff + 128, 56, 24, 8 )
    sspr( 0,24,48,16, hznoff + 160, 56, 24, 8 )
    sspr( 0,24,48,16, hznoff + 196, 48, 48, 16 )
    --]]
 --   sspr( 0,24,48,16, HznOffset + 20, 48, )

end

function RenderSky()
    fillp(0)
    rectfill( -10, 0, 128, 44, 12 ) -- block out
    BayerRectV( -10, 40, 138, 64, 6, 12 )
end

function RenderPoly4( v1, v2, v3, v4, c )

    polyfill({{x=v1[1],y=v1[2]},{x=v2[1],y=v2[2]},{x=v3[1],y=v3[2]}},c)
    polyfill({{x=v1[1],y=v1[2]},{x=v4[1],y=v4[2]},{x=v3[1],y=v3[2]}},c)

end

function RenderSeg( x1, y1, w1, x2, y2, w2, idx )

    thm=THEMEDEF[Theme]

    -- Edge
    if idx % 4 > 1 then
        fillp(0)
        col = thm[6]
    else
        fillp(0x5A5A)
        col = thm[7]
    end
    edgew1=w1*0.86
    edgew2=w2*0.86
    RenderPoly4( {x1-edgew1,y1},{x1-w1,y1},{x2-w2,y2},{x2-edgew2,y2}, col )
    RenderPoly4( {x1+w1,y1},{x1+edgew1,y1},{x2+edgew2,y2},{x2+w2,y2}, col )

    -- Ground
    if idx % 8 > 3 then
        fillp(0)
        col = thm[4]
    else
        fillp(0x5A5A)
        col = thm[5]
    end
    
    RenderPoly4( {-10,y2},{-10,y1},{x1-w1,y1},{x2-w2,y2}, col )
    RenderPoly4( {138,y2},{138,y1},{x1+w1,y1},{x2+w2,y2}, col )

    -- Road
    if thm[3] == 1 then
        -- stripes
        if idx == 1 then
            fillp(0)
            col = 1
        else
            if idx % 3 == 0 then
                fillp(0x5A5A)
                col = thm[2]
            else
                fillp(0)
                col = thm[1]
            end
        end
        RenderPoly4( {x1-edgew1,y1},{x1+edgew1,y1},{x2+edgew2,y2},{x2-edgew2,y2}, col )
    elseif thm[3] == 2 then
        -- patches
        fillp(0x5A5A)
        col = thm[2]
        -- TODO: dont overdraw
        RenderPoly4( {x1-edgew1,y1},{x1+edgew1,y1},{x2+edgew2,y2},{x2-edgew2,y2}, col )
        fillp(0)
        if idx == 1 then
            col = 1
        else
            col = thm[1]
        end
        srand( idx )
        pminx=rnd( 0.6 ) + 0.3
        pmaxx=rnd( 0.6 ) + 0.3
        RenderPoly4( {x1-w1*pminx,y1},{x1+w1*pmaxx,y1},{x2+w2*pmaxx,y2},{x2-w2*pminx,y2}, col )
    end

     -- Lanes
     if thm[8] == 1 then
        -- edge lane
        if idx % 2 > 0 then
            fillp(0)
            col = 6
            dst1=0.74
            dst2=0.78
            RenderPoly4( {x1-w1*dst1,y1},{x1-w1*dst2,y1},{x2-w2*dst2,y2},{x2-w2*dst1,y2}, col )
            RenderPoly4( {x1+w1*dst2,y1},{x1+w1*dst1,y1},{x2+w2*dst1,y2},{x2+w2*dst2,y2}, col )
        end
    elseif thm[8] == 2 then
        -- centre alternating
        if idx % 4 > 2 then
            fillp(0)
            col = 6
            lanew=0.02
            RenderPoly4( {x1-w1*lanew,y1},{x1+w1*lanew,y1},{x2+w2*lanew,y2},{x2-w2*lanew,y2}, col )
        end
    end

    

end -- RenderSeg

function _draw()
	cls()
    
	camera( 0 + sScreenShake[1], HUD_HEIGHT + sScreenShake[2] )
    RenderSky()
    RenderHorizon()
    RenderRoad()
    camera( 0, 0 )
    RenderUI()

    DebugRender()

end

function PrintBigDigit( n, x, y, nrend )
    i=n+1
    if nrend == 0 then
        sspr( NFDEF[i][1], NFDEF[i][2], NFDEF[i][3], NFDEF[i][4], x, y )
    end
    return x + NFDEF[i][3] + 1
end

function PrintBigDigitOutline( n, x, y, col )
    i=n+1
    pal( 7, col )
    sspr( NFDEF[i][1], NFDEF[i][2], NFDEF[i][3], NFDEF[i][4], x-1, y )
    sspr( NFDEF[i][1], NFDEF[i][2], NFDEF[i][3], NFDEF[i][4], x+1, y )
    sspr( NFDEF[i][1], NFDEF[i][2], NFDEF[i][3], NFDEF[i][4], x, y-1 )
    sspr( NFDEF[i][1], NFDEF[i][2], NFDEF[i][3], NFDEF[i][4], x, y+1 )
    pal( 7, 7 )
end


function PrintBigNum( n, x, y, nrend )

    hnd=flr(n/100)
    ten=flr(n%100/10)
    unit=flr(n%10)

    xpos=x
    if hnd != 0 then
        x = PrintBigDigit( hnd, x, y, nrend )
    end
    if ten != 0 or hnd != 0 then
        x = PrintBigDigit( ten, x, y, nrend )
    end
    return PrintBigDigit( unit, x, y, nrend )

end

function GetPlayerStanding()
    s=#OpptPos+1
    for i=1,#OpptPos do
        if OpptLap[i] < PlayerLap then
            s-=1
        elseif OpptLap[i] == PlayerLap and OpptPos[i]<Position then
            s-=1
        end
    end
    return s
end

function GetStandingSuffix(n)

    if n == 1 then
        return "st"
    elseif n== 2 then
        return "nd"
    elseif n==3 then
        return "rd"
    else
        return "th"
    end

    return ""

end

function GetTokenCount()
    n=0
    for i=1,#sTokensExist do
        if sTokensExist[i] == 1 then
            n+=1
        end
    end
    return NumTokens-n
end

function RenderCountdown()

    if RaceState == 2 and time() - RaceStateTimer < 1 then
        frac=( time() - RaceStateTimer )%1
        PrintBigDigitOutline( 10,64-NFDEF[11][3]*0.5-8,30, 0 )
        PrintBigDigitOutline( 0,64-NFDEF[1][3]*0.5+7,30, 0 )
        PrintBigDigit( 10,64-NFDEF[11][3]*0.5-8,30,0 )
        PrintBigDigit( 0,64-NFDEF[1][3]*0.5+7,30,0 )
        clip( 0, 33, 128, 128 )
        pal( 7, 10 )
        PrintBigDigit( 10,64-NFDEF[11][3]*0.5-8,30,0 )
        PrintBigDigit( 0,64-NFDEF[1][3]*0.5+7,30,0 )
        clip( 0, 39, 128, 128 )
        pal( 7, 9 )
        PrintBigDigit( 10,64-NFDEF[11][3]*0.5-8,30,0 )
        PrintBigDigit( 0,64-NFDEF[1][3]*0.5+7,30,0 )
        pal( 7, 7 )
        pal( 7, 7 )
        clip()
    elseif RaceState == 1 then
        num= 3-flr( time() - RaceStateTimer )
        frac=( time() - RaceStateTimer )%1
        if num <= 0 then
            return
        elseif frac < 0.9 then
            PrintBigDigitOutline( num,64-NFDEF[num+1][3]*0.5,30, 0 )
            PrintBigDigit( num,64-NFDEF[num+1][3]*0.5,30,0 )
            clip( 0, 33, 128, 128 )
            pal( 7, 10 )
            PrintBigDigit( num,64-NFDEF[num+1][3]*0.5,30,0 )
            clip( 0, 39, 128, 128 )
            pal( 7, 9 )
            PrintBigDigit( num,64-NFDEF[num+1][3]*0.5,30,0 )
            pal( 7, 7 )
            clip()
        end
    end
end

function RenderRaceEndStanding()
    if RaceState != 3 then return end
    assert( (time()>=RaceStateTimer))
    
    if time()-RaceStateTimer < 1 then
        clip( 0, 0, ((time()-RaceStateTimer)*8)*128, 128 )
    elseif time()-RaceStateTimer > 3 then
        clip( ((time()-(RaceStateTimer+3))*8)*128, 0, 128, 128 )
    end
    rectfill( 0, 25, 128, 49, 1 )
    tw=PrintBigDigit( RaceCompletePos, 0, 0, 1 )
    PrintBigDigit( RaceCompletePos, 64-(tw*0.5+4), 32, 0 )
    print( GetStandingSuffix(RaceCompletePos), 64+tw*0.5-3, 32, 7 )

    sspr( 121, 32, 7, 19, 64-(tw+8+7), 27, 7, 19, true )
    sspr( 121, 32, 7, 19, 64+(tw+8), 27, 7, 19 )

    clip()

    if time()-RaceStateTimer > 3.6 then
        fade=max( (0.5-(time()-(RaceStateTimer+3.6)))/0.5, 0 )
        BayerRectT( 0, 0, 128, 128, 0xE0, fade )    
    elseif time()-RaceStateTimer > 4.2 then
        RaceState = 4
    end
end

function RenderSummaryUI()

    rectfill( 0, 0, 128, 128, 0 )
    print( "lol", 20, 20 )

end

function RenderUI()

    fillp(0)
    rectfill( 0,111, 127, 127, 0 )
    rect( 0, 111, 127, 127, 6 )
    rect( 1, 112, 126, 126, 13 )
    
    stand=GetPlayerStanding()
    strlen=PrintBigNum( GetPlayerStanding(), 3, 114, 0 )
    print( GetStandingSuffix(stand), 16, 114, 7 )

    tkns=GetTokenCount()

    sspr( 0, 110, 9, 5, 37, 114 )
    print( PlayerLap, 49, 114, 6 )
    print( "/"..tostr(NUM_LAPS), 57, 114, 5 )

    sspr( 0, 104, 7, 5, 38, 120 )
    print( tkns, 49, 120, 6 )
    print( "/" ..tostr(NumTokens), 57, 120, 5 )

    for i=80, 124, 2 do
        y1 = flr(lerp( 121, 115, (i-107)/(113-107) ))
        y1=max(min(y1,121),115)
        -- top speed is ~14 m/s
        norm=(i-80)/(128-80)
        
        col = 5
        if norm < PlayerVl/14 then
            if i < 104 then
                col = 6
            elseif i < 118 then
                col = 7
            elseif i < 122 then
                col = 9
            else
                col = 8
            end
        end
        line( i, y1, i, 124, col )
    end

    spd=flr( PlayerVl * 15 )
    x1=88
    if spd > 9 then
        x1 -= 4
    end
    if spd > 99 then
        x1-= 4
    end
    print( flr( PlayerVl * 10.2 ), x1, 114, 6 )
    print( "mph", 94, 114, 6 )

    RenderCountdown()
    RenderRaceEndStanding()

end

function RenderPlayer()

    if RecoverStage == 2 or ( RecoverStage == 3 and time()%0.4>0.2 ) then
        return
    end

    if PlayerDrift != 0 then
        woby=rnd(1.8)
        spr( 9, 64 - 24 + PlayerDrift * 0, 100 - woby, 6, 3, PlayerDrift > 0 )
    elseif PlayerXd > 0.06 or PlayerXd < -0.06 then
        spr( 4, 44, 100, 5, 3, PlayerXd > 0 )
    else
        spr( 0, 48, 100, 4, 3 )
    end

end

function GetSpriteSSRect( s, x1, y1, w1, sc )
    ssc=w1*sc
    aspx = 1
    aspy = 1
    if SDEF[s][3] > SDEF[s][4] then
        aspx = SDEF[s][3]/SDEF[s][4]
    else
        aspy = SDEF[s][4]/SDEF[s][3]
    end
    
    rrect= { x1 - ssc * aspx * 0.5,
            y1 - ssc * aspy,
            ssc * aspx,
            ssc * aspy }
    return rrect
end

function RenderSpriteWorld( s, rrect, d )
    
    -- rectfill( x1 - ssc * 0.5, y1 - ssc, x1 - ssc * 0.5 + ssc, y1, 8 )
    -- rectfill( rrect[1], rrect[2], rrect[1] + rrect[3], rrect[2] + rrect[4], 8 )
    -- sspr seems to over-round the h/w down for some reason, so correct it
    --fact=max(min(d,1),0)
    --print(flr(1+fact*(#BAYER-1)))
    --fillp(BAYER[flr(1+fact*(#BAYER-1))]|0b.011)
    sspr( SDEF[s][1], SDEF[s][2], SDEF[s][3], SDEF[s][4], rrect[1], rrect[2], ceil(rrect[3] + 1), ceil(rrect[4] + 1), SDEF[s][7] == 1 )
    --sspr( SDEF[s][1], SDEF[s][2], SDEF[s][3], SDEF[s][4], rrect[1], rrect[2], rrect[3], rrect[4] )
    BayerRectT( rrect[1], rrect[2], rrect[1] + rrect[3], rrect[2] + rrect[4], 13, d )
end

function RenderSpriteRepeat( s, rrect, d, dx, dy, n )
    
    for i=1,n do
        RenderSpriteWorld( s, rrect, d )
        rrect[1]=rrect[1]+rrect[3]*dx
        rrect[2]=rrect[2]+rrect[4]*dy
    end
end

function RenderRoad()
       
    loopoff=0

    pscreenscale = {}
    psx = {}
    psy = {}
    psw = {}

    pcamx = {}
    pcamy = {}
    pcamz = {}
    pcrv = {}

    clipy={}

    camx = PlayerX * ROAD_WIDTH
    xoff = 0
    posinseg=1-(PlayerSeg*SEG_LEN-Position)/SEG_LEN
    dxoff = - sPointsC[PlayerSeg] * posinseg
    miny=1000
   
    -- calculate projections
    
    for i = 1, DRAW_DIST do

        segidx = (PlayerSeg - 2 + i ) % NumSegs + 1

        pcrv[i] = xoff - dxoff
        pcamx[i] = sPointsX[segidx] - camx - pcrv[i];
        pcamy[i] = sPointsY[segidx] - ( CAM_HEIGHT + PlayerY );
        pcamz[i] = sPointsZ[segidx] - (Position - loopoff);

        if segidx == NumSegs then
            loopoff+=NumSegs*SEG_LEN
        end

        xoff = xoff + dxoff
        dxoff = dxoff + sPointsC[segidx]

    end

    for i = DRAW_DIST - 1, 1, -1 do

        for j = 1, 2 do
            pscreenscale[j] = CAM_DEPTH/pcamz[i+(j-1)];
            psx[j] = flr(64 + (pscreenscale[j] * pcamx[i+(j-1)]  * 64));
            psy[j] = flr(64 - (pscreenscale[j] * pcamy[i+(j-1)]  * 64));
            psw[j] = flr(pscreenscale[j] * ROAD_WIDTH * 64);
        end

        segidx = (PlayerSeg - 2 + i ) % NumSegs + 1
        -- segments
        if ( psy[1] < 128 or psy[2] < 128 ) and ( psy[1] >= psy[2]  ) then -- and ( psy[2] <= miny+1 )
            RenderSeg( psx[1], psy[1], psw[1], psx[2], psy[2], psw[2], segidx )
        end

        if i==1 then
            RenderPlayer()
            RenderParticles()
        end

        -- sprites
        
        if sSprite[segidx] != 0 then
            psx1 = flr(64 + (pscreenscale[1] * ( pcamx[i] + sSpriteX[segidx] * ROAD_WIDTH ) * 64));
            d = min( ( 1 - pcamz[i] / (DRAW_DIST*SEG_LEN) ) * 8 , 1 )
            rrect = GetSpriteSSRect( sSprite[segidx], psx1, psy[1],psw[1], sSpriteSc[segidx] )
            RenderSpriteWorld( sSprite[segidx], rrect, d )
            if i == 2 then
                SpriteCollideRect = rrect
            end
        end

        -- Start gantry
        if segidx == 1 or segidx == 2 then
            psx1l = flr(64 + (pscreenscale[1] * ( pcamx[i] + ROAD_WIDTH * -1.2 ) * 64));
            psx1r = flr(64 + (pscreenscale[1] * ( pcamx[i] + ROAD_WIDTH * 1.2 ) * 64));
            d = min( ( 1 - pcamz[i] / (DRAW_DIST*SEG_LEN) ) * 8 , 1 )
            rrect = GetSpriteSSRect( 11, psx1l, psy[1],psw[1], 0.1 )
            RenderSpriteRepeat( 11, rrect, d, 0, -1, 10 )
            rrect = GetSpriteSSRect( 11, psx1r, psy[1],psw[1], 0.1 )
            RenderSpriteRepeat( 11, rrect, d, 0, -1, 10 )
            if segidx == 1 then
                psx1l = flr(64 + (pscreenscale[1] * ( pcamx[i] + ROAD_WIDTH * -0.55 ) * 64));
                psx1r = flr(64 + (pscreenscale[1] * ( pcamx[i] + ROAD_WIDTH * 0.55 ) * 64));
                rrect = GetSpriteSSRect( 12, psx1l, psy[1],psw[1], 1 )
                RenderSpriteWorld( 12, rrect, d )
                
                rrect = GetSpriteSSRect( 13, psx1r, psy[1],psw[1], 1 )
                RenderSpriteWorld( 13, rrect, d )
            end
        end

        -- tokens
        if sTokensX[segidx] !=0 and sTokensExist[segidx] != 0 then
            psx1 = flr(64 + (pscreenscale[1] * ( pcamx[i] + sTokensX[segidx] * ROAD_WIDTH ) * 64));
            d = min( ( 1 - pcamz[i] / (DRAW_DIST*SEG_LEN) ) * 8 , 1 )
            rrect = GetSpriteSSRect( 10, psx1, psy[1],psw[1], 0.2 )
            RenderSpriteWorld( 10, rrect, d )
        end

        -- opponents
        for o = 1,#OpptPos do
            if OpptSeg[o] == segidx then
                
                plsegoff1=(OpptSeg[o]-PlayerSeg)%NumSegs+1
                opinseg=1-(OpptSeg[o]*SEG_LEN-OpptPos[o])/SEG_LEN

                nxtseg = (OpptSeg[o]) % NumSegs + 1
            
                plsegoff2=(nxtseg-PlayerSeg)%NumSegs+1
                
                ocrv=lerp( pcrv[plsegoff1], pcrv[plsegoff2], opinseg );
                optx=OpptX[o]*ROAD_WIDTH
                opcamx = lerp( sPointsX[OpptSeg[o]] + optx, sPointsX[nxtseg] + optx, opinseg ) - camx - ocrv;
                opcamy = lerp( sPointsY[OpptSeg[o]], sPointsY[nxtseg], opinseg ) - ( CAM_HEIGHT + PlayerY );
                opcamz = lerp( sPointsZ[OpptSeg[o]], sPointsZ[nxtseg], opinseg ) - (Position);

                opss = CAM_DEPTH/opcamz;
                opsx = flr(64 + (opss * opcamx * 64));
                opsy = flr(64 - (opss * opcamy * 64));
                opsw = flr(opss * ROAD_WIDTH * 64);

                opcols1 = { 12, 11, 10, 9, 8, 6 }
                opcols2 = { 1, 3, 4, 4, 2, 5 }
                pal( 14, opcols1[o%#opcols1+1] )
                pal( 2, opcols2[o%#opcols2+1] )

                if sPointsC[OpptSeg[o]] > 0.5 then
                    rrect = GetSpriteSSRect( 8, opsx, opsy,opsw, 0.16 )
                    RenderSpriteWorld( 8, rrect, 1 )
                elseif sPointsC[OpptSeg[o]] < -0.5 then
                    rrect = GetSpriteSSRect( 9, opsx, opsy,opsw, 0.16 )
                    RenderSpriteWorld( 9, rrect, 1 )
                else
                    rrect = GetSpriteSSRect( 7, opsx, opsy,opsw, 0.16 )
                    RenderSpriteWorld( 7, rrect, 1 )
                end

                pal( 14, 14 )
                pal( 2, 2 )
            end
        end

    end
end -- RenderRoad










__gfx__
fffffffeeeeeeeeeeeeeeeeeeffffffffffffffff11eeeeeeeeeeeeeeeeeefffffffffffffffffffffffffe1eeeeeeeeeeeeeeeeeeffffffffffffffffffffff
ffffff5eeeeeeeeeeeeeeeeee5fffffffffffffddddeddd5555555555d555dfffffffffffffffffffff1dddd1eeeeee55555555dddddffffffffffffffffffff
ffff155ddd555555555555ddd551ffffffffeddddd0dddddddddddddddddd66fffffffffffffffffdddddddde0eddddddddd666666666fffffffffffffffffff
fff555dddddddddddddddddddd555fffffff1155d5e6666666666dddddddddddffffffff8e8e8e1d5ddddddd5ee6666666ddddddddddddffffffffffffffffff
ff15e6666666666666666666666e51ffffff21555edddddddddddddddddddddddfffffffe800e811155d5dd5eeeddddddddddddd66666666ffffffffffffffff
ff0dedddddddddddddddddddddded0ffffff2115ee666666666666666666666dddffffff8e108e8e11151de0eedddd66666666ddd5555555dfffffffffffffff
ffde666666666666666666666666edffffff22eeedddd55555dddddd5555555555ddffffe001e8e8e8111d5eee66dd5555d5dddd55556666660000ffffffffff
ffedddd55555dddddddd55555ddddeffffff00eedd555555666666666666000000000fff80000e8e8e8e15eeeedd555556666666000000000000000fffffffff
fe6666666666666666666666666666efffff022eeee000000000000000000000000000ff10000218e811e8eeee666666000000000000022222000000ffffffff
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
fffffffffffffff7ddffffffffffffffffffffffffffffffa000a9a9ff6636ffffff666ffe7fffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff75dffffffffffffffffffffffffffffff9a000a99f63bbbb66ff66666feeffffffffffffffffffffffffffffffff11661166116611f555555
fffffffffffffff75dffffffffffffffffffffffffffffffa9a000a96b7b37b356fdff66ffeffffffffffffffffffffffffffff555500770077007700f55ff65
fffffffffffffff75dffffffffff55fffdffffffffffffff999900095333733353fdddddffeffffffffffffffffffffffffffff555577007700770077f5f5f65
ffffffffffffff6d5dfffffffff5551ff5ffffffffffffffa9a000995533333536ff555f7ffffffffffffffffffffffffffffff555577007700770077f5ff565
ffffffffffffff6555ffdffffff5111ff56fffffffffffff9a000999f555335533fffffffafffffffffffffffffffffffffffff555500770077007700f566655
ffffffffffff51d551115ffffff5151ff55fffffffffffffa0009999ffff4f334fffffe7ffaffffffffffffffffffffffffffffffff11661166116611f555555
ffffffffdfffd16555111ffffff51116d51fffffffffffff55551151ffff2ff4ffffeeefffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffddf6d16155111dd6d6551116651fffffffffffffffffffffffff222fffffeefffafffffffffffffffffffffffffffffffffffffffffffffffff7ffff
ffffffddd5f5d1d5551116d6d65515166516ffffffffffffff9aaaffffff22ffffffffff9afffffffffffffffffffffffffffffffffffffffffffffffff7ffff
ffff5fddd5d1d1d5111116ddd61115166515fffffffffffff994a9afffff22ffffffa7ff899fffffffffffffffffffffffffffffffffffffffffffffff7fffff
fff656d5d55151d55511161ddd15111d651166df6dffffff9949994ffff9ffffffaaffff98ffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff5d5dd5d15151d51511161d1d11151111111ddd66ffffff49999999f9ff9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7ff
ff56dd11d155d1d11511161d1d1111111111dddddd151fff99599499ff4f4ff9fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff777ff
dd565d15d11dd1d11511161d1d5511111111115ddd66d5d655559595ff4f5f4ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff77fff
5d5d5666666dd5d11115155515515115111151ddddd66dd6f554555fff5f5f5fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
000000000000d0ddffffffffaa777fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff77
066666666611111df4449ff9aa5aa7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7777
1611d11ddd118110444449f9a585a7ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff77ff
0611d16d6d1a7e1d444f4f99597e57ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
1616d11ddd11c11054444449a5c5aaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff77
1666666666111110f55f44f9aa5aaaffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7777
1110100100000000ff555fff99999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7777f
fff11ff11ff11fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffd5ffddff5dfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff77ffff
fffd5ffddff5dffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff77777ff
fff41ff11ff14fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff77777f
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffff25222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffff2255452222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffff55444522222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffff22445442222522ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffff22554445522222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffff222554454522222522222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffff225544454552252522222222ff2222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fff25554455555544522222222222222255552222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff2545555555544445222222222222222252222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
f25555255225455452222222222222222222222222222fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
222222522255554522222222222222222222222222222222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
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
aaa5aaafffff7777777777ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
aa585aaffff77777777777ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
a597e5afff777777777777ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
aa5c5aafff777fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
aaa5aaafff777ff7777777ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffff777ff7777777ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
feeeeeeeff777ff7777777ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
efffffffef777ffffff777ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
efffefffef777777777777ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
feeffefefff77777777777ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffefffffff7777777777ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ff7777f7777777777fff7777777777ffffff777ff777ff777777777777fff777777777ffff77777777fffff77777777fffff77777777fffff77777777fffffff
ff7777f77777777777ff77777777777ffff7777ff777ff777777777777ff7777777777fff7777777777fff7777777777fff7777777777fff7777777777ffffff
ff7777f777777777777f777777777777ff7777fff777ff777777777777f77777777777ff777777777777f777777777777f777777777777f777777777777fffff
fff777ffffffffff777ffffffffff777f7777ffff777ff777ffffffffff777ffffffffff777ffffff777f777ffffff777f777ffffff777f777ffffff777fffff
fff777fff7777777777f777777777777f777fffff777ff7777777777fff7777777777ffffffffffff777f777777777777f777777777777f777ffffff777fffff
fff777ff7777777777ff777777777777f777fffff777ff77777777777ff77777777777fffffffffff777f777777777777f777777777777f777ffffff777fffff
fff777f7777777777fff777777777777f777777777777f777777777777f777777777777fffffffff7777f777777777777ff77777777777f777ffffff777fffff
fff777f777fffffffffffffffffff777ff77777777777ffffffffff777f777ffffff777ffffffff7777ff777ffffff777ffffffffff777f777ffffff777fffff
fff777f777777777777f777777777777fffffffff777ff777777777777f777777777777fffffff7777fff777777777777ff77777777777f777777777777fffff
fff777f777777777777f77777777777ffffffffff777ff77777777777fff7777777777fffffff7777fffff7777777777fff77777777777ff7777777777ffffff
fff777f777777777777f7777777777fffffffffff777ff7777777777fffff77777777ffffffff777fffffff77777777ffff7777777777ffff77777777fffffff
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

