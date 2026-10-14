extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g=load("res://main.tscn").instantiate()
	g.screenshot_mode=true
	root.add_child(g)
	g.growth=g.ScoutGrowth.new()
	g.unlocked_stage=30
	# Even while moving, each unobstructed group approaches from all eight sectors.
	for seed_value in range(100):
		g.selected_stage=1+seed_value%5
		g.start_run()
		g.rng.seed=seed_value
		g.obstacles.clear()
		g.facing=Vector2.from_angle(seed_value*0.37)
		var directions: Array[Vector2]=[]
		var seen: Array[int]=[]
		for i in range(8):
			g.player+=g.facing*12
			assert(g.spawn_enemy())
			var e=g.enemies[-1]
			var direction: Vector2=(e.p-g.player).normalized()
			directions.append(direction)
			var sector=posmod(roundi(wrapf(direction.angle()-g.waves.spawn_heading,-PI,PI)/(TAU/8)),8)
			assert(not seen.has(sector), "Each sector gets one arrival before reusing a sector")
			seen.append(sector)
			assert(e.p.distance_to(g.player)>=259.9 and e.p.distance_to(g.player)<=320.1)
			assert(not g.enemy_contact(e,e.p), "Arrival grace protects the player")
			if i%2==1: assert(directions[i].dot(directions[i-1]) < -0.85, "Successive pairs approach from opposite sides")
		assert(seen.size()==8)
	# Rocks trigger a safe alternate approach, not a forced clamped position.
	g.start_run()
	g.obstacles.clear()
	g.waves.spawn_heading=0
	g.waves.spawn_sectors.assign([0])
	for angle in [-0.2,0.0,0.2]: g.obstacles.append(g.player+Vector2.from_angle(angle)*290)
	assert(g.spawn_enemy())
	assert(g.enemies[-1].p.distance_to(g.player)>=260 and g.constrain_actor(g.enemies[-1].p,62).is_equal_approx(g.enemies[-1].p))
	# A fully obstructed ring retries later and does not consume a wave budget.
	g.start_run()
	g.obstacles.clear()
	for i in range(32): g.obstacles.append(g.player+Vector2.from_angle(i*TAU/32)*290)
	var budget: int=g.waves.remaining
	g.waves.advance(g,0.01)
	assert(g.enemies.is_empty() and g.waves.remaining==budget and g.waves.spawned==0)
	# Re-entry preserves wounded enemies and never teleports visible bugs or elites.
	g.start_run()
	g.elapsed=20
	g.obstacles.clear()
	var distant=g.make_enemy(g.player+Vector2(1200,0),0)
	distant.hp=0.5
	g.enemies.append(distant)
	var visible=g.make_enemy(g.player+Vector2(150,0),0)
	g.enemies.append(visible)
	var visible_position: Vector2=visible.p
	var elite=g.make_enemy(g.player+Vector2(1400,0),6)
	g.enemies.append(elite)
	var elite_position: Vector2=elite.p
	g.waves.redirect_straggler(g)
	assert(distant.hp==0.5 and distant.p.distance_to(g.player)<=320 and distant.arrival==0.65)
	assert(visible.p==visible_position and elite.p==elite_position and g.kills==0 and g.gems.is_empty())
	assert(g.waves.redirected==1 and g.enemies.size()==3)
	# An empty field is refilled; timed escalation leaves all XP in place.
	for number in range(1,9):
		g.start_run()
		g.waves.begin(g,number)
		g.enemies.clear()
		g.gems.assign([g.player+Vector2(200,0),g.player+Vector2(-230,0)])
		var seeds=g.gems.duplicate()
		g.elapsed=g.waves.STARTS[number-1]+1
		g.waves.advance(g,0.01)
		assert(g.wave==number and not g.enemies.is_empty() and g.gems==seeds and g.xp==0)
		g.elapsed=g.waves.STARTS[number]
		g.waves.advance(g,0.01)
		assert(g.wave==number+1 and g.gems==seeds, "Timed escalation must not sweep XP")
	# Normal collection still grants one seed and triggers Forager progress.
	g.start_run()
	g.waves.remaining=99
	g.spawn_timer=99
	g.gems.assign([g.player])
	g.upgrade_ranks[8]=1
	g.simulate(0.01,Vector2.ZERO)
	assert(g.gems.is_empty() and g.xp==1 and g.run_skills.gathered==1)
	# The final sweep awards all leftover XP before arena creation, exactly once.
	g.start_run()
	g.wave=9
	g.elapsed=300
	g.waves.remaining=0
	for i in range(g.RUN_XP_STEPS[0]+g.RUN_XP_STEPS[1]): g.gems.append(g.player+Vector2(600+i,0))
	g.waves.advance(g,0.01)
	assert(g.gems.is_empty() and g.level==3 and g.xp==0 and g.pending_levels==3)
	assert(not g.arena_active and not g.boss_spawned and g.state=="upgrade")
	while g.state=="upgrade": g.bot_upgrade()
	g.waves.advance(g,0.01)
	assert(g.wave==10 and g.boss_spawned and g.boss_warning==3 and g.level==3 and g.xp==0)
	var count: int=g.enemies.size()
	assert(not g.spawn_enemy() and g.enemies.size()==count)
	print("SPAWN XP PASSED: 100 seeds, eight approach sectors, opposite pairs, movement, obstacles, retry budget, manual XP and pre-boss sweep")
	quit()
