precision mediump float;
uniform vec2 uv;
uniform sampler2D floor_texture;
void main() {
	vec4 floor_sample = texture2D(floor_texture, uv);
	float height = floor_sample.a;
	float low = fract(height * 255.0);
	float hi = floor(height * 255.0) / 255.0;
	gl_FragColor = vec4(hi, low, 0, 0);
}
