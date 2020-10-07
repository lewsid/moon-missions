pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- mun lander alpha.1.1
-- by lewsidboi/smolboigames, 2020

version="alpha.1.1"

--game parameters
config={}
upkeep={frames=0,seconds=0}
ship={}
levels={}
death_points={}
ground_lines={}
cam={x=0,y=0}
stars={}
pad={}
pickup={height=5,width=4,sprite=35,
	frames=8,frame=1}
pickups={}
intro={moon_sprite=64,moon_y=100,
	moon_width=16,moon_height=9,
	logo_sprite=192,logo_width=9,
	logo_height=3,logo_shown=0,
	logo_flash=10}
logo={}
flag={sprite=2,drop_sprite=7}
banner={intro=12,subhead=1,start,
	score=12,good=11,bad=8,left=0,
	flash=10,right=128}
screen_x=0
screen_y=0
slot_length=18
high_scores={}
alphabet="abcdefghijklmnopqrstuvwxyz "
name_entry={
	cur={x=0,y=0},chars=split(alphabet,""),
	textpos=40,
	name="",
	saved=false}

function _init()
	cartdata("lewsid-moon-missions")

	--erase_data()
	output_data()

	load_high_scores()

	init_config()
	init_levels()
end

function _draw()
	draw_start()
end

