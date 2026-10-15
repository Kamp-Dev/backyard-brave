extends RefCounted
# Character-exclusive mechanics. All secondary damage is queued and cannot proc itself.
const MAX_ZONES=20
const MAX_SHOTS=80
var volleys=0
var gathered=0
var banked=false
var travel=0.0
var echo: Dictionary={}
var zones: Array=[]
var pulses: Array=[]
var rings: Array=[]
var pending_shots: Array=[]
var timers={"moth":3.0,"bee":2.0,"roots":3.0,"decoy":3.0,"dew":0.0,"guard":0.0,"seed_guard":0.0}
var next_zone=0
var temp_guard=0.0
var bark_ready=false
var quickdraw=false
var counter_ready=false
var quick_near_miss=false
var petals_banked=0
var parry_petals=0
var bee_visits=0
var bee_point=Vector2.ZERO
var combo_notice=""
var combo_time=0.0
var active_combos: Array[int]=[]

func rank(g,i:int) -> int: return g.upgrade_ranks[i]
func paired(g,i:int) -> bool: return g.skill_catalog.combo(g,i)
func push_zone(kind:String,p:Vector2,radius:float,life:float,power:float=0.0) -> Dictionary:
	next_zone+=1
	var z={"id":next_zone,"kind":kind,"p":p,"radius":radius,"life":life,"power":power,"tick":0.0,"hits":[],"used":false}
	zones.append(z)
	while zones.size()>MAX_ZONES: zones.pop_front()
	return z
func count_zone(kind:String) -> int:
	var n=0
	for z in zones:
		if z.kind==kind: n+=1
	return n
func trim_kind(kind:String,limit:int):
	while count_zone(kind)>limit:
		for i in range(zones.size()):
			if zones[i].kind==kind:
				zones.remove_at(i)
				break
func queue_pulse(p:Vector2,radius:float,power:float,color:Color):
	if pulses.size()<24: pulses.append({"p":p,"radius":radius,"power":power,"color":color})
func shot(g,p:Vector2,dir:Vector2,power:float,pierce:int=0,extra:Dictionary={}) -> Dictionary:
	var b={"p":p,"origin":p,"v":dir.normalized()*640,"life":0.9,"power":power,"pierce":pierce,"hit_ids":[],"secondary":true,"visual":[]}
	b.merge(extra,true)
	if pending_shots.size()<24: pending_shots.append(b)
	return b
func nearest(g,p:Vector2,exclude:Array=[],marked:bool=false) -> Dictionary:
	var best:Dictionary={}
	var distance=420.0*420.0
	for e in g.enemies:
		if not g.enemy_targetable(e) or exclude.has(e.uid) or not g.clear_line(p,e.p): continue
		if marked and float(e.get("pollen_until",0))<=g.elapsed and float(e.get("trail_mark",0))<=g.elapsed: continue
		var d:float=p.distance_squared_to(e.p)
		if d<distance:
			distance=d
			best=e
	return best
func pending(e:Dictionary,power:float): e.skill_pending=float(e.get("skill_pending",0))+power
func slow(g,e:Dictionary,duration:float=0.65):
	# Boss slows have a refractory period and never alter attack telegraph timers.
	if g.Tuning.is_major(e.kind) or e.get("finale",false):
		if g.elapsed<float(e.get("slow_resist_until",0)): return
		e.slow_resist_until=g.elapsed+3.0
		duration=minf(duration,0.6)
		e.slow_factor=0.8
	else: e.slow_factor=0.55
	e.slow_until=maxf(float(e.get("slow_until",0)),g.elapsed+duration)
func shove(g,e:Dictionary,dir:Vector2,amount:float):
	if g.Tuning.is_major(e.kind) or e.get("finale",false) or e.mode=="rush": return
	e.p=g.move_actor(e.p,dir.normalized()*amount,e.radius)

