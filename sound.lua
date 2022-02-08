-- Sound.lua ---------------------------------------

Chan0=-1

function UpdateRaceSound()
    
    -- channel 0
    -- player
    tgtsnd=-1
    if RecoverStage == 0 and RaceState < 3 and TitleState==2 then
        if PlayerDrift != 0 and PlayerAir == 0 then
            tgtsnd=3
        elseif PlayerVl < 0.8 then
            tgtsnd=0
        elseif btn(4)==false then -- z / btn1
            tgtsnd=4
        elseif PlayerAir > 0 then
            tgtsnd=12
        else
            if PlayerVl > 6 then
                tgtsnd=2
            else
                tgtsnd=1
            end
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
    if RecoverStage == 0 and RaceState < 3 and abs( PlayerX*ROAD_WIDTH ) > ROAD_WIDTH and PlayerVl > 0.5 then
        sfx(5,1)
    else
        sfx(-1,1)
    end
end