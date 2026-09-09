extends "res://scripts/main.gd"
func _ready()->void:
 super._ready();call_deferred("check_aim")

func settle(n:int=6)->void:
 for i in range(n):await get_tree().physics_frame

func shot(id:String)->void:
 if not OS.get_cmdline_user_args().has("--aim-preview"):return
 await RenderingServer.frame_post_draw
 var folder:="res://artifacts/aim-"+str(DisplayServer.window_get_size().x)
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
 get_viewport().get_texture().get_image().save_png(folder+"/"+id+".png")

func check_aim()->void:
 start_new();await settle()
 for a in field.animals:a.set_physics_process(false)
 player.position=Vector3(0,world.terrain_height(0,33)+.1,33);player.velocity=Vector3.ZERO
 player.enabled=false
 survival.items={"bow":1,"arrow":4,"knife":1};survival.kit.weapon="bow";field.update_held()
 await settle()
 field.set_process(false)
 var target_at:Vector3=player.position+Vector3(4,0,-7)
 target_at.y=world.terrain_height(target_at.x,target_at.z)
 var screen_target:Vector2=player.camera.unproject_position(target_at)
 get_viewport().warp_mouse(screen_target)
 field.update_aim(.6,true)
 assert(field.drawing and is_equal_approx(field.aim_time,.6) and field.draw_audio.playing,"Right aim starts audible charge")
 await settle(2)
 assert(field.feedback.cursor_active and field.feedback.preview.size()>1 and field.feedback.mouse_filter==Control.MOUSE_FILTER_IGNORE)
 assert(not help_label.visible and field.context_text().is_empty(),"No idle shortcut spam")
 assert(toast.get_rect().end.y<prompt.position.y and prompt.get_rect().end.y<canvas.size.y-124,"Independent text lanes")
 assert(status_hud.size.is_equal_approx(canvas.size),"Vitals fill the current viewport")
 await shot("aim")
 # Preview and real projectile stop at the same first collision.
 var predicted:PackedVector3Array=field.predict_arrow(target_at)
 var expected:Vector3=predicted[-1]
 field.shoot(target_at,true)
 assert(survival.count("arrow")==3 and field.release_audio.playing and not field.draw_audio.playing)
 await settle(5);await shot("flight")
 await settle(150)
 assert(field.projectiles.is_empty() and field.recoveries.size()==1)
 assert(field.recoveries[0].mesh.position.distance_to(expected)<.025,"Trajectory agrees with actual impact")
 field.cooldown=0;field.update_aim(.4,true);active=false;field.update_aim(.1,true)
 assert(not field.drawing and field.aim_time==0 and not field.draw_audio.playing,"Pause cancels charge and sound")
 await settle(2);assert(not field.feedback.visible)
 active=true;map.visible=true;field.update_aim(.1,true);field.shoot(target_at,true)
 assert(not field.drawing and survival.count("arrow")==3,"Map blocks aim and fire")
 map.visible=false;field.update_aim(.3,true);survival.kit.weapon="knife";field.update_held()
 assert(not field.drawing and not field.draw_audio.playing,"Switch cancels bow draw")
 # Audio playback uses wall time, while headless fixed-fps can advance faster.
 field.release_audio.stop()
 survival.kit.weapon="bow";survival.items.arrow=0;field.update_aim(.2,true);field.shoot(target_at,true)
 assert(not field.drawing and not field.release_audio.playing and survival.count("arrow")==0,"Empty bow has no phantom shot")
 survival.items.arrow=3;field.update_held();field.cancel_aim()
 notify("雪地上的痕迹很新。先查看周围，再决定是否继续前进。")
 update_hud("",false);await settle(2);await shot("quiet")
 assert(field.feedback.preview.is_empty())
 # Exercise the actual input path as well as the deterministic trajectory check.
 field.set_process(true);field.cooldown=0
 var right:=InputEventMouseButton.new();right.button_index=MOUSE_BUTTON_RIGHT;right.pressed=true;right.position=screen_target
 Input.parse_input_event(right);await settle(12)
 assert(field.drawing and field.aim_time>0,"Real right mouse input drives charge")
 var left:=InputEventMouseButton.new();left.button_index=MOUSE_BUTTON_LEFT;left.pressed=true;left.position=screen_target
 Input.parse_input_event(left);await settle(2)
 assert(survival.count("arrow")==2 and field.release_audio.playing,"Real left click releases one arrow")
 left.pressed=false;right.pressed=false;Input.parse_input_event(left);Input.parse_input_event(right)
 await settle(2);assert(not field.drawing)
 active=false;set_process(false);field.cancel_aim();field.release_audio.stop()
 cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();field.audio.stop();field.audio.stream=null
 await settle();OS.delay_msec(120)
 print("AIM_OK: charge, sounds, preview/impact agreement, pause/map/switch/empty, responsive HUD")
 get_tree().quit()
