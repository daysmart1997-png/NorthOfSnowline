shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D height_field : filter_linear, repeat_disable;
uniform sampler2D tracks : filter_linear, repeat_disable;
uniform sampler2D noise_field : filter_linear, repeat_enable;
uniform sampler2D biomes : filter_linear, repeat_disable;
uniform sampler2D powder_normal : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D powder_roughness : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float powder_world_size : hint_range(1.0,12.0) = 3.5;
uniform float powder_strength : hint_range(0.0,1.0) = 0.22;
uniform vec3 snow_low = vec3(.43,.49,.54);
uniform vec3 snow_high = vec3(.55,.61,.64);
uniform vec2 patch_center=vec2(0.0);
uniform bool local_patch=false;
uniform bool patch_active=false;
varying vec3 wp;
float noise(vec2 p){
 vec2 cell=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
 return textureLod(noise_field,(cell+f+.5)/128.0,0.0).r;
}
// Samples are at half-metre world coordinates, including both end points.
// Map to texel centres, not the texture edges (the old mapping shifted slopes).
vec2 field_uv(vec2 p){return ((p-vec2(-110,-225))*2.0+.5)/vec2(441,581);}
float base_height(vec2 p){return textureLod(height_field,field_uv(p),0.0).r;}
float patch_weight(vec2 p){vec2 d=abs(p-patch_center);return 1.0-smoothstep(10.0,11.9,max(d.x,d.y));}
float track_depth(vec2 p){vec2 uv=(p-patch_center)/24.0+.5;return textureLod(tracks,clamp(uv,vec2(.001),vec2(.999)),0.0).r*patch_weight(p);}
float height_at(vec2 p){return base_height(p)-(local_patch?track_depth(p):0.0);}
float normal_height(vec2 p){return base_height(p)-(local_patch?track_depth(p)*.65:0.0);}
float coarse_height(vec2 p){
 vec2 a=floor(p);vec2 f=fract(p);
 float h00=base_height(a);float h10=base_height(a+vec2(1,0));
 float h01=base_height(a+vec2(0,1));float h11=base_height(a+vec2(1,1));
 return f.x+f.y<1.0?h00+(h10-h00)*f.x+(h01-h00)*f.y:h11+(h01-h11)*(1.0-f.x)+(h10-h11)*(1.0-f.y);
}
void vertex(){
 wp=(MODEL_MATRIX*vec4(VERTEX,1)).xyz;
 if(local_patch){
  float edge=max(abs(wp.x-patch_center.x),abs(wp.z-patch_center.y));
  VERTEX.y=height_at(wp.xz);
  if(edge>10.5){VERTEX.y=mix(VERTEX.y,coarse_height(wp.xz),smoothstep(10.5,11.9,edge));}
  wp.y=VERTEX.y;
 }
}
void fragment(){
 float edge=max(abs(wp.x-patch_center.x),abs(wp.z-patch_center.y));
 if(!local_patch && patch_active && edge<11.98){discard;}
 if(local_patch && edge>=11.98){discard;}
 vec2 p=wp.xz;
 vec2 biome=texture(biomes,field_uv(p)).rg;
 float ice=smoothstep(.75,.99,biome.g);
 float broad=noise(p*.18);
 float drift=noise(p*.63+vec2(broad*2.4,-broad));
 // Slow world-space distortion breaks repeated dimples without changing
 // collision, accumulated snow depth, or the existing footprint field.
 vec2 powder_uv=p/powder_world_size+vec2(broad-.5,drift-.5)*.55;
 vec2 powder=texture(powder_normal,powder_uv).rg*2.0-1.0;
 float grain=texture(powder_roughness,powder_uv).r;
 float pressed=local_patch?max(track_depth(p),0.0):0.0;
 // Both mesh resolutions share per-pixel normals. Fine grain stays in the
 // material; adding geometric bands made the snow look like rectangular slabs.
 float e=.065;
 vec3 n=vec3(normal_height(p-vec2(e,0))-normal_height(p+vec2(e,0)),2.0*e,normal_height(p-vec2(0,e))-normal_height(p+vec2(0,e)));
 float ripple=cos(dot(p,vec2(3.1,1.4))+drift*7.0)*.004;
 n.xz+=vec2(ripple,ripple*.45)*(1.0-ice)*(1.0-smoothstep(.003,.03,pressed));
 float loose=smoothstep(.06,.25,biome.r*.65);
 float relief=powder_strength*mix(.32,1.0,loose)*(1.0-smoothstep(.001,.045,pressed)*.85)*(1.0-ice);
 // OpenGL normal Y follows texture-up, opposite increasing world Z.
 n=normalize(n);n.xz+=vec2(powder.x,-powder.y)*relief;
 NORMAL=normalize(mat3(VIEW_MATRIX)*normalize(n));
 ALBEDO=mix(snow_low,snow_high,.30+broad*.35+drift*.18);
 ALBEDO*=mix(.94,1.03,loose);
 ALBEDO+=vec3((grain-.5)*.009);
 // Packed approaches have only ~2 cm of compression. Shade that shallow
 // compaction independently of deep snow, without digging a deeper hole.
 float thin=1.0-smoothstep(.07,.20,biome.r*.65);
 float sole=smoothstep(.001,.020,pressed);
 float compaction=mix(smoothstep(.003,.075,pressed)*.20,sole*.22,thin);
 ALBEDO*=1.0-compaction;
 // Sole cavities receive less diffuse sky light in tree shade and at night.
 // This uses the existing track texture, with no extra lights or glow.
 AO=1.0-sole*thin*.10;
 AO_LIGHT_AFFECT=0.0;
 ROUGHNESS=mix(.80,.96,grain);
 SPECULAR=.12;
 if(ice>.001){
 float veins=pow(1.0-abs(sin(p.x*.63+p.y*.24+noise(p*.24)*2.0)),22.0);
 float frost=smoothstep(.54,.77,noise(p*.45))*.35;
 vec3 frozen=mix(vec3(.20,.31,.39),vec3(.40,.51,.57),frost+veins*.13);
 ALBEDO=mix(ALBEDO,frozen,ice);
 ROUGHNESS=mix(ROUGHNESS,.36+frost*.8,ice);
 SPECULAR=mix(SPECULAR,.48,ice);
 }
}
