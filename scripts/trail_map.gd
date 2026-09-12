extends Control
const Palette=preload("res://scripts/field_theme.gd")

var player_position := Vector3.ZERO
var discoveries:Array=[]
var camps:Array=[]

func map_point(v: Vector2) -> Vector2:
	return Vector2(185 + v.x * 1.2, 55 + (v.y+214) * 1.02)

func _draw() -> void:
	draw_style_box(panel_style(), Rect2(Vector2.ZERO, size))
	var font := get_theme_default_font()
	draw_string(font, Vector2(23, 32), "林区勘测图  /  北 ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("edf0ec"))
	# Nested contour loops distinguish the two exposed ridges from the low basin.
	for center in [Vector2(-34,-36),Vector2(45,-137),Vector2(-56,-158)]:
		for level in range(1,5):
			var contour:=PackedVector2Array()
			for i in range(49):
				var angle:=TAU*i/48.0;var radius:=6+level*3.8
				contour.append(map_point(center+Vector2(cos(angle)*radius,sin(angle)*radius*1.3)))
			draw_polyline(contour,Color(.65,.73,.77,.22),1,true)
	var shore:=PackedVector2Array()
	for i in range(49):shore.append(map_point(Vector2(-31+cos(TAU*i/48)*23,-89+sin(TAU*i/48)*15)))
	draw_colored_polygon(shore,Color("405e70"));draw_polyline(shore,Color("748e9e"),1.5,true)
	draw_line(map_point(Vector2(0, 18)), map_point(Vector2(0, -170)), Color("b8c3c7"), 2)
	var route := PackedVector2Array([map_point(Vector2(0, 0)), map_point(Vector2(22, -25)), map_point(Vector2(22, -140)), map_point(Vector2(0, -165))])
	draw_polyline(route, Color("83959f"), 2)
	draw_line(map_point(Vector2(-90, -86)), map_point(Vector2(90, -86)), Color("405e70"), 7)
	draw_line(map_point(Vector2(0,-76.7)),map_point(Vector2(0,-95.3)),Color("725f49"),4)
	# The compact settlement gets a readable inset, without overlapping map labels.
	if discoveries.has("lodge") or discoveries.has("lodge_route"):
		var panel:=Rect2(18,425,332,112);draw_rect(panel,Color("273b47"))
		draw_string(font,Vector2(28,446),"炭工聚落 / 北 ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("d7b879"))
		for row in [["woodshed",Vector2(40,467),"柴棚 · 干柴"],["bunkhouse",Vector2(199,467),"宿舍 · 衣物"],["lodge",Vector2(40,506),"木屋 · 炉床"],["canteen",Vector2(199,506),"伙房 · 食物"]]:
			if discoveries.has(row[0]) or discoveries.has("lodge_route"):
				draw_rect(Rect2(row[1]-Vector2(8,5),Vector2(5,5)),Color("d7b879"));draw_string(font,row[1],row[2],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("c1cecd"))
	for marker in [[Vector2(0,18),"护林小屋"],[Vector2(0,-170),"北岭车站"]]:
		if marker[1]=="护林小屋" and not discoveries.has("home_reached") and not discoveries.has("lodge_route") and not discoveries.has("home"):continue
		if marker[1]=="北岭车站" and not discoveries.has("home_log") and not discoveries.has("station"):continue
		var p := map_point(marker[0])
		draw_rect(Rect2(p - Vector2(5, 5), Vector2(10, 10)), Color("d7b879"))
		draw_string(font, p + Vector2(-115, 5), marker[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("edf0ec"))
	draw_string(font, Vector2(232, 220), "避风林道", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("b8c3c7"))
	var approach:=PackedVector2Array([map_point(Vector2(0,138)),map_point(Vector2(0,115)),map_point(Vector2(12,115)),map_point(Vector2(0,99)),map_point(Vector2(-11,82)),map_point(Vector2(0,60)),map_point(Vector2(0,27))]);draw_polyline(approach,Color("83959f"),1.5)
	for marker in [["gatehouse",Vector2(12,109),"岗亭 · 无炉"],["lodge",Vector2(-11,73),"木屋 · 有炉"],["wreck",Vector2(-14,-43),"邮递车"],["hunters",Vector2(22,-62),"猎人营地"],["lookout",Vector2(28,-115),"观测点"],["depot",Vector2(-15,-128),"堆场"],["ridge",Vector2(-34,-36),"西岭"],["hollow",Vector2(40,-43),"洼地"],["lake",Vector2(-28,-89),"冻湖"]]:
		if discoveries.has(marker[0]):
			var at:=map_point(marker[1]);draw_circle(at,3,Color("74664f"));draw_string(font,at+Vector2(7,5),marker[2],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("b8c3c7"))
	for camp in camps:
		var at:=map_point(Vector2(camp.position[0],camp.position[2]));draw_colored_polygon(PackedVector2Array([at+Vector2(0,-6),at+Vector2(6,5),at+Vector2(-6,5)]),Color("ce9a60"))
	var p := map_point(Vector2(player_position.x, player_position.z))
	draw_circle(p, 8, Color("17232b"))
	draw_circle(p, 5, Color("d7b879"))
	draw_string(font, Vector2(22, 555), "等高线：高地   蓝灰：冻湖   金点：你", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("b8c3c7"))
	draw_string(font, Vector2(22, 582), "搜寻落脚点，准备后再向北                    Tab 收起", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("b8c3c7"))

func panel_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("17232b")
	s.border_color = Color("50616a")
	s.set_border_width_all(1)
	s.set_corner_radius_all(1)
	return s
