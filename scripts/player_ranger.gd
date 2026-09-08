extends "res://scripts/player.gd"
signal footfall(surface:String,pressure:float,left:bool)
var animation:AnimationPlayer
var animation_names:Dictionary={}
var last_clip:=""
var gait_half:=-1
var last_contact:=Vector3.ZERO
var action_time:=0.0
var breath_cloud:CPUParticles3D
var snow_world:Node3D
var skeleton:Skeleton3D
var ground_samples:Dictionary={}
var feet_modifier:SkeletonModifier3D

func _ready()->void:
	super._ready()
	snow_world=get_parent().get_node("SnowForest")
	floor_snap_length=.55
	for node in visual.get_children():visual.remove_child(node);node.queue_free()
	legs.clear();arms.clear()
	visual.name="RangerVisual"
	var ranger:Node3D=load("res://assets/characters/ranger_motion.glb").instantiate()
	visual.add_child(ranger)
	skeleton=ranger.find_children("*","Skeleton3D",true,false)[0]
	feet_modifier=preload("res://scripts/grounded_feet.gd").new()
	feet_modifier.player=self;feet_modifier.terrain=snow_world;skeleton.add_child(feet_modifier)
	var players:=ranger.find_children("*","AnimationPlayer",true,false)
	if not players.is_empty():
		animation=players[0]
		for clip in animation.get_animation_list():
			var name_part:String=str(clip).get_slice("/",str(clip).get_slice_count("/")-1).trim_prefix("Ranger_")
			if name_part in ["Idle","Walk","Run","CrouchIdle","CrouchWalk","Pickup","Interact","Consume"]:animation_names[name_part]=clip
	for node in ranger.find_children("*","MeshInstance3D",true,false):
		for surface in range(node.mesh.get_surface_count()):
			var original:Material=node.mesh.surface_get_material(surface)
			if original is StandardMaterial3D and (original.resource_name.begins_with("Wool") or original.resource_name.begins_with("Canvas")):
				var fabric:=ShaderMaterial.new();fabric.shader=load("res://assets/shaders/wool.gdshader");fabric.set_shader_parameter("fabric_color",original.albedo_color);node.set_surface_override_material(surface,fabric)
	breath_cloud=CPUParticles3D.new();breath_cloud.amount=9;breath_cloud.lifetime=.8;breath_cloud.one_shot=true;breath_cloud.explosiveness=.7
	breath_cloud.direction=Vector3(0,.2,-1);breath_cloud.spread=20;breath_cloud.gravity=Vector3(.12,.16,0)
	breath_cloud.initial_velocity_min=.15;breath_cloud.initial_velocity_max=.35;breath_cloud.scale_amount_min=.035;breath_cloud.scale_amount_max=.085
	var puff:=QuadMesh.new();puff.size=Vector2(1,1);breath_cloud.mesh=puff
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.vertex_color_use_as_albedo=true;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;breath_cloud.material_override=material
	material.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
	var soft:=GradientTexture2D.new();soft.width=64;soft.height=64;soft.fill=GradientTexture2D.FILL_RADIAL;soft.fill_from=Vector2(.5,.5);soft.fill_to=Vector2(1,.5)
	var edge:=Gradient.new();edge.colors=PackedColorArray([Color(1,1,1,1),Color(1,1,1,0)]);soft.gradient=edge;material.albedo_texture=soft
	breath_cloud.scale_amount_min=.10;breath_cloud.scale_amount_max=.22
	var gradient:=Gradient.new();gradient.colors=PackedColorArray([Color(.8,.86,.92,0),Color(.8,.86,.92,.14),Color(.8,.86,.92,0)]);gradient.offsets=PackedFloat32Array([0,.18,1]);breath_cloud.color_ramp=gradient
	visual.add_child(breath_cloud);breath_cloud.position=Vector3(0,1.65,-.21);breath_cloud.emitting=false

func exhale(effort:float)->void:
	if enabled and snow_world.shelter_at(position).is_empty():
		breath_cloud.scale=Vector3.ONE*lerpf(.7,1.3,effort);breath_cloud.restart();breath_cloud.emitting=true

func play_action(clip:String)->void:
	if animation==null or not animation_names.has(clip):return
	action_time=minf(animation.get_animation(animation_names[clip]).length,1.0)
	last_clip=clip;animation.get_animation(animation_names[clip]).loop_mode=Animation.LOOP_NONE;animation.play(animation_names[clip],.16);animation.speed_scale=1.25

func _physics_process(delta:float)->void:
	super._physics_process(delta)
	if animation==null:return
	if not enabled:
		animation.speed_scale=0;breath_cloud.speed_scale=0
		return
	breath_cloud.speed_scale=1
	sample_ground()
	var speed:=Vector2(velocity.x,velocity.z).length()
	# The imported crouch already bends knees and hips; do not lower the complete model again.
	visual.position.y=lerpf(visual.position.y,-snow_world.snow_depth(position)*.09,delta*10)
	visual.rotation.x=lerpf(visual.rotation.x,0,delta*12)
	if action_time>0 and speed<.2:
		action_time-=delta;animation.speed_scale=1.25;return
	action_time=0
	var clip:String=("CrouchIdle" if crouching else "Idle") if speed<.12 else ("CrouchWalk" if crouching else ("Run" if sprinting else "Walk"))
	if not animation_names.has(clip):return
	var anim:Animation=animation.get_animation(animation_names[clip]);anim.loop_mode=Animation.LOOP_LINEAR
	if last_clip!=clip:
		last_clip=clip;gait_half=-1;animation.play(animation_names[clip],.22)
	var cycle_seconds:=.60 if clip=="Run" else (1.25 if clip=="CrouchWalk" else .80)
	var base_speed:=3.8 if clip=="Run" else (.85 if clip=="CrouchWalk" else 1.65)
	animation.speed_scale=1.0 if speed<.12 else anim.length/cycle_seconds*clampf(speed/base_speed,.45,1.3)
	if speed>.2 and is_on_floor():
		var half:=int(fmod(animation.current_animation_position/maxf(anim.length,.001),1.0)*2)
		if half!=gait_half and position.distance_to(last_contact)>.18:
			gait_half=half;last_contact=position;make_contact(half==0)

func make_contact(left:bool)->void:
	var surface:String=snow_world.surface_at(position)
	var pressure:float=(1.23 if sprinting else (.72 if crouching else 1.0))*(.88+get_parent().survival.weight()/60.0)
	var side:="L" if left else "R"
	var at:Vector3=ground_samples.get(side,{}).get("at",global_position+visual.basis.x*(.13 if left else -.13))
	snow_world.stamp_snow(at,visual.rotation.y,pressure,left)
	footfall.emit(surface,pressure,left)

func leave_footprint()->void:
	# Footfall and indentation are emitted together from the animation's gait phase.
	last_footprint=position

func sample_ground()->void:
	if skeleton==null:return
	for side in ["L","R"]:
		var bone:=skeleton.find_bone("foot."+side)
		var at:Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(bone).origin
		var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.5,at-Vector3.UP*.9)
		ray.exclude=[get_rid()]
		var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():ground_samples[side]={"height":hit.position.y,"normal":hit.normal,"at":hit.position}

func clear_footprints()->void:
	super.clear_footprints()
	if is_instance_valid(snow_world):snow_world.clear_tracks()
	last_contact=position;gait_half=-1
	ground_samples.clear()
	if is_instance_valid(feet_modifier):feet_modifier.corrections.clear()
