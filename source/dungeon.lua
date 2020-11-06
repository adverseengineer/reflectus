
local WALL_REGULAR = 0
local WALL_JOINED_H = 1
local WALL_JOINED_V = 2
local WALL_JOINED_Q = 3
local WALL_DOOR = 4

local color = require "color"

--if you are trying to understand these lines, just know it's something stupid and meta
Dungeon = {}
Dungeon.__index = Dungeon

--[[
i feel i ought to include an explanation of my wall lookup scheme because its not very intuitive
basically, the room data is a conventional grid, meant to be read the way it looks
the wall data is another beast though. wall data is the same size as room data, but twice as wide and minus one column
the reason for this is that for every cell in room data, there's 2 passable walls on its bottom and right edges.
the last room of every row only has one passable wall, hence the minus one
]]

--TODO: test
--creates a new dungeon, ready to be rendered
function Dungeon:new(map_width, map_height, num_iterations, quad_room_freq, h_double_room_freq, v_double_room_freq)
	--more meta garbage. constructors have to explicity return the new table
	local result_dungeon = {}
	setmetatable(result_dungeon, Dungeon)

	result_dungeon.room_data = {}
	result_dungeon.wall_data = {}

	--pre-allocate the room data and wall data
	for y = 1, map_height do
		result_dungeon.room_data[y] = {}
		result_dungeon.wall_data[y] = {}
		for x = 1, map_width do
			result_dungeon.room_data[y][x] = 0
		end
		for x = 1, map_width * 2 - 1, 1 do
			result_dungeon.wall_data[y][x] = 0
		end
	end

	--set the center room and begin the generation
	result_dungeon.room_data[math.ceil(map_height / 2)][math.ceil(map_width / 2)] = num_iterations
	result_dungeon:generate_rooms(vec2(math.ceil(map_width / 2), math.ceil(map_height / 2)), num_iterations, num_iterations)

	--spice up the dungeon
	--result_dungeon:make_quad_rooms(quad_room_freq)
	--result_dungeon:make_h_double_rooms(h_double_room_freq)
	--result_dungeon:make_v_double_rooms(v_double_room_freq)

	return result_dungeon
end

--TODO: test
--populates the dungeon by recursively branching off from the provided room
function Dungeon:generate_rooms(chosen_room, num_iterations, current_iteration)
	--base case: if we are on the last iteration, stop
	if current_iteration == 1 then
		return
	end

	--for each of the adjacent spaces
	local adjacent_cells = self:get_adjacent_cells(chosen_room)
	for i = 1, #adjacent_cells do
		--if the room passes the keep check and the space is not already taken (is zero)
		--NOTE: the chance to keep the room decreases gradually to zero, inversely proportional to the number of iterations that have passed
		if math.random() < math.mix(0, 1, current_iteration / num_iterations) and self:get_room(adjacent_cells[i]) == 0 then
			--add the room to the map
			self:set_room(current_iteration - 1, adjacent_cells[i])
			--add a door connecting the original room and the new room
			self:set_wall_from_room(WALL_DOOR, chosen_room, adjacent_cells[i])
			--and recurse with the room we just added
			self:generate_rooms(adjacent_cells[i], num_iterations, current_iteration - 1)
		end
	end
end

