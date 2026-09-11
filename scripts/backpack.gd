extends PanelContainer
const Palette=preload("res://scripts/field_theme.gd")
const Rules=preload("res://scripts/expedition.gd")
const Icon=preload("res://scripts/item_icon.gd")
const Slot=preload("res://scripts/inventory_slot.gd")
const GROUPS={"all":"全部","food":"食水","medical":"医疗","materials":"材料","gear":"装备","tapes":"磁带"}
const TAB_HINTS={"character":"点击部位查看衣着与身体；操作前显示需要的物资与炉火。","items":"点击物品查看；将磁带或电池拖到右侧磁带机。","craft":"选择配方制作；数字表示现有材料 / 所需材料。","search":"按需取走，剩余物资保留原处；查看时暂停。","journal":"探索记录保存在手记中；返回探索后按 Tab 查看路线。"}
var character_part:="feet"
var character_angle:=PI-.3
var body_view:=false
var game
var content:HBoxContainer
var status:Label
var feedback:Label
var body:VBoxContainer
var category_bar:HBoxContainer
var source_id:=""
var preview_action:=""
var selected:="player"
var tab:="items"
var category:="all"
var journal_focus:=""
var rest_hours:=2
var closing:=false
var roll_tween:Tween
var tab_buttons:Dictionary={}
var category_buttons:Dictionary={}
var weight_bar:ProgressBar
var open_sound:AudioStreamPlayer
signal roll_closed

func group_of(id:String)->String:
	if id in ["food","water","tea","raw_meat","cooked_meat"]:return "food"
	if id in ["herb","bandage","splint","medicine"]:return "medical"
	if id in ["wood","cloth","scrap","hide","leather"]:return "materials"
	return "tapes" if id.begins_with("tape_") else "gear"

func setup(main)->void:
	game=main
	position=Vector2(64,40);custom_minimum_size=Vector2(1152,640);pivot_offset=Vector2(576,320)
	var cloth:StyleBoxTexture=Palette.cloth();cloth.content_margin_left=24;cloth.content_margin_right=24;cloth.content_margin_top=24;cloth.content_margin_bottom=24
	add_theme_stylebox_override("panel",cloth)
	body=VBoxContainer.new();body.add_theme_constant_override("separation",10);add_child(body)
	var header:=HBoxContainer.new();body.add_child(header)
	var title:Label=game.label("行装 · 雪线以北",28,Palette.INK);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(title)
	game.button("返回探索  [ B / Esc ]",func():game.toggle_backpack(),header)
	status=game.label("",14,Palette.MUTED);body.add_child(status)
	weight_bar=ProgressBar.new();weight_bar.custom_minimum_size.y=4;weight_bar.show_percentage=false;weight_bar.max_value=24
	var bar_bg:=StyleBoxFlat.new();bar_bg.bg_color=Color("222b2f");var bar_fill:=StyleBoxFlat.new();bar_fill.bg_color=Palette.ACCENT
	weight_bar.add_theme_stylebox_override("background",bar_bg)
	weight_bar.add_theme_stylebox_override("fill",bar_fill);body.add_child(weight_bar)
	var tabs:=HBoxContainer.new();body.add_child(tabs)
	for pair in [["character","人物"],["items","随身物品"],["craft","制作与庇护所"],["journal","探索手记"]]:
		var id:String=pair[0]
		tab_buttons[id]=game.button(pair[1],func():tab=id;feedback.text="";refresh(),tabs)
	category_bar=HBoxContainer.new();category_bar.add_theme_constant_override("separation",6);body.add_child(category_bar)
	for id in GROUPS:
		var key:String=id
		category_buttons[id]=game.button(GROUPS[id],func():category=key;refresh(),category_bar)
		category_buttons[id].custom_minimum_size=Vector2(104,34)
		category_buttons[id].add_theme_font_size_override("font_size",14)
	content=HBoxContainer.new();content.add_theme_constant_override("separation",22);content.custom_minimum_size=Vector2(1050,325);content.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(content)
	feedback=game.label("",14,Palette.ACCENT);feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;feedback.custom_minimum_size.y=27;body.add_child(feedback)
	open_sound=AudioStreamPlayer.new();open_sound.volume_db=-20;open_sound.bus="SnowEffects";add_child(open_sound)
	visible=false

