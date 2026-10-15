extends Control
## Clipped native canvas: 100 envelopes, bottom first. Only visible rows draw.
const VINE = preload("res://assets/ui/acorn-vine-card.png")
const ART = preload("res://assets/ui/growth-album.png")
const CLOSED_ART = preload("res://assets/ui/growth-album-closed.png")
const WAX_SEAL = preload("res://assets/ui/scout-wax-seal.png")
const ENVELOPE = Rect2(16,105,858,415)
const RIBBON = Rect2(877,58,371,1151)
const BANNER = Rect2(12,572,868,301)
const ACORN = Rect2(249,890,395,340)
const INK = Color("352e23")
const GREEN = Color("587345")
var host: Node2D
var emphasis: Array[float] = []
var glow: GradientTexture2D
var hover_point = Vector2.INF
var hovered_id = -1

func _ready() -> void:
 emphasis.resize(110)
 emphasis.fill(0.0)
 glow = GradientTexture2D.new()
 glow.width = 128
 glow.height = 128
 glow.fill = GradientTexture2D.FILL_RADIAL
 glow.fill_from = Vector2(0.5,0.5)
 glow.fill_to = Vector2(1.0,0.5)
 var gradient = Gradient.new()
 gradient.offsets = PackedFloat32Array([0.0,0.45,0.75,1.0])
 gradient.colors = PackedColorArray([Color(1.0,0.87,0.40,0.6),Color(1.0,0.87,0.40,0.42),Color(1.0,0.9,0.55,0.18),Color(1.0,0.9,0.55,0.0)])
 glow.gradient = gradient
 clip_contents = true
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _process(delta: float) -> void:
 if not visible or not is_instance_valid(host):
  hover_point = Vector2.INF
  hovered_id = -1
  return
 hovered_id = -1
 if host.growth_drag_id==-2 and Rect2(Vector2.ZERO,size).has_point(hover_point):
  for id in range(110):
   if host.growth_node_rect(id).has_point(hover_point+host.GROWTH_VIEW.position):
    hovered_id = id
    break
 for id in range(110):
  var target = 1.0 if host.growth_selected==id or hovered_id==id else 0.0
  emphasis[id] = move_toward(emphasis[id],target,minf(delta,0.05)*8.0)
 queue_redraw()

func begin_emphasis(rect: Rect2, amount: float) -> void:
 var factor = 1.0+0.035*amount
 var center = rect.get_center()
 draw_set_transform(center*(1.0-factor),0,Vector2.ONE*factor)
 if amount>0.001:
  draw_texture_rect(glow,rect.grow(24),false,Color(1,1,1,amount))

func part(rect: Rect2, source: Rect2, color: Color = Color.WHITE) -> void:
 draw_texture_rect_region(ART,rect,source,color)

func label_at(point: Vector2, value: String, font_size: int = 20, color: Color = INK, width: float = -1) -> void:
 draw_string(host.heading_font,point,value,HORIZONTAL_ALIGNMENT_LEFT,width,font_size,color)

func center_label(rect: Rect2, y: float, value: String, font_size: int, color: Color = INK) -> void:
 draw_string(host.heading_font,Vector2(rect.position.x,y),value,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,font_size,color)

func draw_lock(at: Vector2, scale_factor: float = 1.0) -> void:
 draw_arc(at+Vector2(0,-5)*scale_factor,8*scale_factor,PI,TAU,18,Color("59472d"),4*scale_factor,true)
 draw_style_box(lock_style(),Rect2(at+Vector2(-11, -4)*scale_factor,Vector2(22,20)*scale_factor))
 draw_circle(at+Vector2(0,3)*scale_factor,2.5*scale_factor,INK,true,-1,true)
 draw_line(at+Vector2(0,3)*scale_factor,at+Vector2(0,9)*scale_factor,INK,2*scale_factor,true)

func lock_style() -> StyleBoxFlat:
 var style = StyleBoxFlat.new()
 style.bg_color = Color("dfc590")
 style.border_color = Color("59472d")
 style.set_border_width_all(2)
 style.set_corner_radius_all(3)
 return style

