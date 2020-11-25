
--the window has to be created before the requires because some of them involve shaders and you can't link shaders until a window is created
win = am.window{
	title = "Reflectus",
	mode = "windowed",
	width = 1280,
	height = 960,
	lock_pointer = true,
	clear_color = vec4(0, 1, 1, 1),
	depth_buffer = true
}

require "keys"
require "colors"
require "models"
require "shaders"
require "dungeon"
noglobals()
math.randomseed(os.time())

local fov = 60
local near_clip = 1
local far_clip = 1000
local minimum_pitch
local min_y_look = -80
local max_y_look = 80

local mouse_sensitivity_x = 1
local mouse_sensitivity_y = 1
local walk_speed = 20
local strafe_speed = 10
local enemy_speed = 0.04
local enemy_acceleration = 0.005
local enemy_reach = 2

local dungeon_width = 16
local dungeon_height = 16
local dungeon_complexity = 18
local quad_room_freq = 0.4
local horizontal_double_room_freq = 0.4
local veritcal_double_room_freq = 0.4
local room_width = 3
local room_height = 3

local level_vertical_scale = 5
local level_horizontal_scale = 5

local start_position = vec3(
	((math.floor(dungeon_width / 2) - 1) * (room_width + 1) + room_width / 2),
	3,
	(math.floor(dungeon_height / 2) - 1) * (room_height + 1) + room_height / 2
) * level_horizontal_scale

--a table to store player info like postion and orientation
local player = {
	position = start_position,
	pitch = 0, --NOTE: pitch is look up/down
	yaw = 0, --NOTE: yaw is look left/right
	forward = vec3(0), --a vector representing forward, relative to the direction the player is facing
	turn_speed = math.rad(90)
}

--this is here because i cant set it inside the player table initializer because you can't reference yaw inside the table it's still being declared in
player.forward = vec3(math.sin(player.yaw), 0, -math.cos(player.yaw))

--TODO: make this work and use it
--returns a wrap node that combines all of a transform's data under one name
--position and scale are vec3's, and rotation is a quat
-- local function full_transform(position, rotation, scale)
-- 	return am.wrap(
-- 		am.translate(position)
-- 		^ am.rotate(rotation)
-- 		^ am.scale(scale)
-- 	)
-- end

--set up a camera with the default matrices
local camera = am.bind{
	MV = mat4(1),
	P = mat4(1)
}

--updates the camera's model view matrix according to the player's position and orientation
local function update_camera()
	--the updated mv is the player's up/down rotation as a matrix multiplied by a lookat matrix of the direction the player is facing
	--NOTE: the vector here is pointing left so that positive pitch is up and negative pitch is down rather than the default of negative being up
	camera.MV = mat4(quat(player.pitch, vec3(-1, 0, 0))) * math.lookat(player.position, player.position + player.forward, vec3(0, 1, 0))
	camera.P = math.perspective(math.rad(fov), win.width / win.height, near_clip, far_clip)
end

--set up the dungeon by scaling and moving it into place
local dungeon =
	am.scale(level_horizontal_scale, level_vertical_scale, level_horizontal_scale)
	^ Dungeon:new(dungeon_width, dungeon_height, dungeon_complexity, quad_room_freq, horizontal_double_room_freq, veritcal_double_room_freq):create_level(room_width, room_height)

--the monkey ghost thing that follows the player
local enemy = am.translate(vec3(0)) ^ am.rotate(quat(0, vec3(0, 1, 0))) ^ models.le_monke

--stitch the scene together from all the pieces
win.scene = camera ^ am.group{dungeon, enemy}


