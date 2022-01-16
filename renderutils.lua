
local BAYER={ 0, 0x0208, 0x0A0A, 0x1A4A, 0x5A5A, 0xDA7A, 0xFAFA, 0xFBFE, 0xFFFF }

function BayerRectT( x1, y1, x2, y2, c1, fact )
    --render a rect with a bayer pattern
    if fact < 1 and fact >= 0 then
        local BAYERT={ 0, 0x0208.8, 0x0A0A.8, 0x1A4A.8, 0x5A5A.8, 0xDA7A.8, 0xFAFA.8, 0xFBFE.8 }
        fillp(BAYERT[flr(1+fact*#BAYERT)])
        rectfill( x1,y1, x2, y2, c1 )
    end
end

function BayerRectV( x1, y1, x2, y2, c1, c2 )
    -- render a vertical bayer dither
    col = bor( c1 << 4, c2 );
    h=y2-y1
    for i = 1,#BAYER do
        fillp(BAYER[i])
        rectfill( flr(x1), flr(y1), flr(x2), flr(y1)+flr(h/#BAYER), col )
        y1 = y1 + h/#BAYER;
    end
end

function BayerRectH( x1, y1, x2, y2, c1, c2 )
    -- render a horizontal bayer dither
    col = bor( c1 << 4, c2 );
    w=x2-x1
    for i = 1,#BAYER do
        fillp(BAYER[i])
        rectfill( flr(x1), flr(y1), flr(x1)+flr(w/#BAYER), flr(y2), col )
        x1 = x1 + w/#BAYER;
    end
end