function _update()
	--clock upkeep
	upkeep.seconds=upkeep.frames/30
	upkeep.frames+=1

	--track screen
	screen_x=flr(cam.x/128)+1
	screen_y=abs(flr(cam.y/128))+1

	--main game state router
	if(config.game_state=="game-intro") then
		init_stars()
		
		if(btnp(❎)) then
			start_game()
		end
		
		if(btnp(🅾️)) then
			config.game_state="high-scores"
		end
	elseif(config.game_state=="high-scores") then
		if(btnp(❎)) then
			--reset the game
	  		init_config()
			start_game()
		end
	elseif(config.game_state=="started") then
		handle_gameplay()
	elseif(config.game_state=="over-bad") then
		if(config.lives>0) then
			if(btn(❎)) then
				config.lives-=1
				init_level(true)
				reset_banner()
			end
		else
			config.game_state="game-over"
		end
	elseif(config.game_state=="over-good") then
		if(btn(❎)) then
			config.level+=1
			init_level(false)
			reset_banner()
		end
	elseif(config.game_state=="game-over") then
		if(btn(❎)) then
	  		--reset the moon position
	 		intro.moon_y=100
	 		cam.x=0
	 		cam.y=0
	 		camera(cam.y,cam.y)

	 		--reset the game
	  		init_config()
	 	end
	elseif(config.game_state=="goto-enter-name") then
		if(btn(❎)) then
			cam.x=0
	 		cam.y=0
	 		camera(cam.y,cam.y)
			config.game_state="enter-name"
		end
	elseif(config.game_state=="enter-name") then
		--left
		if(btnp(0)) then
			if(name_entry.cur.x>0) name_entry.cur.x-=1
		end

		--right
		if(btnp(1)) then
			if(name_entry.cur.x<8) name_entry.cur.x+=1
		end

		--up
		if(btnp(2)) then
			if(name_entry.cur.y>0) name_entry.cur.y-=1
		end

		--down
		if(btnp(3)) then
			if(name_entry.cur.y<3) name_entry.cur.y+=1
		end
	 
	 	--add letter
		if(btnp(5)) then
			if(#name_entry.name<12 and name_entry.cur.y<3) then
				--cursor is over letter
				local c=(name_entry.cur.x+1)+(name_entry.cur.y*9)
				name_entry.name=name_entry.name..name_entry.chars[c]
			elseif(name_entry.name!="") then
				--cursor is over save button

				--find available slot
				local slot = check_new_high_score()

				--save score to cart memory
				save_score(slot,name_entry.name,get_score_text(config.total_score))

				--refresh the highscore list in memory
				load_high_scores()

				output_data()
				name_entry.saved=true
			end
		end

		--remove letter
		if(btnp(4)) then
			name_entry.name=sub(name_entry.name,0,#name_entry.name-1)
		end
	end
end
-->8
--inits

function init_config()
 	config={
 		stars_per_screen=60,
		start_fuel=100,
		base_ground=110,
		gravity=.02,
		thrust=.15,
		start_x=58,
		start_y=20,
		last_edge=0,
		game_state="game-intro",
		level=1,
		collected=0,
		percent_collected=0,
		max_x=5000,
		score=0,
		total_score=0,
		score_frame=1,
		lives=3
	}
end

--level config
function init_levels()
	levels[1]={
		pad_x=110,  --distance to landing pad
		pad_y=90,   --height of landing pad (keep between 50 and 90)
		pickups=#levels+1,  --number of pickups
		jag_rate=35 --terrain jagginess (higher=flatter, lower than 5 causes mem issues)
	}
	levels[2]={
		pad_x=150,
		pad_y=70,
		pickups=#levels+1,
		jag_rate=22
	}
	levels[3]={
		pad_x=170,
		pad_y=80,
		pickups=#levels+1,
		jag_rate=30
	}
	levels[4]={
		pad_x=200,
		pad_y=65,
		pickups=#levels+1,
		jag_rate=18
	}
	levels[5]={
		pad_x=220,
		pad_y=90,
		pickups=#levels+1,
		jag_rate=25
	}
	levels[6]={
		pad_x=250,
		pad_y=50,
		pickups=#levels+1,
		jag_rate=15
	}
	levels[7]={
		pad_x=280,
		pad_y=60,
		pickups=#levels+1,
		jag_rate=10
	}
	levels[8]={
		pad_x=400,
		pad_y=70,
		pickups=#levels+1,
		jag_rate=50
	}
	levels[9]={
		pad_x=500,
		pad_y=55,
		pickups=#levels+1,
		jag_rate=30
	}
	levels[10]={
		pad_x=600,
		pad_y=85,
		pickups=#levels+1,
		jag_rate=100
	}
	levels[11]={
		pad_x=800,
		pad_y=81,
		pickups=#levels+1,
		jag_rate=90
	}
	levels[11]={
		pad_x=1000,
		pad_y=51,
		pickups=#levels+1,
		jag_rate=65
	}
	levels[12]={
		pad_x=1500,
		pad_y=61,
		pickups=#levels+1,
		jag_rate=70
	}
	levels[14]={
		pad_x=2000,
		pad_y=82,
		pickups=#levels+1,
		jag_rate=100
	}
	levels[15]={
		pad_x=2200,
		pad_y=57,
		pickups=#levels+1,
		jag_rate=140
	}
	levels[16]={
		pad_x=2300,
		pad_y=53,
		pickups=#levels+1,
		jag_rate=100
	}
	levels[17]={
		pad_x=2400,
		pad_y=61,
		pickups=#levels+1,
		jag_rate=101
	}
	levels[18]={
		pad_x=2500,
		pad_y=63,
		pickups=#levels+1,
		jag_rate=105
	}
	levels[19]={
		pad_x=2800,
		pad_y=65,
		pickups=#levels+1,
		jag_rate=110
	}
	levels[20]={
		pad_x=3000,
		pad_y=70,
		pickups=#levels+1,
		jag_rate=115
	}
end

--set up the landing pad 
function init_pad()
	pad={
		sprite=8,
		width=16,
		height=16,
		x=levels[config.level].pad_x,
		y=levels[config.level].pad_y
	}
end

--generate pickups for our level
function init_pickups()
	if(levels[config.level].pickups>0) then
		--set the base x position
		spawn_x=flr((pad.x-50)/levels[config.level].pickups)
		
		--we spawn pickups at random
		--intervals but not overlapping
		for i=1,levels[config.level].pickups do
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

	ship={
		on_screen=true,
		sprite=1,
		drop_sprite=6,
		x=config.start_x,
		y=config.start_y,
		dx=0,
		dy=0,
		height=8,
		width=8,
		up_sprite=3,
		left_sprite=19,
		right_sprite=19,
		velocity_sprite=57,
		speed=0,
		fuel=config.start_fuel,
		alive=1
	}

	return ship
end

--procedurally generate terrain
function init_ground()
	distance=128
	distance+=cam.x+128
	
	while (config.last_edge<distance) do
		new_edge=0
		new_top=config.base_ground
			+rnd(128-config.base_ground)

		if(#ground_lines>0) then
			new_edge=config.last_edge
				+rnd(levels[config.level].jag_rate)
		end
		
		--check for the pad
		--and draw around it
		if(new_edge>pad.x and
			config.last_edge<pad.x+pad.width) then
		 	new_edge=pad.x
		 	new_top=pad.y+pad.height
		 	add(ground_lines,{x=pad.x-1,
				y=new_top })
			add(ground_lines,
				{x=pad.x+pad.width,
					y=new_top })
			config.last_edge=pad.x+pad.width
	 	else
	 		--go nuts
			add(ground_lines,{x=new_edge,
				y=new_top})
		 	config.last_edge=new_edge
		end
	end
end

--initialize matrix of stars based on current position
function init_stars()
	--9 screens surrounding the player
	for star_screen_x=max(screen_x-1,1),max(screen_x-1,1)+2 do
		for star_screen_y=max(screen_y-1,1),max(screen_y-1,1)+2 do
			
			if(stars[star_screen_x]==nil) then
				stars[star_screen_x]={}
			end
	    	
	    	if(stars[star_screen_x][star_screen_y]==nil) do
				stars[star_screen_x][star_screen_y]={}

				for i=1,config.stars_per_screen do
					ranx_x=nil
					rand_y=nil

					rand_x=flr(rnd(128))+(128*(star_screen_x-1))
					
					if(star_screen_y==1) then
						rand_y=flr(rnd(128))
					else
						rand_y=-(flr(rnd(128))
							+(128*(star_screen_y-2)))
					end
					
					stars[star_screen_x][star_screen_y][i]
						={x=rand_x,y=rand_y}
				end
			end

		end
	end
end

function init_level(preserve)
	reset_timer()
	config.game_state="levelintro"
	cam={x=0,y=0}
	init_ship(config.start_x,config.start_y,0,.2)
	init_pad()
	config.collected=0
	config.percent_collected=0
	
	if(preserve==false) then
		config.last_edge=0
		death_points={}
 		ground_lines={}
 		--stars={}
 		pickups={}
 		init_stars()		
		init_ground()
		init_pickups()
	else
		for i=1,#pickups do
			pickups[i].is_active=true
	 	end
	end
end

-->8
--updates

function start_game()
	init_level(false)
	reset_banner()
end

function handle_gameplay()
	init_stars()

	if(ship.on_screen) then
		init_ground()
	end
		
	control_ship()
	move_ship()
	detect_pickup()
end

--update ship trajectory based
--on user input
function control_ship()
	ship.speed=flr((ship.dy*100)/5)

	--if we are still above ground
	if(above_ground(ship) and
		not on_pad()) then
		--left
		if (btn(0) and ship.fuel>0) then
			ship.dx-=config.thrust
			ship.fuel-=1
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
			ship.dx+=config.thrust
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
			ship.dy-=config.thrust
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
			 	config.collected+=1
			 	config.percent_collected=config.collected/#pickups*100
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
		ship.dy+=config.gravity
		ship.y+=ship.dy
	else
		if(ship.speed>10 
			and ship.alive==1) then
			--we are coming in too hot
			ship.alive=0
			ship.sprite=18
			reset_thrust()
			sfx(1)
			config.game_state="over-bad"
			reset_banner()
		elseif(ship.alive==1
			and config.game_state=="started"
			and on_pad()) then
			--ship landed smoothly on the pad
			reset_thrust()
			sfx(2)
			config.game_state="over-good"
			calc_score()
			reset_banner()
		elseif(ship.alive==1
			and config.game_state=="started"
			and not on_pad()) then
			--we landed, but not on the pad
			reset_thrust()
			sfx(2)
			config.game_state="over-bad"
			calc_score()
			reset_banner()
		end
	end
	
	--handle follow camera
	if(ship.x>=config.start_x and
		ship.x<=config.max_x) then
		--update camera position
		cam.x=-config.start_x+ship.x
		ship.on_screen=true
	else
		ship.on_screen=false
	end

	--snap camera if over top
	if(ship.y<20) then
		cam.y=ship.y-20
	else
		cam.y=0
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
		if(flr(ship.y)+ship.height>config.base_ground) then
			return false
		end
	elseif(#death_points>1 and
		flr(ship.x+ship.width)<=#death_points) then
		for x=flr(ship.x),flr(ship.x)+ship.width do
			if(x>0 and ship.y>20) then
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

function check_new_high_score()
	for i=1,#high_scores do
		--convert scores into hex for comparison
		local raw_high_score = tonum('0x'..get_score_text(config.total_score))
		local raw_saved_score = tonum('0x'..tostr(high_scores[i][2]))

		--printh(raw_high_score, 'out.md', true, true)
		--printh(raw_saved_score, 'out.md', false, true)

		if(raw_high_score>raw_saved_score) then
			--printh('higher: '..i, 'out.md', false, true)
			return i
		end
	end

	return false
end

function calc_score()
	local fuel_score=ship.fuel*10
	local distance_score=(pad.x-config.start_x)*10
	local multiplier=config.collected+1
	config.score=0

	for i=1,multiplier do
		config.score+=shr(fuel_score,16)
		config.score+=shr(distance_score,16)
		config.total_score+=shr(fuel_score,16)
		config.total_score+=shr(distance_score,16)
	end
end
-->8
--draws

--handle initial draw state
function draw_start()
	if(config.game_state=='high-scores') then
		cls(0)
		draw_stars()
		draw_intro_borders()
		draw_high_scores()
		draw_logo(false)
	elseif(config.game_state=="enter-name") then
		--game in progress
		cls(0)
		draw_stars()
		draw_name_entry()
	elseif(config.game_state!="game-intro") then
		--game in progress
		cls(0)
		draw_stars()
		draw_ship()
		draw_pad()
		draw_ground()
		draw_pickups()
	elseif(config.game_state=="game-intro") then
		--intro moon slide
		cls(0)
		draw_stars()
		draw_game_intro()
	end

	if(config.game_state=="levelintro") then
		draw_level_intro()
	elseif(config.game_state=="started") then
		--game in progress
		draw_interface()
	elseif(config.game_state=="over-good" 
		or config.game_state=="over-bad") then
		--ship landed/crashed
		draw_interface()
		draw_level_end()
	elseif(config.game_state=="game-over" or 
		config.game_state=="goto-enter-name") then
		--no more lives
		draw_interface()
		draw_game_over()
	end
end

function draw_name()
	print(name_entry.name,43,30,12)
end

function draw_cursor()
	if(name_entry.cur.y<3) then
		rectfill(20+(name_entry.cur.x*10),
			44+(name_entry.cur.y*10),
			24+(name_entry.cur.x*10),
			50+(name_entry.cur.y*10),
			12)
	else
		rectfill(49,79,73,85,12)
	end
end

function draw_alphabet()
	local pos=1

	for i=0,2 do
		for j=0,8 do
			print(name_entry.chars[pos],
				21+(j*10),
				45+(i*10),6)
			pos+=1 		
		end
	end
end

function draw_name_entry()
	cam={x=0,y=0}
	if(name_entry.saved==false) then
		print("name: ",20,30,7)
		draw_cursor()
		draw_alphabet()
		draw_name()
		print("[save]",50,80,6)
	else
		config.game_state='high-scores'
	end
end

function draw_high_scores()
	print("high scores",42,40)

	for i=1,3 do
		print(high_scores[i][1],25,55+((i-1)*10))
		print(high_scores[i][2],80,55+((i-1)*10))
	end

	--draw ninja logo
	spr(61,118,118)

	--draw version info
	print(version..' fall 2020',2,121)

	draw_start_flash(90)
end

function draw_level_intro()
	--level splash
	cls(1)
	draw_banner(banner.intro,
		"level "..config.level,51,0,1)
	
	if(config.level==1) then 
		draw_banner(banner.subhead,
			"touch down on the landing pad!",5,11,1)
		draw_banner(banner.subhead,
			"(GENTLY)",49,20,1)
	end

	start_timer()
	
	if(config.level == 1) then
		if(get_seconds()==3) then	
			config.game_state="started"
		end
	else
		if(get_seconds()==2) then	
			config.game_state="started"
		end
	end
end

function draw_game_intro()
	spr(intro.moon_sprite,0,intro.moon_y,
		intro.moon_width,intro.moon_height)
 
 	--animate moon
	if(intro.moon_y>70) then
 		intro.moon_y-=1
 	else
 		draw_logo(true)
 		draw_intro_borders()
		draw_start_flash(54)
	end 
end

function draw_start_flash(top)
	--that retro gudness
	if(upkeep.seconds%2<1) then
		print("[press ❎ to start]",27,top,1)
		print("[press ❎ to start]",26,top-1,10)
	end
end

function draw_logo(with_extras)
	--draw logo and info text
	spr(intro.logo_sprite,28,8,
			intro.logo_width,intro.logo_height)

	if(with_extras) then
		draw_banner(banner.start,
			"by smolboi games",33,-18,5)
		draw_banner(banner.subhead,
			"🅾️ hIGH sCORES",35,64,false)
	end
end

function draw_intro_borders()
	--draw borders
	line(0,24,31,24,12)
	line(95,24,127,24,12)
	line(1,0,126,0,12)
	line(0,1,0,126,12)
	line(1,127,126,127,12)
	line(127,126,127,1,12)
end

--draw game interface
function draw_interface()
	--status
	print("fuel: "..ship.fuel,
		cam.x+2,cam.y+1,1)
	print("fuel: "..ship.fuel,
		cam.x+1,cam.y,7)
	print("distance: "..ceil(pad.x-ship.x+4).."M",
		cam.x+2,cam.y+8,1)
	print("distance: "..ceil(pad.x-ship.x+4).."M",
		cam.x+1,cam.y+7,7)
	--print("lives: ",cam.x+2,cam.y+15,1)
	--print("lives: ",cam.x+1,cam.y+14,7)
	print(config.collected.."/"..
		#pickups,cam.x+113,cam.y+4,1)
	print(config.collected.."/"..
		#pickups,cam.x+112,cam.y+3,7)

	--data icon (fill-up)
	step=0
	if(config.percent_collected==100) then
		step=3
	elseif(config.percent_collected>=66) then
		step=2
	elseif(config.percent_collected>0) then
		step=1
	end

	--lives icons
	if(config.lives>0) then
		for i=1,config.lives do
			spr(59,cam.x+102+((i-1)*6),cam.y+10)
		end
	end
	
	spr(48,cam.x+101,cam.y+2)
	spr(49+step,cam.x+100,cam.y+1)
end

--draw end level state
function draw_level_end()
	if(config.game_state=="over-good") then
		draw_banner(banner.good,
			"mission accomplished",24,-30,5)
		draw_banner(banner.subhead,
			"dISTANCE: "..pad.x-config.start_x.."M ("..((pad.x-config.start_x)*10)..")",
			26,-19,false)	
		draw_banner(banner.subhead,
			"fUEL: "..ship.fuel.." ("..(ship.fuel*10)..")",
			34,-8,false)
		draw_banner(banner.subhead,
			"dATA cOLLECTED: "..config.collected.."/"..#pickups.." (X"..config.collected..")",
			16,3,false)
		if(config.collected==#pickups) then
			spr(58,cam.x+113,cam.y+54)
		end
		draw_score_banner()
		draw_banner(banner.start,
			"press ❎ to continue",24,25,1)
	elseif(config.game_state=="over-bad" or
		config.game_state=="over-okay") then
		
		draw_banner(banner.bad,
			"mission failed",34,-6,5)
		draw_banner(banner.start,
			"press ❎ to try again",21,5,1)
 	end
end

function draw_score_banner()
	if(upkeep.seconds%1==0) then
		config.score_frame+=1
		if(config.score_frame>6) then
			config.score_frame=1
		end
	end	

	if(config.score_frame<=2) then
		draw_banner(banner.intro,
			"level score: "..get_score_text(config.score),
			30,14,1)
	elseif(config.score_frame==3) then
		draw_banner(banner.intro,
			"",
			30,14,1)
	elseif(config.score_frame<=5) then
		draw_banner(banner.intro,
			"total score: "..get_score_text(config.total_score),
			30,14,1)
	elseif(config.score_frame==6) then
		draw_banner(banner.intro,
			"",
			30,14,1)
	end
end

function draw_game_over()
	local score_text=get_score_text(config.total_score)

	draw_banner(banner.bad,
		"game over",45,-10,1)
	draw_banner(banner.subhead,
		"score: "..score_text,45-((#score_text-1)*1),1,1)

	local slot = check_new_high_score()
		
	if(slot) then
		config.game_state="goto-enter-name"
		
		draw_banner(banner.intro,
			"new high score!",35,12,5)
		draw_banner(banner.start,
			"press ❎ to enter name",20,25,1)
	else
		draw_banner(banner.start,
			"press ❎ to reset",31,16,1)
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
	else
		--ship is moving up
		if(ship.dy<0) then
			ship.sprite=56
		else		
			--provide visual feedback of
			--descent speed
			if(ship.speed>10) then
				if(ship.sprite==53) then
					ship.sprite=54
				else
					ship.sprite=53
				end
			elseif(ship.speed>8) then
				ship.sprite=54
			elseif(ship.speed>6) then
				ship.sprite=55
			elseif(ship.speed>4) then
				ship.sprite=57
			end
		end
	end
	
	--chase the damn thing
	camera(cam.x,cam.y)

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
	if(config.game_state=="over-good") then
		spr(flag.drop_sprite,ship.x+2,ship.y-7)
		spr(flag.drop_sprite,ship.x+4,ship.y-7)
		spr(flag.sprite,ship.x+3,ship.y-7)
	end
end

function draw_stars()
	--render the 9 screens around the player
	for i=max(screen_x-1,1),max(screen_x-1,1)+2 do
		for j=max(screen_y-1,1),max(screen_y-1,1)+2 do
			foreach(stars[i][j],draw_star)
		end
	end
end

--twinkle twinkle
function draw_star(star)
 	if(pget(star.x,star.y)!=7 and
		pget(star.x,star.y)!=6) then
		pset(star.x,star.y,6)
	end
end

--draw data pickups
function draw_pickups()
	if(#pickups>0) then
		for i=1,#pickups do
			if(pickups[i].is_active) then
				--animate trace effect
				if(upkeep.frames%2==0) then
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
			for j=0,config.base_ground-pad.y+1 do
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
	for x=flr(cam.x),distance do
		for y=config.base_ground-pad.y,128 do
			if(pget(x,y)==7) then
				death_points[x]=y
				
				break --stop at the top
			end
		end
	end
	
	--highlight the death line
	for i=flr(cam.x),flr(cam.x)+128 do
		if(death_points[i]) then
			pset(i,death_points[i],13)
		end
	end
	
	--draw the lowest line (fills in gaps)
	line(0,127,cam.x+127,127,7)
end

--draw landing pad
function draw_pad()
	if(flr(upkeep.frames/8)%2==0) then
		spr(pad.sprite,
			pad.x,pad.y,2,2)
	else
 		spr(pad.sprite+2,
 			pad.x,pad.y,2,2)
	end
end

function reset_banner()
	banner.left=0
	banner.right=128
end

--animate banner message
function draw_banner(color,message,offset_x,offset_y,dropshadow,text_color)
	if(text_color==nil) then 
		text_color=7 --default to white
	end

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
		if(dropshadow) then
			print(message,cam.x+offset_x+1,54+offset_y,dropshadow)
		end
 		print(message,cam.x+offset_x,
 			53+offset_y,text_color)
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
	if(timer.start==0) timer.start=upkeep.seconds
end

--get the elapsed number of
--seconds since timer start
function get_seconds()
	timer.seconds=upkeep.seconds-timer.start
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

--https://www.lexaloffle.com/bbs/?pid=22677
--@Felice
function get_score_text(val)
	local s = ""
	local v = abs(val)
	while (v!=0) do
		s = shl(v % 0x0.000a, 16)..s
		v /= 10
	end
	if (val<0)  s = "-"..s

	if(s=="") then
		s="0"
	end

	return s 
end 

function load_high_scores()
	for i=1,3 do
		local high_score=load_score(i)

		--check for a non-nil name
		if(tonum(high_score[2])==nil) then 
			--set some defaults
			if(i==1) then
				save_score(i,"christopherj","10000")
			elseif(i==2) then
				save_score(i,"christopherj","9000")
			elseif(i==3) then
				save_score(i,"christopherj","8000")
			end
			high_score=load_score(i)
		end
		high_scores[i]=high_score
	end
end

--returns table {1 => name, 2 => score}
function load_score(slot)
	local player_name=""
	local player_score=""
	local slot_offset=((slot_length*(slot-1)))
	local parts={}
	local pos=1
	
	for i=slot_offset,
		slot_offset+slot_length-1 do
		if(pos<=12) then
			player_name=player_name..chr(dget(i))
		elseif(pos>12) then
	 		player_score=player_score..chr(dget(i))
		end
		pos+=1
	end

	local output={player_name,player_score}

	return output
end

--save the name and score
--up to three, then overwrite
--the lowest
--first twelve chars=name
--next six chars=score
function save_score(slot,player_name,score)
	--move all chars into a table
	--of char codes
	local name_parts=split(player_name,"")
	local score_parts=split(score,"")
	local slot_offset=(slot-1)*slot_length

	--store each char of name
	for i=1,12 do
		if(name_parts[i]) then
			dset((slot_offset+i)-1,
				ord(name_parts[i]))
		else
			--pad out to 12 chars
			dset((slot_offset+i)-1,ord(" "))
		end
	end
	
	--same treatment for score
	for i=1,6 do
		if(score_parts[i]) then
			dset((slot_offset+i+12)-1,
				ord(score_parts[i]))
		else
			--pad out 6 chars
			dset((slot_offset+i+12)-1
				,ord(" "))
		end
	end
end

--remove saved high score data (and anything else)
function erase_data()
	for i=0,63 do
		dset(i,nil)
	end
end

--output cart save data
function output_data()
	local output=""
 	for i=0,63 do
 		output=output..chr(dget(i))
  		printh(i..": "..chr(dget(i)), 'out.md', false, true)
	end
end
-->8
--todos

--[❎] fix scoring bug (int too small)
--     https://www.lexaloffle.com/bbs/?pid=22677

--[❎] fix ground line draw

--[❎] fix star draw below y=0

--[❎] fix game-over reset
--     force moon animation to
--     complete

--[❎] add lives (x3)

--[❎] add game over screen
--    with score

--[❎] fix level re-init after
--    mission fail

--[❎] land speed indicator 

--[❎] incorporate distnace 
--    into scoring

--[❎] fix pad spawn bug

--[ ] fix pickup spawning 
--    inside terrain bug
--    back, but rare

--[❎] fix pad spawning in 
--     air bug

--[❎] finish contructing levels

--[❎] Follow camera y when 
--above the fold

--[❎] add star icon when all 
--    pickups are collected

--[❎] add high score view

--[❎] improve terrain level
--    variance

--[ ] detect crash on y speed

--[ ] add credits if level game
--    is beaten

--[ ] create some minimal
--	  music

--[ ] add fuel pickups

--[❎] add help text to level 1
--	  music

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
001111000077760000777600007776000077760000000000000000000000000000000000000000000000000000000000000000000055000500000000c000cc00
000110000007700000077000000770000007700000055000000550000005500000055000000550000000000000000000000000000000500500000000c00c0000
0001100000077000000770000007700000077000005dd500005dd500005dd500005dd500005dd5000000a00000000000000000000055500500000000c00ccc00
001111000077760000777600007776000077760005d66d5005d66d5005d66d5005d66d5005d66d50000aaa0000077000000000000555555500000000ccccccc0
01111110077777600777776007777760077cc760058888500599995005aaaa5005cccc5005cccc5000aaaaa000077100000000005005500500000000c00cc00c
11111111777777767777777677cccc7677cccc760d6666d00d6666d00d6666d00d6666d00d6666d0000a0a000071170000000000005555000000000000cccc00
111111117777777677cccc7677cccc7677cccc76565665655656656556566565565665655656656500a000a0000100100000000005500550000000000cc00cc0
01111110077777600777776007777760077777606d6556d66d6556d66d6556d66d6556d66d6556d60000000000000000000000005500005500000000cc0000cc
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
000000000000000000000000000076666666666666666657666666565757777777566656666567666656657777577577756d0000000000000000000000000000
0000000000000000000000000077666666656667676666667666766657757777775666666666666661666655777777755666dd00000000000000000000000000
000000000000000000000000076666667666666666766666666666665777777757566666666666666666666655555557666666d0000000000000000000000000
00000000000000000000000076667656666656666666666666666666577777777756666656d6666166665665667777766666616d000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000cccccccccccccccccccccccccccccccccccccccccccccc000000000000000000000000000000000000000000000000000000000000000000000
000000000000c0000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000000
000000000000c0011111111111111111111111111111111111111111100c00000000000000000000000000000000000000000000000000000000000000000000
000000000000c0100000000000000000000000000000000000000000010c00000000000000000000000000000000000000000000000000000000000000000000
000000000000c0100577777777777700057777000577770057777700010c00000000000000000000000000000000000000000000000000000000000000000000
000000000000c0105777777777777770577057705770577057705770010c00000000000000000000000000000000000000000000000000000000000000000000
00000cccccccc0105777005770057770577057705770577057705770010cccccccc0000000000000000000000000000000000000000000000000000000000000
0000c00000000010577700577005777057705770577057705770577001000000000c000000000000000000000000000000000000000000000000000000000000
0000c00111111110057700577005770005777700057777000570570001111111100c000000000000000000000000000000000000000000000000000000000000
0000c01000000000000000000000000000000000000000000000000000000000010c000000000000000000000000000000000000000000000000000000000000
0000c01000000000000000000000000000000000000000000000000000000000010c000000000000000000000000000000000000000000000000000000000000
0000c01060000060066666000666600066660066666000666000600060006666010c000000000000000000000000000000000000000000000000000000000000
0000c01066000660000600006600000660000000600006000600660060066000010c000000000000000000000000000000000000000000000000000000000000
0000c01066606660000600000666000066600000600006000600606060006660010c000000000000000000000000000000000000000000000000000000000000
0000c01060666060000600000006600000660000600006000600600660000066010c000000000000000000000000000000000000000000000000000000000000
0000c01060060060066666006666000666600066666000666000600060066660010c000000000000000000000000000000000000000000000000000000000000
0000c01000000000000000000000000000000000000000000000000000000000010c000000000000000000000000000000000000000000000000000000000000
0000c01000000000000000000000000000000000000000000000000000000000010c000000000000000000000000000000000000000000000000000000000000
0000c00111111111111111111111111111111111111111111111111111111111100c000000000000000000000000000000000000000000000000000000000000
0000c00000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000
00000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc0000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000060000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc777c7c7c77cccccc7ccc777c77cc77cc777c777cccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc77717171717ccccc71cc7171717c717c71117171ccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc717171717171cccc71cc77717171717177cc77c1ccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc717171717171cccc71cc717171717171711c717cccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc7171c7717171cccc777c717171717771777c7171ccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc1c1cc11c1c1ccccc111c1c1c1c1c111c111c1c1ccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111777171711111177177711771711177711771777111111771777177717771177111111111111111111111111111111111
11111111111111111111111111111111717171711111711177717171711171717171171111117111717177717111711111111111111111111111111111111111
11111111111111111111111111111111771177711111777171717171711177117171171111117111777171717711777111111111111111111111111111111111
11111111111111111111111111111111717111711111117171717171711171717171171111117171717171717111117111111111111111111111111111111111
11111111111111111111111111111111777177711111771171717711777177717711777111117771717171717771771111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000007770777077700770077000000777770000007770077000000770777077707770777000000000000000000000000000000
00000000000000000000000000000007171717171117011701100007717177000000711707100007011071171717171071100000000000000000000000000000
00000000000000000000000000000007771770177007770777000007770777100000710717100007770071077717701071000000000000000000000000000000
00000000000000000000000000000007111717071100171017100007717077100000710717100000171071071717170071000000000000000000000000000000
00000000000000000000000000000007100717177707701770100000777771100000710770100007701071071717171071000000000000000000000000000000
00000000000000000000000000000000100010101110110011000000011111000000010011000000110001001010101001000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000d666d66d6ddddddd00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000007767676665676666616666dddd5d00000000000000000000060000000000000000000000000000
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
00000000000000766666666666665666666566666676657777777566666666566666666661666657775666666666555766665656666665777d00600000000000
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
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111171717771777111117771111177711111777177711111777177717771777111111111111111111111111111111111111
11111111111111111111111111111111171717111717111117171111171711111717111711111117171711171717111111111111111111111111111111111111
11111111111111111111111111111111171717711771111117771111171711111777111711111777171717771717111111111111111111111111111111111111
11111111111111111111111111111111177717111717111117171111171711111717111711111711171717111717111111111111111111111111111111111111
11111111111111111111111111111111117117771717111117171171177711711777111711111777177717771777111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00766666666566667666665666666666666577756666577777775667676666666666666661666566665777777777777777777756666666665777566666666d00
055666666667666667666666666676666666555766657777777775666656666666666666666566666577777775777757777777756666666577777566566666d0
077566666666666766666666666676667666766666577777775777566666766666661656666666666577771777757777777577756616665775777756666616d0

__sfx__
00010000025500c5500355012550025500f5500655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005000000000276200962007610286100861006610026300160006600066001a5001a5001a5001a5001a5001a5001a5000060000600006000060000600016000260000600000000000000000000000000000000
000a000006524065240b5240f524105250352516525115251b525135251852512525295002b500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080000290102d010290103201033000310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000012042120421204214042120521405213052140521205212052100520e0521005210052100520f0520d0520e0520e0520e0520b0520b0520b0520e0520d05212052120521405212052110521205213052
