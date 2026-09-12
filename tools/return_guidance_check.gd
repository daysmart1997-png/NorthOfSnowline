extends "res://tools/building_check.gd"
func shot(id:String)->void:
 if DisplayServer.get_name()=="headless":return
 await frames(15);RenderingServer.force_draw(false);await get_tree().process_frame
 get_viewport().get_texture().get_image().save_png("res://artifacts/return-guidance/"+id+".png")
func check_buildings()->void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/return-guidance"))
 save_path="res://artifacts/return-guidance/manual.json"
 start_new();opening.finish();await frames()
 for animal in field.animals:animal.set_physics_process(false)
 # Actual approach to the wall chart above the existing storage, no new blocker.
 player.position=Vector3(0,.24,-168);player.velocity=Vector3.ZERO
 await walk_to(Vector2(-3.3,-168.3));update_target()
 assert(target.get("id")=="workshop_route_board",str(target))
 assert(not survival.discovered.has("workshop_route_board"))
 await shot("01-workshop-board")
 interact();await frames(65)
 assert(backpack.visible and backpack.journal_focus=="workshop_route_board")
 assert(survival.discovered.has("workshop_route_board"))
 backpack.visible=false;survival.parts=true;open_story("station");await frames()
 assert(story_panel.return_conditions().contains("不含动物袭击"))
 assert(story_panel.find_child("Story_direct",true,false).text.contains("狼"))
 for control in story_panel.find_children("*","Button",true,false):
  assert(Rect2(Vector2.ZERO,canvas.size).encloses(control.get_global_rect()),"Choices fit 720p")
 await shot("02-return-choice");close_story()
 player.position=Vector3(3,world.terrain_height(3,-150)+.24,-150);player.velocity=Vector3.ZERO
 await frames();await walk_to(Vector2(3.2,-150.5));update_target()
 assert(target.get("id")=="return_post_0",str(target))
 assert(not survival.discovered.has("return_post_0"),"Nearby hint does not auto-read the sign")
 assert(exploration.return_guidance.shown.has(0))
 await shot("03-junction")
 interact();await frames(65);assert(backpack.visible and survival.discovered.has("return_post_0"))
 backpack.visible=false;active=false
 var wolf=field.find_animal("wolf_0")
 player.position=Vector3(0,world.terrain_height(0,-110)+.24,-110)
 wolf.position=Vector3(-12,world.terrain_height(-12,-110)+.24,-110);wolf.hp=70;wolf.alert=0;wolf.memory=0
 assert(wolf.presence_hint().contains("西"))
 var hp:float=survival.health;wolf.presence_cooldown=0
 wolf._physics_process(.016);assert(wolf.presence_cooldown==0,"Pause cannot emit animal warnings")
 active=true;wolf._physics_process(.016);active=false
 assert(wolf.presence_cooldown>40 and survival.health==hp and wolf.alert<.35,"Early cue precedes warning and damage")
 var second=field.find_animal("wolf_1");second.position=wolf.position+Vector3(0,0,1);second.alert=0;second.presence_cooldown=0
 active=true;second._physics_process(.016);active=false
 assert(second.presence_cooldown==0,"Nearby animals do not stack presence calls")
 wolf.hp=0;assert(wolf.presence_hint().is_empty(),"Dead animal cannot call")
 wolf.hp=70;player.position=Vector3(0,.24,-168);assert(wolf.presence_hint().is_empty(),"No outdoor cue inside")
 save_game();load_game();await frames();assert(survival.discovered.has("return_post_0"))
 set_process(false);active=false;player.enabled=false;cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();await frames(75);OS.delay_msec(150)
 print("RETURN_GUIDANCE_OK: reachable wall chart and sign, explicit route risk, unclipped choices, live directional cue before damage, pause/death/shelter and saved clue")
 get_tree().quit()
