extends CharacterBody3D

var enabled := false
var sprinting := false
var crouching := false
var move_factor := 1.0
var can_sprint := true
var pivot: Node3D
var camera: Camera3D
var visual: Node3D
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var cycle := 0.0
const CAMERA_YAW := deg_to_rad(35.0)
const CAMERA_PITCH := deg_to_rad(-52.0)
var zoom := 20.0
var footprint_distance := 0.0
var last_footprint := Vector3.ZERO
var footprint_side := false
var footprints: Array[MeshInstance3D] = []
var boot_mesh: Mesh
var boot_material: Material

func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	floor_snap_length = 0.35
	visual = Node3D.new()
	visual.name = "CharacterVisual_REPLACE_WITH_GLB"
	add_child(visual)
	rounded_part(visual, Vector3(0, 1.09, 0), 0.27, 0.84, Color("1c2a40"), 0.36)
	rounded_part(visual, Vector3(0, 1.5, -0.015), 0.29, 0.15, Color("993f24"), 0.30)
	rounded_part(visual, Vector3(0, 1.72, 0), 0.205, 0.36, Color("19273c"))
	part(visual, Vector3(0, 1.67, -0.17), Vector3(0.23, 0.13, 0.06), Color("96785f"))
	part(visual, Vector3(0.15, 1.22, 0.23), Vector3(0.15, 0.42, 0.07), Color("993f24"))
	rounded_part(visual, Vector3(0, 1.13, 0.25), 0.22, 0.55, Color("293544"))
	for side in [-1, 1]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.18, 0.85, 0)
		visual.add_child(leg)
		rounded_part(leg, Vector3(0, -0.32, 0), 0.105, 0.63, Color("142033"))
		part(leg, Vector3(0, -0.72, -0.07), Vector3(0.23, 0.20, 0.35), Color("111b2b"))
		legs.append(leg)
		var limb := Node3D.new()
		limb.position = Vector3(side * 0.33, 1.40, 0)
		visual.add_child(limb)
		rounded_part(limb, Vector3(0, -0.24, 0), 0.115, 0.54, Color("1c2a40"))
		rounded_part(limb, Vector3(0, -0.55, 0), 0.10, 0.18, Color("121d30"))
		arms.append(limb)
	pivot = Node3D.new()
	pivot.position.y = 0.7
	pivot.rotation = Vector3(CAMERA_PITCH, CAMERA_YAW, 0)
	add_child(pivot)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = zoom
	camera.position.z = 38.0
	camera.far = 400.0
	camera.current = true
	pivot.add_child(camera)
	boot_mesh = PlaneMesh.new()
	boot_mesh.size = Vector2(0.22,0.38)
	boot_material = ShaderMaterial.new()
	boot_material.shader=load("res://assets/shaders/footprint.gdshader")

func rounded_part(parent: Node3D, at: Vector3, radius: float, height: float, color: Color, bottom := -1.0) -> void:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius if bottom < 0 else bottom
	cylinder.height = height
	cylinder.radial_segments = 8
	mesh.mesh = cylinder
	mesh.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	mesh.material_override = material
	parent.add_child(mesh)

func part(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	mesh.material_override = material
	parent.add_child(mesh)

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom = maxf(zoom - 1.5, 16.0)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom = minf(zoom + 1.5, 30.0)
	if event.is_action_pressed("crouch"):
		crouching = not crouching

func _physics_process(delta: float) -> void:
	if not enabled:
		sprinting = false
		return
	camera.size = lerpf(camera.size, zoom, delta * 8.0)
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Basis(Vector3.UP, pivot.rotation.y) * Vector3(input.x, 0, input.y)
	sprinting = Input.is_action_pressed("sprint") and can_sprint and input.length() > 0.1 and not crouching
	var speed := (3.8 if sprinting else (0.85 if crouching else 1.65)) * move_factor
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * (12.0 if input.length()<.1 else 9.0))
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * (12.0 if input.length()<.1 else 9.0))
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = -0.1
	move_and_slide()
	if position.distance_to(last_footprint) > 0.64 and is_on_floor():
		leave_footprint()
	if direction.length() > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), (1.0-exp(-delta*10.0)))
	var moving := Vector2(velocity.x, velocity.z).length()
	cycle += delta * moving * 2.7
	if not legs.is_empty():
		visual.position.y = lerpf(visual.position.y, -0.24 if crouching else 0.0, delta * 10.0)
		visual.rotation.x = lerpf(visual.rotation.x, 0.16 if crouching else 0.0, delta * 10.0)
	for i in range(legs.size()):
		var swing := sin(cycle + i * PI) * minf(moving * 0.10, 0.6)
		legs[i].rotation.x = swing
		arms[i].rotation.x = -swing * 0.7

func leave_footprint() -> void:
	last_footprint = position
	# Floor and bridge remain clean; outdoor footprints are bounded in memory.
	if absf(position.x) < 4.5 and (absf(position.z - 18) < 4.5 or absf(position.z + 170) < 4.5): return
	var stamp := MeshInstance3D.new()
	stamp.mesh = boot_mesh
	stamp.material_override = boot_material
	stamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(stamp)
	footprint_side = not footprint_side
	var offset := visual.basis.x * (0.15 if footprint_side else -0.15)
	stamp.global_position = global_position + offset + Vector3(0, 0.028, 0)
	stamp.rotation.y = visual.rotation.y
	footprints.append(stamp)
	if footprints.size() > 180:
		footprints.pop_front().queue_free()

func clear_footprints() -> void:
	for stamp in footprints: stamp.queue_free()
	footprints.clear()
	last_footprint = position
