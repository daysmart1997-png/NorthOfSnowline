extends Node3D

const Survival = preload("res://scripts/expedition.gd")
const Player = preload("res://scripts/player_ranger.gd")
const World = preload("res://scripts/world_frontier.gd")
const Backpack = preload("res://scripts/backpack.gd")
const Cassette = preload("res://scripts/cassette_audio.gd")
const TrailMap = preload("res://scripts/trail_map.gd")
const Palette=preload("res://scripts/field_theme.gd")
const HUD=preload("res://scripts/survival_hud.gd")
const DayCycle=preload("res://scripts/day_cycle.gd")
const Chapter=preload("res://scripts/chapter_one.gd")
const StoryPanel=preload("res://scripts/chapter_panel.gd")
var story_panel:PanelContainer
var radio_lamp:MeshInstance3D
var radio_lit:=false
var opening
var field
var interior_view=preload("res://scripts/interior_view.gd").new()
const SAVE_PATH := "res://savegame.json"
var save_path := SAVE_PATH
var survival = Survival.new()
var player: CharacterBody3D
var world: Node3D
var active := false
var started := false
var target: Dictionary = {}
var canvas: Control
var weather_label: Label
var objective: Label
var context_label: Label
var prompt: Label
var toast: Label
var toast_time := 0.0
var menu: PanelContainer
var menu_title: Label
var menu_info: Label
var resume_button: Button
var new_button: Button
var save_button: Button
var load_button: Button
var map: Control
var capture_mode := false
var capture_frames := 0
var capture_path := "res://artifacts/demo-preview.png"
var backpack:PanelContainer
var cassette:Node
var music_label:Label
var last_discovery := ""
var performance_check:=false
var performance_clock:=0.0
var performance_frames:Array[float]=[]
var menu_veil:ColorRect
var status_hud:Control
var help_label:Label
var preferences=preload("res://scripts/game_preferences.gd").new()
var settings_box:VBoxContainer
var menu_box:VBoxContainer
var pending_action:Dictionary={}
var action_clock:=0.0
var action_duration:=.7
var action_origin:=Vector3.ZERO
var objective_seen:=""
var objective_reveal:=0.0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	if OS.get_cmdline_user_args().has("--isolated-settings"):
		preferences.path="res://artifacts/exploration/test-preferences.cfg"
	else:preferences.load_preferences()
	preferences.apply_audio()
	setup_input()
	world = World.new()
	world.name = "SnowForest"
	add_child(world)
	radio_lamp=world.find_child("RadioTransmitLamp",true,false)
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.position = Vector3(0, 0.2, 20.5)
	interior_view.setup(world,player)
	build_ui()
	backpack=Backpack.new();canvas.add_child(backpack);backpack.setup(self)
	story_panel=StoryPanel.new();canvas.add_child(story_panel);story_panel.setup(self)
	opening=preload("res://scripts/opening_sequence.gd").new();add_child(opening);opening.setup(self)
	backpack.roll_closed.connect(func():active=not menu.visible and not story_panel.visible and started and survival.health>0;player.enabled=active)
	cassette=Cassette.new();add_child(cassette)
	player.footfall.connect(cassette.play_step)
	cassette.breath_pulse.connect(player.exhale)
	field=preload("res://scripts/field_expedition.gd").new();add_child(field);field.setup(self)
	player.collision_mask=5
	world.sync_buildings(survival)
	set_menu(true)
	var args := OS.get_cmdline_user_args()
	if args.has("--capture"):
		capture_mode = true
		start_new()
		Engine.max_fps = 60
		player.position = Vector3(-4, 0.3, -24)
		player.clear_footprints()
		Input.action_press("move_right")
		survival.elapsed = 35.0
		toast_time = 0.0
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if args.has("--clean"): canvas.visible = false
		if args.has("--map-preview"):
			map.visible = true
			capture_path = "res://artifacts/map-preview.png"
		if args.has("--backpack-preview") or args.has("--craft-preview") or args.has("--journal-preview"):
			Input.action_release("move_right")
			survival.loot("preview",{"player":1,"tape_embers":1,"tape_stride":1,"tape_home":1,"cloth":3,"scrap":2,"herb":2,"battery":2})
			survival.use_item("tape_embers");survival.toggle_music()
			toggle_backpack()
			capture_path="res://artifacts/backpack-preview.png"
			if args.has("--craft-preview"):
				backpack.tab="craft";backpack.refresh();capture_path="res://artifacts/craft-preview.png"
			if args.has("--journal-preview"):
				backpack.tab="journal";backpack.refresh();capture_path="res://artifacts/journal-preview.png"
		if args.has("--camp-preview") or args.has("--camp-exterior-preview"):
			Input.action_release("move_right")
			survival.items["wood"]=7;survival.items["cloth"]=4
			var site:Array=world.candidate_camp(Vector3(-5,0,-60))
			survival.craft("camp","",site);world.sync_buildings(survival);survival.light_fire("camp_0")
			if site.size()==3:player.position=Vector3(site[0]-1,site[1]+.2,site[2]+1)
			player.zoom=13;player.camera.size=13
			capture_path="res://artifacts/camp-preview.png"
			if args.has("--camp-exterior-preview") and site.size()==3:
				player.position=Vector3(site[0],site[1]+.2,site[2]+4);player.pivot.position.z=-2;capture_path="res://artifacts/v04-camp-exterior.png"
		if args.has("--approach-preview"):
			Input.action_release("move_right");player.position=Vector3(0,.2,25.4)
			player.pivot.rotation.y=PI;player.zoom=11;player.camera.size=11
			Input.action_press("move_up");capture_path="res://artifacts/approach-preview.png"
		if args.has("--low-status-preview"):
			survival.health=20;survival.temperature=20;survival.stamina=10;survival.thirst=20;survival.hunger=20;survival.energy=20
			capture_path="res://artifacts/low-status-preview.png"
		if args.has("--character-preview"):
			Input.action_release("move_right");player.position=Vector3(0,.2,-27);player.zoom=5;player.camera.size=5
			player.visual.rotation.y=PI
			capture_path="res://artifacts/character-preview.png"
		if args.has("--gait-proof"):
			player.position=Vector3(-12,world.terrain_height(-12,-24)+.2,-24);player.zoom=6;player.camera.size=6
			capture_path="res://artifacts/v04-gait.png"
		if args.has("--snow-preview"):
			Input.action_release("move_right");player.position=Vector3(-10,world.terrain_height(-10,-29)+.2,-29);player.zoom=10;player.camera.size=10
			for i in range(14):
				var p:=Vector3(-10+(.14 if i%2==0 else -.14),0,-29+i*.50)
				world.stamp_snow(p,0,.75+i*.04,i%2==0)
			capture_path="res://artifacts/snow-preview.png"
		if args.has("--crouch-preview") or args.has("--run-preview"):
			player.position=Vector3(-6,world.terrain_height(-6,-27)+.3,-27);player.zoom=7;player.camera.size=7
			player.crouching=args.has("--crouch-preview")
			if args.has("--run-preview"):Input.action_press("sprint")
			capture_path="res://artifacts/crouch-preview.png" if player.crouching else "res://artifacts/run-preview.png"
		for scene in ["cabin","interior","bridge","lake","hollow","ridge"]:
			if args.has("--"+scene+"-preview"):
				Input.action_release("move_right")
				var places:Dictionary={"cabin":Vector3(0,0,26),"interior":Vector3(0,.3,19),"bridge":Vector3(0,.2,-82),"lake":Vector3(-28,-1.5,-89),"hollow":Vector3(39,0,-43),"ridge":Vector3(-34,0,-36)}
				player.position=places[scene];player.position.y=maxf(player.position.y,world.terrain_height(player.position.x,player.position.z)+.1)
				player.zoom=16 if scene in ["cabin","interior"] else 27;player.camera.size=player.zoom
				if scene=="cabin":player.pivot.position.z=-4;player.zoom=20;player.camera.size=20
				if scene=="hollow":player.zoom=13;player.camera.size=13
				if scene=="interior":survival.light_fire("home")
				if scene=="hollow":
					for i in range(18):world.stamp_snow(Vector3(39+(.15 if i%2==0 else -.15),0,-43+i*.38),0,1,i%2==0)
				capture_path="res://artifacts/v04-"+scene+".png"
		for phase in {"dawn":6.3,"noon":12.0,"dusk":17.3,"night":23.0}:
			if args.has("--"+phase+"-preview"):
				survival.elapsed=fposmod(float({"dawn":6.3,"noon":12.0,"dusk":17.3,"night":23.0}[phase])-DayCycle.START_HOUR,24.0)*60.0
				capture_path=capture_path.trim_suffix(".png")+"-"+phase+".png"
	if args.has("--pause-preview"):
			set_menu(true);capture_path="res://artifacts/pause-preview.png"
	if args.has("--capture-menu"):
		capture_mode = true
		capture_path = "res://artifacts/menu-preview.png"
	if args.has("--snow-ui-test"):call_deferred("snow_ui_check")
	if args.has("--day-cycle-test"):call_deferred("day_cycle_check")
	if args.has("--integration"):
		call_deferred("integration_check")
	if args.has("--polish-test"):call_deferred("polish_check")
	if args.has("--frontier-test"):call_deferred("frontier_check")
	if args.has("--performance-check"):
		start_new();performance_check=true;player.position=Vector3(-5,world.terrain_height(-5,-20)+.2,-20);player.pivot.rotation.y=0
		if args.has("--night-preview"):survival.elapsed=840
		Input.action_press("move_up");Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func setup_input() -> void:
	var actions := {"move_left": KEY_A, "move_right": KEY_D, "move_up": KEY_W,
		"move_down": KEY_S, "sprint": KEY_SHIFT, "crouch": KEY_C,
		"interact": KEY_E, "eat": KEY_F, "trail_map": KEY_TAB, "pause_game": KEY_ESCAPE, "hide_hud": KEY_H,
		"backpack":KEY_B,"music":KEY_M,"build_menu":KEY_V}
	for key in actions:
		if not InputMap.has_action(key): InputMap.add_action(key)
		var event := InputEventKey.new()
		event.physical_keycode = actions[key]
		InputMap.action_add_event(key, event)
	for pair in [["move_left", KEY_LEFT], ["move_right", KEY_RIGHT], ["move_up", KEY_UP], ["move_down", KEY_DOWN]]:
		var event := InputEventKey.new()
		event.physical_keycode = pair[1]
		InputMap.action_add_event(pair[0], event)