func open_roll()->void:
	if roll_tween and roll_tween.is_valid():roll_tween.kill()
	closing=false;visible=true;refresh();pivot_offset=size/2
	scale=Vector2.ONE;modulate.a=.0;body.modulate.a=1;mouse_filter=Control.MOUSE_FILTER_STOP
	roll_tween=create_tween();roll_tween.set_parallel(true)
	roll_tween.tween_property(self,"modulate:a",1.0,.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	play_rustle(1.0)

func close_roll()->void:
	if roll_tween and roll_tween.is_valid():roll_tween.kill()
	closing=true;roll_tween=create_tween()
	roll_tween.tween_property(self,"modulate:a",0.0,.14)
	roll_tween.tween_callback(func():visible=false;closing=false;scale=Vector2.ONE;roll_closed.emit())
	play_rustle(.88)

func play_rustle(pitch:float)->void:
	if ResourceLoader.exists("res://assets/audio/bag_unroll.wav"):
		open_sound.stream=load("res://assets/audio/bag_unroll.wav");open_sound.pitch_scale=pitch;open_sound.play()

func refresh()->void:
	for child in content.get_children():content.remove_child(child);child.queue_free()
	if feedback.text.is_empty() or feedback.text in TAB_HINTS.values():feedback.text=TAB_HINTS[tab]
	var s=game.survival
	status.text="健康 %d    体温 %d    体力 %d    ·    负重 %.1f / 24 kg    ·    饱食 %d    水分 %d    精力 %d    ·    第 %d 天 %s / 已暂停"%[s.health,s.temperature,s.stamina,s.weight(),s.hunger,s.thirst,s.energy,Rules.DayCycle.day(s.elapsed),Rules.DayCycle.clock_text(s.elapsed)]
	status.text+="\n%s · 室外 %d°C · %s"%[Rules.DayCycle.phase(s.elapsed),roundi(s.outdoor_temperature()),game.world.terrain_name(game.player.position)]
	if tab=="character":status.text="第 %d 天 %s · 室外 %d°C · 查看时已暂停"%[Rules.DayCycle.day(s.elapsed),Rules.DayCycle.clock_text(s.elapsed),roundi(s.outdoor_temperature())]
	weight_bar.visible=tab!="character"
	weight_bar.value=s.weight();category_bar.visible=tab=="items"
	for id in tab_buttons:
		tab_buttons[id].add_theme_stylebox_override("normal",game.style(Palette.RAISED if tab==id else Color.TRANSPARENT,Palette.ACCENT if tab==id else Color.TRANSPARENT))
	for id in category_buttons:
		var count:=0
		for item in Rules.ITEMS:
			if s.count(item)>0 and (id=="all" or group_of(item)==id):count+=1
		category_buttons[id].text="%s  %d"%[GROUPS[id],count]
		category_buttons[id].add_theme_stylebox_override("normal",game.style(Palette.RAISED if category==id else Color.TRANSPARENT,Palette.LINE if category==id else Color.TRANSPARENT))
	if tab=="character":
		var sheet=preload("res://scripts/character_sheet.gd").new();content.add_child(sheet);sheet.setup(game,self);return
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(592,318);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;content.add_child(scroll)
	var left:=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.add_theme_constant_override("separation",8);scroll.add_child(left)
	var right_scroll:=ScrollContainer.new();right_scroll.custom_minimum_size.x=430;right_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;right_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;content.add_child(right_scroll)
	var right:=VBoxContainer.new();right.custom_minimum_size.x=414;right.add_theme_constant_override("separation",10);right_scroll.add_child(right)
	if tab=="search":
		search_contents(left,right,s);return
	if tab=="items":
		var available:Array[String]=[]
		for id in Rules.ITEMS:
			if (s.count(id)>0 or int(s.storage.get(id,0))>0) and (category=="all" or group_of(id)==category):available.append(id)
		if preview_action=="use" and selected in Rules.Arrival.ITEMS and not available.has(selected):available.append(selected)
		if not available.has(selected) and not available.is_empty():selected=available[0]
		var grid:=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",9);grid.add_theme_constant_override("v_separation",9);left.add_child(grid)
		for id in available:
			var slot=Slot.new();slot.name="Slot_"+id;slot.item_id=id;slot.quantity=s.count(id);slot.custom_minimum_size=Vector2(184,111)
			slot.text="\n\n%s   ×%d"%[Rules.ITEMS[id].name,s.count(id)];slot.tooltip_text=Rules.ITEMS[id].description
			Palette.button_theme(slot)
			slot.add_theme_font_size_override("font_size",14)
			for state in ["normal","hover","pressed","focus"]:
				slot.add_theme_stylebox_override(state,game.style(Palette.RAISED if selected==id or state!="normal" else Color(1,1,1,.025),Palette.ACCENT if selected==id or state=="focus" else Color.TRANSPARENT))
			var icon=Icon.new();icon.item_id=id;icon.position=Vector2(57,6);icon.size=Vector2(70,58);icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;slot.add_child(icon)
			var item:String=id
			slot.pressed.connect(func():selected=item;refresh());slot.apply_item.connect(func(dragged:String):do_action("use",dragged));grid.add_child(slot)
		if available.is_empty():left.add_child(game.label("这个口袋还空着。\n继续探索，收集需要的物资。",18,Palette.MUTED))
		if not available.is_empty():item_details(right,s)
		cassette_dock(right,s)
	elif tab=="craft":
		var shelter:String=game.world.shelter_at(game.player.position)
		for id in Rules.RECIPES:
			var recipe:String=id;var cost:Array[String]=[]
			for item in Rules.RECIPES[id].cost:cost.append("%s %d/%d"%[Rules.ITEMS[item].name,s.count(item),Rules.RECIPES[id].cost[item]])
			var valid:bool=not game.world.candidate_camp(game.player.position).is_empty() if id=="camp" else false
			var problem:String=s.recipe_problem(id,shelter,valid)
			var button=game.button(Rules.RECIPES[id].name+"\n"+" · ".join(cost)+("\n"+problem if not problem.is_empty() else ""),func():do_action("craft",recipe),left)
			button.name="Recipe_"+id;button.disabled=not problem.is_empty();button.tooltip_text=problem;button.add_theme_font_size_override("font_size",14)
		right.add_child(game.label("临时休整" if shelter in ["gatehouse","lodge"] else "把这里变成一个家",24,Palette.INK))
		var description:Label=game.label(Rules.Arrival.SITES[shelter].description if Rules.Arrival.SITES.has(shelter) else "封窗减缓失温，炉火才能回暖。\n修好床铺，为下一次出发养足精神。",15);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;right.add_child(description)
		build_rest_controls(right,s)
	else:
		var entries:Array=game.world.pois.filter(func(p):return not game.Chapter.CLUES.has(p.id))
		for id in game.Chapter.CLUES:
			var clue:Dictionary=game.Chapter.CLUES[id]
			entries.append({"id":id,"title":clue.title,"story":clue.text})
		entries.sort_custom(func(a,b):return a.id==journal_focus and b.id!=journal_focus)
		for poi in entries:
			if not s.discovered.has(poi.id):continue
			left.add_child(game.label(poi.title,20,Palette.INK))
			var entry:Label=game.label(poi.story,15);entry.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;left.add_child(entry)
		if s.discovered.is_empty():left.add_child(game.label("桌上的无线电，仍没能发出你的平安报。",17))
		right.add_child(game.label("第一章 · 失联",22))
		var summary_scroll:=ScrollContainer.new();summary_scroll.custom_minimum_size=Vector2(420,230);summary_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;summary_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;right.add_child(summary_scroll)
		var hint:Label=game.label(game.Chapter.journal_summary(s),15);hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL;hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;summary_scroll.add_child(hint)
		if s.parts and not s.completed:game.button("查看交接单 · 调整返程打算",func():game.open_story("station"),right)
		if s.chapter.intro_seen or s.completed:game.button("重读值守簿 · 回看开场",func():game.open_story("intro"),right)
		right.add_child(game.label("已记下 %d 处发现"%s.discovered.size(),14,Palette.MUTED))
	queue_redraw()

func build_rest_controls(right:VBoxContainer,s)->void:
	right.add_child(game.label("休息前",18,Palette.INK))
	var row:=HBoxContainer.new();right.add_child(row)
	for hours in [1,2,4]:
		var duration:int=hours
		var choice=game.button("%d 小时"%hours,func():rest_hours=duration;refresh(),row)
		choice.custom_minimum_size=Vector2(112,34)
		choice.add_theme_stylebox_override("normal",game.style(Palette.RAISED if hours==rest_hours else Color.TRANSPARENT,Palette.ACCENT if hours==rest_hours else Palette.LINE))
	var preview:Dictionary=s.rest_preview(game.world.shelter_at(game.player.position),rest_hours)
	var text:String=preview.problem
	if text.is_empty():
		text="醒来约 %s  ·  精力 +%d\n饱食 −%.1f  /  水分 −%.1f\n预计体温 %d  ·  炉火余 %d 分钟"%[preview.clock,roundi(preview.energy_gain),preview.hunger_cost,preview.thirst_cost,roundi(preview.temperature),floori(preview.fire_minutes)]
		if not preview.reason.is_empty():text+="\n"+preview.reason+"，可能提前醒来。"
		elif preview.fire_short:text+="\n炉火撑不到醒来；封窗只能减缓失温。"
	var forecast:Label=game.label(text,14,Palette.ACCENT if preview.get("fire_short",false) else Palette.MUTED)
	forecast.name="RestForecast";forecast.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;right.add_child(forecast)
	var rest_button=game.button("休息 %d 小时"%rest_hours,func():do_action("rest",str(rest_hours)),right)
	rest_button.disabled=not preview.problem.is_empty()

func item_details(right:VBoxContainer,s)->void:
	right.add_child(game.label(Rules.ITEMS[selected].name,22,Palette.INK))
	if selected in Rules.Arrival.ITEMS:add_preview(right,selected)
	var desc:Label=game.label(Rules.ITEMS[selected].description,15);desc.custom_minimum_size.x=414;desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;right.add_child(desc)
	right.add_child(game.label("%s  ·  随身 %d / 储存 %d  ·  %.2f kg/份"%[GROUPS[group_of(selected)],s.count(selected),int(s.storage.get(selected,0)),Rules.ITEMS[selected].weight],13,Palette.MUTED))
	var usable:=selected in ["food","water","tea","bandage","battery","player","medicine","splint","cooked_meat","raw_meat","knife","bow","rifle"] or Rules.Kit.GEAR.has(selected) or selected.begins_with("tape_")
	if selected=="tape_home" and s.count("tape_home")>0:
		game.button("展开周岑留下的内页",func():game.open_story("tape_note"),right).name="TapeNote"
	if usable:
		var use_button=game.button("装入磁带机" if selected.begins_with("tape_") else ("播放 / 停止" if selected=="player" else ("应急生食 · 会引起食物不适" if selected=="raw_meat" else "使用一份")),func():do_action("use",selected),right);use_button.disabled=s.count(selected)<=0
	elif selected!="parts":game.button("查看制作配方",func():tab="craft";refresh(),right)
	if selected not in ["player","parts"] and not selected.begins_with("tape_"):
		var row:=HBoxContainer.new();right.add_child(row)
		var home_storage:bool=s.upgrades.storage and game.world.shelter_at(game.player.position)=="home"
		var deposit=game.button("存入",func():do_action("deposit",selected),row);deposit.disabled=not home_storage or s.count(selected)==0;deposit.tooltip_text="需要在小屋制作储物箱"
		var withdraw=game.button("取出",func():do_action("withdraw",selected),row);withdraw.disabled=not home_storage or int(s.storage.get(selected,0))==0
		var discard=game.button("放下一份" if selected in Rules.Arrival.ITEMS else "丢弃一份",func():do_action("discard",selected),row);discard.disabled=s.count(selected)==0

func cassette_dock(right:VBoxContainer,s)->void:
	if s.count("player")<=0:return
	var dock=Slot.new();dock.name="MagneticDock";dock.item_id="player";dock.quantity=1;dock.custom_minimum_size=Vector2(410,64)
	Palette.button_theme(dock)
	dock.text="奇异磁带机    %d%%\n将磁带 / 电池拖到这里"%s.battery_charge;dock.add_theme_font_size_override("font_size",14)
	dock.add_theme_stylebox_override("normal",game.style(Palette.RAISED,Palette.ACCENT));dock.apply_item.connect(func(id:String):do_action("use",id));dock.pressed.connect(func():do_action("music",""));right.add_child(dock)
	var tape_name:String=Rules.ITEMS[s.loaded_tape].name if Rules.ITEMS.has(s.loaded_tape) else "未装磁带"
	right.add_child(game.label(("▶ " if s.music_playing else "■ ")+tape_name+"  ·  "+("试听中" if s.music_playing else "已停止"),14,Palette.ACCENT))

func do_action(kind:String,id:String)->void:
	feedback.text=game.backpack_action(kind,id)
	var show_use:bool=kind=="use" and preview_action=="use"
	refresh()
	if show_use:
		var finish=create_tween();finish.tween_interval(1.1);finish.tween_callback(func():
			if visible and tab=="items" and selected==id:refresh())

func shutdown_ui()->void:
	if roll_tween and roll_tween.is_valid():roll_tween.kill()
	if is_instance_valid(open_sound):open_sound.stop();open_sound.stream=null

func _exit_tree()->void:shutdown_ui()

func _draw()->void:
	var seam:=Color(.62,.63,.57,.45)
	for x in range(12,int(size.x)-12,12):
		draw_line(Vector2(x,10),Vector2(x+5,10),seam,1)
		draw_line(Vector2(x,size.y-10),Vector2(x+5,size.y-10),seam,1)
	for y in range(16,int(size.y)-12,12):
		draw_line(Vector2(10,y),Vector2(10,y+5),seam,1)
		draw_line(Vector2(size.x-10,y),Vector2(size.x-10,y+5),seam,1)

func add_preview(parent:Control,item:String)->void:
	var preview=preload("res://scripts/item_preview.gd").new();preview.item_id=item;preview.action=preview_action;preview_action="";parent.add_child(preview)

func search_contents(left:VBoxContainer,right:VBoxContainer,s)->void:
	if not Rules.Arrival.SUPPLIES.has(source_id):left.add_child(game.label("这里没有待查看的物资。",18));return
	var spec:Dictionary=Rules.Arrival.SUPPLIES[source_id]
	left.add_child(game.label(spec.title,23,Palette.INK))
	left.add_child(game.label("只拿需要的，剩余物资会留在原处。",15,Palette.MUTED))
	if not spec.contents.has(selected):selected=spec.contents.keys()[0]
	for item in spec.contents:
		var remaining:int=int(spec.contents[item])-int(s.supply_taken.get(source_id,{}).get(item,0))
		var choose=game.button("%s  ×%d"%[Rules.ITEMS[item].name,remaining],func():selected=item;refresh(),left);choose.name="Inspect_"+item
	right.add_child(game.label(Rules.ITEMS[selected].name,23,Palette.INK));add_preview(right,selected)
	var desc=game.label(Rules.ITEMS[selected].description,15);desc.custom_minimum_size.x=400;desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;right.add_child(desc)
	var remaining:int=int(spec.contents[selected])-int(s.supply_taken.get(source_id,{}).get(selected,0))
	var take=game.button("取走一份 · %.2f kg"%Rules.ITEMS[selected].weight,func():do_action("take_supply",selected),right);take.name="TakeSupply";take.disabled=remaining<=0 or s.weight()+Rules.ITEMS[selected].weight>s.MAX_WEIGHT
	right.add_child(game.label("已取完，可以留下空包。" if remaining<=0 else ("背包余量不足；可先使用或放下随身物资。" if take.disabled else "剩余 %d 份 · 随身 %d 份"%[remaining,s.count(selected)]),14,Palette.MUTED))
