
local WALL_REGULAR = 0
local WALL_JOINED_H = 1
local WALL_JOINED_V = 2
local WALL_JOINED_Q = 3
local WALL_DOOR = 4

local SEG_BLANK = ""
local SEG_CORNER_0 = "c0"
local SEG_CORNER_1 = "c1"
local SEG_CORNER_2 = "c2"
local SEG_CORNER_3 = "c3"
local SEG_WALL_0 = "w0"
local SEG_WALL_1 = "w1"
local SEG_WALL_2 = "w2"
local SEG_WALL_3 = "w3"
local SEG_FLOOR = "%f"
local SEG_DOOR_H = "#h"
local SEG_DOOR_V = "#v"

require "colors"
require "models"

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

	--testing rooms to show the borders of the map. they'll never cause issues because the algorithm only claims unclaimed spaces
	--NOTE: after testing, it looks like they do get claimed as part of joined rooms, but only because they fit the conditions. is fine either way
	for x = 1, map_width - 1 do
		result_dungeon.room_data[1][x] = 1
		result_dungeon.room_data[map_height][x] = 1
	end
	for y = 1, map_height - 1 do
		result_dungeon.room_data[y][1] = 1
		result_dungeon.room_data[y][map_width] = 1
	end

	--set the center room and begin the generation
	result_dungeon.room_data[math.ceil(map_height / 2)][math.ceil(map_width / 2)] = num_iterations
	result_dungeon:generate_rooms(math.ceil(map_width / 2), math.ceil(map_height / 2), num_iterations, num_iterations)

	--spice up the dungeon
	result_dungeon:make_quad_rooms(quad_room_freq)
	result_dungeon:make_h_double_rooms(h_double_room_freq)
	result_dungeon:make_v_double_rooms(v_double_room_freq)

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
		if math.random() < current_iteration / num_iterations and self:get_room(adjacent_cells[i].x, adjacent_cells[i].y) == 0 then
			--add the room to the map
			self:set_room(current_iteration - 1, adjacent_cells[i].x, adjacent_cells[i].y)
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
					and self:get_wall_from_rooms(x + 1, y, x + 1, y - 1) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(x + 1, y, x + 1, y - 1) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(x + 1, y, x + 1, y - 1) ~= WALL_JOINED_V
					and self:get_wall_from_rooms(x + 1, y, x + 2, y) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(x + 1, y, x + 2, y) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(x + 1, y, x + 2, y) ~= WALL_JOINED_V
					and self:get_wall_from_rooms(x + 1, y + 1, x + 2, y + 1) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(x + 1, y + 1, x + 2, y + 1) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(x + 1, y + 1, x + 2, y + 1) ~= WALL_JOINED_V
					and self:get_wall_from_rooms(x + 1, y + 1, x + 1, y + 2) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(x + 1, y + 1, x + 1, y + 2) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(x + 1, y + 1, x + 1, y + 2) ~= WALL_JOINED_V
					and self:get_wall_from_rooms(x, y + 1, x, y + 2) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(x, y + 1, x, y + 2) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(x, y + 1, x, y + 2) ~= WALL_JOINED_V
					and self:get_wall_from_rooms(x, y + 1, x - 1, y + 1) ~= WALL_JOINED_Q
					and self:get_wall_from_rooms(x, y + 1, x - 1, y + 1) ~= WALL_JOINED_H
					and self:get_wall_from_rooms(x, y + 1, x - 1, y + 1) ~= WALL_JOINED_V
					and self:get_wall_from_rooms(x, y, x - 1, y) ~= WALL_JOINED_Q
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
			and self:get_wall_from_rooms(x, y, x + 1, y) == WALL_DOOR then
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
				and self:get_wall_from_rooms(x, y, x - 1, y) ~= WALL_JOINED_Q
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
--returns the wall value at the provided wall coords in the horizontal wall data
--if invalid coords are given, returns -1
function Dungeon:get_h_wall(wall_x, wall_y)
	if wall_x > 0
	and wall_y > 0
	and wall_x <= #self.h_wall_data[1]
	and wall_y <= #self.h_wall_data then
		return self.h_wall_data[wall_y][wall_x];
	else
		return -1
	end
end

--returns the wall value at the provided wall coords in the horizontal wall data
--if invalid coords are given, returns -1
function Dungeon:get_v_wall(wall_x, wall_y)
	if wall_x > 0
	and wall_y > 0
	and wall_x <= #self.v_wall_data[1]
	and wall_y <= #self.v_wall_data then
		return self.v_wall_data[wall_y][wall_x];
	else
		return -1
	end
