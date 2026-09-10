extends HBoxContainer
const Kit=preload("res://scripts/field_kit.gd")
const Palette=preload("res://scripts/field_theme.gd")
var game
var bag
var part:="feet"
var body_view:=false
var preview:Node3D
var angle:=PI-.3
var dragging:=false
var drag_distance:=0.0

func setup(main,owner_bag)->void:
 game=main;bag=owner_bag;size_flags_horizontal=Control.SIZE_EXPAND_FILL;size_flags_vertical=Control.SIZE_EXPAND_FILL
 part=bag.character_part;body_view=bag.body_view;angle=bag.character_angle
 add_theme_constant_override("separation",24)
 var left:=VBoxContainer.new();left.custom_minimum_size.x=460;add_child(left)
 var tabs:=HBoxContainer.new();left.add_child(tabs)
 for pair in [[false,"衣着"],[true,"身体"]]:
  var mode:bool=pair[0]
  var b=game.button(pair[1],func():bag.body_view=mode;bag.refresh(),tabs)
  b.name="BodyMode" if mode else "ClothingMode"
 var view:=SubViewportContainer.new();view.custom_minimum_size=Vector2(460,290);view.size_flags_vertical=Control.SIZE_EXPAND_FILL;view.stretch=true;left.add_child(view)
 var vp:=SubViewport.new();vp.size=Vector2i(460,320);vp.transparent_bg=true;vp.own_world_3d=true;vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;view.add_child(vp)
 preview=game.player.MODEL.instantiate();vp.add_child(preview);preview.rotation.y=angle
 apply_clothes(preview,game.survival.kit)
 var players:=preview.find_children("*","AnimationPlayer",true,false)
 if not players.is_empty() and game.player.animation_names.has("Idle"):
  var idle:String=game.player.animation_names.Idle
  if players[0].has_animation(idle):players[0].play(idle);players[0].speed_scale=.7
 var camera:=Camera3D.new();vp.add_child(camera);camera.position=Vector3(0,1.2,3.4);camera.look_at(Vector3(0,.94,0));camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.05;camera.current=true
 var light:=DirectionalLight3D.new();vp.add_child(light);light.rotation_degrees=Vector3(-30,-30,0);light.light_color=Color("ffe5c0");light.light_energy=1.8
 var fill:=DirectionalLight3D.new();vp.add_child(fill);fill.rotation_degrees=Vector3(-20,150,0);fill.light_color=Color("a3c2dc");fill.light_energy=.8
 view.gui_input.connect(func(event):
  if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
   dragging=event.pressed
   if dragging:drag_distance=0
   elif drag_distance<5:
    var vertical:float=event.position.y/maxf(view.size.y,1)
    var horizontal:float=absf(event.position.x-view.size.x*.5)/maxf(view.size.x,1)
    bag.character_part="head" if vertical<.23 else ("feet" if vertical>.85 else ("legs" if vertical>.62 else ("hands" if horizontal>.14 else "torso")))
    bag.refresh()
  if event is InputEventMouseMotion and dragging:drag_distance+=event.relative.length();angle+=event.relative.x*.012;preview.rotation.y=angle;bag.character_angle=angle)
 left.add_child(game.label("拖动旋转  ·  保暖 %d  ·  负重 %.1f / 24 kg"%[game.survival.kit.warmth(),game.survival.weight()],14,Palette.ACCENT))
 var slots:=GridContainer.new();slots.columns=3;left.add_child(slots)
 for slot in Kit.SLOTS:
  var key:String=slot
  var b=game.button(Kit.SLOTS[slot],func():bag.character_part=key;bag.refresh(),slots);b.name="BodyPart_"+slot;b.custom_minimum_size=Vector2(123,34)
  if part==slot:b.add_theme_stylebox_override("normal",Palette.box(Palette.RAISED,Palette.ACCENT))
 var paper:=PanelContainer.new();paper.size_flags_horizontal=Control.SIZE_EXPAND_FILL;paper.add_theme_stylebox_override("panel",Palette.paper());add_child(paper)
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;paper.add_child(scroll)
 var details:=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details.add_theme_constant_override("separation",12);scroll.add_child(details)
 if body_view:body_details(details)
 else:clothing_details(details)
 for button in details.find_children("*","Button",true,false):Palette.paper_button(button)

func ink(parent:Node,text:String,font_size:int=17)->Label:
 var l:Label=game.label(text,font_size,Color("333e40"));l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l

