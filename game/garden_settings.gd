extends RefCounted
const BUTTON = Rect2(577,177,108,62)
const CLOSE = Rect2(230,1022,260,70)
const KEYS = ["sound","music","vibration","reduced_vfx","reduced_flashes","damage_numbers","show_joystick","low_graphics"]
const LABELS = ["Sound effects","Music","Vibration","Reduced effects","Reduced flashes","Damage numbers","Show joystick","Graphics"]
var values = {"sound":true,"music":false,"vibration":false,"reduced_vfx":false,"reduced_flashes":false,"damage_numbers":true,"show_joystick":false,"low_graphics":false}
var host: Node2D
var opened = false
var tab = 0
var focus = 0
var notice = ""
var player_id = ""
const CAMP_MUSIC = preload("res://assets/audio/camp-garden.wav")
const COMBAT_MUSIC = preload("res://assets/audio/backyard-adventure.wav")
var music_mode = ""
var music: AudioStreamPlayer
var numbers: Array[Dictionary] = []

func setup(node: Node2D) -> void:
 host=node
 var cfg=ConfigFile.new()
 var result=cfg.load("user://settings.cfg")
 if result==OK:
  for key in KEYS:
   var v=cfg.get_value("options",key,values[key])
   if v is bool: values[key]=v
  player_id=str(cfg.get_value("profile","id",""))
 if player_id.is_empty(): player_id="BB-"+str(Time.get_unix_time_from_system()).replace(".","-")
 host.mute=not values.sound
 music=AudioStreamPlayer.new()
 music.volume_db=-27
 host.add_child(music)
 if result in [OK,ERR_FILE_NOT_FOUND]: persist()
 else: notice="Settings could not be read; defaults loaded."
 sync_music()

func persist() -> bool:
 var cfg=ConfigFile.new()
 for key in KEYS: cfg.set_value("options",key,values[key])
 cfg.set_value("profile","id",player_id)
 var error=cfg.save("user://settings.cfg")
 if error!=OK: notice="Settings could not be saved."
 return error==OK

func sync_music() -> void:
 if not values.music:
  music.stop()
  return
 var wanted = "camp" if host.state=="title" else "combat"
 if music_mode!=wanted or music.stream==null:
  music_mode=wanted
  var stream: AudioStreamWAV = (CAMP_MUSIC if wanted=="camp" else COMBAT_MUSIC).duplicate()
  stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
  stream.loop_end=int(stream.get_length()*stream.mix_rate)
  music.stream=stream
  music.volume_db=-15
 if not music.playing: music.play()

func row(index: int) -> Rect2:
 return Rect2(105,414+index*62,510,57)

func toggle(index: int) -> void:
 var key=KEYS[index]
 var previous=values[key]
 values[key]=not previous
 if not persist():
  values[key]=previous
  return
 host.mute=not values.sound
 if host.mute:
  for voice in host.audio_players: voice.stop()
 if key=="music": sync_music()
 if key=="damage_numbers": numbers.clear()
 notice="Saved"

func handle(event: InputEvent) -> bool:
 if host.state!="title": return false
 if not opened:
  if event is InputEventKey and event.pressed and event.keycode==KEY_O and host.scout_profile.page.is_empty():
   opened=true
   return true
  if (event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT)) and event.pressed and BUTTON.has_point(event.position) and host.scout_profile.page.is_empty():
   opened=true
   return true
  return false
 if event is InputEventKey and event.pressed and not event.echo:
  navigate(event.keycode)
 elif event is InputEventJoypadButton and event.pressed:
  var mapping={JOY_BUTTON_B:KEY_ESCAPE,JOY_BUTTON_A:KEY_ENTER,JOY_BUTTON_DPAD_UP:KEY_UP,JOY_BUTTON_DPAD_DOWN:KEY_DOWN,JOY_BUTTON_DPAD_LEFT:KEY_LEFT,JOY_BUTTON_DPAD_RIGHT:KEY_RIGHT}
  if mapping.has(event.button_index): navigate(mapping[event.button_index])
 elif (event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT)) and event.pressed:
  if CLOSE.has_point(event.position): opened=false
  elif Rect2(110,340,245,58).has_point(event.position): tab=0; focus=0
  elif Rect2(365,340,245,58).has_point(event.position): tab=1; focus=0
  elif tab==0:
   for i in range(8):
    if row(i).has_point(event.position): focus=i; toggle(i)
  else:
   for i in range(3):
    if Rect2(150,610+i*98,420,74).has_point(event.position): focus=i; save_action(i)
 return true

func navigate(key: int) -> void:
 if key==KEY_ESCAPE: opened=false
 elif key in [KEY_LEFT,KEY_RIGHT,KEY_TAB]: tab=1-tab; focus=0
 elif key in [KEY_UP,KEY_DOWN]: focus=posmod(focus+(1 if key==KEY_DOWN else -1),8 if tab==0 else 3)
 elif key in [KEY_ENTER,KEY_SPACE]:
  if tab==0: toggle(focus)
  else: save_action(focus)

