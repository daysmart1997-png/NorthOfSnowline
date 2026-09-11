extends SubViewportContainer
# One selected object owns one viewport. Grid icons stay lightweight.
const Catalog=preload("res://scripts/arrival_catalog.gd")
var item_id:="water"
var action:=""
var model:Node3D
var view:SubViewport
var dragging:=false
var clock:=0.0
func _ready()->void:
 custom_minimum_size=Vector2(400,170);stretch=true;mouse_default_cursor_shape=Control.CURSOR_DRAG
 tooltip_text="拖动查看实物"
 view=SubViewport.new();view.size=Vector2i(400,170);view.own_world_3d=true;view.transparent_bg=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS;view.audio_listener_enable_3d=false;add_child(view)
 var environment:=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color(0,0,0,0);environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("a9b8bf");environment.environment.ambient_light_energy=.65;view.add_child(environment)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,-35,0);light.light_energy=1.3;view.add_child(light)
 model=load("res://assets/arrival/item_"+item_id+".glb").instantiate();view.add_child(model);model.rotation.y=-.25
 var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=.70;view.add_child(camera);camera.position=Vector3(.72,.55,1.2);camera.look_at(Vector3(0,.18 if item_id=="water" else .08,0));camera.current=true

func _gui_input(event:InputEvent)->void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:dragging=event.pressed;accept_event()
 if event is InputEventMouseMotion and dragging and is_instance_valid(model):model.rotation.y+=event.relative.x*.012;accept_event()

func _process(delta:float)->void:
 if not is_instance_valid(model):return
 clock+=delta
 if action=="use" and clock<1.0:
  var t:=sin(clampf(clock,0,1)*PI)
  model.rotation.z=t*(-.35 if item_id=="water" else .08)
  var moving:Node3D=model.find_child("Cap" if item_id=="water" else "Seal",true,false)
  if moving:moving.position.y=t*.085;moving.rotation.y=t*1.5
 else:model.rotation.z=0.0
 # Stop redrawing still previews; interaction or a short action wakes rendering.
 if is_instance_valid(view):view.render_target_update_mode=SubViewport.UPDATE_ALWAYS if dragging or clock<1.2 else SubViewport.UPDATE_ONCE if view.render_target_update_mode==SubViewport.UPDATE_ALWAYS else SubViewport.UPDATE_DISABLED
