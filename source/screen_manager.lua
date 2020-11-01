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
