extends PanelContainer

func _draw()->void:
	# Fine woven marks and ruled edges connect menus to the ranger's canvas equipment.
	for i in range(int(size.y/5)):
		var y:=float(i*5+3)
		draw_line(Vector2(3,y),Vector2(size.x-3,y),Color(.84,.86,.80,.018),1)
	draw_line(Vector2(9,8),Vector2(size.x-9,8),Color(.70,.70,.59,.2),1)
	draw_line(Vector2(9,size.y-8),Vector2(size.x-9,size.y-8),Color(.70,.70,.59,.2),1)
