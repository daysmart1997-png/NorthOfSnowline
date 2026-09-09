shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;
uniform sampler2D backdrop_texture : source_color, filter_linear, repeat_disable;
uniform vec2 texel_size=vec2(.0015625,.002777778);
uniform float focus : hint_range(0.0,1.0)=1.0;
uniform vec2 room_center=vec2(.5,.5);
uniform vec3 haze_color : source_color=vec3(.20,.28,.35);
void fragment(){
 vec2 uv=SCREEN_UV;
 vec2 d=texel_size*mix(.2,1.15,focus);
 vec3 c=texture(backdrop_texture,uv).rgb*.25;
 c+=(texture(backdrop_texture,uv+vec2(d.x,0)).rgb+texture(backdrop_texture,uv-vec2(d.x,0)).rgb+texture(backdrop_texture,uv+vec2(0,d.y)).rgb+texture(backdrop_texture,uv-vec2(0,d.y)).rgb)*.125;
 c+=(texture(backdrop_texture,uv+d).rgb+texture(backdrop_texture,uv-d).rgb+texture(backdrop_texture,uv+vec2(d.x,-d.y)).rgb+texture(backdrop_texture,uv+vec2(-d.x,d.y)).rgb)*.0625;
 float grey=dot(c,vec3(.2126,.7152,.0722));
 c=mix(c,vec3(grey),focus*.32);
 c=mix(c,haze_color,focus*.43);
 float edge=smoothstep(.25,.85,length((uv-room_center)*vec2(1.0,.8)));
 c*=1.0-focus*(.18+edge*.32);
 ALBEDO=c;
}
