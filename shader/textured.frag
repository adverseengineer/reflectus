precision mediump float;
uniform sampler2D tex;
varying vec3 v_shadow;
varying vec2 v_uv;
void main() {
    gl_FragColor = texture2D(tex, v_uv) * vec4(v_shadow, 1.0);
}
