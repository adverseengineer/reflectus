

require "colors"
require "shaders"

--creates a model node that can be added into the scene graph
local function load_model(model_path, texture_path, shader, color, light)
	--load_obj returns 4 things
	--a buffer containing vertex, normals, and uv's
	--the byte stride. NOTE: stride is the byte length of the values in the buffer. it is used for the buffer:view method
	--the byte offset of the normals
	--the byte offset of the UV's
	--NOTE: if normals or UV's are missing, they will return nil
	local buf, stride, norm_offset, uv_offset = am.load_obj(model_path)
	local verts = buf:view("vec3", 0, stride)
	local normals = buf:view("vec3", norm_offset, stride)
	local uvs = buf:view("vec2", uv_offset, stride)

	return
		--cull_face culls faces with a specific winding. possible values are: back, front, cw, ccw, none
		am.cull_face("cw")
		--specifies which shader to use
		^ am.use_program(shader)
		--assigns values to the variables in the shader program
		^ am.bind{
	        P = math.perspective(math.rad(60), win.width/win.height, 1, 1000),
	        vert = verts,
	        normal = normals,
	        uv = uvs,
	        tex = am.texture2d(texture_path),
	        color = color,
	        light = light
    	}
		--specifies which primitive to use to render the model.
		--possible values are: points, lines, line_strip, line_loop, triangles, triangle_strip, triangle_fan
		^ am.draw"triangles"
end

--dictionary of pre-bound and ready-to-use model nodes
models = {
	le_monke = load_model("assets/le_monke.obj", "assets/texture.png", shaders.textured, colors.green, vec3(0.2, 0.1, 0.3)),
	seg_corner_0 = am.rotate(math.rad(360), vec3(0, 1, 0)) ^ load_model("assets/seg_corner.obj", "assets/texture.png", shaders.textured, colors.orange, vec3(0.2, 0.1, 0.3)),
	seg_corner_1 = am.rotate(math.rad(270), vec3(0, 1, 0)) ^ load_model("assets/seg_corner.obj", "assets/texture.png", shaders.textured, colors.orange, vec3(0.2, 0.1, 0.3)),
	seg_corner_2 = am.rotate(math.rad(180), vec3(0, 1, 0)) ^ load_model("assets/seg_corner.obj", "assets/texture.png", shaders.textured, colors.orange, vec3(0.2, 0.1, 0.3)),
	seg_corner_3 = am.rotate(math.rad(90), vec3(0, 1, 0)) ^ load_model("assets/seg_corner.obj", "assets/texture.png", shaders.textured, colors.orange, vec3(0.2, 0.1, 0.3)),
	seg_wall_0 = load_model("assets/seg_wall.obj", "assets/texture.png", shaders.textured, colors.orange, vec3(0.2, 0.1, 0.3)),
	seg_wall_1 = am.rotate(math.rad(270), vec3(0, 1, 0)) ^ load_model("assets/seg_wall.obj", "assets/texture.png", shaders.textured, colors.orange, vec3(0.2, 0.1, 0.3)),
	seg_wall_2 = am.rotate(math.rad(180), vec3(0, 1, 0)) ^ load_model("assets/seg_wall.obj", "assets/texture.png", shaders.textured, colors.orange, vec3(0.2, 0.1, 0.3)),
	seg_wall_3 = am.rotate(math.rad(90), vec3(0, 1, 0)) ^ load_model("assets/seg_wall.obj", "assets/texture.png", shaders.textured, colors.orange, vec3(0.2, 0.1, 0.3)),
	seg_pillar = load_model("assets/seg_pillar.obj", "assets/texture.png", shaders.textured, colors.yellow, vec3(0.2, 0.1, 0.3)),
	seg_door_h = load_model("assets/seg_door.obj", "assets/texture.png", shaders.textured, colors.magenta, vec3(0.2, 0.1, 0.3)),
	seg_door_v = am.rotate(math.rad(90), vec3(0, 1, 0)) ^ load_model("assets/seg_door.obj", "assets/texture.png", shaders.textured, colors.magenta, vec3(0.2, 0.1, 0.3)),
	seg_floor = load_model("assets/seg_floor.obj", "assets/texture.png", shaders.textured, colors.orange, vec3(0.2, 0.1, 0.3))
}