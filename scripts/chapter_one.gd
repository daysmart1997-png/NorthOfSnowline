extends RefCounted
# Chapter facts and transitions. Survival owns this state; UI only presents it.
const CLUES := {
	"home_log": {"title":"值守簿 · 没能发出的平安报", "text":"昨夜，山崩截断了下山的公路。你退回这间护林小屋，直到天亮也没能联系上谷口。\n\n值守簿的末页写着：‘傍晚例行守听巡林频道，其他时段可试呼谷口。备用模块在北岭维修间。’\n\n收音指针还会动，发射灯却不亮。先把自己的位置报出去，才有人知道该往哪里找。"},
	"fork_note": {"title":"褪色的巡林路线", "text":"路线纸上，东侧林道被铅笔重描了一遍：‘送药的人走林道，铁轨上顶风。布条一直挂到旧营地。’\n\n下面是另一种笔迹：‘收到。若先到站，把炉灰留着。——守桥人’\n\n这里曾有人等着另一个人经过。铁轨更直接，林道则能挡住一部分风。"},
	"hunter_note": {"title":"压在石下的纸页", "text":"‘药已交给守桥人。过桥前我们在这里烘干了手套，他还惦记着西岭那箱东西。’\n\n‘我把柴放在帐棚后。维修间的炉子还好用；别等天黑才往回赶。’\n\n落款只剩一个‘林’字。纸上的折痕与岔路那张路线纸相同：送药的人确实走到了这里。"},
	"sled_note": {"title":"断绳与雪橇", "text":"雪橇一侧的绳子断了，绳头拖向西岭。捆扎布下压着一页货单：‘药包随身带走。收信簿留在岭上帆布箱，等风停再取。’\n\n货单上签着‘林’。箱子里也许能找到撤离者的去向。坡上露出一截旧帆布；上岭迎风，先检查体温和水壶。"},
	"ridge_register": {"title":"收信簿 · 平安到达", "text":"帆布下面是一册用油纸包好的收信簿。最后一栏被反复描深：\n\n‘林、守桥人，均已到谷口。药送到了。北坡信标没亮，无法确认是否还有人滞留。请保留巡林频道。’\n\n他们不是无声无息地消失了。只要把这页内容带回去，谷口就能把那两个名字从失联名单上划掉。"},
	"station_dispatch": {"title":"维修交接 · 留给后来的人", "text":"备用模块下压着交接单。\n\n‘线路中断，末班车取消。人员改走西侧便道撤往谷口。发射模块留下，供沿线小屋求援。炉门没锁，这里还能给没赶上撤离的人挡一夜风。’\n\n末尾补了一行：‘送药的林和守桥人尚未回报。西岭转运箱内有收信簿。’\n\n车站的人已经撤离；小屋的无线电才是你与外界的联系。带着零件回去，或在体温和物资允许时绕上西岭，查清他们的下落。"}
}
const ROUTES := {"direct":"沿铁路返家", "sheltered":"沿林道返家", "ridge":"绕访西岭"}

static func fresh()->Dictionary:
	return {"intro_seen":false,"station_seen":false,"weather_warned":false,"return_plan":"","radio_step":0,"reply":"","report_detail":""}

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
	var lead:="谷口值守：收到你的位置。护林小屋，独自一人。先守住炉火，我们会记住这个位置。"
	if s.chapter.reply=="ask":lead="谷口值守：西侧便道也封了，今晚无法接你下山。留在小屋，下一次傍晚守听时我们继续联系。"
	match s.chapter.report_detail:
		"register":return lead+"\n\n你把收信簿里的两个名字念了一遍。\n\n谷口值守：林和守桥人都到了……谢谢，那张送达回条一直没能传回来。还有一件事：北坡信标已经两夜没亮。先休整，等你准备好，我们再谈那条路。"
		"camp":return lead+"\n\n你报告了旧营地里送药人的纸页。\n\n谷口值守：至少能确认他们过了旧营地。我们继续核对到达名单，你别为此折返冒险。北坡信标已经两夜没亮；先休整，等你准备好，我们再谈那条路。"
	return lead+"\n\n谷口值守：撤离名单还没核对齐。有任何沿途记录，先留好。北坡信标已经两夜没亮；先休整，等你准备好，我们再谈那条路。"

static func objective(s)->String:
	if s.completed:return "第一章已完成 · 与谷口建立联系\n留在林区休整，等待下一次出发"
	if s.chapter.radio_step>0:return "小屋无线电 · 继续通话\n确认谷口已经收到你的位置"
	if s.parts:
		var plan:String=ROUTES.get(s.chapter.return_plan,"判断返程路线")
		return "带回备用模块 · "+plan+"\n"+("可选：查看西岭帆布下的收信簿" if s.chapter.return_plan=="ridge" and not s.discovered.has("ridge_register") else "返回小屋，恢复通信")
	if not s.chapter.intro_seen:return "恢复通信 · 查看小屋无线电\n备用模块存放在北岭维修间"
	return "北岭车站 · 找到备用模块\n沿途留下的记录，也许能解释撤离经过"

static func journal_summary(s)->String:
	if s.completed:return "你的平安报已经被谷口接收。\n\n"+radio_response(s)+"\n\n北坡信标是下一章的线索，当前还不能前往。"
	if s.parts:return "车站已撤离，备用模块是留给后来求援的人。\n\n"+("收信簿证实两人平安到达，可在通话中报告。" if s.discovered.has("ridge_register") else "西岭收信簿可能记录了送药人和守桥人的去向。查阅是可选的，平安返家更重要。")
	if s.discovered.has("hunter_note"):return "送药人与守桥人的路线在旧营地交汇。\n\n他们后来到了哪里？车站的交接记录也许能接上这一段。"
	return "山崩切断了下山路，你的平安报还没发出。\n\n先找到备用发射模块，让谷口知道这里还有人。"
