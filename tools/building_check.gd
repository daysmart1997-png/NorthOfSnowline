extends "res://scripts/main.gd"
# Real collision / input checks for the differentiated interiors. No player saves.
func _ready()->void:
 super._ready();call_deferred("check_buildings")

func frames(count:int=8)->void:
 for i in range(count):await get_tree().physics_frame

func release_movement()->void:
 for action in ["move_left","move_right","move_up","move_down"]:Input.action_release(action)

func walk_to(at:Vector2)->void:
 var remaining:=900
 while Vector2(player.position.x,player.position.z).distance_to(at)>.22:
  assert(remaining>0,"Furniture/door route blocked toward "+str(at)+" at "+str(player.position));remaining-=1
  var direction:=Vector3(at.x-player.position.x,0,at.y-player.position.z).normalized()
  var stick:=Basis(Vector3.UP,player.pivot.rotation.y).inverse()*direction
  for pair in [["move_left",maxf(-stick.x,0)],["move_right",maxf(stick.x,0)],["move_up",maxf(-stick.z,0)],["move_down",maxf(stick.z,0)]]:
   if pair[1]>.001:Input.action_press(pair[0],pair[1])
   else:Input.action_release(pair[0])
  await get_tree().physics_frame
 release_movement();await frames(8)

func optional_shot(id:String)->void:
 if not OS.get_cmdline_user_args().has("--building-preview"):return
 var folder:="res://artifacts/architecture-review/walkthrough"
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
 player.zoom=13.5;player.camera.size=13.5;await frames(12)
 RenderingServer.force_draw(false);await get_tree().process_frame
 assert(get_viewport().get_texture().get_image().save_png(folder+"/"+id+".png")==OK)

func mesh_bounds(root:Node3D)->AABB:
 var result:=AABB();var first:=true
 for visual in root.find_children("*","MeshInstance3D",true,false):
  var bounds:AABB=(root.global_transform.affine_inverse()*visual.global_transform)*visual.get_aabb()
  result=bounds if first else result.merge(bounds);first=false
 return result

func check_buildings()->void:
 start_new();player.position=Vector3(0,world.terrain_height(0,38)+.2,38);player.velocity=Vector3.ZERO;await frames()
 # This suite isolates the existing buildings; arrival_check covers the new spawn route.
 var home:Node3D=world.buildings.home;var station:Node3D=world.buildings.station
 assert(home.scene_file_path.ends_with("cabin_lived.glb") and station.scene_file_path.ends_with("station_workshop.glb"))
 assert(home.find_child("HomeBedding",true,false)!=null and home.find_child("KitchenChair",true,false)!=null)
 assert(station.find_child("FoldingCot",true,false)!=null and station.find_child("RepairWorkbench",true,false)!=null)
 # A shared shell would pass interior gameplay tests; verify different silhouettes.
 var home_roof:=mesh_bounds(home.find_child("Roof",true,false))
 var station_roof:=mesh_bounds(station.find_child("Roof",true,false))
 assert(station_roof.size.x>home_roof.size.x+.8 and station_roof.end.y<home_roof.end.y-.7,"Workshop is visibly wider and lower")
 assert(world.shelter_at(Vector3(4.6,.24,-168))=="station")
 assert(world.shelter_at(Vector3(5.1,.24,-168)).is_empty())
 assert(world.shelter_at(Vector3(4.6,.24,20)).is_empty())
 # Walk the central route, then reach the new chair side, stove and old radio.
 await walk_to(Vector2(0,27));await walk_to(Vector2(0,20))
 await walk_to(Vector2(2.55,20.4));await walk_to(Vector2(3.30,19));await walk_to(Vector2(3.30,17.5))
 update_target();assert(target.get("id")=="home","Stove remains reachable around the chair")
 survival.items.wood=8;interact();await frames(90)
 assert(survival.fires.home>0 and world.fire_meshes.home.visible)
 await optional_shot("home-stove")
 for at in [Vector2(3.30,19),Vector2(2.55,20.4),Vector2(0,20.4),Vector2(-2.4,18.2)]:await walk_to(at)
 update_target();assert(target.get("id")=="radio","Shifted bedding leaves the receiver accessible")
 # Upgrade visibility and storage remain in the room; no orphaned collisions.
 survival.upgrades.bed=true;survival.upgrades.storage=true;world.sync_buildings(survival);await frames()
 assert(home.find_child("UpgradeBed",true,false).visible and home.find_child("StorageChest",true,false).visible)
 assert(not home.get_node("StorageCollision").get_child(0).disabled)
 survival.upgrades.storage=false;world.sync_buildings(survival);await frames()
 assert(home.get_node("StorageCollision").get_child(0).disabled)
 await walk_to(Vector2(0,20.4));await walk_to(Vector2(0,27))
 assert(interior_view.room.is_empty() and world.track_marks.size()>0)
 # Test-only relocation between sites. All doorway/furniture routes use inputs.
 player.position=Vector3(0,.24,-160);player.velocity=Vector3.ZERO;await frames()
 await walk_to(Vector2(0,-167));await walk_to(Vector2(-2.4,-169.8))
 assert(interior_view.room=="station")
 var socket:Node3D=station.find_child("ModuleSurface",true,false)
 assert(experience.module_root.global_position.is_equal_approx(socket.global_position))
 assert(experience.contact.global_position.y-.009>1.196,"Contacts sit above the bench and repair mat")
 await optional_shot("station-module-before")
 for i in range(3):
  update_target();assert(target.get("id")=="radio_parts")
  interact();await frames(300)
  assert(survival.kit.route_stage==i+1,"Workbench job must finish through normal timed interaction")
 await optional_shot("station-module-tested")
 update_target();interact();await frames(90);assert(survival.parts)
 close_story();await optional_shot("station-workbench")
 await walk_to(Vector2(0,-168));await walk_to(Vector2(1.3,-170.2))
 update_target();assert(target.get("id")=="station")
 interact();await frames(90);assert(survival.fires.station>0 and world.fire_meshes.station.visible)
 for at in [Vector2(1.3,-168),Vector2(3.23,-168.5)]:await walk_to(at)
 update_target();assert(target.get("id")=="station_bed","Relocated cot has a reachable rest interaction")
 interact();await frames();assert(backpack.visible and backpack.tab=="craft")
 var elapsed:float=survival.elapsed;backpack_action("rest","1");assert(survival.elapsed==elapsed+60)
 toggle_backpack();await optional_shot("station-cot")
 # Actually walk into the newly widened room strip, retaining shelter and cutaway.
 await walk_to(Vector2(3.23,-167));await walk_to(Vector2(4.52,-167))
 assert(interior_view.room=="station" and world.shelter_at(player.position)=="station" and world.surface_at(player.position)=="wood")
 assert(not station.find_child("Roof",true,false).visible and player.camera.cull_mask==76)
 var pose:=player.global_transform
 assert(player.test_move(pose,Vector3(1,0,0)),"Widened side wall stops the player")
 await walk_to(Vector2(0,-167));await walk_to(Vector2(0,-160))
 assert(interior_view.room.is_empty() and station.find_child("Roof",true,false).visible)
 active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
 await frames();OS.delay_msec(100)
 print("BUILDING_CHECK_OK: distinct prefabs, input-driven room/door/chair routes, both stoves, radio, three timed module stages, cot/rest, upgrades/storage, extended shelter/floor/cutaway/wall, outdoor footprints")
 get_tree().quit()
