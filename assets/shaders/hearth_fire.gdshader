shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;
// One palette and motion field for enclosed glass, open fire and ember beds.
uniform int surface_kind=0; // 0 glass, 1 rising plane, 2 coal bed
uniform vec3 bounds_min=vec3(0.0);
uniform vec3 bounds_size=vec3(1.0);
uniform float fire_time=0.0;
uniform float heat=0.0;
uniform float gust=0.0;
varying vec3 local_position;
varying vec3 world_position;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 a=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(a),hash(a+vec2(1,0)),f.x),mix(hash(a+vec2(0,1)),hash(a+vec2(1,1)),f.x),f.y);
}
void vertex(){local_position=VERTEX;world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 uv=surface_kind==1?vec2(UV.x,1.0-UV.y):(local_position.xy-bounds_min.xy)/max(bounds_size.xy,vec2(.001));
 if(surface_kind==2){uv=(world_position.xz-bounds_min.xz)/max(bounds_size.xz,vec2(.001));}
 float t=fire_time;
 float coal=noise(uv*vec2(13.0,5.0));
 float ember=smoothstep(.43,.76,coal)*(.7+.3*sin(t*1.2+uv.x*12.0));
 vec3 coal_color=mix(vec3(.023,.017,.013),vec3(.38,.065,.012),ember*heat);
 float height=mix(.28,.94,clamp(heat,0.0,1.0));
 float y=uv.y/max(height,.01);
 float bend=(noise(vec2(uv.y*3.5,t*.8))-.5)*.22*uv.y+gust*uv.y*uv.y*.13;
 float x=uv.x-bend;
 float curl=noise(vec2(x*5.0,y*3.0-t*1.7));
 float tongues=0.0;
 for(int i=0;i<3;i++){
  float fi=float(i);
  float center=.24+fi*.26+sin(t*1.4+fi*2.8+y*5.0)*.035*y;
  float tip=.60+.29*sin(t*.95+fi*2.5);
  float width=mix(.17,.008,clamp(y/tip,0.0,1.0));
  float edge=abs(x-center)+(curl-.5)*.055-width;
  float aa=max(fwidth(edge),.006);
  tongues=max(tongues,(1.0-smoothstep(-aa,aa,edge))*(1.0-smoothstep(tip-.07,tip,y)));
 }
 float base=(1.0-smoothstep(.04,.23,uv.y))*(1.0-smoothstep(.28,.5,abs(uv.x-.5)));
 float flame=max(tongues,base)*smoothstep(0.0,.10,heat);
 float core=(1.0-smoothstep(.06,.55,y))*.75+curl*.12;
 vec3 fire_color=mix(vec3(.84,.13,.018),vec3(1.0,.73,.24),clamp(core,0.0,1.0));
 if(surface_kind==2){ALBEDO=coal_color;ALPHA=1.0;}
 else if(surface_kind==1){ALBEDO=fire_color;ALPHA=flame*.88;}
 else{
  float sill=1.0-smoothstep(.10,.32,uv.y);
  ALBEDO=mix(mix(vec3(.024,.019,.015),coal_color,sill),fire_color,flame);
  ALPHA=1.0;
 }
}
