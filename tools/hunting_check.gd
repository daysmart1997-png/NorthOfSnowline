extends "res://scripts/main.gd"
func _ready()->void:
 super._ready();call_deferred("check_hunting")
func settle(n:int=6)->void:
 for i in range(n):await get_tree().physics_frame
func check_hunting()->void:
 start_new();await settle()
 for a in field.animals:a.set_physics_process(false)
 player.position=Vector3(0,world.terrain_height(0,33)+.1,33);player.velocity=Vector3.ZERO
 var deer=field.find_animal("deer_0");deer.position=Vector3(0,world.terrain_height(0,29)+.08,29);deer.hp=60
 survival.items={"knife":1,"bow":1,"arrow":3,"rifle":1,"ammo":3};survival.kit.weapon="bow";field.aim_time=1
 await settle()
 field.shoot(deer.position+Vector3.UP*.7,true);assert(survival.count("arrow")==2)
 await settle(1);var flight_save:Dictionary=survival.data();assert(flight_save.field_kit.flights.size()==1)
 var restored=Survival.new();assert(restored.restore(JSON.parse_string(JSON.stringify(flight_save))) and restored.kit.flights.size()==1)
 await settle(35);assert(deer.hp<60 and field.projectiles.is_empty() and field.recoveries.size()==1,"Real arrow sweep hits the animal once")
 var hp:float=deer.hp;await settle(20);assert(deer.hp==hp,"Resting arrow cannot repeat damage")
 var saved:Dictionary=survival.data();assert(saved.field_kit.arrows.size()==1)
 var arrow_at:Vector3=field.recoveries[0].mesh.position;player.position=arrow_at+Vector3(.4,0,0);field.interaction();assert(survival.count("arrow")==3 and survival.kit.arrows.is_empty())
 player.position=Vector3(0,world.terrain_height(0,33)+.1,33);await settle()
 survival.kit.weapon="rifle";field.loaded=false;field.cooldown=0;field.shoot(deer.position+Vector3.UP*.7,true);assert(survival.count("ammo")==3)
 field.loaded=true;field.shoot(deer.position+Vector3.UP*.7,true);assert(survival.count("ammo")==2 and not field.loaded and deer.hp==0)
 field.shoot(deer.position+Vector3.UP*.7,true);assert(survival.count("ammo")==2,"Cooldown rejects repeated shots")
 # A wall blocks both the ray weapon and the AI sight query.
 var wolf=field.find_animal("wolf_0");wolf.position=Vector3(0,world.terrain_height(0,26)+.1,26);wolf.home=wolf.position;wolf.hp=70
 var wall:=StaticBody3D.new();add_child(wall);wall.position=Vector3(0,world.terrain_height(0,30)+1,30)
 var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(5,2,.3);shape.shape=box;wall.add_child(shape);await settle()
 assert(not field.clear_line(player.position+Vector3.UP,wolf.position+Vector3.UP,[player.get_rid(),wolf.get_rid()]))
 field.loaded=true;field.cooldown=0;field.shoot(wolf.position+Vector3.UP*.7,true);assert(wolf.hp==70)
 wall.queue_free();await settle()
 # Freeze the player, allow the wolf's actual perception and movement to run.
 deer.position.x=20;wolf.alert=0;wolf.memory=0;wolf.model.rotation.y=PI;wolf.set_physics_process(true)
 player.enabled=false;survival.health=100;survival.temperature=100;var before:float=survival.health
 await settle(18);assert(survival.health==before,"No damage before warning and wind-up")
 await settle(420);assert(wolf.alert>.35 and survival.health<before and survival.kit.has_condition("wound"),"Wolf detects, approaches and attacks through its state machine")
 player.position=Vector3(0,.24,19);player.velocity=Vector3.ZERO;survival.temperature=100;survival.kit.conditions={};before=survival.health
 await settle(180);assert(survival.health>=before,"Shelter prevents an outside wolf from attacking through the wall")
 var at:Vector3=wolf.position;set_menu(true);await settle(25);assert(wolf.position==at)
 active=false;set_process(false);field.set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();field.audio.stop();field.audio.stream=null
 await settle();OS.delay_msec(120)
 print("HUNTING_OK: real swept arrow, recovery, ammunition, reload gate, ray occlusion, wolf perception/wind-up/attack, shelter and pause")
 get_tree().quit()
