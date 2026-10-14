extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	g.screenshot_mode=true
	root.add_child(g)
	g.growth=g.ScoutGrowth.new()
	g.unlocked_stage=30
	g.selected_stage=5
	var reactive_wins=0
	var circle_losses=0
	for pilot in ["reactive","circle"]:
		for seed_value in [17,42,93]:
			g.start_run()
			g.rng.seed=seed_value
			g.level=10
			g.damage=3.0+9*g.LEVEL_SEED_POWER
			for kind in [0,0,3,3,3,5,5,5,6,6,7,7]:
				g.upgrades.assign([kind])
				g.pending_levels=1
				g.choose_upgrade(0)
			g.waves.begin(g,10)
			for frame in range(6000):
				if g.state!="playing": break
				var offset=g.player-g.arena_center
				var move=g.bot_direction() if pilot=="reactive" else offset.normalized().orthogonal()+(offset.normalized() if offset.length()<185 else -offset.normalized())*0.3
				if offset.length()<10 and pilot=="circle": move=Vector2.RIGHT
				g.simulate(1.0/30,move)
			if pilot=="reactive" and g.state=="won": reactive_wins+=1
			if pilot=="circle" and g.state=="dead": circle_losses+=1
			print("BOSS PILOT ",JSON.stringify({"pilot":pilot,"seed":seed_value,"result":g.state,"time":g.elapsed,"hp":g.hp,"hits":g.damage_taken}))
	assert(reactive_wins==3 and circle_losses>=2, "Reading telegraphs must outperform passive circling")
	print("BOSS PRESSURE PASSED")
	quit()

