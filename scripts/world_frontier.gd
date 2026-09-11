extends "res://scripts/world_polish.gd"
const Terrain=preload("res://scripts/terrain_profile.gd")
const BuildingLayouts=preload("res://scripts/building_layouts.gd")
var buildings:Dictionary={}
var last_sole:Dictionary={}
var building_materials:Dictionary={}
var biome_texture:ImageTexture
var arrival
const Arrival=preload("res://scripts/arrival_catalog.gd")

func terrain_height(x:float,z:float)->float:return Terrain.height(x,z)
func snow_depth(at:Vector3)->float:return Terrain.snow(at.x,at.z)
func slope_at(at:Vector3)->float:return Terrain.slope(at.x,at.z)
func normal_at(at:Vector3)->Vector3:return Terrain.normal(at.x,at.z)

func tree(at:Vector3,scale_value:float)->void:
	if Terrain.lake_weight(at.x,at.z)>.6:return
	super.tree(at,scale_value)
	# Consume the original random draws, then keep the vehicle's immediate site clear.
	if absf(at.x+14)<3.0 and absf(at.z+43)<3.5:
		var obstruction:Node=get_child(get_child_count()-1)
		remove_child(obstruction);obstruction.queue_free()

func terrain_name(at:Vector3)->String:
	if Terrain.lake_weight(at.x,at.z)>.8:return "冻湖 · 冰面"
	if snow_depth(at)>.32:return "背风低洼 · 深雪"
	if terrain_height(at.x,at.z)>3:return "林区高地"
	if slope_at(at)>.2:return "起伏坡地"
	return "林间雪道"

func travel_factor(at:Vector3,motion:Vector3)->float:
	var depth:=snow_depth(at)
	var uphill:=maxf(0,-normal_at(at).dot(motion.normalized()))
	return clampf(1-depth*.38-uphill*.26,.62,1)

func shelter_at(at:Vector3)->String:
	for id in Arrival.SITES:
		var d:Dictionary=Arrival.SITES[id]
		if absf(at.x-d.at.x)<d.half_width-.12 and absf(at.z-d.at.z)<d.half_depth-.10:return id
	if absf(at.x)<float(BuildingLayouts.DATA.station.half_width)-.2 and absf(at.z+170)<3.8:return "station"
	return super.shelter_at(at)

func surface_at(at:Vector3)->String:
	if shelter_at(at) in ["home","station","gatehouse","lodge"]:return "wood"
	if absf(at.x)<1.5 and ((at.z>22 and at.z<25.0) or (at.z> -166 and at.z< -163)):return "wood"
	if absf(at.x)<2.4 and absf(at.z+86)<9.3:return "wood"
	if Terrain.lake_weight(at.x,at.z)>.8:return "ice"
	return "deep" if snow_depth(at)>.28 else "snow"

func _ready()->void:
	super._ready()
	# Tiny flakes should not project dozens of hard rectangular shadows onto snow.
	snow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bridge:Node3D=load("res://assets/architecture/bridge.glb").instantiate();bridge.name="TimberTrestleBridge";bridge.position=Vector3(0,0,-86);add_child(bridge);apply_building_materials(bridge)
	invisible_wall(Vector3(0,.025,-86),Vector3(4.8,.19,18.7))
	for x in [-2.2,2.2]:invisible_wall(Vector3(x,.68,-86),Vector3(.18,1.3,18.5))
	for side in [-1,1]:
		var ramp:=StaticBody3D.new();var collision:=CollisionShape3D.new();var shape:=ConvexPolygonShape3D.new();var vertices:=PackedVector3Array()
		for x in [-2.4,2.4]:
			for p in [Vector2(9.3,.12),Vector2(10.4,0),Vector2(9.3,-.2),Vector2(10.4,-.2)]:vertices.append(Vector3(x,p.y,-86+side*p.x))
		shape.points=vertices;collision.shape=shape;ramp.add_child(collision);add_child(ramp)
		var ramp_mesh:=SurfaceTool.new();ramp_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		for p in [Vector3(-2.4,.12,9.3),Vector3(2.4,.12,9.3),Vector3(-2.4,0,10.4),Vector3(2.4,.12,9.3),Vector3(2.4,0,10.4),Vector3(-2.4,0,10.4)]:ramp_mesh.add_vertex(Vector3(p.x,p.y,-86+p.z*side))
		ramp_mesh.generate_normals();var deck:=MeshInstance3D.new();deck.mesh=ramp_mesh.commit();deck.material_override=mat("665f50");add_child(deck)
	pois.append_array([
		{"id":"ridge","title":"西岭高地","at":Vector3(-34,terrain_height(-34,-36),-36),"story":"风把岭脊的雪吹得很薄。从这里能认出冻湖与旧桥，返程时也能望见小屋。"},
		{"id":"hollow","title":"背风洼地","at":Vector3(40,terrain_height(40,-43),-43),"story":"雪在洼地里积得更厚，靴子会拖出两道沟痕。绕到高处更省力。"},
		{"id":"lake","title":"白桦冻湖","at":Vector3(-28,-1.65,-89),"story":"冰层封住了湖湾。东侧的旧木桥连接两岸，桥脚还能看出林场的铁件与石墩。"}
	])
	add_loot("ridge_cache",Vector3(-32,0,-35),"高地巡林员的补给",{"food":2,"cloth":2,"tea":1})
	add_loot("hollow_cache",Vector3(38,0,-43),"陷在深雪中的背包",{"herb":2,"wood":2})
	add_loot("lake_cache",Vector3(-13,0,-72),"湖畔的旧木箱",{"battery":1,"scrap":2})

	var evidence=preload("res://scripts/trail_details.gd").new();add_child(evidence);evidence.build(self)
	# Authored cabin grove uses its own seed; existing loot/world placement stays stable.
	var saved_rng_state:=rng.state
	rng.seed=90731
	for at in Terrain.CabinSnow.TREES:
		tree(Vector3(at.x,terrain_height(at.x,at.z),at.z),rng.randf_range(.78,1.02))
	rng.state=saved_rng_state
	add_cabin_dressing()
	apply_building_materials(get_node("PostalVan"))
	var pass_scene=preload("res://scripts/mountain_pass.gd").new();add_child(pass_scene);pass_scene.build(self)
	arrival=preload("res://scripts/arrival_world.gd").new();add_child(arrival);arrival.build(self)