func style(color:Color,border:=Color.TRANSPARENT)->StyleBoxFlat:
	return Palette.box(color,border)

func label(text_value:String,font_size:int,color:=Palette.INK)->Label:
	var result:=Label.new()
	result.text=text_value
	result.add_theme_font_size_override("font_size",maxi(14,font_size))
	result.add_theme_color_override("font_color",color)
	return result

func panel(at:Vector2,extent:Vector2,parent:Control=canvas)->PanelContainer:
	var result:=PanelContainer.new()
	result.position=at;result.custom_minimum_size=extent
	var surface:=style(Palette.PANEL)
	surface.content_margin_left=24;surface.content_margin_right=24
	surface.content_margin_top=24;surface.content_margin_bottom=24
	result.add_theme_stylebox_override("panel",surface)
	parent.add_child(result)
	return result

func button(text_value:String,callback:Callable,parent:Control)->Button:
	var result:=Button.new()
	result.text=text_value;result.custom_minimum_size=Vector2(0,40)
	Palette.button_theme(result)
	result.pressed.connect(callback);parent.add_child(result)
	return result

func hud_label(text_value:String,at:Vector2,extent:Vector2,font_size:=16,color:=Palette.INK)->Label:
	var result:=label(text_value,font_size,color)
	result.position=at;result.size=extent
	result.mouse_filter=Control.MOUSE_FILTER_IGNORE
	result.add_theme_color_override("font_outline_color",Color(.035,.065,.085,.7))
	result.add_theme_constant_override("outline_size",2)
	canvas.add_child(result)
	return result

func build_ui()->void:
	var layer:=CanvasLayer.new();add_child(layer)
	canvas=Control.new();canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(canvas)
	var theme:=Theme.new();theme.default_font=Palette.font();theme.default_font_size=16;canvas.theme=theme
	status_hud=HUD.new();status_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);canvas.add_child(status_hud)
	objective=hud_label("",Vector2(32,32),Vector2(490,60),16)
	weather_label=hud_label("",Vector2(832,32),Vector2(416,72),16)
	weather_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	context_label=hud_label("",Vector2(32,96),Vector2(560,26),14,Palette.ACCENT)
	music_label=hud_label("",Vector2(808,600),Vector2(440,24),14,Palette.ACCENT)
	music_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	prompt=hud_label("",Vector2(320,514),Vector2(640,36),20)
	prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast=hud_label("",Vector2(250,562),Vector2(780,28),18)
	toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	help_label=hud_label("",Vector2.ZERO,Vector2.ZERO,14,Palette.MUTED)
	help_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	map=TrailMap.new();map.position=Vector2(858,112);map.size=Vector2(390,490);map.visible=false;canvas.add_child(map)
	menu_veil=ColorRect.new();menu_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_veil.color=Color(.035,.065,.085,.66);menu_veil.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(menu_veil)
	menu=panel(Vector2(360,72),Vector2(560,576))
	menu_box=VBoxContainer.new();menu_box.add_theme_constant_override("separation",12);menu.add_child(menu_box)
	menu_box.add_child(label("雪线以北",28))
	menu_box.add_child(label("第一章 · 失联",14,Palette.MUTED))
	menu_title=label("风雪将至",20,Palette.ACCENT);menu_box.add_child(menu_title)
	menu_info=label("",16);menu_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	menu_info.custom_minimum_size=Vector2(512,76);menu_box.add_child(menu_info)
	new_button=button("开始新的旅程",func():start_new();opening.begin(),menu_box)
	resume_button=button("继续探索",func():set_menu(false),menu_box)
	save_button=button("保存当前进度",save_game,menu_box)
	load_button=button("读取上次保存",load_game,menu_box)
	button("声音与界面",func():show_settings(true),menu_box)
	button("退出游戏",func():get_tree().quit(),menu_box)
	var controls:=label("WASD 移动 · Shift 奔跑 · C 蹲行 · E 交互\nB 行囊 · V 制作 · Tab 地图 · M 磁带 · H 隐藏界面",14,Palette.MUTED)
	menu_box.add_child(controls)
	build_settings()
	canvas.resized.connect(layout_exploration_hud)
	layout_exploration_hud()

