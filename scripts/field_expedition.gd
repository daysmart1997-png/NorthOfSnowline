extends Node3D
const Animal=preload("res://scripts/wild_animal.gd")
const Sheet=preload("res://scripts/character_sheet.gd")
const Feedback=preload("res://scripts/bow_feedback.gd")
const ARROW_STEP:=1.0/60.0
const GRAVITY:=Vector3(0,-5,0)
var game
var animals:Array=[]
var projectiles:Array=[]
var recoveries:Array=[]
var job:Dictionary={}
var progress:=0.0
var cooldown:=0.0
var aim_time:=0.0
var loaded:=false
var last_health:=100.0
var appearance_clock:=0.0
var cough_clock:=40.0
var fall_speed:=0.0
var audio:AudioStreamPlayer
var held:Node3D
var held_signature:=""
var tracks:MultiMeshInstance3D
var track_index:=0
var feedback:Control
var draw_audio:AudioStreamPlayer
var release_audio:AudioStreamPlayer
var drawing:=false
var presence_cooldown:=0.0
var draw_weapon:=""

func setup(main)->void:
 game=main;name="FieldExpedition"
 audio=AudioStreamPlayer.new();audio.bus="SnowEffects";audio.volume_db=-25;add_child(audio)
 draw_audio=AudioStreamPlayer.new();draw_audio.bus="SnowEffects";draw_audio.volume_db=-12;draw_audio.stream=load("res://assets/audio/bow_draw.wav");add_child(draw_audio)
 release_audio=AudioStreamPlayer.new();release_audio.bus="SnowEffects";release_audio.volume_db=-12;release_audio.stream=load("res://assets/audio/bow_release.wav");add_child(release_audio)
 feedback=Feedback.new();feedback.field=self;game.canvas.add_child(feedback)
 var w=game.world
 w.add_loot("field_medical",Vector3(2.3,.24,14.8),"小屋急救盒",{"bandage":2,"medicine":1,"knife":1})
 w.add_loot("field_gloves",Vector3(-11,0,-46),"周岑的备用衣袋",{"dry_gloves":1,"wool_cap":1})
 w.add_loot("field_hunt",Vector3(25,0,-64),"猎人的工具卷",{"bow":1,"arrow":4,"knife":1})
 w.add_loot("field_clothes",Vector3(2.3,.24,-173.2),"维修站衣柜",{"wind_coat":1,"lined_boots":1,"medicine":2})
 w.add_loot("field_rifle",Vector3(-17,0,-129),"护林器材箱 · 稀缺猎枪",{"rifle":1,"ammo":3})
 for point in w.points:
  if not point.id.begins_with("field_"):continue
  var room:String=w.shelter_at(point.position)
  var layer:int=int(game.interior_view.ROOMS.get(room,1))
  for visual in point.node.find_children("*","VisualInstance3D",true,false):visual.layers=layer
 # Breadcrumbs teach the safe eastern route before the western wolf territory.
 for p in [Vector3(7,0,-91),Vector3(9,0,-114)]:
  p.y=w.terrain_height(p.x,p.z)
  var root:=Node3D.new();w.add_child(root);root.position=p
  w.box(Vector3(0,.75,0),Vector3(.12,1.5,.12),"615346",true,root)
  w.box(Vector3(0,1.35,0),Vector3(1.0,.28,.08),"b8af94",false,root)
 held=Node3D.new();game.player.visual.add_child(held);held.position=Vector3(.32,1.02,-.25)
 tracks=MultiMeshInstance3D.new();add_child(tracks);tracks.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var multimesh:=MultiMesh.new();multimesh.transform_format=MultiMesh.TRANSFORM_3D
 var mark:=CylinderMesh.new();mark.top_radius=1;mark.bottom_radius=1;mark.height=.008;mark.radial_segments=8
 var material:=StandardMaterial3D.new();material.albedo_color=Color("5d7180");material.roughness=1;mark.material=material
 multimesh.mesh=mark;multimesh.instance_count=192
 for i in range(192):multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
 tracks.multimesh=multimesh

