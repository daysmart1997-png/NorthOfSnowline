extends "res://tools/building_check.gd"
const Arrival=preload("res://scripts/arrival_catalog.gd")
const ArrivalState=preload("res://scripts/arrival_state.gd")
func shot(id:String)->void:
 if DisplayServer.get_name()=="headless":return
 await frames(12);RenderingServer.force_draw(false);await get_tree().process_frame
 assert(get_viewport().get_texture().get_image().save_png("res://artifacts/arrival/"+id+".png")==OK)
func check_buildings()->void:
 await frames();start_new();opening.finish();await frames()
 assert(player.position.z>125 and survival.arrival_journey and not survival.discovered.has("home_reached"))
 assert(Chapter.objective(survival).contains("山口") and survival.count("food")==0 and survival.hunger>25)
 await shot("start")
 # Continuous input walk from the actual new spawn into the small cold shelter.
 for at in [Vector2(0,121),Vector2(12,118),Vector2(12,113)]:await walk_to(at)
 assert(not survival.discovered.has("gatehouse"),"Approaching does not mark an unentered shelter")
 for at in [Vector2(12,109),Vector2(12.4,108.2)]:await walk_to(at)
 assert(survival.discovered.has("gatehouse") and not survival.discovered.has("gate_route"),"Entering discovers the room, not its unread paper")
 assert(world.shelter_at(player.position)=="gatehouse" and interior_view.room=="gatehouse")
 assert(survival.rest_problem("gatehouse",1).contains("没有卧铺") and not survival.fires.has("gatehouse"))
 assert(survival.temperature_rate("gatehouse",false)<survival.temperature_rate("lodge",false))
 await shot("kiosk")
 update_target();assert(target.get("id")=="gate_desk","Reach the supply on the desk without clipping furniture")
 interact();await frames(110);assert(backpack.visible and backpack.tab=="search")
 await shot("search")
 var before:=survival.data();var food_before:int=survival.count("food")
 assert(arrival_items.take("gate_desk","food").contains("收好"));assert(survival.count("food")==food_before+1)
 arrival_items.take("gate_desk","food");assert(survival.count("food")==food_before+1)
 assert(not world.arrival.stocks.gate_desk.food[0].visible and world.arrival.stocks.gate_desk.water[0].visible)
 # Full inventory preserves the remaining supply, and UI shows disabled take.
 var held:Dictionary=survival.items.duplicate();survival.items={"wood":20}
 var taken_before:Dictionary=survival.supply_taken.duplicate(true)
 assert(arrival_items.take("gate_desk","water").contains("余量不足"));assert(survival.supply_taken==taken_before)
 survival.items=held;backpack.tab="items";backpack.selected="water";backpack.refresh();await frames()
 assert(backpack.size.y<=get_viewport().get_visible_rect().size.y-40,"Item preview fits 720p")
 await shot("flask")
 var count_before:int=survival.count("water")
 assert(arrival_items.place("water").contains("放下"));assert(survival.count("water")==count_before-1 and survival.placed_items.size()==1)
 var key:int=survival.placed_items[0].id;assert(arrival_items.drops[key].get_child(0)!=null)
 var mesh:VisualInstance3D=arrival_items.drops[key].find_children("*","VisualInstance3D",true,false)[0]
 assert(mesh.layers==256,"Placed prop respects the indoor camera layer")
 var path:="res://artifacts/arrival/state.json";var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(survival.data()));f.close()
 var restored=Survival.new();assert(restored.restore(JSON.parse_string(FileAccess.get_file_as_string(path))))
 assert(restored.supply_taken==survival.supply_taken and restored.placed_items.size()==1)
 var invalid:Dictionary=survival.data();invalid.placed_items[0].position[0]=INF
 var snapshot:Dictionary=restored.data();assert(not restored.restore(invalid) and restored.data()==snapshot,"Malformed new fields restore atomically")
 assert(arrival_items.recover(key).contains("收回") and survival.count("water")==count_before)
 arrival_items.recover(key);assert(survival.count("water")==count_before)
 # Legacy saves never reset their journey or duplicate existing goods.
 var legacy:Dictionary=before.duplicate(true)
 for field_name in ["arrival_journey","supply_taken","placed_items","placed_serial"]:legacy.erase(field_name)
 assert(restored.restore(legacy) and not restored.arrival_journey and restored.placed_items.is_empty())
 backpack.visible=false;active=true;player.enabled=true
 await walk_to(Vector2(11.5,108.2));update_target();assert(target.get("id")=="gate_route")
 interact();await frames(55);assert(survival.discovered.has("gate_route"));assert(Chapter.objective(survival).contains("临时木屋"))
 backpack.visible=false;active=true;player.enabled=true
 for at in [Vector2(12,110),Vector2(12,116),Vector2(0,103),Vector2(-11,84),Vector2(-11,78),Vector2(-11,74.8)]:await walk_to(at)
 assert(interior_view.room=="lodge" and world.shelter_at(player.position)=="lodge")
 await shot("lodge")
 await walk_to(Vector2(-9.5,75.35));update_target();assert(target.get("id")=="lodge_stores")
 interact();await frames(110)
 assert(arrival_items.take("lodge_stores","wood").contains("收好"))
 assert(arrival_items.take("lodge_stores","bandage").contains("收好"))
 assert(arrival_items.take("lodge_stores","battery").contains("收好"))
 backpack.visible=false;active=true;player.enabled=true
 for at in [Vector2(-11,75.2),Vector2(-11,72),Vector2(-9.6,71.8)]:await walk_to(at)
 update_target();assert(target.get("id")=="lodge");interact();await frames(60)
 assert(survival.fires.lodge>0 and survival.temperature_rate("lodge",false)>0)
 var rest:Dictionary=survival.rest_preview("lodge",4);assert(rest.problem=="" and rest.fire_short)
 await shot("fire")
 await walk_to(Vector2(-10.9,71.0));update_target();assert(target.get("id")=="lodge_route")
 interact();await frames(55);assert(survival.discovered.has("lodge_route"))
 backpack.visible=false;active=true;player.enabled=true
 for at in [Vector2(-11,74.8),Vector2(-11,79),Vector2(-3,79),Vector2(-3,70),Vector2(0,61),Vector2(0,43),Vector2(0,27),Vector2(0,20.5)]:await walk_to(at)
 assert(survival.discovered.has("home_reached") and Chapter.objective(survival).contains("无线电"))
 map.visible=true;await shot("map");map.visible=false
 var safe=Survival.new();safe.temperature=65;safe.items={"wood":5,"food":2,"water":2};safe.light_fire("lodge")
 var expected:Dictionary=safe.rest_preview("lodge",1);safe.rest("lodge",1);assert(absf(safe.temperature-expected.temperature)<.01)
 assert(world.height_texture.get_height()==761 and world.biome_texture.get_height()==761)
 # Start-new clears all containers and dropped props but retains the authored buildings.
 start_new();opening.finish();await frames();assert(survival.supply_taken.is_empty() and arrival_items.drops.is_empty() and world.arrival.stocks.gate_desk.food[0].visible)
 active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();await frames(12)
 OS.delay_msec(100)
 print("ARRIVAL_CHECK_OK: new route input, distinct rooms/heat/beds, selective supplies, capacity/repeat/save/legacy, physical drops/layers, preview, map, reset")
 get_tree().quit()
