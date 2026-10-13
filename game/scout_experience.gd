extends RefCounted
var level=1
var xp=0
var clears: Dictionary={}
var attempts: Dictionary={}
func required() -> int:
 return 100+35*(level-1)+int(10*pow(level-1,1.25))
func add(amount: int) -> void:
 xp+=maxi(0,amount)
 while xp>=required():
  xp-=required()
  level+=1
func reward(stage: int, won: bool, seconds: float, kills: int) -> int:
 var key=str(stage)
 var prior=int(clears.get(key,0))
 var base=100+12*(stage-1)
 var amount=0
 if won:
  amount=maxi(1,floori(base/(1.0+0.5*prior)))
  clears[key]=prior+1
 elif seconds>=30 and kills>=5:
  amount=maxi(1,floori(base*0.35*clampf(seconds/180.0,0,1)/(1.0+0.5*prior+0.15*int(attempts.get(key,0)))))
  attempts[key]=int(attempts.get(key,0))+1
 add(amount)
 return amount
func load_config(cfg: ConfigFile, records: Dictionary) -> void:
 level=1
 xp=0
 clears={}
 attempts={}
 if cfg.has_section("experience"):
  level=maxi(1,int(cfg.get_value("experience","level",1)))
  xp=maxi(0,int(cfg.get_value("experience","xp",0)))
  var saved=cfg.get_value("experience","clears",{})
  if saved is Dictionary: clears=saved.duplicate()
  saved=cfg.get_value("experience","attempts",{})
  if saved is Dictionary: attempts=saved.duplicate()
  add(0)
 else:
  # Old saves know only whether a stage was cleared, not its replay count.
  for stage in range(1,31):
   if bool(records.get(str(stage),{}).get("cleared",false)):
    reward(stage,true,180,0)
func write_config(cfg: ConfigFile) -> void:
 cfg.set_value("experience","level",level)
 cfg.set_value("experience","xp",xp)
 cfg.set_value("experience","clears",clears.duplicate())
 cfg.set_value("experience","attempts",attempts.duplicate())