end

--returns the wall value between the provided room coords
function Dungeon:get_wall_from_rooms(room_1_x, room_1_y, room_2_x, room_2_y)
	--do a couple sanity checks
	assert(room_1_x ~= room_2_x or room_1_y ~= room_2_y, "given rooms are identical")
	assert(math.abs(room_1_x - room_2_x) == 1 or math.abs(room_1_y - room_2_y) == 1, " given rooms are non-adjacent")    
	--NOTE: doors are associated with the room above or to the left of them.
	--therefore, the upper-leftmost room of any adjacent pair will always be the one whose coords are the same as the door
	local temp_x = math.min(room_1_x, room_2_x)
	local temp_y = math.min(room_1_y, room_2_y)
	--if we got through those two asserts, then the following logic should be bulletproof
	--if the rooms are horizontally adjacent
	if room_1_y == room_2_y then
		return self:get_h_wall(temp_x, temp_y)
	--else they must be vertically adjacent
	else
		return self:get_v_wall(temp_x, temp_y)
	end
end

--sets the room value at the provided coords
--NOTE: this setter as well as the others have no input validation because lua lets any value be an index
function Dungeon:set_room(value, room_x, room_y)
	self.room_data[room_y][room_x] = value
end

--sets the horizontal wall value at the provided coords
function Dungeon:set_h_wall(value, wall_x, wall_y)
	self.h_wall_data[wall_y][wall_x] = value
end

--sets the vertical wall value at the provided coords
function Dungeon:set_v_wall(value, wall_x, wall_y)
	self.v_wall_data[wall_y][wall_x] = value
end

--sets the wall value between the specified rooms coords
function Dungeon:set_wall_from_rooms(value, room_1_x, room_1_y, room_2_x, room_2_y)
	--everything in this method is the same as get_wall_from_rooms except assigning instead of returning
	assert(room_1_x ~= room_2_x or room_1_y ~= room_2_y, "given rooms are identical")
	assert(math.abs(room_1_x - room_2_x) == 1 or math.abs(room_1_y - room_2_y) == 1, " given rooms are non-adjacent")    

	local temp_x = math.min(room_1_x, room_2_x)
	local temp_y = math.min(room_1_y, room_2_y)
	--if the rooms are horizontally adjacent
	if room_1_y == room_2_y then
		self:set_h_wall(value, temp_x, temp_y)
	--else they must be vertically adjacent
	else
		self:set_v_wall(value, temp_x, temp_y)
	end
end

--takes two room coords and returns a table of the coords of all adjacent cells
function Dungeon:get_adjacent_cells(room_x, room_y)
	local adjacent_cells = {}

	if room_x > 0
	and room_y - 1 > 0
	and room_x <= #self.room_data[1] 
	and room_y - 1 <= #self.room_data then
		table.insert(adjacent_cells, {x = room_x, y = room_y - 1})
	end
	if room_x + 1 > 0
	and room_y > 0
	and room_x + 1 <= #self.room_data[1]
	and room_y <= #self.room_data then
		table.insert(adjacent_cells, {x = room_x + 1, y = room_y})
	end
	if room_x > 0
	and room_y + 1 > 0
	and room_x <= #self.room_data[1]
	and room_y + 1<= #self.room_data then
		table.insert(adjacent_cells, {x = room_x, y = room_y + 1})
	end
	if room_x - 1 > 0
	and room_y > 0
	and room_x - 1 <= #self.room_data[1]
	and room_y <= #self.room_data then
		table.insert(adjacent_cells, {x = room_x - 1, y = room_y})
	end

	return adjacent_cells
end

--returns true if a quad room exists at the given coords
function Dungeon:is_quad_room(room_x, room_y)

	return self:get_room(room_x, room_y) > 0
	and self:get_wall_from_rooms(room_x, room_y, room_x + 1, room_y) == WALL_JOINED_Q
	and self:get_wall_from_rooms(room_x + 1, room_y, room_x + 1, room_y + 1) == WALL_JOINED_Q
	and self:get_wall_from_rooms(room_x + 1, room_y + 1, room_x, room_y + 1) == WALL_JOINED_Q
	and self:get_wall_from_rooms(room_x, room_y + 1, room_x, room_y) == WALL_JOINED_Q 
end

--returns true if a horizontal double room exists at the given coords
function Dungeon:is_h_double_room(room_x, room_y)
	return self:get_room(room_x, room_y) > 0
	and self:get_wall_from_rooms(room_x, room_y, room_x + 1, room_y) == WALL_JOINED_H
end

