extends Node3D
const Catalog=preload("res://scripts/arrival_catalog.gd")
const State=preload("res://scripts/arrival_state.gd")
var game
var drops:Dictionary={}
var voices:Array[AudioStreamPlayer3D]=[]
var signature:=""
var serial:=0
func setup(main)->void:
 game=main;name="FieldObjects"
 game.cassette.shutdown_requested.connect(shutdown)
 sync(true)
func sync(force:=false)->void:
 game.world.arrival.sync(game.survival)
 var next:String=JSON.stringify(game.survival.placed_items)
 if next==signature and not force:return
 signature=next
 for node in drops.values():remove_child(node);node.queue_free()
 drops.clear();game.world.points=game.world.points.filter(func(p:Dictionary)->bool:return p.kind!="placed")
 for entry in game.survival.placed_items:
  var model:Node3D=load("res://assets/arrival/item_"+entry.item+".glb").instantiate();add_child(model);model.position=Vector3(entry.position[0],entry.position[1],entry.position[2]);drops[int(entry.id)]=model
  for mesh in model.find_children("*","VisualInstance3D",true,false):mesh.layers=Catalog.room_layer(game.world.shelter_at(model.position))
  game.world.points.append({"id":"placed_%d"%entry.id,"key":int(entry.id),"kind":"placed","position":model.position+Vector3(0,.18,0),"title":"收回 · "+game.survival.ITEMS[entry.item].name,"node":model})
func take(source:String,item:String)->String:
 if not Catalog.SUPPLIES.has(source):return "找不到这处物资。"
 var spec:Dictionary=Catalog.SUPPLIES[source]
 var at:Vector3=game.world.buildings[spec.site].global_position+spec.at
 if game.player.position.distance_to(at)>2.8:return "先靠近这处物资。"
 var before:int=game.survival.count(item);var result:String=State.take_supply(game.survival,source,item)
 if game.survival.count(item)>before:feedback(item,"take",at)
 sync();return result
func place(item:String)->String:
 var s=game.survival
 if item not in Catalog.ITEMS or s.count(item)<=0:return "没有可放下的物资。"
 var space=get_world_3d().direct_space_state
 var at:Vector3=game.player.position
 # Try nearby supported surfaces; do not put an item through a wall or out of bounds.
 var found:=false
 for offset in [Vector3(0,0,.70),Vector3(.70,0,0),Vector3(-.70,0,0),Vector3(0,0,-.70),Vector3.ZERO]:
  var start:Vector3=game.player.position+Vector3(0,.65,0)
  var horizontal:=PhysicsRayQueryParameters3D.create(start,start+offset);horizontal.exclude=[game.player.get_rid()]
  if not offset.is_zero_approx() and not space.intersect_ray(horizontal).is_empty():continue
  var ray:=PhysicsRayQueryParameters3D.create(start+offset,start+offset-Vector3(0,1.5,0));ray.exclude=[game.player.get_rid()]
  var hit:Dictionary=space.intersect_ray(ray)
  if hit.is_empty() or hit.normal.y<.8:continue
  at=hit.position+Vector3(0,.012,0);found=true;break
 if not found:return "附近没有能稳妥放置的表面。"
 var before:int=s.count(item);var result:String=State.place(s,item,at)
 if s.count(item)<before:feedback(item,"place",at)
 sync();return result
func recover(key:int)->String:
 if not drops.has(key) or game.player.position.distance_to(drops[key].position)>2.8:return "先靠近物品。"
 var item:="";var at:Vector3=drops[key].position
 for entry in game.survival.placed_items:
  if entry.id==key:item=entry.item
 var before:int=game.survival.count(item);var result:String=State.recover(game.survival,key)
 if game.survival.count(item)>before:feedback(item,"take",at)
 sync();return result
func feedback(item:String,action:String,at:Vector3=Vector3.INF)->void:
 if item not in Catalog.ITEMS:return
 game.backpack.preview_action=action
 var voice:=AudioStreamPlayer3D.new();voice.bus="SnowEffects";voice.max_distance=14;voice.unit_size=3;voice.volume_db=-12;voice.pitch_scale=1.0+((serial%3)-1)*.035;serial+=1
 voice.stream=load("res://assets/arrival/foley_"+item+".wav");add_child(voice);voice.global_position=game.player.position+Vector3.UP if not at.is_finite() else at;voices.append(voice)
 voice.finished.connect(func():voices.erase(voice);voice.queue_free());voice.play()
 if action=="take":
  var ghost:Node3D=load("res://assets/arrival/item_"+item+".glb").instantiate();add_child(ghost);ghost.global_position=at
  for mesh in ghost.find_children("*","VisualInstance3D",true,false):mesh.layers=8
  var motion=create_tween();motion.set_parallel(true);motion.tween_property(ghost,"global_position",game.player.position+Vector3(0,1,0),.22).set_trans(Tween.TRANS_QUAD);motion.tween_property(ghost,"scale",Vector3.ONE*.05,.22);motion.chain().tween_callback(ghost.queue_free)
func _process(_delta:float)->void:
 if game!=null:game.world.arrival.sync(game.survival)
 for voice in voices:voice.stream_paused=game.menu.visible
func shutdown()->void:
 for voice in voices:
  if is_instance_valid(voice):voice.stop();voice.stream=null
func _exit_tree()->void:shutdown()
