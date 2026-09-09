extends "res://scripts/main.gd"

func _ready()->void:
	super._ready();call_deferred("check_chapter")

func settle(frames:int=8)->void:
	for i in range(frames):await get_tree().process_frame

func check_chapter()->void:
	save_path="res://artifacts/chapter/check-save.json"
	# A transmission can be saved at each sentence, including before its final acknowledgment.
	for detail in ["unknown","camp","register"]:
		var state=Survival.new();assert(not state.repair())
		state.parts=true;assert(state.repair() and not state.completed)
		if detail=="camp":Chapter.discover(state,"hunter_note")
		if detail=="register":Chapter.discover(state,"ridge_register")
		assert(not Chapter.advance_radio(state,"confirm"),"Cannot skip to ending")
		for choice in ["call","ask","confirm"]:
			var restored=Survival.new()
			assert(restored.restore(JSON.parse_string(JSON.stringify(state.data()))))
			state=restored;assert(Chapter.advance_radio(state,choice))
		assert(state.completed and state.chapter.report_detail==detail)
		assert(not Chapter.advance_radio(state,"confirm") and not state.repair(),"Completion cannot duplicate")
		var old_response:String=Chapter.radio_response(state)
		Chapter.discover(state,"ridge_register")
		assert(old_response==Chapter.radio_response(state),"Later exploration cannot rewrite the past conversation")
	var legacy=Survival.new();legacy.parts=true;legacy.completed=true
	var raw:Dictionary=legacy.data();raw.erase("chapter")
	var migrated=Survival.new();assert(migrated.restore(raw) and migrated.completed and migrated.chapter.radio_step==4)
	for invalid in ["wrong",{"radio_step":4},[]]:
		raw=migrated.data();raw.chapter=invalid
		var candidate=Survival.new();var before:Dictionary=candidate.data()
		assert(not candidate.restore(raw) and candidate.data()==before,"Invalid chapter is rejected atomically")
	raw=migrated.data();raw.items="bad";assert(not Survival.new().restore(raw))
	raw=migrated.data();raw.chapter.radio_step=1.5;assert(not Survival.new().restore(raw))
	raw=migrated.data();raw.completed=false;assert(not Survival.new().restore(raw))
	start_new();await settle()
	player.position=Vector3(-2.4,.2,18.2);player.velocity=Vector3.ZERO;await settle();update_target()
	assert(target.get("id")=="radio");interact();await settle(65)
	assert(story_panel.visible and survival.chapter.intro_seen and survival.discovered.has("home_log"))
	var paused:float=survival.elapsed;await settle(30);assert(survival.elapsed==paused and not player.enabled)
	close_story();set_menu(true);save_game();survival.chapter.intro_seen=false;load_game()
	assert(survival.chapter.intro_seen)
	# Reach the new optional evidence using actual targeting, not a direct grant.
	player.position=Vector3(-31.0,world.terrain_height(-31,-33.3)+.2,-33.3);player.velocity=Vector3.ZERO;await settle();update_target()
	assert(target.get("id")=="ridge_register","The register has its own reachable face beside the cache")
	interact();await settle(60);assert(survival.discovered.has("ridge_register") and backpack.visible)
	backpack.visible=false;active=true;player.enabled=true
	survival.kit.module_ready=true
	player.position=Vector3(-2.4,.2,-169.8);player.velocity=Vector3.ZERO;await settle();update_target();interact();await settle(60)
	assert(story_panel.visible and survival.parts and survival.chapter.station_seen)
	assert(story_panel.get_global_rect().end.y<=720,"Station narrative and three route choices fit the screen")
	assert(story_panel.body_label.size.x<=700,"Long Chinese text wraps in the reading column")
	story_panel.select_route("ridge");assert(active and survival.chapter.return_plan=="ridge")
	set_menu(true);save_game();survival.chapter.return_plan="direct";load_game();assert(survival.chapter.return_plan=="ridge")
	player.position=Vector3(-2.4,.2,18.2);player.velocity=Vector3.ZERO;await settle();update_target();interact();await settle(65)
	assert(story_panel.visible and not survival.completed and survival.chapter.radio_step==1)
	story_panel.find_child("Story_call",true,false).pressed.emit()
	assert(survival.chapter.radio_step==2)
	close_story();set_menu(true);save_game();survival=Survival.new();load_game();await settle();update_target();interact();await settle(65)
	assert(story_panel.visible and survival.chapter.radio_step==2,"Radio resumes after closing, disk save and load")
	story_panel.find_child("Story_report",true,false).pressed.emit();await settle()
	assert(story_panel.body_label.text.contains("林和守桥人") and not survival.completed)
	story_panel.find_child("Story_confirm",true,false).pressed.emit();await settle()
	assert(survival.completed and survival.chapter.radio_step==4)
	story_panel.find_child("Story_finish",true,false).pressed.emit();await settle()
	assert(active and not story_panel.visible)
	backpack.tab="journal";toggle_backpack();await settle()
	assert(backpack.get_global_rect().end.y<=720,"Ending transcript fits the scrollable journal")
	backpack.visible=false;survival.health=0;set_menu(true)
	assert(menu_title.text=="你倒在了风雪里","Death remains visible during post-chapter survival")
	active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await settle();OS.delay_msec(100)
	print("CHAPTER_OK: intro, physical optional clue, station reveal, route choice, pause/resume, disk saves during radio, three evidence endings, invalid/legacy saves, repeat guards, UI layout")
	get_tree().quit()
