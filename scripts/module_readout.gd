extends Control
# Only visible within reach of the physical module; no separate repair state.
var game
var stage:=0
var fraction:=0.0
const INK=Color("dce0d7")
const DIM=Color("89958f")
const WARM=Color("c7aa71")

func _process(_delta:float)->void:
 if game==null:return
 visible=game.active and not game.map.visible and not game.survival.parts and game.target.get("id","")=="radio_parts"
 if not visible:return
 position=Vector2(game.canvas.size.x-326,game.canvas.size.y-310);size=Vector2(294,144)
 stage=game.survival.kit.route_stage
 fraction=clampf(game.field.progress/maxf(float(game.field.job.get("duration",1)),.1),0,1) if game.field.job.get("kind","")=="module" and stage==2 else 0
 queue_redraw()

func _draw()->void:
 var font:=get_theme_default_font()
 draw_style_box(panel(),Rect2(Vector2.ZERO,size))
 draw_string(font,Vector2(16,25),"发射模块",HORIZONTAL_ALIGNMENT_LEFT,-1,16,INK)
 var labels:=["接点","导线","测试"]
 for i in range(3):
  var x:=47.0+i*98
  var color:Color=INK if stage>i else DIM
  if i==0:
   for j in range(3):
    draw_rect(Rect2(x-17+j*12,43,7,23),color)
    if stage==0:draw_line(Vector2(x-17+j*12,49),Vector2(x-10+j*12,58),WARM,2,true)
  elif i==1:
   draw_line(Vector2(x-24,57),Vector2(x-2,57),color,2,true)
   draw_line(Vector2(x-2,57 if stage>=2 else 46),Vector2(x+23,57),color,2,true)
   draw_circle(Vector2(x+23,57),3,color)
  else:
   draw_arc(Vector2(x,68),24,PI,TAU,24,DIM,1,true)
   var angle:=lerpf(PI*1.10,PI*1.84,1.0 if stage>=3 else fraction)
   draw_line(Vector2(x,68),Vector2(x,68)+Vector2.from_angle(angle)*22,WARM,2,true)
  draw_string(font,Vector2(x-17,94),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,14,color)
  draw_string(font,Vector2(x-26,119),"已完成" if stage>i else ("处理中" if stage==i and not game.field.job.is_empty() else "待检查"),HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)

func panel()->StyleBoxFlat:
 var box:=StyleBoxFlat.new();box.bg_color=Color(.045,.075,.087,.84)
 return box
