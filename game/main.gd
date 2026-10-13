extends Node2D

const Tuning = preload("res://tuning.gd")
const Combat = preload("res://combat.gd")
const PLAYER_TEXTURES = [preload("res://assets/player/scout-draw.png"), preload("res://assets/player/scout-release.png"), preload("res://assets/player/scout-walk-a.png"), preload("res://assets/player/scout-walk-b.png")]

const WALK_LEGS = preload("res://assets/player/scout-walk-legs.png")
const WALK_STRIDE = 84.0
var walk_regions: Array[Rect2] = []
const WALK_HIPS = [104.5, 93.0, 92.5, 79.5, 70.0, 74.0, 89.5, 78.5, 74.0, 83.0, 72.0, 74.0, 56.5, 58.0, 60.0, 57.5, 57.5, 56.5, 86.0, 76.0, 53.5, 79.5, 77.0, 53.0, 62.5, 60.5, 61.5, 61.5, 60.0, 60.5]
var locomotion_direction = Vector2.UP

const ELITE_TEXTURE = preload("res://assets/enemies/backyard-elites.png")
const DROP_TEXTURE = preload("res://assets/pickups/backyard-drops.png")
var elite_regions: Array[Rect2] = []
var drop_regions: Array[Rect2] = []
var bonus_drops: Array[Dictionary] = []
var elite_spawn_index = 0
const ELITE_TIMES = [45.0, 90.0, 125.0]
const ELITE_KINDS = [7, 6, 8]

const ENEMY_TEXTURE = preload("res://assets/enemies/backyard-bugs.png")
const ENEMY_SIZES = [44.0, 46.0, 48.0, 50.0, 46.0, 86.0, 76.0, 62.0, 64.0, 52.0, 56.0, 58.0]
const ENEMY_RADII = [12.0, 11.0, 17.0, 15.0, 14.0, 30.0, 26.0, 20.0, 20.0, 16.0, 13.0, 15.0]
const GARDEN_BUG_TEXTURES = [preload("res://assets/enemies/weevil.png"), preload("res://assets/enemies/grasshopper.png"), preload("res://assets/enemies/mole-cricket.png")]
var enemy_regions: Array[Rect2] = []

const GROUND_TEXTURE = preload("res://assets/environment/backyard-endless.png")

const ROLL_TEXTURE = preload("res://assets/player/scout-roll.png")
const ROLL_DURATION = 0.32
var roll_regions: Array[Rect2] = []

const HomeGarden = preload("res://home_garden.gd")
var home_garden = HomeGarden.new()
const StageArt = preload("res://stage_art.gd")
const StagePreviewMotion = preload("res://stage_preview_motion.gd")
var stage_art = StageArt.new()
var locked_preview: SubViewport
var locked_sprite: TextureRect
var preview_motion = StagePreviewMotion.new()
const STAGE_COUNT = 30
const STAGE_PREVIOUS = Rect2(45,944,78,78)
const STAGE_NEXT = Rect2(597,944,78,78)
var selected_stage = 1
var run_stage = 1
var unlocked_stage = 1
var stage_records: Dictionary = {}
var preview_enemy = 0
var preview_rng = RandomNumberGenerator.new()

const HOME_PLAY = Rect2(140, 986, 440, 112)
const HOME_RETURN = Rect2(200, 1130, 320, 75)
const ScoutGrowth = preload("res://scout_growth.gd")
var growth = ScoutGrowth.new()
const ScoutExperience = preload("res://scout_experience.gd")
var scout_experience = ScoutExperience.new()
var earned_scout_xp = 0
var scout_levels_gained = 0
const GrowthAlbum = preload("res://growth_album.gd")
const GROWTH_VIEW = Rect2(68,474,584,458)
const GROWTH_HEADER_LEFT = Rect2(55,340,302,120)
const GROWTH_HEADER_RIGHT = Rect2(363,340,302,120)
var album_view: Control
var envelope_scroll = 0.0
var acorn_scroll = 0.0
var growth_scroll: float:
	get: return acorn_scroll if merit_track else envelope_scroll
	set(value):
		if merit_track: acorn_scroll = value
		else: envelope_scroll = value
var merit_track = false
var growth_velocity = 0.0
var growth_drag_id = -2
var growth_drag_start = Vector2.ZERO
var growth_drag_last = Vector2.ZERO
var growth_drag_distance = 0.0
var growth_drag_time = 0
var merit_rolls = 0
var merit_volleys = 0
var bramble_pending = false
var bloom_used = false
var growth_selected = 0
var scout_handbook = false
var growth_notice = "Tap a talent to see its permanent benefit."
var run_growth: Array[int] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
var rescue_used = false
var earned_packets = 0
var earned_acorns = 0
var earned_breakdown: Dictionary = {}
const ScoutProfile = preload("res://scout_profile.gd")
var scout_profile = ScoutProfile.new()
var scout_name = "Backyard Scout"
var progress_save_failed = false
const GROWTH_BUY = Rect2(177,1018,366,79)
var home_tab = 1
var completed_runs = 0
var cleared_runs = 0
var longest_run = 0.0

const HEALTH_WOOD_FRAME = preload("res://assets/ui/health-wood-frame.png")
const CAMP_CACTUS = preload("res://assets/ui/camp-cactus.png")
const TOGGLE_LEAF = preload("res://assets/ui/toggle-leaf.png")
const WOOD_TAB_GREEN = preload("res://assets/ui/wood-tab-green.png")
const WOOD_TAB_NATURAL = preload("res://assets/ui/wood-tab-natural.png")
const WORKBENCH = preload("res://assets/ui/gardener-workbench.png")
const REPORT_ART = preload("res://assets/ui/scout-report-pieces.png")
const CAMP_HEADER = preload("res://assets/ui/campsite-header-name.png")
const STORY_PAUSE = preload("res://assets/ui/storybook-pause.png")
const STORY_PIECES = preload("res://assets/ui/storybook-pieces.png")
const STORY_SKILLS = preload("res://assets/ui/storybook-skills.png")
const STORY_CARD = Rect2(20, 16, 610, 720)
const STORY_TITLE = Rect2(650, 240, 875, 235)
const STORY_NAVIGATION = preload("res://assets/ui/storybook-navigation.png")
const STORY_BUTTON = Rect2(25, 780, 650, 185)
const STORY_LEGEND = Rect2(725, 811, 795, 145)
const STORY_ICONS = [Rect2(50,80,425,315), Rect2(525,80,350,315), Rect2(925,100,350,290), Rect2(55,450,385,315), Rect2(490,450,380,330), Rect2(890,455,395,315), Rect2(65,810,380,325), Rect2(490,822,365,310), Rect2(915,835,365,295)]

const PAPER = Color("ead9b2")
const JOURNAL_INK = Color("352e23")
const LEAF_GREEN = Color("587345")
const PAUSE_BUTTON = Rect2(592, 64, 64, 64)
const EXIT_STAGE_BUTTON = Rect2(210,1090,300,78)
const EXIT_CANCEL_BUTTON = Rect2(180,645,360,88)
const EXIT_CONFIRM_BUTTON = Rect2(180,754,360,88)
var exit_stage_confirmation = false
var pause_choice = 1
var pause_page = 0
const PAUSE_SKILLS_TAB = Rect2(120,285,225,62)
const PAUSE_CONTROLS_TAB = Rect2(375,285,225,62)
var exit_choice = 0
const RESUME_BUTTON = Rect2(190, 990, 340, 90)
const START_BUTTON = Rect2(150, 1020, 420, 90)
const SOUND_BUTTON = Rect2(200, 884, 320, 78)
const ROLL_BUTTON = Rect2(500, 1090, 150, 150)
const DRAG_RADIUS = 65.0
var drag_origin = Vector2.ZERO
var mouse_dragging = false
var move_touch = -1
var move_touch_active = false
var touch_move = Vector2.ZERO
var camera_center = Vector2(640, 390)
var terrain_cell = Vector2i(2147483647, 2147483647)

const CYAN = Color("56e5ed")
const PINK = Color("ee4e9c")
const INK = Color("080f24")
const WHITE = Color("e6f4ff")
const GAMEPLAY_ZOOM = 1.2
const SCREEN_ARENA = Rect2(0, 0, 720, 1280)
const ARENA = Rect2(Vector2(640, 390) - SCREEN_ARENA.size / GAMEPLAY_ZOOM / 2, SCREEN_ARENA.size / GAMEPLAY_ZOOM)
var drawing_world = false
const SPAWN_DURATION = Tuning.RUN_SECONDS
const UPGRADE_NAMES = ["QUICK DRAW", "SCATTER SEEDS", "HARD SEEDS", "FORAGER POUCH", "TUCK AND ROLL", "TRAIL BOOTS", "DEW BARRIER", "NEEDLE SEEDS", "THUMP SHOT"]
const UPGRADE_CAPS = [5, 5, 5, 5, 5, 5, 5, 5, 5]
const MAX_LEVEL = 7
const LEVEL_SEED_POWER = 0.55
const RUN_XP_STEPS = [10,35,60,85,110,145]
const SCATTER_POWER = [1.0, 0.85, 0.70, 0.62, 0.55, 0.50]
const UPGRADE_FAMILIES = ["SHARPSHOOTER", "CROWD CONTROL", "SHARPSHOOTER", "TRAIL SURVIVOR", "TRAIL SURVIVOR", "TRAIL SURVIVOR", "TRAIL SURVIVOR", "SHARPSHOOTER", "CROWD CONTROL"]
var upgrade_ranks: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
var bug_deaths: Array[Dictionary] = []
var roll_echoes: Array[Dictionary] = []
var upgrade_fx: Array[Dictionary] = []
var echo_clock = 0.0
var boot_distance = 0.0
var next_enemy_id = 0
var encounter_rewards = 0
var pending_encounter_rewards = 0
var test_build = 0

var player = Vector2(640, 390)
var facing = Vector2.UP
var player_aim = Vector2.UP
var player_regions: Array = []
var player_moving = false
var attack_pose_timer = 0.0
var attack_phase = "idle"
var attack_clock = 0.0
var walk_distance = 0.0
var player_display_height = 68.0
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var gems: Array[Vector2] = []
var effects: Array[Dictionary] = []
var hostile_bullets: Array[Dictionary] = []
var repairs: Array[Vector2] = []
var stars: Array[Vector2] = []
var obstacles = [Vector2(260, 270), Vector2(1020, 270), Vector2(260, 535), Vector2(1020, 535)]
var rng = RandomNumberGenerator.new()
var font: Font = preload("res://assets/fonts/nunito.ttf")
var heading_font: Font = preload("res://assets/fonts/breeserif.ttf")
var state = "title"
var previous_state = "playing"
var hp = 8
var xp = 0
var level = 1
var kills = 0
var elapsed = 0.0
var wave = 1
var fire_timer = 0.0
var spawn_timer = 0.0
var hurt_timer = 0.0
var roll_timer = 0.0
var roll_time = 0.0
var speed = 230.0
var fire_rate = 0.36
var damage = 3.0
var shots = 1
var magnet = 90.0
var upgrades: Array[int] = []
var pending_levels = 0
var run_best = 0
var audio: AudioStreamPlayer
var audio_players: Array[AudioStreamPlayer] = []
var sound_cache: Dictionary = {}
var audio_cursor = 0
const GardenSettings = preload("res://garden_settings.gd")
var settings = GardenSettings.new()
var browser_touch = preload("res://browser_touch.gd").new()
const GardenAudio = preload("res://garden_audio.gd")
var garden_audio = GardenAudio.new()
var mute = false
var screenshot_mode = false
var boss_spawned = false
var banner = ""
var banner_timer = 0.0
var damage_dealt = 0.0
var damage_taken = 0
var roll_direction = Vector2.UP
var controller_choice = 0
var shield = 0
var guard_absorbed_hit = false
var guard_hit_time = 0.0
var guard_break_time = 0.0

func _ready() -> void:
	browser_touch.setup()
	locked_preview = SubViewport.new()
	locked_preview.size = Vector2i(532,532)
	locked_preview.transparent_bg = true
	locked_preview.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(locked_preview)
	locked_sprite = TextureRect.new()
	locked_sprite.size = Vector2(532,532)
	locked_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var material_gray = ShaderMaterial.new()
	var shader_gray = Shader.new()
	shader_gray.code = "shader_type canvas_item; void fragment(){vec4 c=texture(TEXTURE,UV);float g=dot(c.rgb,vec3(0.299,0.587,0.114));COLOR=vec4(vec3(g)*0.7,c.a);}"
	material_gray.shader = shader_gray
	locked_sprite.material = material_gray
	locked_preview.add_child(locked_sprite)
	album_view = GrowthAlbum.new()
	album_view.host = self
	album_view.size = GROWTH_VIEW.size
	album_view.position = GROWTH_VIEW.position + ui_offset()
	album_view.visible = false
	add_child(album_view)
	var body_font = FontVariation.new()
	body_font.base_font = preload("res://assets/fonts/nunito.ttf")
	body_font.variation_opentype = {2003265652: 600.0}
	font = body_font
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for texture in PLAYER_TEXTURES:
		var sprite_image = texture.get_image()
		var cell_size = sprite_image.get_size() / Vector2i(4, 2)
		var regions: Array[Rect2] = []
		for row in range(2):
			for column in range(4):
				var cell_position = Vector2i(column, row) * cell_size
				var bounds = sprite_image.get_region(Rect2i(cell_position, cell_size)).get_used_rect()
				assert(bounds.has_area(), "Each Scout direction must contain a sprite")
				regions.append(Rect2(bounds.position + cell_position, bounds.size))
		player_regions.append(regions)
	walk_regions.assign([Rect2(18,45,206,161), Rect2(253,45,186,162), Rect2(485,44,196,156), Rect2(724,45,185,161), Rect2(962,45,142,161), Rect2(1190,43,161,164), Rect2(31,251,182,168), Rect2(277,251,155,172), Rect2(506,250,154,166), Rect2(725,248,175,170), Rect2(969,251,142,172), Rect2(1194,250,148,169), Rect2(65,462,113,179), Rect2(294,462,116,177), Rect2(521,461,115,172), Rect2(755,462,115,178), Rect2(980,461,118,180), Rect2(1212,462,117,172), Rect2(40,679,168,183), Rect2(277,679,158,175), Rect2(528,679,113,184), Rect2(728,678,163,178), Rect2(964,679,159,175), Rect2(1215,679,107,187), Rect2(59,902,122,197), Rect2(293,901,120,192), Rect2(521,901,122,198), Rect2(749,901,121,198), Rect2(980,901,120,194), Rect2(1210,901,121,189)])
	enemy_regions.assign([Rect2(49, 43, 356, 244), Rect2(454, 8, 365, 298), Rect2(883, 74, 318, 180), Rect2(49, 344, 359, 245), Rect2(455, 324, 371, 289), Rect2(883, 377, 318, 180), Rect2(26, 634, 387, 284), Rect2(446, 647, 414, 257), Rect2(860, 604, 350, 325), Rect2(25, 951, 391, 298), Rect2(446, 958, 414, 275), Rect2(860, 944, 352, 317)])
	elite_regions.assign([Rect2(34, 80, 452, 385), Rect2(519, 144, 505, 271), Rect2(1024, 101, 490, 351), Rect2(31, 553, 461, 401), Rect2(532, 637, 492, 261), Rect2(1024, 569, 491, 391)])
	drop_regions.assign([Rect2(89,137,365,444), Rect2(569,130,475,453), Rect2(1124,130,450,450), Rect2(1669,112,426,484)])
	roll_regions.assign([Rect2(51, 102, 217, 203), Rect2(342, 101, 192, 209), Rect2(619, 105, 168, 206), Rect2(878, 94, 200, 219), Rect2(1160, 93, 175, 219), Rect2(65, 394, 231, 180), Rect2(364, 360, 191, 213), Rect2(618, 365, 169, 207), Rect2(886, 358, 206, 214), Rect2(1159, 359, 180, 210), Rect2(68, 614, 188, 209), Rect2(350, 616, 170, 206), Rect2(627, 616, 147, 211), Rect2(892, 606, 170, 219), Rect2(1179, 615, 152, 205), Rect2(62, 854, 207, 217), Rect2(341, 860, 204, 222), Rect2(616, 863, 174, 213), Rect2(890, 853, 196, 223), Rect2(1165, 857, 187, 221)])
	rng.randomize()
	for i in range(75):
		stars.append(Vector2(rng.randf_range(45, 1235), rng.randf_range(112, 659)))
	for i in range(8):
		var voice = AudioStreamPlayer.new()
		voice.volume_db = -18
		add_child(voice)
		audio_players.append(voice)
	audio = audio_players[0]
	var save = ConfigFile.new()
	if save.load("user://records.cfg") == OK:
		scout_name = str(save.get_value("scout","name","Backyard Scout")).strip_edges().substr(0,18)
		if scout_name.is_empty(): scout_name = "Backyard Scout"
		run_best = save.get_value("run", "best", 0)
		completed_runs = save.get_value("run", "completed", 0)
		cleared_runs = save.get_value("run", "cleared", 0)
		longest_run = save.get_value("run", "longest", 0.0)
		unlocked_stage = clampi(int(save.get_value("stages", "unlocked", 1)), 1, STAGE_COUNT)
		stage_records = save.get_value("stages", "records", {})
		selected_stage = clampi(int(save.get_value("stages", "selected", unlocked_stage)), 1, unlocked_stage)
	scout_experience.load_config(save,stage_records)
	if not "--smoke-test" in OS.get_cmdline_user_args() and not "--balance-test" in OS.get_cmdline_user_args():
		var new_growth = not save.has_section("growth")
		growth.load_config(save)
		if growth.migrated:
			growth_notice = "Old talent costs refunded; merits kept."
		var backfilled = growth.claim_milestones(stage_records)
		if (new_growth or backfilled>0 or growth.migrated) and not screenshot_mode:
			save_progress()
	preview_rng.randomize()
	scout_profile.setup(self)
	settings.setup(self)
	if not save.has_section("experience") and not screenshot_mode: save_progress()
	roll_preview_enemy()
	if "--smoke-test" in OS.get_cmdline_user_args():
		smoke_test()
	if "--balance-test" in OS.get_cmdline_user_args():
		balance_test()
	if "--visual-test" in OS.get_cmdline_user_args():
		await visual_test()
	if "--screenshot" in OS.get_cmdline_user_args():
		screenshot_mode = true
		start_run()
		elapsed = 95.0
		wave = 5
		banner_timer = 0
		kills = 27
		xp = 5
		level = 3
		shots = 2
		for i in range(22):
			spawn_enemy()
			enemies[-1].p = constrain_actor(player + Vector2(rng.randf_range(-255, 255), rng.randf_range(-285, 285)), enemies[-1].radius, ENEMY_SIZES[enemies[-1].kind] / 2)
		for i in range(15):
			gems.append(Vector2(rng.randf_range(360, 900), rng.randf_range(210, 600)))
		var charger = make_enemy(Vector2(440, 490), 3)
		charger.mode = "windup"
		charger.timer = 0.6
		charger.aim = Vector2.RIGHT
		enemies.append(charger)
		var spitter = make_enemy(Vector2(820, 230), 4)
		spitter.mode = "windup"
		spitter.timer = 0.4
		spitter.aim = (player - spitter.p).normalized()
		enemies.append(spitter)
		shoot()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://preview.png")
		await shutdown()

func start_run() -> void:
	if selected_stage > unlocked_stage:
		return
	exit_stage_confirmation = false
	pause_choice = 1
	run_growth.assign(growth.bonuses())
	merit_rolls = 0
	merit_volleys = 0
	bramble_pending = false
	bloom_used = false
	rescue_used = false
	earned_scout_xp = 0
	scout_levels_gained = 0
	earned_packets = 0
	earned_acorns = 0
	earned_breakdown.clear()
	run_stage = selected_stage
	player = stage_start(run_stage)
	camera_center = player
	clear_touch()
	terrain_cell = Vector2i(2147483647, 2147483647)
	refresh_terrain()
	facing = Vector2.UP
	player_aim = Vector2.UP
	player_moving = false
	locomotion_direction = Vector2.UP
	attack_pose_timer = 0.0
	attack_phase = "idle"
	attack_clock = 0.0
	walk_distance = 0.0
	enemies.clear()
	bullets.clear()
	hostile_bullets.clear()
	repairs.clear()
	bonus_drops.clear()
	elite_spawn_index = 0
	gems.clear()
	effects.clear()
	settings.numbers.clear()
	hp = scout_max_hp()
	xp = 0
	level = 1
	kills = 0
	elapsed = 0.0
	wave = 1
	fire_timer = 0.0
	spawn_timer = 0.0
	hurt_timer = 0.0
	roll_timer = 0.0
	roll_time = 0.0
	speed = 230.0 + run_growth[3]*3 + run_growth[19]*8
	fire_rate = scout_fire_rate()
	damage = 3.0 + run_growth[0]*0.15 + run_growth[17]*0.45
	shots = 1
	magnet = 90.0 + run_growth[2]*7 + run_growth[18]*25
	pending_levels = 0
	bug_deaths.clear()
	roll_echoes.clear()
	upgrade_fx.clear()
	echo_clock = 0.0
	boot_distance = 0.0
	upgrade_ranks.fill(0)
	next_enemy_id = 0
	encounter_rewards = 0
	pending_encounter_rewards = 0
	boss_spawned = false
	damage_dealt = 0
	damage_taken = 0
	banner = "WAVE 01 / CRAWLERS"
	banner_timer = 2.5
	controller_choice = 0
	shield = 0
	guard_absorbed_hit = false
	guard_hit_time = 0.0
	guard_break_time = 0.0
	state = "playing"
	previous_state = "playing"
	if run_growth[7]>0:
		shield = 2
	if run_growth[6]>0:
		pending_levels = 1
		show_upgrades()

func _exit_tree() -> void:
	for voice in audio_players:
		voice.stop()
		voice.stream = null
	sound_cache.clear()

func shutdown() -> void:
	state = "title"
	for voice in audio_players:
		voice.stop()
		voice.stream = null
	sound_cache.clear()
	# Let the audio thread release playback references before test shutdown.
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func ui_offset() -> Vector2:
	var offset = (get_viewport_rect().size - Vector2(720,1280)) / 2
	if state == "title": offset.y = 0
	return offset

func pause_hit_rect() -> Rect2:
	return Rect2(PAUSE_BUTTON.position - Vector2(0, ui_offset().y), PAUSE_BUTTON.size)

func roll_hit_rect() -> Rect2:
	return Rect2(ROLL_BUTTON.position + Vector2(0, ui_offset().y), ROLL_BUTTON.size)

func can_begin_drag(position: Vector2) -> bool:
	return state == "playing" and not pause_hit_rect().has_point(position) and not roll_hit_rect().has_point(position)

func update_drag(position: Vector2) -> void:
	var displacement = position - drag_origin
	# A floating origin allows quick direction changes after long swipes.
	if displacement.length() > DRAG_RADIUS:
		drag_origin = position - displacement.normalized() * DRAG_RADIUS
		displacement = position - drag_origin
	touch_move = displacement / DRAG_RADIUS

func clear_touch() -> void:
	mouse_dragging = false
	move_touch = -1
	move_touch_active = false
	touch_move = Vector2.ZERO

func home_tab_rect(index: int) -> Rect2:
	return Rect2(30 + index * 220, 1160, 220, 94)

