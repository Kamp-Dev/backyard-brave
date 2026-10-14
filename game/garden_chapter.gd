extends RefCounted
## Chapter one teaches one encounter pattern per stage, then combines them.
const TITLES = ["FIRST CLEARING", "PEBBLE CROSSING", "CLOVER CORNER", "POTTING PATCH", "DAISY PATCH"]
const BRIEFS = ["Keep moving / Gather fallen seeds", "Watch the charge / Roll to the side", "Keep an escape route / Watch the flanks", "Dodge the volley / Use the rocks", "Bramble Broodmother / Watch, dodge, strike"]
const FINALES = [7, 6, 7, 8, 5]
const GUARDIANS = ["Clover Captain", "Pebbleback", "Briar Captain", "Goldenwing", "Bramble Broodmother"]
const ELITES = [[7,7,7], [7,6,6], [7,7,6], [7,8,8], [7,6,8]]
const POOLS = [
	[[0,0,0,9], [0,0,9,1], [0,0,9,1]],
	[[0,0,2,9], [0,2,3,9], [0,2,3,3,9]],
	[[0,1,1,9], [0,1,10,9], [0,1,1,10,11]],
	[[0,0,4,9], [0,4,4,2,10], [0,4,2,10,11]],
	[[0,1,9,10], [0,2,3,4,11], [0,1,2,3,4,9,10,11]]
]

static func active(stage: int) -> bool:
	return stage >= 1 and stage <= 5

static func pool(stage: int, seconds: float) -> Array:
	return POOLS[stage-1][mini(2, int(seconds / 60.0))]

static func spawn_pace(stage: int, seconds: float) -> float:
	# Short breathing spaces before checkpoint encounters and the finale.
	var pause = 1.7 if fmod(seconds,45.0) > 38.0 else 1.0
	return [1.45,1.3,1.2,1.15,1.1][stage-1] * pause

static func finale_health(stage: int) -> float:
	return [48.0,85.0,85.0,100.0,190.0][stage-1]

static func rock_offsets(stage: int) -> Array[Vector2]:
	match stage:
		2: return [Vector2(170,140),Vector2(430,380)]
		3: return [Vector2(130,170),Vector2(445,170),Vector2(300,460)]
		4: return [Vector2(130,170),Vector2(270,170),Vector2(430,430),Vector2(290,430)]
		5: return [Vector2(130,130),Vector2(470,130),Vector2(130,470),Vector2(470,470)]
	return []

# Attacks are selected from a shuffled bag, with no immediate repeats. Geometry
# locks when the warning starts; randomness never changes an attack mid-warning.
static func begin_attack(host, e: Dictionary, attack: String, followup: bool = false) -> void:
	e.attack = attack
	e.aim = (host.player-e.p).normalized()
	e.origin = e.p
	e.mode = "windup"
	e.timer = 0.85 if attack=="lunge" else (1.15 if attack in ["slam","eruption"] else 0.9)
	if followup: e.timer = 0.85
	e.windup_duration = e.timer
	if attack=="eruption":
		e.zones = [host.player]
		var heading: Vector2=host.facing.normalized()
		var forecast: Vector2=host.player+heading*host.speed*0.85
		e.zones.append(host.arena_center+(forecast-host.arena_center).limit_length(host.BOSS_ARENA_RADIUS-50))
		# The opposite flank leaves a route through the middle instead of sealing it.
		var flank: Vector2=host.player-heading.orthogonal()*130
		e.zones.append(host.arena_center+(flank-host.arena_center).limit_length(host.BOSS_ARENA_RADIUS-65))
		e.zone_radius = 62.0 + e.phase*6
	if not followup: e.charges = 2 if e.phase>=2 and attack=="lunge" else 1

static func choose_attack(host, e: Dictionary) -> String:
	var bag: Array = e.get("attack_bag",[])
	if bag.is_empty():
		bag = ["fan","lunge","ring","slam","eruption"]
		if host.run_stage==1 and e.phase==1: bag.erase("eruption")
		# Deterministic RNG belongs to gameplay, not render frames.
		for i in range(bag.size()-1,0,-1):
			var j = host.rng.randi_range(0,i)
			var swap = bag[i]
			bag[i] = bag[j]
			bag[j] = swap
	if bag.size()>1 and bag[-1]==e.get("last_attack",""):
		var swap=bag[0]
		bag[0]=bag[-1]
		bag[-1]=swap
	var attack: String = bag.pop_back()
	e.attack_bag = bag
	e.last_attack = attack
	return attack

static func recover(e: Dictionary) -> void:
	e.mode = "recover"
	e.timer = 1.0 if e.phase==1 else 0.75

static func update_boss(host, e: Dictionary, dt: float) -> void:
	var phase = 3 if e.hp/e.max_hp<=0.3 else 2 if e.hp/e.max_hp<=0.65 else 1
	if phase>e.get("phase",1):
		e.phase=phase
		e.attack_bag=[]
		e.zones=[]
		e.mode="recover"
		e.timer=1.0
		host.banner="GUARDIAN / " + ("ENRAGED" if phase==3 else "PHASE 2")
		host.banner_timer=1.5
		host.hostile_bullets.clear()
	e.timer-=dt
	if e.mode=="windup":
		if e.timer>0: return
		match e.attack:
			"lunge":
				e.mode="rush"
				e.timer=0.55
			"slam":
				e.mode="shockwave"
				e.front=20.0
				e.timer=0.95
			"eruption":
				e.mode="eruption"
				e.timer=0.38
			"fan":
				for i in range(7+phase*2):
					var angle=-0.85+1.7*i/float(6+phase*2)
					host.add_hostile_shot(e.p,e.aim.rotated(angle),190+phase*15,7)
				recover(e)
			"ring":
				for i in range(22):
					var angle=TAU*i/22.0
					if absf(wrapf(angle,-PI,PI))<0.48: continue
					host.add_hostile_shot(e.p,e.aim.rotated(angle),185,7)
				recover(e)
		return
	if e.mode=="eruption":
		for point in e.zones:
			if host.player.distance_to(point)<e.zone_radius+14 and host.roll_time<=0 and host.hurt_timer<=0: host.hurt_player()
		if e.timer<=0:
			e.zones=[]
			recover(e)
		return
	if e.mode=="shockwave":
		var previous: float=e.front
		e.front+=280*dt
		var distance: float=host.player.distance_to(e.origin)
		if distance>=previous-22 and distance<=e.front+22 and host.roll_time<=0 and host.hurt_timer<=0: host.hurt_player()
		if e.timer<=0: recover(e)
		return
	if e.mode=="rush":
		var destination: Vector2=e.p+e.aim*450*dt
		e.p=host.move_actor(e.p,e.aim*450*dt,e.radius)
		if e.timer<=0 or e.p.distance_to(destination)>2:
			e.charges-=1
			if e.charges>0: begin_attack(host,e,"lunge",true)
			else: recover(e)
		return
	if e.mode=="recover":
		if e.timer<=0:
			e.mode="seek"
			e.timer=0.4 if phase==1 else 0.2
		return
	if e.timer<=0:
		begin_attack(host,e,choose_attack(host,e))
		return
	var direction: Vector2=(host.player-e.p).normalized()
	host.walk_enemy(e,direction,175+phase*15,dt)