func layout_exploration_hud()->void:
	# Separate notification, interaction and vital-stat lanes, anchored to viewport.
	var extent:=canvas.size
	var width:=minf(740,extent.x-64)
	prompt.position=Vector2((extent.x-width)*.5,extent.y-174);prompt.size=Vector2(width,44)
	toast.position=Vector2((extent.x-width)*.5,extent.y-236);toast.size=Vector2(width,48)
	for item in [prompt,toast]:
		item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		item.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		item.add_theme_constant_override("line_spacing",3)
	music_label.position=Vector2(extent.x-472,extent.y-122);music_label.size=Vector2(440,24)
	weather_label.position.x=extent.x-448
	map.position.x=extent.x-422

func build_settings()->void:
	settings_box=VBoxContainer.new();settings_box.add_theme_constant_override("separation",14);menu.add_child(settings_box);settings_box.visible=false
	settings_box.add_child(label("声音与界面",24))
	settings_box.add_child(label("调整到适合你的风雪。",14,Palette.MUTED))
	for spec in [["master","总音量",0.0,1.0],["music","音乐与磁带",0.0,1.0],["effects","风声与动作",0.0,1.0],["hud_scale","生存栏大小",.85,1.3]]:
		var key:String=spec[0]
		var caption:=label("%s  %d%%"%[spec[1],roundi(preferences.get(key)*100)],16);settings_box.add_child(caption)
		var slider:=HSlider.new();slider.name="Setting_"+key;slider.min_value=spec[2];slider.max_value=spec[3];slider.step=.05;slider.value=preferences.get(key);slider.custom_minimum_size=Vector2(440,24);settings_box.add_child(slider)
		var title:String=spec[1]
		slider.value_changed.connect(func(value:float):preferences.set(key,value);preferences.apply_audio();caption.text="%s  %d%%"%[title,roundi(value*100)])
	var compact_toggle:=CheckButton.new();compact_toggle.name="Setting_compact_hud"
	compact_toggle.text="简洁探索界面（关闭后显示完整信息）";compact_toggle.button_pressed=preferences.compact_hud
	compact_toggle.toggled.connect(func(value:bool):preferences.compact_hud=value);settings_box.add_child(compact_toggle)
	button("返回",func():preferences.save_preferences();show_settings(false),settings_box)

func show_settings(show:bool)->void:
	menu_box.visible=not show;settings_box.visible=show
	if show:settings_box.find_child("Setting_master",true,false).grab_focus()
	else:resume_button.grab_focus() if started else new_button.grab_focus()

func start_new() -> void:
	cancel_action()
	survival = Survival.new()
	survival.temperature=68;survival.energy=70
	survival.kit.owned[survival.kit.equipped.feet].wet=35
	if field!=null:field.reset()
	player.position = Vector3(0, world.terrain_height(0,38)+.2, 38)
	player.velocity = Vector3.ZERO
	player.pivot.rotation = Vector3(Player.CAMERA_PITCH, Player.CAMERA_YAW, 0)
	player.clear_footprints()
	player.crouching = false
	backpack.visible=false
	story_panel.visible=false
	world.sync_buildings(survival)
	world.refresh_pickups([])
	started = true
	set_menu(false)
	notify("连夜赶路让你又冷又渴。前方是七号小屋；B 取用食水、查看人物。")

func set_menu(show_menu: bool) -> void:
	if show_menu:
		cancel_action()
		if is_instance_valid(story_panel):story_panel.visible=false
	if is_instance_valid(settings_box):show_settings(false)
	menu.visible = show_menu
	active = not show_menu and not backpack.visible and not story_panel.visible and started and survival.health > 0
	player.enabled = active
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if show_menu: canvas.visible = true
	resume_button.visible = started and survival.health > 0
	resume_button.text="继续在林区生存" if survival.completed else "继续探索"
	save_button.visible = resume_button.visible
	load_button.disabled = not FileAccess.file_exists(save_path)
	new_button.text = "重新开始旅程" if started else "开始新的旅程"
	new_button.get_parent().move_child(new_button,7 if started else 4)
	if show_menu:
		if started:resume_button.grab_focus()
		else:new_button.grab_focus()
	menu_title.text = "暂停 · 风雪正在等待" if started else "风雪将至"
	if survival.completed and survival.health>0:
		menu_title.text = "求援成功 · 失联"
		menu_info.text = "谷口已经记下你的位置，约好明晚再次守听。\n旧频道出现微弱信号，可休整后再次查看。\n林区时间已过：%d 小时 %02d 分钟。" % [int(survival.elapsed) / 60, int(survival.elapsed) % 60]
	elif survival.health <= 0:
		menu_title.text = "你倒在了风雪里"
		menu_info.text = "下次可以在车站火炉旁恢复体温，\n或沿东侧避风林道返程。\n读取保存，或重新开始。"
	else:
		menu_info.text = "昨夜山崩截断了下山路，你的平安报还没发出。\n桌上值守簿提到北岭维修间的备用模块。\n恢复通信，询问失联搭档周岑的消息。"

func _unhandled_input(event: InputEvent) -> void:
	if capture_mode:return
	if story_panel.visible:
		if event.is_action_pressed("pause_game"):close_story();get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause_game") and settings_box.visible:
		preferences.save_preferences();show_settings(false);get_viewport().set_input_as_handled();return
	if event.is_action_pressed("backpack") and started and not menu.visible:
		toggle_backpack();get_viewport().set_input_as_handled();return
	if event.is_action_pressed("pause_game") and started:
		if backpack.visible:
			toggle_backpack();get_viewport().set_input_as_handled();return
		set_menu(not menu.visible)
		get_viewport().set_input_as_handled()
		return
	if not active: return
	if event.is_action_pressed("build_menu"):
		backpack.tab="craft";toggle_backpack()
	if event.is_action_pressed("music"):notify(survival.toggle_music())
	if event.is_action_pressed("hide_hud"): canvas.visible = not canvas.visible
	if event.is_action_pressed("interact"): interact()
	if event.is_action_pressed("eat"):
		if survival.food>0:player.play_action("Consume")
		notify(survival.eat())
	if event.is_action_pressed("trail_map"): map.visible = not map.visible