func return_home() -> void:
	var ready_growth = state in ["won", "dead"] and next_growth_ready()
	if state == "won":
		selected_stage = mini(run_stage + 1, unlocked_stage)
	roll_preview_enemy()
	clear_touch()
	state = "title"
	home_tab = 1
	if ready_growth:
		home_tab = 0
		focus_growth(growth.growth_level())

func next_growth_ready() -> bool:
	var next = growth.growth_level()
	return next < 100 and growth.status(next,stage_records) == "READY"

func continue_adventure() -> void:
	if state == "won" and run_stage < STAGE_COUNT and run_stage < unlocked_stage:
		selected_stage = run_stage + 1
	start_run()

func activate_pointer(position: Vector2) -> void:
	if state=="paused" and exit_stage_confirmation:
		if EXIT_CANCEL_BUTTON.has_point(position):
			exit_stage_confirmation = false
			toggle_pause()
		elif EXIT_CONFIRM_BUTTON.has_point(position):
			exit_to_camp()
		return
	if state=="paused" and not exit_stage_confirmation and (PAUSE_SKILLS_TAB.has_point(position) or PAUSE_CONTROLS_TAB.has_point(position)):
		pause_page = 0 if PAUSE_SKILLS_TAB.has_point(position) else 1
		return
	if state=="paused" and EXIT_STAGE_BUTTON.has_point(position):
		request_exit_stage()
		return
	if state == "title":
		for tab in range(3):
			if home_tab_rect(tab).has_point(position):
				home_tab = tab
				return
		if home_tab == 0:
			if GROWTH_HEADER_LEFT.has_point(position):
				scout_handbook = false
				focus_growth(mini(growth.growth_level(),99))
			elif GROWTH_HEADER_RIGHT.has_point(position):
				scout_handbook = false
				focus_growth(100+clampi(growth.growth_level()/10-1,0,9))
			elif Rect2(210,1106,300,40).has_point(position):
				scout_handbook = not scout_handbook
			elif not scout_handbook:
				growth_pointer(position)
			return
		if home_tab == 1 and STAGE_PREVIOUS.has_point(position):
			select_stage(selected_stage - 1)
		elif home_tab == 1 and STAGE_NEXT.has_point(position):
			select_stage(selected_stage + 1)
		elif home_tab == 1 and HOME_PLAY.has_point(position):
			start_run()

		return
	if state in ["dead", "won"] and HOME_RETURN.has_point(position):
		return_home()
		return
	if state in ["playing", "upgrade"] and pause_hit_rect().has_point(position):
		toggle_pause()
	elif state == "playing" and roll_hit_rect().has_point(position):
		start_roll()
	elif state == "paused" and RESUME_BUTTON.has_point(position):
		toggle_pause()
	elif state == "paused" and SOUND_BUTTON.has_point(position):
		mute = not mute
		if mute:
			for voice in audio_players:
				voice.stop()
	elif state in ["title", "dead", "won"] and START_BUTTON.has_point(position):
		continue_adventure()
	elif state == "upgrade":
		for i in range(upgrades.size()):
			if upgrade_card_rect(i).has_point(position):
				choose_upgrade(i)
				break

func _input(event: InputEvent) -> void:
	# Capture gameplay fingers before GUI controls can consume touch/drag events.
	if state in ["playing", "upgrade", "paused"] and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		_unhandled_input(event)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if browser_touch.suppress(event): return
	# Drawn menus use a centered 720x1280 layout; pointers share that transform.
	if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouse:
		event = event.duplicate()
		event.position -= ui_offset()
	if settings.handle(event): return
	if scout_profile.handle(event): return
	if event is InputEventScreenTouch:
		album_view.hover_point = Vector2.INF
	elif event is InputEventMouseMotion:
		album_view.hover_point = event.position-GROWTH_VIEW.position if state=="title" and home_tab==0 and not scout_handbook else Vector2.INF
		if state=="paused":
			var buttons = [EXIT_CANCEL_BUTTON,EXIT_CONFIRM_BUTTON] if exit_stage_confirmation else [SOUND_BUTTON,RESUME_BUTTON,EXIT_STAGE_BUTTON]
			for index in range(buttons.size()):
				if buttons[index].has_point(event.position):
					if exit_stage_confirmation: exit_choice = index
					else: pause_choice = index
	if state=="paused":
		if event is InputEventKey and event.pressed and not event.echo and pause_key(event.keycode):
			return
		if event is InputEventJoypadButton and event.pressed:
			var keys = {JOY_BUTTON_DPAD_UP:KEY_UP,JOY_BUTTON_DPAD_DOWN:KEY_DOWN,JOY_BUTTON_DPAD_LEFT:KEY_LEFT,JOY_BUTTON_DPAD_RIGHT:KEY_RIGHT,JOY_BUTTON_A:KEY_ENTER,JOY_BUTTON_B:KEY_ESCAPE,JOY_BUTTON_START:KEY_ESCAPE}
			if keys.has(event.button_index) and pause_key(keys[event.button_index]): return
	if growth_input(event):
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if can_begin_drag(event.position) and not move_touch_active and not mouse_dragging:
				move_touch = event.index
				move_touch_active = true
				drag_origin = event.position
				touch_move = Vector2.ZERO
			else:
				activate_pointer(event.position)
		elif move_touch_active and event.index == move_touch:
			clear_touch()
		return
	if event is InputEventScreenDrag:
		if move_touch_active and event.index == move_touch and state == "playing":
			update_drag(event.position)
		return
	if event is InputEventMouseMotion and mouse_dragging:
		if state == "playing" and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			update_drag(event.position)
		else:
			clear_touch()
		return
	if event is InputEventMouseMotion and state == "upgrade":
		for i in range(upgrades.size()):
			if upgrade_card_rect(i).has_point(event.position):
				controller_choice = i
	if event is InputEventKey and event.pressed and not event.echo:
		if state == "title" and home_tab == 0 and not scout_handbook:
			if growth_key(event.keycode):
				return
		if event.keycode == KEY_M:
			mute = not mute
			if mute:
				for voice in audio_players:
					voice.stop()
		if state == "title" and event.keycode in [KEY_UP, KEY_DOWN]:
			home_tab = posmod(home_tab + (-1 if event.keycode == KEY_UP else 1), 3)
		elif state == "title" and event.keycode in [KEY_LEFT, KEY_RIGHT]:
			if home_tab == 1:
				select_stage(selected_stage + (-1 if event.keycode == KEY_LEFT else 1))
			else:
				home_tab = posmod(home_tab + (-1 if event.keycode == KEY_LEFT else 1), 3)
		if event.keycode == KEY_ESCAPE and state in ["dead", "won"]:
			return_home()
		if event.keycode == KEY_ENTER and state in ["title", "dead", "won"]:
			continue_adventure()
		elif event.keycode == KEY_ESCAPE and state in ["playing", "upgrade", "paused"]:
			toggle_pause()
		elif event.keycode == KEY_SPACE and state == "playing" and roll_timer <= 0:
			start_roll()
		elif state == "upgrade" and event.keycode in [KEY_1, KEY_2, KEY_3]:
			choose_upgrade(event.keycode - KEY_1)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if can_begin_drag(event.position) and not move_touch_active:
				mouse_dragging = true
				drag_origin = event.position
				touch_move = Vector2.ZERO
			else:
				activate_pointer(event.position)
		elif mouse_dragging:
			clear_touch()
	if event is InputEventJoypadButton and event.pressed:
		if state == "title" and home_tab == 0 and not scout_handbook:
			var mapped = {JOY_BUTTON_DPAD_UP:KEY_UP,JOY_BUTTON_DPAD_DOWN:KEY_DOWN,JOY_BUTTON_DPAD_LEFT:KEY_LEFT,JOY_BUTTON_DPAD_RIGHT:KEY_RIGHT,JOY_BUTTON_A:KEY_ENTER,JOY_BUTTON_B:KEY_ESCAPE,JOY_BUTTON_LEFT_SHOULDER:KEY_PAGEUP,JOY_BUTTON_RIGHT_SHOULDER:KEY_PAGEDOWN}
			if mapped.has(event.button_index) and growth_key(mapped[event.button_index]):
				return
		if state == "title" and event.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]:
			home_tab = posmod(home_tab + (-1 if event.button_index == JOY_BUTTON_DPAD_UP else 1), 3)
		elif state == "title" and event.button_index in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
			if home_tab == 1:
				select_stage(selected_stage + (-1 if event.button_index == JOY_BUTTON_DPAD_LEFT else 1))
			else:
				home_tab = posmod(home_tab + (-1 if event.button_index == JOY_BUTTON_DPAD_LEFT else 1), 3)
		elif state in ["dead", "won"] and event.button_index == JOY_BUTTON_B:
			return_home()
		if event.button_index == JOY_BUTTON_A:
			if state in ["title", "dead", "won"]:
				continue_adventure()
			elif state == "upgrade":
				choose_upgrade(controller_choice)
			elif state == "playing":
				start_roll()
		elif state == "upgrade" and event.button_index in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]:
			controller_choice = posmod(controller_choice + (-1 if event.button_index in [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_UP] else 1), upgrades.size())
		elif event.button_index == JOY_BUTTON_START:
			toggle_pause()

func toggle_pause() -> void:
	clear_touch()
	if state == "paused":
		if exit_stage_confirmation:
			exit_stage_confirmation = false
			return
		state = previous_state
	elif state in ["playing", "upgrade"]:
		previous_state = state
		pause_choice = 1
		pause_page = 0
		exit_stage_confirmation = false
		state = "paused"

func start_roll() -> void:
	if state != "playing" or roll_timer > 0:
		return
	roll_time = ROLL_DURATION
	roll_timer = roll_cooldown()
	merit_rolls += 1
	if run_growth[12]>0 and merit_rolls%4==0 and hp<ceili(scout_max_hp()/2.0):
		hp += 1
		burst(player,LEAF_GREEN,6)
	roll_direction = facing.normalized()
	attack_phase = "idle"
	attack_clock = 0.0
	tone(220, 0.1)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		growth_drag_id = -2
		growth_velocity = 0
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and state in ["playing", "upgrade", "paused"]:
		toggle_pause()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state in ["playing", "upgrade"] and not screenshot_mode and not "--smoke-test" in OS.get_cmdline_user_args() and not "--balance-test" in OS.get_cmdline_user_args():
		toggle_pause()

func _process(delta: float) -> void:
	browser_touch.drain(self)
	settings.advance(delta)
	if state=="title" and not screenshot_mode and not settings.values.low_graphics:
		home_garden.advance(delta)
	album_view.visible = state == "title" and home_tab == 0 and not scout_handbook and scout_profile.page.is_empty() and not settings.opened
	album_view.position = GROWTH_VIEW.position + ui_offset()
	if album_view.visible:
		if growth_drag_id == -2 and absf(growth_velocity)>1:
			growth_scroll = clampf(growth_scroll+growth_velocity*minf(delta,0.05),0,growth_max_scroll())
			growth_velocity = move_toward(growth_velocity,0,1800*delta)
		album_view.queue_redraw()
	else:
		growth_drag_id = -2
		growth_velocity = 0
	if state == "title" and home_tab == 1 and not screenshot_mode:
		preview_motion.advance(delta)
	if state == "playing" and not screenshot_mode:
		simulate(minf(delta, 0.05))
	elif state in ["won", "dead"] and not screenshot_mode:
		update_bug_deaths(minf(delta, 0.05))
	queue_redraw()

func simulate(dt: float, bot_move: Vector2 = Vector2.INF) -> void:
	if state != "playing":
		return
	update_bug_deaths(dt)
	update_upgrade_fx(dt)
	elapsed += dt
	guard_hit_time = maxf(0, guard_hit_time - dt)
	guard_break_time = maxf(0, guard_break_time - dt)
	var last_wave = wave
	wave = 1 + int(minf(elapsed, SPAWN_DURATION - 0.001) / 20.0)
	banner_timer = maxf(0, banner_timer - dt)
	if last_wave != wave:
		if upgrade_ranks[6] > 0:
			shield = mini(guard_capacity(), shield + 1)
		if run_growth[13]>0 and wave%3==0:
			shield = mini(guard_capacity(),shield+1)
		banner = "WAVE %02d" % wave
		for kind in range(Tuning.START_WAVES.size()):
			if Tuning.START_WAVES[kind] == wave:
				banner += " / " + Tuning.ENEMY_NAMES[kind].to_upper()
		banner_timer = 2.5
	if elapsed >= Tuning.BOSS_ARRIVAL and elapsed < SPAWN_DURATION and not boss_spawned:
		spawn_boss()
	update_elite_schedule()
	hurt_timer = maxf(0, hurt_timer - dt)
	attack_pose_timer = maxf(0, attack_pose_timer - dt)
	roll_timer = maxf(0, roll_timer - dt)
	roll_time = maxf(0, roll_time - dt)
	var move = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).normalized()
	if bot_move != Vector2.INF:
		move = bot_move.normalized()
	elif move_touch_active or mouse_dragging:
		move = touch_move if touch_move.length() > 0.12 else Vector2.ZERO
	elif not Input.get_connected_joypads().is_empty():
		var device = Input.get_connected_joypads()[0]
		var stick = Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
		if stick.length() > 0.2:
			move = stick.limit_length()
	if move != Vector2.ZERO:
		facing = move
	if enemies.is_empty():
		if attack_phase == "idle":
			player_aim = facing
	var previous_player_position = player
	player = move_actor(player, (roll_direction * 230.0 * 1.9125 if roll_time > 0 else move * speed) * dt, 17)
	camera_center = player
	refresh_terrain()
	update_locomotion(player - previous_player_position)
	record_movement_fx(dt, previous_player_position)
	update_attack(dt)
	fire_timer -= dt
	if fire_timer <= 0 and not enemies.is_empty() and attack_phase != "windup" and roll_time <= 0:
		begin_attack()
		fire_timer = fire_rate
	spawn_timer -= dt
	if spawn_timer <= 0 and elapsed < SPAWN_DURATION:
		spawn_enemy()
		spawn_timer = maxf(0.17, 0.85 - wave * 0.065) * 1.15 * (1.5 if boss_spawned else 1.0) / Tuning.stage_density(run_stage) * Tuning.closing_spawn_delay(elapsed)
	for e in enemies:
		var previous_position: Vector2 = e.p
		update_enemy(e, dt)
		e.walk_distance += e.p.distance_to(previous_position)
		if enemy_contact(e,previous_position) and hurt_timer <= 0 and roll_time <= 0:
			hurt_player()
			e.p = constrain_actor(e.p + (e.p - player).normalized() * 40, e.radius, ENEMY_SIZES[e.kind] / 2)
			if state == "dead":
				return
	resolve_bramble()
	update_player_bullets(dt)
	update_hostile_bullets(dt)
	if state == "dead":
		return
	if elapsed >= SPAWN_DURATION and enemies.is_empty():
		hostile_bullets.clear()
		finish_run("won")
		return
	for e in enemies:
		update_enemy_health_feedback(e,dt)
		e.flash = maxf(0, e.flash - dt)
		e.recoil = maxf(0, e.recoil - dt)
	for i in range(gems.size() - 1, -1, -1):
		if gems[i].distance_to(player) < magnet:
			gems[i] = gems[i].move_toward(player, 430 * dt)
		if gems[i].distance_to(player) < 20:
			if upgrade_ranks[3] > 0:
				add_upgrade_fx(player + Vector2(0, 7), "gather", upgrade_ranks[3], Vector2.UP, 0.28)
			gems.remove_at(i)
			gain_xp()
	for i in range(repairs.size() - 1, -1, -1):
		if hp < scout_max_hp() and repairs[i].distance_to(player) < bonus_pickup_reach():
			repairs[i] = repairs[i].move_toward(player,300*dt)
		if repairs[i].distance_to(player) < 24:
			if hp < scout_max_hp():
				hp = mini(scout_max_hp(), hp + 2)
				repairs.remove_at(i)
				tone(520, 0.13)
	update_bonus_drops(dt)
	if pending_levels > 0 and state == "playing":
		show_upgrades()
	for i in range(effects.size() - 1, -1, -1):
		effects[i].p += effects[i].v * dt
		effects[i].life -= dt
		if effects[i].life <= 0:
			effects.remove_at(i)

func constrain_actor(p: Vector2, radius: float, edge_radius: float = -1.0) -> Vector2:
	# Only physical rocks block travel; the garden has no outer walls.
	for o in obstacles:
		var diff = p - o
		if diff.length() < 38 + radius:
			p = o + (diff.normalized() if diff.length() > 0.01 else Vector2.RIGHT) * (38 + radius)
	return p

func move_actor(p: Vector2, displacement: Vector2, radius: float, edge_radius: float = -1.0) -> Vector2:
	# Substeps keep fast rolls and charges from crossing solid pillars.
	var steps = maxi(1, int(ceil(displacement.length() / 10.0)))
	for i in range(steps):
		p = constrain_actor(p + displacement / steps, radius, edge_radius)
	return p

func clear_line(start: Vector2, end: Vector2) -> bool:
	for o in obstacles:
		if Combat.hit_fraction(start, end, o, 42) != INF:
			return false
	return true

func steering(e: Dictionary, desired: Vector2) -> Vector2:
	var result = desired
	for o in obstacles:
		var from_obstacle: Vector2 = e.p - o
		if from_obstacle.length() < 105 + e.radius and desired.dot(-from_obstacle.normalized()) > 0.1:
			var tangent = from_obstacle.normalized().orthogonal()
			if tangent.dot(desired) < 0:
				tangent = -tangent
			result = (tangent + from_obstacle.normalized() * 0.25).normalized()
	for other in enemies:
		if e == other:
			continue
		var diff: Vector2 = e.p - other.p
		var distance = diff.length()
		if distance < 0.01:
			result += Vector2.from_angle(mini(e.uid,other.uid)*2.39996)*(0.6 if e.uid>other.uid else -0.6)
		elif distance < e.radius + other.radius + 14:
			result += diff / distance * 0.6
	return result.normalized()

func update_player_bullets(dt: float) -> void:
	for bi in range(bullets.size() - 1, -1, -1):
		var b = bullets[bi]
		var start: Vector2 = b.p
		b.p += b.v * dt
		b.life -= dt
		if not b.has("hit_ids"):
			b.hit_ids = []
		var wall_hit = INF
		for o in obstacles:
			wall_hit = minf(wall_hit, Combat.hit_fraction(start, b.p, o, 41))
		var consumed = false
		# Resolve every pierced target along this swept segment in distance order.
		for contact in range(3):
			var first_hit = wall_hit
			var enemy_index = -1
			for ei in range(enemies.size()):
				var e = enemies[ei]
				if b.hit_ids.has(e.uid) or not enemy_targetable(e):
					continue
				var hit = Combat.hit_fraction(start, b.p, e.p, e.radius + 5)
				if hit < first_hit:
					first_hit = hit
					enemy_index = ei
			if enemy_index < 0:
				break
			var e = enemies[enemy_index]
			var power: float = b.get("power", damage) * (0.7 if e.kind==9 and e.mode=="brace" else 1.0) * (1.2 if run_growth[14]>0 and Tuning.is_major(e.kind) else 1.0)
			damage_dealt += minf(power, e.hp)
			mark_enemy_hit(e,minf(power,e.hp))
			e.hp -= power
			e.flash = 0.1
			e.recoil = 0.18
			e.hit_dir = b.v.normalized()
			add_upgrade_fx(e.p, "hit", 1, e.hit_dir, 0.14)
			if e.hp > 0:
				tone(210 if e.kind in [2, 5, 6] else 290, 0.035)
			var visual: Array = b.get("visual", [])
			if not visual.is_empty() and visual[8] > 0:
				add_upgrade_fx(e.p, "thump", visual[8], b.v.normalized(), 0.22)
			b.hit_ids.append(e.uid)
			if e.kind not in [5, 6] and e.mode != "rush":
				e.p = move_actor(e.p, b.v.normalized() * (6 + upgrade_ranks[8] * 6), e.radius, ENEMY_SIZES[e.kind] / 2)
			if e.hp <= 0:
				kill_enemy(enemy_index)
			if b.get("pierce", 0) <= 0:
				consumed = true
				break
			b.pierce -= 1
		if consumed or wall_hit != INF or b.life <= 0 or not world_view().grow(220).has_point(b.p):
			bullets.remove_at(bi)

func make_enemy(p: Vector2, kind: int) -> Dictionary:
	var health: float = [2, 2, 7, 4, 3, Tuning.BOSS_HEALTH, 65, 20, 30, 4.5, 3.0, 5.0][kind]
	if kind < 5:
		health += int(wave / 4) * [0, 0, 2, 1, 1][kind]
		if kind == 1 and wave >= 8:
			health += 1
	health *= Tuning.stage_health(run_stage,Tuning.is_major(kind))
	if kind<9: health *= 1.08 if Tuning.is_major(kind) else 1.12
	next_enemy_id += 1
	return {"uid": next_enemy_id, "p": constrain_actor(p, ENEMY_RADII[kind], ENEMY_SIZES[kind] / 2), "hp": health, "max_hp": health, "trail_hp": health, "display_hp": health, "bar_delay": 0.0, "radius": ENEMY_RADII[kind], "walk_distance": 0.0, "chain": 0, "speed": ([62.0, 125.0, 48.0, 82.0, 65.0, 42.0, 55.0, 100.0, 85.0, 62.0, 80.0, 68.0][kind] + wave * 3) * Tuning.stage_speed(run_stage), "kind": kind, "flash": 0.0, "recoil": 0.0, "hit_dir": Vector2.ZERO, "mode": "seek", "timer": 1.2, "aim": Vector2.UP}

func spawn_boss() -> void:
	if elapsed >= SPAWN_DURATION or boss_spawned: return
	boss_spawned = true
	var p = camera_center + Vector2(0, -world_view().size.y / 2 - 85)
	enemies.append(make_enemy(p, 5))
	banner = "BROODMOTHER / FINAL THREAT"
	banner_timer = 3.0
	tone(150, 0.3)

func update_elite_schedule() -> void:
	if elapsed >= 145 or elite_spawn_index >= ELITE_TIMES.size():
		return
	if elapsed < ELITE_TIMES[elite_spawn_index]:
		return
	for e in enemies:
		if Tuning.is_elite(e.kind):
			return
	var kind: int = ELITE_KINDS[elite_spawn_index]
	elite_spawn_index += 1
	var spawn_point = camera_center + Vector2((world_view().size.x / 2 + 85) * (-1 if elite_spawn_index % 2 == 0 else 1), 0)
	enemies.append(make_enemy(spawn_point, kind))
	banner = Tuning.ENEMY_NAMES[kind].to_upper() + " / " + ("BOSS" if kind == 6 else "MINIBOSS")
	banner_timer = 3.0
	spawn_timer = maxf(spawn_timer, 2.0)

