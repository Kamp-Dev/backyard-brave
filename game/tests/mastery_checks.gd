extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var m=load("res://mastery.gd").new()
 assert(m.unlocked(0,{}))
 assert(not m.unlocked(1,{}))
 assert(not m.unlocked(1,{"2":{"cleared":true}}))
 assert(not m.unlocked(1,{"3":{"cleared":true}}))
 assert(not m.unlocked(1,{"4":{"cleared":true}}))
 assert(not m.unlocked(1,{"5":{"cleared":false}}))
 assert(not m.unlocked(1,{"5":{"cleared":true}}))
 assert(m.unlocked(1,{"15":{"cleared":true}}))
 m.signature=150
 m.finish(0,1,true,750,0,[0,1,2])
 assert(m.tier(0)==4)
 assert(m.tier(1)==0)
 m.signature=0
 m.finish(0,2,true,0,0,[])
 assert(m.tier(0)==4)
 m.finish(0,5,true,0,0,[])
 assert(m.tier(0)==5)
 m.finish(1,1,false,750,40,[0,1,2])
 assert(m.tier(1)==0 and m.entry(1).combos.is_empty())
 m.finish(1,1,true,0,0,[0,1,2])
 assert(m.tier(1)==4)
 var c=ConfigFile.new()
 m.write_config(c)
 var restored=load("res://mastery.gd").new()
 restored.load_config(c)
 assert(restored.tier(0)==5 and restored.tier(1)==4)
 var g=load("res://main.tscn").instantiate()
 g.screenshot_mode=true
 root.add_child(g)
 g.mastery=m
 g.stage_records={}
 g.scout_profile.character_choice=1
 g.scout_profile.select_character()
 assert(g.selected_character==0)
 print("MASTERY CHECKS PASSED")
 quit()

