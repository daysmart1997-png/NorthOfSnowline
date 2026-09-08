extends RefCounted

const MAX_WEIGHT := 24.0
const ITEMS := {
	"wood": {"name":"木柴", "weight":1.2, "description":"干燥的劈柴。用于添火、搭营地、制作和修缮。"},
	"food": {"name":"口粮", "weight":0.4, "description":"恢复 32 饱食与 25 体力。"},
	"water": {"name":"饮用水", "weight":0.7, "description":"恢复 40 水分。在燃烧的火炉旁可以融雪补水。"},
	"cloth": {"name":"布料", "weight":0.2, "description":"制作绷带、铺床、修补窗户和搭建营地。"},
	"scrap": {"name":"废金属", "weight":0.6, "description":"用于庇护所结构加固和储物箱。"},
	"herb": {"name":"干药草", "weight":0.1, "description":"与饮用水一起，在火炉旁煮成暖身茶。"},
	"bandage": {"name":"绷带", "weight":0.1, "description":"由两份布料制成，恢复 22 健康。"},
	"tea": {"name":"暖身茶", "weight":0.5, "description":"恢复 18 体温与 20 水分。"},
	"battery": {"name":"备用电池", "weight":0.15, "description":"装入磁带机，将电量补满。"},
	"player": {"name":"奇异磁带机", "weight":0.7, "description":"这台旧机器让旋律拥有力量。选磁带装入，再按播放。"},
	"tape_embers": {"name":"磁带 · 余烬", "weight":0.08, "description":"播放期间，室外失温速度降低 25%。消耗磁带机电量。"},
	"tape_stride": {"name":"磁带 · 步履", "weight":0.08, "description":"播放期间，奔跑体力消耗降低 25%。消耗磁带机电量。"},
	"tape_home": {"name":"磁带 · 归途", "weight":0.08, "description":"在庇护所播放时缓慢恢复精力与健康。消耗磁带机电量。"},
	"parts": {"name":"无线电零件", "weight":2.0, "description":"带回护林小屋，在无线电旁安装。"}
}
const RECIPES := {
	"bandage": {"name":"制作绷带", "cost":{"cloth":2}, "output":"bandage"},
	"tea": {"name":"煮暖身茶", "cost":{"herb":1,"water":1}, "output":"tea", "fire":true},
	"water": {"name":"融雪煮水", "cost":{"wood":1}, "output":"water", "fire":true},
	"insulation": {"name":"封窗保温", "cost":{"wood":3,"cloth":2,"scrap":1}, "upgrade":true},
	"bed": {"name":"修复保暖床铺", "cost":{"wood":2,"cloth":3}, "upgrade":true},
	"storage": {"name":"制作储物箱", "cost":{"wood":3,"scrap":2}, "upgrade":true},
	"camp": {"name":"搭建临时营地", "cost":{"wood":3,"cloth":3}, "outdoor":true}
}
var temperature := 88.0
var stamina := 100.0
var health := 100.0
var hunger := 85.0
var thirst := 80.0
var energy := 90.0
var elapsed := 0.0
var completed := false
var items := {"wood":2,"food":2,"water":1}
var collected: Array = []
var discovered: Array = []
var fires := {"home":0.0,"station":0.0,"hunters":0.0}
var upgrades := {"insulation":false,"bed":false,"storage":false}
var storage := {}
var structures: Array = []
var battery_charge := 65.0
var loaded_tape := ""
var music_playing := false
var wood: int:
	get: return count("wood")
	set(value): items["wood"] = value
var food: int:
	get: return count("food")
	set(value): items["food"] = value
var parts: bool:
	get: return count("parts") > 0
	set(value): items["parts"] = 1 if value else 0

func count(id: String) -> int:
	return int(items.get(id, 0))

func weight() -> float:
	var total := 5.0
	for id in items:
		if ITEMS.has(id): total += count(id) * float(ITEMS[id].weight)
	return total

func storm() -> float:
	var phase := fmod(elapsed, 1200.0)
	return clampf((phase - 90.0) / 360.0, 0.0, 1.0) * (1.0 - clampf((phase - 850.0) / 300.0, 0.0, 1.0))