func learned(g,kind:int):
	if g.run_character==1 and kind==2 and rank(g,2)==1: timers.moth=3.0
	if g.run_character==1 and kind==8 and rank(g,8)==1: timers.roots=3.0
	if g.run_character==0 and kind==1 and rank(g,1)==1: timers.decoy=3.0
	if g.run_character==0 and kind==6 and rank(g,6)==1:
		bark_ready=true
		g.shield=mini(g.guard_capacity(),g.shield+1)
	for i in range(5):
		if paired(g,i) and not active_combos.has(i):
			active_combos.append(i)
			combo_notice=g.skill_catalog.kit(g).combos[i][2]
			combo_time=2.2
	# Acquiring/upgrading a skill never restarts its live cooldown.

func on_roll(g):
	if g.run_character==1:
		if rank(g,3)>0 and timers.dew<=0:
			push_zone("dew",g.player,65,6)
			trim_kind("dew",2)
			timers.dew=8.0
		if rank(g,7)>0:
			for i in range(3):
				push_zone("petal",g.player-g.roll_direction*float(12+i*17)+g.roll_direction.orthogonal()*float((i-1)*12),17,4,g.damage*0.5)
			trim_kind("petal",9)
	else:
		quickdraw=rank(g,5)>0
		if rank(g,2)>0:
			var z=push_zone("line",g.player,60,7,g.damage*1.0)
			z.end=g.constrain_actor(g.player+g.roll_direction*100,8)
			z.charges=2 if rank(g,2)>=3 else 1
			trim_kind("line",3)

func on_near_miss(g):
	if g.run_character==0 and rank(g,7)>0: counter_ready=true
	if g.run_character==0 and rank(g,5)>=3: quick_near_miss=true

func on_guard(g):
	if g.run_character==1:
		if temp_guard>0:
			temp_guard=0
			if rank(g,6)>=2: queue_pulse(g.player,100,g.damage*0.9,Color("e4b4a1"))
			if rank(g,6)>=3 and timers.seed_guard<=0:
				add_seed(g,g.player+g.player_aim*70)
				timers.seed_guard=6.0
	else:
		bark_ready=false
		timers.guard=20.0
		if rank(g,6)>=2:
			for e in g.enemies:
				if e.p.distance_to(g.player)<100: shove(g,e,e.p-g.player,30)
			if rings.size()<24: rings.append({"p":g.player,"radius":100,"color":Color("b8a676"),"life":0.3})
		if rank(g,6)>=3:
			for side in [-1,1]: push_zone("bark",g.player+Vector2(side*35,0),20,2)
		if paired(g,3) and counter_ready: fire_counter(g)
func on_hurt(g):
	if g.run_character==0 and rank(g,6)>0: timers.guard=20.0
func on_pickup(g):
	if g.run_character!=0 or rank(g,8)<=0: return
	gathered+=1
	if gathered>=8:
		gathered-=8
		banked=true
func after_move(g,previous:Vector2):
	if g.run_character!=1 or rank(g,3)<3: return
	for z in zones:
		if z.kind=="dew" and not z.used and previous.distance_to(z.p)<z.radius and g.player.distance_to(z.p)>=z.radius:
			z.used=true
			var e=nearest(g,g.player)
			if not e.is_empty(): queue_pulse(e.p,42,g.damage*0.65,Color("99c2bc"))

func add_seed(g,p:Vector2):
	var z=push_zone("seed",p,85,5,g.damage*0.65)
	z.tick=0.15
	trim_kind("seed",3)
func on_turn(g,b:Dictionary):
	if not b.get("catchable",false): return
	if b.get("plant",false): add_seed(g,b.p)
func on_catch(g,b:Dictionary,rolled:bool):
	if not rolled: return
	if rank(g,6)>0:
		if temp_guard<=0 and g.shield<g.guard_capacity():
			g.shield+=1
			temp_guard=3.0
		elif temp_guard>0: temp_guard=3.0
	if paired(g,3):
		for z in zones:
			if z.kind=="petal" and z.life>0 and z.p.distance_to(g.player)<130:
				z.life=0
				petals_banked=mini(6,petals_banked+1)
		parry_petals=mini(6,parry_petals+petals_banked)
		petals_banked=0
	elif rank(g,7)>=3:
		if petals_banked>0:
			var num=mini(6,petals_banked)
			for i in range(num): shot(g,g.player,Vector2.from_angle(i*TAU/num),g.damage*0.5)
			petals_banked=0

