extends "res://scripts/world_expansion.gd"

var height_texture:ImageTexture
var snow_surface:ShaderMaterial
var detail_surface:ShaderMaterial
var detail_mesh:MeshInstance3D
var track_image:Image
var track_texture:ImageTexture
var track_marks:Array[Dictionary]=[]
var patch_center:=Vector2(9999,9999)
var track_dirty:=true
var snowfall:=0.0
var track_clock:=0.0
var bark_library:Array[ShaderMaterial]=[]

func _ready()->void:
	super._ready()
	sun.directional_shadow_max_distance=55

func candidate_camp(at:Vector3)->Array:
	if not shelter_at(at).is_empty():return []
	for radius in [4.8,7.2,9.6]:
		for i in range(12):
			var angle:float=i*TAU/12
			var p:=Vector3(at.x+cos(angle)*radius,0,at.z+sin(angle)*radius)
			p.y=terrain_height(p.x,p.z)
			if camp_spot_valid(p):return [p.x,p.y,p.z]
	return []

func terrain_height(x:float,z:float)->float:
	var home_mask:=smoothstep(5.6,10.0,Vector2(x,z-18).length())*smoothstep(5.6,10.0,Vector2(x,z+170).length())
	var river_mask:=smoothstep(8.0,13.0,absf(z+86))
	var track_mask:=smoothstep(1.4,5.0,absf(x))
	var path_mask:=lerpf(.13,1.0,smoothstep(1.4,4.5,absf(x-22)))
	var banks:=.50+.37*sin(x*.34+z*.13)+.24*sin(z*.35-x*.17)
	var wind_ridges:=.11*pow(sin(x*1.21+z*.48)*.5+.5,2.0)+.055*sin(z*1.8+x*.65)
	return maxf(.015,banks+wind_ridges)*track_mask*path_mask*home_mask*river_mask

func snow_depth(at:Vector3)->float:
	if shelter_at(at) in ["home","station"] or absf(at.z+86)<7:return 0.0
	return clampf(.06+terrain_height(at.x,at.z)*.35,.035,.35)

func surface_at(at:Vector3)->String:
	if shelter_at(at) in ["home","station"]:return "wood"
	if absf(at.z+86)<7:return "wood" if absf(at.x)<2.5 else "ice"
	return "deep" if snow_depth(at)>.16 else "snow"

func sync_buildings(state)->void:
	# Existing camp saves settle onto the revised snow surface rather than floating or sinking.
	for structure in state.structures:
		var p:Array=structure.position
		p[1]=terrain_height(float(p[0]),float(p[2]))
	super.sync_buildings(state)

func build_terrain()->void:
	var image:=Image.create(441,581,false,Image.FORMAT_RF)
	for z in range(581):
		for x in range(441):image.set_pixel(x,z,Color(terrain_height(-110+x*.5,-225+z*.5),0,0))
	height_texture=ImageTexture.create_from_image(image)
	var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var indices:=PackedInt32Array()
	for z in range(291):
		for x in range(221):
			var h:=image.get_pixel(x*2,z*2).r
			vertices.append(Vector3(-110+x,h,-225+z))
			var dx:=image.get_pixel(maxi(0,x*2-1),z*2).r-image.get_pixel(mini(440,x*2+1),z*2).r
			var dz:=image.get_pixel(x*2,maxi(0,z*2-1)).r-image.get_pixel(x*2,mini(580,z*2+1)).r
			normals.append(Vector3(dx,1,dz).normalized())
			if x<220 and z<290:
				var a:=z*221+x
				indices.append_array(PackedInt32Array([a,a+1,a+221,a+1,a+222,a+221]))
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_INDEX]=indices
	var terrain:=MeshInstance3D.new();var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);terrain.mesh=mesh
	snow_surface=ShaderMaterial.new();snow_surface.shader=load("res://assets/shaders/snow_relief.gdshader");snow_surface.set_shader_parameter("height_field",height_texture)
	track_image=Image.create(768,768,false,Image.FORMAT_RF);track_image.fill(Color(0,0,0));track_texture=ImageTexture.create_from_image(track_image)
	snow_surface.set_shader_parameter("tracks",track_texture);terrain.material_override=snow_surface;add_child(terrain);terrain.create_trimesh_collision()
	detail_surface=snow_surface.duplicate();detail_surface.set_shader_parameter("local_patch",true)
	detail_mesh=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(24,24);plane.subdivide_width=383;plane.subdivide_depth=383;detail_mesh.mesh=plane;detail_mesh.material_override=detail_surface
	detail_mesh.custom_aabb=AABB(Vector3(-12,-1,-12),Vector3(24,4,24));detail_mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(detail_mesh)

