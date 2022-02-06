pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
-- P2
-- by PAK-9

#include menus.lua
#include particle.lua
#include renderutils.lua
#include sound.lua
#include spritedef.lua
#include trackdef.lua
#include utility.lua
#include profile.lua
#include debug.lua

-- music(0)

Frame = 0

SEG_LEN = 10
DRAW_DIST = 60
CANVAS_SIZE = 128
ROAD_WIDTH = 60 -- half
CAM_HEIGHT = 21
CAM_DEPTH = 0.55; -- 1 / tan((100/2) * pi/180)  (fov is 100)

-- horizon sprite def
-- 1. sx 2. sy 3. sw 4. sh 5. xscale 6. yscale
HORZSDEF = {
{0, 24, 48, 16, 1, 1 }, -- 1. City
{0, 52, 48, 11, 1.2, 0.8 }, -- 2. Mountain
{0, 64, 45, 10, 1.2, 0.8 }, -- 3. Glacier
}

-- 1. Road c1 2. Road c2 3. Road pat 4. Ground c1 5. Ground c2(x2) 6. Edge c1 7. Edge c2(x2) 8. Lane pat 9. Sky c1 10. Sky c2 11. horizon spr
-- Road patterns: 1. alternating stripes 2. random patches
-- Lane patterns: 1. edges 2. centre alternating 3. 3 lane yellow
THEMEDEF = {
--    r1 r2   rp g1  g2   e1  e2   lp sk1 sk2 hz
    { 5, 0x5D, 1, 3, 0x3B, 6, 0x42, 1, 6, 12, 1 }, -- 1. USA
    { 5, 0x05, 1, 6, 0x6D, 6, 0x15, 3, 6, 12, 3 }, -- 2. Alaska
    { 5, 0x15, 1, 3, 0x23, 6, 0xC5, 2, 12,7,  1 }, -- 3. Japan
    { 5, 0x25, 2, 2, 0x21, 5, 0x42, 3, 13, 2, 2 }, -- 4. Oz
    { 4, 0x45, 2, 4, 0x34, 1, 0xD5, 2, 13, 12, 2 }, -- 5. nairobi
    { 5, 0x65, 2, 6, 0x76, 6, 0x15, 2, 6, 12, 3 }, -- 6. Nepal
    { 5, 0x51, 1, 5, 0x35, 6, 0x82, 1, 1, 0, 1 }, -- 7. Germany
    { 13, 0xCD, 1, 2, 0x2E, 10, 0xBD, 3, 6, 14, 2 }, -- 8. Funland
}

-- 1. Theme 2. spr pattern 3. yscale 4. curvescale 5. seed 6. name
LEVELDEF={
    { 1, 1, 1, 1, 1, "usa" },
    { 4, 4, 1, 1, 1, "australia" },
    { 2, 2, 1, 0.8, 1, "alaska" },
    { 3, 3, 1, 1, 1, "japan" },
    { 5, 4, 1, 1, 1, "nairobi" },
    { 6, 2, 1.1, 1, 1, "nepal" },
    { 7, 1, 1.1, 1, 1, "germany" },
    { 8, 4, 1.1, 1, 1, "funland" },
}

Theme = 1
Level=1

NumSegs = 0
sPointsX = {}
sPointsY = {}
sPointsZ = {}
sPointsC = {}

NUM_LAPS = 1

sSprite = {}
sSpriteX = {}
sSpriteSc = {} -- scale
SpriteCollideRect = {}

sTokensX = {}
sTokensExist = {}
TokenCollected=0
NumTokens = 0

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

LastY = 0 -- last y height when building a track

Position = 0 -- current position around the track

PlayerX = 0 -- -1 to 1 TODO: maybe don't make relative to road width
PlayerXd = 0
PlayerY = 0
PlayerYd = 0
PlayerVl = 0
PlayerVf = 0
PlayerDrift = 0
PlayerAir = 0
PlayerSeg = 0 -- current player segment
PlayerLap = 0
PlayerStandF = 0 -- final standing

RecoverStage = 0 -- 1. pause 2. lerp to track 3. flash
RecoverTimer = 0
InvincibleTime = 0

OpptPos = {}
OpptBoost = {}
OpptLap = {}
OpptSeg = {}
OpptX = {}
OpptV = {}

HznOffset = 0

HUD_HEIGHT = 16

sScreenShake = {0,0}
sScreenShakeR = {0,0}

-- 1. Menus 2. Racing
TitleState=1

