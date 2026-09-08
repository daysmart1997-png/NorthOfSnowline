shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D height_field : filter_linear, repeat_disable;
uniform sampler2D tracks : filter_linear, repeat_disable;
uniform sampler2D biomes : filter_linear, repeat_disable;
uniform vec2 patch_center=vec2(0.0);
uniform bool local_patch=false;
uniform bool patch_active=false;
varying vec3 wp;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 a=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(a),hash(a+vec2(1,0)),f.x),mix(hash(a+vec2(0,1)),hash(a+vec2(1,1)),f.x),f.y);}
float track_depth(vec2 p){vec2 uv=(p-patch_center)/24.0+.5;return textureLod(tracks,clamp(uv,vec2(0.001),vec2(.999)),0.0).r;}
float height_at(vec2 p){return textureLod(height_field,(p-vec2(-110,-225))/vec2(220,290),0.0).r-track_depth(p);}
void vertex(){
 wp=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;
 if(local_patch){
  VERTEX.y=height_at(wp.xz);
  float e=.055;
  NORMAL=normalize(vec3(height_at(wp.xz-vec2(e,0))-height_at(wp.xz+vec2(e,0)),2.0*e,height_at(wp.xz-vec2(0,e))-height_at(wp.xz+vec2(0,e))));
  wp.y=VERTEX.y;
 }
}
void fragment(){
 if(!local_patch && patch_active && max(abs(wp.x-patch_center.x),abs(wp.z-patch_center.y))<11.93){discard;}
 vec2 p=wp.xz;
 float broad=noise(p*.22);
 float wind=sin(p.x*4.0+p.y*1.25+noise(p*.6)*3.0)*.5+.5;
 float grain=noise(p*48.0);
 float pressed=local_patch?max(track_depth(p),0.0):0.0;
 ALBEDO=mix(vec3(.43,.51,.62),vec3(.58,.64,.73),broad*.60+.25);
 ALBEDO+=vec3((grain-.5)*.013+wind*.009);
 ALBEDO*=1.0-smoothstep(.008,.15,pressed)*.22;
 ROUGHNESS=mix(.86,.98,grain);
 SPECULAR=.22;
 // Only rare, subdued grains catch the grazing sun.
 ROUGHNESS-=smoothstep(.985,1.0,grain)*.18;
 vec2 biome=texture(biomes,(p-vec2(-110,-225))/vec2(220,290)).rg;
 float ice=smoothstep(.75,.99,biome.g);
 float veins=pow(1.0-abs(sin(p.x*.63+p.y*.24+noise(p*.24)*2.0)),22.0);
 float frost=smoothstep(.54,.77,noise(p*.45))*0.35;
 vec3 frozen=mix(vec3(.20,.31,.39),vec3(.40,.51,.57),frost+veins*.13);
 ALBEDO=mix(ALBEDO,frozen,ice);
 ROUGHNESS=mix(ROUGHNESS,.36+frost*.8,ice);
 SPECULAR=mix(SPECULAR,.48,ice);
}
