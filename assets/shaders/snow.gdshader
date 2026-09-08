shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p=world_pos.xz;
 float drifts=noise(p*.24)*.60+noise(p*.83)*.26+noise(p*3.2)*.14;
 float crust=noise(p*26.0);
 float wind=sin(p.x*3.1+p.y*.7+noise(p*.4)*5.0)*.5+.5;
 ALBEDO=mix(vec3(.37,.46,.58),vec3(.47,.56,.68),drifts)+vec3((crust-.5)*.008+wind*.008);
 ROUGHNESS=.90+crust*.06;
 SPECULAR=.18;
 NORMAL=normalize(NORMAL+vec3(dFdx(crust)*.022,dFdy(crust)*.022,0.0));
}
