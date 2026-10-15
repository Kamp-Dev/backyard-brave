extends RefCounted
# Shared requirement vocabulary for rewards and future character definitions.
const CHARACTER_RULES = {0: [], 1: [{"type":"stage", "target":15}]}
var totals: Dictionary = {"kills":0, "damage":0.0, "pickups":0, "dodges":0, "bosses":0}
func load_config(save: ConfigFile):
 var data=save.get_value("lifetime","totals",{})
 for key in totals:
  totals[key]=maxf(0,float(data.get(key,0))) if key=="damage" else maxi(0,int(data.get(key,0)))
func write_config(save: ConfigFile): save.set_value("lifetime","totals",totals)
func record(kills:int, damage:float, pickups:int, dodges:int, won:bool):
 totals.kills+=maxi(0,kills)
 totals.damage+=maxf(0,damage)
 totals.pickups+=maxi(0,pickups)
 totals.dodges+=maxi(0,dodges)
 totals.bosses+=int(won)
func value(rule:Dictionary, stages:Dictionary, account_level:int=1, growth_level:int=0) -> float:
 match rule.type:
  "stage": return float(rule.target) if bool(stages.get(str(rule.target),{}).get("cleared",false)) else 0.0
  "level": return account_level
  "growth": return growth_level
  _: return float(totals.get(rule.type,0))
func meets(rules:Array, stages:Dictionary, account_level:int=1, growth_level:int=0) -> bool:
 for rule in rules:
  if value(rule,stages,account_level,growth_level)<float(rule.target): return false
 return true
func character_unlocked(character:int, stages:Dictionary, account_level:int=1) -> bool:
 return CHARACTER_RULES.has(character) and meets(CHARACTER_RULES[character],stages,account_level)