func update_elite(e: Dictionary, dt: float) -> void:
	e.timer -= dt
	var direction: Vector2 = (player - e.p).normalized()
	if e.mode == "windup":
		if e.timer <= 0:
			if e.kind == 8:
				for offset in [-0.24, 0.0, 0.24]:
					add_hostile_shot(e.p, e.aim.rotated(offset), 195, 5)
				e.mode = "recover"
				e.timer = 0.75
			else:
				e.mode = "rush"
				e.timer = 0.5 if e.kind == 6 else 0.3
		return
	if e.mode == "rush":
		var velocity = 420.0 if e.kind == 6 else 480.0
		var wanted: Vector2 = e.p + e.aim * velocity * dt
		e.p = move_actor(e.p, e.aim * velocity * dt, e.radius, ENEMY_SIZES[e.kind] / 2)
		if e.timer <= 0 or e.p.distance_to(wanted) > 2:
			e.mode = "recover"
			e.timer = 0.8
		return
	if e.mode == "recover":
		if e.timer <= 0:
			if e.kind == 6 and e.chain > 0:
				e.chain -= 1
				e.mode = "windup"
				e.aim = direction
				e.timer = 0.8
			else:
				e.mode = "seek"
				e.timer = 2.4
		return
	if e.timer <= 0 and clear_line(e.p, player) and (e.kind == 8 or e.p.distance_to(player) < 320):
		e.mode = "windup"
		e.aim = direction
		e.timer = 1.0 if e.kind == 6 else 0.85
		e.chain = 1 if e.kind == 6 else 0
		return
	if e.kind == 8 and e.p.distance_to(player) < (140 if elapsed>=SPAWN_DURATION else 260):
		direction = direction.orthogonal() * 0.7 - direction * 0.3
	elif e.kind == 7 and e.p.distance_to(player) > 160:
		direction = (direction + direction.orthogonal() * 0.4).normalized()
	var pursuit_speed: float = maxf(e.speed, 185.0) if Tuning.is_major(e.kind) and e.p.distance_to(player) > 240 else e.speed
	walk_enemy(e,direction,pursuit_speed,dt)

func update_enemy(e: Dictionary, dt: float) -> void:
	# Catch-up applies outside the visible playfield only; never teleport or award
	# kills for stragglers. Distance-based pace bounds long endless-map tails.
	if not world_view().grow(28).has_point(e.p):
		var catchup = maxf(speed*1.65,e.p.distance_to(player)/1.5)
		e.p = move_actor(e.p, steering(e,(player-e.p).normalized())*catchup*dt,e.radius)
		e.mode="seek"
		e.timer=maxf(e.timer,0.8)
		return
	if e.kind>=9:
		update_garden_bug(e,dt)
		return
	if Tuning.is_elite(e.kind):
		update_elite(e, dt)
		return
	e.timer -= dt
	var direction: Vector2 = (player - e.p).normalized()
	var distance: float = player.distance_to(e.p)
	if e.kind == 3:
		if e.mode == "windup":
			if e.timer <= 0:
				e.mode = "rush"
				e.timer = Tuning.CHARGE_SECONDS
				tone(180, 0.09)
			return
		if e.mode == "rush":
			var wanted: Vector2 = e.p + e.aim * Tuning.CHARGE_SPEED * dt
			e.p = move_actor(e.p, e.aim * Tuning.CHARGE_SPEED * dt, e.radius, ENEMY_SIZES[e.kind] / 2)
			if e.timer <= 0 or wanted.distance_to(e.p) > 2:
				e.mode = "recover"
				e.timer = Tuning.CHARGE_RECOVERY
			return
		if e.mode == "recover":
			if e.timer <= 0:
				e.mode = "seek"
				e.timer = 1.0
			return
		if e.timer <= 0 and distance < 340 and clear_line(e.p, player):
			e.mode = "windup"
			e.timer = Tuning.CHARGE_WARNING
			e.aim = direction
			return
	elif e.kind in [4, 5]:
		if e.mode == "windup":
			if e.timer <= 0:
				fire_enemy(e)
				e.mode = "seek"
				e.timer = (1.4 if e.hp < e.max_hp / 2.0 else 2.1) if e.kind == 5 else 2.3
			return
		if e.timer <= 0 and (e.kind == 5 or clear_line(e.p, player)):
			e.mode = "windup"
			e.timer = 0.95 if e.kind == 5 else Tuning.SHOT_WARNING
			e.aim = direction
			return
		if e.kind == 4:
			if elapsed>=SPAWN_DURATION:
				direction=direction if distance>145 else direction.orthogonal()*0.35
			elif distance < 200:
				direction = -direction
			elif distance < 285:
				direction = direction.orthogonal() * 0.6
	var pursuit_speed: float = maxf(e.speed, 185.0) if Tuning.is_major(e.kind) and e.p.distance_to(player) > 240 else e.speed
	walk_enemy(e,direction,pursuit_speed,dt)

func fire_enemy(e: Dictionary) -> void:
	if e.kind == 5:
		var count = 12 if e.hp < e.max_hp / 2.0 else 8
		for i in range(count):
			add_hostile_shot(e.p, e.aim.rotated(TAU * i / count), 155, 7)
		for angle in [-0.2, 0.0, 0.2]:
			add_hostile_shot(e.p, e.aim.rotated(angle), 235, 6)
	else:
		add_hostile_shot(e.p, e.aim, 220, 6)
	tone(280, 0.06)

func add_hostile_shot(p: Vector2, direction: Vector2, velocity: float, radius: float) -> void:
	hostile_bullets.append({"p": p + direction * 24, "v": direction * velocity, "life": 7.0, "radius": radius})

func update_hostile_bullets(dt: float) -> void:
	for i in range(hostile_bullets.size() - 1, -1, -1):
		var b = hostile_bullets[i]
		var start: Vector2 = b.p
		b.p += b.v * dt
		b.life -= dt
		var wall_hit = INF
		for o in obstacles:
			wall_hit = minf(wall_hit, Combat.hit_fraction(start, b.p, o, 38 + b.radius))
		var player_hit = Combat.hit_fraction(start, b.p, player, 15 + b.radius)
		if player_hit < wall_hit:
			if roll_time <= 0 and hurt_timer <= 0:
				hurt_player()
		if player_hit != INF or wall_hit != INF or b.life <= 0 or not world_view().grow(220).has_point(b.p):
			hostile_bullets.remove_at(i)

func hurt_player() -> void:
	settings.vibrate()
	guard_absorbed_hit = shield > 0
	settings.scout_hit(guard_absorbed_hit)
	if shield > 0:
		shield -= 1
		guard_hit_time = 0.32
		if shield == 0:
			bramble_pending = run_growth[9]>0
			guard_break_time = 0.55
		tone(740, 0.12)
	else:
		hp -= 1
		burst(player, PINK, 8)
		tone(90, 0.18)
	damage_taken += 1
	hurt_timer = 1.0
	if hp <= 0:
		if run_growth[8]>0 and not rescue_used:
			rescue_used = true
			hp = ceili(scout_max_hp()/2.0)
			hurt_timer = 2.0
			guard_hit_time = 0.55
			burst(player,LEAF_GREEN,20)
			banner = "SECOND WIND"
			banner_timer = 2.0
		else:
			finish_run("dead")

func kill_enemy(index: int) -> void:
	var e = enemies[index]
	var death = e.duplicate(true)
	death.life = 0.8 if Tuning.is_major(e.kind) else 0.55
	death.duration = death.life
	death.angle = e.aim.angle() if e.mode in ["windup", "rush", "recover"] else (player - e.p).angle()
	if death.hit_dir == Vector2.ZERO:
		death.hit_dir = (e.p - player).normalized()
	bug_deaths.append(death)
	if bug_deaths.size() > 64:
		bug_deaths.pop_front()
	var core_count = 14 if e.kind == 6 else (8 if Tuning.is_major(e.kind) else (2 if e.kind in [2, 3, 4, 9, 10, 11] else 1))
	for i in range(core_count):
		gems.append(constrain_actor(e.p + Vector2.from_angle(i * TAU / core_count) * (14 if core_count > 1 else 0), 8))
	burst(e.p, Color("cbb78b"), 6)
	enemies.remove_at(index)
	kills += 1
	if run_growth[10]>0 and kills%5==0:
		gems.append(e.p+Vector2(0,12))
	if kills % (30 + (run_stage-1)/5*6) == 0 or Tuning.is_major(e.kind):
		repairs.append(constrain_actor(e.p + Vector2(15, 0), 12))
	if Tuning.is_major(e.kind):
		bonus_drops.append({"p": constrain_actor(e.p - Vector2(18, 0), 12), "kind": 2 if e.kind in [5, 6] else 3})
	elif kills % 50 == 0:
		bonus_drops.append({"p": e.p, "kind": 3})
	if Tuning.is_elite(e.kind) and encounter_rewards < 3:
		encounter_rewards += 1
		pending_encounter_rewards += 1
		pending_levels += 1
	# Open rewards after simulation finishes, never inside projectile iteration.
	tone(340, 0.045)

func spawn_enemy() -> void:
	if elapsed >= SPAWN_DURATION or enemies.size() >= 70:
		return
	var p: Vector2
	var edges = world_view().grow(60)
	match rng.randi_range(0, 3):
		0: p = Vector2(rng.randf_range(edges.position.x, edges.end.x), edges.position.y)
		1: p = Vector2(rng.randf_range(edges.position.x, edges.end.x), edges.end.y)
		2: p = Vector2(edges.position.x, rng.randf_range(edges.position.y, edges.end.y))
		3: p = Vector2(edges.end.x, rng.randf_range(edges.position.y, edges.end.y))
	if p.distance_to(player) < 200:
		p = camera_center * 2 - p
	var kind = 0
	var roll = rng.randf()
	if wave >= 4 and roll < 0.18:
		kind = 4
	elif wave >= 2 and roll < 0.4:
		kind = 3
	elif wave >= 3 and roll < 0.58:
		kind = 1
	elif wave >= 5 and roll < 0.76:
		kind = 2
	# Replace a portion of existing spawns; don't stack extra waves on top.
	if wave>=2 and roll>=0.80 and roll<0.88: kind=9
	elif wave>=3 and roll>=0.88 and roll<0.95: kind=10
	elif wave>=4 and roll>=0.95: kind=11
	enemies.append(make_enemy(p, kind))

func target_direction() -> Vector2:
	var target = player + facing
	var best = INF
	for e in enemies:
		if not enemy_targetable(e): continue
		var d: float = player.distance_squared_to(e.p)
		if d < best and clear_line(player, e.p):
			best = d
			target = e.p
	if best == INF:
		return Vector2.ZERO
	return (target - player).normalized()

func begin_attack() -> void:
	var direction = target_direction()
	if direction == Vector2.ZERO:
		player_aim = facing
		return
	player_aim = direction
	attack_phase = "windup"
	attack_clock = minf(0.11, fire_rate * 0.35)

func update_attack(dt: float) -> void:
	if attack_phase == "idle":
		return
	attack_clock -= dt
	if attack_clock > 0:
		return
	match attack_phase:
		"windup": shoot(player_aim)
		"release":
			attack_phase = "recover"
			attack_clock = minf(0.08, fire_rate * 0.2)
		"recover": attack_phase = "idle"

func shoot(locked_direction: Vector2 = Vector2.ZERO) -> void:
	var dir = locked_direction if locked_direction != Vector2.ZERO else target_direction()
	if dir == Vector2.ZERO:
		return
	garden_audio.play(self,"seed-release")
	player_aim = dir
	attack_pose_timer = 0.2
	attack_phase = "release"
	attack_clock = minf(0.1, fire_rate * 0.3)
	for i in range(shots):
		var angle = (i - (shots - 1) / 2.0) * 0.16
		var v = dir.rotated(angle)
		bullets.append({"p": scout_muzzle(dir), "v": v * 720, "life": 1.4, "power": damage * (SCATTER_POWER[upgrade_ranks[1]]), "pierce": upgrade_ranks[7], "hit_ids": [], "visual": upgrade_ranks.duplicate()})
	merit_volleys += 1
	if run_growth[11]>0 and merit_volleys%6==0:
		for angle in [-0.30,0.30]:
			bullets.append({"p":scout_muzzle(dir),"v":dir.rotated(angle)*720,"life":1.4,"power":damage*0.6,"pierce":0,"hit_ids":[],"visual":upgrade_ranks.duplicate()})
		add_upgrade_fx(player,"upgrade",1,dir,0.25)
	tone(880, 0.035)

func xp_required() -> int:
	return RUN_XP_STEPS[clampi(level-1,0,RUN_XP_STEPS.size()-1)]

func roll_cooldown() -> float:
	return maxf(0.75,2.5 - upgrade_ranks[4] * 0.25 - run_growth[4]*0.04 - run_growth[20]*0.12)

func guard_capacity() -> int:
	return 2 + upgrade_ranks[6]

func gain_xp() -> void:
	if level >= MAX_LEVEL:
		return
	xp += 1
	while level < MAX_LEVEL and xp >= xp_required():
		xp -= xp_required()
		level += 1
		if run_growth[15]>0 and level>=MAX_LEVEL and not bloom_used:
			bloom_used = true
			pending_levels += 1
			banner = "FINAL BLOOM / BONUS SKILL"
			banner_timer = 2.0
		damage = 3.0 + (level - 1) * LEVEL_SEED_POWER + upgrade_ranks[2] + run_growth[0]*0.15 + run_growth[17]*0.45
		pending_levels += 1
	if level >= MAX_LEVEL:
		xp = 0
	if pending_levels > 0 and state == "playing":
		show_upgrades()

func upgrade_description(kind: int) -> String:
	match kind:
		0: return "Shot delay %.2fs > %.2fs" % [fire_rate, fire_rate / 1.15]
		1: return "%d > %d seeds; %d%% power each" % [shots, shots + 1, int(SCATTER_POWER[mini(upgrade_ranks[1] + 1, 5)] * 100)]
		2: return "Seed power %.1f > %.1f" % [damage, damage + 1]
		3: return "Pickup reach %.0f > %.0f" % [magnet, magnet + 40]
		4: return "Roll ready %.2fs > %.2fs" % [roll_cooldown(), roll_cooldown() - 0.25]
		5: return "Run speed %.0f > %.0f" % [speed, speed + 15]
		6: return "Guard %d > %d; +1 each wave" % [guard_capacity(), guard_capacity() + 1]
		7: return "Pierce %d > %d extra bugs" % [upgrade_ranks[7], upgrade_ranks[7] + 1]
		8: return "Knockback %d > %d" % [6 + upgrade_ranks[8] * 6, 12 + upgrade_ranks[8] * 6]
	return ""

func show_upgrades() -> void:
	clear_touch()
	upgrades.clear()
	# One choice from each family prevents rolls of three utility-only cards.
	for family in ["SHARPSHOOTER", "CROWD CONTROL", "TRAIL SURVIVOR"]:
		var pool: Array[int] = []
		for kind in range(UPGRADE_NAMES.size()):
			if UPGRADE_FAMILIES[kind] == family and upgrade_ranks[kind] < UPGRADE_CAPS[kind]:
				pool.append(kind)
		if not pool.is_empty():
			upgrades.append(pool[rng.randi_range(0, pool.size() - 1)])
	# A completed family yields its slot to another available upgrade.
	var remaining: Array[int] = []
	for kind in range(UPGRADE_NAMES.size()):
		if upgrade_ranks[kind] < UPGRADE_CAPS[kind] and not upgrades.has(kind):
			remaining.append(kind)
	while upgrades.size() < 3 and not remaining.is_empty():
		var index = rng.randi_range(0, remaining.size() - 1)
		upgrades.append(remaining[index])
		remaining.remove_at(index)
	if upgrades.is_empty():
		pending_levels = 0
		state = "playing"
		return
	controller_choice = 0
	state = "upgrade"
	tone(660, 0.16)

func choose_upgrade(index: int) -> void:
	if index < 0 or index >= upgrades.size():
		return
	var kind = upgrades[index]
	if upgrade_ranks[kind] >= UPGRADE_CAPS[kind]:
		return
	upgrade_ranks[kind] += 1
	add_upgrade_fx(player + Vector2(0, -15), "upgrade", upgrade_ranks[kind], Vector2.UP, 0.6)
	match kind:
		0: fire_rate = scout_fire_rate() / pow(1.15, upgrade_ranks[0])
		1: shots = 1 + upgrade_ranks[1]
		2: damage = 3.0 + (level - 1) * LEVEL_SEED_POWER + upgrade_ranks[2] + run_growth[0]*0.15 + run_growth[17]*0.45
		3: magnet = 90.0 + upgrade_ranks[3] * 40 + run_growth[2]*7 + run_growth[18]*25
		4: roll_timer = minf(roll_timer, roll_cooldown())
		5: speed = 230.0 + upgrade_ranks[5] * 15 + run_growth[3]*3 + run_growth[19]*8
		6: shield = guard_capacity()
	pending_encounter_rewards = maxi(0, pending_encounter_rewards - 1)
	pending_levels = maxi(0, pending_levels - 1)
	state = "playing"
	if pending_levels > 0:
		show_upgrades()

func finish_run(result: String) -> void:
	if state in ["dead", "won"]:
		return
	clear_touch()
	state = result
	if screenshot_mode or "--smoke-test" in OS.get_cmdline_user_args() or "--balance-test" in OS.get_cmdline_user_args():
		return
	run_best = maxi(run_best, kills)
	completed_runs += 1
	if result == "won":
		cleared_runs += 1
	longest_run = maxf(longest_run, elapsed)
	var first_clear = result == "won" and not bool(stage_records.get(str(run_stage),{}).get("cleared",false))
	earned_breakdown = growth.reward_parts(kills,result == "won",first_clear,run_stage,elapsed)
	earned_packets = growth.reward(kills,result == "won",first_clear,run_stage,elapsed)
	var old_scout_level = scout_experience.level
	earned_scout_xp = scout_experience.reward(run_stage,result=="won",elapsed,kills)
	scout_levels_gained = scout_experience.level-old_scout_level
	record_stage_result(result)
	earned_acorns = growth.claim_milestones(stage_records)
	save_progress()

func save_progress() -> bool:
	progress_save_failed = false
	var save = ConfigFile.new()
	var read_error = save.load("user://records.cfg")
	if read_error != OK and read_error != ERR_FILE_NOT_FOUND:
		progress_save_failed = true
		push_warning("Existing progress could not be read; save left untouched.")
		return false
	save.set_value("run", "best", run_best)
	save.set_value("scout", "name", scout_name)
	save.set_value("run", "completed", completed_runs)
	save.set_value("run", "cleared", cleared_runs)
	save.set_value("run", "longest", longest_run)
	save.set_value("stages", "unlocked", unlocked_stage)
	save.set_value("stages", "selected", mini(selected_stage, unlocked_stage))
	save.set_value("stages", "records", stage_records)
	growth.write_config(save)
	scout_experience.write_config(save)
	if save.save("user://records.cfg") != OK:
		progress_save_failed = true
		push_warning("Progress could not be saved.")
		return false
	return true

func burst(p: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		effects.append({"p": p, "v": Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(50, 140), "life": 0.25, "color": color})

func tone(freq: float, _duration: float) -> void:
	var cues={90:"scout-hurt",150:"boss-arrival",180:"charge-warning",210:"shell-hit",290:"soft-hit",220:"roll-rustle",280:"bug-spit",340:"bug-defeat",520:"berry-heal",660:"upgrade",740:"guard-block",880:"seed-pickup"}
	garden_audio.play(self,cues.get(int(freq),"upgrade"))

func ui_font(size: int) -> Font:
	return heading_font if heading_font != null and size >= 19 else font

func text_at(p: Vector2, text: String, size: int = 18, color: Color = WHITE) -> void:
	draw_string(ui_font(size), p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func center_text(y: float, text: String, size: int, color: Color = WHITE) -> void:
	text_at(Vector2(360 - ui_font(size).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x / 2, y), text, size, color)

func paper_panel(rect: Rect2, border: Color = JOURNAL_INK) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	draw_style_box(style, rect)

func panel(rect: Rect2, accent: Color = LEAF_GREEN) -> void:
	paper_panel(rect, accent)

func journal_leaf(origin: Vector2) -> void:
	draw_line(origin + Vector2(-7, 14), origin + Vector2(7, -15), JOURNAL_INK, 2, true)
	for side in [-1, 1]:
		for i in range(3):
			var base = origin + Vector2(i * 3 - 4, 9 - i * 9)
			var leaf = PackedVector2Array([base, base + Vector2(side * 9, -2), base + Vector2(side * 11, -10), base + Vector2(side * 3, -8)])
			draw_colored_polygon(leaf, LEAF_GREEN)
			draw_polyline(leaf + PackedVector2Array([leaf[0]]), JOURNAL_INK, 1.2, true)

func journal_heart(origin: Vector2, filled: bool) -> void:
	var points = PackedVector2Array()
	for i in range(32):
		var t = i * TAU / 32
		points.append(origin + Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2*t) - 2*cos(3*t) - cos(4*t))) * 0.67)
	draw_colored_polygon(points, Color("c45343") if filled else Color("b3a58a"))
	draw_polyline(points + PackedVector2Array([points[0]]), JOURNAL_INK, 1.5, true)

func story_piece(rect: Rect2, region: Rect2, tint: Color = Color.WHITE) -> void:
	draw_texture_rect_region(STORY_PIECES, rect, region, tint)

func draw_stage_arrow(rect: Rect2, direction: int, enabled: bool) -> void:
	# A native square asset avoids squeezing the wide Play leaf into a tall sliver.
	var tint = Color.WHITE if enabled else Color(0.80,0.84,0.74)
	draw_texture_rect(STORY_NAVIGATION,rect,false,tint)
	var center = rect.get_center()
	var points = PackedVector2Array([
		center+Vector2(-direction*5.5,-10),
		center+Vector2(direction*5.5,0),
		center+Vector2(-direction*5.5,10)
	])
	var ink = Color("fff7de") if enabled else Color("bdc4a6")
	draw_polyline(points,Color("344522"),7.5,true)
	draw_polyline(points,ink,4.5,true)
	for point in points:
		draw_circle(point,2.25,ink,true,-1,true)

func upgrade_card_rect(index: int) -> Rect2:
	return Rect2(40, 235 + index * 280, 640, 264)

func card_text(rect: Rect2, y: float, label: String, size: int, color: Color = JOURNAL_INK) -> void:
	var width = ui_font(size).get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	text_at(Vector2(rect.get_center().x - width / 2, y), label, size, color)

func story_description(kind: int) -> Array[String]:
	match kind:
		0: return ["Shot delay", "%.2fs > %.2fs" % [fire_rate, fire_rate / 1.15]]
		1: return ["%d > %d seeds" % [shots, shots + 1], "%d%% power per seed" % (int(SCATTER_POWER[mini(upgrade_ranks[1] + 1, 5)] * 100))]
		2: return ["Seed power", "%.1f > %.1f" % [damage, damage + 1]]
		3: return ["Pickup reach", "%.0f > %.0f" % [magnet, magnet + 40]]
		4: return ["Roll recharge", "%.2fs > %.2fs" % [roll_cooldown(), roll_cooldown() - 0.25]]
		5: return ["Run speed", "%.0f > %.0f" % [speed, speed + 15]]
		6: return ["Guard %d > %d; refill" % [guard_capacity(), guard_capacity() + 1], "+1 charge each wave"]
		7: return ["Pierce extra bugs", "%d > %d" % [upgrade_ranks[7], upgrade_ranks[7] + 1]]
		8: return ["Knockback", "%d > %d" % [6 + upgrade_ranks[8] * 6, 12 + upgrade_ranks[8] * 6]]
	return ["", ""]