func speed_factor() -> float:
	return clampf(1.0 - maxf(weight() - 15.0, 0.0) * 0.035, 0.65, 1.0) * (0.82 if temperature < 22 or energy < 15 else 1.0)

func music_effect() -> String:
	return loaded_tape if music_playing and battery_charge > 0 and count("player") > 0 and count(loaded_tape) > 0 else ""

func tick(delta: float, shelter: String, windbreak: bool, sprinting: bool) -> void:
	if health <= 0: return
	elapsed += delta
	var effect := music_effect()
	if not effect.is_empty():
		battery_charge = maxf(0, battery_charge - delta * 0.13)
		if battery_charge <= 0: music_playing = false
	for key in fires: fires[key] = maxf(float(fires[key]) - delta, 0.0)
	var warm := not shelter.is_empty()
	var burning := warm and float(fires.get(shelter,0)) > 0
	if warm:
		temperature += (1.0 if burning else (0.12 if shelter == "home" and upgrades.insulation else -0.015 * storm())) * delta
	else:
		var loss := (0.075 + 0.16 * storm()) * (0.55 if windbreak else 1.0)
		temperature -= loss * (0.75 if effect == "tape_embers" else 1.0) * delta
	temperature = clampf(temperature,0,100)
	stamina = clampf(stamina + delta * (-14.0 * (0.75 if effect == "tape_stride" else 1.0) if sprinting else (8.0 if hunger > 15 else 3.0)),0,100)
	hunger = maxf(0,hunger - delta * (0.05 if sprinting else 0.027))
	thirst = maxf(0,thirst - delta * (0.065 if sprinting else 0.043))
	energy = maxf(0,energy - delta * (0.035 if sprinting else 0.012))
	if effect == "tape_home" and warm:
		energy = minf(100,energy + delta * 0.10)
		health = minf(100,health + delta * 0.04)
	if temperature < 10: health = maxf(0,health - delta * 1.0)
	if hunger <= 0 or thirst <= 0: health = maxf(0,health - delta * 0.14)

func loot(id: String, contents: Dictionary) -> String:
	if collected.has(id): return "这里已经搜寻过了。"
	var extra := 0.0
	for item in contents:
		if not ITEMS.has(item): return "未知物品。"
		extra += float(ITEMS[item].weight) * int(contents[item])
	if weight() + extra > MAX_WEIGHT: return "背包装不下：先使用、存放或丢弃一些物品，再来搜寻。"
	var found: Array[String] = []
	for item in contents:
		items[item] = count(item) + int(contents[item])
		found.append(str(ITEMS[item].name) + " ×" + str(contents[item]))
	collected.append(id)
	return "找到：" + "、".join(found)

func pickup(id: String, kind: String) -> String:
	return loot(id,{kind:1})

func light_fire(id: String) -> String:
	if not fires.has(id): return "没有可用火炉。"
	if wood <= 0: return "需要一份木柴。"
	if float(fires[id]) >= 230: return "炉火充足，先留着木柴。"
	wood -= 1
	fires[id] = float(fires[id]) + 120
	return "添入木柴。炉火增加 120 秒。"

func use_item(id: String) -> String:
	if count(id) <= 0: return "背包里没有这件物品。"
	match id:
		"food": hunger=minf(100,hunger+32); stamina=minf(100,stamina+25)
		"water": thirst=minf(100,thirst+40)
		"tea": temperature=minf(100,temperature+18); thirst=minf(100,thirst+20)
		"bandage": health=minf(100,health+22)
		"battery":
			if count("player") <= 0: return "先找到磁带机。"
			if battery_charge > 95: return "电量还很充足，先留着电池。"
			battery_charge=100
		"player": return toggle_music()
		"tape_embers", "tape_stride", "tape_home":
			if count("player") <= 0: return "还没有磁带机，先收好这盘磁带。"
			loaded_tape=id
			return "装入「%s」。点击磁带机播放。" % ITEMS[id].name
		_: return "这是制作材料或任务物品。可查看配方，或放入储物箱。"
	items[id]=count(id)-1
	return "已使用%s。" % ITEMS[id].name

