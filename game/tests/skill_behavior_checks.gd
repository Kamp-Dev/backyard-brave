extends SceneTree
func _initialize(): call_deferred("run")
func fresh(g,character:int=0):
 g.selected_character=character
 g.start_run()
 g.obstacles.clear()
 g.enemies.clear()
 g.fire_timer=99
 g.spawn_timer=99
func target(g,p:Vector2=Vector2(100,0)) -> Dictionary:
 var e=g.make_enemy(g.player+p,2)
 e.hp=10000.0
 e.max_hp=10000.0
 g.enemies.append(e)
 return e
func give(g,kind:int,n:int):
 for step in range(g.upgrade_ranks[kind]+1,n+1):
  g.upgrade_ranks[kind]=step
  g.run_skills.learned(g,kind)
func run():
 var g=load("res://main.tscn").instantiate()
 g.screenshot_mode=true
 root.add_child(g)
 g.growth=g.ScoutGrowth.new()
 for character in [0,1]:
  fresh(g,character)
  for kind in range(9):
   var combination=g.skill_catalog.kit(g).combos[g.skill_catalog.combo_index(g,kind)]
   assert(kind==int(combination[0]) or kind==int(combination[1]),"Every unowned card names its own compatible partner")
  for kind in range(9):
   for n in range(3):
    g.upgrade_ranks[kind]=n
    var lines=g.story_description(kind)
    assert(lines.size()<=4,"Card descriptions fit four lines")
    for line in lines: assert(g.ui_font(21).get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x<=394)
   g.upgrade_ranks[kind]=0
  g.pending_levels=1
  g.show_upgrades()
  var pending=g.pending_levels
  g.reroll_skills();g.reroll_skills();g.reroll_skills()
  assert(g.rerolls==0 and g.pending_levels==pending and g.learned_skill_ranks()==0)
  for seed_value in range(100):
   g.rng.seed=seed_value
   g.upgrade_ranks.fill(0)
   g.upgrade_ranks[0]=1
   g.upgrade_ranks[2]=3
   g.show_upgrades()
   assert(g.upgrades.has(0) and not g.upgrades.has(2))
   assert(g.upgrades.size()==3 and g.upgrades[0]!=g.upgrades[1] and g.upgrades[1]!=g.upgrades[2] and g.upgrades[0]!=g.upgrades[2])
  for combo in range(5):
   g.upgrade_ranks.fill(0)
   var pair=g.skill_catalog.kit(g).combos[combo]
   give(g,int(pair[0]),2);give(g,int(pair[1]),1)
   assert(not g.skill_catalog.combo(g,combo))
   give(g,int(pair[1]),2)
   assert(g.skill_catalog.combo(g,combo))
 fresh(g)
 var e=target(g)
 var other=target(g,Vector2(130,40))
 give(g,0,1)
 g.shoot(Vector2.RIGHT)
 g.update_player_bullets(0.2)
 assert(not g.run_skills.pending_shots.is_empty(),"Bank Shot queues a bounce after contact")
 assert(g.run_skills.pending_shots[0].hit_ids.has(e.uid))
 fresh(g)
 e=target(g,Vector2(60,0))
 give(g,1,2)
 g.run_skills.timers.decoy=0
 g.run_skills.advance(g,0.01)
 assert(g.run_skills.count_zone("decoy")==1)
 assert(g.run_skills.lure_direction(g,e,Vector2.DOWN).x<0)
 var boss=g.make_enemy(g.player+Vector2(70,0),5)
 assert(g.run_skills.lure_direction(g,boss,Vector2.DOWN)==Vector2.DOWN)
 g.run_skills.advance(g,3.1)
 assert(e.hp<10000 and g.run_skills.count_zone("decoy")==0)
 fresh(g)
 e=target(g,Vector2(50,0))
 give(g,2,3)
 g.roll_direction=Vector2.RIGHT
 g.run_skills.on_roll(g)
 g.run_skills.advance(g,0.01)
 var hp=e.hp
 g.run_skills.advance(g,0.5)
 assert(e.hp==hp,"A trip line cannot re-hit the same target")
 assert(g.run_skills.zones[0].charges==1)
 fresh(g)
 e=target(g)
 give(g,3,2)
 g.run_skills.volleys=3
 g.shoot(Vector2.RIGHT)
 var b=g.bullets[0]
 var first=g.run_skills.projectile_power(g,b,e)
 assert(e.trail_mark>g.elapsed)
 assert(g.run_skills.projectile_power(g,{"power":3.0,"hit_ids":[],"v":Vector2.RIGHT},e)>first)
 fresh(g)
 give(g,4,3)
 g.run_skills.volleys=5
 g.shoot(Vector2.RIGHT)
 assert(g.bullets.size()==5 and g.bullets[-1].pierce==1)
 fresh(g)
 give(g,5,2)
 g.run_skills.on_roll(g)
 g.shoot(Vector2.RIGHT)
 assert(g.bullets[0].quick and g.bullets[0].pierce==2 and not g.run_skills.quickdraw)
 fresh(g)
 give(g,6,2)
 assert(g.shield==1)
 g.hurt_player()
 g.run_skills.advance(g,19.9)
 assert(g.shield==0)
 g.run_skills.advance(g,0.11)
 assert(g.shield==1,"Bark Guard recharges after its delay")
 fresh(g)
 e=target(g)
 give(g,7,3)
 g.run_skills.on_near_miss(g)
 g.shoot(Vector2.RIGHT)
 assert(not g.run_skills.counter_ready and g.run_skills.pending_shots[0].counter)
 fresh(g)
 give(g,8,3)
 for i in range(8): g.run_skills.on_pickup(g)
 g.run_skills.advance(g,0.01)
 assert(g.run_skills.banked and g.bullets.is_empty())
 target(g)
 g.run_skills.advance(g,0.01)
 assert(g.bullets.size()==9 and not g.run_skills.banked)
 fresh(g,1)
 give(g,0,3)
 g.run_skills.volleys=3
 g.shoot(Vector2.RIGHT)
 g.update_player_bullets(0.3)
 g.update_player_bullets(0.2)
 assert(g.run_skills.count_zone("seed")==1)
 var seed=g.run_skills.zones[0]
 var disc=g.bullets[0]
 disc.p=seed.p
 g.run_skills.on_projectile_move(g,disc,disc.p)
 assert(seed.used)
 var pulse_count=g.run_skills.pulses.size()
 g.run_skills.on_projectile_move(g,disc,disc.p)
 assert(g.run_skills.pulses.size()==pulse_count,"Each seed reacts to a return only once")
 fresh(g,1)
 e=target(g)
 other=target(g,Vector2(120,20))
 give(g,1,3)
 b={"power":3.0,"returning":false}
 g.run_skills.projectile_power(g,b,e)
 assert(e.pollen_until>0)
 b.returning=true
 g.run_skills.projectile_power(g,b,e)
 assert(e.weak_until>0 and other.pollen_until>0 and g.run_skills.pulses.size()==1)
 fresh(g,1)
 target(g)
 give(g,2,1)
 g.run_skills.advance(g,2.9)
 assert(g.run_skills.zones.is_empty())
 g.run_skills.advance(g,0.11)
 assert(g.run_skills.count_zone("scent")==3)
 var cooldown=g.run_skills.timers.moth
 give(g,2,2)
 assert(g.run_skills.timers.moth==cooldown,"Rank-up must not restart a timed skill")
 g.state="upgrade"
 g.simulate(1.0,Vector2.ZERO)
 assert(g.run_skills.timers.moth==cooldown,"Menus pause skill timers")
 fresh(g,1)
 give(g,3,2)
 g.run_skills.on_roll(g)
 g.run_skills.on_roll(g)
 assert(g.run_skills.count_zone("dew")==1)
 give(g,0,2)
 g.run_skills.add_seed(g,g.player)
 g.run_skills.advance(g,0.01)
 assert(g.run_skills.count_zone("bloom")==1,"Bloom Patch converts a watered seed")
 fresh(g,1)
 e=target(g)
 give(g,4,3)
 g.run_skills.timers.bee=0
 g.run_skills.advance(g,0.01)
 assert(e.hp<10000 and g.run_skills.bee_visits==1)
 fresh(g,1)
 e=target(g,Vector2(10,0))
 give(g,5,3)
 b={"p":g.player,"v":Vector2.RIGHT*100,"returning":true,"fan":true}
 g.run_skills.on_projectile_move(g,b,g.player)
 assert(b.fan_used and e.p.distance_to(g.player)>10 and e.slow_until>0)
 fresh(g,1)
 give(g,6,2)
 g.run_skills.on_catch(g,{},true)
 assert(g.shield==1 and g.run_skills.temp_guard==3)
 g.run_skills.on_catch(g,{},true)
 assert(g.shield==1)
 g.run_skills.advance(g,3.1)
 assert(g.shield==0,"Catch Guard expires without leaving permanent protection")
 fresh(g,1)
 give(g,7,2)
 g.run_skills.on_roll(g)
 assert(g.run_skills.count_zone("petal")==3)
 b={"p":g.player,"v":Vector2.RIGHT,"returning":true,"power":3.0}
 g.run_skills.on_projectile_move(g,b,g.player-Vector2(80,0))
 assert(g.run_skills.petals_banked>0 and b.power>3)
 fresh(g,1)
 e=target(g,Vector2(40,0))
 give(g,8,3)
 g.run_skills.timers.roots=0
 g.run_skills.advance(g,0.01)
 assert(g.run_skills.count_zone("root")<=2 and e.hp<10000 and e.slow_until>0)
 check_combinations(g)
 # Quickdraw's own near-miss rank works without owning Counterseed.
 fresh(g)
 give(g,5,3)
 target(g)
 g.run_skills.on_roll(g)
 g.run_skills.on_near_miss(g)
 g.shoot(Vector2.RIGHT)
 assert(g.run_skills.pending_shots.size()==1 and not g.run_skills.quick_near_miss)
 # A damage pulse cannot start recursive on-death skill chains.
 fresh(g)
 give(g,7,3)
 e=target(g);e.hp=1;e.counter_mark=5.0
 g.run_skills.queue_pulse(e.p,70,3,Color.WHITE)
 g.run_skills.advance(g,0.01)
 assert(g.run_skills.pulses.is_empty())
 # Arrival immunity, bounded work and reset are shared by both kits.
 fresh(g,1)
 g.waves.begin(g,10)
 boss=g.enemies[0]
 hp=boss.hp
 g.run_skills.queue_pulse(boss.p,100,100,Color.WHITE)
 g.run_skills.advance(g,0.01)
 assert(boss.hp==hp)
 for i in range(60): g.run_skills.push_zone("dew",g.player,60,3)
 assert(g.run_skills.zones.size()==20)
 fresh(g)
 assert(g.run_skills.zones.is_empty() and g.run_skills.pending_shots.is_empty() and g.run_skills.volleys==0 and g.rerolls==2)
 for character in [0,1]:
  fresh(g,character)
  g.hp=10000
  for kind in range(9): give(g,kind,3)
  for i in range(60): target(g,Vector2.from_angle(i*TAU/60)*150)
  for frame in range(300):
   if g.roll_timer<=0: g.start_roll()
   g.simulate(1.0/30,Vector2.from_angle(frame*0.03))
   while g.state=="upgrade": g.bot_upgrade()
   assert(g.bullets.size()<=80 and g.run_skills.zones.size()<=20 and g.run_skills.rings.size()<=24 and g.run_skills.pending_shots.size()<=24)
 print("SKILL BEHAVIORS PASSED: 18 exclusive tools, 10 combo requirements, offers, rerolls, timing, boss immunity, caps and reset")
 quit()