--player input is done every frame
win.scene:action("player_movement", function(scene)
	--look left/right
	--NOTE: wraps back to 0 at 2pi
	player.yaw = (player.yaw + win:mouse_norm_delta().x * mouse_sensitivity_x) % (2 * math.pi)
	--look up/down
	player.pitch = math.clamp(player.pitch + win:mouse_norm_delta().y * mouse_sensitivity_y, math.rad(min_y_look), math.rad(max_y_look))

	--if the player is holding the alt left or right keys, increment or decrement the yaw
	if win:key_down(keys.left_alt) then
		player.yaw = player.yaw - player.turn_speed * am.delta_time
	elseif win:key_down(keys.right_alt) then
		player.yaw = player.yaw + player.turn_speed * am.delta_time
	end

	--calculate the new forward
	player.forward = vec3(math.sin(player.yaw), 0, -math.cos(player.yaw))

	--if the player is holding forward or backward, or the alts, move along the forward vector
	if win:key_down(keys.up) or win:key_down(keys.up_alt) then
		player.position = player.position + vec3(player.forward.x, 0, player.forward.z) * walk_speed * am.delta_time
	elseif win:key_down(keys.down) or win:key_down(keys.down_alt) then
		player.position = player.position - vec3(player.forward.x, 0, player.forward.z) * walk_speed * am.delta_time
	end

	--if the player is holding left or right, move along a vector perpendicular to the forward vector
	if win:key_down(keys.left) then
		player.position = player.position - vec3(math.cos(player.yaw), 0, math.sin(player.yaw)) * strafe_speed * am.delta_time
	elseif win:key_down(keys.right) then
		player.position = player.position + vec3(math.cos(player.yaw), 0, math.sin(player.yaw)) * strafe_speed * am.delta_time
	end

	--TODO: push player back if intersecting wall

	update_camera()
end)

--NOTE: this block is the sloppiest because i wrote it with 3 hours on the clock
enemy:action("enemy_movement", function(node)
	local vec_between = player.position - node"translate".position

	--make the enemy always face toward the player
	local angle_to_face_player = math.rad(90) - math.atan2(vec_between.z, vec_between.x)
	node"rotate".rotation = quat(angle_to_face_player, vec3(0, 1, 0))

	--NOTE: this code was adapted from Unity's Vector3.MoveTowards()
	--slowly approach the player
	local sqdist = vec_between.x ^ 2 + vec_between.y ^ 2 
	if sqdist == enemy_reach or (enemy_speed >= 0 and sqdist <= enemy_speed ^ 2) then
		node"translate".position = player.position
	else
		node"translate".position = node"translate".position + vec_between / math.sqrt(sqdist) * enemy_speed
	end

	--NOTE: this was supposed to be the code that checks if you are looking at him, but i didnt have time
	-- log(math.dot(node"translate".position.xz, player.forward.xz))

	--NOTE: i dont have time to balance this right now so im cutting it
	-- --increase the enemy's speed
	-- enemy_speed = enemy_speed + enemy_acceleration
end)

--NOTE: disabling this feature for the demo
--if the enemy gets within reach of the player, exit the game
-- enemy:action("death_check", function(node)
-- 	if math.distance(player.position, node"translate".position) <= enemy_reach then
-- 		win:close()
-- 	end
-- end)

local looking_back = false
-- look backwards when the player hits the reflect key
win.scene:action("look_behind", function(scene)
	if win:key_pressed(keys.reflect) or win:key_released(keys.reflect) then
		camera.MV = camera.MV * math.scale4(vec3(1, 1, -1))
	end
end)

--respond to any meta inputs later
win.scene:late_action("meta_controls", function(scene)
	--if the cursor is locked and exit requested, unlock the cursor
	--if the cursor is unlock and exit requested, exit
	if win:key_pressed(keys.exit) then
		if win.lock_pointer then
			win.lock_pointer = false
		else
			win:close()
		end
	end

	--if the cursor is unlocked and the player clicks, lock it
	if not win.lock_pointer then
		if win:mouse_pressed"left" or win:mouse_pressed"middle" or win:mouse_pressed"right" then
			win.lock_pointer = true
		end
	end

	--toggle fullscreen
	if win:key_pressed(keys.toggle_fullscreen) then
		if win.mode == "windowed" then
			win.mode = "fullscreen"
		else
			win.mode = "windowed"
		end
	end
end)

win.scene:late_action(function(scene)
	if win:resized() then
		update_camera()
	end
end)
