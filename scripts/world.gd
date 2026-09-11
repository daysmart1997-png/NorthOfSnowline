extends Node3D

const DayCycle = preload("res://scripts/day_cycle.gd")

var points: Array[Dictionary] = []
var env: Environment
var sun: DirectionalLight3D
var night_fill: DirectionalLight3D
var snow: CPUParticles3D
var fire_lights := {}
var fire_meshes := {}
var materials := {}
var rng := RandomNumberGenerator.new()
var cutaways: Array[Dictionary] = []
var lighting_time := -INF

func mat(hex: String) -> StandardMaterial3D:
	if materials.has(hex):
		return materials[hex]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 0.95
	materials[hex] = m
	return m

func box(at: Vector3, size: Vector3, color: String, collision := false, parent: Node3D = self) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	m.material_override = mat(color)
	m.position = at
	parent.add_child(m)
	if collision:
		var body := StaticBody3D.new()
		body.position = at
		var shape := CollisionShape3D.new()
		var s := BoxShape3D.new()
		s.size = size
		shape.shape = s
		body.add_child(shape)
		parent.add_child(body)
	return m

func cone(at: Vector3, radius: float, height: float, color: String, parent: Node3D = self) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 7
	m.mesh = mesh
	m.material_override = mat(color)
	m.position = at
	parent.add_child(m)
	return m

func sign_text(text_value: String, at: Vector3, size := 38, parent: Node3D = self) -> Label3D:
	var label := Label3D.new()
	label.text = text_value
	label.font_size = size
	label.pixel_size = 0.012
	label.outline_size = 4
	label.modulate = Color("ece3cb")
	label.position = at
	parent.add_child(label)
	return label

func _ready() -> void:
	rng.seed = 198812
	var world_env := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("536f87")
	sky_mat.sky_horizon_color = Color("c7c9be")
	sky_mat.ground_bottom_color = Color("7d919e")
	sky_mat.ground_horizon_color = Color("c7c9be")
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a4b2c7")
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("607b9f")
	env.fog_density = 0.0005
	world_env.environment = env
	add_child(world_env)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-23, -62, 0)
	sun.light_color = Color("c5cbd4")
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)
	# A faint, shadowless night fill reveals snow normals without another shadow map.
	night_fill = DirectionalLight3D.new()
	night_fill.light_color = Color("8299be")
	night_fill.light_energy = 0.0
	night_fill.shadow_enabled = false
	night_fill.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(night_fill)
	build_terrain()
	# A snow-covered river stripe and intact crossing; ice hazard is a later milestone.
	box(Vector3(0, 0.015, -86), Vector3(175, 0.025, 13), "344e6c")
	box(Vector3(0, 0.022, -86), Vector3(5.0, 0.035, 16), "7f8d91")
	for x in [-1.0, 1.0]:
		box(Vector3(x, 0.055, -85), Vector3(0.09, 0.11, 155), "273b53")
	for z in range(-159, -9, 3):
		box(Vector3(0, 0.035, z), Vector3(2.8, 0.05, 0.26), "46566a")
	# Authored bare-tree silhouettes frame a continuous, clear walkable route.
	for i in range(145):
		var x := rng.randf_range(-86, 86)
		var z := rng.randf_range(-215, 48)
		if absf(x) < 8.0 or (x > 15 and x < 30) or (absf(x) < 15 and (z > 4 or z < -150)) or absf(z + 86) < 9:
			continue
		tree(Vector3(x, terrain_height(x, z), z), rng.randf_range(0.75, 1.25))
	for z in range(-180, 35, 19):
		for side in [-1, 1]:
			var x: float = side * rng.randf_range(6.5, 12.5)
			var tz := float(z) + rng.randf_range(-4, 4)
			if absf(tz + 86) < 10 or absf(tz - 18) < 10 or absf(tz + 170) < 10: continue
			tree(Vector3(x, terrain_height(x, tz), tz), rng.randf_range(0.7, 1.15))
	fence(Vector3(4, 0, -39), 6)
	fence(Vector3(-17, 0, -116), 4)
	for i in range(110):
		var x := rng.randf_range(-34, 34)
		var z := rng.randf_range(-156, 6)
		if absf(x) < 2.3 or absf(z + 86) < 9: continue
		rock(Vector3(x, terrain_height(x, z), z), rng.randf_range(0.11, 0.30))
	rock(Vector3(4.3, terrain_height(4.3, -27), -27), 0.75)
	for i in range(17):
		var a := TAU * i / 17.0
		var at := Vector3(cos(a) * 200, 6, sin(a) * 245 - 70)
		var h := rng.randf_range(45, 83)
		cone(at, rng.randf_range(42, 62), h, "607884")
		cone(at + Vector3(0, h * 0.24, 0), 18, h * 0.48, "acbec6")
	for x in [-93, 93]:
		invisible_wall(Vector3(x, 4, -80), Vector3(2, 12, 270))
	for z in [-214, 52]:
		invisible_wall(Vector3(0, 4, z), Vector3(190, 12, 2))
	cabin(Vector3(0, 0, 18), "home", "29374b", "林区 · 07 号护林站")
	cabin(Vector3(0, 0, -170), "station", "513f47", "北岭车站 · 维修间")
	box(Vector3(5.3, 4, -168), Vector3(0.12, 8, 0.12), "656e6d")
	box(Vector3(6.15, 7.1, -168), Vector3(1.8, 0.7, 0.06), "bd6c4d")
	# Hand-placed, terrain-aligned route evidence is added by world_frontier.
	add_pickup("wood_1", "wood", Vector3(5, 0.45, -30), "散落的木柴")
	add_pickup("food_1", "food", Vector3(20, 0.45, -55), "遗留的口粮")
	add_pickup("wood_2", "wood", Vector3(23, 0.45, -112), "干燥的木柴")
	add_pickup("food_2", "food", Vector3(-5, 0.45, -131), "密封口粮")
	add_pickup("radio_parts", "parts", Vector3(-2.5, 0.8, -171), "无线电备用零件")
	add_point("radio", "radio", Vector3(-2.5, 1, 17), "修复无线电 / 发出呼叫")
	box(Vector3(-2.5, 0.4, 17), Vector3(1.5, 0.8, 0.8), "5c5148", true)
	box(Vector3(-2.5, 1, 17), Vector3(0.85, 0.4, 0.45), "45524c")
	box(Vector3(-2.3, 1.06, 16.76), Vector3(0.28, 0.13, 0.02), "daa36e")
	build_snow()

