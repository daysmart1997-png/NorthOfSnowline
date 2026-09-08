extends Node3D

const Survival = preload("res://scripts/expedition.gd")
const Player = preload("res://scripts/player_ranger.gd")
const World = preload("res://scripts/world_frontier.gd")
const Backpack = preload("res://scripts/backpack.gd")
const Cassette = preload("res://scripts/cassette_audio.gd")
const TrailMap = preload("res://scripts/trail_map.gd")
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
var inventory: Label
var context_label: Label
var prompt: Label
var toast: Label
var toast_time := 0.0
var meters: Array[ProgressBar] = []
var meter_texts: Array[Label] = []
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
var needs_label:Label
var music_label:Label
var last_discovery := ""
var performance_check:=false
var performance_clock:=0.0
var performance_frames:Array[float]=[]
var menu_veil:ColorRect

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	setup_input()
	world = World.new()
	world.name = "SnowForest"
	add_child(world)
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.position = Vector3(0, 0.2, 20.5)
	build_ui()
	backpack=Backpack.new();canvas.add_child(backpack);backpack.setup(self)
	backpack.roll_closed.connect(func():active=not menu.visible and started and survival.health>0;player.enabled=active)
	cassette=Cassette.new();add_child(cassette)
	player.footfall.connect(cassette.play_step)
	cassette.breath_pulse.connect(player.exhale)
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
		if args.has("--backpack-preview"):
			Input.action_release("move_right")
			survival.loot("preview",{"player":1,"tape_embers":1,"tape_stride":1,"tape_home":1,"cloth":3,"scrap":2,"herb":2,"battery":2})
			survival.use_item("tape_embers");survival.toggle_music()
			toggle_backpack()
			capture_path="res://artifacts/backpack-preview.png"
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
	if args.has("--capture-menu"):
		capture_mode = true
		capture_path = "res://artifacts/menu-preview.png"
	if args.has("--integration"):
		call_deferred("integration_check")
	if args.has("--polish-test"):call_deferred("polish_check")
	if args.has("--frontier-test"):call_deferred("frontier_check")
	if args.has("--performance-check"):
		start_new();performance_check=true;player.position=Vector3(-5,world.terrain_height(-5,-20)+.2,-20);player.pivot.rotation.y=0
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

func style(color: Color, border := Color("73796f")) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(1)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 9
	s.content_margin_bottom = 9
	return s

func label(text_value: String, font_size: int, color := Color("e3e8e4")) -> Label:
	var l := Label.new()
	l.text = text_value
	l.add_theme_font_size_override("font_size", maxi(14,font_size))
	if font_size>=21:
		var heading_font:=SystemFont.new();heading_font.font_names=PackedStringArray(["SimSun","Songti SC","Noto Serif CJK SC"]);l.add_theme_font_override("font",heading_font)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0.06, 0.08, 0.10, 0.45))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l

func panel(at: Vector2, extent: Vector2, parent: Control = canvas) -> PanelContainer:
	var p := preload("res://scripts/field_panel.gd").new()
	p.position = at
	p.custom_minimum_size = extent
	p.add_theme_stylebox_override("panel", style(Color(0.13, 0.16, 0.17, 0.96)))
	parent.add_child(p)
	return p

