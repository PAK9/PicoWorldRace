-- RenderUtils.lua ---------------------------------------

BAYER =split" 0, 0x0208,   0x0A0A,   0x1A4A,   0x5A5A,   0xDA7A,   0xFAFA,   0xFBFE, 0xFFFF "
BAYERT=split" 0, 0x0208.8, 0x0A0A.8, 0x1A4A.8, 0x5A5A.8, 0xDA7A.8, 0xFAFA.8, 0xFBFE.8 "

opcols1 = split" 12, 11, 10, 9, 8, 6 "
opcols2 = split" 1, 3, 4, 4, 2, 5 "

function BayerRectT( fact, ...)
--render a rect with a bayer pattern
if fact < 1 and fact >= 0 then
  fillp(BAYERT[(1+fact*#BAYERT)\1])
  rectfill( ... )
end
end

function BayerRectV( x1, y1, x2, y2, c1, c2 )
-- render a vertical bayer dither
col = bor( c1 << 4, c2 );
h=y2-y1
for i = 1,#BAYER do
  fillp(BAYER[i])
  rectfill( x1\1, y1\1, x2\1, y1\1+h/#BAYER\1, col )
  y1 += h/#BAYER;
end
end

pd_modes = split"rect,oval,line,map,pal,rectfill,ovalfill,pd_tri,pset,spr,pd_draw,clip,_trifill"
pd_fillp = split"32768, 32736, 24544, 24416, 23392, 23391, 23135, 23131, 6747, 6731, 2635, 2571, 523, 521, 9, 1, 1"


function pd_draw(index,x,y,s_start,s_end,flip_h)

function _trifill(x1,y1,x2,y2,c) --@JadeLombax
  local inc=sgn(y2-y1)
  local fy=y2-y1+inc/2
  for i=inc\2,fy,inc do
    line(x1+.5,y1+i,x1+(x2-x1)*i/fy+.5,y1+i,c)
  end
  line(x1,y1,x2,y2)
end

local l,cmd= #brush[index]

local function _flip(p,f,o,n)
  for i=0,o==0 and 2 or 0,2 do cmd[p+i] = f-cmd[p+i]-o end
  cmd[n] = not cmd[n]
end

camera(%0x5f28-x,%0x5f2a-y)

for i=s_start and s_start or 1, s_end and s_end or l do

cmd={unpack(brush[index][i])}


local s_cmd,px,ox = deli(cmd,1),2,0

if ((s_cmd<=9 or s_cmd==13) and cmd[6]>0) fillp(-pd_fillp[cmd[6]]+.5,x,y)
  if(flip_h and flip_h!=0) _flip(px,flip_h,ox,6)
  _ENV[pd_modes[s_cmd]](unpack(cmd))
  fillp()
end

camera(%0x5f28+x,%0x5f2a+y)

end