--TODO: test
--loops over the entire map and finds 2x2 groups of rooms
--every pair is given a roughly <frequency>% chance to become joined into a larger room
function Dungeon:make_quad_rooms(frequency)
	--for every cell in the map
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[y] do
			--if a 2x2 group exists here
			if self:get_room(vec2(x, y)) > 0
			and self:get_room(vec2(x + 1, y)) > 0
			and self:get_room(vec2(x, y + 1)) > 0
			and self:get_room(vec2(x + 1, y + 1)) > 0 then
				--if the group is connected by either regular walls or doors
				if (self:get_wall_from_rooms(vec2(x, y), vec2(x + 1, y)) == WALL_REGULAR or self:get_wall_from_rooms(vec2(x, y), vec2(x + 1, y)) == WALL_DOOR)
				and (self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 1, y + 1)) == WALL_REGULAR or self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 1, y + 1)) == WALL_DOOR)
				and (self:get_wall_from_rooms(vec2(x + 1, y + 1), vec2(x, y + 1)) == WALL_REGULAR or self:get_wall_from_rooms(vec2(x + 1, y + 1), vec2(x, y + 1)) == WALL_DOOR)
				and (self:get_wall_from_rooms(vec2(x, y + 1), vec2(x, y)) == WALL_REGULAR or self:get_wall_from_rooms(vec2(x, y + 1), vec2(x, y)) == WALL_DOOR) then
					--this huge block of conditions checks every wall connected to the candidate group. if ANY of them are already joined, the group is discarded
					if self:get_wall_from_rooms(vec2(x, y), vec2(x, y - 1)) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(vec2(x, y), vec2(x, y + 1)) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(vec2(x, y), vec2(x, y + 1)) ~= WALL_JOINED_V
					and	self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 1, y - 1)) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 1, y - 1)) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 1, y - 1)) ~= WALL_JOINED_V
					and self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 2, y)) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 2, y)) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 2, y)) ~= WALL_JOINED_V
					and self:get_wall_from_rooms(vec2(x + 1, y + 1), vec2(x + 2, y + 1)) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(vec2(x + 1, y + 1), vec2(x + 2, y + 1)) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(vec2(x + 1, y + 1), vec2(x + 2, y + 1)) ~= WALL_JOINED_V
					and	self:get_wall_from_rooms(vec2(x + 1, y + 1), vec2(x + 1, y + 2)) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(vec2(x + 1, y + 1), vec2(x + 1, y + 2)) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(vec2(x + 1, y + 1), vec2(x + 1, y + 2)) ~= WALL_JOINED_V
					and self:get_wall_from_rooms(vec2(x, y + 1), vec2(x, y + 2)) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(vec2(x, y + 1), vec2(x, y + 2)) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(vec2(x, y + 1), vec2(x, y + 2)) ~= WALL_JOINED_V
					and	self:get_wall_from_rooms(vec2(x, y + 1), vec2(x - 1, y + 1)) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(vec2(x, y + 1), vec2(x - 1, y + 1)) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(vec2(x, y + 1), vec2(x - 1, y + 1)) ~= WALL_JOINED_V
					and	self:get_wall_from_rooms(vec2(x, y), vec2(x - 1, y)) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(vec2(x, y), vec2(x - 1, y)) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(vec2(x, y), vec2(x - 1, y)) ~= WALL_JOINED_V then
						--if the rng passes the check
						if math.random() < frequency then
							--set the walls between the four rooms to be quad joined
							self:set_wall_from_rooms(WALL_JOINED_Q, vec2(x, y), vec2(x + 1, y))
							self:set_wall_from_rooms(WALL_JOINED_Q, vec2(x + 1, y), vec2(x + 1, y + 1))
							self:set_wall_from_rooms(WALL_JOINED_Q, vec2(x + 1, y + 1), vec2(x, y + 1))
							self:set_wall_from_rooms(WALL_JOINED_Q, vec2(x, y + 1), vec2(x, y))
							log("quad @"..vec2(x, y))
						end
					end
				end
			end
		end
	end
end

--TODO: test
--loops over the entire map and finds 2x1 groups of rooms
--every pair is given a roughly <frequency>% chance to become joined into a larger room
function Dungeon:make_h_double_rooms(frequency)
	--for every cell in the map
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[y] do
			--if a 2x1 group exists here, connected by a door
			if self:get_room(vec2(x, y)) > 0
			and self:get_room(vec2(x + 1, y)) > 0
			and self:get_wall(vec2(x, y), vec2(x + 1, y)) == WALL_DOOR then
				--this huge block of conditions checks every wall connected to the candidate group. if ANY of them are already joined, the group is discarded
				if self:get_wall_from_rooms(vec2(x, y), vec2(x - 1, y)) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(vec2(x, y), vec2(x - 1, y)) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(vec2(x, y), vec2(x - 1, y)) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 2, y)) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 2, y)) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 2, y)) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(vec2(x, y), vec2(x, y - 1)) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(vec2(x, y), vec2(x, y - 1)) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(vec2(x, y), vec2(x, y - 1)) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(vec2(x, y), vec2(x, y + 1)) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(vec2(x, y), vec2(x, y + 1)) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(vec2(x, y), vec2(x, y + 1)) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 1, y - 1)) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 1, y - 1)) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 1, y - 1)) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 1, y + 1)) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 1, y + 1)) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(vec2(x + 1, y), vec2(x + 1, y + 1)) ~= WALL_JOINED_V then
					--if the rng passes the check
					if(math.random() < frequency) then
						--set the walls between the group to be horizontally joined
						self:set_wall(WALL_JOINED_H, vec2(x, y), vec2(x + 1, y))
						log("hpair @"..vec2(x, y))
					end
				end
			end
		end
	end
