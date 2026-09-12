extends "res://tools/playtest_demo.gd"

func _ready()->void:
	demo_output="res://artifacts/exploration/station-cold-control" if OS.get_cmdline_user_args().has("--skip-warmth") else "res://artifacts/exploration/station-demo"
	if OS.get_cmdline_user_args().has("--chapter-rehearsal"):
		demo_output="res://artifacts/chapter/route-"+("ridge" if OS.get_cmdline_user_args().has("--ridge-detour") else "direct")
	if OS.get_cmdline_user_args().has("--flow-content"):
		demo_output="res://artifacts/chapter-flow/route-"+("sheltered" if OS.get_cmdline_user_args().has("--sheltered-return") else "direct")
	if OS.get_cmdline_user_args().has("--arrival-route"):demo_output="res://artifacts/arrival/route-"+("sheltered" if OS.get_cmdline_user_args().has("--sheltered-return") else "direct")
	if OS.get_cmdline_user_args().has("--mountain-route"):demo_output="res://artifacts/mountain-pass/route-"+("sheltered" if OS.get_cmdline_user_args().has("--sheltered-return") else "direct")
	if OS.get_cmdline_user_args().has("--first-night-route"):demo_output="res://artifacts/settlement-polish/route-"+("sheltered" if OS.get_cmdline_user_args().has("--sheltered-return") else "direct")
	if OS.get_cmdline_user_args().has("--guidance-route"):demo_output="res://artifacts/return-guidance/route-"+("sheltered" if OS.get_cmdline_user_args().has("--sheltered-return") else "direct")
	super._ready()

func play_session()->void:
	await chapter("风雪将至")
	await observe(2)
	new_button.pressed.emit();await observe(2);opening.finish();await observe(1)
	if OS.get_cmdline_user_args().has("--arrival-route"):
		if not await arrival_route():return
	if not await walk_to(Vector2(0,27)):return
	if not await walk_to(Vector2(0,20.5)):return
	if not await walk_to(Vector2(-2.4,18.2)):return
	if not await use_target("radio"):return
	await chapter("值守簿 · 没能发出的平安报")
	if not await story_click("leave"):return
	if OS.get_cmdline_user_args().has("--flow-content"):
		if not await walk_to(Vector2(-3.2,18.2)):return
		if not await use_target("departure_trace"):return
		await chapter("空挂钩 · 出巡前的字条")
		if not await story_click("leave"):return
	for at in [Vector2(0,20),Vector2(0,17),Vector2(0,14.8),Vector2(1.1,14.8)]:
		if not await walk_to(at):return
	if not await use_target("field_medical"):return
	backpack.tab="items";toggle_backpack();await observe(1)
	if not await press_button_with("\n\n饮用水"):return
	if not await press_button_with("使用一份"):return
	await close_inventory()
	for at in [Vector2(0,14.8),Vector2(0,20),Vector2(0,27),Vector2(5.3,25)]:
		if not await walk_to(at):return
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
	if OS.get_cmdline_user_args().has("--flow-content"):
		for at in [Vector2(0,-168),Vector2(-.35,-172.15)]:
			if not await walk_to(at):return
		if not await use_target("station_cabinet"):return
		await chapter("零件柜 · 留给后来人的一份柴")
		for at in [Vector2(0,-168),Vector2(-2.4,-169.8)]:
			if not await walk_to(at):return
	for i in range(3):
		if not await use_target("radio_parts"):return
		await observe(3)
	if not await use_target("radio_parts"):return
	await chapter("维修交接 · 留给后来的人")
	if not await story_click("sheltered" if OS.get_cmdline_user_args().has("--sheltered-return") else ("ridge" if OS.get_cmdline_user_args().has("--ridge-detour") else "direct")):return
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
	var return_path:=[Vector2(-.2,-170),Vector2(-.2,-168),Vector2(0,-160)]
	return_path.append_array([Vector2(6,-153),Vector2(22,-138),Vector2(22,-102),Vector2(0,-100)] if OS.get_cmdline_user_args().has("--sheltered-return") else [Vector2(0,-140),Vector2(0,-100)])
	for at in return_path:
		if not await walk_to(at):return
	await chapter("沿林道返程 · 绕行树后，观察风压" if OS.get_cmdline_user_args().has("--sheltered-return") else "沿铁路返程 · 迎风更冷，路线更直接")
	if not await walk_to(Vector2(0,-74)):return
	if OS.get_cmdline_user_args().has("--sheltered-return"):
		for at in [Vector2(18,-72),Vector2(22,-40),Vector2(22,-24),Vector2(12,-24),Vector2(0,-14)]:
			if not await walk_to(at):return
	else:
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
	if OS.get_cmdline_user_args().has("--guidance-route"):
		assert(exploration.return_guidance.shown.has(0) and exploration.return_guidance.shown.has(1),"Both return junctions offer directions during normal travel")
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

func walk_to(at:Vector2,run:=false)->bool:
	var reached:bool=await super.walk_to(at,run)
	if reached and survival.kit.has_condition("wound") and survival.count("bandage")>0:
		backpack.tab="items";toggle_backpack();await observe(1)
		if not await press_button_with("\n\n绷带"):return false
		if not await press_button_with("使用一份"):return false
		await close_inventory()
	return reached

