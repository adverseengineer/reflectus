precision mediump float;
attribute vec3 pos;
attribute vec3 normal;
uniform mat4 MV;
uniform mat4 P;
varying vec3 v_color;
void main() {
    vec3 light = normalize(vec3(0.1, 0.1, 1.0));
    vec3 nm = normalize((MV * vec4(normal, 0.0)).xyz);
    v_color = vec3(max(0.1, dot(light, nm)));
    gl_Position = P * MV * vec4(pos, 1.0);
	gl_PointSize = 3.0;
}
