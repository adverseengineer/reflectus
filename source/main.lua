-- local win1, win2 = require "windows"

assert(#arg == 1, "Too few or too many args")

--seed the RNG
math.randomseed(os.time())

require "dungeon"
require "colors"

win = am.window{
	title = "Reflectus",
	resizable = true,
	width = 720,
	height = 720,
	clear_color = colors.black
}

win.scene = am.group()

--window exit action
win.scene:action(function(scene)
	if win:key_down"escape" then
		win:close()
	end

	--if any key is pressed
	if #win:keys_pressed() > 0 then
		local dun = Dungeon:new(20, 20, 15, 1, 1, 1):top_down(tonumber(arg[1]), 4, 4, 1, 1)
		scene:remove_all()
		scene:append(am.rotate(math.rad(45)) ^ dun)
	end
end)
