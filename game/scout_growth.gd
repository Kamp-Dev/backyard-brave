extends RefCounted

const REGULAR_COUNT = 100
const MERIT_COUNT = 10
const TYPES = [0,1,2,0,5,3,0,4,5,0]
const NAMES = ["Strong Seeds","Healthy Scout","Forager Reach","Trail Feet","Nimble Roll","Quick Hands","First Pick","Dew Shield","Second Wind","Bramble Guard","Lucky Harvest","Petal Burst","Refreshing Roll","Deep Roots","Boss Breaker","Final Bloom", "Oak Heart", "Amber Seeds", "Wide Pouch", "Light Steps", "Spring Roll", "Swift Sling", "Ancient Oak"]
const DETAILS = ["+0.15 seed damage","+1 maximum heart","+7 pickup reach","+3 movement speed","Roll recovers 0.04s faster","+2% attack speed","Choose a skill before each run","Start each run with 2 guard charges","Once per run: revive at half health","Broken guard hits nearby bugs for 2x damage","Every fifth bug drops an extra XP seed","Every sixth volley fires 2 extra seeds","Every fourth roll heals 1 heart below half HP","Gain 1 guard charge every third wave","Deal 20% more damage to bosses and minibosses","Reaching run level 10 grants an extra skill choice", "+25% maximum hearts", "+0.45 seed damage", "+50% pickup reach", "+8 movement speed", "Roll recovers 0.12s faster", "+15% base attack speed", "Revive at full health with 4s protection"]
const ICONS = [2,-1,3,5,4,0,1,6,-1,8,3,1,4,6,2,0,-1,2,3,5,4,0,-1]
const FIXED = [16,18,6,21,8,17,14,7,15,22]
const GATES = [20,30,40,50,60,70,80,90,95,100]
const GOALS = [{"type":"kills","target":5000},{"type":"pickups","target":10000},{"type":"stage","target":15},{"type":"damage","target":500000},{"type":"stage","target":20},{"type":"kills","target":25000},{"type":"bosses","target":50},{"type":"dodges","target":500},{"type":"level","target":50},{"type":"stage","target":30}]
var lifetime = preload("res://lifetime_progress.gd").new()
var account_level = 1
var legacy: Array[int] = []
var packets = 5
var acorns = 0
var ranks: Array[int] = []
var claimed: Array[int] = []
var migrated = false
var merit_seed = randi()
var merit_picks: Array[int] = []

func _init() -> void:
 ranks.resize(REGULAR_COUNT+MERIT_COUNT)
 ranks.fill(0)
 for index in range(10): merit_picks.append(6+index)

func kind(id: int) -> int:
 return TYPES[id%10] if id<100 else FIXED[id-100]

func name_for(id: int) -> String:
 return NAMES[kind(id)]

func detail_for(id: int) -> String:
 return DETAILS[kind(id)]

func cap(_id: int) -> int:
 return 1

func cost(id: int) -> int:
 if id>=100: return 1
 if id==0: return 5
 return ceili(8.0+0.32*id+0.4*pow(id/10.0,1.25))

func growth_level() -> int:
 var total = 0
 for id in range(100): total += ranks[id]
 return total

func required_stage(id: int) -> int:
 return 1+id*29/99

func available_stage(records: Dictionary) -> int:
 var stage = 1
 while stage<30 and bool(records.get(str(stage),{}).get("cleared",false)):
  stage += 1
 return stage

func gate_met(id: int, records: Dictionary) -> bool:
 if id>=100: return growth_level()>=GATES[id-100] and lifetime.meets([GOALS[id-100]],records,account_level)
 return available_stage(records)>=required_stage(id) and (id==0 or ranks[id-1]>0)

func status(id: int, records: Dictionary) -> String:
 if id<0 or id>=110: return "LOCKED"
 if ranks[id]>0: return "LEARNED"
 if id>=100: return requirement_text(id,records)
 if id<100 and available_stage(records)<required_stage(id): return "Reach stage %d" % required_stage(id)
 if id>0 and id<100 and ranks[id-1]==0: return "Learn level %d first" % id
 if (packets if id<100 else acorns)<cost(id): return "Need %d %s" % [cost(id),"packets" if id<100 else "acorn"]
 return "READY"

func requirement_text(id:int, records:Dictionary) -> String:
 var slot=id-100
 var rule=GOALS[slot]
 var label={"kills":"bugs","damage":"damage","pickups":"XP drops","dodges":"near misses","bosses":"boss wins","level":"account level","stage":"stage clear"}.get(rule.type,rule.type)
 return "Growth %d/%d | %s %d/%d" % [mini(growth_level(),GATES[slot]),GATES[slot],label,mini(int(lifetime.value(rule,records,account_level)),int(rule.target)),rule.target]

