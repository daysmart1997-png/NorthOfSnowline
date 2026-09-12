extends CharacterBody3D
var field
var animal_id:=""
var species:="deer"
var home:=Vector3.ZERO
var hp:=60.0
var meat:=6
var hide_count:=1
var alert:=0.0
var last_known:=Vector3.ZERO
var memory:=0.0
var attack_clock:=-1.0
var recovery:=0.0
var warned:=false
var phase:=0.0
var model:Node3D
var legs:Array=[]
var head:Node3D
var sight_clock:=0.0
var sees:=false
var state:="游荡"
var warning:Label3D
var last_track:=Vector3.ZERO
var returning_home:=false
var fleeing:=false
var detour_time:=0.0
var detour_direction:=Vector3.ZERO
var gait_speed:=0.0
var gait_weight:=0.0
var shins:Array=[]
var leg_rest:Array[Vector3]=[]
var shin_rest:Array[Vector3]=[]
var head_rest:=Vector3.ZERO
var presence_cooldown:=0.0

# A distant cue describes a real living animal, before its detection changes.
# It never grants awareness to the animal or pretends the forest is safe.
func presence_hint()->String:
 if hp<=0 or species=="deer" or alert>.35:return ""
 var p:Vector3=field.game.player.global_position
 if not field.game.world.shelter_at(p).is_empty():return ""
 var offset:Vector3=global_position-p
 if offset.length()<6 or offset.length()>18-field.game.survival.storm()*4:return ""
 var bearing:String=("东" if offset.x>0 else "西") if absf(offset.x)>absf(offset.z) else ("南" if offset.z>0 else "北")
 return "%s侧传来%s的声音。先停下辨认，拉开距离；奔跑会更容易惊动它。"%[bearing,"熊" if species=="bear" else "狼"]

func setup(owner_field,id:String,kind:String,at:Vector3,dead:=false)->void:
 field=owner_field;animal_id=id;species=kind;home=at;position=at
 hp=0 if dead else (140 if species=="bear" else (70 if species=="wolf" else 60));meat=8 if species=="bear" else (6 if species=="deer" else 3)
 name=id;collision_layer=4;collision_mask=1
 var collider:=CollisionShape3D.new();var shape:=CapsuleShape3D.new();shape.radius=.42 if species=="bear" else .24;shape.height=1.3 if species in ["bear","deer"] else .75;collider.shape=shape;collider.position.y=shape.height*.5;add_child(collider)
 model=load("res://assets/wildlife/%s.glb"%species).instantiate();add_child(model)
 for i in range(4):
  var leg:Node3D=model.find_child("Leg%d"%i,true,false)
  var shin:Node3D=model.find_child("Shin%d"%i,true,false)
  legs.append(leg);shins.append(shin)
  leg_rest.append(leg.rotation if leg!=null else Vector3.ZERO)
  shin_rest.append(shin.rotation if shin!=null else Vector3.ZERO)
 head=model.find_child("Head",true,false)
 if head!=null:head_rest=head.rotation
 warning=Label3D.new();warning.billboard=BaseMaterial3D.BILLBOARD_ENABLED;warning.no_depth_test=true;warning.font_size=24;warning.pixel_size=.007;warning.position.y=2.1 if species=="deer" else 1.5;warning.modulate=Color("e2bf88");add_child(warning)
 last_track=position
 if field.game.survival.kit.wildlife.has(id):
  var d:Dictionary=field.game.survival.kit.wildlife[id];hp=d.health;meat=int(d.meat);hide_count=int(d.hide);position=Vector3(d.position[0],d.position[1],d.position[2])
 else:save_state()

func save_state()->void:
 field.game.survival.kit.wildlife[animal_id]={"health":hp,"meat":meat,"hide":hide_count,"position":[position.x,position.y,position.z]}

