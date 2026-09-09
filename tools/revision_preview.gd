extends "res://scripts/main.gd"
var output_dir:="res://artifacts/revision"

func _ready()->void:
	super._ready();call_deferred("preview_revision")

func settle(count:=24)->void:
	for i in range(count):await get_tree().process_frame

func picture(id:String)->void:
	await settle();await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(output_dir+"/"+id+".png")==OK)

func preview_revision()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--revision-output="):output_dir="res://artifacts/"+arg.get_slice("=",1).get_file()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	start_new();opening.begin();await settle(55);await picture("opening")
	opening.advance();await settle(55);await picture("opening-station");opening.advance();await settle(55);await picture("opening-home");opening.finish()
	active=false;player.enabled=false;canvas.visible=false
	player.position=Vector3(0,world.terrain_height(0,29)+.1,29)
	var camera:=Camera3D.new();add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.cull_mask=interior_view.OUTDOOR_VIEW;camera.current=true
	var focus:=Vector3(-14,world.terrain_height(-14,-43)+.8,-43)
	camera.position=focus+Vector3(6,4,6);camera.look_at(focus);camera.size=7.2
	await picture("postal-van")
	camera.position=focus+Vector3(-6,7,-6);camera.look_at(focus);await picture("postal-van-front")
	focus=Vector3(0,2,18);camera.position=focus+Vector3(12,13,16);camera.look_at(focus);camera.size=17
	player.position=Vector3(0,world.terrain_height(0,29)+.1,29);await picture("cabin")
	focus=Vector3(0,2,-170);camera.position=focus+Vector3(12,13,16);camera.look_at(focus);camera.size=17;await picture("station")
	focus=Vector3(0,.2,-86);camera.position=focus+Vector3(12,11,15);camera.look_at(focus);camera.size=22;await picture("bridge")
	player.camera.current=true;camera.queue_free();player.position=Vector3(-.4,.26,18.5);canvas.visible=true;open_story("intro");await picture("ledger")
	survival.parts=true;survival.repair();Chapter.advance_radio(survival,"call");open_story("radio");await picture("call")
	Chapter.advance_radio(survival,"report");Chapter.advance_radio(survival,"confirm")
	open_story("epilogue");story_panel.listen("listen");await picture("fragment");story_panel.listen("check_card");await picture("card");story_panel.listen("record");await picture("ending")
	active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();await settle(3);OS.delay_msec(100)
	print("REVISION_PREVIEW_OK");get_tree().quit()