--returns true if a vertical double room exists at the given coords
function Dungeon:is_v_double_room(room_x, room_y)
	return self:get_room(room_x, room_y) > 0 
	and self:get_wall_from_rooms(room_x, room_y, room_x, room_y + 1) == WALL_JOINED_V
end

--returns a node for a top-down view of the dungeon
function Dungeon:top_down(scale_factor, room_width, room_height, h_spacing, v_spacing)
	--declare a node to store the view
	-- the translate here is so that the view is centered
	local dungeon_view = am.translate(
		-#self.room_data[1] * (room_width + h_spacing) / 2,
		-#self.room_data * (room_height + v_spacing) / 2
	)

	--NOTE: each type of room must be done in it's own nested for loops so that they render in the correct order
	--NOTE: any time x or y is used within these loops, you must subtract 1 to correct for lua's 1-based arrays
	--theyre a nice idea on paper but they suck when you start counting at zero from habit

	--single room loop
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[1] do
			--if there is a room here
			if self:get_room(x, y) > 0 then
				--add it to the view
				dungeon_view:append(
					--NOTE: explaining this math so that it makes sense later
					--x and y are multiplied by their respective room dimension plus spacing so that no rooms overlap
					am.rect(
						(x - 1) * (room_width + h_spacing),
						(y - 1) * (room_height + v_spacing),
						(x - 1) * (room_width + h_spacing) + room_width,
						(y - 1) * (room_height + v_spacing) + room_height,
						colors.green
					)
				)
			end
		end
	end

	--quad room loop
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[1] do
			--if there is a quad room here
			if self:is_quad_room(x, y) then
				--add it to the view
				dungeon_view:append(
					am.rect(
						(x - 1) * (room_width + h_spacing),
						(y - 1) * (room_height + v_spacing),
						x * (room_width + h_spacing) + room_width,
						y * (room_height + v_spacing) + room_height,
						colors.red
					)
				)
			end
		end
	end

	--horizontal double room loop
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[1] do
			--if there is a horizontal double room here
			if self:is_h_double_room(x, y) then
				--add it to the view
				dungeon_view:append(
					am.rect(
						(x - 1) * (room_width + h_spacing),
						(y - 1) * (room_height + v_spacing),
						x * (room_width + h_spacing) + room_width,
						(y - 1) * (room_height + v_spacing) + room_height,
						colors.blue
					)
				)
			end
		end
	end

	--vertical double rooms
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[1] do
			--if there is a vertical double room here
			if self:is_v_double_room(x, y) then
				--add it to the view
				dungeon_view:append(
					am.rect(
						(x - 1) * (room_width + h_spacing),
						(y - 1) * (room_height + v_spacing),
						(x - 1) * (room_width + h_spacing) + room_width,
						y * (room_height + v_spacing) + room_height,
						colors.yellow
					)
				)
			end
		end
	end
	
	--now do the doors
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[1] do
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
						colors.orange
					)
				)
			end
			--if there is a door connecting the bottom edge of this room
			if self:get_wall_from_rooms(x, y, x, y + 1) == WALL_DOOR then
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
						colors.purple
					)
				)
			end
		end
	end

	return am.scale(scale_factor) ^ dungeon_view
end