func invisible_wall(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = at
	var shape := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	shape.shape = s
	body.add_child(shape)
	add_child(body)

func tree(at: Vector3, scale_value: float) -> void:
	var root := Node3D.new()
	root.position = at
	add_child(root)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := 6.0 * scale_value
	var trunk := [Vector3.ZERO, Vector3(0.13, h * 0.36, 0.07), Vector3(-0.08, h * 0.68, 0.15), Vector3(0.12, h, 0)]
	for i in range(3):
		branch(st, trunk[i], trunk[i + 1], (0.24 - i * 0.068) * scale_value, (0.17 - i * 0.068) * scale_value)
	for i in range(9):
		var fraction := 0.25 + i * 0.072
		var start := Vector3(0, h * fraction, 0.04)
		var angle := i * 2.4 + rng.randf_range(-0.35, 0.35)
		var spread := (1.0 - fraction) * 2.9 * scale_value
		var end := start + Vector3(cos(angle) * spread, h * 0.17, sin(angle) * spread)
		branch(st, start, end, 0.09 * scale_value, 0.023 * scale_value)
		for fork in [-1, 1]:
			var twig := end + Vector3(cos(angle + fork * 0.55) * spread * 0.46, h * 0.18, sin(angle + fork * 0.55) * spread * 0.46)
			branch(st, end, twig, 0.024 * scale_value, 0.003)
			var middle := end.lerp(twig, 0.48)
			branch(st, middle, middle + Vector3(cos(angle + fork * 1.25) * 0.45 * scale_value, 0.55 * scale_value, sin(angle + fork * 1.25) * 0.45 * scale_value), 0.012, 0.002)
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	var bark := ShaderMaterial.new()
	bark.shader = load("res://assets/shaders/bark.gdshader")
	mesh.material_override = bark
	root.add_child(mesh)
	invisible_wall(at + Vector3(0, 1.8, 0), Vector3(0.38, 3.6, 0.38))

func branch(st: SurfaceTool, start: Vector3, end: Vector3, r1: float, r2: float) -> void:
	var axis := (end - start).normalized()
	var u := axis.cross(Vector3.FORWARD).normalized()
	if u.length() < 0.1: u = axis.cross(Vector3.RIGHT).normalized()
	var v := axis.cross(u).normalized()
	for i in range(5):
		var angle1 := TAU * i / 5.0
		var angle2 := TAU * (i + 1) / 5.0
		var d1 := u * cos(angle1) + v * sin(angle1)
		var d2 := u * cos(angle2) + v * sin(angle2)
		var a := start + d1 * r1
		var b := start + d2 * r1
		var c := end + d2 * r2
		var d := end + d1 * r2
		st.set_normal((d1 + d2).normalized())
		for vertex in [a, b, c, a, c, d]: st.add_vertex(vertex)

func terrain_height(x: float, z: float) -> float:
	var trail_mask := smoothstep(3.0, 9.0, absf(x)) * smoothstep(2.0, 6.0, absf(x - 22.0))
	var cabin_mask := smoothstep(6.0, 13.0, Vector2(x, z - 18).length()) * smoothstep(6.0, 13.0, Vector2(x, z + 170).length())
	var river_mask := smoothstep(8.0, 14.0, absf(z + 86.0))
	var wave := 0.40 + 0.36 * sin(x * 0.33 + z * 0.12) + 0.25 * sin(z * 0.29 - x * 0.14)
	return maxf(wave, 0.0) * trail_mask * cabin_mask * river_mask

func build_terrain() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := 2.0
	for ix in range(110):
		for iz in range(145):
			var x := -110.0 + ix * step
			var z := -225.0 + iz * step
			for p in [Vector2(x, z), Vector2(x + step, z), Vector2(x, z + step), Vector2(x + step, z), Vector2(x + step, z + step), Vector2(x, z + step)]:
				var eps := 0.05
				var dx := (terrain_height(p.x + eps, p.y) - terrain_height(p.x - eps, p.y)) / (2.0 * eps)
				var dz := (terrain_height(p.x, p.y + eps) - terrain_height(p.x, p.y - eps)) / (2.0 * eps)
				st.set_normal(Vector3(-dx, 1.0, -dz).normalized())
				st.add_vertex(Vector3(p.x, terrain_height(p.x, p.y), p.y))
	var terrain := MeshInstance3D.new()
	terrain.mesh = st.commit()
	var snow_material := ShaderMaterial.new()
	snow_material.shader = load("res://assets/shaders/snow.gdshader")
	terrain.material_override = snow_material
	add_child(terrain)
	terrain.create_trimesh_collision()

func fence(at: Vector3, sections: int) -> void:
	for i in range(sections + 1):
		var x := at.x + i * 2.6
		var y := terrain_height(x, at.z)
		box(Vector3(x, y + 0.66, at.z), Vector3(0.13, 1.32, 0.16), "1b293e", true)
		box(Vector3(x, y + 1.33, at.z), Vector3(0.18, 0.07, 0.2), "586d86")
		if i < sections:
			for rail_y in [0.38, 1.03]:
				box(Vector3(x + 1.3, y + rail_y, at.z), Vector3(2.6, 0.12, 0.11), "1b293e", true)

func rock(at: Vector3, radius: float) -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 1.3
	sphere.radial_segments = 5
	sphere.rings = 2
	mesh.mesh = sphere
	mesh.position = at + Vector3(0, radius * 0.28, 0)
	mesh.material_override = mat("26364e")
	add_child(mesh)
	cone(at + Vector3(0, radius * 0.85, 0), radius * 0.64, radius * 0.16, "526984")

func cabin(at: Vector3, id: String, color: String, title: String) -> void:
	var root := Node3D.new()
	root.position = at
	add_child(root)
	box(Vector3(0, 0.008, 0), Vector3(8.4, 0.016, 8.4), "8c8475", false, root)
	box(Vector3(-4, 1.7, 0), Vector3(0.3, 3.4, 8), color, true, root)
	var to_hide: Array[Node3D] = []
	to_hide.append(box(Vector3(4, 1.7, 0), Vector3(0.3, 3.4, 8), color, true, root))
	box(Vector3(0, 1.7, -4), Vector3(8, 3.4, 0.3), color, true, root)
	for x in [-2.6, 2.6]:
		to_hide.append(box(Vector3(x, 1.7, 4), Vector3(2.8, 3.4, 0.3), color, true, root))
	to_hide.append(box(Vector3(0, 3.0, 4), Vector3(2.4, 0.8, 0.3), color, true, root))
	for y in [0.5, 1.1, 1.7, 2.3, 2.9]:
		box(Vector3(-4.18, y, 0), Vector3(0.08, 0.04, 8), "444e4b", false, root)
		to_hide.append(box(Vector3(4.18, y, 0), Vector3(0.08, 0.04, 8), "182538", false, root))
	to_hide.append(box(Vector3(0, 3.55, 0), Vector3(9.1, 0.32, 9.0), "455c79", true, root))
	to_hide.append(box(Vector3(-2.5, 4.3, -2), Vector3(0.65, 1.6, 0.65), "26364b", true, root))
	to_hide.append(box(Vector3(0, 2.85, 4.22), Vector3(4.6, 0.6, 0.1), "263649", false, root))
	# Cabins have no naming signs.
	for x in [-2.6, 2.6]:
		to_hide.append(box(Vector3(x, 1.85, 4.18), Vector3(1.05, 1.15, 0.08), "b67d43", false, root))
		to_hide.append(box(Vector3(x, 1.85, 4.24), Vector3(0.07, 1.15, 0.07), "263549", false, root))
		to_hide.append(box(Vector3(x, 1.85, 4.24), Vector3(1.05, 0.07, 0.07), "263549", false, root))
	cutaways.append({"at": at, "nodes": to_hide})
	box(Vector3(2.6, 0.65, -2), Vector3(0.9, 1.3, 0.9), "363f42", true, root)
	var flame := box(Vector3(2.6, 0.65, -1.53), Vector3(0.55, 0.45, 0.025), "edb671", false, root)
	flame.visible = false
	fire_meshes[id] = flame
	var glow := OmniLight3D.new()
	glow.position = Vector3(2.3, 1.6, -1.1)
	glow.light_color = Color("ffb569")
	glow.light_energy = 0.0
	glow.omni_range = 8.0
	root.add_child(glow)
	fire_lights[id] = glow
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 2.4, 2.2)
	lamp.light_color = Color("e6bc8e")
	lamp.light_energy = 0.5
	lamp.omni_range = 8
	root.add_child(lamp)
	add_point(id, "fire", at + Vector3(2.6, 0.9, -1.4), "火炉 · 添入一份木柴")
	box(Vector3(-2.4, 0.3, -2.2), Vector3(1.6, 0.6, 2.2), "797967", true, root)