# Keep decorative corners at their intended proportions as paper panels resize.
func story_panel(rect: Rect2, tint: Color = Color.WHITE) -> void:
	# Draw nine regions explicitly to make the source-to-destination scale fixed.
	var sx = [0.0, 390.0, STORY_PAUSE.get_width() - 390.0, float(STORY_PAUSE.get_width())]
	var sy = [0.0, 320.0, STORY_PAUSE.get_height() - 320.0, float(STORY_PAUSE.get_height())]
	var dx = [rect.position.x, rect.position.x + 95, rect.end.x - 95, rect.end.x]
	var dy = [rect.position.y, rect.position.y + 78, rect.end.y - 78, rect.end.y]
	for y in range(3):
		for x in range(3):
			draw_texture_rect_region(STORY_PAUSE, Rect2(dx[x], dy[y], dx[x+1]-dx[x], dy[y+1]-dy[y]), Rect2(sx[x],sy[y],sx[x+1]-sx[x],sy[y+1]-sy[y]), tint)

func draw_story_card(index: int) -> void:
	var kind = upgrades[index]
	var rect = upgrade_card_rect(index)
	story_panel(rect, Color.WHITE if controller_choice == index else Color(0.92, 0.94, 0.87))
	var region: Rect2 = STORY_ICONS[kind]
	var icon_size = region.size * (112.0 / maxf(region.size.x, region.size.y))
	var icon_center = rect.position + Vector2(110, 130)
	draw_texture_rect_region(STORY_SKILLS, Rect2(icon_center - icon_size / 2, icon_size), region)
	card_text(Rect2(rect.position + Vector2(62, 0), Vector2(96, 50)), rect.position.y + 57, "%02d" % (index + 1), 24, LEAF_GREEN)
	var content = Rect2(rect.position + Vector2(182, 0), Vector2(394, rect.size.y))
	card_text(content, rect.position.y + 58, UPGRADE_FAMILIES[kind], 19, LEAF_GREEN)
	card_text(content, rect.position.y + 96, UPGRADE_NAMES[kind], 29)
	var lines = story_description(kind)
	card_text(content, rect.position.y + 143, lines[0], 23)
	card_text(content, rect.position.y + 177, lines[1], 24)
	draw_rank_stars(rect, upgrade_ranks[kind], UPGRADE_CAPS[kind])

func draw_rank_stars(rect: Rect2, earned: int, cap: int) -> void:
	for rank in range(cap):
		var upcoming = rank == earned
		var center = Vector2(rect.get_center().x + (rank - (cap - 1) / 2.0) * 37, rect.end.y - 38)
		var radius = 15.0 if upcoming else 12.5
		var points = PackedVector2Array()
		for vertex in range(10):
			points.append(center + Vector2.from_angle(-PI / 2 + vertex * PI / 5) * (radius if vertex % 2 == 0 else radius * 0.47))
		var color = Color("ffe96b") if upcoming else (Color("dca83a") if rank < earned else Color("8e9583"))
		draw_colored_polygon(points, color)
		draw_polyline(points + PackedVector2Array([points[0]]), Color("fff7d6") if upcoming else Color("6e613c"), 2.2, true)
		if upcoming:
			draw_circle(center + Vector2(0,-2), 2, Color("fffbe6"))

func draw_pause_menu() -> void:
	draw_rect(Rect2(-ui_offset(), get_viewport_rect().size), Color(0.10, 0.13, 0.09, 0.84))
	if exit_stage_confirmation:
		story_panel(Rect2(50,350,620,555))
		center_text(458,"LEAVE STAGE %02d?" % run_stage,34,JOURNAL_INK)
		center_text(526,"Return to Scout Camp?",26,LEAF_GREEN)
		center_text(571,"Unfinished runs earn no Seed Packets.",23,JOURNAL_INK)
		center_text(605,"Your saved upgrades and stage clears stay.",21,JOURNAL_INK)
		draw_pause_action(EXIT_CANCEL_BUTTON,"KEEP PLAYING",exit_choice==0)
		draw_pause_action(EXIT_CONFIRM_BUTTON,"EXIT STAGE",exit_choice==1)
		return
	story_panel(Rect2(35, 130, 650, 1090))
	center_text(223, "FIELD JOURNAL", 38, JOURNAL_INK)
	center_text(262, "PAUSED", 21, LEAF_GREEN)
	draw_pause_action(PAUSE_SKILLS_TAB,"YOUR SKILLS",pause_page==0)
	draw_pause_action(PAUSE_CONTROLS_TAB,"CONTROLS",pause_page==1)
	if pause_page==0:
		draw_paused_skills()
	else:
		center_text(397, "TOUCH CONTROLS", 26, LEAF_GREEN)
		center_text(440, "Touch or click, then drag to move", 25, JOURNAL_INK)
		center_text(480, "Tap Roll to dodge through danger", 24, JOURNAL_INK)
		center_text(520, "Shooting is automatic", 24, JOURNAL_INK)
		center_text(581, "KEYBOARD / CONTROLLER", 24, LEAF_GREEN)
		center_text(622, "WASD / arrows / left stick: Move", 23, JOURNAL_INK)
		center_text(661, "Space / A: Roll     Esc / Start: Pause", 22, JOURNAL_INK)
		center_text(700, "1 / 2 / 3 or D-pad + A: Upgrade", 22, JOURNAL_INK)
		var names = ["Seed  +1 XP", "Berries  +2 HP", "Dew  +1 guard", "Clover  gather XP"]
		for i in range(4):
			var pos = Vector2(135 + (i % 2) * 255, 765 + (i / 2) * 64)
			draw_pickup(pos, i, 33)
			text_at(pos + Vector2(28, 8), names[i], 21, JOURNAL_INK)
	draw_pause_action(SOUND_BUTTON,"SOUND: " + ("OFF" if mute else "ON"),pause_choice==0)
	draw_pause_action(RESUME_BUTTON,"RESUME",pause_choice==1)
	draw_pause_action(EXIT_STAGE_BUTTON,"EXIT STAGE",pause_choice==2)

func learned_skill_ranks() -> int:
	var count = 0
	for rank in upgrade_ranks: count += rank
	return count

func draw_paused_skills() -> void:
	for kind in range(9):
		var origin = Vector2(85+(kind%3)*185,365+(kind/3)*142)
		var rank = upgrade_ranks[kind]
		var tint = Color.WHITE if rank>0 else Color(0.65,0.68,0.57,0.5)
		var region: Rect2 = STORY_ICONS[kind]
		var icon_size = region.size*(60.0/maxf(region.size.x,region.size.y))
		draw_texture_rect_region(STORY_SKILLS,Rect2(origin+Vector2(90,33)-icon_size/2,icon_size),region,tint)
		card_text(Rect2(origin,Vector2(180,130)),origin.y+82,UPGRADE_NAMES[kind],18,JOURNAL_INK if rank>0 else LEAF_GREEN)
		for star in range(5):
			var center = origin+Vector2(46+star*22,103)
			var points = PackedVector2Array()
			for vertex in range(10):
				points.append(center+Vector2.from_angle(-PI/2+vertex*PI/5)*(9.0 if vertex%2==0 else 4.3))
			draw_colored_polygon(points,Color("dca83a") if star<rank else Color("bbb99a"))
			if star<rank: draw_polyline(points+PackedVector2Array([points[0]]),Color("6e613c"),1.2,true)
		card_text(Rect2(origin,Vector2(180,130)),origin.y+131,"Rank %d / 5" % rank if rank>0 else "Not learned",17,LEAF_GREEN)
	center_text(812,"Level %d / %d  -  %d skill ranks learned" % [level,MAX_LEVEL,learned_skill_ranks()],21,JOURNAL_INK)
	center_text(841,"6 level choices + 3 encounter rewards",19,LEAF_GREEN)

func bonus_pickup_reach() -> float:
	return clampf(magnet*0.65,60,100)

func update_bonus_drops(dt: float = 0.0) -> void:
	for i in range(bonus_drops.size() - 1, -1, -1):
		var drop = bonus_drops[i]
		if drop.kind == 2 and shield >= guard_capacity(): continue
		if player.distance_to(drop.p) < bonus_pickup_reach():
			drop.p = drop.p.move_toward(player,300*dt)
		if player.distance_to(drop.p) >= 25:
			continue
		if drop.kind == 2:
			if shield >= guard_capacity():
				continue
			shield = mini(guard_capacity(), shield + 1)
		else:
			# Pull the existing seeds in, then let normal XP pickup handle level-ups.
			for j in range(gems.size()):
				gems[j] = player + Vector2.from_angle(j * 0.8) * 12
		bonus_drops.remove_at(i)
		tone(660, 0.1)

func draw_pickup(position: Vector2, kind: int, extent: float) -> void:
	var region = drop_regions[kind]
	var size = region.size * (extent / maxf(region.size.x, region.size.y))
	draw_circle(position + Vector2(0, 3), extent * 0.3, Color(0, 0, 0, 0.2))
	draw_texture_rect_region(DROP_TEXTURE, Rect2(position - size / 2, size), region)

func world_to_screen(point: Vector2) -> Vector2:
	return get_viewport_rect().get_center() + (point - camera_center) * GAMEPLAY_ZOOM

func set_scene_transform(origin: Vector2, rotation: float = 0.0, draw_scale: Vector2 = Vector2.ONE) -> void:
	if drawing_world:
		draw_set_transform(world_to_screen(origin), rotation, draw_scale * GAMEPLAY_ZOOM)
	else:
		draw_set_transform(origin + ui_offset(), rotation, draw_scale)

func draw_backyard_rock(origin: Vector2) -> void:
	# Match the existing 38px collision radius with a readable stone silhouette.
	var outline = PackedVector2Array([Vector2(-38, -7), Vector2(-25, -31), Vector2(2, -39), Vector2(29, -26), Vector2(39, 1), Vector2(25, 32), Vector2(-3, 39), Vector2(-30, 25)])
	set_scene_transform(origin)
	draw_circle(Vector2(3, 5), 40, Color(0.10, 0.13, 0.07, 0.28))
	draw_colored_polygon(outline, Color("6c7260"))
	draw_colored_polygon(PackedVector2Array([Vector2(-25, -31), Vector2(2, -39), Vector2(29, -26), Vector2(21, -5), Vector2(-9, 8), Vector2(-31, -5)]), Color("92977b"))
	draw_colored_polygon(PackedVector2Array([Vector2(21, -5), Vector2(29, -26), Vector2(39, 1), Vector2(25, 32), Vector2(-3, 39), Vector2(-9, 8)]), Color("545e4e"))
	draw_polyline(outline + PackedVector2Array([outline[0]]), Color("29352a"), 4, true)
	draw_polyline(PackedVector2Array([Vector2(-23, -23), Vector2(-6, -28), Vector2(7, -22)]), Color("b1b397"), 2, true)
	set_scene_transform(Vector2.ZERO)

func _draw() -> void:
	set_scene_transform(Vector2.ZERO)
	if state == "title":
		draw_home()
		return
	draw_rect(Rect2(-ui_offset(), get_viewport_rect().size), Color("252c21"))
	drawing_world = true
	set_scene_transform(Vector2.ZERO)
	draw_ground()
	for o in obstacles:
		if world_view().grow(80).has_point(o):
			draw_backyard_rock(o)
	draw_bug_deaths()
	for g in gems:
		if world_view().grow(30).has_point(g):
			draw_pickup(g, 0, 15)
	for p in repairs:
		if world_view().grow(30).has_point(p):
			draw_pickup(p, 1, 23)
	for drop in bonus_drops:
		if world_view().grow(30).has_point(drop.p):
			draw_pickup(drop.p, drop.kind, 25)
	draw_movement_fx()
	for b in bullets:
		draw_seed_projectile(b)
	for b in hostile_bullets:
		draw_circle(b.p, b.radius + 2, INK)
		draw_circle(b.p, b.radius, Color("ff776d"))
		draw_circle(b.p, b.radius * 0.4, Color("ffd29e"))
	for e in enemies:
		if world_view().grow(140).has_point(e.p):
			draw_enemy(e)
	for i in range(effects.size()):
		if settings.values.low_graphics or (settings.values.reduced_vfx and i%3!=0): continue
		var e = effects[i]
		draw_circle(e.p, 2.5, e.color)
	if state != "title":
		draw_guard(false)
		draw_player()
		draw_weapon_fx()
		draw_guard(true)
		draw_upgrade_fx()
		draw_attack_meter()
	set_scene_transform(Vector2.ZERO)
	settings.draw_numbers()
	drawing_world = false
	set_scene_transform(Vector2.ZERO)
	draw_hud()
	if state == "playing":
		draw_touch_controls()
		draw_enemy_directions()
		if banner_timer > 0:
			center_text(280, banner, 21, PAPER)
	if state == "upgrade":
		draw_rect(Rect2(-ui_offset(), get_viewport_rect().size), Color(0.08, 0.11, 0.07, 0.86))
		story_panel(Rect2(60, 66, 600, 160))
		center_text(143, "ENCOUNTER REWARD" if pending_encounter_rewards > 0 else "SCOUT UPGRADES", 34, JOURNAL_INK)
		center_text(182, "Level %d  /  Choose your next skill" % level, 22, LEAF_GREEN)
		for i in range(upgrades.size()):
			draw_story_card(i)
		center_text(1137, "Tap a card to continue", 29, PAPER)
		center_text(1183, "6 level choices + 3 encounter rewards", 22, PAPER)
		center_text(1217, "Bright star = next rank / Merits add bonuses", 20, PAPER)
	elif state == "paused":
		draw_pause_menu()
	elif state in ["dead", "won"]:
		draw_rect(Rect2(-ui_offset(), get_viewport_rect().size), Color(0.08, 0.11, 0.07, 0.87))
		draw_scout_report()

func draw_scout_report() -> void:
	story_panel(Rect2(30,60,660,1190))
	center_text(177,"SCOUT REPORT",42,JOURNAL_INK)
	center_text(223,"Stage %d cleared" % run_stage if state=="won" else "Another adventure awaits",26,LEAF_GREEN)
	draw_texture_rect_region(REPORT_ART,Rect2(91,265,211,250),Rect2(135,10,480,535))
	set_scene_transform(Vector2(204,485),-0.126)
	var caption_size=19
	while heading_font.get_string_size(scout_name,HORIZONTAL_ALIGNMENT_LEFT,-1,caption_size).x>158 and caption_size>11: caption_size-=1
	draw_string(heading_font,Vector2(-79,0),scout_name,HORIZONTAL_ALIGNMENT_CENTER,158,caption_size,JOURNAL_INK)
	set_scene_transform(Vector2.ZERO)
	draw_texture_rect_region(REPORT_ART,Rect2(309,282,312,220),Rect2(770,88,700,415))
	var stats = [["Bugs defeated",str(kills)],["Time","%02d:%02d" % [int(elapsed)/60,int(elapsed)%60]],["Run level",str(level)],["Best bugs",str(run_best)],["Hits taken",str(damage_taken)],["Damage dealt",str(damage_dealt)]]
	for i in range(stats.size()):
		text_at(Vector2(330,317+i*30),stats[i][0],20,JOURNAL_INK)
		draw_string(heading_font,Vector2(522,317+i*30),stats[i][1],HORIZONTAL_ALIGNMENT_RIGHT,76,20,JOURNAL_INK)
	if state=="won":
		draw_texture_rect_region(REPORT_ART,Rect2(556,110,94,125),Rect2(1030,544,355,468))
		card_text(Rect2(567,0,72,0),194,"CLEARED",12,JOURNAL_INK)
	draw_texture_rect_region(REPORT_ART,Rect2(105,531,510,218),Rect2(18,567,907,394))
	center_text(569,"SEED PACKETS EARNED   +%d" % earned_packets,22,JOURNAL_INK)
	draw_reward_summary()
	draw_garden_button(START_BUTTON,"NEXT STAGE" if state=="won" and run_stage<mini(STAGE_COUNT,unlocked_stage) else "TRY AGAIN" if state=="dead" else "PLAY AGAIN",false,30)
	draw_garden_button(HOME_RETURN,"UPGRADE SCOUT" if next_growth_ready() else "BACK TO CAMP",false,23)

func draw_reward_summary() -> void:
	var y = 779
	for item in [["harvest","Bug harvest"],["clear","Stage cleared"],["first","First clear"],["chapter","Chapter milestone"],["effort","Scout effort"]]:
		var amount = int(earned_breakdown.get(item[0],0))
		if amount <= 0: continue
		text_at(Vector2(155,y),item[1],22,JOURNAL_INK)
		text_at(Vector2(525,y),"+%d" % amount,22,LEAF_GREEN)
		y += 28
	center_text(910,"SCOUT LEVEL %d  /  +%d XP%s" % [scout_experience.level,earned_scout_xp,"  /  LEVEL UP!" if scout_levels_gained>0 else ""],20,LEAF_GREEN)
	var next = growth.growth_level()
	if progress_save_failed:
		center_text(950,"Save failed. Keep the game open.",22,JOURNAL_INK)
	elif next < 100:
		var required = growth.cost(next)
		var meter = Rect2(155,930,410,12)
		draw_rect(meter,Color("b9b58b"))
		draw_rect(Rect2(meter.position,Vector2(meter.size.x*clampf(float(growth.packets)/required,0,1),meter.size.y)),LEAF_GREEN)
		var message = "Growth %d ready to learn" % (next+1) if next_growth_ready() else "%d / %d packets for Growth %d" % [growth.packets,required,next+1]
		if growth.packets >= required and not next_growth_ready(): message = growth.status(next,stage_records)
		center_text(978,message,22,JOURNAL_INK)
	else:
		center_text(978,"Scout Growth complete!",25,LEAF_GREEN)

func home_scout(rect: Rect2) -> void:
	var region: Rect2 = player_regions[0][2]
	var size = region.size * (rect.size.y / region.size.y)
	draw_texture_rect_region(PLAYER_TEXTURES[0], Rect2(Vector2(rect.get_center().x - size.x / 2, rect.position.y), size), region)

func draw_home() -> void:
	home_garden.paint(self)
	draw_campsite_header()
	center_text(246,"BACKYARD BRAVE",44,JOURNAL_INK)
	center_text(280,"Small scout. Big adventure.",23,LEAF_GREEN)
	if home_tab == 1:
		story_panel(Rect2(35,312,650,626))
		center_text(376,"%02d / %s" % [selected_stage,stage_theme_name(selected_stage)],33,JOURNAL_INK)
		center_text(416,"%s / %s" % [stage_patch_name(selected_stage),Tuning.ENEMY_NAMES[preview_enemy]],22,LEAF_GREEN)
		var bob = sin(Time.get_ticks_msec() / 1400.0) * 3
		draw_stage_island(bob)
		if selected_stage<=unlocked_stage:
			draw_stage_enemy(StageArt.RECT.position + preview_motion.position * StageArt.RECT.size + Vector2(0,bob))
		else:
			draw_texture_rect_region(GrowthAlbum.ART,Rect2(146,626,428,147),GrowthAlbum.BANNER)
			center_text(709,"LOCKED",40,JOURNAL_INK)
		center_text(967,stage_status(),20,JOURNAL_INK)
		draw_stage_arrow(STAGE_PREVIOUS,-1,selected_stage > 1)
		draw_stage_arrow(STAGE_NEXT,1,selected_stage < STAGE_COUNT)
		draw_garden_button(HOME_PLAY,"PLAY" if selected_stage <= unlocked_stage else "LOCKED",false,39,selected_stage <= unlocked_stage)
		center_text(1130,"3 minutes / Clear the stage to unlock the next",21,JOURNAL_INK)
	elif home_tab == 0 and not scout_handbook:
		draw_scout_growth()
	elif home_tab == 0:
		story_panel(Rect2(35,312,650,810))
		center_text(383,"GROWTH   /   SKILLS",30,JOURNAL_INK)
		center_text(425,"9 skills / 5 ranks each / Level cap 7",22,LEAF_GREEN)
		for i in range(9):
			var y = 475+i*62
			var region: Rect2 = STORY_ICONS[i]
			var size = region.size * (43 / maxf(region.size.x,region.size.y))
			draw_texture_rect_region(STORY_SKILLS,Rect2(Vector2(115,y)-size/2,size),region)
			text_at(Vector2(157,y+7),UPGRADE_NAMES[i],23,JOURNAL_INK)
			text_at(Vector2(505,y+7),"5 ranks",20,LEAF_GREEN)
		center_text(1085,"Choose skills as you level up during a run.",21,LEAF_GREEN)
	else:
		draw_field_journal()
	for tab in range(3):
		var rect = home_tab_rect(tab)
		draw_garden_button(rect,["SCOUT","ADVENTURE","JOURNAL"][tab],home_tab==tab,24)
	text_at(Vector2(65,184),"SCOUT LEVEL %d" % scout_experience.level,22,JOURNAL_INK)
	text_at(Vector2(65,208),"%d / %d XP" % [scout_experience.xp,scout_experience.required()],16,LEAF_GREEN)
	draw_style_box(bar_style(Color("9d9d6a")),Rect2(240,199,275,7))
	draw_style_box(bar_style(LEAF_GREEN),Rect2(240,199,275*float(scout_experience.xp)/scout_experience.required(),7))
	settings.draw_header()
	scout_profile.paint()
	settings.paint()

func draw_field_journal() -> void:
	story_panel(Rect2(35,312,650,810))
	illustrated_wood(Rect2(170,342,380,68),false)
	center_text(387,"FIELD JOURNAL",30,JOURNAL_INK)
	center_text(442,"%s's adventure log" % scout_name,22,LEAF_GREEN)
	var labels=["RUNS FINISHED","STAGES CLEARED","BEST BUG HARVEST"]
	var values=[completed_runs,cleared_runs,run_best]
	for i in range(3):
		var rect=Rect2(80+i*190,465,180,123)
		var paper=bar_style(Color("f3e3bb"))
		paper.set_corner_radius_all(12)
		paper.set_border_width_all(2)
		paper.border_color=Color("c4a775")
		draw_style_box(paper,rect)
		card_text(rect,501,labels[i],15,LEAF_GREEN)
		card_text(rect,554,str(values[i]),39,JOURNAL_INK)
	center_text(635,"SCOUT'S FIELD NOTES",25,LEAF_GREEN)
	var notes=[
		["MOVE","Drag anywhere on the field","WASD / arrows / left stick"],
		["DODGE","Tap Roll to slip past danger","Space / controller A"],
		["FIGHT","Your scout fires automatically","Collect seeds to earn skill choices"],
		["TAKE A BREAK","Pause to inspect your skills","Esc / Start / pause button"]]
	for i in range(notes.size()):
		var y=666+i*91
		draw_line(Vector2(96,y+81),Vector2(624,y+81),Color("d3bd90"),1,true)
		garden_leaf(Vector2(110,y+32),0.54)
		text_at(Vector2(141,y+16),notes[i][0],16,LEAF_GREEN)
		text_at(Vector2(141,y+43),notes[i][1],22,JOURNAL_INK)
		text_at(Vector2(141,y+67),notes[i][2],18,Color("786b4c"))
	center_text(1078,"Every expedition helps your scout grow.",21,LEAF_GREEN)

func scout_frame(direction: Vector2) -> int:
	return posmod(int(round(direction.angle() / (PI / 4.0))), 8)

func scout_muzzle(direction: Vector2) -> Vector2:
	var offsets = [Vector2(19, -12), Vector2(13, -8), Vector2(5, -5), Vector2(-13, -8), Vector2(-19, -12), Vector2(-12, -24), Vector2(-7, -26), Vector2(12, -24)]
	return player + offsets[scout_frame(direction)] * (player_display_height / 56.0)