func arrival_route()->bool:
	for at in [Vector2(0,121),Vector2(12,118),Vector2(12,113),Vector2(12.4,108.2)]:
		if not await walk_to(at):return false
	if not await use_target("gate_desk"):return false
	for item in ["food","water","cloth"]:
		var button:Button=backpack.find_child("Inspect_"+item,true,false)
		button.pressed.emit();await observe(.3)
		backpack.find_child("TakeSupply",true,false).pressed.emit();await observe(.4)
	await chapter("岗亭翻找 · 只带走需要的食水")
	if OS.get_cmdline_user_args().has("--mountain-route"):
		backpack.tab="items";backpack.selected="food";backpack.refresh();await observe(.3)
		if not await press_button_with("使用一份"):return false
	backpack.tab="items";backpack.selected="water";backpack.refresh();await observe(.3)
	if not await press_button_with("使用一份"):return false
	await close_inventory()
	if not await walk_to(Vector2(11.5,108.2)):return false
	if not await use_target("gate_route"):return false
	await close_inventory()
	for at in [Vector2(12,110),Vector2(12,116),Vector2(0,103),Vector2(-11,84),Vector2(-11,78),Vector2(-11,74.8),Vector2(-9.5,75.35)]:
		if not await walk_to(at):return false
	if not await use_target("lodge_stores"):return false
	for item in ["wood","wood","wood","bandage","battery"]:
		backpack.find_child("Inspect_"+item,true,false).pressed.emit();await observe(.2)
		backpack.find_child("TakeSupply",true,false).pressed.emit();await observe(.3)
	await close_inventory()
	for at in [Vector2(-11,75.2),Vector2(-11,72),Vector2(-9.6,71.8)]:
		if not await walk_to(at):return false
	if not await use_target("lodge"):return false
	if OS.get_cmdline_user_args().has("--first-night-route"):
		if not await settlement_night():return false
	else:
		backpack.tab="craft";backpack.rest_hours=1;toggle_backpack();await observe(.5)
		if not await press_button_with("休息 1 小时"):return false
		await chapter("临时木屋 · 添柴、估算并正常休息")
		await close_inventory()
	if not await walk_to(Vector2(-10.9,71.0)):return false
	if not await use_target("lodge_route"):return false
	await close_inventory()
	for at in [Vector2(-11,74.8),Vector2(-11,79),Vector2(-3,79),Vector2(-3,69),Vector2(0,61),Vector2(0,43)]:
		if not await walk_to(at):return false
	await chapter("找到长期据点前 · 沿路线纸寻找护林小屋")
	return true

func settlement_night()->bool:
	for at in [Vector2(-11,74.8),Vector2(-11,83),Vector2(-2,85),Vector2(10,85),Vector2(10,80),Vector2(10,78),Vector2(10,76.8)]:
		if not await walk_to(at):return false
	if not await use_target("canteen_pantry"):return false
	var light_pack:=OS.get_cmdline_user_args().has("--light-pack")
	for item in (["food","water"] if light_pack else ["food","food","water"]):
		backpack.find_child("Inspect_"+item,true,false).pressed.emit();await observe(.2)
		backpack.find_child("TakeSupply",true,false).pressed.emit();await observe(.3)
	await close_inventory();await chapter("夜间搜寻 · 伙房的有限口粮")
	for at in [Vector2(10,79),Vector2(10,85),Vector2(-2,85),Vector2(-11,83),Vector2(-16,88),Vector2(-23,92),Vector2(-23,89),Vector2(-23,86.5)]:
		if not await walk_to(at):return false
	if not await use_target("shed_fuel"):return false
	for i in range(3 if light_pack else 4):
		backpack.find_child("Inspect_wood",true,false).pressed.emit();await observe(.2)
		backpack.find_child("TakeSupply",true,false).pressed.emit();await observe(.3)
	await close_inventory()
	for at in [Vector2(-23,90),Vector2(-23,92),Vector2(-16,88),Vector2(-11,83),Vector2(-11,79),Vector2(-11,75),Vector2(-12.6,75.5)]:
		if not await walk_to(at):return false
	if not await use_target("wreck_player"):return false
	await chapter("回到炉屋 · 留出后半夜的食物与燃料")
	# Inspecting and eating stay in the preparation page; only normal rest skips time.
	while DayCycle.day(survival.solar_time())<2 or DayCycle.hour(survival.solar_time())<7:
		for at in [Vector2(-11,75.2),Vector2(-11,72),Vector2(-9.6,71.8)]:
			if not await walk_to(at):return false
		if survival.fires.lodge<125:
			if not await use_target("lodge"):return false
		backpack.tab="craft";backpack.rest_hours=2;toggle_backpack();await observe(.5)
		if survival.hunger<48 and survival.count("food")>0:
			if not await press_button_with("吃口粮"):return false
		if survival.thirst<40 and survival.count("water")>0:
			if not await press_button_with("喝水"):return false
		var before:float=survival.elapsed
		if not await press_button_with("休息 2 小时"):return false
		if survival.elapsed<=before or survival.health<=0:fail_session("Overnight rest could not advance safely");return false
		await close_inventory()
	await chapter("第一晚之后 · 天亮再向北")
	return true