func _process(delta: float) -> void:
	var overlay:bool=menu.visible or backpack.visible or story_panel.visible
	menu_veil.visible=overlay
	for child in canvas.get_children():
		if child not in [menu,backpack,map,menu_veil,story_panel]:child.visible=not overlay
	map.modulate.a=0.0 if overlay else 1.0
	if performance_check:
		performance_clock+=delta
		if performance_clock>1.0:performance_frames.append(delta*1000)
		if performance_clock>7.0:performance_check=false;finish_performance_check()
	var shelter: String = world.shelter_at(player.position)
	var windbreak: bool = world.windbreak_at(player.position)
	if active:
		survival.tick(delta, shelter, windbreak, player.sprinting)
		player.move_factor = survival.speed_factor()*world.travel_factor(player.position,player.velocity)
		# Hysteresis prevents exhausted sprint toggling every frame.
		player.can_sprint = survival.stamina > (1.0 if player.sprinting else 22.0) and not survival.kit.has_condition("sprain")
		update_target()
		advance_action(delta)
		for poi in world.pois:
			if not poi.get("inspect",false) and not survival.discovered.has(poi.id) and player.position.distance_to(poi.at)<9:
				survival.discovered.append(poi.id);notify("发现："+poi.title+" · 已记入手记")
		if active and survival.parts and not survival.completed and not survival.chapter.weather_warned and shelter.is_empty() and (survival.storm()>.35 or DayCycle.cold(survival.elapsed)>.35):
			survival.chapter.weather_warned=true
			notify("风正在变硬。先找背风处；铁路直返，林道绕远但避风。")
		if survival.health <= 0: set_menu(true)
	cassette.sync(survival,menu.visible,shelter.is_empty(),Vector2(player.velocity.x,player.velocity.z).length() if active else 0.0,float(survival.fires.get(shelter,0))>0,active)
	world.update_snow(player.position,delta if active else 0.0,survival.storm())
	world.weather_update(survival.storm(), player.position, survival.fires, survival.elapsed)
	interior_view.update()
	if is_instance_valid(radio_lamp) and radio_lit!=(survival.chapter.radio_step>0):
		radio_lit=survival.chapter.radio_step>0
		radio_lamp.material_override=world.mat("daa36e" if radio_lit else "343e3e")
	update_hud(shelter, windbreak)
	if overlay:objective.visible=false;weather_label.visible=false;context_label.visible=false
	toast_time = maxf(0.0, toast_time - delta)
	toast.visible = toast_time > 0 and not overlay
	if capture_mode:
		capture_frames += 1
		if OS.get_cmdline_user_args().has("--gait-proof") and capture_frames in [55,64,73,82]:capture_gait_frame(capture_frames)
		if capture_frames == 85 and not OS.get_cmdline_user_args().has("--crouch-preview") and not OS.get_cmdline_user_args().has("--run-preview"): Input.action_release("move_right")
		if capture_frames == 120:
			capture_mode = false
			capture_image()

