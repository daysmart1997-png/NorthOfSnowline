extends SceneTree
func _initialize()->void:call_deferred("inspect")
func inspect()->void:
	var model=load("res://assets/characters/ranger_supplied_v3.glb").instantiate();root.add_child(model)
	var skel:Skeleton3D=model.find_children("*","Skeleton3D",true,false)[0]
	var anim:AnimationPlayer=model.find_children("*","AnimationPlayer",true,false)[0]
	for side in ["L","R"]:
		print("REST ",side," ",skel.get_bone_global_rest(skel.find_bone("foot."+side)))
	for name in anim.get_animation_list():
		if not ("Walk" in name or "Run" in name):continue
		var length:float=anim.get_animation(name).length
		anim.play(name,0)
		for i in range(21):
			anim.seek(length*i/20.0,true)
			var foot:Transform3D=skel.get_bone_global_pose(skel.find_bone("foot.L"))
			print(name," ",i/20.0," ",foot.origin)
	model.free();quit()