func _physics_process(delta:float)->void:
 if not field.game.active:return
 if hp<=0:
  warning.visible=false
  state="尸体";model.rotation.z=lerp_angle(model.rotation.z,PI*.5,delta*6);model.position.y=.22
  velocity=Vector3.ZERO;save_state();return
 var player=field.game.player;var s=field.game.survival
 var offset:Vector3=player.global_position-global_position;var distance:=offset.length()
 presence_cooldown=maxf(0,presence_cooldown-delta)
 if presence_cooldown<=0 and field.presence_cooldown<=0:
  var hint:=presence_hint()
  if not hint.is_empty():
   presence_cooldown=45;field.presence_cooldown=12;field.game.notify(hint);field.animal_sound(species,global_position)
 sight_clock-=delta
 if sight_clock<=0:
  sight_clock=.18;sees=false
  if distance<12*(1-s.storm()*.4) and field.game.world.shelter_at(player.position).is_empty():
   var forward:Vector3=-model.global_basis.z
   if distance<3 or forward.dot(offset.normalized())>-.15:sees=field.clear_line(global_position+Vector3.UP*.8,player.global_position+Vector3.UP*.8,[get_rid(),player.get_rid()])
 var moving:bool=player.velocity.length()>.2
 var hearing:bool=moving and distance<(9 if player.sprinting else (2 if player.crouching else 4))*(1-s.storm()*.4)
 # Wind flows diagonally north-east; scent reaches only downwind of its source.
 var scent:bool=s.count("raw_meat")>0 and distance<10 and (-offset.normalized()).dot(Vector3(.8,0,-.6))>.6
 if (sees or hearing or scent) and field.game.world.shelter_at(player.position).is_empty():
  alert=minf(1,alert+delta*(.8 if distance<4 else .3));last_known=player.position;memory=7
 else:alert=maxf(0,alert-delta*.10);memory=maxf(0,memory-delta)
 recovery=maxf(0,recovery-delta)
 var direction:=Vector3.ZERO;var speed:=.55
 state="游荡"
 # Keep the decision until safely released; never bounce across one threshold.
 if species=="deer":
  if alert>.3:fleeing=true
  elif alert<.15 and memory<=0:fleeing=false
 if species=="deer" and fleeing:
  state="逃离";direction=(position-last_known).normalized();speed=4.0
 elif species!="deer" and alert>.35 and memory>0 and position.distance_to(home)<28:
  state="警戒";direction=(last_known-position).normalized();speed=1.2 if alert<.7 else 2.7
  if not warned and distance<14:warned=true;field.game.notify("附近有%s低吼 · 停下观察，退向林道或屋内。"%("熊" if species=="bear" else "狼"));field.animal_sound(species,global_position)
  if alert>.7 and distance<2.5 and sees and recovery<=0 and attack_clock<0:attack_clock=.75;state="扑击前摇"
 else:
  var home_distance:=Vector2(position.x-home.x,position.z-home.z).length()
  if home_distance>5:returning_home=true
  elif home_distance<2:returning_home=false
  if returning_home:direction=(home-position).normalized();speed=.85
  else:direction=Vector3(sin(field.game.survival.elapsed*.07+home.x),0,cos(field.game.survival.elapsed*.07+home.z))*.3
  if alert<.15:warned=false
 if attack_clock>=0:
  direction=Vector3.ZERO;state="扑击前摇";attack_clock-=delta
  if attack_clock<0:
   recovery=2.2
   if sees and distance<2.9 and field.game.world.shelter_at(player.position).is_empty():field.hurt_player(30 if species=="bear" else 14,"legs");state="扑击"
 if memory<=0 or (species!="deer" and position.distance_to(home)>=28):alert=minf(alert,.3)
 direction.y=0
 if direction.length()>.01:
  direction=direction.normalized()
  direction=steer_around_obstacle(direction,delta)
  if direction.length()>.01:
   var heading:=atan2(-direction.x,-direction.z)
   model.rotation.y=rotate_toward(model.rotation.y,heading,delta*(4.0 if fleeing else 2.5))
   # Turn the body before travelling; a 180-degree decision cannot slide backwards.
   var alignment:=maxf(0,(-model.basis.z).dot(direction))
   direction=-model.basis.z*alignment
 var target_velocity:=direction*speed
 var acceleration:=7.0 if fleeing else 2.5
 velocity.x=move_toward(velocity.x,target_velocity.x,delta*acceleration)
 velocity.z=move_toward(velocity.z,target_velocity.z,delta*acceleration)
 velocity.y=-.2 if is_on_floor() else velocity.y-18*delta
 var before:=position
 move_and_slide()
 var travelled:=Vector2(position.x-before.x,position.z-before.z).length()
 update_gait(delta,travelled)
 warning.visible=alert>.35 and distance<15
 warning.text="!" if attack_clock>=0 else ("警觉" if species=="deer" else "低吼")
 if position.distance_to(last_track)>.8:
  field.track(position,model.rotation.y,species);last_track=position
 if is_instance_valid(head):head.rotation.x=lerpf(head.rotation.x,head_rest.x+(-.18 if state=="警戒" else 0),1-exp(-delta*3))
 save_state()

