extends Node
# Presentation and first-time guidance. Expedition remains the sole state owner.
const Chapter=preload("res://scripts/chapter_one.gd")
var game
var cue:AudioStreamPlayer
var listener:AudioListener3D
var module_root:Node3D
var contact:MeshInstance3D
var cable:MeshInstance3D
var needle:MeshInstance3D
var needle_pivot:Node3D
var last_room:=""
var calm_time:=0.0
var advice_wait:=4.0
var last_stage:=-1
var milestone_events:Array[Dictionary]=[]

func setup(main)->void:
 game=main;name="ChapterExperience"
 listener=AudioListener3D.new();listener.name="PlayerHearing";game.player.pivot.add_child(listener);listener.make_current()
 game.cassette.shutdown_requested.connect(shutdown)
 game.cassette.shutdown_requested.connect(game.field.shutdown_spatial_audio)
 var readout=preload("res://scripts/module_readout.gd").new();readout.name="ModuleReadout";readout.game=game;readout.mouse_filter=Control.MOUSE_FILTER_IGNORE;game.canvas.add_child(readout)
 cue=AudioStreamPlayer.new();cue.bus="SnowEffects";cue.volume_db=-19;add_child(cue)
 module_root=Node3D.new();module_root.name="ModuleFeedback";game.world.add_child(module_root)
 var surface:Node3D=game.world.buildings.station.find_child("ModuleSurface",true,false)
 module_root.global_position=surface.global_position
 contact=piece(Vector3(-.15,0,0),Vector3(.18,.018,.11),"80775f")
 cable=piece(Vector3(.08,.01,.01),Vector3(.24,.018,.024),"76614b")
 piece(Vector3(.0,.02,-.16),Vector3(.26,.02,.16),"c3c3ac")
 needle_pivot=Node3D.new();module_root.add_child(needle_pivot);needle_pivot.position=Vector3(0,.038,-.14)
 needle=piece(Vector3(0,0,-.055),Vector3(.012,.008,.11),"303b3c",needle_pivot)
 reset()

func piece(at:Vector3,size:Vector3,color:String,parent:Node3D=null)->MeshInstance3D:
 var mesh:MeshInstance3D=game.world.box(at,size,color,false,module_root if parent==null else parent)
 mesh.layers=4;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 return mesh

func reset()->void:
 last_room="";calm_time=0;advice_wait=4;last_stage=-1;milestone_events.clear()
 if cue!=null:cue.stop()
 if game.cassette!=null:game.cassette.cue_seconds=12;game.cassette.alert_seconds=0

func sound(id:String)->void:
 cue.stream=load("res://assets/audio/chapter/"+id+".wav");cue.play()

func module_completed(stage:int)->void:
 sound(["contact","wire","test"][clampi(stage-1,0,2)])
 milestone_events.append({"event":"module_%d"%stage,"elapsed":game.survival.elapsed})

func radio_event(step:int)->void:
 sound("radio_received" if step==4 else "radio_connect")
 if step==4:game.cassette.cue_seconds=16

static func advice(s,shelter:String)->Dictionary:
 if s.kit.has_condition("wound"):return {"id":"wound","text":"伤口正在消耗健康 · B → 人物 → 身体，用绷带处理。"}
 if s.temperature<30:return {"id":"cold","text":"先停止赶路 · 到屋内添柴取暖；背风处只能减缓失温。"}
 if s.thirst<20:return {"id":"thirst","text":"缺水影响恢复和步速 · B → 随身物品 → 饮用水；有炉火可融雪。"}
 if s.kit.has_condition("sprain"):return {"id":"sprain","text":"扭伤正在拖慢脚步 · 减轻负重，在人物身体页用夹板处理。"}
 if s.hunger<20:return {"id":"hunger","text":"饥饿影响恢复和步速 · 先吃随身口粮，暂缓可选的高地绕行。"}
 if not shelter.is_empty() and s.fires.has(shelter) and s.kit.owned[s.kit.equipped.feet].wet>25:return {"id":"wet","text":"湿靴会带走热量 · 点燃炉火后，B → 人物 → 双脚，烘干衣物。"}
 if s.thirst<35 and s.elapsed<90:return {"id":"first_water","text":"背包里有应急饮水 · B → 随身物品 → 饮用水 → 使用一份。"}
 return {}

func safe_to_save(room:String)->bool:
 var s=game.survival
 if room not in ["home","station","lodge"] or s.health<55 or s.temperature<35 or s.thirst<15 or s.hunger<10:return false
 if float(s.fires.get(room,0))<12 or not game.field.job.is_empty():return false
 for animal in game.field.animals:
  if animal.hp>0 and animal.species in ["wolf","bear"] and animal.alert>.6 and animal.position.distance_to(game.player.position)<20:return false
 return true

func _process(delta:float)->void:
 if game==null or not game.started:return
 var s=game.survival
 module_root.visible=not s.parts
 var stage:int=s.kit.route_stage
 if stage!=last_stage:
  last_stage=stage;contact.material_override=game.world.mat("b9bcb1" if stage>=1 else "80775f")
 cable.rotation.y=0.0 if stage>=2 else .6
 var testing:bool=game.field.job.get("kind","")=="module" and stage==2
 var fraction:float=clampf(game.field.progress/maxf(float(game.field.job.get("duration",1)),.1),0,1) if testing else 0
 needle_pivot.rotation.y=lerpf(-.85,.65,1.0 if stage>=3 else fraction)
 cue.stream_paused=not game.active and not game.story_panel.visible
 if not game.active:return
 var room:String=game.world.shelter_at(game.player.position)
 if room!=last_room:
  calm_time=0
  if not room.is_empty():
   sound("pack_rustle");game.cassette.cue_seconds=14 if s.parts else 8
   milestone_events.append({"event":"enter_"+room,"elapsed":s.elapsed})
  last_room=room
 if s.collected.has("field_gloves") and not s.discovered.has("zhou_gloves"):
  Chapter.discover(s,"zhou_gloves");game.notify("衣袋里有周岑的便笺 · 已收进探索手记")
 if s.count("tape_home")>0 and not s.discovered.has("tape_home_note"):
  Chapter.discover(s,"tape_home_note");game.notify("《归途》盒内夹着一页留言 · 行囊中可展开阅读")
 if s.music_effect()=="tape_embers" and room=="lodge" and not s.discovered.has("embers_notice"):
  s.discovered.append("embers_notice");game.notify("《余烬》的盒盖里有周岑的字。行囊中选中磁带，可以展开留言。")
 advice_wait-=delta
 if advice_wait<=0 and game.toast_time<=0:
  var hint:=advice(s,room)
  if not hint.is_empty() and not s.discovered.has("lesson_"+hint.id):
   s.discovered.append("lesson_"+hint.id);game.notify(hint.text)
  advice_wait=25
 if game.player.velocity.length()<.2 and safe_to_save(room):calm_time+=delta
 else:calm_time=0
 var checkpoint:="checkpoint_"+room+("_rescue" if s.completed else ("_return" if s.parts else "_outward"))
 if calm_time>5 and game.automatic_saves and not s.discovered.has(checkpoint):
  s.discovered.append(checkpoint)
  if not game.save_checkpoint():s.discovered.erase(checkpoint)
  calm_time=0

func shutdown()->void:
 if is_instance_valid(cue):cue.stream_paused=false;cue.stop();cue.stream=null

func _exit_tree()->void:
 shutdown()
