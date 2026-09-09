shader_type spatial;
uniform vec4 base_color:source_color=vec4(.15,.17,.16,1);
uniform bool metal=false;
varying vec3 p;
void vertex(){p=VERTEX;}
void fragment(){
 float broad=sin(p.x*7.0+sin(p.z*4.0)+p.y*2.1)*sin(p.z*8.0-p.y*3.0);
 float wear=smoothstep(.18,.8,broad);
 float frequency=(p.x+p.y+p.z)*210.0;
 float weave=sin(frequency)*(1.0-smoothstep(.6,2.1,fwidth(frequency)));
 vec3 worn=metal?vec3(.22,.13,.082):base_color.rgb*1.18;
 ALBEDO=mix(base_color.rgb,worn,wear*(metal?.35:.32))+weave*.004;
 ROUGHNESS=metal?mix(.67,.94,wear):.96;
 METALLIC=metal?(1.0-wear)*.42:0.0;SPECULAR=metal?.35:.13;
}
