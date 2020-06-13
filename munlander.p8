pico-8 cartridge // http://www.pico-8.com
version 27
__lua__
-- mun lander alpha.0.82
-- by lewsidboi, 2020

version="a.0.82"

--game parameters
start_fuel=100
base_ground=110
gravity=.02
thrust=.15
start_x=58
start_y=10
last_edge=0
game_state="intro"
level=1
collected=0
max_x=5000

--tables
global={frames=0,seconds=0}
ship={}
data_collected=0
levels={}
death_points={}
ground_lines={}
cam={x=0}
stars={}
pad={}
pickup={height=5,width=4,sprite=35,frames=8,frame=1}
pickups={}
intro={moon_y=100}
flag={sprite=2,drop_sprite=7}
banner={intro=12,subhead=1,start,good=11,bad=8,left=0,right=128}

function _init()
	init_levels()
end

function _draw()
	cls()
	
	--stars forever
	foreach(stars, draw_star)

	if(game_state!="intro") then
	 draw_ship()
		draw_pad()
		draw_ground()		
		draw_pickups()
	end	
	
	draw_start()
end

function _update()
	--clock upkeep
	global.seconds=global.frames/30
	global.frames+=1

	init_stars()

	if(game_state=="intro") then
		if(btn(❎)) then
			game_state="levelintro"
			init_ship(start_x,start_y,0,.2)
			init_pad()
			init_ground()
			init_pickups()
			collected=0
		end
	elseif(game_state=="started") then
		if(ship.on_screen) then
			init_ground()
		end
		
		control_ship()
		move_ship()
		detect_pickup()
	end
end
-->8
--inits

--level config
function init_levels()
	levels[1]=
	{
		pad_x=130,
		pad_y=90,
		pickups=4,
		jag_rate=25
	}
	levels[2]=
	{
		pad_x=150,
		pad_y=95,
		pickups=4,
		jag_rate=22
	}
end

--set up the landing pad 
function init_pad()
	pad=
	{
		sprite=8,
		width=16,
		height=16,
		surface=12,
		x=levels[level].pad_x,
		y=levels[level].pad_y
	}
end

--generate pickups for our level
function init_pickups()
	if(levels[level].pickups>0) then
		--set the base x position
		spawn_x=flr((pad.x)/levels[level].pickups)
		
		--we spawn pickups at random
		--intervals but not overlapping
		for i=1,levels[level].pickups do
			pickups[i]= {
				sprite=pickup.sprite,
				frame=pickup.frame,
				frames=pickup.frames,
				x=rnd(spawn_x)+((i*spawn_x)-1),
				y=10+rnd(80),
				width=pickup.width,
				height=pickup.height,
				is_active=true
			}
		end
	end
end

