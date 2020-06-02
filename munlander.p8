pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- mun lander alpha.0.6
-- by lewsidboi, 2020

--game parameters
start_fuel=100
base_ground=110
frame=0
seconds=0
gravity=.02
thrust=.15
start_x=58
start_y=10
last_edge=0
game=nil

--tables
ship={}
death_points={}
ground_lines={}
cam={}
stars={}
pad={}
flag={sprite=2,drop_sprite=7}
banner={good=11,bad=8,left=0,right=128}

function _init()
	init_ship(start_x,start_y,0,.2)
 init_pad(128,80)
 init_ground()
 init_stars()
end

function _draw()
	cls()

	draw_pad()
	draw_ground()
	draw_ship()
	
	foreach(stars, draw_star)
	
 draw_ui()
end

function _update()
	--clock upkeep
	seconds=frame/30
	frame=frame+1

 init_ground()
 init_stars()
 
	ship.speed=flr((ship.dy*100)/5)

	control_ship()
	move_ship()
	check_end()
end
-->8
--inits

function init_pad(base_x,base_y)
	pad=
	{
		sprite=8,
		width=16,
		height=16,
		surface=12,
		x=rnd(128)+base_x,
		y=rnd(10)+base_y,
	}
end

function init_ship()
	--up_sprite: 3 = off, 4 = on, 5 = on-alt
	--left_sprite: 19 = off, 20 = on, 21 = on-alt
	--right_sprite: 19 = off, 22 = on, 23 = on-alt

	ship= 
	{
		sprite=1,
		drop_sprite=6,
		x=start_x,
		y=start_y,
		dx=0,
		dy=0,
		height=8,
		width=8,
		up_sprite=3,
		left_sprite=19,
		right_sprite=19,
		speed=0,
		fuel=start_fuel,
		alive=1
	}
	
	cam={x=0}
	
	game="started"

	return ship
end

