extends RefCounted

const REGULAR_COUNT = 100
const MERIT_COUNT = 10
const TYPES = [0,1,2,0,5,3,0,4,5,0]
const NAMES = ["Strong Seeds","Healthy Scout","Forager Reach","Trail Feet","Nimble Roll","Quick Hands","First Pick","Dew Shield","Second Wind","Bramble Guard","Lucky Harvest","Petal Burst","Refreshing Roll","Deep Roots","Boss Breaker","Final Bloom", "Oak Heart", "Amber Seeds", "Wide Pouch", "Light Steps", "Spring Roll", "Swift Sling"]
const DETAILS = ["+0.15 seed damage","+1 maximum heart","+7 pickup reach","+3 movement speed","Roll recovers 0.04s faster","+2% attack speed","Choose a skill before each run","Start each run with 2 guard charges","Once per run: revive at half health","Broken guard hits nearby bugs for 2x damage","Every fifth bug drops an extra XP seed","Every sixth volley fires 2 extra seeds","Every fourth roll heals 1 heart below half HP","Gain 1 guard charge every third wave","Deal 20% more damage to bosses and minibosses","Reaching run level 7 grants an extra skill choice", "+2 maximum hearts", "+0.45 seed damage", "+25 pickup reach", "+8 movement speed", "Roll recovers 0.12s faster", "+6% base attack speed"]
const ICONS = [2,-1,3,5,4,0,1,6,-1,8,3,1,4,6,2,0,-1,2,3,5,4,0]
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
 return TYPES[id%10] if id<100 else merit_picks[id-100]

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
 if id>=100: return growth_level()>=(id-99)*10
 return available_stage(records)>=required_stage(id) and (id==0 or ranks[id-1]>0)

func status(id: int, records: Dictionary) -> String:
 if id<0 or id>=110: return "LOCKED"
 if ranks[id]>0: return "LEARNED"
 if id>=100 and not gate_met(id,records): return "Growth level %d" % ((id-99)*10)
 if id<100 and available_stage(records)<required_stage(id): return "Reach stage %d" % required_stage(id)
 if id>0 and id<100 and ranks[id-1]==0: return "Learn level %d first" % id
 if (packets if id<100 else acorns)<cost(id): return "Need %d %s" % [cost(id),"packets" if id<100 else "acorn"]
 return "READY"

func merit_offers(id: int) -> Array[int]:
 var offers: Array[int] = []
 if id<100 or id>=110 or ranks[id]>0: return offers
 var unlock_at = {8:30,9:40,10:30,11:60,12:40,13:60,14:70,15:90}
 var pool: Array[int] = []
 for bonus in range(6,NAMES.size()):
  if (id-99)*10 < int(unlock_at.get(bonus,10)): continue
  var owned = false
  for slot in range(10):
   if ranks[100+slot]>0 and merit_picks[slot]==bonus: owned = true
  if not owned: pool.append(bonus)
 var random = RandomNumberGenerator.new()
 random.seed = merit_seed+id*7919
 while offers.size()<3 and not pool.is_empty():
  var index = random.randi_range(0,pool.size()-1)
  offers.append(pool[index])
  pool.remove_at(index)
 return offers

func buy(id: int, records: Dictionary, bonus: int = -1) -> bool:
 if status(id,records)!="READY": return false
 if id<100: packets -= cost(id)
 else:
  if not merit_offers(id).has(bonus): return false
  merit_picks[id-100] = bonus
  acorns -= 1
 ranks[id] = 1
 claim_milestones(records)
 return true

func claim_milestones(_records: Dictionary) -> int:
 var gained = 0
 for milestone in range(10,101,10):
  if growth_level()>=milestone and not claimed.has(milestone):
   claimed.append(milestone)
   acorns += 1
   gained += 1
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

func write_config(save: ConfigFile) -> void:
 save.set_value("growth","merit_seed",merit_seed)
 save.set_value("growth","merit_picks",merit_picks.duplicate())
 save.set_value("growth","version",2)
 save.set_value("growth","packets",packets)
 save.set_value("growth","acorns",acorns)
 save.set_value("growth","ranks",ranks.duplicate())
 save.set_value("growth","claimed",claimed.duplicate())