func update_locomotion(displacement: Vector2) -> void:
	player_moving = displacement.length() > 0.01 and roll_time <= 0
	if player_moving:
		locomotion_direction = displacement.normalized()
		walk_distance += displacement.length()

func scout_pose() -> int:
	return 1 if attack_phase in ["release", "recover"] else 0

func scout_upper_direction() -> Vector2:
	return player_aim if attack_phase != "idle" or not enemies.is_empty() else facing

func scout_backpedaling() -> bool:
	return locomotion_direction.dot(scout_upper_direction()) < -0.1

func scout_leg_direction() -> int:
	# Turn hips toward travel for forward/side steps, reverse the gait for retreat.
	return scout_frame(-locomotion_direction if scout_backpedaling() else locomotion_direction)

func scout_walk_frame() -> int:
	var phase = int(fmod(walk_distance, WALK_STRIDE) / (WALK_STRIDE / 6.0))
	return posmod(5 - phase, 6) if scout_backpedaling() else phase

func draw_walking_scout() -> void:
	var scale_factor = player_display_height / 56.0
	var heading = scout_leg_direction()
	var row: int = [0, 1, 2, 1, 0, 3, 4, 3][heading]
	var mirror_legs = heading in [3, 4, 5]
	var leg_index = row * 6 + scout_walk_frame()
	var leg_region = walk_regions[leg_index]
	var row_height = 1.0
	for phase in range(6):
		row_height = maxf(row_height, walk_regions[row * 6 + phase].size.y)
	var leg_size = leg_region.size * (23.0 * scale_factor / row_height)
	set_scene_transform(player + Vector2(0, 12), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.3))
	set_scene_transform(player)
	draw_texture_rect_region(WALK_LEGS, Rect2(Vector2(-(leg_region.size.x - WALK_HIPS[leg_index] if mirror_legs else WALK_HIPS[leg_index]) * (23.0 * scale_factor / row_height), 16 - 23 * scale_factor), Vector2(-leg_size.x if mirror_legs else leg_size.x, leg_size.y)), leg_region)
	var direction = scout_upper_direction()
	var frame = scout_frame(direction)
	var source: int = [0, 1, 2, 1, 0, 7, 6, 7][frame]
	var mirrored = frame in [3, 4, 5]
	var pose = scout_pose()
	var region: Rect2 = player_regions[pose][source]
	var full_size = Vector2(player_display_height * region.size.x / region.size.y, player_display_height)
	# Keep the jacket/waist over the moving hips; attack frames never replace legs.
	var hip_fraction: float = {0: 0.42, 1: 0.46, 2: 0.50, 6: 0.50, 7: 0.42}[source]
	var cutoff = 0.69
	region.size.y *= cutoff
	var torso_size = Vector2(full_size.x, player_display_height * cutoff)
	var bob = sin(walk_distance / WALK_STRIDE * TAU * 2) * 0.55 * scale_factor
	var recoil = -direction * attack_pose_timer * 3 * scale_factor
	var x = -full_size.x * (1.0 - hip_fraction if mirrored else hip_fraction)
	set_scene_transform(player + Vector2(0, -bob) + recoil)
	draw_texture_rect_region(PLAYER_TEXTURES[pose], Rect2(Vector2(x, 16 - player_display_height), Vector2(-torso_size.x if mirrored else torso_size.x, torso_size.y)), region)
	set_scene_transform(Vector2.ZERO)

func roll_frame() -> int:
	return clampi(int((1.0 - roll_time / ROLL_DURATION) * 4), 0, 3)

func draw_roll(origin: Vector2 = player, phase: int = -1, heading: Vector2 = roll_direction, tint: Color = Color.WHITE, shadow: bool = true) -> void:
	var direction = scout_frame(heading)
	var column: int = [0, 1, 2, 1, 0, 3, 4, 3][direction]
	var mirrored = direction in [3, 4, 5]
	var region = roll_regions[(roll_frame() if phase < 0 else phase) * 5 + column]
	# A shared scale per direction preserves the crouch/tumble compression.
	var extent = 1.0
	for frame_index in range(4):
		var bounds = roll_regions[frame_index * 5 + column].size
		extent = maxf(extent, maxf(bounds.x, bounds.y))
	var size = region.size * (player_display_height * 0.95 / extent)
	if shadow:
		set_scene_transform(origin + Vector2(0, 12), 0, Vector2(1, 0.35))
		draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.3))
	set_scene_transform(origin)
	draw_texture_rect_region(ROLL_TEXTURE, Rect2(Vector2(-size.x / 2, 16 - size.y), Vector2(-size.x if mirrored else size.x, size.y)), region, tint)
	set_scene_transform(Vector2.ZERO)

func attack_ready_fraction() -> float:
	if roll_time > 0:
		return 0.0
	if enemies.is_empty() or (attack_phase == "idle" and target_direction() == Vector2.ZERO):
		return 1.0
	var until_shot = attack_clock if attack_phase == "windup" else maxf(0, fire_timer) + minf(0.11, fire_rate * 0.35)
	return clampf(1.0 - until_shot / fire_rate, 0, 1)

func draw_attack_meter() -> void:
	if state in ["dead", "won"]:
		return
	var bar = Rect2(player + Vector2(-20, 22), Vector2(40, 6))
	draw_rect(bar.grow(1.5), Color("302b1e"))
	draw_rect(bar, Color("61583a"))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * attack_ready_fraction(), bar.size.y)), Color("f4cf45"))
	draw_line(bar.position, bar.position + Vector2(bar.size.x * attack_ready_fraction(), 0), Color("fff0a0"), 1)

func draw_player() -> void:
	if roll_time > 0:
		draw_roll()
		return
	if hurt_timer > 0 and not guard_absorbed_hit and not settings.values.reduced_flashes and int(hurt_timer * 16) % 2 == 0:
		return
	if player_moving:
		draw_walking_scout()
		return
	var direction = scout_upper_direction()
	var pose = scout_pose()
	var frame = scout_frame(direction)
	# Mirror the clearer northeast pose for a distinct northwest silhouette.
	var mirrored = frame == 5
	var region: Rect2 = player_regions[pose][7 if mirrored else frame]
	var bob = absf(sin(walk_distance / 52.0 * TAU)) * 1.0 if player_moving else 0.0
	var lean = facing.x * 0.035 if player_moving else 0.0
	var recoil = -direction * attack_pose_timer * 5
	var size = Vector2(player_display_height * region.size.x / region.size.y, player_display_height)
	# Feet stay at the ground anchor; sprites never rotate with aim direction.
	set_scene_transform(player + Vector2(0, 12), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 12, Color(0, 0, 0, 0.3))
	set_scene_transform(player + Vector2(0, -bob) + recoil, lean)
	var destination = Rect2(Vector2(-size.x / 2, 16 - size.y), Vector2(-size.x if mirrored else size.x, size.y))
	draw_texture_rect_region(PLAYER_TEXTURES[pose], destination, region)
	set_scene_transform(Vector2.ZERO)

# Layered geometry keeps the barrier luminous in the Compatibility renderer.
# The back shell sits behind the scout; only rim highlights cross the front.
func draw_guard(front: bool) -> void:
	if shield <= 0 and guard_break_time <= 0:
		return
	var center = player + Vector2(0, -17)
	var pulse = 0.5 + 0.5 * sin(elapsed * 3.8)
	var impact = guard_hit_time / 0.32 * (0.15 if settings.values.reduced_flashes else 1.0)
	var breaking = shield <= 0
	var fade = guard_break_time / 0.55 if breaking else 1.0
	var expansion = (1.0 - fade) * 23.0 if breaking else impact * 5.0
	var radius = 40.0 + pulse * 1.2 + expansion
	set_scene_transform(center, 0, Vector2(0.88, 1.0))
	if not front:
		if not breaking:
			draw_circle(Vector2.ZERO, radius, Color(0.28, 0.9, 0.76, 0.07 + impact * 0.1))
		for layer in range(4):
			draw_arc(Vector2.ZERO, radius + layer * 2.0, 0, TAU, 72, Color(0.32, 1.0, 0.83, (0.07 - layer * 0.014) * fade), 5.0, true)
	else:
		if not breaking:
			draw_arc(Vector2.ZERO, radius, 0, TAU, 72, Color(0.6, 1.0, 0.88, 0.48 + pulse * 0.18 + impact * 0.3), 1.5, true)
		# Moving crescents suggest energy circulating around a protective shell.
		for i in range(3 + upgrade_ranks[6] if not breaking else 8):
			var angle = elapsed * (0.8 + upgrade_ranks[6] * 0.12) + i * TAU / (3.0 + upgrade_ranks[6] if not breaking else 8.0)
			var length = 0.62 if not breaking else 0.23 * fade
			draw_arc(Vector2.ZERO, radius, angle, angle + length, 12, Color(0.78, 1.0, 0.94, fade * 0.95), 2.6, true)
			if breaking:
				var shard = Vector2.from_angle(angle) * (radius + (1.0 - fade) * 12)
				draw_line(shard, shard + Vector2.from_angle(angle + 0.5) * 7 * fade, Color(0.7, 1.0, 0.9, fade), 2, true)
		if impact > 0 and not breaking:
			draw_arc(Vector2.ZERO, radius + (1.0 - impact) * 14, 0, TAU, 72, Color(0.85, 1.0, 0.94, impact * 0.7), 2, true)
	set_scene_transform(Vector2.ZERO)

func add_upgrade_fx(p: Vector2, kind: String, rank: int, direction: Vector2, duration: float) -> void:
	# Cosmetic effects never consume gameplay randomness or alter combat state.
	if upgrade_fx.size() >= 64:
		upgrade_fx.pop_front()
	upgrade_fx.append({"p": p, "kind": kind, "rank": rank, "dir": direction, "life": duration, "duration": duration})

func update_upgrade_fx(dt: float) -> void:
	for collection in [roll_echoes, upgrade_fx]:
		for i in range(collection.size() - 1, -1, -1):
			collection[i].life -= dt
			if collection[i].life <= 0:
				collection.remove_at(i)

func record_movement_fx(dt: float, previous: Vector2) -> void:
	var travel = player.distance_to(previous)
	if roll_time > 0 and upgrade_ranks[4] > 0:
		echo_clock -= dt
		if echo_clock <= 0 and travel > 0.1:
			echo_clock = 0.055 if upgrade_ranks[4] == 1 else 0.035
			roll_echoes.append({"p": previous, "phase": roll_frame(), "dir": roll_direction, "rank": upgrade_ranks[4], "life": 0.18, "duration": 0.18})
			if roll_echoes.size() > 6:
				roll_echoes.pop_front()
	else:
		echo_clock = 0.0
	if roll_time <= 0 and upgrade_ranks[5] > 0:
		boot_distance += travel
		if boot_distance >= 19:
			boot_distance = fmod(boot_distance, 19)
			add_upgrade_fx(player + Vector2(0, 12), "boots", upgrade_ranks[5], locomotion_direction, 0.3)

func draw_movement_fx() -> void:
	if settings.values.reduced_vfx or settings.values.low_graphics: return
	for echo in roll_echoes:
		var fade: float = echo.life / echo.duration
		var tint = Color(0.3, 0.47, 0.7, fade * 0.25) if echo.rank == 1 else Color(0.45, 0.8, 0.95, fade * 0.3)
		draw_roll(echo.p, echo.phase, echo.dir, tint, false)
	if roll_time > 0 and upgrade_ranks[4] > 0:
		set_scene_transform(player + Vector2(0, 5), roll_direction.angle(), Vector2(1, 0.6))
		draw_arc(Vector2.ZERO, 23, -1.4, 1.4, 20, Color(0.55, 0.85, 1.0, 0.22 + upgrade_ranks[4] * 0.09), 3, true)
		set_scene_transform(Vector2.ZERO)
	for g in gems:
		if upgrade_ranks[3] > 0 and g.distance_to(player) < magnet and g.distance_to(player) > 22:
			var direction = (player - g).normalized()
			draw_line(g - direction * (5 + upgrade_ranks[3] * 4), g, Color(0.73, 0.91, 0.4, 0.35), 1.5, true)

func seed_color(ranks: Array) -> Color:
	# Damage color takes priority even when piercing/scatter are also equipped.
	if ranks[2] > 0:
		return [Color("f3d693"), Color("f6df79"), Color("f2cd58"), Color("efa63e"), Color("f4773c"), Color("ed4545")][ranks[2]]
	if ranks[7] > 0:
		return Color("a4e6db") if ranks[7] == 1 else Color("63d6d0")
	return Color("b9d779") if ranks[1] > 0 else Color("f3d693")

func draw_seed_projectile(b: Dictionary) -> void:
	var ranks: Array = b.get("visual", [0,0,0,0,0,0,0,0,0])
	var color = seed_color(ranks)
	var direction: Vector2 = b.v.normalized()
	var tail: float = 7 + ranks[0] * 3 + ranks[7] * 5
	draw_line(b.p - direction * tail, b.p, Color(color, 0.42), 2.0, true)
	set_scene_transform(b.p, direction.angle())
	var size: float = 3.0 + ranks[2] * 0.35 - ranks[1] * 0.2
	if ranks[7] > 0:
		var points = PackedVector2Array([Vector2(7 + ranks[7], 0), Vector2(-3, -size), Vector2(-6, 0), Vector2(-3, size)])
		draw_colored_polygon(points, color)
		draw_polyline(points + PackedVector2Array([points[0]]), JOURNAL_INK, 1.4, true)
		draw_line(Vector2(-3, 0), Vector2(5, 0), (color.lightened(0.3) if ranks[2] > 0 else Color("f1fff2")), 1.1, true)
	else:
		draw_circle(Vector2.ZERO, size + 1.2, JOURNAL_INK)
		draw_circle(Vector2.ZERO, size, color)
		draw_line(Vector2(-1.5, -size * 0.6), Vector2(1.5, size * 0.6), Color("745338"), 1.2, true)
	if ranks[2] > 0 and ranks[7] > 0:
		draw_circle(Vector2(-1, 0), 0.8 + ranks[2] * 0.15, color.lightened(0.35))
	if ranks[8] > 0:
		draw_arc(Vector2(-3, 0), size + 2, PI * 0.55, PI * 1.45, 12, Color("c3ade6"), 1.2 + ranks[8] * 0.4, true)
	set_scene_transform(Vector2.ZERO)

func draw_weapon_fx() -> void:
	if settings.values.reduced_flashes or settings.values.low_graphics: return
	if roll_time > 0 or attack_pose_timer <= 0:
		return
	var strength = attack_pose_timer / 0.2
	var muzzle = scout_muzzle(player_aim)
	var color = seed_color(upgrade_ranks)
	if upgrade_ranks[0] > 0 or upgrade_ranks[2] > 0 or upgrade_ranks[7] > 0 or upgrade_ranks[1] > 0:
		set_scene_transform(muzzle, player_aim.angle())
		# Brief colored release flash; the original slingshot art stays crisp.
		var length = (4 + upgrade_ranks[0] * 2) * strength
		for side in [-1, 1]:
			draw_line(Vector2(2, side * 2), Vector2(length, side * (2 + 3 * strength)), Color(color, strength * 0.8), 1.5, true)
		set_scene_transform(Vector2.ZERO)

func draw_upgrade_fx() -> void:
	if settings.values.reduced_vfx or settings.values.low_graphics: return
	for fx in upgrade_fx:
		var fade: float = fx.life / fx.duration
		var age = 1.0 - fade
		match fx.kind:
			"hit":
				for side in [-1, 1]:
					var direction: Vector2 = fx.dir.rotated(side * 0.8)
					draw_line(fx.p + direction * (4 + age * 10), fx.p + direction * (9 + age * 14), Color(1.0, 0.92, 0.69, fade), 2.0, true)
			"thump":
				draw_arc(fx.p, 5 + age * (10 + fx.rank * 4), fx.dir.angle() - 1.0, fx.dir.angle() + 1.0, 16, Color(0.78, 0.68, 0.92, fade * 0.75), 1.8, true)
			"boots":
				for side in [-1, 1]:
					var p: Vector2 = fx.p + fx.dir.orthogonal() * side * 6 - fx.dir * age * 9
					draw_line(p, p - fx.dir * (4 + fx.rank * 3), Color(0.83, 0.76, 0.5, fade * 0.4), 2, true)
			"gather":
				var p: Vector2 = fx.p + Vector2(sin(age * PI) * 5, -age * 16)
				draw_line(p, p + Vector2(3, -4 - fx.rank), Color(0.74, 0.94, 0.45, fade * 0.65), 2, true)
			"upgrade":
				for i in range(5):
					var p: Vector2 = fx.p + Vector2.from_angle(i * TAU / 5 - PI / 2) * (22 + age * 18)
					draw_line(p, p + Vector2(0, -4 - fx.rank), Color(0.95, 0.84, 0.5, fade * 0.65), 2, true)

func update_bug_deaths(dt: float) -> void:
	for i in range(bug_deaths.size() - 1, -1, -1):
		bug_deaths[i].life -= dt
		if bug_deaths[i].life <= 0:
			bug_deaths.remove_at(i)

func draw_bug_deaths() -> void:
	for e in bug_deaths:
		var age: float = 1.0 - e.life / e.duration
		var tumble = clampf(age / 0.55, 0, 1)
		var settle = 1.0 - pow(1.0 - tumble, 3)
		var fade = 1.0 - smoothstep(0.6, 1.0, age)
		var art=enemy_art(e.kind,int(age*12)%2 if age<0.3 else 1)
		var texture: Texture2D=art.texture
		var region: Rect2=art.region
		var size: Vector2=art.size
		var p: Vector2 = e.p + e.hit_dir * settle * (10 if e.kind in [5, 6] else 19)
		var hop = sin(tumble * PI) * (5 if e.kind in [5, 6] else 11)
		set_scene_transform(p + Vector2(0, 4), 0, Vector2(1, 0.5))
		draw_circle(Vector2.ZERO, e.radius * (1.0 - age * 0.25), Color(0.12, 0.1, 0.05, fade * 0.22))
		var turn: float = (1 if e.uid % 2 == 0 else -1) * (0.55 if e.kind in [5, 6] else 1.5)
		set_scene_transform(p - Vector2(0, hop), e.angle + settle * turn, Vector2(1.0 - settle * 0.16, 1.0 - settle * 0.45))
		draw_texture_rect_region(texture, Rect2(-size / 2, size), region, Color(1.0 - age * 0.25, 1.0 - age * 0.3, 1.0 - age * 0.35, fade))
		set_scene_transform(Vector2.ZERO)

func draw_enemy(e: Dictionary) -> void:
	var p: Vector2 = e.p
	var angle: float = (player - p).angle()
	if e.kind in [3, 6, 7, 8] and e.mode in ["windup", "rush", "recover"]:
		angle = e.aim.angle()
	var r: float = e.radius
	if e.mode == "windup":
		var warning_color: Color = Tuning.ENEMY_COLORS[e.kind]
		if e.kind in [3, 6, 7]:
			var end: Vector2 = p + e.aim * (210.0 if e.kind == 6 else (144.0 if e.kind == 7 else Tuning.CHARGE_SPEED * Tuning.CHARGE_SECONDS))
			draw_line(p, end, Color(warning_color, 0.18), r * 2, true)
			draw_line(p, end, warning_color, 2, true)
			draw_line(end - e.aim.rotated(0.65) * 18, end, warning_color, 3, true)
			draw_line(end - e.aim.rotated(-0.65) * 18, end, warning_color, 3, true)
		elif e.kind in [4, 8]:
			draw_line(p, p + e.aim * 160, warning_color, 2, true)
		else:
			draw_arc(p, r + 15, 0, TAU, 32, warning_color, 3, true)
	if e.kind>=9:
		draw_garden_bug_warning(e)
		if e.mode=="burrow": return
	var art=enemy_art(e.kind,int(e.walk_distance/9.0)%2)
	var texture: Texture2D=art.texture
	var region: Rect2=art.region
	var size: Vector2=art.size
	if e.kind>=9:
		if e.mode=="hop": p.y-=sin((1.0-e.timer/0.5)*PI)*22
		elif e.mode in ["dig","emerge"]: size*=0.75
		elif e.mode=="brace": size*=Vector2(0.92,1.08)
		else: angle+=sin(e.walk_distance/6.0)*0.045
	set_scene_transform(p + Vector2(0, 3), 0, Vector2(1, 0.65))
	draw_circle(Vector2.ZERO, r, Color(0.08, 0.09, 0.04, 0.25))
	var impact: float = e.get("recoil", 0.0) / 0.18
	var kick = sin(impact * PI)
	var strength = 0.45 if e.kind in [5, 6] else 1.0
	var offset: Vector2 = e.get("hit_dir", Vector2.ZERO) * kick * 5 * strength
	set_scene_transform(p + offset, angle + sin(impact * TAU) * 0.16 * strength, Vector2(1.0 - kick * 0.15 * strength, 1.0 + kick * 0.12 * strength))
	var tint = Color(1.7, 1.7, 1.7) if e.flash > 0 and not settings.values.reduced_flashes else Color.WHITE
	if e.flash <= 0 and e.mode == "windup" and int(e.timer * 6) % 2 == 0:
		tint = Color(1.25, 1.2, 1.05)
	draw_texture_rect_region(texture, Rect2(-size / 2, size), region, tint)
	set_scene_transform(Vector2.ZERO)
	if Tuning.is_elite(e.kind):
		text_at(p + Vector2(-42, -r - 19), Tuning.ENEMY_NAMES[e.kind], 11, PAPER)
	if (e.hp < e.max_hp or Tuning.is_elite(e.kind)) and e.kind != 5:
		var width = 76.0 if Tuning.is_elite(e.kind) else clampf(r*2,38,68)
		var bar = Rect2(p.x-width/2,p.y-r-12,width,12 if Tuning.is_elite(e.kind) else 10)
		draw_combat_health(bar,float(e.get("display_hp",e.hp))/e.max_hp,float(e.get("trail_hp",e.hp))/e.max_hp,Tuning.is_elite(e.kind),float(e.get("bar_delay",0))/0.18)

# Stretch only the quiet paper center; preserve the illustrated end-cap proportions.
func draw_story_header(rect: Rect2) -> void:
	var source = STORY_LEGEND
	var cap = 120.0
	var cap_width = cap * rect.size.y / source.size.y
	story_piece(Rect2(rect.position, Vector2(cap_width, rect.size.y)), Rect2(source.position, Vector2(cap, source.size.y)))
	story_piece(Rect2(rect.position + Vector2(cap_width, 0), Vector2(rect.size.x - cap_width * 2, rect.size.y)), Rect2(source.position + Vector2(cap, 0), Vector2(source.size.x - cap * 2, source.size.y)))
	story_piece(Rect2(rect.end.x - cap_width, rect.position.y, cap_width, rect.size.y), Rect2(source.end.x - cap, source.position.y, cap, source.size.y))

