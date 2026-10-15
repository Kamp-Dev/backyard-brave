extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var l=load("res://lifetime_progress.gd").new()
 assert(not l.character_unlocked(1,{"5":{"cleared":true}}))
 assert(not l.character_unlocked(1,{"14":{"cleared":true}}))
 assert(l.character_unlocked(1,{"15":{"cleared":true}}))
 assert(not l.character_unlocked(2,{}))
 l.record(5000,500000,10000,500,false)
 assert(l.totals.bosses==0)
 assert(l.meets([{"type":"kills","target":5000},{"type":"level","target":40}],{},40))
 assert(not l.meets([{"type":"stage","target":50}],{}))
 var g=load("res://scout_growth.gd").new()
 g.lifetime=l
 for i in range(20): g.ranks[i]=1
 assert(g.claim_milestones({})==1 and g.ranks[100]==1)
 assert(g.claim_milestones({})==0)
 assert(g.merit_offers(101).is_empty())
 assert(not g.buy(101,{},18))
 for i in range(20,100): g.ranks[i]=1
 g.account_level=50
 l.totals.bosses=50
 l.totals.kills=25000
 assert(g.claim_milestones({"15":{"cleared":true},"20":{"cleared":true},"30":{"cleared":true}})==9)
 assert(g.acorns==10)
 var old=ConfigFile.new()
 old.set_value("growth","version",2)
 var ranks=[]
 ranks.resize(110)
 ranks.fill(0)
 ranks[100]=1
 old.set_value("growth","ranks",ranks)
 old.set_value("growth","merit_picks",[8])
 old.set_value("growth","acorns",2)
 old.set_value("growth","packets",10)
 var migrated=load("res://scout_growth.gd").new()
 migrated.load_config(old)
 assert(migrated.bonuses()[8]==1 and migrated.ranks[100]==0 and migrated.packets==50)
 var save=ConfigFile.new()
 migrated.write_config(save)
 l.write_config(save)
 var again=load("res://scout_growth.gd").new()
 again.load_config(save)
 assert(again.packets==50 and again.bonuses()[8]==1)
 var restored=load("res://lifetime_progress.gd").new()
 restored.load_config(save)
 assert(restored.totals==l.totals)
 var game=load("res://main.tscn").instantiate()
 game.screenshot_mode=true
 root.add_child(game)
 game.growth=g
 game.start_run()
 assert(game.scout_max_hp()==23)
 assert(is_equal_approx(game.magnet,240.0))
 game.run_skills.on_near_miss(game)
 game.run_skills.on_near_miss(game)
 assert(game.run_dodges==1)
 game.roll_counted=false
 game.run_skills.on_near_miss(game)
 assert(game.run_dodges==2)
 print("LIFETIME ACORN CHECKS PASSED")
 quit()
