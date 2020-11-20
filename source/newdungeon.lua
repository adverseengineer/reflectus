
local WALL_REGULAR = 0
local WALL_JOINED_H = 1
local WALL_JOINED_V = 2
local WALL_JOINED_Q = 3
local WALL_DOOR = 4

require "colors"

--just meta stuff that lua needs to emulate OOP
Dungeon = {}
Dungeon.__index = Dungeon

--creates a new dungeon, ready to be rendered
function Dungeon:new(map_width, map_height, num_iterations, quad_room_freq, h_double_room_freq, v_double_room_freq)
	--more meta garbage. constructors have to explicity return the new table
	local result_dungeon = {}
	setmetatable(result_dungeon, Dungeon)

	result_dungeon.room_data = {}
	result_dungeon.h_wall_data = {}
	result_dungeon.v_wall_data = {}

	--pre-allocate the room data and wall data
	for y = 1, map_height do
		result_dungeon.room_data[y] = {}
		result_dungeon.h_wall_data[y] = {}
		result_dungeon.v_wall_data[y] = {}
		for x = 1, map_width do
			result_dungeon.room_data[y][x] = 0
			result_dungeon.h_wall_data[y][x] = 0
			result_dungeon.v_wall_data[y][x] = 0
		end
	end

	--set the center room and begin the generation
	result_dungeon.room_data[math.ceil(map_height / 2)][math.ceil(map_width / 2)] = num_iterations
	result_dungeon:generate_rooms(vec2(math.ceil(map_width / 2), math.ceil(map_height / 2)), num_iterations, num_iterations)

	--spice up the dungeon
	-- result_dungeon:make_quad_rooms(quad_room_freq)
	-- result_dungeon:make_h_double_rooms(h_double_room_freq)
	-- result_dungeon:make_v_double_rooms(v_double_room_freq)

	return result_dungeon
end

--populates the dungeon by recursively branching off from the provided room coords
function Dungeon:generate_rooms(chosen_room_x, chosen_room_y, num_iterations, current_iteration)
	--sanity check: if this fails, the algorithm would have infinitely looped
	assert(current_iteration / num_iterations > 0 and current_iteration / num_iterations <= 1, "current_iteration was higher than num_iterations")
	--base case: if we are on the last iteration, stop
	if current_iteration == 1 then
		return
	end

	--for each of the adjacent spaces
	local adjacent_cells = self:get_adjacent_cells(chosen_room_x, chosen_room_y)
	for i = 1, #adjacent_cells do
		--NOTE: the chance to keep the room decreases gradually to zero, inversely proportional to the number of iterations that have passed
		--if the room passes the keep check and the space is not already taken (is zero)
		if math.random() < current_iteration / num_iterations and self:get_room(adjacent_cells[i]) == 0 then
			--add the room to the map
			self:set_room(current_iteration - 1, adjacent_cells[i])
			--add a door connecting the original room and the new room
			self:set_wall_from_rooms(WALL_DOOR, chosen_room_x, chosen_room_y, adjacent_cells[i].x, adjacent_cells[i].y)
			--and recurse with the room we just added
			self:generate_rooms(adjacent_cells[i].x, adjacent_cells[i].y, num_iterations, current_iteration - 1)
		end
	end
end

