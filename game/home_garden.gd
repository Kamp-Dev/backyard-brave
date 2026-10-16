extends RefCounted
## Bounded menu-only ambience. No combat RNG, nodes, timers or accumulating particles.
const DAY = preload("res://assets/ui/pollinator-garden.png")
const NIGHT = preload("res://assets/ui/firefly-garden.png")
var clock = 0.0
var light: GradientTexture2D

func _init() -> void:
 light=GradientTexture2D.new()
 light.width=32
 light.height=32
 light.fill=GradientTexture2D.FILL_RADIAL
 light.fill_from=Vector2(0.5,0.5)
 light.fill_to=Vector2(1,0.5)
 var gradient=Gradient.new()
 gradient.colors=PackedColorArray([Color(1,0.86,0.4,0.22),Color(1,0.86,0.4,0)])
 light.gradient=gradient

func advance(delta: float) -> void:
 clock+=minf(delta,0.05)

func paint(canvas: Node2D) -> void:
 var bounds=Rect2(-canvas.ui_offset(),canvas.get_viewport_rect().size)
 var night=canvas.settings.values.dark_mode
 var texture=NIGHT if night else DAY
 var scale=maxf(bounds.size.x/texture.get_width(),bounds.size.y/texture.get_height())
 var size=texture.get_size()*scale
 canvas.draw_texture_rect(texture,Rect2(bounds.get_center()-size/2,size),false)
 var quiet=canvas.settings.values.low_graphics or canvas.settings.values.reduced_vfx
 var t=0.0 if quiet else clock
 # A few foreground leaves move independently; the painted scenery stays still.
 for i in range(6):
  var side=-1 if i%2==0 else 1
  var x=bounds.position.x+17 if side==-1 else bounds.end.x-17
  var at=Vector2(x,bounds.position.y+bounds.size.y*(0.12+float(i/2)*0.36))
  var direction=Vector2(-side*0.8,-0.7).rotated(sin(t*0.65+i)*0.07)
  leaf(canvas,at,direction,30,Color("42635b") if night else Color("8baf60"))
 if quiet: return
 if night:
  # Five slow lights on the margins. Reduced flashes keeps their glow steady.
  for i in range(5):
   var x=bounds.position.x+27 if i%2==0 else bounds.end.x-27
   var at=Vector2(x+sin(t*0.29+i*2)*13,bounds.position.y+bounds.size.y*(0.16+i*0.17)+sin(t*0.21+i)*20)
   var alpha=0.7 if canvas.settings.values.reduced_flashes else 0.55+0.2*sin(t*0.55+i*1.8)
   canvas.draw_texture_rect(light,Rect2(at-Vector2(20,20),Vector2(40,40)),false,Color(1,1,1,alpha))
   canvas.draw_circle(at,2.1,Color(1,0.88,0.47,alpha),true,-1,true)
 else:
  # Four petals only, constrained to side borders behind the UI.
  for i in range(4):
   var phase=fposmod(t/(24.0+i*3)+i*0.24,1.0)
   var x=bounds.position.x+27 if i%2==0 else bounds.end.x-27
   var at=Vector2(x+sin(t*0.5+i)*14,bounds.position.y+phase*bounds.size.y)
   var alpha=sin(phase*PI)*0.65
   canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(-4,0),at+Vector2(0,-6),at+Vector2(5,-2),at+Vector2(3,3)]),Color(0.91,0.62,0.64,alpha))
  # A bee and butterfly take turns visiting the top canopy every 28 seconds.
  var cycle=fposmod(t,28.0)
  if cycle<10.0:
   var phase=cycle/10.0
   var at=bounds.position+Vector2(lerpf(-25,bounds.size.x+25,phase),48+sin(phase*TAU)*14)
   pollinator(canvas,at,int(t/28.0)%2==1,t)

func pollinator(canvas: Node2D, at: Vector2, butterfly: bool, t: float) -> void:
 canvas.set_scene_transform(at,0.12*sin(t*2))
 var wing=0.55+0.35*absf(sin(t*(6 if butterfly else 12)))
 if butterfly:
  for side in [-1,1]:
   canvas.draw_colored_polygon(PackedVector2Array([Vector2.ZERO,Vector2(side*12*wing,-10),Vector2(side*15*wing,-3),Vector2(side*7*wing,5),Vector2(side*10*wing,10),Vector2(0,5)]),Color("cc9863"))
  canvas.draw_line(Vector2(0,-5),Vector2(0,8),Color("53412d"),3,true)
 else:
  canvas.set_scene_transform(at,0,Vector2(1,wing))
  canvas.draw_circle(Vector2(-3,-6),5,Color(0.92,0.93,0.77,0.7),true,-1,true)
  canvas.draw_circle(Vector2(4,-6),5,Color(0.92,0.93,0.77,0.7),true,-1,true)
  canvas.set_scene_transform(at)
  canvas.draw_circle(Vector2.ZERO,6,Color("c7a34b"),true,-1,true)
  canvas.draw_line(Vector2(-2,-5),Vector2(-2,5),Color("574732"),2,true)
  canvas.draw_circle(Vector2(6,0),3,Color("574732"),true,-1,true)
 canvas.set_scene_transform(Vector2.ZERO)

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
