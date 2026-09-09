extends "res://scripts/main.gd"
# Still pose sheets, not video; frozen scene state never touches player saves.
var output_dir:="res://artifacts/ranger-finish/before"

func _ready()->void:
	super._ready();call_deferred("capture_ranger")

func capture_ranger()->void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--ranger-output="):output_dir="res://artifacts/ranger-finish/"+arg.get_slice("=",1).get_file()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	start_new();active=false;player.enabled=false;canvas.visible=false
	player.position=Vector3(0,world.terrain_height(0,30),30)
	player.camera.size=4.2;player.zoom=4.2
	player.pivot.rotation.x=deg_to_rad(-24);player.pivot.position.y=.95
	player.feet_modifier.active=false
	for i in range(40):await get_tree().process_frame
	for view in ["front","back"]:
		player.visual.rotation.y=PI if view=="front" else 0.0
		await pose("Idle",.2,view)
	for clip in ["Walk","Run","CrouchWalk"]:
		player.visual.rotation.y=PI*.5
		for i in range(8):await pose(clip,i/8.0,clip.to_lower()+"-%02d"%i)
	player.visual.rotation.y=PI
	for clip in ["Pickup","Interact","Consume"]:await pose(clip,.45,clip.to_lower())
	await pose("Idle",.2,"breath-rest")
	player.set_physics_process(false);player.enabled=true;player.breath_cloud.speed_scale=1
	player.exhale(1.0)
	for i in range(48):
		await get_tree().physics_frame
		if i in [7,15,30,45]:
			RenderingServer.force_draw(false);await get_tree().process_frame
			assert(get_viewport().get_texture().get_image().save_png(output_dir+"/breath-%02d.png"%i)==OK)
	player.enabled=false
	set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame;await get_tree().process_frame;OS.delay_msec(100)
	print("RANGER_PREVIEW_OK");get_tree().quit()

func pose(clip:String,phase:float,label:String)->void:
	var name:String=player.animation_names[clip]
	player.animation.play(name);player.animation.seek(player.animation.get_animation(name).length*phase,true)
	for i in range(3):await get_tree().process_frame
	RenderingServer.force_draw(false);await get_tree().process_frame
	assert(get_viewport().get_texture().get_image().save_png(output_dir+"/"+label+".png")==OK)
