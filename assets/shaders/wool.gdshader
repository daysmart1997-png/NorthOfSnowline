shader_type spatial;
uniform vec4 fabric_color : source_color = vec4(.08,.14,.22,1.0);
varying vec3 p;
void vertex(){p=VERTEX;}
void fragment(){
 // Fade threads below pixel size: dense unfiltered sine patterns shimmer
 // and make the coat look metallic at the normal overhead camera distance.
 vec3 thread=p*260.0;
 vec3 visibility=vec3(1.0)-smoothstep(vec3(.6),vec3(2.2),fwidth(thread));
 float weave=(sin(thread.x)*visibility.x*sin(thread.y)*visibility.y+sin(thread.z)*visibility.z)*.004;
 float wear=sin(p.y*9.0+sin(p.x*7.0)+p.z*4.0)*.018;
 ALBEDO=fabric_color.rgb*(1.0+wear)+vec3(weave);
 ROUGHNESS=.96;
 SPECULAR=.13;
}
