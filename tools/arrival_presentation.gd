extends "res://scripts/main.gd"
func _ready()->void:
 super._ready();call_deferred("verify")
func frames(n:int=8)->void:
 for i in range(n):await get_tree().process_frame
func picture(id:String)->void:
 if DisplayServer.get_name()=="headless":return
 await frames(3);RenderingServer.force_draw(false);await get_tree().process_frame
 assert(get_viewport().get_texture().get_image().save_png("res://artifacts/arrival/"+id+".png")==OK)
func verify()->void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/arrival"))
 await frames();start_new();opening.finish();active=false;player.enabled=false
 player.position=Vector3(0,.3,130);await frames();await picture("south-exterior")
 survival.items={"wood":1,"water":1,"food":1,"cloth":1,"bandage":1,"battery":1,"player":1}
 backpack.tab="items";backpack.visible=true;preferences.large_text=true
 for id in survival.Arrival.ITEMS:
  backpack.selected=id;backpack.refresh();await frames(5)
  assert(backpack.position.y+backpack.size.y<=get_viewport().get_visible_rect().size.y,"Six physical previews fit with the cassette dock")
  var previews=backpack.find_children("*","SubViewportContainer",true,false);assert(previews.size()==1)
  var preview=previews[0];assert(preview.model!=null)
  var rotation:float=preview.model.rotation.y
  var down:=InputEventMouseButton.new();down.button_index=MOUSE_BUTTON_LEFT;down.pressed=true;preview._gui_input(down)
  var drag:=InputEventMouseMotion.new();drag.relative=Vector2(25,0);preview._gui_input(drag);assert(preview.model.rotation.y>rotation)
  down.pressed=false;preview._gui_input(down)
  await picture("item-"+id)
 # Last unit still shows its use movement before the empty slot leaves the list.
 backpack.selected="water";backpack.refresh();backpack.do_action("use","water");await frames(8)
 assert(survival.count("water")==0 and backpack.selected=="water")
 var preview=backpack.find_children("*","SubViewportContainer",true,false)[0]
 assert(absf(preview.model.rotation.z)>.01 and preview.model.find_child("Cap",true,false).position.y>0)
 await picture("water-use")
 await frames(90);assert(backpack.selected!="water")
 backpack.visible=false
 for id in ["gatehouse","lodge"]:
  var site:Dictionary=survival.Arrival.SITES[id]
  player.position=site.at+Vector3(0,.3,0);await frames(100)
  assert(interior_view.room==id and world.stamp_snow(player.position,0,1,true)==0)
  assert(cassette.wind_filter.cutoff_hz>2500 if id=="gatehouse" else cassette.wind_filter.cutoff_hz<1400)
  # Check both outside silhouettes without the cutaway.
  player.position=site.at+Vector3(0,.3,9);await frames(30);await picture(id+"-exterior")
 player.position=Vector3(-11,.3,74.8);survival.elapsed=720;survival.items.wood=3;survival.items.food=2;survival.items.water=2;survival.hunger=65;survival.thirst=65
 survival.light_fire("lodge");await frames(40);await picture("lodge-night")
 var preview_rest:Dictionary=survival.rest_preview("lodge",4);assert(preview_rest.fire_short and preview_rest.problem=="")
 survival.rest("lodge",4);assert(survival.health>0 and survival.temperature>18)
 assert(not survival.ArrivalState.valid({"placed_serial":1,"placed_items":[{"id":0,"item":"wood","position":[0,0,130]},{"id":0,"item":"wood","position":[0,0,130]}]}))
 assert(not survival.ArrivalState.valid({"supply_taken":{"gate_desk":{"food":2}}}))
 assert(not survival.ArrivalState.valid({"supply_taken":{"gate_desk":{"food":.5}}}))
 active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();await frames(15)
 # Headless fixed-fps frames can outpace the audio driver's release queue.
 OS.delay_msec(100)
 print("ARRIVAL_PRESENTATION_OK: six real previews, drag/use-last-unit, 720p/large/cassette, room sound/footprints, exteriors/night rest, malformed state")
 get_tree().quit()