func update_target() -> void:
	target = {}
	var best := 2.5
	for point in world.points:
		if survival.collected.has(point.id): continue
		var distance := player.position.distance_to(point.position)
		if distance >= best: continue
		var query := PhysicsRayQueryParameters3D.create(player.position + Vector3(0, 1.2, 0), point.position)
		query.exclude = [player.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.position.distance_to(point.position) > 0.8: continue
		best = distance
		target = point

func cancel_action()->void:
	pending_action={};action_clock=0
	if is_instance_valid(player):player.action_time=0

func interact() -> void:
	if active and field!=null and field.interaction():return
	if active and target.get("kind")=="parts" and not survival.kit.module_ready:
		notify(field.start_job("module","module"));return
	if not active or target.is_empty() or not pending_action.is_empty():return
	if target.kind in ["workbench","rest"]:
		backpack.tab="craft";toggle_backpack();return
	pending_action=target.duplicate()
	action_origin=player.position;action_clock=0
	action_duration=.7 if target.kind in ["loot","wood","food","parts","clue"] else .85
	player.play_action("Pickup" if target.kind in ["loot","wood","food","parts"] else "Interact")

func advance_action(delta:float)->void:
	if pending_action.is_empty():return
	if not active or player.position.distance_to(action_origin)>.25 or target.get("id","")!=pending_action.id:
		cancel_action();return
	action_clock+=delta
	if action_clock<action_duration:return
	var action:=pending_action.duplicate();cancel_action()
	match action.kind:
		"loot":notify(survival.loot(action.id,action.contents))
		"clue":
			if not survival.discovered.has(action.id):survival.discovered.append(action.id)
			backpack.journal_focus=action.id;backpack.tab="journal";toggle_backpack()
			notify("已记下这条线索。")
		"fire":notify(survival.light_fire(action.id))
		"radio":
			if not survival.parts:
				Chapter.discover(survival,"home_log");open_story("intro")
			else:
				survival.repair();open_story("epilogue" if survival.completed else "radio")
		"parts":
			notify(survival.pickup(action.id,action.kind))
			if survival.collected.has(action.id):
				Chapter.discover(survival,"station_dispatch");open_story("station")
		_:notify(survival.pickup(action.id,action.kind))
	world.refresh_pickups(survival.collected);update_target()

func open_story(kind:String)->void:
	cancel_action();backpack.visible=false;map.visible=false;canvas.visible=true
	active=false;player.enabled=false;player.velocity=Vector3.ZERO
	story_panel.show_scene(kind)

func close_story()->void:
	story_panel.visible=false
	active=not menu.visible and not backpack.visible and started and survival.health>0
	player.enabled=active

func update_hud(shelter:String,windbreak:bool)->void:
	status_hud.survival=survival;status_hud.hud_scale=preferences.hud_scale
	status_hud.compact=preferences.compact_hud;status_hud.show_details=survival.elapsed<18 or map.visible
	status_hud.update_warnings()
	status_hud.temperature_trend=survival.temperature_rate(shelter,windbreak) if survival.temperature<100 or survival.temperature_rate(shelter,windbreak)<0 else 0.0
	status_hud.action_progress=action_clock/action_duration if not pending_action.is_empty() else -1.0
	status_hud.queue_redraw()
	var weather:="晴冷" if survival.storm()<.25 else ("风雪增强" if survival.storm()<.7 else "暴雪")
	weather_label.text="第 %d 天  ·  %s  %s\n%s  /  %d°C  ·  %s"%[DayCycle.day(survival.elapsed),DayCycle.clock_text(survival.elapsed),DayCycle.phase(survival.elapsed),weather,roundi(survival.outdoor_temperature()),world.terrain_name(player.position)]
	objective.text=Chapter.objective(survival)
	if objective.text!=objective_seen:objective_seen=objective.text;objective_reveal=9.0
	if active:objective_reveal=maxf(0,objective_reveal-get_process_delta_time())
	objective.visible=not preferences.compact_hud or map.visible or survival.elapsed<18 or objective_reveal>0
	weather_label.visible=not preferences.compact_hud or map.visible or survival.elapsed<18
	context_label.text=""
	if not shelter.is_empty():
		var remaining:=float(survival.fires.get(shelter,0))
		context_label.text="庇护所 · 炉火剩余 %d 分钟 · 正在回暖"%ceili(remaining) if remaining>0 else ("庇护所 · 已封窗，失温减缓" if shelter=="home" and survival.upgrades.insulation else "庇护所 · 尚未点火")
	elif survival.temperature<25:context_label.text="体温过低 · 尽快寻找火炉"
	elif DayCycle.cold(survival.elapsed)>.65:context_label.text="夜间严寒 · 林道避风，尽早寻找庇护所" if windbreak else "夜间严寒 · 回庇护所生火取暖"
	elif DayCycle.phase(survival.elapsed)=="暮色":context_label.text="天色渐暗 · 留好返程的木柴与口粮"
	elif windbreak:context_label.text="林道避风 · 失温减缓"
	context_label.add_theme_color_override("font_color",Palette.DANGER if survival.temperature<25 else Palette.ACCENT)
	context_label.position.y=96 if objective.visible else 32
	music_label.text=("磁带 · "+str(Survival.ITEMS[survival.loaded_tape].name)+"  %d%%"%survival.battery_charge) if not survival.music_effect().is_empty() else ""
	prompt.text="[ E ]  "+str(target.title) if active and not target.is_empty() else ""
	if active and target.get("kind")=="radio":
		prompt.text="[ E ]  "+(("回顾 · 旧频道记录" if survival.chapter.epilogue_step==3 else "旧频道有微弱信号") if survival.completed else ("接起听筒 · 继续通话" if survival.chapter.radio_step>0 else ("安装模块 · 恢复通信" if survival.parts else "查看无线电 · 值守记录")))
	if not pending_action.is_empty():prompt.text=("正在查看" if pending_action.kind=="clue" else ("正在添柴" if pending_action.kind=="fire" else "正在操作"))+" · 移动取消"
	if field!=null and active:
		var field_context:String=field.context_text()
		if not field_context.is_empty():prompt.text=field_context
	prompt.visible=active and not map.visible
	map.player_position=player.position;map.discoveries=survival.discovered;map.camps=survival.structures
	if map.visible:map.queue_redraw()
	help_label.visible=false

func notify(message: String) -> void:
	toast.text = message
	toast_time = 4.0

func save_game() -> void:
	var data := {"version": 2, "state": survival.data(), "position": [player.position.x, player.position.y, player.position.z], "yaw": player.pivot.rotation.y}
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		menu_info.text = "保存失败：无法写入项目文件夹。"
		return
	file.store_string(JSON.stringify(data))
	file.close()
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path + ".tmp"), ProjectSettings.globalize_path(save_path))
	menu_info.text = "进度已保存。\n可继续探索，或下次读取保存。" if err == OK else "保存失败，请检查文件是否被占用。"
	load_button.disabled = not FileAccess.file_exists(save_path)

func load_game() -> void:
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		menu_info.text = "没有找到可读取的存档。"
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Dictionary:
		menu_info.text = "存档内容损坏，未改变当前进度。"
		return
	var candidate = Survival.new()
	var p = data.get("position")
	if (data.get("version") != 1 and data.get("version") != 2) or not data.get("state") is Dictionary or not p is Array or p.size() != 3:
		menu_info.text = "存档格式不兼容，未改变当前进度。"
		return
	for value in p:
		if not (value is float or value is int):
			menu_info.text = "存档位置无效。"
			return
	if not (data.get("yaw") is float or data.get("yaw") is int) or not candidate.restore(data.state):
		menu_info.text = "存档数据无效，未改变当前进度。"
		return
	survival = candidate
	if field!=null:field.reset()
	backpack.visible=false
	story_panel.visible=false
	world.sync_buildings(survival)
	player.position = Vector3(clampf(p[0], -90, 90), clampf(p[1], -5, 16), clampf(p[2], -210, 49))
	player.position.y=maxf(player.position.y,world.terrain_height(player.position.x,player.position.z)+.06)
	player.velocity = Vector3.ZERO
	player.pivot.rotation = Vector3(Player.CAMERA_PITCH, Player.CAMERA_YAW, 0)
	player.clear_footprints()
	world.refresh_pickups(survival.collected)
	started = true
	set_menu(survival.completed or survival.health <= 0)
	notify("已恢复进度。时间、天气和补给状态已还原。")

func toggle_backpack()->void:
	cancel_action()
	canvas.visible=true
	if backpack.visible and not backpack.closing:backpack.close_roll()
	else:map.visible=false;backpack.open_roll()
	active=not backpack.visible and not menu.visible and not story_panel.visible and started and survival.health>0
	player.enabled=active
	if not active:player.velocity=Vector3.ZERO

func backpack_action(kind:String,id:String)->String:
	var shelter:String=world.shelter_at(player.position)
	var result:=""
	match kind:
		"use":
			result=survival.use_item(id)
			if id in ["food","water","tea"]:player.play_action("Consume")
		"music":result=survival.toggle_music()
		"deposit":result=survival.transfer(id,true,shelter)
		"withdraw":result=survival.transfer(id,false,shelter)
		"discard":result=survival.discard(id)
		"rest":result=survival.rest(shelter,int(id) if not id.is_empty() else 2)
		"craft":
			var position_array:Array=world.candidate_camp(player.position) if id=="camp" else []
			if int(Survival.RECIPES.get(id,{}).get("minutes",0))>0:return field.start_job("craft",id)
			result=survival.craft(id,shelter,position_array)
			world.sync_buildings(survival)
	if survival.health<=0:
		backpack.visible=false;set_menu(true)
	return result

func capture_image() -> void:
	await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png(capture_path)
	print("CAPTURE_RESULT=", result)
	get_tree().quit()

func capture_gait_frame(frame:int)->void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/v04-gait-%d.png"%frame)

