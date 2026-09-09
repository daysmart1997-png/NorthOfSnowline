extends "res://scripts/main.gd"

func _ready()->void:
	super._ready();call_deferred("preview_interior")

func preview_interior()->void:
	start_new()
	var mode:="home"
	for option in ["station","outside","night","tent","doorstep"]:
		if OS.get_cmdline_user_args().has("--"+option):mode=option
	var positions:={"doorstep":Vector3(0,.24,22.05),"home":Vector3(0,.24,20),"station":Vector3(0,.24,-168),"outside":Vector3(0,.12,27),"night":Vector3(0,.24,20),"tent":Vector3(22,.2,-62)}
	player.position=positions[mode];player.zoom=16;player.camera.size=16
	if mode=="night":survival.elapsed=840;survival.light_fire("home")
	for i in range(14):world.stamp_snow(Vector3(.14 if i%2 else -.14,0,25.5+i*.45),0,1,i%2==0)
	active=false;player.enabled=false;toast_time=0
	for i in range(8 if mode=="doorstep" else 16):await get_tree().process_frame
	RenderingServer.force_draw(false);await get_tree().process_frame
	var output:=("res://artifacts/interior-atmosphere/" if OS.get_cmdline_user_args().has("--atmosphere") else "res://artifacts/interior/")+mode+("-wide" if OS.get_cmdline_user_args().has("--wide") else "")+".png"
	assert(get_viewport().get_texture().get_image().save_png(output)==OK)
	print("INTERIOR_CAPTURE ",output)
	set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame;await get_tree().process_frame;OS.delay_msec(100);get_tree().quit()
