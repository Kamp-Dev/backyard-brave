extends RefCounted

# Normalized island coordinates, manually kept on the open central grass.
# Routes are deliberately independent from combat RNG and world coordinates.
var points: PackedVector2Array
var position = Vector2(0.44,0.65)
var heading = 0.0
var target_index = 1
var rest = 0.7
var distance_walked = 0.0
var clock = 0.0
var moving = false

func reset(stage: int) -> void:
	var variants = [
		PackedVector2Array([Vector2(0.44,0.65),Vector2(0.53,0.62),Vector2(0.60,0.67),Vector2(0.49,0.70)]),
		PackedVector2Array([Vector2(0.43,0.67),Vector2(0.49,0.61),Vector2(0.59,0.64),Vector2(0.54,0.70)]),
		PackedVector2Array([Vector2(0.45,0.62),Vector2(0.58,0.63),Vector2(0.57,0.70),Vector2(0.46,0.68)])
	]
	points = variants[(stage-1)%variants.size()]
	for i in range(points.size()):
		points[i].y -= 0.06
	position = points[0]
	target_index = 1
	heading = (points[1]-position).angle()
	rest = 0.7
	distance_walked = 0.0
	clock = 0.0
	moving = false

func advance(delta: float) -> void:
	if points.is_empty():
		return
	var dt = minf(delta,0.05)
	clock += dt
	moving = false
	if rest > 0.0:
		rest = maxf(0.0,rest-dt)
		return
	var direction = points[target_index]-position
	var desired = direction.angle()
	heading = rotate_toward(heading,desired,dt*3.0)
	# Turn on the spot before walking forward; don't slide sideways on corners.
	if absf(angle_difference(heading,desired)) > 0.12:
		return
	var step = minf(38.0/532.0*dt,direction.length())
	position += direction.normalized()*step
	distance_walked += step*532.0
	moving = step > 0.0
	if position.distance_to(points[target_index]) < 0.0001:
		position = points[target_index]
		target_index = (target_index+1)%points.size()
		rest = 0.55+target_index*0.17
