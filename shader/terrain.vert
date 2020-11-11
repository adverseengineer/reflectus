precision mediump float;
attribute vec2 vert;
void main() {
	gl_Position = vec4(vert, 0.0, 1.0);
	gl_PointSize = 2.0;
}
