extends RefCounted
## Finite encounters: time is a score, never a condition for advancing.
const COUNTS = [14,20,24,30,34,38,44,50,56,0]
var remaining = 0
var spawned = 0
var miniboss_spawned = false
var intermission = -1.0
var cleared = 0
var final_prep = false

func begin(host, number: int) -> void:
	host.wave = number
	spawned = 0
	miniboss_spawned = false
	intermission = -1.0
	remaining = int(ceil(COUNTS[number-1] * minf(1.5,host.Tuning.stage_density(host.run_stage))))
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
	if intermission>=0:
		intermission -= dt
		if intermission<=0: begin(host,host.wave+1)
		return
	if remaining==0 and host.enemies.is_empty():
		cleared = host.wave
		intermission = 1.2
		host.hostile_bullets.clear()
		host.banner = ("MINIBOSS DEFEATED / WAVE %d" if host.wave in [3,6] else "WAVE %d CLEARED") % host.wave
		host.banner_timer = 1.2
		# Sweep XP only on a true clear: no tedious backtracking before the next wave.
		var seeds = host.gems.size()
		host.gems.clear()
		for i in range(seeds): host.gain_xp()
		if host.wave==9 and not final_prep:
			final_prep = true
			host.pending_levels += 1
			host.pending_encounter_rewards += 1
			host.encounter_rewards += 1
		return
	host.spawn_timer -= dt
	if remaining<=0 or host.spawn_timer>0: return
	var batch = mini(remaining,2+int(host.wave/3))
	for i in range(batch):
		if host.enemies.size()>=70: break
		host.spawn_enemy()
		var enemy = host.enemies[-1]
		enemy.hp *= 1.0 + (host.wave-1)*0.035
		# Compact champions punctuate later hordes without being minibosses.
		if host.wave>=4 and spawned%11==7:
			enemy.champion = true
			enemy.hp *= 2.1
			enemy.speed *= 1.12
			enemy.visual_scale = 0.9
			enemy.radius *= 0.9
		enemy.max_hp = enemy.hp
		enemy.trail_hp = enemy.hp
		spawned += 1
		remaining -= 1
	host.spawn_timer = maxf(0.28,0.7-host.wave*0.035)