func add_cabin_dressing()->void:
	var placements:=[
		["fallen_timber",Vector3(-6.3,0,28.0),-.24,Vector3(3.4,.38,1.0)],
		["old_stump",Vector3(5.8,0,29.0),.3,Vector3(.6,.55,.6)],
		["firewood_stack",Vector3(-4.9,0,19.0),0.0,Vector3(1.5,.75,1.1)]
	]
	for placement in placements:
		var at:Vector3=placement[1];at.y=terrain_height(at.x,at.z)-.07
		var prop:Node3D=load("res://assets/props/"+placement[0]+".glb").instantiate()
		prop.name="CabinDressing_"+placement[0];prop.position=at;prop.rotation.y=placement[2];add_child(prop);apply_building_materials(prop)
		var body:=StaticBody3D.new();var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new()
		shape.size=placement[3];collision.shape=shape;collision.position.y=shape.size.y*.4;body.add_child(collision);prop.add_child(body)

func build_terrain()->void:
	super.build_terrain()
	detail_mesh.custom_aabb=AABB(Vector3(-12,-5,-12),Vector3(24,20,24))
	var image:=Image.create(441,761,false,Image.FORMAT_RG8)
	for z in range(761):
		for x in range(441):
			var px:float=-110+x*.5;var pz:float=-225+z*.5
			image.set_pixel(x,z,Color(Terrain.snow(px,pz)/.65,Terrain.lake_weight(px,pz),0))
	biome_texture=ImageTexture.create_from_image(image)
	for material in [snow_surface,detail_surface]:material.set_shader_parameter("biomes",biome_texture)

func box(at:Vector3,extent:Vector3,color:String,collision:=false,parent:Node3D=self)->MeshInstance3D:
	var replaced:bool=parent.name=="ShelterRepairs" or (is_equal_approx(at.x,-2.7) and is_equal_approx(at.z,20.5)) or (is_equal_approx(at.x,-2.5) and is_equal_approx(at.z,17))
	var object:=super.box(at,extent,color,collision and not replaced,parent)
	# Replaced by actual lake terrain, trestle bridge and imported cabin furnishings.
	if (extent.x>170 and absf(at.z+86)<.1) or (extent.x==5.0 and extent.z==16.0):object.visible=false
	if is_equal_approx(extent.x,4.5) and is_equal_approx(extent.z,28):object.visible=false
	if parent.name=="ShelterRepairs":object.visible=false
	if is_equal_approx(at.x,-2.7) and is_equal_approx(at.z,20.5):object.visible=false
	if (is_equal_approx(at.x,-2.5) and is_equal_approx(at.z,17)) or (is_equal_approx(at.x,-2.3) and is_equal_approx(at.z,16.76)):object.visible=false
	return object

