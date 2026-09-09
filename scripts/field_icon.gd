extends Control
# Original field symbols on a 24-unit grid; no third-party game artwork.
var symbol:="health"
var tint:=Color("edf0ec")

func _draw()->void:
	paint(self,symbol,size*.5,minf(size.x,size.y)/28.0,tint)

static func paint(c:CanvasItem,id:String,at:Vector2,scale_value:float,color:Color)->void:
	c.draw_set_transform(at,0,Vector2.ONE*scale_value)
	match id:
		"health","medical","bandage":
			c.draw_rect(Rect2(-3,-10,6,20),color);c.draw_rect(Rect2(-10,-3,20,6),color)
		"temperature":
			c.draw_circle(Vector2(0,6),5,color);c.draw_line(Vector2(0,6),Vector2(0,-9),color,4,true)
			for y in [-8,-3]:c.draw_line(Vector2(4,y),Vector2(7,y),color,2,true)
		"stamina":
			c.draw_colored_polygon(PackedVector2Array([Vector2(1,-11),Vector2(-7,2),Vector2(-1,2),Vector2(-3,11),Vector2(8,-3),Vector2(2,-3)]),color)
		"battery":
			c.draw_style_box(rounded(color,2),Rect2(-7,-8,14,19));c.draw_rect(Rect2(-3,-11,6,3),color)
			c.draw_line(Vector2(-4,1),Vector2(4,1),Color("26353e"),2,true);c.draw_line(Vector2(0,-3),Vector2(0,5),Color("26353e"),2,true)
		"water","tea":
			var p:=PackedVector2Array([Vector2(0,-12),Vector2(7,0),Vector2(8,5),Vector2(5,9),Vector2(0,11),Vector2(-5,9),Vector2(-8,5),Vector2(-7,0)])
			c.draw_colored_polygon(p,color)
		"food":
			c.draw_style_box(rounded(color,3),Rect2(-8,-8,16,18));c.draw_line(Vector2(-6,-11),Vector2(6,-11),color,2,true)
			c.draw_line(Vector2(-4,-3),Vector2(4,-3),Color("26353e"),2,true)
		"energy":
			c.draw_circle(Vector2(0,-5),4,color);c.draw_line(Vector2(-7,3),Vector2(7,3),color,3,true);c.draw_line(Vector2(0,-1),Vector2(0,8),color,3,true)
			c.draw_line(Vector2(0,7),Vector2(-6,11),color,3,true);c.draw_line(Vector2(0,7),Vector2(6,11),color,3,true)
		"wood":
			for y in [-4,5]:c.draw_line(Vector2(-8,y+3),Vector2(8,y-3),color,5,true)
		"cloth":
			c.draw_colored_polygon(PackedVector2Array([Vector2(-9,-8),Vector2(6,-10),Vector2(10,8),Vector2(-6,10)]),color)
			c.draw_line(Vector2(0,-6),Vector2(3,6),Color("26353e"),2,true)
		"herb":
			c.draw_line(Vector2(0,10),Vector2(0,-9),color,2,true)
			for y in [-6,0,6]:c.draw_line(Vector2(0,y),Vector2(-6,y-4),color,4,true);c.draw_line(Vector2(0,y-2),Vector2(6,y-6),color,4,true)
		"player","tape_embers","tape_stride","tape_home":
			c.draw_style_box(rounded(color,2),Rect2(-11,-7,22,15))
			for x in [-5,5]:c.draw_circle(Vector2(x,0),3,Color("26353e"))
			c.draw_line(Vector2(-5,5),Vector2(5,5),Color("26353e"),2,true)
			if id=="player":c.draw_line(Vector2(-6,-10),Vector2(6,-10),color,2,true)
		"scrap","parts":
			c.draw_line(Vector2(-7,8),Vector2(6,-6),color,6,true);c.draw_arc(Vector2(5,-6),5,.2,4.5,16,color,3,true)
		"map":
			c.draw_polyline(PackedVector2Array([Vector2(-10,9),Vector2(-10,-7),Vector2(-3,-10),Vector2(4,-7),Vector2(10,-10),Vector2(10,7),Vector2(4,10),Vector2(-3,7),Vector2(-10,9)]),color,2,true)
			c.draw_line(Vector2(-3,-10),Vector2(-3,7),color,2,true);c.draw_line(Vector2(4,-7),Vector2(4,10),color,2,true)
		_:
			c.draw_style_box(rounded(color,3),Rect2(-9,-6,18,17));c.draw_arc(Vector2(0,-6),5,PI,TAU,16,color,2,true)
			c.draw_line(Vector2(-5,3),Vector2(5,3),Color("26353e"),2,true)
	c.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

static func rounded(color:Color,radius:int)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=color;style.set_corner_radius_all(radius);return style
