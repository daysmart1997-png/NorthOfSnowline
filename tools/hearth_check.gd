extends "res://scripts/main.gd"
var animate:=false
var inspect_capture:=false

func _ready()->void:
	super._ready();inspect_capture=OS.get_cmdline_user_args().has("--hearth-capture")
	call_deferred("check_hearth")

func _process(delta:float)->void:
	if animate:survival.elapsed+=delta
	super._process(delta)

func frames(count:=5)->void:
	for i in range(count):await get_tree().process_frame

func draw_fire(id:String,fuel:float,time:float)->void:
	survival.fires[id]=fuel;survival.elapsed=time-survival.clock_offset
	world.weather_update(0,player.position,survival.fires,time);interior_view.update()

func capture(id:String)->void:
	if not inspect_capture or DisplayServer.get_name()=="headless":return
	await frames(4);RenderingServer.force_draw(false);await get_tree().process_frame
	assert(get_viewport().get_texture().get_image().save_png("res://artifacts/hearth/"+id+".png")==OK)

func check_hearth()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/hearth"))
	start_new();opening.finish();active=false;player.enabled=false;canvas.visible=false;player.camera.make_current()
	await frames()
	assert(world.fire_effects.size()==4,"All existing usable fireplaces register, including the later-built lodge")
	for id in ["home","station","lodge","hunters"]:
		var effect=world.fire_effects[id]
		assert(effect.material.shader==load("res://assets/shaders/hearth_fire.gdshader"))
		assert(effect.open_fire==(id=="hunters"))
		assert(effect.sparks.size()==(4 if id=="hunters" else 0),"Closed iron stoves cannot throw indoor sparks")
		if id=="hunters":player.position=world.camp_positions[id]+Vector3(0,.1,1)
		else:player.position=world.buildings[id].global_position+Vector3(0,.05,1)
		player.pivot.global_position=effect.source.global_transform*effect.source.get_aabb().get_center()+Vector3(0,.3,0)
		player.zoom=4.0;player.camera.size=4.0
		await frames(50) # Let indoor/outdoor camera layers finish their transition.
		if effect.open_fire:
			assert(effect.global_basis.y.is_equal_approx(Vector3.UP),"Imported mesh axes cannot turn fire sideways")
			assert(effect.tongues[0].global_basis.y.is_equal_approx(Vector3.UP))
		draw_fire(id,0,2220);assert(not effect.source.visible and effect.light.light_energy==0)
		survival.items.wood=2;var before_wood:int=survival.wood
		survival.light_fire(id);assert(survival.wood==before_wood-1 and survival.fires[id]==120)
		draw_fire(id,survival.fires[id],2220.01);var initial:float=effect.level
		draw_fire(id,119,2221);assert(effect.level>initial,"Ignition settles into a full flame")
		var fuel_before:Dictionary=survival.fires.duplicate()
		world.weather_update(0,player.position,survival.fires,survival.solar_time())
		assert(survival.fires==fuel_before,"Rendering never burns or awards fuel")
		await capture(id+"-full-a")
		var frozen:float=effect.material.get_shader_parameter("fire_time");var brightness:float=effect.light.light_energy
		await frames(12)
		assert(effect.material.get_shader_parameter("fire_time")==frozen and effect.light.light_energy==brightness,"Paused simulation freezes both flame and light")
		draw_fire(id,118,2221.6);assert(effect.material.get_shader_parameter("fire_time")!=frozen)
		await capture(id+"-full-b")
		survival.light_fire(id);draw_fire(id,survival.fires[id],2221.6)
		assert(effect.feed_time==2221.6,"Adding real wood triggers the short feed response")
		var full:float=effect.level
		draw_fire(id,3,2225);assert(effect.level<full*.35,"Last fuel has shorter, dimmer flames")
		await capture(id+"-low")
		draw_fire(id,0,2228);assert(not effect.visible and not effect.source.visible and effect.light.light_energy==0)
		if id=="lodge":assert(world.arrival.window_glow.light_energy==0)
		await capture(id+"-out")
	# Construct through the actual recipe; load and removal must not leave an
	# unregistered emitter or a reference to a deleted camp's visuals.
	survival.items={"wood":12,"cloth":8,"scrap":8}
	survival.craft("camp","",[38,world.terrain_height(38,-20),-20]);world.sync_buildings(survival);await frames()
	assert(world.fire_effects.has("camp_0") and world.fire_effects.camp_0.open_fire)
	survival.light_fire("camp_0");draw_fire("camp_0",survival.fires.camp_0,2400)
	assert(world.fire_effects.camp_0.visible and world.fire_effects.camp_0.tongues.size()==3)
	var saved:Dictionary=survival.data();var restored=Survival.new();assert(restored.restore(saved));survival=restored;world.sync_buildings(survival)
	draw_fire("camp_0",survival.fires.camp_0,survival.solar_time());assert(world.fire_effects.camp_0.visible)
	var old_effect:Node=world.fire_effects.camp_0
	start_new();active=false;player.enabled=false;await frames()
	assert(not world.fire_effects.has("camp_0") and not is_instance_valid(old_effect),"New game removes the camp, including its flame and sparks")
	if OS.get_cmdline_user_args().has("--hearth-motion"):
		canvas.visible=false;player.position=world.buildings.lodge.global_position+Vector3(0,.05,1)
		player.pivot.global_position=world.fire_meshes.lodge.global_position+Vector3(-.5,.25,.15);player.zoom=5;player.camera.size=5
		draw_fire("lodge",120,2220);animate=true;await get_tree().create_timer(4).timeout;animate=false
	set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await frames();OS.delay_msec(100)
	print("HEARTH_OK: shared indoor/open fire, real fuel ignition/refeed, pause, dying flame, no ghost light, constructed camp save/load and cleanup")
	get_tree().quit()