func hit(damage:float,source:Vector3)->void:
 if hp<=0:return
 hp=maxf(0,hp-damage);last_known=source;memory=8;alert=1;save_state()

# Hold a clear detour briefly instead of flipping when a single ray changes hits.
func steer_around_obstacle(direction:Vector3,delta:float)->Vector3:
 detour_time=maxf(0,detour_time-delta)
 if detour_time>0 and path_clear(detour_direction):return detour_direction
 if path_clear(direction):return direction
 for angle in [.65,-.65,1.2,-1.2,1.9,-1.9,PI]:
  var candidate:=direction.rotated(Vector3.UP,angle)
  if path_clear(candidate):
   detour_direction=candidate;detour_time=.8;return candidate
 return Vector3.ZERO

func path_clear(direction:Vector3)->bool:
 var side:=Vector3(-direction.z,0,direction.x)*(.43 if species=="bear" else .26)
 for offset in [Vector3.ZERO,side,-side]:
  var start:Vector3=position+Vector3.UP*.7+offset
  if not field.clear_line(start,start+direction*1.2,[get_rid(),field.game.player.get_rid()]):return false
 return true

# Imported GLBs have rigid hip/knee pivots, not a skinned animation. Drive both
# segments from a foot arc, preserving each pivot's authored rest orientation.
func update_gait(delta:float,travelled:float)->void:
 var actual_speed:=travelled/maxf(delta,.0001)
 gait_speed=lerpf(gait_speed,actual_speed,1-exp(-delta*10))
 gait_weight=move_toward(gait_weight,clampf(actual_speed/.25,0,1),delta*5)
 var run:=smoothstep(1.2,3.5,gait_speed)
 var stride:=lerpf(.65,1.65,run)
 phase=fmod(phase+travelled/stride*TAU,TAU)
 var offsets:=[0.0,.5,lerpf(.75,.5,run),lerpf(.25,0,run)]
 for i in range(4):
  if not is_instance_valid(legs[i]) or not is_instance_valid(shins[i]):continue
  var leg:Node3D=legs[i];var shin:Node3D=shins[i]
  var t:=fposmod(phase/TAU+offsets[i],1.0)
  var stance:=.62
  var foot_travel:=stride*stance
  var forward:float
  var lift:=0.0
  if t<stance:
   forward=lerpf(-foot_travel*.5,foot_travel*.5,t/stance)
  else:
   var swing:=(t-stance)/(1-stance)
   forward=lerpf(foot_travel*.5,-foot_travel*.5,smoothstep(0,1,swing))
   lift=sin(swing*PI)*lerpf(.10,.23,run)
  var upper:=shin.position.length()
  var lower:=maxf(.12,leg.position.y-upper-.065)
  var hip_height:=leg.position.y
  # Probe the snow beneath the foot, bounded to avoid snapping up a cliff.
  var rest_foot:=Vector3(leg.position.x,0,leg.position.z+forward*gait_weight)
  var world_foot:=model.to_global(rest_foot)
  var ground:float=field.game.world.terrain_height(world_foot.x,world_foot.z)-position.y
  ground=clampf(ground,-.14,.14)
  var target:=Vector2(-(hip_height-.09-ground-lift*gait_weight),forward*gait_weight)
  var length:=clampf(target.length(),absf(upper-lower)+.001,upper+lower-.001)
  var base:=atan2(-target.y,-target.x)
  var bend:=acos(clampf((upper*upper+lower*lower-length*length)/(2*upper*lower),-1,1))
  var hip:=base+acos(clampf((upper*upper+length*length-lower*lower)/(2*upper*length),-1,1))
  var blend:=1-exp(-delta*18)
  leg.rotation.x=lerp_angle(leg.rotation.x,leg_rest[i].x+hip*gait_weight,blend)
  shin.rotation.x=lerp_angle(shin.rotation.x,shin_rest[i].x+(bend-PI)*gait_weight,blend)
