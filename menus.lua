
-- 1. Title 2. Campaign 3. Custom race
MenuState=2

function RenderFlag( x,y,lvl )
    if lvl==1 then
        --usa
        sspr( 118, 69, 10, 7, x, y )
    elseif lvl==2 then
        --alaska
        sspr( 118, 76, 10, 7, x, y )
    elseif lvl==3 then
        --japan
        sspr( 118, 83, 10, 7, x, y )
    elseif lvl==4 then
        -- oz
        sspr( 118, 62, 10, 7, x, y )
    elseif lvl==5 then
        -- kenya
        --sspr( 118, 62, 10, 7, x, y )
    elseif lvl==6 then
        -- nepal
        --sspr( 118, 62, 10, 7, x, y )
    elseif lvl==7 then
        -- germany
        --sspr( 118, 62, 10, 7, x, y )
    elseif lvl==8 then
        -- funland
        --sspr( 118, 62, 10, 7, x, y )
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

-- Title
function UpdateMenu_Title()
end

function RenderMenu_Title()
end

-- Campaign
function UpdateMenu_Campaign()
    if btnp(0) then -- left
        Level=(Level-2)%#LEVELDEF+1
        Theme=LEVELDEF[Level][1]
        BuildPreviewTrack()
    elseif btnp(1) then -- right
        Level=Level%#LEVELDEF+1
        Theme=LEVELDEF[Level][1]
        BuildPreviewTrack()
    elseif btnp(4) then -- btn1
        InitRace()
    end
end

function RenderMenu_Campaign()

    fillp(0)
    rectfill( 13, 26, 115, 86, 13 )
    rect( 12, 25, 116, 87, 6 )

    -- logo
    sspr( 23, 101, 75, 14, 27, 5 )

    -- car
    sspr( 49, 64, 62, 30, 38, 96 )

    -- Country
    RenderFlag( 43, 29, Level )
    RenderTextOutlined( LEVELDEF[Level][6], 56, 30, 0, 7 )

    -- position
    rectfill( 16, 41, 46, 64, 1 )
    sspr( 103, 40, 8, 9, 27, 43 ) -- trophy
    ProfStnd=ReadProfile(Level,1)
    if ProfStnd == 0 then
        print( "none", 24, 57, 7 )
    else
        print( tostr(ProfStnd)..tostr( GetStandingSuffix(ProfStnd) ), 26, 57, 7 )
    end

    -- tokens
    rectfill( 49, 41, 79, 64, 2 )
    sspr( 23, 40, 7, 7, 61, 44 ) -- token
    print( tostr(ReadProfile(Level,2)).."/20", 56, 57, 7 )

    -- time
    rectfill( 82, 41, 112, 64, 3 )
    sspr( 112, 41, 7, 7, 94, 44 ) -- clock
    PrintTime( ReadProfile(Level,3), 84, 57 )

    -- controls
    
    RenderTextOutlined( " \142  race", 38, 70, 1, 10 )
    print( "\139\145 country", 38, 77, 6 )

end

-- Custom
function UpdateMenu_Custom()
end

function RenderMenu_Custom()
end

function RenderMenus()
    if MenuState == 1 then
    elseif MenuState==2 then
        RenderSky()
        RenderHorizon()
        RenderRoad()
        RenderMenu_Campaign()
    elseif MenuState==3 then
    end
end

function CloseMenu( i )
    
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
    if MenuState==1 then
        UpdateMenu_Title()
    elseif MenuState==2 then
        UpdateMenu_Campaign()
    elseif MenuState==3 then
        UpdateMenu_Custom()
    end
end