extends "res://scripts/main.gd"

func _ready()->void:
 super._ready();call_deferred("check_field")

func settle(frames:int=8)->void:
 for i in range(frames):await get_tree().process_frame

func check_field()->void:
 save_path="res://artifacts/field/check-save.json"
 start_new();await settle()
 assert(player.position.z>30,"Playable opening begins outside the cabin")
 var fresh=Survival.new();assert(fresh.hunger==35 and fresh.thirst==30)
 fresh.tick(600,"home",false,false);assert(is_equal_approx(fresh.hunger,18.8) and is_equal_approx(fresh.thirst,4.2))
 var s=Survival.new();var warmth:float=s.kit.warmth();var boot:String=s.kit.equipped.feet
 s.kit.owned[boot].wet=70;assert(s.kit.warmth()<warmth)
 s.items.wind_coat=1;var weight:float=s.weight();s.use_item("wind_coat")
 assert(is_equal_approx(weight,s.weight()) and s.count("wind_coat")==0 and s.kit.owned[s.kit.equipped.torso].type=="wind_coat")
 var data:Dictionary=s.data();var restored=Survival.new();assert(restored.restore(JSON.parse_string(JSON.stringify(data))) and JSON.parse_string(JSON.stringify(restored.kit.data()))==JSON.parse_string(JSON.stringify(s.kit.data())))
 var before:Dictionary=restored.data();var corrupt:Dictionary=data.duplicate(true);corrupt.field_kit.equipped.feet="missing"
 assert(not restored.restore(corrupt) and before==restored.data())
 for value in [true,"wet",-1,101]:
  corrupt=data.duplicate(true);corrupt.field_kit.owned[boot].wet=value;assert(not Survival.new().restore(corrupt))
 var legacy:Dictionary=data.duplicate(true);legacy.erase("field_kit");legacy.schema=4
 assert(restored.restore(legacy) and restored.kit.conditions.is_empty() and restored.health==data.health)
 s=Survival.new();s.items.bandage=2;s.health=70;s.kit.add_condition("wound","legs",20)
 s.tick(2,"home",false,false);var hurt:float=s.health;assert(hurt<70)
 s.use_item("bandage");s.tick(2,"home",false,false);assert(is_equal_approx(s.health,hurt) and s.count("bandage")==1)
 s.use_item("bandage");assert(s.count("bandage")==1,"Repeated treatment cannot consume another bandage")
 s.kit.add_condition("sprain","feet",20);assert(s.speed_factor()<1);s.items.splint=1;s.use_item("splint");assert(s.kit.conditions["sprain:feet"].treated)
 s=Survival.new();s.items={"player":1,"tape_home":1};s.loaded_tape="tape_home";s.music_playing=true;s.health=50;s.energy=50
 s.tick(5,"home",false,false);assert(s.health==50,"A cold unlit cabin is not a music healing source")
 s.fires.home=50;s.tick(5,"home",false,false);assert(s.health>50)
 # No materials deducted on cancel; complete exactly one timed action.
 player.position=Vector3(0,.24,19);player.velocity=Vector3.ZERO;await settle()
 survival.items={"wood":3,"cloth":3,"raw_meat":2,"knife":1};survival.fires.home=100
 boot=survival.kit.equipped.feet;survival.kit.owned[boot].wet=70
 assert(field.start_job("dry",boot).contains("烘干"));field.finish_job();assert(survival.kit.owned[boot].wet<=20)
 field.start_job("craft","cooked_meat");field.interaction();assert(survival.count("raw_meat")==2 and survival.count("cooked_meat")==0)
 field.start_job("craft","cooked_meat");field.finish_job();assert(survival.count("raw_meat")==1 and survival.count("cooked_meat")==1)
 survival.items={"knife":1};var carcass=field.find_animal("carcass_0");player.position=carcass.position+Vector3(0,.2,1.2);await settle()
 var meat:int=carcass.meat;field.start_job("harvest",carcass.animal_id);field.finish_job()
 assert(carcass.meat==meat-1 and survival.count("raw_meat")==1)
 data=survival.data();assert(Survival.new().restore(data));field.reset();assert(field.find_animal("carcass_0").meat==meat-1)
 # Module is a three-stage physical interaction, progress survives snapshots.
 player.position=Vector3(-2.4,.24,-169.8);player.velocity=Vector3.ZERO;await settle()
 for i in range(3):
  field.start_job("module","module");field.finish_job();assert(survival.kit.route_stage==i+1)
 assert(survival.kit.module_ready);update_target();interact();await settle(60);assert(survival.parts)
 close_story();backpack.tab="character";toggle_backpack();await settle(20)
 assert(backpack.find_child("DryGarment",true,false)!=null)
 assert(backpack.get_global_rect().end.y<=720,"Character sheet fits the viewport")
 var time:float=survival.elapsed;var wolf=field.find_animal("wolf_0");var at:Vector3=wolf.position
 await settle(30);assert(survival.elapsed==time and wolf.position==at,"Inventory pauses animals and needs together")
 backpack.body_view=true;backpack.refresh();await settle()
 assert(backpack.find_child("BodyPart_feet",true,false)!=null)
 if OS.get_cmdline_user_args().has("--field-preview"):
  await preview_field()
 active=false;player.enabled=false;set_process(false);field.set_process(false)
 cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();field.audio.stop();field.audio.stream=null
 await settle();OS.delay_msec(120)
 print("FIELD_OK: clothing, body treatments, needs, atomic save migration, timed jobs, harvesting, three-stage module, character UI, pause")
 get_tree().quit()

func shot(name:String)->void:
 # Explicit draw also captures when macOS occludes the test window.
 await get_tree().process_frame
 RenderingServer.force_draw(false)
 var folder:="field"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--field-output="):folder=arg.trim_prefix("--field-output=")
 var path:="res://artifacts/"+folder
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
 get_viewport().get_texture().get_image().save_png(path+"/"+name+".png")

func preview_field()->void:
 backpack.body_view=false;survival.items={"food":2,"water":1,"cloth":3,"wind_coat":1,"knife":1,"bow":1,"arrow":4,"rifle":1,"ammo":3}
 survival.kit.owned[survival.kit.equipped.feet].wet=42;survival.kit.owned[survival.kit.equipped.feet].condition=76
 backpack.refresh();await settle(15);await shot("character")
 survival.kit.add_condition("sprain","feet",20);survival.items.splint=1;backpack.body_view=true;backpack.refresh();await settle();await shot("body")
 backpack.visible=false;open_story("intro");await settle();await shot("story")
 close_story();canvas.visible=false;active=false;player.enabled=false;player.position=Vector3(0,.3,-35);interior_view.update()
 var camera:=Camera3D.new();add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=5
 for kind in ["deer_0","wolf_0","bear_0"]:
  var a=field.find_animal(kind);camera.position=a.position+a.model.basis*Vector3(3,4,-4);camera.look_at(a.position+Vector3.UP*.8);camera.current=true
  world.sun.light_cull_mask=0xfffff;world.night_fill.light_cull_mask=0xfffff
  await settle(4);await shot(kind)
 camera.queue_free()
