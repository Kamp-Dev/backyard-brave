extends RefCounted
# Poppy shares the collision/skill pipeline, but her throws have two hit passes.
const ART = preload("res://assets/player/poppy.png")
var regions: Array[Rect2] = []
var empowered = false
var catch_notice = 0.0
var catches = 0

func setup() -> void:
	if not regions.is_empty(): return
	var image = ART.get_image()
	var cell = Vector2i(image.get_width()/2,image.get_height()/2)
	for row in range(2):
		for column in range(2):
			var origin = Vector2i(column,row)*cell
			var bounds = image.get_region(Rect2i(origin,cell)).get_used_rect()
			regions.append(Rect2(bounds.position+origin,bounds.size))

func reset() -> void:
	empowered = false
	catch_notice = 0
	catches = 0

func prepare(g, b: Dictionary, can_catch: bool, powered: bool) -> void:
	b.boomerang = true
	b.returning = false
	b.age = 0.0
	b.turn_time = 0.32 if b.get("scatter",false) else 0.48
	b.v = b.v.normalized()*560.0
	b.life = 2.6
	b.pierce = 99
	b.catchable = can_catch
	b.empowered = powered
	b.power *= 0.95 * (1.5 if powered else 1.0)

func step(g, b: Dictionary, dt: float) -> bool:
	b.age += dt
	if not b.returning and b.age>=b.turn_time:
		b.returning = true
		b.hit_ids.clear() # Each target can be struck once going out and once back.
		g.run_skills.on_turn(g,b)
	if b.returning:
		b.v = b.p.direction_to(g.player)*620.0
		var next: Vector2 = b.p+b.v*dt
		if g.Combat.hit_fraction(b.p,next,g.player,20)<INF:
			if b.catchable and g.roll_time>0 and b.age>0.35:
				empowered = true # One banked charge, never a stacking multiplier.
				catch_notice = 0.9
				catches += 1
				g.tone(660,0.045)
			g.run_skills.on_catch(g,b,b.catchable and g.roll_time>0 and b.age>0.35)
			return true
	return false

func portrait(g, rect: Rect2) -> void:
	setup()
	var region = regions[0]
	var size = region.size*(rect.size.y/region.size.y)
	g.draw_texture_rect_region(ART,Rect2(Vector2(rect.get_center().x-size.x/2,rect.position.y),size),region)

func gait(g) -> Vector2:
	return g.character_art[1].gait(g)
func player_art(g, origin: Vector2, rolling: bool, tint: Color = Color.WHITE) -> void:
	g.character_art[1].player_art(g,origin,rolling,tint)

func projectile_art(g, b: Dictionary) -> void:
	g.set_scene_transform(b.p,b.age*17)
	var points = PackedVector2Array([Vector2(-12,-6),Vector2(-2,-3),Vector2(11,-8),Vector2(7,2),Vector2(-1,6),Vector2(-10,2)])
	g.draw_colored_polygon(points,Color("efd58c") if b.empowered else Color("bc884d"))
	var outline = points.duplicate()
	outline.append(points[0])
	g.draw_polyline(outline,Color("5f442c"),1.6,true)
	g.draw_line(Vector2(-7,-1),Vector2(5,-1),Color("e8be77"),1,true)
	g.set_scene_transform(Vector2.ZERO)
	if b.returning and b.catchable:
		g.draw_arc(b.p,16,0,TAU,16,Color("e7dba4"),1.5,true)

func draw_cue(g) -> void:
	if empowered:
		g.draw_arc(g.player,25,-PI,0,20,Color("d2b45d"),2,true)
		g.text_at(g.player+Vector2(-37,-62),"POWERED",12,g.PAPER)
	elif catch_notice>0:
		g.text_at(g.player+Vector2(-40,-62),"NICE CATCH",12,g.PAPER)
	elif g.roll_timer<=0:
		for b in g.bullets:
			if b.get("boomerang",false) and b.returning and b.catchable and b.p.distance_to(g.player)<150:
				g.text_at(g.player+Vector2(-48,-62),"ROLL TO CATCH",12,g.PAPER)
				break
