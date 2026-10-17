extends RefCounted
## Cosmetics never write combat stats, character unlocks, XP, or Acorn rewards.
const DATA = preload("res://cosmetic_catalog.json")
const Rig = preload("res://character_art.gd")
const OPEN = Rect2(465,450,150,65)
const BACK = Rect2(370,987,260,65)
const RESTORE = Rect2(90,987,260,65)
const ACTION = Rect2(165,839,390,70)
const LEFT = Rect2(85,550,90,80)
const RIGHT = Rect2(545,550,90,80)
var host: Node2D
var catalog: Dictionary = DATA.data
var opened = false
var tab = 0
var index = 0
var equipped = ["scout","poppy"]
var honey_garden = false
var rigs: Dictionary = {}
var notice = ""
var garden_texture: Texture2D

func setup(game: Node2D, save: ConfigFile) -> void:
 host=game
 for character in range(2):
  var id=str(save.get_value("wardrobe",str(character),equipped[character]))
  var entry=skin(id)
  if not entry.is_empty() and entry.character==character: equipped[character]=id
 honey_garden=bool(save.get_value("wardrobe","honey_garden",false))
 refresh()

func skin(id: String) -> Dictionary:
 for entry in catalog.skins:
  if entry.id==id: return entry
 return {}

func owned(entry: Dictionary) -> bool:
 if entry.is_empty(): return false
 if entry.earned_mastery>0: return host.mastery.tier(int(entry.character))>=entry.earned_mastery
 return entry.product.is_empty() or host.commerce.owns(entry.product)

func rig(id: String):
 if rigs.has(id): return rigs[id]
 var entry=skin(id)
 if entry.is_empty(): return null
 # Keep both bundle portraits alive through rendering, plus equipped rigs.
 if rigs.size()>=4:
  for key in rigs.keys():
   if not equipped.has(key):
    rigs.erase(key)
    break
 var result=Rig.new(load(entry.atlas),entry.character==0)
 rigs[id]=result
 return result

func refresh() -> void:
 for character in range(2):
  var id=equipped[character]
  # Preserve the saved preference while offline/revoked; render the free outfit.
  if not owned(skin(id)): id="scout" if character==0 else "poppy"
  host.character_art[character]=rig(id)

func write_config(save: ConfigFile) -> void:
 for character in range(2): save.set_value("wardrobe",str(character),equipped[character])
 save.set_value("wardrobe","honey_garden",honey_garden)

func has_honey_garden() -> bool:
 return honey_garden and host.commerce.owns("com.xevapps.backyardbrave.supporter")

func entries() -> Array:
 return catalog.skins.filter(func(entry): return entry.character==tab)

func open(character: int) -> void:
 opened=true
 tab=character
 index=0
 notice=""

func activate() -> void:
 if tab==2:
  var product="com.xevapps.backyardbrave.supporter"
  if host.commerce.owns(product):
   honey_garden=not honey_garden
   if not host.save_progress():
    honey_garden=not honey_garden
    notice="Could not save. Please try again."
   else: notice="Honey garden selected." if honey_garden else "Original garden selected."
  else: host.commerce.purchase(product)
  return
 var entry=entries()[index]
 if owned(entry):
  if not host.lifetime.character_unlocked(tab,host.stage_records,host.scout_experience.level):
   notice="Clear Stage 15 to invite Poppy first."
   return
  var previous=equipped[tab]
  equipped[tab]=entry.id
  if not host.save_progress():
   equipped[tab]=previous
   notice="Could not save. Please try again."
  else: notice=entry.name+" equipped."
  refresh()
 elif entry.earned_mastery>0:
  notice="Earn all five mastery titles for this character."
 else: host.commerce.purchase(entry.product)

