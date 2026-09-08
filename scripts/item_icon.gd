extends Control
var item_id := "wood"
func _draw() -> void:
	var c:=Color("b5ab91")
	match item_id:
		"player":
			draw_style_box(block(Color("485c63")),Rect2(5,8,55,39))
			draw_rect(Rect2(13,16,34,19),Color("17282e"))
			for x in [23,37]: draw_circle(Vector2(x,25),5,Color("a0aca2"));draw_circle(Vector2(x,25),2,Color("263940"))
			for x in [17,25,33,41]:draw_rect(Rect2(x,39,5,3),Color("c89758"))
		"tape_embers","tape_stride","tape_home":
			draw_style_box(block(Color("aa8b64") if item_id=="tape_embers" else Color("83958e")),Rect2(5,13,55,31))
			draw_rect(Rect2(11,18,43,13),Color("263c46"))
			for x in [23,41]:draw_circle(Vector2(x,24),4,Color("e1d3ae"))
			draw_line(Vector2(20,37),Vector2(46,37),Color("ded2b6"),2)
		"wood":
			for y in [22,34]:
				draw_line(Vector2(13,y+7),Vector2(49,y-5),Color("816348"),9)
				draw_circle(Vector2(13,y+7),5,Color("b6996c"));draw_circle(Vector2(13,y+7),2,Color("6c513b"))
		"water","tea":
			draw_style_box(block(Color("87a4b4") if item_id=="water" else Color("bd8c55")),Rect2(19,14,27,34))
			draw_rect(Rect2(23,8,18,8),Color("485860"));draw_line(Vector2(24,24),Vector2(24,39),Color("cfdfdc"),3)
		"cloth","bandage":
			draw_style_box(block(Color("d0c3a5")),Rect2(12,17,42,28))
			for x in [22,30,38]:draw_line(Vector2(x,18),Vector2(x-3,43),Color("9e927e"),2)
		"scrap","parts":
			draw_rect(Rect2(12,19,41,24),Color("647a85"))
			for p in [Vector2(19,26),Vector2(46,36)]:draw_circle(p,3,Color("c0baa2"))
			draw_line(Vector2(24,16),Vector2(44,12),Color("b19160"),4)
		"herb":
			draw_line(Vector2(31,45),Vector2(31,13),Color("97a480"),2)
			for i in range(3):draw_circle(Vector2(25,20+i*8),5,Color("81916f"));draw_circle(Vector2(37,15+i*8),4,Color("a4ad82"))
		"battery":
			draw_style_box(block(Color("969375")),Rect2(20,12,25,36));draw_rect(Rect2(26,8,13,5),c)
			draw_line(Vector2(27,29),Vector2(39,29),Color("263b44"),3);draw_line(Vector2(33,23),Vector2(33,35),Color("263b44"),3)
		_:
			draw_style_box(block(Color("7c8b7e")),Rect2(17,12,31,36));draw_rect(Rect2(19,25,27,11),Color("c6b896"))
func block(color:Color)->StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=color;s.set_corner_radius_all(4);return s