--returns a table representing the dungeon's layout
function Dungeon:get_data(room_width, room_height)
	assert(room_width >= 3, "given room width is too small")
	assert(room_height >= 3, "given room height is too small")

	local data = {}

	--pre-allocate the return array
	for y = 1, #self.room_data * (room_height + 1) do
		data[y] = {}
		for x = 1, #self.room_data[1] * (room_width + 1) do
			data[y][x] = SEG_BLANK
		end
	end

	--NOTE: in order to avoid overcomplicating the code, the blocks that add single rooms must be in their own loops, otherwise they overlap everything else
	--if we put it anywhere in the other set of loops it ends up overlapping other rooms.
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[1] do
			local temp_x = (x - 1) * (room_width + 1) + 1
			local temp_y = (y - 1) * (room_height + 1) + 1
			--if there is a room here at all
			if self:get_room(x, y) > 0 then
				--draw the floor
				for floor_y = 1, room_height - 2 do
					for floor_x = 1, room_width - 2 do
						data[temp_y + floor_y][temp_x + floor_x] = SEG_FLOOR
					end
				end
				--set the corners
				data[temp_y][temp_x] = SEG_CORNER_0
				data[temp_y][temp_x + room_width - 1] = SEG_CORNER_1
				data[temp_y + room_height - 1][temp_x + room_width - 1] = SEG_CORNER_2
				data[temp_y + room_height - 1][temp_x] = SEG_CORNER_3
				--NOTE: it helps to think of the borders as two perpendicular pairs of parallel lines
				--NOTE: to avoid wasted loop iterations, start the loop 1 later, and end 1 sooner
				--set the north and south borders
				for border_ns = temp_x + 1, temp_x + room_width - 2 do
					data[temp_y][border_ns] = SEG_WALL_0
					data[temp_y + room_height - 1][border_ns] = SEG_WALL_2
				end
				--set the east and west borders
				for border_ew = temp_y + 1, temp_y + room_height - 2 do
					data[border_ew][temp_x + room_width - 1] = SEG_WALL_1
					data[border_ew][temp_x] = SEG_WALL_3
				end
			end
		end
	end

	--for every cell in room_data
	--add the special rooms
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[1] do
			--part of the math that determines the correct position is the same for every type of room, so store that here and add the different part later
			local temp_x = (x - 1) * (room_width + 1) + 1
			local temp_y = (y - 1) * (room_height + 1) + 1

			--if there is a quad room here
			if self:is_quad_room(x, y) then
				--draw the floor
				for floor_y = 1, room_height * 2 - 1 do
					for floor_x = 1, room_width * 2 - 1 do
						data[temp_y + floor_y][temp_x + floor_x] = SEG_FLOOR
					end
				end
				--set the corners
				data[temp_y][temp_x] = SEG_CORNER_0
				data[temp_y][temp_x + room_width * 2] = SEG_CORNER_1
				data[temp_y + room_height * 2][temp_x + room_width * 2] = SEG_CORNER_2
				data[temp_y + room_height * 2][temp_x] = SEG_CORNER_3
				--set the north and south borders
				for border_ns = temp_x + 1, temp_x + room_width * 2 - 1 do
					data[temp_y][border_ns] = SEG_WALL_0
					data[temp_y + room_height * 2][border_ns] = SEG_WALL_2
				end
				--set the east and west borders
				--NOTE: i had to add a -2 to the max of this loop to make it work right, but im not sure why because the others didn't need it
				for border_ew = temp_y + 1, temp_y + room_height * 2 - 2 do
					data[border_ew][temp_x + room_width * 2] = SEG_WALL_1
					data[border_ew][temp_x] = SEG_WALL_3
				end
			--else if it is a horizontal double room
			elseif self:is_h_double_room(x, y) then
				--draw the floor
				for floor_y = 1, room_height - 2 do
					for floor_x = 1, room_width * 2 - 1 do
						data[temp_y + floor_y][temp_x + floor_x] = SEG_FLOOR
					end
				end
				--set the corners
				data[temp_y][temp_x] = SEG_CORNER_0
				data[temp_y][temp_x + room_width * 2] = SEG_CORNER_1
				data[temp_y + room_height - 1][temp_x + room_width * 2] = SEG_CORNER_2
				data[temp_y + room_height - 1][temp_x] = SEG_CORNER_3
				--set the north and south borders
				for border_ns = temp_x + 1, temp_x + room_width * 2 - 1 do
					data[temp_y][border_ns] = SEG_WALL_0
					data[temp_y + room_height - 1][border_ns] = SEG_WALL_2
				end
				--set the east and west borders
				for border_ew = temp_y + 1, temp_y + room_height - 2 do
					data[border_ew][temp_x + room_width * 2] = SEG_WALL_1
					data[border_ew][temp_x] = SEG_WALL_3
				end
			--else if it is a vertical double room
			elseif self:is_v_double_room(x, y) then
				--draw the floor
				for floor_y = 1, room_height * 2 - 1 do
					for floor_x = 1, room_width - 2 do
						data[temp_y + floor_y][temp_x + floor_x] = SEG_FLOOR
					end
				end
				--set the corners
				data[temp_y][temp_x] = SEG_CORNER_0
				data[temp_y][temp_x + room_width - 1] = SEG_CORNER_1
				data[temp_y + room_height * 2][temp_x + room_width - 1] = SEG_CORNER_2
				data[temp_y + room_height * 2][temp_x] = SEG_CORNER_3
				--set the north and south borders
				for border_ns = temp_x + 1, temp_x + room_width - 2 do
					data[temp_y][border_ns] = SEG_WALL_0
					data[temp_y + room_height * 2][border_ns] = SEG_WALL_2
				end
				--set the east and west borders
				for border_ew = temp_y + 1, temp_y + room_height * 2 - 1 do
					data[border_ew][temp_x + room_width - 1] = SEG_WALL_1
					data[border_ew][temp_x] = SEG_WALL_3
				end
			end
		end
	end

	--NOTE: the doors are special too. in order to not get the entryways overwritten, they have to be done in their own loops
	--for every cell in room_data
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[1] do
			--part of the math that determines the correct position is the same for every type of room, so store that here and add the different part later
			local temp_x = (x - 1) * (room_width + 1) + 1
			local temp_y = (y - 1) * (room_height + 1) + 1

			--if there is a door on the right of this room (horizontal)
			if self:get_wall_from_rooms(x, y, x + 1, y) == WALL_DOOR then
				--drop in a door and change the wall segs on either side of it to floor
				data[temp_y + math.floor(room_height / 2)][temp_x + room_width] = SEG_DOOR_H
				data[temp_y + math.floor(room_height / 2)][temp_x + room_width - 1] = SEG_FLOOR
				data[temp_y + math.floor(room_height / 2)][temp_x + room_width + 1] = SEG_FLOOR
			end
			
			--if there is a door along the bottom of this room (vertical)
			if self:get_wall_from_rooms(x, y, x, y + 1) == WALL_DOOR then
				--drop in a door and change the wall segs on either side of it to floor
				data[temp_y + room_height][temp_x + math.floor(room_width / 2)] = SEG_DOOR_V
				data[temp_y + room_height - 1][temp_x + math.floor(room_width / 2)] = SEG_FLOOR
				data[temp_y + room_height + 1][temp_x + math.floor(room_width / 2)] = SEG_FLOOR
			end
		end
	end

	return data
