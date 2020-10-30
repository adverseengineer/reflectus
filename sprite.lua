--making maps with lua is incredibly easy

local face = [[
..YYYYY..
.Y.....Y.
Y..B.B..Y
Y.......Y
Y.R...R.Y
Y..RRR..Y
.Y.....Y.
..YYYYY..
]]
am.window{}.scene = am.scale(20) ^ am.sprite(face)
