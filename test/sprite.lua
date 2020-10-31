--making maps with lua is incredibly easy
--this may be what i fall back on if i cant get 3d to work reliably
local face =
[[
	..YYYYY..
	.Y.....Y.
	Y..B.B..Y
	Y.......Y
	Y.R...R.Y
	Y..RRR..Y
	.Y.....Y.
	..YYYYY..
]]

local win = am.window{}

win.scene =
	am.scale(20)
	^ am.sprite(face)
