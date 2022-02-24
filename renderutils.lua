-- RenderUtils.lua ---------------------------------------

BAYER=split" 0, 0x0208, 0x0A0A, 0x1A4A, 0x5A5A, 0xDA7A, 0xFAFA, 0xFBFE, 0xFFFF "

function BayerRectT( x1, y1, x2, y2, c1, fact )
    --render a rect with a bayer pattern
    if fact < 1 and fact >= 0 then
        BAYERT={ 0, 0x0208.8, 0x0A0A.8, 0x1A4A.8, 0x5A5A.8, 0xDA7A.8, 0xFAFA.8, 0xFBFE.8 }
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

pd_modes = split"rect,oval,line,map,pal,rectfill,ovalfill,pd_tri,pset,spr,pd_draw,clip,_trifill"
pd_fillp = split"32768, 32736, 24544, 24416, 23392, 23391, 23135, 23131, 6747, 6731, 2635, 2571, 523, 521, 9, 1, 1"

function pd_draw(index,x,y,s_start,s_end,flip_h)

 local x,y,cmd=x or 0,y or 0

 function _trifill(x1,y1,x2,y2,c) --@JadeLombax
  local inc=sgn(y2-y1)
  local fy=y2-y1+inc/2
  for i=inc\2,fy,inc do
  line(x1+.5,y1+i,x1+(x2-x1)*i/fy+.5,y1+i,c)
  end
  line(x1,y1,x2,y2)
 end

 local function _flip(p,f,o,n)
  if (f==0) return
  for i=0,o==0 and 2 or 0,2 do cmd[p+i] = f-cmd[p+i]-o end
  cmd[n] = not cmd[n]
 end

 camera(%0x5f28-x,%0x5f2a-y)

 for i=s_start and s_start*6-5 or 1, s_end and s_end*6 or #pd_car[index],6 do
  cmd={ord(pd_car[index],i,6)}

  for j=1,5 do cmd[j]-=64 end

  cmd[7]=(cmd[6]&240)>>4
  cmd[6]&=15

  local s_cmd,px,ox,oy = cmd[1],2,0,0

  if (index!= 58 and (s_cmd<=9 or s_cmd==13) and cmd[7]>0) fillp(-pd_fillp[cmd[7]]+.5,x,y)

  if s_cmd!=11 then
   if s_cmd==5 then
    cmd[1] = {unpack(cmd)} cmd[2]=0
   else
    if (s_cmd==10) cmd[8],cmd[7],px,ox,oy = cmd[7]%2==1,cmd[7]\2==1,3,cmd[5]*8-1,cmd[6]*8-1
    if (s_cmd==12) cmd[2]+=x cmd[3]+=y cmd[6]=false cmd[7]=false

    if(flip_h) _flip(px,flip_h,ox,7)
   end
  else
   add(pd_root,i)

   add(cmd,index,2) cmd[7]*=8 cmd[8]*=8

   if(flip_h and flip_h!=0) cmd[6] = 64-cmd[6] cmd[2]-=flip_h

  end

  if (i!= pd_root[#pd_root-1]) deli(cmd,1) _ENV[pd_modes[s_cmd]](unpack(cmd))
  if (index!= 58) fillp()
  --_pal()
 end

 deli(pd_root,#pd_root)
 camera(%0x5f28+x,%0x5f2a+y)
end