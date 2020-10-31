--this file works, so use it to find out whats wrong with the other one

local win = am.window
{
	depth_buffer = true,
	clear_color = vec4(0,1,0,1),
	width = 960,
	height = 720
}

local shader = am.program(am.load_string("../shader/main.vert"), am.load_string("../shader/main.frag"))

local buf, stride, norm_offset, tex_offset = am.load_obj("../assets/diamond.obj")
local verts = buf:view("vec3", 0, stride)
local normals = buf:view("vec3", norm_offset, stride)
local uvs = buf:view("vec2", tex_offset, stride)

win.scene = am.group():tag"models" ^ {
    am.cull_face"ccw"
    ^ am.translate(0, -1, -5)
	^ am.scale(1)
    ^ am.use_program(shader)
    ^ am.bind{
        P = math.perspective(math.rad(60), win.width/win.height, 1, 1000),
        vert = verts,
        normal = normals,
        uv = uvs,
        tex = am.texture2d("../assets/debug.png"),
    }
    ^am.draw"triangles",

	am.cull_face"ccw"
    ^ am.translate(0, 1, -5)
	^ am.scale(1)
    ^ am.use_program(shader)
    ^ am.bind{
        P = math.perspective(math.rad(60), win.width/win.height, 1, 1000),
        vert = verts,
        normal = normals,
        uv = uvs,
        tex = am.texture2d("../assets/debug.png"),
    }
    ^am.draw"triangles"
}

win.scene:action(function(scene)
	if win:key_down"escape" then
		win:close()
	end
end)