func button(text_value: String, callback: Callable, parent: Control) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_stylebox_override("normal", style(Color("343d3e")))
	b.add_theme_stylebox_override("hover", style(Color("555d58"), Color("d0b37f")))
	b.add_theme_stylebox_override("pressed", style(Color("262f31")))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	canvas = Control.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(canvas)
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC"])
	theme.default_font = font
	theme.default_font_size = 16
	canvas.theme = theme
	menu_veil=ColorRect.new();menu_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);menu_veil.color=Color(.08,.11,.14,.62);menu_veil.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(menu_veil)
	var heading := label("雪线以北", 26)
	heading.position = Vector2(28, 20)
	canvas.add_child(heading)
	var subtitle := label("NORTH OF THE SNOWLINE  /  0.4", 12, Color("adc0c7"))
	subtitle.position = Vector2(29, 56)
	canvas.add_child(subtitle)
	var task_box := VBoxContainer.new()
	task_box.position = Vector2(29, 93)
	canvas.add_child(task_box)
	task_box.add_child(label("最后一班电波", 12, Color("d5b67d")))
	objective = label("前往北岭车站\n取回无线电备用零件", 14)
	task_box.add_child(objective)
	weather_label = label("", 13)
	weather_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weather_label.position = Vector2(862, 30)
	weather_label.size = Vector2(386, 85)
	canvas.add_child(weather_label)
	context_label = label("", 13, Color("d2bb90"))
	context_label.position = Vector2(29, 163)
	canvas.add_child(context_label)
	var bottom := panel(Vector2(22, 623), Vector2(322, 57))
	bottom.add_theme_stylebox_override("panel", style(Color(0.13, 0.16, 0.17, 0.68), Color(0.45, 0.48, 0.44, 0.35)))
	var stat_box := HBoxContainer.new()
	stat_box.add_theme_constant_override("separation", 15)
	bottom.add_child(stat_box)
	var names := ["体温", "体力", "健康"]
	var colors := [Color("80baca"), Color("d5b77d"), Color("adbf9e")]
	for i in range(3):
		var col := VBoxContainer.new()
		col.custom_minimum_size.x = 84
		stat_box.add_child(col)
		var title := label(names[i], 12)
		col.add_child(title)
		meter_texts.append(title)
		var meter := ProgressBar.new()
		meter.custom_minimum_size = Vector2(84, 4)
		meter.show_percentage = false
		var fill := StyleBoxFlat.new()
		fill.bg_color = colors[i]
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("304650")
		meter.add_theme_stylebox_override("fill", fill)
		meter.add_theme_stylebox_override("background", bg)
		col.add_child(meter)
		meters.append(meter)
	inventory = label("", 12)
	inventory.position = Vector2(970, 642)
	inventory.size.x = 280
	inventory.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	canvas.add_child(inventory)
	needs_label=label("",12,Color("b9c9cd"));needs_label.position=Vector2(30,597);canvas.add_child(needs_label)
	music_label=label("",13,Color("dec498"));music_label.position=Vector2(800,602);music_label.size.x=448;music_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;canvas.add_child(music_label)
	var help := label("WASD 行走    Shift 奔跑    E 交互    B 行囊    V 制作    Tab 地图    Esc 暂停", 12, Color("b5c2d1"))
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.position = Vector2(120, 689)
	help.size.x = 1040
	canvas.add_child(help)
	prompt = label("", 16, Color("f1d49c"))
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.position = Vector2(290, 505)
	prompt.size.x = 700
	canvas.add_child(prompt)
	toast = label("", 14)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.position = Vector2(230, 551)
	toast.size.x = 820
	canvas.add_child(toast)
	map = TrailMap.new()
	map.position = Vector2(870, 105)
	map.size = Vector2(380, 490)
	map.visible = false
	canvas.add_child(map)
	menu = panel(Vector2(375, 98), Vector2(530, 470))
	var menu_box := VBoxContainer.new()
	menu_box.add_theme_constant_override("separation", 10)
	menu.add_child(menu_box)
	menu_box.add_child(label("第一章    /    林区最后一班电波", 14, Color("d5b67d")))
	menu_title = label("风雪将至", 34)
	menu_box.add_child(menu_title)
	menu_info = label("前往北岭车站，取回无线电零件，再返回小屋。\n木柴可以点燃两处火炉；东侧林道能够避风。\n留意体温，别把所有体力耗在去程。", 16)
	menu_box.add_child(menu_info)
	new_button = button("开始新的旅程", start_new, menu_box)
	resume_button = button("继续探索", func(): set_menu(false), menu_box)
	save_button = button("保存当前进度", save_game, menu_box)
	load_button = button("读取上次保存", load_game, menu_box)
	button("退出游戏", func(): get_tree().quit(), menu_box)
	menu_box.add_child(label("门外正在起风。沿旧铁路往北，别忘记回家的路。", 12, Color("9cabb0")))

func start_new() -> void:
	survival = Survival.new()
	player.position = Vector3(0, 0.2, 20.5)
	player.velocity = Vector3.ZERO
	player.pivot.rotation = Vector3(Player.CAMERA_PITCH, Player.CAMERA_YAW, 0)
	player.clear_footprints()
	player.crouching = false
	backpack.visible=false
	world.sync_buildings(survival)
	world.refresh_pickups([])
	started = true
	set_menu(false)
	notify("你在护林小屋。E 与物品交互，Tab 查看北行路线。")

