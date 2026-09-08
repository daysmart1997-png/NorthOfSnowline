extends Node
signal breath_pulse(effort:float)
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
var step_bank:Dictionary={}
var footsteps_played:=0
var breaths_played:=0
const TRACKS={"tape_embers":"res://assets/audio/embers.wav","tape_stride":"res://assets/audio/stride.wav","tape_home":"res://assets/audio/homeward.wav"}

func _ready()->void:
	speaker=AudioStreamPlayer.new();speaker.volume_db=-13;add_child(speaker)
	wind=ambient("res://assets/audio/wind.wav",-19)
	fire=ambient("res://assets/audio/fire.wav",-80)
	background=ambient("res://assets/audio/winter_ambient.wav",-32)
	for i in range(4):
		var voice:=AudioStreamPlayer.new();voice.volume_db=-16;add_child(voice);step_voices.append(voice)
	footstep=step_voices[0]
	breathing=AudioStreamPlayer.new();breathing.volume_db=-25;add_child(breathing)
	for surface in ["snow","deep","ice","wood"]:
		var samples:Array[AudioStream]=[]
		for i in range(8 if surface in ["snow","deep"] else 4):samples.append(load("res://assets/audio/step_%s_%d.wav"%[surface,i]))
		step_bank[surface]=samples

func ambient(path:String,volume:float)->AudioStreamPlayer:
	var node:=AudioStreamPlayer.new();var stream:AudioStreamWAV=load(path).duplicate()
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=int(stream.get_length()*stream.mix_rate)
	node.stream=stream;node.volume_db=volume;add_child(node);node.play();return node

func play_step(surface:String,pressure:float,_left:bool)->void:
	if not step_bank.has(surface):return
	var bank:Array=step_bank[surface]
	var pick:=randi_range(0,bank.size()-2)
	if pick>=last_sample:pick+=1
	pick=clampi(pick,0,bank.size()-1);last_sample=pick
	voice_index=(voice_index+1)%step_voices.size();footstep=step_voices[voice_index]
	footstep.stream=bank[pick];footstep.pitch_scale=randf_range(.97,1.03)
	footstep.volume_db=-17+linear_to_db(clampf(pressure,.6,1.5));footstep.play();footsteps_played+=1

func sync(state,paused:bool,outside:=true,speed:=0.0,burning:=false,simulating:=true)->void:
	var delta:=get_process_delta_time()
	wind.stream_paused=paused;fire.stream_paused=paused;background.stream_paused=paused
	for voice in step_voices:voice.stream_paused=paused or not simulating
	breathing.stream_paused=paused or not simulating
	wind.volume_db=lerpf(wind.volume_db,(-19.0+state.storm()*3.0) if outside else -34.0,minf(delta*2,1))
	fire.volume_db=lerpf(fire.volume_db,-18.0 if burning else -80.0,minf(delta*3,1))
	if simulating and not paused:
		var effort:float=clampf(maxf((100-state.stamina)/85.0,.72 if speed>2.8 else .06)+(maxf(0,25-state.temperature)/100.0),0,1)
		breathing_effort=move_toward(breathing_effort,effort,delta*(.19 if effort>breathing_effort else .065))
		breath_wait-=delta
		if breath_wait<=0 and not breathing.playing:
			breathing.stream=load("res://assets/audio/breath_pant.wav" if breathing_effort>.46 else "res://assets/audio/breath_calm.wav")
			breathing.volume_db=lerpf(-31,-19,breathing_effort)
			breathing.pitch_scale=lerpf(.90,1.06,breathing_effort);breathing.play()
			breath_wait=lerpf(6.3,2.9,breathing_effort);breath_pulse.emit(breathing_effort);breaths_played+=1
	var desired:String=state.music_effect()
	background.volume_db=lerpf(background.volume_db,-49.0 if not desired.is_empty() else (-31.0 if outside else -29.0),minf(delta*.8,1))
	if desired.is_empty():
		speaker.stop();current_tape="";return
	if desired!=current_tape:
		current_tape=desired
		var stream:AudioStreamWAV=load(TRACKS[desired]).duplicate();stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=0;stream.loop_end=int(stream.get_length()*stream.mix_rate)
		speaker.stream=stream;speaker.play()
	speaker.stream_paused=paused

func shutdown()->void:
	current_tape=""
	for node in [speaker,wind,fire,footstep,breathing,background]:
		if is_instance_valid(node):node.stream_paused=false;node.stop();node.stream=null
	for node in step_voices:node.stream_paused=false;node.stop();node.stream=null
	step_bank.clear()

func _exit_tree()->void:
	if is_instance_valid(speaker):shutdown()
