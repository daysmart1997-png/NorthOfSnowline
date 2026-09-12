extends Node3D
# Presentation only: fuel and time always come from Expedition. No extra heat,
# inventory, wall-clock timers or self-running particles survive a paused game.
const FIRE_SHADER=preload("res://assets/shaders/hearth_fire.gdshader")
var source:MeshInstance3D
var light:OmniLight3D
var spill:OmniLight3D
var material:ShaderMaterial
var open_material:ShaderMaterial
var sparks:Array[MeshInstance3D]=[]
var tongues:Array[MeshInstance3D]=[]
var open_fire:=false
var seed:=0.0
var level:=0.0
var last_fuel:=-1.0
var last_time:=-INF
var feed_time:=-INF
var start_time:=-INF
var center:=Vector3.ZERO

func setup(id:String,mesh:MeshInstance3D,glow:OmniLight3D,is_open:bool)->void:
	source=mesh;light=glow;open_fire=is_open;name="HearthEffect_"+id
	seed=float(id.hash()%1009)*.017
	source.get_parent().add_child(self);transform=source.transform
	var bounds:=source.get_aabb();center=bounds.get_center()
	material=ShaderMaterial.new();material.shader=FIRE_SHADER
	material.set_shader_parameter("bounds_min",bounds.position);material.set_shader_parameter("bounds_size",bounds.size)
	material.set_shader_parameter("surface_kind",2 if open_fire else 0)
	source.material_override=material;source.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	light.light_color=Color("ffc18a")
	if open_fire:
		# Imported coal meshes can carry a Blender axis rotation and scale. Fire
		# rises in world metres, independently of the source mesh's local axes.
		global_transform=Transform3D(Basis.IDENTITY,source.to_global(center));center=Vector3.ZERO
		var world_bounds:AABB=source.global_transform*bounds
		material.set_shader_parameter("bounds_min",world_bounds.position);material.set_shader_parameter("bounds_size",world_bounds.size)
		open_material=ShaderMaterial.new();open_material.shader=FIRE_SHADER;open_material.set_shader_parameter("surface_kind",1)
		for i in range(3):
			var flame:=MeshInstance3D.new();var plane:=QuadMesh.new();plane.size=Vector2(.57,.69)
			flame.mesh=plane;flame.material_override=open_material;add_child(flame)
			flame.position=center+Vector3(0,.37,0);flame.rotation.y=float(i)*PI/3.0
			flame.layers=source.layers;flame.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;tongues.append(flame)
		for i in range(4):
			var spark:=MeshInstance3D.new();var mote:=SphereMesh.new();mote.radius=.5;mote.height=1;mote.radial_segments=4;mote.rings=1
			var glow_material:=StandardMaterial3D.new();glow_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;glow_material.albedo_color=Color("ef9e43")
			spark.mesh=mote;spark.material_override=glow_material;spark.scale=Vector3.ONE*.014;spark.layers=source.layers
			spark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(spark);sparks.append(spark)
	visible=false

func sync(fuel:float,time:float,storm:float)->void:
	# Repeated weather calls in the same frame are idempotent. A rest/load jump
	# settles directly to its remaining fuel instead of replaying an ignition.
	var continuous:bool=last_fuel>=0 and time>=last_time and time-last_time<2.0
	if continuous and fuel>last_fuel+1.0:
		feed_time=time
		if last_fuel<=0:start_time=time
	elif not continuous:feed_time=-INF;start_time=-INF
	last_fuel=fuel;last_time=time
	visible=fuel>0;source.visible=fuel>0
	if fuel<=0:
		level=0;light.light_energy=0
		if is_instance_valid(spill):spill.light_energy=0
		material.set_shader_parameter("heat",0.0)
		return
	var flicker:float=.96+.025*sin(time*5.1+seed)+.015*sin(time*8.7+seed*2.3)
	var feed:float=.16*exp(-maxf(0,time-feed_time)*2.0)
	var ignition:float=lerpf(.55,1.0,smoothstep(0,.8,time-start_time))
	level=(lerpf(.20,1.0,smoothstep(0,45,fuel))+feed)*flicker*ignition
	material.set_shader_parameter("fire_time",time+seed);material.set_shader_parameter("heat",level)
	light.light_energy=(1.8 if open_fire else 2.0)*level
	if is_instance_valid(spill):spill.light_energy=.80*level
	if not open_fire:return
	open_material.set_shader_parameter("fire_time",time+seed);open_material.set_shader_parameter("heat",level)
	open_material.set_shader_parameter("gust",storm)
	for i in range(sparks.size()):
		var phase:float=fposmod(time*.57+seed+float(i)*.27,1.0)
		sparks[i].visible=level>.35 and phase<.78
		sparks[i].position=center+Vector3(sin(float(i)*4.1+time)*.07+storm*phase*phase*.18,.15+phase*.86,cos(float(i)*2.3)*.08)
		sparks[i].scale=Vector3.ONE*.018*(1.0-phase)
