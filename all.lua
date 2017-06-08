-- combozard
-- by martin sandgren

actors = {}
timers = {}
ents = {}
bat_spots = {}

fg_1 = 3+32+64+128

monster_1 = 8 -- ?

player = nil
cam_x = 0
cam_y = 0
track_player = true
slide = 0
shake_screen = 0
shake_x = 0
shake_y = 0

function make_animations()
	ani_pl_idle = ani_still(16)
	ani_pl_walk = ani(8,{16,17})
	ani_pl_jump = ani_still(17)
	ani_slime_walk = ani(12, {9,10})
	ani_bat_sit = ani_still(26)
	ani_bat_fly = ani(8,{27,28})
end

-- entry -----------------------

function _init()
	cls()
	make_animations()
	load_scene()
	music()
end

function _update60()
	timer_step()

	for a in all(actors) do
		if a.upd(a) then
			del(actors, a)
		end
	end

	for g in all(ents) do
		if g.upd(g) then
			del(ents,g)
		end
		g.t += 1
	end
	
	if track_player then
		cam_x = max(0,player.x-63)
		cam_y = 0
	end
	
	for t in all(timers) do
		t.t -= 1
		if t.t <= 0 then
			t.cb()
			del(timers,t)
		end
	end
end

function _draw()

	-- shaking screen fx
	if shake_screen > 0 then

		shake_screen -= 1

		if shake_screen == 0 then
			shake_x = 0
			shake_y = 0
		elseif shr(shake_screen, 2) then
			shake_x = flr(rnd(4)) - 2
			shake_y = flr(rnd(4)) - 2
		end
	end
	camera(
		cam_x + shake_x,
		cam_y + shake_y)

	--cls(12)
	cls(0)

	-- bg
	local bgx = cam_x*0.5+8*grd(0.5*player.x/32)*32 - 32
	map(0,32,bgx,0,32,16)
	if flr(grd(bgx) % 32) > 0 then
		map(0,32,bgx+32*8,0,32,16)
	end

	map(0,0,0,0,256,16, fg_1) --fg
	for a in all(actors) do
		spr(a.spr,a.x,a.y,1,1,a.flipx)
	end
	for g in all(ents) do
		g.draw(g)
	end

	camera(0, 0)

	timer_draw()
	infobox_draw()
	if slide > 0 then
		slide_draw()
	end
end

-- actors ----------------------

function make_actor(x,y,w,h,team,upd)
	local a = {
		alive=true,
		x=x,y=y,dx=0,dy=0,
		w=w,h=h,
		team=team,
		floor=false,
		flipx=false,
		spr=0,
		ani_t=0,
		ani=ani_pl_walk,
		kill=function (a)
			del(actors,a)
		end,upd=upd,spr=0 }
	add(actors,a)
	return a
end

-- collision -------------------

function act_animation(a)
	a.ani_t += 1
	a.spr = ani_get(a.ani,a.ani_t)
	return a.spr
end

function act_gravity(a)
	if a.dy < 2.3 then
		a.dy += 0.12
	end
end

function grd(n)
	return flr(n / 8)
end

function act_move(a)
	local wx,wy
	wx=0
	wy=0
	if (a.dx > 0) wx = a.w
	if (a.dy > 0) wy = a.h
	
	if abs(a.dx) > abs(a.dy) then
		move_x(a,wx)
		move_y(a,wy)
	else
		move_y(a,wy)
		move_x(a,wx)
	end
	
	if (a.dx > 0) a.flipx = false
	if (a.dx < 0) a.flipx = true
end

function move_x(a,wx)
	local x0,x1
	x0 = grd(a.x+wx)
	x1 = grd(a.x+wx+a.dx)
	if x0 != x1 then
		local f0,f1
		f0 = fget(mget(x1,max(0, grd(a.y))),0)
		f1 = fget(mget(x1,max(0, grd(a.y+a.h))),0)
		if f0 or f1 then
			a.dx = 0
		end
	end
	a.x += a.dx
end

