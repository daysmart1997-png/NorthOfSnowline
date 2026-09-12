extends "res://scripts/world.gd"

var pois: Array[Dictionary] = [
	{"id":"home","title":"护林小屋","at":Vector3(0,0,18),"story":"窗缝漏着风，床铺已经破损。找些木柴、布料和废金属，让这里重新成为一个家。"},
	{"id":"wreck","title":"被遗弃的邮递车","at":Vector3(-14,0,-43),"story":"邮递车停在雪里，车身的蓝漆已经褪色。旁边留着寄给七号的包裹。便笺上是周岑的字：“归途这面给你。干手套在工具箱左边，杯子等我回去再还。”"},
	{"id":"hunters","title":"猎人的旧营地","at":Vector3(22,0,-62),"story":"帐棚挡住了风，灰烬早已冷透。石头下压着送药人留下的纸页，旁边留着几根没有烧完的柴。"},
	{"id":"lookout","title":"林道观测点","at":Vector3(28,0,-115),"story":"风吹过断裂的观测仪。箱子里有电池和《步履》，也许能帮你走得更远。"},
	{"id":"depot","title":"废弃物资堆场","at":Vector3(-15,0,-128),"story":"几只木箱埋在雪里。生锈的金属和旧布料，如今比钱更有用。"},
	{"id":"station","title":"北岭维修站","at":Vector3(0,0,-170),"story":"维修间里没有人，床铺与火炉都还在。桌边放着备用模块，旁边压着一张折起的交接单。"}
]
var structure_root:Node3D
var improvement_root:Node3D
var upgrades_signature := ""
var structure_signature := ""
var camp_positions:Dictionary = {}
var camp_roofs:Dictionary = {}
var fire_effects:Dictionary={}

func _ready()->void:
	super._ready()
	structure_root=Node3D.new();structure_root.name="BuiltCamps";add_child(structure_root)
	improvement_root=Node3D.new();improvement_root.name="ShelterRepairs";add_child(improvement_root)
	add_loot("home_supplies",Vector3(5.3,0,23),"门廊里的旧工具箱",{"wood":3,"cloth":5,"scrap":3})
	add_loot("timber_south",Vector3(-7,0,-3),"倒木 · 收集干柴",{"wood":3})
	add_loot("cloth_south",Vector3(12,0,-20),"挂在树上的旧行囊",{"cloth":3,"food":1})
	add_loot("wreck_player",Vector3(-12.4,0,-41),"邮递车里的皮包",{"player":1,"tape_embers":1,"battery":1})
	add_loot("wreck_food",Vector3(-16,0,-44),"旧食品箱",{"food":2,"water":1})
	add_loot("herbs_1",Vector3(15,0,-42),"雪下的干药草",{"herb":3})
	add_loot("hunter_pack",Vector3(-12,0,-44),"寄给七号的包裹",{"cloth":3,"tape_home":1,"herb":2})
	add_loot("hunter_wood",Vector3(25,0,-59),"备用柴堆",{"wood":3})
	add_loot("river_water",Vector3(8,0,-78),"被遗落的水壶",{"water":2})
	add_loot("lookout_case",Vector3(28,0,-113),"观测员的金属盒",{"battery":2,"tape_stride":1,"bandage":1})
	add_loot("depot_crate",Vector3(-16,0,-126),"拆卸过的器材箱",{"scrap":5,"cloth":3})
	add_loot("depot_wood",Vector3(-12,0,-130),"干燥的木板",{"wood":4})
	add_loot("station_rations",Vector3(6,0,-158),"维修工的应急箱",{"food":2,"water":2,"herb":2})
	add_point("workbench","workbench",Vector3(-2.5,.8,20.5),"工作台 · 制作与修缮")
	box(Vector3(-2.7,.4,20.5),Vector3(1.4,.8,.75),"35414a",true)
	add_point("home_bed","rest",Vector3(-2.4,.7,15.8),"床铺 · 休息")
	add_point("station_bed","rest",Vector3(4.12,.7,-168.5),"折叠床 · 休息")
	make_tent(Vector3(22,terrain_height(22,-62),-62),"hunters",self)
	# A distinctive delivery van makes the optional cassette discovery legible.
	var van:Node3D=load("res://assets/architecture/delivery_van.glb").instantiate()
	van.name="PostalVan";van.position=Vector3(-14,terrain_height(-14,-43)-.055,-43);add_child(van)
	# One hull per body section follows the silhouette without invisible mirrors.
	for bounds in [[Vector3(0,.91,.70),Vector3(1.86,1.72,2.40)],[Vector3(0,.77,-1.24),Vector3(1.84,.64,1.43)],[Vector3(0,1.42,-.74),Vector3(1.6,.69,1.05)]]:
		var body:=StaticBody3D.new();var shape:=BoxShape3D.new();shape.size=bounds[1]
		var collision:=CollisionShape3D.new();collision.shape=shape;collision.position=bounds[0];body.add_child(collision);van.add_child(body)

	for x in [-17,-14,-11]:
		box(Vector3(x,terrain_height(x,-128)+.35,-128),Vector3(1.5,.7,1.1),"454b4d",true)
		box(Vector3(x,terrain_height(x,-128)+.74,-128),Vector3(1.6,.08,1.2),"8495a9")
	box(Vector3(29,terrain_height(29,-116)+1.5,-116),Vector3(.2,3,.2),"263b4d",true)
	box(Vector3(29,terrain_height(29,-116)+2.9,-116),Vector3(2,.2,.25),"69798a")
	fence(Vector3(-20,0,-133),4)
	for z in [-5,-36,-101,-142]:
		var log:=box(Vector3(-5,.26,z),Vector3(2.8,.38,.45),"3b3c41");log.rotation.y=.35
		box(Vector3(-5,.48,z),Vector3(2.7,.12,.32),"889aad")
	for id in fire_lights:add_flames(id)

