extends "res://scripts/main.gd"
# Isolated UI fixture; complete input journeys are checked by station_playtest.
func _ready()->void:
	super._ready();call_deferred("check_preparation")
func frames(count:=12)->void:
	for i in range(count):await get_tree().process_frame
func shot(id:String)->void:
	if DisplayServer.get_name()=="headless":return
	await frames();RenderingServer.force_draw(false);await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://artifacts/settlement-polish/"+id+".png")
func check_preparation()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/settlement-polish"))
	start_new();opening.finish();active=false;player.enabled=false
	player.position=Vector3(-11,world.terrain_height(-11,73)+.2,73)
	survival.elapsed=400;survival.hunger=24;survival.thirst=25;survival.temperature=65
	survival.items.food=1;survival.items.water=1;survival.fires.lodge=30
	backpack.tab="craft";backpack.rest_hours=4;backpack.open_roll();await frames(30)
	var before:Dictionary=survival.data();var preview:Dictionary=survival.rest_preview("lodge",4)
	assert(before==survival.data(),"Forecast must not consume time, food or fuel")
	assert(preview.fire_day==2 and preview.fire_until=="00:10" and preview.extra_wood==2)
	assert(preview.wake_day==2 and preview.fire_short)
	var forecast:Label=backpack.find_child("RestForecast",true,false)
	assert(forecast.text.contains("醒来") and forecast.text.contains("熄灭"))
	await shot("rest-before")
	await click_control(backpack.find_child("RestPrepare_food",true,false));await frames()
	assert(survival.count("food")==0 and survival.hunger>24)
	assert(backpack.find_child("RestPrepare_food",true,false).disabled)
	await click_control(backpack.find_child("RestPrepare_water",true,false));await frames()
	assert(survival.count("water")==0 and survival.thirst>25)
	assert(survival.elapsed==before.elapsed and survival.fires.lodge==30,"Preparation consumes only the chosen item")
	await shot("rest-prepared")
	var expected:Dictionary=survival.rest_preview("lodge",4)
	var rest_button:Button
	for button_node in backpack.find_children("*","Button",true,false):
		if button_node.text=="休息 4 小时":rest_button=button_node
	assert(rest_button!=null and not rest_button.disabled)
	await click_control(rest_button);await frames()
	assert(is_equal_approx(survival.elapsed,before.elapsed+expected.minutes))
	assert(is_equal_approx(survival.hunger,expected.hunger) and is_equal_approx(survival.thirst,expected.thirst))
	assert(DayCycle.day(survival.solar_time())==expected.wake_day)
	assert(not survival.rest_preview("canteen",2).problem.is_empty())
	set_process(false);title_screen.set_process(false);title_screen.music.stop();title_screen.music.stream=null
	cassette.shutdown();story_panel.shutdown_audio();backpack.shutdown_ui();await frames();OS.delay_msec(150)
	print("PREPARATION_OK: midnight forecast, finite quick supplies, disabled empty items, real scrolled rest input matches prediction")
	get_tree().quit()
