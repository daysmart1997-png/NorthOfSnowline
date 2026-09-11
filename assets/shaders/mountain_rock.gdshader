shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec3 wp;
varying vec3 wn;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;wn=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 float broad=noise(wp.xz*.22);float fissure=noise(wp.xz*.67+wp.y*.18);
 float snow=smoothstep(.49,.79,wn.y+(broad-.5)*.22);
 vec3 rock=mix(vec3(.15,.19,.22),vec3(.26,.30,.32),broad*.65+fissure*.25);
 vec3 powder=mix(vec3(.48,.55,.59),vec3(.63,.68,.70),broad);
 ALBEDO=mix(rock,powder,snow);ROUGHNESS=.94;SPECULAR=.09;
}