func add_pickup(id:String,kind:String,at:Vector3,title:String)->void:
	if id!="radio_parts":super.add_pickup(id,kind,at,title);return
	# Authored anchor places the compact module on the thick bench
	# without burying its underside or covering the repair feedback.
	var socket:Node3D=buildings.station.find_child("ModulePickup",true,false)
	super.add_pickup(id,kind,socket.global_position,title)
	var root:Node3D=points.back().node
	for mesh in root.get_children():
		if mesh is MeshInstance3D:
			mesh.scale=Vector3(.68,.5,.5);mesh.position*=Vector3(.68,.5,.5)

func add_loot(id:String,at:Vector3,title:String,contents:Dictionary)->void:
	var root:Node3D=load("res://assets/architecture/supply_crate.glb").instantiate()
	root.name="Supply_"+id;root.position=Vector3(at.x,maxf(terrain_height(at.x,at.z),at.y),at.z);add_child(root);apply_building_materials(root)
	var body:=StaticBody3D.new();body.name="SupplyCollision";root.add_child(body)
	var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(.86,.53,.65)
	collision.shape=shape;collision.position.y=.265;body.add_child(collision)
	var marker:=sign_text("◇",Vector3(0,.95,0),25,root);marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED;marker.modulate=Color("d3b684")
	points.append({"id":id,"kind":"loot","position":root.position+Vector3(0,.6,0),"title":title,"node":root,"contents":contents})

func refresh_pickups(collected:Array)->void:
	super.refresh_pickups(collected)
	for point in points:
		if point.kind!="loot" or not is_instance_valid(point.node):continue
		for collision in point.node.find_children("*","CollisionShape3D",true,false):
			collision.set_deferred("disabled",collected.has(point.id))

func apply_building_materials(root:Node3D)->void:
	for node in root.find_children("*","MeshInstance3D",true,false):
		for i in range(node.mesh.get_surface_count()):
			var original:Material=node.mesh.surface_get_material(i)
			if original is StandardMaterial3D and original.resource_name.begins_with("Timber"):
				var key:String=original.resource_name
				if not building_materials.has(key):
					var material:=ShaderMaterial.new();material.shader=load("res://assets/shaders/timber.gdshader");material.set_shader_parameter("timber_color",original.albedo_color);material.set_shader_parameter("floorboards",key.contains("Floor"));material.set_shader_parameter("horizontal_boards",key.begins_with("TimberWorkshop"));building_materials[key]=material
				node.set_surface_override_material(i,building_materials[key])
			elif original is StandardMaterial3D and original.resource_name in ["IronOxide","WaxedCanvas","CanvasPatch","BlanketWool","PostalPaint"]:
				var key:String=original.resource_name
				if not building_materials.has(key):
					var material:=ShaderMaterial.new();material.shader=load("res://assets/shaders/field_surface.gdshader")
					material.set_shader_parameter("base_color",original.albedo_color);material.set_shader_parameter("metal",key in ["IronOxide","PostalPaint"]);building_materials[key]=material
				node.set_surface_override_material(i,building_materials[key])
			elif original is StandardMaterial3D and original.resource_name == "SnowCap":
				# Runtime material override preserves the authored GLB/Blender assets.
				if not building_materials.has("SnowCap"):
					var snow_cap := ShaderMaterial.new()
					snow_cap.shader = load("res://assets/shaders/roof_snow.gdshader")
					snow_cap.set_shader_parameter("powder_normal",load("res://assets/textures/snow004/Snow004_1K-PNG_NormalGL.png"))
					snow_cap.set_shader_parameter("powder_roughness",load("res://assets/textures/snow004/Snow004_1K-PNG_Roughness.png"))
					building_materials["SnowCap"] = snow_cap
				node.set_surface_override_material(i,building_materials["SnowCap"])

