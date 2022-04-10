pico-8 cartridge // http://www.pico-8.com
version 35
__lua__
-- pico world race 1.1
-- by pak-9

#include menus.lua
#include particle.lua
#include renderutils.lua
#include sound.lua
#include spritedef.lua
#include trackdef.lua
#include utility.lua
#include profile.lua

-- custom font
font="8,8,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,240,248,252,28,28,0,0,0,15,31,63,56,56,0,0,0,192,192,192,128,128,0,0,0,3,3,3,3,3,0,0,0,252,252,252,0,240,0,0,0,15,31,63,56,63,0,0,0,252,252,252,0,252,0,0,0,15,31,63,56,63,0,0,0,224,240,120,60,28,0,0,0,28,28,28,28,28,0,0,0,252,252,252,28,252,0,0,0,63,63,63,0,15,0,0,0,240,248,252,28,252,0,0,0,31,31,31,0,15,0,0,0,240,248,252,28,0,0,0,0,15,31,63,56,56,28,28,28,252,248,240,0,0,56,56,56,63,31,15,0,0,128,128,128,128,128,128,0,0,3,3,3,3,3,3,0,0,248,252,28,252,252,252,0,0,31,15,0,63,63,63,0,0,252,252,0,252,252,252,0,0,63,63,56,63,31,15,0,0,28,252,248,0,0,0,0,0,28,63,63,28,28,28,0,0,252,252,0,252,252,252,0,0,31,63,56,63,31,15,0,0,252,252,28,252,248,240,0,0,31,63,56,63,31,15,0,0,0,0,0,0,128,128,0,0,56,60,30,15,7,3,0,0,0,0,0,240,248,252,28,252,0,0,0,15,31,63,56,63,0,0,0,240,248,252,28,252,0,0,0,15,31,63,56,63,0,0,0,240,248,252,28,156,0,0,0,63,63,63,0,63,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,252,252,28,252,248,240,0,0,63,63,56,63,31,15,0,0,252,248,0,248,248,248,0,0,63,63,56,63,63,31,0,0,156,156,28,252,248,240,0,0,63,63,56,63,63,63,0,0,0,0,0,0,0,0,0,0,0"

CType = split"0,37,40"

Frame, SEG_LEN, DRAW_DIST, CANVAS_SIZE, CAM_HEIGHT = 0,10,100,128,21

ROAD_WIDTH = 60 -- half
CAM_DEPTH = 0.55; -- 1 / tan((100/2) * pi/180) (fov is 100)

-- horizon sprite def: 1. sx 2. sy 3. sw 4. sh 5. xscale 6. yscale
HORZSDEF = {
  split"32,  83, 48, 15,   1,   1", -- 1. City
  split"32,  98, 48, 10, 1.2, 0.8", -- 2. Mountain
  split"32, 109, 45,  9, 1.2, 0.8", -- 3. Glacier
  split"32, 119, 46,  9, 1.4, 0.7", -- 4. Hills
}

-- 1. Road c1 2. Road c2 3. Road pat 4. Ground c1 5. Ground c2(x2) 6. Edge c1 7. Edge c2(x2) 8. Lane pat 9. Sky c1 10. Sky c2 11. horizon spr
-- Road patterns: 1. alternating stripes 2. random patches
-- Lane patterns: 1. edges 2. centre alternating 3. 3 lane yellow
THEMEDEF = {
--  r1 r2   rp g1  g2   e1  e2   lp sk1 sk2 hz
split"5, 0x5D, 1, 3, 0x3B, 6, 0x42, 1, 6, 12, 1 ", -- 1. USA
split"5, 0x05, 1, 6, 0x6D, 6, 0x15, 3, 6, 12, 3 ",-- 2. Alaska
split"5, 0x15, 1, 3, 0x23, 6, 0xC5, 2, 7, 12,  4 ", -- 3. Japan
split"5, 0x25, 2, 2, 0x21, 5, 0x42, 3, 13, 2, 2 ", -- 4. Oz
split"4, 0x45, 2, 4, 0x34, 1, 0xD5, 2, 13, 12, 2 ", -- 5. kenya
split"5, 0x65, 2, 6, 0x76, 6, 0x15, 2, 6, 12, 3 ", -- 6. Nepal
split"5, 0x51, 1, 5, 0x35, 6, 0x82, 1, 1, 0, 1 ", -- 7. Germany
split"13, 0xCD, 1, 2, 0x2E, 10, 0xBD, 3, 6, 14, 2 ", -- 8. Funland
  }

-- 1. Theme 2. spr pattern 3. yscale 4. curvescale 5. seed 6. name
LEVELDEF={
split"1, 1, 0.5, 0.8, 1, usa ",
split"4, 4, 0.8, 1, 4, australia",
split"2, 2, 1.1, 0.8, 8, alaska",
split"3, 3, 0.9, 1.1, 13, japan",
split"5, 4, 0.8, 1, 30, kenya",
split"6, 2, 1.2, 0.9, 14, nepal",
split"7, 1, 0.9, 1.2, 88, germany",
split"8, 5, 1.3, 1.4, 29, funland"
}

Theme, Level, IsCustomRace=1,1,0

NumSegs = 0
sPointsX, sPointsY, sPointsZ, sPointsC = {},{},{},{}

NUM_LAPS = 3

sSprite,sSpriteX,SpriteCollideRect = {},{},{}
sSpriteSc = {} -- scale
SpriteCollideIdx=-1
sTokensX, sTokensExist = {},{}
TokenCollected,NumTokens = 0,0

LastY = 0 -- last y height when building a track
Position = 0 -- current position around the track

-- -1 to 1 TODO: maybe don't make relative to road width
PlayerX, PlayerXd, PlayerY, PlayerYd, PlayerVl, PlayerVf, PlayerDrift, PlayerAir, PlayerLap, Pfrm = 0,0,0,0,0,0,0,0,0,0

PlayerSeg = 0 -- current player segment
PlayerStandF = 0 -- final standing

BURNOUT_SPD = 1.3

RecoverStage = 0 -- 1. pause 2. lerp to track 3. flash
RecoverTimer, InvincibleTime = 0,0

OpptPos, OpptLap, OpptSeg, OpptX, OpptV = {},{},{},{},{}

HznOffset = 0
HUD_HEIGHT = 16
sScreenShake = {0,0}

-- 1. Menus 2. Racing
TitleState=1
-- 1. countdown 2. race 3. end standing 4. Summary UI
RaceState = -1
RaceStateTimer, RaceCompleteTime = 0,0
RaceCompletePos = 0 -- player standing

function LoopedTrackPos(z)
  lps=flr(z/(SEG_LEN*NumSegs))
  return z-SEG_LEN*NumSegs*lps
end

function DepthToSegIndex(z)
  return flr(z/SEG_LEN) % NumSegs + 1
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
          if (sdi[6] == 1 and rnd( 30000 ) > 15000) xrand = -1

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

function MenuRestart()
  InitRace()
end

function MenuQuit()
  OpenMenu(MenuState)
end

function InitRace()

  TitleState=2

  menuitem( 1, "restart race", MenuRestart )
  menuitem( 2, "abandon race", MenuQuit )

  NumTokens=0
  TokenCollected=0

  EraseTrack()
  if IsCustomRace==1 then
    BuildCustomTrack( CustomLevel, CT_HILLS[CustomHills], CT_CURVES[CustomCurves], CustomSeed )
  else
    BuildCustomTrack( Level, LEVELDEF[Level][3], LEVELDEF[Level][4], LEVELDEF[Level][5] )
  end
  InitOps()
  RaceStateTimer = time()
  RaceState = 1

  Position = SEG_LEN
  PlayerX = -0.2 -- -1 to 1 TODO: maybe don't make relative to road width
  PlayerXd, PlayerY, PlayerYd, PlayerVl, PlayerVf, PlayerDrift, PlayerAir, Pfrm = 0,0,0,0,0,0,0,0
  PlayerSeg = 0 -- current player segment
  PlayerLap = 1

  RecoverStage = 0 -- 1. pause 2. lerp to track 3. flash
  RecoverTimer, InvincibleTime = 0,0
  UpdatePlayer()
end

function _init()
  --font init
  memset(0x5600,0,256*8)
  poke(0x5600,unpack(split(font)))

  brush={}

  for n=0,4,4 do

    brush[n]={}

    local start = 0x2000+n*128
    local l=peek(start)

    for i=1, l do

      local cmd={}

      for j=1,5 do
        cmd[j]=peek(start+(i-1)*6+j)-64
      end
      cmd[6]=peek(start+(i-1)*6+6)
      cmd[7],cmd[6]=(cmd[6]&240)>>4,(cmd[6]&15)
      add(brush[n],cmd)
    end

  end

  LoadProfile()
  --EraseProfile()
  InitSpriteDef()

  palt(0, false)
  palt(15, true)

  InitParticles()
  OpenMenu(1)
end

function RaceStateTime()
  return time()-RaceStateTimer
end

function IsOffRoad()
  return abs( PlayerX*ROAD_WIDTH ) > ROAD_WIDTH and PlayerAir == 0
end

function IsBurnout()
  return PlayerAir==0 and IsOffRoad() == false and PlayerVf < BURNOUT_SPD and btn(🅾️) -- z / btn1
end

