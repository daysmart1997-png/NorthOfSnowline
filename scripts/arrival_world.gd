extends Node3D
const Catalog=preload("res://scripts/arrival_catalog.gd")
var world
var stocks:Dictionary={}
var satchels:Dictionary={}
func build(w)->void:
 world=w;name="SouthApproach"
 for id in Catalog.SITES:building(id)
 for id in Catalog.SUPPLIES:
  var data:Dictionary=Catalog.SUPPLIES[id];var root:Node3D=world.buildings[data.site]
  var pile:=Node3D.new();pile.name=id;root.add_child(pile);pile.position=data.at
  var bag=world.box(Vector3(0,-.03,0),Vector3(.75,.07,.47),"676451",false,pile)
  var flap=world.box(Vector3(0,.04,-.20),Vector3(.75,.12,.12),"676451",false,pile);satchels[id]=flap
  bag.name="SupplyMat";stocks[id]={};var index:=0
  for item in data.contents:
   var nodes:Array[Node3D]=[]
   for n in range(int(data.contents[item])):
    var model:Node3D=load("res://assets/arrival/item_"+item+".glb").instantiate();pile.add_child(model)
    model.position=Vector3((index%3-1)*.27,0,(index/3)*.18);model.rotation.y=.20*(index-1)
    if id=="lodge_stores":
     # Real remaining fuel sits on the lower shelf; small dry goods stay on top.
     model.position=Vector3((n-1)*.43,-.68,0) if item=="wood" else Vector3(-.15 if item=="bandage" else .16,0,0)
     model.rotation.y=PI*.5 if item=="wood" else 0.0
    nodes.append(model);index+=1
   stocks[id][item]=nodes
  world.points.append({"id":id,"kind":"supply","position":pile.global_position+Vector3(0,.12,.15),"title":"翻找 · "+data.title,"node":null})
 for row in [["gate_route","gatehouse",Vector3(-.55,1.15,-2.15)],["lodge_route","lodge",Vector3(.23,1.73,-2.65)]]:
  var at:Vector3=world.buildings[row[1]].global_position+row[2]
  world.points.append({"id":row[0],"kind":"clue","position":at,"title":"查看 · 路线便笺","node":null})
 # Authored tree banks leave the approach, doorway and fork sight lines open.
 var rng_state=world.rng.state;world.rng.seed=91126
 for side in [-1,1]:
  for z in range(44,141,6):
   var x:float=side*(23+world.rng.randf_range(0,9))
   world.tree(Vector3(x,world.terrain_height(x,z),z),world.rng.randf_range(.8,1.2))
 for at in [Vector2(5,121),Vector2(-4,99),Vector2(-20,61),Vector2(16,86),Vector2(10,52)]:
  world.rock(Vector3(at.x,world.terrain_height(at.x,at.y),at.y),.7)
 for at in [Vector2(-10,126),Vector2(-12,137),Vector2(14,129),Vector2(17,118),Vector2(8,94),Vector2(-17,90),Vector2(12,58)]:
  world.tree(Vector3(at.x,world.terrain_height(at.x,at.y),at.y),.95)
 world.rng.state=rng_state
 # Two restrained direction boards, at decisions rather than house nameplates.
 for data in [[Vector3(1,0,115),"避风 →"],[Vector3(-1,0,91),"炉屋 ↖"]]:
  var at:Vector3=data[0];at.y=world.terrain_height(at.x,at.z)
  world.box(at+Vector3(0,.7,0),Vector3(.12,1.4,.12),"514a3c",true,self)
  world.box(at+Vector3(0,1.28,0),Vector3(1.1,.27,.09),"625b4c",false,self)
  var lettering=world.sign_text(data[1],at+Vector3(0,1.28,.055),22,self);lettering.pixel_size=.005;lettering.outline_size=0;lettering.modulate=Color("bbb7a4")

func building(id:String)->void:
 var d:Dictionary=Catalog.SITES[id];var at:Vector3=d.at;at.y=world.terrain_height(at.x,at.z)+.14
 var root:Node3D=load(d.get("path","res://assets/arrival/"+d.asset+".glb")).instantiate();root.position=at;root.name="Cabin_"+id;world.add_child(root);world.apply_building_materials(root);world.buildings[id]=root
 var w:float=d.half_width;var depth:float=d.half_depth;var hidden:Array[Node3D]=[]
 for key in ["Roof","CutawayFront","CutawayRight"]:hidden.append(root.find_child(key,true,false))
 world.cutaways.append({"at":at,"nodes":hidden,"half_width":w+.25,"half_depth":depth+.25})
 world.invisible_wall(at+Vector3(0,-.07,0),Vector3(w*2,.14,depth*2))
 for side in [-1,1]:
  world.invisible_wall(at+Vector3(side*w,1.3,0),Vector3(.16,2.6,depth*2))
  world.invisible_wall(at+Vector3(side*(w+.65)/2,1.3,depth),Vector3(w-.65,2.6,.16))
 world.invisible_wall(at+Vector3(0,1.3,-depth),Vector3(w*2,2.6,.17))
 for bounds in d.obstacles:world.invisible_wall(at+bounds[0],bounds[1])
 for bounds in d.get("exterior_obstacles",[]):world.invisible_wall(at+bounds[0],bounds[1])
 # Low continuous ramp, no vertical step at the sill.
 var ramp:=StaticBody3D.new();var collider:=CollisionShape3D.new();var shape:=ConvexPolygonShape3D.new();var verts:=PackedVector3Array()
 for x in [-.65,.65]:
  for p in [Vector2(depth,0),Vector2(depth+1,-.18),Vector2(depth,-.25),Vector2(depth+1,-.25)]:verts.append(at+Vector3(x,p.y,p.x))
 shape.points=verts;collider.shape=shape;ramp.add_child(collider);world.add_child(ramp)
 var deck=world.box(Vector3(0,-.10,depth+.45),Vector3(1.28,.06,.95),"625b4c",false,root);deck.rotation.x=.17
 var ambient:=OmniLight3D.new();ambient.position=Vector3(0,2,0);ambient.omni_range=6;ambient.light_color=Color("96a6ac");ambient.light_energy=.35;ambient.light_cull_mask=d.layer|8;root.add_child(ambient)
 if d.heat:
  var flame:MeshInstance3D=root.find_child("FireWindow",true,false);flame.visible=false;world.fire_meshes[id]=flame
  var light:=OmniLight3D.new();light.position=Vector3(2.35,1.2,-1.4);light.light_color=Color("ffc18a");light.light_energy=0;light.omni_range=6;light.light_cull_mask=d.layer|8;root.add_child(light);world.fire_lights[id]=light
  world.add_point(id,"fire",at+Vector3(2.35,.7,-1.35),"旧炉 · 添柴取暖")
 if d.bed:world.add_point(id+"_bed","rest",at+Vector3(-2.55,.7,.15),"简陋卧铺 · 预估休息")
 # Buildings are discovered on entry; their separate route papers are inspectable clues.
 world.pois.append({"id":id,"title":d.title,"at":at,"story":d.description,"enter":true})

func sync(state)->void:
 for id in stocks:
  for item in stocks[id]:
   var used:int=int(state.supply_taken.get(id,{}).get(item,0))
   for i in range(stocks[id][item].size()):stocks[id][item][i].visible=i>=used
  satchels[id].rotation.x=-.8 if state.discovered.has("searched_"+id) else 0.0
