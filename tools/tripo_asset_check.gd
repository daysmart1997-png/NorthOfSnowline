extends SceneTree
const Ranger=preload("res://scripts/player_ranger.gd")
const Kit=preload("res://scripts/field_kit.gd")
const Sheet=preload("res://scripts/character_sheet.gd")

func _initialize()->void:
 call_deferred("check_asset")

func check_asset()->void:
 var model:Node3D=Ranger.MODEL.instantiate()
 var rigs:=model.find_children("*","Skeleton3D",true,false)
 assert(rigs.size()==1 and rigs[0].get_bone_count()==41,"Keep supplied rig and twist helpers")
 for name in ["hips","spine","head","thigh.L","shin.L","foot.L","thigh.R","shin.R","foot.R"]:
  assert(rigs[0].find_bone(name)>=0,"Terrain IK bone exists: "+name)
 var meshes:=model.find_children("*","MeshInstance3D",true,false)
 assert(meshes.size()==1,"Importer custom bone shapes must not enter the game")
 var mesh:MeshInstance3D=meshes[0]
 assert(mesh.skin!=null and mesh.skin.get_bind_count()>=41)
 assert(absf(mesh.mesh.get_aabb().size.y-1.88)<.005,"Metre scale is baked into geometry")
 var triangles:=0
 var atlas:Texture2D
 var surfaces:Dictionary={}
 for i in range(mesh.mesh.get_surface_count()):
  var arrays:Array=mesh.mesh.surface_get_arrays(i)
  var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  var uv:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
  var weights:PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
  assert(uv.size()==vertices.size() and weights.size()==vertices.size()*4)
  for v in range(vertices.size()):
   var sum:=0.0
   for w in range(4):sum+=weights[v*4+w]
   assert(absf(sum-1.0)<.002,"Every runtime vertex remains normalized and skinned")
  triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
  var material:StandardMaterial3D=mesh.mesh.surface_get_material(i)
  assert(material.albedo_texture!=null,"Atlas must survive all clothing surfaces")
  if atlas==null:atlas=material.albedo_texture
  assert(material.albedo_texture==atlas and atlas.get_width()==2048)
  surfaces[material.resource_name]=i
 assert(triangles==11000,"All 11000 supplied faces survive without subdivision or custom shape export")
 var kit=Kit.new();Sheet.apply_clothes(model,kit)
 await process_frame;await process_frame
 for slot in Kit.SLOTS:
  var index:int=surfaces["Gear_"+slot+"_Tripo"]
  var material:ShaderMaterial=mesh.get_surface_override_material(index)
  assert(material.get_shader_parameter("atlas")==atlas)
  assert(material.get_shader_parameter("dye_factor")==Vector3.ONE,"Default gear retains authored colours")
  kit.owned[kit.equipped[slot]].wet=70
 Sheet.apply_clothes(model,kit)
 await process_frame;await process_frame
 for slot in Kit.SLOTS:
  var material:ShaderMaterial=mesh.get_surface_override_material(surfaces["Gear_"+slot+"_Tripo"])
  assert(is_equal_approx(material.get_shader_parameter("wetness"),.7))
 var replacement:String=kit.acquire("wind_coat");kit.wear(replacement);Sheet.apply_clothes(model,kit)
 await process_frame;await process_frame
 var coat:ShaderMaterial=mesh.get_surface_override_material(surfaces.Gear_torso_Tripo)
 assert(coat.get_shader_parameter("dye_factor")!=Vector3.ONE and coat.get_shader_parameter("atlas")==atlas)
 assert(mesh.get_surface_override_material(surfaces.Tripo_Detail)==null,"Face and scarf keep source material")
 for i in range(mesh.mesh.get_surface_count()):
  assert(mesh.mesh.surface_get_material(i).albedo_color==Color.WHITE,"Preview tint cannot mutate shared source materials")
 var animation:AnimationPlayer=model.find_children("*","AnimationPlayer",true,false)[0]
 var clips:=0
 for name in animation.get_animation_list():
  if name.contains("Ranger_"):
   clips+=1;assert(animation.get_animation(name).length>0.3)
 assert(clips==8)
 # Retain surface resources until the renderer has released the mesh RID.
 var materials:Array[Material]=[]
 for i in range(mesh.mesh.get_surface_count()):
  materials.append(mesh.get_surface_override_material(i))
 model.free();await process_frame;await process_frame
 materials.clear()
 print("TRIPO_ASSET_OK: normalized 41-bone skin, 11000 supplied triangles, metre scale, shared 2K UV atlas, six clothing slots, wetness and immutable source materials, eight clips")
 quit()
