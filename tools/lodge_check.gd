extends "res://tools/building_check.gd"
func shot(id:String)->void:
 if DisplayServer.get_name()=="headless":return
 await frames(20);RenderingServer.force_draw(false);await get_tree().process_frame
 assert(get_viewport().get_texture().get_image().save_png("res://artifacts/lodge-refinement/"+id+".png")==OK)
func check_buildings()->void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/lodge-refinement"))
 save_path="res://artifacts/lodge-refinement/session.json"
 start_new();opening.finish()
 # Isolated site relocation. Every doorway/furniture segment below uses movement input.
 player.position=Vector3(-11,.3,81);player.velocity=Vector3.ZERO;player.zoom=15;await frames(30)
 var lodge:Node3D=world.buildings.lodge
 assert(lodge.scene_file_path.ends_with("charcoal_lodge_v3.glb"))
 assert(lodge.find_child("SideShelter",true,false).get_parent().name=="CutawayRight")
 var materials:Array=[]
 for visual in lodge.find_children("*","MeshInstance3D",true,false):
  for i in range(visual.mesh.get_surface_count()):
   var material=visual.get_active_material(i)
   if material is StandardMaterial3D and material.resource_name in ["LodgeTimber","LodgeIron"]:
    assert(material.albedo_texture!=null and material.roughness_texture!=null and material.normal_enabled)
    if not materials.has(material.resource_name):materials.append(material.resource_name)
 assert(materials.size()==2)
 await shot("01-exterior")
 for at in [Vector2(-11,78),Vector2(-11,74.8),Vector2(-9.5,75.35)]:await walk_to(at)
 assert(interior_view.room=="lodge" and not world.fire_meshes.lodge.visible)
 assert(not lodge.find_child("CutawayRight",true,false).visible)
 assert(world.stamp_snow(player.position,0,1,true)==0)
 await shot("02-room-cold")
 var fuel:Array=world.arrival.stocks.lodge_stores.wood
 for log_node in fuel:assert(log_node.position.y<-.6)
 update_target();assert(target.get("id")=="lodge_stores");interact();await frames(110)
 assert(backpack.visible and backpack.tab=="search")
 backpack.selected="wood";backpack.refresh();backpack.do_action("take_supply","wood");await frames()
 assert(not fuel[0].visible and fuel[1].visible and fuel[2].visible)
 toggle_backpack();await frames();await shot("03-one-log-taken")
 for at in [Vector2(-11,75.2),Vector2(-11,72),Vector2(-9.6,71.8)]:await walk_to(at)
 update_target();assert(target.get("id")=="lodge");interact();await frames(70)
 assert(survival.fires.lodge>0 and world.fire_meshes.lodge.visible and world.fire_lights.lodge.light_energy>0)
 for at in [Vector2(-11,74.6),Vector2(-13.5,74.25)]:await walk_to(at)
 update_target();assert(target.get("id")=="lodge_bed","Sleep bay stays accessible past the low divider")
 interact();await frames();assert(backpack.visible)
 backpack.rest_hours=1;backpack.refresh();var before:float=survival.elapsed
 backpack.do_action("rest","1");assert(survival.elapsed>=before+60 and survival.health>0)
 toggle_backpack();await frames();await shot("04-bed-and-fire")
 for at in [Vector2(-11,74.6),Vector2(-11,72),Vector2(-10.9,71.0)]:await walk_to(at)
 update_target();assert(target.get("id")=="lodge_route");interact();await frames(55)
 assert(survival.discovered.has("lodge_route"));toggle_backpack();await frames()
 save_game();load_game();await frames();assert(not fuel[0].visible and fuel[1].visible)
 for at in [Vector2(-11,74.8),Vector2(-11,79),Vector2(-3,79),Vector2(-3,69)]:await walk_to(at)
 assert(interior_view.room.is_empty() and lodge.find_child("CutawayRight",true,false).visible)
 # Static lighting comparison, separate from the input/rest assertions above.
 player.position=Vector3(-11,.3,74.8);survival.elapsed=720;await frames(40);await shot("05-night-fire")
 var review:=Camera3D.new();add_child(review);review.projection=Camera3D.PROJECTION_ORTHOGONAL;review.size=13;review.cull_mask=interior_view.OUTDOOR_VIEW
 player.position=Vector3(-11,.3,81);survival.elapsed=0;await frames(40)
 var focus:=Vector3(-10.2,1.4,73);review.position=focus+Vector3(10,7,13);review.look_at(focus);review.current=true;canvas.visible=false;await shot("06-material-review")
 active=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();await frames(12);OS.delay_msec(100)
 print("LODGE_CHECK_OK: independent log cabin materials, side shed cutaway, physical finite fuel, door/stove/bed/note paths, actual rest, save restore, exterior bypass")
 get_tree().quit()
