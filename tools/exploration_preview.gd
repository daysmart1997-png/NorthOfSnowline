extends "res://scripts/main.gd"

func _ready()->void:
	super._ready();call_deferred("preview_exploration")

func preview_exploration()->void:
	start_new()
	var args:=OS.get_cmdline_user_args()
	var mode:="fork"
	for option in ["craft","settings","cabin","snow","night","sled","journal","hud"]:
		if args.has("--"+option):mode=option
	if mode=="craft":
		survival.upgrades.bed=true;survival.items.cloth=1;survival.fires.home=90
		backpack.rest_hours=4;backpack.tab="craft";toggle_backpack()
	elif mode=="settings":set_menu(true);show_settings(true)
	elif mode=="journal":
		survival.discovered.append("fork_note");backpack.journal_focus="fork_note";backpack.tab="journal";toggle_backpack()
	else:
		var places:={"fork":Vector2(4,-14),"cabin":Vector2(0,31),"snow":Vector2(39,-43),"night":Vector2(0,31),"sled":Vector2(-18,-27),"hud":Vector2(0,31)}
		var at:Vector2=places[mode];player.position=Vector3(at.x,world.terrain_height(at.x,at.y)+.2,at.y)
		player.pivot.position.z=-3;player.zoom=20;player.camera.size=20
		if mode=="night":survival.elapsed=840
		if mode=="hud":preferences.hud_scale=1.3;survival.temperature=19;survival.thirst=21
		if mode in ["cabin","night","snow","hud"]:
			for i in range(16):world.stamp_snow(Vector3(at.x+(.14 if i%2==0 else -.14),0,at.y-4+i*.48),0,1,i%2==0)
	active=false;player.enabled=false;toast_time=0
	for i in range(16):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path:="res://artifacts/exploration/preview-%s.png"%mode
	assert(get_viewport().get_texture().get_image().save_png(path)==OK)
	print("EXPLORATION_CAPTURE ",path)
	set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame;await get_tree().process_frame;OS.delay_msec(100);get_tree().quit()
