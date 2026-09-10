shader_type spatial;
render_mode cull_disabled;

uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 dye_factor = vec3(1.0);
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform bool protect_warm_details = false;

void fragment() {
	vec3 base = texture(atlas, UV).rgb;
	// Scarf, leather fasteners and exposed skin retain their original pigment.
	float warm = protect_warm_details ? smoothstep(1.1, 1.4, base.r / max(base.b, 0.005)) : 0.0;
	ALBEDO = mix(base * dye_factor, base, warm) * (1.0 - wetness * 0.23);
	ROUGHNESS = mix(0.93, 0.76, wetness);
}
