-- sprite definitions (the bottom of the sprite should be on the ground)
-- 1.sx, 2.sy, 3.sw, 4.sh, 5.scalemin, 6.scalemax, 7.flip, 8.collidable
SDEF = { 
    { 48, 24, 8, 8, 1.4, 1.4, 0, 1 }, -- 1. chevron r (orange)
    { 48, 24, 8, 8, 1.4, 1.4, 1, 1 }, -- 2. chevron l (orange)
    { 57, 35, 7, 5, 0.4, 0.6, 0, 0 }, -- 3. grass
    { 56, 24, 10, 11, 2.5, 4.5, 0, 1 }, -- 4. tree
    { 48, 32, 8, 8, 0.5, 2, 0, 0 }, -- 5. shrub
    { 0, 40, 16, 11, 4, 4, 0, 1 }, -- 6. bilboard
    { 0, 0, 32, 24, 1, 1, 0, 0 }, -- 7. opponent car
    { 36, 0, 36, 24, 1, 1, 0, 0 }, -- 8. opponent car l
    { 36, 0, 36, 24, 1, 1, 1, 0 }, -- 9. opponent car r
    { 23, 40, 7, 7, 1, 1, 0, 0 }, -- 10. token
    { 122, 25, 6, 6, 1, 1, 0, 1 }, -- 11. gantry section
    { 103, 25, 18, 15, 1, 1, 0, 0 }, -- 12. start/end banner left
    { 103, 25, 18, 15, 1, 1, 1, 0 }, -- 13. start/end banner right
    { 30, 40, 5, 11, 0.6, 0.6, 0, 1 }, -- 14. warn sign
    { 35, 40, 5, 11, 0.6, 0.6, 0, 1 }, -- 15. diamond sign
    { 40, 40, 5, 11, 0.6, 0.6, 0, 1 }, -- 16. diamond sign back
    { 45, 40, 12, 8, 1.2, 1.2, 0, 1 }, -- 17. chevron r (red)
    { 45, 40, 12, 8, 1.2, 1.2, 1, 1 }, -- 18. chevron l (red)
    { 57, 40, 8, 23, 1, 1, 0, 1 }, -- 19. jap flag l
    { 57, 40, 8, 23, 1, 1, 1, 1 }, -- 20. jap flag r
    { 65, 40, 10, 13, 1.8, 3, 0, 1 }, -- 21. sakura tree
    { 65, 53, 20, 6, 3, 3, 0, 1 }, -- 22. distant building
    { 75, 46, 4, 7, 0.6, 0.6, 0, 1 }, -- 23. jap lantern
}
-- sprite pattern definitions
-- when conflict first is used
-- 1. SDEF, 2. interval, 3. interval offset, 4. minx (*roadw), 5. maxx (*roadw), 6. rand l/r
SPDEF = {
    { { 1, 4, 0, -1.6, -1.6, 0 }, { 4, 2,0, 2, 8, 1 }, { 3, 1,0, 1.5, 2, 1 }  }, --  1. <green> chevron r, trees, grass
    { { 2, 4,0, 1.6, 1.6, 0 }, { 4, 2,0, 2, 8, 1 }, { 3, 1,0, 1.5, 2, 1 }  }, --  2. <green> chevron l, trees, grass
    { { 4, 2,0, 1.5, 8, 1 }, { 5, 3,0, 2, 4, 1 }, { 3, 1,0, 1.4, 3, 1 } }, -- 3. <green> trees, shrubs, grass
    { { 6, 18,0, 2, 2, 0 }, { 4, 2,0,  1.5, 8, 1 }, { 5, 3,0, 2, 4, 1 }, { 3, 1,0, 1.4, 3, 1 } }, -- 4. <green> billboard, trees, shrubs, grass
    { { 19, 6, 0, 1.05, 1.1, 0 }, { 20, 6, 1, -1.08, -1.15, 0 } }, -- 5. <jap> flag
    { { 21, 5, 0, 1.5, 6, 1 },  { 5, 5, 0, 2, 4, 1 }, { 3, 1,0, 1.4, 3, 1 } }, -- 6. <jap> trees, shrubs, grass
    { { 17, 6, 0, -1.6, -1.6, 0 }, { 21, 2, 0, 1.2, 8, 1 }, { 3, 1,0, 1.5, 2, 1 }  }, --  7. <jap> chevron r, trees, grass
    { { 18, 6, 0, 1.6, 1.6, 0 }, { 21, 2, 0, 1.2, 8, 1 }, { 3, 1,0, 1.5, 2, 1 }  }, --  8. <jap> chevron l, trees, grass
    { { 14, 2, 0, -1.1, -1.1, 0 }  }, --  9. warning sign l
    { { 14, 2, 0, 1.1, 1.1, 0 }  }, --  10. warning sign r
    { { 15, 8, 0,-1.1,-1.1, 0 }, { 16, 8, 1, 1.1, 1.1, 0 }, { 5, 5, 0, 2, 4, 1 }  }, --  11. diamond sign l
    { { 16, 2, 0, 1.1, 1.1, 0 }, { 15, 2, 1, -1.1, -1.1, 0 }  }, --  12. diamond sign r
    { { 22, 8, 0, 4, 6, 1 }, { 21, 3, 0, 1.5, 6, 1 } }, -- 13. <jap> buildings (x2), trees
    { { 23, 6, 0, 1.2, 1.2, 0 }, { 23, 6, 2, -1.2, -1.2, 0 }, { 21, 7, 0, 1.5, 6, 1 }, { 3, 1,0, 1.5, 5, 1 } }, -- 14. <jap> lantern (x2), grass
    { { 19, 8, 0, 1.02, 1.02, 0 }, { 5, 5, 0, 2, 4, 1 } }, -- 15. <jap> flag right only
    { { 20, 8, 0, -1.02, -1.02, 0 }, { 5, 5, 0, 2, 4, 1 } }, -- 16. <jap> flag left only
}

-- Sprite pattern theme def
-- 1. Left turn SPDEF 2. Right turn SPDEF 3...n SPDEF  
SPTHMDEF = {
    { 2, 1, 3 }, -- Green raceway
    { 2, 1, 3 }, -- Snowy
    { 8, 7, 5, 6, 13, 14, 15, 16 }, -- Japan
    { 2, 1, 3 }, -- Red desert
}