func add_loot(id:String,at:Vector3,title:String,contents:Dictionary)->void:
	var root:=Node3D.new();root.position=Vector3(at.x,terrain_height(at.x,at.z),at.z);add_child(root)
	box(Vector3(0,.23,0),Vector3(.85,.46,.62),"4e4b43",false,root)
	box(Vector3(0,.48,0),Vector3(.9,.05,.66),"8797a8",false,root)
	for x in [-.28,.28]:box(Vector3(x,.25,.32),Vector3(.05,.46,.035),"273746",false,root)
	var marker:=sign_text("◇",Vector3(0,1,0),25,root);marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED;marker.modulate=Color("d3b684")
	points.append({"id":id,"kind":"loot","position":root.position+Vector3(0,.6,0),"title":title,"node":root,"contents":contents})

func make_tent(at:Vector3,id:String,parent:Node3D)->void:
	var tent:=Node3D.new();tent.position=at;parent.add_child(tent)
	for x in [-1.7,1.7]:
		for z in [-1.7,1.7]:box(Vector3(x,1,z),Vector3(.09,2,.09),"39434a",true,tent)
	var roof:=box(Vector3(0,2.1,0),Vector3(4.2,.09,4.4),"58616b",false,tent);roof.rotation.z=-.12
	camp_roofs[id]=roof
	box(Vector3(0,1,-1.8),Vector3(3.6,1.8,.05),"444d58",false,tent)
	box(Vector3(-.6,.08,-.4),Vector3(1,.15,2),"6f776c",false,tent)
	for i in range(9):
		var angle:=TAU*i/9.0
		var stone:=box(Vector3(1.05+cos(angle)*.48,.11,.8+sin(angle)*.48),Vector3(.25,.21,.25),"374252",false,tent);stone.rotation.y=angle
	box(Vector3(1.05,.12,.8),Vector3(.65,.15,.38),"433b33",false,tent)
	var flame:=cone(Vector3(1.05,.5,.8),.23,.8,"efb061",tent);flame.visible=false
	var glow:=OmniLight3D.new();glow.position=Vector3(1.05,1,.8);glow.light_color=Color("ffb166");glow.omni_range=7;glow.light_energy=0;tent.add_child(glow)
	fire_lights[id]=glow;fire_meshes[id]=flame
	add_point(id,"fire",at+Vector3(1.05,.6,1.3),"营火 · 添入一份木柴")
	camp_positions[id]=at
	add_flames(id)