end

--TODO: test
--loops over the entire map and finds 1x2 groups of rooms
--every pair is given a roughly <frequency>% chance to become joined into a larger room
function Dungeon:make_v_double_rooms(frequency)
	--for every cell in the map
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[y] do
			--if a 1x2 group exists here, connected by a door
			if self:get_room(vec2(x, y)) > 0
			and self:get_room(vec2(x, y + 1)) > 0
			and self:get_wall_from_rooms(vec2(x, y), vec2(x, y + 1)) == WALL_DOOR then
				--this huge block of conditions checks every wall connected to the candidate group. if ANY of them are already joined, the group is discarded
				if self:get_wall_from_rooms(vec2(x, y), vec2(x, y - 1)) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(vec2(x, y), vec2(x, y - 1)) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(vec2(x, y), vec2(x, y - 1)) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(vec2(x, y + 1), vec2(x, y + 2)) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(vec2(x, y + 1), vec2(x, y + 2)) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(vec2(x, y + 1), vec2(x, y + 2)) ~= WALL_JOINED_V
				and	self:get_wall_from_rooms(vec2(x, y), vec2(x - 1, y)) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(vec2(x, y), vec2(x - 1, y)) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(vec2(x, y), vec2(x - 1, y)) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(vec2(x, y), vec2(x + 1, y)) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(vec2(x, y), vec2(x + 1, y)) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(vec2(x, y), vec2(x + 1, y)) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(vec2(x, y + 1), vec2(x - 1, y + 1)) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(vec2(x, y + 1), vec2(x - 1, y + 1)) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(vec2(x, y + 1), vec2(x - 1, y + 1)) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(vec2(x, y + 1), vec2(x + 1, y + 1)) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(vec2(x, y + 1), vec2(x + 1, y + 1)) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(vec2(x, y + 1), vec2(x + 1, y + 1)) ~= WALL_JOINED_H then
					--if the rng passes the check
					if(math.random() < frequency) then
						self:set_wall_from_rooms(WALL_JOINED_VERTICAL, vec2(x, y), vec2(x, y + 1))
						log("vpair @"..vec2(x, y))
					end
				end
			end
		end
	end
end

--returns the room value at the provided room coords
function Dungeon:get_room(room_position)
	return self.room_data[room_position.y][room_position.x]
end

--returns the wall value at the provided wall coords
function Dungeon:get_wall(wall_position)
	return self.wall_data[wall_position.y][wall_position.x];
end

--returns the wall value between the provided room coords
function Dungeon:get_wall_from_rooms(room_1_position, room_2_position)
	return self:get_wall(self:get_wall_position(room_1_position, room_2_position))
end

--sets the room value at the provided coords
function Dungeon:set_room(value, room_position)
	self.room_data[room_position.y][room_position.x] = value
end

--sets the wall value at the provided coords
function Dungeon:set_wall(value, wall_position)
	self.wall_data[wall_position.y][wall_position.x] = value
end

--sets the wall value between the specified rooms coords
function Dungeon:set_wall_from_rooms(value, room_1_position, room_2_position)
	self:set_wall(value, self:get_wall_position(room_1_position, room_2_position))
end

--takes a vec2 as room coordinates and returns a list of the coords of all adjacent cells
function Dungeon:get_adjacent_cells(room_position)
	local adjacent_cells = {}

	if room_position.x > 0
	and room_position.x <= self:get_width()
	and room_position.y - 1 > 0
	and room_position.y - 1 <= self:get_height() then
		table.insert(adjacent_cells, vec2(room_position.x, room_position.y - 1))
	end
	if room_position.x + 1 > 0
	and room_position.x + 1 <= self:get_width()
	and room_position.y > 0
	and room_position.y <= self:get_height() then
		table.insert(adjacent_cells, vec2(room_position.x + 1, room_position.y))
	end
	if room_position.x > 0
	and room_position.x <= self:get_width()
	and room_position.y + 1 > 0
	and room_position.y + 1 <= self:get_height() then
		table.insert(adjacent_cells, vec2(room_position.x, room_position.y + 1))
	end
	if room_position.x - 1 > 0
	and room_position.x - 1 <= self:get_width()
	and room_position.y > 0
	and room_position.y <= self:get_height() then
		table.insert(adjacent_cells, vec2(room_position.x - 1, room_position.y))
	end

	return adjacent_cells
end

