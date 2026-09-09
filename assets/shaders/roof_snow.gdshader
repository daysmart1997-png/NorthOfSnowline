shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;

varying vec3 world_position;

float hash(vec2 p) {
 return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
 vec2 cell = floor(p);
 vec2 f = fract(p);
 f = f * f * (3.0 - 2.0 * f);
 return mix(mix(hash(cell), hash(cell + vec2(1, 0)), f.x),
            mix(hash(cell + vec2(0, 1)), hash(cell + vec2(1, 1)), f.x), f.y);
}

void vertex() {
 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
 vec2 p = world_position.xz;
 float drift = noise(p * 0.48);
 float powder = noise(p * 2.4 + vec2(drift * 1.7));
 float grain = hash(floor(p * 64.0));
 // Match the ground's snow palette, leaving room for the sun-facing roof
 // to brighten without washing out to a uniform white surface.
 ALBEDO = mix(vec3(0.47, 0.53, 0.57), vec3(0.60, 0.65, 0.66), 0.2 + drift * 0.3 + powder * 0.12);
 ALBEDO += vec3((grain - 0.5) * 0.012);
 ROUGHNESS = 0.96 + (grain - 0.5) * 0.035;
 SPECULAR = 0.06;
 // Small, irregular wind-set facets; retain the model's roof slope.
 vec3 relief = vec3(sin(p.x * 3.1 + drift * 5.0), 0.0, cos(p.y * 2.7 + powder * 4.0)) * 0.009;
 NORMAL = normalize(NORMAL + mat3(VIEW_MATRIX) * relief);
}
