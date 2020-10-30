local vert = [[
precision mediump float;
attribute vec3 vert;
attribute vec2 uv;
attribute vec3 normal;
uniform mat4 MV;
uniform mat4 P;
varying vec3 v_shadow;
varying vec2 v_uv;
void main() {
    vec3 light = normalize(vec3(1, 0, 2));
    vec3 nm = normalize((MV * vec4(normal, 0.0)).xyz);
    v_shadow = vec3(max(0.1, dot(light, nm)));
    v_uv = uv;
    gl_Position = P * MV * vec4(vert, 1.0);
}]]

local frag = [[
precision mediump float;
uniform sampler2D tex;
varying vec3 v_shadow;
varying vec2 v_uv;
void main() {
    gl_FragColor = texture2D(tex, v_uv) * vec4(v_shadow, 1.0);
}]]

--to do 3d with amulet, you must give the window a depth buffer
local win = am.window
{
	depth_buffer = true
}

--link the shader program
local shader = am.program(vert, frag)

--creates a model node that can be easily added into the scene graph
function create_model(model_path, texture_path, shader, cull_type)
	--load_obj returns 4 things
	--a buffer containing vertex, normal, and uv's
	--the byte stride. NOTE: stride is the byte length of the values in the buffer it is used for the buffer:view method
	--the byte offset where the normals start in the buffer
	--the byte offset of the uv's in the buffer
	--NOTE: if the model is missing normals or uvs, load_obj will return nil
	local buf, stride, norm_offset, uv_offset = am.load_obj(model_path)
	local verts = buf:view("vec3", 0, stride)
	local norms = buf:view("vec3", norm_offset, stride)
	local uvs = buf:view("vec2", uv_offset, stride)

	return
		--TODO: i think that models dont render unless given a translate node
		am.translate(vec3(0))
		--cull_face culls faces with a specific winding. possible values are: back, front, cw, ccw, none
		^ am.cull_face(cull_type)
		--specifies which shader to use
		^ am.use_program(shader)
		--i *think* this assigns the variables in the shader program
		^ am.bind{
			--mv is a built in value. it is the default model-view matrix
			P = math.perspective(math.rad(60), win.width/win.height, 1, 1000),
			vert = verts,
			normal = normals,
			uv = uvs,
			tex = am.texture2d(texture_path)
		}
		--specifies what primitive to use to render the model.
		--possible values are: points, lines, line_strip, line_loop, triangles, triangle_strip, triange_fan
		^ am.draw"triangles"
end

win.scene = am.group() ^
{
	create_model("diamond.obj", "debug.png", shader, "none")
	^am.scale(4),
	am.text("Hello")
}
