local screen_width = 960
local screen_height = 720

local win1 = am.window{
	title = "Reflectus",
	resizable = true,
	-- width = screen_width,
	-- height = screen_height,
	clear_color = vec4(1,0,0,1)

}

local win2 = am.window{
	title = "sutcelfeR",
	resizable = true,
	-- width = screen_width,
	-- height = screen_height,
	clear_color = vec4(0,1,1,1)
}

local win1_message_text =
[[
	This game is played in two windows at once.
	For the best experience, please resize the windows to each fill
	half of your screen. If you need help with this, check README.txt
]]

local win2_message_text =
[[
	.ecno ta swodniw owt ni deyalp si emag sihT
	llif hcae swodniw eht eziser esaelp ,ecneirepxe tseb eht roF
	txt.EMDAER kcehc ,siht htiw pleh deen uoy fI .neercs ruoy fo flah

]]

local scene_graph = am.rotate(0) ^ am.group():tag"shared" ^
{
	am.translate(50,50)
	^ am.circle(vec2(0,0), 50, red,3),

	am.translate(-50,50)
	^ am.circle(vec2(0,0), 50, red,3),

	am.translate(50,-50)
	^ am.circle(vec2(0,0), 50, red,3),

	am.translate(-50,-50)
	^ am.circle(vec2(0,0), 50, red,3),
}

win1.scene = am.group() ^
{
	am.text(win1_message_text),
	scene_graph
}

win2.scene = am.group() ^
{
	am.text(win2_message_text, vec4(0,0,0,1)),
	scene_graph
}

--NOTE: because of the way that amulet is coded, window 2 depends on window 1
--		so if window 1 closes window 2 closes as well. if window 2 has focus
--		and is exited, it calls win1:close() to close both
win1.scene:action(function(scene)
	if win1:key_pressed"escape" then
		win1:close()
	end
end)

win1.scene:action(function(scene)
	scene"rotate".angle = am.frame_time

	if win2:key_pressed"escape" then
		win1:close()
	end
end)
