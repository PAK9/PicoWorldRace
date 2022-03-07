-- Profile.lua ---------------------------------------

-- 1. Standing 2. Tokens 3. Time
PlayerProfile = {}

-- note: 1 based in cart memory
function LoadProfile()
  cartdata("pak9_pwr_1")
  for i=1,#LEVELDEF*3 do
    add(PlayerProfile, dget(i))
    assert( PlayerProfile[i] != nil )
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

function EraseProfile()
  for i=0,#PlayerProfile do
    PlayerProfile[i]=0
  end
  SaveProfile()
end

function CountProfileTokens()
  tkns=0
  for i=1,#LEVELDEF do
    tkns+=ReadProfile( i, 2 )
  end
  return tkns
end