extends "res://scripts/main.gd"

# An isolated, repeatable play session: real input, physics, target detection,
# inventory buttons and survival rules. No teleports, free items or clock edits.
var demo_output:="res://artifacts/playtest-demo"
var demo_seconds := 0.0
var demo_frames:=0
var demo_events: Array[Dictionary] = []
var demo_finished := false

func _ready() -> void:
	super._ready()
	if OS.get_cmdline_user_args().has("--recording") and DisplayServer.get_name()!="headless":
		RenderingServer.render_loop_enabled=false
	save_path = demo_output+"/session-save.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(demo_output))
	call_deferred("play_session")

func _process(delta: float) -> void:
	# These sessions run at fixed 30 FPS; frame-derived chapters stay correct
	# even if a blocking GPU readback reports an inflated process delta.
	demo_frames+=1
	demo_seconds=float(demo_frames)/30.0
	super._process(delta)
	if OS.get_cmdline_user_args().has("--recording") and DisplayServer.get_name()!="headless":
		call_deferred("draw_movie_frame")

func draw_movie_frame()->void:
	# A covered macOS window may stop the normal presentation loop while
	# MovieWriter keeps copying the last image. Render each simulation frame.
	RenderingServer.viewport_set_update_mode(get_viewport().get_viewport_rid(),RenderingServer.VIEWPORT_UPDATE_ALWAYS)
	RenderingServer.force_draw(false,1.0/30.0)

func observe(seconds: float) -> void:
	for i in range(ceili(seconds * 30.0)):
		await get_tree().process_frame

func chapter(title: String) -> void:
	var record := {"title":title,"video_seconds":snappedf(demo_seconds,.01),"game_time":DayCycle.clock_text(survival.elapsed),"position":[player.position.x,player.position.y,player.position.z],"health":survival.health,"temperature":survival.temperature,"inventory":survival.items.duplicate()}
	demo_events.append(record)
	print("DEMO_CHAPTER ", JSON.stringify(record))
	write_report("running")
	if DisplayServer.get_name() != "headless" and not OS.get_cmdline_user_args().has("--recording"):
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(demo_output+"/chapter-%02d.png" % demo_events.size())

func write_report(status: String) -> void:
	var file := FileAccess.open(demo_output+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"status":status,"duration_seconds":demo_seconds,"events":demo_events,"rules":"unmodified survival, real movement/collision and UI actions; no time skips except normal rest","discovered":survival.discovered,"final_state":survival.data()},"\t"))

func release_movement() -> void:
	for action in ["move_left","move_right","move_up","move_down","sprint"]:Input.action_release(action)

func fail_session(reason: String) -> void:
	if demo_finished:return
	demo_finished=true;release_movement();set_menu(true)
	push_error("DEMO_FAILED: "+reason)
	write_report("failed: "+reason)
	active=false;player.enabled=false;set_process(false)
	cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await observe(.2)
	OS.delay_msec(100)
	get_tree().quit(1)

func walk_to(at: Vector2, run := false) -> bool:
	var previous := player.position
	var stalled := 0.0
	var travel := 0.0
	while Vector2(player.position.x,player.position.z).distance_to(at) > .35:
		if survival.health<=0:fail_session("Death on route to "+str(at));return false
		var direction := Vector3(at.x-player.position.x,0,at.y-player.position.z).normalized()
		var stick := Basis(Vector3.UP,player.pivot.rotation.y).inverse()*direction
		for pair in [["move_left",maxf(-stick.x,0)],["move_right",maxf(stick.x,0)],["move_up",maxf(-stick.z,0)],["move_down",maxf(stick.z,0)]]:
			if pair[1]>.001:Input.action_press(pair[0],pair[1])
			else:Input.action_release(pair[0])
		if run:Input.action_press("sprint")
		else:Input.action_release("sprint")
		await get_tree().process_frame
		travel+=1.0/30.0
		if player.position.distance_to(previous)<.003:stalled+=1.0/30.0
		else:stalled=0
		previous=player.position
		if stalled>3.0 or travel>90:
			fail_session("Route blocked at "+str(player.position)+" toward "+str(at));return false
	release_movement()
	await observe(.3)
	return true

func use_target(id: String) -> bool:
	update_target()
	if target.get("id","")!=id:
		fail_session("Expected reachable target "+id+" but found "+str(target.get("id","none")));return false
	interact()
	await observe(2.2)
	return true

