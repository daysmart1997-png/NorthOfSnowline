extends RefCounted
# Chapter facts and transitions. Survival owns this state; UI only presents it.
const CLUES := {
 "embers_note":{"title":"《余烬》盒盖里的字","text":"‘你总是一进屋就先找收音机。先把手暖回来。’\n\n‘桌边留了三根干柴，电池在旁边。别全塞进炉子，夜还长。伙房在东边，柴棚在西北。’\n\n落款是周岑。纸角被烟熏黄，字迹却是你熟悉的那种急。\n\n这盘歌你们以前听过。现在他不在炉边，但他留下的东西还在帮你。"},
 "morning_tracks":{"title":"木屋外，朝北的鞋印","text":"木屋东侧还有一小段鞋印，鞋底比你的窄。边缘已经被风磨平，看不出是什么时候留下的。\n\n它们朝北，消失在被吹硬的雪面上。\n\n周岑的纸条也指向北边。但你还不能确认留下鞋印的是谁，先准备好能回来的补给。"},
 "canteen_note":{"title":"伙房的领用单","text":"名单最后一行停在雪封山前。锅和炉门已经运走，架上的干粮却有人用油纸重新包过。\n\n“还留两份。拿走了就在单子上划掉，别让后来的人白跑。”\n\n从这里往西是炭工木屋，西北柴棚里有干柴。天黑后只走这一小段，别顺着旧公路继续赶夜路。"},
 "bunk_note":{"title":"没有签完的换班记录","text":"床垫已经湿透，靠窗的鞋里结着冰。这间屋子有床的形状，却不能让人暖和地睡上一夜。\n\n夹在衣物里的换班记录写着：“北岭四昨天经过，让我们把剩下的干柴移到油布下面。他还要往北。”\n\n没有离开的具体时刻，也没有后续消息。你只能确认周岑来过这个聚落。"},
 "gate_route":{"title":"值班桌上的路线纸","text":"值班人画了两处屋顶。沿公路向北，岔口往西，是有旧铁炉的炭工木屋；再往北，路回到低处，才是七号护林小屋。\n\n纸边写着：“岗亭漏风，没有卧铺。桌上的东西留给回不去的人。别把这里当成能熬整夜的地方。”"},
 "lodge_route":{"title":"炉边的巡林便笺","text":"“炉子还能用，干柴留在桌边。睡前看一眼火，别指望余烬一直撑到天亮。”\n\n聚落小图标着：东侧伙房剩干粮，西北柴棚留着干柴，东北宿舍的被褥已经湿透。卧铺上的旧磁带机，等手暖了再试。\n\n背面是向北的旧公路：七号护林小屋有工作台、储物空间和无线电。你认出了周岑的笔迹。先熬过这一晚，再去那里找他的消息。"},
 "departure_trace":{"title":"空挂钩与一只手套","text":"挂钩上只剩皮带的浅色印子，旁边挂着一只没来得及补好的旧手套。周岑出巡时常带的保温壶不在了。\n\n桌角那张出巡前的纸条被杯底压皱：“去看北坡信标。壶我带上了，柴留给你。天黑前回频道。”\n\n这只能说明他出发前做过准备，不能说明他现在还在北坡。你把纸条放回杯子下面，也摸了摸自己的水壶。"},
 "cabinet_note":{"title":"柜里的最后一份干柴","text":"零件柜下层用油布包着一份劈柴，上层剩一块干布。抽屉里都是拆下的旧螺帽，没有第二套发射模块。\n\n柜门内侧夹着字条：“木柴给后来的人。先把雪烧开，别空着水壶赶夜路。”\n\n这一份柴可以添火，也可以在已有炉火旁融雪。怎么用，要看你现在最缺什么。"},
 "wind_trace":{"title":"布条与风向","text":"布条朝林道一侧拖去，铁路边细雪贴着地面奔跑。走到东侧树后，衣袖上的风压明显轻了。\n\n铁路更直接；林道多绕一段，但沿途有树挡风。避风只能减缓失温，不能替代炉火。\n\n返回前，可以在维修交接单里比较当前衣物和补给下的步行估算。"},
 "return_wind":{"title":"返程时的布条","text":"回来时，岔路的布条已经被渐强的风拉直。树后仍能挡住一部分风，铁路上的细雪却一直扫过靴面。\n\n这是风雪随时间增强留下的变化，不是有人刚刚走过。绕路、取暖和补水，都需要重新算进返程。"},
	"zhou_gloves":{"title": "衣袋便笺 · 右手拇指", "text": "备用手套叠在衣袋里，右手拇指留着一排歪针脚。\n\n周岑写道：“上回你替我缝的，没拆。针脚丑，倒是一点风都不漏。备用这副给你，湿了就换，别又说走两步就干。”\n\n纸角画了个很小的炉子。你记得他添柴总把最干的一根留到最后。"},
	"tape_home_note":{"title": "《归途》内页 · 给你回程听", "text": "盒内夹着周岑的便笺，日期是这次出巡之前。\n\n“前半面是你嫌慢的那几首，回程慢慢听。右边耳机又接触不好，线别扯太紧。”\n\n“壶放炉边，别贴着铁皮。回来的时候要是我睡了，敲两下桌子。别拿凉手碰我脖子。”\n\n最后一行写得很轻：“傍晚见。”\n\n这张旧便笺不能说明他现在在哪里。"},

	"home_log": {"title":"值守簿 · 没能发出的平安报", "text":"你穿过山口，沿途补给，终于回到七号护林小屋。\n\n末页是你匆忙写下的记录：“北岭四前往北坡检查信标。周岑说，查完就回频道，傍晚见。”下面只补了四个字：“尚未回报。”\n\n你们搭档多年。他偶尔错过饭点，很少错过守听。\n\n收音指针还会动，发射灯却不亮。检修单写着：“备用发射模块存于北岭车站维修间。”\n\n先让谷口知道你还在这里，再问问他的消息。也许他已从另一条路下山，只是消息还没传回来。"},
	"fork_note": {"title":"褪色的巡林路线", "text":"路线纸上，东侧林道被铅笔重描了一遍：‘送药的人走林道，铁轨上顶风。布条一直挂到旧营地。’\n\n下面是另一种笔迹：‘收到。若先到站，把炉灰留着。——守桥人’\n\n这里曾有人等着另一个人经过。铁轨更直接，林道则能挡住一部分风。"},
	"hunter_note": {"title":"压在石下的纸页", "text":"‘药已交给守桥人。过桥前我们在这里烘干了手套，他还惦记着西岭那箱东西。’\n\n‘我把柴放在帐棚后。维修间的炉子还好用；别等天黑才往回赶。’\n\n落款只剩一个‘林’字。纸上的折痕与岔路那张路线纸相同：送药的人确实走到了这里。"},
	"sled_note": {"title":"断绳与雪橇", "text":"雪橇一侧的绳子断了，绳头拖向西岭。捆扎布下压着一页货单：‘药包随身带走。收信簿留在岭上帆布箱，等风停再取。’\n\n货单上签着‘林’。箱子里也许能找到撤离者的去向。坡上露出一截旧帆布；上岭迎风，先检查体温和水壶。"},
	"ridge_register": {"title":"收信簿 · 平安到达", "text":"帆布下面是一册用油纸包好的收信簿。最后一栏被反复描深：\n\n‘林、守桥人，均已到谷口。药送到了。北坡信标没亮，无法确认是否还有人滞留。请保留巡林频道。’\n\n他们不是无声无息地消失了。只要把这页内容带回去，谷口就能把那两个名字从失联名单上划掉。"},
	"station_dispatch": {"title":"维修交接 · 留给后来的人", "text":"备用模块下压着交接单。\n\n“线路中断，末班车取消。人员改走西侧便道撤往谷口。发射模块留下，供沿线小屋求援。炉门没锁，这里还能给没赶上撤离的人挡一夜风。”\n\n末尾补了一行：“送药的林和守桥人尚未回报。西岭转运箱内有收信簿。”\n\n你翻到名单最后，没有周岑的名字。但这是一张撤离前的交接单，不能说明他后来去了哪里。"},
	"old_channel_fragment": {"title":"旧频道 · 听到的残句", "text":"［断续电流声］\n不明声音：……不要去北边。\n［短暂停顿］\n不明声音：……三号……北岭四……\n\n你：北岭四？周岑，是你吗？\n\n只有噪声，没有回答。尚未确认：说话者、时间、警告的含义，以及是否与周岑有关。"},
	"old_channel_card": {"title":"线路卡 · 三号气象线路", "text":"无线电侧盖内的褪色线路卡：“三号气象站，北坡中继支线。”上面盖着停用章。\n\n周岑说过，那边的旧设备早就不再值守。你再次呼叫，没有回答。\n\n可查的线索是旧线路的去向；不能据此确认声音来自周岑。第二章的气象站区域尚未开放。"}
}
const ROUTES := {"direct":"沿铁路返家", "sheltered":"沿林道返家", "ridge":"绕访西岭"}

