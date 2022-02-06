
-- 1. Standing 2. Tokens 3. Time
PlayerProfile = {}

-- note: 1 based in cart memory
function LoadProfile()
    cartdata("pak9_pwr_1")
    for i=1,#LEVELDEF*3 do
        add(PlayerProfile, dget(i))
        assert( PlayerProfile[i] != nil )    
        --if PlayerProfile[i] == nil then
          --      PlayerProfile[i] = 0
            --end
        --end
    end
end

function SaveProfile()
    for i=1,#PlayerProfile do
        dset( i, PlayerProfile[i] )
    end
end

function ReadProfile( lvl, id )
    idx=(lvl-1)*3+id
    return PlayerProfile[idx]
end

function WriteProfile( lvl, id, val )
    idx=(lvl-1)*3+id
    PlayerProfile[idx]=val
    SaveProfile()
end