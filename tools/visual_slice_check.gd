extends "res://scripts/main.gd"

func _ready()->void:
	super._ready();call_deferred("check_slice")

func check_slice()->void:
	start_new()
	for i in range(8):await get_tree().physics_frame
	# The doorway and existing approach remain shallow despite nearby drifts.
	for z in [25.5,27.0,30.0,32.0]:
		assert(world.snow_depth(Vector3(0,0,z))<.08,"Door approach remains packed and traversable")
	var bank:=Vector3(-5.6,0,15.5)
	assert(world.snow_depth(bank)>.25,"Snow visibly accumulates outside the eave")
	var query:=PhysicsRayQueryParameters3D.create(bank+Vector3(0,3,0),bank-Vector3(0,2,0))
	var hit:=world.get_world_3d().direct_space_state.intersect_ray(query)
	assert(not hit.is_empty() and absf(hit.position.y-world.terrain_height(bank.x,bank.z))<.10,"Drift collision agrees with rendered terrain")
	var depth:float=world.stamp_snow(bank,0,1,true)
	assert(depth>0 and depth<=world.snow_depth(bank),"New drifts retain depth-bounded boot impressions")
	for x in [-19.01,19.01]:
		for z in range(4,44,4):
			assert(absf(world.terrain_height(x-.02,z)-world.terrain_height(x+.02,z))<.04,"Local dressing boundary has no height discontinuity")
	for id in ["fallen_timber","old_stump","firewood_stack"]:
		var prop:Node3D=world.get_node("CabinDressing_"+id)
		assert(not prop.find_children("*","MeshInstance3D",true,false).is_empty())
		assert(not prop.find_children("*","StaticBody3D",true,false).is_empty(),"Dressing has physical presence")
	for id in ["home","station"]:
		assert((world.fire_lights[id].light_cull_mask & (1 | 16 | 32))==0,"Indoor stove light cannot leak onto exterior snow")
		assert(world.buildings[id].has_node("PorchLantern"))
	assert(world.snow_surface.get_shader_parameter("powder_normal").get_width()>0)
	assert(world.detail_surface.get_shader_parameter("powder_normal")==world.snow_surface.get_shader_parameter("powder_normal"),"Both snow meshes share the same surface data")
	active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame;await get_tree().process_frame;OS.delay_msec(100)
	print("VISUAL_SLICE_CHECK_OK: clear approach, physical drift heights, bounded prints, local boundary, prop collision, indoor light isolation, shared snow maps")
	get_tree().quit()
