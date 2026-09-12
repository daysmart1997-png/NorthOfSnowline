shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx, cull_disabled;
#include "res://assets/shaders/snow_detail.gdshaderinc"

varying vec3 world_position;
uniform sampler2D powder_normal : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D powder_roughness : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float powder_world_size : hint_range(1.0,12.0) = 2.8;
uniform float powder_strength : hint_range(0.0,1.0) = .10;

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
 vec3 micro=snow_detail(powder_normal,powder_roughness,p/powder_world_size+vec2(drift-.5,powder-.5)*.55,.3+drift*.4);
 float grain = micro.z;
 // Match the ground's snow palette, leaving room for the sun-facing roof
 // to brighten without washing out to a uniform white surface.
 ALBEDO = mix(vec3(0.47, 0.53, 0.57), vec3(0.60, 0.65, 0.66), 0.2 + drift * 0.3 + powder * 0.12);
 ALBEDO += vec3((grain - 0.5) * 0.012);
 ROUGHNESS = 0.96 + (grain - 0.5) * 0.035;
 SPECULAR = 0.06;
 // Small, irregular wind-set facets; retain the model's roof slope.
 vec3 relief = vec3(micro.x,0.0,micro.y)*powder_strength*snow_detail_visibility(p);
 NORMAL = normalize(NORMAL + mat3(VIEW_MATRIX) * relief);
}