func check_combinations(g):
 fresh(g)
 give(g,0,2); give(g,3,2)
 var e=target(g)
 var other=target(g,Vector2(160,0))
 e.trail_mark=3.0; other.trail_mark=3.0
 var b={"p":e.p,"v":Vector2.RIGHT,"power":3.0,"hit_ids":[],"bounces":1,"ricochet":true}
 g.run_skills.projectile_power(g,b,e)
 assert(b.return_done and g.run_skills.pending_shots.size()==2)
 assert(g.run_skills.pending_shots[-1].return_done,"A ricochet chain carries its one-return flag")
 fresh(g)
 give(g,1,2); give(g,4,2)
 target(g)
 g.run_skills.push_zone("decoy",g.player,80,3,4.2)
 b={"p":g.player,"v":Vector2.RIGHT,"fan_shot":true}
 g.run_skills.on_projectile_move(g,b,g.player)
 g.run_skills.advance(g,0.02)
 assert(g.bullets.size()==8 and g.run_skills.count_zone("decoy")==0,"Acorn Ambush emits its wider fan")
 fresh(g)
 give(g,2,2); give(g,5,2)
 e=target(g,Vector2(50,0))
 g.roll_direction=Vector2.RIGHT
 g.run_skills.on_roll(g)
 b={"p":g.player,"v":Vector2.RIGHT,"quick":true}
 g.run_skills.on_projectile_move(g,b,g.player)
 assert(b.line_sweep and e.skill_pending>0)
 var hit=e.skill_pending
 g.run_skills.on_projectile_move(g,b,g.player)
 assert(e.skill_pending==hit,"Tripwire Volley sweeps only once per quickdraw shot")
 fresh(g)
 give(g,6,2); give(g,7,2)
 target(g)
 g.run_skills.on_near_miss(g)
 g.hurt_player()
 assert(not g.run_skills.counter_ready and g.run_skills.pending_shots.size()==1,"Bark Reprisal consumes one prepared retaliation")
 fresh(g)
 give(g,2,2); give(g,8,2)
 target(g,Vector2(200,0))
 g.run_skills.on_roll(g)
 var line=g.run_skills.zones[0]
 for i in range(8): g.run_skills.on_pickup(g)
 g.run_skills.advance(g,0.01)
 assert(line.charges==2 and line.armed)
 for i in range(8): g.run_skills.on_pickup(g)
 g.run_skills.advance(g,0.01)
 assert(line.charges==2,"Trail Network cannot refresh a line twice")
 fresh(g,1)
 give(g,1,2); give(g,4,2)
 var targets=[]
 for i in range(3):
  e=target(g,Vector2(80+i*40,0));e.pollen_until=3.0;targets.append(e)
 g.run_skills.timers.bee=0
 g.run_skills.advance(g,0.01)
 for enemy in targets: assert(enemy.hp<10000,"Pollinator Loop reaches three marked bugs")
 fresh(g,1)
 give(g,2,2); give(g,5,2)
 g.run_skills.push_zone("scent",g.player,48,6)
 b={"p":g.player,"v":Vector2.RIGHT,"returning":true,"fan":true}
 g.run_skills.on_projectile_move(g,b,g.player)
 assert(g.run_skills.count_zone("scent_lane")==1)
 g.run_skills.on_projectile_move(g,b,g.player)
 assert(g.run_skills.count_zone("scent_lane")==1)
 fresh(g,1)
 give(g,6,2);give(g,7,2)
 g.run_skills.on_roll(g)
 g.run_skills.on_catch(g,{},true)
 assert(g.run_skills.parry_petals==3 and g.shield==1 and g.run_skills.pending_shots.is_empty())
 g.shoot(Vector2.RIGHT)
 assert(g.run_skills.parry_petals==0 and g.run_skills.pending_shots.size()==3)
 g.shoot(Vector2.RIGHT)
 assert(g.run_skills.pending_shots.size()==3,"Petal Parry releases its bank exactly once")
 fresh(g,1)
 give(g,3,2);give(g,8,2)
 g.run_skills.push_zone("dew",g.player,65,6)
 var root_zone=g.run_skills.push_zone("root",g.player,72,3,2)
 g.run_skills.advance(g,0.01)
 assert(root_zone.garden and root_zone.radius==105 and root_zone.life>3)
 assert(g.move_actor(g.player,Vector2(100,0),17).distance_to(g.player)>99,"Root Garden never blocks its owner")
