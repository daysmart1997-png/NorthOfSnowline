extends Button
signal apply_item(id: String)
var item_id := ""
var quantity:=1
func _get_drag_data(_at:Vector2)->Variant:
	if quantity<=0:return null
	var preview:=PanelContainer.new();var icon=preload("res://scripts/item_icon.gd").new();icon.item_id=item_id;icon.custom_minimum_size=Vector2(72,60);preview.add_child(icon);preview.modulate=Color("f0d4a0");set_drag_preview(preview)
	return {"kind":"backpack_item","id":item_id}
func _can_drop_data(_at:Vector2,data:Variant)->bool:
	return item_id=="player" and data is Dictionary and data.get("kind")=="backpack_item" and (str(data.get("id","")).begins_with("tape_") or data.get("id")=="battery")
func _drop_data(_at:Vector2,data:Variant)->void: apply_item.emit(data.id)
