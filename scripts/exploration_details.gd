extends Node
# Visual state derives from Expedition.collected/discovered; no second save store.
const Chapter=preload("res://scripts/chapter_one.gd")
const CABINET="station_cabinet"
const CONTENTS={"wood":1,"cloth":1}
var game
var doors:Array[Node3D]=[]
var door_collisions:Array[CollisionShape3D]=[]
var stock:Node3D
var cloths:Array[Node3D]=[]
var cloth_rest:Array[Vector3]=[]
var clock:=0.0

func setup(main)->void:
 game=main;name="ExplorationDetails"
 var station:Node3D=game.world.buildings.station
 doors.assign([station.find_child("CabinetDoorLeft",true,false),station.find_child("CabinetDoorRight",true,false)])
 for i in range(doors.size()):
  var body:=StaticBody3D.new();body.name="OpenDoorCollision";doors[i].add_child(body)
  var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(1.12,1.97,.06)
  collision.shape=shape;collision.position=Vector3(.59 if i==0 else -.59,1.06,0);collision.disabled=true
  body.add_child(collision);door_collisions.append(collision)
 stock=station.find_child("CabinetStock",true,false)
 game.world.points.append({"id":CABINET,"kind":"cabinet","position":Vector3(-.35,1.25,-173.12),"title":"搜寻 · 零件柜","node":null})
 add_clue("departure_trace",Vector3(-3.48,1.30,17.80))
 add_clue("wind_trace",Vector3(14,.90,-25))
 for root in game.world.find_children("TrailCloth*","Node3D",true,false):
  for child in root.get_children():
   if child is MeshInstance3D and child.position.x>.05:
    cloths.append(child);cloth_rest.append(child.rotation)
 sync(true)

func add_clue(id:String,at:Vector3)->void:
 game.world.points.append({"id":id,"kind":"clue","position":at,"title":"查看 · "+Chapter.CLUES[id].title,"node":null,"story":Chapter.CLUES[id].text})
 game.world.pois.append({"id":id,"title":Chapter.CLUES[id].title,"at":at,"story":Chapter.CLUES[id].text,"inspect":true})

func search()->String:
 var s=game.survival
 var was_collected:bool=s.collected.has(CABINET)
 var result:String=s.loot(CABINET,CONTENTS)
 if not was_collected and s.collected.has(CABINET):
  Chapter.discover(s,"cabinet_note")
  game.experience.sound("cabinet_open")
 return result

func sync(immediate:=false)->void:
 var opened:bool=game.survival.collected.has(CABINET)
 stock.visible=not opened
 for i in range(doors.size()):
  var goal:float=(-1.08 if i==0 else 1.08) if opened else 0.0
  doors[i].rotation.y=goal if immediate else move_toward(doors[i].rotation.y,goal,get_process_delta_time()*2.2)
  door_collisions[i].set_deferred("disabled",not opened or absf(doors[i].rotation.y-goal)>.02)

func _process(delta:float)->void:
 if game==null:return
 sync()
 if not game.active:return
 clock+=delta
 var strength:float=game.survival.storm()
 for i in range(cloths.size()):
  cloths[i].rotation=cloth_rest[i]+Vector3(sin(clock*(3+strength*4)+i)*(.035+strength*.15),strength*.65,sin(clock*2+i)*.045)
 # A returning player can read wind-driven cloth more clearly as the weather rises.
 if game.survival.parts and strength>.35 and game.player.position.distance_to(Vector3(5,0,-16))<8 and not game.survival.discovered.has("return_wind"):
  Chapter.discover(game.survival,"return_wind")
  game.notify("布条被风拉直了。铁路迎风，东侧树后还能缓一口气。")
