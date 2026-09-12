extends Control
# Presentation-only title composition. The live journey and its clock are untouched.
var game
var camera:Camera3D
var clock:=0.0
var was_visible:=false
var music:AudioStreamPlayer
var footer:Label

func setup(main)->void:
	game=main;mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade:=ColorRect.new();shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;shade.show_behind_parent=true;add_child(shade)
	var shader:=Shader.new()
	shader.code="""shader_type canvas_item;
void fragment(){
 float left=1.0-smoothstep(0.20,0.76,UV.x);
 float edge=smoothstep(0.25,0.72,abs(UV.y-0.5));
 COLOR=vec4(vec3(0.028,0.052,0.067),min(0.96,0.18+left*0.73+edge*0.26));
}"""
	var material:=ShaderMaterial.new();material.shader=shader;shade.material=material
	var frequency:Label=game.label("北岭林区   /   无线电守听",12,Color("83999f"))
	frequency.position=Vector2(76,682);frequency.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(frequency)
	camera=Camera3D.new();camera.name="TitleSnowfieldCamera";game.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=24
	camera.cull_mask=game.interior_view.OUTDOOR_VIEW & ~game.interior_view.ACTOR
	music=AudioStreamPlayer.new();music.bus="SnowMusic";music.volume_db=-35;add_child(music)
	var stream:AudioStreamWAV=load("res://assets/audio/winter_ambient.wav").duplicate()
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=int(stream.get_length()*stream.mix_rate);music.stream=stream
	style_menu()

func style_menu()->void:
	game.menu.position=Vector2(74,62);game.menu.custom_minimum_size=Vector2(512,584);game.menu.size=Vector2(512,584)
	game.menu.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	game.menu_box.add_theme_constant_override("separation",10)
	var brand:Label=game.menu_box.get_child(0)
	brand.text="雪 线 以 北"
	var serif:=SystemFont.new();serif.font_names=PackedStringArray(["Songti SC","SimSun","Noto Serif CJK SC"])
	brand.add_theme_font_override("font",serif);brand.add_theme_font_size_override("font_size",64)
	brand.add_theme_color_override("font_color",Color("ede9dc"))
	brand.add_theme_constant_override("outline_size",1);brand.add_theme_color_override("font_outline_color",Color("ede9dc"))
	var subtitle:Label=game.menu_box.get_child(1);subtitle.text="N O R T H   O F   T H E   S N O W L I N E";subtitle.add_theme_font_size_override("font_size",12)
	subtitle.add_theme_color_override("font_color",Color("9badb7"))
	game.menu_title.add_theme_font_size_override("font_size",16)
	game.menu_info.custom_minimum_size=Vector2(480,58);game.menu_info.add_theme_font_size_override("font_size",15)
	game.menu_info.add_theme_color_override("font_color",Color("aebfc5"))
	for node in game.menu_box.find_children("*","Button",true,false):
		node.alignment=HORIZONTAL_ALIGNMENT_LEFT
		node.add_theme_font_size_override("font_size",16)
		for state in ["normal","disabled","hover","pressed","focus"]:
			var box:=StyleBoxFlat.new();box.bg_color=Color(0,0,0,0)
			box.content_margin_left=16;box.content_margin_right=16;box.content_margin_top=9;box.content_margin_bottom=9
			if state in ["hover","pressed","focus"]:
				box.bg_color=Color(.70,.63,.43,.09);box.border_color=Color("d7b879");box.border_width_left=2
			node.add_theme_stylebox_override(state,box)
			node.add_theme_color_override("font_disabled_color",Color("637980"))
	game.new_button.add_theme_color_override("font_color",Color("ead7ac"))
	game.new_button.add_theme_font_size_override("font_size",20)
	footer=game.menu_box.get_child(game.menu_box.get_child_count()-1)
	footer.text="一场风雪，一盏灯，一段尚未回应的信号。"
	footer.add_theme_font_size_override("font_size",13)
	footer.add_theme_color_override("font_color",Color("83999f"))

func _process(delta:float)->void:
	if not is_instance_valid(game):return
	visible=game.menu.visible and not game.started
	if visible:
		clock+=delta;camera.current=true
		var focus:=Vector3(-6.4,1.0,22.8)
		camera.position=focus+Vector3(17,24,23)+Vector3(sin(clock*.07)*.18,0,0);camera.look_at(focus)
		game.world.weather_update(.12,Vector3(0,0,18),game.survival.fires,475.0)
		for entry in game.world.cutaways:
			for node in entry.nodes:node.visible=true
		game.world.sun.light_cull_mask=0xfffff;game.world.night_fill.light_cull_mask=0xfffff
		game.world.snow.visible=true;game.world.snow.global_position=Vector3(0,8,20)
		game.menu_veil.visible=false
		if not music.playing:music.play()
		music.volume_db=lerpf(music.volume_db,-26.0,minf(delta,1))
		queue_redraw()
	elif was_visible:
		camera.current=false
		if game.opening.sheet.visible:game.opening.camera.current=true
		else:game.player.camera.current=true
		music.stop()
	was_visible=visible

func _draw()->void:
	var color:=Color(.62,.72,.74,.35)
	var y:=size.y-54
	draw_line(Vector2(76,y),Vector2(574,y),color,1)
	for i in range(51):
		var x:=76+i*9.96
		draw_line(Vector2(x,y),Vector2(x,y+(8 if i%5==0 else 3)),color,1)
	var tuning:=312+sin(clock*.32)*9
	draw_line(Vector2(tuning,y-5),Vector2(tuning,y+12),Color("d7b879"),2)
	draw_circle(Vector2(size.x-58,54),3,Color(.84,.72,.47,.6+.3*sin(clock*.7)))

func _exit_tree()->void:
	if is_instance_valid(music):music.stop();music.stream=null
