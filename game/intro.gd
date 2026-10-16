extends Control
# Native boot scene: real threaded loading, full-viewport art and a skippable intro.
var movie: VideoStreamPlayer
var caption: Label
var meter: ProgressBar
var skip: Button
var elapsed=0.0
var ready_to_enter=false
var entering=false
const MAIN="res://main.tscn"
func _ready():
 if OS.has_feature("web") or DisplayServer.get_name()=="headless":
  get_tree().change_scene_to_file.call_deferred(MAIN)
  return
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var poster=TextureRect.new()
 poster.texture=load("res://assets/intro/garden-poster.png")
 poster.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 poster.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 add_child(poster)
 poster.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 movie=VideoStreamPlayer.new()
 movie.stream=load("res://assets/intro/garden-intro.ogv")
 movie.expand=true
 movie.volume=0
 movie.loop=true
 add_child(movie)
 movie.play()
 var shade=ColorRect.new()
 shade.color=Color(0,0,0,0)
 shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(shade)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var title=Label.new()
 title.text="BACKYARD\nBRAVE"
 title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 title.add_theme_font_override("font",load("res://assets/fonts/breeserif.ttf"))
 title.add_theme_font_size_override("font_size",52)
 title.add_theme_color_override("font_color",Color("fff1ca"))
 title.add_theme_color_override("font_shadow_color",Color("273318"))
 title.add_theme_constant_override("shadow_offset_y",3)
 add_child(title)
 title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
 title.position.y=70
 caption=Label.new()
 caption.text="Getting the garden ready…"
 caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 caption.add_theme_font_size_override("font_size",23)
 add_child(caption)
 meter=ProgressBar.new()
 meter.show_percentage=false
 add_child(meter)
 skip=Button.new()
 skip.text="ENTER"
 skip.disabled=true
 skip.hide()
 skip.add_theme_font_override("font",load("res://assets/fonts/breeserif.ttf"))
 skip.add_theme_font_size_override("font_size",32)
 skip.add_theme_color_override("font_color",Color("49351e"))
 skip.add_theme_color_override("font_hover_color",Color("49351e"))
 var atlas=AtlasTexture.new()
 atlas.atlas=load("res://assets/ui/wood-tab-natural.png")
 atlas.region=Rect2(85,128,1735,565)
 var wood=StyleBoxTexture.new()
 wood.texture=atlas
 for state in ["normal","hover","pressed","focus"]: skip.add_theme_stylebox_override(state,wood)
 skip.pressed.connect(enter_garden)
 add_child(skip)
 resized.connect(layout)
 layout()
 var error=ResourceLoader.load_threaded_request(MAIN)
 if error!=OK: caption.text="Could not load the garden. Please restart."
func layout():
 if movie==null: return
 var frame=get_viewport_rect().size
 var factor=maxf(frame.x/540.0,frame.y/960.0)
 movie.size=Vector2(540,960)*factor
 movie.position=(frame-movie.size)/2
 caption.position=Vector2(0,frame.y-190)
 caption.size=Vector2(frame.x,35)
 meter.position=Vector2(frame.x*0.2,frame.y-145)
 meter.size=Vector2(frame.x*0.6,14)
 skip.position=Vector2(frame.x/2-140,frame.y-140)
 skip.size=Vector2(280,85)
func _process(dt):
 if movie==null or entering: return
 elapsed+=dt
 var progress=[]
 var status=ResourceLoader.load_threaded_get_status(MAIN,progress)
 if not progress.is_empty(): meter.value=float(progress[0])*100
 if status==ResourceLoader.THREAD_LOAD_FAILED or status==ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
  caption.text="Could not load the garden. Please restart."
  movie.stop()
 elif status==ResourceLoader.THREAD_LOAD_LOADED:
  ready_to_enter=true
  meter.value=100
  skip.disabled=false
  caption.text="Your adventure is ready"
  skip.show()
  meter.hide()
  caption.hide()
func enter_garden():
 if not ready_to_enter or entering: return
 entering=true
 movie.stop()
 get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(MAIN))