func update_snow(at:Vector3,delta:float,storm:float)->void:
	snowfall=storm
	var center:=Vector2(floor(at.x/4.0)*4.0,floor(at.z/4.0)*4.0)
	if center!=patch_center:
		patch_center=center;detail_mesh.position=Vector3(center.x,0,center.y)
		for material in [snow_surface,detail_surface]:material.set_shader_parameter("patch_center",center);material.set_shader_parameter("patch_active",true)
		track_dirty=true
	track_clock+=delta
	for stamp in track_marks:stamp.age+=delta*(1.0+storm*3.0)
	while not track_marks.is_empty() and track_marks[0].age>240:track_marks.pop_front();track_dirty=true
	if track_clock>2:track_clock=0;track_dirty=true
	if track_dirty:paint_tracks();track_dirty=false

func stamp_snow(at:Vector3,yaw:float,pressure:float,left:bool)->float:
	var depth:=snow_depth(at)
	if depth<=0:return 0.0
	var compression:=clampf(depth*.42*pressure,.024,.16)
	track_marks.append({"at":Vector2(at.x,at.z),"yaw":yaw,"depth":compression,"age":0.0,"left":left})
	if track_marks.size()>180:track_marks.pop_front()
	track_dirty=true
	return compression

func clear_tracks()->void:
	track_marks.clear();track_dirty=true

func paint_tracks()->void:
	track_image.fill(Color(0,0,0))
	for stamp in track_marks:
		var pos:Vector2=(stamp.at-patch_center)/24.0*768+Vector2(384,384)
		if pos.x<0 or pos.y<0 or pos.x>=768 or pos.y>=768:continue
		var fade:=1.0-smoothstep(60,240,stamp.age)
		var cs:=cos(stamp.yaw);var sn:=sin(stamp.yaw)
		for iy in range(-10,11):
			for ix in range(-10,11):
				var x:=int(pos.x)+ix;var y:=int(pos.y)+iy
				if x<0 or y<0 or x>=768 or y>=768:continue
				var dx:float=(x-pos.x)/32.0;var dz:float=(y-pos.y)/32.0
				var u:=dx*cs-dz*sn;var v:=dx*sn+dz*cs
				var shape:=minf(Vector2(u/.115,(v+.065)/.17).length(),Vector2(u/.087,(v-.13)/.075).length())
				if shape>1.32:continue
				var core:=1.0-smoothstep(.62,1.0,shape)
				var rim:=smoothstep(.86,1.06,shape)*(1-smoothstep(1.08,1.32,shape))
				var tread:=.93+.07*sin(v*110.0)
				var value:float=(core*stamp.depth*tread-rim*.017)*fade
				var old:=track_image.get_pixel(x,y).r
				track_image.set_pixel(x,y,Color(maxf(old,value) if value>0 else (minf(old,value) if old<=0 else old),0,0))
	track_texture.update(track_image)

