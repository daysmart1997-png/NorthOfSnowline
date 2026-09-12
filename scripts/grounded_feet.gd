extends SkeletonModifier3D
var player:CharacterBody3D
var terrain:Node3D
var corrections:Dictionary={}
var contact_normals:Dictionary={}
var authored_rotations:Dictionary={}
var adjustments:=0

func _process_modification()->void:
	var skel:=get_skeleton()
	if not is_instance_valid(player) or not player.enabled or not player.is_on_floor():return
	if player.last_clip not in ["Idle","Walk","Run","CrouchIdle","CrouchWalk"]:return
	player.sample_ground()
	var transform:=skel.global_transform
	for side in ["L","R"]:
		var hip:=skel.find_bone("thigh."+side);var knee:=skel.find_bone("shin."+side);var foot:=skel.find_bone("foot."+side)
		if mini(hip,mini(knee,foot))<0:continue
		var h:=skel.get_bone_global_pose(hip);var k:=skel.get_bone_global_pose(knee);var f:=skel.get_bone_global_pose(foot)
		authored_rotations[side]=f.basis.get_rotation_quaternion()
		var sample:Dictionary=player.ground_samples.get(side,{})
		if sample.is_empty():continue
		var shift:float=clampf(float(sample.height)-player.global_position.y,-.22,.22)
		var filtered:float=lerpf(float(corrections.get(side,shift)),shift,clampf(get_physics_process_delta_time()*15,0,1));corrections[side]=filtered
		var target:=f.origin+transform.basis.inverse()*Vector3(0,filtered,0)
		var l1:=h.origin.distance_to(k.origin);var l2:=k.origin.distance_to(f.origin)
		var axis:Vector3=(target-h.origin).normalized();var distance:=clampf(target.distance_to(h.origin),.12,l1+l2-.001)
		target=h.origin+axis*distance
		# Preserve the authored knee plane, including turning and running.
		var authored:=k.origin-h.origin
		var bend:Vector3=authored-axis*authored.dot(axis)
		if bend.length_squared()<.000001:
			bend=Vector3.FORWARD-axis*Vector3.FORWARD.dot(axis)
		bend=bend.normalized()
		var along:float=(l1*l1-l2*l2+distance*distance)/(2*distance)
		var joint:Vector3=h.origin+axis*along+bend*sqrt(maxf(0,l1*l1-along*along))
		var h_rotation:=Quaternion((k.origin-h.origin).normalized(),(joint-h.origin).normalized())
		var k_rotation:=Quaternion((f.origin-k.origin).normalized(),(target-joint).normalized())
		h.basis=Basis(h_rotation)*h.basis;k.basis=Basis(k_rotation)*k.basis;k.origin=joint
		var ground_normal:Vector3=(transform.basis.inverse()*Vector3(sample.normal)).normalized()
		var smoothed:Vector3=Vector3(contact_normals.get(side,ground_normal)).lerp(ground_normal,clampf(get_physics_process_delta_time()*12,0,1)).normalized()
		contact_normals[side]=smoothed
		var alignment:=Quaternion(Vector3.UP,smoothed)
		var planted:float=clampf(1.0-maxf(0,f.origin.y-.19)/.10,0,1)
		f.basis=Basis(Quaternion.IDENTITY.slerp(alignment,.65*planted))*f.basis;f.origin=target
		skel.set_bone_global_pose(hip,h);skel.set_bone_global_pose(knee,k);skel.set_bone_global_pose(foot,f)
		adjustments+=1
	player.update_foot_contacts()