func cabin(at:Vector3,id:String,_color:String,_title:String)->void:
	var layout:Dictionary=BuildingLayouts.DATA[id]
	var half_width:float=layout.half_width
	var root:Node3D=load("res://assets/architecture/"+str(layout.asset)+".glb").instantiate();root.name="Cabin_"+id;root.position=at+Vector3(0,.24,0);add_child(root);apply_building_materials(root);buildings[id]=root
	var nodes:Array[Node3D]=[]
	for key in ["Roof","CutawayFront","CutawayRight"]:
		var child:Node3D=root.find_child(key,true,false)
		if child:nodes.append(child)
	cutaways.append({"at":at,"nodes":nodes,"half_width":half_width+.4})
	invisible_wall(at+Vector3(0,.20,0),Vector3(half_width*2+.2,.08,8.2))
	invisible_wall(at+Vector3(-half_width,1.8,0),Vector3(.25,3.4,8))
	invisible_wall(at+Vector3(half_width,1.8,0),Vector3(.25,3.4,8))
	invisible_wall(at+Vector3(0,1.8,-4),Vector3(half_width*2,3.4,.25))
	for side in [-1,1]:invisible_wall(at+Vector3(side*(half_width+.94)/2,1.8,4.05),Vector3(half_width-.94,3.4,.27))
	for x in [-1.35,1.35]:invisible_wall(at+Vector3(x,.91,4.92),Vector3(.15,1.4,1.60))
	invisible_wall(at+Vector3(0,.20,4.8),Vector3(2.7,.08,1.8))
	# A shallow continuous entrance ramp follows the model's porch, avoiding a capsule-catching step.
	var ramp:=StaticBody3D.new();var collider:=CollisionShape3D.new();var shape:=ConvexPolygonShape3D.new()
	var ramp_points:=PackedVector3Array()
	for x in [-1.35,1.35]:
		for p in [Vector2(5.65,.24),Vector2(6.8,0),Vector2(5.65,-.1),Vector2(6.8,-.1)]:ramp_points.append(at+Vector3(x,p.y,p.x))
	shape.points=ramp_points;collider.shape=shape;ramp.add_child(collider);add_child(ramp)
	var ramp_mesh:=SurfaceTool.new();ramp_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in [Vector3(-1.35,.24,5.65),Vector3(1.35,.24,5.65),Vector3(-1.35,0,6.8),Vector3(1.35,.24,5.65),Vector3(1.35,0,6.8),Vector3(-1.35,0,6.8)]:ramp_mesh.add_vertex(at+p)
	ramp_mesh.generate_normals();var visible_ramp:=MeshInstance3D.new();visible_ramp.mesh=ramp_mesh.commit();visible_ramp.material_override=mat("584f40");add_child(visible_ramp)
	# The targeted asset builder exports matching room/furniture dimensions.
	for obstruction in layout.obstructions:
		var center:Array=obstruction[0];var size:Array=obstruction[1]
		invisible_wall(at+Vector3(center[0],center[1],center[2]),Vector3(size[0],size[1],size[2]))
	var storage_body:=StaticBody3D.new();storage_body.name="StorageCollision";root.add_child(storage_body)
	var storage_shape:=CollisionShape3D.new();var bounds:=BoxShape3D.new();bounds.size=Vector3(1.22,.81,.84);storage_shape.shape=bounds;storage_shape.position=Vector3(2.4,.405,2.4);storage_shape.disabled=true;storage_body.add_child(storage_shape)
	if id=="station":
		var equipment:Node3D=load("res://assets/architecture/station_equipment.glb").instantiate();equipment.name="StationLineEquipment";equipment.position=at+Vector3(1.25,0,0);add_child(equipment);apply_building_materials(equipment)
		invisible_wall(at+Vector3(5.60,2.8,-3),Vector3(.23,5.6,.23))
		invisible_wall(at+Vector3(6.10,.46,-1.8),Vector3(.8,.85,.74))
	var flame:MeshInstance3D=root.find_child("FireWindow",true,false);flame.visible=false;fire_meshes[id]=flame
	var light:=OmniLight3D.new();light.position=Vector3(2.6,1.5,-1.3);light.light_color=Color("ffc18a");light.omni_range=7;light.light_energy=0;root.add_child(light);fire_lights[id]=light
	var lamp:=OmniLight3D.new();lamp.position=Vector3(.5,2.2,1.8);lamp.light_color=Color("dfb783");lamp.light_energy=.8;lamp.omni_range=7;root.add_child(lamp)
	# Interior light does not illuminate outdoor snow through closed walls.
	# Room/actor bits match InteriorView; the visible porch lantern owns its pool.
	var room_layer:=2 if id=="home" else 4
	light.light_cull_mask=room_layer | 8;lamp.light_cull_mask=room_layer | 8
	var porch_lamp:=OmniLight3D.new();porch_lamp.name="PorchLantern"
	porch_lamp.position=Vector3(1.31,2.10,4.48);porch_lamp.light_color=Color("eab278")
	porch_lamp.light_energy=.65;porch_lamp.omni_range=4.6
	porch_lamp.light_cull_mask=1 | room_layer | 8 | 32;root.add_child(porch_lamp)
	add_point(id,"fire",at+Vector3(2.6,1.0,-1.35),"铸铁炉 · 添柴")
	# Identify buildings by silhouette and interior, never a floating nameplate.

