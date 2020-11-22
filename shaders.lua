shaders =
{
	default = am.program(am.load_string("shader/default.vert"), am.load_string("shader/default.frag")),
	textured = am.program(am.load_string("shader/textured.vert"), am.load_string("shader/textured.frag"))
}