func track(at:Vector3,yaw:float,species:String)->void:
 if game.world.surface_at(at)=="ice":return
 for side in [-1,1]:
  var p:Vector3=at+Vector3(side*.17,0,0).rotated(Vector3.UP,yaw);p.y=game.world.terrain_height(p.x,p.z)+.008
  var radius:=.07 if species=="bear" else .042
  tracks.multimesh.set_instance_transform(track_index%192,Transform3D(Basis(Vector3.UP,yaw).scaled(Vector3(radius,1,radius*1.4)),p));track_index+=1

func reset()->void:
 presence_cooldown=0
 shutdown_spatial_audio()
 cancel_aim()
 feedback.traces.clear();feedback.preview.clear()
 release_audio.stop()
 track_index=0
 if tracks!=null:
  for i in range(192):tracks.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO))
 for a in animals:remove_child(a);a.queue_free()
 animals.clear()
 for p in projectiles:p.mesh.queue_free()
 for p in recoveries:p.mesh.queue_free()
 projectiles.clear();recoveries.clear();job={};loaded=false;cooldown=0;last_health=game.survival.health
 for at in game.survival.kit.arrows:
  var mesh:=rod(self,Vector3.ZERO,Vector3(0,0,-.55),.009,Color("9e805e"));mesh.position=Vector3(at[0],at[1],at[2]);recoveries.append({"mesh":mesh})
 for f in game.survival.kit.flights:
  var mesh:=rod(self,Vector3.ZERO,Vector3(0,0,-.55),.009,Color("9e805e"));mesh.position=Vector3(f.position[0],f.position[1],f.position[2])
  projectiles.append({"mesh":mesh,"velocity":Vector3(f.velocity[0],f.velocity[1],f.velocity[2]),"age":float(f.age)})
 for row in [["deer_0","deer",Vector3(25,0,-72),false],["deer_1","deer",Vector3(31,0,-120),false],["wolf_0","wolf",Vector3(-12,0,-105),false],["wolf_1","wolf",Vector3(-17,0,-116),false],["bear_0","bear",Vector3(-51,0,-154),false],["carcass_0","deer",Vector3(18,0,-54),true]]:
  var at:Vector3=safe_spawn(row[2]);at.y=game.world.terrain_height(at.x,at.z)+.04
  var a=Animal.new();a.setup(self,row[0],row[1],at,row[3]);add_child(a);animals.append(a)
 update_held()

func safe_spawn(origin:Vector3)->Vector3:
 var shape:=SphereShape3D.new();shape.radius=.85
 for i in range(25):
  var at:Vector3=origin+Vector3(cos(i*2.4),0,sin(i*2.4))*.32*i
  at.y=game.world.terrain_height(at.x,at.z)
  var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*1.1);query.exclude=[game.player.get_rid()]
  if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return at
 return origin

func clear_line(a:Vector3,b:Vector3,exclude:Array)->bool:
 var query:=PhysicsRayQueryParameters3D.create(a,b,1);query.exclude=exclude
 return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func nearest_carcass():
 for a in animals:
  if a.hp<=0 and (a.meat>0 or a.hide_count>0) and a.position.distance_to(game.player.position)<2.5:return a
 return null

func interaction()->bool:
 if not job.is_empty():job={};game.notify("已中止操作；已完成的取肉保留。");return true
 for arrow in recoveries:
  if arrow.mesh.position.distance_to(game.player.position)<2:
   if game.survival.weight()+.06>game.survival.MAX_WEIGHT:game.notify("背包已满。");return true
   game.survival.items.arrow=game.survival.count("arrow")+1
   arrow.mesh.queue_free();recoveries.erase(arrow);save_arrows();game.notify("回收猎箭 ×1。");return true
 var carcass=nearest_carcass()
 if carcass!=null:
  game.notify(start_job("harvest",carcass.animal_id));return true
 return false

