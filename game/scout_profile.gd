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
var character_choice = 0
const PREVIOUS = Rect2(85,575,95,85)
const NEXT = Rect2(540,575,95,85)
const MASTERY = Rect2(218,770,284,52)
const SELECT = Rect2(218,830,284,72)

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

func select_character() -> void:
 if not host.lifetime.character_unlocked(character_choice,host.stage_records,host.scout_experience.level):
  notice = "Clear Stage 15 to invite Poppy to camp."
  return
 var previous = host.selected_character
 host.selected_character = character_choice
 if not host.screenshot_mode and not host.save_progress():
  host.selected_character = previous
  notice = "Could not save. Please try again."
 else:
  notice = "Poppy is ready!" if character_choice==1 else "Scout is ready!"

func character_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed:
  if event.keycode in [KEY_LEFT,KEY_RIGHT]: character_choice = 1-character_choice
  elif event.keycode in [KEY_ENTER,KEY_SPACE]: select_character()
  elif event.keycode==KEY_M: page = "mastery"
  elif event.keycode==KEY_ESCAPE: close()
 elif event is InputEventJoypadButton and event.pressed:
  if event.button_index in [JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]: character_choice = 1-character_choice
  elif event.button_index==JOY_BUTTON_Y: page = "mastery"
  elif event.button_index==JOY_BUTTON_A: select_character()
  elif event.button_index==JOY_BUTTON_B: close()
 elif (event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT)) and event.pressed:
  if PREVIOUS.has_point(event.position) or NEXT.has_point(event.position): character_choice = 1-character_choice
  elif MASTERY.has_point(event.position): page = "mastery"
  elif SELECT.has_point(event.position): select_character()
  elif CLOSE.has_point(event.position): close()


func handle(event: InputEvent) -> bool:
 if host.state!="title": return false
 if page!="":
  if page=="mastery":
   if (event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_B): page = "characters"
   elif (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed and CLOSE.has_point(event.position): page = "characters"
   return true
  if page=="characters":
   character_input(event)
   return true
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
   character_choice = host.selected_character
   notice = ""
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
 if page=="mastery":
  paint_mastery()
  return
 host.center_text(413,"CHOOSE YOUR SCOUT" if page=="characters" else "NAME YOUR SCOUT",30,host.JOURNAL_INK)
 if page=="characters":
  var saved = host.selected_character
  host.selected_character = character_choice
  host.home_scout(Rect2(270,447,180,205))
  host.selected_character = saved
  host.draw_garden_button(PREVIOUS,"<",false,32)
  host.draw_garden_button(NEXT,">",false,32)
  host.center_text(692,"POPPY / THE GARDENER" if character_choice==1 else host.scout_name,27,host.JOURNAL_INK)
  host.center_text(733,"Steer the boomerang's return by moving." if character_choice==1 else "Build firing lanes with seeds and traps.",21,host.LEAF_GREEN)
  host.center_text(760,"Roll into its pale ring to catch it." if character_choice==1 else "Automatic seed shots. Roll to dodge.",21,host.LEAF_GREEN)
  host.draw_pause_action(MASTERY,"MASTERY / %d OF 5" % host.mastery.tier(character_choice),false)
  var available = host.lifetime.character_unlocked(character_choice,host.stage_records,host.scout_experience.level)
  host.draw_pause_action(SELECT,"CLEAR STAGE 15" if not available else "SELECTED" if character_choice==host.selected_character else "SELECT CHARACTER",character_choice==host.selected_character and available)
  host.center_text(921,notice if not notice.is_empty() else host.mastery.title(character_choice),18,host.LEAF_GREEN)
  host.draw_pause_action(CLOSE,"BACK TO CAMP",true)
 else:
  host.home_scout(Rect2(320,460,80,125))
  host.center_text(605,"Up to 18 characters",21,host.LEAF_GREEN)
  host.center_text(742,notice if not notice.is_empty() else "Tap the wooden name sign to rename.",20,host.LEAF_GREEN)
  host.draw_pause_action(CANCEL,"CANCEL",false)
  host.draw_pause_action(SAVE,"SAVE NAME",true)

func paint_mastery() -> void:
 host.center_text(405,("POPPY" if character_choice==1 else "SCOUT")+" / MASTERY",30,host.JOURNAL_INK)
 host.center_text(441,host.mastery.title(character_choice),23,host.LEAF_GREEN)
 var goals = host.mastery.goals(character_choice)
 var rank = host.mastery.tier(character_choice)
 for i in range(5):
  var y = 482+i*77
  var goal = goals[i]
  host.center_text(y,"%d. %s%s" % [i+1,host.mastery.TITLES[character_choice][i]," / EARNED" if i<rank else ""],21,host.LEAF_GREEN)
  host.center_text(y+25,goal[0],18,host.JOURNAL_INK)
  var bar = Rect2(130,y+37,380,7)
  host.draw_rect(bar,Color("c9bd91"))
  host.draw_rect(Rect2(bar.position,Vector2(380*minf(1,float(goal[1])/goal[2]),7)),host.LEAF_GREEN)
  host.text_at(Vector2(527,y+44),"%d/%d" % [mini(goal[1],goal[2]),goal[2]],16,host.JOURNAL_INK)
 host.center_text(879,"Goals count together. Titles unlock in order.",18,host.LEAF_GREEN)
 host.center_text(903,"Cosmetic titles / no added combat power",18,host.LEAF_GREEN)
 host.draw_pause_action(CLOSE,"BACK TO CHARACTER",true)
