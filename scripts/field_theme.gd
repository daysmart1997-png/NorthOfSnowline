extends RefCounted
# Shared visual vocabulary for HUD, inventory, map and pause controls.
const INK=Color("edf0ec")
const MUTED=Color("b8c3c7")
const PANEL=Color("17232b")
const RAISED=Color("26353e")
const LINE=Color("50616a")
const ACCENT=Color("d7b879")
const DANGER=Color("e49a85")

static func font()->SystemFont:
	var result:=SystemFont.new()
	result.font_names=PackedStringArray(["PingFang SC","Microsoft YaHei","Noto Sans CJK SC"])
	return result

static func box(color:Color,border:=Color.TRANSPARENT)->StyleBoxFlat:
	var result:=StyleBoxFlat.new()
	result.bg_color=color;result.border_color=border
	result.set_border_width_all(1 if border.a>0 else 0)
	result.content_margin_left=16;result.content_margin_right=16
	result.content_margin_top=8;result.content_margin_bottom=8
	return result

static func button_theme(button:Button)->void:
	button.add_theme_color_override("font_color",INK)
	button.add_theme_color_override("font_hover_color",INK)
	button.add_theme_color_override("font_pressed_color",INK)
	button.add_theme_color_override("font_disabled_color",Color("91a0a6"))
	button.add_theme_stylebox_override("normal",box(Color(1,1,1,.035)))
	button.add_theme_stylebox_override("hover",box(RAISED))
	button.add_theme_stylebox_override("pressed",box(Color("34444b"),ACCENT))
	button.add_theme_stylebox_override("disabled",box(Color(1,1,1,.018)))
	var focus:=box(Color.TRANSPARENT,ACCENT)
	button.add_theme_stylebox_override("focus",focus)

static func paper()->StyleBoxTexture:
	return surface("res://assets/ui/field_paper.png",Color.WHITE)

static func cloth()->StyleBoxTexture:
	return surface("res://assets/ui/field_canvas.png",Color(.40,.46,.52))

static func surface(path:String,tint:Color)->StyleBoxTexture:
	var result:=StyleBoxTexture.new();result.texture=load(path);result.modulate_color=tint
	result.content_margin_left=24;result.content_margin_right=24;result.content_margin_top=20;result.content_margin_bottom=20
	return result

static func paper_button(control:Button)->void:
	control.add_theme_stylebox_override("normal",box(PANEL))
	control.add_theme_stylebox_override("disabled",box(Color("b4b0a3")))
	control.add_theme_color_override("font_disabled_color",Color("515951"))