end

--returns an amulet node that can be added to a scene
function Dungeon:create_level(room_width, room_height)
	assert(room_width >= 3, "given room width is too small")
	assert(room_height >= 3, "given room height is too small")

	local data = self:get_data(room_width, room_height)
	local level = am.group()

	--loop through all the map data and add the corresponding model node for each data value
	for y = 1, #data do
		for x = 1, #data[1] do
			local position = am.translate(x, 0, y)

			if data[y][x] == SEG_CORNER_0 then
				level:append(position ^ models.seg_corner_0)
			elseif data[y][x] == SEG_CORNER_1 then
				level:append(position ^ models.seg_corner_1)
			elseif data[y][x] == SEG_CORNER_2 then
				level:append(position ^ models.seg_corner_2)
			elseif data[y][x] == SEG_CORNER_3 then
				level:append(position ^ models.seg_corner_3)
			elseif data[y][x] == SEG_WALL_0 then
				level:append(position ^ models.seg_wall_0)
			elseif data[y][x] == SEG_WALL_1 then
				level:append(position ^ models.seg_wall_1)
			elseif data[y][x] == SEG_WALL_2 then
				level:append(position ^ models.seg_wall_2)
			elseif data[y][x] == SEG_WALL_3 then
				level:append(position ^ models.seg_wall_3)
			elseif data[y][x] == SEG_DOOR_H then
				level:append(position ^ models.seg_door_h)
			elseif data[y][x] == SEG_DOOR_V then
				level:append(position ^ models.seg_door_v)
			elseif data[y][x] == SEG_FLOOR then
				level:append(position ^ models.seg_floor)
			end
		end
	end

	return level
end

--prints the ascii data that the level builder uses to place segments
function Dungeon:print_all(room_width, room_height)
	local data = self:get_data(room_width, room_height)
	for y = 1, #data do
		for x = 1, #data[1] do
			io.write(string.format("%3s", data[y][x]))
		end
		io.write("\n")
	end
end

--prints out the contents of the room data
function Dungeon:print_room_data()
	for y = 1, #self.room_data do
		for x = 1, #self.room_data[1] do
			if self:get_room(x, y) > 0 then
				io.write(" "..self:get_room(x, y))
			else
				io.write(" .")
			end
		end
		io.write("\n")
	end
end

--prints out the contents of the horizontal wall data
function Dungeon:print_h_wall_data()
	for y = 1, #self.h_wall_data do
		for x = 1, #self.h_wall_data[1] do
			if self:get_h_wall(x, y) > 0 then
				io.write(" "..self:get_h_wall(x, y))
			else
				io.write(" .")
			end
		end
		io.write("\n")
	end
end

--prints out the contents of the vertical wall data
function Dungeon:print_v_wall_data()
	for y = 1, #self.v_wall_data do
		for x = 1, #self.v_wall_data[1] do
			if self:get_v_wall(x, y) > 0 then
				io.write(" "..self:get_v_wall(x, y))
			else
				io.write(" .")
			end
		end
		io.write("\n")
	end
end