--loops over the entire map and finds 2x2 groups of rooms
--every pair is given a roughly <frequency>% chance to become joined into a larger room
function Dungeon:make_quad_rooms(frequency)
	--for every cell in the map
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[1] do
			--if a 2x2 group exists here
			if self:get_room(x, y) > 0
			and self:get_room(x + 1, y) > 0
			and self:get_room(x, y + 1) > 0
			and self:get_room(x + 1, y + 1) > 0 then
				--if the group is connected by either regular walls or doors
				if (self:get_wall_from_rooms(x, y, x + 1, y) == WALL_REGULAR or self:get_wall_from_rooms(x, y, x + 1, y) == WALL_DOOR)
				and (self:get_wall_from_rooms(x + 1, y, x + 1, y + 1) == WALL_REGULAR or self:get_wall_from_rooms(x + 1, y, x + 1, y + 1) == WALL_DOOR)
				and (self:get_wall_from_rooms(x + 1, y + 1, x, y + 1) == WALL_REGULAR or self:get_wall_from_rooms(x + 1, y + 1, x, y + 1) == WALL_DOOR)
				and (self:get_wall_from_rooms(x, y + 1, x, y) == WALL_REGULAR or self:get_wall_from_rooms(x, y + 1, x, y) == WALL_DOOR) then
					--this huge block of conditions checks every wall connected to the candidate group. if ANY of them are already joined, the group is discarded
					if self:get_wall_from_rooms(x, y, x, y - 1) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(x, y, x, y - 1) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(x, y, x, y - 1) ~= WALL_JOINED_V
					and	self:get_wall_from_rooms(x + 1, y, x + 1, y - 1) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(x + 1, y, x + 1, y - 1) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(x + 1, y, x + 1, y - 1) ~= WALL_JOINED_V
					and self:get_wall_from_rooms(x + 1, y, x + 2, y) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(x + 1, y, x + 2, y) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(x + 1, y, x + 2, y) ~= WALL_JOINED_V
					and self:get_wall_from_rooms(x + 1, y + 1, x + 2, y + 1) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(x + 1, y + 1, x + 2, y + 1) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(x + 1, y + 1, x + 2, y + 1) ~= WALL_JOINED_V
					and	self:get_wall_from_rooms(x + 1, y + 1, x + 1, y + 2) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(x + 1, y + 1, x + 1, y + 2) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(x + 1, y + 1, x + 1, y + 2) ~= WALL_JOINED_V
					and self:get_wall_from_rooms(x, y + 1, x, y + 2) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(x, y + 1, x, y + 2) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(x, y + 1, x, y + 2) ~= WALL_JOINED_V
					and	self:get_wall_from_rooms(x, y + 1, x - 1, y + 1) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(x, y + 1, x - 1, y + 1) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(x, y + 1, x - 1, y + 1) ~= WALL_JOINED_V
					and	self:get_wall_from_rooms(x, y, x - 1, y) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(x, y, x - 1, y) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(x, y, x - 1, y) ~= WALL_JOINED_V then
						--if the rng passes the check
						if math.random() < frequency then
							--set the walls between the four rooms to be quad joined
							self:set_wall_from_rooms(WALL_JOINED_Q, x, y, x + 1, y)
							self:set_wall_from_rooms(WALL_JOINED_Q, x + 1, y, x + 1, y + 1)
							self:set_wall_from_rooms(WALL_JOINED_Q, x + 1, y + 1, x, y + 1)
							self:set_wall_from_rooms(WALL_JOINED_Q, x, y + 1, x, y)
						end
					end
				end
			end
		end
	end
end

--loops over the entire map and finds 2x1 groups of rooms
--every pair is given a roughly <frequency>% chance to become joined into a larger room
function Dungeon:make_h_double_rooms(frequency)
	--for every cell in the map
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[1] do
			--if a 2x1 group exists here, connected by a door
			if self:get_room(x, y) > 0
			and self:get_room(x + 1, y) > 0
			and self:get_wall(x, y, x + 1, y) == WALL_DOOR then
				--this huge block of conditions checks every wall connected to the candidate group. if ANY of them are already joined, the group is discarded
				if self:get_wall_from_rooms(x, y, x - 1, y) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(x, y, x - 1, y) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(x, y, x - 1, y) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(x + 1, y, x + 2, y) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(x + 1, y, x + 2, y) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(x + 1, y, x + 2, y) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(x, y, x, y - 1) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(x, y, x, y - 1) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(x, y, x, y - 1) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(x, y, x, y + 1) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(x, y, x, y + 1) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(x, y, x, y + 1) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(x + 1, y, x + 1, y - 1) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(x + 1, y, x + 1, y - 1) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(x + 1, y, x + 1, y - 1) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(x + 1, y, x + 1, y + 1) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(x + 1, y, x + 1, y + 1) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(x + 1, y, x + 1, y + 1) ~= WALL_JOINED_V then
					--if the rng passes the check
					if math.random() < frequency then
						--set the walls between the group to be horizontally joined
						self:set_wall_from_rooms(WALL_JOINED_H, x, y, x + 1, y)
					end
				end
			end
		end
	end
