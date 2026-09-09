shader_type spatial;
uniform bool birch=false;
varying vec3 local_pos;
varying vec3 local_normal;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() { local_pos=VERTEX; local_normal=NORMAL; }
void fragment() {
 float grooves=sin(local_pos.y*8.0+sin(local_pos.x*39.0)*1.6+local_pos.z*14.0)*.5+.5;
 // Broad stable bark variation; no pixel-sized checker flecks on branches.
 float grain=sin(local_pos.y*2.3+local_pos.x*6.0+sin(local_pos.z*4.2))*.5+.5;
 vec3 wood=mix(vec3(.055,.073,.105),vec3(.14,.17,.22),grooves*.55+grain*.16);
 float scar_wave=sin(local_pos.y*18.0+sin(local_pos.x*13.0)*2.0+local_pos.z*12.0)*.5+.5;
 float scars=smoothstep(.83,.96,scar_wave)*smoothstep(.25,.72,grain);
 if(birch){wood=mix(vec3(.31,.34,.36),vec3(.105,.13,.17),scars*.72);}
 float snow=smoothstep(.50,.86,local_normal.y)*smoothstep(.12,.75,grain);
 ALBEDO=mix(wood,vec3(.46,.52,.57),snow*.56);
 float damp=1.0-smoothstep(.05,.65,local_pos.y);
 ALBEDO*=1.0-damp*.18;
 ROUGHNESS=mix(.86,.97,1.0-damp);SPECULAR=.13;
}