func add_flames(id:String)->void:
	if fire_effects.has(id):return
	var effect=preload("res://scripts/hearth_effect.gd").new()
	effect.setup(id,fire_meshes[id],fire_lights[id],camp_positions.has(id));fire_effects[id]=effect

func shelter_at(at:Vector3)->String:
	var base:=super.shelter_at(at)
	if not base.is_empty():return base
	for id in camp_positions:
		var p:Vector3=camp_positions[id]
		if absf(at.x-p.x)<1.85 and absf(at.z-p.z)<1.9:return id
	return ""

func candidate_camp(at:Vector3)->Array:
	for offset in [Vector3(4.8,0,0),Vector3(-4.8,0,0),Vector3(0,0,4.8),Vector3(0,0,-4.8)]:
		var p:Vector3=at+offset;p.y=terrain_height(p.x,p.z)
		if camp_spot_valid(p):return [p.x,p.y,p.z]
	return []

func camp_spot_valid(p:Vector3)->bool:
	if absf(p.x)>82 or p.z>39 or p.z< -198 or absf(p.z+86)<12:return false
	if absf(p.x)<3.8 and p.z< -5 and p.z> -170:return false
	if absf(p.x-22)<2.8 and p.z< -15 and p.z> -150:return false
	for poi in pois:
		if p.distance_to(poi.at)<10:return false
	for pos in camp_positions.values():
		if p.distance_to(pos)<9:return false
	for offset in [Vector2(-2,-2),Vector2(2,-2),Vector2(-2,2),Vector2(2,2)]:
		if absf(terrain_height(p.x+offset.x,p.z+offset.y)-p.y)>.35:return false
	var query:=PhysicsShapeQueryParameters3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(4.6,1.8,4.6);query.shape=shape;query.transform.origin=p+Vector3(0,1.4,0)
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func sync_buildings(state)->void:
	var sig:=JSON.stringify(state.structures)
	if sig!=structure_signature:
		structure_signature=sig
		for node in structure_root.get_children():structure_root.remove_child(node);node.queue_free()
		points=points.filter(func(p:Dictionary)->bool:return not str(p.id).begins_with("camp_"))
		for id in camp_positions.keys():
			if str(id).begins_with("camp_"):camp_positions.erase(id);camp_roofs.erase(id);fire_lights.erase(id);fire_meshes.erase(id);fire_effects.erase(id)
		for structure in state.structures:
			var p:Array=structure.position
			make_tent(Vector3(p[0],p[1],p[2]),structure.id,structure_root)
	var up_sig:=JSON.stringify(state.upgrades)
	if up_sig!=upgrades_signature:
		upgrades_signature=up_sig
		for node in improvement_root.get_children():improvement_root.remove_child(node);node.queue_free()
		if state.upgrades.insulation:
			for x in [-2.6,2.6]:
				for y in [1.45,1.75,2.05]:box(Vector3(x,y,22.32),Vector3(1.24,.19,.07),"826f53",false,improvement_root)
		if state.upgrades.bed:
			box(Vector3(-2.4,.65,15.8),Vector3(1.5,.2,2),"677c74",false,improvement_root)
			box(Vector3(-2.4,.8,15.1),Vector3(1.1,.15,.45),"b4b1a0",false,improvement_root)
		if state.upgrades.storage:
			box(Vector3(2.4,.4,20.4),Vector3(1.2,.8,.8),"736147",true,improvement_root)
			box(Vector3(2.4,.83,20.4),Vector3(1.3,.08,.86),"8a7b60",false,improvement_root)

func weather_update(storm:float,at:Vector3,fires:Dictionary,elapsed:=0.0)->void:
	# Ensure legacy saves lacking a camp fire still render safely.
	var all_fires:=fires.duplicate()
	for id in fire_lights:
		if not all_fires.has(id):all_fires[id]=0.0
	super.weather_update(storm,at,all_fires,elapsed)
	for id in camp_roofs:camp_roofs[id].visible=shelter_at(at)!=id
	for id in fire_effects:fire_effects[id].sync(float(all_fires.get(id,0)),elapsed,storm)