end

--loops over the entire map and finds 1x2 groups of rooms
--every pair is given a roughly <frequency>% chance to become joined into a larger room
function Dungeon:make_v_double_rooms(frequency)
	--for every cell in the map
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[1] do
			--if a 1x2 group exists here, connected by a door
			if self:get_room(x, y) > 0
			and self:get_room(x, y + 1) > 0
			and self:get_wall_from_rooms(x, y, x, y + 1) == WALL_DOOR then
				--this huge block of conditions checks every wall connected to the candidate group. if ANY of them are already joined, the group is discarded
				if self:get_wall_from_rooms(x, y, x, y - 1) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(x, y, x, y - 1) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(x, y, x, y - 1) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(x, y + 1, x, y + 2) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(x, y + 1, x, y + 2) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(x, y + 1, x, y + 2) ~= WALL_JOINED_V
				and	self:get_wall_from_rooms(x, y, x - 1, y) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(x, y, x - 1, y) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(x, y, x - 1, y) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(x, y, x + 1, y) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(x, y, x + 1, y) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(x, y, x + 1, y) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(x, y + 1, x - 1, y + 1) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(x, y + 1, x - 1, y + 1) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(x, y + 1, x - 1, y + 1) ~= WALL_JOINED_V
				and self:get_wall_from_rooms(x, y + 1, x + 1, y + 1) ~= WALL_JOINED_Q
				and self:get_wall_from_rooms(x, y + 1, x + 1, y + 1) ~= WALL_JOINED_H
				and self:get_wall_from_rooms(x, y + 1, x + 1, y + 1) ~= WALL_JOINED_H then
					--if the rng passes the check
					if math.random() < frequency then
						--set the wall between the group to be vertically joined
						self:set_wall_from_rooms(WALL_JOINED_V, x, y, x, y + 1)
					end
				end
			end
		end
	end
end

--TODO: test
--returns the room value at the provided room coords
--if invalid coords are given, returns -1
function Dungeon:get_room(room_x, room_y)
	if room_x > 0
	and room_y > 0
	and room_x <= #self.room_data
	and room_y <= #self.room_data[1] then
		return self.room_data[room_y][room_x]
	else
		return -1
	end
end

--TODO: test
--returns the wall value at the provided wall coords in the horizontal wall data
--if invalid coords are given, returns -1
function Dungeon:get_h_wall(wall_x, wall_y)
	if wall_x > 0
	and wall_y > 0
	and wall_x <= #self.h_wall_data[1]
	and wall_y <= #self.h_wall_data then
		return self.wall_h_data[wall_y][wall_x];
	else
		return -1
	end
end

--TODO: test
--returns the wall value at the provided wall coords in the horizontal wall data
--if invalid coords are given, returns -1
function Dungeon:get_v_wall(wall_x, wall_y)
	if wall_x > 0
	and wall_y > 0
	and wall_x <= #self.v_wall_data[1]
	and wall_y <= #self.v_wall_data then
		return self.wall_v_data[wall_y][wall_x];
	else
		return -1
	end
end

--TODO: test
--returns the wall value between the provided room coords
function Dungeon:get_wall_from_rooms(room_1_x, room_2_y, room_2_x, room_2_y)
	--do a couple sanity checks
	assert(room_1_x ~= room_2_x and room_2_x ~= room_2_y, "given rooms are identical")
	assert(math.abs(room_1_x - room_2_x) == 1 or math.abs(room_1_y - room_2_y) == 1, " given rooms are non-adjacent")	

	--if we got through those two asserts, then the following logic should be bulletproof
	--if the rooms are horizontally adjacent
	if room_1_y == room_2_y then
		--NOTE: doors are associated with the room above or to the left of them
		--NTOE: therefore, the upper-leftmost room of any adjacent pair will always be the one whose coords are the same as the door
		return self.h_wall_data[math.min(room_1_y, room_2_y)][math.min(room_1_x, room_2_x)]
	--if the rooms are vertically adjacent
	elseif room_1_x == room_2_x then
		return self.v_wall_data[math.min(room_1_y, room_2_y)][math.min(room_1_x, room_2_x)]
	end
