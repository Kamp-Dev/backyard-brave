extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var g=load("res://main.tscn").instantiate()
 g.screenshot_mode=true
 root.add_child(g)
 g.growth=g.ScoutGrowth.new()
 g.unlocked_stage=30
 for stage in range(1,6):
  for build in range(4):
   g.selected_character=1
   g.selected_stage=stage
   g.test_build=build
   g.start_run()
   g.rng.seed=42
   var peak=0
   for frame in range(24000):
    while g.state=="upgrade": g.bot_upgrade()
    if g.state!="playing": break
    g.simulate(1.0/30,g.bot_direction())
    peak=maxi(peak,g.bullets.size())
   assert(g.state in ["won","dead"] and g.elapsed<720 and peak<80)
   print("POPPY BALANCE ",JSON.stringify({"stage":stage,"build":build,"result":g.state,"seconds":snappedf(g.elapsed,0.1),"level":g.level,"hp":g.hp,"catches":g.poppy.catches,"peak_projectiles":peak}))
 print("POPPY BALANCE FINISHED")
 quit()