function move_y(a,wy)
	local y0,y1
	y0 = grd(a.y+wy)
	y1 = grd(a.y+wy+a.dy)
	if y0 != y1 then
		local m0,m1
		m0 = mget(grd(a.x),y1)
		m1 = mget(grd(a.x+a.w),y1)
		if fget(m0,0) or fget(m1,0) then
			a.dy = 0
			if wy > 0 then
				a.floor = true
			else
				a.floor = false
				a.lifting = 0
			end
			a.y = 8*y0
		else
			a.floor = false
		end
	end
	a.y += a.dy
end

function is_map_mask(x, y, m)
	return fget(mget(grd(x),
			grd(y)), m)
end

function is_in_wall(x,y)
	return is_map_mask(x, y, 0)
end

-- actors ----------------------

function act_trap(a)
	if is_map_mask(
			getcenterx(a),
			getcentery(a),
			1) then
		a.kill(a)
	end
end

function getcenterx(a)
	return a.x + 0.5*a.w
end

function getcentery(a)
	return a.y + 0.5*a.h
end

function act_jump(a,speed)
	a.floor = false
	a.dy = -speed
end

function act_range(a, remove)
	if a.y > 127 then
		a.kill(a)
		if (remove) del(actors,a)
	end
end

function act_infobox(a)
	infobox_isatinfo(a)
end

function act_near_player(a)
	return abs(
		getcenterx(player) -
		getcenterx(a)) < 128
end

function act_wall_ahead(a)
	local tx
	if a.dx > 0 then
		tx = a.x+a.w+1
	elseif a.dx < 0 then
		tx = a.x-1
	else
		tx = getcenterx(a)
	end

	local fl = fget(
		mget(grd(tx),
			grd(getcentery(a))))

	return band(fl, 9) > 0
end

function act_touchdamage(a)
	damage(
		getcenterx(a),
		getcentery(a),
		3, a.team)
end

-- damage ----------------------

function is_touching(x, y, radius, a)
	return
		x+radius > a.x and
		y+radius > a.y and
		x-radius < a.x+a.w and
		y-radius < a.y+a.h
end

-- damage from team
function damage(x, y, radius, team)
	local touched = false
	for a in all(actors) do
		if
				a.team != team and
				a.alive and
				a.team >= 0 then
			if is_touching(
					x, y,
					radius, a) then
				a.kill(a)
				touched = true
			end
		end
	end
	return touched
end

-- jeton -----------------------

function jeton(a)
	local j = gfx_pxl(
		getcenterx(a),
		getcentery(a),
		0, 0, 6)
	j.dx = 1.4
	j.dy = -0.4
	j.t = -40
	if (a.flipx) j.dx = -j.dx
	j.upd = jeton_upd
	j.draw = jeton_draw
	sfx(10)
	return j
end

function jeton_upd(a)
	if (pxl_update(a)) return true

	-- red tail
	if band(shr(a.t+4, 3), 1) == 1 then
		gfx_pixel_spray(
			a.x, a.y,
			a.dx, a.dy,
			2, 8)
	end

	-- yellow tail
	if band(shr(a.t, 3), 1) == 1 then
		gfx_pixel_spray(
			a.x, a.y,
			a.dx, a.dy,
			2, 4)
	end

	if damage(a.x, a.y, 2, 0) then
		gfx_pixel_spray(
			a.x, a.y, 0, 0,
			10, 10)
		return true
	end
end

function jeton_draw(a)
	pxl_draw(a)
end

-- combo -----------------------

combos = {
{{2,4}, function (a) -- salti
	if (not a.salti) return

	a.dy = -2
	a.floor = false
	gfx_pixel_spray_actor(
		player, -1, 4, 3)
	gfx_pixel_spray_actor(
		player, -1, 4, 11)
	sfx(9)

	a.salti = false
end},
{{3,0,4}, jeton }, -- jeton
{{4,2,3,4}, function (a) -- generis
	-- remove old
	if a.generis != nil then
		gfx_pixel_spray_actor(
			a.generis, 0, 10, 2)
		generis_remove(a)
	end

	sfx(12)
	a.generis = true
	a.generis = make_actor(
		a.x, a.y, 7, 7, -1, monster_idle)
	a.generis.spr = 33
	gfx_pixel_spray_actor(
		a.generis, 0, 20, 13)
	gfx_pixel_spray_actor(
		a.generis, 0, 20, 6)
end}
}