func start_job(kind:String,id:String)->String:
 var s=game.survival;var shelter:String=game.world.shelter_at(game.player.position)
 var seconds:=10.0;var title:="";var problem:=""
 if not job.is_empty():return "先完成或取消当前操作。"
 match kind:
  "dry":
   seconds=15;title="烘干衣物"
   if not s.kit.owned.has(id):return "衣物不存在。"
   if s.kit.owned[id].wet<=0:return "衣物已经干燥。"
   if float(s.fires.get(shelter,0))<seconds:return "需要足够的炉火，先在火炉旁添柴。"
  "mend":
   seconds=10;title="修补衣物"
   if not s.kit.owned.has(id):return "衣物不存在。"
   if s.kit.owned[id].condition>=100:return "衣物完好，无需修补。"
   if s.count("cloth")<1:return "缺少布料 ×1。"
   if shelter.is_empty():return "先到庇护所再修补。"
  "craft":
   if not s.RECIPES.has(id):return "未知配方。"
   problem=s.recipe_problem(id,shelter,false)
   if not problem.is_empty():return problem
   seconds=float(s.RECIPES[id].get("minutes",5));title=s.RECIPES[id].name
   if s.RECIPES[id].get("fire",false) and float(s.fires.get(shelter,0))<seconds+1:return "炉火撑不到完成，先添柴再制作。"
  "harvest":
   if s.count("knife")<=0:return "需要小刀；小屋急救盒或猎人营地可以找到。"
   var a=find_animal(id)
   if a==null or a.hp>0 or a.position.distance_to(game.player.position)>2.5:return "靠近动物遗骸再取肉。"
   if a.meat<=0 and a.hide_count<=0:return "已经取尽。"
   if s.weight()+(.5 if a.meat>0 else .8)>s.MAX_WEIGHT:return "背包余量不足，先减轻负重。"
   seconds=10 if a.meat>0 else 20;title="取肉 0.5 kg" if a.meat>0 else "收取生皮"
  "module":
   if s.kit.module_ready:return "模块已测试，可以取下。"
   seconds=[3.0,4.0,2.5][mini(s.kit.route_stage,2)];title=["擦净氧化接点","固定松脱导线","按下测试 · 观察指针"][mini(s.kit.route_stage,2)]
  _:return "未知操作。"
 job={"kind":kind,"id":id,"duration":seconds,"origin":game.player.position,"shelter":shelter,"title":title,"health":s.health};progress=0
 game.backpack.visible=false;game.active=true;game.player.enabled=true;game.player.velocity=Vector3.ZERO
 game.player.play_action("Interact")
 return "%s · %d 分钟；移动或 E 取消"%[title,seconds]

func finish_job()->void:
 var done:=job.duplicate();job={};var s=game.survival;var message:=""
 match done.kind:
  "dry":
   if s.kit.owned.has(done.id) and float(s.fires.get(done.shelter,0))>0:s.kit.owned[done.id].wet=maxf(0,float(s.kit.owned[done.id].wet)-50);message="衣物已烘干一段，保暖正在恢复。"
  "mend":
   if s.count("cloth")>0 and s.kit.owned.has(done.id):s.items.cloth=s.count("cloth")-1;s.kit.owned[done.id].condition=minf(100,float(s.kit.owned[done.id].condition)+35);message="已修补衣物。"
  "craft":message=s.craft(done.id,done.shelter)
  "module":
   s.kit.route_stage=mini(3,s.kit.route_stage+1);s.kit.module_ready=s.kit.route_stage>=3
   game.experience.module_completed(s.kit.route_stage)
   message="指针稳定，测试通过。按 E 取下模块。" if s.kit.module_ready else "这一步已完成。按 E 继续检查。"
  "harvest":
   var a=find_animal(done.id)
   if a!=null and a.hp<=0 and (a.meat>0 or a.hide_count>0):
    var item:String="raw_meat" if a.meat>0 else "hide"
    if s.weight()+float(s.ITEMS[item].weight)<=s.MAX_WEIGHT:
     s.items[item]=s.count(item)+1
     if a.meat>0:a.meat-=1
     else:a.hide_count-=1
     a.save_state();message="获得%s ×1。E 继续，或先带回烹饪。"%s.ITEMS[item].name
    else:message="背包已满，取肉中止。"
 game.notify(message if not message.is_empty() else "条件已经变化，操作没有完成。")

func find_animal(id:String):
 for a in animals:
  if a.animal_id==id:return a
 return null

func save_arrows()->void:
 game.survival.kit.arrows=[]
 for arrow in recoveries:
  var p:Vector3=arrow.mesh.position;game.survival.kit.arrows.append([p.x,p.y,p.z])