func fire_counter(g):
	var e=nearest(g,g.player)
	if e.is_empty(): return
	counter_ready=false
	shot(g,g.player,e.p-g.player,g.damage*2.4,1 if rank(g,7)>=2 else 0,{"counter":true})

func make_volley(g,dir:Vector2) -> Array:
	volleys+=1
	var result=[]
	if g.run_character==1:
		var powered:bool=g.poppy.empowered
		g.poppy.empowered=false
		var b={"p":g.scout_muzzle(dir),"origin":g.player,"v":dir*560,"life":2.6,"power":g.damage,"pierce":99,"hit_ids":[],"visual":[],"plant":rank(g,0)>0 and volleys%4==0,"fan":rank(g,5)>0 and volleys%3==0}
		g.poppy.prepare(g,b,true,powered)
		if parry_petals>0:
			for i in range(parry_petals): shot(g,g.player,dir.rotated((i-(parry_petals-1)/2.0)*0.18),g.damage*0.5)
			parry_petals=0
		result.append(b)
	else:
		var fan:bool=rank(g,4)>0 and volleys%6==0
		var number:int=5 if fan else 1
		for i in range(number):
			var aim=dir.rotated((i-(number-1)/2.0)*0.19)
			var b={"p":g.scout_muzzle(dir),"origin":g.player,"v":aim*720,"life":0.8 if fan else 1.4,"power":g.damage*(0.75 if fan else 1.0),"pierce":0,"hit_ids":[],"visual":[],"bounces":1 if rank(g,0)>0 else 0,"fan_shot":fan,"mark_shot":rank(g,3)>0 and volleys%4==0,"quick":quickdraw,"bounce_bonus_used":false}
			if fan and rank(g,4)>=3 and i==number-1: b.pierce=1
			if quickdraw:
				b.power*=1.8
				b.pierce=2 if rank(g,5)>=2 else 1
				if rank(g,5)>=3 and quick_near_miss and i==0: shot(g,g.player,aim,g.damage*0.6)
			result.append(b)
		quickdraw=false
		quick_near_miss=false
		if counter_ready: fire_counter(g)
	return result

func projectile_power(g,b:Dictionary,e:Dictionary) -> float:
	if g.run_character==0 and b.get("ricochet",false): g.mastery.signature += 1
	var power:float=b.get("power",g.damage)
	if b.get("counter",false):
		if rank(g,7)>=2:
			slow(g,e,0.65)
			if not g.Tuning.is_major(e.kind) and not e.get("finale",false):
				e.slow_factor=0.0
				e.slow_until=g.elapsed+0.35
		if rank(g,7)>=3: e.counter_mark=g.elapsed+3.0
	if b.get("secondary",false): return power
	if g.run_character==1:
		e.visited_until=g.elapsed+4.0
		if float(e.get("weak_until",0))>g.elapsed:
			power*=1.25
			e.weak_until=0.0
		if rank(g,1)>0:
			if not b.get("returning",false): e.pollen_until=g.elapsed+3.0
			elif float(e.get("pollen_until",0))>g.elapsed:
				e.pollen_until=0.0
				queue_pulse(e.p,54,g.damage*0.8,Color("e5c777"))
				if rank(g,1)>=2:
					var other=nearest(g,e.p,[e.uid])
					if not other.is_empty() and other.p.distance_to(e.p)<110: other.pollen_until=g.elapsed+3.0
				if rank(g,1)>=3: e.weak_until=g.elapsed+2.0
	else:
		if b.get("mark_shot",false): e.trail_mark=g.elapsed+3.0
		elif float(e.get("trail_mark",0))>g.elapsed:
			power*=1.5
			if rank(g,3)>=3 and (g.Tuning.is_major(e.kind) or e.get("finale",false)): slow(g,e,0.6)
		if paired(g,0) and b.get("ricochet",false) and float(e.get("trail_mark",0))>g.elapsed and not b.get("return_done",false):
			var marked_target=nearest(g,e.p,[e.uid],true)
			if not marked_target.is_empty():
				b.return_done=true
				shot(g,e.p,marked_target.p-e.p,g.damage*0.45,0,{"return_done":true})
		var remaining:int=b.get("bounces",0)
		var marked:bool=float(e.get("trail_mark",0))>g.elapsed
		if marked and rank(g,0)>=2 and not b.get("bounce_bonus_used",false):
			remaining+=1
			b.bounce_bonus_used=true
		if remaining>0:
			var exclude:Array=b.hit_ids.duplicate()
			exclude.append(e.uid)
			var target=nearest(g,e.p,exclude)
			if not target.is_empty():
				shot(g,e.p,target.p-e.p,power*0.8,0,{"secondary":false,"ricochet":true,"bounces":remaining-1,"hit_ids":exclude,"bounce_bonus_used":b.get("bounce_bonus_used",false),"split_done":b.get("split_done",false),"return_done":b.get("return_done",false)})
		elif rank(g,0)>=3 and not b.get("split_done",false):
			for side in [-0.4,0.4]: shot(g,e.p,b.v.rotated(side),power*0.3)
			b.split_done=true
	return power