function UpdateRaceInput()

  if RaceState == 2 and PlayerAir == 0 then
    if btn(❎) then -- btn2
      if abs( PlayerXd ) > 0.1 then
        PlayerDrift=sgn(PlayerXd)
        Pfrm=max(.2,Pfrm)
      else
        PlayerVl=PlayerVl-0.08
      end
    end

    if btn(🅾️) then -- z / btn1
      PlayerVl=PlayerVl+0.09
    end

    if btn(⬅️) then -- left
      PlayerXd-= (0.022 + -PlayerDrift*0.01) * (1-PlayerVl*0.0005)*min(PlayerVl*0.125,1)
    elseif btn(➡️) then -- right
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
      
    local drftslw=(1-abs(PlayerDrift)*0.001)
      
    if IsOffRoad() then
      PlayerVl=PlayerVl*0.989*drftslw
      PlayerXd=PlayerXd*0.96
    else
      PlayerVl=PlayerVl*0.995*drftslw
      PlayerXd=PlayerXd*0.95
    end
  end
  if PlayerVl < 0.02 then
    PlayerVl = 0
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
  PlayerX+=sPointsC[PlayerSeg]*0.45*PlayerVl*0.01 + PlayerXd*0.15

  if abs( PlayerXd ) < 0.08 then
    PlayerDrift=0
  end

  HznOffset = HznOffset + sPointsC[PlayerSeg] * 0.14 * (PlayerVf)

  if PlayerDrift==0 then
    Pfrm-=.2
  else
    Pfrm+=.2
  end
  Pfrm=mid(0,Pfrm,1)

  -- jumps / player y

  local ground = lerp( sPointsY[PlayerSeg], sPointsY[nxtseg], posinseg)
  PlayerY=max(PlayerY+PlayerYd, ground)
  if( PlayerY == ground ) then
    if PlayerYd < -2 and PlayerAir > 4 then
      sScreenShake = {1.5,4}
      sfx( 11, 2 )
      AddParticle( 6, 52, 122 )
      AddParticle( 7, 78, 126 )
      AddParticle( 1, 52, 122 )
      AddParticle( 2, 78, 122 )
    end
    local nposinseg=1-(PlayerSeg*SEG_LEN-(Position+PlayerVf ))/SEG_LEN
    local nground = lerp( sPointsY[PlayerSeg], sPointsY[nxtseg], nposinseg )
    PlayerYd = ( nground - ground ) - 0.2
    PlayerAir = 0
  else
    PlayerYd=PlayerYd-0.25
    PlayerAir = PlayerAir + 1
  end

  -- particles

  if RecoverStage < 2 then
    if IsOffRoad() then
      if PlayerVf > 1 then
        if Frame%5 == 0 then
          srand(Frame)
          AddParticle( 3, 64 + flr(rnd(32))-16, 120 + rnd( 1 ) )
        end
        if Frame%10 == 0 then
          sScreenShake[1],sScreenShake[2] = 1,1
        end
      end
    else
      if Frame%8 == 0 and PlayerAir == 0 then
        if PlayerDrift < 0 then
          AddParticle( 1, 62 - rnd( 4 ), 120 + rnd( 2 ) )
        elseif PlayerDrift > 0 then
          AddParticle( 2, 74 + rnd( 4 ), 120 + rnd( 2 ) )
        elseif IsBurnout() then
          AddParticle( 1, 50 - rnd( 4 ), 122 )
          AddParticle( 2, 80 + rnd( 4 ), 122 )
        end
      end
    end
  end
end

function UpdateRecover()

  if RecoverStage == 0 then
    return
  else

    t1,t2,t3=1.5,2.5,3.5
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
      if time() - RecoverTimer >= t3 then RecoverStage = 0 end
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
      local opv=(NUM_LAPS-OpptLap[i])*0.017
      local opspd=(0.04+PlayerVl*0.022+i*0.008+opv)
      if RaceState >= 3 then
        opspd=0.08
      end
      OpptV[i]=OpptV[i]+opspd
      OpptV[i]=OpptV[i]*0.92

      if RecoverStage == 0 then
        srand(i)
        OpptX[i] = min( max( OpptX[i] + sPointsC[OpptSeg[i]] * (0.008+rnd(0.01)), -0.6 ), 0.6 ) * (0.99+rnd(0.005))
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

  local nxtseg=(PlayerSeg)%NumSegs + 1

  -- opponents

  local carlen=2+PlayerVl*0.1

  local ground = lerp( sPointsY[PlayerSeg], sPointsY[nxtseg], posinseg)
  for i=1,#OpptPos do

    local opposl = LoopedTrackPos( OpptPos[i] )

    if ( Position + PlayerVf ) > ( opposl - carlen + OpptV[i] ) and
       ( Position + PlayerVf ) < ( opposl + OpptV[i] ) and
      ROAD_WIDTH * abs( PlayerX - OpptX[i] ) < 12 and
      ( PlayerY-ground ) < 2 then

      sfx( 7, 2 )

      PlayerVl = OpptV[i]
      PlayerXd = -sgn(PlayerX) * 0.2

      sScreenShake[1],sScreenShake[2] = 4, 2

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

  if SpriteCollideIdx > 0 then --and ( Position + carlen + PlayerVf ) > PlayerSeg*SEG_LEN then

    sdef1=SDEF[SpriteCollideIdx]
    if sdef1[8]==1 then

      -- work out range of pixels in the source sprite that we overlap
      -- player is ~40-80px
      local insprx1=(48-SpriteCollideRect[1])/SpriteCollideRect[3]
      local insprx2=(80-SpriteCollideRect[1])/SpriteCollideRect[3]

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
      sScreenShake[1],sScreenShake[2] = 3, 1
      PlayerVl = PlayerVl * 0.2
      PlayerXd = -sgn(PlayerX) * 0.2
      InvincibleTime=time()+1
      AddParticle( 4, 64 + rnd(32)-16, 96 + rnd( 8 ) )
      AddParticle( 5, 64 + rnd(32)-16, 96 + rnd( 8 ) )
    else
      -- big hit
      sfx( 6, 2 )
      sScreenShake[1],sScreenShake[2] = 10, 4

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
    ProfTime=ReadProfile( Level, 3 )
    if ProfTime==0 or RaceCompleteTime < ProfTime then
      WriteProfile( Level, 3, RaceCompleteTime )
    end
    ProfStand=ReadProfile( Level, 1 )
    if ProfStand==0 or RaceCompletePos < ProfStand then
      WriteProfile( Level, 1, RaceCompletePos )
    end
    if TokenCollected > ReadProfile( Level, 2 ) then
      WriteProfile( Level, 2, TokenCollected )
    end
  end
end

function UpdateRace()
  if RaceState < 4 then
    -- screenshake
    sScreenShake[1]=lerp(sScreenShake[1],0, 0.1)
    sScreenShake[2]=lerp(sScreenShake[2],0, 0.1)
    if Frame%3 == 0 then
      sScreenShake[1]=-sScreenShake[1]
      sScreenShake[2]=-sScreenShake[2]
    end
    if( abs( sScreenShake[1] ) + abs( sScreenShake[2] ) < 1 ) then
      sScreenShake = {0,0}
    end

    UpdatePlayer()
    UpdateRecover()
    UpdateCollide()
    UpdateOpts()
    UpdateParticles()
    UpdateRaceState()
  else
    if btnp(🅾️) then
      OpenMenu(MenuState)
    elseif btnp(❎) then
      InitRace()
    end
  end
end

function _update60()

  --DebugUpdate()
  Frame=Frame+1
  if TitleState == 1 then
    UpdateMenus()
  elseif TitleState == 2 then
    UpdateRace()
  end
  UpdateRaceSound()
end

function HrzSprite( x, ssx, ssy, f )
  hsprdef=HORZSDEF[THEMEDEF[Theme][11]]
  ssy=ssy*hsprdef[6]
  sspr( hsprdef[1],hsprdef[2],hsprdef[3],hsprdef[4],
    (HznOffset + x) % 256 - 128, 64 - flr( ssy * 16 ), ssx*hsprdef[5] * 48, ssy * 16, f )
end

function RenderHorizon()

  fillp(0)
  rectfill( 0, 64, 128, 128, THEMEDEF[Theme][4] ) -- block out the ground
  HrzSprite(10, 1.0, 0.7, true)
  HrzSprite(64, 0.3, 1.2, false)
  HrzSprite(60, 2.3, 0.3, false)
  HrzSprite(128, 1, 1, false)
  HrzSprite(178, 1.5, 0.5, true)

end

function RenderSky()
  local thm = THEMEDEF[Theme]
  fillp(0)
  rectfill( 0, 0, 128, 20, thm[10] ) -- block out
  BayerRectV( 0, 20, 138, 50, thm[9], thm[10] )
  fillp(0)
  rectfill( 0, 50, 128, 64, thm[9] ) -- block out
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

  local thm=THEMEDEF[Theme]

  -- Ground, We only render intermittent strips, most of the ground has been
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
end


function _draw()
  --cls()
  if TitleState == 1 then
    RenderMenus()
  elseif TitleState == 2 then
    if RaceState < 4 then
      camera( sScreenShake[1], HUD_HEIGHT + sScreenShake[2] )
      RenderSky()
      RenderHorizon()
      RenderRoad()
      camera( 0, 0 )
      RenderRaceUI()
    else
      RenderSummaryUI()
    end
  end
  --DebugRender()
end

function PrintBigDigit( n, x, y,nrend)
  x-=2
  if not nrend then
  poke(0x5f58, 0x1 | 0x80) --custom font
    n1=n*2+16+n\8*16
    print(chr(n1)..chr(n1+1).."\n"..chr(n1+16)..chr(n1+17),x,y-3,7) --4 chars to print 1 big
  poke(0x5f58, 0x0) --default font
  end
  if (n==1) return 12
  return 16
