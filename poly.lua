function polyfill(v,c)	
	if(#v<3) return
	color(c)
	local p0,spans=v[#v],{}
	local x0,y0=p0.x,p0.y
	-- ipairs is slower for small arrays
	for i=1,#v do
		local p1=v[i]
		local x1,y1=p1.x,p1.y
		local _x1,_y1,_v1=x1,y1
		if(y0>y1) x0,y0,x1,y1=x1,y1,x0,y0
		local dx=(x1-x0)/(y1-y0)
		local cy0=y0\1+1
		if(y0<0) x0-=y0*dx y0=0 cy0=0
		-- sub-pix shift
		x0+=(cy0-y0)*dx
		if(y1>127) y1=127
		for y=cy0,y1 do
			local span=spans[y]
			if span then
				rectfill(x0,y,span,y)
			else
				spans[y]=x0
			end
			x0+=dx
		end
		x0,y0=_x1,_y1
	end
end