function init_ground()
	distance=128
	distance+=ship.x+128
	
	while (last_edge<distance) do
		new_edge=0
		new_top=base_ground+rnd(128-base_ground)

		if(#ground_lines>0) then
			new_edge=last_edge+rnd(25)
		end
		
		--check for the pad
		if(new_edge>=pad.x-8 and
		 new_edge<=pad.x+pad.width) then
	 	new_edge=pad.x
	 	new_top=pad.y+pad.height
	 	add(ground_lines,{x=pad.x,
				y=new_top })
			add(ground_lines,{x=pad.x+pad.width,
				y=new_top })
			last_edge=pad.x+pad.height
	 else
	 	--go nuts
			add(ground_lines,{x=new_edge,
				y=new_top })
			last_edge=new_edge
		end
	end
end

function init_stars()
  screen=flr(cam.x/128)
  if(#stars<60*screen+1) then
  	for i=1,60 do
  	 --place stars up to one 
  	 --screen away so we don't 
  	 --see them spawn in
				star={
					x=rnd(screen+1*256)+screen*256,
					y=rnd(base_ground)
				}
		 	add(stars,star)
			end
	 end
end

-->8
--updates

function control_ship()
	--if we are still above ground
	if(above_ground(ship) and
		not on_pad()) then
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
		if (btn(1) and ship.fuel>0) then
			ship.dx+=thrust
			ship.fuel-=1
			sfx(0)

			if (ship.left_sprite==19 
				or ship.left_sprite==20) then 
				ship.left_sprite=21
			else
				ship.left_sprite=20
			end
		else
			ship.left_sprite=19
		end

		--up
		if (btn(2) and ship.fuel>0) then
			ship.dy-=thrust
			ship.up_sprite=4+rnd(2)
			ship.fuel-=1
			sfx(0)
		else
			ship.up_sprite = 3
		end
	else
		ship.dx = 0
	end
end

function move_ship()
	if(game=="started") then
		ship.x+=ship.dx
	end
		
	--if the ship is above ground,
	--move it
	if(above_ground() 
		and not on_pad()) then
		ship.dy+=gravity
		ship.y+=ship.dy
	else
		--we are coming in too hot
		if(ship.speed>10 
			and ship.alive==1) then
			ship.alive=0
			ship.sprite=18
			reset_thrust()
			sfx(1)
			game="over-bad"
		elseif(ship.alive==1
		 and game=="started"
		 and on_pad()) then
		 --we landed, but not on the pad
			reset_thrust()
			sfx(2)
			game="over-good"
		elseif(ship.alive==1
			and game=="started"
			and not on_pad()) then
			reset_thrust()
		 sfx(2)
		 game="over-okay"
		end
	end
	
	if(ship.x>=start_x) then
		--update camera position
		cam.x=-start_x+ship.x
	end
	return ship
end

function reset_thrust()
	ship.left_sprite=19
	ship.right_sprite=19
	ship.up_sprite=3
end

function above_ground()
 if(ship.x<cam.x) then
  --ship is off screen
  if(flr(ship.y)+ship.height>base_ground) then
  	return false
  end
 elseif(#death_points>1 and
		flr(ship.x+ship.width)<=#death_points) then
		for x=flr(ship.x),flr(ship.x)+ship.width do
			if(x>0) then
				if(flr(ship.y)+ship.height>death_points[x]) then
					--if any part of the ship
					--touches a death line
					return false
				end
			end
		end
	end

	return true
end

function check_end()
	
end

function on_pad()
	if(ship.x>=pad.x and
		ship.x<=pad.x+pad.width
		and flr(ship.y)>=pad.y+3)
		then
		return true
	end
	return false
end
-->8
--draws

function draw_ui()
	print("fuel: "..ship.fuel,cam.x,0,13)
	--print("speed: "..ship.speed,cam.x,7,13)
 --print("game: "..game,cam.x,14,13)

	if(game=="over-good") then
 	draw_banner(banner.good,
			"mission accomplished",25)
	elseif(game=="over-bad" or
		game=="over-okay") then	
		draw_banner(banner.bad,
			"mission failed",35)
	end
end

function draw_ship()
	--ship crashed, burn
	if(ship.alive==0) then
		if(ship.sprite==18) then
			ship.sprite=17
		else 
			ship.sprite=18
		end
	end
	
	--chase the damn thing
	camera(cam.x)

	--ship
	spr(ship.drop_sprite,ship.x+1,ship.y)
	spr(ship.drop_sprite,ship.x-1,ship.y)
	spr(ship.sprite,ship.x,ship.y)
	
	--thrust
	spr(ship.up_sprite,ship.x, ship.y + 8)
	spr(ship.left_sprite,ship.x-2,ship.y)
	spr(ship.right_sprite,ship.x+2,ship.y)

	--raise flag
	if(game=="over-good") then
	 spr(flag.drop_sprite,ship.x+2,ship.y-7)
	 spr(flag.drop_sprite,ship.x+4,ship.y-7)
 	spr(flag.sprite,ship.x+3,ship.y-7)
 end
end

function draw_star(star)
	--draw star if nothing else is there
	if(pget(star.x,star.y)!=7) then
		pset(star.x,star.y,6)
	end
end

function draw_ground()
	for i=1,#ground_lines-1 do
	 if(ground_lines[i+1].x>=flr(cam.x)-10
	  and ground_lines[i+1].x<cam.x+256) then
		 --fill lines
		 for j=0,base_ground-pad.y+1 do
			 line(ground_lines[i].x,
			  ground_lines[i].y+j,
			  ground_lines[i+1].x,
			  ground_lines[i+1].y+j,7)
		 end
	 end
	end	
	
	--search for and store 
	--the visible tops
	distance=ship.x+128
	for x=flr(cam.x), distance do
		for y=base_ground-pad.y,128 do
			if(pget(x,y)==7) then
				death_points[x]=y
				break --stop at the top
			end
		end
	end
	
	--highlight the death line
	for i=flr(cam.x),#death_points do
		pset(i,death_points[i],13)
	end
	
	--draw the lowest line (fills in gaps)
	line(0,127,ship.x+127,127,7)
end

function draw_pad()
 if(flr(frame/8)%2==0) then
 	spr(pad.sprite,pad.x,pad.y,
 		2,2)
 else
 	spr(pad.sprite+2,pad.x,pad.y,
 		2,2)
 end
end

function draw_banner(which,message,offset)
 if(banner.left<128) then
 	banner.left+=10
 end
 if(banner.right>0) then
 	banner.right-=10
 end
	rectfill(cam.x,50,
  cam.x+banner.left,55,which)
 rectfill(cam.x+128,55,
 	cam.x+banner.right,60,which)
	
	if(banner.left>=128) then
		print(message,cam.x+offset+1,54,1)
 	print(message,cam.x+offset,53,7)
	end
end
__gfx__
00000000000000000000000000000000000aa000000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000055000000000000000000009a99a900a9aa9a000011000000000000000000000000000000000000000000000000000000000000000000000000000
00700700005665000dc9ac0000000000009aa90000a99a0000111100011111000000000000000000000000000000000000000000000000000000000000000000
00077000056666500d9aaac00000000000099000000aa00001111110011111100000000000000000000000000000000000000000000000000000000000000000
00077000056cc6500dc9ac0000000000000000000000000001111110011111000000000000000000000000000000000000000000000000000000000000000000
00700700566666650d00000000000000000000000000000011111111010000000000000000000000000000000000000000000000000000000000000000000000
00000000565665650d00000000000000000000000000000011111111010000000000000000000000000000000000000000000000000000000000000000000000
00000000666556660d00000000000000000000000000000011111111010000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000a00000000000000000000000000000000000000000000000000000000000000000000b00000000000000800000000000000000000000000000000
0000000000a90000000a00000000000090000000a0000000000000090000000a5000000000000005500000000000000500000000000000000000000000000000
00000000009a600000a9600000000000a90000009a0000000000009a000000a96500000000000056650000000000005600000000000000000000000000000000
000000000066060000660600000000009a000000a9000000000000a90000009a65aaaaaa9999995665999999aaaaaa5600000000000000000000000000000000
00000000060666000606660000000000a0000000900000000000000a000000096550005665000556655000566500055600000000000000000000000000000000
000000000a6ccc90096ccca000000000000000000000000000000000000000006505050550505056650505055050505600000000000000000000000000000000
0000000095c6555aa5c6555900000000000000000000000000000000000000006500500660050056650050066005005600000000000000000000000000000000
__sfx__
01010000025500c5500355012550025500f5500655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0105000000000276200962007610286100861006610026300160006600066001a5001a5001a5001a5001a5001a5001a5000060000600006000060000600016000260000600000000000000000000000000000000
010a000006524065240b5240f524105250352516525115251b525135251852512525295002b500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
