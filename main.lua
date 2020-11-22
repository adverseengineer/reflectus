
win = am.window{
	clear_color = vec4(0, 1, 1, 1),
	depth_buffer = true
}

require "dungeon"
noglobals()

-- math.randomseed(os.time())
local dungeon = Dungeon:new(15, 15, 13, 0.2, 0.2, 0.2):create_level(3, 3)

-- local cor = coroutine.create(function(node)
-- 	while true do
-- 		local angle = math.random() * 2 * math.pi --random angle
-- 		local axis = math.normalize(vec3(math.random(), math.random(), math.random()) - 0.5) --random axis
-- 		am.wait(
-- 			am.tween(
-- 				1,
-- 				{rotation = quat(angle, axis)},
-- 				am.ease.inout(am.ease.cubic)
-- 			),
-- 			node
-- 		)
-- 		am.wait(am.delay(0.1))
-- 	end
-- end)

require "model"
-- win.scene = am.translate(20, 20, 20) ^ dungeon
win.scene = am.translate(0, 0, -5) --[[^ am.rotate(0):action(cor) ^ load_model("assets/seg_floor.obj", "assets/wall.png")]] ^ dungeon