function is_combo(pl, combo)
	for i = 1,#combo do
		local kid, cid
		kid = #pl.keyhistory - (i-1)
		cid = #combo - (i-1)
		if pl.keyhistory[kid] != combo[cid] then
			return false
		end
	end
	return true
end

function player_combo(a)
	for combo in all(combos) do
		local keys, cb
		keys = combo[1]
		cb = combo[2]
		if is_combo(a, keys) then
			cb(a)
			a.keyhistory = {}
			return
		end
	end
end

-- player ----------------------

function player_upd(a)

	if not a.alive then
		a.dx = 0
		act_gravity(a)
		act_move(a)
		return
	end

	a.spr = player_spr(a,16)
	a.dx = 0

	if collect_keys(a) then
		player_combo(a)
	end

	if btn(0) then
		a.dx -= 1
		a.walking = true
	elseif btn(1) then
		a.dx += 1
		a.walking = true
	else
		a.walking = false
	end
	
	if a.walking and a.floor then
		set_animation(a,ani_pl_walk)
	elseif a.floor then
		set_animation(a,ani_pl_idle)
	elseif a.walking then
		set_animation(a,ani_pl_idle)
	end
	
	if (a.floor or a.lifting > 0)
			and btn(2) then
		set_animation(a,ani_pl_jump)
		act_jump(a,1.7)
		if a.lifting == 0 then
			a.lifting = 12
			sfx(7)
		else
			a.lifting -= 1
		end
	else
		a.lifting = 0
	end
	act_animation(a)
	act_gravity(a)
	act_move(a)	
	act_trap(a)	
	act_range(a, false)
	act_infobox(a)

	player_spr(a, a.spr)

	if a.floor and not a.salti then
		a.salti = true
	end
	player_combo(a)
end

function player_spr(a, spr)
	if a.grayed then
		a.spr = spr + 4
	else
		a.spr = spr
	end
end

function generis_remove(a)
	del(actors, a.generis)
	a.generis = nil
end

function collect_keys(pl)
	local hasadded = false
	local k
	for key=0,5 do
		if btnp(key) then
			if #pl.keyhistory > 5 then
				del(pl.keyhistory,
					pl.keyhistory[1])
			end
			k = key
			if (key == 1) k = 0
			add(pl.keyhistory, k)
			hasadded = true
		end
	end
	return hasadded
end

-- monsters --------------------

function monster_walker(a)
	if not act_near_player(a) then
	else
		if a.dx == 0 then
			a.dx = a.walkspeed
		end

		if act_wall_ahead(a) then
			a.dx = -a.dx
			act_move(a)
		end
		act_animation(a)
		act_move(a)
		act_gravity(a)
		act_range(a, true)
		act_touchdamage(a)
	end
	return false
end

function monster_bat(a)
	if (not act_near_player(a)) return false

	if a.bat_flytime > 0 then
		a.x += a.dx
		local prog = 1 - a.bat_flytime / a.bat_flytime_tot
		local t2 = 2*prog - 1
		a.y = a.bat_start_y +
			prog*a.bat_flytime_tot*a.dy +
			(1 - t2*t2)*10
		a.bat_flytime -= 1

		if a.bat_flytime <= 0 then
			a.bat_sleep = 50
			a.x = a.link.x
			a.y = a.link.y
			set_animation(a, ani_bat_sit)
		end
	else
		a.bat_sleep -= 1
		if a.bat_sleep <= 0 then
			-- find link closest to player
			local best_dist = 999
			local best = a.link
			for l in all(a.link.links) do
				local d =
					abs(l.x - player.x) +
					abs(l.y - player.y)
				if d < best_dist then
					best = l
					best_dist = d
				end
			end

			bat_set_course(a, best)
		end
	end

	act_animation(a)
	act_touchdamage(a)
	return false
end

