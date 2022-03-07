------------------ Particle.lua

-- particle definitions
-- 1.sx, 2.sy, 3.sw, 4.sh, 5.life 6.dx 7.dy 8.dsc 9. sc
--     sx  sy  sw sh lif  dx   dy   dsc  sc
PDEF=split([[
67, 24, 5, 5, 0.5, -0.5,0.25, -0.05,  1 /
67, 24, 5, 5, 0.5, 0.5, 0.25, -0.05,  1 /
16, 40, 7, 7, 0.2, 0.15, 0.25,  -0.02, 1.2 /
72, 24, 4, 4, 1,   0.6, -0.5, -0.025, 1 /
68, 30, 4, 4, 1,   -0.6,-0.5, -0.025, 1 /
72, 28, 3, 3, 0.2, -2,  -2,   -0.005, 0.4 /
66, 33, 4, 4, 0.2, 2,   -0.5, -0.005, 0.5 /
72, 32, 4, 4, 0.3, 0.25,-0.5, -0.02, 0.8 /
67, 24, 5, 5, 4,   0.25,-0.5, 0.1, 0.2 /
98, 25, 5, 5, 0.8, 0, -0.01, -0.05, 1 /
98, 25, 5, 5, 0.8, 0, -0.01, -0.05, 1 /
]],"/")

sPartic, sParticT, sParticSc, sParticX, sParticY, NextPartic = {},{},{},{},{},1

function InitParticles()
  for i=1, #PDEF do PDEF[i]=split(PDEF[i]) end
  for i=1,40 do
    sPartic[i] = 0
  end
end

function AddParticle( p, x, y )
  srand( time() )
  sPartic[NextPartic] = p
  sParticT[NextPartic] = time()
  sParticSc[NextPartic] = 1
  sParticX[NextPartic] = x
  sParticY[NextPartic] = y
  NextPartic=(NextPartic+1)%#sPartic+1
end

function ClearParticles()
  for i=1, #sPartic do
    sPartic[i] = 0
  end
end

function UpdateParticles()

  npart=0
  for i=1, #sPartic do
    p = sPartic[i]
    if p != 0 then
      npart = npart + 1
      srand(p)
      sParticSc[i] += ( PDEF[p][8] + (rnd(0.5)) * PDEF[p][8] )
      sParticX[i] += ( PDEF[p][6] + (rnd(0.5)) * PDEF[p][6] )
      sParticY[i] += ( PDEF[p][7] + (rnd(0.5)) * PDEF[p][7] )
      if sParticSc[i] <= 0 or time() - sParticT[i] > PDEF[p][5] then
        sPartic[i] = 0
      end
    end
  end
end

function RenderParticles()
  for i=1, #sPartic do
     p = sPartic[i]
     if p != 0 then
       ssc=sParticSc[i]*10*PDEF[p][9]
       rrect= { sParticX[i] - ssc * 0.5, sParticY[i] - ssc * 0.5, ssc, ssc }
         sspr( PDEF[p][1], PDEF[p][2], PDEF[p][3], PDEF[p][4], rrect[1], rrect[2], rrect[3], rrect[4] )
       end
     end
   end