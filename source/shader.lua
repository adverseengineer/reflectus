--the purpose of this file is to store a global table of shader objects that can easily be refered to by shader.name
shaders =
{
	default = am.program(am.load_string("../shader/default.vert"), am.load_string("../shader/default.frag")),
	terrain = am.program(am.load_string("../shader/terrain.vert"), am.load_string("../shader/terrain.frag"))
}
