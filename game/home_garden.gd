extends RefCounted
## Deterministic menu-only garden; no particles/nodes or combat RNG required.
var clock = 0.0
var sky: GradientTexture2D
var light: GradientTexture2D

func _init() -> void:
 sky = GradientTexture2D.new()
 sky.width = 64
 sky.height = 512
 sky.fill_from = Vector2(0,0)
 sky.fill_to = Vector2(0,1)
 var colors = Gradient.new()
 colors.offsets = PackedFloat32Array([0.0,0.35,1.0])
 colors.colors = PackedColorArray([Color("d8dfa6"),Color("b8ce89"),Color("b2c58d")])
 sky.gradient = colors
 light = GradientTexture2D.new()
 light.width = 128
 light.height = 128
 light.fill = GradientTexture2D.FILL_RADIAL
 light.fill_from = Vector2(0.5,0.5)
 light.fill_to = Vector2(1.0,0.5)
 var glow = Gradient.new()
 glow.colors = PackedColorArray([Color(1,0.96,0.65,0.27),Color(1,0.96,0.65,0)])
 light.gradient = glow

func advance(delta: float) -> void:
 clock = fmod(clock+minf(delta,0.05),600.0)

func paint(canvas: Node2D) -> void:
 var bounds = Rect2(-canvas.ui_offset(),canvas.get_viewport_rect().size)
 canvas.draw_texture_rect(sky,bounds,false)
 canvas.draw_texture_rect(canvas.GROUND_TEXTURE,bounds,true,Color(0.69,0.85,0.49,0.13))
 # Broad moving sun patches keep the center calm behind titles.
 for i in range(4):
  var center = bounds.position+Vector2(bounds.size.x*(0.15+i*0.27)+sin(clock*0.12+i)*60,150+i*350+sin(clock*0.09+i)*45)
  canvas.draw_texture_rect(light,Rect2(center-Vector2(240,200),Vector2(480,400)),false)
 # A wind-swayed hedge frames the outer edges, underneath all panels.
 for side in [-1,1]:
  var stem_x = bounds.position.x+8 if side==-1 else bounds.end.x-8
  var spine = PackedVector2Array()
  for point in range(45):
   spine.append(Vector2(stem_x+sin(point*0.47+clock*0.22)*5,bounds.position.y+point*bounds.size.y/44.0))
  canvas.draw_polyline(spine,Color("526d3e"),3,true)
  canvas.draw_polyline(spine+PackedVector2Array(),Color("829850"),1,true)
  for i in range(12):
   var root = Vector2(stem_x+sin((115+i*112)/bounds.size.y*44*0.47+clock*0.22)*5,bounds.position.y+115+i*112)
   var sway = sin(clock*0.9+i*0.73+side)*8
   var tip = root+Vector2(-side*(22+9*sin(i*2.0))+sway,-60-12*cos(i))
   canvas.draw_line(root,tip,Color("526d3e"),3,true)
   for branch in range(3):
    var at = root.lerp(tip,0.3+branch*0.25)
    var direction = Vector2(-side*(1 if branch%2==0 else -0.6),-0.5).normalized()
    leaf(canvas,at,direction,17+branch*3,Color("819e52") if branch%2==0 else Color("97af60"))
 # Light seeds drift across open margins; no flashes or input interception.
 for i in range(13):
  var period = 36.0+i*1.7
  var phase = fposmod(clock/period+i*0.137,1.0)
  var at = bounds.position+Vector2(fposmod(i*113.0+phase*180,bounds.size.x),bounds.size.y*(1.06-phase*1.12))
  at.x += sin(clock*0.48+i)*12
  var fade = smoothstep(0.0,0.08,phase)*(1.0-smoothstep(0.92,1.0,phase))
  canvas.draw_line(at,at+Vector2(2,7),Color(0.53,0.55,0.29,0.32*fade),1,true)
  canvas.draw_circle(at,2.2,Color(1,0.98,0.72,0.7*fade),true,-1,true)

func leaf(canvas: Node2D, origin: Vector2, direction: Vector2, length: float, color: Color) -> void:
 var across = direction.orthogonal()
 var points = PackedVector2Array()
 for i in range(17):
  var fraction = i/16.0
  var width = sin(fraction*PI)*length*0.32
  points.append(origin+direction*length*fraction+across*width)
 for i in range(16,-1,-1):
  var fraction = i/16.0
  points.append(origin+direction*length*fraction-across*sin(fraction*PI)*length*0.32)
 canvas.draw_colored_polygon(points,color)
 canvas.draw_polyline(points+PackedVector2Array([points[0]]),Color("52643b"),1.4,true)
 canvas.draw_line(origin,origin+direction*length*0.85,Color("b4c47a"),1.0,true)
