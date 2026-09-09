extends "res://scripts/main.gd"

# Identical camera, clock and real snow stamps for material comparison captures.
func _ready()->void:
	super._ready()
	call_deferred("preview")

func preview()->void:
	start_new();active=false;player.enabled=false
	var args:=OS.get_cmdline_user_args()
	var phase:="night" if args.has("--night") else ("noon" if args.has("--noon") else "day")
	var version:="before" if args.has("--before") else "after"
	survival.elapsed=840 if phase=="night" else (180 if phase=="noon" else 0)
	player.position=Vector3(0,world.terrain_height(0,31)+.2,31)
	player.pivot.position.z=-4;player.zoom=20;player.camera.size=20
	world.clear_tracks()
	for i in range(12):
		world.stamp_snow(Vector3(.14 if i%2==0 else -.14,0,27+i*.48),0,1,i%2==0)
	if args.has("--aged"):
		for mark in world.track_marks:mark.age=180.0
	toast_time=0
	for i in range(12):await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var destination:="res://artifacts/snow-finish/%s/%s%s.png"%[version,phase,"-aged" if args.has("--aged") else ""]
	var result:=get_viewport().get_texture().get_image().save_png(destination)
	print("SNOW_FINISH_CAPTURE=",result," ",destination)
	set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame;await get_tree().process_frame
	OS.delay_msec(100)
	get_tree().quit()
