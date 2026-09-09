extends "res://scripts/main.gd"
# Native-renderer measurement only. It does not record or alter player settings.
var samples:Array[float]=[]
var wall_start:=0
var previous_tick:=0
var solid:=false
var finished:=false
func _ready()->void:
	super._ready();start_new();active=false;player.enabled=false
	player.position=Vector3(0,.24,20);player.zoom=16;player.camera.size=16
	solid=OS.get_cmdline_user_args().has("--solid")
	Engine.max_fps=0;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.render_loop_enabled=false
	wall_start=Time.get_ticks_usec();previous_tick=wall_start
func _process(delta:float)->void:
	if finished:return
	super._process(delta)
	if solid:
		interior_view.backdrop.render_target_update_mode=SubViewport.UPDATE_DISABLED
		interior_view.backdrop_plane.visible=false
	var now:=Time.get_ticks_usec()
	var seconds:=float(now-wall_start)/1000000.0
	if previous_tick-wall_start>=1500000 and seconds<=7.5:samples.append(float(now-previous_tick)/1000.0)
	previous_tick=now
	RenderingServer.force_draw(false)
	if seconds>7.5:
		finished=true;samples.sort()
		var total:=0.0
		for value in samples:total+=value
		var data:={"mode":"solid" if solid else "atmosphere","viewport":"1280x720","backdrop":"640x360","case":"stationary indoor scene, native forced draw, VSync off, 1.5s warmup + 6s sample","sample_seconds":total/1000.0,"samples":samples.size(),"mean_ms":total/samples.size(),"p95_ms":samples[int(samples.size()*.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"triangles":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
		var file:=FileAccess.open("res://artifacts/interior-atmosphere/performance-"+data.mode+".json",FileAccess.WRITE);file.store_string(JSON.stringify(data,"\t"));file.close()
		print("INTERIOR_PERFORMANCE ",JSON.stringify(data))
		set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
		await get_tree().process_frame;await get_tree().process_frame;OS.delay_msec(100);get_tree().quit()
