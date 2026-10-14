extends RefCounted
# Combat procs are resolved outside enemy/projectile iteration. Secondary damage
# cannot create more procs, and mobile work is bounded independently of VFX settings.
var volleys = 0
var gathered = 0
var banked = false
var travel = 0.0
var echo: Dictionary = {}
var zones: Array = []
var pulses: Array = []
var rings: Array = []

func queue_pulse(p: Vector2, radius: float, power: float, color: Color) -> void:
	if pulses.size() < 24: pulses.append({"p":p,"radius":radius,"power":power,"color":color})

func on_roll(g) -> void:
	var rank: int = g.upgrade_ranks[4]
	if rank > 0:
		zones.append({"p":g.player,"radius":70.0+rank*6,"power":g.damage*(1.2+rank*0.16),"life":0.6,"bomb":true})
		while zones.size()>20: zones.pop_front()

func on_guard(g) -> void:
	var rank: int = g.upgrade_ranks[6]
	if rank > 0: queue_pulse(g.player,150,g.damage*(1.0+rank*0.2),Color("8dcfc3"))

func on_pickup(g) -> void:
	if g.upgrade_ranks[3] <= 0: return
	gathered += 1
	if gathered >= 8:
		gathered -= 8
		# Banking an attack rewards collecting even if the wave is already cleared.
		banked = true

func after_move(g, previous: Vector2) -> void:
	if g.upgrade_ranks[5] <= 0: return
	travel += g.player.distance_to(previous)
	if travel >= 65:
		travel = fmod(travel,65)
		zones.append({"p":g.player,"radius":32.0,"power":g.damage*(0.16+g.upgrade_ranks[5]*0.04),"life":2.4,"bomb":false})
	while zones.size()>20: zones.pop_front()

func projectile_power(g, b: Dictionary, e: Dictionary) -> float:
	var power: float = b.get("power",g.damage)
	if b.get("scatter",false) and e.p.distance_to(b.get("origin",g.player))<160: power *= 1.2
	if int(b.get("needle",0))>0:
		var stacks: int = int(e.get("needle_stacks",0)) if float(e.get("needle_until",0))>g.elapsed else 0
		power *= 1.0+stacks*0.04
		e.needle_stacks = mini(2+int(b.needle),stacks+1)
		e.needle_until = g.elapsed+2.0
	if b.get("thump",0)>0:
		queue_pulse(e.p,65+b.thump*5,g.damage*(0.35+b.thump*0.07),Color("c4a4d4"))
		b.thump = 0 # A piercing explosive seed detonates only once.
	return power

func advance(g, dt: float) -> void:
	for i in range(rings.size()-1,-1,-1):
		rings[i].life -= dt
		if rings[i].life<=0: rings.remove_at(i)
	if not echo.is_empty():
		echo.delay -= dt
		if echo.delay<=0:
			if g.roll_time<=0 and not g.enemies.is_empty():
				for b in echo.shots:
					b.p = g.scout_muzzle(b.v.normalized())
					b.origin = b.p
					g.bullets.append(b)
			echo = {}
	if banked and not g.enemies.is_empty() and g.boss_warning<=0:
		banked = false
		for i in range(8):
			var dir = Vector2.from_angle(i*TAU/8)
			g.bullets.append({"p":g.player,"v":dir*500,"life":0.6,"power":g.damage*(0.65+g.upgrade_ranks[3]*0.12),"pierce":1,"hit_ids":[],"visual":g.upgrade_ranks.duplicate()})
	for i in range(zones.size()-1,-1,-1):
		var z = zones[i]
		z.life -= dt
		if z.bomb and z.life<=0: queue_pulse(z.p,z.radius,z.power,Color("efc77a"))
		if not z.bomb:
			for e in g.enemies:
				if g.enemy_targetable(e) and e.p.distance_to(z.p)<z.radius+e.radius and g.clear_line(z.p,e.p) and float(e.get("trail_tick",0))<=g.elapsed:
					e.trail_tick = g.elapsed+0.5 # Overlapping trails never multiply DPS.
					e.skill_pending = float(e.get("skill_pending",0))+z.power
		if z.life<=0: zones.remove_at(i)
	for pulse in pulses:
		if rings.size()<24: rings.append({"p":pulse.p,"radius":pulse.radius,"color":pulse.color,"life":0.3})
		for e in g.enemies:
			if g.enemy_targetable(e) and e.p.distance_to(pulse.p)<pulse.radius+e.radius and g.clear_line(pulse.p,e.p):
				e.skill_pending = float(e.get("skill_pending",0))+pulse.power
	pulses.clear()
	for i in range(g.enemies.size()-1,-1,-1):
		var e = g.enemies[i]
		var power: float = e.get("skill_pending",0)
		e.skill_pending = 0.0
		if power<=0 or not g.enemy_targetable(e): continue
		if e.kind==9 and e.mode=="brace": power *= 0.7
		if g.run_growth[14]>0 and g.Tuning.is_major(e.kind): power *= 1.2
		if e.get("finale",false) and e.mode=="recover": power *= 1.35
		g.damage_dealt += minf(power,e.hp)
		g.mark_enemy_hit(e,minf(power,e.hp))
		e.hp -= power
		e.flash = 0.1
		if e.hp<=0:
			g.kill_enemy(i)
			if g.boss_defeat_timer>0: return

func draw(g) -> void:
	# Gameplay footprints remain visible even on battery/reduced-effects modes.
	for z in zones:
		if z.bomb:
			g.draw_arc(z.p,z.radius,0,TAU,24,Color(0.9,0.72,0.35,0.6),2,true)
			g.draw_circle(z.p,7,Color("715035"))
			g.draw_circle(z.p,4+sin(z.life*25),Color("ebc576"))
		else:
			g.draw_circle(z.p,z.radius,Color(0.33,0.47,0.17,0.18))
			for j in range(4):
				var p: Vector2 = z.p+Vector2.from_angle(j*2.4)*14
				g.draw_line(p+Vector2(-5,3),p+Vector2(0,-5),Color("6c7d3e"),2,true)
				g.draw_line(p+Vector2(5,3),p+Vector2(0,-5),Color("6c7d3e"),2,true)
	for r in rings:
		g.draw_arc(r.p,r.radius*(1-r.life/0.3),0,TAU,24,Color(r.color,r.life/0.3),2,true)
	if g.upgrade_ranks[2]>0:
		for i in range(3):
			g.draw_circle(g.player+Vector2(-8+i*8,-43),2.5,Color("f2ca73") if volleys%4>i else Color("675b3d"))
	for e in g.enemies:
		if float(e.get("needle_until",0))>g.elapsed:
			g.draw_arc(e.p,e.radius+3,-0.7,0.7,10,Color("8ddbd1"),2,true)