func hud_meter_style(border: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("d1c59e")
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style

func draw_hud() -> void:
	draw_set_transform(Vector2(ui_offset().x, 0))
	story_panel(Rect2(12, 24, 696, 198))
	for i in range(scout_max_hp()):
		journal_heart(Vector2(80 + i * minf(26,224.0/scout_max_hp()), 77), i < hp)
	text_at(Vector2(337, 79), ("LEVEL %d / MAX" % level if level>=MAX_LEVEL else "LEVEL %d" % level), 24, JOURNAL_INK)
	draw_style_box(hud_meter_style(Color("5b6240")), Rect2(337, 95, 215, 14))
	var fraction = 1.0 if level >= MAX_LEVEL else clampf(float(xp) / xp_required(), 0, 1)
	draw_rect(Rect2(339, 97, 211 * fraction, 10), Color("8daa55"))
	if shield>0:
		for charge in range(shield): draw_pickup(Vector2(86+charge*26,106),2,23)
	else:
		text_at(Vector2(73,112),"STAGE %02d" % run_stage,17,LEAF_GREEN)
	var labels = ["BUGS", "WAVE", "TIME", "REMAINING" if elapsed >= SPAWN_DURATION else "SURVIVE"]
	var values = [str(kills), "%02d" % wave, "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60], str(enemies.size()) if elapsed >= SPAWN_DURATION else "03:00"]
	for i in range(4):
		var column = Rect2(64 + i * 147, 126, 147, 66)
		card_text(column, 148, labels[i], 17, LEAF_GREEN)
		card_text(column, 181, values[i], 28)
	draw_garden_button(PAUSE_BUTTON,"II",false,25)
	for e in enemies:
		if e.kind == 5:
			text_at(Vector2(28, 237), "BROODMOTHER", 17, PAPER)
			draw_combat_health(Rect2(210,227,474,18),float(e.get("display_hp",e.hp))/e.max_hp,float(e.get("trail_hp",e.hp))/e.max_hp,true)

	set_scene_transform(Vector2.ZERO)

func draw_touch_controls() -> void:
	var active_drag = move_touch_active or mouse_dragging
	if settings.values.show_joystick or active_drag or DisplayServer.is_touchscreen_available():
		var origin = drag_origin if active_drag else Vector2(145,1150 + ui_offset().y)
		draw_circle(origin,DRAG_RADIUS,Color(0.22,0.35,0.12,0.25))
		draw_arc(origin,DRAG_RADIUS,0,TAU,48,Color(0.65,0.76,0.36,0.7),3,true)
		draw_circle(origin+touch_move*DRAG_RADIUS,25,Color(0.77,0.84,0.47,0.7))
		if not active_drag:
			text_at(origin + Vector2(-76,90),"DRAG TO MOVE",19,PAPER)
	draw_set_transform(Vector2(ui_offset().x, ui_offset().y * 2))
	draw_garden_button(Rect2(470,1092,215,110),"ROLL",false,28,roll_timer<=0)
	# Small shadow keeps the readiness label readable over grass.
	card_text(ROLL_BUTTON, 1232, "READY" if roll_timer <= 0 else "%.1fs" % roll_timer, 23, JOURNAL_INK)
	card_text(ROLL_BUTTON, 1230, "READY" if roll_timer <= 0 else "%.1fs" % roll_timer, 23, PAPER)
	if roll_timer > 0:
		draw_rect(Rect2(525, 1244, 100 * clampf(1 - roll_timer / roll_cooldown(), 0, 1), 5), LEAF_GREEN)
	set_scene_transform(Vector2.ZERO)

func world_view() -> Rect2:
	return Rect2(camera_center - get_viewport_rect().size / GAMEPLAY_ZOOM / 2, get_viewport_rect().size / GAMEPLAY_ZOOM)

func refresh_terrain() -> void:
	var cell = Vector2i(floori(player.x / 600), floori(player.y / 600))
	if cell == terrain_cell:
		return
	terrain_cell = cell
	obstacles = [Vector2(260,270), Vector2(1020,270), Vector2(260,535), Vector2(1020,535)] if run_stage == 1 else []
	# Stateless per-cell seeds make backtracking stable without retaining a map.
	for y in range(cell.y - 2, cell.y + 3):
		for x in range(cell.x - 2, cell.x + 3):
			if run_stage == 1 and x in [0, 1] and y == 0:
				continue
			var terrain_rng = RandomNumberGenerator.new()
			terrain_rng.seed = hash("garden:%d:%d" % [x, y]) if run_stage == 1 else hash("stage:%d:%d:%d" % [run_stage,x,y])
			var rock = Vector2(x * 600, y * 600) + Vector2(terrain_rng.randf_range(130,470), terrain_rng.randf_range(130,470))
			var rocks = [rock]
			if stage_theme(run_stage) == 1:
				rocks.append(rock + Vector2(150,55))
			elif stage_theme(run_stage) == 2:
				# Rocks frame a roomy central clearing with broad exits.
				var center = Vector2(x * 600 + 300, y * 600 + 300)
				var angle = terrain_rng.randf_range(0,TAU)
				rocks = [center + Vector2.from_angle(angle) * 190, center - Vector2.from_angle(angle) * 190]
			for point in rocks:
				if point.distance_to(stage_start(run_stage)) > 130:
					obstacles.append(point)

func draw_ground() -> void:
	var view = world_view().grow(100)
	for y in range(floori(view.position.y / 640), floori(view.end.y / 640) + 1):
		for x in range(floori(view.position.x / 640), floori(view.end.x / 640) + 1):
			# Reflected neighbours share identical boundary pixels, including at negative coordinates.
			set_scene_transform(Vector2(x * 640 + (640 if posmod(x,2) else 0), y * 640 + (640 if posmod(y,2) else 0)), 0, Vector2(-1 if posmod(x,2) else 1, -1 if posmod(y,2) else 1))
			draw_texture_rect(GROUND_TEXTURE, Rect2(0,0,640,640), false)
	set_scene_transform(Vector2.ZERO)

func draw_enemy_directions() -> void:
	for e in enemies:
		if elapsed < SPAWN_DURATION and not Tuning.is_major(e.kind):
			continue
		var point = world_to_screen(e.p)
		if get_viewport_rect().grow(-25).has_point(point):
			continue
		var direction = (point - get_viewport_rect().get_center()).normalized()
		var edge = get_viewport_rect().grow(-28)
		point = Vector2(clampf(point.x, edge.position.x, edge.end.x), clampf(point.y, maxf(260, edge.position.y), edge.end.y - 140)) - ui_offset()
		var side = direction.orthogonal()
		draw_colored_polygon(PackedVector2Array([point + direction * 12, point - direction * 9 + side * 8, point - direction * 9 - side * 8]), Color("e8ba65"))

func test_new_encounters() -> void:
	start_run()
	elapsed = 45
	update_elite_schedule()
	assert(enemies.size() == 1 and enemies[0].kind == 7)
	elapsed = 90
	update_elite_schedule()
	assert(enemies.size() == 1 and elite_spawn_index == 1, "Do not stack special encounters")
	kill_enemy(0)
	assert(gems.size() == 8 and repairs.size() == 1 and bonus_drops[0].kind == 3)
	update_elite_schedule()
	assert(enemies[0].kind == 6)
	var rhino = enemies[0]
	rhino.p = player - Vector2(150, 0)
	rhino.timer = 0
	update_enemy(rhino, 0.01)
	assert(rhino.mode == "windup" and rhino.chain == 1)
	var aim: Vector2 = rhino.aim
	player.y += 50
	update_enemy(rhino, 1.01)
	assert(rhino.mode == "rush" and rhino.aim == aim)
	update_enemy(rhino, 0.51)
	assert(rhino.mode == "recover")
	update_enemy(rhino, 0.81)
	assert(rhino.mode == "windup" and rhino.chain == 0, "Second charge needs a fresh warning")
	kill_enemy(0)
	assert(bonus_drops[-1].kind == 2)
	elapsed = 125
	update_elite_schedule()
	assert(enemies[0].kind == 8 and elite_spawn_index == 3)
	var wasp = enemies[0]
	wasp.p = player + Vector2(180, 0)
	wasp.timer = 0
	update_enemy(wasp, 0.01)
	assert(wasp.mode == "windup" and hostile_bullets.is_empty())
	update_enemy(wasp, 0.86)
	assert(hostile_bullets.size() == 3 and wasp.mode == "recover")
	start_run()
	bonus_drops.append({"p": player, "kind": 2})
	update_bonus_drops()
	assert(shield == 1 and bonus_drops.is_empty())
	shield = 2
	bonus_drops.append({"p": player, "kind": 2})
	update_bonus_drops()
	assert(bonus_drops.size() == 1, "Do not waste dew at full protection")
	bonus_drops.clear()
	gems.append(Vector2(100, 160))
	bonus_drops.append({"p": player, "kind": 3})
	update_bonus_drops()
	assert(gems[0].distance_to(player) < 20 and bonus_drops.is_empty())
	start_run()
	elapsed = 180
	update_elite_schedule()
	assert(enemies.is_empty(), "No special spawns after the cutoff")
	assert(gems.is_empty() and bonus_drops.is_empty() and elite_spawn_index == 0)

func test_journal_controls() -> void:
	start_run()
	var click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = pause_hit_rect().get_center() + ui_offset()
	_unhandled_input(click)
	assert(state == "paused" and previous_state == "playing")
	click.position = RESUME_BUTTON.get_center() + ui_offset()
	_unhandled_input(click)
	assert(state == "playing")
	state = "upgrade"
	click.position = pause_hit_rect().get_center() + ui_offset()
	_unhandled_input(click)
	assert(state == "paused" and previous_state == "upgrade")
	click.position = RESUME_BUTTON.get_center() + ui_offset()
	_unhandled_input(click)
	assert(state == "upgrade", "Resume must return to the upgrade choices")

func test_storybook_controls() -> void:
	start_run()
	upgrades.assign([0, 1, 2])
	pending_levels = 1
	state = "upgrade"
	var hover = InputEventMouseMotion.new()
	hover.position = upgrade_card_rect(2).get_center() + ui_offset()
	_unhandled_input(hover)
	assert(controller_choice == 2)
	var joy = InputEventJoypadButton.new()
	joy.pressed = true
	joy.button_index = JOY_BUTTON_DPAD_LEFT
	_unhandled_input(joy)
	assert(controller_choice == 1)
	joy.button_index = JOY_BUTTON_A
	_unhandled_input(joy)
	assert(upgrade_ranks[1] == 1 and state == "playing")
	for index in range(3):
		start_run()
		upgrades.assign([0, 1, 2])
		pending_levels = 1
		state = "upgrade"
		var click = InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		# Bottom of the new illustrated card lies outside the previous hit area.
		click.position = upgrade_card_rect(index).get_center() + Vector2(0, 90) + ui_offset()
		_unhandled_input(click)
		assert(upgrade_ranks[index] == 1 and state == "playing")
	start_run()

func smoke_test() -> void:
	# Deterministic fixtures must not inherit the developer's saved stage/build.
	growth = ScoutGrowth.new()
	stage_records = {}
	selected_stage = 1
	unlocked_stage = 1
	state = "title"
	test_stages()
	test_home_navigation()
	test_five_star_progression()
	test_mouse_drag()
	test_mobile_world()
	test_new_encounters()
	test_journal_controls()
	test_storybook_controls()
	assert(walk_regions.size() == 30)
	for direction_index in range(8):
		facing = Vector2.from_angle(direction_index * PI / 4)
		locomotion_direction = facing
		player_aim = facing
		for step in range(6):
			walk_distance = (step + 0.1) * WALK_STRIDE / 6.0
			for phase in ["windup", "release", "recover"]:
				attack_phase = phase
				assert(scout_walk_frame() == step)
				assert(scout_leg_direction() == direction_index)
	assert(roll_regions.size() == 20)
	for phase in range(4):
		roll_time = ROLL_DURATION * (1.0 - (phase + 0.1) / 4.0)
		assert(roll_frame() == phase)
	assert(player_regions.size() == 4)
	for regions in player_regions:
		assert(regions.size() == 8)
	for i in range(8):
		assert(scout_frame(Vector2.from_angle(i * PI / 4)) == i)
	rng.seed = 42
	start_run()
	spawn_enemy()
	assert(enemies.size() == 1)
	enemies[0].p = player + Vector2(70, 0)
	shoot()
	assert(bullets.size() == 1)
	for i in range(15):
		simulate(0.016)
	assert(kills == 1, "Projectile should destroy an enemy")
	assert(state == "playing", "An empty arena before spawn cutoff must not end the run")
	assert(xp == 1, "Enemy core should be collected")
	for i in range(15):
		gain_xp()
	assert(state == "upgrade" and level == 2)
	assert(upgrades.size() == 3)
	choose_upgrade(0)
	assert(state == "playing")
	start_run()
	for choice in range(6):
		upgrades = [choice]
		pending_levels = 1
		choose_upgrade(0)
	assert(shots == 2 and damage == 4 and magnet == 130 and speed == 245)
	assert(constrain_actor(obstacles[0], 17).distance_to(obstacles[0]) >= 54.9)
	start_run()
	spawn_enemy()
	enemies[0].p = player
	simulate(0.016)
	assert(hp == 7)
	simulate(0.016)
	assert(hp == 7, "Damage grace period should prevent repeated hits")
	start_run()
	spawn_enemy()
	spawn_enemy()
	enemies[0].p = player + Vector2(70, 0)
	enemies[1].p = player + Vector2(400, 0)
	boss_spawned = true
	elapsed = 179.99
	simulate(0.02)
	assert(state == "playing" and enemies.size() == 2, "Timer cutoff must stop spawns without awarding victory")
	spawn_enemy()
	assert(enemies.size() == 2, "No new enemies may spawn after cutoff")
	for i in range(15):
		simulate(0.016)
	assert(kills == 1 and enemies.size() == 1 and state == "playing", "Victory must wait for the last enemy")
	enemies[0].p = player + Vector2(70, 0)
	xp = 5
	fire_timer = 0
	for i in range(15):
		if state == "playing":
			simulate(0.016)
	assert(state == "won" and enemies.is_empty(), "Killing the last enemy must clear the grid immediately")
	start_run()
	spawn_enemy()
	enemies[0].p = player
	hp = 1
	boss_spawned = true
	elapsed = SPAWN_DURATION
	simulate(0.016)
	assert(state == "dead", "Remaining enemies must still be dangerous after cutoff")
	start_run()
	boss_spawned = true
	elapsed = SPAWN_DURATION
	simulate(0.016)
	assert(state == "won", "An already empty grid should clear at cutoff")
	start_run()
	for i in range(12000):
		if state == "upgrade":
			choose_upgrade(0)
		if state != "playing":
			break
		if i % 200 == 0:
			player = Vector2(rng.randf_range(400, 850), rng.randf_range(280, 500))
		simulate(0.016)
	assert(state in ["dead", "won"])
	test_enemy_behaviors()
	test_scout_progression()
	start_run()
	enemies.append(make_enemy(player + Vector2(80, 0), 0))
	kill_enemy(0)
	assert(enemies.is_empty() and bug_deaths.size() == 1 and kills == 1 and gems.size() == 1)
	state = "paused"
	var death_life: float = bug_deaths[0].life
	simulate(0.1, Vector2.ZERO)
	assert(bug_deaths[0].life == death_life, "Death animation freezes while paused")
	update_bug_deaths(1.0)
	assert(bug_deaths.is_empty() and kills == 1 and gems.size() == 1, "Death visuals cannot duplicate loot")
	assert(seed_color([5,5,5,0,0,0,0,5,5]) == Color("ed4545"), "Maximum damage stays red with every ammo modifier")
	start_run()
	assert(bug_deaths.is_empty())
	print("SMOKE TEST PASSED: combat, progression, charger, ranged attacks, boss, pause, restart, swept collision, last-enemy victory")
	shutdown.call_deferred()

func test_enemy_behaviors() -> void:
	start_run()
	enemies.append(make_enemy(player + Vector2(100, 100), 0))
	begin_attack()
	assert(attack_phase == "windup" and bullets.is_empty() and scout_frame(player_aim) == 1)
	update_attack(0.05)
	assert(bullets.is_empty(), "A projectile must not appear before release")
	update_attack(0.07)
	assert(attack_phase == "release" and bullets.size() == 1 and scout_pose() == 1)
	update_attack(0.11)
	assert(attack_phase == "recover")
	update_attack(0.09)
	assert(attack_phase == "idle")
	begin_attack()
	start_roll()
	assert(attack_phase == "idle", "Dodge must cancel an unfinished draw")
	assert(is_equal_approx(roll_time, ROLL_DURATION))
	roll_time = 0.2
	start_roll()
	assert(is_equal_approx(roll_time, 0.2), "Cooldown must prevent roll restart")
	player_moving = true
	roll_time = 0
	walk_distance = 0
	locomotion_direction = Vector2.RIGHT
	facing = Vector2.RIGHT
	assert(scout_walk_frame() == 0)
	walk_distance = WALK_STRIDE / 6.0
	assert(scout_walk_frame() == 1)
	for phase in ["windup", "release", "recover"]:
		attack_phase = phase
		player_aim = Vector2.RIGHT
		assert(scout_walk_frame() == 1, "Shooting must not replace the leg cycle")
	player_aim = Vector2.LEFT
	assert(scout_backpedaling() and scout_leg_direction() == 4)
	var old_distance = walk_distance
	update_locomotion(Vector2.ZERO)
	assert(not player_moving and walk_distance == old_distance)
	roll_time = 0.2
	update_locomotion(Vector2(20, 0))
	assert(not player_moving and walk_distance == old_distance)
	start_run()
	player = Vector2(315, 270)
	spawn_timer = 100
	simulate(0.016, Vector2.LEFT)
	assert(not player_moving and is_zero_approx(walk_distance), "Blocked movement must not walk in place")
	simulate(0.016, Vector2.RIGHT)
	assert(player_moving and walk_distance > 0)
	start_run()
	var charger = make_enemy(player + Vector2(-180, 0), 3)
	charger.timer = 0
	update_enemy(charger, 0.016)
	assert(charger.mode == "windup")
	var launch_position: Vector2 = charger.p
	var locked_direction: Vector2 = charger.aim
	player += Vector2(0, 100)
	update_enemy(charger, 0.2)
	assert(charger.p == launch_position and charger.aim == locked_direction, "Charger must stop and lock its aim before rushing")
	update_enemy(charger, 0.65)
	assert(charger.mode == "rush")
	update_enemy(charger, 0.05)
	assert(charger.p.x > launch_position.x + 30 and charger.p.y == launch_position.y, "Charge must follow the warning line, not track the player")
	for i in range(15):
		update_enemy(charger, 0.04)
	assert(charger.mode == "recover")
	var recover_position: Vector2 = charger.p
	update_enemy(charger, 0.1)
	assert(charger.p == recover_position, "Recovery is a stationary punish window")
	update_enemy(charger, 1.0)
	assert(charger.mode == "seek")
	charger.p = Vector2(960, 270)
	charger.mode = "rush"
	charger.aim = Vector2.RIGHT
	charger.timer = 0.4
	update_enemy(charger, 0.05)
	assert(charger.mode == "recover", "Rock collision must interrupt charge")
	var spitter = make_enemy(player + Vector2(220, 0), 4)
	spitter.timer = 0
	update_enemy(spitter, 0.01)
	assert(spitter.mode == "windup" and hostile_bullets.is_empty())
	update_enemy(spitter, 0.7)
	assert(hostile_bullets.size() == 1, "Spitter must fire after its warning")
	hostile_bullets.clear()
	add_hostile_shot(player - Vector2(40, 0), Vector2.RIGHT, 500, 6)
	roll_time = 0.15
	update_hostile_bullets(0.05)
	assert(hp == 8, "Roll must protect against hostile projectiles")
	add_hostile_shot(player - Vector2(40, 0), Vector2.RIGHT, 500, 6)
	roll_time = 0
	update_hostile_bullets(0.05)
	assert(hp == 7)
	shield = 2
	hurt_player()
	assert(shield == 1 and hp == 7 and guard_hit_time > 0)
	hurt_player()
	assert(shield == 0 and hp == 7 and guard_break_time > 0)
	start_run()
	elapsed = Tuning.BOSS_ARRIVAL - 0.01
	simulate(0.02, Vector2.ZERO)
	assert(boss_spawned)
	var bosses = enemies.filter(func(e): return e.kind == 5)
	assert(bosses.size() == 1)
	simulate(0.02, Vector2.ZERO)
	assert(enemies.filter(func(e): return e.kind == 5).size() == 1, "Boss must appear only once")
	hostile_bullets.clear()
	fire_enemy(bosses[0])
	assert(hostile_bullets.size() == 11)
	hostile_bullets.clear()
	bosses[0].hp = 40
	fire_enemy(bosses[0])
	assert(hostile_bullets.size() == 15, "Warden second phase must intensify the radial pattern")
	toggle_pause()
	var frozen_elapsed = elapsed
	var frozen_boss_position: Vector2 = bosses[0].p
	simulate(1.0)
	assert(elapsed == frozen_elapsed and bosses[0].p == frozen_boss_position)
	toggle_pause()
	assert(state == "playing")
	assert(Combat.hit_fraction(Vector2.ZERO, Vector2(100, 0), Vector2(50, 0), 5) < 0.5)
	assert(Combat.hit_fraction(Vector2.ZERO, Vector2(100, 0), Vector2(50, 20), 5) == INF)
	var blocked = move_actor(Vector2(150, 270), Vector2(220, 0), 17)
	assert(blocked.x < 210, "Fast movement must not tunnel through a pillar")
	start_run()
	upgrade_ranks.assign(UPGRADE_CAPS)
	upgrade_ranks[2] -= 1
	show_upgrades()
	assert(upgrades == [2], "Only uncapped ranks may be offered")
	start_run()
	for i in range(RUN_XP_STEPS[0]+RUN_XP_STEPS[1]+RUN_XP_STEPS[2]):
		gain_xp()
	assert(pending_levels == 3 and level == 4)
	for i in range(3):
		choose_upgrade(0)
	assert(pending_levels == 0 and state == "playing", "Multiple pickups must queue every earned upgrade")
	start_run()
	assert(hostile_bullets.is_empty() and repairs.is_empty() and not boss_spawned and shield == 0)
	# A shot must hit the first surface, and never shoot through a pillar.
	var enemy = make_enemy(Vector2(330, 270), 0)
	enemies.append(enemy)
	bullets.append({"p": Vector2(170, 270), "v": Vector2(4000, 0), "life": 1.0})
	spawn_timer = 99
	fire_timer = 99
	simulate(0.05, Vector2.ZERO)
	assert(enemies.size() == 1 and enemies[0].hp == enemies[0].max_hp and bullets.is_empty())
	# Every archetype remains numerically stable throughout a crowded simulation.
	start_run()
	for kind in range(12):
		enemies.append(make_enemy(Vector2(150 + kind * 80, 200), kind))
	hp = 10000
	for i in range(900):
		if state == "upgrade":
			choose_upgrade(0)
		simulate(0.033, Vector2.from_angle(i * 0.01))
		for e in enemies:
			assert(e.p.is_finite())
		assert(hostile_bullets.size() < 150)
	start_run()

func test_scout_progression() -> void:
	start_run()
	show_upgrades()
	assert(UPGRADE_FAMILIES[upgrades[0]] == "SHARPSHOOTER")
	assert(UPGRADE_FAMILIES[upgrades[1]] == "CROWD CONTROL")
	assert(UPGRADE_FAMILIES[upgrades[2]] == "TRAIL SURVIVOR")
	# A pierced seed hits each bug once, including several in one frame.
	start_run()
	for x in [680, 730, 780]:
		enemies.append(make_enemy(Vector2(x, 390), 2))
	bullets.append({"p": Vector2(640, 390), "v": Vector2(4000, 0), "life": 1.0, "power": 2.0, "pierce": 2, "hit_ids": []})
	damage = 99
	update_player_bullets(0.05)
	assert(bullets.is_empty() and enemies.size() == 3)
	for e in enemies:
		assert(is_equal_approx(e.hp,e.max_hp-2), "Power is fixed at launch and each target takes one hit")
	start_run()
	enemies.append(make_enemy(Vector2(330, 270), 0))
	bullets.append({"p": Vector2(170, 270), "v": Vector2(4000, 0), "life": 1.0, "power": 10.0, "pierce": 2, "hit_ids": []})
	update_player_bullets(0.05)
	assert(enemies[0].hp == enemies[0].max_hp and bullets.is_empty(), "Piercing cannot bypass rocks")
	start_run()
	enemies.append(make_enemy(Vector2(700, 390), 2))
	bullets.append({"p": Vector2(700, 390), "v": Vector2.ZERO, "life": 1.0, "power": 1.0, "pierce": 2, "hit_ids": []})
	update_player_bullets(0.01)
	update_player_bullets(0.01)
	assert(is_equal_approx(enemies[0].hp,enemies[0].max_hp-1), "A lingering pierced seed cannot hit the same bug again")
	start_run()
	for i in range(1000):
		gain_xp()
	assert(level == MAX_LEVEL and pending_levels == 6 and is_equal_approx(damage, 6.3))
	enemies.append(make_enemy(Vector2(700, 390), 6))
	kill_enemy(0)
	assert(pending_levels == 7 and encounter_rewards == 1 and pending_encounter_rewards == 1)
	while pending_levels > 0:
		choose_upgrade(0)
	assert(state == "playing")
	start_run()
	for kind in [4, 4, 5, 5, 6, 6]:
		upgrades = [kind]
		pending_levels = 1
		choose_upgrade(0)
	assert(is_equal_approx(roll_cooldown(), 2.0) and shield == 4 and speed == 260)
	shield = 0
	elapsed = 19.99
	spawn_timer = 99
	simulate(0.02, Vector2.ZERO)
	assert(shield == 1, "Ranked guard restores one charge at a wave boundary")
	var origin = player
	facing = Vector2.RIGHT
	start_roll()
	simulate(0.1, Vector2.ZERO)
	assert(is_equal_approx(player.distance_to(origin), 230.0 * 1.9125 * 0.1), "Boots must not extend roll travel")
	start_run()
	assert(upgrade_ranks == [0,0,0,0,0,0,0,0,0] and pending_encounter_rewards == 0 and damage == 3)

func bot_direction() -> Vector2:
	var target = Vector2(640, 385) + Vector2(cos(elapsed * 0.3) * 340, sin(elapsed * 0.3) * 160)
	var best = INF
	var pickups = repairs if hp < 6 and not repairs.is_empty() else gems
	for p in pickups:
		var d: float = player.distance_squared_to(p)
		if d < best:
			best = d
			target = p
	var move = (target - player).normalized() * 1.0
	var danger = false
	for e in enemies:
		var diff: Vector2 = player - e.p
		var distance = diff.length()
		if distance < 150 + e.radius:
			move += diff.normalized() * (1.0 - distance / (150 + e.radius)) * 4
			if distance < 75 + e.radius:
				danger = true
		if e.kind in [3, 6, 7, 8] and e.mode in ["windup", "rush"]:
			var closest = Geometry2D.get_closest_point_to_segment(player, e.p, e.p + e.aim * 320)
			if player.distance_to(closest) < 65:
				move += (player - closest).normalized() * 2
	for b in hostile_bullets:
		var closest = Geometry2D.get_closest_point_to_segment(player, b.p, b.p + b.v * 0.5)
		if player.distance_to(closest) < 60:
			move += (player - closest).normalized() * 2.5
			if player.distance_to(b.p) < 55:
				danger = true
	for o in obstacles:
		var diff = player - o
		if diff.length() < 62:
			var tangent = diff.normalized().orthogonal()
			if tangent.dot(target - player) < 0:
				tangent = -tangent
			move += tangent * 1.5 + diff.normalized() * 0.5
	if danger and roll_timer <= 0:
		facing = move.normalized()
		start_roll()
	return move.normalized()

func bot_upgrade() -> void:
	var priorities = [[2, 7, 0, 5, 4, 6, 3, 8, 1], [1, 8, 0, 2, 5, 7, 6, 4, 3], [5, 4, 6, 2, 0, 3, 7, 8, 1]]
	var priority: Array = priorities[test_build]
	# Survivor remains a mixed build: invest every third choice in its weapon.
	var chosen = 0
	for rank in upgrade_ranks:
		chosen += rank
	if test_build == 2 and chosen % 3 == 0:
		priority = [2, 7, 0, 5, 4, 6, 3, 8, 1]
	for kind in priority:
		if upgrades.has(kind):
			choose_upgrade(upgrades.find(kind))
			return

func balance_test() -> void:
	for scenario in range(9):
		var seed_value: int = [17, 42, 93][scenario % 3]
		test_build = scenario / 3
		rng.seed = seed_value
		start_run()
		for i in range(12000):
			if state == "upgrade":
				bot_upgrade()
			if state != "playing":
				break
			simulate(1.0 / 30.0, bot_direction())
		print("BALANCE build=%d seed=%d result=%s time=%.1f kills=%d level=%d hp=%d hits=%d enemies=%d boss=%s" % [test_build, seed_value, state, elapsed, kills, level, hp, damage_taken, enemies.size(), boss_spawned])
		assert(state in ["dead", "won"], "A run must end without a stalled cleanup phase")
		if not "--balance-survey" in OS.get_cmdline_user_args():
			assert(state == "won" and boss_spawned and enemies.is_empty(), "Reference pilot must be able to beat the complete run")
		if not "--balance-survey" in OS.get_cmdline_user_args():
			assert(elite_spawn_index == 3, "Reference run must encounter all three new threats")
		print("  ranks=%s rewards=%d xp=%d" % [upgrade_ranks, encounter_rewards, xp])
	shutdown.call_deferred()

func visual_test() -> void:
	screenshot_mode = true
	var directory = OS.get_environment("NEON_QA_DIR")
	assert(not directory.is_empty())
	state = "title"
	await capture_screen(directory.path_join("title.png"))
	home_tab = 0
	await capture_screen(directory.path_join("home-scout.png"))
	home_tab = 2
	await capture_screen(directory.path_join("home-journal.png"))
	home_tab = 1
	start_run()
	elapsed = 155
	wave = 8
	spawn_boss()
	var boss = enemies[-1]
	boss.mode = "windup"
	boss.timer = 0.8
	boss.aim = (player - boss.p).normalized()
	fire_enemy(boss)
	for b in hostile_bullets:
		b.p += b.v * 0.65
	enemies.append(make_enemy(Vector2(420, 385), 3))
	enemies[-1].mode = "windup"
	enemies[-1].aim = Vector2.RIGHT
	enemies[-1].timer = 0.4
	repairs.append(Vector2(850, 460))
	shield = 2
	await capture_screen(directory.path_join("boss.png"))
	roll_timer = 1.3
	await capture_screen(directory.path_join("roll-cooldown.png"))
	roll_timer = 0
	show_upgrades()
	await capture_screen(directory.path_join("upgrades.png"))
	toggle_pause()
	await capture_screen(directory.path_join("paused.png"))
	state = "won"
	enemies.clear()
	hostile_bullets.clear()
	elapsed = 195
	kills = 400
	await capture_screen(directory.path_join("victory.png"))
	print("VISUAL TEST PASSED: title, boss combat, upgrade cards, pause, victory")
	await shutdown()

func capture_screen(path: String) -> void:
	queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(path) == OK)





func test_mobile_world() -> void:
	start_run()
	var press = InputEventScreenTouch.new()
	press.index = 3
	press.position = Vector2(170, 800) + ui_offset()
	press.pressed = true
	_unhandled_input(press)
	assert(move_touch == 3 and touch_move == Vector2.ZERO, "A press alone must not move")
	var drag = InputEventScreenDrag.new()
	drag.index = 3
	drag.position = press.position + Vector2(60,0)
	_unhandled_input(drag)
	assert(touch_move.x > 0.9)
	var before = player
	spawn_timer = 999
	simulate(0.05)
	assert(player.x > before.x and camera_center == player)
	var roll_press = InputEventScreenTouch.new()
	roll_press.index = 7
	roll_press.position = roll_hit_rect().get_center() + ui_offset()
	roll_press.pressed = true
	_unhandled_input(roll_press)
	assert(roll_time > 0 and move_touch == 3, "Second finger must roll without releasing movement")
	roll_press.pressed = false
	_unhandled_input(roll_press)
	assert(move_touch == 3)
	press.pressed = false
	_unhandled_input(press)
	assert(touch_move == Vector2.ZERO and move_touch == -1)
	press.pressed = true
	_unhandled_input(press)
	toggle_pause()
	assert(move_touch == -1 and touch_move == Vector2.ZERO)
	toggle_pause()
	press.position = pause_hit_rect().get_center() + ui_offset()
	_unhandled_input(press)
	assert(state == "paused")
	press.position = SOUND_BUTTON.get_center() + ui_offset()
	var was_muted = mute
	_unhandled_input(press)
	assert(mute != was_muted)
	mute = was_muted
	press.position = RESUME_BUTTON.get_center() + ui_offset()
	_unhandled_input(press)
	assert(state == "playing")
	for choice in range(3):
		start_run()
		upgrades.assign([0,1,2])
		pending_levels = 1
		state = "upgrade"
		press.position = upgrade_card_rect(choice).get_center() + ui_offset()
		_unhandled_input(press)
		assert(upgrade_ranks[choice] == 1 and state == "playing")
	start_run()
	var starting_rocks = obstacles.duplicate()
	for destination in [Vector2(18000,-18000), Vector2(-18000,18000), Vector2(-18000,-18000), Vector2(18000,18000)]:
		player = destination
		camera_center = player
		refresh_terrain()
		assert(obstacles.size() <= 29)
		var projected = world_to_screen(player)
		assert(projected.is_equal_approx(get_viewport_rect().get_center()))
		var old_seed = rng.state
		refresh_terrain()
		assert(rng.state == old_seed, "Terrain must not consume combat RNG")
		enemies.clear()
		for i in range(20):
			spawn_enemy()
		for e in enemies:
			assert(not world_view().grow(40).has_point(e.p), "New bugs must enter from outside the view")
		var free = Vector2(destination.x, floorf(destination.y / 600) * 600 + 40)
		assert(move_actor(free, Vector2(60,0), 17).distance_to(free) > 59, "No hidden arena wall at distant coordinates")
	player = Vector2(640,390)
	camera_center = player
	refresh_terrain()
	assert(obstacles == starting_rocks, "Returning to a place must restore the same rocks")
	start_run()
	elapsed = SPAWN_DURATION
	boss_spawned = true
	enemies.append(make_enemy(player + Vector2(2000,0),0))
	var distant = enemies[0]
	var old_position: Vector2 = distant.p
	simulate(0.05,Vector2.ZERO)
	assert(state == "playing" and enemies.size() == 1)
	assert(distant.p.distance_to(old_position) <= 2000.0/1.5*0.05+0.1 and distant.p.x < old_position.x, "Catchup must move continuously, not teleport")
	kill_enemy(0)
	simulate(0.05,Vector2.ZERO)
	assert(state == "won", "Final death, not timer alone, completes the run")
	start_run()
	# Traverse a clear cell boundary for a complete run, far beyond the old map.
	player = Vector2(0, 40)
	camera_center = player
	hp = 10000
	spawn_timer = 0
	for frame in range(5500):
		if elapsed >= SPAWN_DURATION:
			break
		if state == "upgrade":
			choose_upgrade(0)
		simulate(1.0 / 30.0, Vector2.LEFT)
		assert(obstacles.size() <= 29 and enemies.size() <= 101)
	assert(elapsed >= SPAWN_DURATION and player.x < -30000, "A full three-minute walk must cross terrain cells without hitting a world edge")
	var count_at_cutoff = enemies.size()
	spawn_enemy()
	assert(enemies.size() == count_at_cutoff, "Spawning must stop at three minutes even far from the starting area")
	start_run()
	print("MOBILE WORLD PASSED: multitouch, pause, upgrade taps, three-minute travel, stable terrain, offscreen spawns and final cleanup")

func test_mouse_drag() -> void:
	start_run()
	var down = InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(240,700) + ui_offset()
	_unhandled_input(down)
	assert(mouse_dragging and touch_move == Vector2.ZERO)
	var motion = InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.position = down.position + Vector2(0,-60)
	_unhandled_input(motion)
	assert(touch_move.y < -0.9)
	spawn_timer = 999
	var before = player
	simulate(0.05)
	assert(player.y < before.y)
	motion.position = down.position + Vector2(0,-600)
	_unhandled_input(motion)
	assert(touch_move.length() <= 1.001)
	motion.position += Vector2(0,80)
	_unhandled_input(motion)
	assert(touch_move.y > 0, "Long swipes must reverse without returning to the first press")
	down.pressed = false
	_unhandled_input(down)
	assert(not mouse_dragging and touch_move == Vector2.ZERO)
	down.pressed = true
	down.position = roll_hit_rect().get_center() + ui_offset()
	_unhandled_input(down)
	assert(roll_time > 0 and not mouse_dragging)
	down.position = pause_hit_rect().get_center() + ui_offset()
	_unhandled_input(down)
	assert(state == "paused" and not mouse_dragging)
	toggle_pause()
	down.position = Vector2(240,700) + ui_offset()
	_unhandled_input(down)
	motion.button_mask = 0
	_unhandled_input(motion)
	assert(not mouse_dragging, "A lost mouse release must not leave movement stuck")
	start_run()
	print("DRAG INPUT PASSED: floating origin, mouse movement, release, reversal, UI exclusion")

func test_five_star_progression() -> void:
	for kind in range(9):
		start_run()
		for rank in range(5):
			upgrades.assign([kind])
			pending_levels = 1
			state = "upgrade"
			choose_upgrade(0)
			assert(upgrade_ranks[kind] == rank + 1)
			assert(roll_cooldown() >= 1.25 and fire_rate > 0.17)
			seed_color(upgrade_ranks)
		show_upgrades()
		assert(not upgrades.has(kind), "Five-star skills must leave the offer pool")
	start_run()
	upgrade_ranks[1] = 5
	shots = 6
	enemies.append(make_enemy(player + Vector2(100,0),2))
	shoot()
	assert(bullets.size() == 6 and is_equal_approx(bullets[0].power, damage * 0.5))
	attack_phase = "recover"
	fire_timer = fire_rate - minf(0.11, fire_rate * 0.35)
	assert(is_zero_approx(attack_ready_fraction()))
	fire_timer -= fire_rate * 0.5
	assert(is_equal_approx(attack_ready_fraction(), 0.5))
	attack_phase = "windup"
	attack_clock = 0
	assert(is_equal_approx(attack_ready_fraction(), 1.0))
	roll_time = 0.2
	assert(is_zero_approx(attack_ready_fraction()))
	start_run()
	print("FIVE STAR CHECKS PASSED: all 45 skill ranks, cap exclusion, scatter and attack meter")


func test_home_navigation() -> void:
	return_home()
	var touch = InputEventScreenTouch.new()
	touch.pressed = true
	for tab in [0,2,1]:
		touch.position = home_tab_rect(tab).get_center() + ui_offset()
		_unhandled_input(touch)
		assert(state == "title" and home_tab == tab and move_touch == -1)
	touch.position = HOME_PLAY.get_center() + ui_offset()
	_unhandled_input(touch)
	assert(state == "playing")
	state = "won"
	var expected_tab = 0 if next_growth_ready() else 1
	touch.position = HOME_RETURN.get_center() + ui_offset()
	_unhandled_input(touch)
	assert(state == "title" and home_tab == expected_tab)
	home_tab = 2
	var old_mute = mute
	touch.position = SOUND_BUTTON.get_center() + ui_offset()
	_unhandled_input(touch)
	assert(mute == old_mute and state == "title")
	mute = old_mute
	start_run()
	print("HOME CHECKS PASSED: navigation, play, result return and journal has no sound action")

func stage_theme(stage: int) -> int:
	return clampi((stage-1)/10,0,2)

func stage_theme_name(stage: int) -> String:
	return ["CLOVER PATCH","PEBBLE TRAILS","GARDEN CLEARINGS"][stage_theme(stage)]

func stage_patch_name(stage: int) -> String:
	return StageArt.NAMES[clampi(stage,1,STAGE_COUNT)-1]

func stage_start(stage: int) -> Vector2:
	return Vector2(640,390) + Vector2(((stage-1)%5)*181, ((stage-1)/5)*143)

func roll_preview_enemy() -> void:
	# Separate randomness: opening the homepage never affects combat rolls.
	var pools = [[0,1,2,3,4,5,6,7,8,9,10,11],[1,2,4,5,8,9,10],[0,2,3,6,7,9,11]]
	var pool: Array = pools[stage_theme(selected_stage)]
	pool = pool.filter(func(kind): return kind != preview_enemy)
	preview_enemy = pool[preview_rng.randi_range(0,pool.size()-1)]
	preview_motion.reset(selected_stage)

func select_stage(stage: int) -> void:
	var next = clampi(stage,1,STAGE_COUNT)
	if selected_stage == next:
		return
	selected_stage = next
	roll_preview_enemy()

func stage_status() -> String:
	if selected_stage > unlocked_stage:
		return "Clear stage %02d to unlock" % (selected_stage-1)
	var record: Dictionary = stage_records.get(str(selected_stage),{})
	if record.is_empty():
		return "Stage %02d / %d  -  Ready to explore" % [selected_stage,STAGE_COUNT]
	return "%s / Best: %d bugs" % ["CLEARED" if record.get("cleared",false) else "READY",record.get("best",0)]

func record_stage_result(result: String) -> void:
	var record: Dictionary = stage_records.get(str(run_stage),{})
	record["best"] = maxi(int(record.get("best",0)),kills)
	record["longest"] = maxf(float(record.get("longest",0)),elapsed)
	record["cleared"] = bool(record.get("cleared",false)) or result == "won"
	stage_records[str(run_stage)] = record
	if result == "won":
		unlocked_stage = maxi(unlocked_stage,mini(run_stage+1,STAGE_COUNT))

func draw_stage_island(bob: float) -> void:
	var rect = StageArt.RECT
	rect.position.y += bob
	if selected_stage>unlocked_stage:
		var texture = stage_art.image_for(selected_stage)
		if locked_sprite.texture!=texture:
			locked_sprite.texture = texture
			locked_preview.render_target_update_mode = SubViewport.UPDATE_ONCE
		draw_texture_rect(locked_preview.get_texture(),rect,false)
	else:
		draw_texture_rect(stage_art.image_for(selected_stage),rect,false)

func draw_stage_enemy(center: Vector2) -> void:
	var kind = preview_enemy
	var art=enemy_art(kind,int(preview_motion.distance_walked/12.0)%2)
	var texture: Texture2D=art.texture
	var region: Rect2=art.region
	var depth=remap(preview_motion.position.y,0.60,0.72,0.92,1.0)
	var size: Vector2=art.size*(118.0/ENEMY_SIZES[kind])*depth
	set_scene_transform(center+Vector2(0,14),0,Vector2(1,0.45))
	draw_circle(Vector2.ZERO,28*depth,Color(0.12,0.16,0.08,0.2))
	var hover = Vector2(0,-5-sin(preview_motion.clock*4)*2) if kind == 8 else Vector2.ZERO
	set_scene_transform(center+hover,preview_motion.heading)
	draw_texture_rect_region(texture,Rect2(-size/2,size),region)
	set_scene_transform(Vector2.ZERO)

func test_stages() -> void:
	var saved_unlock = unlocked_stage
	var saved_records = stage_records.duplicate(true)
	stage_records.clear()
	unlocked_stage = 1
	selected_stage = 2
	state = "title"
	start_run()
	assert(state == "title", "Locked stages cannot start through any input")
	run_stage = 1
	kills = 10
	elapsed = 180
	record_stage_result("dead")
	assert(unlocked_stage == 1)
	record_stage_result("won")
	assert(unlocked_stage == 2 and stage_records["1"].cleared)
	assert(stage_theme(10)==0 and stage_theme(11)==1 and stage_theme(20)==1 and stage_theme(21)==2)
	unlocked_stage = STAGE_COUNT
	var seen = {}
	for stage in range(1,STAGE_COUNT+1):
		selected_stage = stage
		start_run()
		var rocks = obstacles.duplicate()
		assert(not seen.has(str(rocks)), "Every stage needs a distinct terrain layout")
		seen[str(rocks)] = true
		terrain_cell = Vector2i(9999,9999)
		refresh_terrain()
		assert(rocks == obstacles and player == stage_start(stage))
		assert(constrain_actor(player,17).is_equal_approx(player), "Starting area must be clear")
		var old_rng = rng.state
		roll_preview_enemy()
		assert(preview_enemy >= 0 and preview_enemy < Tuning.ENEMY_NAMES.size() and old_rng == rng.state)
	run_stage = 30
	record_stage_result("won")
	assert(unlocked_stage == 30)
	unlocked_stage = saved_unlock
	stage_records = saved_records
	selected_stage = 1
	start_run()
	print("STAGES PASSED: 30 distinct stable layouts, chapter boundaries, safe starts, locks, unlocks and isolated preview RNG")

func scout_max_hp() -> int:
	return 8 + run_growth[1] + run_growth[16]*2

func scout_fire_rate() -> float:
	return 0.36 / (1.0 + run_growth[5]*0.02 + run_growth[21]*0.06)

func growth_max_scroll(track: int = -1) -> float:
	var acorns = merit_track if track<0 else track==1
	return 9.0*280.0 if acorns else 99.0*170.0-(GROWTH_VIEW.size.y-168.0)

func growth_node_rect(id: int) -> Rect2:
	if id>=100: return Rect2(GROWTH_VIEW.position+Vector2(358,GROWTH_VIEW.size.y-260-(id-100)*280+acorn_scroll),Vector2(220,220.0*1280.0/1086.0))
	return Rect2(GROWTH_VIEW.position+Vector2(0,GROWTH_VIEW.size.y-168-id*170+envelope_scroll),Vector2(342,162))

func visible_merit() -> int:
	return 100+clampi(roundi(acorn_scroll/280.0) if merit_track else int(envelope_scroll/170.0)/10,0,9)

func focus_growth(id: int) -> void:
	growth_selected = clampi(id,0,109)
	merit_track = growth_selected>=100
	var row = growth_selected if not merit_track else growth_selected-100
	growth_scroll = clampf(row*(280.0 if merit_track else 170.0),0,growth_max_scroll())
	growth_velocity = 0
	growth_notice = ""

func growth_input(event: InputEvent) -> bool:
	if state!="title" or home_tab!=0 or scout_handbook: return false
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and GROWTH_VIEW.has_point(event.position):
		if event.pressed:
			merit_track = event.position.x>=GROWTH_VIEW.position.x+350
			growth_scroll = clampf(growth_scroll+(100 if event.button_index==MOUSE_BUTTON_WHEEL_UP else -100),0,growth_max_scroll())
			growth_velocity = 0
		return true
	var is_press = (event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT))
	if is_press:
		var pointer_id = event.index if event is InputEventScreenTouch else -1
		if event.pressed and GROWTH_VIEW.has_point(event.position):
			if growth_drag_id!=-2: return true
			merit_track = event.position.x>=GROWTH_VIEW.position.x+350
			growth_drag_id = pointer_id
			growth_drag_start = event.position
			growth_drag_last = event.position
			growth_drag_distance = 0
			growth_drag_time = Time.get_ticks_msec()
			growth_velocity = 0
			return true
		if not event.pressed and pointer_id==growth_drag_id:
			growth_drag_id = -2
			if growth_drag_distance<10:
				growth_velocity = 0
				growth_pointer(event.position)
			elif Time.get_ticks_msec()-growth_drag_time>120:
				growth_velocity = 0
			return true
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		var pointer_id = event.index if event is InputEventScreenDrag else -1
		if pointer_id==growth_drag_id:
			var delta_y = event.position.y-growth_drag_last.y
			var now = Time.get_ticks_msec()
			growth_drag_distance += event.position.distance_to(growth_drag_last)
			if growth_drag_distance>=10:
				growth_scroll = clampf(growth_scroll+delta_y,0,growth_max_scroll())
				growth_velocity = clampf(delta_y/maxf(0.008,(now-growth_drag_time)/1000.0),-2200,2200)
			growth_drag_last = event.position
			growth_drag_time = now
			return true
	return false