end

--TODO: test
--sets the room value at the provided coords
function Dungeon:set_room(value, room_x, room_y)
	if room_x > 0
	and room_y > 0
	and room_x <= #self.room_data[1]
	and room_y <= #self.room_data then
		self.room_data[room_y][room_x] = value
	end
end

--TODO: test
--sets the horizontal wall value at the provided coords
function Dungeon:set_h_wall(value, wall_x, wall_y)
	if wall_x > 0
	and wall_y > 0
	and wall_x <= #self.h_wall_data[1]
	and wall_y <= #self.h_wall_data then
		self.h_wall_data[wall_y][wall_x] = value
	end
end

--TODO: test
--sets the vertical wall value at the provided coords
function Dungeon:set_v_wall(value, wall_x, wall_y)
	if wall_x > 0
	and wall_y > 0
	and wall_x <= #self.v_wall_data[1]
	and wall_y <= #self.v_wall_data then
		self.v_wall_data[wall_y][wall_x] = value
	end
end

--TODO: test
--sets the wall value between the specified rooms coords
function Dungeon:set_wall_from_rooms(value, room_1_x, room_1_y, room_2_x, room_2_y)
	--same as before, validate the coords given
	assert(room_1_x ~= room_2_x and room_2_x ~= room_2_y, "given rooms are identical")
	assert(math.abs(room_1_x - room_2_x) == 1 or math.abs(room_1_y - room_2_y) == 1, " given rooms are non-adjacent")	

	--if we got through those two asserts, then the following logic should be bulletproof
	--if the rooms are horizontally adjacent
	if room_1_y == room_2_y then
		--NOTE: doors are associated with the room above or to the left of them
		--NTOE: therefore, the upper-leftmost room of any adjacent pair will always be the one whose coords are the same as the door
		self.h_wall_data[math.min(room_1_y, room_2_y)][math.min(room_1_x, room_2_x)] = value
	--if the rooms are vertically adjacent
	elseif room_1_x == room_2_x then
		self.v_wall_data[math.min(room_1_y, room_2_y)][math.min(room_1_x, room_2_x)] = value
	end
end

--TODO: test
--takes two room coords and returns a table of the coords of all adjacent cells
function Dungeon:get_adjacent_cells(room_x, room_y)
	local adjacent_cells = {}

	if room_x > 0 and room_x <= #self.room_data[1] and room_y - 1 > 0 and room_y - 1 <= #self.room_data then
		table.insert(adjacent_cells, {x = room_x, y = room_y - 1})
	end
	if room_x + 1 > 0 and room_x + 1 <= #self.room_data[1] and room_y > 0 and room_y <= #self.room_data then
		table.insert(adjacent_cells, {x = room_x + 1, y = room_y})
	end
	if room_x > 0 and room_x <= #self.room_data[1] and room_y + 1 > 0 and room_y + 1 <= #self.room_data then
		table.insert(adjacent_cells, {x = room_x, y = room_y + 1})
	end
	if room_x - 1 > 0 and room_x - 1 <= #self.room_data[1] and room_y > 0 and room_y <= #self.room_data then
		table.insert(adjacent_cells, {x = room_x - 1, y = room_y})
	end

	return adjacent_cells
end

--prints out the contents of the room data
function Dungeon:print_room_data()
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[y] do
			if self:get_room(x, y) > 0 then
				io.write(self:get_room(x, y).." ")
			else
				io.write(". ")
			end
		end
		io.write("\n")
	end
end

--prints out the contents of the horizontal wall data
function Dungeon:print_h_wall_data()
	for y = 1, #self.h_wall_data do
		for x = 1, #self.h_wall_data[y] do
			if self:get_h_wall(x, y) > 0 then
				io.write(self:get_h_wall(x, y).." ")
			else
				io.write(". ")
			end
		end
		io.write("\n")
	end
end

--prints out the contents of the vertical wall data
function Dungeon:print_v_wall_data()
	for y = 1, #self.v_wall_data do
		for x = 1, #self.v_wall_data[y] do
			if self:get_v_wall(x, y) > 0 then
				io.write(self:get_v_wall(x, y).." ")
			else
				io.write(". ")
			end
		end
		io.write("\n")
	end
