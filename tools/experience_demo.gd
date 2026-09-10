extends "res://tools/playtest_demo.gd"

# A reproducible local recording, separate from the shipped main scene.
# Gameplay uses real movement and UI. The final, explicitly labelled lighting
# study changes only the displayed solar time, never the survival clock/save.
var light_study := false
var study_clock := 0.0
var study_caption: Label

func _ready() -> void:
	demo_output = "res://artifacts/experience-demo-2026-09-10"
	if DisplayServer.get_name() == "headless":demo_output += "-rehearsal"
	super._ready()
	# Windows MovieWriter needs its normal presentation loop. The inherited
	# forced draw workaround is only for covered macOS recording windows.
	if OS.get_name() == "Windows":RenderingServer.render_loop_enabled = true

func draw_movie_frame() -> void:
	if OS.get_name() != "Windows":super.draw_movie_frame()

func _process(delta: float) -> void:
	super._process(delta)
	if light_study:
		study_clock += 1.0 / 30.0
		var elapsed := lerpf(180.0, 1350.0, clampf(study_clock / 48.0, 0.0, 1.0))
		world.weather_update(.12, player.position, survival.fires, elapsed)
		study_caption.text = "昼夜光影 · 延时展示     %s  %s" % [DayCycle.clock_text(elapsed), DayCycle.phase(elapsed)]

func press_button_with(text_prefix: String) -> bool:
	for node in backpack.find_children("*", "Button", true, false):
		if node.text.begins_with(text_prefix) and node.is_visible_in_tree() and not node.disabled:
			var parent: Node = node.get_parent()
			while parent != backpack:
				if parent is ScrollContainer:parent.ensure_control_visible(node)
				parent = parent.get_parent()
			await observe(.4)
			# Activate the visible button's real callback deterministically. Native
			# pointer/tooltips can otherwise swallow a synthetic mouse release.
			node.grab_focus()
			node.pressed.emit()
			await observe(1.5)
			return true
	fail_session("No enabled visible inventory button: " + text_prefix)
	return false

func chapter(title: String) -> void:
	await super.chapter(title)
	if OS.get_cmdline_user_args().has("--recording") and DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(demo_output + "/chapter-%02d.png" % demo_events.size())

func play_session() -> void:
	await chapter("雪线以北 · 当前版本实机体验")
	await observe(2)
	await click_control(new_button)
	for i in range(3):
		await observe(5)
		await click_control(opening.sheet.get_node("OpeningContinue"))
	await observe(1)
	player.zoom = 16.0
	await chapter("七号小屋 · 雪地行走与足迹")
	for at in [Vector2(0,27),Vector2(5.3,25)]:
		if not await walk_to(at):return
	if not await use_target("home_supplies"):return
	for at in [Vector2(0,27),Vector2(0,20.5),Vector2(-2.4,18.2)]:
		if not await walk_to(at):return
	if not await use_target("radio"):return
	await chapter("失联 · 值守簿里的线索")
	await observe(5)
	await click_control(story_panel.find_child("Story_leave",true,false))
	await observe(1)
	for at in [Vector2(0,20),Vector2(0,17),Vector2(0,14.8),Vector2(1.1,14.8)]:
		if not await walk_to(at):return
	if not await use_target("field_medical"):return
	backpack.tab="items";toggle_backpack();await observe(1)
	if not await press_button_with("\n\n饮用水"):return
	if not await press_button_with("使用一份"):return
	if not await press_button_with("\n\n口粮"):return
	if not await press_button_with("使用一份"):return
	if not await press_button_with("人物"):return
	await chapter("行囊 · 新角色与衣着身体状态")
	await observe(6)
	await close_inventory()
	for at in [Vector2(0,14.8),Vector2(0,20),Vector2(0,27),Vector2(-6,27),Vector2(-6,8),Vector2(-7,-1.5)]:
		if not await walk_to(at):return
	if not await use_target("timber_south"):return
	await chapter("林间探索 · 奔跑、呼吸与积雪")
	if not await walk_to(Vector2(-10,-18),true):return
	if not await walk_to(Vector2(-10,-29)):return
	map.visible=true;await observe(5);map.visible=false
	if not await walk_to(Vector2(-12,-39.5)):return
	if not await use_target("wreck_player"):return
	await chapter("邮递车 · 偶然找到的磁带机")
	backpack.tab="items";toggle_backpack();await observe(1)
	if not await press_button_with("\n\n磁带 · 余烬"):return
	if not await press_button_with("装入磁带机"):return
	if not await press_button_with("奇异磁带机"):return
	await observe(6)
	await close_inventory()
	await chapter("余烬 · 带着音乐踏上归途")
	for at in [Vector2(-10,-29),Vector2(-10,-18),Vector2(-2,-18),Vector2(-2,8),Vector2(-6,8),Vector2(-6,27),Vector2(0,27),Vector2(0,20.7)]:
		if not await walk_to(at):return
	backpack.tab="craft";toggle_backpack();await observe(1)
	if not await press_button_with("修复保暖床铺"):return
	await close_inventory()
	if not await walk_to(Vector2(1.3,17.8)):return
	if not await use_target("home"):return
	await chapter("庇护所 · 木屋与炉火")
	await observe(6)
	backpack.tab="items";toggle_backpack();await observe(1)
	if not await press_button_with("\n\n口粮"):return
	if not await press_button_with("使用一份"):return
	if not await press_button_with("制作与庇护所"):return
	if not await press_button_with("融雪煮水"):return
	if not await press_button_with("随身物品"):return
	if not await press_button_with("\n\n饮用水"):return
	if not await press_button_with("使用一份"):return
	if not await press_button_with("制作与庇护所"):return
	if not await press_button_with("4 小时"):return
	await chapter("休整 · 预估消耗后睡到傍晚")
	if not await press_button_with("休息 4 小时"):return
	await close_inventory()
	if not await use_target("home"):return
	backpack.tab="craft";toggle_backpack();await observe(1)
	if not await press_button_with("2 小时"):return
	if not await press_button_with("休息 2 小时"):return
	await close_inventory()
	if not await use_target("home"):return
	for at in [Vector2(0,20.7),Vector2(0,27),Vector2(2,29)]:
		if not await walk_to(at):return
	await chapter("暮色雪原 · 小屋的暖光")
	await observe(7)
	# Keep this artistic comparison visibly separate from the continuous play.
	active=false;player.enabled=false;release_movement();player.velocity=Vector3.ZERO
	canvas.visible=false
	var title_layer:=CanvasLayer.new();title_layer.layer=30;add_child(title_layer)
	study_caption=label("",20,Color("e5e4d9"));study_caption.position=Vector2(36,660)
	study_caption.add_theme_color_override("font_shadow_color",Color(.03,.04,.06,.95))
	study_caption.add_theme_constant_override("shadow_offset_x",2)
	study_caption.add_theme_constant_override("shadow_offset_y",2)
	title_layer.add_child(study_caption)
	player.camera.size=24.0
	await chapter("昼夜延时 · 正午、夕照、夜色与晨光")
	light_study=true
	await observe(50)
	light_study=false
	demo_finished=true;write_report("complete")
	var file:=FileAccess.open(demo_output+"/recording-notes.txt",FileAccess.WRITE)
	file.store_string("Gameplay: real movement, collisions, inventory and normal rest, isolated settings/save.\nFinal 50 seconds: labelled solar-lighting study, noon to next dawn; survival paused, display-only clock and mild snow. Native game audio; no microphone.\n")
	file.close()
	print("EXPERIENCE_DEMO_COMPLETE seconds=",demo_seconds)
	set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await observe(.2);get_tree().quit()