func eat() -> String: return use_item("food")

func toggle_music() -> String:
	if music_playing:
		music_playing=false
		return "磁带机已停止。"
	if count("player") <= 0: return "你还没有磁带机。"
	if loaded_tape.is_empty() or count(loaded_tape) <= 0: return "先在背包中选择一盘磁带装入。"
	if battery_charge <= 0: return "电池耗尽，装入备用电池。"
	music_playing=true
	return "旋律响起：" + str(ITEMS[loaded_tape].description)

func recipe_problem(id: String, shelter: String, camp_valid := false) -> String:
	if not RECIPES.has(id): return "未知配方。"
	var recipe: Dictionary = RECIPES[id]
	if recipe.get("upgrade",false):
		if shelter != "home": return "需要回到护林小屋。"
		if upgrades[id]: return "已经建好了。"
	if recipe.get("fire",false) and (shelter.is_empty() or float(fires.get(shelter,0)) <= 0): return "需要靠近燃烧的火炉。"
	if id == "camp":
		if structures.size() >= 3: return "最多搭建三处营地。"
		if not shelter.is_empty() or not camp_valid: return "附近没有足够平坦、空旷的搭建位置。"
	var after := weight()
	for item in recipe.cost:
		if count(item) < int(recipe.cost[item]): return "缺少：%s ×%d" % [ITEMS[item].name,int(recipe.cost[item])-count(item)]
		after -= int(recipe.cost[item]) * float(ITEMS[item].weight)
	if recipe.has("output"):
		after += float(ITEMS[recipe.output].weight)
		if after > MAX_WEIGHT: return "背包装不下成品。"
	return ""

func craft(id: String, shelter: String, camp_position: Array = []) -> String:
	var problem := recipe_problem(id,shelter,camp_position.size()==3)
	if not problem.is_empty(): return problem
	var recipe: Dictionary = RECIPES[id]
	for item in recipe.cost: items[item]=count(item)-int(recipe.cost[item])
	if recipe.has("output"): items[recipe.output]=count(recipe.output)+1
	elif id == "camp":
		var camp_id := "camp_%d" % structures.size()
		structures.append({"id":camp_id,"position":[float(camp_position[0]),float(camp_position[1]),float(camp_position[2])]})
		fires[camp_id]=0.0
	else: upgrades[id]=true
	return "完成："+str(recipe.name)

func transfer(id: String, deposit: bool, shelter: String) -> String:
	if shelter != "home" or not upgrades.storage: return "需要在护林小屋制作储物箱后使用。"
	if not ITEMS.has(id): return "未知物品。"
	if deposit:
		if count(id)<=0: return "没有可存放的物品。"
		if id in ["player","parts"] or id.begins_with("tape_"): return "重要装备和任务物品随身携带。"
		items[id]=count(id)-1;storage[id]=int(storage.get(id,0))+1
	else:
		if int(storage.get(id,0))<=0: return "储物箱里没有这件物品。"
		if weight()+float(ITEMS[id].weight)>MAX_WEIGHT: return "背包装不下了。"
		storage[id]=int(storage[id])-1;items[id]=count(id)+1
	return "已存放一份。" if deposit else "已取出一份。"

func discard(id: String) -> String:
	if id in ["player","parts"] or id.begins_with("tape_"): return "重要装备与磁带不能丢弃。"
	if count(id)<=0: return "背包里没有这件物品。"
	items[id]=count(id)-1
	return "已丢弃一份%s。" % ITEMS[id].name

func rest(shelter: String) -> String:
	if shelter.is_empty(): return "需要在庇护所休息。"
	if shelter == "home" and not upgrades.bed: return "先修复小屋里的保暖床铺。"
	if temperature < 30 and float(fires.get(shelter,0)) <= 0: return "太冷了，先把火点起来。"
	for i in range(120):
		tick(1,shelter,false,false)
		if health<=0: return "你没能挺过这个寒夜。"
	energy=minf(100,energy+35)
	stamina=100
	return "休息了两分钟，恢复 35 精力；天气与消耗继续推进。"