func tree(at:Vector3,scale_value:float)->void:
	var root:=Node3D.new();root.position=at;root.rotation.y=rng.randf_range(0,TAU);add_child(root)
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var caps:=SurfaceTool.new();caps.begin(Mesh.PRIMITIVE_TRIANGLES)
	var kind:=rng.randi_range(0,2);var h:=rng.randf_range(5.1,7.8)*scale_value*(.84 if kind==2 else 1.0)
	var lean:=Vector3(rng.randf_range(-.8,.8),0,rng.randf_range(-.65,.65))
	var trunk:Array[Vector3]=[Vector3.ZERO]
	for i in range(1,7):
		var t:=i/6.0
		trunk.append(Vector3(lean.x*t+sin(t*4.1)*.17,h*t,lean.z*t+sin(t*5.0)*.12))
	var thickness:=.22 if kind==1 else (.39 if kind==2 else .31)
	for i in range(6):branch(st,trunk[i],trunk[i+1],lerpf(thickness,.036,i/6.0)*scale_value,lerpf(thickness,.025,(i+1)/6.0)*scale_value)
	for i in range(4):
		var a:=i*1.7;branch(st,Vector3(cos(a)*.66,.04,sin(a)*.66),Vector3(0,.55,0),.06,.17)
	var count:=rng.randi_range(8,12)
	for i in range(count):
		var t:=.24+i*.052
		var begin:=trunk[clampi(int(t*6),1,5)]
		var angle:=i*2.399+rng.randf_range(-.7,.7)
		var spread:=rng.randf_range(1.25,2.45)*(1.1-t)*scale_value*(1.42 if kind==2 else (.78 if kind==1 else 1.0))
		var radial:=Vector3(cos(angle),0,sin(angle))
		var elbow:=begin+radial*spread*.55+Vector3(0,rng.randf_range(.12,.50),0)
		var end:=begin+radial*spread+Vector3(0,rng.randf_range(.65,1.25),0)
		branch(st,begin,elbow,.10*scale_value,.065*scale_value);branch(st,elbow,end,.065*scale_value,.025*scale_value)
		# Narrow snow sleeves accumulate only along the upward side of thick limbs.
		branch(caps,begin+Vector3(0,.075,0),elbow+Vector3(0,.053,0),.075*scale_value,.049*scale_value)
		for j in range(3):
			var a:=angle+(j-1)*.73+rng.randf_range(-.15,.15)
			var fork:=end+Vector3(cos(a)*spread*.55,rng.randf_range(.45,1.05),sin(a)*spread*.55)
			var mid:=end.lerp(fork,.52)+Vector3(.06,0,-.09)
			branch(st,end,mid,.026,.015);branch(st,mid,fork,.015,.004)
			for k in [-1,1]:
				var tip:=mid+Vector3(cos(a+k*.8)*.40,.40+absf(k)*.15,sin(a+k*.8)*.40)
				branch(st,mid,tip,.011,.0025)
	var mesh:=MeshInstance3D.new();mesh.mesh=st.commit()
	var bark:=ShaderMaterial.new();bark.shader=load("res://assets/shaders/bark.gdshader");bark.set_shader_parameter("birch",kind==1);mesh.material_override=bark;root.add_child(mesh)
	var snow_cap:=MeshInstance3D.new();snow_cap.mesh=caps.commit();snow_cap.material_override=mat("8294ab");root.add_child(snow_cap)
	invisible_wall(at+Vector3(0,1.8,0),Vector3(.45,3.6,.45))

func branch(st:SurfaceTool,start:Vector3,end:Vector3,r1:float,r2:float)->void:
	var axis:Vector3=(end-start).normalized();var u:=axis.cross(Vector3.FORWARD).normalized()
	if u.length()<.1:u=axis.cross(Vector3.RIGHT).normalized()
	var v:=axis.cross(u).normalized()
	for i in range(7):
		var a:=TAU*i/7;var b:=TAU*(i+1)/7
		var d1:=u*cos(a)+v*sin(a);var d2:=u*cos(b)+v*sin(b)
		var positions:=[start+d1*r1,start+d2*r1,end+d2*r2,start+d1*r1,end+d2*r2,end+d1*r2]
		for j in range(6):
			st.set_normal(d1 if j in [0,3,5] else d2);st.add_vertex(positions[j])
