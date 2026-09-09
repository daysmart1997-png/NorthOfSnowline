extends PanelContainer
const Chapter=preload("res://scripts/chapter_one.gd")
const Palette=preload("res://scripts/field_theme.gd")
var game
var scene_kind:=""
var title_label:Label
var body_label:Label
var choices:VBoxContainer
var scroll:ScrollContainer
var radio_sound:AudioStreamPlayer
var route_status:Label

func setup(main)->void:
	game=main;name="ChapterPanel";position=Vector2(260,82);custom_minimum_size=Vector2(760,556)
	var surface=Palette.box(Palette.PANEL);surface.content_margin_left=32;surface.content_margin_right=32;surface.content_margin_top=24;surface.content_margin_bottom=24
	add_theme_stylebox_override("panel",surface)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",14);add_child(column)
	column.add_child(game.label("第一章  /  最后一班电波",14,Palette.MUTED))
	title_label=game.label("",24);column.add_child(title_label)
	scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(696,230);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	body_label=game.label("",17);body_label.name="ChapterText";body_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;scroll.add_child(body_label)
	route_status=game.label("",14,Palette.ACCENT);route_status.name="ReturnConditions";route_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(route_status)
	choices=VBoxContainer.new();choices.add_theme_constant_override("separation",8);column.add_child(choices)
	column.add_child(game.label("阅读时已暂停  ·  Esc 暂时收起  ·  记录保留在探索手记",13,Palette.MUTED))
	radio_sound=AudioStreamPlayer.new();radio_sound.bus="SnowEffects";radio_sound.volume_db=-23;add_child(radio_sound)
	var sample:=AudioStreamWAV.new();sample.format=AudioStreamWAV.FORMAT_16_BITS;sample.mix_rate=22050
	var bytes:=PackedByteArray();bytes.resize(6615*2)
	var random:=RandomNumberGenerator.new();random.seed=821
	var filtered:=0.0
	for i in range(6615):
		filtered=lerpf(filtered,random.randf_range(-1,1),.65)
		var envelope:=sin(PI*float(i)/6615.0)
		bytes.encode_s16(i*2,int(filtered*envelope*6500))
	sample.data=bytes;radio_sound.stream=sample
	visible=false

func show_scene(kind:String)->void:
	scene_kind=kind;visible=true;refresh()

func option(id:String,text:String,callback:Callable)->void:
	var control:Button=game.button(text,callback,choices);control.name="Story_"+id;control.add_theme_font_size_override("font_size",16)

func refresh()->void:
	for child in choices.get_children():choices.remove_child(child);child.queue_free()
	var s=game.survival
	scroll.scroll_vertical=0
	route_status.visible=scene_kind=="station"
	scroll.custom_minimum_size.y=190 if scene_kind=="station" else 230
	if scene_kind=="intro":
		title_label.text="没能发出的平安报"
		body_label.text=Chapter.CLUES.home_log.text
		option("leave","收好记录 · 准备出发",game.close_story)
	elif scene_kind=="station":
		title_label.text="留给后来的人"
		body_label.text="备用模块下的交接单写着：\n\n‘末班车取消，人员撤往谷口。模块留下，供沿线小屋求援。送药的林和守桥人尚未回报；西岭转运箱里留有收信簿。’\n\n车站已经撤空，小屋的无线电是你与外界的联系。先带零件回家，或在物资允许时查清两人的下落。完整交接单已收进手记。"
		route_status.text=return_conditions()
		option("direct","沿铁路返家 · 路程直接，迎风更冷",func():select_route("direct"))
		option("sheltered","沿林道返家 · 绕远一些，沿途可避风",func():select_route("sheltered"))
		option("ridge","绕访西岭 · 可选收信簿，高地迎风",func():select_route("ridge"))
	else:
		match int(s.chapter.radio_step):
			1:
				title_label.text="发射灯亮了"
				body_label.text="备用模块接上后，指针终于越过红线。\n\n你调整到值守簿上留下的巡林频道。窗外的风还在吹，听筒里传来一段短促的电流声。\n\n这一次，可以把自己的位置说出去了。"
				option("call","按下通话键 · 报告位置",func():transmit("call"))
			2:
				title_label.text="谷口有人守听"
				body_label.text="你：这里是护林小屋。下山公路被山崩截断，只有我一个人。能听见吗？\n\n电流声停了一瞬。\n\n谷口值守：听见了。我们还在。你那里能生火吗？北岭的人已经撤了，沿路有没有留下消息？"
				option("report","报告沿途发现",func():transmit("report"))
				option("ask","先询问下山的办法，再报告发现",func():transmit("ask"))
			3:
				title_label.text="你的位置被记下了"
				body_label.text=Chapter.radio_response(s)
				option("confirm","回复：收到。我会守住小屋。",func():transmit("confirm"))
			_:
				title_label.text="第一章 · 平安报"
				body_label.text="谷口值守：明晚，同一频道。\n\n你松开通话键。屋里仍然很冷，但这间小屋终于不再是地图上无人知晓的一点。\n\n本章已完成。你可以继续在现有林区寻找遗漏的记录、准备补给、修缮小屋。北坡信标的故事留待下一章。"
				option("finish","收起听筒 · 留在林区休整",game.close_story)
	if choices.get_child_count()>0:choices.get_child(0).grab_focus()

func return_conditions()->String:
	var s=game.survival
	return "现在 %s · 体温 %d · 木柴 %d · 水 %d\n%s  返程打算可随时在手记里调整。"%[game.DayCycle.clock_text(s.elapsed),s.temperature,s.wood,s.count("water"),"体温偏低，建议先取暖，暂缓登岭。" if s.temperature<40 else ("风雪正在增强，高地与铁路更耗体温。" if s.storm()>.25 else "留意天色，返程还需要时间与补给。")]

func select_route(route:String)->void:
	if Chapter.choose_route(game.survival,route):game.close_story();game.notify("已记下返程打算 · "+Chapter.ROUTES[route])

func transmit(choice:String)->void:
	if Chapter.advance_radio(game.survival,choice):
		radio_sound.play();refresh()

func shutdown_audio()->void:
	if is_instance_valid(radio_sound):radio_sound.stop();radio_sound.stream=null

func _exit_tree()->void:shutdown_audio()