static func fresh()->Dictionary:
	return {"intro_seen":false,"station_seen":false,"weather_warned":false,"return_plan":"","radio_step":0,"reply":"","report_detail":"","epilogue_step":0}

static func valid(raw:Variant)->bool:
	if not raw is Dictionary:return false
	for key in ["intro_seen","station_seen","weather_warned"]:
		if not raw.get(key) is bool:return false
	if not raw.get("return_plan") is String or raw.return_plan not in ["","direct","sheltered","ridge"]:return false
	if not (raw.get("radio_step") is int or raw.get("radio_step") is float):return false
	if not is_finite(float(raw.radio_step)) or float(raw.radio_step)!=floorf(float(raw.radio_step)) or raw.radio_step<0 or raw.radio_step>4:return false
	if raw.get("reply") not in ["","report","ask"] or raw.get("report_detail") not in ["","unknown","camp","register"]:return false
	if raw.radio_step>=3 and (raw.reply=="" or raw.report_detail==""):return false
	if raw.radio_step<3 and (raw.reply!="" or raw.report_detail!=""):return false
	var ep:Variant=raw.get("epilogue_step",0)
	if not (ep is int or ep is float):return false
	if not is_finite(float(ep)) or float(ep)!=floorf(float(ep)) or ep<0 or ep>3:return false
	if ep>0 and raw.radio_step!=4:return false
	return true