func growth_pointer(point: Vector2) -> void:
	if GROWTH_BUY.has_point(point):
		purchase_growth()
	elif GROWTH_VIEW.has_point(point):
		merit_track = point.x>=GROWTH_VIEW.position.x+350
		for id in range(100,110) if merit_track else range(100):
			if growth_node_rect(id).has_point(point):
				growth_selected = id
				break
		growth_notice = ""
		growth_velocity = 0

func growth_key(key: int) -> bool:
	match key:
		KEY_ESCAPE: home_tab = 1
		KEY_H: scout_handbook = true
		KEY_ENTER, KEY_SPACE: purchase_growth()
		KEY_UP, KEY_DOWN:
			var step = 1 if key==KEY_UP else -1
			focus_growth(clampi(growth_selected+step,0,99) if growth_selected<100 else clampi(growth_selected+step,100,109))
		KEY_PAGEUP, KEY_PAGEDOWN:
			growth_scroll = clampf(growth_scroll+(GROWTH_VIEW.size.y if key==KEY_PAGEUP else -GROWTH_VIEW.size.y),0,growth_max_scroll())
			growth_velocity = 0
		KEY_LEFT: focus_growth(clampi((growth_selected-100)*10 if merit_track else int(envelope_scroll/170),0,99))
		KEY_RIGHT: focus_growth(visible_merit())
		KEY_HOME: focus_growth(0)
		KEY_END: focus_growth(99)
		_: return false
	return true

