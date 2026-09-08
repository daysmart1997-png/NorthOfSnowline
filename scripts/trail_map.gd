extends Control

var player_position := Vector3.ZERO
var discoveries:Array=[]
var camps:Array=[]

func map_point(v: Vector2) -> Vector2:
	return Vector2(175 + v.x * 1.25, 375 + v.y * 1.65)

func _draw() -> void:
	draw_style_box(panel_style(), Rect2(Vector2.ZERO, size))
	var font := get_theme_default_font()
	for y in range(45,440,8):draw_line(Vector2(16,y),Vector2(size.x-16,y),Color(.34,.31,.24,.035),1)
	draw_string(font, Vector2(23, 32), "林区勘测图  /  北 ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("343f41"))
	# Nested contour loops distinguish the two exposed ridges from the low basin.
	for center in [Vector2(-34,-36),Vector2(45,-137),Vector2(-56,-158)]:
		for level in range(1,5):
			var contour:=PackedVector2Array()
			for i in range(49):
				var angle:=TAU*i/48.0;var radius:=6+level*3.8
				contour.append(map_point(center+Vector2(cos(angle)*radius,sin(angle)*radius*1.3)))
			draw_polyline(contour,Color(.34,.39,.34,.28),1,true)
	var shore:=PackedVector2Array()
	for i in range(49):shore.append(map_point(Vector2(-31+cos(TAU*i/48)*23,-89+sin(TAU*i/48)*15)))
	draw_colored_polygon(shore,Color("9caeb0"));draw_polyline(shore,Color("6c8389"),1.5,true)
	draw_line(map_point(Vector2(0, 18)), map_point(Vector2(0, -170)), Color("68655a"), 2)
	var route := PackedVector2Array([map_point(Vector2(0, 0)), map_point(Vector2(22, -25)), map_point(Vector2(22, -140)), map_point(Vector2(0, -165))])
	draw_polyline(route, Color("71826d"), 2)
	draw_line(map_point(Vector2(-90, -86)), map_point(Vector2(90, -86)), Color("9caeb0"), 7)
	draw_line(map_point(Vector2(0,-76.7)),map_point(Vector2(0,-95.3)),Color("725f49"),4)
	for marker in [[Vector2(0, 18), "护林小屋"], [Vector2(0, -170), "北岭车站"]]:
		var p := map_point(marker[0])
		draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), Color("896549"))
		draw_string(font, p + Vector2(-115, 5), marker[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("343f41"))
	draw_string(font, Vector2(218, 218), "避风林道", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("596851"))
	for marker in [["wreck",Vector2(-14,-43),"邮递车"],["hunters",Vector2(22,-62),"猎人营地"],["lookout",Vector2(28,-115),"观测点"],["depot",Vector2(-15,-128),"堆场"],["ridge",Vector2(-34,-36),"西岭"],["hollow",Vector2(40,-43),"洼地"],["lake",Vector2(-28,-89),"冻湖"]]:
		if discoveries.has(marker[0]):
			var at:=map_point(marker[1]);draw_circle(at,3,Color("74664f"));draw_string(font,at+Vector2(7,5),marker[2],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("454f49"))
	for camp in camps:
		var at:=map_point(Vector2(camp.position[0],camp.position[2]));draw_colored_polygon(PackedVector2Array([at+Vector2(0,-6),at+Vector2(6,5),at+Vector2(-6,5)]),Color("ce9a60"))
	var p := map_point(Vector2(player_position.x, player_position.z))
	draw_circle(p, 8, Color("e5dcc5"))
	draw_circle(p, 5, Color("a4573d"))
	draw_string(font, Vector2(22, 448), "等高线：高地   蓝灰：冻湖   红点：你", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("52605b"))
	draw_string(font, Vector2(22, 475), "沿旧铁路向北                    Tab 收起", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("52605b"))

func panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("c7c4b2")
	s.border_color = Color("777f74")
	s.set_border_width_all(1)
	s.set_corner_radius_all(1)
	return s