func set_menu(show_menu: bool) -> void:
	menu.visible = show_menu
	active = not show_menu and not backpack.visible and started and survival.health > 0
	player.enabled = active
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if show_menu: canvas.visible = true
	resume_button.visible = started and survival.health > 0
	resume_button.text="继续在林区生存" if survival.completed else "继续探索"
	save_button.visible = resume_button.visible
	load_button.disabled = not FileAccess.file_exists(save_path)
	new_button.text = "重新开始旅程" if started else "开始新的旅程"
	menu_title.text = "暂停 · 风雪正在等待" if started else "风雪将至"
	if survival.completed:
		menu_title.text = "信号已发出"
		menu_info.text = "无线电里终于传来回应。你完成了第一次往返。\n现在可以继续搜寻磁带、搭建营地、加固小屋。\n本次旅程：%d 分 %02d 秒。" % [int(survival.elapsed) / 60, int(survival.elapsed) % 60]
	elif survival.health <= 0:
		menu_title.text = "你倒在了风雪里"
		menu_info.text = "下次可以在车站火炉旁恢复体温，\n或沿东侧避风林道返程。\n读取保存，或重新开始。"
	else:
		menu_info.text = "前往北岭车站，取回无线电零件，再返回小屋。\n木柴可以点燃两处火炉；东侧林道能够避风。\n留意体温，别把所有体力耗在去程。"

func _unhandled_input(event: InputEvent) -> void:
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
	var overlay:bool=menu.visible or backpack.visible
	menu_veil.visible=overlay
	for child in canvas.get_children():
		if child not in [menu,backpack,map,menu_veil]:child.visible=not overlay
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
		player.can_sprint = survival.stamina > (1.0 if player.sprinting else 22.0)
		update_target()
		for poi in world.pois:
			if not survival.discovered.has(poi.id) and player.position.distance_to(poi.at)<9:
				survival.discovered.append(poi.id);notify("发现："+poi.title+" · 已记入手记")
		if survival.health <= 0: set_menu(true)
	cassette.sync(survival,menu.visible,shelter.is_empty(),Vector2(player.velocity.x,player.velocity.z).length() if active else 0.0,float(survival.fires.get(shelter,0))>0,active)
	world.update_snow(player.position,delta if active else 0.0,survival.storm())
	world.weather_update(survival.storm(), player.position, survival.fires)
	update_hud(shelter, windbreak)
	toast_time = maxf(0.0, toast_time - delta)
	toast.visible = toast_time > 0
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

func interact() -> void:
	if target.is_empty(): return
	if target.kind in ["loot","wood","food","parts"]:player.play_action("Pickup")
	elif target.kind in ["fire","radio"]:player.play_action("Interact")
	match target.kind:
		"loot":
			notify(survival.loot(target.id,target.contents));world.refresh_pickups(survival.collected)
		"workbench":backpack.tab="craft";toggle_backpack()
		"rest":notify(survival.rest(world.shelter_at(player.position)))
		"fire": notify(survival.light_fire(target.id))
		"radio":
			if survival.repair():
				set_menu(true)
			else: notify("信号已发出，继续加固庇护所等待救援。" if survival.completed else "还缺少备用零件。沿铁路向北，到车站维修间寻找。")
		_:
			notify(survival.pickup(target.id, target.kind))
			world.refresh_pickups(survival.collected)
	update_target()

