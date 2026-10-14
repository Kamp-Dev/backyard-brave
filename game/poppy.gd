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
	if b.returning:
		b.v = b.p.direction_to(g.player)*620.0
		var next: Vector2 = b.p+b.v*dt
		if g.Combat.hit_fraction(b.p,next,g.player,20)<INF:
			if b.catchable and g.roll_time>0 and b.age>0.35:
				empowered = true # One banked charge, never a stacking multiplier.
				catch_notice = 0.9
				catches += 1
				g.tone(660,0.045)
			return true
	return false

func portrait(g, rect: Rect2) -> void:
	setup()
	var region = regions[0]
	var size = region.size*(rect.size.y/region.size.y)
	g.draw_texture_rect_region(ART,Rect2(Vector2(rect.get_center().x-size.x/2,rect.position.y),size),region)

func gait(g) -> Vector2:
	# Distance, not time or attack state: blocked/idle feet stop immediately.
	if not g.player_moving: return Vector2.ZERO
	var phase: float = g.walk_distance / g.WALK_STRIDE * TAU
	if g.scout_backpedaling(): phase = -phase
	return Vector2(sin(phase),cos(phase))

func leg_art(g, source: Rect2, anchor: Vector2, scale_factor: float, step: float, tint: Color) -> void:
	# Six-vertex leg strip. Hips stay fixed; knees and boots follow opposite steps.
	var a = source.position
	var b = source.end
	var knee = lerpf(a.y,b.y,0.48)
	var uv = PackedVector2Array([a,Vector2(b.x,a.y),Vector2(b.x,knee),b,Vector2(a.x,b.y),Vector2(a.x,knee)])
	var points = PackedVector2Array()
	var stride_scale = scale_factor*10.0
	for i in range(6):
		var point = (uv[i]-anchor)*scale_factor
		if i in [2,5]: point += Vector2(step*0.95,-absf(step)*0.4)*stride_scale
		if i in [3,4]: point += Vector2(step*3.8,-maxf(0,step)*3.2)*stride_scale
		points.append(point)
		uv[i] /= Vector2(ART.get_size())
	g.draw_polygon(points,PackedColorArray([tint]),uv,ART)

func player_art(g, origin: Vector2, rolling: bool, tint: Color = Color.WHITE) -> void:
	setup()
	var direction: Vector2 = g.roll_direction if rolling else g.scout_upper_direction()
	var frame = 2 if direction.y< -0.25 else 0
	var height: float = g.player_display_height
	var scale_factor: float = height/560.0
	var stride = gait(g) if not rolling else Vector2.ZERO
	var bob: float = absf(stride.x)*0.65
	var rotation: float = (1-g.roll_time/g.ROLL_DURATION)*TAU*(1 if direction.x>=0 else -1) if rolling else 0
	g.set_scene_transform(origin+Vector2(0,12),0,Vector2(1,0.35))
	g.draw_circle(Vector2.ZERO,12,Color(0,0,0,0.25))
	g.set_scene_transform(origin+Vector2(0,-bob),rotation,Vector2(-1 if direction.x<0 else 1,1))
	var rear = frame==2
	var anchor = Vector2(350,1208) if rear else Vector2(320,617)
	anchor.y -= 16/scale_factor
	var left_leg = Rect2(224,1038,127,170) if rear else Rect2(189,459,128,158)
	var right_leg = Rect2(351,1038,161,170) if rear else Rect2(317,459,165,158)
	leg_art(g,left_leg,anchor,scale_factor,stride.x,tint)
	leg_art(g,right_leg,anchor,scale_factor,-stride.x,tint)
	# Only the torso changes on release; neither the gait nor body scale resets.
	var release: bool = g.attack_phase=="release" and not rolling
	if release: frame+=1
	var region = regions[frame]
	var torso_anchor = anchor
	var cut: float = 1042 if rear else 463
	if release:
		torso_anchor += Vector2(588,4) if rear else Vector2(618,9)
		cut += 4 if rear else 9
	region.size.y = cut-region.position.y
	g.draw_texture_rect_region(ART,Rect2((region.position-torso_anchor)*scale_factor,region.size*scale_factor),region,tint)
	g.set_scene_transform(Vector2.ZERO)

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
