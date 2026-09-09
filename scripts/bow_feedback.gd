extends Control
## Presentation only: all collision and charge rules belong to FieldExpedition.
const Palette=preload("res://scripts/field_theme.gd")
var field
var preview:=PackedVector3Array()
var traces:Array=[]
var refresh:=0.0
var cursor_active:=false
var mouse:=Vector2.ZERO
var typeface:Font=Palette.font()

func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func add_trace(a:Vector3,b:Vector3)->void:
 traces.append({"a":a,"b":b,"life":.28})
 if traces.size()>96:traces.pop_front()

func _process(delta:float)->void:
 if field==null:return
 var game=field.game
 for t in traces:t.life-=delta
 traces=traces.filter(func(t):return t.life>0)
 cursor_active=game.active and not game.map.visible and game.survival.kit.weapon=="bow" and game.survival.count("bow")>0 and field.job.is_empty()
 mouse=get_local_mouse_position()
 refresh-=delta
 if not cursor_active or not field.drawing:preview.clear()
 elif refresh<=0:
  preview=field.predict_arrow(field.aim_point());refresh=1.0/30.0
 visible=game.active and not game.map.visible
 queue_redraw()

func screen(at:Vector3)->Vector2:
 return get_global_transform().affine_inverse()*field.game.player.camera.unproject_position(at)

func segment(a:Vector3,b:Vector3,color:Color,width:float)->void:
 var camera=field.game.player.camera
 if camera.is_position_behind(a) or camera.is_position_behind(b):return
 draw_line(screen(a),screen(b),color,width,true)

func _draw()->void:
 if field==null:return
 for t in traces:segment(t.a,t.b,Color(.92,.82,.57,t.life/.28*.8),2.0)
 if not cursor_active:return
 var ink:=Color("eee6ce") if field.game.survival.count("arrow")>0 else Palette.DANGER
 for i in range(1,preview.size()):
  if i%3!=0:segment(preview[i-1],preview[i],Color(ink,.48),1.4)
 if preview.size()>1:
  var end:=screen(preview[-1]);draw_arc(end,5,0,TAU,24,Color(ink,.7),1.5,true)
 var radius:=lerpf(19,10,field.aim_time) if field.drawing else 15.0
 draw_arc(mouse,radius+1,0,TAU,48,Color(.04,.08,.1,.65),3,true)
 draw_arc(mouse,radius,0,TAU,48,Color(ink,.8),1.3,true)
 draw_circle(mouse,1.7,ink)
 if field.drawing:draw_arc(mouse,radius+5,-PI/2,-PI/2+TAU*maxf(.001,field.aim_time),48,ink,2,true)
 var count_text:=str(field.game.survival.count("arrow"))
 draw_string_outline(typeface,mouse+Vector2(23,5),count_text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,2,Color(.04,.08,.1,.8))
 draw_string(typeface,mouse+Vector2(23,5),count_text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,ink)