-- 1. countdown 2. race 3. end standing 4. Summary UI
RaceState = -1
RaceStateTimer = 0
RaceCompleteTime = 0
RaceCompletePos = 0 -- player standing

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
    sp=LEVELDEF[Level][2]
    sd=SPDEF[sp][p]
    for i = 1, n do

        if p == 0 then
            add( sSprite, 0 )
            add( sSpriteX, 0 )
            add( sSpriteSc, 0 )
        else
            srand( #sSprite )
            added = false
            for j = 1, #sd do
                sdi=sd[j]
                if (#sSprite+sdi[3]) % sdi[2] == 0 then
                    -- SDEF, interval, interval offset, minx (*roadw), maxx (*roadw), rand l/r
                    
                    xrand = 1
                    if sdi[6] == 1 and rnd( 30000 ) > 15000 then
                        xrand = -1
                    end
                    spindex=sdi[1]
                    add( sSprite, spindex )
                    add( sSpriteX, ( sdi[4] + rnd( sdi[5] - sdi[4] ) ) * xrand )
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
        sTokensX[seg+i*3-3] = x
        sTokensExist[seg+i*3-3]=1
    end
    NumTokens += n
end

function InitOps()
    for i=1,8 do
        OpptPos[i] = SEG_LEN+SEG_LEN *  i
        OpptX[i]=((i%2)*2-1)*0.2
        OpptV[i]=0
        OpptLap[i]=1
    end
end

function InitRace()

    TitleState=2
    NumTokens=0
    TokenCollected=0

    -- 3.4 rep bug
    EraseTrack()
    BuildCustomTrack( Theme, 1, 1, 3.1 ) 
    InitOps()
    RaceStateTimer = time()
    RaceState = 1
    
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
    PlayerLap = 1

    RecoverStage = 0 -- 1. pause 2. lerp to track 3. flash
    RecoverTimer = 0
    InvincibleTime = 0
    UpdatePlayer()
end

function _init()


    LoadProfile()
    InitSpriteDef()

    -- draw black pixels
    palt(0, false)
    -- don't draw tan pixels
    palt(15, true)

    InitParticles()

    OpenMenu(2)

    --InitRace()

end

function RaceStateTime()
    return time()-RaceStateTimer
end

function UpdateRaceInput()

    if RaceState == 2 and PlayerAir == 0 then

        if btn(5) then -- btn2
            if abs( PlayerXd ) > 0.1 then
                PlayerDrift=sgn(PlayerXd)
            else
                PlayerVl=PlayerVl-0.08
            end
        end

        if btn(4) then -- z / btn1
            PlayerVl=PlayerVl+0.09
        end

        if btn(0) then -- left
            PlayerXd-= (0.022 + -PlayerDrift*0.01) * (1-PlayerVl*0.0005)*min(PlayerVl*0.125,1)
        elseif btn(1) then -- right
            PlayerXd+= (0.022 + PlayerDrift*0.01) * (1-PlayerVl*0.0005)*min(PlayerVl*0.125,1)
        end
    end

end

function UpdatePlayer()

    if InvincibleTime-time() < 0 then
        InvincibleTime = 0
    end

    if PlayerAir == 0 then
        if RecoverStage == 0 then
            UpdateRaceInput()
        end
        drftslw=(1-abs(PlayerDrift)*0.001)
        if abs( PlayerX*ROAD_WIDTH ) > ROAD_WIDTH then
            PlayerVl=PlayerVl*0.989*drftslw
            PlayerXd=PlayerXd*0.96
        else
            PlayerVl=PlayerVl*0.995*drftslw
            PlayerXd=PlayerXd*0.95
        end
    end
    if PlayerVl < 0.02 then
        --PlayerVl = 0
    end

    PlayerVf = PlayerVl*0.35
    Position=Position+PlayerVf
    if Position > SEG_LEN*NumSegs then
        Position -= SEG_LEN*NumSegs
        PlayerLap += 1
    end

    PlayerSeg=DepthToSegIndex(Position)

    nxtseg=(PlayerSeg)%NumSegs + 1
    posinseg=1-(PlayerSeg*SEG_LEN-Position)/SEG_LEN

    if RaceState == 3 then
        PlayerX=lerp(PlayerX,sPointsX[PlayerSeg],0.05)
    end
    if abs( PlayerXd ) < 0.005 then
        PlayerXd = 0
    end
    PlayerX+=sPointsC[PlayerSeg]*0.45*PlayerVl*0.01
    PlayerX+=PlayerXd*0.15

    if abs( PlayerXd ) < 0.08 then
        PlayerDrift=0
    end

    HznOffset = HznOffset + sPointsC[PlayerSeg] * 0.14 * (PlayerVf)

     -- jumps / player y

    ground = lerp( sPointsY[PlayerSeg], sPointsY[nxtseg], posinseg)
    PlayerY=max(PlayerY+PlayerYd, ground)
    if( PlayerY == ground ) then
        if PlayerYd < -2 and PlayerAir > 4 then
            sScreenShake = {2,7}
            sfx( 7, 2 )
            AddParticle( 6, 52, 122 )
            AddParticle( 7, 78, 126 )
            AddParticle( 1, 52, 122 )
            AddParticle( 2, 78, 122 )
        end
        nposinseg=1-(PlayerSeg*SEG_LEN-(Position+PlayerVf ))/SEG_LEN
        nground = lerp( sPointsY[PlayerSeg], sPointsY[nxtseg], nposinseg )
        PlayerYd = ( nground - ground ) - 0.2
        
        PlayerAir = 0
    else
        PlayerYd=PlayerYd-0.25
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
            if Frame%(dirtfq*8) == 0 then
                sScreenShake[1] = 2 * PlayerVf * 0.1
                sScreenShake[2] = 1 * PlayerVf * 0.1
            end
        else
            if Frame%8 == 0 and PlayerAir == 0 then
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
            PlayerVl=8
            if time() - RecoverTimer >= t3 then
                RecoverStage = 0
            end
        end
    end

end

function UpdateOpts()
    
    for i=1,#OpptPos do

        OpptPos[i]=OpptPos[i]+OpptV[i]
        if OpptPos[i] > SEG_LEN*NumSegs then
            OpptPos[i] -= SEG_LEN*NumSegs
            OpptLap[i] += 1
        end
        OpptSeg[i]=DepthToSegIndex(OpptPos[i])
        plsegoff1=(OpptSeg[i]-PlayerSeg)%NumSegs+1

        if RaceState > 1 then
            opv=(NUM_LAPS-OpptLap[i])*0.017
            opspd=(0.04+PlayerVl*0.022+i*0.008+opv)
            if RaceState >= 3 then
                opspd=0.08
            end
            OpptV[i]=OpptV[i]+opspd
            OpptV[i]=OpptV[i]*0.92
                        
            if plsegoff1 < 20 and abs( PlayerX - OpptX[i] ) > 0.05 and RecoverStage == 0 then
                OpptX[i] = min( max( OpptX[i] + 0.001 * sgn( PlayerX - OpptX[i] ), -0.8 ), 0.8 )
            end
        end
    end
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

    if InvincibleTime > 0 or RecoverStage > 0 or RaceState >= 3 then
        return
    end

    nxtseg=(PlayerSeg)%NumSegs + 1

    -- opponents

    carlen=2+PlayerVl*0.1

    ground = lerp( sPointsY[PlayerSeg], sPointsY[nxtseg], posinseg)
    for i=1,#OpptPos do

        opposl = LoopedTrackPos( OpptPos[i] )

        if ( Position + PlayerVf ) > ( opposl - carlen + OpptV[i] ) and
           ( Position + PlayerVf ) < ( opposl + OpptV[i] ) and
            ROAD_WIDTH * abs( PlayerX - OpptX[i] ) < 12 and
            ( PlayerY-ground ) < 2 then
        
            sfx( 7, 2 )

            PlayerVl = OpptV[i]
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
            TokenCollected+=1
            if TokenCollected == NumTokens then
                sfx( 10, 3 )
            else
                sfx( 9, 3 )
            end
        end
    end

    -- sprites
    
    if sSprite[nxtseg] > 0 and ( Position + carlen + PlayerVf ) > PlayerSeg*SEG_LEN then

        sdef1=SDEF[sSprite[nxtseg]]

        if sdef1[8]==1 then
            
            -- work out the range of pixels in the source sprite that we overlap
            -- player is ~40-80px
            insprx1=(48-SpriteCollideRect[1])/SpriteCollideRect[3];
            insprx2=(80-SpriteCollideRect[1])/SpriteCollideRect[3];

            it1=flr(max(sdef1[3]*insprx1,0))
            it2=flr(min(sdef1[3]*insprx2,sdef1[3]))

            collided=0
            if sdef1[7]==0 then
                for colit=flr(it1), flr(it2)-1 do
                    if sget(sdef1[1]+colit,sdef1[2]+sdef1[4]-1)!=15 then
                        collided=1
                        break
                    end
                end
            else
                --flipped
                for colit=sdef1[3]-flr(it2), (sdef1[3]-flr(it1))-1 do
                    if sget(sdef1[1]+colit,sdef1[2]+sdef1[4]-1)!=15 then
                        collided=1
                        break
                    end
                end
            end

            if collided == 1 then

                if PlayerVf < 4 then
                    -- small hit
                    sfx( 7, 2 )
                    sScreenShake[1] = 3
                    sScreenShake[2] = 1
                    PlayerVl = PlayerVl * 0.2
                    PlayerXd = -sgn(PlayerX) * 0.2
                    InvincibleTime=time()+1
                    AddParticle( 4, 64 + rnd(32)-16, 96 + rnd( 8 ) )
                    AddParticle( 5, 64 + rnd(32)-16, 96 + rnd( 8 ) )
                else
                    -- big hit
                    sfx( 6, 2 )
                    sScreenShake[1] = 8
                    sScreenShake[2] = 3

                    PlayerXd = sgn(PlayerX) * 0.2
                    PlayerVl = PlayerVl * 0.2
                    RecoverStage = 1
                    RecoverTimer = time()
                    AddCollisionParticles()
                end
            end
        end
    end
end

function UpdateRaceState()
    if RaceState==1 and RaceStateTime() > 3 then
        RaceState=2
        RaceStateTimer=time()
    elseif RaceState==2 and PlayerLap == NUM_LAPS+1 then
        RaceState=3
        RaceCompleteTime=RaceStateTime()
        RaceCompletePos=GetPlayerStanding()
        RaceStateTimer=time()
    end
end

function UpdateRace()
    if RaceState < 4 then
        -- screenshake
        sScreenShake[1]=lerp(sScreenShake[1],0, 0.1)
        sScreenShake[2]=lerp(sScreenShake[1],0, 0.1)
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
    else
        if btnp(4) then -- btn1
            OpenMenu(2)
        elseif btnp(5) then --btn2
            InitRace()
        end
    end
end

function _update60()

    DebugUpdate()
    Frame=Frame+1
    if TitleState == 1 then
        UpdateMenus()
    elseif TitleState == 2 then
        --if RaceState > 0 then
        UpdateRaceSound()
        UpdateRace()
    end

end

function HrzSprite( x, ssx, ssy, f )
    hsprdef=HORZSDEF[THEMEDEF[Theme][11]]
    ssy=ssy*hsprdef[6]
    sspr( hsprdef[1],hsprdef[2],hsprdef[3],hsprdef[4], 
        (HznOffset + x) % 256 - 128, 64 - flr( ssy * 16 ), ssx*hsprdef[5] * 48, ssy * 16, f )
end

function RenderHorizon()

    fillp(0)
    --rectfill( 0, 74, 138, 128, 3 ) -- block out
    --BayerRectV( 0, 64, 138, 74, THEMEDEF[Theme][4], THEMEDEF[Theme][9] )
    rectfill( 0, 64, 128, 128, THEMEDEF[Theme][4] ) -- block out the ground
    HrzSprite(10, 1.0, 0.7, true)
    HrzSprite(64, 0.3, 1.2, false)
    HrzSprite(60, 2.3, 0.3, false)
    HrzSprite(128, 1, 1, false)
    HrzSprite(178, 1.5, 0.5, true)

end

function RenderSky()
    fillp(0)
    rectfill( 0, 0, 128, 20, THEMEDEF[Theme][10] ) -- block out
    BayerRectV( 0, 20, 138, 50, THEMEDEF[Theme][9], THEMEDEF[Theme][10] )
    fillp(0)
    rectfill( 0, 50, 128, 64, THEMEDEF[Theme][9] ) -- block out
end

function RenderP4( xlt, xrt, xlb, xrb, yt, yb, c )
    
    if yt - yb < 1 then
    return
    elseif yt - yb < 2 then
        line( xlt, yt, xrt, yt, c)
    else
        yd=yt-yb
        rp=1/yd
        xldlt=(xlt-xlb)*rp
        xrdlt=(xrt-xrb)*rp
        for i=yb,yt do
            if i > 126 then return end
            line( xlb, i, xrb, i, c)
            xlb+=xldlt
            xrb+=xrdlt
        end
    end
end

function RenderSeg( x1, y1, w1, x2, y2, w2, idx )

    thm=THEMEDEF[Theme]

    -- Ground
    -- We only render intermittent strips, most of the ground has been
    -- blocked out in the road render before this
    if idx % 8 <= 3 then
        fillp(0x5A5A)
        RenderP4( -1, x1-w1, -1, x2-w2, y1, y2, thm[5] )
        RenderP4( x1+w1, 128, x2+w2, 128, y1, y2,thm[5] )
    end

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
    RenderP4( x1-edgew1, x1-w1,x2-edgew2, x2-w2, y1, y2, col )
    RenderP4( x1+w1, x1+edgew1, x2+w2, x2+edgew2, y1, y2, col )
  
    -- Road
    fillp(0)
    if thm[3] == 1 then
        -- stripes
        if idx == 1 then
            col = 1
        else
            if idx % 3 == 0 then
                fillp(0x5A5A)
                col = thm[2]
            else
                col = thm[1]
            end
        end
        RenderP4( x1-edgew1, x1+edgew1, x2-edgew2, x2+edgew2, y1, y2, col )
    elseif thm[3] == 2 then
        -- patches
        fillp(0x5A5A)
        -- TODO: dont overdraw
        RenderP4( x1-edgew1, x1+edgew1, x2-edgew2, x2+edgew2, y1, y2, thm[2] )
        fillp(0)
        if idx == 1 then
            col = 1
        else
            col = thm[1]
        end
        srand( idx )
        rx1=rnd( 0.6 ) + 0.3
        rx2=rnd( 0.6 ) + 0.3
        RenderP4( x1-edgew1*rx1, x1+edgew1*rx2, x2-edgew2*rx1, x2+edgew2*rx2, y1, y2, col )
    end

     -- Lanes
     if thm[8] == 1 then
        -- edge lane
        if idx % 2 > 0 then
            fillp(0)
            RenderP4( x1-w1*0.74, x1-w1*0.78, x2-w2*0.74, x2-w2*0.78, y1, y2, 6 )
            RenderP4( x1+w1*0.78, x1+w1*0.74, x2+w2*0.78, x2+w2*0.74, y1, y2, 6 )
        end
    elseif thm[8] == 2 then
        -- centre alternating
        if idx % 4 > 2 then
            fillp(0)
            lanew=0.02
            RenderP4(x1-w1*lanew,x1+w1*lanew,x2-w2*lanew,x2+w2*lanew,y1,y2,6 )
        end
    elseif thm[8] == 3 then
       -- 3 lane yellow
        if idx % 4 == 0 then
            fillp(0)
            RenderP4( x1-w1*0.3, x1-w1*0.34, x2-w2*0.3, x2-w2*0.34, y1, y2, 9 )
            RenderP4( x1+w1*0.34, x1+w1*0.3, x2+w2*0.34, x2+w2*0.3, y1, y2, 9 )
        end
    end
    
end -- RenderSeg

function _draw()
	
    --cls()
    if TitleState == 1 then
        RenderMenus()
    elseif TitleState == 2 then
        if RaceState < 4 then
            camera( 0 + (rnd(sScreenShake[1]*2)-sScreenShake[1]), HUD_HEIGHT + (rnd(sScreenShake[2]*2)-sScreenShake[2]) )
            RenderSky()
            RenderHorizon()
            ProfileStart(1)
            RenderRoad()
            ProfileEnd(1)
            camera( 0, 0 )
            RenderRaceUI()
            
            if stat(1) < 0.65 then
                --DRAW_DIST+=1
            elseif stat(1) > 0.8 then
                --DRAW_DIST-=5
            end
        else
            RenderSummaryUI()
        end
    end
    DebugPrint( Position )
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
    stnd={ "st", "nd", "rd" }
    if n < 4 then
        return stnd[n]
    end
    return "th"
end

function RenderCountdown()

    if RaceState == 2 and RaceStateTime() < 1 then
        frac=( time() - RaceStateTimer )%1
        x=64-NFDEF[11][3]*0.5-8
        PrintBigDigitOutline( 10,x,30, 0 )
        PrintBigDigit( 10,x,30,0 )
        x=x+16
        PrintBigDigitOutline( 0,x,30, 0 )
        PrintBigDigit( 0,x,30,0 )
    elseif RaceState == 1 then
        num= 3-flr( RaceStateTime() )
        frac=( RaceStateTime() )%1
        if num <= 0 then
            return
        elseif frac < 0.9 then
            x=64-NFDEF[num+1][3]*0.5
            PrintBigDigitOutline( num,x,30, 0 )
            PrintBigDigit( num,x,30,0 )
        end
    end
end

function RenderRaceEndStanding()
    if RaceState != 3 then return end
    
    if RaceStateTime() < 1 then
        clip( 0, 0, (RaceStateTime()*8)*128, 128 )
    elseif RaceStateTime() > 3 then
        clip( ((RaceStateTime()+3)*8)*128, 0, 128, 128 )
    end
    rectfill( 0, 25, 128, 49, 1 )
    tw=PrintBigDigit( RaceCompletePos, 0, 0, 1 )
    PrintBigDigit( RaceCompletePos, 64-(tw*0.5+4), 32, 0 )
    print( GetStandingSuffix(RaceCompletePos), 64+tw*0.5-3, 32, 7 )

    sspr( 121, 32, 7, 19, 64-(tw+8+7), 27, 7, 19, true )
    sspr( 121, 32, 7, 19, 64+(tw+8), 27, 7, 19 )

    clip()

    if RaceStateTime() > 3.6 then
        fade=max( (0.5-(time()-(RaceStateTimer+3.6)))/0.5, 0 )
        BayerRectT( 0, 0, 128, 128, 0xE0, fade )    
        if RaceStateTime() > 4.2 then
            RaceState = 4
        end
    end
end

function RenderSummaryUI()

    rectfill( 0, 0, 128, 128, 0 )

    fillp(0x33CC)
    col = bor( 6 << 4, 0 );
    rectfill(0,12,33,21, col)
    rectfill(94,12,128,21, col)
    print( "race complete", 38, 15, 7 )
    fillp()

    -- position
    rectfill(0,44,64,56, 1)
    print( "position", 19, 48, 6 )
    sspr( 103, 40, 8, 9, 54, 46 ) -- trophy

    -- tokens
    rectfill(0,61,64,73, 2)
    print( "tokens", 27, 65, 6 )
    sspr( 23, 40, 7, 7, 55, 64 ) -- token

    -- time
    rectfill(0,78,64,90, 3)
    print( "time", 35, 82, 6 )
    sspr( 112, 41, 7, 7, 55, 81 ) -- clock
    
    -- position text
    col=7
    if RaceCompletePos == 1 then
        col = 9
    end
    print( tostr( RaceCompletePos ).. tostr( GetStandingSuffix(RaceCompletePos) ), 69, 48, col )

    -- tokens text
    col=7
    if TokenCollected == NumTokens then
        col = 9
    end
    print( tostr( TokenCollected ).."/".. tostr( NumTokens ), 69, 65, col )

    -- time text
    PrintTime( RaceCompleteTime, 69, 82 )

    -- controls
    print( " \142  menu", 50, 103, 6 )
    print( " \151  retry", 50, 109, 6 )

end

function RenderRaceUI()

    fillp(0)
    rectfill( 0,111, 127, 127, 0 )
    rect( 0, 111, 127, 127, 6 )
    rect( 1, 112, 126, 126, 13 )

    stand=GetPlayerStanding()
    strlen=PrintBigDigit( GetPlayerStanding(), 3, 114, 0 )
    print( GetStandingSuffix(stand), strlen+1, 114, 7 )

    sspr( 0, 110, 9, 5, 37, 114 )
    print( min(PlayerLap, NUM_LAPS), 49, 114, 6 )
    print( "/"..tostr(NUM_LAPS), 57, 114, 5 )

    sspr( 0, 104, 7, 5, 38, 120 )
    print( TokenCollected, 49, 120, 6 )
    print( "/" ..tostr(NumTokens), 57, 120, 5 )    

    for i=80, 124, 2 do
        y1 = flr(lerp( 121, 115, (i-107)/(113-107) ))
        y1=max(min(y1,121),115)
        -- top speed is ~17.5 m/s
        norm=(i-80)/(128-80)
        
        col = 5
        if norm < PlayerVl/19 then
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
    --print( flr( PlayerVl * 8.5 ), x1, 114, 6 )
    print(stat(1),88,114,6)
    --print(DRAW_DIST,88,114,6)
    --print( "mph", 94, 114, 6 )
    RenderCountdown()
    RenderRaceEndStanding()

end

function RenderPlayer()

    if RecoverStage == 2 or ( InvincibleTime-time() > 0 and time()%0.4>0.2 ) then
        return
    end

    if PlayerDrift != 0 then
        woby=0
        if PlayerAir == 0 then
        srand(time())
        woby=rnd(1.2)
        end
        spr( 9, 44, 100-woby, 6, 3, PlayerDrift > 0 )
    elseif PlayerXd > 0.06 or PlayerXd < -0.06 then
        spr( 4, 44, 100, 5, 3, PlayerXd > 0 )
    else
        spr( 0, 48, 100, 4, 3 )
    end

end

function GetSpriteSSRect( s, x1, y1, w1, sc )
    ssc=w1*sc
    aspx = ssc
    aspy = ssc
    if SDEF[s][3] > SDEF[s][4] then
        aspx = ssc*SDEF[s][3]/SDEF[s][4]
    else
        aspy = ssc*SDEF[s][4]/SDEF[s][3]
    end
    
    rrect= { x1 - aspx * 0.5,
            y1 - aspy,
            aspx,
            aspy }
    return rrect
end

function RenderSpriteWorld( s, rrect, d )
    sspr( SDEF[s][1], SDEF[s][2], SDEF[s][3], SDEF[s][4], rrect[1], rrect[2], ceil(rrect[3] + 1), ceil(rrect[4] + 1), SDEF[s][7] == 1 )
    --BayerRectT( rrect[1], rrect[2], rrect[1] + rrect[3], rrect[2] + rrect[4], 13, d )
end

function RenderSpriteRepeat( s, rrect, d, dx, dy, n )
    
    for i=1,n do
        RenderSpriteWorld( s, rrect, d )
        rrect[1]=rrect[1]+rrect[3]*dx
        rrect[2]=rrect[2]+rrect[4]*dy
    end

end

oopon=0

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
   
   ProfileStart(2)
    -- calculate projections
    hrzny=128
    hrzseg=DRAW_DIST
    for i = 1, DRAW_DIST do

        -- fun foreshortening hack (add to i in statement below)
        -- oop=flr(max(i/DRAW_DIST-0.4,0)*50)
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

        pscreenscale[i] = CAM_DEPTH/pcamz[i];
        psx[i] = (64 + (pscreenscale[i] * pcamx[i]  * 64));
        psy[i] = flr(64 - (pscreenscale[i] * pcamy[i]  * 64));
        psw[i] = (pscreenscale[i] * ROAD_WIDTH * 64);

        -- store the min y to block out the ground
        if psy[i] < hrzny then
            hrzny=psy[i]+1
            hrzseg=i
        end

    end
    ProfileEnd(2)
    
    for i = DRAW_DIST - 1, 1, -1 do

        segidx = (PlayerSeg - 2 + i ) % NumSegs + 1
        
         if i+1== hrzseg then
            fillp(0)
            rectfill( 0, hrzny, 128, 128, THEMEDEF[Theme][4] ) -- block out the ground
        end
        
        ProfileStart(3)
        -- segments
        j=i+1
        if psy[i] > psy[j] and ( psy[i] >= hrzny ) then
            RenderSeg( psx[i], psy[i], psw[i], psx[j], psy[j], psw[j], segidx )
        end
        ProfileEnd(3)
        ProfileStart(4)
        if i==1 and TitleState == 2 then
            RenderPlayer()
            RenderParticles()
        end
        ProfileEnd(4)

        -- sprites
        
        if sSprite[segidx] != 0 then
            psx1 = flr(64 + (pscreenscale[i] * ( pcamx[i] + sSpriteX[segidx] * ROAD_WIDTH ) * 64));
            d = min( ( 1 - pcamz[i] / (DRAW_DIST*SEG_LEN) ) * 8 , 1 )
            sindx=sSprite[segidx]
            rrect = GetSpriteSSRect( sindx, psx1, psy[i],psw[i], sSpriteSc[segidx] )
            if sindx == 22 then
                -- special case for buildings
                srand(segidx)
                nrep=flr(rnd( 3 ))+1
                RenderSpriteRepeat( sindx, rrect, d, 0, -1, nrep )
            else
                RenderSpriteWorld( sindx, rrect, d )
            end
            if i == 2 then
                SpriteCollideRect = rrect
            end
        end

        -- Start gantry
        if segidx == 1 or segidx == 2 then
            psx1l = flr(64 + (pscreenscale[i] * ( pcamx[i] + ROAD_WIDTH * -1.2 ) * 64));
            psx1r = flr(64 + (pscreenscale[i] * ( pcamx[i] + ROAD_WIDTH * 1.2 ) * 64));
            d = min( ( 1 - pcamz[i] / (DRAW_DIST*SEG_LEN) ) * 8 , 1 )
            rrect = GetSpriteSSRect( 11, psx1l, psy[i],psw[i], 0.1 )
            RenderSpriteRepeat( 11, rrect, d, 0, -1, 10 )
            rrect = GetSpriteSSRect( 11, psx1r, psy[i],psw[i], 0.1 )
            RenderSpriteRepeat( 11, rrect, d, 0, -1, 10 )
            if segidx == 1 then
                psx1l = flr(64 + (pscreenscale[i] * ( pcamx[i] + ROAD_WIDTH * -0.55 ) * 64));
                psx1r = flr(64 + (pscreenscale[i] * ( pcamx[i] + ROAD_WIDTH * 0.55 ) * 64));
                rrect = GetSpriteSSRect( 12, psx1l, psy[i],psw[i], 1 )
                RenderSpriteWorld( 12, rrect, d )
                
                rrect = GetSpriteSSRect( 13, psx1r, psy[i],psw[i], 1 )
                RenderSpriteWorld( 13, rrect, d )
            end
        end

        -- tokens
        if sTokensX[segidx] !=0 and sTokensExist[segidx] != 0 then
            psx1 = flr(64 + (pscreenscale[i] * ( pcamx[i] + sTokensX[segidx] * ROAD_WIDTH ) * 64));
            d = min( ( 1 - pcamz[i] / (DRAW_DIST*SEG_LEN) ) * 8 , 1 )
            rrect = GetSpriteSSRect( 10, psx1, psy[i],psw[i], 0.2 )
            RenderSpriteWorld( 10, rrect, d )
        end

        -- opponents
        ProfileStart(5)
        for o = 1,#OpptPos do
            if OpptSeg[o] == segidx then
                
                opsx=0
                opsy=0
                opsw=0
                if i>15 then
                -- Imposters, just render them at the seg pos (and in the middle of the road)
                opsx=psx[i]
                opsy=psy[i]
                opsw=psw[i]
                else
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
                end

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
        ProfileEnd(5)

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
fffffffffffffff7ddffffffffffffffffffffffffffffffa000a9a9ffbb3bffffff666ffe7ffffffffffff65ff0ffffffffffffffffffffffffffffffffffff
fffffffffffffff75dffffffffffffffffffffffffffffff9a000a99fb3bbbbbbff66666feeff0ffffffffff56f0ffff0ffffffffff11661166116611f555555
fffffffffffffff75dffffffffffffffffffffffffffffffa9a000a9bbbb3bb35bfdff66ffefff0fff00fff65fff0ff0fffffff555500770077007700f55ff65
fffffffffffffff75dffffffffff55fffdffffffffffffff999900095333333353fdddddffefff0ff0ffffff56fff0f0fffffff555577007700770077f5f5f65
ffffffffffffff6d5dfffffffff5551ff5ffffffffffffffa9a00099553333353bff555f7ff00f0ff0ffff3f5ff0f000fffffff555577007700770077f5ff565
ffffffffffffff6555ffdffffff5111ff56fffffffffffff9a000999f555335533fffffffaff0f0ff0fffff353ff000ffffffff555500770077007700f566655
ffffffffffff51d551115ffffff5151ff55fffffffffffffa0009999ff4f4f33ffffffe7ffaf000f0ffff3fffffff00ffffffffffff11661166116611f555555
ffffffffdfffd16555111ffffff51116d51fffffffffffff55551151fff42f4fffffeeeffffff000ffffff3f3f3fffffffffffffffffffffffffffffffffffff
ffffffffddf6d16155111dd6d6551116651fffffffffffffffffffffffff222fffffeefffafff0f0ffffffd33dfffffffffffffffffffffffffffffffff7ffff
ffffffddd5f5d1d5551116d6d65515166516ffffffffffffff9aaaffffff22ffffffffff9affff00fffff3d5533ffffffffffffffffffffffffffffffff7ffff
ffff5fddd5d1d1d5111116ddd61115166515fffffffffffff994a9afffff22ffffffa7ff899fff00ffffff3555ffffffffffffffffffffffffffffffff7fffff
fff656d5d55151d55511161ddd15111d651166df6dffffff9949994ffff9ffffffaaffff98ffff00ffff66600ff255ffffffffffffffffffffffffffffffffff
ff5d5dd5d15151d51511161d1d11151111111ddd66ffffff49999999f9ff9fffffffffffffffff2221ff06660ff544fffffffffffffffffffffffffffffff7ff
ff56dd11d155d1d11511161d1d1111111111dddddd151fff99599499ff4f4ff9fffffffffffff2dd6d1f00666ff549fffffffffffffffffffffffffffff777ff
dd565d15d11dd1d11511161d1d5511111111115ddd66d5d655559595ff4f5f4fffffffffffff2dddd62f06660ff5245ffffffffffffffffffffffffffff77fff
5d5d5666666dd5d11115155515515115111151ddddd66dd6f554555fff5f5f5fffffffffffff11d44d4266600ff1499fffffffffffffffffffffffffffffffff
000000000000d0ddffffffffaa777ff888fff9ffff6ff887888878888eeeeeee5ffee2efffffffffffffff5ffff5445fffffffff9999a9ffffffffffffffff77
066666666611111df4449ff9aa5aa788788f979ff666f888788887888eeeeeee5fe2eeeeeeffffffffffff6ffff51154fffffff9f999af9fff666fffffff7777
1611d11ddd118110444449f9a585a7886889777966666888878888788e77777e5ee7e27eeeefffffffffff6fff1d49999ffffff9f999af9ff67576ffffff77ff
0611d16d6d1a7e1d444f4f99597e5788788f979ff666f888788887888e7eee7e5e222722ee2fffffffffff6ff1204d4449ffffff9999a9ff6775776fffffffff
1616d11ddd11c11054444449a5c5aaf888fff9ffff6ff887888878888d77777e52e2222272effffffffffd7d373fff990ffffffff999afff6775776fffffff77
1666666666111110f55f44f9aa5aaaff5ffff5ffff5fffff55ff55fffd7eee7e5f2ee22ee22ffffffffff3733373ff909fffffffff9affff6777576fffff7777
1110100100000000ff555fff99999fff6ffff6ffff6fffff66ff66fffd77777e5ff4f5f22fff28fffffffd7333373f099fffffffff55fffff67776fffff7777f
fff11ff11ff11fffffffffffffffffff6ffff6ffff6fffff66ff66fffd7dde7e5fff4445fff2558ffffff36d3d63ff990fffffffff44ffffff666fffffffffff
fffd5ffddff5dfffffffffffffffffff6ffff6ffff6ffffffffffffffdddddee5ffff44fffff67fffffffd63d6dfff909ffffffff4444fffffffffffff77ffff
fffd5ffddff5dfffffffffffffffffff6ffff6ffff6ffffffffffffffddd7dde5ffff49fffff76ffffffff5ff5ffff099fffffffff21fffffffffffff77777ff
fff41ff11ff14fffffffffffffffffff6ffff6ffff6ffffffffffffffc77777d5ffff44fffff22ffffffff6ff6ffff999ffff446664266666666ffffff77777f
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffccd7ddd5fff449fffff22ffffffff6ff6fffff5ffff41446642666666666fffffffffff
fffffffffffffff25222fffffffffffffffffffffffffffffffffffffcc7d7dd5ff44494fff2288ffffffffffffffff6fff4144446666666666666ffffffffff
ffffffffffff2255452222fffffffffffffffffffffffffffffffffffc7c7d7d55dd55555555555555555ffff5fffff6ff414444446666666666666fffffffff
ffffffffffff55444522222ffffffffffffffffffffffffffffffffffcc777dd55555ddddddddddddddddfff33fffff6f41444444442222222222222ffffffff
ffffffffff22445442222522fffffffffffffffffffffffffffffffffccc7ccd555d5d65d65dd65d65dffffff536fff6fff2222222111111111114ffffffffff
fffffffff22554445522222222fffffffffffffffffffffffffffffffccccccc555d5d65d65dd65d65dffff3334ffffffff2222222122222222224ffffffffff
ffffff222554454522222522222ffffffffffffffffffffffffffffffccccccc55555ddddddddddddddddfff3563fffffff4444444124442444224ffffffffff
fffff225544454552252522222222ff2222222ffffffffffffffffffffffffff55dd5ddddddddddddddddff3533ffffffff2222222129992444224ffffffffff
fff25554455555544522222222222222255552222fffffffffffffffffffffff5fffffffffffffffffffffff45fffffffff4444444129992445224ffffffffff
ff2545555555544445222222222222222252222222ffffffffffffffffffffff5ffffffffffffffffffffff33663fffffff2222222121112444224ffffffffff
f25555255225455452222222222222222222222222222fffffffffffffffffff5fffffffffffffffffffff35533ffffffff4444444122222444224ffffffffff
222222522255554522222222222222222222222222222222ffffffffffffffff5fffffffffffffffffffffff45ffffffffffffffffffffffffffff7181711111
ffffffffffffffffffffffff6fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff8888811611
ffffff7dfffffff7dd6dd66c66dfffffffffffffffffffffffffffffffffffffff000eeeeeeeeeefffffffffffffffffffffffffffffffffffffff7181711116
ffffff67ddddddd6dd76dd6c666dddffffffffffffffffffffffffff00000eeeeeeeeeeeeeeeeeee000fffffffffffffffffffffffffffffffffff1111116111
ffffff6ddddddddddddcddd7676ddd67dffffffffffffffffff00000000eee5111eeeee000011115555d1fffffffffffffffffffffffffffffffff1161111161
fffff76ddddddddddddc66dd6d6c66cc65dddfffffffffffff00000000eee5dddd1e1115555555555dddd1ffffffffffffffffffffffffffffffff1676111611
fffff7556dddddddddc6c7d77d5d6666cdddddfffffffffff0000000eeee5ed1ddd111d555ddddddddddddd1ffffffffffffffffffffffffffffff1161111111
ffffc766666d6ddddd76c667cddd7d666dd5d5dffffffffffe8eeeeeeee5edddddd111ddddddddddddddddddd1ffffffffffffffffffffffffffff6161688888
ff777cdddd6dd6ddddc777757c656dd66c6dd55ffffffffff8e8e8eeee05dd5ddddd11ddddddddddddddddddddd1ffffffffffffffffffffffffff1616177777
fd76dddd666ddddddd67c77677d666dd6cc66d55dffffffffe8e8e8e8e5ed555ddddd11ddddddddddddddddddddd11ffffffffffffffffffffffff6161688888
7777cdddddddd677c6c77c7777cdd666666d6dd1dddffffff8e8e010e8e8111555ddd11dddddddddddddddddddd55511ffffffffffffffffffffff1616177777
c6c776dc6dddddd7cc76dd777666d5d666ccc66ddddddffffe1e05010e8e8e8111d5dd11dddddddd5555555111eeeeeeeeffffffffffffffffffff8888888888
fffffffffffffffffffffffffffffffffffffffffffffffff120101010e8e1e8e8111d11ddddd555111eeee44444eeeeeeeeffffffffffffffffff7777777777
fffffffffffffffffffffffffffffffffffffffffffffffff2100101108e851e8e8e11115111eeee44444eeeeeeeeeeeeeeeeeffffffffffffffff8888888888
fffffffffffffffffffffffffffffffffffffffffffffffff150106d5001e8e8e8e8e8eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffffffffffffff1111111111
fffffffffffffffffffffffffffffffffffffffffffffffff01005561102121e8e8e8e8e8eeeeeeeeeeeeeeeeeeeeeeeeeeee2eeeeffffffffffff1111111191
fffffffffffffffffffffffffffffffffffffffffffffffff05011d55001212128e8e8e8e8eeeeeeeeeeeeeeeeeeeeeee22eeee22eeeffffffffff1911111999
ffffffffffffffffffffffffffffffffffffffffffffffffff00050111021212121e8e8e800eeeeeeeeeeeeeeeeeeeeeeee22e222eeeeeffffffff1191111191
ffffffffffffffffffffffffffffffffffffffffffffffffffff00d050012121212121e8001010eeee22eee22eeeeeeeeeeeeeeeeee1515fffffff1111191111
ffffffffffffffffffffffffffffffffffffffffffffffffffffff5d00051212121212120111008eeee22eeee22eeeeeeeeee515151515ffffffff1191911111
ffffffffffffffffffffffffffffffffffffffffffffffffffffffff100051512121212111105008eeeee222eeeeeeee51515154967151ffffffff1111111111
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00015151212120501050e8e8eeeeeee1515151515151960008effffffff7777777777
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00051512121111d1111e8e8e15151515151515100000008efffffffff7777888777
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000051512050605028e8e1517674515100000008e8e8e8fffffffff7778888877
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00001511115111128e851567000000008e8e8e821212fffffffff7778888877
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0005055d05021e8e100000008e8e8e8212121200ffffffffff7778888877
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000d0d11021e8e008e8e8e821212120000000ffffffffff7777888777
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff011d5500128e8e8e821212120000000fffffffffffffff7777777777
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff5d00021e8212121210000000fffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff10002121210000000ffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000fffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000ffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffff0000000000000000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffff0999999999999999905566556655665566556655665566f56fff6fffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffff091199199119911990556655665566f566f5f6f5f6f5f6ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
aaa5aaafffff7777777777ffff091919191999199190665566556655665566556655665f6f5fff5fffffffffffffffffffffffffffffffffffffffffffffffff
aa585aaffff77777777777ff000911991919991991900000000000f566f5f600000006f5000000fff000000fff0000000fffffffffffffffffffffffffffffff
a597e5afff777777777777f09999199919911991199999990099990ff00ff0aaaaaaa0f0aaaaaa0f0aaaaaa0f0aaaaaaa0ffffffffffffffffffffffffffffff
aa5c5aafff777ffffffffff0999999999999999999999990ee09990f0ee0f0aaaaaaaa0aaaaaaaa0aaaaaaaa0aaaaaaaa0ffffffffffffffffffffffffffffff
aaa5aaafff777ff7777777ff000000000000000000000000ee0000000ee0ff000000aa0aa0000aa0aa0000aa0aa000000fffffffffffffffffffffffffffffff
ffffffffff777ff7777777ff0ee0ee0ee00eeeee0f0eeee0ee00eeee0ee0f0aaaaaaaa0aa0000aa0aa0fff000aaaaaa0ffffffffffffffffffffffffffffffff
feeeeeeeff777ff7777777ff0ee0ee0ee0eeeeeee0eeeee0ee0eeeee0ee0f0aaaaaaa00aa0aaaaa0aa0fff000aaaaaa0ffffffffffffffffffffffffffffffff
efffffffef777ffffff777ff0ee0ee0ee0ee000ee0ee0000ee0ee0000ee0f0aa000aa00aa0aaaaa0aa0000aa0aa000000fffffffffffffffffffffffffffffff
efffefffef777777777777ff0eeeeeeee0eeeeeee0ee0ff0ee0eeeeeeee0f0aa0ff0aa0aa0000aa0aaaaaaaa0aaaaaaaa0ffffffffffffffffffffffffffffff
feeffefefff77777777777fff0eeeeee0f0eeeee00ee0ff0ee00eeeeeee0f0aa0ff0aa0aa0ff0aa00aaaaaa0f0aaaaaaa0ffffffffffffffffffffffffffffff
ffffefffffff7777777777ffff000000fff00000ff00ffff00ff0000000fff00ffff00f00ffff00ff000000fff0000000fffffffffffffffffffffffffffffff
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
020500190111001120011200112001110011200112001120011200112001110011200112001120011200111001120011200112001110011200111001120011200112000000000000000000000000000000000000
0401000f1272012710117201172011710117101172012710117001071010710127001271010710117102813028120281202812028120281202812028120281301a0401a050000000000000000000000000000000
4c0100201971019722197201871019722197201971219720197201872018712187201872018722197101971019710197221972019712197221972019712197101871019720197201971018720187101871018720
aa0100202712228122291302a1202a12028132271322712028121281312713029122291222a1222b1202b1202a1202b1202a1312a131291212a1212a121291202a1302a122291322812227122271222813228120
4c01000f137201372014730120301203012020147201372013720137201102012720127201372012030150501f050200502105022050220502305025050260502705027050280502905029050290502905029050
c60200090b0200a020084100a0200b1100a010074100a0200a0201000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4804000034660356503564034640336402f6401a6401764014630106200f6200d6200c6200b6200b6100a6100c6100e6100f6100e6100d6100b61009610076100661004610036100261002610016100161000610
00020000286302863027620246201762015610136101361013610126100e6100b6000861007610056100461003610016100060001600006000060000000000000000000000000000000000000000000000000000
140200001a5441a5441a5441a53016030160301604016030160431753517535175251751516700000000000000000000000000000000000000000000000000002e705000002e1052e005000002e1052e70500000
150400003435036050382403902000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01050000322302f240312403225034240332303622039040390503905000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