static func advance_epilogue(s,choice:String)->bool:
	if not s.completed or s.health<=0:return false
	var step:int=s.chapter.epilogue_step
	if step>=3 or choice!=["listen","check_card","record"][step]:return false
	s.chapter.epilogue_step=step+1
	if step==0:discover(s,"old_channel_fragment")
	if step==1:discover(s,"old_channel_card")
	return true

static func discover(s,id:String)->void:
	if not CLUES.has(id):return
	if not s.discovered.has(id):s.discovered.append(id)
	if id=="home_log":s.chapter.intro_seen=true
	if id=="station_dispatch":s.chapter.station_seen=true

static func choose_route(s,route:String)->bool:
	if not s.parts or s.completed or not ROUTES.has(route):return false
	s.chapter.return_plan=route
	return true

static func advance_radio(s,choice:String)->bool:
	if s.health<=0 or s.completed:return false
	match int(s.chapter.radio_step):
		1:
			if choice!="call":return false
			s.chapter.radio_step=2
		2:
			if choice not in ["report","ask"]:return false
			s.chapter.reply=choice
			s.chapter.report_detail="register" if s.discovered.has("ridge_register") else ("camp" if s.discovered.has("hunter_note") else "unknown")
			s.chapter.radio_step=3
		3:
			if choice!="confirm":return false
			s.chapter.radio_step=4;s.completed=true
		_:return false
	return true

static func radio_response(s)->String:
	var lead:="谷口值守：七号的位置记下了。今晚守住小屋。有火和补给，比赶夜路强。"
	if s.chapter.reply=="ask":lead="谷口值守：西侧便道也封了，今晚还不能接你下来。不要沿公路硬闯。先留在小屋，恢复接应后会通知你。"
	var detail:="你：车站已经撤空，我没有找到能确认他们去向的记录。\n\n谷口值守：收到。能回来报信就好。有后来发现的记录，先收着。"
	match s.chapter.report_detail:
		"register":detail="你：收信簿上写着，林和守桥人都到了谷口，药也送到了。\n\n谷口值守：对得上。送药的两个人已经安顿了，那张回条却没传回来。谢谢你把它带上这条线。"
		"camp":detail="你：旧营地有林留下的纸页。他把药交给守桥人，两个人一起过了桥。\n\n谷口值守：至少知道他们走到了那里。我们继续查到达记录。你不用为了补齐消息再冒险折返。"
	if s.discovered.has("departure_trace"):detail+="\n\n你：他出巡前留了纸条，说天黑前回频道。\n\n谷口值守：纸条先留好，那是出发前的记录。我们不会把它当成他现在的位置。"
	return lead+"\n\n"+detail+"\n\n你：周岑最后说，他要去查北坡信标。\n\n谷口值守：那盏灯已经两夜没亮了。现在还不知道是电源还是线路的问题。今晚先休整，别凭一个没亮的灯往山里找人。"

