--possible names
--reflectus
--refractus

--new terminology
	--action: a function that is run once per frame by a window's scene
	--scene graph: the collection of nodes owned by a window's scene
	--node: similar to a gameobject in unity. can be used to make a scene hierarchy
		--nodes have tags that correspond to their names so `scene"string"` accesses all nodes named string


--new tricks
	--any node can be given a tag
	--all nodes with a given tag can be accessed at once with scene("tagName")
	--functions are treated as values, so you can assign a function to a variable
	--you can also assign a function as a member of an array (think behavior tables)
	--lua can return multiple values from a function (function f() \ return 1, 2 \ end \ local a, b = f()`)
	--when initializing a vector, you can provide just one arg and it will set all components to that
	--you can create vectors from any combination of other vectors and numbers as long as you use the proper number of values for the vector
	--each component of a vector has multiple names: 1 = x,r,s; 2 = y,g,t; 3 = z,b,p; 4 = w,a,q
	--if you have `a = vec4(1,2,3,4)` and say `b = vec4(a.rgg, -4)` then b gets `1,2,2,-4`. (these are called swizzle fields)
	--vectors are immutable, but you can use a little syntax magic to do this: `v1 = v1{y = 10}` this updates just the y component. (this is called vector update syntax)
	--you can also use swizzle fields with the last trick: `v1 = v1{xy = vec2(0), zw = vec2(1)}` this produces a vector containing `0,0,1,1`

--lua quirks
	--lua has all the regular kinds of loops, but also has a "repeat-until" loop (repeat statements until condition)
	--`#arr` means length of array. it also works with amulet vectors
	--array indexes start at 1
	--for all it's amazing shorthand and syntax magic, lua lacks assignment operators and increment/decrement. you have to do `a = a + b`
	--you can't even increment a vector component's value with this: `vec = vec{x = x + 1}` so do without the update syntax on those

local red = vec4(1, 0, 0, 1)
local blue = vec4(0, 0, 1, 1)
local green = vec4(0, 1, 0, 1)

local screen_width = 960
local screen_height = 720

local player_position = vec2(0)

--creates a window
local win = am.window{
	title = "Reflectus",
	width = screen_width,
	height = screen_height,
	clear_color = blue
}

--assigns a group node and assigns the contents of the group node
--think of this like setting up the scene hierarchy in unity
win.scene = am.group() ^
{
	am.rect(-screen_width/2,-200,screen_width/2,-500, green),

	am.translate(vec2(0)):tag"player"
	^ am.rotate(0):tag"player_spin"
	^ am.circle(vec2(0,0), 50, red,3),
}

--the "game loop"
--NOTE: a scene action is the closest thing you have in amulet to a conventional game loop
win.scene:action(function(scene)

		player_position = player_position + get_input(300) * am.delta_time

		scene"player".position = vec3(player_position, 0)

		if win:key_pressed"space" then
			scene"player_spin".angle = scene"player_spin".angle + math.rad(90)
		end

		if win:key_down"escape" then
			-- this is how you would iterate over a grid
			-- local grid = {
  			-- 	{ 11, 12, 13 },
			-- 	{ 21, 22, 23 },
			-- 	{ 31, 32, 33 }
			-- }
			--
			-- for y, row in ipairs(grid) do
  			-- 	for x, value in ipairs(row) do
    		-- 		print(x, y, grid[y][x])
  			-- 	end
			-- end
			win:close()
		end
end)

--takes keyboard input and returns a vector representing the players movement for this frame. multiplies the vector by speed_multiplier
function get_input(speed_multiplier)
	local move = vec2(0)

	if win:key_down"w" then
		move = vec2(move.x, move.y + 1)
	elseif win:key_down"s" then
		move = vec2(move.x, move.y - 1)
	end

	if win:key_down"a" then
		move = vec2(move.x - 1, move.y)
	elseif win:key_down"d" then
		move = vec2(move.x + 1, move.y)
	end

	return move * speed_multiplier
end
