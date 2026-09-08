extends SceneTree

const Survival = preload("res://scripts/survival.gd")
var failures := 0

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1

func _initialize() -> void:
	var s = Survival.new()
	s.tick(10, "", false, true)
	check(s.temperature < 88 and s.stamina == 0, "Outside cold and sprint drain")
	var protected = Survival.new()
	protected.tick(10, "", true, false)
	check(protected.temperature > s.temperature, "Windbreak reduces temperature loss")
	s.temperature = 30
	s.light_fire("home")
	s.tick(10, "home", false, false)
	check(s.temperature > 40 and s.wood == 1, "Fire consumes wood and warms shelter")
	s.pickup("parts_test", "parts")
	var weight: float = s.weight()
	s.pickup("parts_test", "parts")
	check(s.parts and s.weight() == weight and s.collected.size() == 1, "Pickup cannot duplicate")
	check(not Survival.new().repair(), "Cannot complete without parts")
	check(s.repair(), "Can complete with parts")
	var before: float = s.elapsed
	s.tick(60, "", false, false)
	check(s.elapsed == before, "Completed game does not advance")
	var full = Survival.new()
	full.wood = 7
	full.pickup("blocked", "parts")
	check(not full.parts and not full.collected.has("blocked"), "Full backpack rejects pickup without consuming it")
	var restored = Survival.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(s.data()))), "Save data JSON round trip")
	check(restored.parts and restored.completed and restored.collected == s.collected and restored.wood == s.wood, "Save restores task and inventory")
	check(not restored.restore({"temperature": "bad"}), "Reject malformed save")
	var dying = Survival.new()
	dying.temperature = 0
	dying.tick(60, "", false, false)
	check(dying.health == 0, "Exposure can cause failure")
	var food = Survival.new()
	food.stamina = 20
	food.eat()
	check(food.stamina == 65 and food.food == 1, "Food consumes one ration and restores stamina")
	print("SMOKE_RESULT failures=", failures)
	quit(1 if failures > 0 else 0)