func merit_offers(_id:int) -> Array[int]: return []

func buy(id:int, records:Dictionary, _bonus:int=-1) -> bool:
 if id>=100 or status(id,records)!="READY": return false
 packets-=cost(id)
 ranks[id]=1
 claim_milestones(records)
 return true

func claim_milestones(records:Dictionary) -> int:
 var gained=0
 for slot in range(10):
  if ranks[100+slot]==0 and gate_met(100+slot,records):
   ranks[100+slot]=1
   gained+=1
 acorns=0
 for slot in range(10): acorns+=ranks[100+slot]
 return gained

func reward_parts(kills: int, won: bool, first_clear: bool, stage: int = 1, seconds: float = 0.0) -> Dictionary:
 var garden_stage = clampi(stage,1,30)
 var harvest = mini(maxi(0,kills)/60,4+garden_stage/10)
 var clear_bonus = 3+(garden_stage-1)/2 if won else 0
 var first_bonus = 4+garden_stage/10 if won and first_clear else 0
 var chapter_bonus = 5 if won and first_clear and garden_stage%10==0 else 0
 # Completed attempts retain a little progress; quitting never calls reward().
 var effort = mini(3,maxi(0,int(seconds))/45) if not won and kills>=10 else 0
 return {"harvest":harvest,"clear":clear_bonus,"first":first_bonus,"chapter":chapter_bonus,"effort":effort}

func reward(kills: int, won: bool, first_clear: bool, stage: int = 1, seconds: float = 0.0) -> int:
 var earned = 0
 for amount in reward_parts(kills,won,first_clear,stage,seconds).values(): earned += amount
 packets += earned
 return earned

func bonuses() -> Array[int]:
 var result: Array[int] = []
 result.resize(NAMES.size())
 result.fill(0)
 for id in range(110): result[kind(id)] += ranks[id]
 for bonus in legacy: result[bonus]=maxi(1,result[bonus])
 return result

func load_config(save: ConfigFile) -> void:
 merit_seed = int(save.get_value("growth","merit_seed",merit_seed))
 var picks = save.get_value("growth","merit_picks",[])
 for i in range(10):
  merit_picks[i] = clampi(int(picks[i]),6,NAMES.size()-1) if i<picks.size() else 6+i
 packets = maxi(0,int(save.get_value("growth","packets",5)))
 acorns = maxi(0,int(save.get_value("growth","acorns",0)))
 ranks.fill(0)
 claimed.clear()
 var saved = save.get_value("growth","ranks",[])
 migrated = save.has_section("growth") and int(save.get_value("growth","version",1))<2
 if migrated:
  # Refund old regular ranks at their original price; preserve rare perks.
  for id in range(mini(6,saved.size())):
   var rank = clampi(int(saved[id]),0,3)
   packets += 5*rank*(rank+1)/2
  for id in range(6,mini(9,saved.size())): ranks[100+id-6] = clampi(int(saved[id]),0,1)
  # Previously issued acorns count toward the same lifetime total of ten.
  var issued = clampi(acorns+ranks[100]+ranks[101]+ranks[102],0,10)
  for i in range(issued): claimed.append((i+1)*10)
 else:
  for id in range(mini(saved.size(),110)): ranks[id] = clampi(int(saved[id]),0,1)
  for milestone in save.get_value("growth","claimed",[]):
   if int(milestone) in range(10,101,10) and not claimed.has(int(milestone)): claimed.append(int(milestone))

 # Old chosen perks remain active without granting unearned new milestones.
 legacy.assign(save.get_value("growth","legacy",[]))
 if int(save.get_value("growth","version",1))<3:
  for slot in range(10):
   if ranks[100+slot]>0 and not legacy.has(merit_picks[slot]): legacy.append(merit_picks[slot])
   ranks[100+slot]=0
  packets += acorns*20 # Retired unspent currency becomes useful Growth currency.
  migrated=save.has_section("growth")
  acorns=0

func write_config(save: ConfigFile) -> void:
 save.set_value("growth","merit_seed",merit_seed)
 save.set_value("growth","merit_picks",merit_picks.duplicate())
 save.set_value("growth","version",3)
 save.set_value("growth","legacy",legacy)
 save.set_value("growth","packets",packets)
 save.set_value("growth","acorns",acorns)
 save.set_value("growth","ranks",ranks.duplicate())
 save.set_value("growth","claimed",claimed.duplicate())

func next_reward() -> int:
 for id in range(100,110):
  if ranks[id]==0: return id
 return -1