func save_action(index: int) -> void:
 if index==0:
  DisplayServer.clipboard_set(player_id)
  notice="Local player ID copied."
 elif index==1:
  if not host.save_progress(): notice="Could not save; no backup created."; return
  var target="user://backup-%d-%d.cfg" % [int(Time.get_unix_time_from_system()*1000),Time.get_ticks_msec()]
  var error=DirAccess.copy_absolute(ProjectSettings.globalize_path("user://records.cfg"),ProjectSettings.globalize_path(target))
  notice="Backup saved on this device." if error==OK else "Backup could not be created."
 else:
  var cfg=ConfigFile.new()
  var ok=cfg.load("user://records.cfg")==OK
  notice="Save file readable. No issues found." if ok else "Save unreadable. Existing file left untouched."

func advance(delta: float) -> void:
 if values.sound==host.mute:
  values.sound=not host.mute
  persist()
 if values.music: sync_music()
 music.stream_paused=host.state=="paused"
 if host.state!="playing": return
 for i in range(numbers.size()-1,-1,-1):
  numbers[i].life-=delta
  numbers[i].merge=maxf(0,float(numbers[i].get("merge",0))-delta)
  numbers[i].p.y-=22*delta
  if numbers[i].life<=0: numbers.remove_at(i)

func hit(at: Vector2, amount: float, enemy_id: int = -1) -> void:
 if not values.damage_numbers or amount<=0: return
 if enemy_id>=0:
  for item in numbers:
   if item.get("enemy_id",-1)==enemy_id and item.get("merge",0)>0:
    item.amount+=amount
    item.text=damage_text(item.amount)
    return
 if numbers.size()>=40: numbers.pop_front()
 numbers.append({"p":at+Vector2(-8,-25),"text":damage_text(amount),"amount":amount,"life":0.7,"merge":0.09,"enemy_id":enemy_id,"kind":"damage"})

func damage_text(amount: float) -> String:
 return str(roundi(amount)) if is_equal_approx(amount,float(roundi(amount))) else "%.1f" % amount

func scout_hit(blocked: bool) -> void:
 if not values.damage_numbers: return
 if numbers.size()>=40: numbers.pop_front()
 numbers.append({"p":host.player+Vector2(-20,-49),"text":"BLOCK" if blocked else "-1","life":0.85,"merge":0.0,"kind":"block" if blocked else "hurt"})

func vibrate() -> void:
 if not values.vibration or host.screenshot_mode: return
 if OS.get_name() in ["Android","iOS"]: Input.vibrate_handheld(60)
 for device in Input.get_connected_joypads(): Input.start_joy_vibration(device,0.15,0.25,0.06)

func draw_numbers() -> void:
 if not values.damage_numbers: return
 for item in numbers:
  var kind: String=item.get("kind","damage")
  var color=Color("f9edc8") if kind=="damage" else Color("ee7561") if kind=="hurt" else Color("a9e3ee")
  color.a=minf(item.life*4,1)
  var font_size=16 if kind=="damage" else 18
  # Crisp dark outline; no scaling pulses or flashes, including reduced-VFX mode.
  host.draw_string_outline(host.heading_font,item.p,item.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,3,Color(0.16,0.13,0.09,color.a))
  host.draw_string(host.heading_font,item.p,item.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func draw_header() -> void:
 host.draw_garden_button(BUTTON,"SETTINGS",opened,17)

func paint() -> void:
 if not opened: return
 host.draw_rect(Rect2(-host.ui_offset(),host.get_viewport_rect().size),Color(0.08,0.11,0.07,0.88))
 host.story_panel(Rect2(45,230,630,910))
 host.center_text(314,"CAMP SETTINGS",36,host.JOURNAL_INK)
 host.draw_pause_action(Rect2(110,340,245,58),"GENERAL",tab==0)
 host.draw_pause_action(Rect2(365,340,245,58),"SAVE & INFO",tab==1)
 if tab==0:
  for i in range(8):
   var rect=row(i)
   host.text_at(rect.position+Vector2(12,37),LABELS[i],25,host.JOURNAL_INK)
   var toggle_rect=Rect2(rect.position+Vector2(351,4),Vector2(145,48))
   if i==7:
    host.draw_garden_button(toggle_rect,"LOW" if values.low_graphics else "HIGH",focus==i,22)
   else:
    host.draw_garden_toggle(toggle_rect,values[KEYS[i]])
  host.center_text(942,"Language: English",21,host.LEAF_GREEN)
  host.center_text(973,"Vibration requires a supported device.",18,host.LEAF_GREEN)
 else:
  host.center_text(452,"LOCAL SCOUT PROFILE",26,host.JOURNAL_INK)
  host.center_text(494,player_id,20,host.LEAF_GREEN)
  host.center_text(544,"Progress is saved on this device.",22,host.JOURNAL_INK)
  host.center_text(578,"Cloud accounts are not connected.",20,host.LEAF_GREEN)
  for i in range(3): host.draw_pause_action(Rect2(150,610+i*98,420,74),["COPY PLAYER ID","BACK UP SAVE","CHECK SAVE FILE"][i],focus==i)
  host.center_text(940,"Backups stay in the game's local save folder.",18,host.LEAF_GREEN)
  host.center_text(973,"Backyard Brave / Development build",18,host.LEAF_GREEN)
 host.center_text(1004,notice,18,host.LEAF_GREEN)
 host.draw_pause_action(CLOSE,"BACK TO CAMP",true)