func clothing_details(parent:Node)->void:
 var kit=game.survival.kit
 var current:String=kit.equipped[part];var g:Dictionary=kit.owned[current];var spec:Dictionary=Kit.GEAR[g.type]
 ink(parent,spec.name,26)
 ink(parent,"潮湿 %d%%  ·  完好 %d%%\n保暖 %d  ·  挡风 %d  ·  %.1f kg"%[g.wet,g.condition,spec.warmth,spec.wind,spec.weight])
 ink(parent,"潮湿内衬使保暖下降；炉边烘干可恢复。" if g.wet>15 else "衣物干燥。出发前留意天气和返程重量。")
 var row:=HBoxContainer.new();parent.add_child(row)
 var dry=game.button("靠炉烘干 · 15 分钟",func():bag.feedback.text=game.field.start_job("dry",current);bag.refresh(),row);dry.name="DryGarment"
 var shelter:String=game.world.shelter_at(game.player.position)
 var hot:bool=float(game.survival.fires.get(shelter,0))>15
 dry.disabled=not hot or g.wet<=0
 if not hot:ink(parent,"需要炉火余量至少 16 分钟；靠近火炉按 E 添柴。",14)
 game.button("修补 · 布料 ×1",func():bag.feedback.text=game.field.start_job("mend",current);bag.refresh(),parent).name="MendGarment"
 ink(parent,"可替换衣物",20)
 var found:=false
 for id in kit.owned:
  if id==current or Kit.GEAR[kit.owned[id].type].slot!=part:continue
  found=true
  var key:String=id;var other:Dictionary=Kit.GEAR[kit.owned[id].type]
  game.button("换上 %s\n保暖 %+d · 衣物重 %+.1f kg（已计入负重）"%[other.name,int(other.warmth)-int(spec.warmth),float(other.weight)-float(spec.weight)],func():bag.feedback.text=kit.wear(key);bag.refresh(),parent)
  game.button("拆解这件备用衣物 → 布料 ×1",func():bag.feedback.text=kit.salvage(game.survival,key);bag.refresh(),parent)
 for item in Kit.GEAR:
  if Kit.GEAR[item].slot!=part or game.survival.count(item)<=0:continue
  found=true;var id:String=item
  game.button("收好并换上 "+Kit.GEAR[id].name,func():bag.feedback.text=game.survival.use_item(id);bag.refresh(),parent)
 if not found:ink(parent,"尚无替换衣物。邮递车包裹、营地和维修站衣柜值得搜寻。",15)

func body_details(parent:Node)->void:
 ink(parent,Kit.SLOTS[part]+" · 身体状态",26)
 ink(parent,"健康 %d  ·  体温状态 %d\n饱食 %d  ·  水分 %d  ·  精力 %d"%[game.survival.health,game.survival.temperature,game.survival.hunger,game.survival.thirst,game.survival.energy])
 var found:=false
 for id in game.survival.kit.conditions:
  var c:Dictionary=game.survival.kit.conditions[id]
  if c.part!=part:continue
  found=true;var key:String=id
  ink(parent,Kit.CONDITIONS[c.kind]+(" · 已处理" if c.treated else " · 待处理"),22)
  var why:String=game.survival.kit.treatment_problem(game.survival,id)
  ink(parent,why if not why.is_empty() else "对应物资充足。处理后在安全处休息恢复。",15)
  var b=game.button("处理 "+Kit.CONDITIONS[c.kind],func():bag.feedback.text=game.survival.kit.treat(game.survival,key);bag.refresh(),parent)
  b.disabled=not why.is_empty();b.name="Treat_"+c.kind
 if not found:ink(parent,"此部位没有伤情。\n湿衣请切换到衣着查看。",18)

static func apply_clothes(root:Node,kit)->void:
 for node in root.find_children("*","MeshInstance3D",true,false):
  for surface in range(node.mesh.get_surface_count()):
   var original:Material=node.mesh.surface_get_material(surface)
   if original==null:continue
   var slot:=""
   var name:String=original.resource_name
   for key in Kit.SLOTS:
    if name.begins_with("Gear_"+key):slot=key;break
   if slot.is_empty():continue
   var g:Dictionary=kit.owned[kit.equipped[slot]]
   var tint:=Color(Kit.GEAR[g.type].color).darkened(float(g.wet)/100*.23)
   if name.ends_with("_Tripo") and original is StandardMaterial3D and original.albedo_texture!=null:
    var defaults:Dictionary={"head":"cap","torso":"coat","hands":"gloves","legs":"trousers","feet":"boots","pack":"pack"}
    var source:=Color(Kit.GEAR[defaults[slot]].color)
    var chosen:=Color(Kit.GEAR[g.type].color)
    var factor:=Vector3(chosen.r/source.r,chosen.g/source.g,chosen.b/source.b)
    var textured:=ShaderMaterial.new();textured.shader=preload("res://assets/shaders/tripo_clothing.gdshader")
    textured.set_shader_parameter("atlas",original.albedo_texture)
    textured.set_shader_parameter("dye_factor",factor)
    textured.set_shader_parameter("wetness",float(g.wet)/100)
    textured.set_shader_parameter("protect_warm_details",slot in ["torso","legs","hands"])
    node.set_surface_override_material(surface,textured);continue
   if name.contains("Brass") or (slot in ["pack","torso"] and name.contains("Leather")):
    node.set_surface_override_material(surface,null);continue
   if name.contains("Wool") or name.contains("Canvas"):
    var fabric:=ShaderMaterial.new();fabric.shader=load("res://assets/shaders/wool.gdshader");fabric.set_shader_parameter("fabric_color",tint);node.set_surface_override_material(surface,fabric)
   else:
    var mat:=StandardMaterial3D.new();mat.albedo_color=tint;mat.roughness=.93
    if name.contains("Dark"):mat.albedo_color=mat.albedo_color.darkened(.35)
    node.set_surface_override_material(surface,mat)
