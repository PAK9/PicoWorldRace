-- Menus.lua ---------------------------------------

-- 1. Title 2. Campaign 3. Custom race
-- (not implemented)
MenuState=2

MenuLvlTokenReq={ 0,0,0,0,0,60,80,120 }

function RenderFlag( x,y,lvl )
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
        Level=max(Level-1,1)
        Theme=LEVELDEF[Level][1]
        BuildPreviewTrack()
    elseif btnp(1) then -- right
        Level=min(Level+1,#LEVELDEF)
        Theme=LEVELDEF[Level][1]
        BuildPreviewTrack()
    elseif btnp(4) and CountProfileTokens() >= MenuLvlTokenReq[Level] then -- btn1
        InitRace()
    end
end

function RenderMenu_Campaign()

    fillp(0)
    rectfill( 13, 26, 115, 86, 13 )
    rect( 12, 25, 116, 87, 1 )

    -- logo
    sspr( 43, 114, 75, 14, 27, 5 )

    -- car
    sspr( 49, 64, 62, 30, 38, 96 )

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

function RenderMenus()
    if MenuState==2 then
        RenderSky()
        RenderHorizon()
        RenderRoad()
        RenderMenu_Campaign()
        RenderParticles()
    end
end

function OpenMenu( i )
    if i == 2 then
        -- campaign
        BuildPreviewTrack()
        Position = SEG_LEN
        PlayerX = 0
        PlayerY = 0
        UpdatePlayer()
    end
    MenuState=i
    TitleState=1
    menuitem(1)
    menuitem(2)
end

function UpdateMenus()
    if MenuState==2 then
        UpdateMenu_Campaign()
    end
    UpdateParticles()
end