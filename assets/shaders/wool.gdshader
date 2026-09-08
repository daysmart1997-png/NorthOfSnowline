shader_type spatial;
uniform vec4 fabric_color : source_color = vec4(.08,.14,.22,1.0);
varying vec3 p;
void vertex(){p=VERTEX;}
void fragment(){
 float weave=(sin(p.x*600.0)*sin(p.y*600.0)+sin(p.z*520.0))*.012;
 ALBEDO=fabric_color.rgb+vec3(weave);
 ROUGHNESS=.96;
 SPECULAR=.13;
}
