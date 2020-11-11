require "keys"

--just meta stuff that lua needs to emulate OOP
Player = {}
Player.__index = Player

function Player:new(position, xz_speed, jump_speed, gravity)
	--more meta
	local result_player = {}
	setmetatable(result_player, Player)

	result_player.position = position
	result_player.xz_speed = xz_speed
	result_player.jump_speed = jump_speed
	result_player.gravity = gravity
	result_player.is_grounded = false
	result_player.y_speed = 0

	return result_player
end

--moves the player based on keyboard input
function Player:move(window, floor_y)
	--up/down
	if window:key_down(keys.up)  or window:key_down(keys.up_alt) then
		self.position = vec3(self.position.xy, self.position.z + self.xz_speed * am.delta_time)
	elseif window:key_down(keys.down) or window:key_down(keys.down_alt) then
		self.position = vec3(self.position.xy, self.position.z - self.xz_speed * am.delta_time)
	end
	--left/right
	if window:key_down(keys.left) or window:key_down(keys.left_alt) then
		self.position = vec3(self.position.x - self.xz_speed * am.delta_time, self.position.yz)
	elseif window:key_down(keys.right) or window:key_down(keys.right_alt)  then
		self.position = vec3(self.position.x + self.xz_speed * am.delta_time, self.position.yz)
	end
	--jump
	if self.is_grounded and window:key_pressed(keys.jump) then
		self.y_speed = self.jump_speed
		self.is_grounded = false
	end
	--apply gravity
	log(self.y_speed)
	self.y_speed = self.y_speed - self.gravity * am.delta_time
	self.position = vec3(self.position.x, self.position.y + self.y_speed * am.delta_time, self.position.z)
	--land
	if self.position.y < floor_y then
		self.position = vec3(self.position.x, floor_y, self.position.z)
		self.y_speed = 0
		self.is_grounded = true
	end
end

local win = am.window{}
win.scene = am.group()

local player = Player:new(vec3(0, 0, 0), 4, 100, 100)

win.scene:action(function()
	player:move(win, 0)
	log(player.position)
end)
