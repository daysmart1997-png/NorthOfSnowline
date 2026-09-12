extends "res://scripts/main.gd"
# Reproducible native-renderer comparisons. All output is local; no player save.
var slice_clock:=0.0
var slice_storm:=0.0
var slice_running:=false
var output_dir:="res://artifacts/visual-slice/after"

func _ready()->void:
	super._ready()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--slice-output="):output_dir="res://artifacts/visual-slice/"+arg.get_slice("=",1).get_file()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	# Explicit diagnostic only, never part of the production lighting preset.
	if OS.get_cmdline_user_args().has("--slice-terrain-shadow-off"):
		for node in world.get_children():
			if node is MeshInstance3D and node.material_override==world.snow_surface:
				node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	call_deferred("capture_slice")

func _process(delta:float)->void:
	super._process(delta)
	if slice_running:
		world.lighting_time=-INF
		world.weather_update(slice_storm,player.position,survival.fires,slice_clock)
		interior_view.update()

func capture_slice()->void:
	start_new();opening.finish();active=false;player.enabled=false;canvas.visible=false
	player.camera.make_current()
	player.position=Vector3(0,world.terrain_height(0,30)+.04,30)
	player.pivot.position.z=-5;player.zoom=27;player.camera.size=27
	world.clear_tracks()
	for i in range(15):
		world.stamp_snow(Vector3(.14 if i%2==0 else -.14,0,25.5+i*.45),0,1,i%2==0)
	toast_time=0;slice_running=true
	if OS.get_cmdline_user_args().has("--slice-profile"):
		await profile_slice()
	else:
		for phase in ["dawn","noon","dusk","night","storm","interior","lodge_dusk","lodge_night","lodge_cold","lodge_fire","station"]:
			# Fixtures keep the new journey's offset and use one solar time for
			# the HUD, indoor ambient, lights and weather. No simulation ticks.
			slice_clock=1440.0+{"dawn":1260.0,"noon":180.0,"dusk":510.0,"night":840.0,"storm":180.0,"interior":840.0,"lodge_dusk":510.0,"lodge_night":840.0,"lodge_cold":840.0,"lodge_fire":840.0,"station":840.0}[phase]
			slice_storm=1.0 if phase=="storm" else 0.0
			survival.elapsed=slice_clock-survival.clock_offset
			if phase in ["night","interior"]:survival.fires.home=120.0
			else:survival.fires.home=0.0
			survival.fires.lodge=120.0 if phase in ["lodge_night","lodge_fire"] else 0.0
			if phase=="interior":player.position=Vector3(0,.24,20);player.pivot.position.z=0;player.zoom=16;player.camera.size=16
			if phase in ["lodge_dusk","lodge_night"]:
				player.position=Vector3(-11,world.terrain_height(-11,83)+.04,83);player.pivot.position.z=-5;player.zoom=27;player.camera.size=27
			if phase in ["lodge_cold","lodge_fire"]:
				player.position=Vector3(-11,.24,73.7);player.pivot.position.z=0;player.zoom=14;player.camera.size=14
			if phase=="station":
				var at:Vector3=world.buildings.station.position
				player.position=at+Vector3(0,.04,1);player.pivot.position.z=0;player.zoom=16;player.camera.size=16;survival.fires.station=120.0
			# Wait by time for the room transition, independent of host FPS.
			await get_tree().create_timer(.8).timeout
			RenderingServer.force_draw(false);await get_tree().process_frame
			assert(get_viewport().get_camera_3d()==player.camera,"Opening camera must not own the capture")
			var path:String=output_dir+"/"+phase+".png"
			assert(get_viewport().get_texture().get_image().save_png(path)==OK)
			print("SLICE_CAPTURE ",path)
		# One extra actual-play-scale view with HUD; never confuse a clean art
		# capture with a redesign of the player's interface.
		slice_clock=1440+480;slice_storm=0;survival.elapsed=slice_clock-survival.clock_offset;survival.fires.home=0
		player.position=Vector3(0,world.terrain_height(0,29)+.04,29)
		player.pivot.position.z=0;player.zoom=20;player.camera.size=20;canvas.visible=true
		await get_tree().create_timer(.8).timeout
		RenderingServer.force_draw(false);await get_tree().process_frame
		assert(get_viewport().get_texture().get_image().save_png(output_dir+"/gameplay.png")==OK)
		print("SLICE_CAPTURE ",output_dir+"/gameplay.png")
	set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame;await get_tree().process_frame;OS.delay_msec(100)
	print("VISUAL_SLICE_OK");get_tree().quit()

func profile_slice()->void:
	slice_clock=1440+180;survival.elapsed=slice_clock-survival.clock_offset
	var profile_room:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--slice-profile-room="):profile_room=arg.get_slice("=",1)
	if not profile_room.is_empty():
		assert(profile_room in ["home","lodge","station"])
		slice_clock=1440+840;survival.elapsed=slice_clock-survival.clock_offset;survival.fires[profile_room]=120.0
		player.position=world.buildings[profile_room].global_position+Vector3(0,.04,1)
		player.pivot.position.z=0;player.zoom=16;player.camera.size=16
		await get_tree().create_timer(.8).timeout
	Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.render_loop_enabled=false
	var samples:Array[float]=[]
	var start:=Time.get_ticks_usec();var previous:=start
	while Time.get_ticks_usec()-start<8000000:
		RenderingServer.force_draw(false)
		await get_tree().process_frame
		var now:=Time.get_ticks_usec()
		if previous-start>2000000:samples.append((now-previous)/1000.0)
		previous=now
	assert(not samples.is_empty());samples.sort()
	var total:=0.0
	for value in samples:total+=value
	var data:={"case":"stationary cabin exterior, noon, 1280x720, zoom 27, native forced draw, VSync off, 2s warmup + 6s sample","samples":samples.size(),"mean_ms":total/samples.size(),"p95_ms":samples[int(samples.size()*.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"triangles":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
	if not profile_room.is_empty():data["case"]="stationary "+profile_room+" interior with lit stove and exterior backdrop, 23:00, 1280x720, zoom 16, native forced draw, VSync off, 2s warmup + 6s sample"
	var file:=FileAccess.open(output_dir+"/performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t"));file.close();print("SLICE_PERFORMANCE ",JSON.stringify(data))
