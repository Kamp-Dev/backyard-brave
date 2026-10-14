extends RefCounted
## Continuous pressure for five minutes, then the arena guardian.
const DURATION = 300.0
const REGULAR_LIMIT = 68 # Reserve two mobile-cap slots for the required minibosses.
const STARTS = [0.0,30.0,60.0,95.0,130.0,165.0,200.0,235.0,270.0]
const INTERVALS = [2.0,1.8,1.6,1.4,1.25,1.1,0.95,0.8,0.7]
var remaining = 0
var spawned = 0
var miniboss_spawned = false
var intermission = -1.0
var cleared = 0
var final_prep = false
var spawn_sectors: Array[int] = []
var spawn_heading = 0.0
var waiting_for_elites = false
var redirected = 0

func next_spawn_angle(host) -> float:
	# Opposite pairs prevent a whole batch choosing one side by chance. Each
	# eight-bug group covers the circle, relative to the scout's recent movement.
	if spawn_sectors.is_empty():
		spawn_heading = host.facing.angle()+host.rng.randf_range(-0.16,0.16)
		var pairs = [0,1,2,3]
		for i in range(3,0,-1):
			var j: int = host.rng.randi_range(0,i)
			var swap: int = pairs[i]
			pairs[i] = pairs[j]
			pairs[j] = swap
		for sector in pairs:
			var first: int = sector+(4 if host.rng.randf()<0.5 else 0)
			spawn_sectors.append(first)
			spawn_sectors.append((first+4)%8)
	return spawn_heading+spawn_sectors.pop_front()*TAU/8

func begin(host, number: int) -> void:
	host.wave = number
	spawned = 0
	spawn_sectors.clear()
	miniboss_spawned = false
	intermission = -1.0
	remaining = 1 if number<10 else 0 # Compatibility flag: reinforcements are active.
	host.spawn_timer = 0
	if number>1:
		if host.upgrade_ranks[6]>0: host.shield = mini(host.guard_capacity(),host.shield+1)
		if host.run_growth[13]>0 and number%3==0: host.shield = mini(host.guard_capacity(),host.shield+1)
	host.banner = "WAVE %d / 10" % number + (" / LAST STAND" if number==9 else " / SWARM SURGE" if number==7 else "")
	host.banner_timer = 1.6
	if number==10:
		host.spawn_boss()
	elif number in [3,6]:
		host.update_elite_schedule()

func advance(host, dt: float) -> void:
	if host.boss_spawned: return
	if final_prep:
		begin(host,10)
		return
	# Timed escalation never waits for an empty field or drops unclaimed XP.
	while host.wave<9 and host.elapsed>=STARTS[host.wave]:
		cleared = host.wave
		begin(host,host.wave+1)
	if host.elapsed>=DURATION:
		remaining = 0
		for e in host.enemies:
			if e.get("miniboss",false):
				if not waiting_for_elites:
					host.banner = "DEFEAT THE MINIBOSS / THEN THE GUARDIAN"
					host.banner_timer = 3.0
				waiting_for_elites = true
				return
		waiting_for_elites = false
		final_prep = true
		var seeds = host.gems.size()
		host.gems.clear()
		for i in range(seeds): host.gain_xp()
		host.pending_levels += 1
		host.pending_encounter_rewards += 1
		host.encounter_rewards += 1
		if host.state=="playing": host.show_upgrades()
		return
	host.spawn_timer -= dt
	if host.spawn_timer>0: return
	for i in range(2+int(host.wave/3)):
		if host.enemies.size()>=REGULAR_LIMIT:
			redirect_straggler(host)
			continue
		if not host.spawn_enemy(): break
		var enemy = host.enemies[-1]
		enemy.hp *= 1.0 + (host.wave-1)*0.05
		if host.wave>=4 and spawned%13==7:
			enemy.champion = true
			enemy.hp *= 2.1
			enemy.speed *= 1.12
			enemy.visual_scale = 0.9
			enemy.radius *= 0.9
		enemy.max_hp = enemy.hp
		enemy.trail_hp = enemy.hp
		enemy.display_hp = enemy.hp
		spawned += 1
	host.spawn_timer = INTERVALS[host.wave-1]/minf(1.35,host.Tuning.stage_density(host.run_stage))

func redirect_straggler(host) -> void:
	# At the mobile cap, offscreen stragglers re-enter from fresh approaches.
	# Keep identity and HP: this cannot grant kills, XP or free healing.
	var chosen = -1
	var farthest = 0.0
	for i in range(host.enemies.size()):
		var e = host.enemies[i]
		if host.Tuning.is_major(e.kind) or host.elapsed-float(e.get("spawned_at",0))<3: continue
		if host.world_view().grow(24).has_point(e.p): continue
		var distance: float = e.p.distance_squared_to(host.player)
		if distance>farthest:
			farthest = distance
			chosen = i
	if chosen<0: return
	var point: Vector2 = host.wave_spawn_point()
	if not point.is_finite(): return
	var enemy = host.enemies[chosen]
	enemy.p = point
	enemy.arrival = 0.65
	enemy.spawned_at = host.elapsed
	enemy.mode = "seek"
	enemy.timer = 1.0
	redirected += 1
