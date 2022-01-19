-- curve guide: -- y = #segs in/hold/out, x=c
-- T - trivial
-- E - Easy (not constant input)
-- M - medium (constant input)
-- H - hard (just possible at top)
-- D - Drift required
-- X - Not (not possible at top)
 --    1|1.5| 2 |2.5
-- 10  T| M | H | H 
-- 20  E| M | H | D 
-- 30  E| M | D | X 
-- 40  E| M | D | X 

-- 1. SPDEF 2. NumSegs 3. End Y 4. 1Straight/2Curve [5. C InSegs 6. C OutSegs 7. C]
local TRACKSEGDEF = {
    --  Debug track
        {
    --    s  n   y  s/c in out c
        { 3, 40, 00, 1 },
        { 3, 10, 00, 1 },
        },
    --  Track 1
        {
    --    s  n   y  s/c in out c
        { 3, 40, 00, 1 },
        { 3, 10, 20, 2,  20, 20, 0.5 },
        { 3, 10, 17, 1 },
        { 3, 20, 22, 1 },
        { 3, 10, 16, 1 },
        { 1, 20, 52, 2,  10, 20, -1 },
        { 3, 10, 38, 1 },
        { 2, 10, 70, 2,  10, 10, 1.5 },
        { 3, 40, 23, 1 },
        { 3, 10, 100, 2,  30, 30, 0.2 },
        { 3, 10, 150, 2,  20, 30, -0.7 },
        { 3, 20, 90, 1 },
        { 1, 20, 60, 2,  20, 20, -1.6 },
        { 3, 20, 30, 1 },
        { 3, 30, 0, 2,  20, 30, -1.2 },
        { 3, 80, -50, 2,  40, 40, -0.7 },
        { 3, 40, -30, 1 },
        { 3, 40, 00, 1 },
    --  Track 2
        },{
    --    s  n   y s/c in out c
        { 3, 40, 0, 1 },
        }
    }