func update_hud(shelter: String, windbreak: bool) -> void:
	var names := ["体温", "体力", "健康"]
	var values := [survival.temperature, survival.stamina, survival.health]
	for i in range(3):
		meters[i].value = values[i]
		meter_texts[i].text = "%s   %d" % [names[i], int(values[i])]
	var weather := "晴冷" if survival.storm() < 0.25 else ("风雪增强" if survival.storm() < 0.7 else "暴雪")
	weather_label.text = "%s   ·   %d°C\n已探索 %02d:%02d    |    北 ↗" % [weather, int(-12 - 15 * survival.storm()), int(survival.elapsed) / 60, int(survival.elapsed) % 60]
	weather_label.text+="\n"+world.terrain_name(player.position)
	var target_pos := Vector3(0, 0, 18) if survival.parts else Vector3(0, 0, -170)
	objective.text = ("返回护林小屋\n修复无线电" if survival.parts else "前往北岭车站\n取回无线电零件") + "   %dm" % int(player.position.distance_to(target_pos))
	if survival.completed:objective.text="信号已发出\n加固庇护所，搜寻林区的秘密"
	inventory.text = "木柴 %d    口粮 %d    饮水 %d\n背包 %.1f / 24 kg   [ B ]" % [survival.wood, survival.food, survival.count("water"), survival.weight()]
	needs_label.text="饱食 %d   水分 %d   精力 %d"%[survival.hunger,survival.thirst,survival.energy]
	music_label.text=("♫ "+str(Survival.ITEMS[survival.loaded_tape].name)+"   %d%%"%survival.battery_charge) if not survival.music_effect().is_empty() else ""
	context_label.text = ""
	if not shelter.is_empty():
		var remaining := float(survival.fires[shelter])
		context_label.text = "庇护所 · 炉火 %ds · 快速回暖" % int(remaining) if remaining > 0 else ("小屋已保温 · 缓慢回暖" if shelter=="home" and survival.upgrades.insulation else "庇护所避风 · 尚未点火")
	elif windbreak:
		context_label.text = "林道避风 · 失温速度降低"
	elif survival.temperature < 25:
		context_label.text = "体温过低，尽快寻找火炉！"
	prompt.text = "[ E ]  " + str(target.title) if active and not target.is_empty() else ""
	map.player_position = player.position
	map.discoveries=survival.discovered
	map.camps=survival.structures
	if map.visible: map.queue_redraw()

func notify(message: String) -> void:
	toast.text = message
	toast_time = 5.0

func save_game() -> void:
	var data := {"version": 2, "state": survival.data(), "position": [player.position.x, player.position.y, player.position.z], "yaw": player.pivot.rotation.y}
	var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		menu_info.text = "保存失败：无法写入项目文件夹。"
		return
	file.store_string(JSON.stringify(data))
	file.close()
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path + ".tmp"), ProjectSettings.globalize_path(save_path))
	menu_info.text = "进度已保存到 D 盘项目目录。\n可继续探索，或下次读取保存。" if err == OK else "保存失败，请检查文件是否被占用。"
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
	backpack.visible=false
	world.sync_buildings(survival)
	player.position = Vector3(clampf(p[0], -90, 90), clampf(p[1], -5, 16), clampf(p[2], -210, 49))
	player.position.y=maxf(player.position.y,world.terrain_height(player.position.x,player.position.z)+.06)
	player.velocity = Vector3.ZERO
	player.pivot.rotation = Vector3(Player.CAMERA_PITCH, Player.CAMERA_YAW, 0)
	player.clear_footprints()
	world.refresh_pickups(survival.collected)
	started = true
	set_menu(survival.completed or survival.health <= 0)
	notify("已恢复进度。天气和补给状态也已还原。")

func toggle_backpack()->void:
	canvas.visible=true
	if backpack.visible and not backpack.closing:backpack.close_roll()
	else:map.visible=false;backpack.open_roll()
	active=not backpack.visible and not menu.visible and started and survival.health>0
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
		"rest":result=survival.rest(shelter)
		"craft":
			var position_array:Array=world.candidate_camp(player.position) if id=="camp" else []
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
	assert(world.get_node("TimberTrestleBridge")!=null and world.pois.size()==9)
	active=false;player.enabled=false;set_process(false);cassette.shutdown();backpack.shutdown_ui()
	await get_tree().process_frame;await get_tree().process_frame
	OS.delay_msec(100)
	print("FRONTIER_OK: ridge/basin/lake heights, independent snow accumulation, depth compression, continuous grooves, ice exclusion, live foot IK, terrain collision, modular interiors, nine discoveries")
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
	interact()
	assert(survival.parts)
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
	interact()
	assert(survival.completed)
	survival.music_playing=false
	cassette.shutdown()
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
	active=false;player.enabled=false;set_menu(true);survival.music_playing=false;cassette.shutdown();backpack.shutdown_ui()
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
	set_menu(true);cassette.shutdown();backpack.shutdown_ui()
	await get_tree().process_frame
	await get_tree().process_frame
	OS.delay_msec(100)
	get_tree().quit()
