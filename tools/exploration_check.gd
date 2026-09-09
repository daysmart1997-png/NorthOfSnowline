extends "res://scripts/main.gd"

func _ready()->void:
	super._ready();call_deferred("check_exploration")

func settle(frames:int=8)->void:
	for i in range(frames):await get_tree().process_frame

func check_exploration()->void:
	start_new();await settle()
	player.position=Vector3(-2.4,.2,-169.8);player.velocity=Vector3.ZERO;await settle();update_target()
	assert(target.get("id")=="radio_parts")
	interact();interact()
	assert(not survival.parts and not pending_action.is_empty(),"Repeated E must not finish or duplicate pickup")
	player.position.z+=.4;await settle()
	assert(pending_action.is_empty() and not survival.parts,"Movement cancels pending pickup without granting items")
	player.position=Vector3(-2.4,.2,-169.8);await settle();update_target();interact();set_menu(true);await settle(60)
	assert(not survival.parts and pending_action.is_empty(),"Pause cancels action; cannot settle a paused pickup")
	set_menu(false);update_target();interact();await settle(60)
	assert(survival.parts and survival.count("parts")==1,"Pickup grants exactly one item after its contact interval")
	assert(story_panel.visible)
	story_panel.select_route("direct")
	player.position=Vector3(1.3,.3,-170.2);player.velocity=Vector3.ZERO;await settle();update_target()
	assert(target.get("id")=="station")
	var wood_before:int=survival.wood;interact();interact();await settle(65)
	assert(survival.wood==wood_before-1 and survival.fires.station>100,"Fire feedback settles fuel exactly once")
	set_menu(true)
	player.position=Vector3(0,.3,20.5);survival.upgrades.bed=true
	survival.items.cloth=0;survival.items.wood=0
	set_menu(false);backpack.tab="craft";toggle_backpack();await settle()
	assert(backpack.find_child("Recipe_bed",true,false).disabled,"Finished upgrade is disabled")
	assert(backpack.find_child("Recipe_bandage",true,false).disabled,"Missing materials are visible before clicking")
	assert(backpack.find_child("Recipe_tea",true,false).disabled,"Unlit fire recipes are disabled")
	backpack.rest_hours=4;backpack.refresh();await settle()
	assert(backpack.find_child("RestForecast",true,false).text.contains("撑不到"),"Four-hour sleep warns about cold fire")
	assert(backpack.get_global_rect().end.y<=720,"Craft and rest fit the reference viewport")
	for building in world.buildings.values():assert(building.find_children("*","Label3D",true,false).is_empty(),"Cabins have no name signs")
	for poi in world.pois:
		if poi.get("inspect",false):assert(world.points.any(func(point):return point.id==poi.id),"All authored clues survive shelter synchronization")
	assert(not survival.discovered.has("fork_note"),"Written clues are not auto-revealed from proximity")
	backpack.visible=false;active=true;player.enabled=true
	player.position=Vector3(4,world.terrain_height(4,-15)+.2,-15);player.velocity=Vector3.ZERO;await settle();update_target()
	assert(target.get("id")=="fork_note")
	interact();await settle(60)
	assert(backpack.visible and backpack.tab=="journal" and survival.discovered.has("fork_note"),"Inspecting a clue reveals its journal entry")
	assert(backpack.journal_focus=="fork_note","New clue is shown first")
	preferences.path="res://artifacts/exploration/preferences-check.cfg"
	preferences.master=.65;preferences.music=0;preferences.effects=.4;preferences.hud_scale=1.3;preferences.apply_audio();preferences.save_preferences()
	var restored=preload("res://scripts/game_preferences.gd").new();restored.path=preferences.path;restored.load_preferences()
	assert(is_equal_approx(restored.hud_scale,1.3) and is_equal_approx(restored.effects,.4),"Presentation preferences survive reload outside savegame")
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("SnowMusic")),"Music slider actually mutes the music bus")
	assert(cassette.speaker.bus=="SnowMusic" and cassette.wind.bus=="SnowEffects","Independent volume controls are connected to actual sounds")
	active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await settle();OS.delay_msec(100)
	print("EXPLORATION_OK: delayed/cancelled/repeated interactions, fire fuel, disabled recipes, rest layout, physical clues, unsigned cabins, persistent audio/HUD preferences")
	get_tree().quit()
