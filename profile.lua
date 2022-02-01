
-- 1. Standing 2. Tokens 3. Time
PlayerProfile = {{},{},{},{}}

function LoadProfile()
    cartdata("pak9_pwr_1")
    for i=1,#THEMEDEF do
        for j=1,3 do
            add(PlayerProfile[i], dget((i-1)*3+(j-1)))
        end
    end
end

function SaveProfile()
    for i=1,#THEMEDEF do
        for j=1,3 do
            dset( (i-1)*3+(j-1), PlayerProfile[i][j] )
        end
    end
end