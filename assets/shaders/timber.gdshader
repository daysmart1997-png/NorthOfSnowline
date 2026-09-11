shader_type spatial;
uniform vec4 timber_color:source_color=vec4(.18,.14,.10,1);
uniform bool floorboards=false;
uniform bool horizontal_boards=false;
varying vec3 p;
varying vec3 n;
float hash(vec2 q){return fract(sin(dot(q,vec2(17.19,83.17)))*41243.14);}
void vertex(){p=VERTEX;n=NORMAL;}
void fragment(){
 float along=horizontal_boards?p.x+p.z:(floorboards?p.z:p.y);
 float crossgrain=horizontal_boards?p.y:(floorboards?p.x:p.x+p.z);
 float phase=crossgrain*65.0+sin(along*1.3)*2.1+sin(crossgrain*11.0)*1.7;
 float detail=1.0-smoothstep(.7,2.6,fwidth(phase));
 float grain=sin(phase)*detail;
 float broad=sin(crossgrain*8.0+sin(along*.8)*1.4);
 float weather=smoothstep(-.5,.8,sin(along*1.6+crossgrain*3.0));
 vec3 faded=mix(timber_color.rgb,vec3(.31,.29,.25),weather*.15);
 ALBEDO=faded*(.96+grain*.065+broad*.08);
 ROUGHNESS=clamp(.87+weather*.09+grain*.018,.82,.98);SPECULAR=.16;
}