func frontier_check()->void:
	start_new()
	var ridge:=Vector3(-34,0,-36);var hollow:=Vector3(39,0,-43);var lake:=Vector3(-31,0,-89)
	assert(world.terrain_height(ridge.x,ridge.z)>5 and world.terrain_height(hollow.x,hollow.z)<0,"High ridge and recessed basin")
	assert(world.snow_depth(hollow)>.40 and world.snow_depth(hollow)>world.snow_depth(ridge)*2,"Sheltered basin accumulates more snow than exposed ridge")
	assert(world.surface_at(lake)=="ice" and world.snow_depth(lake)==0)
	assert(is_equal_approx(world.terrain_height(-31,-89),world.terrain_height(-29,-88)),"Frozen water level is continuous")
	world.clear_tracks()
	var light:float=world.stamp_snow(ridge,0,1,true)
	var deep:float=world.stamp_snow(hollow,0,1,true)
	assert(deep>light and deep<=world.snow_depth(hollow),"Snow depth changes real displacement")
	world.stamp_snow(hollow+Vector3(0,0,.7),0,1,true)
	var grooves:int=world.track_marks.filter(func(s:Dictionary)->bool:return s.get("kind")=="drag").size()
	assert(grooves==1,"Successive deep-snow contacts form a continuous groove")
	world.update_snow(hollow,0,0)
	var midpoint:Vector2=(Vector2(hollow.x,hollow.z+.35)-world.patch_center)*32+Vector2(384,384)
	assert(world.track_image.get_pixel(int(midpoint.x),int(midpoint.y)).r>.03,"Groove indents between the bootprints")
	assert(world.stamp_snow(lake,0,1,true)==0 and not world.last_sole.has(true),"Ice breaks the trench chain")
	player.position=Vector3(-18,world.terrain_height(-18,-34)+.2,-34);player.velocity=Vector3.ZERO;player.pivot.rotation.y=0;player.clear_footprints()
	Input.action_press("move_up")
	for i in range(150):
		await get_tree().physics_frame
		if i>30:
			for side in ["L","R"]:
				var foot:int=player.skeleton.find_bone("foot."+side)
				var actual:Quaternion=player.skeleton.get_bone_global_pose(foot).basis.get_rotation_quaternion()
				var rest:Quaternion=player.skeleton.get_bone_global_rest(foot).basis.get_rotation_quaternion()
				assert(absf(actual.dot(rest))>.90,"Boot must not tip upright or twist through the gait")
	Input.action_release("move_up")
	assert(player.feet_modifier.adjustments>80,"Skeleton modifier is adjusting feet on real slope contacts")
	assert(player.ground_samples.size()==2 and player.is_on_floor(),"Both foot rays reach the terrain")
	for side in ["L","R"]:
		assert(absf(player.feet_modifier.corrections[side])<=.221)
		var bone:int=player.skeleton.find_bone("foot."+side)
		assert(player.skeleton.get_bone_global_pose(bone).is_finite(),"Foot pose stays finite")
	player.position=Vector3(-31,-1.2,-89);player.velocity=Vector3.ZERO
	for i in range(35):await get_tree().physics_frame
	assert(player.is_on_floor() and absf(player.position.y+1.65)<.06,"Lake collision agrees with visible ice level")
	for name in ["Interior","Roof","StorageChest","UpgradeBed","WindowRepairs"]:assert(world.buildings.home.find_child(name,true,false)!=null)
	assert(world.get_node("TimberTrestleBridge")!=null and world.pois.filter(func(p):return not p.get("inspect",false)).size()==9)
	active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame;await get_tree().process_frame
	OS.delay_msec(100)
	print("FRONTIER_OK: ridge/basin/lake heights, independent snow accumulation, depth compression, continuous grooves, ice exclusion, live foot IK, terrain collision, modular interiors, nine places plus inspectable clues")
	get_tree().quit()

func integration_check() -> void:
	save_path = "res://artifacts/test-save.json"
	start_new()
	assert(player.camera.projection == Camera3D.PROJECTION_ORTHOGONAL)
	assert(is_equal_approx(player.pivot.rotation.y, Player.CAMERA_YAW))
	assert(player.animation_names.size()==8,"Mesh2Motion retarget must expose eight usable clips")
	# Physical movement through the doorway, then a solid wall collision.
	player.position = Vector3(0, 0.2, 20.5)
	player.pivot.rotation.y = PI
	Input.action_press("move_up")
	for i in range(125): await get_tree().physics_frame
	Input.action_release("move_up")
	assert(player.position.z > 23.0, "Player must exit through the doorway")
	player.pivot.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	Input.action_press("move_up")
	for i in range(125): await get_tree().physics_frame
	Input.action_release("move_up")
	assert(player.position.z < 22.0, "Player must reenter without a blocking doorstep")
	player.position = Vector3(0, 0.2, 18)
	player.pivot.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	Input.action_press("move_up")
	for i in range(110): await get_tree().physics_frame
	Input.action_release("move_up")
	assert(player.position.z > 14.3, "Player must not walk through the rear wall")
	player.position = Vector3(0, 0.2, -76)
	player.velocity = Vector3.ZERO
	Input.action_press("move_up")
	for i in range(150): await get_tree().physics_frame
	Input.action_release("move_up")
	assert(player.position.z < -79, "Bridge must be traversable without jumping")
	set_menu(true)
	var paused_time: float = survival.elapsed
	for i in range(4): await get_tree().process_frame
	assert(survival.elapsed == paused_time, "Pause must stop survival simulation")
	active = false
	player.enabled = false
	player.position = Vector3(0, 0.2, 20.5)
	await get_tree().physics_frame
	assert(world.shelter_at(player.position) == "home")
	player.position = Vector3(-2.4, 0.2, -169.8)
	await get_tree().physics_frame
	update_target()
	assert(target.get("id") == "radio_parts", "Station parts must be accessible")
	survival.kit.module_ready=true;set_menu(false);interact()
	assert(not survival.parts,"Pickup waits for contact feedback")
	for i in range(60):await get_tree().process_frame
	assert(survival.parts and story_panel.visible)
	story_panel.select_route("direct")
	# Exercise the real backpack callbacks, placement checks and audio node.
	survival.items["wood"]=8;survival.items["cloth"]=8;survival.items["scrap"]=4
	player.position=Vector3(0,.2,20.5)
	backpack_action("craft","storage")
	assert(survival.upgrades.storage and world.improvement_root.get_child_count()>0)
	backpack_action("deposit","wood")
	assert(int(survival.storage.get("wood",0))==1)
	player.position=Vector3(-5,.2,-60)
	await get_tree().physics_frame
	backpack_action("craft","camp")
	assert(survival.structures.size()==1,"Valid outdoor site must build a camp")
	var cp:Array=survival.structures[0].position
	assert(world.shelter_at(Vector3(cp[0],cp[1],cp[2]))=="camp_0")
	survival.items["player"]=1;survival.items["tape_embers"]=1
	backpack_action("use","tape_embers");backpack_action("music","")
	cassette.sync(survival,false)
	assert(cassette.speaker.playing and cassette.speaker.stream.get_length()>10,"Cassette must have real playable audio")
	backpack.visible=true;backpack.refresh();backpack.visible=false
	save_game()
	# A second save verifies replacement of an existing file.
	save_game()
	survival.parts = false
	load_game()
	assert(survival.parts and survival.collected.has("radio_parts"), "Disk load restores task and one-shot items")
	assert(survival.structures.size()==1 and survival.music_playing and survival.upgrades.storage,"V2 disk save preserves camps, cassette and repairs")
	active = false
	player.enabled = false
	player.position = Vector3(-2.4, 0.2, 18.2)
	await get_tree().physics_frame
	update_target()
	assert(target.get("id") == "radio", "Home radio must be accessible")
	survival.kit.module_ready=true;set_menu(false);interact()
	for i in range(60):await get_tree().process_frame
	assert(story_panel.visible and not survival.completed)
	story_panel.transmit("call");story_panel.transmit("report");story_panel.transmit("confirm")
	assert(survival.completed)
	survival.music_playing=false
	cassette.shutdown();story_panel.shutdown_audio()
	await get_tree().process_frame
	await get_tree().process_frame
	OS.delay_msec(100)
	print("INTEGRATION_OK: Blender rig, movement, collision, backpack, shelter building, storage, actual cassette audio, v2 disk save, radio milestone")
	get_tree().quit()