function bat_set_course(a, link)
	local dist = abs(link.x - a.x)
	a.bat_flytime = dist / 0.5
	a.bat_flytime_tot = a.bat_flytime
	a.bat_start_y = a.y
	a.link = link
	a.dx = sgn(link.x - a.x) * 0.5
	a.dy = ((link.y - a.y) / dist) * 0.5
	a.flipx = a.dx < 0
	set_animation(a, ani_bat_fly)
	sfx(14)
end

function bat_add_spot(gx, gy)
	local s = {
		x=gx*8,
		y=gy*8,
		links={}
	}
	add(bat_spots, s)
	return s
end

function bat_build_links()
	function is_close(a, b)
		return abs(a.x - b.x) < 8*8
	end

	for a in all(bat_spots) do
		for b in all(bat_spots) do
			if a != b then
				if is_close(a, b) then
					add(a.links, b)
				end
			end
		end
	end
end

monster_updates = {
[8] = function(mk, gx, gy)
	local a = mk()
	set_animation(a,
		ani_slime_walk)
	a.spr = 8
	a.walkspeed = 0.25
	a.upd = monster_walker
	a.kill = function(a)
		sfx(11)
		del(actors,a)
		gfx_pixel_spray_actor(a,
			1, 10, 8)
		gfx_pixel_spray_actor(a,
			1, 10, 4)
	end
end,
[24] = function(mk, gx, gy)
	local a = mk()
	set_animation(a, ani_still(24))
	a.spr = 24
	a.bat_sleep = 20
	a.bat_flytime = 0
	a.bat_flytime_tot = 0
	a.bat_start_y = a.y
	a.upd = monster_bat
	a.link = bat_add_spot(gx, gy)
	set_animation(a, ani_bat_sit)
	a.kill = function(a)
		sfx(16)
		del(actors,a)
		gfx_pixel_spray_actor(a,
			1, 10, 5)
		gfx_pixel_spray_actor(a,
			1, 10, 6)
	end
end,
[25] = function(mk, gx, gy)
	bat_add_spot(gx, gy)
end
}

function monster_idle(a)
end

function make_monster(gx, gy, id)
	local mk = function()
		return make_actor(
			gx*8, gy*8, 7, 7,
			1, nil)
	end
	monster_updates[id](mk, gx, gy)
	return a
end

-- scene -----------------------

function load_scene()
	slide_screen()
	sfx(6)
	timer_restart()

	-- clear lists
	actors = {}
	bat_spots = {}
	ents = {}

	-- look for ai actors
	for y=0,15 do
		for x= 0,256 do
			if fget(mget(x, y), 2) then
				make_monster(x, y,
					mget(x, y))
			end
		end
	end
	bat_build_links()

	player = make_actor(
		2*8,16,
		--49*8,16,
		--99*8,16,
		7,7,0, player_upd)
	player.keyhistory = {0,0,0,0,0}
	player.salti = false
	player.generis = nil
	player.grayed = false
	player.lifting = 0
	player.kill = function()
		player.spr = 32
		player.alive = false
		gfx_pixel_spray_actor(
			player, -1, 20, 2)
		sfx(8)

		if player.generis != nil then
			timer_add(80, function()
				player.x = player.generis.x
				player.y = player.generis.y
				player.dx = 0
				player.dy = 0
				player.alive = true
				generis_remove(player)
				player.grayed = true
				sfx(13)
				shake()
			end)
		else
			timer_add(80,function()
				load_scene()
			end)
		end
	end
end

-- infobox ---------------------

infos = {{
"with the use of spells",
"you shall navigate this",
"world.",
"each spell has a key-",
"combination that must",
"be pressed in the right.",
"order",
" , up and down",
" , left and right",
" (z) action",
},{
"spell \"jeton\"",
"   +  + ",
"         or",
"   +  + ",
"a wizard must be able",
"to defend oneself"
},{
"spell \"salti\"",
"   + ",
"used by the wizards",
"to reach new heights",
"",
"do it mid air"
},{
"spell \"generis\"",
"   +  +  + ",
"never betray a wizard",
"they can come back from",
"the dead"
},{
"       gg ",
"",
"      you'r a wiz.",
"",
"       gg "
}}
infocurrent = 0
inforollout = 0

