extends "res://tools/building_check.gd"
const Routes=preload("res://scripts/route_planner.gd")

func _ready()->void:
 # main setup without starting the inherited building coroutine.
 super._ready()

# Parent dispatches this name; replace its test with the new flow contract.
func check_buildings()->void:
 save_path="res://artifacts/chapter-flow/state.json"
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/chapter-flow"))
 start_new();await frames()
 await walk_to(Vector2(0,27));await walk_to(Vector2(0,20));await walk_to(Vector2(-3.2,18.2))
 update_target();assert(target.get("id")=="departure_trace",str(target))
 interact();await frames(70);assert(story_panel.visible and story_panel.scene_kind=="departure")
 var before:Dictionary=survival.data();var t:float=survival.elapsed
 story_panel.find_child("Story_replay",true,false).pressed.emit();await frames(60)
 assert(survival.elapsed==t and survival.data()==before,"Re-reading neither advances time nor creates rewards")
 await shot("departure");close_story()
 # Independent site relocation: the full-route test covers continuous travel.
 player.position=Vector3(-.35,.24,-172.15);player.velocity=Vector3.ZERO;await frames()
 update_target();assert(target.get("id")=="station_cabinet")
 # Cancelled search and a full backpack cannot consume the one-time cache.
 interact();await frames(15);cancel_action();assert(not survival.collected.has("station_cabinet"))
 survival.items.wood=24;update_target();interact();await frames(120)
 assert(not survival.collected.has("station_cabinet") and exploration.stock.visible)
 survival.items={"wood":1,"water":1,"food":1};update_target();interact();await frames(140)
 assert(survival.collected.count("station_cabinet")==1 and survival.count("wood")==2 and survival.count("cloth")==1)
 assert(not exploration.stock.visible and absf(exploration.doors[0].rotation.y)>1)
 var wall:Node3D=world.buildings.station.find_child("ElectricalPartsCabinet",true,false)
 assert(wall.is_visible_in_tree(),"Searching keeps the cabinet in the room")
 var door_pose:=player.global_transform;door_pose.origin=Vector3(-.35,.24,-172.72)
 assert(player.test_move(door_pose,Vector3(-1.3,0,0)),"Opened door has matching collision")
 before=survival.data();exploration.search();assert(survival.data()==before,"Repeat search has no rewards")
 await shot("cabinet-open")
 set_menu(true);save_game();start_new();assert(exploration.stock.visible and exploration.doors[0].rotation.y==0)
 load_game();await frames();assert(not exploration.stock.visible and survival.collected.count("station_cabinet")==1)
 before=survival.data();exploration.search();assert(survival.data()==before,"Loading cannot replenish a searched cabinet")
 # Legacy snapshots need no new fields; absence of collected key means unopened.
 var legacy:Dictionary=before.duplicate(true);legacy.collected.erase("station_cabinet")
 var old=Survival.new();assert(old.restore(legacy) and not old.collected.has("station_cabinet"))
 # Predictions reuse the live rules without touching the live state, even injured.
 var s=Survival.new();s.elapsed=420;s.temperature=65;s.thirst=65;s.parts=true
 before=s.data()
 var direct:=Routes.forecast(s,"direct",world);var sheltered:=Routes.forecast(s,"sheltered",world)
 assert(s.data()==before and direct.finished and sheltered.finished)
 assert(sheltered.distance>direct.distance and sheltered.protected_seconds>direct.protected_seconds+30)
 assert(sheltered.minutes>direct.minutes)
 print("ROUTE_FORECAST ",JSON.stringify({"direct":direct,"sheltered":sheltered}))
 s.temperature=18;s.thirst=10;assert(Routes.forecast(s,"direct",world).unsafe)
 assert(s.temperature_rate("",true)>s.temperature_rate("",false),"Shelter comparison matches actual loss rules")
 # Full UI including increased text must stay inside the 720p viewport.
 survival.parts=true;preferences.large_text=true;open_story("station");await frames(10)
 assert(story_panel.get_global_rect().end.y<=720,"Route comparison and buttons fit the screen")
 assert(story_panel.route_status.text.contains("铁路") and story_panel.route_status.text.contains("不计搜寻"))
 await shot("return-plan");close_story();preferences.large_text=false
 # Ambient wind stays audible but is filtered through the room; danger ducks tapes.
 survival.items.player=1;survival.items.tape_embers=1;survival.loaded_tape="tape_embers";survival.music_playing=true
 active=false;player.enabled=false;set_process(false)
 for i in range(120):cassette.sync(survival,false,false,0,true,false);await frames(1)
 assert(cassette.wind_filter.cutoff_hz<1200 and AudioServer.get_bus_send(AudioServer.get_bus_index("SnowWind"))=="SnowEffects")
 for i in range(120):cassette.sync(survival,false,true,0,false,false);await frames(1)
 assert(cassette.wind_filter.cutoff_hz>9000)
 # The main update also syncs audio; directly test its threat trigger then pause it.
 field.animal_sound("wolf",player.position+Vector3(3,0,0));assert(cassette.alert_seconds>0)
 set_process(false)
 for i in range(40):cassette.sync(survival,false,true,0,false,true);await frames(1)
 assert(cassette.speaker.volume_db< -23,"Music leaves headroom for directional animal warning")
 var remaining:float=cassette.alert_seconds;cassette.sync(survival,true,true,0,false,false)
 assert(cassette.alert_seconds==remaining and cassette.speaker.stream_paused)
 experience.reset();assert(cassette.alert_seconds==0,"Reset clears stale danger ducking")
 # Discovery enriches the conversation but never pretends to confirm Zhou's location.
 survival.kit.module_ready=true;survival.repair()
 for choice in ["call","report"]:assert(Chapter.advance_radio(survival,choice))
 Chapter.discover(survival,"departure_trace")
 assert(Chapter.radio_response(survival).contains("不会把它当成他现在的位置"))
 open_story("radio");await frames();await shot("radio-response")
 assert(story_panel.find_child("Story_replay",true,false)!=null)
 assert(Chapter.advance_radio(survival,"confirm") and survival.completed)
 # Optional visual return cue is based on actual wind/time, not pickup alone.
 survival.parts=true;survival.elapsed=0;player.position=Vector3(5,.24,-16);active=true;exploration._process(.1)
 assert(not survival.discovered.has("return_wind"))
 survival.elapsed=600;exploration._process(.1);assert(survival.discovered.count("return_wind")==1)
 exploration._process(.1);assert(survival.discovered.count("return_wind")==1)
 active=false;player.enabled=false;field.set_process(false)
 cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();await frames();OS.delay_msec(100)
 print("CHAPTER_FLOW_OK: optional clues, atomic cabinet/cancel/full/load/new/legacy, forecasts without mutation, route tradeoffs, readable UI, filtered wind, threat duck/pause, remembered dialogue, weather-driven return cue")
 get_tree().quit()

func shot(id:String)->void:
 if DisplayServer.get_name()=="headless":return
 RenderingServer.force_draw(false);await get_tree().process_frame
 assert(get_viewport().get_texture().get_image().save_png("res://artifacts/chapter-flow/"+id+".png")==OK)
