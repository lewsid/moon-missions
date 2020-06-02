pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- mun lander alpha.0.3
-- by lewsid

ground = 110
death_points = {}
ground_lines = {}
stars = {}
frame = 0
seconds = 0
ship = {}
gravity = .02
thrust = .15

function _init()
	gen_ground()
	gen_stars()
	gen_ship(58, 10, 0, .2)
end

function _draw()
	cls(1)

	draw_ground()
	draw_ship(ship)
	foreach(stars, draw_star)

	--clock upkeep
	seconds = frame / 30
	frame = frame + 1
	
	print("fuel: " .. ship.fuel,13)
	print("speed: " .. ship.speed,13)
end

function _update()
	ship.speed = flr((ship.dy * 100)/5)

	control_ship(ship)
	move_ship(ship)
end

function control_ship(ship)
	--if we are still above ground
	if(above_ground(ship)) then
		--left
		if (btn(0) and ship.fuel > 0) then
			ship.dx -= thrust
			ship.fuel -= 1
			sfx(0)
			if (ship.right_sprite == 19 or ship.right_sprite == 22) then 
				ship.right_sprite = 23
			else
				ship.right_sprite = 22
			end 
		else
			ship.right_sprite = 19
		end

		--right
		if (btn(1) and ship.fuel > 0) then
			ship.dx += thrust
			ship.fuel -= 1
			sfx(0)

			if (ship.left_sprite == 19 or ship.left_sprite == 20) then 
				ship.left_sprite = 21
			else
				ship.left_sprite = 20
			end
		else
			ship.left_sprite = 19
		end

		--up
		if (btn(2) and ship.fuel > 0) then
			ship.dy -= thrust
			ship.up_sprite = 4 + rnd(2)
			ship.fuel -= 1
			sfx(0)
		else
			ship.up_sprite = 3
		end
	else
		ship.dx = 0
	end
end

function move_ship(ship)
	ship.x += ship.dx

	--loop the edges
	if (ship.x > 128) then
		ship.x = 0
	elseif (ship.x < 0) then
		ship.x = 128
	end

	--if the ship is above ground, move it
	if(above_ground(ship)) then
		ship.dy += gravity
		ship.y += ship.dy
	else
		--we are coming in too hot
		if(ship.speed > 10 and ship.alive == 1) then
			ship.alive = 0
			ship.sprite = 18
			ship.left_sprite = 19
			ship.right_sprite = 19
			ship.up_sprite = 3
			sfx(1)
		end
	end

	return ship
end

function above_ground(ship)
	if(#death_points > 1 and
		flr(ship.x+ship.width)<=#death_points) then
		for x=flr(ship.x),flr(ship.x)+ship.width do
			if(flr(ship.y)+ship.height > death_points[x]) then
				return false
			end
		end
	end

	return true
end

function draw_ground()
	for i=1,#ground_lines - 1 do
		for j=0, 28 do
			line(ground_lines[i].x, ground_lines[i].y + j, ground_lines[i+1].x, ground_lines[i+1].y + j, 7)
		end
		line(ground_lines[i].x, ground_lines[i].y, ground_lines[i+1].x, ground_lines[i+1].y, 7)
		line(ground_lines[i].x, ground_lines[i].y, ground_lines[i].x, 128, 7)
	end	
	
	--search for and store the tops
	for x=0,128 do
		for y=100,128 do
			if(pget(x,y) == 7) then
				death_points[x]=y
				break --stop at the top
			end
		end
	end
	
	--highlight the death line
	for i=1, #death_points do
		pset(i,death_points[i],13)
	end
		
	line(0, 127, 127, 127, 7)
end

function draw_ship(ship)
	if(ship.alive == 0) then
		if(ship.sprite == 18) then
			ship.sprite = 17
		else 
			ship.sprite = 18
		end
	end

	--ship
	spr(ship.sprite, ship.x, ship.y)

	--thrust
	spr(ship.up_sprite, ship.x, ship.y + 8)
	spr(ship.left_sprite, ship.x - 2, ship.y)
	spr(ship.right_sprite, ship.x + 2, ship.y)
end

function draw_star(star)
	--draw star if nothing else is there
	if(pget(star.x, star.y) != 7) then
		pset(star.x, star.y, 6)
	end
end

function gen_ground()
	last_edge = 0
	pos = 1

	while (last_edge < 128) do
		new_edge = 0
		new_top = 100 + rnd(28)

		if(pos > 1) then
			new_edge = last_edge + rnd(25)
		end

		ground_lines[pos] = { x = new_edge, y = new_top }
		last_edge = new_edge
		pos+=1
	end

end

function gen_stars()
	for i=0,50 do
		star = { x = rnd(129), y = rnd(115), sprite = 6 + flr(rnd(2)) }

		add(stars, star)
	end
end

function gen_ship(start_x, start_y, start_dx, start_dy)
	--up_sprite: 3 = off, 4 = on, 5 = on-alt
	--left_sprite: 19 = off, 20 = on, 21 = on-alt
	--right_sprite: 19 = off, 22 = on, 23 = on-alt

	ship = 
	{
		sprite = 1,
		x = start_x,
		y = start_y,
		dx = start_dx,
		dy = start_dy,
		height = 8,
		width = 8,
		up_sprite = 3,
		left_sprite = 19,
		speed = 0,
		fuel = 50,
		alive = 1,
		right_sprite = 19
	}

	return ship
end

__gfx__
00000000000000000009a00000000000000aa000000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000005500000a00a000000000009a99a900a9aa9a000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700005665000000000000000000009aa90000a99a0000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700005666650000000000000000000099000000aa00000006000000070000000000000000000000000000000000000000000000000000000000000000000
00077000056cc6500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700566666650000000000000000000000000000000000000000000000000065660000000000000000000000000000000000000000000000000000000000
00000000565665650000000000000000000000000000000000000000000000000656566000000000000000000000000000000000000000000000000000000000
00000000666556660000000000000000000000000000000000000000000000006565665600000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000055000000000000000000000000000000000000000
00000000000a00000000000000000000000000000000000000000000000000000000000000000000000000566500000000000000000000000000000000000000
0000000000a90000000a00000000000090000000a0000000000000090000000a0000000000000000000005666650000000000000000000000000000000000000
00000000009a600000a9600000000000a90000009a0000000000009a000000a900000000000000000000056cc650000000000000000000000000000000000000
000000000066060000660600000000009a000000a9000000000000a90000009a0000000000000000000056666665000000000000000000000000000000000000
00000000060666000606660000000000a0000000900000000000000a000000090000000000000000000056566565000000000000000000000000000000000000
000000000a6ccc90096ccca000000000000000000000000000000000000000000000000000000000000566655666500000000000000000000000000000000000
0000000095c6555aa5c6555900000000000000000000000000000000000000000000000000000000000555500555500000000000000000000000000000000000
__sfx__
00010000025500c5500355012550025500f5500655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005000000000276200962007610286100861006610026300160006600066001a5001a5001a5001a5001a5001a5001a5000060000600006000060000600016000260000600000000000000000000000000000000
