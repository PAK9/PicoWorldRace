-- Debug.lua ---------------------------------------

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

function ProfileRender()
    if #proftms > 0 then
        
        for i = 1,#proftms do
            RenderTextOutlined( tostr(i)..". ".. tostr(proftms[i]),24,2 + (i-1) * 6, 0, 6 )
            --print(tostr(i)..". ".. tostr(proftms[i]),24,2 + (i-1) * 6, 0, 6 )
            proftms[i]=0
        end
    end
end

function DebugRender()
    fillp(0)
    for i = 1,#DEBUG_PRINT do
        RenderTextOutlined(tostr(DEBUG_PRINT[i]),2,2 + (i-1) * 6, 0,6)
    end
    RenderTextOutlined( flr(stat(1)*100).."%", 98,2,0,6 )
    
    --ProfileRender

end

proftms={0,0,0,0,0,0,0,0}
profstrt={}

function ProfileStart( id )
    profstrt[id]=stat(1)
end

function ProfileEnd( id )
    proftms[id]=proftms[id]+(stat(1)-profstrt[id])
end