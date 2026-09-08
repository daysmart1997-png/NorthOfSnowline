extends PanelContainer
const Rules=preload("res://scripts/expedition.gd")
const Icon=preload("res://scripts/item_icon.gd")
const Slot=preload("res://scripts/inventory_slot.gd")
const GROUPS={"all":"全部","food":"食水","medical":"医疗","materials":"材料","gear":"装备","tapes":"磁带"}
var game
var content:HBoxContainer
var status:Label
var feedback:Label
var body:VBoxContainer
var category_bar:HBoxContainer
var selected:="player"
var tab:="items"
var category:="all"
var closing:=false
var roll_tween:Tween
var tab_buttons:Dictionary={}
var category_buttons:Dictionary={}
var weight_bar:ProgressBar
var open_sound:AudioStreamPlayer
signal roll_closed

func group_of(id:String)->String:
	if id in ["food","water","tea"]:return "food"
	if id in ["herb","bandage"]:return "medical"
	if id in ["wood","cloth","scrap"]:return "materials"
	return "tapes" if id.begins_with("tape_") else "gear"

func setup(main)->void:
	game=main
	position=Vector2(80,48);custom_minimum_size=Vector2(1120,624);pivot_offset=Vector2(560,312)
	var cloth:StyleBoxFlat=game.style(Color("303a3d"),Color("8e9389"));cloth.content_margin_left=28;cloth.content_margin_right=28;cloth.content_margin_top=27;cloth.content_margin_bottom=20
	add_theme_stylebox_override("panel",cloth)
	body=VBoxContainer.new();body.add_theme_constant_override("separation",10);add_child(body)
	var header:=HBoxContainer.new();body.add_child(header)
	var title:Label=game.label("行 囊    /    林区野外装备",25,Color("e4ddc9"));title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(title)
	game.button("收起行囊  [ B ]",func():game.toggle_backpack(),header)
	status=game.label("",14,Color("bac4c4"));body.add_child(status)
	weight_bar=ProgressBar.new();weight_bar.custom_minimum_size.y=4;weight_bar.show_percentage=false;weight_bar.max_value=24
	var bar_bg:=StyleBoxFlat.new();bar_bg.bg_color=Color("222b2f");var bar_fill:=StyleBoxFlat.new();bar_fill.bg_color=Color("b4a176")
	weight_bar.add_theme_stylebox_override("background",bar_bg)
	weight_bar.add_theme_stylebox_override("fill",bar_fill);body.add_child(weight_bar)
	var tabs:=HBoxContainer.new();body.add_child(tabs)
	for pair in [["items","随身物品"],["craft","制作与庇护所"],["journal","探索手记"]]:
		var id:String=pair[0]
		tab_buttons[id]=game.button(pair[1],func():tab=id;feedback.text="";refresh(),tabs)
	category_bar=HBoxContainer.new();category_bar.add_theme_constant_override("separation",6);body.add_child(category_bar)
	for id in GROUPS:
		var key:String=id
		category_buttons[id]=game.button(GROUPS[id],func():category=key;refresh(),category_bar)
		category_buttons[id].custom_minimum_size=Vector2(104,34)
		category_buttons[id].add_theme_font_size_override("font_size",14)
	content=HBoxContainer.new();content.add_theme_constant_override("separation",22);content.custom_minimum_size=Vector2(1050,325);content.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(content)
	feedback=game.label("点击查看；将磁带或电池拖到右侧磁带机。",14,Color("dec89b"));feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;feedback.custom_minimum_size.y=27;body.add_child(feedback)
	open_sound=AudioStreamPlayer.new();open_sound.volume_db=-20;add_child(open_sound)
	visible=false

func _draw()->void:
	# Seams, narrow leather bindings and canvas grain remain subtle behind readable labels.
	for y in [11.0,size.y-11]:
		draw_style_box(binding(),Rect2(8,y-4,size.x-16,8))
		for x in range(24,int(size.x)-24,12):draw_line(Vector2(x,y+7),Vector2(x+5,y+7),Color(.70,.65,.48,.5),1,true)
	for x in [12.0,size.x-12]:draw_line(Vector2(x,24),Vector2(x,size.y-24),Color("838879"),2,true)
	for i in range(65):
		var y:=22+i*8.7
		if y<size.y-18:draw_line(Vector2(18,y),Vector2(size.x-18,y),Color(1,1,1,.018),1)

func binding()->StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=Color("242a2c");s.corner_radius_top_left=5;s.corner_radius_top_right=5;s.corner_radius_bottom_left=5;s.corner_radius_bottom_right=5;return s

