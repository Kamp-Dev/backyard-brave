extends RefCounted
const PORTRAIT = Rect2(116,48,82,106)
const NAME = Rect2(203,53,258,49)
const CLOSE = Rect2(218,925,284,78)
const SAVE = Rect2(377,780,220,76)
const CANCEL = Rect2(123,780,220,76)
var host: Node2D
var page = ""
var notice = ""
var edit: LineEdit
var merit_id = 100
var merit_choice = 0

func open_merits(id: int) -> void:
 if not host.save_progress():
  host.growth_notice = "Could not save reward choices. Please try again."
  return
 merit_id = id
 merit_choice = 0
 notice = ""
 page = "merits"

func merit_rect(index: int) -> Rect2:
 return Rect2(105,463+index*132,510,119)

func choose_merit(index: int) -> void:
 var offers = host.growth.merit_offers(merit_id)
 if index<0 or index>=offers.size(): return
 var before = ConfigFile.new()
 host.growth.write_config(before)
 if not host.growth.buy(merit_id,host.stage_records,offers[index]): return
 if not host.save_progress():
  host.growth.load_config(before)
  notice = "Could not save. Nothing spent."
  return
 host.growth_notice = host.growth.name_for(merit_id)+" learned! Applies next run."
 close()

func setup(owner_node: Node2D) -> void:
 host = owner_node
 edit = LineEdit.new()
 edit.max_length = 18
 edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
 edit.placeholder_text = "Your scout's name"
 edit.add_theme_font_override("font",host.heading_font)
 edit.add_theme_font_size_override("font_size",30)
 edit.add_theme_color_override("font_color",Color("352e23"))
 var box = StyleBoxFlat.new()
 box.bg_color = Color("fff0cd")
 box.set_corner_radius_all(10)
 box.set_content_margin_all(12)
 edit.add_theme_stylebox_override("normal",box)
 edit.add_theme_stylebox_override("focus",box)
 edit.hide()
 host.add_child(edit)
 edit.text_submitted.connect(func(_value): save_name())

func open_name() -> void:
 page = "name"
 notice = ""
 edit.text = host.scout_name
 update_layout()
 edit.show()
 edit.grab_focus()
 edit.select_all()

func close() -> void:
 page = ""
 edit.release_focus()
 edit.hide()

func update_layout() -> void:
 edit.position = host.ui_offset()+Vector2(150,630)
 edit.size = Vector2(420,70)

func save_name() -> void:
 var value = edit.text.strip_edges()
 if value.is_empty():
  notice = "Please enter a name."
  return
 var previous = host.scout_name
 host.scout_name = value
 if not host.save_progress():
  host.scout_name = previous
  notice = "Could not save. Please try again."
  return
 close()

func handle(event: InputEvent) -> bool:
 if host.state!="title": return false
 if page!="":
  if page=="merits":
   if event is InputEventKey and event.pressed:
    if event.keycode in [KEY_UP,KEY_LEFT]: merit_choice = posmod(merit_choice-1,3)
    elif event.keycode in [KEY_DOWN,KEY_RIGHT]: merit_choice = posmod(merit_choice+1,3)
    elif event.keycode in [KEY_ENTER,KEY_SPACE]: choose_merit(merit_choice)
   elif event is InputEventJoypadButton and event.pressed:
    if event.button_index in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_LEFT]: merit_choice = posmod(merit_choice-1,3)
    elif event.button_index in [JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_RIGHT]: merit_choice = posmod(merit_choice+1,3)
    elif event.button_index==JOY_BUTTON_A:
     choose_merit(merit_choice)
     return true
   elif (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
    for index in range(3):
     if merit_rect(index).has_point(event.position):
      choose_merit(index)
      return true
    if CLOSE.has_point(event.position): close()
  if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
   close()
  elif event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_B,JOY_BUTTON_A]:
   if page=="name" and event.button_index==JOY_BUTTON_A: save_name()
   else: close()
  elif (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
   if page=="characters" and CLOSE.has_point(event.position): close()
   elif page=="name" and CANCEL.has_point(event.position): close()
   elif page=="name" and SAVE.has_point(event.position): save_name()
  return true
 if (event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT)) and event.pressed:
  if PORTRAIT.has_point(event.position):
   page = "characters"
   return true
  if NAME.has_point(event.position):
   open_name()
   return true
 return false

func paint() -> void:
 if page.is_empty(): return
 update_layout()
 host.draw_rect(Rect2(-host.ui_offset(),host.get_viewport_rect().size),Color(0.08,0.11,0.07,0.88))
 host.story_panel(Rect2(50,300,620,745))
 host.center_text(413,"CHOOSE AN ACORN BONUS" if page=="merits" else "CHOOSE YOUR SCOUT" if page=="characters" else "NAME YOUR SCOUT",30,host.JOURNAL_INK)
 if page=="merits":
  var offers = host.growth.merit_offers(merit_id)
  for index in range(offers.size()):
   var rect = merit_rect(index)
   host.story_panel(rect,Color.WHITE if index==merit_choice else Color(0.92,0.94,0.86))
   host.card_text(rect,rect.position.y+39,host.growth.NAMES[offers[index]],25,host.JOURNAL_INK)
   var words = host.growth.DETAILS[offers[index]].split(" ")
   var line = ""
   var y = rect.position.y+70
   for word in words:
    if (line+" "+word).length()>37:
     host.card_text(rect,y,line,20,host.LEAF_GREEN)
     line = ""
     y += 23
    line += (" " if not line.is_empty() else "")+word
   host.card_text(rect,y,line,20,host.LEAF_GREEN)
  host.center_text(893,notice if not notice.is_empty() else "Choose one / Costs 1 Golden Acorn",22,host.LEAF_GREEN)
  host.draw_pause_action(CLOSE,"CHOOSE LATER",true)
  return
 if page=="characters":
  host.home_scout(Rect2(270,465,180,238))
  host.center_text(755,host.scout_name,30,host.JOURNAL_INK)
  host.center_text(798,"Level %d / Backyard Scout" % host.scout_experience.level,23,host.LEAF_GREEN)
  host.center_text(850,"More scouts will join the camp later.",22,host.LEAF_GREEN)
  host.draw_pause_action(CLOSE,"BACK TO CAMP",true)
 else:
  host.home_scout(Rect2(320,460,80,125))
  host.center_text(605,"Up to 18 characters",21,host.LEAF_GREEN)
  host.center_text(742,notice if not notice.is_empty() else "Tap the wooden name sign to rename.",20,host.LEAF_GREEN)
  host.draw_pause_action(CANCEL,"CANCEL",false)
  host.draw_pause_action(SAVE,"SAVE NAME",true)