func on_kill(g,e:Dictionary):
	if g.run_character!=0: return
	if rank(g,3)>=2 and float(e.get("trail_mark",0))>g.elapsed:
		var other=nearest(g,e.p,[e.uid])
		if not other.is_empty(): other.trail_mark=g.elapsed+3.0
	if rank(g,7)>=3 and float(e.get("counter_mark",0))>g.elapsed: queue_pulse(e.p,65,g.damage*0.65,Color("dbc790"))

func on_projectile_move(g,b:Dictionary,start:Vector2):
	if b.get("secondary",false): return
	var additions=[]
	for z in zones:
		if z.life<=0: continue
		if g.Combat.hit_fraction(start,b.p,z.p,z.radius)==INF: continue
		if g.run_character==1 and b.get("returning",false):
			if z.kind=="seed" and rank(g,0)>=2 and not z.used:
				z.used=true
				queue_pulse(z.p,z.radius,z.power,Color("d6c276"))
				if rank(g,0)>=3:
					for angle in [-0.35,0,0.35]: shot(g,z.p,b.v.rotated(angle),g.damage*0.4)
			if z.kind=="petal" and rank(g,7)>=2:
				z.life=0
				petals_banked=mini(6,petals_banked+1)
				b.power+=g.damage*0.12
			if z.kind=="root" and rank(g,8)>=2 and not z.used:
				z.used=true
				queue_pulse(z.p,z.radius,g.damage*0.65,Color("a0b36a"))
			if paired(g,2) and z.kind=="scent" and b.get("fan",false) and not b.get("scent_carried",false):
				b.scent_carried=true
				additions.append({"p":b.p+b.v.normalized()*50})
		elif g.run_character==0:
			if z.kind=="decoy" and b.get("fan_shot",false) and paired(g,1): z.life=0.01; z.ambush=true
			if z.kind=="line" and b.get("fan_shot",false) and rank(g,4)>=2: z.armed=true
			if z.kind=="line" and b.get("quick",false) and paired(g,2) and not b.get("line_sweep",false):
				b.line_sweep=true
				line_damage(g,z.p,z.end,18,g.damage*1.3)
	for a in additions: push_zone("scent_lane",a.p,65,2)
	if g.run_character==1 and b.get("returning",false) and b.get("fan",false) and not b.get("fan_used",false):
		var e=nearest(g,b.p)
		if not e.is_empty() and e.p.distance_to(b.p)<85:
			b.fan_used=true
			var side:Vector2=b.v.normalized().orthogonal()
			for target in g.enemies:
				if not g.enemy_targetable(target) or target.p.distance_to(b.p)>85: continue
				shove(g,target,side*signf(side.dot(target.p-b.p)+0.01),25)
				if rank(g,5)>=2: slow(g,target)
			queue_pulse(b.p,65,g.damage*0.75,Color("c0d59c"))
			if rank(g,5)>=3:
				for sign_value in [-1,1]: queue_pulse(b.p+side*sign_value*55,40,g.damage*0.5,Color("c0d59c"))

