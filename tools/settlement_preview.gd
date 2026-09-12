extends "res://scripts/main.gd"
# Static art review only; first_night_check is the real input/overnight evidence.
func _ready()->void:
 super._ready();call_deferred("review")
func frames(n:=15)->void:
 for i in range(n):await get_tree().process_frame
func capture(id:String)->void:
 await frames();RenderingServer.force_draw(false);await get_tree().process_frame
 get_viewport().get_texture().get_image().save_png("res://artifacts/first-night/"+id+".png")
func review()->void:
 start_new();opening.finish();active=false;player.enabled=false;set_process(false);canvas.visible=false
 title_screen.set_process(false);title_screen.music.stop();await frames()
 var camera:=Camera3D.new();add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=49;camera.cull_mask=interior_view.OUTDOOR_VIEW & ~8;camera.current=true
 var focus:=Vector3(-6,0,78);camera.position=focus+Vector3(26,38,36);camera.look_at(focus)
 survival.light_fire("lodge")
 for entry in world.cutaways:
  for node in entry.nodes:node.visible=true
 world.sun.light_cull_mask=0xfffff;world.night_fill.light_cull_mask=0xfffff
 world.weather_update(.15,focus,survival.fires,510);await capture("09-settlement-dusk")
 world.weather_update(.50,focus,survival.fires,690);await capture("10-settlement-night")
 for id in ["canteen","woodshed","bunkhouse"]:
  var center:Vector3=world.buildings[id].position
  for key in ["Roof","CutawayFront","CutawayRight"]:world.buildings[id].find_child(key,true,false).visible=false
  camera.cull_mask=int(survival.Arrival.SITES[id].layer);camera.size=11;camera.environment=interior_view.indoor_environment
  camera.position=center+Vector3(9,12,13);camera.look_at(center+Vector3(0,.6,0))
  await capture("11-"+id+"-interior")
 cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();await frames();OS.delay_msec(150)
 print("SETTLEMENT_PREVIEW_OK: static exterior lighting and furnished cutaway reviews")
 get_tree().quit()
