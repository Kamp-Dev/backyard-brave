extends SceneTree

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var g=load("res://main.tscn").instantiate()
	g.screenshot_mode=true
	root.add_child(g)
	g.growth=g.ScoutGrowth.new()
	g.unlocked_stage=30
	g.selected_character=1 if "--poppy" in OS.get_cmdline_user_args() else 0
	g.start_run()
	g.damage=0
	g.hp=10000
	for frame in range(6000): g.simulate(1.0/30,Vector2.RIGHT)
	assert(g.wave>=6 and not g.boss_spawned and g.waves.remaining>0 and not g.enemies.is_empty(), "Reinforcements continue during the five-minute buildup")
	assert(g.waves.redirected>0, "Running away at the cap must not leave all pressure behind")
	var frozen: float=g.elapsed
	g.state="upgrade"
	g.simulate(1.0,Vector2.ZERO)
	assert(g.elapsed==frozen, "Skill decisions do not consume survival time")
	g.state="playing"
	g.elapsed=300
	g.enemies.assign(g.enemies.filter(func(e): return e.get("miniboss",false)))
	g.waves.advance(g,0.01)
	assert(g.waves.waiting_for_elites and not g.boss_spawned and g.elite_spawn_index==2)
	for i in range(g.enemies.size()-1,-1,-1): g.kill_enemy(i)
	g.waves.advance(g,0.01)
	assert(g.waves.final_prep and g.state=="upgrade" and not g.boss_spawned)
	while g.state=="upgrade": g.bot_upgrade()
	g.waves.advance(g,0.01)
	assert(g.wave==10 and g.encounter_rewards==3 and g.arena_active and g.boss_warning==3.0 and g.enemies.size()==1)
	assert(g.repairs.size()<=2 and g.bonus_drops.size()<=1)
	var boss=g.enemies[0]
	for i in range(16):
		var direction=Vector2.from_angle(i*TAU/16)
		var start=g.arena_center+direction*150
		assert(g.move_actor(start,direction*2000,17).distance_to(g.arena_center)<=g.BOSS_ARENA_RADIUS-17+0.01)
		assert(g.move_actor(start,direction*2000,boss.radius).distance_to(g.arena_center)<=g.BOSS_ARENA_RADIUS-boss.radius+0.01)
	assert(not g.enemy_targetable(boss) and not g.enemy_contact(boss,boss.p))
	g.simulate(1.5,Vector2.ZERO)
	assert(g.boss_warning==1.5)
	g.simulate(1.5,Vector2.ZERO)
	assert(g.boss_warning==0 and g.enemy_targetable(boss))
	g.kill_enemy(0)
	var hp_before=g.hp
	g.simulate(0.5,Vector2.ZERO)
	assert(g.state=="playing" and g.hp==hp_before)
	g.simulate(0.5,Vector2.ZERO)
	assert(g.state=="won")
	g.start_run()
	assert(not g.arena_active and g.wave==1 and g.waves.remaining>0)
	for seed_value in range(100):
		g.rng.seed=seed_value
		g.pending_levels=1
		g.level=2
		g.show_upgrades()
		assert(g.upgrades.size()==3 and g.upgrades[0] in [0,1,4])
		g.waves.final_prep=true
		g.show_upgrades()
		assert(g.upgrades.size()==3)
		for kind in g.upgrades: assert(g.run_character==1 or kind!=8)
		assert(g.upgrades[0]!=g.upgrades[1] and g.upgrades[1]!=g.upgrades[2] and g.upgrades[0]!=g.upgrades[2])
		g.waves.final_prep=false
	g.start_run()
	g.upgrade_ranks.assign(g.UPGRADE_CAPS)
	g.upgrade_ranks[2]=2
	g.waves.final_prep=true
	g.show_upgrades()
	assert(g.upgrades==[2])
	# New records use their own key, preserving legacy records and unlocks.
	g.stage_records={}
	g.elapsed=172.5
	g.record_stage_result("won")
	g.elapsed=200
	g.record_stage_result("won")
	assert(g.stage_records[str(g.run_stage)].five_minute_v1_best==172.5)
	g.elapsed=150
	g.record_stage_result("won")
	assert(g.stage_records[str(g.run_stage)].five_minute_v1_best==150)
	# Boss attack randomness changes order, never warning geometry or dodge rules.
	g.selected_stage=5
	g.start_run()
	g.waves.begin(g,10)
	var guardian=g.enemies[0]
	guardian.arrival=0
	guardian.phase=1
	for seed_value in range(40):
		g.rng.seed=seed_value
		guardian.attack_bag=[]
		guardian.last_attack=""
		var seen=[]
		var previous=""
		for i in range(10):
			var attack=g.Chapter.choose_attack(g,guardian)
			assert(attack!=previous)
			previous=attack
			if i<5: seen.append(attack)
		assert(seen.has("slam") and seen.has("eruption") and seen.has("ring") and seen.has("fan") and seen.has("lunge"))
	g.player=g.arena_center
	g.Chapter.begin_attack(g,guardian,"eruption")
	var zones=guardian.zones.duplicate()
	g.player+=Vector2(100,100)
	var original_hp=g.hp
	g.Chapter.update_boss(g,guardian,0.5)
	assert(guardian.zones==zones and g.hp==original_hp, "Ground warnings lock their positions and do not deal early damage")
	g.Chapter.update_boss(g,guardian,0.66)
	g.player=zones[0]
	g.roll_time=0.2
	g.Chapter.update_boss(g,guardian,0.01)
	assert(g.hp==original_hp, "Rolling dodges erupting soil")
	g.roll_time=0
	g.hurt_timer=0
	g.Chapter.update_boss(g,guardian,0.01)
	assert(g.hp==original_hp-1)
	g.Chapter.update_boss(g,guardian,0.01)
	assert(g.hp==original_hp-1, "Overlapping circles respect hit grace")
	g.Chapter.begin_attack(g,guardian,"slam")
	g.Chapter.update_boss(g,guardian,1.16)
	g.player=guardian.origin+Vector2(40,0)
	g.hurt_timer=0
	g.roll_time=0.2
	g.Chapter.update_boss(g,guardian,0.01)
	assert(g.hp==original_hp-1, "Roll crosses shockwave safely")
	g.roll_time=0
	g.Chapter.update_boss(g,guardian,0.01)
	assert(g.hp==original_hp-2, "Shockwave damages its expanding ring, not an invisible whole disc")
	guardian.hp=guardian.max_hp*0.6
	g.Chapter.update_boss(g,guardian,0.01)
	assert(guardian.phase==2 and guardian.mode=="recover")
	g.Chapter.begin_attack(g,guardian,"lunge")
	g.Chapter.update_boss(g,guardian,0.86)
	g.Chapter.update_boss(g,guardian,0.56)
	assert(guardian.mode=="windup" and guardian.charges==1 and guardian.timer>=0.8, "Second charge gets a fresh, full warning")
	print("CHAPTER CHECKS PASSED: five-minute pressure, required minibosses, two minibosses, solid arena, warning, victory delay, skill fairness and clear records")
	var results=[]
	for stage in ([1,5] if "--probe" in OS.get_cmdline_user_args() else range(1,6)):
		for build in range(4):
			if "--targeted" in OS.get_cmdline_user_args() and not ((stage in [2,4] and build==1) or (stage==5 and build==0)): continue
			for seed_value in ([42] if "--probe" in OS.get_cmdline_user_args() else [17,42,93]):
				g.selected_stage=stage
				g.test_build=build
				g.start_run()
				g.rng.seed=seed_value
				var splits=[]
				var choices=[]
				var last_wave=1
				var peak=0
				var projectile_peak=0
				var zone_peak=0
				for frame in range(27000):
					while g.state=="upgrade":
						choices.append({"wave":g.wave,"time":snappedf(g.elapsed,0.1)})
						g.bot_upgrade()
					if g.state!="playing": break
					g.simulate(1.0/30,g.bot_direction())
					peak=maxi(peak,g.enemies.size())
					projectile_peak=maxi(projectile_peak,g.bullets.size())
					zone_peak=maxi(zone_peak,g.run_skills.zones.size())
					if g.arena_active: assert(g.player.distance_to(g.arena_center)<=g.BOSS_ARENA_RADIUS-17+0.02)
					if g.wave!=last_wave:
						splits.append(snappedf(g.elapsed,0.1))
						last_wave=g.wave
				var record={"character":g.run_character,"stage":stage,"build":build,"seed":seed_value,"result":g.state,"seconds":snappedf(g.elapsed,0.1),"wave":g.wave,"hp":g.hp,"hits":g.damage_taken,"level":g.level,"catches":g.poppy.catches,"choices":choices,"splits":splits,"peak":peak,"projectile_peak":projectile_peak,"zone_peak":zone_peak,"ranks":g.upgrade_ranks.duplicate()}
				results.append(record)
				print("CHAPTER BALANCE ",JSON.stringify(record))
	for record in results:
		assert(record.result in ["won","dead"] and record.seconds<720, "Every run must end without stalled encounters")
		assert(record.peak<=70 and record.projectile_peak<=80 and record.zone_peak<=20)
		if record.result=="won":
			assert(record.seconds>=303 and record.wave==10, "No early timer or skipped guardian victory")
			assert(record.choices.size()==record.level+2 and record.level>=8 and record.level<=10, "Choices match earned levels plus both minibosses and final prep")
	# Sustained survival can punish a build/seed. Require every archetype to
	# succeed on at least two of three seeds, rather than guaranteeing victory.
	for stage in ([1,5] if "--probe" in OS.get_cmdline_user_args() else range(1,6)):
		for build in range(4):
			if "--targeted" in OS.get_cmdline_user_args() and not ((stage in [2,4] and build==1) or (stage==5 and build==0)): continue
			var wins=0
			for record in results:
				if record.stage==stage and record.build==build and record.result=="won": wins+=1
			if not "--probe" in OS.get_cmdline_user_args(): assert(wins>=2, "Every build must remain viable in every chapter stage")
	print(("CHAPTER PROBE FINISHED" if "--probe" in OS.get_cmdline_user_args() else "CHAPTER BALANCE PASSED")+": %d complete simulations / character %d" % [results.size(),g.selected_character])
	quit()
