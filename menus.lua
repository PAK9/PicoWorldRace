-- Menus.lua ---------------------------------------

-- 1. Title 2. Campaign 3. Custom race
-- (not implemented)
MenuState=1

MenuLvlTokenReq={ 0,0,0,0,0,60,80,120 }

-- 1. Level/Theme 2. Hills 3. Curves 4. Seed
CustomOption=1
CustomLevel=1
-- 1. Low 2. Medium 3. High 4. Extreme
CustomHills=1
-- 1. Low 2. Medium 4. High 4. Extreme
CustomCurves=1
CustomSeed=1

TitleOption=1

CUSTOM_SETSTR={ "low", "medium", "high", "extreme" }

function SetLevel( n )
    Level=n
    Theme=LEVELDEF[Level][1]
end

function RenderFlag( x,y,lvl )
    -- TODO: Stick these sprite defs into a table to save some tokens
    if lvl==1 then
        --usa
        sspr( 118, 69, 10, 7, x, y )
    elseif lvl==2 then
       -- oz
       sspr( 118, 62, 10, 7, x, y )
    elseif lvl==3 then
         --alaska
         sspr( 118, 76, 10, 7, x, y )
    elseif lvl==4 then
        --japan
        sspr( 118, 83, 10, 7, x, y )
    elseif lvl==5 then
        -- kenya
        sspr( 118, 97, 10, 7, x, y )
    elseif lvl==6 then
        -- nepal
        sspr( 118, 90, 10, 7, x, y )
    elseif lvl==7 then
        -- germany
        sspr( 118, 104, 10, 7, x, y )
    elseif lvl==8 then
        -- funland
        sspr( 118, 111, 10, 7, x, y )
    else
        assert( false )
    end
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
    if btnp(0) then -- left
        SetLevel( max(Level-1,1) )
        BuildPreviewTrack()
    elseif btnp(1) then -- right
        SetLevel( min(Level+1,#LEVELDEF) )
        BuildPreviewTrack()
    elseif btnp(4) and CountProfileTokens() >= MenuLvlTokenReq[Level] then -- btn1
        InitRace()
    end
end

function RenderMenu_BG()
    rectfill( 13, 26, 115, 86, 13 )
    rect( 12, 25, 116, 87, 1 )

    -- logo
    sspr( 43, 114, 75, 14, 27, 5 )

    -- car
    sspr( 49, 64, 62, 30, 38, 96 )
end

function RenderMenu_Campaign()

    RenderMenu_BG()    

    -- Country
    RenderFlag( 43, 29, Level )
    RenderTextOutlined( LEVELDEF[Level][6], 56, 30, 0, 7 )

    TotalTkns=CountProfileTokens()
    if TotalTkns >= MenuLvlTokenReq[Level] then
        -- position
        ProfStnd=ReadProfile(Level,1)
        rectfill( 16, 41, 46, 64, 1 )
        sspr( 103, 40, 8, 9, 27, 43 ) -- trophy
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

        -- tokens
        ProfTkns=ReadProfile(Level,2)
        rectfill( 49, 41, 79, 64, 2 )
        sspr( 23, 40, 7, 7, 61, 44 ) -- token
        col=7
        if ProfTkns == 20 then
            BestParticles( 61, 43 )
            rect( 49, 41, 79, 64, 10 )
            col=10
        end
        print( tostr(ProfTkns).."/20", 56, 57, col )

        -- time
        rectfill( 82, 41, 112, 64, 3 )
        sspr( 112, 41, 7, 7, 94, 44 ) -- clock
        PrintTime( ReadProfile(Level,3), 84, 57 )

        --RenderTextOutlined( " \142  race", 38, 70, 1, 6 )
        print( " \142  race", 38, 70, 6 )
    else
        sspr( 39, 75, 8, 11, 30, 44 ) -- lock
        sspr( 39, 75, 8, 11, 91, 44 ) -- lock
        print( "race locked", 43, 48, 9 )

        sspr( 0, 104, 7, 5, 36, 62 ) -- lock
        print( tostr(TotalTkns).."/".. tostr(MenuLvlTokenReq[Level]) .. " tokens", 46, 62, 6 )
    end
    print( "\139\145 country", 38, 77, 6 )

    -- arrows
    xoff=sin(time())*1.2
    if Level < #LEVELDEF then
        sspr( 113, 62, 5, 9, 120+xoff, 49 ) -- arrow
    end
    if Level > 1 then
        sspr( 113, 62, 5, 9, 5-xoff, 49, 5, 9 ,1 ) -- arrow
    end

end

function RenderMenu_Custom()
    RenderMenu_BG()
    RenderTextOutlined( "custom race", 42, 30, 0, 7 )

    -- cursor
    xoff=(flr(time()*3  )%2)
    ypos=33 + CustomOption * 8
    rectfill( 68, ypos-1, 104, ypos+5, 1 )
    sspr( 115, 70, 3, 5, 64-xoff, ypos, 3, 5, 1 )
    sspr( 115, 70, 3, 5, 106+xoff, ypos )

    -- Level/Theme
    print( "country", 29, 41, 6 )
    print( LEVELDEF[CustomLevel][6], 65, 41, 7 )

    -- Hills
    print( "hills", 37, 49, 6 )
    print( CUSTOM_SETSTR[CustomHills], 69, 49, 7 )

    -- Curves
    print( "curves", 33, 57, 6 )
    print( CUSTOM_SETSTR[CustomCurves], 69, 57, 7 )

    -- Seed
    print( "seed", 41, 65, 6 )
    print( CustomSeed, 69, 65, 7 )

    print( " \142 race", 48, 78, 6 )
end

function UpdateMenu_Custom()
    if btnp(0) or btnp(1) then -- left/right
        if btnp(0) then dir=-1 else dir=1 end
        if CustomOption==1 then
            CustomLevel=max(min(CustomLevel+dir,#LEVELDEF),1)
            SetLevel( CustomLevel )
        elseif CustomOption==2 then
            CustomHills=max(min(CustomHills+dir,4),1)
        elseif CustomOption==3 then
            CustomCurves=max(min(CustomCurves+dir,4),1)
        else --if CustomOption==4 then
            CustomSeed=max(min(CustomSeed+dir,100),1)
        end
    elseif btnp(2) then -- up
        CustomOption=max( CustomOption-1, 1 )
    elseif btnp(3) then -- down
        CustomOption=min( CustomOption+1, 4 )
    elseif btnp(4) then -- btn 1
        IsCustomRace=1
        InitRace()
    end
end

function RenderMenu_Title()
    RenderMenu_BG()

    sspr( 111, 76, 7, 7, 15, 37 )
    print( "world tour", 29, 41, 6 )

    sspr( 111, 83, 7, 7, 15, 45 )
    print( "custom race", 29, 49, 6 )

    print( " \142 select", 48, 78, 6 )

end

function UpdateMenu_Title()
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
    PlayerX = 0
    PlayerY = 0
    UpdatePlayer()
    
    MenuState=i
    TitleState=1
    menuitem(1)
    menuitem(2)
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