func repair() -> bool:
	if not parts or health<=0 or completed: return false
	completed=true
	return true

func data() -> Dictionary:
	return {"schema":2,"temperature":temperature,"stamina":stamina,"health":health,"hunger":hunger,"thirst":thirst,"energy":energy,"elapsed":elapsed,"completed":completed,"items":items.duplicate(),"collected":collected.duplicate(),"discovered":discovered.duplicate(),"fires":fires.duplicate(),"upgrades":upgrades.duplicate(),"storage":storage.duplicate(),"structures":structures.duplicate(true),"battery_charge":battery_charge,"loaded_tape":loaded_tape,"music_playing":music_playing}

func restore(d: Dictionary) -> bool:
	# Validate before assigning. Supports the original v1 save as well as v2.
	for key in ["temperature","stamina","health","elapsed"]:
		if not (d.get(key) is float or d.get(key) is int) or not is_finite(float(d[key])): return false
	if not d.get("collected") is Array or not d.get("fires") is Dictionary or not d.get("completed") is bool: return false
	var raw_inventory = d.get("items",{"wood":d.get("wood",2),"food":d.get("food",2),"parts":1 if d.get("parts",false) else 0,"water":1})
	if not raw_inventory is Dictionary:return false
	var inv:Dictionary=raw_inventory
	for k in inv:
		if not ITEMS.has(k) or not (inv[k] is int or inv[k] is float) or not is_finite(float(inv[k])) or float(inv[k])<0: return false
	for key in ["hunger","thirst","energy","battery_charge"]:
		if d.has(key) and (not (d[key] is float or d[key] is int) or not is_finite(float(d[key]))): return false
	for key in ["upgrades","storage"]:
		if d.has(key) and not d[key] is Dictionary: return false
	for key in ["structures","discovered"]:
		if d.has(key) and not d[key] is Array: return false
	for id in d.get("storage",{}):
		var qty = d.storage[id]
		if not ITEMS.has(id) or not (qty is int or qty is float) or float(qty)<0: return false
	for id in d.get("upgrades",{}):
		if not upgrades.has(id) or not d.upgrades[id] is bool: return false
	for key in d.fires:
		if not (d.fires[key] is int or d.fires[key] is float) or not is_finite(float(d.fires[key])): return false
	if d.get("structures",[]).size()>3:return false
	var camp_index:=0
	for structure in d.get("structures",[]):
		if not structure is Dictionary or not structure.get("position") is Array or structure.position.size()!=3 or not structure.get("id") is String: return false
		if structure.id!="camp_%d"%camp_index:return false
		camp_index+=1
		for v in structure.position:
			if not (v is float or v is int) or not is_finite(float(v)): return false
	var tape = d.get("loaded_tape","")
	if not tape is String or (not tape.is_empty() and not tape in ["tape_embers","tape_stride","tape_home"]): return false
	if not d.get("music_playing",false) is bool: return false
	for key in ["temperature","stamina","health","hunger","thirst","energy","battery_charge"]: set(key,clampf(float(d.get(key,get(key))),0,100))
	elapsed=clampf(float(d.elapsed),0,864000)
	completed=d.completed;items={};collected=d.collected.duplicate()
	for key in inv:items[key]=int(inv[key])
	discovered=d.get("discovered",[]).duplicate();structures=d.get("structures",[]).duplicate(true)
	fires={"home":0.0,"station":0.0,"hunters":0.0}
	upgrades={"insulation":false,"bed":false,"storage":false}
	for key in d.fires: fires[key]=clampf(float(d.fires[key]),0,360)
	for key in d.get("upgrades",{}): upgrades[key]=d.upgrades[key]
	storage={};loaded_tape=tape
	for key in d.get("storage",{}):storage[key]=int(d.storage[key])
	music_playing=d.get("music_playing",false) and count("player")>0 and count(tape)>0 and battery_charge>0
	return true
