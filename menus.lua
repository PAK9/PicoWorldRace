-- Menus.lua ---------------------------------------

-- 1. Title 2. Campaign 3. Custom race
MenuState,TitleOption=1,1

MenuLvlTokenReq=split"0,0,0,0,0,60,80,120"

-- 1. Level/Theme 2. Hills 3. Curves 4. Seed
CustomOption,CustomLevel=1,1

-- 1. Low 2. Medium 3. High 4. Extreme
CustomHills=1

-- 1. Low 2. Medium 4. High 4. Extreme
CustomCurves,CustomSeed=1,1

CUSTOM_SETSTR=split"low,medium,high,extreme"

function SetLevel( n )
  Level=n
  Theme=LEVELDEF[Level][1]
  BuildPreviewTrack()
end

function RenderFlag( x,y,lvl )
  -- flattened x,y pairs (top left of sprite)
  FLAGDEF=split"79, 72, 86, 93, 107, 100, 114, 121"
  sspr( 118,FLAGDEF[lvl], 10, 7, x, y )
end

function RenderTextOutlined( str, x, y, ocol, incol )
print( str, x-1,y, ocol )
print( str, x+1,y, ocol )
print( str, x,y-1, ocol )
print( str, x,y+1, ocol )
print( str, x,y, incol )
end

function PrintTime( secs,x,y )
mins=flr(secs/60)
secs=flr(secs%60)
if secs > 9 then
  secstr=tostr(secs)
else
  secstr="0"..tostr(secs)
end
hnd=flr(secs%1*100)
if hnd > 9 then
  hndstr=tostr(hnd)
else
  hndstr="0"..tostr(hnd)
end
print( tostr( mins )..":".. secstr.."."..hndstr , x, y, 7 )
end

function BestParticles( x, y )

srand(Frame+x)
if (Frame+x)%60==0 then
  AddParticle( 10, x+rnd(8), y+rnd(5) )
end
end

-- Campaign
function UpdateMenu_Campaign()
if btnp(⬅️) then
  SetLevel( max(Level-1,1) )
