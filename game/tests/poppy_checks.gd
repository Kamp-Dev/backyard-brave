extends SceneTree
func _initialize() -> void: call_deferred("run")

func fresh(g) -> void:
	g.selected_character=1
	g.start_run()
	g.obstacles.clear()
	g.enemies.clear()
	g.fire_timer=99
	g.spawn_timer=99

func target(g) -> Dictionary:
	var e=g.make_enemy(g.player+Vector2(135,0),2)
	e.hp=1000.0
	e.max_hp=1000.0
	g.enemies.append(e)
	return e

func run() -> void:
	var g=load("res://main.tscn").instantiate()
	g.screenshot_mode=true
	root.add_child(g)
	g.growth=g.ScoutGrowth.new()
	g.unlocked_stage=30
	fresh(g)
	assert(g.poppy.regions.size()==4)
	# Locomotion remains continuous through attack poses and is driven by travel.
	g.enemies.clear()
	g.facing=Vector2.RIGHT
	g.player_aim=Vector2.RIGHT
	g.locomotion_direction=Vector2.RIGHT
	g.player_moving=true
	g.walk_distance=g.WALK_STRIDE*0.25
	g.attack_phase="idle"
	var stride=g.poppy.gait(g)
	g.attack_phase="release"
	assert(g.poppy.gait(g).is_equal_approx(stride),"Throwing must not reset or replace the walk cycle")
	g.walk_distance+=g.WALK_STRIDE*0.5
	assert(is_equal_approx(g.poppy.gait(g).x,-stride.x),"Opposite half-strides alternate feet")
	g.locomotion_direction=Vector2.LEFT
	assert(is_equal_approx(g.poppy.gait(g).x,stride.x),"Retreat reverses the stride")
	g.update_locomotion(Vector2.ZERO)
	assert(g.poppy.gait(g)==Vector2.ZERO,"Blocked or idle movement plants both feet")
	fresh(g)
	var e=target(g)
	g.shoot(Vector2.RIGHT)
	var power=g.bullets[0].power
	for i in range(90): g.update_player_bullets(1.0/60)
	assert(g.bullets.is_empty() and is_equal_approx(e.hp,1000-power*2),"Boomerang hits once in each direction, without repeated contact damage")
	assert(not g.poppy.empowered,"An ordinary catch cannot empower the next throw")
	fresh(g)
	target(g)
	g.shoot(Vector2.RIGHT)
	var b=g.bullets[0]
	g.update_player_bullets(0.3)
	g.player+=Vector2(0,80)
	g.update_player_bullets(0.2)
	assert(b.returning and b.v.y>0,"Return aims at current player position")
	b.p=g.player+Vector2(25,0)
	g.roll_time=0.15
	g.update_player_bullets(0.02)
	assert(g.poppy.empowered and g.poppy.catches==1)
	g.shoot(Vector2.RIGHT)
	assert(not g.poppy.empowered and g.bullets[-1].empowered and is_equal_approx(g.bullets[-1].power,power*1.5))
	# Faster frame rates must not change damage per pass or lose a normal catch.
	for hz in [30,60,120]:
		fresh(g)
		e=target(g)
		g.shoot(Vector2.RIGHT)
		for i in range(hz*2): g.update_player_bullets(1.0/hz)
		assert(g.bullets.is_empty() and is_equal_approx(e.hp,1000-power*2))
	fresh(g)
	e=target(g)
	g.obstacles.append(g.player+Vector2(70,0))
	g.shoot(Vector2.RIGHT)
	for i in range(30): g.update_player_bullets(1.0/60)
	assert(e.hp==1000 and g.bullets.is_empty(),"Boomerangs cannot damage enemies through rocks")
	fresh(g)
	g.poppy.empowered=true
	g.start_run()
	assert(not g.poppy.empowered and g.bullets.is_empty())
	g.state="title"
	var touch=InputEventScreenTouch.new()
	touch.pressed=true
	touch.position=g.scout_profile.PORTRAIT.get_center()+g.ui_offset()
	g._unhandled_input(touch)
	assert(g.scout_profile.page=="characters")
	g.scout_profile.character_choice=0
	touch.position=g.scout_profile.NEXT.get_center()+g.ui_offset()
	g._unhandled_input(touch)
	assert(g.scout_profile.character_choice==1)
	touch.position=g.scout_profile.SELECT.get_center()+g.ui_offset()
	g._unhandled_input(touch)
	assert(g.selected_character==1)
	var button=InputEventJoypadButton.new()
	button.pressed=true
	button.button_index=JOY_BUTTON_DPAD_LEFT
	g._unhandled_input(button)
	button.button_index=JOY_BUTTON_A
	g._unhandled_input(button)
	assert(g.selected_character==0 and g.scout_profile.page=="characters")
	g.scout_profile.close()
	g.start_run()
	g.shoot(Vector2.RIGHT)
	assert(not g.bullets[0].get("boomerang",false) and g.fire_rate<0.4,"Original scout weapon is unchanged")
	print("POPPY CHECKS PASSED: two passes, moving return, roll catch, nonstacking charge, travel-driven gait, rocks, reset and touch/controller selection")
	quit()