end

function PrintBigDigitOutline( n, x, y, col )
  i=n+1
  pal( 7, col )
  PrintBigDigit( n, x-1, y )
  PrintBigDigit( n, x+1, y )
  PrintBigDigit( n, x, y-1 )
  PrintBigDigit( n, x, y+1 )
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
  stnd=split"st,nd,rd"
  if n < 4 then
    return stnd[n]
  end
  return "th"
end

function RenderCountdown()
  if RaceState == 2 and RaceStateTime() < 1 then
    frac=( time() - RaceStateTimer )%1
    x=64-16
    PrintBigDigitOutline( 10,x,30, 0 )
    PrintBigDigit( 10,x,30)
    x=x+16
    PrintBigDigitOutline( 0,x,30, 0 )
    PrintBigDigit( 0,x,30)
  elseif RaceState == 1 then
    num= 3-flr( RaceStateTime() )
    frac=( RaceStateTime() )%1
    if num <= 0 then
      return
    elseif frac < 0.9 then
      x=64-8
      PrintBigDigitOutline( num,x,30, 0 )
      PrintBigDigit( num,x,30)
    end
  end
end

function RenderRaceEndStanding()
  if (RaceState != 3) return

  if RaceStateTime() < 1 then
    clip( 0, 0, (RaceStateTime()*8)*128, 128 )
  elseif RaceStateTime() > 3 then
    clip( ((RaceStateTime()-3)*8)*128, 0, 128, 128 )
  end
  rectfill( 0, 25, 128, 49, 1 )
  tw=PrintBigDigit( RaceCompletePos, 0, 0, 1 )
  PrintBigDigit( RaceCompletePos, 53, 32)
  print( GetStandingSuffix(RaceCompletePos), 64+tw*0.5-5, 32, 7 )

  sspr(unpack(split"120, 16, 7, 18, 37, 27, -7, 18"))
  sspr(unpack(split"120, 16, 7, 18, 84, 27, 7, 18"))

  clip()

  if RaceStateTime() > 3.6 then
    fade=max( (0.5-(time()-(RaceStateTimer+3.6)))/0.5, 0 )
    BayerRectT( fade, 0, 0, 128, 128, 0xE0 )
    if RaceStateTime() > 4.8 then
      RaceState = 4
      RaceStateTimer=time()
    end
  end
end

function RenderSummaryUI()

  rectfill( 0, 0, 128, 128, 0 )

  if RaceStateTime() < 1 then
    clip( 0, 0, 128, ((RaceStateTime())*3)*128 )
  end

  for x=-1,7 do
    for y=-1,7 do
      off=(Frame*0.5)%16
      xoff=x*16+off
      yoff=y*16+off
      RenderFlag( xoff, yoff, Level )
      BayerRectT( max(sin(Frame/120+xoff/53+yoff/63)+1,0.1), xoff, yoff, xoff+10, yoff+7 )
    end
  end
  fillp()

  if RaceStateTime() > 1 then

    if (RaceStateTime() < 2) then
      clip( 0, 0, ((RaceStateTime()-1)*16)*128, 128 )
    end

    rectfill( 0, 10, 128, 23, 13 )
    rectfill( 0, 34, 128, 90, 13 )
    line( 0, 33, 128, 33, 1 )
    line( 0, 91, 128, 91, 1 )
    rectfill( 0, 101, 128, 117, 13 )

    fillp(0x33CC)
    col = bor( 6 << 4, 0 )
    rectfill(0,12,33,21, col)
    rectfill(94,12,128,21, col)
    RenderTextOutlined( "race complete", 38, 15, 0, 7 )
    fillp()

    -- position
    rectfill(0,39,64,51, 1)
    print( "position", 19, 43, 6 )
    sspr( 65, 49, 8, 8, 54, 41 ) -- trophy

    -- tokens
    rectfill(0,56,64,68, 2)
    print( "tokens", 27, 60, 6 )
    sspr( 17, 121, 7, 7, 55, 59 )

    -- time
    rectfill(0,73,64,85, 3)
    print( "time", 35, 77, 6 )
    sspr( 73, 50, 7, 7, 55, 76 )

    -- position text
    col=RaceCompletePos == 1 and 9 or 7
    print( tostr( RaceCompletePos ).. tostr( GetStandingSuffix(RaceCompletePos) ), 69, 43, col )

    -- tokens text
    col=7
    if TokenCollected == NumTokens then
      col = 9
    end
    print( tostr( TokenCollected ).."/".. tostr( NumTokens ), 69, 60, col )

    -- time text
    PrintTime( RaceCompleteTime, 69, 77 )

    -- controls
    print( " \142  menu", 45, 104, 6 )
    print( " \151  retry", 45, 110, 6 )

    clip()
  end
end

function RenderRaceUI()

  fillp(0)
  rectfill( 0,111, 127, 127, 0 )
  rect( 0, 111, 127, 127, 6 )
  rect( 1, 112, 126, 126, 13 )

  stand=GetPlayerStanding()
  strlen=PrintBigDigit( GetPlayerStanding(), 3, 114)
  print( GetStandingSuffix(stand), strlen+1, 114, 7 )

  sspr(unpack(split"52, 24, 7, 5, 38, 120"))
  sspr(unpack(split"59, 24, 9, 5, 37, 114"))
  print( min(PlayerLap, NUM_LAPS), 49, 114, 6 )
  print( "/"..tostr(NUM_LAPS), 57, 114, 5 )
  print( TokenCollected, 49, 120, 6 )
  print( "/" ..tostr(NumTokens), 57, 120, 5 )

  for i=80, 124, 2 do
    y1 = flr(lerp( 121, 115, (i-107)/(113-107) ))
    y1=max(min(y1,121),115)
    -- top speed is ~17.5 m/s
    norm=(i-80)/(128-80)

    col = 5
    if norm < PlayerVl/19 then
      if i < 104 then col = 6
      elseif i < 118 then col = 7
      elseif i < 122 then col = 9
      else col = 8
      end
    end
    line( i, y1, i, 124, col )
  end

  spd=flr( PlayerVl * 8.5 )
  x1=88
  if spd > 9 then
    x1 -= 4
  end
  if spd > 99 then
    x1-= 4
  end
  print( spd, x1, 114, 6 )
  print( "mph", 94, 114, 6 )
  RenderCountdown()
  RenderRaceEndStanding()

end

function RenderPlayer()

  if RecoverStage == 2 or ( InvincibleTime-time() > 0 and time()%0.4>0.2 ) then
    return
  end

  local woby=0

  function drawDrift()
    if Pfrm==0 and (PlayerXd <= 0.28 and PlayerXd >=-0.28) then
      fillp()
      local px=48+woby
      pd_draw(4,px+PlayerXd,92,1,9)
      pd_draw(4,px-PlayerXd*6\1,92,10,17)
      pd_draw(4,px-PlayerXd*11\1,92,18,40)
    elseif Pfrm > .6 then
      sspr(52, 0, 47, 23, 44, 100+woby, 47, 23, PlayerXd > 0 ) --drift
    else
      sspr(16, 0, 35, 23, 47+woby, 100, 35, 23, PlayerXd>0) --turn
    end
  end

  if PlayerDrift != 0 or IsBurnout() then -- z / btn1
    srand(time())
    woby=rnd(1.2)
  end

  drawDrift()

end

function GetSpriteSSRect( s, x1, y1, w1, sc )
  ssc = w1*sc
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

function RenderSpriteWorld( s, rrect, f)
  local w = ceil(rrect[3] + 1)
  sspr( SDEF[s][1], SDEF[s][2], SDEF[s][3], SDEF[s][4], rrect[1]+(f and w or 0), rrect[2], w, ceil(rrect[4] + 1), f or SDEF[s][7] == 1 )
end

