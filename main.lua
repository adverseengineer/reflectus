
--the window has to be created before the requires because some of them involve shaders and you can't link shaders until a window is created
win = am.window{
	title = "Reflectus",
	mode = "windowed",
	width = 300,--1280,
	height = 300,--960,
	--lock_pointer = true,
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

local fullscreen = true
local fov = 60
local near_clip = 1
local far_clip = 1000
local minimum_pitch

local mouse_sensitivity_x = 1
local mouse_sensitivity_y = 1
local walk_speed = 20
local strafe_speed = 15

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

local up = vec3(0, 1, 0)
local right = vec3(1, 0, 0)

--a table to store player info like postion and orientation
local player = {
	position = vec3(0),
	pitch = 0, --NOTE: pitch is look up/down
	yaw = 0, --NOTE: yaw is look left/right
	forward = vec3(0), --a vector representing forward, relative to the direction the player is facing
	turn_speed = math.rad(90)
}
--this is here because i cant set it inside the player table initializer because you can't reference yaw inside the table it's still being declared in
player.forward = vec3(math.sin(player.yaw), 0, -math.cos(player.yaw))

--set up a camera with the default matrices
local camera = am.bind{
	MV = mat4(1),
	P = mat4(1)
}

--updates the camera's model view matrix according to the player's position and orientation
local function update_camera()
	--the updated mv is the player's up/down rotation as a matrix multiplied by a lookat matrix of the direction the player is facing
	--NOTE: the vectore here is pointing left so that positive pitch is up and negative pitch is down rather than the default of negative being up
	camera.MV = mat4(quat(player.pitch, vec3(-1, 0, 0))) * math.lookat(player.position, player.position + player.forward, up)
	camera.P = math.perspective(math.rad(fov), win.width / win.height, near_clip, far_clip)
end

--set up the dungeon by scaling and moving it into place
local dungeon = am.scale(level_horizontal_scale, level_vertical_scale, level_horizontal_scale)
	^ Dungeon:new(dungeon_width, dungeon_height, dungeon_complexity, quad_room_freq, horizontal_double_room_freq, veritcal_double_room_freq):create_level(room_width, room_height)

--is prepended to a scene node to invert it's colors
--TODO: make this work
local inverter = am.postprocess{
	depth_buffer = true,
	program = shaders.inverted
}

--stitch the scene together from the locals
win.scene = camera ^ dungeon

--move the camera
camera.MV = camera.MV * math.translate4(0, -50, 0)
camera.MV = camera.MV * math.rotate4(math.rad(45), vec3(1, 0, 0))

--player input is done every frame
win.scene:action(function(scene)
	--look left/right
	--NOTE: wraps back to 0 at 2pi
	player.yaw = (player.yaw + win:mouse_norm_delta().x * mouse_sensitivity_x) % (2 * math.pi)
	--look up/down
	player.pitch = math.clamp(player.pitch + win:mouse_norm_delta().y * mouse_sensitivity_y, -math.pi/2, math.pi/2)

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

	update_camera()
end)

--respond to any meta inputs later
win.scene:late_action(function(scene)
	if win:key_down(keys.quit) then
		win:close()
	end
	if win:key_pressed(keys.toggle_fs) then
		fullscreen = not fullscreen
		if fullscreen then
			win.mode = "fullscreen"
		else
			win.mode = "windowed"
		end
	end
end)

-- win.scene:late_action(function(scene)
-- 	log("\npitch: %d\nyaw:   %d", math.deg(player.pitch), math.deg(player.yaw))
-- end)

--TODO: comment this block out before release
-- win.scene:late_action(function(scene)
-- 	log(table.tostring(am.perf_stats()))
-- end)