func line_damage(g,a:Vector2,b:Vector2,radius:float,power:float):
	for e in g.enemies:
		if g.enemy_targetable(e) and g.Combat.hit_fraction(a,b,e.p,e.radius+radius)<INF and g.clear_line(a,e.p): pending(e,power)
	if rings.size()<24: rings.append({"p":(a+b)/2,"radius":a.distance_to(b)/2,"color":Color("c8ca86"),"life":0.3})

func advance(g,dt:float):
	combo_time=maxf(0,combo_time-dt)
	for key in timers: timers[key]=maxf(0,float(timers[key])-dt)
	if temp_guard>0:
		temp_guard-=dt
		if temp_guard<=0: g.shield=maxi(0,g.shield-1)
	for i in range(rings.size()-1,-1,-1):
		rings[i].life-=dt
		if rings[i].life<=0: rings.remove_at(i)
	if g.boss_warning<=0:
		if g.run_character==1: advance_poppy(g)
		else: advance_scout(g)
	advance_zones(g,dt)
	for pulse in pulses:
		if rings.size()<24: rings.append({"p":pulse.p,"radius":pulse.radius,"color":pulse.color,"life":0.3})
		for e in g.enemies:
			if g.enemy_targetable(e) and e.p.distance_to(pulse.p)<pulse.radius+e.radius and g.clear_line(pulse.p,e.p): pending(e,pulse.power)
	pulses.clear()
	for b in pending_shots:
		if g.bullets.size()<MAX_SHOTS: g.bullets.append(b)
	pending_shots.clear()
	for i in range(g.enemies.size()-1,-1,-1):
		var e=g.enemies[i]
		var power:float=e.get("skill_pending",0)
		e.skill_pending=0.0
		if power<=0 or not g.enemy_targetable(e): continue
		if e.kind==9 and e.mode=="brace": power*=0.7
		if g.run_growth[14]>0 and g.Tuning.is_major(e.kind): power*=1.2
		if e.get("finale",false) and e.mode=="recover": power*=1.35
		g.damage_dealt+=minf(power,e.hp)
		g.mark_enemy_hit(e,minf(power,e.hp))
		e.hp-=power
		e.flash=0.1
		if e.hp<=0:
			g.kill_enemy(i,false)
			if g.boss_defeat_timer>0: return

func advance_poppy(g):
	var target=nearest(g,g.player)
	if target.is_empty(): return # Hold at most one ready charge; no offscreen waste.
	if rank(g,2)>0 and timers.moth<=0:
		timers.moth=30.0
		for i in range(3):
			var p:Vector2=g.player+Vector2.from_angle(i*TAU/3)*28
			push_zone("scent",p,48,6)
		trim_kind("scent",3)
		if rank(g,2)>=2:
			for e in g.enemies:
				if e.p.distance_to(g.player)<95: shove(g,e,e.p-g.player,35)
		if rank(g,2)>=3:
			for side in [-1,1]: push_zone("scent_lane",g.player+Vector2(side*65,0),36,6)
			trim_kind("scent_lane",2)
	if rank(g,8)>0 and timers.roots<=0:
		timers.roots=12.0
		var z=push_zone("root",g.player.lerp(target.p,0.6),72,3,g.damage*1.0)
		z.forked=false
		trim_kind("root",2)
	if rank(g,4)>0 and timers.bee<=0:
		timers.bee=2.0
		var marked=nearest(g,g.player,[],true) if rank(g,4)>=2 else {}
		if not marked.is_empty(): target=marked
		else:
			for e in g.enemies:
				if g.enemy_targetable(e) and float(e.get("visited_until",0))>g.elapsed and g.clear_line(g.player,e.p):
					target=e
					break
		bee_point=target.p
		pending(target,g.damage*1.15)
		bee_visits+=1
		if paired(g,1):
			var previous:Vector2=target.p
			var used=[target.uid]
			for i in range(2):
				var next=nearest(g,previous,used,true)
				if next.is_empty(): break
				line_damage(g,previous,next.p,8,g.damage*0.8)
				previous=next.p
				used.append(next.uid)
		if rank(g,4)>=3 and bee_visits%3==0: line_damage(g,g.player,target.p,14,g.damage*1.0)

