extends Control
const Palette=preload("res://scripts/field_theme.gd")
const Icon=preload("res://scripts/field_icon.gd")
var hud_scale:=1.0
var temperature_trend:=0.0
var action_progress:=-1.0
var survival
var typeface:Font=Palette.font()
var scrim:GradientTexture2D

func _ready()->void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	scrim=GradientTexture2D.new();scrim.width=2;scrim.height=128
	scrim.fill_from=Vector2.ZERO;scrim.fill_to=Vector2(0,1)
	var gradient:=Gradient.new()
	gradient.colors=PackedColorArray([Color(.035,.065,.085,0),Color(.035,.065,.085,.64)])
	scrim.gradient=gradient

func text_at(text:String,at:Vector2,fontsize:int,color:=Palette.INK)->void:
	draw_string_outline(typeface,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize,2,Color(.04,.07,.09,.55))
	draw_string(typeface,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize,color)

func scaled_icon(id:String,at:Vector2,ratio:float,color:Color,origin:Vector2)->void:
	# Icon.paint owns and resets its draw transform; restore the HUD transform.
	Icon.paint(self,id,origin+at*hud_scale,ratio*hud_scale,color)
	draw_set_transform(origin,0,Vector2.ONE*hud_scale)

func _draw()->void:
	if survival==null:return
	# A functional bottom scrim keeps white symbols readable across white snow.
	draw_texture_rect(scrim,Rect2(0,size.y-112*hud_scale,size.x,112*hud_scale),false)
	var y:=size.y-52
	var origin:=Vector2(0,size.y*(1-hud_scale))
	draw_set_transform(origin,0,Vector2.ONE*hud_scale)
	var health_color:Color=Palette.DANGER if survival.health<25 else Palette.INK
	# Compact two-row cluster: health above, five needs aligned below.
	scaled_icon("health",Vector2(42,y-44),.65,health_color,origin)
	text_at("健康",Vector2(56,y-39),14,health_color)
	draw_rect(Rect2(100,y-47,174,3),Color(1,1,1,.22))
	draw_rect(Rect2(100,y-47,174*clampf(survival.health/100.0,0,1),3),health_color)
	var values:Array=[survival.temperature,survival.stamina,survival.thirst,survival.hunger,survival.energy]
	var names:=["体温","体力","水分","饱食","精力"]
	var symbols:=["temperature","stamina","water","food","energy"]
	for i in range(5):
		var x:=42.0+i*54
		var value:float=values[i]
		var ink:Color=Palette.DANGER if value<25 else Palette.INK
		scaled_icon(symbols[i],Vector2(x,y-8),.6,ink,origin)
		draw_rect(Rect2(x-12,y+6,24,3),Color(1,1,1,.22))
		draw_rect(Rect2(x-12,y+6,24*clampf(value/100.0,0,1),3),ink)
		text_at(names[i],Vector2(x-14,y+27),14,ink)
		if i==0 and absf(temperature_trend)>.001:
			text_at("↑" if temperature_trend>0 else "↓",Vector2(x+11,y-20),12,Palette.ACCENT if temperature_trend>0 else ink)
		if value<25:text_at("低",Vector2(x+10,y-3),14,ink)
	origin.x=size.x*(1-hud_scale)
	draw_set_transform(origin,0,Vector2.ONE*hud_scale)
	scaled_icon("backpack",Vector2(size.x-224,y-8),.8,Palette.INK,origin)
	text_at("%.1f / 24 kg"%survival.weight(),Vector2(size.x-205,y-13),16)
	text_at("B 行囊    Tab 地图    Esc 暂停",Vector2(size.x-267,y+20),14,Palette.MUTED)
	draw_set_transform(Vector2.ZERO)
	if action_progress>=0:
		draw_rect(Rect2(size.x/2-90,553,180,2),Palette.LINE)
		draw_rect(Rect2(size.x/2-90,553,180*action_progress,2),Palette.INK)