static func objective(s)->String:
	if s.completed:return "第一章已完成 · 留在林区休整\n气象站区域尚未开放" if s.chapter.epilogue_step==3 else "已向谷口报平安 · 可选：查看旧频道\n先休整，也可以稍后再听"
	if s.chapter.radio_step>0:return "小屋无线电 · 继续通话\n确认谷口已经收到你的位置"
	if s.parts:
		var plan:String=ROUTES.get(s.chapter.return_plan,"判断返程路线")
		return "带回备用模块 · "+plan+"\n"+("可选：查看西岭帆布下的收信簿" if s.chapter.return_plan=="ridge" and not s.discovered.has("ridge_register") else "返回小屋，恢复通信")
	if s.arrival_journey and not s.discovered.has("home_reached"):
		if s.clock_offset>0 and s.discovered.has("lodge") and not s.discovered.has("first_rest"):
			if not s.discovered.has("first_warmth"):return "第一晚 · 在临时木屋生火取暖\n伙房在东侧，柴棚在西北；屋内也会失温"
			if s.hunger<45:return "第一晚 · 备好过夜食物\n东侧伙房找干粮；进食后回炉边检查休息预估"
			if s.wood<2:return "第一晚 · 给后半夜留好干柴\n西北柴棚有剩余燃料，找到后原路返回"
			return "第一晚 · 在炉边安排休息\n检查火能烧多久；可收起卧铺上的磁带机"
		if s.discovered.has("lodge_route"):return "寻找七号护林小屋 · 沿旧公路向北\n先补水、暖身；找到能安顿下来的地方"
		if s.discovered.has("gate_route") or s.discovered.has("lodge"):return "寻找有炉的临时木屋 · 岔路向西\n留意屋顶烟管，先取暖再继续赶路"
		if s.discovered.has("gatehouse"):
			return "已找到补给 · 查看桌上的路线纸\n岗亭不能过夜，寻找下一处落脚点" if int(s.supply_taken.get("gate_desk",{}).get("food",0))>0 else "搜寻岗亭 · 找到第一份食物\n按需取用食水，查看桌上的路线纸"
		if s.discovered.has("pass_exit"):return "前方的铁皮屋檐 · 靠近岗亭\n搜寻食物，找个能避风的地方"
		return "穿过山口 · 寻找食物与避风处\n沿低处的雪道，留意人类活动的痕迹"
	if not s.chapter.intro_seen:return "恢复通信 · 查看小屋无线电\n向谷口报平安，询问北岭四的消息"
	return "北岭车站 · 找到备用模块\n沿途留下的记录，也许能解释撤离经过"

static func journal_summary(s)->String:
	if s.completed:return "已经确认：谷口收到了平安报。周岑尚未出现在他们核对到的名单里。\n\n"+radio_response(s)+"\n\n"+("旧频道的原句与线路卡已单独收录。说话者与警告含义尚未确认。第一章 · 失联已完成，第二章区域尚未开放。" if s.chapter.epilogue_step==3 else "无线电刻度边缘出现微弱信号。休整后可再次查看；正常求援已经成功。")
	if s.parts:return "车站已撤离，备用模块是留给后来求援的人。\n\n"+("收信簿证实两人平安到达，可在通话中报告。" if s.discovered.has("ridge_register") else "西岭收信簿可能记录了送药人和守桥人的去向。查阅是可选的，平安返家更重要。")
	if s.arrival_journey and not s.discovered.has("home_reached"):
		return "你已经走出山口，随身食物用尽，湿靴仍在带走热量。\n\n"+("纸条提到北边还有落脚处。先暖身、补水，再寻找七号护林小屋。" if s.discovered.has("gate_route") else "沿低处雪道寻找屋檐、电线杆和生活痕迹。哪里有留下的食物，哪里能暂时避风，都需要走近查看。")
	if s.discovered.has("hunter_note"):return "送药人与守桥人的路线在旧营地交汇。\n\n他们后来到了哪里？车站的交接记录也许能接上这一段。"
	return "风雪封住了下山路，你的平安报还没发出。\n\n先找到备用发射模块，让谷口知道这里还有人，也问问周岑的消息。"
