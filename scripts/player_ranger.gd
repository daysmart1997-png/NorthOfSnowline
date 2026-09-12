extends "res://scripts/player.gd"
const MODEL = preload("res://assets/characters/ranger_supplied_v3.glb")
# Measured travel per second in the supplied clips, after metre conversion.
const AUTHORED_SPEED={"Walk":1.2687091312,"Run":4.6237804848}
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
var foot_armed:Dictionary={"L":true,"R":true}
var contact_age:=1.0
var contact_evidence:Dictionary={}

func _ready()->void:
	super._ready()
	snow_world=get_parent().get_node("SnowForest")
	floor_snap_length=.55
	for node in visual.get_children():visual.remove_child(node);node.queue_free()
	legs.clear();arms.clear()
	visual.name="RangerVisual"
	var ranger:Node3D=MODEL.instantiate()
	visual.add_child(ranger)
	skeleton=ranger.find_children("*","Skeleton3D",true,false)[0]
	skeleton.modifier_callback_mode_process=Skeleton3D.MODIFIER_CALLBACK_MODE_PROCESS_PHYSICS
	feet_modifier=preload("res://scripts/grounded_feet.gd").new()
	feet_modifier.player=self;feet_modifier.terrain=snow_world;skeleton.add_child(feet_modifier)
	var players:=ranger.find_children("*","AnimationPlayer",true,false)
	if not players.is_empty():
		animation=players[0]
		animation.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
		for clip in animation.get_animation_list():
			var name_part:String=str(clip).get_slice("/",str(clip).get_slice_count("/")-1).trim_prefix("Ranger_")
			if name_part in ["Idle","Walk","Run","CrouchIdle","CrouchWalk","Pickup","Interact","Consume"]:animation_names[name_part]=clip
	for node in ranger.find_children("*","MeshInstance3D",true,false):
		for surface in range(node.mesh.get_surface_count()):
			var original:Material=node.mesh.surface_get_material(surface)
			if original is StandardMaterial3D and (original.resource_name.begins_with("Wool") or original.resource_name.begins_with("Canvas")):
				var fabric:=ShaderMaterial.new();fabric.shader=load("res://assets/shaders/wool.gdshader");fabric.set_shader_parameter("fabric_color",original.albedo_color);node.set_surface_override_material(surface,fabric)
	breath_cloud=CPUParticles3D.new();breath_cloud.amount=9;breath_cloud.lifetime=.8;breath_cloud.one_shot=true;breath_cloud.explosiveness=.7
	breath_cloud.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	breath_cloud.direction=Vector3(0,.2,-1);breath_cloud.spread=20;breath_cloud.gravity=Vector3(.12,.16,0)
	breath_cloud.initial_velocity_min=.15;breath_cloud.initial_velocity_max=.35;breath_cloud.scale_amount_min=.035;breath_cloud.scale_amount_max=.085
	var puff:=QuadMesh.new();puff.size=Vector2(1,1);breath_cloud.mesh=puff
	var material:=ShaderMaterial.new();material.shader=load("res://assets/shaders/breath.gdshader");breath_cloud.material_override=material
	breath_cloud.scale_amount_min=.10;breath_cloud.scale_amount_max=.22
	var gradient:=Gradient.new();gradient.colors=PackedColorArray([Color(.8,.86,.92,0),Color(.8,.86,.92,.14),Color(.8,.86,.92,0)]);gradient.offsets=PackedFloat32Array([0,.18,1]);breath_cloud.color_ramp=gradient
	visual.add_child(breath_cloud);breath_cloud.position=Vector3(0,1.65,-.21);breath_cloud.emitting=false

func exhale(effort:float)->void:
	if enabled and snow_world.shelter_at(position).is_empty():
		breath_cloud.scale=Vector3.ONE*lerpf(.7,1.3,effort);breath_cloud.restart();breath_cloud.emitting=true

func play_action(clip:String)->void:
	if animation==null or not animation_names.has(clip):return
	action_time=animation.get_animation(animation_names[clip]).length/1.25
	last_clip=clip;animation.get_animation(animation_names[clip]).loop_mode=Animation.LOOP_NONE;animation.play(animation_names[clip],.16);animation.speed_scale=1.25

