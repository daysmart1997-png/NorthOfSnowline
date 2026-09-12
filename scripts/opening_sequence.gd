extends CanvasLayer
# Three quiet establishing shots. Survival is frozen; every card is skippable.
const CARDS := [
	["暮色将至 / 北岭山口", "你在风雪里走了一天，终于穿过山口。\n最后一份口粮已经吃完，谷口还没有收到你的平安报。", Vector3(-7,3,134)],
	["未归的搭档", "周岑，呼号北岭四，前往北坡检查信标。\n昨天约好的守听没有回应。他至今没有回报。", Vector3(-10,4,137)],
	["第一章 / 失联", "湿靴正在带走热量。山路往低处延伸。\n天黑前找到有炉的落脚点，备好食物与干柴。", Vector3(0,0,130)]
]
var game
var camera:Camera3D
var sheet:Control
var heading:Label
var caption:Label
var page:=0
var clock:=0.0

func setup(main)->void:
	game=main;layer=20
	sheet=Control.new();sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(sheet)
	sheet.theme=game.canvas.theme
	for rect in [Rect2(0,0,1280,65),Rect2(0,510,1280,210)]:
		var bar:=ColorRect.new();bar.position=rect.position;bar.size=rect.size;bar.color=Color(.025,.045,.06,.94);sheet.add_child(bar)
	heading=game.label("",24);heading.position=Vector2(82,540);sheet.add_child(heading)
	caption=game.label("",19);caption.position=Vector2(82,584);caption.size=Vector2(865,92);sheet.add_child(caption)
	var next:Button=game.button("继续",advance,sheet);next.name="OpeningContinue";next.position=Vector2(1040,555);next.size=Vector2(158,46)
	var skip:Button=game.button("跳过开场 · Esc",finish,sheet);skip.position=Vector2(1040,615);skip.size=Vector2(158,42)
	camera=Camera3D.new();game.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.cull_mask=game.interior_view.OUTDOOR_VIEW
	sheet.visible=false;set_process(false)

func begin()->void:
	game.cancel_action();game.active=false;game.player.enabled=false;game.player.velocity=Vector3.ZERO
	game.canvas.visible=false;sheet.visible=true;camera.current=true;page=0;show_card();set_process(true)

func show_card()->void:
	clock=0;heading.text=CARDS[page][0];caption.text=CARDS[page][1]
	sheet.get_node("OpeningContinue").grab_focus()
	# Cutaway still follows the player; temporarily restore the exterior for the cabin shot.
	for entry in game.world.cutaways:
		for node in entry.nodes:node.visible=true

func _process(delta:float)->void:
	clock+=delta
	var t:float=smoothstep(0,6,clock)
	var focus:Vector3=CARDS[page][2]+Vector3(0,.8,0)
	camera.position=focus+Vector3(15,23,21);camera.look_at(focus)
	camera.size=lerpf(38 if page==0 else 29,31 if page==0 else 24,t)
	# Establishing shots show exterior light; InteriorView resumes control on return.
	game.world.sun.light_cull_mask=0xfffff;game.world.night_fill.light_cull_mask=0xfffff
	game.world.sun.shadow_enabled=game.world.sun.light_energy>.015
	game.world.snow.global_position=focus+Vector3(0,7,0);game.world.snow.visible=true
	# Keep captions until the player advances; slow readers never lose a line.
	heading.modulate.a=clampf(clock*2,0,1);caption.modulate.a=heading.modulate.a
	for entry in game.world.cutaways:
		for node in entry.nodes:node.visible=true

func advance()->void:
	page+=1
	if page>=CARDS.size():finish()
	else:show_card()

func finish()->void:
	if not sheet.visible:return
	set_process(false);sheet.visible=false;game.player.camera.current=true;game.canvas.visible=true
	game.set_menu(false);game.interior_view.update()
	game.notify("沿山口向低处寻找人类活动的痕迹 · 靠近物品按 E，B 查看行囊。")

func _input(event:InputEvent)->void:
	if sheet.visible and event.is_action_pressed("pause_game"):
		finish();get_viewport().set_input_as_handled()
