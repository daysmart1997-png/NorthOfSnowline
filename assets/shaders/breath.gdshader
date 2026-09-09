shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

void vertex() {
 // Face the camera while retaining the CPU particle's individual scale.
 vec3 size=vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*size.x,INV_VIEW_MATRIX[1]*size.y,INV_VIEW_MATRIX[2]*size.z,MODEL_MATRIX[3]);
}

void fragment() {
 float radial=1.0-smoothstep(.12,.5,length(UV-vec2(.5)));
 ALBEDO=vec3(.78,.85,.90);
 ALPHA=radial*min(COLOR.a,.14);
}
