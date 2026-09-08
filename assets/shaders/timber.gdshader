shader_type spatial;
uniform vec4 timber_color:source_color=vec4(.18,.14,.10,1);
uniform bool floorboards=false;
varying vec3 p;
float hash(vec2 q){return fract(sin(dot(q,vec2(17.19,83.17)))*41243.14);}
void vertex(){p=VERTEX;}
void fragment(){
 float along=floorboards?p.z:p.y;
 float crossgrain=floorboards?p.x:p.x+p.z;
 float grain=sin(crossgrain*83.0+sin(along*.72)*2.1+sin(crossgrain*15.0)*1.7)*.5+.5;
 float flecks=hash(floor(vec2(crossgrain*120.0,along*15.0)));
 ALBEDO=timber_color.rgb*(.97+grain*.035+flecks*.012);
 ROUGHNESS=.92;SPECULAR=.12;
}