func purchase_growth() -> void:
	if growth_selected>=100 and growth.status(growth_selected,stage_records)=="READY":
		scout_profile.open_merits(growth_selected)
		return
	var old = ConfigFile.new()
	growth.write_config(old)
	var before_acorns = growth.acorns
	if not growth.buy(growth_selected,stage_records):
		growth_notice = growth.status(growth_selected,stage_records)
		return
	if not save_progress():
		growth.load_config(old)
		growth_notice = "Save failed. Nothing spent; please try again."
		return
	growth_notice = "Learned! Applies next run."
	if growth.acorns>before_acorns: growth_notice = "Golden Acorn earned! A new merit is ready."
	tone(880,0.08)

func draw_scout_growth() -> void:
	story_panel(Rect2(35,312,650,810))
	draw_workbench_header()
	card_text(Rect2(68,0,342,0),469,"GROWTH  /  Scroll up",15,LEAF_GREEN)
	card_text(Rect2(426,0,220,0),469,"ACORNS  /  Scroll up",15,LEAF_GREEN)
	var detail = "Choose one of three unique bonuses" if growth_selected>=100 and growth.ranks[growth_selected]==0 else growth.detail_for(growth_selected)
	center_text(959,("Level %d / " % (growth_selected+1) if growth_selected<100 else "")+detail,19,JOURNAL_INK)
	var hint = growth_notice if not growth_notice.is_empty() else growth.status(growth_selected,stage_records)
	center_text(990,hint,18,LEAF_GREEN)
	var ready = growth.status(growth_selected,stage_records)=="READY"
	var label = "LEARN / %d %s" % [growth.cost(growth_selected),"PACKETS" if growth_selected<100 else "ACORN"] if ready else ("LEARNED" if growth.ranks[growth_selected]>0 else "LOCKED")
	draw_garden_button(GROWTH_BUY,label,false,23,ready)
	center_text(1135,"FIELD GUIDE  /  All run skills",19,LEAF_GREEN)

func resolve_bramble() -> void:
	if not bramble_pending: return
	bramble_pending = false
	add_upgrade_fx(player,"thump",3,Vector2.UP,0.5)
	for i in range(enemies.size()-1,-1,-1):
		var enemy = enemies[i]
		if enemy.p.distance_to(player)>120 or not enemy_targetable(enemy): continue
		var power = damage*2*(1.2 if run_growth[14]>0 and Tuning.is_major(enemy.kind) else 1.0)
		damage_dealt += minf(power,enemy.hp)
		mark_enemy_hit(enemy,minf(power,enemy.hp))
		enemy.hp -= power
		enemy.flash = 0.15
		enemy.recoil = 0.2
		enemy.hit_dir = (enemy.p-player).normalized()
		if enemy.hp<=0: kill_enemy(i)

func garden_leaf(center: Vector2, scale_factor: float = 1.0) -> void:
	var extent=64.0*scale_factor
	var dimensions=Vector2(TOGGLE_LEAF.get_size())
	var size=dimensions*(extent/maxf(dimensions.x,dimensions.y))
	draw_texture_rect(TOGGLE_LEAF,Rect2(center-size/2,size),false)

func illustrated_wood(rect: Rect2, active: bool) -> void:
	# Only the quiet horizontal grain stretches; end grain and leaf retain their aspect.
	var art=WOOD_TAB_GREEN if active else WOOD_TAB_NATURAL
	var source=Rect2(183,32,1650,736) if active else Rect2(85,128,1735,565)
	var scale_factor=rect.size.y/(510.0 if active else 565.0)
	var left=260.0
	var right=480.0 if active else 260.0
	var target=Rect2(rect.position+Vector2(0,-224*scale_factor if active else 0),Vector2(rect.size.x+(140*scale_factor if active else 0),source.size.y*scale_factor))
	var widths=[left*scale_factor,target.size.x-(left+right)*scale_factor,right*scale_factor]
	var source_widths=[left,source.size.x-left-right,right]
	var dx=target.position.x
	var sx=source.position.x
	for i in range(3):
		draw_texture_rect_region(art,Rect2(dx,target.position.y,widths[i],target.size.y),Rect2(sx,source.position.y,source_widths[i],source.size.y))
		dx+=widths[i]
		sx+=source_widths[i]

func garden_wood(rect: Rect2, active: bool) -> void:
	var shadow = bar_style(Color("664226"))
	shadow.set_corner_radius_all(12)
	draw_style_box(shadow,Rect2(rect.position+Vector2(0,4),rect.size))
	var style = bar_style(Color("527c3d") if active else Color("deb579"))
	style.set_corner_radius_all(12)
	style.set_border_width_all(3)
	style.border_color=Color("493522")
	draw_style_box(style,rect)
	var inset=rect.grow(-6)
	draw_line(inset.position+Vector2(6,1),Vector2(inset.end.x-6,inset.position.y+1),Color("91ad62") if active else Color("f9dba1"),3,true)
	for i in range(2):
		var y=rect.position.y+rect.size.y*(0.22+0.56*i)
		var ink=Color("3f6434") if active else Color("bd905c")
		draw_polyline(PackedVector2Array([Vector2(rect.position.x+14,y),Vector2(rect.position.x+rect.size.x*0.22,y+2),Vector2(rect.position.x+rect.size.x*0.36,y)]),ink,1.3,true)
		draw_line(Vector2(rect.end.x-35,y+2),Vector2(rect.end.x-13,y),ink,1.3,true)

func draw_garden_button(rect: Rect2, label: String, selected: bool = false, size: int = 26, enabled: bool = true) -> void:
	var pointer=get_global_mouse_position()-ui_offset()
	if state in ["playing","upgrade"]:
		if rect==PAUSE_BUTTON: pointer.y+=ui_offset().y
		elif rect.position.y>1000: pointer.y-=ui_offset().y
	var hovered=enabled and rect.has_point(pointer) and not screenshot_mode
	var active=enabled and (selected or hovered)
	var factor=1.025 if hovered else 1.0
	if hovered and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): factor=0.985
	var visual=Rect2(rect.get_center()-rect.size*factor/2,rect.size*factor).grow(-5)
	if hovered:
		for spread in [6,3]:
			var glow=bar_style(Color(0.72,0.82,0.35,0.10))
			glow.set_corner_radius_all(17)
			draw_style_box(glow,visual.grow(spread))
	illustrated_wood(visual,active and not "CAMP" in label)
	var camp="CAMP" in label
	if camp:
		var height=visual.size.y*1.45
		var dimensions=Vector2(CAMP_CACTUS.get_size())
		var cactus_size=dimensions*(height/dimensions.y)
		var base=Vector2(visual.position.x+12,visual.end.y+8)
		draw_texture_rect(CAMP_CACTUS,Rect2(base-Vector2(cactus_size.x/2,cactus_size.y),cactus_size),false)
	var available=visual.size.x-(66 if camp else 34)
	var font_size=mini(size,int(visual.size.y*0.48))
	while font_size>10 and ui_font(font_size).get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>available:
		font_size-=1
	var text_rect=visual
	if camp: text_rect=Rect2(visual.position+Vector2(34,0),visual.size-Vector2(34,0))
	card_text(text_rect,visual.get_center().y+font_size*0.34,label,font_size,Color("fff4d5") if active and not camp else Color("493522") if enabled else Color("82765e"))

func draw_garden_toggle(rect: Rect2, on: bool) -> void:
	garden_wood(rect,on)
	var track=Rect2(rect.position+Vector2(9,9),rect.size-Vector2(18,18))
	var style=bar_style(Color("37552c") if on else Color("94754f"))
	style.set_corner_radius_all(15)
	draw_style_box(style,track)
	var thumb=Vector2(rect.end.x-27 if on else rect.position.x+27,rect.get_center().y)
	garden_leaf(thumb,0.72)
	var label_rect=Rect2(rect.position+Vector2(9 if on else 49,0),Vector2(rect.size.x-58,rect.size.y))
	card_text(label_rect,rect.get_center().y+7,"ON" if on else "OFF",21,Color("fff4d5"))

func draw_pause_action(rect: Rect2, label: String, focused: bool) -> void:
	draw_garden_button(rect,label,focused)

func request_exit_stage() -> void:
	if state!="paused": return
	clear_touch()
	exit_stage_confirmation = true
	exit_choice = 0

func exit_to_camp() -> void:
	if state!="paused" or not exit_stage_confirmation: return
	exit_stage_confirmation = false
	# Abandonment intentionally does not call finish_run or award/save a result.
	return_home()

func pause_key(key: int) -> bool:
	match key:
		KEY_LEFT, KEY_RIGHT, KEY_TAB:
			if not exit_stage_confirmation: pause_page = 1-pause_page
		KEY_ESCAPE:
			toggle_pause()
		KEY_UP, KEY_DOWN:
			var step = -1 if key==KEY_UP else 1
			if exit_stage_confirmation: exit_choice = posmod(exit_choice+step,2)
			else: pause_choice = posmod(pause_choice+step,3)
		KEY_ENTER, KEY_SPACE:
			if exit_stage_confirmation:
				activate_pointer((EXIT_CANCEL_BUTTON if exit_choice==0 else EXIT_CONFIRM_BUTTON).get_center())
			else:
				activate_pointer([SOUND_BUTTON,RESUME_BUTTON,EXIT_STAGE_BUTTON][pause_choice].get_center())
		_: return false
	return true

func draw_campsite_header() -> void:
	var source = Rect2(20,200,1956,336)
	var target = Rect2(18,38,684,source.size.y*684.0/source.size.x)
	draw_texture_rect_region(CAMP_HEADER,target,source)
	var name_size = 31
	while name_size>16 and heading_font.get_string_size(scout_name,HORIZONTAL_ALIGNMENT_LEFT,-1,name_size).x>230:
		name_size -= 1
	card_text(ScoutProfile.NAME,87,scout_name,name_size,JOURNAL_INK)
	var scale_factor = target.size.x/source.size.x
	var plaque = Rect2(target.position+(Vector2(584,394)-source.position)*scale_factor,Vector2(640,100)*scale_factor)
	card_text(plaque,plaque.get_center().y+8,"Stage %d unlocked" % unlocked_stage,22,LEAF_GREEN)
	for i in range(2):
		var counter = Rect2(target.position+(Vector2(1375+i*231,438)-source.position)*scale_factor,Vector2(162,64)*scale_factor)
		var label = str(completed_runs if i==0 else cleared_runs)
		var font_size = 28
		while font_size>12 and ui_font(font_size).get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>counter.size.x:
			font_size -= 1
		card_text(counter,counter.get_center().y+font_size*0.35,label,font_size,JOURNAL_INK)

func draw_workbench_header() -> void:
	# Uniform source-to-screen scale preserves the selected artwork's proportions.
	var source = Rect2(0,140,2172,405)
	var scale_factor = 646.0/source.size.x
	draw_texture_rect_region(WORKBENCH,Rect2(Vector2(37,340),source.size*scale_factor),source)
	var left = Rect2(166,350,171,95)
	var right = Rect2(386,350,171,95)
	card_text(left,371,"GROWTH",23,LEAF_GREEN)
	card_text(right,371,"ACORNS",23,LEAF_GREEN)
	card_text(left,395,"Packets: %d" % growth.packets,20,JOURNAL_INK)
	card_text(right,395,"Acorns: %d" % growth.acorns,20,JOURNAL_INK)
	card_text(left,417,"Growth %d / 100" % growth.growth_level(),17,JOURNAL_INK)
	card_text(right,417,"All acorns earned" if growth.growth_level()>=100 else "Next: Growth %d" % ((growth.growth_level()/10+1)*10),17,JOURNAL_INK)
	var meter = Rect2(181,428,142,7)
	draw_style_box(bar_style(Color("aaa680")),meter)
	draw_style_box(bar_style(LEAF_GREEN),Rect2(meter.position,Vector2(maxf(2,meter.size.x*growth.growth_level()/100.0),7)))

func bar_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	return style

func walk_enemy(e: Dictionary, direction: Vector2, pace: float, dt: float) -> void:
	var desired = steering(e,direction)
	var previous: Vector2 = e.get("walk_velocity",desired*pace)
	# Turn and accelerate smoothly; special rush/windup/recovery paths stay exact.
	var velocity = previous.move_toward(desired*pace,pace*7.0*dt)
	e.walk_velocity = velocity
	e.p = move_actor(e.p,velocity*dt,e.radius,ENEMY_SIZES[e.kind]/2)

func mark_enemy_hit(enemy: Dictionary, amount: float) -> void:
	enemy.trail_hp = maxf(float(enemy.get("trail_hp",enemy.hp)),float(enemy.hp))
	enemy.bar_delay = 0.18
	settings.hit(enemy.p+Vector2(0,-enemy.radius-5),amount,enemy.uid)

func update_enemy_health_feedback(enemy: Dictionary, dt: float) -> void:
	enemy.bar_delay = maxf(0,float(enemy.get("bar_delay",0))-dt)
	var previous = float(enemy.get("trail_hp",enemy.hp))
	if enemy.bar_delay<=0:
		previous=move_toward(previous,maxf(0,enemy.hp),float(enemy.max_hp)*1.5*dt)
	enemy.trail_hp=clampf(previous,maxf(0,enemy.hp),enemy.max_hp)
	enemy.display_hp=move_toward(float(enemy.get("display_hp",enemy.hp)),maxf(0,enemy.hp),float(enemy.max_hp)*3.0*dt)

func draw_health_fill(track: Rect2, amount: float, color: Color) -> void:
	amount=clampf(amount,0,1)
	if amount<=0: return
	var radius=track.size.y/2
	var edge=track.position.x+track.size.x*amount
	var points=PackedVector2Array()
	for i in range(17):
		var angle=PI/2+PI*i/16.0
		points.append(Vector2(track.position.x+radius,track.get_center().y)+Vector2.from_angle(angle)*radius)
	for i in range(17):
		var angle=-PI/2+PI*i/16.0
		points.append(Vector2(track.end.x-radius,track.get_center().y)+Vector2.from_angle(angle)*radius)
	var clipped=PackedVector2Array()
	var previous=points[-1]
	for point in points:
		if (point.x<=edge)!=(previous.x<=edge):
			clipped.append(previous.lerp(point,(edge-previous.x)/(point.x-previous.x)))
		if point.x<=edge: clipped.append(point)
		previous=point
	if clipped.size()<3: return
	var colors=PackedColorArray()
	for point in clipped:
		colors.append(color.lightened(0.15).lerp(color.darkened(0.12),(point.y-track.position.y)/track.size.y))
	draw_polygon(clipped,colors)

func draw_combat_health(rect: Rect2, health: float, trail: float, elite: bool = false, hit: float = 0.0) -> void:
	var frame=rect.grow(4)
	var source=Rect2(235,220,1700,274)
	var scale_factor=frame.size.y/source.size.y
	var cap=200.0*scale_factor
	var dx=frame.position.x
	var sx=source.position.x
	var widths=[cap,frame.size.x-cap*2,cap]
	var source_widths=[200.0,1300.0,200.0]
	for i in range(3):
		draw_texture_rect_region(HEALTH_WOOD_FRAME,Rect2(dx,frame.position.y,widths[i],frame.size.y),Rect2(sx,source.position.y,source_widths[i],source.size.y))
		dx+=widths[i]
		sx+=source_widths[i]
	var track=Rect2(frame.position+Vector2(66,72)*scale_factor,Vector2(frame.size.x-132*scale_factor,128*scale_factor))
	# Clip one continuous capsule at the health boundary, rather than nesting
	# rounded mini-bars/highlights inside the illustrated track.
	draw_health_fill(track,trail,Color("b8cf83"))
	draw_health_fill(track,health,Color("70b746"))
	var sway=0.0 if settings.values.reduced_vfx else sin(elapsed*2.3+rect.position.x*0.02)*0.65+sin(hit*PI)*1.4
	var leaf_extent=frame.size.y*(1.55 if elite else 1.4)
	garden_leaf(Vector2(frame.position.x+1,frame.get_center().y+sway),leaf_extent/64.0)


func enemy_art(kind: int, phase: int = 0) -> Dictionary:
	if kind>=9:
		var regions=[Rect2(270,110,1080,805),Rect2(172,145,1297,713),Rect2(95,265,1375,510)]
		var region: Rect2=regions[kind-9]
		return {"texture":GARDEN_BUG_TEXTURES[kind-9],"region":region,"size":region.size*ENEMY_SIZES[kind]/maxf(region.size.x,region.size.y)}
	var atlas: Array=elite_regions if Tuning.is_elite(kind) else enemy_regions
	var base: int=kind-6 if Tuning.is_elite(kind) else [0,1,2,6,7,8][kind]
	var region: Rect2=atlas[base+phase*3]
	var largest=maxf(maxf(atlas[base].size.x,atlas[base].size.y),maxf(atlas[base+3].size.x,atlas[base+3].size.y))
	return {"texture":ELITE_TEXTURE if Tuning.is_elite(kind) else ENEMY_TEXTURE,"region":region,"size":region.size*ENEMY_SIZES[kind]/largest}

func enemy_targetable(e: Dictionary) -> bool:
	return not (e.kind==11 and e.mode=="burrow")

func enemy_contact(e: Dictionary, previous: Vector2) -> bool:
	if e.kind==11 and e.mode in ["dig","burrow","emerge"]: return false
	if e.kind==10:
		if e.mode in ["crouch","hop"]: return false
		# Landing only hits the landing point, never the airborne flight segment.
		return e.p.distance_to(player)<e.radius+15
	return Combat.hit_fraction(previous,e.p,player,e.radius+15)!=INF

func update_garden_bug(e: Dictionary, dt: float) -> void:
	e.timer-=dt
	var direction: Vector2=(player-e.p).normalized()
	var distance: float=e.p.distance_to(player)
	if e.mode=="recover":
		if e.timer<=0:
			e.mode="seek"
			e.timer=2.8+float(e.uid%4)*0.25
		return
	if e.kind==9:
		if e.mode=="brace":
			if e.timer<=0:
				e.mode="rush"
				e.timer=0.32
			return
		if e.mode=="rush":
			e.p=move_actor(e.p,e.aim*210*dt,e.radius)
			if e.timer<=0:
				e.mode="recover"
				e.timer=0.7
			return
		if e.timer<=0 and distance<180 and elapsed<SPAWN_DURATION and clear_line(e.p,player):
			e.mode="brace"
			e.aim=direction
			e.timer=0.7
			return
	elif e.kind in [10,11]:
		var preparing="crouch" if e.kind==10 else "dig"
		var traveling="hop" if e.kind==10 else "burrow"
		if e.mode==preparing:
			if e.timer<=0:
				e.mode=traveling
				e.timer=0.5 if e.kind==10 else 0.75
				e.travel_start=e.p
			return
		if e.mode==traveling:
			var duration=0.5 if e.kind==10 else 0.75
			var target: Vector2=e.travel_start.lerp(e.goal,clampf(1.0-e.timer/duration,0,1))
			e.p=move_actor(e.p,target-e.p,e.radius)
			if e.timer<=0:
				e.mode="recover" if e.kind==10 else "emerge"
				e.timer=0.75
			return
		if e.mode=="emerge":
			if e.timer<=0:
				e.mode="recover"
				e.timer=0.45
			return
		if e.timer<=0 and distance>80 and distance<260 and elapsed<SPAWN_DURATION and clear_line(e.p,player):
			e.goal=constrain_actor(e.p+direction*minf(distance,175),e.radius)
			e.mode=preparing
			e.aim=direction
			e.timer=0.8
			return
	walk_enemy(e,direction,e.speed,dt)

func draw_garden_bug_warning(e: Dictionary) -> void:
	var color: Color=Tuning.ENEMY_COLORS[e.kind]
	if e.mode=="brace":
		draw_arc(e.p,e.radius+5,0,TAU,24,color,2,true)
		draw_line(e.p+e.aim*20,e.p+e.aim*68,Color(color,0.65),2,true)
	elif e.mode in ["crouch","dig","hop","burrow","emerge"]:
		# Essential telegraphs remain visible under reduced VFX.
		var goal: Vector2=e.get("goal",e.p)
		draw_circle(goal,21,Color(color,0.14))
		draw_arc(goal,21,0,TAU,24,color,2,true)
		if e.kind==11:
			for i in range(5):
				var at: Vector2=e.p+Vector2.from_angle(i*TAU/5+e.timer)*float(5+i)
				draw_circle(at,4,Color("57412a"))
				draw_circle(at+Vector2(-1,-1),2.5,Color("ac8150"))
