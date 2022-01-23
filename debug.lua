local DEBUG_PRINT = {}
local DEBUG_PRINT_I = 1

function DebugPrint(n)
    DEBUG_PRINT[DEBUG_PRINT_I] = n
    DEBUG_PRINT_I += 1
end

function DebugUpdate()
    DEBUG_PRINT_I = 1
    for i = 1,#DEBUG_PRINT do
        DEBUG_PRINT[i] = "-"
    end
end

function DebugRender()
    for i = 1,#DEBUG_PRINT do
        print(tostr(DEBUG_PRINT[i]),2,2 + (i-1) * 6, 0)
    end
    print( flr(stat(1)*100).."%", 98,2,3 )
    -- print(tostr( flr(stat(0)) ) .."/2048k", 98,10,3 )
end