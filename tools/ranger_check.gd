extends "res://scripts/main.gd"
var contacts:Array[Dictionary]=[]
var tick:=0

func _ready()->void:
	super._ready();call_deferred("check_ranger")

func check_ranger()->void:
	start_new();active=false;player.enabled=false;player.feet_modifier.active=false
	for i in range(6):await get_tree().process_frame
	assert(player.animation_names.size()==8,"All interaction and locomotion clips survive the refined export")
	# Inspect the imported asset, not the Blender generator's intermediate data.
	for clip in ["Walk","Run","CrouchWalk"]:
		var name:String=player.animation_names[clip]
		var length:float=player.animation.get_animation(name).length
		var left:Array[Vector3]=[];var right:Array[Vector3]=[]
		player.animation.play(name,0)
		for i in range(80):
			player.animation.seek(length*i/80.0,true)
			left.append(player.skeleton.get_bone_global_pose(player.skeleton.find_bone("foot.L")).origin)
			right.append(player.skeleton.get_bone_global_pose(player.skeleton.find_bone("foot.R")).origin)
		for i in range(80):
			var mirrored:Vector3=right[(i+40)%80];mirrored.x=-mirrored.x
			assert(left[i].distance_to(mirrored)<.018,"Left/right half-cycle symmetry: %s frame %d left %s mirrored %s length %f"%[clip,i,left[i],mirrored,length])
	# Real movement through walk/run/crouch and stop/restart. A mid-cycle sprint
	# used to restart the left foot and break alternation even on flat ground.
	player.feet_modifier.active=true;player.enabled=true;active=true
	player.position=Vector3(0,world.terrain_height(0,-10)+.025,-10)
	player.velocity=Vector3.ZERO;player.pivot.rotation.y=0;player.clear_footprints()
	var capture:=OS.get_cmdline_user_args().has("--ranger-capture")
	if capture:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/ranger-finish/live"))
		canvas.visible=false;player.zoom=5;player.camera.size=5
		var inspection:=Camera3D.new();player.add_child(inspection)
		inspection.projection=Camera3D.PROJECTION_ORTHOGONAL;inspection.size=5
		inspection.cull_mask=interior_view.OUTDOOR_VIEW
		inspection.position=Vector3(4,2.4,-2)
		inspection.look_at(player.global_position+Vector3(0,.9,0));inspection.current=true
	player.footfall.connect(func(surface:String,pressure:float,left:bool):contacts.append({"tick":tick,"left":left,"surface":surface,"pressure":pressure}))
	Input.action_press("move_up")
	for i in range(390):
		tick=i
		if i==85:Input.action_press("sprint")
		if i==145:Input.action_release("sprint")
		if i==208:player.crouching=true
		if i==292:player.crouching=false
		if i==318:Input.action_release("move_up")
		if i==340:Input.action_press("move_up")
		await get_tree().physics_frame
		if capture and i in [75,125,260]:
			RenderingServer.force_draw(false);await get_tree().process_frame
			assert(get_viewport().get_texture().get_image().save_png("res://artifacts/ranger-finish/live/%03d.png"%i)==OK)
	Input.action_release("move_up")
	assert(contacts.size()>=10,"Transitions retain real gait-driven contacts")
	for i in range(1,contacts.size()):
		assert(contacts[i].left!=contacts[i-1].left,"Walk/run/crouch and stop/restart preserve alternating feet")
		assert(contacts[i].tick-contacts[i-1].tick>=8,"Changing clips does not double-trigger a footstep")
	assert(player.position.z< -18,"Checks use actual movement, without disabling collisions")
	assert(world.track_marks.size()>=8,"Refined gait continues to leave snow impressions")
	assert(player.feet_modifier.adjustments>200,"Terrain fitting still runs with the refined skin")
	print("RANGER_CONTACTS ",JSON.stringify(contacts))
	active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame;await get_tree().process_frame;OS.delay_msec(100)
	print("RANGER_CHECK_OK: eight clips, imported bilateral gait symmetry, real walk/run/crouch and restart contacts, bounded cadence, snow impressions and terrain fitting")
	get_tree().quit()