func hurt_player(amount:float,part:String)->void:
 var s=game.survival;var gear:Dictionary=s.kit.owned[s.kit.equipped[part]]
 s.health=maxf(0,s.health-amount*.8);gear.condition=maxf(0,float(gear.condition)-18)
 s.kit.add_condition("wound",part,18);job={};game.notify("%s受伤，衣物破损 · B → 人物 → 身体处理"%s.kit.SLOTS[part])

func noise(at:Vector3,radius:float)->void:
 for a in animals:
  if a.hp>0 and a.position.distance_to(at)<radius:a.last_known=at;a.memory=7;a.alert=maxf(a.alert,.6)

func animal_sound(kind:String,at:Vector3=Vector3.INF)->void:
 var wav:=AudioStreamWAV.new();wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate=22050
 var length:=.65 if kind=="cough" else .9
 var bytes:=PackedByteArray();var n:=int(22050*length);bytes.resize(n*2)
 var random:=RandomNumberGenerator.new();random.seed=53;var smooth:=0.0
 for i in range(n):
  var t:=float(i)/22050;smooth=lerpf(smooth,random.randf_range(-1,1),.15)
  var envelope:=sin(PI*float(i)/n)
  if kind=="cough":envelope*=pow(maxf(0,sin(t*29)),3)
  var value:=smooth*.5+sin(t*TAU*(76 if kind=="bear" else 112))*.25
  bytes.encode_s16(i*2,int(value*envelope*6500))
 wav.data=bytes
 if at.is_finite():
  if kind in ["wolf","bear"] and at.distance_to(game.player.position)<32:game.cassette.alert_seconds=3.0
  var voice:=AudioStreamPlayer3D.new();voice.bus="SnowEffects";voice.volume_db=-11;voice.max_distance=32;voice.unit_size=7
  add_child(voice);voice.global_position=at+Vector3.UP;voice.stream=wav;voice.finished.connect(voice.queue_free);voice.play()
 else:audio.stream=wav;audio.play()

func update_held()->void:
 var signature:String=game.survival.kit.weapon+str(game.survival.count(game.survival.kit.weapon)>0)
 if signature==held_signature:return
 cancel_aim()
 held_signature=signature
 for child in held.get_children():held.remove_child(child);child.queue_free()
 var weapon:String=game.survival.kit.weapon
 held.visible=game.survival.count(weapon)>0
 if not held.visible:return
 if weapon=="bow":
  for i in range(10):
   var a:=-1.3+i*.26;var b:=a+.26
   rod(held,Vector3(cos(a)*.18-.1,sin(a)*.45,0),Vector3(cos(b)*.18-.1,sin(b)*.45,0),.018,Color("806046"))
  rod(held,Vector3(-.052,-.434,0),Vector3(-.052,.434,0),.004,Color("bfc4b0"))
 elif weapon=="rifle":
  rod(held,Vector3(0,0,.18),Vector3(0,0,-.7),.028,Color("3d4245"));rod(held,Vector3(0,-.04,.28),Vector3(0,-.04,-.15),.055,Color("71513c"))
 else:rod(held,Vector3.ZERO,Vector3(0,0,-.22),.025,Color("c5c9c7"))

func rod(parent:Node3D,a:Vector3,b:Vector3,radius:float,color:Color)->MeshInstance3D:
 var mesh:=MeshInstance3D.new();var shape:=CylinderMesh.new();shape.top_radius=radius;shape.bottom_radius=radius;shape.height=a.distance_to(b);shape.radial_segments=6;mesh.mesh=shape
 var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=.85;mesh.material_override=mat;parent.add_child(mesh);mesh.position=(a+b)*.5
 if parent==held:mesh.layers=8
 mesh.quaternion=Quaternion(Vector3.UP,(b-a).normalized());return mesh

func _unhandled_input(event:InputEvent)->void:
 if not game.active:return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.physical_keycode==KEY_Q:
   var choices:Array=[]
   for id in ["knife","bow","rifle"]:
    if game.survival.count(id)>0:choices.append(id)
   if not choices.is_empty():game.survival.kit.weapon=choices[(choices.find(game.survival.kit.weapon)+1)%choices.size()];update_held();game.notify("持用 "+game.survival.ITEMS[game.survival.kit.weapon].name)
  if event.physical_keycode==KEY_R and game.survival.kit.weapon=="rifle" and game.survival.count("ammo")>0 and not loaded and cooldown<=0:cooldown=1.6;loaded=true;game.notify("装填中…")
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:fire()

