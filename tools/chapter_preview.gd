extends "res://scripts/main.gd"

func _ready()->void:
	super._ready();call_deferred("preview_chapter")

func preview_chapter()->void:
	start_new()
	var mode:="intro"
	for option in ["station","radio","ending","journal","ridge","ledger","module"]:
		if OS.get_cmdline_user_args().has("--"+option):mode=option
	if mode=="intro":Chapter.discover(survival,"home_log");open_story("intro")
	elif mode=="station":
		player.position=Vector3(-2.4,.2,-169.8);survival.parts=true;survival.elapsed=310;survival.temperature=34
		Chapter.discover(survival,"station_dispatch");open_story("station")
	elif mode in ["radio","ending","journal"]:
		player.position=Vector3(-2.4,.2,18.2);survival.parts=true;survival.elapsed=490
		Chapter.discover(survival,"ridge_register");survival.repair();Chapter.advance_radio(survival,"call");Chapter.advance_radio(survival,"report")
		if mode in ["ending","journal"]:Chapter.advance_radio(survival,"confirm")
		if mode=="journal":backpack.tab="journal";backpack.journal_focus="ridge_register";toggle_backpack()
		else:open_story("radio")
	elif mode=="ridge":player.position=Vector3(-31,world.terrain_height(-31,-33.3)+.2,-33.3);player.zoom=8;player.camera.size=8
	elif mode=="module":player.position=Vector3(-2,.24,-169.5);player.zoom=7;player.camera.size=7
	elif mode=="ledger":player.position=Vector3(-2,.2,18.5);player.zoom=7;player.camera.size=7
	active=false;player.enabled=false;toast_time=0
	for i in range(20):await get_tree().process_frame
	# Force one draw also when the app window is covered; this captures a still, not a recording.
	RenderingServer.force_draw(false)
	await get_tree().process_frame
	var path:="res://artifacts/chapter/preview-%s.png"%mode
	assert(get_viewport().get_texture().get_image().save_png(path)==OK)
	print("CHAPTER_CAPTURE ",path)
	set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame;await get_tree().process_frame;OS.delay_msec(100);get_tree().quit()
