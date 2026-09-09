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

func setup(owner_field,id:String,kind:String,at:Vector3,dead:=false)->void:
 field=owner_field;animal_id=id;species=kind;home=at;position=at
 hp=0 if dead else (140 if species=="bear" else (70 if species=="wolf" else 60));meat=8 if species=="bear" else (6 if species=="deer" else 3)
 name=id;collision_layer=4;collision_mask=1
 var collider:=CollisionShape3D.new();var shape:=CapsuleShape3D.new();shape.radius=.42 if species=="bear" else .24;shape.height=1.3 if species in ["bear","deer"] else .75;collider.shape=shape;collider.position.y=shape.height*.5;add_child(collider)
 model=load("res://assets/wildlife/%s.glb"%species).instantiate();add_child(model)
 for i in range(4):legs.append(model.find_child("Leg%d"%i,true,false))
 head=model.find_child("Head",true,false)
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
 if species=="deer" and alert>.3:
  state="逃离";direction=(position-last_known).normalized();speed=4.0
 elif species!="deer" and alert>.35 and memory>0 and position.distance_to(home)<28:
  state="警戒";direction=(last_known-position).normalized();speed=1.2 if alert<.7 else 2.7
  if not warned and distance<14:warned=true;field.game.notify("附近有%s低吼 · 停下观察，退向林道或屋内。"%("熊" if species=="bear" else "狼"));field.animal_sound(species)
  if alert>.7 and distance<2.5 and sees and recovery<=0 and attack_clock<0:attack_clock=.75;state="扑击前摇"
 else:
  if position.distance_to(home)>5:direction=(home-position).normalized();speed=.85
  else:direction=Vector3(sin(field.game.survival.elapsed*.07+home.x),0,cos(field.game.survival.elapsed*.07+home.z))*.3
  if alert<.15:warned=false
 if attack_clock>=0:
  direction=Vector3.ZERO;state="扑击前摇";attack_clock-=delta
  if attack_clock<0:
   recovery=2.2
   if sees and distance<2.9 and field.game.world.shelter_at(player.position).is_empty():field.hurt_player(30 if species=="bear" else 14,"legs");state="扑击"
 if memory<=0 or position.distance_to(home)>=28:alert=minf(alert,.3)
 direction.y=0
 if direction.length()>.01:
  direction=direction.normalized()
  if not field.clear_line(position+Vector3.UP*.7,position+Vector3.UP*.7+direction*1.2,[get_rid(),player.get_rid()]):direction=direction.rotated(Vector3.UP,1.2)
  model.rotation.y=lerp_angle(model.rotation.y,atan2(-direction.x,-direction.z),delta*5)
 velocity.x=direction.x*speed;velocity.z=direction.z*speed;velocity.y=-.2 if is_on_floor() else velocity.y-18*delta
 move_and_slide()
 warning.visible=alert>.35 and distance<15
 warning.text="!" if attack_clock>=0 else ("警觉" if species=="deer" else "低吼")
 if position.distance_to(last_track)>.8:
  field.track(position,model.rotation.y,species);last_track=position
 phase+=delta*Vector2(velocity.x,velocity.z).length()*4
 for i in range(4):
  if is_instance_valid(legs[i]):legs[i].rotation.x=sin(phase+(PI if i in [1,2] else 0))*.35*minf(speed,1.5)
 if is_instance_valid(head):head.rotation.x=lerpf(head.rotation.x,-.18 if state=="警戒" else 0,delta*3)
 save_state()

func hit(damage:float,source:Vector3)->void:
 if hp<=0:return
 hp=maxf(0,hp-damage);last_known=source;memory=8;alert=1;save_state()
