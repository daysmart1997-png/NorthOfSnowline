shader_type spatial;
uniform vec4 timber_color:source_color=vec4(.18,.14,.10,1);
uniform bool floorboards=false;
uniform bool horizontal_boards=false;
varying vec3 p;
varying vec3 n;
varying vec3 wp;
float hash(vec2 q){return fract(sin(dot(q,vec2(17.19,83.17)))*41243.14);}
float noise(vec2 q){
 vec2 cell=floor(q);vec2 f=fract(q);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(cell),hash(cell+vec2(1,0)),f.x),mix(hash(cell+vec2(0,1)),hash(cell+vec2(1,1)),f.x),f.y);
}
void vertex(){p=VERTEX;n=NORMAL;wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 // Dominant face projection avoids diagonal grain across perpendicular walls.
 float face=abs(n.x)>abs(n.z)?p.z:p.x;
 float along=horizontal_boards?face:(floorboards?p.z:p.y);
 float crossgrain=horizontal_boards?p.y:(floorboards?p.x:face);
 float variation=noise(vec2(crossgrain*7.0,along*.55));
 float warp=noise(vec2(crossgrain*3.5,along*.7));
 float phase=crossgrain*110.0+warp*6.0;
 float detail=1.0-smoothstep(.7,2.6,fwidth(phase));
 float grain=sin(phase)*detail;
 float weather=noise(vec2(crossgrain*2.7,along*.85)+vec2(wp.x,wp.z)*.11);
 vec3 faded=mix(timber_color.rgb,vec3(.31,.29,.25),weather*.10);
 ALBEDO=faded*(.96+grain*.025+(variation-.5)*.12);
 ROUGHNESS=clamp(.89+weather*.07+grain*.01,.85,.98);SPECULAR=.12;
}
