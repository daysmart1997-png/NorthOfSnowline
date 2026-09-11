extends "res://scripts/main.gd"

func _ready()->void:
	super._ready();call_deferred("check_interior")

func settle(frames:int=6)->void:
	for i in range(frames):await get_tree().process_frame

func check_interior()->void:
	save_path="res://artifacts/interior/check-save.json"
	start_new();player.position=Vector3(0,.24,20.5);survival.kit.module_ready=true;await settle()
	assert(interior_view.room=="home" and player.camera.cull_mask==74)
	assert(player.camera.environment==interior_view.indoor_environment and not world.sun.shadow_enabled and (world.sun.light_cull_mask & 2)==0)
	assert((world.detail_mesh.layers & player.camera.cull_mask)==0,"Outside snow and all its footprints are excluded")
	assert((world.snow.layers & player.camera.cull_mask)==0,"Weather cannot render inside")
	assert(world.buildings.home.find_children("*","MeshInstance3D",true,false).all(func(mesh):return (mesh.layers & 2)!=0))
	assert(world.buildings.station.find_children("*","MeshInstance3D",true,false).all(func(mesh):return (mesh.layers & 2)==0))
	assert((radio_lamp.layers & player.camera.cull_mask)!=0,"Story props remain visible")
	assert(interior_view.backdrop.render_target_update_mode==SubViewport.UPDATE_ALWAYS)
	assert(interior_view.backdrop_camera.cull_mask==17 and (world.detail_mesh.layers & 17)==0)
	assert(interior_view.ground_copy.mesh!=null and not interior_view.ground_copy.material_override.get_shader_parameter("patch_active"),"Backdrop terrain has no footprint patch or missing hole")
	assert(interior_view.backdrop_camera.get_viewport()!=player.camera.get_viewport(),"Backdrop cannot replace the player camera")
	assert((interior_view.ground_copy.layers & player.camera.cull_mask)==0,"Coarse backdrop ground never overlays the detailed room")
	player.camera.size=24;interior_view.update()
	assert(is_equal_approx(interior_view.backdrop_camera.size,24.0))
	assert(interior_view.backdrop_camera.global_transform.is_equal_approx(player.camera.global_transform),"Foreground and background stay registered when zooming or moving")
	player.zoom=20;player.camera.size=20
	# Real doorway traversal creates outdoor tracks, then hides them on return.
	player.pivot.rotation.y=0
	Input.action_press("move_down")
	for i in range(180):await get_tree().physics_frame
	Input.action_release("move_down");await settle()
	# Exterior includes the two new southern buildings (layers 256 and 512).
	assert(player.position.z>25 and interior_view.room.is_empty() and player.camera.cull_mask==943)
	assert(player.camera.environment==null and world.sun.visible)
	assert(interior_view.backdrop.render_target_update_mode==SubViewport.UPDATE_DISABLED,"No second render outside")
	assert(world.track_marks.size()>0,"Walking out leaves real snow marks")
	var marks:int=world.track_marks.size()
	Input.action_press("move_up")
	for i in range(240):
		await get_tree().physics_frame
		if player.position.z<21.5:break
	Input.action_release("move_up");await settle()
	assert(interior_view.focus>0 and interior_view.focus<1,"Entering eases focus instead of snapping the atmosphere")
	assert(interior_view.room=="home" and world.track_marks.size()>=marks,"Entering hides, never erases, outdoor tracks")
	# Do not flicker on tiny doorway movements; do switch after crossing the wall.
	for z in [21.81,21.90,21.84]:
		player.position=Vector3(0,.24,z);interior_view.update();assert(interior_view.room=="home")
	player.position.z=22.1;interior_view.update();assert(interior_view.room.is_empty())
	player.position.z=21.9;interior_view.update();assert(interior_view.room.is_empty())
	player.position.z=21.7;interior_view.update();assert(interior_view.room=="home")
	player.position=Vector3(-2.4,.24,-169.8);player.velocity=Vector3.ZERO;await settle()
	assert(interior_view.room=="station" and player.camera.cull_mask==76)
	update_target();assert(target.get("id")=="radio_parts")
	var container:Node3D=target.node
	assert(container.get_children().filter(func(n):return n is MeshInstance3D).all(func(n):return (n.layers & 4)!=0))
	interact();await settle(60);assert(survival.parts and not container.visible)
	close_story();set_menu(true);save_game();player.position=Vector3(0,.24,27);load_game();await settle()
	assert(interior_view.room=="station" and not container.visible,"Loading indoors preserves room visibility and collected state")
	player.position=Vector3(22,.2,-62);await settle(35)
	assert(interior_view.room.is_empty() and world.shelter_at(player.position)=="hunters","An open canvas shelter keeps the exterior visible")
	assert(not interior_view.backdrop_plane.visible)
	start_new();player.position=Vector3(0,.24,20.5);survival.kit.module_ready=true;await settle();assert(interior_view.room=="home" and container.visible)
	active=false;player.enabled=false;set_process(false);cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui()
	await settle();OS.delay_msec(100)
	print("INTERIOR_OK: softened external backdrop, no footprint texture, disabled outdoor pass, correct cameras, room-only foreground rendering, actor/props, snow/weather exclusion, real door traversal, retained tracks, doorway hysteresis, both rooms, pickups/load/new game, open tent")
	get_tree().quit()