end

--returns a node for a top-down view of the dungeon
--NOTE: this is the only code in this file that is not portable away from amulet. everything besides this function is pure lua
--NOTE: this function does not need to be efficient. it is only for verifying everything else works
function Dungeon:top_down(scale_factor, room_width, room_height, h_spacing, v_spacing)
	--declare a node to store the view
	--the translate here is so that the view is centered
	local dungeon_view = am.translate(
		-#self.room_data[1] * (room_width + h_spacing) / 2,
		-#self.room_data * (room_height + v_spacing) / 2
	)

	--NOTE: any time x or y is used within these loops, you must subtract 1 to correct for lua's 1-based arrays
	--theyre a nice idea on paper but they suck when you start counting at zero from habit

	--single room loop
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[1] do
			--if there is a room here
			if self:get_room(x, y) > 0 then
				--if it is a quad room
				if self:get_wall_from_rooms(x, y, x + 1, y) == WALL_JOINED_Q
				and self:get_wall_from_rooms(x + 1, y, x + 1, y + 1) == WALL_JOINED_Q
				and self:get_wall_from_rooms(x + 1, y + 1, x, y + 1) == WALL_JOINED_Q
				and self:get_wall_from_rooms(x, y + 1, x, y) == WALL_JOINED_Q then
					dungeon_view:append(
						am.rect(
							(x - 1) * (room_width + h_spacing),
							(y - 1) * (room_height + v_spacing),
							x * (room_width + h_spacing) + room_width,
							y * (room_height + v_spacing) + room_height,
							colors.orange
						)
					)
				--else if it is a horizontal double room
				elseif self:get_wall_from_rooms(x, y, x + 1, y) == WALL_JOINED_H then
					dungeon_view:append(
						am.rect(
							(x - 1) * (room_width + h_spacing),
							(y - 1) * (room_height + v_spacing),
							x * (room_width + h_spacing) + room_width,
							(y - 1) * (room_height + v_spacing) + room_height,
							colors.yellow
						)
					)
				--else if it is a vertical double room
				elseif self:get_wall_from_rooms(x, y, x, y + 1) == WALL_JOINED_V then
					dungeon_view:append(
						am.rect(
							(x - 1) * (room_width + h_spacing),
							(y - 1) * (room_height + v_spacing),
							(x - 1) * (room_width + h_spacing) + room_width,
							y * (room_height + v_spacing) + room_height,
							colors.purple
						)
					)
				--else if it is just a regular room
				else
					--append a rect for it
					dungeon_view:append(
					--NOTE: explaining this math so that it makes sense later
					--x and y are multiplied by their respective room dimension plus spacing so that no rooms overlap
					am.rect(
						(x - 1) * (room_width + h_spacing),
						(y - 1) * (room_height + v_spacing),
						(x - 1) * (room_width + h_spacing) + room_width,
						(y - 1) * (room_height + v_spacing) + room_height,
						colors.red
					)
				)
				end
				--now do the doors
				--if there is a door connecting the right side of this room
				if self:get_wall_from_rooms(x, y, x + 1, y) == WALL_DOOR then
					dungeon_view:append(
						am.line(
							vec2(
								(x - 1) * (room_width + h_spacing) + room_width / 2,
								(y - 1) * (room_height + v_spacing) + room_height / 2
							),
							vec2(
								x * (room_width + h_spacing) + room_width / 2,
								(y - 1) * (room_height + v_spacing) + room_height / 2
							),
							1,
							colors.green
						)
					)
				end
				--if there is a door connecting the bottom edge of this room
				if self:get_wall_from_rooms(vec2(x, y), vec2(x, y + 1)) == WALL_DOOR then
					dungeon_view:append(
						am.line(
							vec2(
								(x - 1) * (room_width + h_spacing) + room_width / 2,
								(y - 1) * (room_height + v_spacing) + room_height / 2
							),
							vec2(
								(x - 1) * (room_width + h_spacing) + room_width / 2,
								y * (room_height + v_spacing) + room_height / 2
							),
							1,
							colors.blue
						)
					)
				end
			end
		end
	end

	return am.scale(scale_factor) ^ dungeon_view
