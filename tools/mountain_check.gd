extends "res://tools/building_check.gd"
func shot(id:String)->void:
 if DisplayServer.get_name()=="headless":return
 await frames(12);RenderingServer.force_draw(false);await get_tree().process_frame
 assert(get_viewport().get_texture().get_image().save_png("res://artifacts/mountain-pass/"+id+".png")==OK)
func check_buildings()->void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/mountain-pass"))
 save_path="res://artifacts/mountain-pass/manual.json"
 start_new();opening.finish();await frames()
 assert(survival.count("food")==0 and survival.hunger>=30 and survival.count("water")==1)
 assert(world.get_node_or_null("SouthRoadClosure")==null and world.get_node_or_null("MountainPass")!=null)
 assert(world.terrain_height(-12,134)>6 and world.terrain_height(21,141)>3)
 for at in [Vector2(0,130),Vector2(0,126),Vector2(0,121),Vector2(12,118)]:
  assert(world.Terrain.normal(at.x,at.y).y>.9,"Snow passage remains walkable without jumping")
 var kiosk:Node3D=world.buildings.gatehouse
 assert(kiosk.scene_file_path.ends_with("road_kiosk_v3.glb"))
 var textured:Array=[]
 for node in kiosk.find_children("*","MeshInstance3D",true,false):
  for i in range(node.mesh.get_surface_count()):
   var material=node.get_active_material(i)
   if material is StandardMaterial3D and material.resource_name in ["KioskPaint","KioskWood","KioskMetal"]:
    assert(material.albedo_texture!=null and material.normal_enabled and material.normal_texture!=null and material.roughness_texture!=null,"Baked materials survive GLB import and runtime overrides")
    if not textured.has(material.resource_name):textured.append(material.resource_name)
 assert(textured.size()==3 and mesh_bounds(kiosk.find_child("Roof",true,false)).size.z>7)
 await shot("01-pass-start")
 # Opening shows the pass only; survival is frozen and can be skipped.
 var elapsed:float=survival.elapsed;opening.begin()
 for i in range(3):
  await frames(20);assert(survival.elapsed==elapsed and opening.CARDS[i][2].z>=126)
  await shot("opening-%d"%i)
  if i<2:opening.advance()
 opening.finish();await frames()
 await walk_to(Vector2(0,125));await shot("02-shoulders")
 await walk_to(Vector2(0,121));assert(survival.discovered.has("pass_exit"))
 assert(Chapter.objective(survival).contains("岗亭"))
 # One optional log off the food route; normal targeted interaction, persisted once.
 await walk_to(Vector2(-4.7,122));update_target();assert(target.get("id")=="pass_dry_wood")
 var count:int=survival.wood;interact();await frames(65)
 assert(survival.wood==count+1 and survival.collected.has("pass_dry_wood"))
 var log_node:Node3D=world.points.filter(func(p):return p.id=="pass_dry_wood")[0].node
 assert(not log_node.visible)
 for at in [Vector2(0,121),Vector2(12,118),Vector2(12,113.3)]:await walk_to(at)
 player.zoom=20;await frames(25);await shot("03-kiosk-exterior")
 assert(not survival.discovered.has("gatehouse") and not survival.discovered.has("gate_route"))
 for at in [Vector2(12,113),Vector2(12,109),Vector2(12.4,108.2)]:await walk_to(at)
 assert(interior_view.room=="gatehouse" and survival.discovered.has("gatehouse"))
 update_target();assert(target.get("id")=="gate_desk");interact();await frames(110)
 backpack.selected="food";backpack.refresh();await frames();await shot("04-first-food")
 assert(survival.count("food")==0)
 backpack.do_action("take_supply","food");assert(survival.count("food")==1)
 var before:float=survival.hunger;backpack.tab="items";backpack.selected="food";backpack.refresh();backpack.do_action("use","food")
 assert(survival.count("food")==0 and survival.hunger>before+30)
 await frames(90);toggle_backpack();await frames(40);await shot("05-kiosk-interior")
 save_game();var saved:Dictionary=survival.data();load_game();await frames()
 assert(survival.supply_taken==saved.supply_taken and not log_node.visible and survival.count("food")==0)
 assert(not world.arrival.stocks.gate_desk.food[0].visible)
 # Existing pre-arrival saves do not become a hungry new journey on restore.
 var legacy=Survival.new();legacy.items.food=3;var raw:Dictionary=legacy.data();raw.erase("arrival_journey")
 var restored=Survival.new();assert(restored.restore(raw) and restored.count("food")==3 and not restored.arrival_journey)
 active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();await frames(12);OS.delay_msec(100)
 print("MOUNTAIN_CHECK_OK: layered terrain, imported painted materials, pass-only opening, no-food start, visible detour, first food input/use, room cutaway, save/old-state")
 get_tree().quit()