func polish_check()->void:
	start_new()
	assert(player.animation_names.size()==8)
	player.position=Vector3(-12,world.terrain_height(-12,-24)+.2,-24)
	player.pivot.rotation.y=0
	Input.action_press("move_up")
	for i in range(70):await get_tree().physics_frame
	assert(cassette.footsteps_played>=2,"Footsteps must follow the live gait")
	assert(world.track_marks.size()>=2,"Gait must indent outdoor snow")
	assert(player.last_clip=="Walk")
	player.crouching=true
	for i in range(30):await get_tree().physics_frame
	assert(player.last_clip=="CrouchWalk","Dedicated crouch locomotion")
	Input.action_release("move_up");player.crouching=false
	for i in range(20):await get_tree().physics_frame
	player.play_action("Pickup")
	assert(player.last_clip=="Pickup")
	var a:=Vector3(-11,0,-31)
	world.clear_tracks()
	var light:float=world.stamp_snow(a,0,.7,true)
	var heavy:float=world.stamp_snow(a+Vector3(.4,0,0),0,1.5,false)
	assert(heavy>light and light>0,"Pressure changes indentation depth")
	world.update_snow(a,0,0)
	var center:Vector2=(Vector2(a.x,a.z)-world.patch_center)*32+Vector2(384,384)
	assert(world.track_image.get_pixel(int(center.x),int(center.y)).r>0,"Track height map stores depressed boot interior")
	var old_age:float=world.track_marks[0].age
	world.update_snow(a,10,1)
	assert(world.track_marks[0].age>=old_age+39,"Storm accelerates filling footprints")
	assert(world.stamp_snow(Vector3(0,0,18),0,1,true)==0,"Cabin floors do not deform")
	survival.items["player"]=1;survival.items["tape_stride"]=1;survival.items["battery"]=1
	toggle_backpack()
	var paused:float=survival.elapsed
	for i in range(26):await get_tree().process_frame
	assert(backpack.visible and is_equal_approx(backpack.scale.y,1.0) and not player.enabled)
	assert(survival.elapsed==paused,"Opening animation keeps survival paused")
	assert(backpack.category_buttons.size()==6)
	await click_control(backpack.category_buttons["tapes"])
	assert(backpack.category=="tapes","Pointer click selects category")
	var source:Control=backpack.find_child("Slot_tape_stride",true,false)
	var dock:Control=backpack.find_child("MagneticDock",true,false)
	assert(source!=null and dock!=null,"Tapes and persistent player dock are visible together")
	var begin:=source.get_global_rect().get_center();var end:=dock.get_global_rect().get_center()
	var down:=InputEventMouseButton.new();down.position=begin;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;get_viewport().push_input(down,true)
	await get_tree().process_frame
	var drag:=InputEventMouseMotion.new();drag.position=begin+Vector2(24,0);drag.relative=Vector2(24,0);drag.button_mask=MOUSE_BUTTON_MASK_LEFT;get_viewport().push_input(drag,true)
	await get_tree().process_frame
	drag=InputEventMouseMotion.new();drag.position=end;drag.relative=end-begin;drag.button_mask=MOUSE_BUTTON_MASK_LEFT;get_viewport().push_input(drag,true)
	await get_tree().process_frame
	var up:=InputEventMouseButton.new();up.position=end;up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;get_viewport().push_input(up,true)
	for i in range(3):await get_tree().process_frame
	assert(survival.loaded_tape=="tape_stride","Actual pointer drag installs the tape")
	toggle_backpack()
	for i in range(26):await get_tree().process_frame
	assert(not backpack.visible and player.enabled,"Closing roll restores movement")
	# Reopening during closing must cancel the old completion callback.
	toggle_backpack();toggle_backpack();toggle_backpack()
	for i in range(26):await get_tree().process_frame
	assert(backpack.visible and not backpack.closing and not player.enabled)
	toggle_backpack()
	for i in range(26):await get_tree().process_frame
	survival.stamina=5;cassette.breath_wait=0;cassette.breathing_effort=.8
	cassette.sync(survival,false,true,5.0,false,true)
	assert(cassette.breathing.playing and cassette.breaths_played>0,"Exertion triggers recorded breathing")
	cassette.sync(survival,true,true,0,false,false)
	assert(cassette.breathing.stream_paused and cassette.background.stream_paused)
	assert(cassette.background.stream.get_length()>70 and cassette.step_bank.snow.size()==8)
	active=false;player.enabled=false;set_menu(true);survival.music_playing=false;cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame
	await get_tree().process_frame
	OS.delay_msec(100)
	print("POLISH_OK: eight clips, gait/foley coupling, snow pressure/fill, indoor exclusion, categories, real pointer drag, interrupted unroll, pause, breathing, ambient score")
	get_tree().quit()

func click_control(control:Control)->void:
	var point:=control.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=point;get_viewport().push_input(motion,true)
	var down:=InputEventMouseButton.new();down.position=point;down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;get_viewport().push_input(down,true)
	await get_tree().process_frame
	var up:=InputEventMouseButton.new();up.position=point;up.button_index=MOUSE_BUTTON_LEFT;up.pressed=false;get_viewport().push_input(up,true)
	await get_tree().process_frame
	await get_tree().process_frame

