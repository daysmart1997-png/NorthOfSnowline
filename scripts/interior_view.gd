extends RefCounted
# Camera visibility, not world visibility: looted items, upgrades and snow tracks
# retain their own state while the room is clear and the exterior is softened.
const OUTDOOR:=1
const ACTOR:=8
const BACKDROP_GROUND:=16
const SNOW_DETAIL:=32
const BACKDROP_PLANE:=64
const OUTDOOR_MARKERS:=128
const OUTDOOR_VIEW:=OUTDOOR | ACTOR | 2 | 4 | SNOW_DETAIL | OUTDOOR_MARKERS
const ROOMS:={"home":2,"station":4}
var world:Node3D
var player:CharacterBody3D
var room:=""
var indoor_environment:Environment
var backdrop:SubViewport
var backdrop_camera:Camera3D
var backdrop_plane:MeshInstance3D
var backdrop_material:ShaderMaterial
var ground_copy:MeshInstance3D
var display_room:=""
var focus:=0.0
var initialized:=false

func setup(w:Node3D,p:CharacterBody3D)->void:
	world=w;player=p
	indoor_environment=world.env.duplicate()
	indoor_environment.background_mode=Environment.BG_COLOR
	indoor_environment.background_color=Color("111c23")
	indoor_environment.fog_enabled=false
	indoor_environment.ambient_light_color=Color("8996a1")
	indoor_environment.ambient_light_energy=.34
	for visual in world.find_children("*","VisualInstance3D",true,false):
		var assigned:=""
		for id in ROOMS:
			if world.buildings[id].is_ancestor_of(visual):assigned=id;break
		# Original procedural interactables live outside the imported cabin root.
		# Only compact, room-contained props qualify; never terrain or weather.
		if assigned.is_empty() and visual is MeshInstance3D:
			var bounds:AABB=visual.get_aabb()
			var center:Vector3=visual.global_transform*bounds.get_center()
			if bounds.size.length()<5.0:
				for id in ROOMS:
					var origin:Vector3=world.buildings[id].global_position
					if absf(center.x-origin.x)<3.9 and absf(center.z-origin.z)<3.9 and center.y>=origin.y-.3 and center.y<origin.y+3.4:
						assigned=id;break
		visual.layers=int(ROOMS.get(assigned,OUTDOOR))
		if visual is Label3D and assigned.is_empty():visual.layers=OUTDOOR_MARKERS
		if visual is MeshInstance3D and visual.material_override in [world.snow_surface,world.detail_surface]:visual.layers=SNOW_DETAIL
	for visual in player.find_children("*","VisualInstance3D",true,false):visual.layers=ACTOR
	build_backdrop()
	update()

func room_at(at:Vector3)->String:
	for id in ROOMS:
		var center:Vector3=world.buildings[id].global_position
		# A small doorway hysteresis avoids flicker when feet straddle the sill.
		var edge:=3.95 if room==id else 3.80
		if absf(at.x-center.x)<edge and absf(at.z-center.z)<edge and at.y>=center.y-.5 and at.y<center.y+3.5:return id
	return ""