func advance_scout(g):
	if rank(g,6)>0 and not bark_ready and timers.guard<=0 and g.shield<g.guard_capacity():
		bark_ready=true
		g.shield+=1
	if banked and not g.enemies.is_empty() and g.boss_warning<=0:
		banked=false
		for i in range(8): shot(g,g.player,Vector2.from_angle(i*TAU/8),g.damage*0.65,1)
		if rank(g,8)>=2:
			for z in zones:
				if z.kind=="line" and z.p.distance_to(g.player)<210:
					z.armed=true
					if paired(g,4) and not z.get("refreshed",false): z.charges+=1; z.refreshed=true
		if rank(g,8)>=3:
			var e=nearest(g,g.player)
			if not e.is_empty(): shot(g,g.player,e.p-g.player,g.damage*0.65,0,{"secondary":false,"bounces":1,"bounce_bonus_used":true,"split_done":true,"return_done":true})
	if rank(g,1)>0 and timers.decoy<=0 and not nearest(g,g.player).is_empty():
		timers.decoy=18.0
		push_zone("decoy",g.player,80,3,g.damage*1.4)
		trim_kind("decoy",1)

func advance_zones(g,dt:float):
	var extra=[]
	for z in zones:
		z.life-=dt
		z.tick-=dt
		if z.kind=="seed":
			for water in zones:
				if water.kind!="dew" or water.p.distance_to(z.p)>water.radius: continue
				if rank(g,3)>=2 and not z.get("watered",false): z.life+=2; z.watered=true
				if paired(g,0) and count_zone("bloom")<2:
					z.kind="bloom"
					z.life=4.0
					z.tick=0.0
		if z.kind in ["seed","bloom"] and z.tick<=0:
			z.tick=1.0
			if z.kind=="bloom":
				var target=nearest(g,z.p)
				if not target.is_empty():
					for a in [-0.2,0,0.2]: shot(g,z.p,(target.p-z.p).rotated(a),g.damage*0.6)
			else: queue_pulse(z.p,z.radius,z.power,Color("b9c779"))
		if z.kind=="root" and paired(g,4) and not z.get("garden",false):
			for water in zones:
				if water.kind=="dew" and water.p.distance_to(z.p)<water.radius:
					z.garden=true
					z.radius=105.0
					z.life+=1.0
		var touched=0
		for e in g.enemies:
			if not g.enemy_targetable(e): continue
			var contact:bool=e.p.distance_to(z.p)<z.radius+e.radius
			if z.kind=="line": contact=g.Combat.hit_fraction(z.p,z.end,e.p,e.radius+12)<INF
			if not contact or not g.clear_line(z.p,e.p): continue
			touched+=1
			if z.kind in ["dew","scent","scent_lane","root"]: slow(g,e)
			if z.kind=="root" and not z.hits.has(e.uid):
				z.hits.append(e.uid)
				pending(e,z.power)
				if rank(g,8)>=3 and not z.get("forked",false):
					z.forked=true
					extra.append({"kind":"root","p":e.p+Vector2(40,0),"radius":45.0,"life":1.5,"power":g.damage*0.3})
			if z.kind=="petal" and not z.hits.has(e.uid):
				z.hits.append(e.uid)
				pending(e,z.power)
			if z.kind=="line" and z.charges>0 and z.tick<=0 and not z.hits.has(e.uid):
				z.hits.append(e.uid)
				z.charges-=1
				z.tick=0.4
				pending(e,z.power*(1.3 if z.get("armed",false) else 1.0))
				if rank(g,2)>=2:
					queue_pulse(e.p,65,g.damage*0.4,Color("b7b57c"))
					for nearby in g.enemies:
						if g.enemy_targetable(nearby) and nearby.p.distance_to(e.p)<65 and g.clear_line(e.p,nearby.p): slow(g,nearby,0.8)
			if z.kind=="decoy" and rank(g,1)>=2 and touched>=3: z.life=0.0
		if z.kind=="decoy" and z.life<=0 and rank(g,1)>=2:
			queue_pulse(z.p,90,z.power,Color("c5a76e"))
			if rank(g,1)>=3 or z.get("ambush",false):
				var count=8 if z.get("ambush",false) else 4
				for i in range(count): shot(g,z.p,Vector2.from_angle(i*TAU/count),g.damage*0.5)
		if z.kind=="bark":
			for i in range(g.hostile_bullets.size()-1,-1,-1):
				if g.hostile_bullets[i].p.distance_to(z.p)<z.radius:
					g.hostile_bullets.remove_at(i)
					z.life=0.0
					break
	for i in range(zones.size()-1,-1,-1):
		if zones[i].life<=0: zones.remove_at(i)
	for z in extra:
		var root=push_zone(z.kind,z.p,z.radius,z.life,z.power)
		root.forked=true
	trim_kind("root",2)
	trim_kind("scent_lane",2)

