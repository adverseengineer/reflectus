precision mediump float;
attribute vec3 vert;
attribute vec2 uv;
attribute vec3 normal;
uniform mat4 MV;
uniform mat4 P;
varying vec3 v_shadow;
varying vec2 v_uv;
void main() {
    vec3 light = normalize(vec3(1, 1, -1));
    vec3 nm = normalize((MV * vec4(normal, 0.0)).xyz);
    v_shadow = vec3(max(0.1, dot(light, nm)));
    v_uv = uv;
    gl_Position = P * MV * vec4(vert, 1.0);
}
