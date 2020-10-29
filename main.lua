--possible names
--reflectus
--refractus

--create a window
local win = am.window
{
	title = "Hi",
	width = 400,
	height = 300,
	clear_color = vec4(1, 0, 0.5, 1)
}

--assign a scene graph to the window
--the scene graph has a single text node
win.scene =
	am.translate(150,100)
	^ am.scale(2)
	^ am.rotate(math.rad(90))
	^ am.text("Hello!")
