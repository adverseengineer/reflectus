-- local win1, win2 = require "windows"
require "dungeon"

dung = Dungeon:new(6, 14, 4, 0, 0, 0)

print"rooms"
dung:print_room_data()
print"walls"
dung:print_wall_data()

dung:set_wall(420, vec2(2,2))
print(dung:get_wall(vec2(2,2)))
