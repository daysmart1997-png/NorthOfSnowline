extends Node3D
# Visible evidence for the opening's closed road, at the expanded southern map edge.
func build(world)->void:
	name="SouthRoadClosure";position.z=90
	var clusters:=[Vector3(-5,.95,47.3),Vector3(-3.1,1.8,47.8),Vector3(-1,2.6,48.6),Vector3(1.5,2.0,47.7),Vector3(4,1.6,48.4),Vector3(5.5,1.1,46.7),Vector3(-1.7,.8,45.8),Vector3(2.4,.85,45.6)]
	for i in range(clusters.size()):
		var position_data:Vector3=clusters[i];var height:float=position_data.y
		var at:=Vector3(position_data.x,world.terrain_height(position_data.x,position_data.z+position.z)-.10,position_data.z)
		var ring:=PackedVector3Array();var radius:float=1.1+height*.34
		for j in range(7):
			var angle:float=j*TAU/7+i*1.37
			ring.append(Vector3(cos(angle)*radius*(.86+.12*sin(j*3.7+i)),height*(.52+.16*sin(j*2.1+i)),sin(angle)*radius*.80))
		var crown:=Vector3(.16*sin(i),height,.13*cos(i))
		var stone:=SurfaceTool.new();stone.begin(Mesh.PRIMITIVE_TRIANGLES)
		var cover:=SurfaceTool.new();cover.begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in range(7):
			var a:Vector3=ring[j];var b:Vector3=ring[(j+1)%7]
			var low_a:=Vector3(a.x*.88,-.15,a.z*.88);var low_b:=Vector3(b.x*.88,-.15,b.z*.88)
			for v in [a,b,crown,a,low_b,b,a,low_a,low_b]:stone.add_vertex(v)
			# Snow follows the fractured upper planes; no separate circular caps.
			for v in [a,b,crown]:cover.add_vertex(v+Vector3.UP*.035)
		stone.generate_normals();cover.generate_normals()
		var block:=MeshInstance3D.new();block.mesh=stone.commit();block.position=at;block.material_override=world.mat("4a535c");add_child(block);block.create_convex_collision()
		var cap:=MeshInstance3D.new();cap.mesh=cover.commit();cap.material_override=world.building_materials.get("SnowCap",world.mat("a4b5c0"));block.add_child(cap)
	# A broken guardrail and a low closure bar distinguish a road from a rock field.
	for x in [-4.5,4.5]:
		for z in [39.8,42.2,44.6]:
			var y:float=world.terrain_height(x,z+position.z)
			world.box(Vector3(x,y+.56,z),Vector3(.11,1.12,.12),"494e50",true,self)
		var rail=world.box(Vector3(x,world.terrain_height(x,42+position.z)+.86,42),Vector3(.13,.20,4.6),"606b70",false,self)
		if x<0:rail.rotation.x=.10
	for x in [-2.7,2.7]:world.box(Vector3(x,world.terrain_height(x,44+position.z)+.45,44),Vector3(.13,.90,.16),"514b40",true,self)
	world.box(Vector3(0,world.terrain_height(0,44+position.z)+.70,44),Vector3(5.5,.20,.15),"79604b",true,self)
