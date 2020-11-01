
--to do 3d with amulet, you must give the window a depth buffer
local win = am.window
{
	depth_buffer = true,
	clear_color = vec4(0,1,0,1),
	width = 960,
	height = 720
}

-- local win2 = am.window
-- {
-- 	clear_color = vec4(1,1,0,1)
-- }

--link the shader program
local shader = am.program(am.load_string("../shader/main.vert"), am.load_string("../shader/main.frag"))

--creates a vbo node that can be easily added into the scene graph
--TODO: fix this function. it doesn't render. the cause is that the return values from am.load_obj are no longer in scope and the node loses its meaning
function create_vbo_node(model_path, texture_path, shader, cull_type)
	--load_obj returns 4 things
	--a buffer containing vertex, normals, and uv's
	--the byte stride. NOTE: stride is the byte length of the values in the buffer. it is used for the buffer:view method
	--the byte offset where the normals start in the buffer
	--the byte offset of the uv's in the buffer
	--NOTE: if the model is missing normals or uvs, load_obj will return nil
	buf, stride, norm_offset, uv_offset = am.load_obj(model_path)
	verts = buf:view("vec3", 0, stride)
	norms = buf:view("vec3", norm_offset, stride)
	uvs = buf:view("vec2", uv_offset, stride)

	return
		--cull_face culls faces with a specific winding. possible values are: back, front, cw, ccw, none
		am.cull_face("ccw")
		--specifies which shader to use
		^ am.use_program(shader)
		--assigns values to the variables in the shader program
		--TODO: find a way to pass a vec3 light source into the shader
		^ am.bind{
			P = math.perspective(math.rad(60), win.width/win.height, 1, 1000),
			vert = verts,
			normal = normals,
			uv = uvs,
			tex = am.texture2d(texture_path)
		}
		--specifies which primitive to use to render the model.
		--possible values are: points, lines, line_strip, line_loop, triangles, triangle_strip, triange_fan
		^ am.draw"triangles"
end

win.scene = am.group():tag"models" ^ {
		--TODO: probably after the jam, but write a system that reads a scene hierarchy from file and converts it to a scene graph.
		create_vbo_node("../assets/diamond.obj", "../assets/debug.png", shader, "ccw")
		^ am.translate(0, -1, -5):tag"m1",

		am.text("Hello")
}

win.scene:action(function(scene)
	log(scene"bind".tex)

	if win:key_down"escape" then
		win:close()
	end
end)
