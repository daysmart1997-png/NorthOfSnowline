extends PanelContainer
const Chapter=preload("res://scripts/chapter_one.gd")
const Routes=preload("res://scripts/route_planner.gd")
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
	game=main;name="ChapterPanel";position=Vector2(650,52);custom_minimum_size=Vector2(580,616)
	var surface=Palette.paper();surface.content_margin_left=32;surface.content_margin_right=32;surface.content_margin_top=24;surface.content_margin_bottom=24
	add_theme_stylebox_override("panel",surface)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",14);add_child(column)
	column.add_child(game.label("七号值守簿  /  第一章 · 失联",14,Color("596061")))
	title_label=game.label("",24,Color("253238"));column.add_child(title_label)
	scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(516,230);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	body_label=game.label("",17,Color("344044"));body_label.name="ChapterText";body_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;scroll.add_child(body_label)
	route_status=game.label("",14,Color("755433"));route_status.name="ReturnConditions";route_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(route_status)
	choices=VBoxContainer.new();choices.add_theme_constant_override("separation",8);column.add_child(choices)
	column.add_child(game.label("阅读时已暂停  ·  Esc 暂时收起  ·  记录保留在探索手记",13,Color("616564")))
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
	if kind=="departure":game.experience.sound("memory_tape")

func option(id:String,text:String,callback:Callable)->void:
	var control:Button=game.button(text,callback,choices);control.name="Story_"+id;control.add_theme_font_size_override("font_size",16);Palette.paper_button(control)

func refresh()->void:
	for child in choices.get_children():choices.remove_child(child);child.queue_free()
	var s=game.survival
	scroll.scroll_vertical=0
	route_status.visible=scene_kind=="station"
	scroll.custom_minimum_size.y=145 if scene_kind=="station" else 230
	body_label.add_theme_font_size_override("font_size",20 if game.preferences.large_text else 17)
	if scene_kind=="lodge_board":
		title_label.text="把挡风板送进炉子？"
		var removed:bool=s.discovered.has("lodge_board_removed")
		body_label.text="炉旁的墙缝用两块干木板封着，钉头还缠着一截旧布。\n\n拆下它们能立刻得到两根木柴，但木屋会漏风：有火时回暖变慢，熄火后失温加快。\n\n也可以保留挡风板，趁还能走动去西北柴棚找燃料。修回木板需要两根柴和一份布料。\n\n随身木柴 %d · 布料 %d"%[s.wood,s.count("cloth")]
		if removed:body_label.text="墙缝正往里面送冷风。炉火能顶一阵，睡前还得看它能烧多久。\n\n修复消耗两根木柴、一份布料，恢复原有保暖能力。\n\n随身木柴 %d · 布料 %d"%[s.wood,s.count("cloth")]
		option("board_repair" if removed else "board_remove","修好挡风板 · 木柴 2 / 布料 1" if removed else "拆板取柴 · 获得 2 根柴，木屋更冷",func():change_board("repair" if removed else "remove"))
		choices.get_child(0).disabled=(s.wood<2 or s.count("cloth")<1) if removed else s.weight()+2*s.ITEMS.wood.weight>s.MAX_WEIGHT
		choices.get_child(0).tooltip_text="需要两根木柴和一份布料" if removed else "需要能装下两根木柴的负重空间"
		option("leave","暂时保留现状",game.close_story)
	elif scene_kind=="embers_note":
		title_label.text=Chapter.CLUES.embers_note.title
		body_label.text=Chapter.CLUES.embers_note.text
		if not s.discovered.has("embers_note"):s.discovered.append("embers_note")
		option("leave","收好内页 · 先照顾好自己",game.close_story)
	elif scene_kind=="departure":
		title_label.text=Chapter.CLUES.departure_trace.title;body_label.text=Chapter.CLUES.departure_trace.text
		option("leave","放回纸条 · 检查自己的补给",game.close_story)
		option("replay","再读一遍",func():scroll.scroll_vertical=0;game.experience.sound("memory_tape"))
	elif scene_kind=="tape_note":
		title_label.text=Chapter.CLUES.tape_home_note.title;body_label.text=Chapter.CLUES.tape_home_note.text
		Chapter.discover(s,"tape_home_note")
		option("leave","收好内页",game.close_story)
		option("replay","再看一遍",func():scroll.scroll_vertical=0;game.experience.sound("tape_button"))
	elif scene_kind=="intro":
		title_label.text="没能发出的平安报"
		body_label.text=Chapter.CLUES.home_log.text
		option("leave","收好记录 · 准备出发",game.close_story)
		option("replay_opening","回看开场",func():game.close_story();game.opening.begin())
	elif scene_kind=="station":
		title_label.text="留给后来的人"
		body_label.text=Chapter.CLUES.station_dispatch.text
		route_status.text=return_conditions()
		option("direct","沿铁路返家 · 迎风，西侧有狼活动",func():select_route("direct"))
		option("sheltered","沿林道返家 · 东侧绕行，树后避风",func():select_route("sheltered"))
		option("ridge","绕访西岭 · 可选收信簿，高地迎风",func():select_route("ridge"))
	elif scene_kind=="epilogue":
		match int(s.chapter.epilogue_step):
			0:
				title_label.text="还有一个声音"
				body_label.text="你以为谷口还有话没说完。\n\n但指针停在刻度边缘。那里贴着一张褪色线路卡：‘三号气象线路 · 停用。’\n\n灰尘下面，还能辨认出‘北坡中继’的字样。"
				option("listen","试着听清",func():listen("listen"))
				option("later","稍后再听",game.close_story)
			1:
				title_label.text="没有回应的呼号"
				body_label.text=Chapter.CLUES.old_channel_fragment.text
				option("check_card","核对线路卡",func():listen("check_card"))
			2:
				title_label.text="三号线路"
				body_label.text=Chapter.CLUES.old_channel_card.text
				option("record","记下线索 · 先准备补给",func():listen("record"))
			3:
				title_label.text="第一章 · 失联"
				body_label.text="谷口已经收到了你的平安报。周岑尚未出现在他们核对到的名单里。\n\n旧频道留下了警告、‘三号’和残缺呼号。线路卡指向北坡中继；说话者与警告的含义仍未确认。原句和通话已收进手记。\n\n先补齐木柴、饮水和食物。要去找人，得能从山里回来。\n\n第一章已完成。你可以继续探索林区、修缮小屋和准备补给。第二章的气象站区域尚未开放。"
				option("finish","回到小屋",game.close_story)
	else:
		match int(s.chapter.radio_step):
			1:
				title_label.text="发射灯亮了"
				body_label.text="备用模块接上后，指针终于越过红线。\n\n你调整到值守簿上留下的巡林频道。窗外的风还在吹，听筒里传来一段短促的电流声。\n\n这一次，可以把自己的位置说出去了。"
				option("call","按下通话键 · 报告位置",func():transmit("call"))
			2:
				title_label.text="谷口有人守听"
				body_label.text="你：谷口，这里是七号护林小屋。下山公路被风雪封住，目前只有我一个人。能听见吗？\n\n谷口值守：七号，听见了。我们还在。你那里炉子还能用吗？\n\n你：能用。先记下我的位置。北岭四回来过没有？\n\n谷口值守：周岑？到达名单里还没有他。我们会继续核对。你沿路看见其他人的消息了吗？"
				option("report","报告沿途发现",func():transmit("report"))
				option("ask","先询问下山的办法，再报告发现",func():transmit("ask"))
			3:
				title_label.text="你的位置被记下了"
				body_label.text=Chapter.radio_response(s)
				option("confirm","回复：收到。我会守住小屋。",func():transmit("confirm"))
			_:
				title_label.text="平安报已送达"
				body_label.text="谷口值守：下次傍晚，同一频道。七号，我们记着你。\n\n你松开通话键，等了一会儿。听筒里没有再催你赶路。\n\n谷口记下了你的位置。这一次，你可以先照顾好自己。"
				option("finish","收起听筒",game.close_story)
	if scene_kind=="radio" and s.chapter.radio_step>=2:
		option("replay","重读这段通话",func():scroll.scroll_vertical=0;game.experience.sound("radio_connect"))
	if choices.get_child_count()>0:choices.get_child(0).grab_focus()

