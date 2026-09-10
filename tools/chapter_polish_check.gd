extends "res://scripts/main.gd"
const Experience=preload("res://scripts/chapter_experience.gd")

func _ready()->void:
 super._ready();call_deferred("check_polish")

func settle(n:=8)->void:
 for i in range(n):await get_tree().process_frame

func shot(label:String)->void:
 if DisplayServer.get_name()=="headless":return
 await settle();RenderingServer.force_draw(false);await get_tree().process_frame
 assert(get_viewport().get_texture().get_image().save_png("res://artifacts/chapter-polish/"+label+".png")==OK)

func check_polish()->void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/chapter-polish"))
 save_path="res://artifacts/chapter-polish/manual.json"
 start_new();active=false;player.enabled=false;await settle()
 # New weather lets daylight end before the first storm peak; old saves retain their weather.
 var s=Survival.new();s.elapsed=240;assert(s.storm()==0)
 s.elapsed=450;assert(s.storm()<.5)
 s.elapsed=720;assert(s.storm()==1)
 var legacy:Dictionary=s.data();legacy.erase("weather_profile");legacy.schema=5
 var old=Survival.new();assert(old.restore(legacy) and old.weather_profile==0)
 old.elapsed=450;assert(old.storm()==1)
 assert(Survival.new().restore(s.data()))
 for invalid in [true,-1,2,"new"]:
  var bad:Dictionary=s.data();bad.weather_profile=invalid
  var candidate=Survival.new();var before:Dictionary=candidate.data()
  assert(not candidate.restore(bad) and candidate.data()==before)
 # Independent slots and backup, including an actual failed filesystem write.
 assert(Saves.write(save_path,{"probe":1})==OK)
 assert(Saves.write(save_path,{"probe":2})==OK)
 assert(JSON.parse_string(FileAccess.get_file_as_string(save_path+".bak")).probe==1)
 assert(Saves.write(Saves.checkpoint_path(save_path),{"probe":3})==OK)
 assert(JSON.parse_string(FileAccess.get_file_as_string(save_path)).probe==2)
 assert(Saves.write(save_path+"/blocked.json",{})!=OK)
 assert(JSON.parse_string(FileAccess.get_file_as_string(save_path)).probe==2)
 assert(Saves.manual_source("res://artifacts/chapter-polish/no-save.json")=="res://artifacts/chapter-polish/no-save.json")
 # Manual and safe checkpoint restores carry different state, never touching player slots.
 survival.temperature=72;save_game();survival.temperature=63;automatic_saves=true
 assert(save_checkpoint());survival.temperature=10
 load_game();assert(survival.temperature==72)
 load_game(true);assert(survival.temperature==63)
 active=false;player.enabled=false;automatic_saves=false
 survival.health=80;survival.temperature=60;survival.thirst=50;survival.hunger=50;survival.fires.home=40
 assert(experience.safe_to_save("home") and not experience.safe_to_save(""))
 survival.temperature=20;assert(not experience.safe_to_save("home"));survival.temperature=60
 survival.fires.home=0;assert(not experience.safe_to_save("home"));survival.fires.home=40
 # Real safe-node trigger writes only the isolated checkpoint and respects nearby threats.
 player.position=Vector3(0,.24,20.5);player.velocity=Vector3.ZERO
 var wolf=field.find_animal("wolf_0");var old_at:Vector3=wolf.position;var old_alert:float=wolf.alert
 wolf.position=player.position+Vector3(2,0,0);wolf.alert=1
 assert(not experience.safe_to_save("home"));wolf.position=old_at;wolf.alert=old_alert
 automatic_saves=true;active=true;experience.last_room="home";experience.calm_time=0
 experience._process(5.1);assert(survival.discovered.has("checkpoint_home_outward"))
 assert(JSON.parse_string(FileAccess.get_file_as_string(save_path)).state.temperature==72)
 automatic_saves=false;active=false;player.enabled=false
 # Cancelled work cannot commit a repair stage; partial meter only reflects current testing.
 player.position=Vector3(-2.4,.24,-169.8);player.velocity=Vector3.ZERO;await settle()
 field.start_job("module","module");field.progress=1;field.interaction()
 assert(survival.kit.route_stage==0)
 for i in range(3):
  field.start_job("module","module")
  assert(is_equal_approx(field.job.duration,[3.0,4.0,2.5][i]))
  if i==2:
   field.progress=1.25;experience._process(0)
   assert(is_equal_approx(experience.needle_pivot.rotation.y,-.1))
  field.finish_job();assert(survival.kit.route_stage==i+1)
 active=false;player.enabled=false
 experience._process(0);assert(experience.contact.layers==4 and experience.cable.rotation.y==0)
 active=true;update_target();await shot("module-complete");active=false;player.enabled=false
 survival.parts=true;experience._process(0);assert(not experience.module_root.visible)
 # Guidance points to available remedies; paused UI does not consume its cadence.
 survival.temperature=20;assert(Experience.advice(survival,"home").id=="cold")
 survival.kit.add_condition("wound","legs",20);assert(Experience.advice(survival,"home").id=="wound")
 var wait:float=experience.advice_wait;experience._process(12);assert(experience.advice_wait==wait)
 # Letter is rereadable, changes no inventory/needs, and enlarged text stays in the panel.
 survival.items.tape_home=1;preferences.large_text=true;open_story("tape_note");await settle()
 assert(story_panel.body_label.get_theme_font_size("font_size")==20)
 var owned:Dictionary=survival.items.duplicate();var time:float=survival.elapsed
 await shot("tape-note-large")
 story_panel.find_child("Story_replay",true,false).pressed.emit();await settle()
 assert(survival.items==owned and survival.elapsed==time)
 close_story();active=false;player.enabled=false
 # Orthographic camera is 38 m away; hearing must follow the player, not the camera.
 assert(experience.listener.is_current() and experience.listener.global_position.distance_to(player.global_position)<1.0)
 # Wildlife cues retain source position and pause with world simulation.
 field.animal_sound("deer",Vector3(3,0,10));await settle()
 var voices:Array=field.find_children("*","AudioStreamPlayer3D",true,false)
 assert(not voices.is_empty())
 assert(voices[-1].global_position==Vector3(3,1,10) and voices[-1].stream_paused)
 field.reset();await settle()
 assert(field.find_children("*","AudioStreamPlayer3D",true,false).is_empty(),"Loading another journey discards old wildlife voices")
 voices=[]
 cassette.cue_seconds=0
 for i in range(300):cassette.sync(survival,false,true,0,false,false)
 assert(cassette.background.volume_db< -60)
 set_menu(true);await shot("save-menu")
 preferences.large_text=false;set_process(false);field.set_process(false)
 experience.cue.stop();experience.cue.stream=null
 for voice in voices:voice.stop();voice.stream=null;voice.queue_free()
 cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();await settle();OS.delay_msec(100)
 print("CHAPTER_POLISH_OK: weather migration, independent safe saves, backup failure, repair feedback, remedy priority, letter pause, larger text, positional audio, music silence")
 get_tree().quit()
