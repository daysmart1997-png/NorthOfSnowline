shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void fragment(){
 vec2 p=UV-vec2(.5);
 float toe=length((p-vec2(0,-.12))/vec2(.37,.33));
 float heel=length((p-vec2(0,.25))/vec2(.28,.18));
 float shape=min(toe,heel);
 float inner=1.0-smoothstep(.74,1.0,shape);
 float rim=smoothstep(.72,.88,shape)*(1.0-smoothstep(.90,1.12,shape));
 float tread=step(.58,fract(UV.y*9.0))*.08;
 ALBEDO=mix(vec3(.22,.31,.44),vec3(.57,.66,.75),rim);
 ALPHA=clamp(inner*.48+rim*.30-tread*inner,0.0,.7);
}
