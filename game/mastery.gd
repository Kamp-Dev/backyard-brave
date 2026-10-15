extends RefCounted
# Cosmetic achievements only. All goals accumulate together; titles unlock in order.
const TITLES = [["Trail Beginner", "Seed Slinger", "Lane Keeper", "Clover Ranger", "Garden Guardian"], ["Garden Guest", "Return Artist", "Bloom Keeper", "Rain Gardener", "Garden Guardian"]]
var records: Dictionary = {}
var signature = 0
func unlocked(character: int, stages: Dictionary) -> bool:
	return preload("res://lifetime_progress.gd").new().character_unlocked(character,stages)
func entry(character: int) -> Dictionary:
	var key = str(character)
	if not records.has(key): records[key] = {"clears": [], "bugs": 0, "signature": 0, "combos": [], "chapter": false}
	return records[key]
func load_config(config: ConfigFile):
	var value = config.get_value("mastery", "records", {})
	records = value.duplicate(true) if value is Dictionary else {}
func write_config(config: ConfigFile):
	config.set_value("mastery", "records", records)
func finish(character: int, stage: int, won: bool, bugs: int, catches: int, combos: Array):
	var e = entry(character)
	e.bugs += maxi(0, bugs)
	e.signature += maxi(0, catches if character == 1 else signature)
	if won:
		if not e.clears.has(stage): e.clears.append(stage)
		for combo in combos:
			if not e.combos.has(combo): e.combos.append(combo)
		if stage >= 5: e.chapter = true
func goals(character: int) -> Array:
	var e = entry(character)
	return [["Clear a stage", e.clears.size(), 1], ["Defeat bugs", e.bugs, 750], ["Roll-catch returns" if character == 1 else "Land ricochet hits", e.signature, 40 if character == 1 else 150], ["Win with different compatibility bonuses", e.combos.size(), 3], ["Clear three stages, including Stage 5+", mini(3,e.clears.size()) if e.chapter else mini(2,e.clears.size()), 3]]
func tier(character: int) -> int:
	var result = 0
	for goal in goals(character):
		if goal[1] < goal[2]: break
		result += 1
	return result
func title(character: int) -> String:
	var rank = tier(character)
	return TITLES[character][rank-1] if rank > 0 else "New adventurer"