func build_backdrop()->void:
	# Reuse the coarse terrain mesh with a separate material. Its backdrop never
	# samples footprint displacement or cuts a hole for the detailed patch.
	for node in world.get_children():
		if node is MeshInstance3D and node.material_override==world.snow_surface:
			ground_copy=MeshInstance3D.new();ground_copy.name="AtmosphereGround";ground_copy.mesh=node.mesh
			ground_copy.material_override=world.snow_surface.duplicate()
			ground_copy.material_override.set_shader_parameter("patch_active",false)
			ground_copy.material_override.set_shader_parameter("local_patch",false)
			ground_copy.layers=BACKDROP_GROUND;ground_copy.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			world.add_child(ground_copy);break
	backdrop=SubViewport.new();backdrop.name="ExteriorAtmosphere";backdrop.size=Vector2i(640,360)
	backdrop.render_target_update_mode=SubViewport.UPDATE_DISABLED
	backdrop.msaa_3d=Viewport.MSAA_DISABLED;backdrop.positional_shadow_atlas_size=0
	backdrop.gui_disable_input=true;backdrop.audio_listener_enable_3d=false
	player.get_parent().add_child(backdrop);backdrop.world_3d=world.get_world_3d()
	backdrop_camera=Camera3D.new();backdrop_camera.name="ExteriorCamera";backdrop_camera.cull_mask=OUTDOOR | BACKDROP_GROUND
	backdrop_camera.far=100;backdrop.add_child(backdrop_camera);backdrop_camera.current=true
	# A camera-attached far plane sits behind the room's actual depth, avoiding
	# screen-space masks that could blur furniture or let foreground trees overlap.
	backdrop_plane=MeshInstance3D.new();backdrop_plane.name="SoftSnowForest"
	var quad:=QuadMesh.new();quad.size=Vector2(200,200);backdrop_plane.mesh=quad
	backdrop_plane.layers=BACKDROP_PLANE;backdrop_plane.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	player.camera.add_child(backdrop_plane);backdrop_plane.position.z=-100
	backdrop_material=ShaderMaterial.new();backdrop_material.shader=load("res://assets/shaders/interior_backdrop.gdshader")
	backdrop_material.set_shader_parameter("backdrop_texture",backdrop.get_texture());backdrop_plane.material_override=backdrop_material

func update()->void:
	room=room_at(player.global_position)
	var delta:float=player.get_process_delta_time()
	if not initialized:focus=0.0 if room.is_empty() else 1.0;initialized=true
	focus=move_toward(focus,0.0 if room.is_empty() else 1.0,delta/0.45)
	if not room.is_empty():display_room=room
	elif focus<=0:display_room=""
	var indoors:=not display_room.is_empty()
	player.camera.cull_mask=ACTOR | BACKDROP_PLANE | int(ROOMS[display_room]) if indoors else OUTDOOR_VIEW
	player.camera.environment=indoor_environment if indoors else null
	indoor_environment.ambient_light_energy=clampf(world.env.ambient_light_energy*1.65,.36,.70)
	# The exterior camera gets the real day/weather. The room gets its own lamps,
	# so tree silhouettes cannot project through the cutaway roof.
	world.sun.visible=true;world.night_fill.visible=true
	world.sun.light_cull_mask=OUTDOOR | SNOW_DETAIL | BACKDROP_GROUND if indoors else 0xfffff
	world.night_fill.light_cull_mask=world.sun.light_cull_mask
	world.sun.shadow_enabled=not indoors and world.sun.light_energy>.015
	backdrop_plane.visible=indoors
	backdrop.render_target_update_mode=SubViewport.UPDATE_ALWAYS if indoors else SubViewport.UPDATE_DISABLED
	if indoors:
		world.snow.visible=true
		var viewport_size:Vector2=player.get_viewport().get_visible_rect().size
		var desired:=Vector2i(640,maxi(1,roundi(640.0*viewport_size.y/viewport_size.x)))
		if backdrop.size!=desired:backdrop.size=desired
		backdrop_material.set_shader_parameter("texel_size",Vector2.ONE/Vector2(desired))
		backdrop_camera.global_transform=player.camera.global_transform
		backdrop_camera.projection=player.camera.projection;backdrop_camera.size=player.camera.size
		backdrop_camera.keep_aspect=player.camera.keep_aspect
		var center:Vector3=world.buildings[display_room].global_position+Vector3(0,.4,0)
		backdrop_material.set_shader_parameter("room_center",player.camera.unproject_position(center)/viewport_size)
		backdrop_material.set_shader_parameter("focus",focus)
		backdrop_material.set_shader_parameter("haze_color",world.env.fog_light_color.darkened(.42))