func make_tent(at:Vector3,id:String,parent:Node3D)->void:
	var root:Node3D=load("res://assets/architecture/camp.glb").instantiate();root.name="CanvasCamp_"+id;root.position=at;parent.add_child(root);apply_building_materials(root)
	var roof:Node3D=root.find_child("CampRoof",true,false);camp_roofs[id]=roof;camp_positions[id]=at
	var flame:MeshInstance3D=root.find_child("FireBed",true,false);flame.visible=false;fire_meshes[id]=flame
	var light:=OmniLight3D.new();light.position=Vector3(1.1,1,2.65);light.light_color=Color("ffc080");light.omni_range=7;root.add_child(light);fire_lights[id]=light
	add_point(id,"fire",at+Vector3(1.1,.6,2.2),"营火 · 添柴煮水")
	for x in [-2.1,2.1]:
		var wall:=StaticBody3D.new();var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new()
		shape.size=Vector3(.18,1,1.0);collision.shape=shape;wall.position=Vector3(x,.5,-2.15);wall.add_child(collision);root.add_child(wall)
	add_flames(id)

func sync_buildings(state)->void:
	super.sync_buildings(state)
	for id in buildings:
		if Arrival.SITES.has(id):continue
		for pair in [["UpgradeBed","bed"],["StorageChest","storage"],["WindowRepairs","insulation"]]:
			var node:Node3D=buildings[id].find_child(pair[0],true,false)
			if node:node.visible=id=="home" and bool(state.upgrades[pair[1]])

		var storage_collision:CollisionShape3D=buildings[id].get_node("StorageCollision").get_child(0)
		storage_collision.set_deferred("disabled",not (id=="home" and state.upgrades.storage))

func stamp_snow(at:Vector3,yaw:float,pressure:float,left:bool)->float:
	var depth:=snow_depth(at)
	if depth<.005 or surface_at(at) in ["ice","wood"]:last_sole.erase(left);return 0.0
	var grade:=slope_at(at)
	var compression:=minf(depth*.85,clampf(depth*.40*pressure*(1+minf(grade,.6)*.30),.003,.17))
	if depth>.30 and last_sole.has(left):
		var previous:Vector2=last_sole[left];var current:=Vector2(at.x,at.z)
		var distance:=previous.distance_to(current)
		if distance>.12 and distance<2.6:
			var middle:=previous.lerp(current,.5)
			if Terrain.snow(middle.x,middle.y)>.28:
				track_marks.append({"kind":"drag","at":current,"from":previous,"depth":compression*.30,"age":0.0,"yaw":yaw,"left":left})
	track_marks.append({"kind":"boot","at":Vector2(at.x,at.z),"yaw":yaw,"depth":compression,"age":0.0,"left":left})
	# A thin path breaks a deep-snow drag trail; do not bridge a cleared crossing.
	if depth>.30:last_sole[left]=Vector2(at.x,at.z)
	else:last_sole.erase(left)
	while track_marks.size()>240:track_marks.pop_front()
	track_dirty=true;return compression

func clear_tracks()->void:
	super.clear_tracks();last_sole.clear()

func paint_tracks()->void:
	# Base painter handles the individual boot depressions; grooves use a swept boot volume.
	var all:=track_marks
	track_marks=all.filter(func(p:Dictionary)->bool:return p.get("kind","boot")=="boot")
	super.paint_tracks();track_marks=all
	for stamp in track_marks:
		if stamp.get("kind","")!="drag":continue
		var a:Vector2=(stamp.from-patch_center)*32+Vector2(384,384);var b:Vector2=(stamp.at-patch_center)*32+Vector2(384,384)
		var fade:=1.0-smoothstep(60,240,stamp.age)
		var delta:=b-a;var length_sq:=maxf(delta.length_squared(),.01)
		for y in range(maxi(0,int(minf(a.y,b.y))-6),mini(768,int(maxf(a.y,b.y))+7)):
			for x in range(maxi(0,int(minf(a.x,b.x))-6),mini(768,int(maxf(a.x,b.x))+7)):
				var p:=Vector2(x,y);var t:=clampf((p-a).dot(delta)/length_sq,0,1)
				var meander:Vector2=Vector2(-delta.y,delta.x).normalized()*sin(t*TAU)*.45
				var radius:float=p.distance_to(a+delta*t+meander)/32
				var core:=1.0-smoothstep(.025,.115,radius);var rim:=smoothstep(.092,.12,radius)*(1-smoothstep(.12,.16,radius))
				var value:float=(stamp.depth*core*(.5+.5*sin(t*PI))-rim*.008)*fade;var old:=track_image.get_pixel(x,y).r
				track_image.set_pixel(x,y,Color(maxf(old,value) if value>0 else (minf(old,value) if old<=0 else old),0,0))
	track_texture.update(track_image)
