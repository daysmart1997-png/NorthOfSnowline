extends Node
signal shutdown_requested
signal breath_pulse(effort:float)
var cue_seconds:=12.0
var alert_seconds:=0.0
var wind_filter:AudioEffectLowPassFilter
var fire_distance:=0.0
var speaker:AudioStreamPlayer
var current_tape:=""
var wind:AudioStreamPlayer
var fire:AudioStreamPlayer
var footstep:AudioStreamPlayer
var step_voices:Array[AudioStreamPlayer]=[]
var voice_index:=0
var breathing:AudioStreamPlayer
var background:AudioStreamPlayer
var breathing_effort:=0.0
var breath_wait:=2.0
var last_sample:=-1
var last_surface_samples:Dictionary={}
var foley_levels:Dictionary={}
var panting:=false
var tape_gain:=-60.0
var step_bank:Dictionary={}
var footsteps_played:=0
var breaths_played:=0
const TRACKS={"tape_embers":"res://assets/audio/embers.wav","tape_stride":"res://assets/audio/stride.wav","tape_home":"res://assets/audio/homeward.wav"}

func _ready()->void:
	speaker=AudioStreamPlayer.new();speaker.volume_db=-13;add_child(speaker)
	wind=ambient("res://assets/audio/wind.wav",-19)
	fire=ambient("res://assets/audio/fire.wav",-80)
	background=ambient("res://assets/audio/winter_ambient.wav",-60)
	for i in range(4):
		var voice:=AudioStreamPlayer.new();voice.volume_db=-16;add_child(voice);step_voices.append(voice)
	footstep=step_voices[0]
	breathing=AudioStreamPlayer.new();breathing.volume_db=-25;add_child(breathing)
	speaker.bus="SnowMusic";background.bus="SnowMusic"
	for voice in [wind,fire,breathing]+step_voices:voice.bus="SnowEffects"
	if AudioServer.get_bus_index("SnowWind")<0:
		AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,"SnowWind")
	var wind_bus:=AudioServer.get_bus_index("SnowWind")
	AudioServer.set_bus_send(wind_bus,"SnowEffects")
	if AudioServer.get_bus_effect_count(wind_bus)==0:
		AudioServer.add_bus_effect(wind_bus,AudioEffectLowPassFilter.new())
	wind_filter=AudioServer.get_bus_effect(wind_bus,0)
	wind.bus="SnowWind"
	for surface in ["snow","deep","ice","wood"]:
		var samples:Array[AudioStream]=[]
		for i in range(8 if surface in ["snow","deep"] else 4):samples.append(load("res://assets/audio/step_%s_%d.wav"%[surface,i]))
		step_bank[surface]=samples
	foley_levels=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/foley_levels.json")).samples

func ambient(path:String,volume:float)->AudioStreamPlayer:
	var node:=AudioStreamPlayer.new();var stream:AudioStreamWAV=load(path).duplicate()
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=int(stream.get_length()*stream.mix_rate)
	node.stream=stream;node.volume_db=volume;add_child(node);node.play();return node

func play_step(surface:String,pressure:float,_left:bool)->void:
	if not step_bank.has(surface):return
	var bank:Array=step_bank[surface]
	last_sample=int(last_surface_samples.get(surface,-1))
	var pick:=randi_range(0,bank.size()-2)
	if pick>=last_sample:pick+=1
	pick=clampi(pick,0,bank.size()-1);last_sample=pick
	last_surface_samples[surface]=pick
	voice_index=(voice_index+1)%step_voices.size();footstep=step_voices[voice_index]
	footstep.stream=bank[pick];footstep.pitch_scale=randf_range(.985,1.015)
	var gain:float=foley_levels.get("step_%s_%d"%[surface,pick],{}).get("gain_db",0.0)
	var base:float={"snow":-18.0,"deep":-18.5,"wood":-22.0,"ice":-20.0}[surface]
	footstep.volume_db=base+gain+linear_to_db(clampf(pressure,.6,1.5));footstep.play();footsteps_played+=1

func sync(state,paused:bool,outside:=true,speed:=0.0,burning:=false,simulating:=true)->void:
	var delta:=get_process_delta_time()
	var reading:=not simulating and not paused
	wind.stream_paused=paused;fire.stream_paused=paused;background.stream_paused=paused
	for voice in step_voices:voice.stream_paused=paused or not simulating
	breathing.stream_paused=paused or not simulating
	var wind_target:float=(-21.0+state.storm()*5.0) if outside else -35.0
	if reading:wind_target-=5.0
	wind.volume_db=lerpf(wind.volume_db,wind_target,minf(delta*2,1))
	wind_filter.cutoff_hz=lerpf(wind_filter.cutoff_hz,11000.0 if outside else 900.0,minf(delta*3,1))
	if simulating and not paused:alert_seconds=maxf(0,alert_seconds-delta)
	var fire_target:float=-18.0-clampf(fire_distance-1.5,0,8)*1.6 if burning else -80.0
	if reading:fire_target-=4.0
	fire.volume_db=lerpf(fire.volume_db,fire_target,minf(delta*3,1))
	if simulating and not paused:
		var effort:float=clampf(maxf((100-state.stamina)/85.0,.72 if speed>2.8 else .06)+(maxf(0,25-state.temperature)/100.0),0,1)
		breathing_effort=move_toward(breathing_effort,effort,delta*(.19 if effort>breathing_effort else .065))
		panting=breathing_effort>.36 if panting else breathing_effort>.52
		breath_wait-=delta
		if breath_wait<=0 and not breathing.playing:
			breathing.stream=load("res://assets/audio/breath_pant.wav" if panting else "res://assets/audio/breath_calm.wav")
			breathing.volume_db=lerpf(-29,-18,breathing_effort)
			breathing.pitch_scale=lerpf(.90,1.06,breathing_effort);breathing.play()
			breath_wait=lerpf(6.3,2.9,breathing_effort);breath_pulse.emit(breathing_effort);breaths_played+=1
	var desired:String=state.music_effect()
	if not paused:cue_seconds=maxf(0,cue_seconds-delta)
	var background_target:float=-65.0 if not desired.is_empty() or cue_seconds<=0 else (-35.0 if outside else -32.0)
	if reading:background_target-=5.0
	if alert_seconds>0:background_target-=10.0
	background.volume_db=lerpf(background.volume_db,background_target,minf(delta*.8,1))
	var switching:=not desired.is_empty() and desired!=current_tape and speaker.playing
	tape_gain=move_toward(tape_gain,-60.0 if desired.is_empty() or switching else (-24.0 if alert_seconds>0 else (-21.0 if reading else -14.0)),delta*100.0)
	speaker.volume_db=tape_gain;speaker.stream_paused=paused
	if desired.is_empty():
		if tape_gain<=-59.9:speaker.stop();current_tape=""
		return
	if switching and tape_gain> -59.9:return
	if desired!=current_tape:
		current_tape=desired
		var stream:AudioStreamWAV=load(TRACKS[desired]).duplicate();stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=0;stream.loop_end=int(stream.get_length()*stream.mix_rate)
		speaker.stream=stream;speaker.play()
	speaker.stream_paused=paused

func shutdown()->void:
	shutdown_requested.emit()
	current_tape=""
	for node in [speaker,wind,fire,footstep,breathing,background]:
		if is_instance_valid(node):node.stream_paused=false;node.stop();node.stream=null
	for node in step_voices:node.stream_paused=false;node.stop();node.stream=null
	step_bank.clear()

func _exit_tree()->void:
	if is_instance_valid(speaker):shutdown()