--set up our ship with some
--basic settings
function init_ship()

	--up_sprite: 3 = off, 4 = on, 5 = on-alt
	--left_sprite: 19 = off, 20 = on, 21 = on-alt
	--right_sprite: 19 = off, 22 = on, 23 = on-alt

	ship= 
	{
	 on_screen=true,
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

	return ship
end

--procedurally generate terrain
function init_ground()
	distance=128
	distance+=cam.x+128
	
	while (last_edge<distance) do
		new_edge=0
		new_top=base_ground+rnd(128-base_ground)

		if(#ground_lines>0) then
			new_edge=last_edge+rnd(levels[level].jag_rate)
		end
		
		--check for the pad
		--and draw around it
		if(new_edge>=pad.x and
			new_edge<=pad.x+levels[level].jag_rate) then
	 		new_edge=pad.x
	 		new_top=pad.y+pad.height
	 		add(ground_lines,{x=pad.x-1,
				y=new_top })
			add(ground_lines,
				{x=pad.x+pad.width,
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

--initialize stars, two screens
--worth at a time
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

--update ship trajectory based
--on user input
function control_ship()
	ship.speed=flr((ship.dy*100)/5)

	--if we are still above ground
	if(above_ground(ship) and
		not on_pad()) then
		--left
		if (btn(0) and ship.fuel>0) then
			ship.dx -= thrust
			ship.fuel -= 1
			sfx(0)
			if (ship.right_sprite==19 
				or ship.right_sprite==22) then 
				ship.right_sprite=23
			else
				ship.right_sprite=22
			end 
		else
			ship.right_sprite=19
		end

		--right
		if(btn(1) and ship.fuel>0) then
			ship.dx+=thrust
			ship.fuel-=1
			sfx(0)

			if(ship.left_sprite==19 
				or ship.left_sprite==20) then 
				ship.left_sprite=21
			else
				ship.left_sprite=20
			end
		else
			ship.left_sprite=19
		end

		--up
		if(btn(2) and ship.fuel>0) then
			ship.dy-=thrust
			ship.up_sprite=4+rnd(2)
			ship.fuel-=1
			sfx(0)
		else
			ship.up_sprite=3
		end
	else
		ship.dx=0
	end
end

--detect if ship has collided 
--with/collected a pickup
function detect_pickup()
	for i=1,#pickups do
		if(pickups[i].is_active) then
			if(collide(ship,pickups[i])) then
			 	collected+=1
			 	pickups[i].is_active=false
			 	sfx(3)
			end
		end
	end
end

--update ship position
function move_ship()		
	--if ship is above ground 
	--and not on the pad, move it
	if(above_ground() and not
	 on_pad()) then
	 ship.x+=ship.dx
		ship.dy+=gravity
		ship.y+=ship.dy
	else
		if(ship.speed>10 
			and ship.alive==1) then
			--we are coming in too hot
			ship.alive=0
			ship.sprite=18
			reset_thrust()
			sfx(1)
			game_state="over-bad"
		elseif(ship.alive==1
			and game_state=="started"
			and on_pad()) then
			--ship landed smoothly on the pad
			reset_thrust()
			sfx(2)
			game_state="over-good"
		elseif(ship.alive==1
			and game=="started"
			and not on_pad()) then
			--we landed, but not on the pad
			reset_thrust()
			sfx(2)
			game_state="over-bad"
		end
	end
	
	if(ship.x>=start_x and
		ship.x<=max_x) then
		--update camera position
		cam.x=-start_x+ship.x
		ship.on_screen=true
	else
		ship.on_screen=false
	end
end

--reset ship thrust to off state
function reset_thrust()
	ship.left_sprite=19
	ship.right_sprite=19
	ship.up_sprite=3
end

--true if ship is above ground
--false otherwise
function above_ground()
	if(ship.x<cam.x or 
	 ship.x>cam.x+128) then
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

--true if ship is on landing pad,
--false otherwise
function on_pad()
	if(ship.x>=pad.x and
		ship.x<=pad.x+pad.width
		and flr(ship.y)>=pad.y+4)
		then
		return true
	end
	return false
end
-->8
--draws

--handle initial draw state
function draw_start()
	if(game_state=="intro") then
		draw_intro()
	elseif(game_state=="levelintro") then
		cls(1)
		draw_banner(banner.intro,
			"level "..level,48,5)
		start_timer()	
		
		if(get_seconds()==2) then	
			game_state="started"
		end
	else
		draw_game()
	end
end

--draw game intro
function draw_intro()
	spr(64,0,intro.moon_y,16,9)
 
 	--animate moon
	if(intro.moon_y>70) then
 		intro.moon_y-=1
	else
		draw_banner(banner.intro,
			"mun lander",43,-30)
		draw_banner(banner.subhead,
			"by smolboi games",32,-20)
		draw_banner(banner.subhead,
			"ver "..version.." 2020",33,64)
		draw_banner(banner.start,
		 "press ❎ to start",31,-5)
	end 
end

--draw in-progress game stuff
function draw_game()
	--status
	print("fuel: "..ship.fuel,
		cam.x+1,1,1)
	print("fuel: "..ship.fuel,
		cam.x,0,7)
	print("distance: "..ceil(pad.x-ship.x+4).."m",
		cam.x+1,8,1)
	print("distance: "..ceil(pad.x-ship.x+4).."m",
		cam.x,7,7)
	
	--data icon
 	percent=collected/#pickups*100
	step=0
	if(percent==100) then
		step=3
	elseif(percent>=66) then
		step=2
	elseif(percent>0) then
		step=1
	end
	
	spr(48,cam.x+120,2)
	spr(49+step,cam.x+119,1)

	--handle endgame state
	draw_end()
end

--draw end game state
function draw_end()
	if(game_state=="over-good") then
 		draw_banner(banner.good,
			"mission accomplished",25)
	elseif(game_state=="over-bad" or
		game_state=="over-okay") then	
		draw_banner(banner.bad,
			"mission failed",35)
	elseif(game_state=="intro") then
 		draw_banner(banner.intro,
			"mun lander",35)
 	end
end

--draw our wee spaceship
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
	spr(ship.drop_sprite,ship.x,ship.y+1)
	spr(ship.drop_sprite,ship.x+1,ship.y)
	spr(ship.drop_sprite,ship.x-1,ship.y)
	spr(ship.sprite,ship.x,ship.y)
	
	--thrust
	spr(ship.up_sprite,ship.x, ship.y + 8)
	spr(ship.left_sprite,ship.x-2,ship.y)
	spr(ship.right_sprite,ship.x+2,ship.y)

	--raise flag
	if(game_state=="over-good") then
		spr(flag.drop_sprite,ship.x+2,ship.y-7)
		spr(flag.drop_sprite,ship.x+4,ship.y-7)
		spr(flag.sprite,ship.x+3,ship.y-7)
	end
end

--twinkle twinkle
function draw_star(star)
 	--only draw stars on screen
	if(star.x>=cam.x and 
		star.x<= cam.x+128) then
		--check for terrain and draw
		if(pget(star.x,star.y)!=7 and
	 	pget(star.x,star.y)!=6) then
			pset(star.x,star.y,6)
		end
	end
end

--draw data pickups
function draw_pickups()
	if(#pickups>0) then
		for i=1,#pickups do
			if(pickups[i].is_active) then
				--animate trace effect
				if(global.frames%2==0) then
					pickups[i].frame+=1
					if(pickups[i].frame == pickups[i].frames) then
						--reset frame
						pickups[i].frame=1
					end
				end

				spr(pickups[i].sprite+pickups[i].frame-1,
					pickups[i].x,pickups[i].y)
			end
		end
	end
end

--draw the moonscape
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
	distance=cam.x+128
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
	line(0,127,cam.x+127,127,7)
end

--draw landing pad
function draw_pad()
	if(flr(global.frames/8)%2==0) then
		spr(pad.sprite,
			pad.x,pad.y,2,2)
	else
 		spr(pad.sprite+2,
 			pad.x,pad.y,2,2)
	end
end

--animate banner message
function draw_banner(color,message,offset_x,offset_y)
	if(offset_y==nil) offset_y=0
	
	if(banner.left<128) then
 		banner.left+=10
 	end
 	
 	if(banner.right>0) then
 		banner.right-=10
 	end
	
	rectfill(cam.x,50+offset_y,
		cam.x+banner.left,55+offset_y,color)
 	rectfill(cam.x+128,55+offset_y,
		cam.x+banner.right,60+offset_y,color)
	
	if(banner.left>=128) then
		print(message,cam.x+offset_x+1,
			54+offset_y,1)
 		print(message,cam.x+offset_x,
 			53+offset_y,7)
	end
end
-->8
--helpers

timer={start=0,seconds=0}

--reset timer to zero
function reset_timer()
	timer.start=0
end

--start the clock
function start_timer()
 if(timer.start==0) timer.start=global.seconds
end

--get the elapsed number of
--seconds since timer start
function get_seconds()
	timer.seconds=global.seconds-timer.start
	return timer.seconds
end

function intersect(min1,max1,
	min2,max2)
	return max(min1,max1)>min(min2,max2) 
  and min(min1,max1)<max(min2,max2)
end

--return true if object1 has 
--collided with object2
function collide(object1,object2)
	return intersect(object1.x,
		object1.x+object1.width,
		object2.x,object2.x+object2.width)
		and
		intersect(object1.y,object1.y+object1.height,
		object2.y,object2.y+object2.height)
end
__gfx__
00000000000000000000000000000000000aa000000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000055000111111100000000009a99a900a9aa9a000011000000000000000000000000000000000000000000000000000000000000000000000000000
00700700005dd5001dc9ac1100000000009aa90000a99a0000111100011111000000000000000000000000000000000000000000000000000000000000000000
0007700005d66d501d9aaac10000000000099000000aa00001111110011111100000000000000000000000000000000000000000000000000000000000000000
00077000056cc6501dc9ac1100000000000000000000000001111110011111000000000000000000000000000000000000000000000000000000000000000000
007007000d6666d01d11111000000000000000000000000001111110010000000000000000000000000000000000000000000000000000000000000000000000
00000000565665651d10000000000000000000000000000011111111010000000000000000000000000000000000000000000000000000000000000000000000
000000006d6556d61d10000000000000000000000000000011111111010000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000a0000000000000000000000000000000000000000000000000000900000000000000aa00000000000000900000000000000000000000000000000
0000000000a95000000a50000000000090000000a0000000000000090000000a5000000000000005500000000000000500000000000000000000000000000000
00000000009a650000a9650000000000a90000009a0000000000009a000000a95500000000000055550000000000005500000000000000000000000000000000
000000000566d6000566d600000000009a000000a9000000000000a90000009a55aaaaaa9999995555999999aaaaaa5500000000000000000000000000000000
0000000056d6665056d6665000000000a0000000900000000000000a000000095550005665000555555000566500055500000000000000000000000000000000
000000005a6ccc90596ccca000000000000000000000000000000000000000005505050550505055550505055050505500000000000000000000000000000000
0000000095c6555aa5c6555900000000000000000000000000000000000000005500500660050055550050066005005500000000000000000000000000000000
0000000000000000000000007c00000067000000c6000000cc000000cc000000cc000000cc000000cc0000000000000000000000000000000000000000000000
00000000000000000000000061c00000c1c00000c1700000c1600000c1c00000c1c00000c1c0000071c000000000000000000000000000000000000000000000
000000000000000000000000c1c10000c1c10000c1c10000c1710000c1610000c1c1000071c1000061c100000000000000000000000000000000000000000000
000000000000000000000000cc110000cc110000cc110000cc110000c7110000761100006c1100007c1100000000000000000000000000000000000000000000
00000000000000000000000001100000011000000110000001100000011000000110000001100000011000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100007776000077760000777600007776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011000000770000007700000077000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011000000770000007700000077000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100007776000077760000777600007776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111110077777600777776007777760077cc7600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111777777767777777677cccc7677cccc760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111111117777777677cccc7677cccc7677cccc760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01111110077777600777776007777760077777600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000d666d66d6ddddddd00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000007767676665676666616666dddd5d00000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000077775556567667666656666656666666dd5d0000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000777666577756666666666676666666566566657ddd0000000000000000000000000000000000000000000
000000000000000000000000000000000000000077766656577777565666656666d666676666666657777ddd0000000000000000000000000000000000000000
0000000000000000000000000000000000000077666666665777575666656676566166661666665657757777dd00000000000000000000000000000000000000
000000000000000000000000000000000000776666766666577777566666666666666665666666666577771777dd000000000000000000000000000000000000
000000000000000000000000000000000077667666666666657775766665555566665666666d5666657775777777dd0000000000000000000000000000000000
0000000000000000000000000000000077666666666766766655576666577777566566666666666566577777717777dd00000000000000000000000000000000
000000000000000000000000000000076676666666666666567665666577777775666666666666666665777577577777d0000000000000000000000000000000
0000000000000000000000000000077666666566666766666666766657777757775666661666665666665777777777577d500000000000000000000000000000
000000000000000000000000000076666666666666666657666666565777777777566656616557666656657777577577756d0000000000000000000000000000
0000000000000000000000000077666666656667676666667666766657775777775666666666666661666655777777755666dd00000000000000000000000000
000000000000000000000000076666667666666666766666666666665777777757566616666666666666666655555557666666d0000000000000000000000000
00000000000000000000000076667656666656666666666666666666577777757756666656d6666166665665667777766666616d000000000000000000000000
00000000000000000000007655566666666566667666666766766666657777777566666666666666666666666666666666566666dd0000000000000000000000
000000000000000000000765677566667666666665556666666666656657777756756666566656666656666566665556666766666d5000000000000000000000
0000000000000000000076657775666666666666577756665666656666655555765666666616666666666666666577756666666666dd00000000000000000000
000000000000000000076665777566666666666657775666666666666666777766756666666666566676666666577777566666656616d0000000000000000000
0000000000000000007666665557656667656666577756666666667666666666666666616666566666666616657757777566656666666d000000000000000000
00000000000000000766665667666666666666766555766666676666566666666665666666666666656666666577775775666666166666d00000000000000000
00000000000000007666666665666666676666666677666666666666667667766666666666666666d666566665777577556661666665656d0000000000000000
00000000000000007667666667666666666666666666666555556665666666666666657656656665556666666657777756666666666666655000000000000000
00000000000000076676666666666667666766676656665777775666666766666d6666666666665777566657666577757666666661666657d000000000000000
00000000000000766666666666665666666566666676657777777566666666566666666661666657775666666666555766665656666665777d00000000000000
000000000000076666666666676665666666666666665775777777566666666666661656666566577756666665666776665666666566577577d0000000000000
0000000000000766666665666666666667666666666657775775775666566666666666666666666555766665666666665666666666565777577d000000000000
0000000000007666676667666667666666676676766657777777775666766766d66566656666666677666666666666656666565666665775777d000000000000
00000000000766766666666666666666666666666666577777777756666666656666666666665566666656666666566661666666666665777575d00000000000
00000000000766666666666657666666666667666766577777777756676666666666555666616666666666665666666666666666656666577756d00000000000
000000000076666766667666666666765666666667666577577775766666566656657775666666666561666666666666666656666166666555666d0000000000
000000000566766666666776666766666666666666666657777757676667676666657775665666666666666666166666666566166666616666666dd000000000
0000000007566666666666666666666666666666666666655555666666666661666577756666666666166666d66666166656666666666666656566d000000000
00000000777566666676666666666656666766566666666667766666666666666666555766655555666666166666666666766666166566666666666d00000000
00000000777566666766665555566666666666676666666666665666666666667666677666577777566666666166666656656666666665566665665d00000000
000000077775666666665577777556666666666676766566666666666765666666666666657757777566666666666166666616666666666666666666d0000000
000000077757666666557777777775566665666666666666666666656666666666666666577777777756656656666656666666566566666665656666d0000000
0000007555766766657777757777577566667666666566667666666666676666676766665777777577566666766666666666666d66661666666666166d000000
0000007677667666657777777777777566666666666666666676666666666766676665665777777777566666666666666666166666666661666666666d000000
00000766666666665775777777757777566666676666666666666666767666666666666657775757775666666166666566666666666566665666166666d00000
00000766666666665777775777777777566666666666666676661666666666656667616657775777775676666666166665666665566656666666666616d00000
00000766666656657777777777777777756667666666616666766666666656666666666665777777756666665666666666666666666666666166666666d00000
000076666666666577777777777777777566666667666666676666666666666666666666665777775666666666666666666566666665665666666656666d0000
000076676666766577777777777757777566666676666666666666666666666666566666566555556666666566656616666666166616666666656666665d0000
000076666666666577777777777777777576666666666767666666576666d66766656656666666666766661666666666656666666666566665666656666d0000
000766666566666577777757777777577566667666666666666666666676666666666666666666166666666666566d66666666666666666666666666566d5000
0007666666666766577577777775777757666566666666666666666666666666666666661616666666661666666666666676656666666665666666666166d000
0007676666667666577777777777777756667666665666665666767666666666666d66666666666666666565666666666666666566661566666556616666d000
0007666666666666657777757777577566666666666666766666666676666166666666666666661666666666655555556665666665666666666666666666d000
00677666766666666577777777777775666666666666666666766666656666666667666665665666656666655777777755666666666666661566665665616d00
00766666666666666655777777777557666666666676666665666666666666666566666666666666666665577777717777556661666666666666666666666d00
007666666667656666665577777557666766555666666666666667666665666666666616666d666665665777777d7777777756666166566665666166d6661d00
00776667666666666666675555577666666577756667665555566666666666666666666666666661666577775777777771777566666566666666666666666d00
00766667666666666666667777766666666577756666657777756666666666766566665666666666665777177777577577777756666661666555666616666d00
00766666666566667666665666666666666577756666577777775667676666666666666661666566665777777777777777777756666666665777566666666d00
055666666667666667666666666676666666555766657777777775666656666666666666666566666577777775777757777777756666666577777566566666d0
077566666666666766666666666676667666766666577777775777566666766666661656666666666577771777757777777577756616665775777756666616d0
077566666666666666666666665666666766667666577757777777566666666676666666666666165777577777777777777717775666665777757756661666d0
077576676666666666676666666667666666666666577777777777566666666666666666656666665777777777717777717777775666665777577756666666d0
055666666666766666666566766666667666566656577775777777566666766666666656666666665777777757777757777577775616666577777566656666d0
077766666766666676666666666666666766666666577777777777566676666666666666166166665777775777777777777777755666166657775666666656d0
076666666666666667666666666656666666666666657777777775766666666566616666666665665717777777577777757777775666566665556661666656d0
076666666766666666666666666666666676666666665777777756666666666666666656666666665777777777777777777775775666666666666666666666d0
__sfx__
00010000025500c5500355012550025500f5500655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005000000000276200962007610286100861006610026300160006600066001a5001a5001a5001a5001a5001a5001a5000060000600006000060000600016000260000600000000000000000000000000000000
000a000006524065240b5240f524105250352516525115251b525135251852512525295002b500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080000290102d010290103201033000310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
