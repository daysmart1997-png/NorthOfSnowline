extends "res://scripts/main.gd"
# Static art review, not a claimed input playthrough. Player save/settings remain isolated.
func _ready()->void:
 super._ready();call_deferred("preview")
func frames(n:int=20)->void:
 for i in range(n):await get_tree().process_frame
func shot(id:String)->void:
 await frames();RenderingServer.force_draw(false);await get_tree().process_frame
 assert(get_viewport().get_texture().get_image().save_png("res://artifacts/mountain-pass/"+id+".png")==OK)
func preview()->void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/mountain-pass"))
 start_new();opening.finish();active=false;player.enabled=false
 for row in [["start-review",Vector3(0,0,130)],["exit-review",Vector3(0,0,121)],["kiosk-review",Vector3(12,0,113.3)],["room-review",Vector3(12.4,0,108.2)]]:
  player.position=row[1];player.position.y=world.terrain_height(player.position.x,player.position.z)+.2
  await frames(45);await shot(row[0])
 player.position=Vector3(12,.3,116);await frames(30)
 var review:=Camera3D.new();add_child(review);review.projection=Camera3D.PROJECTION_ORTHOGONAL;review.size=11;review.cull_mask=interior_view.OUTDOOR_VIEW
 var focus:=Vector3(12,1.3,109);review.position=focus+Vector3(9,6.5,12);review.look_at(focus);review.current=true
 canvas.visible=false;await shot("kiosk-material-review")
 review.current=false;player.camera.current=true
 active=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();await frames(12);OS.delay_msec(100)
 print("MOUNTAIN_PREVIEW_OK: native static game-camera views and separate material inspection camera")
 get_tree().quit()
