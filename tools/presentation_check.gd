extends "res://scripts/main.gd"

func _ready()->void:
	super._ready();call_deferred("check_presentation")

func check_presentation()->void:
	start_new();active=false;player.enabled=false
	player.position=Vector3(0,world.terrain_height(0,29),29)
	survival.elapsed=60;objective_seen=Chapter.objective(survival);objective_reveal=0
	update_hud("",false)
	assert(status_hud.compact and not objective.visible and not weather_label.visible,"Ordinary exploration leaves the upper corners clear")
	survival.thirst=34;update_hud("",false);assert(status_hud.warnings.thirst)
	survival.thirst=38;update_hud("",false);assert(status_hud.warnings.thirst,"Recovery hysteresis prevents flickering warnings")
	survival.thirst=42;update_hud("",false);assert(not status_hud.warnings.thirst)
	survival.temperature=20;update_hud("",false);assert(context_label.text.contains("体温过低"))
	map.visible=true;update_hud("",false);assert(objective.visible and weather_label.visible)
	map.visible=false;preferences.compact_hud=false;update_hud("",false);assert(objective.visible and weather_label.visible and not status_hud.compact)
	preferences.path="res://artifacts/exploration/presentation.cfg";preferences.save_preferences()
	var restored=preload("res://scripts/game_preferences.gd").new();restored.path=preferences.path;restored.load_preferences()
	assert(not restored.compact_hud,"The accessibility choice survives a restart")
	preferences.compact_hud=true
	for surface in ["snow","deep","wood","ice"]:
		var previous:=-1
		for i in range(12):
			cassette.play_step(surface,1.0,i%2==0)
			assert(cassette.last_surface_samples[surface]!=previous,"No immediate repeat within each surface bank")
			previous=cassette.last_surface_samples[surface]
			assert(is_finite(cassette.footstep.volume_db) and cassette.footstep.volume_db< -10)
	assert(cassette.foley_levels.size()==24)
	survival.loot("presentation",{"player":1,"tape_embers":1});survival.use_item("tape_embers");survival.toggle_music()
	for i in range(35):await get_tree().process_frame
	assert(cassette.speaker.playing and cassette.speaker.volume_db> -25,"Tape fades in while reading")
	survival.loot("presentation_second_tape",{"tape_stride":1});survival.use_item("tape_stride")
	for i in range(65):await get_tree().process_frame
	assert(cassette.current_tape=="tape_stride" and cassette.speaker.volume_db> -25,"Changing tape fades through the old stream before playing the new one")
	survival.toggle_music()
	for i in range(38):await get_tree().process_frame
	assert(not cassette.speaker.playing and cassette.current_tape.is_empty(),"Tape fade-out actually stops playback")
	set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame;await get_tree().process_frame;OS.delay_msec(100)
	print("PRESENTATION_OK: contextual HUD, warning hysteresis, danger text, map/full-mode access, saved preference, balanced nonrepeating footsteps, cassette fades")
	get_tree().quit()