func press_button_with(text_prefix: String) -> bool:
	for node in backpack.find_children("*","Button",true,false):
		if node.text.begins_with(text_prefix) and node.is_visible_in_tree() and not node.disabled:
			await click_control(node)
			await observe(1.5)
			return true
	fail_session("No enabled visible inventory button: "+text_prefix)
	return false

func close_inventory() -> void:
	if backpack.visible:toggle_backpack()
	await observe(.5)

func play_session() -> void:
	await chapter("开始菜单")
	await observe(2.5)
	new_button.pressed.emit()
	await observe(3)
	await chapter("护林小屋 · 新旅程")
	if not await walk_to(Vector2(0,27)):return
	await chapter("走出门廊 · 薄雪脚印")
	await observe(3)
	if not await walk_to(Vector2(5.3,25)):return
	if not await use_target("home_supplies"):return
	await chapter("搜寻工具箱 · 获得修缮材料")
	if not await walk_to(Vector2(0,27)):return
	if not await walk_to(Vector2(-6,27)):return
	if not await walk_to(Vector2(-6,8)):return
	if not await walk_to(Vector2(-7,-1.5)):return
	if not await use_target("timber_south"):return
	map.visible=true
	await chapter("查看路线地图")
	await observe(4)
	map.visible=false
	if not await walk_to(Vector2(-10,-18),true):return
	if not await walk_to(Vector2(-10,-29)):return
	await chapter("雪坡 · 行走脚印与奔跑消耗")
	await observe(4)
	if not await walk_to(Vector2(-12,-39.5)):return
	if not await use_target("wreck_player"):return
	await chapter("发现邮递车 · 找到磁带机")
	backpack.tab="items";toggle_backpack()
	await observe(1)
	if not await press_button_with("\n\n磁带 · 余烬"):return
	if not await press_button_with("装入磁带机"):return
	if not await press_button_with("奇异磁带机"):return
	await chapter("行囊 · 装带与播放")
	await observe(5)
	await close_inventory()
	# Return along the known clear route, with the warmth tape now consuming charge.
	if not await walk_to(Vector2(-10,-29)):return
	if not await walk_to(Vector2(-10,-18)):return
	if not await walk_to(Vector2(-2,-18)):return
	if not await walk_to(Vector2(-2,8)):return
	if not await walk_to(Vector2(-6,8)):return
	if not await walk_to(Vector2(-6,27)):return
	if not await walk_to(Vector2(0,27)):return
	if not await walk_to(Vector2(0,20.7)):return
	await chapter("返回小屋 · 避风与修缮")
	backpack.tab="craft";toggle_backpack();await observe(1)
	if not await press_button_with("修复保暖床铺"):return
	if not await press_button_with("封窗保温"):return
	await chapter("制作 · 修床与封窗")
	await observe(3)
	await close_inventory()
	if not await walk_to(Vector2(1.3,17.8)):return
	if not await use_target("home"):return
	await chapter("炉火 · 回暖")
	await observe(4)
	backpack.tab="items";toggle_backpack();await observe(1)
	if not await press_button_with("\n\n饮用水"):return
	if not await press_button_with("使用一份"):return
	if not await press_button_with("\n\n口粮"):return
	if not await press_button_with("使用一份"):return
	if not await press_button_with("制作与庇护所"):return
	for i in range(4):
		if not await press_button_with("休息 2 小时"):return
		await observe(1.5)
	await close_inventory()
	await chapter("夜晚 · 休息推进时间与消耗")
	if not await use_target("home"):return
	await observe(4)
	if not await walk_to(Vector2(0,20.7)):return
	if not await walk_to(Vector2(0,27)):return
	if not await walk_to(Vector2(2,29)):return
	await chapter("夜间雪地 · 严寒提示与脚印")
	await observe(5)
	if not await walk_to(Vector2(0,27)):return
	if not await walk_to(Vector2(0,20.7)):return
	await chapter("结束 · 回到暖炉旁")
	await observe(5)
	set_menu(true)
	await observe(2)
	demo_finished=true;write_report("complete")
	print("DEMO_COMPLETE seconds=",demo_seconds)
	active=false;player.enabled=false;set_process(false)
	cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await observe(.2)
	OS.delay_msec(100)
	get_tree().quit()
