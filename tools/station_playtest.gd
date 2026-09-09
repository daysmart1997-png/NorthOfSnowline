extends "res://tools/playtest_demo.gd"

func _ready()->void:
	demo_output="res://artifacts/exploration/station-cold-control" if OS.get_cmdline_user_args().has("--skip-warmth") else "res://artifacts/exploration/station-demo"
	if OS.get_cmdline_user_args().has("--chapter-rehearsal"):
		demo_output="res://artifacts/chapter/route-"+("ridge" if OS.get_cmdline_user_args().has("--ridge-detour") else "direct")
	super._ready()

func play_session()->void:
	await chapter("风雪将至")
	await observe(2)
	new_button.pressed.emit();await observe(2)
	if not await walk_to(Vector2(-2.4,18.2)):return
	if not await use_target("radio"):return
	await chapter("值守簿 · 没能发出的平安报")
	if not await story_click("leave"):return
	if not await walk_to(Vector2(0,27)):return
	if not await walk_to(Vector2(5.3,25)):return
	if not await use_target("home_supplies"):return
	await chapter("准备出发 · 门外薄雪与修缮物资")
	for at in [Vector2(0,27),Vector2(-6,27),Vector2(-6,8),Vector2(0,8),Vector2(0,-14),Vector2(4,-15)]:
		if not await walk_to(at):return
	if not await use_target("fork_note"):return
	await chapter("巡林路标 · 选择较远的避风路线")
	await observe(4);await close_inventory()
	for at in [Vector2(12,-24),Vector2(22,-24),Vector2(22,-40),Vector2(20,-56.7)]:
		if not await walk_to(at):return
	if not await use_target("hunter_note"):return
	await chapter("旧营地 · 柴火与返程的线索")
	await observe(4);await close_inventory()
	for at in [Vector2(18,-55),Vector2(18,-72),Vector2(0,-74)]:
		if not await walk_to(at):return
	await chapter("旧桥 · 跨过冻河")
	if not await walk_to(Vector2(0,-100)):return
	for at in [Vector2(22,-102),Vector2(22,-138),Vector2(6,-153),Vector2(6,-156.5)]:
		if not await walk_to(at):return
	if not await use_target("station_rations"):return
	await chapter("北侧应急箱 · 为返程补水")
	for at in [Vector2(0,-160),Vector2(0,-167),Vector2(-2.4,-169.8)]:
		if not await walk_to(at):return
	if not await use_target("radio_parts"):return
	await chapter("维修交接 · 留给后来的人")
	if not await story_click("ridge" if OS.get_cmdline_user_args().has("--ridge-detour") else "direct"):return
	for at in [Vector2(0,-168),Vector2(1.3,-170.2)]:
		if not await walk_to(at):return
	if not OS.get_cmdline_user_args().has("--skip-warmth"):
		if not await use_target("station"):return
	else:await observe(2.2)
	await observe(8)
	backpack.tab="items";toggle_backpack();await observe(1)
	if not await press_button_with("\n\n饮用水"):return
	if not await press_button_with("使用一份"):return
	if not await press_button_with("\n\n口粮"):return
	if not await press_button_with("使用一份"):return
	if not await press_button_with("制作与庇护所"):return
	if not await press_button_with("1 小时"):return
	await chapter("炉火旁 · 预估消耗后休息一小时")
	if not await press_button_with("休息 1 小时"):return
	await observe(3);await close_inventory()
	for at in [Vector2(0,-168),Vector2(0,-160),Vector2(0,-140),Vector2(0,-100)]:
		if not await walk_to(at):return
	await chapter("沿铁路返程 · 迎风更冷，路线更直接")
	if not await walk_to(Vector2(0,-74)):return
	if not await walk_to(Vector2(0,-40)):return
	if OS.get_cmdline_user_args().has("--ridge-detour"):
		for at in [Vector2(-10,-29),Vector2(-18,-28),Vector2(-26,-30),Vector2(-31,-33.3)]:
			if not await walk_to(at):return
		if not await use_target("ridge_register"):return
		await chapter("西岭收信簿 · 两个名字的下落")
		await observe(4);await close_inventory()
		for at in [Vector2(-26,-30),Vector2(-18,-28),Vector2(-10,-29),Vector2(0,-30)]:
			if not await walk_to(at):return
	for at in [Vector2(0,-14),Vector2(0,8),Vector2(-6,8),Vector2(-6,27),Vector2(0,27),Vector2(0,20.5),Vector2(-2.4,18.2)]:
		if not await walk_to(at):return
	if not await use_target("radio"):return
	assert(not survival.completed and story_panel.visible)
	for reply in ["call","report","confirm"]:
		if not await story_click(reply):return
	assert(survival.completed,"A physical station roundtrip must finish the radio objective")
	await chapter("信号已发出 · 完成第一次往返")
	await observe(5)
	demo_finished=true;write_report("complete")
	print("STATION_COMPLETE seconds=",demo_seconds," health=",survival.health," temperature=",survival.temperature)
	active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await observe(.2);OS.delay_msec(100);get_tree().quit()

func story_click(id:String)->bool:
	var control=story_panel.find_child("Story_"+id,true,false)
	if not is_instance_valid(control) or not control.is_visible_in_tree():
		fail_session("Missing story choice: "+id);return false
	await click_control(control);await observe(1.5)
	return true