function infobox_isatinfo(a)
	local mask = fget(mget(
		grd(getcenterx(a)),
		grd(getcentery(a))))
	mask = band(shr(mask, 5), 7)
	if mask > 0 then
		if mask != infocurrent then
			infocurrent = mask

			if mask == 5 then
				timer_stop()
			end
		end
	elseif infocurrent > 0 then
		infocurrent = 0
	end
end

function infobox_draw()
	if inforollout > 0 then
		rectfill(18, 18,
			116,
			22+4*inforollout,
			7)
	end

	if infocurrent == 0 then
		if (inforollout > 0) inforollout -= 1
	else
		if (inforollout < #infos[infocurrent]*2) inforollout += 1
	end

	if (infocurrent == 0) return

	for i = 1, min(
			#infos[infocurrent],
			flr(inforollout / 2)) do
		print(
			infos[infocurrent][i],
			21, 21 + (i-1)*8, 1)
	end
end

-- timers ----------------------

function timer_add(t,cb)
	add(timers,{ t=t,cb=cb })
end

-- gfx -------------------------

function make_entity(x,y,
		upd,draw)
	local e = {
		t=0,dx=0,dy=0,
		sx=x,sy=y,
		x=x,y=y,upd=upd,
		draw=draw }
	add(ents,e)
	return e
end

-- pixel -----------------------

function gfx_pxl(x,y,dx,dy,col)
	local g = make_entity(x,y,
		pxl_update,pxl_draw)
	g.t = flr(rnd(16))
	if col then
		g.col = col
	else
		g.col = 13
	end
	g.dx = (rnd(2)-1)/4
	g.dy = -rnd(1)/4
	if dx and dy then
		g.dx += dx/4
		g.dy += dy/4
	end
	return g
end

function pxl_update(g)
	g.dy += 0.01
	g.x += g.dx
	g.y += g.dy
	return
		is_in_wall(g.x,g.y) or
		g.t >= 32
end

function pxl_draw(g)
	pset(g.x,g.y,g.col)
end

function gfx_pixel_spray(x,y,dx,dy,count,col)
	for i=1,count do
		gfx_pxl(x,y,dx,dy,col)
	end
end

function gfx_pixel_spray_actor(
		a, dir_mul, count, col)
	gfx_pixel_spray(
			a.x+a.w/2,
			a.y+a.h/2,
			dir_mul * a.dx,
			dir_mul * a.dy,
			count, col)
end

-- projectile ------------------

function gfx_proj(x,y,dx,dy)
	return gfx_pxl(x,y,dx,dy,13)
end

-- shake -----------------------

function shake()
	shake_screen = 48
	sfx(15)
end

-- slide screen ----------------

function slide_screen()
	slide = 31
end

function slide_draw()
	local amount = flr(slide / 8)

	for slice = 0, 31 do
		for i = 0, amount do
			memcpy(0x6000 + (slice*4 + i)*64,
				0x4300, 64)
		end
	end


	slide -= 1
end

-- animation -------------------

function ani(steps,arr)
	return {
		steps=steps,
		arr=arr
	}
end

function ani_still(frame)
	return ani(8,{frame})
end

function ani_step(ani)
	ani.t += 1
	if ani.t >= ani.steps then
		ani.t = 0
		i += 1
		if (i > #ani.arr) i = 1
	end
end

function ani_get(ani,t)
	local frame=1+(flr(t/ani.steps) % #ani.arr)
	return ani.arr[frame]
end

function set_animation(
		a,ani)
	if ani != a.ani then
		a.ani_t = 0
		a.ani = ani
	end
end

-- timer -----------------------

timer_on = false
timer_ticks = 0

function timer_restart()
	timer_on = true
	timer_ticks = 0
end

function timer_stop()
	timer_on = false
end

function timer_step()
	if timer_on then timer_ticks += 1 end
end

function timer_draw()
	local elapsed= flr(timer_ticks / 6) / 10

	if timer_on == false then
		rectfill(98, 0, 128, 20, 0)
		print("time:", 101, 0, 7)
		print(elapsed, 101, 6, 7)
		print("secs.", 101, 12, 7)
	end
end

