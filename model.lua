require "shaders"

--creates a model node that can be added into the scene graph
function load_model(model_path, texture_path)
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
		am.cull_face("front")
		--specifies which shader to use
		^ am.use_program(shaders.textured)
		--assigns values to the variables in the shader program
		^ am.bind{
	        P = math.perspective(math.rad(60), win.width/win.height, 1, 1000),
	        vert = verts,
	        normal = normals,
	        uv = uvs,
	        tex = am.texture2d(texture_path),
    	}
		--specifies which primitive to use to render the model.
		--possible values are: points, lines, line_strip, line_loop, triangles, triangle_strip, triange_fan
		^ am.draw"triangles"
end
