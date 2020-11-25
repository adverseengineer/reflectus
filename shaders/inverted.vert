precision mediump float;
uniform sampler2D tex;
attribute vec2 vert;
attribute vec2 uv;
varying vec2 v_uv;
void main() {
	v_uv = uv;
	gl_Position = vec4(vert, 1.0, 1.0);
}