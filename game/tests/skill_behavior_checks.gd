extends SceneTree
func _initialize() -> void: call_deferred("run")

func fresh(g) -> void:
	g.start_run()
	g.obstacles.clear()
	g.enemies.clear()
	g.waves.remaining = 99
	g.spawn_timer = 99
	g.fire_timer = 99

func target(g, offset: Vector2) -> Dictionary:
	var e = g.make_enemy(g.player+offset,2)
	e.hp = 1000.0
	e.max_hp = 1000.0
	g.enemies.append(e)
	return e

func run() -> void:
	var g = load("res://main.tscn").instantiate()
	g.screenshot_mode = true
	root.add_child(g)
	g.growth = g.ScoutGrowth.new()
	fresh(g)
	target(g,Vector2(100,0))
	g.upgrade_ranks[0] = 1
	g.shoot(Vector2.RIGHT)
	assert(g.bullets.size()==1)
	g.run_skills.advance(g,0.1)
	assert(g.bullets.size()==1)
	g.run_skills.advance(g,0.03)
	assert(g.bullets.size()==2 and g.bullets[1].power<g.bullets[0].power, "Burst is a delayed second volley")
	fresh(g)
	var e = target(g,Vector2(100,0))
	g.upgrade_ranks[1] = 1
	g.shots = 2
	g.shoot(Vector2.RIGHT)
	assert(g.bullets[0].v.y<0 and g.bullets[1].v.y>0 and g.bullets[0].life<1)
	var close_power = g.run_skills.projectile_power(g,g.bullets[0],e)
	e.p += Vector2(200,0)
	assert(is_equal_approx(close_power,g.run_skills.projectile_power(g,g.bullets[0],e)*1.2))
	fresh(g)
	target(g,Vector2(100,0))
	g.upgrade_ranks[2] = 1
	for i in range(4): g.shoot(Vector2.RIGHT)
	assert(not g.bullets[2].charged and g.bullets[3].charged and g.bullets[3].pierce==1)
	assert(g.bullets[3].power>g.bullets[2].power*2)
	fresh(g)
	g.upgrade_ranks[3] = 1
	for i in range(10): g.run_skills.on_pickup(g)
	g.run_skills.advance(g,0.01)
	assert(g.bullets.is_empty() and g.run_skills.banked)
	target(g,Vector2(100,0))
	g.run_skills.advance(g,0.01)
	assert(g.bullets.size()==8 and not g.run_skills.banked and g.run_skills.gathered==2)
	fresh(g)
	e = target(g,Vector2(20,0))
	g.upgrade_ranks[4] = 1
	g.start_roll()
	g.run_skills.advance(g,0.5)
	assert(e.hp==1000)
	g.run_skills.advance(g,0.11)
	assert(e.hp<1000 and g.run_skills.zones.is_empty(), "Roll bomb detonates after its visible fuse")
	fresh(g)
	e = target(g,Vector2.ZERO)
	g.upgrade_ranks[5] = 1
	g.run_skills.after_move(g,g.player)
	assert(g.run_skills.zones.is_empty(), "Standing still cannot farm brambles")
	for i in range(30): g.run_skills.after_move(g,g.player-Vector2(70,0))
	assert(g.run_skills.zones.size()==20)
	g.run_skills.advance(g,0.01)
	var after_tick: float = e.hp
	assert(is_equal_approx(1000-after_tick,g.damage*0.2), "Overlapping trails deal one tick, not twenty")
	g.run_skills.advance(g,0.1)
	assert(e.hp==after_tick)
	fresh(g)
	e = target(g,Vector2(100,0))
	g.upgrade_ranks[6] = 1
	g.shield = 1
	g.hurt_player()
	assert(e.hp==1000 and g.shield==0)
	g.run_skills.advance(g,0.01)
	assert(e.hp<1000, "Shield counters resolve safely after collision iteration")
	fresh(g)
	e = target(g,Vector2(100,0))
	var b = {"power":3.0,"needle":1}
	assert(g.run_skills.projectile_power(g,b,e)==3)
	assert(g.run_skills.projectile_power(g,b,e)>3)
	g.elapsed = 3
	assert(g.run_skills.projectile_power(g,b,e)==3, "Needle marks expire when focus is lost")
	fresh(g)
	e = target(g,Vector2(100,0))
	var nearby = target(g,Vector2(100,30))
	g.upgrade_ranks[8] = 1
	for i in range(3): g.shoot(Vector2.RIGHT)
	assert(g.bullets[0].thump==0 and g.bullets[2].thump==1)
	g.run_skills.projectile_power(g,g.bullets[2],e)
	g.run_skills.projectile_power(g,g.bullets[2],nearby)
	assert(g.run_skills.pulses.size()==1, "Piercing thumps explode once, never recursively")
	g.run_skills.advance(g,0.01)
	assert(nearby.hp<1000 and e.hp==nearby.hp)
	# No procs hurt an arriving guardian; run reset discards all queued damage.
	g.waves.begin(g,10)
	var boss = g.enemies[-1]
	var hp_before: float = boss.hp
	g.run_skills.queue_pulse(boss.p,100,100,Color.WHITE)
	g.run_skills.advance(g,0.01)
	assert(boss.hp==hp_before)
	fresh(g)
	assert(g.run_skills.zones.is_empty() and g.run_skills.pulses.is_empty() and g.run_skills.echo.is_empty() and g.run_skills.volleys==0)
	print("SKILL BEHAVIORS PASSED: nine mechanics, timing, focus expiry, bounded non-stacking trails, safe procs and reset")
	quit()