func finish_performance_check()->void:
	Input.action_release("move_up")
	performance_frames.sort()
	var average:=0.0
	for ms in performance_frames:average+=ms
	average/=maxi(1,performance_frames.size())
	var report:={"render_size":str(get_viewport().get_texture().get_size()),"samples":performance_frames.size(),"average_ms":average,"median_ms":performance_frames[performance_frames.size()/2],"p95_ms":performance_frames[int(performance_frames.size()*.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"triangles":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"scope":"6-second moving scene sample after 1-second warmup; not a full-game benchmark"}
	var file:=FileAccess.open("res://artifacts/v04-performance.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("PERFORMANCE_SAMPLE ",JSON.stringify(report))
	set_menu(true);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame
	await get_tree().process_frame
	OS.delay_msec(100)
	get_tree().quit()

func snow_ui_check()->void:
	start_new()
	# Regression: flattening the approach/rail bed must never erase its snow.
	for at in [Vector3(0,0,26),Vector3(0,0,30),Vector3(0,0,-25),Vector3(22,0,-40)]:
		world.clear_tracks()
		var depth:float=world.snow_depth(at)
		assert(depth>.005,"Packed outdoor snow retains a physical snow layer")
		var pressed:float=world.stamp_snow(at,0,1,true)
		assert(pressed>0 and pressed<=depth,"Thin snow accepts a bounded sole impression")
		world.update_snow(at,0,0)
		var pixel:Vector2=(Vector2(at.x,at.z)-world.patch_center)*32+Vector2(384,384)
		assert(world.track_image.get_pixel(int(pixel.x),int(pixel.y)).r>0,"Approach imprint reaches the render texture")
	for at in [Vector3(0,0,18),Vector3(0,.2,23),Vector3(0,.2,-86),Vector3(-31,-1.65,-89)]:
		assert(world.stamp_snow(at,0,1,true)==0,"Cabin, porch, bridge and lake remain unmarked")
	world.clear_tracks()
	player.position=Vector3(0,.2,20.5);player.velocity=Vector3.ZERO
	player.pivot.rotation.y=PI;player.clear_footprints()
	Input.action_press("move_up")
	for i in range(270):await get_tree().physics_frame
	Input.action_release("move_up")
	assert(player.position.z>26,"Walk continuously from cabin across ramp onto packed snow")
	var outside:Array=world.track_marks.filter(func(mark:Dictionary)->bool:return mark.kind=="boot" and mark.at.y>25)
	assert(outside.size()>=3,"Actual gait leaves multiple prints immediately outside the door")
	assert(outside.any(func(mark:Dictionary)->bool:return mark.left) and outside.any(func(mark:Dictionary)->bool:return not mark.left),"Both boots imprint packed snow")
	assert(not world.track_marks.any(func(mark:Dictionary)->bool:return mark.kind=="drag"),"Packed approach does not create deep-snow grooves")
	map.visible=true
	await get_tree().process_frame
	assert(map.visible and map.modulate.a==1,"Map remains visible during exploration")
	toggle_backpack()
	for i in range(24):await get_tree().process_frame
	assert(not status_hud.visible and backpack.visible,"Inventory suppresses the exploration HUD")
	assert(backpack.modulate.a>.99 and backpack.scale==Vector2.ONE,"Inventory opens fully without stretch distortion")
	toggle_backpack()
	for i in range(24):await get_tree().process_frame
	assert(status_hud.visible and not backpack.visible,"Closing inventory restores the HUD")
	active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame;await get_tree().process_frame
	# Match the other audio integration checks: let the mixer consume stop/free
	# commands before exiting an accelerated headless test.
	OS.delay_msec(100)
	print("SNOW_UI_OK: packed approach and rail prints, bounded depth, wood/ice exclusion, live door exit, alternating gait, HUD and map states")
	get_tree().quit()

func day_cycle_check()->void:
	save_path="res://artifacts/day-cycle-save.json"
	start_new()
	for i in range(4):await get_tree().process_frame
	var running_time:float=survival.elapsed
	for i in range(8):await get_tree().process_frame
	assert(survival.elapsed>running_time,"Exploration advances time")
	set_menu(true)
	var paused_time:float=survival.elapsed
	for i in range(16):await get_tree().process_frame
	assert(survival.elapsed==paused_time,"Pause freezes survival and the solar clock")
	set_menu(false);toggle_backpack()
	paused_time=survival.elapsed
	for i in range(24):await get_tree().process_frame
	assert(survival.elapsed==paused_time,"Open inventory freezes time")
	player.position=Vector3(0,.24,20.5)
	survival.upgrades.bed=true;survival.fires.home=240
	survival.elapsed=890 # 23:50, crossing midnight while resting in the inventory.
	var before_rest:float=survival.elapsed
	backpack_action("rest","")
	assert(survival.elapsed==before_rest+120 and DayCycle.day(survival.elapsed)==2,"Rest intentionally advances two hours through midnight")
	assert(survival.fires.home==120,"Rest consumes fire fuel on the same clock")
	for i in range(4):await get_tree().process_frame
	assert(world.sun.light_energy==0 and not world.sun.shadow_enabled,"Sun is below the horizon at night")
	assert(world.night_fill.light_energy>0 and not world.night_fill.shadow_enabled,"Night fill reveals relief without a second shadow map")
	assert(world.env.ambient_light_energy>=.2,"Night has a readable ambient floor")
	save_game()
	var saved_time:float=survival.elapsed
	var saved_direction:Basis=world.sun.basis
	survival.elapsed=0
	load_game();set_menu(true)
	for i in range(4):await get_tree().process_frame
	assert(survival.elapsed==saved_time and world.sun.basis.is_equal_approx(saved_direction),"File load restores time and lighting while paused")
	# Compare clear/weather lighting at the same time without changing game rules.
	world.lighting_time=-INF;world.update_daylight(0,0)
	var morning:Basis=world.sun.basis
	world.lighting_time=-INF;world.update_daylight(360,0)
	assert(not world.sun.basis.is_equal_approx(morning),"Sun and shadow direction move across the day")
	var clear_energy:float=world.sun.light_energy
	world.lighting_time=-INF;world.update_daylight(360,1)
	assert(world.sun.light_energy<clear_energy and world.sun.light_energy>0,"Clouds attenuate daylight without replacing the solar cycle")
	world.lighting_time=-INF;world.update_daylight(840,1)
	assert(world.sun.light_energy==0,"Weather cannot turn the night sun back on")
	start_new();set_menu(true)
	for i in range(4):await get_tree().process_frame
	assert(survival.elapsed==0 and world.sun.light_energy>0,"New journey resets the clock and lighting")
	assert(world.night_fill.light_energy==0,"Night fill switches off in daylight")
	active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame;await get_tree().process_frame
	OS.delay_msec(100)
	print("DAY_CYCLE_OK: live clock, pause/inventory freeze, rest across midnight, saved lighting, moving sun, storm attenuation, night visibility, new journey reset")
	get_tree().quit()