func handle(event: InputEvent) -> bool:
 if not opened: return false
 if event is InputEventKey and event.pressed:
  if event.keycode==KEY_ESCAPE: opened=false
  elif event.keycode in [KEY_LEFT,KEY_RIGHT] and tab<2: index=posmod(index+(-1 if event.keycode==KEY_LEFT else 1),entries().size())
  elif event.keycode in [KEY_ENTER,KEY_SPACE]: activate()
  return true
 if event is InputEventJoypadButton and event.pressed:
  if event.button_index==JOY_BUTTON_B: opened=false
  elif event.button_index==JOY_BUTTON_A: activate()
  elif event.button_index in [JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT] and tab<2: index=posmod(index+(-1 if event.button_index==JOY_BUTTON_DPAD_LEFT else 1),entries().size())
  return true
 if (event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT)) and event.pressed:
  for i in range(3):
   if Rect2(80+i*190,345,180,64).has_point(event.position):
    tab=i
    index=0
    notice=""
  if BACK.has_point(event.position): opened=false
  elif RESTORE.has_point(event.position): host.commerce.restore()
  elif ACTION.has_point(event.position): activate()
  elif tab<2 and LEFT.has_point(event.position): index=posmod(index-1,entries().size())
  elif tab<2 and RIGHT.has_point(event.position): index=posmod(index+1,entries().size())
 return true

func paint() -> void:
 if not opened: return
 host.draw_rect(Rect2(-host.ui_offset(),host.get_viewport_rect().size),Color(0.08,0.11,0.07,0.9))
 host.story_panel(Rect2(40,250,640,850))
 host.center_text(315,"GARDEN WARDROBE",32,host.JOURNAL_INK)
 for i in range(3): host.draw_garden_button(Rect2(80+i*190,345,180,64),["SCOUT","POPPY","FRIENDS"][i],tab==i,22)
 var product="com.xevapps.backyardbrave.supporter"
 var label=""
 var enabled=true
 if tab==2:
  if garden_texture==null: garden_texture=load("res://assets/cosmetics/honey_garden.png")
  host.draw_texture_rect(garden_texture,Rect2(150,430,420,275),false)
  rig("honeybee").portrait(host,Rect2(200,455,140,235))
  rig("honeyblossom").portrait(host,Rect2(380,455,140,235))
  host.center_text(741,"Garden Friends Pack",29,host.JOURNAL_INK)
  host.center_text(775,"Two exclusive outfits + Honey garden",20,host.JOURNAL_INK)
  host.center_text(805,"Supporter portrait trim / No combat bonuses",19,host.LEAF_GREEN)
  label=("USE ORIGINAL GARDEN" if honey_garden else "USE HONEY GARDEN") if host.commerce.owns(product) else host.commerce.price_label(product)
  enabled=host.commerce.owns(product) or host.commerce.can_purchase(product)
 else:
  var entry=entries()[index]
  product=entry.product
  rig(entry.id).portrait(host,Rect2(250,437,220,265))
  host.draw_garden_button(LEFT,"<",false,32)
  host.draw_garden_button(RIGHT,">",false,32)
  host.center_text(741,entry.name,29,host.JOURNAL_INK)
  host.center_text(775,entry.description,19,host.JOURNAL_INK)
  var detail="Cosmetic only / Same skills and stats"
  if tab==1 and not host.lifetime.character_unlocked(1,host.stage_records,host.scout_experience.level): detail="Poppy unlocks by clearing Stage 15"
  if entry.earned_mastery>0: detail="Mastery %d / 5 titles earned" % host.mastery.tier(tab)
  elif product.ends_with("supporter"): detail="Included in Garden Friends Pack"
  host.center_text(805,detail,19,host.LEAF_GREEN)
  if owned(entry): label="EQUIPPED" if equipped[tab]==entry.id else "EQUIP OUTFIT"
  elif entry.earned_mastery>0: label="EARN THROUGH MASTERY"
  else: label=host.commerce.price_label(product)
  enabled=owned(entry) or (entry.earned_mastery==0 and host.commerce.can_purchase(product))
 host.draw_garden_button(ACTION,label,false,22,enabled)
 var message=notice if not notice.is_empty() else host.commerce.notice
 host.center_text(942,message,17,host.LEAF_GREEN)
 host.center_text(970,"Outfits never unlock characters or increase power.",17,host.JOURNAL_INK)
 host.draw_garden_button(RESTORE,"RESTORE",false,22)
 host.draw_garden_button(BACK,"BACK",true,22)
