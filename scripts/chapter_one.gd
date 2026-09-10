extends RefCounted
# Chapter facts and transitions. Survival owns this state; UI only presents it.
const CLUES := {
	"zhou_gloves":{"title": "衣袋便笺 · 右手拇指", "text": "备用手套叠在衣袋里，右手拇指留着一排歪针脚。\n\n周岑写道：“上回你替我缝的，没拆。针脚丑，倒是一点风都不漏。备用这副给你，湿了就换，别又说走两步就干。”\n\n纸角画了个很小的炉子。你记得他添柴总把最干的一根留到最后。"},
	"tape_home_note":{"title": "《归途》内页 · 给你回程听", "text": "盒内夹着周岑的便笺，日期是这次出巡之前。\n\n“前半面是你嫌慢的那几首，回程慢慢听。右边耳机又接触不好，线别扯太紧。”\n\n“壶放炉边，别贴着铁皮。回来的时候要是我睡了，敲两下桌子。别拿凉手碰我脖子。”\n\n最后一行写得很轻：“傍晚见。”\n\n这张旧便笺不能说明他现在在哪里。"},

	"home_log": {"title":"值守簿 · 没能发出的平安报", "text":"昨夜，山崩截断了下山公路。你退回七号护林小屋。\n\n末页是你匆忙写下的记录：“北岭四前往北坡检查信标。周岑说，查完就回频道，傍晚见。”下面只补了四个字：“尚未回报。”\n\n你们搭档多年。他偶尔错过饭点，很少错过守听。\n\n收音指针还会动，发射灯却不亮。检修单写着：“备用发射模块存于北岭车站维修间。”\n\n先让谷口知道你还在这里，再问问他的消息。也许他已从另一条路下山，只是消息还没传回来。"},
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
	return lead+"\n\n"+detail+"\n\n你：周岑最后说，他要去查北坡信标。\n\n谷口值守：那盏灯已经两夜没亮了。现在还不知道是电源还是线路的问题。今晚先休整，别凭一个没亮的灯往山里找人。"

static func objective(s)->String:
	if s.completed:return "第一章已完成 · 留在林区休整\n气象站区域尚未开放" if s.chapter.epilogue_step==3 else "已向谷口报平安 · 可选：查看旧频道\n先休整，也可以稍后再听"
	if s.chapter.radio_step>0:return "小屋无线电 · 继续通话\n确认谷口已经收到你的位置"
	if s.parts:
		var plan:String=ROUTES.get(s.chapter.return_plan,"判断返程路线")
		return "带回备用模块 · "+plan+"\n"+("可选：查看西岭帆布下的收信簿" if s.chapter.return_plan=="ridge" and not s.discovered.has("ridge_register") else "返回小屋，恢复通信")
	if not s.chapter.intro_seen:return "恢复通信 · 查看小屋无线电\n向谷口报平安，询问北岭四的消息"
	return "北岭车站 · 找到备用模块\n沿途留下的记录，也许能解释撤离经过"

static func journal_summary(s)->String:
	if s.completed:return "已经确认：谷口收到了平安报。周岑尚未出现在他们核对到的名单里。\n\n"+radio_response(s)+"\n\n"+("旧频道的原句与线路卡已单独收录。说话者与警告含义尚未确认。第一章 · 失联已完成，第二章区域尚未开放。" if s.chapter.epilogue_step==3 else "无线电刻度边缘出现微弱信号。休整后可再次查看；正常求援已经成功。")
	if s.parts:return "车站已撤离，备用模块是留给后来求援的人。\n\n"+("收信簿证实两人平安到达，可在通话中报告。" if s.discovered.has("ridge_register") else "西岭收信簿可能记录了送药人和守桥人的去向。查阅是可选的，平安返家更重要。")
	if s.discovered.has("hunter_note"):return "送药人与守桥人的路线在旧营地交汇。\n\n他们后来到了哪里？车站的交接记录也许能接上这一段。"
	return "山崩切断了下山路，你的平安报还没发出。\n\n先找到备用发射模块，让谷口知道这里还有人，也问问周岑的消息。"
