extends "res://tools/building_check.gd"
func shot(id:String)->void:
 if DisplayServer.get_name()=="headless":return
 await frames(12);RenderingServer.force_draw(false);await get_tree().process_frame
 get_viewport().get_texture().get_image().save_png("res://artifacts/night-choice/"+id+".png")
func check_buildings()->void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/night-choice"))
 save_path="res://artifacts/night-choice/manual.json"
 start_new();opening.finish();player.position=Vector3(-11,.24,73.4);await frames()
 await walk_to(Vector2(-8.05,73.4));update_target();assert(target.get("id")=="lodge_board",str(target))
 interact();await frames(65);assert(story_panel.scene_kind=="lodge_board" and story_panel.visible)
 var before:Dictionary=survival.data();var rate:float=survival.temperature_rate("lodge",false)
 await shot("01-cost-before-choice")
 await click_control(story_panel.find_child("Story_board_remove",true,false));await frames()
 assert(survival.wood==int(before.items.wood)+2 and survival.discovered.has("lodge_board_removed"))
 assert(survival.temperature_rate("lodge",false)<rate and not world.arrival.wind_boards.visible)
 before=survival.data();survival.lodge_board("remove","lodge");assert(before==survival.data(),"No duplicate salvage")
 assert(story_panel.find_child("Story_board_repair",true,false).disabled)
 before=survival.data();survival.lodge_board("repair","home");assert(before==survival.data(),"No remote repair")
 await shot("02-missing-board")
 save_game();load_game();await frames();assert(not world.arrival.wind_boards.visible)
 active=false;player.enabled=false;survival.items.cloth=1;survival.temperature=70;survival.hunger=70;survival.thirst=70;survival.fires.lodge=30
 var predicted:Dictionary=survival.rest_preview("lodge",2);before=survival.data()
 var copy=Survival.new();assert(copy.restore(before));copy.rest("lodge",2)
 assert(is_equal_approx(copy.temperature,predicted.temperature) and before==survival.data())
 open_story("lodge_board");await frames();var wood:int=survival.wood
 await click_control(story_panel.find_child("Story_board_repair",true,false));await frames()
 assert(survival.wood==wood-2 and survival.count("cloth")==0 and world.arrival.wind_boards.visible)
 assert(not survival.discovered.has("lodge_board_removed"))
 close_story();survival.items.player=1;survival.items.tape_embers=1;backpack.selected="tape_embers";backpack.tab="items";toggle_backpack();await frames()
 await click_control(backpack.find_child("EmbersNote",true,false));await frames()
 assert(story_panel.scene_kind=="embers_note" and survival.discovered.has("embers_note"))
 await shot("03-zhou-note");close_story();active=false
 assert(not survival.morning_trace_visible())
 survival.discovered.append("first_rest");survival.elapsed=900;world.arrival.sync(survival)
 assert(survival.morning_trace_visible() and world.arrival.morning_tracks.visible)
 player.position=Vector3(-3.4,world.terrain_height(-3.4,74.5)+.24,74.5);player.velocity=Vector3.ZERO;active=true;await frames();update_target()
 assert(target.get("id")=="morning_tracks",str(target));await shot("04-morning-trace")
 interact();await frames(65);assert(survival.discovered.has("morning_tracks") and backpack.journal_focus=="morning_tracks")
 var old=Survival.new();assert(not old.morning_trace_visible() and old.lodge_board("remove","lodge").contains("需要"))
 active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();await frames(15);OS.delay_msec(150)
 print("NIGHT_CHOICE_OK: real board choice, finite salvage, colder shelter, repair cost, save/load, forecast parity, cassette note and morning clue")
 get_tree().quit()