func open_roll()->void:
	if roll_tween and roll_tween.is_valid():roll_tween.kill()
	closing=false;visible=true;refresh();pivot_offset=size/2
	scale=Vector2(1,.045);body.modulate.a=0;mouse_filter=Control.MOUSE_FILTER_STOP
	roll_tween=create_tween();roll_tween.set_parallel(true)
	roll_tween.tween_property(self,"scale",Vector2.ONE,.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	roll_tween.tween_property(body,"modulate:a",1.0,.17).set_delay(.15)
	play_rustle(1.0)

func close_roll()->void:
	if roll_tween and roll_tween.is_valid():roll_tween.kill()
	closing=true;roll_tween=create_tween()
	roll_tween.tween_property(body,"modulate:a",0.0,.10)
	roll_tween.tween_property(self,"scale",Vector2(1,.035),.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	roll_tween.tween_callback(func():visible=false;closing=false;scale=Vector2.ONE;roll_closed.emit())
	play_rustle(.88)

func play_rustle(pitch:float)->void:
	if ResourceLoader.exists("res://assets/audio/bag_unroll.wav"):
		open_sound.stream=load("res://assets/audio/bag_unroll.wav");open_sound.pitch_scale=pitch;open_sound.play()

func refresh()->void:
	for child in content.get_children():content.remove_child(child);child.queue_free()
	var s=game.survival
	status.text="负重 %.1f / 24 kg    ·    饱食 %d    水分 %d    精力 %d                           整理行囊时暂停生存"%[s.weight(),s.hunger,s.thirst,s.energy]
	weight_bar.value=s.weight();category_bar.visible=tab=="items"
	for id in tab_buttons:
		tab_buttons[id].add_theme_stylebox_override("normal",game.style(Color("625b4b") if tab==id else Color("273337"),Color("78827d")))
	for id in category_buttons:
		var count:=0
		for item in Rules.ITEMS:
			if s.count(item)>0 and (id=="all" or group_of(item)==id):count+=1
		category_buttons[id].text="%s  %d"%[GROUPS[id],count]
		category_buttons[id].add_theme_stylebox_override("normal",game.style(Color("71614b") if category==id else Color("303c40"),Color("77817c")))
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(592,318);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;content.add_child(scroll)
	var left:=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.add_theme_constant_override("separation",8);scroll.add_child(left)
	var right:=VBoxContainer.new();right.custom_minimum_size.x=420;right.add_theme_constant_override("separation",10);content.add_child(right)
	if tab=="items":
		var available:Array[String]=[]
		for id in Rules.ITEMS:
			if (s.count(id)>0 or int(s.storage.get(id,0))>0) and (category=="all" or group_of(id)==category):available.append(id)
		if not available.has(selected) and not available.is_empty():selected=available[0]
		var grid:=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",9);grid.add_theme_constant_override("v_separation",9);left.add_child(grid)
		for id in available:
			var slot=Slot.new();slot.name="Slot_"+id;slot.item_id=id;slot.quantity=s.count(id);slot.custom_minimum_size=Vector2(184,111)
			slot.text="\n\n%s   ×%d"%[Rules.ITEMS[id].name,s.count(id)];slot.tooltip_text=Rules.ITEMS[id].description
			slot.add_theme_font_size_override("font_size",14)
			for state in ["normal","hover","pressed","focus"]:
				slot.add_theme_stylebox_override(state,game.style(Color("605b4c") if selected==id or state!="normal" else Color("3b4749"),Color("b4a17a") if selected==id else Color("667775")))
			var icon=Icon.new();icon.item_id=id;icon.position=Vector2(57,6);icon.size=Vector2(70,58);icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;slot.add_child(icon)
			var item:String=id
			slot.pressed.connect(func():selected=item;refresh());slot.apply_item.connect(func(dragged:String):do_action("use",dragged));grid.add_child(slot)
		if available.is_empty():left.add_child(game.label("这个口袋还空着。\n继续探索，收集需要的物资。",18,Color("c1c8c3")))
		if not available.is_empty():item_details(right,s)
		cassette_dock(right,s)
	elif tab=="craft":
		for id in Rules.RECIPES:
			var recipe:String=id;var cost:Array[String]=[]
			for item in Rules.RECIPES[id].cost:cost.append("%s %d/%d"%[Rules.ITEMS[item].name,s.count(item),Rules.RECIPES[id].cost[item]])
			var button=game.button(Rules.RECIPES[id].name+"\n"+" · ".join(cost),func():do_action("craft",recipe),left);button.add_theme_font_size_override("font_size",14)
		right.add_child(game.label("把这里变成一个家",24,Color("e0cfac")))
		var description:Label=game.label("封窗保温，让冷风留在屋外。\n修好床铺，为下一次出发养足精神。\n制作储物箱，将备用物资留在家里。\n搭建临时营地，获得遮蔽与营火。\n\n煮水、泡茶需要庇护所内燃烧的火源。",16);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;right.add_child(description)
		for id in s.upgrades:right.add_child(game.label(("✓ " if s.upgrades[id] else "○ ")+Rules.RECIPES[id].name,14))
		game.button("休息两分钟",func():do_action("rest",""),right)
	else:
		for poi in game.world.pois:
			if not s.discovered.has(poi.id):continue
			left.add_child(game.label(poi.title,20,Color("dcc599")))
			var entry:Label=game.label(poi.story,15);entry.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;left.add_child(entry)
		if s.discovered.is_empty():left.add_child(game.label("走出小屋，寻找林区留下的痕迹。",17))
		right.add_child(game.label("已发现 %d / %d 个地点"%[s.discovered.size(),game.world.pois.size()],20))
		var hint:Label=game.label("铁轨通往车站，东侧林道可避风。\n西边废弃车辆里也许有意外收获。\n\n找到新的磁带后，在背包里装入试听。",16);hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;right.add_child(hint)
	queue_redraw()

func item_details(right:VBoxContainer,s)->void:
	right.add_child(game.label(Rules.ITEMS[selected].name,22,Color("ead9b4")))
	var desc:Label=game.label(Rules.ITEMS[selected].description,15);desc.custom_minimum_size.x=414;desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;right.add_child(desc)
	right.add_child(game.label("%s  ·  随身 %d / 储存 %d  ·  %.2f kg/份"%[GROUPS[group_of(selected)],s.count(selected),int(s.storage.get(selected,0)),Rules.ITEMS[selected].weight],13,Color("c4c9b6")))
	var usable:=selected in ["food","water","tea","bandage","battery","player"] or selected.begins_with("tape_")
	if usable:
		var use_button=game.button("装入磁带机" if selected.begins_with("tape_") else ("播放 / 停止" if selected=="player" else "使用一份"),func():do_action("use",selected),right);use_button.disabled=s.count(selected)<=0
	elif selected!="parts":game.button("查看制作配方",func():tab="craft";refresh(),right)
	if selected not in ["player","parts"] and not selected.begins_with("tape_"):
		var row:=HBoxContainer.new();right.add_child(row)
		var home_storage:bool=s.upgrades.storage and game.world.shelter_at(game.player.position)=="home"
		var deposit=game.button("存入",func():do_action("deposit",selected),row);deposit.disabled=not home_storage or s.count(selected)==0;deposit.tooltip_text="需要在小屋制作储物箱"
		var withdraw=game.button("取出",func():do_action("withdraw",selected),row);withdraw.disabled=not home_storage or int(s.storage.get(selected,0))==0
		var discard=game.button("丢弃一份",func():do_action("discard",selected),row);discard.disabled=s.count(selected)==0

func cassette_dock(right:VBoxContainer,s)->void:
	if s.count("player")<=0:return
	var dock=Slot.new();dock.name="MagneticDock";dock.item_id="player";dock.quantity=1;dock.custom_minimum_size=Vector2(410,64)
	dock.text="◉  奇异磁带机    %d%%\n将磁带 / 电池拖到这里"%s.battery_charge;dock.add_theme_font_size_override("font_size",14)
	dock.add_theme_stylebox_override("normal",game.style(Color("222d30"),Color("ba9e69")));dock.apply_item.connect(func(id:String):do_action("use",id));dock.pressed.connect(func():do_action("music",""));right.add_child(dock)
	var tape_name:String=Rules.ITEMS[s.loaded_tape].name if Rules.ITEMS.has(s.loaded_tape) else "未装磁带"
	right.add_child(game.label(("▶ " if s.music_playing else "■ ")+tape_name+"  ·  "+("试听中" if s.music_playing else "已停止"),14,Color("d9bd84")))

func do_action(kind:String,id:String)->void:
	feedback.text=game.backpack_action(kind,id);refresh()

func shutdown_ui()->void:
	if roll_tween and roll_tween.is_valid():roll_tween.kill()
	if is_instance_valid(open_sound):open_sound.stop();open_sound.stream=null

func _exit_tree()->void:shutdown_ui()
