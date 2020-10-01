cur={x=0,y=0}
alphabet="abcdefghijklmnopqrstuvwxyz "
chars=split(alphabet,"")
textpos=40
saved=false
name=""

function _init()
	
end

function _update()
	--left
 if(btnp(0)) then
 	if(cur.x>0) cur.x-=1
 end
 
 --right
 if(btnp(1)) then
 	if(cur.x<8) cur.x+=1
 end
 
 --up
 if(btnp(2)) then
 	if(cur.y>0) cur.y-=1
 end
 
 --down
 if(btnp(3)) then
 	if(cur.y<3) cur.y+=1
 end
 
 if(btnp(4)) then
  if(#name<12 and cur.y<3) then
 		local c=(cur.x+1)+(cur.y*9)
 		name=name..chars[c]
 	elseif(name!="") then
 		saved=true
 	end
 end
 
 if(btnp(5)) then
 	name=sub(name,0,#name-1)
 end
end

function _draw()
 cls()
 
 if(saved==false) then
 	print("name: ",20,30,7)
 	draw_cursor()
 	draw_alphabet()
 	draw_name()
 	print("[save]",50,80,6)
	else
		print("saved!",50,50,12)
	end
end

function draw_name()
	print(name,43,30,12)
end

function draw_cursor()
	if(cur.y<3) then
		rectfill(20+(cur.x*10),
			44+(cur.y*10),
			24+(cur.x*10),
			50+(cur.y*10),
			12)
	else
		rectfill(49,79,73,85,12)
	end
end

function draw_alphabet()
 local pos=1

	for i=0,2 do
 	for j=0,8 do
 		print(chars[pos],
 			21+(j*10),
 			45+(i*10),6)
 		pos+=1 		
 	end
 end
end