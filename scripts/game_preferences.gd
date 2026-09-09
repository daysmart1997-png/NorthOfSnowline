extends RefCounted
# Local presentation preferences are independent from journey save data.
var path:="user://preferences.cfg"
var master:=1.0
var music:=1.0
var effects:=1.0
var hud_scale:=1.0
var compact_hud:=true

func load_preferences()->void:
	var config:=ConfigFile.new()
	if config.load(path)!=OK:return
	var compact=config.get_value("presentation","compact_hud",true)
	if compact is bool:compact_hud=compact
	for key in ["master","music","effects","hud_scale"]:
		var value=config.get_value("presentation",key,get(key))
		if (value is float or value is int) and is_finite(float(value)):
			set(key,clampf(float(value),.85 if key=="hud_scale" else 0.0,1.3 if key=="hud_scale" else 1.0))

func save_preferences()->void:
	var config:=ConfigFile.new()
	for key in ["master","music","effects","hud_scale"]:config.set_value("presentation",key,get(key))
	config.set_value("presentation","compact_hud",compact_hud)
	config.save(path)

func apply_audio()->void:
	for name in ["SnowMusic","SnowEffects"]:
		if AudioServer.get_bus_index(name)<0:
			AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,name)
	for pair in [["Master",master],["SnowMusic",music],["SnowEffects",effects]]:
		var index:=AudioServer.get_bus_index(pair[0])
		AudioServer.set_bus_mute(index,pair[1]<=.001)
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(.001,pair[1])))