func add_point(id: String, kind: String, at: Vector3, title: String, node: Node3D = null) -> void:
	points.append({"id": id, "kind": kind, "position": at, "title": title, "node": node})

func add_pickup(id: String, kind: String, at: Vector3, title: String) -> void:
	var root := Node3D.new()
	root.position = at
	add_child(root)
	box(Vector3.ZERO, Vector3(0.7, 0.35, 0.55), "4b4340" if kind == "wood" else "364354", false, root)
	box(Vector3(0, 0.19, 0), Vector3(0.72, 0.04, 0.57), "4c5e76", false, root)
	var marker := sign_text("◇", Vector3(0, 1.1, 0), 40, root)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.modulate = Color("f0cc85")
	add_point(id, kind, at + Vector3(0, 0.2, 0), title, root)

func shelter_at(at: Vector3) -> String:
	if absf(at.x) < 3.8:
		if absf(at.z - 18) < 3.8: return "home"
		if absf(at.z + 170) < 3.8: return "station"
	return ""

func windbreak_at(at: Vector3) -> bool:
	return at.x > 14 and at.x < 34 and at.z < -15 and at.z > -150

func refresh_pickups(collected: Array) -> void:
	for p in points:
		if p.node != null:
			p.node.visible = not collected.has(p.id)

