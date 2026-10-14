extends RefCounted
# One renderer and gait for every playable character. See ART_STYLE.md.
var art: Texture2D
var regions: Array[Rect2] = []
var anchors: Array
var legs: Array
var cuts: Array
var release_offsets: Array
var rear_faces_left = false
func _init(texture: Texture2D, scout: bool = false):
	art=texture
	rear_faces_left=scout
	anchors=[Vector2(350,617),Vector2(366,1190)] if scout else [Vector2(320,617),Vector2(350,1208)]
	legs=[Rect2(193,478,157,139),Rect2(350,478,173,139),Rect2(198,1065,168,125),Rect2(366,1065,163,125)] if scout else [Rect2(189,459,128,158),Rect2(317,459,165,158),Rect2(224,1038,127,170),Rect2(351,1038,161,170)]
	cuts=[482,1069] if scout else [463,1042]
	release_offsets=[Vector2(572,0),Vector2(568,2)] if scout else [Vector2(618,9),Vector2(588,4)]
	setup()
func setup():
	if not regions.is_empty(): return
	var image=art.get_image()
	var cell=Vector2i(image.get_width()/2,image.get_height()/2)
	for row in range(2):
		for column in range(2):
			var origin=Vector2i(column,row)*cell
			var bounds=image.get_region(Rect2i(origin,cell)).get_used_rect()
			regions.append(Rect2(bounds.position+origin,bounds.size))
func portrait(g,rect:Rect2):
	var region=regions[0]
	var size=region.size*(rect.size.y/region.size.y)
	g.draw_texture_rect_region(art,Rect2(Vector2(rect.get_center().x-size.x/2,rect.position.y),size),region)

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
		uv[i] /= Vector2(art.get_size())
	g.draw_polygon(points,PackedColorArray([tint]),uv,art)

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
	var mirror: float = -1 if direction.x<0 else 1
	if frame==2 and rear_faces_left: mirror *= -1
	g.set_scene_transform(origin+Vector2(0,-bob),rotation,Vector2(mirror,1))
	var rear = frame==2
	var anchor: Vector2 = anchors[1 if rear else 0]
	anchor.y -= 16/scale_factor
	var left_leg: Rect2 = legs[2 if rear else 0]
	var right_leg: Rect2 = legs[3 if rear else 1]
	leg_art(g,left_leg,anchor,scale_factor,stride.x,tint)
	leg_art(g,right_leg,anchor,scale_factor,-stride.x,tint)
	# Only the torso changes on release; neither the gait nor body scale resets.
	var release: bool = g.attack_phase=="release" and not rolling
	if release: frame+=1
	var region = regions[frame]
	var torso_anchor = anchor
	var cut: float = cuts[1 if rear else 0]
	if release:
		torso_anchor += release_offsets[1 if rear else 0]
		cut += release_offsets[1 if rear else 0].y
	region.size.y = cut-region.position.y
	g.draw_texture_rect_region(art,Rect2((region.position-torso_anchor)*scale_factor,region.size*scale_factor),region,tint)
	g.set_scene_transform(Vector2.ZERO)