elseif btnp(➡️) then
  SetLevel( min(Level+1,#LEVELDEF) )
elseif btnp(🅾️) and CountProfileTokens() >= MenuLvlTokenReq[Level] then
  InitRace()
elseif btn(❎) then
  OpenMenu(1)
end
end

function RenderMenu_BG( y, h )
rectfill( 13, y, 115, h, 13 )
rect( 12, y-1, 116, h+1, 1 )

-- logo
sspr(unpack(split"33, 57, 56, 14, 27, 5"))
sspr(unpack(split"89, 61, 19, 10, 83, 9"))

-- car
pd_draw(0,38,88)
end

function RenderMenu_Campaign()

RenderMenu_BG(25,92)
-- Country
RenderFlag( 43, 29, Level )
RenderTextOutlined( LEVELDEF[Level][6], 56, 30, 0, 7 )

TotalTkns=CountProfileTokens()
if TotalTkns >= MenuLvlTokenReq[Level] then
  -- position
  ProfStnd=ReadProfile(Level,1)
  rectfill( 16, 41, 46, 64, 1 )
  sspr(unpack(split"65, 49, 8, 8, 27, 43")) -- trophy
  col=7
  if ProfStnd == 1 then
    BestParticles( 27, 43 )
    rect( 16, 41, 46, 64, 10 )
    col=10
  end

  if ProfStnd == 0 then
    print( "none", 24, 57, 7 )
  else
    print( tostr(ProfStnd)..tostr( GetStandingSuffix(ProfStnd) ), 26, 57, col )
  end

  ProfTkns=ReadProfile(Level,2)
  rectfill( 49, 41, 79, 64, 2 )
  sspr(unpack(split"17, 121, 7, 7, 61, 44")) -- token
  col=7
  if ProfTkns == 20 then
    BestParticles( 61, 43 )
    rect( 49, 41, 79, 64, 10 )
    col=10
  end
  print( tostr(ProfTkns).."/20", 56, 57, col )

  rectfill( 82, 41, 112, 64, 3 )
  sspr(unpack(split"73, 50, 7, 7, 94, 44")) -- clock
  PrintTime( ReadProfile(Level,3), 84, 57 )

  print( " \142  race", 38, 70, 6 )
else
  sspr(unpack(split"120, 34, 8, 11, 30, 44")) -- lock
  sspr(unpack(split"120, 34, 8, 11, 91, 44")) -- lock
  print( "race locked", 43, 48, 9 )

  sspr(unpack(split"17, 121, 7, 7, 36, 61")) -- token
  print( tostr(TotalTkns).."/".. tostr(MenuLvlTokenReq[Level]) .. " tokens", 46, 62, 6 )
end
print( "\139\145 country", 38, 77, 6 )
print( "\151  back", 42, 84, 6 )

-- arrows
xoff=sin(time())*1.2
if Level < #LEVELDEF then
  sspr( 113, 80, 5, 7, 120+xoff, 49 ) -- arrow
end
if Level > 1 then
  sspr( 113, 80, 5, 7, 5-xoff, 49, 5, 7 ,1 ) -- arrow
end

end

function RenderMenu_Custom()
RenderMenu_BG(24,92)
RenderTextOutlined( "custom race", 42, 29, 0, 7 )

-- cursor
xoff=(flr(time()*3  )%2)
ypos=32 + CustomOption * 8
rectfill( 68, ypos-1, 104, ypos+5, 1 )
sspr( 113, 75, 3, 5, 64-xoff, ypos, 3, 5, 1 )
sspr( 113, 75, 3, 5, 106+xoff, ypos )

-- Level/Theme
print( "country", 29, 40, 6 )
print( LEVELDEF[CustomLevel][6], 65, 40, 7 )
print( "hills", 37, 48, 6 )
print( CUSTOM_SETSTR[CustomHills], 69, 48, 7 )
print( "curves", 33, 56, 6 )
print( CUSTOM_SETSTR[CustomCurves], 69, 56, 7 )
print( "seed", 41, 64, 6 )
print( CustomSeed, 69, 64, 7 )
print( " \142 race", 44, 76, 6 )
print( " \151 back", 44, 83, 6 )
end

function UpdateMenu_Custom()
if btnp(⬅️) or btnp(➡️) then -- left/right
  if btnp(⬅️) then dir=-1 else dir=1 end
  if CustomOption==1 then
    CustomLevel=max(min(CustomLevel+dir,#LEVELDEF),1)
    TotalTkns=CountProfileTokens()
    if TotalTkns < MenuLvlTokenReq[CustomLevel] then
      CustomLevel-=1
    end
    SetLevel( CustomLevel )
  elseif CustomOption==2 then
    CustomHills=max(min(CustomHills+dir,4),1)
  elseif CustomOption==3 then
    CustomCurves=max(min(CustomCurves+dir,4),1)
  else --if CustomOption==4 then
    CustomSeed=max(min(CustomSeed+dir,100),1)
  end
elseif btnp(❎) then
  OpenMenu(1)
elseif btnp(⬆️) then
  CustomOption=max( CustomOption-1, 1 )
elseif btnp(⬇️) then
  CustomOption=min( CustomOption+1, 4 )
elseif btnp(🅾️) then
  IsCustomRace=1
  InitRace()
end
end

function RenderMenu_Title()
RenderMenu_BG(33,62)

ypos=31 + TitleOption * 10
rectfill( 30, ypos-2, 96, ypos+6, 1 )

sspr(unpack(split"24, 121, 7, 7, 35, 40")) --globe
print( "world tour", 48, 41, 7 )

sspr(unpack(split"33, 49, 7, 7, 35, 50")) --gear
print( "custom race", 48, 51, 7 )

RenderTextOutlined( "a game by pak-9", 35, 70, 0,6 )
RenderTextOutlined( "thx theroboz", 40, 80, 0,6 )
end

function UpdateMenu_Title()
if btnp(⬆️) then
  TitleOption=1
elseif btnp(⬇️) then
  TitleOption=2
elseif btnp(🅾️) then
  OpenMenu(TitleOption+1)
end
end

function RenderMenus()

RenderSky()
RenderHorizon()
RenderRoad()
fillp(0)
if MenuState==1 then
  RenderMenu_Title()
elseif MenuState==2 then
  RenderMenu_Campaign()
elseif MenuState==3 then
  RenderMenu_Custom()
end
RenderParticles()
end

function OpenMenu( i )

BuildPreviewTrack()
Position = SEG_LEN
PlayerX, PlayerY = 0,0
UpdatePlayer()

MenuState,TitleState=i,1

menuitem(1)
menuitem(2)
if MenuState==3 then
  SetLevel(CustomLevel)
end
end

function UpdateMenus()
if MenuState==1 then
  UpdateMenu_Title()
elseif MenuState==2 then
  UpdateMenu_Campaign()
elseif MenuState==3 then
  UpdateMenu_Custom()
end
UpdateParticles()
end