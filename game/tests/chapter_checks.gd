extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var g = load("res://main.tscn").instantiate()
	g.screenshot_mode = true
	root.add_child(g)
	g.growth = g.ScoutGrowth.new()
	g.unlocked_stage = 30
	for stage in range(1,6):
		g.selected_stage = stage
		g.start_run()
		for second in [0,60,120]:
			g.elapsed = second
			g.enemies.clear()
			for i in range(40): g.spawn_enemy()
			for e in g.enemies: assert(g.Chapter.pool(stage,second).has(e.kind))
		g.enemies.clear()
		g.elapsed = 150
		g.spawn_boss()
		assert(g.enemies.size()==1 and g.enemies[0].kind==g.Chapter.FINALES[stage-1])
		g.spawn_boss()
		assert(g.enemies.size()==1)
		g.elapsed = 180
		g.spawn_enemy()
		g.update_elite_schedule()
		assert(g.enemies.size()==1)
		g.kill_enemy(0)
		g.pending_levels = 0
		g.simulate(1.0/30,Vector2.ZERO)
		assert(g.state=="won")
	g.selected_stage = 5
	g.start_run()
	g.obstacles.clear()
	g.spawn_boss()
	var boss = g.enemies[0]
	boss.p = g.player + Vector2(150,0)
	boss.timer = 0
	g.update_enemy(boss,0.01)
	assert(boss.mode=="windup" and boss.attack=="fan")
	var aim: Vector2 = boss.aim
	g.player.y += 50
	g.update_enemy(boss,0.5)
	assert(g.hostile_bullets.is_empty() and boss.aim==aim)
	g.update_enemy(boss,0.51)
	assert(g.hostile_bullets.size()==7 and boss.mode=="recover")
	boss.hp = boss.max_hp * 0.6
	g.update_enemy(boss,0.01)
	assert(boss.phase==2 and boss.mode=="recover" and g.hostile_bullets.is_empty())
	boss.mode = "seek"
	boss.timer = 0
	boss.cycle = 2
	g.update_enemy(boss,0.01)
	assert(boss.attack=="ring" and boss.mode=="windup")
	g.update_enemy(boss,1.01)
	assert(g.hostile_bullets.size()==13)
	for shot in g.hostile_bullets: assert(absf(shot.v.angle_to(boss.aim))>0.5)
	boss.hp = boss.max_hp * 0.25
	g.update_enemy(boss,0.01)
	assert(boss.phase==3 and boss.mode=="recover")
	boss.mode = "seek"
	boss.timer = 0
	boss.cycle = 0
	g.update_enemy(boss,0.01)
	assert(boss.attack=="lunge" and boss.mode=="windup")
	g.update_enemy(boss,1.16)
	assert(boss.mode=="rush")
	g.update_enemy(boss,0.56)
	assert(boss.mode=="recover")
	print("CHAPTER CHECKS PASSED: pools, finales, cutoff, victory, locked warnings, three phases, ring gap and charge recovery")
	var results = []
	for stage in range(1,6):
		for seed_value in [17,42,93]:
			g.selected_stage = stage
			g.rng.seed = seed_value
			g.test_build = 0
			g.start_run()
			var boss_attacks = {}
			for frame in range(10500):
				if g.state=="upgrade": g.bot_upgrade()
				if g.state!="playing": break
				g.simulate(1.0/30,g.bot_direction())
				for enemy in g.enemies:
					if enemy.get("chapter_boss",false) and enemy.mode=="windup": boss_attacks[enemy.attack]=true
			var record = {"stage":stage,"seed":seed_value,"result":g.state,"seconds":snappedf(g.elapsed,0.1),"hp":g.hp,"hits":g.damage_taken,"kills":g.kills,"enemies":g.enemies.size(),"boss_attacks":boss_attacks.keys()}
			results.append(record)
			print("CHAPTER BALANCE ",JSON.stringify(record))
	for record in results:
		assert(record.result == 'won' and record.seconds <= 210, 'Chapter reference run must finish without stalled cleanup')
	print('CHAPTER BALANCE PASSED: 15 complete runs')
	quit()
