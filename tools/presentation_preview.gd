extends "res://scripts/main.gd"

func _ready()->void:
	super._ready();call_deferred("capture_presentation")

func capture_presentation()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/presentation"))
	start_new();active=false;player.enabled=false;toast_time=0
	player.position=Vector3(0,world.terrain_height(0,29),29)
	survival.elapsed=60;objective_seen=Chapter.objective(survival);objective_reveal=0
	for state in ["quiet","danger","large","full","map","bag","settings"]:
		preferences.compact_hud=state!="full";preferences.hud_scale=1.3 if state=="large" else 1.0
		survival.temperature=20 if state in ["danger","large"] else 85
		survival.thirst=20 if state in ["danger","large"] else 85
		survival.hunger=20 if state in ["danger","large"] else 85
		survival.energy=20 if state in ["danger","large"] else 85
		map.visible=state=="map"
		if state=="bag":backpack.open_roll()
		if state=="settings":backpack.visible=false;set_menu(true);show_settings(true)
		for i in range(40):await get_tree().process_frame
		RenderingServer.force_draw(false);await get_tree().process_frame
		assert(get_viewport().get_texture().get_image().save_png("res://artifacts/presentation/"+state+".png")==OK)
	set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame;await get_tree().process_frame;OS.delay_msec(100)
	print("PRESENTATION_PREVIEW_OK");get_tree().quit()
