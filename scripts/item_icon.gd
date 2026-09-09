extends Control
const Icon=preload("res://scripts/field_icon.gd")
const Palette=preload("res://scripts/field_theme.gd")
var item_id:="wood"
func _draw()->void:
	Icon.paint(self,item_id,size*.5,minf(size.x,size.y)/32.0,Palette.INK)
