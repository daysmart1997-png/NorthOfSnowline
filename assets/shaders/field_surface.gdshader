shader_type spatial;
uniform vec4 base_color:source_color=vec4(.15,.17,.16,1);
uniform bool metal=false;
varying vec3 p;
varying vec3 n;
float hash(vec2 q){return fract(sin(dot(q,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 q){
 vec2 cell=floor(q);vec2 f=fract(q);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(cell),hash(cell+vec2(1,0)),f.x),mix(hash(cell+vec2(0,1)),hash(cell+vec2(1,1)),f.x),f.y);
}
void vertex(){p=VERTEX;n=NORMAL;}
void fragment(){
 vec2 face=abs(n.y)>.6?p.xz:(abs(n.x)>abs(n.z)?p.zy:p.xy);
 float wear=smoothstep(.44,.80,noise(face*5.0)+noise(face*17.0)*.15);
 vec2 frequency=face*240.0;
 vec2 filter_size=fwidth(frequency);
 float weave=sin(frequency.x)*sin(frequency.y)*(1.0-smoothstep(.6,2.1,max(filter_size.x,filter_size.y)));
 vec3 worn=metal?vec3(.22,.13,.082):base_color.rgb*1.18;
 ALBEDO=mix(base_color.rgb,worn,wear*(metal?.35:.32))+weave*.004;
 ROUGHNESS=metal?mix(.67,.94,wear):.96;
 METALLIC=metal?(1.0-wear)*.42:0.0;SPECULAR=metal?.35:.13;
}
