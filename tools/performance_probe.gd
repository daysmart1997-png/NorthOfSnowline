extends "res://scripts/main.gd"

# Isolated ablations; never a player graphics preset.
func _ready()->void:
	super._ready()
	var args:=OS.get_cmdline_user_args()
	if args.has("--no-detail"):world.detail_mesh.visible=false
	if args.has("--snow-255"):
		world.detail_mesh.mesh.subdivide_width=255
		world.detail_mesh.mesh.subdivide_depth=255

func _process(delta:float)->void:
	super._process(delta)
	if OS.get_cmdline_user_args().has("--no-shadows"):world.sun.shadow_enabled=false
