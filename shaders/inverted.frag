precision mediump float;
uniform sampler2D tex;
varying vec2 v_uv;
void main() {
	vec4 pixel_color = texture2D(tex, v_uv);
	gl_FragColor = vec4(1.0 - pixel_color.r, 1.0 - pixel_color.g, 1.0 - pixel_color.b, 1.0);
}