func lure_direction(g,e:Dictionary,direction:Vector2) -> Vector2:
	if g.run_character!=0 or g.Tuning.is_major(e.kind) or e.get("finale",false): return direction
	for z in zones:
		if z.kind=="decoy" and e.p.distance_to(z.p)<160 and g.clear_line(e.p,z.p): return e.p.direction_to(z.p)
	return direction

func draw(g):
	for z in zones:
		var color=Color("9cb371")
		if z.kind in ["dew","scent_lane"]: color=Color("91b8a7")
		elif z.kind in ["scent","petal"]: color=Color("c6b39b")
		elif z.kind in ["line","decoy","bark"]: color=Color("aa8559")
		g.draw_circle(z.p,z.radius,Color(color,0.12))
		if z.kind=="line":
			g.draw_line(z.p,z.end,color,2,true)
			for p in [z.p,z.end]: g.draw_line(p-Vector2(0,8),p+Vector2(0,6),Color("68503a"),4,true)
		elif z.kind=="root":
			g.draw_arc(z.p,z.radius*0.6,0.2,2.9,10,color,3,true)
		else:
			var icons={"seed":0,"bloom":0,"dew":3,"scent":2,"scent_lane":2,"petal":7,"decoy":1,"bark":6}
			g.skill_catalog.draw_icon(g,g.run_character,int(icons.get(z.kind,0)),Rect2(z.p-Vector2(14,20),Vector2(28,28)))
	for r in rings:
		g.draw_arc(r.p,r.radius*(1-r.life/0.3),0,TAU,20,Color(r.color,r.life/0.3),2,true)
	if g.run_character==1 and rank(g,4)>0:
		var p:Vector2=g.player+Vector2(cos(g.elapsed*3)*23,-34+sin(g.elapsed*3)*5)
		if bee_visits>0 and timers.bee>1.2: p=p.lerp(bee_point, sin((2.0-float(timers.bee))/0.8*PI))
		g.skill_catalog.draw_icon(g,1,4,Rect2(p-Vector2(12,12),Vector2(24,24)))
	for e in g.enemies:
		if float(e.get("pollen_until",0))>g.elapsed or float(e.get("trail_mark",0))>g.elapsed:
			g.draw_arc(e.p,e.radius+4,-1.2,1.2,10,Color("e3c576"),2,true)

func draw_readiness(g):
	var entries=[]
	var slots=[[2,"moth",30.0],[4,"bee",2.0],[8,"roots",12.0],[3,"dew",8.0]] if g.run_character==1 else [[1,"decoy",18.0],[6,"guard",20.0]]
	for slot in slots:
		if rank(g,slot[0])<=0: continue
		var seconds:float=timers[slot[1]]
		if g.run_character==0 and slot[0]==6 and bark_ready: seconds=0
		entries.append([slot[0],seconds])
	for i in range(entries.size()):
		var x=360+(i-(entries.size()-1)/2.0)*63
		g.skill_catalog.draw_icon(g,g.run_character,entries[i][0],Rect2(x-15,243,30,30))
		var label="READY" if entries[i][1]<=0 else "%ds" % ceili(entries[i][1])
		g.card_text(Rect2(x-30,0,60,0),288,label,13,g.PAPER)