--returns the coords of the wall that lies between the provided room coords
function Dungeon:get_wall_position(room_1_position, room_2_position)
	assert(room_1_position ~= room_2_position, "given rooms are identical")
	assert(math.distance(room_1_position, room_2_position) == 1, "given rooms are non-adjacent")

	--if the rooms are vertically adjacent (x1 == x2)
	--the y coord of the wall will always be the smaller of the two rooms' y coords
	if room_1_position.x == room_2_position.x then
		return vec2(room_1_position.x + self:get_width() - 1, math.min(room_1_position.y, room_2_position.y))
	--if the rooms are horizontally adjacent (y1 == y2)
	--the x coord of the wall will always be the smaller of the two room's x coords
	else
		return vec2(math.min(room_1_position.x, room_2_position.x), room_1_position.y)
	end
end

--NOTE: thought out, needs testing
--takes the coordinates of a wall and returns the coords of the rooms it lies between
function Dungeon:get_room_positions(wall_position)
	--if the wall connects vertically
	if wall_position.x >= self:get_width() then
		return
			vec2(wall_position.x - self:get_width() + 1, wall_position.y),
			vec2(wall_position.x - self:get_width() + 1, wall_position.y + 1)
	--if the wall connects horizontally
	else
		return
			vec2(wall_position),
			vec2(wall_position.x + 1, wall_position.y)
	end
end

--returns the width of the map
function Dungeon:get_width()
	return #self.room_data[1]
end

--returns the height of the map
function Dungeon:get_height()
	return #self.room_data
end

--prints out the contents of the room data
function Dungeon:print_room_data()
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[y] do
			if self:get_room(vec2(x, y)) > 0 then
				io.write(self:get_room(vec2(x, y)).." ")
			else
				io.write(". ")
			end
		end
		print("")
	end
end

--prints out the contents of the wall data
function Dungeon:print_wall_data()
	for y = 1, #self.wall_data do
		for x = 1, #self.wall_data[y] do
			if self:get_wall(vec2(x, y)) > 0 then
				io.write(self:get_wall(vec2(x, y)).." ")
			else
				io.write(". ")
			end
		end
		print("")
	end
end

--TODO: as far as i can tell, everything else works now, so all that's left is to get this to render doors correctly
--NOTE: this function does not need to be efficient. it is only for verifying everything else works
--returns a node for a top-down view of the dungeon
function Dungeon:top_down(scale_factor, room_width, room_height, h_spacing, v_spacing)

	--declare a node to store the view
	local dungeon_view = am.scale(scale_factor)-- ^ am.translate(10, 10)

	--NOTE: any time x or y is used within these loops, you must subtract 1 to correct for lua's 1-based arrays
	--theyre a nice idea on paper but they suck when you start counting at zero from habit

	--for every room in the dungeon
	for y = 1, self:get_height() do
		for x = 1, self:get_width() do
			--if there is a room here
			if self:get_room(vec2(x, y)) > 0 then
				--append a rect for it
				dungeon_view:append(
					--NOTE: explaining this math so that it makes sense later
					--x and y are multiplied by their respective room dimension plus spacing so that no rooms overlap
					am.rect(
						(x - 1) * (room_width + h_spacing),
						(y - 1) * (room_height + v_spacing),
						(x - 1) * (room_width + h_spacing) + room_width,
						(y - 1) * (room_height + v_spacing) + room_height
					)
					--NOTE: the big scary block of coordinates above is unnecessary here, it just saves memory
					--if i wanted to make it cleaner, i could say this
					-- am.translate(vec2((x - 1) * (room_width + h_spacing), (y - 1) * (room_height + v_spacing)))
					-- ^ am.rect(0, 0, room_width, room_height)
				)
			end
		end
	end

	--for every wall in the dungeon
	--NOTE: make sure to use the dimensions of the wall data array, not get_width or get_height
	for y = 1, #self.wall_data do
		for x = 1, #self.wall_data[y] do
			--if there is a door in this spot
			if self:get_room(vec2(x, y)) == WALL_DOOR then
				local room1, room2 = self:get_room_positions(vec2(x, y))
				dungeon_view:append(
					am.line(
						vec2(
							(room1.x - 1) * (room_width + h_spacing) + room_width / 2,
							(room1.y - 1) * (room_height + v_spacing) + room_height / 2
						),
						vec2(
							(room2.x - 1) * (room_width + h_spacing) + room_width / 2,
							(room2.y - 1) * (room_height + v_spacing) + room_height / 2
						),
						1,
						color.magenta
					)
				)
			end
		end
	end

	return dungeon_view
end
