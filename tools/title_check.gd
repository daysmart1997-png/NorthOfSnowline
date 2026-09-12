extends "res://scripts/main.gd"
func _ready()->void:
	super._ready();call_deferred("check_title")
func frames(count:=12)->void:
	for i in range(count):await get_tree().process_frame
func shot(id:String)->void:
	if DisplayServer.get_name()=="headless" or not OS.get_cmdline_user_args().has("--title-capture"):return
	await frames();RenderingServer.force_draw(false);await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://artifacts/title-review/"+id+".png")
func check_layout()->void:
	for item in menu.find_children("*","Button",true,false):
		if item.is_visible_in_tree():
			var rect:Rect2=item.get_global_rect()
			assert(Rect2(Vector2.ZERO,canvas.size).encloses(rect),"Menu buttons stay on screen: "+item.text)
func check_title()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/title-review"))
	save_path="res://artifacts/title-review/manual.json";preferences.path="res://artifacts/title-review/preferences.cfg"
	await frames(30)
	assert(title_screen.visible and title_screen.camera.current and not active)
	assert(survival.elapsed==0 and survival.count("food")==2,"Title never changes the journey state")
	check_layout();await shot("01-title-720")
	show_settings(true);await frames();check_layout();await shot("02-settings")
	assert(settings_box.visible);show_settings(false)
	new_button.pressed.emit();await frames()
	assert(opening.sheet.visible and opening.camera.current and not title_screen.visible and not title_screen.music.playing)
	assert(survival.elapsed==0 and survival.count("food")==0,"Opening still starts the real mountain journey")
	opening.finish();await frames(15)
	assert(player.camera.current and active)
	set_menu(true);await frames();var paused:float=survival.elapsed
	assert(not title_screen.visible and player.camera.current and resume_button.visible)
	check_layout();await shot("03-pause")
	await frames();assert(survival.elapsed==paused)
	save_game();assert(FileAccess.file_exists(save_path))
	set_menu(true);assert(not load_button.disabled)
	load_button.pressed.emit();await frames();assert(active and player.camera.current)
	started=false;set_menu(true);await frames()
	if DisplayServer.get_name()!="headless":
		get_window().size=Vector2i(1920,1080);await frames(20);check_layout();await shot("04-title-1080")
	set_process(false);title_screen.set_process(false);title_screen.music.stop();title_screen.music.stream=null
	cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();await frames()
	OS.delay_msec(150)
	print("TITLE_CHECK_OK: title/settings/pause layouts, opening camera handoff, isolated save/load, unchanged survival clock")
	get_tree().quit()
