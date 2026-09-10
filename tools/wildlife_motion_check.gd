extends "res://scripts/main.gd"
var motion_preview:=false
var motion_camera:Camera3D

func _ready()->void:
 super._ready();call_deferred("check_motion")

func frames(count:int)->void:
 for i in range(count):await get_tree().physics_frame

func picture(deer,id:String)->void:
 if not motion_preview:return
 motion_camera.position=deer.position+deer.model.basis*Vector3(4,2.4,2)
 motion_camera.look_at(deer.position+Vector3.UP*.9)
 await frames(2)
 RenderingServer.force_draw(false)
 var image:=get_viewport().get_texture().get_image()
 assert(image.save_png("res://artifacts/deer-motion/"+id+".png")==OK)

func check_motion()->void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/deer-motion"))
 motion_preview=OS.get_cmdline_user_args().has("--motion-preview")
 start_new();player.position=Vector3(0,.24,19);player.enabled=false;await frames(8)
 var deer=field.find_animal("deer_0");var other=field.find_animal("deer_1")
 if motion_preview:
  canvas.visible=false;motion_camera=Camera3D.new();add_child(motion_camera)
  motion_camera.projection=Camera3D.PROJECTION_ORTHOGONAL;motion_camera.size=4.6
  motion_camera.cull_mask=interior_view.OUTDOOR_VIEW;motion_camera.current=true
  world.sun.light_cull_mask=0xfffff;world.night_fill.light_cull_mask=0xfffff
 var prior:=[Vector3.ZERO,Vector3.ZERO];var turns:=[0,0];var knee_range:=0.0
 var max_home:=[0.0,0.0]
 # Both authored spawns, actual terrain and collision, 40 seconds of wandering.
 for i in range(2400):
  var before:=[deer.position,other.position]
  await frames(1)
  for j in range(2):
   var a=deer if j==0 else other
   var step:Vector3=a.position-before[j];step.y=0
   if step.length()>.001 and prior[j].length()>.001 and step.angle_to(prior[j])>PI*.55:turns[j]+=1
   prior[j]=step;max_home[j]=maxf(max_home[j],Vector2(a.position.x-a.home.x,a.position.z-a.home.z).length())
  knee_range=maxf(knee_range,absf(deer.shins[0].rotation.x-deer.shin_rest[0].x))
  if i in [260,270,280,1600]:await picture(deer,"walk-%d"%i)
 assert(turns[0]<8 and turns[1]<8,"No repeated frame-to-frame reversals at the home boundary")
 assert(max_home[0]>4.8 and max_home[1]>4.8,"Exercise the actual old return boundary")
 assert(knee_range>.1,"Walking bends the knee, not only a rigid hip pendulum")
 # A remembered threat beyond the old 28m leash must not alternate flee/return.
 deer.position=deer.home+Vector3(31,0,0);deer.position.y=world.terrain_height(deer.position.x,deer.position.z)+.08
 deer.last_known=deer.position-Vector3(8,0,0);deer.alert=.5;deer.memory=5
 var flee_frames:=0
 for i in range(90):
  await frames(1)
  if deer.state=="逃离":flee_frames+=1
  if i in [40,46,52]:await picture(deer,"flee-%d"%i)
 assert(flee_frames==90,"Deer escape remains stable beyond the predator leash")
 # A small real enclosure stops locomotion; leg motion must settle too.
 deer.alert=0;deer.memory=0;deer.fleeing=false;deer.velocity=Vector3.ZERO
 deer.position=field.safe_spawn(Vector3(0,0,29));deer.position.y=world.terrain_height(deer.position.x,deer.position.z)+.04
 deer.home=deer.position
 var cage:=Node3D.new();add_child(cage);cage.position=deer.position
 for side in [Vector3(.75,0,0),Vector3(-.75,0,0),Vector3(0,0,.75),Vector3(0,0,-.75)]:
  var wall:=StaticBody3D.new();cage.add_child(wall);wall.position=side+Vector3.UP
  var collision:=CollisionShape3D.new();var box:=BoxShape3D.new()
  box.size=Vector3(.1,2,2) if side.x!=0 else Vector3(2,2,.1);collision.shape=box;wall.add_child(collision)
 await frames(150)
 assert(deer.gait_weight<.05,"Blocked movement settles the gait instead of walking in place")
 await picture(deer,"stopped")
 var pose:Transform3D=deer.legs[0].transform;var at:Vector3=deer.position
 active=false;await frames(20)
 assert(deer.position==at and deer.legs[0].transform==pose,"Pause freezes movement and pose together")
 cage.queue_free();set_process(false);field.set_process(false)
 cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();field.audio.stop();field.audio.stream=null
 await frames(4);OS.delay_msec(120)
 print("WILDLIFE_MOTION_OK: 40s reversals=%s, boundary=%s, knee=%.3f, sustained escape, blocked gait, pause"%[turns,max_home,knee_range])
 get_tree().quit()