end

--returns a table representing the dungeon's layout
function Dungeon:get_data(room_width, room_height)
	local data = {}

	--pre-allocate the return array
	for y = 1, #self.room_data * (room_height + 1) do
		data[y] = {}
		for x = 1, #self.room_data[1] * (room_width + 1) do
			data[y][x] = "  "
		end
	end

	--for every row of the room data
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[1] do
			--if there is a room here
			if self:get_room(x, y) > 0 then
				--if it is a quad room
				if self:get_wall_from_rooms(x, y, x + 1, y) == WALL_JOINED_Q
				and self:get_wall_from_rooms(x + 1, y, x + 1, y + 1) == WALL_JOINED_Q
				and self:get_wall_from_rooms(x + 1, y + 1, x, y + 1) == WALL_JOINED_Q
				and self:get_wall_from_rooms(x, y + 1, x, y) == WALL_JOINED_Q then
					--mark a square region of the return data as "room"
					--NOTE: offset_x and offset_y are used as offsets, rather than indexes. they range from 0 to max - 1
					--NOTE: in the case of joined rooms, the minus one is dropped to make room for the wall between them and the limit becomes max * 2
					--TODO: change this so that it marks the edge with a distinct value from the middle
					for offset_y = 0, room_height * 2 do
						for offset_x = 0, room_width * 2 do
							--NOTE: these temp vars are just for readability
							--NOTE: if you're reading this and don't understand the logic behind the math, draw it on paper
							local temp_x = (x - 1) * (room_width + 1) + offset_x + 1
							local temp_y = (y - 1) * (room_height + 1) + offset_y + 1
							log("room: ("..temp_x..","..temp_y..")")
							data[temp_y][temp_x] = " #"
						end
					end
				--else if it is a horizontal double room
				elseif self:get_wall_from_rooms(x, y, x + 1, y) == WALL_JOINED_H then
					--same as before, but this time loop for 2x,y
					for offset_y = 0, room_height - 1 do
						for offset_x = 0, room_width * 2 do
							local temp_x = (x - 1) * (room_width + 1) + offset_x + 1
							local temp_y = (y - 1) * (room_height + 1) + offset_y + 1
							log("room: ("..temp_x..","..temp_y..")")
							data[temp_y][temp_x] = " #"
						end
					end
				--else if it is a vertical double room
				elseif self:get_wall_from_rooms(x, y, x, y + 1) == WALL_JOINED_V then
					--yet again, but loop for x, 2y
					for offset_y = 0, room_height * 2 do
						for offset_x = 0, room_width - 1 do
							local temp_x = (x - 1) * (room_width + 1) + offset_x + 1
							local temp_y = (y - 1) * (room_height + 1) + offset_y + 1
							log("room: ("..temp_x..","..temp_y..")")
							data[temp_y][temp_x] = " #"
						end
					end
				--else if it is a single room
				else
					--loop for the regular size
					for offset_y = 0, room_height - 1 do
						for offset_x = 0, room_width - 1 do
							local temp_x = (x - 1) * (room_width + 1) + offset_x + 1
							local temp_y = (y - 1) * (room_height + 1) + offset_y + 1
							log("room: ("..temp_x..","..temp_y..")")
							data[temp_y][temp_x] = " #"
						end
					end
				end

				--now do the doors
				--if there is a door on the right of this room
				if self:get_wall_from_rooms(x, y, x + 1, y) == WALL_DOOR then
					local temp_x = (x - 1) * (room_width + 1) + room_width + 1
					local temp_y = (y - 1) * (room_height + 1) + 1 + 1
					log("vdoor: ("..temp_x..","..temp_y..")")
					data[temp_x][temp_y] = " X"
				end
				
				--if there is a door along the bottom of this room
				if self:get_wall_from_rooms(x, y, x, y + 1) == WALL_DOOR then
					local temp_x = (x - 1) * (room_width + 1) + 1 + 1
					local temp_y = (y - 1) * (room_height + 1) + room_height + 1
					log("hdoor: ("..temp_x..","..temp_y..")")
					data[temp_x][temp_y] = " D"
				end
			end
		end
	end

	return data
end