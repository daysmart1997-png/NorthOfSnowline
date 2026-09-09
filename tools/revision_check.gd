extends "res://scripts/main.gd"

func _ready()->void:
	super._ready();call_deferred("check_revision")

func frames(count:int=8)->void:
	for i in range(count):await get_tree().physics_frame

func check_revision()->void:
	# All six rescue replies remain independent of the new optional mystery.
	for reply in ["ask","report"]:
		for evidence in ["unknown","camp","register"]:
			var s=Survival.new();s.parts=true;s.repair()
			if evidence=="camp":Chapter.discover(s,"hunter_note")
			if evidence=="register":Chapter.discover(s,"ridge_register")
			for choice in ["call",reply,"confirm"]:assert(Chapter.advance_radio(s,choice))
			assert(s.completed and s.chapter.report_detail==evidence)
			var recorded:String=Chapter.radio_response(s)
			assert(recorded.contains("周岑") and recorded.contains("两夜"))
			for step in range(3):
				var restored=Survival.new();assert(restored.restore(JSON.parse_string(JSON.stringify(s.data()))));s=restored
				assert(s.chapter.epilogue_step==step)
				assert(not Chapter.advance_epilogue(s,"wrong"))
				assert(Chapter.advance_epilogue(s,["listen","check_card","record"][step]))
			assert(not Chapter.advance_epilogue(s,"record"))
			assert(s.discovered.count("old_channel_fragment")==1 and s.discovered.count("old_channel_card")==1)
			assert(Chapter.radio_response(s)==recorded and s.completed)
			assert(Chapter.objective(s).contains("尚未开放"))
			var raw:Dictionary=s.data();raw.chapter.erase("epilogue_step");raw.schema=3
			var old=Survival.new();assert(old.restore(raw) and old.completed and old.chapter.epilogue_step==0)
			for invalid in [-1,4,1.5,"1",true]:
				raw=s.data();raw.chapter.epilogue_step=invalid
				var untouched=Survival.new();var before:Dictionary=untouched.data()
				assert(not untouched.restore(raw) and untouched.data()==before)
	start_new();await frames()
	opening.begin();var elapsed:float=survival.elapsed;await frames(40)
	assert(not active and survival.elapsed==elapsed and opening.camera.current)
	opening.advance();opening.advance();opening.advance();await frames()
	assert(active and not opening.sheet.visible and player.camera.current)
	# Check the station radio desk from every side using the actual character hull.
	active=false;player.enabled=false
	var center:=Vector3(-2.43,.25,-171)
	for axis in [Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD,Vector3.BACK]:
		var pose:=player.global_transform;pose.origin=center+axis*1.35
		assert(player.test_move(pose,-axis*1.30),"Station desk blocks a character hull from all four directions")
	# Then walk against it using the normal input / floor / animation path.
	player.position=Vector3(-2.43,.26,-169.7);player.velocity=Vector3.ZERO;player.pivot.rotation.y=0
	player.enabled=true;active=true;Input.action_press("move_up");await frames(85);Input.action_release("move_up")
	assert(player.position.z> -170.5 and player.position.z< -169.8,"Player stops at the station desk, never inside it")
	update_target();assert(target.get("id")=="radio_parts","Desk collision still permits retrieving the module")
	active=false;player.enabled=false
	var loot:Dictionary=world.points.filter(func(p):return p.id=="lake_cache")[0]
	var collider:CollisionShape3D=loot.node.find_child("SupplyCollision",true,false).get_child(0)
	assert(not collider.disabled)
	world.refresh_pickups(["lake_cache"]);await frames(2);assert(collider.disabled and not loot.node.visible)
	world.refresh_pickups([]);await frames(2);assert(not collider.disabled and loot.node.visible)
	assert(world.find_children("TrunkCollision","StaticBody3D",true,false).size()>20)
	assert(world.has_node("PostalVan") and world.has_node("StationLineEquipment"))
	# Resume/close/reopen the new epilogue using the actual panel buttons.
	survival.parts=true;survival.repair()
	for choice in ["call","report","confirm"]:Chapter.advance_radio(survival,choice)
	open_story("epilogue");story_panel.find_child("Story_later",true,false).pressed.emit();assert(active)
	open_story("epilogue");story_panel.find_child("Story_listen",true,false).pressed.emit()
	assert(story_panel.body_label.text.contains("不要去北边"))
	close_story();open_story("epilogue");assert(survival.chapter.epilogue_step==1)
	story_panel.find_child("Story_check_card",true,false).pressed.emit();story_panel.find_child("Story_record",true,false).pressed.emit()
	await frames();assert(story_panel.get_global_rect().end.y<=720)
	active=false;player.enabled=false;set_process(false);opening.set_process(false)
	cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();await frames(3);OS.delay_msec(100)
	print("REVISION_OK: six report branches, epilogue roundtrips and legacy saves, no duplicate clues, opening freeze/skip, four desk approaches and live walking, accessible module, loot collision lifecycle")
	get_tree().quit()
