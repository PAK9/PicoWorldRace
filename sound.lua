
Chan0=-1
Chan1=-1

function UpdateSound()

    if TitleState == 2 then
        if RaceState > 0 then
            UpdateRaceSound()
        end
    end
end

function UpdateRaceSound()
    
    -- channel 0
    -- player
    tgtsnd=-1
    if RecoverStage == 0 and RaceState < 3 then
        if PlayerDrift != 0 then
            tgtsnd=3
        elseif PlayerVl < 0.8 then
            tgtsnd=0
        elseif btn(4)==false then -- z / btn1
            tgtsnd=4
        elseif PlayerVl > 6 then
            tgtsnd=2
        else
            tgtsnd=1
        end
    end
    if Chan0 != tgtsnd then
        if Chan0 != -1 then
            sfx(-1,0)
        end
        if tgtsnd != -1 then
            sfx(tgtsnd,0)
        end
    end
    Chan0=tgtsnd

    -- channel 1
    -- offroad
    tgtsnd=-1
    if RecoverStage == 0 and RaceState < 3 then
        if abs( PlayerX*ROAD_WIDTH ) > ROAD_WIDTH and PlayerVl > 0.5 then
            tgtsnd=5
        end
    end
    if Chan1 != tgtsnd then
        if Chan1 != -1 then
            sfx(-1,1)
        end
        if tgtsnd != -1 then
            sfx(tgtsnd,1)
        end
    end
    Chan1=tgtsnd
end