func aim_point()->Vector3:
 var camera=game.player.camera;var mouse:=get_viewport().get_mouse_position();var origin:Vector3=camera.project_ray_origin(mouse);var direction:Vector3=camera.project_ray_normal(mouse)
 var q:=PhysicsRayQueryParameters3D.create(origin,origin+direction*180,5);q.exclude=[game.player.get_rid()]
 var hit:=get_world_3d().direct_space_state.intersect_ray(q)
 return hit.position if not hit.is_empty() else game.player.position-game.player.visual.global_basis.z*8

func fire()->void:
 if game.map.visible:return
 shoot(aim_point(),Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))

func cancel_aim()->void:
 aim_time=0;drawing=false;draw_weapon=""
 if draw_audio!=null:draw_audio.stop()

func update_aim(delta:float,pressed:bool)->void:
 var s=game.survival
 var weapon:String=s.kit.weapon
 var allowed:bool=game.active and not game.map.visible and job.is_empty() and s.count(weapon)>0 and weapon in ["bow","rifle"] and cooldown<=0
 if not allowed or not pressed or (weapon=="bow" and s.count("arrow")<=0):cancel_aim();return
 if draw_weapon!=weapon:cancel_aim()
 if not drawing:
  drawing=true;draw_weapon=weapon
  if weapon=="bow":draw_audio.play()
 aim_time=minf(1,aim_time+delta)
 var toward:Vector3=aim_point()-game.player.position
 game.player.visual.rotation.y=atan2(-toward.x,-toward.z)

func arrow_velocity(target:Vector3)->Vector3:
 return (target-(game.player.position+Vector3.UP*1.05)).normalized()*lerpf(15,29,clampf(aim_time,0,1))

func arrow_hit(a:Vector3,b:Vector3)->Dictionary:
 var q:=PhysicsRayQueryParameters3D.create(a,b,5);q.exclude=[game.player.get_rid()]
 return get_world_3d().direct_space_state.intersect_ray(q)

func predict_arrow(target:Vector3)->PackedVector3Array:
 var at:Vector3=game.player.position+Vector3.UP*1.05
 var velocity:=arrow_velocity(target)
 var points:=PackedVector3Array([at])
 for i in range(300):
  var next:=at+velocity*ARROW_STEP+GRAVITY*.5*ARROW_STEP*ARROW_STEP
  var hit:=arrow_hit(at,next)
  if not hit.is_empty():points.append(hit.position);break
  at=next;velocity+=GRAVITY*ARROW_STEP
  if i%4==3:points.append(at)
 return points

func context_text()->String:
 if not job.is_empty():return "%s · %d%%   /   移动或 E 取消"%[job.title,100*progress/job.duration]
 if nearest_carcass()!=null:return "[ E ] 分批取肉 · 每份 0.5 kg / 10 分钟"
 return ""

func shoot(target:Vector3,aiming:bool)->void:
 var s=game.survival;var weapon:String=s.kit.weapon
 if not game.active or game.map.visible or cooldown>0 or not job.is_empty() or s.count(weapon)<=0:return
 var origin:Vector3=game.player.position+Vector3.UP*1.05;var direction:Vector3=(target-origin).normalized()
 if weapon=="knife":
  cooldown=.65
  for a in animals:
   if a.hp>0 and a.position.distance_to(game.player.position)<1.8 and (a.position-game.player.position).normalized().dot(Vector3(direction.x,0,direction.z).normalized())>.25 and clear_line(origin,a.position+Vector3.UP*.5,[game.player.get_rid(),a.get_rid()]):a.hit(12,game.player.position);break
 elif not aiming:game.notify("按住右键瞄准，再按左键。");return
 elif weapon=="rifle":
  if not loaded:game.notify("按 R 装填，弹药 %d 发。"%s.count("ammo"));return
  if s.count("ammo")<=0:loaded=false;return
  s.items.ammo=s.count("ammo")-1;loaded=false;cooldown=.8;noise(origin,60);animal_sound("rifle")
  var q:=PhysicsRayQueryParameters3D.create(origin,origin+direction*90,5);q.exclude=[game.player.get_rid()]
  var hit:=get_world_3d().direct_space_state.intersect_ray(q)
  if not hit.is_empty() and hit.collider is Animal:hit.collider.hit(85,game.player.position)
 elif weapon=="bow":
  if s.count("arrow")<=0:game.notify("没有猎箭。可在制作页修制。");return
  s.items.arrow=s.count("arrow")-1;cooldown=.7;noise(origin,5)
  var mesh:=rod(self,Vector3.ZERO,Vector3(0,0,-.55),.009,Color("9e805e"));mesh.position=origin
  projectiles.append({"mesh":mesh,"velocity":arrow_velocity(target),"age":0.0})
  cancel_aim();release_audio.play()
 game.player.play_action("Interact")

