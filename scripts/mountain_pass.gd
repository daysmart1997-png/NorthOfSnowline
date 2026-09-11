extends Node3D
# Background mountains are authored in Blender; nearby snow shoulders share terrain collision.
func build(world)->void:
 name="MountainPass"
 var ridge:Node3D=load("res://assets/mountain_pass/mountain_ridge.glb").instantiate();add_child(ridge)
 var rock:=ShaderMaterial.new();rock.shader=load("res://assets/shaders/mountain_rock.gdshader")
 for mesh in ridge.find_children("*","MeshInstance3D",true,false):mesh.material_override=rock
 for row in [[Vector3(-6.2,0,129),1.35,.7],[Vector3(-8.5,0,123),1.25,.2],[Vector3(-10,0,136),1.55,-.3],[Vector3(17,0,136),1.15,-.8]]:
  var rib:Node3D=load("res://assets/mountain_pass/cliff_ribs.glb").instantiate();add_child(rib)
  rib.position=row[0];rib.position.y=world.terrain_height(rib.position.x,rib.position.z)-.8;rib.scale=Vector3.ONE*row[1];rib.rotation.y=row[2]
  for visual in rib.find_children("*","MeshInstance3D",true,false):visual.material_override=rock;visual.create_trimesh_collision()
 # Small human traces lead to the kiosk without showing the next shelters.
 for at in [Vector3(7,0,121),Vector3(14,0,116)]:
  at.y=world.terrain_height(at.x,at.z)
  world.box(at+Vector3(0,1.8,0),Vector3(.17,3.6,.17),"5b584e",true,self)
  world.box(at+Vector3(0,3.32,0),Vector3(1.3,.12,.12),"575a56",false,self)
  for x in [-.45,.45]:world.box(at+Vector3(x,3.44,0),Vector3(.12,.18,.12),"909895",false,self)
 # A visible optional detour costs walking time, grants one finite dry log.
 var at:=Vector3(-5,0,121);at.y=world.terrain_height(at.x,at.z)+.015
 var log:Node3D=load("res://assets/arrival/item_wood.glb").instantiate();add_child(log);log.position=at;log.rotation.y=.4
 world.add_point("pass_dry_wood","wood",at+Vector3(0,.18,0),"背风岩脚 · 一段干木柴",log)
 world.box(at+Vector3(-.8,.27,-.6),Vector3(.13,.14,1.6),"62584a",false,self).rotation.x=.3