func build_snow() -> void:
	snow = CPUParticles3D.new()
	snow.amount = 220
	snow.lifetime = 5
	snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	snow.emission_box_extents = Vector3(18, 8, 18)
	snow.direction = Vector3(-0.45, -1, 0.15)
	snow.spread = 18
	snow.gravity = Vector3(0, -0.6, 0)
	snow.initial_velocity_min = 1.2
	snow.initial_velocity_max = 3.5
	snow.scale_amount_min = 0.055
	snow.scale_amount_max = 0.10
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1
	mesh.radial_segments = 4
	mesh.rings = 3
	snow.mesh = mesh
	var snow_mat := StandardMaterial3D.new()
	snow_mat.albedo_color = Color("ebf0ec")
	snow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	snow.material_override = snow_mat
	add_child(snow)

func update_daylight(elapsed: float, storm: float) -> void:
	# Updating procedural sky resources at 10 Hz avoids needless redraw work.
	# Absolute difference also handles backwards jumps when loading an old save.
	if absf(elapsed - lighting_time) < 0.1: return
	lighting_time = elapsed
	var day := DayCycle.daylight(elapsed)
	var warm := DayCycle.sunset_tint(elapsed) * (1.0 - storm * 0.8)
	sun.basis = Basis.looking_at(-DayCycle.sun_direction(elapsed), Vector3.UP)
	sun.light_color = Color("c5cbd4").lerp(Color("efb082"), warm)
	sun.light_energy = lerpf(0.75, 0.38, storm) * DayCycle.sun_strength(elapsed)
	sun.shadow_enabled = sun.light_energy > 0.015
	# Snow scatters light into long morning/evening shadows. Keep the actual
	# solar direction and silhouettes while reducing their graphic dominance.
	sun.shadow_opacity = lerpf(.34, .84, smoothstep(.12, .65, DayCycle.sun_direction(elapsed).y)) * (1.0 - storm * .24)
	night_fill.basis = Basis.looking_at(DayCycle.sun_direction(elapsed), Vector3.UP)
	night_fill.light_energy = 0.22 * DayCycle.sun_strength(elapsed + DayCycle.DAY_SECONDS * 0.5) * (1.0 - storm * 0.45)
	# Diffuse blue fill keeps silhouettes, trails and snow relief readable at night.
	env.ambient_light_color = Color("7086ac").lerp(Color("a4b2c7"), day)
	env.ambient_light_energy = lerpf(0.32, 0.42, day)
	env.fog_light_color = Color("25344e").lerp(Color("607b9f"), day).lerp(Color("947f82"), warm * 0.3)
	var sky_mat := env.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = Color("101b30").lerp(Color("536f87"), day)
	sky_mat.sky_horizon_color = Color("394761").lerp(Color("c7c9be"), day).lerp(Color("bb8e7d"), warm * 0.6)
	sky_mat.ground_bottom_color = Color("25344e").lerp(Color("7d919e"), day)
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color
	snow.material_override.albedo_color = Color("7e95b9").lerp(Color("ebf0ec"), day)

func weather_update(storm: float, at: Vector3, fires: Dictionary, elapsed := 0.0) -> void:
	update_daylight(elapsed, storm)
	env.fog_density = lerpf(0.0005, 0.010, storm)
	snow.global_position = at + Vector3(0, 7, 0)
	snow.speed_scale = 0.8 + storm * 1.5
	snow.visible = shelter_at(at).is_empty()
	for cutaway in cutaways:
		var inside: bool = absf(at.x - cutaway.at.x) < float(cutaway.get("half_width",4.4)) and absf(at.z - cutaway.at.z) < 4.5
		for node in cutaway.nodes: node.visible = not inside
	for key in fire_lights:
		var active := float(fires[key]) > 0.0
		fire_lights[key].light_energy = 2.8 if active else 0.0
		fire_meshes[key].visible = active
