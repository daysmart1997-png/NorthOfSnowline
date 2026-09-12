extends "res://scripts/main.gd"
var contacts:Array[Dictionary]=[]
var tick:=0

func _ready()->void:
	super._ready();call_deferred("check_ranger")

func check_ranger()->void:
	start_new();active=false;player.enabled=false;player.feet_modifier.active=false
	for i in range(6):await get_tree().process_frame
	assert(player.animation_names.size()==8,"All interaction and locomotion clips survive the refined export")
	assert(player.animation.get_animation(player.animation_names.Idle).length>17,"Keep the supplied relaxed standing sequence")
	for clip in ["Idle","Walk","Run"]:
		var anim:Animation=player.animation.get_animation(player.animation_names[clip])
		player.animation.play(player.animation_names[clip],0)
		for i in range(33):
			player.animation.seek(anim.length*i/32.0,true)
			var hip:Vector3=player.skeleton.get_bone_global_pose(player.skeleton.find_bone("hips")).origin
			assert(Vector2(hip.x,hip.z).length()<.36,"Root travel cannot move the visual out of its collision body: "+clip)
	for clip in ["Pickup","Interact","Consume"]:
		var anim:Animation=player.animation.get_animation(player.animation_names[clip])
		player.animation.play(player.animation_names[clip],0);player.animation.seek(0,true)
		var rest_hip:Vector3=player.skeleton.get_bone_global_pose(player.skeleton.find_bone("hips")).origin
		player.animation.seek(anim.length*.5,true)
		var hand:Vector3=player.skeleton.get_bone_global_pose(player.skeleton.find_bone("L_Hand")).origin
		var head:Vector3=player.skeleton.get_bone_global_pose(player.skeleton.find_bone("head")).origin
		var hip:Vector3=player.skeleton.get_bone_global_pose(player.skeleton.find_bone("hips")).origin
		if clip=="Consume":assert(hand.distance_to(head)<.3,"Eating reaches the new face")
		if clip=="Pickup":assert(hip.y<rest_hip.y-.2 and hand.y<.7,"Pickup bends and reaches down")
		if clip=="Interact":assert(hand.z<-.2 and hand.y>.9,"Interaction reaches a work surface")
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
		# Supplied motion is naturally asymmetric. Check functional contacts and
		# loop continuity, rather than forcing the old generated mirror poses.
		for foot in [left,right]:
			var low:=100.0;var high:=-100.0
			for at in foot:low=minf(low,at.y);high=maxf(high,at.y)
			assert(high-low>.045 and high-low<.65,"Each supplied foot lifts and lands: "+clip)
			assert(foot[0].distance_to(foot[-1])<.15,"No discontinuous foot reset: "+clip)
		print("GAIT_PHASE ",clip," ",left[0]," ",left[40]," ",right[0]," ",right[40])
		assert(left[0].z<right[0].z and right[40].z<left[40].z,"Advancing foot matches alternating footstep events: "+clip)
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
	player.footfall.connect(func(surface:String,pressure:float,left:bool):
		var side:="L" if left else "R"
		var actual:Vector3=player.skeleton.global_transform*player.skeleton.get_bone_global_pose(player.skeleton.find_bone("foot."+side)).origin
		var ground:Vector3=player.ground_samples[side].at
		assert(Vector2(actual.x,actual.z).distance_to(Vector2(ground.x,ground.z))<.001,"Footstep uses this frame's rendered foot, not last frame's sample")
		assert(actual.y-ground.y<=.0751,"No print or sound while the foot is airborne")
		if surface in ["snow","deep"] and absf(ground.y-world.terrain_height(ground.x,ground.z))<.18:
			var mark:Dictionary=world.track_marks.back()
			assert(Vector2(mark.at).distance_to(Vector2(actual.x,actual.z))<.001,"Snow indentation is under the contacting boot")
		contacts.append({"tick":tick,"left":left,"surface":surface,"pressure":pressure,"clearance":actual.y-ground.y,"phase":player.contact_evidence.phase})
	)
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
	# Keep the same geometry assertions while the body turns under running feet.
	var before_turns:=contacts.size()
	Input.action_press("sprint")
	for direction in ["move_right","move_down","move_left"]:
		Input.action_press(direction)
		for i in range(65):tick+=1;await get_tree().physics_frame
		Input.action_release(direction)
	Input.action_release("sprint")
	assert(contacts.size()>before_turns+3,"Running turns still produce grounded contacts")
	print("RANGER_CONTACTS ",JSON.stringify(contacts))
	active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await get_tree().process_frame;await get_tree().process_frame;OS.delay_msec(100)
	print("RANGER_CHECK_OK: eight clips, supplied gait lift/contact/loop continuity, real walk/run/crouch and restart contacts, bounded cadence, snow impressions and terrain fitting")
	get_tree().quit()