func _physics_process(delta:float)->void:
	super._physics_process(delta)
	if animation==null:return
	if not enabled:
		animation.speed_scale=0;breath_cloud.speed_scale=0
		return
	breath_cloud.speed_scale=1
	contact_age+=delta
	var speed:=Vector2(velocity.x,velocity.z).length()
	# The imported crouch already bends knees and hips; do not lower the complete model again.
	visual.position.y=lerpf(visual.position.y,-snow_world.snow_depth(position)*.09,delta*10)
	var load_lean:float=deg_to_rad(lerpf(1.0,4.0,clampf(get_parent().survival.weight()/24.0,0,1)))
	visual.rotation.x=lerpf(visual.rotation.x,-load_lean*clampf(speed/1.65,0,1),delta*8)
	if action_time>0 and speed<.2:
		action_time-=delta;animation.speed_scale=1.25;return
	action_time=0
	var clip:String=("CrouchIdle" if crouching else "Idle") if speed<.12 else ("CrouchWalk" if crouching else ("Run" if sprinting else "Walk"))
	if not animation_names.has(clip):return
	var anim:Animation=animation.get_animation(animation_names[clip]);anim.loop_mode=Animation.LOOP_LINEAR
	if last_clip!=clip:
		var moving_clips:=["Walk","Run","CrouchWalk"]
		var keep_phase:bool=last_clip in moving_clips and clip in moving_clips
		var phase:float=fposmod(animation.current_animation_position/maxf(animation.current_animation_length,.001),1.0) if keep_phase else (.5 if gait_half==0 else 0.0)
		last_clip=clip;animation.play(animation_names[clip],.18)
		if clip in moving_clips and not keep_phase:foot_armed["R" if gait_half==0 else "L"]=true
		# Walk/run/crouch share alternating contacts. Retain the current support
		# foot across transitions instead of restarting every clip on the left.
		if clip in moving_clips:animation.seek(phase*anim.length,true)
	var cycle_seconds:=.60 if clip=="Run" else (1.25 if clip=="CrouchWalk" else .80)
	var base_speed:=3.8 if clip=="Run" else (.85 if clip=="CrouchWalk" else 1.65)
	animation.speed_scale=1.0 if speed<.12 else anim.length/cycle_seconds*clampf(speed/base_speed,.08,1.3)
	if AUTHORED_SPEED.has(clip):animation.speed_scale=clampf(speed/float(AUTHORED_SPEED[clip]),.08,1.6)

func update_foot_contacts()->void:
	# Called by the final foot modifier, after this physics tick's animation/IK.
	# A lifted foot re-arms; its actual return to the surface emits one event.
	if not enabled or not is_on_floor():return
	var moving:=Vector2(velocity.x,velocity.z).length()>.2 and last_clip in ["Walk","Run","CrouchWalk"]
	for side in ["L","R"]:
		var at:Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("foot."+side)).origin
		var hit:=foot_ground(at)
		if hit.is_empty():foot_armed[side]=true;continue
		var clearance:float=at.y-hit.position.y
		if clearance>.105:foot_armed[side]=true
		var half:=0 if side=="L" else 1
		if moving and foot_armed[side] and clearance<=.075 and half!=gait_half and contact_age>=.14 and position.distance_to(last_contact)>.18:
			foot_armed[side]=false;gait_half=half;last_contact=position;contact_age=0
			ground_samples[side]={"height":hit.position.y,"normal":hit.normal,"at":hit.position}
			contact_evidence={"foot":at,"ground":hit.position,"clearance":clearance,"clip":last_clip,"phase":animation.current_animation_position/animation.current_animation_length}
			make_contact(side=="L")

func make_contact(left:bool)->void:
	var pressure:float=(1.23 if sprinting else (.72 if crouching else 1.0))*(.88+get_parent().survival.weight()/60.0)
	var side:="L" if left else "R"
	var at:Vector3=ground_samples.get(side,{}).get("at",global_position+visual.basis.x*(.13 if left else -.13))
	var surface:String=snow_world.surface_at(at)
	# Contact on raised props must not stamp the snow underneath the object.
	if absf(at.y-snow_world.terrain_height(at.x,at.z))<.18:
		var bone:=skeleton.find_bone("foot."+side)
		var rest:Basis=skeleton.get_bone_global_rest(bone).basis
		var forward:Vector3=skeleton.global_basis*skeleton.get_bone_global_pose(bone).basis*rest.inverse()*Vector3.FORWARD
		snow_world.stamp_snow(at,atan2(-forward.x,-forward.z),pressure,left)
	else:snow_world.last_sole.erase(left)
	footfall.emit(surface,pressure,left)

func leave_footprint()->void:
	# Footfall and indentation are emitted together from the animation's gait phase.
	last_footprint=position

func sample_ground()->void:
	if skeleton==null:return
	for side in ["L","R"]:
		var bone:=skeleton.find_bone("foot."+side)
		var at:Vector3=skeleton.global_transform*skeleton.get_bone_global_pose(bone).origin
		var hit:=foot_ground(at)
		if not hit.is_empty():ground_samples[side]={"height":hit.position.y,"normal":hit.normal,"at":hit.position}
		else:ground_samples.erase(side)

func foot_ground(at:Vector3)->Dictionary:
	var ray:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.5,at-Vector3.UP*.9)
	ray.exclude=[get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(ray)

func clear_footprints()->void:
	super.clear_footprints()
	if is_instance_valid(snow_world):snow_world.clear_tracks()
	last_contact=position;gait_half=-1
	ground_samples.clear()
	foot_armed={"L":true,"R":true};contact_age=1.0;contact_evidence.clear()
	if is_instance_valid(feet_modifier):feet_modifier.corrections.clear();feet_modifier.contact_normals.clear();feet_modifier.authored_rotations.clear()
