-- local win1, win2 = require "windows"
-- os.execute("sleep " .. tonumber(0.25))

assert(#arg == 1, "Too few or too many args")

--seed the RNG
math.randomseed(os.time())

require "dungeon"
local color = require "color"

dun = Dungeon:new(20, 20, 9, 0.2, 0.2, 0.2)
win = am.window{
	title = "Refucktus",
	resizable = true,
	-- width = screen_width,
	-- height = screen_height,
	clear_color = color.black
}

win.scene = am.group() ^ {

	am.line(vec2(0, win.top), vec2(0, win.bottom), 1, color.yellow),
	am.line(vec2(win.left, 0), vec2(win.right, 0), 1, color.yellow),

	dun:top_down(tonumber(arg[1]), 4, 4, 1, 1)
}

--window exit action
win.scene:action(function(scene)
	if win:key_down"escape" then
		win:close()
	end
end)