func _draw() -> void:
 if not is_instance_valid(host): return
 var model = host.growth
 for id in range(100):
  var rect: Rect2 = host.growth_node_rect(id)
  rect.position -= host.GROWTH_VIEW.position
  if not rect.intersects(Rect2(Vector2.ZERO,size)): continue
  var owned: bool = model.ranks[id]>0
  rect = rect.grow_individual(-5,-3,-5,-3)
  var tint = Color.WHITE if model.gate_met(id,host.stage_records) or owned else Color(0.87,0.86,0.78)
  begin_emphasis(rect,emphasis[id])
  if owned:
   draw_texture_rect_region(CLOSED_ART,rect,ENVELOPE,tint)
  else:
   part(rect,ENVELOPE,tint)
  var origin = rect.position
  var icon: int = model.ICONS[model.kind(id)]
  var icon_rect = Rect2(origin+Vector2(15,72 if owned else 65),Vector2(53,53))
  draw_texture_rect(host.STORY_NAVIGATION,icon_rect,false,tint)
  if icon>=0:
   var region: Rect2 = host.STORY_ICONS[icon]
   var icon_size = region.size*(48.0/maxf(region.size.x,region.size.y))
   draw_texture_rect_region(host.STORY_SKILLS,Rect2(icon_rect.get_center()-icon_size/2,icon_size),region,tint)
  else:
   var points = PackedVector2Array()
   for i in range(32):
    var t = i*TAU/32
    points.append(icon_rect.get_center()+Vector2(16*pow(sin(t),3),-(13*cos(t)-5*cos(2*t)-2*cos(3*t)-cos(4*t))))
   draw_colored_polygon(points,Color("f5dfb0"))
   draw_polyline(points+PackedVector2Array([points[0]]),INK,1.5,true)
  label_at(origin+Vector2(76,86 if owned else 73),model.name_for(id),20)
  label_at(origin+Vector2(76,112 if owned else 102),"Level %d" % (id+1),20,GREEN)
  var status: String = model.status(id,host.stage_records)
  label_at(origin+Vector2(76,141 if owned else 136),"%d Packets" % model.cost(id) if status=="READY" else status,17)
  var stamp = Rect2(origin+Vector2(291,89),Vector2(38,38))
  if owned:
   # Seal spans the folded flap seam; learned rows always reload closed.
   draw_texture_rect(WAX_SEAL,Rect2(origin+Vector2(283,42),Vector2(42,42)),false)
  elif not model.gate_met(id,host.stage_records):
   draw_lock(stamp.get_center(),0.7)
  else:
   draw_texture_rect(WAX_SEAL,stamp,false,Color(1,1,1,0.25))
  draw_set_transform(Vector2.ZERO)
 draw_merit_vine()
 draw_scroll_track(348,host.envelope_scroll,host.growth_max_scroll(0))

func draw_scroll_track(x: float, offset: float, maximum: float) -> void:
 draw_line(Vector2(x,8),Vector2(x,size.y-8),Color("baa577"),1,true)
 var thumb_y = lerpf(size.y-42,8,offset/maximum)
 draw_line(Vector2(x,thumb_y),Vector2(x,thumb_y+34),GREEN,3,true)

func draw_merit_vine() -> void:
 draw_continuous_vine()
 var model = host.growth
 for id in range(109,99,-1):
  var rect: Rect2 = host.growth_node_rect(id)
  rect.position -= host.GROWTH_VIEW.position
  if not rect.intersects(Rect2(Vector2.ZERO,size)): continue
  var owned: bool = model.ranks[id]>0
  var unlocked: bool = model.gate_met(id,host.stage_records)
  begin_emphasis(rect,emphasis[id])
  draw_texture_rect_region(VINE,rect,Rect2(0,30,1086,1280),Color.WHITE if unlocked else Color(0.87,0.88,0.79))
  var y = rect.position.y
  center_label(rect,y+57,"Growth %d" % model.GATES[id-100],17)
  var badge = Rect2(rect.get_center().x-28,y+65,56,48)
  part(badge,ACORN)
  if owned:
   draw_texture_rect(WAX_SEAL,Rect2(rect.get_center().x+32,y+80,30,30),false)

  var title: String = model.name_for(id)
  var title_size = 18
  while host.heading_font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,title_size).x>114 and title_size>11: title_size-=1
  center_label(rect,y+137,title,title_size)
  var detail: String = model.detail_for(id)
  var lines: Array[String] = []
  var line = ""
  for word in detail.split(" "):
   if host.heading_font.get_string_size(line+" "+word,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x>110:
    lines.append(line)
    line = ""
   line += (" " if not line.is_empty() else "")+word
  lines.append(line)
  for i in range(mini(lines.size(),4)):
   center_label(rect,y+156+i*16,lines[i] if i<3 or lines.size()<=4 else lines[i]+"…",14)
  center_label(rect,y+236,"Earned" if owned else "NEXT / Tap for goals" if id==model.next_reward() else "Tap for requirements",10,GREEN)
  draw_set_transform(Vector2.ZERO)
 draw_scroll_track(581,host.acorn_scroll,host.growth_max_scroll(1))

func draw_continuous_vine() -> void:
 # Sample one continuous stem in scroll-space. Cards float above it; no tiled ends.
 var wood = PackedVector2Array()
 var highlight = PackedVector2Array()
 var tendril = PackedVector2Array()
 for y in range(-24,int(size.y)+25,4):
  var phase = (float(y)-host.acorn_scroll)/75.0
  var x = 468+sin(phase)*9
  wood.append(Vector2(x,y))
  highlight.append(Vector2(x-3,y))
  tendril.append(Vector2(x+sin(phase*2.0)*5,y))
 draw_polyline(wood,Color("302d18"),16,true)
 draw_polyline(wood,Color("94602e"),11,true)
 draw_polyline(highlight,Color("c4934d"),5,true)
 draw_polyline(tendril,Color("294521"),10,true)
 draw_polyline(tendril,Color("668d2e"),6,true)
