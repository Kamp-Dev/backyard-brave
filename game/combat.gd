extends RefCounted
## Swept collision prevents fast projectiles and dashes skipping targets.
static func hit_fraction(start: Vector2, end: Vector2, center: Vector2, radius: float) -> float:
	var offset = start - center
	if offset.length_squared() <= radius * radius:
		return 0.0
	var travel = end - start
	var a = travel.length_squared()
	if a < 0.000001:
		return INF
	var b = 2.0 * offset.dot(travel)
	var c = offset.length_squared() - radius * radius
	var discriminant = b * b - 4.0 * a * c
	if discriminant < 0:
		return INF
	var t = (-b - sqrt(discriminant)) / (2.0 * a)
	return t if t >= 0.0 and t <= 1.0 else INF
