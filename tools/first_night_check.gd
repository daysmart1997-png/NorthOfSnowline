extends "res://tools/building_check.gd"
const ArrivalState=preload("res://scripts/arrival_state.gd")
func shot(id:String)->void:
 if DisplayServer.get_name()=="headless" or not OS.get_cmdline_user_args().has("--first-night-capture"):return
 await frames(12);RenderingServer.force_draw(false);await get_tree().process_frame
 get_viewport().get_texture().get_image().save_png("res://artifacts/first-night/"+id+".png")
func resume_play()->void:
 backpack.visible=false;story_panel.visible=false;active=true;player.enabled=true
func search(id:String)->void:
 update_target();assert(target.get("id")==id,"Reach actual search target: "+id+" got "+str(target.get("id")))
 interact();await frames(110);assert(backpack.visible and backpack.tab=="search")
func take(id:String,item:String)->void:
 assert(arrival_items.take(id,item).contains("收好"),"Take real remaining supply")
func check_buildings()->void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/first-night"))
 save_path="res://artifacts/first-night/manual.json"
 start_new();opening.finish();await frames()
 assert(DayCycle.hour(survival.solar_time())>=16.5 and survival.elapsed<1)
 var old=Survival.new();var legacy:Dictionary=old.data();legacy.erase("clock_offset");legacy.schema=7
 legacy.elapsed=150.0;assert(old.restore(legacy) and old.clock_offset==0 and DayCycle.clock_text(old.solar_time())=="11:30")
 var invalid:=old.data();invalid.clock_offset=NAN;var before:=old.data();assert(not old.restore(invalid) and before==old.data())
 await shot("01-mountain-dusk")
 for at in [Vector2(0,121),Vector2(12,118),Vector2(12,113),Vector2(12,109),Vector2(12.4,108.2)]:await walk_to(at)
 await search("gate_desk");take("gate_desk","food");take("gate_desk","water")
 survival.use_item("food");survival.use_item("water");resume_play()
 for at in [Vector2(12,110),Vector2(12,116),Vector2(0,103),Vector2(-11,84),Vector2(-11,78),Vector2(-11,74.8)]:await walk_to(at)
 assert(interior_view.room=="lodge" and survival.health>0)
 print("FIRST_NIGHT_ARRIVAL ",DayCycle.clock_text(survival.solar_time())," elapsed=",survival.elapsed," warmth=",survival.temperature)
 await shot("02-lodge-arrival")
 await walk_to(Vector2(-9.5,75.35));await search("lodge_stores")
 for i in range(3):take("lodge_stores","wood")
 resume_play()
 for at in [Vector2(-11,75.2),Vector2(-11,72),Vector2(-9.6,71.8)]:await walk_to(at)
 update_target();assert(target.id=="lodge");interact();await frames(60)
 assert(survival.fires.lodge>0 and survival.temperature_rate("lodge",false)>0)
 if OS.get_cmdline_user_args().has("--emergency-boards"):
  await walk_to(Vector2(-8.05,73.4));update_target();assert(target.id=="lodge_board")
  interact();await frames(65);assert(story_panel.visible)
  await click_control(story_panel.find_child("Story_board_remove",true,false));await frames()
  assert(survival.discovered.has("lodge_board_removed"));close_story()
 # A cold shelter is useful, but is not equivalent to a burning stove.
 assert(survival.temperature_rate("canteen",false)<0 and survival.rest_problem("bunkhouse",2)!="")
 for at in [Vector2(-11,74.8),Vector2(-11,79),Vector2(-3,85),Vector2(10,85),Vector2(10,80),Vector2(10,78),Vector2(10,76.8)]:await walk_to(at)
 assert(interior_view.room=="canteen");await search("canteen_pantry");await shot("03-pantry")
 take("canteen_pantry","food");take("canteen_pantry","food");take("canteen_pantry","water")
 assert(arrival_items.take("canteen_pantry","food").contains("已经取走"));resume_play()
 for at in [Vector2(10,79),Vector2(10,85),Vector2(0,96),Vector2(-23,94),Vector2(-23,89),Vector2(-23,86.5)]:await walk_to(at)
 assert(interior_view.room=="woodshed");await search("shed_fuel");await shot("04-fuel-shed")
 for i in range(2 if OS.get_cmdline_user_args().has("--emergency-boards") else 4):take("shed_fuel","wood")
 assert(not world.arrival.stocks.shed_fuel.wood[0].visible)
 resume_play()
 for at in [Vector2(-23,90),Vector2(-23,95),Vector2(-11,95),Vector2(-11,79),Vector2(-11,75),Vector2(-12.6,75.5)]:await walk_to(at)
 update_target();assert(target.id=="wreck_player","Receiver can be reached from bedside aisle")
 interact();await frames(60);assert(survival.count("player")==1 and survival.count("tape_embers")==1)
 survival.use_item("tape_embers");survival.toggle_music();assert(survival.music_effect()=="tape_embers")
 await shot("05-warmth-and-tape")
 # Actual rest UI advances the same state until morning. Never grant fuel/food.
 while DayCycle.day(survival.solar_time())<2 or DayCycle.hour(survival.solar_time())<7:
  if survival.hunger<48 and survival.count("food")>0:survival.use_item("food")
  if survival.thirst<40 and survival.count("water")>0:survival.use_item("water")
  if survival.fires.lodge<125:
   for at in [Vector2(-11,75.2),Vector2(-11,72),Vector2(-9.6,71.8)]:await walk_to(at)
   update_target();assert(target.id=="lodge");interact();await frames(60)
  for at in [Vector2(-11,74.8),Vector2(-13,74.7),Vector2(-13,73.4)]:await walk_to(at)
  update_target();assert(target.id=="lodge_bed");interact();await frames(20)
  var clock:float=survival.elapsed;var forecast:Dictionary=survival.rest_preview("lodge",2)
  assert(forecast.problem=="");backpack_action("rest","2");await frames(20)
  assert(survival.elapsed>clock and survival.health>0);resume_play()
 assert(survival.discovered.has("first_rest") and survival.discovered.has("first_warmth"))
 print("FIRST_NIGHT_MORNING ",DayCycle.clock_text(survival.solar_time())," health=",survival.health," warmth=",survival.temperature," hunger=",survival.hunger," wood=",survival.wood)
 await shot("06-first-morning")
 # Optional ruined quarters, after the night: supplies, entry and furniture path.
 for at in [Vector2(-13,74.7),Vector2(-11,74.8),Vector2(-11,79),Vector2(-3,79),Vector2(-3,68),Vector2(12,68),Vector2(12,62),Vector2(12,59),Vector2(12,57.8)]:await walk_to(at)
 assert(interior_view.room=="bunkhouse");await search("bunk_effects");take("bunk_effects","cloth");await shot("07-quarters")
 resume_play();survival.discovered.append("lodge_route");map.visible=true;await shot("08-map");map.visible=false
 save_game();var state:Dictionary=survival.data();load_game();await frames()
 assert(survival.clock_offset==state.clock_offset and survival.supply_taken==state.supply_taken and survival.count("player")==1)
 assert(world.points.filter(func(p):return p.id=="wreck_player").size()==1)
 if OS.get_cmdline_user_args().has("--emergency-boards"):
  assert(survival.discovered.has("lodge_board_removed") and not world.arrival.wind_boards.visible)
 active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();await frames(12)
 OS.delay_msec(150)
 print("FIRST_NIGHT_OK: real dusk route, distinct supplies/rooms, warmed shelter, cassette, finite overnight fuel/food, morning, legacy and save/load")
 get_tree().quit()
