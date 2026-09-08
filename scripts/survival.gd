extends RefCounted

const MAX_WEIGHT := 18.0
var temperature := 88.0
var stamina := 100.0
var health := 100.0
var elapsed := 0.0
var wood := 2
var food := 2
var parts := false
var completed := false
var collected: Array = []
var fires := {"home": 0.0, "station": 0.0}

func weight() -> float:
	return 6.0 + wood * 1.5 + food * 0.4 + (3.0 if parts else 0.0)

func storm() -> float:
	return clampf((elapsed - 35.0) / 220.0, 0.0, 1.0)

func speed_factor() -> float:
	return clampf(1.0 - maxf(weight() - 11.0, 0.0) * 0.045, 0.65, 1.0) * (0.8 if temperature < 22.0 else 1.0)

func tick(delta: float, shelter: String, windbreak: bool, sprinting: bool) -> void:
	if completed or health <= 0.0:
		return
	elapsed += delta
	for key in fires:
		fires[key] = maxf(float(fires[key]) - delta, 0.0)
	var warm := not shelter.is_empty()
	var burning := warm and float(fires.get(shelter, 0.0)) > 0.0
	if warm:
		temperature += (1.5 if burning else 0.08) * delta
	else:
		temperature -= (0.15 + 0.30 * storm()) * (0.50 if windbreak else 1.0) * delta
	temperature = clampf(temperature, 0.0, 100.0)
	stamina = clampf(stamina + (-16.0 if sprinting else 10.0) * delta, 0.0, 100.0)
	if temperature < 10.0:
		health = maxf(health - delta * 1.8, 0.0)

func pickup(id: String, kind: String) -> String:
	if collected.has(id):
		return "已经取走了。"
	var extra := 1.5 if kind == "wood" else (0.4 if kind == "food" else 3.0)
	if weight() + extra > MAX_WEIGHT:
		return "背包太重，先使用一些木柴或口粮。"
	match kind:
		"wood": wood += 1
		"food": food += 1
		"parts": parts = true
		_: return "无法拾取。"
	collected.append(id)
	return "已取回无线电零件。返回南侧护林小屋！" if kind == "parts" else "已收入背包。"

func light_fire(id: String) -> String:
	if not fires.has(id):
		return "没有可用火炉。"
	if wood <= 0:
		return "没有木柴了，去沿途补给点寻找。"
	if float(fires[id]) >= 160.0:
		return "炉火充足，先留着木柴。"
	wood -= 1
	fires[id] = float(fires[id]) + 90.0
	return "添入木柴：炉火增加 90 秒，室内快速回暖。"

func eat() -> String:
	if food <= 0:
		return "口粮已经用完。"
	food -= 1
	stamina = minf(stamina + 45.0, 100.0)
	temperature = minf(temperature + 5.0, 100.0)
	return "吃下口粮，体力恢复。"

func repair() -> bool:
	if not parts or health <= 0.0:
		return false
	completed = true
	return true

func data() -> Dictionary:
	return {"temperature": temperature, "stamina": stamina, "health": health,
		"elapsed": elapsed, "wood": wood, "food": food, "parts": parts,
		"completed": completed, "collected": collected.duplicate(), "fires": fires.duplicate()}

func restore(d: Dictionary) -> bool:
	for key in ["temperature", "stamina", "health", "elapsed", "wood", "food"]:
		if not d.has(key) or not (d[key] is float or d[key] is int):
			return false
	if not d.get("collected") is Array or not d.get("fires") is Dictionary:
		return false
	if not d.get("parts") is bool or not d.get("completed") is bool:
		return false
	for key in ["home", "station"]:
		if not (d.fires.get(key) is float or d.fires.get(key) is int):
			return false
	temperature = clampf(float(d.temperature), 0.0, 100.0)
	stamina = clampf(float(d.stamina), 0.0, 100.0)
	health = clampf(float(d.health), 0.0, 100.0)
	elapsed = clampf(float(d.elapsed), 0.0, 86400.0)
	wood = clampi(int(d.wood), 0, 8)
	food = clampi(int(d.food), 0, 20)
	parts = d.parts
	completed = d.completed
	collected = d.collected.duplicate()
	for key in fires:
		fires[key] = clampf(float(d.fires[key]), 0.0, 250.0)
	return true