function RenderRoad()

  local loopoff,xoff = 0,0

  local pscreenscale, psx, psy, psw, pcamx, pcamy, pcamz, pcrv, clipy={},{},{},{},{},{},{},{},{}

  local camx = PlayerX * ROAD_WIDTH

  local function RenderOpponent(o,i,t)

    -- Imposters, render at the seg pos/middle of road
    local opsx,opsy,opsw =psx[i],psy[i],psw[i]
    local seg = OpptSeg[o]

    if i<50 then

      local plsegoff1=(seg-PlayerSeg)%NumSegs+1
      local opinseg=1-(seg*SEG_LEN-OpptPos[o])/SEG_LEN
      local nxtseg = seg % NumSegs + 1
      local plsegoff2=(nxtseg-PlayerSeg)%NumSegs+1
      local ppos=Position

      if OpptLap[o] > PlayerLap then
        ppos-=SEG_LEN*NumSegs
      end

      local ocrv=lerp( pcrv[plsegoff1], pcrv[plsegoff2], opinseg )
      local optx=OpptX[o]*ROAD_WIDTH

      local opcamx = lerp( sPointsX[seg ] + optx, sPointsX[nxtseg] + optx, opinseg ) - camx - ocrv
      local opcamy = lerp( sPointsY[seg ], sPointsY[nxtseg], opinseg ) - ( CAM_HEIGHT + PlayerY )
      local opcamz = lerp( sPointsZ[seg ], sPointsZ[nxtseg], opinseg ) - ppos

      local opss = CAM_DEPTH/opcamz
      opsx = flr(64 + (opss * opcamx * 64))
      opsy = flr(64 - (opss * opcamy * 64))
      opsw = flr(opss * ROAD_WIDTH * 64)
    end

    pal( 14, opcols1[o%#opcols1+1] )
    pal( 2, opcols2[o%#opcols2+1] )

    if sPointsC[seg ] > 0.5 then
      local rrect = GetSpriteSSRect( 8, opsx, opsy,opsw, .16 )
      RenderSpriteWorld( 8+t, rrect)
    elseif sPointsC[seg ] < -0.5 then
      local rrect = GetSpriteSSRect( 9, opsx, opsy,opsw, .16 )
      RenderSpriteWorld( 9+t, rrect )
    else
      local rrect = GetSpriteSSRect( 7, opsx, opsy,opsw, .12 )
      RenderSpriteWorld( 7+t, rrect )
      RenderSpriteWorld( 7+t, rrect,1)
    end
  end

  local posinseg=1-(PlayerSeg*SEG_LEN-Position)/SEG_LEN
  local dxoff = - sPointsC[PlayerSeg] * posinseg

  -- calculate projections
  local hrzny=128
  local hrzseg=DRAW_DIST

  for i = 1, DRAW_DIST do

    -- fun foreshortening hack (add to i in statement below)
    -- oop=flr(max(i/DRAW_DIST-0.4,0)*50)
    local segidx = (PlayerSeg - 2 + i ) % NumSegs + 1

    pcrv[i] = xoff - dxoff
    pcamx[i] = sPointsX[segidx] - camx - pcrv[i]
    pcamy[i] = sPointsY[segidx] - ( CAM_HEIGHT + PlayerY )
    pcamz[i] = sPointsZ[segidx] - (Position - loopoff)

    if segidx == NumSegs then
      loopoff+=NumSegs*SEG_LEN
    end

    xoff = xoff + dxoff
    dxoff = dxoff + sPointsC[segidx]

    pscreenscale[i] = CAM_DEPTH/pcamz[i]
    psx[i] = (64 + (pscreenscale[i] * pcamx[i]  * 64))
    psy[i] = flr(64 - (pscreenscale[i] * pcamy[i]  * 64))
    psw[i] = (pscreenscale[i] * ROAD_WIDTH * 64)

    -- store the min y to block out the ground
    if psy[i] < hrzny then
      hrzny=psy[i]+1
      hrzseg=i
    end

  end

  SpriteCollideIdx=-1

  for i = DRAW_DIST - 1, 1, -1 do

    segidx = (PlayerSeg - 2 + i ) % NumSegs + 1

     if i+1== hrzseg then
      fillp(0)
      rectfill( 0, hrzny, 128, 128, THEMEDEF[Theme][4] ) -- block out the ground
    end

    -- segments
    local j=i+1
    if psy[i] > psy[j] and ( psy[i] >= hrzny ) then
      RenderSeg( psx[i], psy[i], psw[i], psx[j], psy[j], psw[j], segidx )
    end
    if i==1 and TitleState == 2 then
      RenderPlayer()
      RenderParticles()
    end

    -- sprites

    --local d = min( ( 1 - pcamz[i] / (DRAW_DIST*SEG_LEN) ) * 8 , 1 ) --passed to RenderSpriteworld but unused?
    local pcamx,psscale,rrect=pcamx[i],pscreenscale[i]
    if sSprite[segidx] != 0 then
      local psx1 = flr(64 + (psscale * ( pcamx + sSpriteX[segidx] * ROAD_WIDTH ) * 64))

      local sindx=sSprite[segidx]
      rrect = GetSpriteSSRect( sindx, psx1, psy[i],psw[i], sSpriteSc[segidx] )
      RenderSpriteWorld( sindx, rrect)
      if i == 2 then
        SpriteCollideRect = rrect
        SpriteCollideIdx=sSprite[segidx]
      end
    end

    -- Start gantry
    if segidx == 1 or segidx == 2 then
      local psx1l = flr(64 + (psscale * ( pcamx + ROAD_WIDTH * -1.2 ) * 64))
      local psx1r = flr(64 + (psscale * ( pcamx + ROAD_WIDTH * 1.2 ) * 64))
      rrect = GetSpriteSSRect( 11, psx1l, psy[i],psw[i], 0.14 )
      RenderSpriteWorld( 11, rrect)
      rrect = GetSpriteSSRect( 11, psx1r, psy[i],psw[i], 0.14 )
      RenderSpriteWorld( 11, rrect )

      if segidx == 1 then
        psx1l = flr(64 + (psscale * ( pcamx + ROAD_WIDTH * -0.55 ) * 64))
        psx1r = flr(64 + (psscale * ( pcamx + ROAD_WIDTH * 0.55 ) * 64))
        for j=12,13 do
          rrect = GetSpriteSSRect( j, j==12 and psx1l or psx1r, psy[i], psw[i], .75 )
          rrect[2]-=.25*psw[i]
          RenderSpriteWorld( j, rrect )
        end
      end
    end

    -- tokens
    if sTokensX[segidx] !=0 and sTokensExist[segidx] != 0 then
      local psx1 = flr(64 + (psscale * ( pcamx + sTokensX[segidx] * ROAD_WIDTH ) * 64))
      local psy1 = flr(64 - (psscale * ( pcamy[i] + 4 )  * 64))
      rrect = GetSpriteSSRect( 43, psx1, psy1,psw[i], 0.15 )
      RenderSpriteWorld( 43, rrect)
    end

    -- opponents
    for o = 1,#OpptPos do
      if (OpptSeg[o] == segidx) RenderOpponent(o,i,CType[o%3+1])
    end
    pal( 14, 14 )
    pal( 2, 2 )
  end

end

__gfx__
fffffffeeeeeeeeefffff11eeeeeeeeeeeeeeeeeefffffffffffffffffffffffffe1eeeeeeeeeeeeeeeeeeffffffffffffffffff2154fffffffd66500109940f
ffffff5eeeeeeeeefffddddeddd5555555555dddddfffffffffffffffffffff1dddd1eeeeee55555555dddddffffffffffffffff5449fffffff0d6651009404f
ffff155ddd555555eddddd0ddddddddddddddddddddfffffffffffffffffdddddddde0eddddddddd666666666fffffffffffffff14999ffffff10d665004049f
fff555dddddddddd1155d5e66666666666666666ddddffffffff8e8e8e1d5ddddddd5ee6666666ddddddddddddfffffffffffffff5224ffffff000d66500494f
ff15e6666666666621555edddddddddddddddddddddddfffffffe800e811155d5dd5eeeddddddddddddd66666666ffffffffffff2424fffffff001d66504940f
ff0deddddddddddd2115ee666666666666666666666dddffffff8e108e8e11151de0eedddd66666666ddd5555555dfffffffffff5542fffffff01d665009404f
ffde66666666666602eeedddd55555dddddd5555555555ddffffe001e8e8e8111d5eee66dd5555d5dddd55556666660000ffffff2452fffffff1d6650014049f
ffedddd55555dddd02eedd666666666666666666666665550fff80000e8e8e8e15eeeedd555556666666000000000000000fffff54444ffffffd66500100499f
fe66666666666666002eeee000000000000000000000000000ff10000218e811e8eeee666666000000000000022222000000ffff15245fffffffff55fff4999f
fee0000000000000002eee00000022222222222222222200000f100001212e818e88eeeeeee00002222222222222222eeeeefffff4944fffffffffddffff55ff
fe000002222222220002e000222222222222222222222eeeeeee005002121218e8e0e8eeee00002222222eeeeeeeeeeeeeeeffff594994ffffffff66ffffddff
e0000222222222220002eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeef015012121212e00008e8000eeeeeeeeeeeeeed44877888effff1d2455ffffffffd6ffff66ff
eeeeeeeeeeeeeeee0002eeeeeeeeeeeeedddddddd448877888eeff1102121212120000e8eeeeeeeee4ddddddddd4487d222efff54444445f2fffff66ffff6dff
ee888877844dddddf000ee888778844dddd5555dd448877222eeffff002121212101010e8ee8877844dddd555dd442dd222efff259499999494fffd6ffff66ff
ee888877844dddddf000ee222dd2244dd555555dd4422dd222eeffffff00121212010008eee88dd244d555555deeeeeeeeeef11522222454249fff66ffff6dff
ee2222dd244dd555f000ee222dd2244dd55eeeeeeeeeeeeeeeeefffffff000212101d0008ee22dd244eeeeeeeeeeeee22222125222222222422fffffff7fffff
ee2222dd244dd555ff00eeeeeeeeeeeeeeeeeeeeeeeeeeeee222fffffffff0021201d0002eeeeeeeeeeeee2222222222222fffffffffffee2effefffff7fffff
eeeeeeeeeeeeeeeeff00eeee2222222222222222222222222222ffffffffff00010150002eeeee2222222222222d6d55555fffffffefee2eeeee7efff7ffffff
2222222222222222ff002222222222222222225555d6d5555555ffffffffffff00010000222222222225555555560650000fffffffee2e7e27e2eeefffffffff
2222222222222222fff055555555d6d555555555556065550000fffffffffffff00005002222555d6d555550000d6d00000ffffffe72e2227e2ee27effff7fff
55555555d6d55555fff05555555560600000000000d6d0000000fffffffffffffff0550025555556060000000000000000ffffffffe97e24e2272e2eff777fff
0000000060600000fff000000000d6d000000000000000000000ffffffffffffffff51002000000d6d0000000000000ffffffffffe2272ee42ee2227ff77ffff
f0000000d6d00000ffff0000000000000000000000000000000fffffffffffffffffff000000000000000000ffffffffffffffffffe44f4f4f4ff4eeffffffff
f000000000000000fffff0000000000ffffffffffffffffffffffffffffffffffffffffff00000000ffffffffffffffffffffffffff5eff444f2eee5fffff77f
ffffffeeeeeeeeeefffffffffffffffffffffffffffffffffffffaa5aaafeeeeeeeffffffffff2221ff49ff49fffffffffffffffffffef5e44945ffffff7777f
fffffeeeeeeeeeeefffffffffffeeeeeeeeeeeeeeefffffffffffa585aaefffffffeffffffff2dd6d1f4f4ff4fffffffffffffffffffffff49fffffffff77fff
ffffee1d55555dd5ffff50eeeeeeeeeeeeeeeeeeeeeeeefffffff597e5aefffefffefffffff2dddd62f54f54f4ffffffffffffffffffffff44ffffffffffffff
ffffe11dddddddddfff555ee1d5555555555ddd5555d1eeffffffa5c5aafeeefefeffffffff11d44d42f454f4fffffffffffffffffffffff49fffffffffff77f
fffee1ddddddddddfff555e1100000000000000000000000000ffaa5aaaffffefffffffffffffffffff45555ffffffffffffffffffffffff44fffffffff7777f
fff0000000000000ee5558e1000000000000000000000000000ffffffe2e2e2e2e2e2efffddd2e2e2e2e2e2e2e2e2e2e2fffffffffffffff49ffffffff7777ff
ffe000000000000020515ee10000000000000000005ddd1ee00fffffeeeeeeeeeeeeeeedddddeeeeeeeeeeeeeeeeeeeeeeeffffffffffff2444fffffffffffff
ffe01dd55555555d22055e110d55555555ddd55555555511e00fffffff6e62226222221155d52226226222226222226e6ffffffffffff9ffffff6ffff77fffff
fee0eeeeeeeeeeee0220ee110555555555eeeeeeeeeeeeeee00ffffff6ee6ee65d222221555eee66e6d22222d6eee66eee6fffffffff9a9ffff676ff77777fff
fee02222222222222222eeee022222222222222222222222200effff6eee6e65d666662115ee6666265d66666d56666eeee6fffffff9a7a9ff67666ff77777ff
eee022222222222220222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeff6eed5665555555502eeed566665555555555566655deee6ffff9a777a96666666fff55fff
eeeeeeeeeeeeeeee20220ee2220000000000000000000000222eef6eed55655666666602eedd5566655566666666556555deee6ffff9a7a9ff666d6fff5675ff
eee222000000000002020e278820022000000000000220027882e6eeeeee5e55555555002eeeeeee5e5555555555555eeeeeeeeeffff9a9ffff6d6fff565575f
ee2887200220000002200e288820276200088888002762028882eeeeeeeeee77777777002eeeeeeeeee7777777777777ee88822efffff9ffffff6ffff565565f
ee2888202672088800220e288820266200066666002662028882e22888872eeeeeeeee0002e2288872eeeeeeeeeeeeee2788822efffff5ffffff5fff55555555
ee28882026620666f0220ee2220002200000000000022000222ee22888872eeeeeeeee0002e2288872eeeeeeeeeeeeee2782222efffffdffffffdfff5aaaa995
eee2220002200000f0025eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee22222282eeeee57770002e2222282eeee577775eeeeee2222eefffff6ffffff6fff5aaa9995
eeeeeeeeeeeeeeeeff0002e22222222222222222222222222222ee222222eeeeee5777f000ee22222eeeee577775eeeeeeeee555fffff6ffffff6fff59999995
2222222222222222ff0002eeee2020202ddddddddd20200202eee55555555555555555f000eee555555555555555555555555656fffff6ffffff6fff5aa99995
eeee20202020ddddfff012eee20202020ddddddddd052525775ee56565656666666666f000ee5656566666666666666666665666fffff6ffffff6fff59999995
eee577020202dd55ffff02ee577525252dd55555dd5252570065e06666666d77d7d666ff002e656666d77d7d666d7d77d666620ffffff6ffffff6ffff5555555
ee5600752525dd55ffff12e5700652525dd550000000000600655f0222000700707000ff000222200070070700070700702220005aaa8f8867e8e8e867e8e8e8
5556006000000000fffff0556006000000000000000000006600ff0000000d77d7d000fff000000000d77d7d000d7d77d00000005aa88f88867e8e8e867e8e8e
0000660000000000ffffff0006600000fffffffffffffffffffff00000000000000000ffff00000000000000000000000000000f5a88cf888867e8888867e8e8
ffffffffffff6f6ff66fffffffffffffffffffffffa7fffff3fffff3ffffffffffffffffffffffff7fffaffe7fffffffffffffff588ccf8888867e8888867e8e
ffffffffff1d6d6dd66ffdddfdddffffffff5ffffaffffffff3f3f3ff0ffffff0f9999a9fffffffffaf9affeefffffffffffffff58ccbf88888867e8888867e8
fffffffff1dd666dd66ff55df55dffffff56665ffff9aaafffd33d3fd0fffff0f9f999af9ff666ffffa899ffeffffff55fff55ff5ccbbf8888867e8888867e88
155555d5ddddddddddddddddddddddddff66f66fff994a9af3d55333f0f0ff0ff9f999af9f67576ffff98fffefffff588555885f5cbb7f888867e8888867e888
ddddddd5555555555555555555555555f56fff65f9949994ff3d553fff0ff00f0f9999a9f6775776ffafffffffffff588585885f5bb77f88867e8888867e8888
ddddddd5ddddddddddddddddddddddddff66f66ff49999999ff9fffffff0f000fff999aff6775776fa7afffe75555555555555555b77ef8867e8888867e88888
d55555d5dd665d665dd665d665dd665dff56665ff995994994f4ff9ff0f0000fffff9afff6777576a777aeeef5365bbbb585bb75577eeffffffd55fffd55ffff
d5d5d5d5dd665d665dd665d665dd665dffff5ffff5555959f4f5f4ffff0000000fff55ffff67776ffa7afeeff5335b7bb585bbb557eeeffffff6ddfff6ddffff
d5d5d5d5dd665d665dd665d665dd665dffffffffff554555f5f5f5f5fff000f0fff4444ffff666ffffaffffff5335777b5857bb55ffffffffff666fff666ffff
d55555d5dddddddddddddddddddddddddffff0000000000000000ffffffffffffffffffffffffffffffffffff5635b7bb58577b55ffffffffff667fff667ffff
d51115d5dddddddddddddddddddddddddfff0999999999999999905566556655665566556655665566f56fff65665bbbb5857bb55ffffffffff667fff667ffff
d55555d5555555555555555555555555ffff091199199119911990556655665566f566f5f6f5f6f5f6fffffff5635bbb7585bbb55fffffffff11661166116611
ddddddd5ddddddddddddddddddddddddffff091919191999199190665566556655665566556655665f6f5fff5555555555555555ffffff555500770077007700
d55555d5dd665d665dd665d665dd665dff000911991919991991900000000000f566f5f600000006f5000000fff000000fff0000000fff555577007700770077
d5d5d5d5dd665d665dd665d665dd665df09999199919911991199999990099990ff00ff0aaaaaaa0f0aaaaaa0f0aaaaaa0f0aaaaaaa0ff555577007700770077
d5d5d5d5dd665d665dd665d665dd665df0999999999999999999999990ee09990f0ee0f0aaaaaaaa0aaaaaaaa0aaaaaaaa0aaaaaaaa0ff555500770077007700
d55555d5dddddddddddddddddddddddddf000000000000000000000000ee0000000ee0ff000000aa0aa0000aa0aa0000aa0aa000000fffffff11661166116611
d51115d5dddddddddddddddddddddddddf0ee0ee0ee00eeeee0f0eeee0ee00eeee0ee0f0aaaaaaaa0aa0000aa0aa0fff000aaaaaa0ffffffffffffffffffffff
d55555d5555555555555555555555555ff0ee0ee0ee0eeeeeee0eeeee0ee0eeeee0ee0f0aaaaaaa00aa0aaaaa0aa0fff000aaaaaa0ffffffffffffffffffffff
ddddddd5ddddddddddddddddddddddddff0ee0ee0ee0ee000ee0ee0000ee0ee0000ee0f0aa000aa00aa0aaaaa0aa0000aa0aa000000fffffffffffffffffffff
d55555d5dd665d665dd665d665dd665dff0eeeeeeee0eeeeeee0ee0ff0ee0eeeeeeee0f0aa0ff0aa0aa0000aa0aaaaaaaa0aaaaaaaa0ffffffffffffffffffff
d5d5d5d5dd665d665dd665d665dd665dfff0eeeeee0f0eeeee00ee0ff0ee00eeeeeee0f0aa0ff0aa0aa0ff0aa00aaaaaa0f0aaaaaaa0ffffffffffffffffffff
d5d5d5d5dd665d665dd665d665dd665dffff000000fff00000ff00ffff00ff0000000fff00ffff00f00ffff00ff000000fff00000000ffffffffffffffffffff
d55555d5dddddddddddddddddddddddddfaaaaaaafff28ff0000000000000000d0ddf555566ff888ffff8888fffdb7733b7763ffffff65ffffffffffffffffff
d51115d5ddddddddddddddddddddddddda9444449af2228f0666666666666611111d59aaaaa588788ff8e7e88ffd377d33b7763ffffff56ffffa7f7181711111
d55555d5555555555555555555555555f945505d4922552816d1616d16d1d6118110595aa5a688878ff8866e8ff3377d333b7763ffff65fffaafff8888811611
ddddddd5dddddddddddd515dddddddddf9550805d9f6d6df061161616616161a7e1d59aaaaa588888ff887688ff337733333b7763ffff56fffffff7181711116
ddddddd5dddddddddddd515dddddddddf950976059f7676f1616616d16d1d611c110195aa5a5f888fff88e7e8ffd366d33333d77b3f3f5fff1ffff1111116111
ddddddd5d6665dd6665dd5d666d6665df90a777e09f6767f1666666666666611111019955aa5ff8fffff8888fff3d7733333dd77b3ff353ff71fff1161111161
d5d5ddd5d6665dd6665dd5d666d6665df950b7d059f8282f11101001000000000000f199aa5fff7ffffff55ffffd366d3d3dd66d3ffffffffaa1ff1676111611
d555ddd5ddddddddddddd5d665ddddddf9d50c0559f2228ffff11ffff11fff11ffffff1555fffff77ffffddffff3d663d3dd66d3fff4449ff91fff1161111111
d5115d55ddddddddddddd5d666ddddddf9ad5055a9f2222ffffddffffddfffddfffffff11ffffffff7fffd6ffffd366d3dd66d5fff444449f1ffff6161688888
fffffffffffffb35bfffffffffff677ff49aaaaa94228888fffddffffddfffddfffffff55ffffffff7fff66ffff56655dd66d5ffff444f4f911fff1616177777
ffffffffbfb35b333bfffffffff6777eff4444444f222828f33dd3333dd333dd3333fff55fffffff7ffff66fffff55ffff55ffffff5444444171ff6161688888
fffffffb33b3b333b5bffffffff677e8fffffffffffffff7ddfffffffffffffffffffffffffffffffffff66fffffddffffddfffffff15f44f1aa1f1616177777
ffffffb33b53b3bb333bfffffff67e88fffffffffffffff75dfffffffffffffffffffffffffffffffffff66fffff66ffff66ffffffff555ff1aaa18888888888
fffffffbb5b33333333b5ffffff6e886fffffffffffffff75dfffffffffffffffffffffffffffffffffff66ffff5665555665555fffffffff1991f7777777777
ffffff55333335333355335ffffe8867fffffffffffffff75dffffffffff55fffdffffffffffffffffeeeeeee5f5dd5555dd55fffffffffff191ff8888888888
ffffff333b535533335333bbfff88677ffffffffffffff6d5dfffffffff5551ff5ffffffffffffffffeeeeeee5ffffffff0ffff0fffffffff11fff1111111111
fffff53b3535bb33553b35353bf86777ffffffffffffff6555ffdffffff5111ff56fffffffffffffffe77777e5fffffffff0f0f0ff0fffff7765561111111191
ffffff335555333333b3b53333f67777ffffffffffff51d551115ffffff5151ff55fffffffffffffffe7eee7e5f00ff0ff0ff0ff0f0fff0075ff651911111999
ffff6b55335333333333555535b67777ffffffffdfffd16555111ffffff51116d51fffffffffffffffd77777e5fff00fff0ff0f0fff0f0ff6f5f651191111191
fff5bb3335553355bb531f33bb56777effffffffddf6d16155111dd6d6551116651fffffffffffffffd7eee7e5fffff0ff0fff0fffff0fff6ff5651111191111
ffff5533bbb5533355333f333bb677e8ffffffddd5f5d1d5551116d6d65515166516ffffffffffffffd77777e5000fff000fff0fff0f0fff5666551191911111
fb3b33553333bd533335b54533367e88ffff5fddd5d1d1d5111116ddd61115166515ffffffffffffffd7dde7e5fff00fff0ff02ff0ff00ff6555551111111111
f35333153335ff153351fd533536e886fff656d5d55151d55511161ddd15111d651166df6dffffffffdddddee5fffff00f0f0ffff0ff00f055ff657777777777
b33b55ff355fff5533fd1f5355de8867ff5d5dd5d15151d51511161d1d11151111111ddd66f6ffffffddd7dde5ff000000000fff0ff2000f5f5f65777e88e777
db354dff553fffd54555fff5ddf88677ff56dd11d155d1d11511161d1d1111111111dddddd151fffffc77777d5f0ffffff200fff0f200fff5ff56577e8888e77
fd5dff514455ffff4ffffffffff867775d565d15d11dd1d11511161d1d5511111111115ddd66d5dfffccd7ddd5ffffffffff00f00000ffff5666557788888877
fffffffff544dfd49ffffffffff677775d5d5666666dd5d11115155515515115111151ddddd66ddfffcc7d7dd5ffffffffff000022200fff55555577e8888e77
fffffffffff549dd9ffffffffff66777fffffffffffffff25222ffffffffffffffffffffffffffffffc7c7d7d5ffffffffff0000fffff0ff55ff65777e88e777
ffffffffffff5449ffffffffffff666fffffffffffff2255452222ffffffffffffffffffffffffffffcc777dd5fffffffff0000fffffffff5f5f657777777777
ffffffffffff5d49fffffffffff66666ffffffffffff55444522222fffffffffffffffffffffffffffccc7ccd5ffffffff0000ffffffffff5ff565111fffffff
fffffffffffff544fffffffffffdff66ffffffffff22445442222522ffffffffffffffffffffffffffccccccc5ffffffff000fffffffffff56665518711fffff
fffffffffffff544fffffffffffdddddfffffffff22554445522222222ffffffffffffffffffffffffccccccc5ffffffff0000ffffffffff5555551888811fff
ffffff3f3f335444d333f3f3ffff555fffffff222554454522222522222fffffffffffffffffffffffffffff5ffffffffff000ffffffffff55ff6518711fffff
fffffff36fffffffa4000004a999a999fffff225544454552252522222222ff2222222ffffffffffffffffff5ffffffffff0002fffffffff1f5f651777811fff
ffffff333fffffff9a4000004a999a99fff25554455555544522222222222222255552222fffffffffffffff5fffffffff00000fffffffff5ff565187888811f
fffff33365ffffffa9a4000004a999a9ff2545555555544445222222222222222252222222ffffffffffffff5fffffffff00000fffffffff1666551111111111
ffff56f33fffffffa99a4000004a999af25555255225455452222222222222222222222222222fffffffffff5fffffff00000000ffffffff5555550000000000
ffffff5356ffffffaa99a4000004a99922222252225555452222222222222222222222222222222fffffffffffff44444fffffffffffffff15ff650007007000
fffff563333fffff9aa9994000004a99ffffff7dfffffff7dd6dd66c66dfffffffffffffffffffffffffffffffff44444fffffffffffffff5f5f658888778888
fff353f675ffffffa9aa9994000004a9ffffff67ddddddd6dd76dd6c666dddfffffffffffffffffffffffffffffff211ffffffffffffffff1ff5658888778888
ffff565336f36fff999aaa400000499affffff6ddddddddddddcddd7676ddd67dfffffffffffffffffffff44665554226666666666ffffff5666558888778888
fffff553355fffffa999a40000049999fffff76ddddddddddddc66dd6d6c66cc65dddffffffffffffffff4224665542266666666766fffff1515153337337333
ffff53333353ffff999a405000499999fffff7556dddddddddc6c7d77d5d6666cdddddffffffffffffff421144665422666666766666ffff51ff653333333333
ff355b56b6656fffa9a4000504a99999ffffc766666d6ddddd76c667cddd7d666dd5d5dffffffffffff42144444666666667666666676fff1f5f650000000000
ff55653635156fff9a4000004a9a9999ff777cdddd6dd6ddddc777757c656dd66c6dd55fffffffffff4214444444667676767676767676ff5ff5650000000000
ffff5755533fffffa40000049aa9a999fd76dddd666ddddddd67c77677d666dd6cc66d55dffffffff421444444444666666666666666666f1666158888888888
ffff55331333fffff555d655ffff55ff7777cdddddddd677c6c77c7777cdd666666d6dd1dddfffff421444444444442222222222222222225151558888888888
ff33336365355fff35dd67d533335d33c6c776dc6dddddd7cc76dd777666d5d666ccc66dddddd51ffff11111111111111111111111112fff11ff658888888888
f5356633773335ff35dd67d533335d33fffffffffffffffff3533f33333ffffffffffffffffffffffff22222222221121212121212124fff5f5f61aaaaaaaaaa
5677663533b36fffffffffffffffffffffffffffffffffff5113535533555355333f3ffffffffffffff24242424241222222222222224fff1ff565aaaaaaaaaa
f661333335565fffffaa777fffcc3fffffffffffffffff355555335555533355533333fffffffffffff44444444441124444211112224fff166651aaaccccccc
ff5555333333533ff9aa5aa7fcc333ffffffffffffff3553333353355353333553333333fffffffffff22222222221229949214442224fff111115aacc77cccc
f55673733333775ff9a585a7cc3ccccfffffffffff55113533333333533533333333353333fffffffff24242424241129949244442224fff11ff61accccc7ccc
553557556733555ff9597e573cc33ccffffffffff5555533333333333335333333333553333ffffffff44444444441229949214452224fff1f5f61ccccc7cccc
ffddb355d3d5bffff9a5c5aa3cc33ccffffff555555555533333333333333333355333553533fffffff22222222221121111244442224fff1ff561ccccccccca
ffffff254ffffffff9aa5aaafccc3cffff5555553333511555333553333333553333333355533ffffff24242424241222222214442224fff166611ccccc7ccaa
fffff22442ffffffff99999fffcccfff55555333335111115553335333333533333333333333335ffff44444444441122222244442224fff111111cccccccaaa
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccc7777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccc777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccc777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccc777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc777777777766677777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc777777cc7777666666666667777777777777777cccccccc7777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc777777cc7777666666666667777777777777777cccccccc7777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc77777777777770000000000000000000000000000000077cc77777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccc7777777777770aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa077777666666ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc666666666666660999999999999999999999999999999990555556666665555566666555556666655555666665555566c665c5c5c6c6c5c5c5c6c6ccc5cccc
cc666666666666660990000999900999900009999000099990555556666665555566666555556666655c556c6c6c5c5c6c6c6c5c5c6ccc6ccccccccccccccccc
ccccdddddddddddd09911110999109991111099911111099905555566666655555666665555566666555556666655555c666c5c5c5c6c6c5c5c5c6ccc5cccccc
cccccccccccccccc0991199109910991119999911199110990555556666665555566666555556666655555666c655c5c6c6c6c5c5c6c6ccc5ccccccccccccccc
cccccccccccccccc0991199119911991199999911999910990555556666665555566666555556666655555666665555566c665c5c5c6c6c5c5c5c6c6ccc5cccc
cccccccccccccccc0991111199911991199999911999911990666665555556666655555666665555566c665c5c5c6c6c5c5c5c6c6c5ccc5ccccccccccccccccc
ccccccccccc00000999111199991199d1199999d11991119990000000000000000000006666655555666665555566666c555c6c6c6c5c5c6c6c6c5ccc6cccccc
cccccccccc0999999991199999911999d1111999d111119999999999999999999999999066665555566666555c566c6c5c5c5c6c6c5c5ccc6ccccccccccccccc
cccccccccc099999999dd999999dd9999dddd9999dddd99999999999999000099999999066665000066666555556666655c556c6c6c5c5c6c6c6c5c5ccc6cccc
cccccccccc0999999999999999999999999999999999999999999999990777709999999066660777706c665c5c5c6c6c5c5c5c6c6c5ccc5ccccccccccccccccc
cccccccccc0444444444444444444444444444444444444444444444440eeee044444440cccc0eeee0cccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccc0000000000000000000000000000000000000000000000c0eeee0c000000ccccc0eeee0cccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccc0000cc0000cc0000cccc0000000000cccccc00000000c0eeee0ccc00000000c0eeee0cccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccc077770077770077770cc077777777770cccc07777777700eeee0cc07777777700eeee0cccccccccccccccccccccccc7777cccccccccccccccccc
cccccccccccc0eeee00eeee00eeee0c00eeeeeeeeee00cc00eeeeeeee00eeee0c00eeeeeeee00eeee0cccccccccccccccccccccc77777777cccccccccccccccc
cccccccccccc0eeee00eeee00eeee00eeeeeeeeeeeeee00eeeeeeeeee00eeee00eeeeeeeeee00eeee0cccccccccccccccccccccc77777777cccccccccccccccc
cccccccccccc0eeee00eeee00eeee00eeeeeeeeeeeeee00eeeeeeeeee00eeee00eeeeeeeeee00eeee0cccccccccccccccccccc77777667777ccccccccccccccc
cccccccccccc0eeee00eeee00eeee00eeee000000eeee00eeee000000c0eeee00eeee00000000eeee0cccccccccccccccc777c7766666677777777cccc77cccc
cccccccccccc0eeee00eeee00eeee00eeee000000eeee00eeee0cccccc0eeee00eeee00000000eeee0cccccccccccccc777777776666666677766677c7777ccc
cccccccccccc0eeeeeeeeeeeeeeee00eeeeeeeeeeeeee00eeee0cccccc0eeee00eeeeeeeeeeeeeeee0cccccccccccccc777777776666666677766677776666cc
cccccccccccc0eeeeeeeeeeeeeeee00eeeeeeeeeeeeee00eeee0cccccc0eeee00eeeeeeeeeeeeeeee0cccccccccccccc777666666666666666666666666ddccc
ccccccccccccc0088888888888800cc00888888888800c088880cccccc088880c00888888888888880cccccccccccccccddddddddddddddddddddddddddccccc
cccccccccccccc08888888888880cccc088888888880cc088880cccccc088880cc0888888888888880cccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccc000000000000cccccc0000000000cccc0000cccccccc0000cccc00000000000000ccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccc00000000000000cccccc000000000000cccccc000000000000cccccc00000000000000cccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc0777777777777770cccc07777777777770cccc07777777777770cccc0777777777777770ccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc07777777777777700cc0077777777777700cc0077777777777700cc00777777777777770ccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc077777777777777770077777777777777770077777777777777770077777777777777770ccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc0aaaaaaaaaaaaaaaa00aaaaaaaaaaaaaaaa00aaaaaaaaaaaaaaaa00aaaaaaaaaaaaaaaa0ccccccccc
cccccccccccccc7ddccccccccccccccccccccccccccccccc000000000000aaaa00aaaa00000000aaaa00aaaa00000000aaaa00aaaa000000000000cccccccccc
cccccccccccccc75dccccccccccccccccccccccccccccccc000000000000aaaa00aaaa0cccccc0aaaa00aaaa0cccccc0aaaa00aaaa00000000cccccccccccccc
cccccccccccccc75dcccccccccccccccccccccccccccccc0aaaaaaaaaaaaaaaa00aaaa0cccccc0aaaa00aaaa0ccccccc0000c0aaaaaaaaaaaa0ccccccccccccc
cccccccccccccc75dcccccccccc55cccdcccccccccccccc0aaaaaaaaaaaaaaaa00aaaa0c000000aaaa00aaaa0cccccccccccc0aaaaaaaaaaaa0ccccccccccccc
ccccccccccccc6d5dccccccccc5551cc5cccccccccccccc0aaaaaaaaaaaaaa00c0aaaa00aaaaaaaaaa00aaaa0cccccccccccc0aaaaaaaaaaaa0ccccccccccccc
ccccccccccccc6555ccdcccccc5111cc56ccccccccccccc0aaaaaaaaaaaaaa0cc0aaaa00aaaaaaaaaa00aaaa0ccccccc0000c0aaaaaaaaaaaa0ccccccccccccc
ccccccccccc51d551115cccccc5151cc55ccccccccccccc0aaaa000000aaaa0cc0aaaa00aaaaaaaaaa00aaaa0cccccc0aaaa00aaaa00000000cccccccccccccc
cccccccdcccd16555111cccccc51116d51ccccccccccccc0aaaa0cccc0aaaa00c0aaaa00aaaaaaaaaa00aaaa00000000aaaa00aaaa000000000000cccccccccc
cccccccddc6d16155111dd6d6551116651ccccccccccccc0aaaa0ccccc00aaaa00aaaa0c000000aaaa00aaaaaaaaaaaaaaaa00aaaaaaaaaaaaaaaa0ccccccccc
cccccddd5c5d1d5551116d6d65515166516cccccccccccc099990cccccc099990099990cccccc099990099999999999999990099999999999999990ccccccccc
ccc5cddd5d1d1d5111116ddd61115166515cccccccccccc099990cccccc099990099990cccccc099990c0099999999999900cc00999999999999990ccccccccc
cc656d5d55151d55511161ddd15111d651166dc6dcccccc099990cccccc099990099990cccccc099990cc09999999999990cccc0999999999999990ccccccccc
c5d5dd5d15151d51511161d1d11151111111ddd66ccccccc0000cccccccc0000cc0000cccccccc0000cccc000000000000cccccc00000000000000cccccccccc
c56dd11d155d1d11511161d1d1111111111dddddd151cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
d565d15d11dd1d11511161d1d5511111111115ddd66d5d6ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
3333333333333333333333333333333333333ddddd66dd6ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
3333333333333333333333333333333333333333333333333333ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc6c6cc
33333333333333333333333333333333333333333333333333333333333333cccccceeeeeeeeeeeeeeeeeeeeeeeeccccccccccccccccccccccccccccddd666cc
33333333333333333333333333333333333333333333333333333333333333300000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeecccccccccccccccd6dd6d666d
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333311111111111000000000000000eeeeeeeee1111eeeecccccccccccccc5d6dddddd6
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333331115555555555555511111111111111000001111dde5eee0000000ddd1dd66665d5dd
3333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333311dd555555555555555555555555555551111eddd1dd50eee0000000001d6666665ddd
3333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbb88811ddddddddddd555555555555555555555dd1111dddd1dd50eeee000000005ddddd6665d
333333333333333333333333333333333333bbbbbbbbbbbb888822111ddddddddddddddddddddddddddddddddddd11111dddddde50eeee0000000d66665666dd
3333333333333333333333333333333333333333333888822888111ddddddddddddddddddddddddddddddddddddd1111ddddd1dde5eeeeee00000566666dd666
33333333333333333333333333333333333337776677667778111ddddddddddddddddddddddddddddddddddddddd1111dddddd1dd55eeeeee00000d66665dd66
3333333333333333333333333333333377766776667777111111dddddddddddddddddddddddddddddddddddddddd111ddddddddddd50eeeeeeeeee866d6ddd6d
33333333333333333333333333366777776667777711111111dddddddddddddddddddddddddddddddddddddddddd1111dddddd515de50eeeeeee88886d665566
333333333333333333333366777777777777711111111111dddddddddddddddddddddddddddddddddddddddddddd1111dddddd5515d55eeeee8808856ddddd6d
33333333333333338887777777777777111111111111111ddddddddddddddddddddddddddddddddddddddddddddd111ddddddd5555de50ee88888885dddddddd
333333333338888888888888887711111111111551111ddddddddddddddddddddddddddddddddddddddddddddddd1111ddddd5555111e5888808888dd6dddddd
3333338888888888888888811111111111155555111555555ddddddddddddddddddddddddddddddddddddddddddd111ddddd5555111188880008888d666ddddd
38888888888888888811111111111155555555eee111111111555555555555555555dddddddddddddddddddddddd111dd55d5511118888000000888dd66ddddd
888888888888881111111111115555555555eeeeeeeeeeeeeee11111111155555555555555dddddddddddddddddd111dd5551111888888000100818dd66d6ddd
8888888881111111111111555555555555eeeeeeeeeeeeeeeeeeeeeeeeeee11111111155555555dddddddddddddd111ddd111188888888000100118dd666d6dd
77881111111111111555555555555555eeeeeeeeeeeeeeeeeee444444444eeeeeeeeeee11111111555555555dddd111d11118888818880000010111ddd6dddd6
111111111111155555555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeee44444444444eeeeeeeeeee111111111555111111888881188880100010111ddd6dd6dd
111111111555555555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee44444444444eeeeeeeeeee11111088888881188880000010111dddd6dd55
1111155555555555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee44eeeeeeeeeeeeeeee88888888888880100d010111ddd6ddd55
55555555555555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88888888888811010dd000111ddddd5555
555555555555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888888881111010dd000110555555555
5555555555555555555eeeeeeee222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8888888888881111101055100115555555555
55555555555555555eeeeeeee2222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee88888888888811111101055100105555555555
555555555555555eeeeeeee2222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee888888888881111111101050100005555555555
5555555555555eeeeeeee2222eeeeeeeee2222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee8808888888811111111001505100005555555555
55555555555eeeeeeee22222eeeeeeee2222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee80008888888111111111001505000055555555555
555555555eeeeeeeeeeeee222222222222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee800008088881111111111001501005555555555555
55555555515eeeeeeeeeeeeeeeee22222eeeeeeeeeeeeeeeeeeeeeeeeee2222eeeeeeeee2eeeeeeeeeeee0000000088111111111111001151055555555555555
55555555151515151eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee2222eeeeeeeee2222eeeeeeeee00000100881111111111111000151555555555555555
55555555515151515151515eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee2222eeeeeeeee2222eeeeeeeee800000100001111111111111000155555555555555555
55555555551515151515151515151eeeeeeeeeeeeeeeeeeeeeeeeeee2222eeeeeeeee2222eeeeeeee88801000100001111111111111000155555555555555555
55555555515151517151515151515151515eeeeeeeeeeeeeeeeeee2222222eeeeee22222eeeeeeee888801000010001111111111110000555555555555555555
55555555551515151767676515151515151515151eeeeeeeeeeeeeeeee2222222222222eeeeeeee8888001000010011111111111100055555555555555555555
5555555555e851515676767694915151515151515151515eeeeeeeeeeeeeeeee22222eeeeeeeee88888001000010011111111110000555555555555555555555
55555555558e8e000067676749491515151515151515151515151eeeeeeeeeeeeeeeeeeeeeeee888888010000010011111111100005555555555555555555555
555555555558e8000000000094945151515151515151515151515151515eeeeeeeeeeeeeeeee888888801000d010011111111000055555555555555555555555
55555555555e8e800000000000000015151515151515151515151515151515151eeeeeeeeee88888810010ddd010011111110000555555555555555555555555
555555555555e8e8e8e0000000000000000051515151515151515151515151515151515eee888888100010ddd010011111100005555555555555555555550555
5555555555558e8e8e8e8e8e00000000000000000015151515151515494515151515151518888888100010dd5010011111000555555555555555555555555555
55555555555528e8e8e8e8e8e8e8e800000000000000000151515151949476765151515158888888100010d50010011100005555555555555555555555555555
5555555555555212121e8e8e8e8e8e8e8e8e00000000000000001515194967676765151515888888100010550010011000055555555555555555555555555555
55555555555551212121212128e8e8e8e8e8e8e8e000000000000000049476767671515151888881100010550510010000555555555555555555555505550555
5555555555555012121212121212128e8e8e8e8e8e8e8e0000000000000000676765151515888881100010555110000005555555555555555555555555555555
555555555555550000012121212121212128e8e8e8e8e8e8e8e00000000000000001515151888881100010005110000555555555555555555555555555555505
55555555555555000000000002121212121212128e8e8e8e8e8e8e8e000000000000000e15888881100115005100005555555555555555555555555555555555
5555555555555500000000000000002121212121212128e8e8e8e8e8e8e8e00000000008e8888881100115001000055555555555555505555555055505550555
555555555555555555500000000000000012121212121212128e8e8e8e8e8e8e8000000e8e888811100115051000555555555555555555555555555555555555
555555555555555555555550000000000000000121212121212121e8e8e8e8e8e8e8e808e8e88111100155551005555555555555555555555505550555055505
55555555555555555555555555550000000000000002121212121212121e8e8e8e8e8e8e8e888111100151551055555555555555555555555555555555555555
0555055505555555555555555555555500000000000000002121212121212128e8e8e8e8e8e88111100111555555555555555555055505550555055505050505
5555555555555555555555555555555555555000000000000000121212121212121e8e8e8e888111100015555555555555555555555555555555555555555555
550555055555555555555555555555555555555550000000000000002121212121212121e8e88111100015555555555555555555555555055505550555055505
55555555555555555555555555555555555555555555500000000000000002121212121212121111000015555555555555555555555555555555555555555555
05050505055505550555055555555555555555555555555555000000000000000121212121211110000055555555555555550555055505550555050505050505
55555555555555555555555555555555555555555555555555555500000000000000001212121100000555555555555555555555555555555555555555555555
05050505050555055505550555055555555555555555555555555555555000000000000000211000055555555555555555555555550555055505550505055505
50555555555555555555555555555555555555555555555555555555555555500000000000000000555555555555555555555555555555555555555555555555
05050505050505050505050505050555055505550555555555555555555555555550000000000005555555550555055505550555050505550505050505050505
55555555555555555555555555555555555555555555555555555555555555555555555500000055555555555555555555555555555555555555555555555555
05050505050505050505050555055505550555055555555555555555555555555555555555550555555555555555555555555505550555055505050555050505
50555055505550555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555055
05050505050505050505050505050505050505050555055505550555555555555555555555555555555505550555055505550505055505050505050505050505
50505550555055505550555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
05050505050505050505050505050505050505050505550555055555555555555555555555555555555555555505550555055505550555050505050505050505
50505050505050505050505550555055505555555555555555555555555555555555555555555555555555555555555555555555555555555555555550555055
00050505050505050505050505050505050505050505050505050555055505550555555505555555055505550555055505050505050505050505050505050505

__map__
554740495c4f0043614951480047464968540e4758627b550e4d626440520e4d614a7c570e46404d45530e435d484c490e4360657960004360647a5f00436163785f024363627a5e024d4a54585a024d575e4b5b024340544152024d5e5c6063024d60627a5d884d5553665e88436063795f814361627a5e8143634a6d501147
504a67520d4d604b6c500d4d4e4a4b4f0d4d564c624a054d4e4b60510d437c59635e01474c4e4e5005437c58635d014d404d585688437c5a635f01437c59635e85437c58635d85437b5a635f85436c505953014369505853a543534b57530143534c57530143524c575101434b50585301434b4e4a4f01434c524d5301434e4c
4e4c0143514b4e4a11435c4a524b014340565c62054340545c60054742504858004d495a41550043554a584a004d5c595e62004757585d62004341575f64004340565f630042585c5c620542595f5b620d42445546580d42445247595543524a524b0e4d4a54595a814749584051b14d5c614c5a814d5d5c62638146665d695e
0746775a7a5b0743695d695d0443775a775a0443685d695e0943785a775b0946665d675e7646795a7a5b7643795c656000437a5b655f004364617b5c88436658695902436158625802436259665a02437555775642437757765702437156745702435f536353044366526a5204434d4a4a4d054354514e5045434c534c530500
284d444a424c014d5b4a5d4c014744495b4e0546474958490e4d584a504b0d4d484a454b0d4d574a5a4b0d4d474a4f4b0d46424d5d55004641505e58004641505e530e41424d5d4f0d41454c5a4c0641444e5b4e064142505c500643444d424f0e435b4d5d4f0e43425140530e435d515f530e4641525e5f004744525b570246
405c5f5d0046405c5f5c0541485c4a5e0d41555c575e0d42485c4a5e0642555c575e064640545f590e46495557580446405a5f5b024642574858024657575d58024642554856084657555d560846465547560746585559560746465747580d46585759580d464b5554580d464d57525805000000000000000000000000000000
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
140400003435036050382403902000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000322302f240312403225034240332303622039040390503905000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
480200001e650226500b250206400a2301c630196200b600096000760007600066000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4c0200091a0301a7201a7201c0301a7301b7201b7301c0301b0300000000000000000000000000043000030000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

