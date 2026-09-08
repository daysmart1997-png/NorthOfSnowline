shader_type spatial;
uniform bool birch=false;
varying vec3 local_pos;
varying vec3 local_normal;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() { local_pos=VERTEX; local_normal=NORMAL; }
void fragment() {
 float grooves=sin(local_pos.y*8.0+sin(local_pos.x*39.0)*1.6+local_pos.z*14.0)*.5+.5;
 float grain=hash(floor(local_pos.xy*55.0));
 vec3 wood=mix(vec3(.055,.073,.105),vec3(.14,.17,.22),grooves*.55+grain*.16);
 float scars=step(.86,sin(local_pos.y*31.0+floor(local_pos.x*8.0)*2.0+floor(local_pos.z*9.0))*.5+.5);
 if(birch){wood=mix(vec3(.40,.43,.46),vec3(.105,.13,.17),scars*.88);}
 float snow=smoothstep(.32,.75,local_normal.y)*step(.36,grain);
 ALBEDO=mix(wood,vec3(.40,.48,.59),snow*.72);
 ROUGHNESS=.97;
}