func return_conditions()->String:
	var s=game.survival
	var lines:Array[String]=["现在 %s · 木柴 %d · 水 %d"%[game.DayCycle.clock_text(s.solar_time()),s.wood,s.count("water")],"按当前衣物/步行状态，从维修间返家估算："]
	for row in [["direct","铁路"],["sheltered","林道"],["ridge","西岭"]]:
		lines.append(Routes.line(row[1],Routes.forecast(s,row[0],game.world)))
	lines.append("不计搜寻，也不含动物袭击。铁路西侧有狼；林道仍需观察。")
	if s.temperature<40:lines.append("先添柴取暖；避风不能替代炉火。")
	elif s.count("water")==0 or s.thirst<35:lines.append("检查水壶：有炉火时可用一份柴融雪。")
	return "\n".join(lines)

func select_route(route:String)->void:
	if Chapter.choose_route(game.survival,route):game.close_story();game.notify("已记下返程打算 · "+Chapter.ROUTES[route])

func change_board(action:String)->void:
	var message:String=game.survival.lodge_board(action,game.world.shelter_at(game.player.position))
	game.world.arrival.sync(game.survival);game.notify(message);refresh()

func transmit(choice:String)->void:
	if Chapter.advance_radio(game.survival,choice):
		game.experience.radio_event(int(game.survival.chapter.radio_step));refresh()

func shutdown_audio()->void:
	if is_instance_valid(radio_sound):radio_sound.stop();radio_sound.stream=null

func _exit_tree()->void:shutdown_audio()

func listen(choice:String)->void:
	if Chapter.advance_epilogue(game.survival,choice):
		radio_sound.play();refresh()