func _process(delta:float)->void:
 if game==null or not game.started:return
 for voice in get_children():
  if voice is AudioStreamPlayer3D:voice.stream_paused=not game.active
 if not game.active:cancel_aim();return
 var s=game.survival
 cooldown=maxf(0,cooldown-delta)
 presence_cooldown=maxf(0,presence_cooldown-delta)
 update_aim(delta,Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT))
 if game.world.shelter_at(game.player.position).is_empty():s.kit.exposure(delta,game.world.snow_depth(game.player.position),game.player.velocity.length()>.15,s.storm())
 if game.player.is_on_floor():
  if fall_speed< -8:
   s.kit.add_condition("sprain","feet",25);game.notify("落地扭伤双脚 · 减负并到人物页处理。");job={}
  fall_speed=0
 else:fall_speed=minf(fall_speed,game.player.velocity.y)
 appearance_clock-=delta
 if appearance_clock<=0:appearance_clock=1;Sheet.apply_clothes(game.player.visual,s.kit);update_held()
 cough_clock-=delta
 if cough_clock<=0:
  cough_clock=45
  if s.kit.has_condition("cough"):animal_sound("cough");game.notify("咳嗽 · 人物页可查看身体状态。");noise(game.player.position,5)
 if s.temperature<16 and not s.kit.has_condition("cough"):s.kit.add_condition("cough","torso",12)
 if not job.is_empty():
  if game.player.position.distance_to(job.origin)>.25 or s.health<float(job.health)-.2:job={};game.notify("操作中止，先确保周围安全。")
  else:
   progress+=delta
   if game.player.action_time<=0:game.player.play_action("Interact")
   if progress>=float(job.duration):finish_job()

func _physics_process(delta:float)->void:
 if game==null or not game.started or not game.active:return
 var s=game.survival
 for p in projectiles.duplicate():
  var previous:Vector3=p.mesh.position
  var next:Vector3=previous+p.velocity*delta+GRAVITY*.5*delta*delta
  p.velocity+=GRAVITY*delta;p.age+=delta
  var hit:=arrow_hit(previous,next)
  feedback.add_trace(previous,hit.position if not hit.is_empty() else next)
  if not hit.is_empty():
   if hit.collider is Animal:hit.collider.hit(38,game.player.position)
   p.mesh.position=hit.position;recoveries.append({"mesh":p.mesh});projectiles.erase(p)
   if recoveries.size()>64:recoveries[0].mesh.queue_free();recoveries.remove_at(0)
   save_arrows()
  elif p.age>5:p.mesh.queue_free();projectiles.erase(p)
  else:p.mesh.position=next;p.mesh.look_at(next+p.velocity)
 s.kit.flights=[]
 for p in projectiles:
  var at:Vector3=p.mesh.position;var v:Vector3=p.velocity
  s.kit.flights.append({"position":[at.x,at.y,at.z],"velocity":[v.x,v.y,v.z],"age":p.age})

func shutdown_spatial_audio()->void:
 for voice in get_children():
  if voice is AudioStreamPlayer3D:
   voice.stream_paused=false;voice.stop();voice.stream=null;voice.queue_free()

func _exit_tree()->void:
 shutdown_spatial_audio()
