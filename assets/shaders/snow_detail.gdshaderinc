// Shared ground / roof micro-surface. XY is a world XZ normal perturbation,
// Z is roughness. Blend two non-matching periods instead of enlarging dimples.
vec3 snow_detail(sampler2D normal_map, sampler2D roughness_map, vec2 uv, float blend) {
 vec2 uv_b=vec2(-uv.y,uv.x)*1.37+vec2(5.31,2.17);
 vec2 a=(texture(normal_map,uv).rg*2.0-1.0)*vec2(1.0,-1.0);
 vec2 b=(texture(normal_map,uv_b).rg*2.0-1.0)*vec2(1.0,-1.0);
 // Rotate the second normal back into world XZ, not just its UVs.
 b=vec2(b.y,-b.x);
 float rough_a=texture(roughness_map,uv).r;
 float rough_b=texture(roughness_map,uv_b).r;
 return vec3(mix(a,b,blend),mix(rough_a,rough_b,blend));
}

float snow_detail_visibility(vec2 world_xz) {
 // Orthographic zoom changes pixel footprint, not camera distance. Fade
 // sub-pixel grain by metres per pixel on both the main and backdrop views.
 float pixel_size=max(length(dFdx(world_xz)),length(dFdy(world_xz)));
 return 1.0-smoothstep(.075,.18,pixel_size);
}
