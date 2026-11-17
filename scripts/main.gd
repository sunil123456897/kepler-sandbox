extends Node2D

const WorldTerrainScript = preload("res://scripts/world_terrain.gd")
const HudWorldLawsScript = preload("res://scripts/hud_world_laws.gd")
const BRUSH_CANAL: int = WorldTerrainScript.BrushMode.LOWER_CANAL
const BRUSH_ORBITAL_STRIKE: int = 6
const BRUSH_COLONY: int = 100
const BRUSH_BLESS: int = 101
const BRUSH_INSPECT: int = 102
const BRUSH_STORM_RAIN: int = 103
const BRUSH_STORM_FIRE: int = 104
const BRUSH_STORM_ION: int = 105
const BRUSH_DIPLO_SPARK: int = 106
const BRUSH_AI_GLITCH: int = 107
const BRUSH_XENO_VIRUS: int = 108
const BRUSH_BIO_SEEDER: int = 109

const SAVE_MAGIC: int = 0x4B45504C
const SAVE_VERSION: int = 5
const DEFAULT_SAVE_PATH := "user://kepler_slot1.dat"

const STRIP_PACT: int = 8
const STRIP_WAR: int = 9
const STRIP_REBEL: int = 10

const POWER_TAB_EARTH: int = 0
const POWER_TAB_WEATHER: int = 1
const POWER_TAB_WAR: int = 2
const POWER_TAB_EVO: int = 3

const FACTION_RETICLE_COLORS := [Color("#38F0FF"), Color("#E63B3B"), Color("#B84DFF")]
const FACTION_NAMES_RU := ["Люди", "Роботы", "Споры"]
const DIPLO_NAMES_RU := ["Мир", "Пакт", "Война", "Мятеж"]
const COSMIC_AGE_KEYS := ["GOLD", "SOLAR_FLARE", "ICE_SHADOW", "SPORE_BLOOM", "ION_STORM"]
const COSMIC_AGE_LABELS_RU := ["Золотое окно", "Солнечная буря", "Ледяная тень", "Спороцвет", "Ионный шторм"]
const COSMIC_AGE_COLORS := [
	Color("#F5C84B"),
	Color("#FF7A38"),
	Color("#6CD4FF"),
	Color("#7CE86B"),
	Color("#46F2FF"),
]
const STATE_NAMES_RU := {
	"Thriving": "Процветает",
	"Alerted": "Тревога",
	"Starving": "Голод",
	"Constructing": "Стройка",
	"Total War": "Война",
	"Rebellion": "Мятеж",
	"EMP Glitch": "ИИ-Сбой",
}

enum LightMode {
	DAY = 0,
	DUSK = 1,
	NIGHT = 2,
	CYCLE = 3,
}

const ZOOM_STOPS: Array[float] = [1.2, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0, 12.0]

const TUNING_KNOBS := {
	"POPULATION_COUNT": 0,
	"ZOOM_MIN": 1.2,
	"ZOOM_MAX": 12.0,
	"ZOOM_DEFAULT": 2.0,
	"ZOOM_MACRO_SHOT": 2.0,
	"ZOOM_DETAIL_SHOT": 6.0,
	"ZOOM_STEP": 1.18,
	"ZOOM_SMOOTH_RATE": 14.0,
	"PAN_SPEED": 280.0,
	"FOLLOW_SMOOTH_RATE": 11.0,
	"BREATHE_AMPLITUDE_PX": 0.30,
	"BREATHE_FREQ_X": 0.43,
	"BREATHE_FREQ_Y": 0.31,
	"TRAUMA_DECAY": 1.65,
	"SHAKE_MAX_OFFSET_PX": 14.0,
	"SHAKE_MAX_ROLL_RAD": 0.042,
	"SHAKE_NOISE_SPEED": 36.0,
	"HIT_STOP_MAX_SEC": 0.085,
	"SIM_SUBSTEP_MAX_DT": 0.033,
	"SIM_MAX_SUBSTEPS": 7,
	"SIM_FRAME_BUDGET_USEC": 10500,
	"BRUSH_SIZE_XS": 4,
	"BRUSH_SIZE_S": 8,
	"BRUSH_SIZE_M": 16,
	"BRUSH_SIZE_L": 28,
	"BRUSH_SIZE_XL": 48,
	"METEOR_BLAST_MULT": 2.65,
	"METEOR_BLAST_FORCE": 140.0,
	"METEOR_REPEAT_SEC": 0.26,
	"BLESS_REPEAT_SEC": 0.18,
	"STORM_REPEAT_SEC": 0.18,
	"EVO_REPEAT_SEC": 0.22,
	"VORTEX_RADIUS_MULT": 2.8,
	"VORTEX_STRENGTH": 125.0,
	"BRUSH_SFX_COOLDOWN_SEC": 0.09,
	"FPS_UPDATE_INTERVAL_SEC": 0.25,
	"ORBITAL_CYCLE_SEC": 72.0,
	"CIV_SMOKE_SEED": 20261114,
	"CIV_SHOT_TICKS": 280,
}

@onready var _world_env: WorldEnvironment = $WorldEnvironment
@onready var _canvas_modulate: CanvasModulate = $CanvasModulate
@onready var _world: Node2D = $WorldTerrain
@onready var _civ: Node2D = $CivSim
@onready var _physics: Node2D = $UnitPhysics
@onready var _combat: Node2D = $CombatAndBeams
@onready var _fx: Node2D = $FxAudio
@onready var _world_overlay: Node2D = $WorldOverlay
@onready var _reticle: Node2D = $BrushReticle
@onready var _camera: Camera2D = $Camera2D
@onready var _macro_badges: Control = $HUD/MacroBadges

@onready var _top_bar: PanelContainer = $HUD/TopBar
@onready var _planet_label: Label = $HUD/TopBar/TopRow/PlanetLabel
@onready var _colonists_label: Label = $HUD/TopBar/TopRow/ColonistsLabel
@onready var _cities_label: Label = $HUD/TopBar/TopRow/CitiesLabel
@onready var _tech_label: Label = $HUD/TopBar/TopRow/TechLabel
@onready var _wars_label: Label = $HUD/TopBar/TopRow/WarsLabel
@onready var _flora_label: Label = $HUD/TopBar/TopRow/FloraLabel
@onready var _temp_label: Label = $HUD/TopBar/TopRow/TempLabel
@onready var _btn_light_day: Button = $HUD/TopBar/TopRow/LightRow/BtnLightDay
@onready var _btn_light_dusk: Button = $HUD/TopBar/TopRow/LightRow/BtnLightDusk
@onready var _btn_light_night: Button = $HUD/TopBar/TopRow/LightRow/BtnLightNight
@onready var _btn_light_cycle: Button = $HUD/TopBar/TopRow/LightRow/BtnLightCycle
@onready var _btn_speed_0: Button = $HUD/TopBar/TopRow/SpeedRow/BtnSpeed0
@onready var _btn_speed_1: Button = $HUD/TopBar/TopRow/SpeedRow/BtnSpeed1
@onready var _btn_speed_3: Button = $HUD/TopBar/TopRow/SpeedRow/BtnSpeed3
@onready var _btn_speed_5: Button = $HUD/TopBar/TopRow/SpeedRow/BtnSpeed5
@onready var _btn_speed_20: Button = $HUD/TopBar/TopRow/SpeedRow/BtnSpeed20
@onready var _sep_fps: VSeparator = $HUD/TopBar/TopRow/SepFps
@onready var _fps_label: Label = $HUD/TopBar/TopRow/FpsLabel
@onready var _btn_cosmic_age: Button = $HUD/TopBar/TopRow/BtnCosmicAge
@onready var _btn_laws: Button = $HUD/TopBar/TopRow/BtnLaws

@onready var _inspector_panel: PanelContainer = $HUD/InspectorPanel
@onready var _entity_header_label: Label = $HUD/InspectorPanel/InspectorBox/EntityHeaderLabel
@onready var _entity_detail_label: Label = $HUD/InspectorPanel/InspectorBox/EntityDetailLabel
@onready var _entity_extra_label: Label = $HUD/InspectorPanel/InspectorBox/EntityExtraLabel
@onready var _memory_label: Label = $HUD/InspectorPanel/InspectorBox/MemoryLabel
@onready var _btn_possess: Button = $HUD/InspectorPanel/InspectorBox/BtnPossess
@onready var _loc_label: Label = $HUD/InspectorPanel/InspectorBox/LocLabel
@onready var _metrics_label: Label = $HUD/InspectorPanel/InspectorBox/MetricsLabel

@onready var _bottom_dock: PanelContainer = $HUD/BottomDock
@onready var _btn_tab_earth: Button = $HUD/BottomDock/DockRow/TabsRow/BtnTabEarth
@onready var _btn_tab_weather: Button = $HUD/BottomDock/DockRow/TabsRow/BtnTabWeather
@onready var _btn_tab_war: Button = $HUD/BottomDock/DockRow/TabsRow/BtnTabWar
@onready var _btn_tab_evo: Button = $HUD/BottomDock/DockRow/TabsRow/BtnTabEvo
@onready var _group_earth: HBoxContainer = $HUD/BottomDock/DockRow/GroupEarth
@onready var _group_weather: HBoxContainer = $HUD/BottomDock/DockRow/GroupWeather
@onready var _group_war: HBoxContainer = $HUD/BottomDock/DockRow/GroupWar
@onready var _group_evo: HBoxContainer = $HUD/BottomDock/DockRow/GroupEvo

@onready var _btn_terraform: Button = $HUD/BottomDock/DockRow/GroupEarth/BtnTerraform
@onready var _btn_canal: Button = $HUD/BottomDock/DockRow/GroupEarth/BtnCanal
@onready var _btn_crystal: Button = $HUD/BottomDock/DockRow/GroupEarth/BtnCrystal
@onready var _btn_lava: Button = $HUD/BottomDock/DockRow/GroupEarth/BtnLava
@onready var _btn_rain: Button = $HUD/BottomDock/DockRow/GroupWeather/BtnRain
@onready var _btn_firestorm: Button = $HUD/BottomDock/DockRow/GroupWeather/BtnFirestorm
@onready var _btn_ion_storm: Button = $HUD/BottomDock/DockRow/GroupWeather/BtnIonStorm
@onready var _btn_diplo: Button = $HUD/BottomDock/DockRow/GroupWar/BtnDiplo
@onready var _btn_orbital_strike: Button = $HUD/BottomDock/DockRow/GroupWar/BtnOrbitalStrike
@onready var _btn_meteor: Button = $HUD/BottomDock/DockRow/GroupWar/BtnMeteor
@onready var _btn_vortex: Button = $HUD/BottomDock/DockRow/GroupWar/BtnVortex
@onready var _btn_ai_glitch: Button = $HUD/BottomDock/DockRow/GroupEvo/BtnAiGlitch
@onready var _btn_xeno_virus: Button = $HUD/BottomDock/DockRow/GroupEvo/BtnXenoVirus
@onready var _btn_bio_seeder: Button = $HUD/BottomDock/DockRow/GroupEvo/BtnBioSeeder

@onready var _btn_colony: Button = $HUD/BottomDock/DockRow/BtnColony
@onready var _btn_fac_human: Button = $HUD/BottomDock/DockRow/FactionRow/BtnFactionHuman
@onready var _btn_fac_robot: Button = $HUD/BottomDock/DockRow/FactionRow/BtnFactionRobot
@onready var _btn_fac_spore: Button = $HUD/BottomDock/DockRow/FactionRow/BtnFactionSpore
@onready var _btn_size_4: Button = $HUD/BottomDock/DockRow/SizeRow/BtnSize4
@onready var _btn_size_8: Button = $HUD/BottomDock/DockRow/SizeRow/BtnSize8
@onready var _btn_size_16: Button = $HUD/BottomDock/DockRow/SizeRow/BtnSize16
@onready var _btn_size_28: Button = $HUD/BottomDock/DockRow/SizeRow/BtnSize28
@onready var _btn_size_48: Button = $HUD/BottomDock/DockRow/SizeRow/BtnSize48
@onready var _btn_bless: Button = $HUD/BottomDock/DockRow/BtnBless
@onready var _btn_inspect: Button = $HUD/BottomDock/DockRow/BtnInspect
@onready var _btn_regen: Button = $HUD/BottomDock/DockRow/BtnRegen

var _current_brush: int = WorldTerrainScript.BrushMode.TERRAFORM_LIFE
var _active_power_tab: int = POWER_TAB_EARTH
var _brush_radius: int = int(TUNING_KNOBS["BRUSH_SIZE_M"])
var _sim_speed: float = 1.0
var _sim_pace_mult: float = 1.0
var _last_nonzero_speed: float = 1.0
var _seed_counter: int = 20261114
var _selected_faction: int = 0
var _light_mode: int = LightMode.DAY
var _orbital_phase: float = 0.06
var _night_mix: float = 0.0

var _target_zoom: float = float(TUNING_KNOBS["ZOOM_DEFAULT"])
var _cam_base_pos: Vector2 = Vector2(320.0, 180.0)
var _cam_focus_active: bool = false
var _cam_focus_target: Vector2 = Vector2(320.0, 180.0)
var _panning_rmb: bool = false
var _painting_lmb: bool = false
var _has_mouse_hover: bool = false
var _hover_world_pos: Vector2 = Vector2(320.0, 180.0)

var _locked_unit_uid: int = -1
var _locked_city_id: int = -1
var _locked_city_pos: Vector2 = Vector2.ZERO
var _follow_locked_unit: bool = false
var _last_inspect_unit_uid: int = -1
var _possessing_uid: int = -1
var _possess_pulse_queued: bool = false
var _possess_cooldown: float = 0.0

var _cosmic_age_id: int = 0
var _cosmic_age_tint: Color = Color.WHITE
var _cosmic_age_tint_strength: float = 0.0

var _prev_hover_world_pos: Vector2 = Vector2(320.0, 180.0)
var _cursor_speed_ema: float = 0.0
var _orbital_strike_cooldown: float = 0.0

var _trauma: float = 0.0
var _last_trauma_frame: int = -1
var _hit_stop_timer: float = 0.0
var _elapsed_time: float = 0.0
var _meteor_cooldown: float = 0.0
var _bless_cooldown: float = 0.0
var _storm_cooldown: float = 0.0
var _evo_cooldown: float = 0.0
var _terrain_hold_cooldown: float = 0.0
var _vortex_terrain_cooldown: float = 0.0
var _sfx_cooldown: float = 0.0
var _shake_noise := FastNoiseLite.new()

var _fps_ema: float = 60.0
var _fps_accum_time: float = 0.0
var _fps_frames_skipped: int = 0

var _smoke_mode: bool = false
var _smoke_civ_mode: bool = false
var _smoke_combat_mode: bool = false
var _smoke_worldbox_pace_mode: bool = false
var _screenshot_path: String = ""
var _zoom_shot_path: String = ""
var _shot_civ_path: String = ""
var _shot_night_path: String = ""
var _shot_combat_path: String = ""
var _capture_frames_waited: int = 0
var _capturing_now: bool = false
var _showcase_anchor: Vector2 = Vector2(320.0, 180.0)
var _combat_shot_ctx: Dictionary = {}
var _world_laws_ui: RefCounted = null

var _style_panel: StyleBoxFlat
var _style_btn_normal: StyleBoxFlat
var _style_btn_hover: StyleBoxFlat
var _style_btn_tab_normal: StyleBoxFlat
var _style_btn_tab_hover: StyleBoxFlat
var _style_btn_tab_pressed_cyan: StyleBoxFlat
var _style_btn_tab_pressed_war: StyleBoxFlat
var _style_btn_tab_pressed_evo: StyleBoxFlat
var _style_btn_size_normal: StyleBoxFlat
var _style_btn_size_hover: StyleBoxFlat
var _style_btn_size_pressed: StyleBoxFlat
var _style_btn_pressed_cyan: StyleBoxFlat
var _style_btn_pressed_warm: StyleBoxFlat
var _style_btn_pressed_robot: StyleBoxFlat
var _style_btn_pressed_spore: StyleBoxFlat
var _style_btn_pressed_gold: StyleBoxFlat
var _cosmic_age_styles: Array[StyleBoxFlat] = []


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#080E18"))
	get_viewport().use_hdr_2d = true

	_shake_noise.seed = 4421
	_shake_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_shake_noise.frequency = 0.12

	_configure_world_environment()
	_apply_hud_theme()
	_wire_ui()
	_setup_world_laws_ui()

	_world_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_reticle.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_camera.ignore_rotation = false
	_cam_base_pos = Vector2(float(_world.map_w) * 0.5, float(_world.map_h) * 0.5)
	_camera.position = _cam_base_pos.round()
	_camera.zoom = Vector2(_target_zoom, _target_zoom)
	if _fx != null and _fx.has_method("set_camera_center_x"):
		_fx.set_camera_center_x(_cam_base_pos.x)

	_reticle.draw.connect(_on_reticle_draw)
	_world_overlay.draw.connect(_on_world_overlay_draw)
	_macro_badges.draw.connect(_on_macro_badges_draw)

	if _world.has_signal("region_changed"):
		_world.region_changed.connect(_on_world_region_changed)
	if _world.has_signal("cosmic_age_changed"):
		_world.cosmic_age_changed.connect(_on_cosmic_age_changed)
	if _physics.has_signal("impact_trauma"):
		_physics.impact_trauma.connect(_on_impact_trauma)
	if _fx.has_signal("impact_trauma") and not _fx.impact_trauma.is_connected(_on_impact_trauma):
		_fx.impact_trauma.connect(_on_impact_trauma)

	_physics.bind_systems(_world, _fx)
	_physics.rebuild_population(int(TUNING_KNOBS["POPULATION_COUNT"]))
	_civ.bind_systems(_world, _physics, _fx)
	if _combat != null and _combat.has_method("bind_systems"):
		_combat.bind_systems(_world, _physics, _civ)
	if _combat != null and _combat.has_signal("impact_trauma") and not _combat.impact_trauma.is_connected(_on_impact_trauma):
		_combat.impact_trauma.connect(_on_impact_trauma)

	_apply_sim_pace(1.0)
	if _world_laws_ui != null:
		_broadcast_world_laws(_world_laws_ui.get_laws())

	_select_power_tab(POWER_TAB_EARTH, false)
	_select_brush(WorldTerrainScript.BrushMode.TERRAFORM_LIFE)
	_select_faction(0)
	_select_brush_size(int(TUNING_KNOBS["BRUSH_SIZE_M"]))
	_set_sim_speed(1.0)
	_set_light_mode(LightMode.DAY)
	_sync_cosmic_age_state()
	_update_hud_telemetry()
	_sync_hud_layouts()

	_parse_cli_args()
	if _smoke_mode:
		call_deferred("_run_headless_smoke")
	elif _smoke_civ_mode:
		call_deferred("_run_headless_smoke_civ")
	elif _smoke_combat_mode:
		call_deferred("_run_headless_smoke_combat")
	elif _smoke_worldbox_pace_mode:
		call_deferred("_run_headless_smoke_worldbox_pace")
	elif _is_capture_mode():
		_prepare_capture_mode()


func _exit_tree() -> void:
	_combat_shot_ctx.clear()
	if _world_laws_ui != null:
		_world_laws_ui.dispose()
		_world_laws_ui = null
	_shake_noise = null
	_style_panel = null
	_style_btn_normal = null
	_style_btn_hover = null
	_style_btn_tab_normal = null
	_style_btn_tab_hover = null
	_style_btn_tab_pressed_cyan = null
	_style_btn_tab_pressed_war = null
	_style_btn_tab_pressed_evo = null
	_style_btn_size_normal = null
	_style_btn_size_hover = null
	_style_btn_size_pressed = null
	_style_btn_pressed_cyan = null
	_style_btn_pressed_warm = null
	_style_btn_pressed_robot = null
	_style_btn_pressed_spore = null
	_style_btn_pressed_gold = null
	_cosmic_age_styles.clear()


func _configure_world_environment() -> void:
	var env: Environment = _world_env.environment
	if env == null:
		env = Environment.new()
		_world_env.environment = env
	env.background_mode = Environment.BG_CANVAS
	env.background_canvas_max_layer = 1
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_agx_white = 6.0
	env.glow_enabled = true
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.glow_hdr_threshold = 1.0
	env.glow_hdr_scale = 2.0
	env.glow_intensity = 0.85
	env.glow_strength = 1.05
	env.glow_bloom = 0.14


func _make_box_style(bg: Color, border: Color, rad: int, pad_x: float, pad_y: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(rad)
	box.content_margin_left = pad_x
	box.content_margin_right = pad_x
	box.content_margin_top = pad_y
	box.content_margin_bottom = pad_y
	return box


func _apply_hud_theme() -> void:
	_style_panel = _make_box_style(Color(0.047, 0.075, 0.118, 0.88), Color(0.22, 0.37, 0.50, 0.72), 4, 6.0, 4.0)
	_style_panel.shadow_color = Color(0.01, 0.02, 0.04, 0.48)
	_style_panel.shadow_size = 5
	_style_panel.shadow_offset = Vector2(0.0, 2.0)

	_style_btn_normal = _make_box_style(Color(0.082, 0.129, 0.192, 0.90), Color(0.20, 0.34, 0.46, 0.65), 3, 4.0, 3.0)
	_style_btn_hover = _make_box_style(Color(0.125, 0.200, 0.294, 0.96), Color(0.36, 0.69, 0.86, 0.88), 3, 4.0, 3.0)
	_style_btn_size_normal = _make_box_style(Color(0.082, 0.129, 0.192, 0.90), Color(0.20, 0.34, 0.46, 0.65), 3, 3.0, 3.0)
	_style_btn_size_hover = _make_box_style(Color(0.125, 0.200, 0.294, 0.96), Color(0.36, 0.69, 0.86, 0.88), 3, 3.0, 3.0)
	_style_btn_size_pressed = _make_box_style(Color(0.094, 0.278, 0.369, 0.96), Color(0.28, 0.87, 0.96, 1.0), 3, 3.0, 3.0)
	_style_btn_pressed_cyan = _make_box_style(Color(0.094, 0.278, 0.369, 0.96), Color(0.28, 0.87, 0.96, 1.0), 3, 4.0, 3.0)
	_style_btn_pressed_warm = _make_box_style(Color(0.34, 0.145, 0.090, 0.96), Color(0.98, 0.53, 0.22, 1.0), 3, 4.0, 3.0)
	_style_btn_pressed_robot = _make_box_style(Color(0.36, 0.105, 0.125, 0.96), Color(0.90, 0.23, 0.23, 1.0), 3, 4.0, 3.0)
	_style_btn_pressed_spore = _make_box_style(Color(0.25, 0.115, 0.36, 0.96), Color(0.72, 0.30, 1.0, 1.0), 3, 4.0, 3.0)
	_style_btn_pressed_gold = _make_box_style(Color(0.32, 0.225, 0.060, 0.96), Color("#FFD15C"), 3, 4.0, 3.0)

	_style_btn_tab_normal = _make_box_style(Color(0.055, 0.088, 0.135, 0.84), Color(0.18, 0.30, 0.42, 0.45), 3, 4.0, 2.5)
	_style_btn_tab_hover = _make_box_style(Color(0.095, 0.145, 0.215, 0.92), Color(0.30, 0.56, 0.74, 0.72), 3, 4.0, 2.5)
	_style_btn_tab_pressed_cyan = _make_box_style(Color(0.085, 0.175, 0.245, 0.94), Color(0.36, 0.74, 0.88, 0.78), 3, 4.0, 2.5)
	_style_btn_tab_pressed_cyan.border_width_bottom = 2
	_style_btn_tab_pressed_war = _make_box_style(Color(0.21, 0.105, 0.125, 0.94), Color(0.84, 0.36, 0.36, 0.78), 3, 4.0, 2.5)
	_style_btn_tab_pressed_war.border_width_bottom = 2
	_style_btn_tab_pressed_evo = _make_box_style(Color(0.165, 0.105, 0.245, 0.94), Color(0.64, 0.38, 0.88, 0.78), 3, 4.0, 2.5)
	_style_btn_tab_pressed_evo.border_width_bottom = 2

	_cosmic_age_styles.clear()
	for age_col in COSMIC_AGE_COLORS:
		var bg_c := Color(age_col.r * 0.24 + 0.04, age_col.g * 0.24 + 0.06, age_col.b * 0.24 + 0.08, 0.94)
		var rim_c := Color(age_col.r, age_col.g, age_col.b, 0.86)
		_cosmic_age_styles.append(_make_box_style(bg_c, rim_c, 3, 4.0, 3.0))

	for panel in [_top_bar, _inspector_panel, _bottom_dock]:
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.add_theme_stylebox_override("panel", _style_panel)

	var text_main := Color("#E2ECF5")
	var text_accent := Color("#7CE7FF")
	for lbl in [_colonists_label, _cities_label, _tech_label, _wars_label, _flora_label, _temp_label, _fps_label]:
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", text_main)
	_planet_label.add_theme_font_size_override("font_size", 11)
	_planet_label.add_theme_color_override("font_color", text_accent)

	_entity_header_label.add_theme_font_size_override("font_size", 12)
	_entity_header_label.add_theme_color_override("font_color", text_accent)
	for lbl in [_entity_detail_label, _entity_extra_label, _loc_label, _metrics_label]:
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", text_main)
	_memory_label.add_theme_font_size_override("font_size", 10)
	_memory_label.add_theme_color_override("font_color", Color("#A8B8C8"))

	var all_buttons: Array[Button] = [
		_btn_light_day, _btn_light_dusk, _btn_light_night, _btn_light_cycle,
		_btn_speed_0, _btn_speed_1, _btn_speed_3, _btn_speed_5, _btn_speed_20, _btn_cosmic_age,
		_btn_possess,
		_btn_terraform, _btn_canal, _btn_crystal, _btn_lava,
		_btn_rain, _btn_firestorm, _btn_ion_storm,
		_btn_diplo, _btn_orbital_strike, _btn_meteor, _btn_vortex,
		_btn_ai_glitch, _btn_xeno_virus, _btn_bio_seeder,
		_btn_colony, _btn_fac_human, _btn_fac_robot, _btn_fac_spore,
		_btn_bless, _btn_inspect, _btn_regen,
	]
	for btn in all_buttons:
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color", text_main)
		btn.add_theme_color_override("font_hover_color", Color("#F4FAFF"))
		btn.add_theme_color_override("font_pressed_color", Color("#F7FCFF"))
		btn.add_theme_stylebox_override("normal", _style_btn_normal)
		btn.add_theme_stylebox_override("hover", _style_btn_hover)
		var pressed_box := _style_btn_pressed_cyan
		if btn in [_btn_lava, _btn_meteor, _btn_firestorm, _btn_light_dusk]:
			pressed_box = _style_btn_pressed_warm
		elif btn in [_btn_fac_robot, _btn_diplo]:
			pressed_box = _style_btn_pressed_robot
		elif btn in [_btn_fac_spore, _btn_xeno_virus]:
			pressed_box = _style_btn_pressed_spore
		elif btn in [_btn_bless, _btn_light_day, _btn_bio_seeder, _btn_orbital_strike]:
			pressed_box = _style_btn_pressed_gold
		btn.add_theme_stylebox_override("pressed", pressed_box)

	for tbtn in [_btn_tab_earth, _btn_tab_weather, _btn_tab_war, _btn_tab_evo]:
		tbtn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tbtn.add_theme_font_size_override("font_size", 10)
		tbtn.add_theme_color_override("font_color", Color("#9DB2C7"))
		tbtn.add_theme_color_override("font_hover_color", Color("#E4F2FC"))
		tbtn.add_theme_color_override("font_pressed_color", Color("#EBF5FE"))
		tbtn.add_theme_stylebox_override("normal", _style_btn_tab_normal)
		tbtn.add_theme_stylebox_override("hover", _style_btn_tab_hover)
		var t_pressed := _style_btn_tab_pressed_cyan
		if tbtn == _btn_tab_war:
			t_pressed = _style_btn_tab_pressed_war
		elif tbtn == _btn_tab_evo:
			t_pressed = _style_btn_tab_pressed_evo
		tbtn.add_theme_stylebox_override("pressed", t_pressed)

	for sbtn in [_btn_size_4, _btn_size_8, _btn_size_16, _btn_size_28, _btn_size_48]:
		sbtn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		sbtn.add_theme_font_size_override("font_size", 11)
		sbtn.add_theme_color_override("font_color", text_main)
		sbtn.add_theme_color_override("font_hover_color", Color("#F4FAFF"))
		sbtn.add_theme_color_override("font_pressed_color", Color("#F7FCFF"))
		sbtn.add_theme_stylebox_override("normal", _style_btn_size_normal)
		sbtn.add_theme_stylebox_override("hover", _style_btn_size_hover)
		sbtn.add_theme_stylebox_override("pressed", _style_btn_size_pressed)

	_lock_dock_group_widths()


func _lock_dock_group_widths() -> void:
	var groups: Array[HBoxContainer] = [_group_earth, _group_weather, _group_war, _group_evo]
	var max_w := 0.0
	for grp in groups:
		grp.custom_minimum_size.x = 0.0
		max_w = maxf(max_w, grp.get_combined_minimum_size().x)
	max_w = clampf(max_w, 224.0, 280.0)
	for grp in groups:
		grp.custom_minimum_size.x = max_w
		grp.alignment = BoxContainer.ALIGNMENT_CENTER


func _sync_hud_layouts() -> void:
	_top_bar.reset_size()
	_bottom_dock.reset_size()
	var dock_half := _bottom_dock.size.x * 0.5
	_bottom_dock.offset_left = -dock_half
	_bottom_dock.offset_right = dock_half
	_sync_inspector_layout()
	if _world_laws_ui != null:
		_world_laws_ui.sync_anchors(_top_bar, _inspector_panel)


func _sync_inspector_layout() -> void:
	_inspector_panel.reset_size()
	var w := clampf(_inspector_panel.size.x, 252.0, 276.0)
	_inspector_panel.offset_right = -12.0
	_inspector_panel.offset_left = -12.0 - w
	if _world_laws_ui != null:
		_world_laws_ui.sync_anchors(_top_bar, _inspector_panel)


func _setup_world_laws_ui() -> void:
	_world_laws_ui = HudWorldLawsScript.new()
	_world_laws_ui.setup($HUD, _btn_laws, _style_panel)
	_btn_laws.pressed.connect(_on_laws_button_pressed)
	_world_laws_ui.laws_changed.connect(_on_world_laws_changed)
	_world_laws_ui.chronicle_focus_requested.connect(_on_chronicle_focus_requested)


func _apply_sim_pace(mult: float) -> void:
	_sim_pace_mult = maxf(mult, 0.05)
	for sys in [_world, _civ, _physics, _combat]:
		if sys != null and sys.has_method("set_sim_pace"):
			sys.set_sim_pace(_sim_pace_mult)


func _broadcast_world_laws(laws: Dictionary) -> void:
	for sys in [_world, _civ, _physics, _combat]:
		if sys != null and sys.has_method("set_world_laws"):
			sys.set_world_laws(laws)


func _on_laws_button_pressed() -> void:
	if _world_laws_ui != null:
		_world_laws_ui.toggle_laws_panel()
		_world_laws_ui.sync_anchors(_top_bar, _inspector_panel)
	_fx.play_sfx("ui")


func _on_world_laws_changed(laws: Dictionary) -> void:
	_broadcast_world_laws(laws)
	_fx.play_sfx("ui")


func _on_chronicle_focus_requested(world_pos: Vector2) -> void:
	_follow_locked_unit = false
	_cam_focus_target = _clamp_to_world(world_pos, 16.0)
	_cam_focus_active = true
	_fx.play_sfx("ui")


func _wire_ui() -> void:
	_btn_light_day.pressed.connect(func() -> void: _on_light_clicked(LightMode.DAY))
	_btn_light_dusk.pressed.connect(func() -> void: _on_light_clicked(LightMode.DUSK))
	_btn_light_night.pressed.connect(func() -> void: _on_light_clicked(LightMode.NIGHT))
	_btn_light_cycle.pressed.connect(func() -> void: _on_light_clicked(LightMode.CYCLE))

	_btn_speed_0.pressed.connect(func() -> void: _on_speed_clicked(0.0))
	_btn_speed_1.pressed.connect(func() -> void: _on_speed_clicked(1.0))
	_btn_speed_3.pressed.connect(func() -> void: _on_speed_clicked(3.0))
	_btn_speed_5.pressed.connect(func() -> void: _on_speed_clicked(5.0))
	_btn_speed_20.pressed.connect(func() -> void: _on_speed_clicked(20.0))
	_btn_cosmic_age.pressed.connect(_on_cosmic_age_clicked)
	_btn_possess.pressed.connect(_on_possess_clicked)

	_btn_tab_earth.pressed.connect(func() -> void: _on_tab_clicked(POWER_TAB_EARTH))
	_btn_tab_weather.pressed.connect(func() -> void: _on_tab_clicked(POWER_TAB_WEATHER))
	_btn_tab_war.pressed.connect(func() -> void: _on_tab_clicked(POWER_TAB_WAR))
	_btn_tab_evo.pressed.connect(func() -> void: _on_tab_clicked(POWER_TAB_EVO))

	_btn_terraform.pressed.connect(func() -> void: _on_brush_clicked(WorldTerrainScript.BrushMode.TERRAFORM_LIFE))
	_btn_canal.pressed.connect(func() -> void: _on_brush_clicked(BRUSH_CANAL))
	_btn_crystal.pressed.connect(func() -> void: _on_brush_clicked(WorldTerrainScript.BrushMode.CRYSTAL_FLORA))
	_btn_lava.pressed.connect(func() -> void: _on_brush_clicked(WorldTerrainScript.BrushMode.LAVA_VOLCANO))

	_btn_rain.pressed.connect(func() -> void: _on_brush_clicked(BRUSH_STORM_RAIN))
	_btn_firestorm.pressed.connect(func() -> void: _on_brush_clicked(BRUSH_STORM_FIRE))
	_btn_ion_storm.pressed.connect(func() -> void: _on_brush_clicked(BRUSH_STORM_ION))

	_btn_diplo.pressed.connect(func() -> void: _on_brush_clicked(BRUSH_DIPLO_SPARK))
	_btn_orbital_strike.pressed.connect(func() -> void: _on_brush_clicked(BRUSH_ORBITAL_STRIKE))
	_btn_meteor.pressed.connect(func() -> void: _on_brush_clicked(WorldTerrainScript.BrushMode.METEOR_CRATER))
	_btn_vortex.pressed.connect(func() -> void: _on_brush_clicked(WorldTerrainScript.BrushMode.VORTEX_PULL))

	_btn_ai_glitch.pressed.connect(func() -> void: _on_brush_clicked(BRUSH_AI_GLITCH))
	_btn_xeno_virus.pressed.connect(func() -> void: _on_brush_clicked(BRUSH_XENO_VIRUS))
	_btn_bio_seeder.pressed.connect(func() -> void: _on_brush_clicked(BRUSH_BIO_SEEDER))

	_btn_colony.pressed.connect(func() -> void: _on_brush_clicked(BRUSH_COLONY))
	_btn_bless.pressed.connect(func() -> void: _on_brush_clicked(BRUSH_BLESS))
	_btn_inspect.pressed.connect(func() -> void: _on_brush_clicked(BRUSH_INSPECT))

	_btn_fac_human.pressed.connect(func() -> void: _on_faction_clicked(0))
	_btn_fac_robot.pressed.connect(func() -> void: _on_faction_clicked(1))
	_btn_fac_spore.pressed.connect(func() -> void: _on_faction_clicked(2))

	_btn_size_4.pressed.connect(func() -> void: _on_size_clicked(int(TUNING_KNOBS["BRUSH_SIZE_XS"])))
	_btn_size_8.pressed.connect(func() -> void: _on_size_clicked(int(TUNING_KNOBS["BRUSH_SIZE_S"])))
	_btn_size_16.pressed.connect(func() -> void: _on_size_clicked(int(TUNING_KNOBS["BRUSH_SIZE_M"])))
	_btn_size_28.pressed.connect(func() -> void: _on_size_clicked(int(TUNING_KNOBS["BRUSH_SIZE_L"])))
	_btn_size_48.pressed.connect(func() -> void: _on_size_clicked(int(TUNING_KNOBS["BRUSH_SIZE_XL"])))

	_btn_regen.pressed.connect(_on_regen_pressed)


func _on_world_region_changed(rect: Rect2i) -> void:
	if _civ != null and _civ.has_method("refresh_resource_zone"):
		_civ.refresh_resource_zone(rect)
	if _physics != null and _physics.has_method("sync_flora_region"):
		_physics.sync_flora_region(rect)


func _on_light_clicked(mode: int) -> void:
	_set_light_mode(mode)
	_fx.play_sfx("ui")


func _on_speed_clicked(speed: float) -> void:
	_set_sim_speed(speed)
	_fx.play_sfx("ui")


func _on_brush_clicked(mode: int) -> void:
	_select_brush(mode)
	_fx.play_sfx("ui")


func _on_faction_clicked(faction_id: int) -> void:
	_select_faction(faction_id)
	_select_brush(BRUSH_COLONY)
	_fx.play_sfx("ui")


func _on_size_clicked(radius: int) -> void:
	_select_brush_size(radius)
	_fx.play_sfx("ui")


func _on_regen_pressed() -> void:
	_seed_counter += 1
	_trauma = 0.0
	_hit_stop_timer = 0.0
	_exit_possession()
	_clear_inspector_lock()
	_world.generate_planet(_seed_counter)
	_sync_cosmic_age_state()
	_apply_orbital_lighting(_orbital_phase, _night_mix)
	_fx.play_sfx("ui")


func _on_cosmic_age_changed(_age_id: int) -> void:
	_sync_cosmic_age_state()


func _on_cosmic_age_clicked() -> void:
	var next_age := (_cosmic_age_id + 1) % COSMIC_AGE_KEYS.size()
	if _world.has_method("set_cosmic_age"):
		_world.set_cosmic_age(next_age, true)
	_sync_cosmic_age_state()
	_fx.play_sfx("ui")


func _sync_cosmic_age_state() -> void:
	var info: Dictionary = _world.get_cosmic_age_info() if _world.has_method("get_cosmic_age_info") else {}
	_cosmic_age_id = clampi(int(info.get("id", 0)), 0, COSMIC_AGE_KEYS.size() - 1)
	_cosmic_age_tint = info.get("tint", COSMIC_AGE_COLORS[_cosmic_age_id])
	_cosmic_age_tint_strength = float(info.get("tint_strength", 0.0))

	if _civ != null and _civ.has_method("set_cosmic_age_mods"):
		_civ.set_cosmic_age_mods(
			float(info.get("solar_mul", 1.0)),
			float(info.get("crop_mul", 1.0)),
			float(info.get("fire_mul", 1.0)),
			_cosmic_age_tint,
			_cosmic_age_tint_strength
		)
	if _physics != null and _physics.has_method("set_cosmic_age_mods"):
		_physics.set_cosmic_age_mods(
			float(info.get("flora_mul", 1.0)),
			float(info.get("crop_mul", 1.0)),
			_cosmic_age_tint,
			_cosmic_age_tint_strength
		)
	_refresh_cosmic_age_ui(info)


func _refresh_cosmic_age_ui(info: Dictionary = {}) -> void:
	if _btn_cosmic_age == null:
		return
	var idx := clampi(_cosmic_age_id, 0, COSMIC_AGE_LABELS_RU.size() - 1)
	var ru_name := str(info.get("name_ru", COSMIC_AGE_LABELS_RU[idx]))
	_btn_cosmic_age.text = "Эпоха: %s" % ru_name
	_btn_cosmic_age.add_theme_color_override("font_color", COSMIC_AGE_COLORS[idx].lightened(0.35))
	if idx < _cosmic_age_styles.size():
		_btn_cosmic_age.add_theme_stylebox_override("normal", _cosmic_age_styles[idx])
		_btn_cosmic_age.add_theme_stylebox_override("hover", _cosmic_age_styles[idx])
	_top_bar.reset_size()
	if _top_bar.position.x + _top_bar.size.x > _inspector_panel.position.x - 10.0:
		_btn_cosmic_age.text = ru_name
	_sync_hud_layouts()


func _on_possess_clicked() -> void:
	if _possessing_uid >= 0:
		_exit_possession()
		_fx.play_sfx("ui")
		_update_hud_telemetry()
		return
	var target_uid := _locked_unit_uid if _locked_unit_uid >= 0 else _last_inspect_unit_uid
	if target_uid >= 0:
		_enter_possession(target_uid)
	else:
		_fx.play_sfx("ui")


func _enter_possession(uid: int) -> void:
	if uid < 0:
		return
	var u_info: Dictionary = _physics.inspect_unit_by_id(uid)
	if not bool(u_info.get("found", false)):
		return
	_possessing_uid = uid
	_locked_unit_uid = uid
	_locked_city_id = -1
	_follow_locked_unit = true
	_painting_lmb = false
	_possess_pulse_queued = false
	_btn_possess.visible = true
	_btn_possess.button_pressed = true
	_btn_possess.text = "Выйти [Esc]"
	if _physics.has_method("set_possessed_unit"):
		_physics.set_possessed_unit(uid, Vector2.ZERO, false)
	_fx.play_sfx("ui")
	_reticle.queue_redraw()
	_world_overlay.queue_redraw()
	_update_hud_telemetry()


func _exit_possession() -> void:
	if _possessing_uid >= 0 and _physics != null and _physics.has_method("set_possessed_unit"):
		_physics.set_possessed_unit(-1, Vector2.ZERO, false)
	_possessing_uid = -1
	_possess_pulse_queued = false
	if _btn_possess != null:
		_btn_possess.button_pressed = false
		_btn_possess.text = "Взять управление [P]"
	if _reticle != null:
		_reticle.queue_redraw()
	if _world_overlay != null:
		_world_overlay.queue_redraw()


func _on_impact_trauma(trauma: float, hit_stop_sec: float) -> void:
	var frame := Engine.get_process_frames()
	if frame != _last_trauma_frame:
		_trauma = clampf(_trauma + trauma, 0.0, 1.0)
		_last_trauma_frame = frame
	else:
		_trauma = clampf(maxf(_trauma, trauma), 0.0, 1.0)
	_hit_stop_timer = maxf(_hit_stop_timer, clampf(hit_stop_sec, 0.0, float(TUNING_KNOBS["HIT_STOP_MAX_SEC"])))


func _set_light_mode(mode: int) -> void:
	_light_mode = clampi(mode, LightMode.DAY, LightMode.CYCLE)
	_btn_light_day.button_pressed = (_light_mode == LightMode.DAY)
	_btn_light_dusk.button_pressed = (_light_mode == LightMode.DUSK)
	_btn_light_night.button_pressed = (_light_mode == LightMode.NIGHT)
	_btn_light_cycle.button_pressed = (_light_mode == LightMode.CYCLE)
	match _light_mode:
		LightMode.DAY:
			_orbital_phase = 0.0
			_night_mix = 0.0
		LightMode.DUSK:
			_orbital_phase = 0.27
			_night_mix = 0.48
		LightMode.NIGHT:
			_orbital_phase = 0.46
			_night_mix = 0.80
		LightMode.CYCLE:
			var raw_nm := 0.5 - 0.5 * cos(_orbital_phase * TAU)
			_night_mix = pow(clampf(raw_nm, 0.0, 1.0), 1.35) * 0.84
	_apply_orbital_lighting(_orbital_phase, _night_mix)


func _update_orbital_lighting(delta: float) -> void:
	if _light_mode != LightMode.CYCLE:
		return
	var rate := 0.35 if _sim_speed <= 0.0 else clampf(_sim_speed, 1.0, 2.5)
	_orbital_phase = fposmod(_orbital_phase + (delta * rate) / float(TUNING_KNOBS["ORBITAL_CYCLE_SEC"]), 1.0)
	var raw_nm := 0.5 - 0.5 * cos(_orbital_phase * TAU)
	_night_mix = pow(clampf(raw_nm, 0.0, 1.0), 1.35) * 0.84
	_apply_orbital_lighting(_orbital_phase, _night_mix)


func _apply_orbital_lighting(phase: float, night_mix: float) -> void:
	var nm := clampf(night_mix, 0.0, 1.0)
	var dusk := sin(nm * PI)
	if _world != null and _world.has_method("set_day_phase"):
		_world.set_day_phase(phase, nm)
	if _civ != null and _civ.has_method("set_day_phase"):
		_civ.set_day_phase(phase, nm)
	if _physics != null and _physics.has_method("set_day_phase"):
		_physics.set_day_phase(phase, nm)

	if _canvas_modulate != null:
		var day_c := Color(1.0, 1.0, 1.0, 1.0)
		var dusk_c := Color(1.0, 0.93, 0.86, 1.0)
		var night_c := Color(0.84, 0.88, 0.98, 1.0)
		var mid_c := day_c.lerp(dusk_c, dusk * 0.65)
		_canvas_modulate.color = mid_c.lerp(night_c, nm)

	if _world_env != null and _world_env.environment != null:
		var env: Environment = _world_env.environment
		env.glow_intensity = lerpf(0.85, 0.98, maxf(nm, dusk * 0.5))
		env.glow_bloom = lerpf(0.14, 0.21, maxf(nm, dusk * 0.6))


func _set_sim_speed(speed: float) -> void:
	_sim_speed = speed
	if speed > 0.0:
		_last_nonzero_speed = speed
	_btn_speed_0.button_pressed = is_zero_approx(speed)
	_btn_speed_1.button_pressed = is_equal_approx(speed, 1.0)
	_btn_speed_3.button_pressed = is_equal_approx(speed, 3.0)
	_btn_speed_5.button_pressed = is_equal_approx(speed, 5.0)
	_btn_speed_20.button_pressed = is_equal_approx(speed, 20.0)


func _on_tab_clicked(tab_id: int) -> void:
	_select_power_tab(tab_id, true)
	_fx.play_sfx("ui")


func _tab_for_brush(mode: int) -> int:
	match mode:
		WorldTerrainScript.BrushMode.TERRAFORM_LIFE, BRUSH_CANAL, WorldTerrainScript.BrushMode.CRYSTAL_FLORA, WorldTerrainScript.BrushMode.LAVA_VOLCANO:
			return POWER_TAB_EARTH
		BRUSH_STORM_RAIN, BRUSH_STORM_FIRE, BRUSH_STORM_ION:
			return POWER_TAB_WEATHER
		BRUSH_DIPLO_SPARK, BRUSH_ORBITAL_STRIKE, WorldTerrainScript.BrushMode.METEOR_CRATER, WorldTerrainScript.BrushMode.VORTEX_PULL:
			return POWER_TAB_WAR
		BRUSH_AI_GLITCH, BRUSH_XENO_VIRUS, BRUSH_BIO_SEEDER:
			return POWER_TAB_EVO
	return -1


func _select_power_tab(tab_id: int, select_default_brush: bool = false) -> void:
	_active_power_tab = clampi(tab_id, POWER_TAB_EARTH, POWER_TAB_EVO)
	_group_earth.visible = (_active_power_tab == POWER_TAB_EARTH)
	_group_weather.visible = (_active_power_tab == POWER_TAB_WEATHER)
	_group_war.visible = (_active_power_tab == POWER_TAB_WAR)
	_group_evo.visible = (_active_power_tab == POWER_TAB_EVO)

	_btn_tab_earth.button_pressed = (_active_power_tab == POWER_TAB_EARTH)
	_btn_tab_weather.button_pressed = (_active_power_tab == POWER_TAB_WEATHER)
	_btn_tab_war.button_pressed = (_active_power_tab == POWER_TAB_WAR)
	_btn_tab_evo.button_pressed = (_active_power_tab == POWER_TAB_EVO)

	if select_default_brush and _tab_for_brush(_current_brush) != _active_power_tab:
		var defaults := [
			WorldTerrainScript.BrushMode.TERRAFORM_LIFE,
			BRUSH_STORM_RAIN,
			BRUSH_DIPLO_SPARK,
			BRUSH_AI_GLITCH,
		]
		_select_brush(defaults[_active_power_tab])

	_sync_hud_layouts()
	call_deferred("_sync_hud_layouts")


func _select_active_tab_slot(slot_idx: int) -> void:
	var slots := [
		[WorldTerrainScript.BrushMode.TERRAFORM_LIFE, BRUSH_CANAL, WorldTerrainScript.BrushMode.CRYSTAL_FLORA, WorldTerrainScript.BrushMode.LAVA_VOLCANO],
		[BRUSH_STORM_RAIN, BRUSH_STORM_FIRE, BRUSH_STORM_ION],
		[BRUSH_DIPLO_SPARK, BRUSH_ORBITAL_STRIKE, WorldTerrainScript.BrushMode.METEOR_CRATER, WorldTerrainScript.BrushMode.VORTEX_PULL],
		[BRUSH_AI_GLITCH, BRUSH_XENO_VIRUS, BRUSH_BIO_SEEDER],
	]
	var tab_slots: Array = slots[_active_power_tab]
	if slot_idx >= 0 and slot_idx < tab_slots.size():
		_select_brush(int(tab_slots[slot_idx]))
		_fx.play_sfx("ui")


func _select_brush(mode: int) -> void:
	_current_brush = mode
	var owner_tab := _tab_for_brush(mode)
	if owner_tab >= 0 and owner_tab != _active_power_tab:
		_select_power_tab(owner_tab, false)
	_btn_terraform.button_pressed = (mode == WorldTerrainScript.BrushMode.TERRAFORM_LIFE)
	_btn_canal.button_pressed = (mode == BRUSH_CANAL)
	_btn_crystal.button_pressed = (mode == WorldTerrainScript.BrushMode.CRYSTAL_FLORA)
	_btn_lava.button_pressed = (mode == WorldTerrainScript.BrushMode.LAVA_VOLCANO)
	_btn_rain.button_pressed = (mode == BRUSH_STORM_RAIN)
	_btn_firestorm.button_pressed = (mode == BRUSH_STORM_FIRE)
	_btn_ion_storm.button_pressed = (mode == BRUSH_STORM_ION)
	_btn_diplo.button_pressed = (mode == BRUSH_DIPLO_SPARK)
	_btn_orbital_strike.button_pressed = (mode == BRUSH_ORBITAL_STRIKE)
	_btn_meteor.button_pressed = (mode == WorldTerrainScript.BrushMode.METEOR_CRATER)
	_btn_vortex.button_pressed = (mode == WorldTerrainScript.BrushMode.VORTEX_PULL)
	_btn_ai_glitch.button_pressed = (mode == BRUSH_AI_GLITCH)
	_btn_xeno_virus.button_pressed = (mode == BRUSH_XENO_VIRUS)
	_btn_bio_seeder.button_pressed = (mode == BRUSH_BIO_SEEDER)
	_btn_colony.button_pressed = (mode == BRUSH_COLONY)
	_btn_bless.button_pressed = (mode == BRUSH_BLESS)
	_btn_inspect.button_pressed = (mode == BRUSH_INSPECT)
	_reticle.queue_redraw()


func _select_faction(faction_id: int) -> void:
	_selected_faction = posmod(faction_id, FACTION_RETICLE_COLORS.size())
	_btn_fac_human.button_pressed = (_selected_faction == 0)
	_btn_fac_robot.button_pressed = (_selected_faction == 1)
	_btn_fac_spore.button_pressed = (_selected_faction == 2)
	_reticle.queue_redraw()


func _select_brush_size(radius: int) -> void:
	_brush_radius = radius
	_btn_size_4.button_pressed = (radius == int(TUNING_KNOBS["BRUSH_SIZE_XS"]))
	_btn_size_8.button_pressed = (radius == int(TUNING_KNOBS["BRUSH_SIZE_S"]))
	_btn_size_16.button_pressed = (radius == int(TUNING_KNOBS["BRUSH_SIZE_M"]))
	_btn_size_28.button_pressed = (radius == int(TUNING_KNOBS["BRUSH_SIZE_L"]))
	_btn_size_48.button_pressed = (radius == int(TUNING_KNOBS["BRUSH_SIZE_XL"]))
	_reticle.queue_redraw()


func _clear_inspector_lock() -> void:
	_exit_possession()
	_locked_unit_uid = -1
	_locked_city_id = -1
	_locked_city_pos = Vector2.ZERO
	_last_inspect_unit_uid = -1
	_follow_locked_unit = false


func _extract_cli_value(arg: String, prefix: String) -> String:
	return arg.substr(prefix.length()).strip_edges().trim_prefix("\"").trim_suffix("\"")


func _parse_cli_args() -> void:
	var all_args: Array[String] = []
	for raw_arg in OS.get_cmdline_args():
		all_args.append(str(raw_arg))
	for raw_arg in OS.get_cmdline_user_args():
		all_args.append(str(raw_arg))

	for arg in all_args:
		if arg == "--smoke-test" or arg == "--smoke":
			_smoke_mode = true
		elif arg == "--smoke-civ":
			_smoke_civ_mode = true
		elif arg == "--smoke-combat":
			_smoke_combat_mode = true
		elif arg == "--smoke-worldbox-pace":
			_smoke_worldbox_pace_mode = true
		elif arg.begins_with("--screenshot="):
			_screenshot_path = _extract_cli_value(arg, "--screenshot=")
		elif arg.begins_with("--shot-macro="):
			_screenshot_path = _extract_cli_value(arg, "--shot-macro=")
		elif arg == "--shot-macro":
			_screenshot_path = "screenshots/world_macro.png"
		elif arg.begins_with("--zoom-shot="):
			_zoom_shot_path = _extract_cli_value(arg, "--zoom-shot=")
		elif arg.begins_with("--shot-zoom="):
			_zoom_shot_path = _extract_cli_value(arg, "--shot-zoom=")
		elif arg == "--shot-zoom":
			_zoom_shot_path = "screenshots/world_zoom.png"
		elif arg.begins_with("--shot-civ="):
			_shot_civ_path = _extract_cli_value(arg, "--shot-civ=")
		elif arg == "--shot-civ":
			_shot_civ_path = "screenshots/stage2_civ.png"
		elif arg.begins_with("--shot-night="):
			_shot_night_path = _extract_cli_value(arg, "--shot-night=")
		elif arg == "--shot-night":
			_shot_night_path = "screenshots/stage2_night.png"
		elif arg.begins_with("--shot-combat="):
			_shot_combat_path = _extract_cli_value(arg, "--shot-combat=")
		elif arg == "--shot-combat":
			_shot_combat_path = "screenshots/stage3_war.png"


func _is_capture_mode() -> bool:
	return (
		_screenshot_path != ""
		or _zoom_shot_path != ""
		or _shot_civ_path != ""
		or _shot_night_path != ""
		or _shot_combat_path != ""
	)


func pack_world_state() -> Dictionary:
	return {
		"magic": SAVE_MAGIC,
		"version": SAVE_VERSION,
		"seed": _seed_counter,
		"cosmic_age": _world.get_cosmic_age() if _world.has_method("get_cosmic_age") else 0,
		"light_mode": _light_mode,
		"orbital_phase": _orbital_phase,
		"sim_speed": _sim_speed,
		"selected_faction": _selected_faction,
		"active_power_tab": _active_power_tab,
		"current_brush": _current_brush,
		"brush_radius": _brush_radius,
		"camera_pos": _cam_base_pos,
		"target_zoom": _target_zoom,
		"world_laws": _world_laws_ui.get_laws() if _world_laws_ui != null else {},
		"civ_blob": _civ.pack_state() if _civ != null and _civ.has_method("pack_state") else PackedByteArray(),
		"combat_blob": _combat.pack_state() if _combat != null and _combat.has_method("pack_state") else PackedByteArray(),
	}


func unpack_world_state(snapshot: Dictionary) -> bool:
	if int(snapshot.get("magic", 0)) != SAVE_MAGIC:
		return false
	if int(snapshot.get("version", 0)) != SAVE_VERSION:
		return false
	var civ_blob: PackedByteArray = snapshot.get("civ_blob", PackedByteArray())
	var combat_blob: PackedByteArray = snapshot.get("combat_blob", PackedByteArray())
	if civ_blob.is_empty() or combat_blob.is_empty():
		return false

	var saved_seed: int = int(snapshot.get("seed", _seed_counter))
	if saved_seed != _seed_counter:
		_seed_counter = saved_seed
		_world.generate_planet(_seed_counter)
		_physics.rebuild_population(int(TUNING_KNOBS["POPULATION_COUNT"]))

	if _world.has_method("set_cosmic_age"):
		_world.set_cosmic_age(int(snapshot.get("cosmic_age", 0)), false)
	_sync_cosmic_age_state()

	if _civ != null and _civ.has_method("unpack_state"):
		if not _civ.unpack_state(civ_blob):
			return false
	if _combat != null and _combat.has_method("unpack_state"):
		if not _combat.unpack_state(combat_blob):
			return false

	_select_faction(int(snapshot.get("selected_faction", 0)))
	_select_power_tab(int(snapshot.get("active_power_tab", POWER_TAB_EARTH)), false)
	_select_brush(int(snapshot.get("current_brush", WorldTerrainScript.BrushMode.TERRAFORM_LIFE)))
	_select_brush_size(int(snapshot.get("brush_radius", int(TUNING_KNOBS["BRUSH_SIZE_M"]))))
	_set_light_mode(int(snapshot.get("light_mode", LightMode.DAY)))
	_orbital_phase = float(snapshot.get("orbital_phase", _orbital_phase))
	_set_sim_speed(float(snapshot.get("sim_speed", 1.0)))
	if snapshot.has("world_laws") and (snapshot["world_laws"] is Dictionary) and _world_laws_ui != null:
		_world_laws_ui.set_laws(snapshot["world_laws"] as Dictionary)
		_broadcast_world_laws(_world_laws_ui.get_laws())
	var saved_cam: Variant = snapshot.get("camera_pos", _cam_base_pos)
	if saved_cam is Vector2:
		_cam_base_pos = saved_cam
	_target_zoom = clampf(
		float(snapshot.get("target_zoom", _target_zoom)),
		float(TUNING_KNOBS["ZOOM_MIN"]),
		float(TUNING_KNOBS["ZOOM_MAX"])
	)
	_update_hud_telemetry()
	_sync_hud_layouts()
	_world_overlay.queue_redraw()
	_macro_badges.queue_redraw()
	return true


func save_world_to_file(path: String = DEFAULT_SAVE_PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	var payload: PackedByteArray = var_to_bytes(pack_world_state())
	f.store_32(SAVE_MAGIC)
	f.store_32(SAVE_VERSION)
	f.store_32(payload.size())
	f.store_buffer(payload)
	f.close()
	return true


func load_world_from_file(path: String = DEFAULT_SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var magic := int(f.get_32())
	var version := int(f.get_32())
	var byte_len := int(f.get_32())
	if magic != SAVE_MAGIC or version != SAVE_VERSION or byte_len <= 0 or byte_len > 16777216:
		f.close()
		return false
	var payload := f.get_buffer(byte_len)
	f.close()
	var decoded: Variant = bytes_to_var(payload)
	if not (decoded is Dictionary):
		return false
	return unpack_world_state(decoded as Dictionary)


func _find_element_point(want_water: bool) -> Vector2:
	for py in range(24, int(_world.map_h) - 24, 12):
		for px in range(24, int(_world.map_w) - 24, 12):
			if _world.is_water(px, py) == want_water:
				if want_water or _is_dry_patch(px, py, 8):
					return Vector2(float(px) + 0.5, float(py) + 0.5)
	return Vector2(32.0, 32.0)


func _run_headless_smoke() -> void:
	_apply_sim_pace(1.0)
	var expected_units: int = 110
	_physics.rebuild_population(expected_units)
	var count: int = _physics.get_unit_count()
	if count != expected_units:
		push_error("Smoke test failed: expected %d colonists, got %d" % [expected_units, count])
		get_tree().quit(1)
		return

	var first_before: Vector2 = _physics.get_first_unit_pos()
	for _i in range(60):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)
		_fx.step_fx(0.05)
	var first_after: Vector2 = _physics.get_first_unit_pos()

	if first_before.is_equal_approx(first_after):
		push_error("Smoke test failed: colonist did not move after 60 deterministic ticks")
		get_tree().quit(1)
		return

	var speed_before: float = _physics.get_max_unit_speed()
	var impact_pos: Vector2 = first_after
	_world.apply_brush(impact_pos, WorldTerrainScript.BrushMode.METEOR_CRATER, 18)
	_physics.trigger_impulse(impact_pos, 48.0, 140.0, true)
	var max_speed: float = _physics.get_max_unit_speed()
	if max_speed <= maxf(speed_before, 80.0):
		push_error("Smoke test failed: blast impulse did not spike max unit speed (before=%.2f after=%.2f)" % [speed_before, max_speed])
		get_tree().quit(1)
		return

	# Vortex Alchemy + elemental storm checks
	for _i in range(6):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)
		_fx.step_fx(0.05)

	var dry_spot: Vector2 = _find_element_point(false)
	_world.apply_brush(dry_spot, WorldTerrainScript.BrushMode.TERRAFORM_LIFE, 12)
	_world.apply_brush(dry_spot, WorldTerrainScript.BrushMode.LAVA_VOLCANO, 7)
	var elem_lava: String = _world.sample_dominant_element(dry_spot, 16.0)
	_physics.apply_vortex(dry_spot, 28.0, 125.0, 0.05)
	for _i in range(6):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)
		_fx.step_fx(0.05)

	var water_spot: Vector2 = _find_element_point(true)
	_physics.apply_vortex(water_spot, 28.0, 125.0, 0.05)
	_world.apply_elemental_storm(dry_spot, 26.0, "rainburst")
	for _i in range(4):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)
		_fx.step_fx(0.05)

	var fire_stats: Dictionary = _world.get_fire_stats()
	var fire_events: int = int(fire_stats.get("fire_events", 0))
	var flora: int = _physics.get_flora_count()
	if flora < 400 or (elem_lava != "lava" and elem_lava != "fire" and fire_events <= 0):
		push_error("Smoke test failed: flora=%d elem=%s fire_events=%d" % [flora, elem_lava, fire_events])
		get_tree().quit(1)
		return

	max_speed = maxf(max_speed, _physics.get_max_unit_speed())
	print("SMOKE_PASS units=%d flora=%d max_speed=%.2f fire_events=%d" % [count, flora, max_speed, fire_events])
	get_tree().quit(0)


func _run_headless_smoke_civ() -> void:
	_world.generate_planet(int(TUNING_KNOBS["CIV_SMOKE_SEED"]))
	_physics.rebuild_population(0)
	_apply_sim_pace(70.0)
	var anchors: Array[Vector2] = _find_multi_colony_anchors()
	var anchor1: Vector2 = anchors[0]
	var anchor2: Vector2 = anchors[1]
	var cid1: int = _civ.spawn_colony(anchor1, 0)
	var cid2: int = _civ.spawn_colony(anchor2, 1)
	if cid1 < 0 or cid2 < 0:
		var spawn_err := "SMOKE_CIV_FAIL reason=spawn_colony_failed c1=%d c2=%d a1=(%.1f,%.1f) a2=(%.1f,%.1f)" % [
			cid1, cid2, anchor1.x, anchor1.y, anchor2.x, anchor2.y
		]
		push_error(spawn_err)
		print(spawn_err)
		get_tree().quit(1)
		return

	var bench := _run_smoke_civ_benchmark(150)
	var possession_ok := _run_smoke_civ_post_bench(anchor1, anchor2)
	_finish_smoke_civ_report(bench, possession_ok)


func _run_smoke_civ_benchmark(ticks: int) -> Dictionary:
	var world_usec: int = 0
	var phys_usec: int = 0
	var civ_usec: int = 0
	var combat_usec: int = 0
	var fx_usec: int = 0
	for _i in range(ticks):
		var t0 := Time.get_ticks_usec()
		_world.step_environment(0.05)
		var t1 := Time.get_ticks_usec()
		_physics.step_physics(0.05)
		var t2 := Time.get_ticks_usec()
		_civ.step_civ(0.05)
		var t3 := Time.get_ticks_usec()
		if _combat != null and _combat.has_method("step_combat"):
			_combat.step_combat(0.05)
		var t4 := Time.get_ticks_usec()
		_fx.step_fx(0.05)
		var t5 := Time.get_ticks_usec()
		world_usec += (t1 - t0)
		phys_usec += (t2 - t1)
		civ_usec += (t3 - t2)
		combat_usec += (t4 - t3)
		fx_usec += (t5 - t4)
	return {
		"ticks": ticks,
		"world_ms": float(world_usec) / 1000.0,
		"phys_ms": float(phys_usec) / 1000.0,
		"civ_ms": float(civ_usec) / 1000.0,
		"combat_ms": float(combat_usec) / 1000.0,
		"fx_ms": float(fx_usec) / 1000.0,
	}


func _run_smoke_civ_post_bench(anchor1: Vector2, anchor2: Vector2) -> int:
	var test_spot: Vector2 = _find_safe_far_land(anchor1, anchor2, 54.0)
	_world.apply_brush(test_spot, WorldTerrainScript.BrushMode.TERRAFORM_LIFE, 10)
	_world.apply_brush(test_spot, WorldTerrainScript.BrushMode.LAVA_VOLCANO, 6)
	for _i in range(6):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)
	_physics.apply_vortex(test_spot, 28.0, 125.0, 0.05)
	for _i in range(6):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)
	var water_spot: Vector2 = _find_element_point(true)
	_physics.apply_vortex(water_spot, 28.0, 125.0, 0.05)
	_world.apply_elemental_storm(test_spot, 24.0, "rainburst")
	for _i in range(4):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)

	_physics.bless_or_mutate_area(anchor1, 28.0, false)

	if _world.has_method("set_cosmic_age"):
		_world.set_cosmic_age(4, true)
	_sync_cosmic_age_state()
	for k in range(380):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)
		_civ.step_civ(0.05)
		if _combat != null and _combat.has_method("step_combat"):
			_combat.step_combat(0.05)
		_fx.step_fx(0.05)
		if _world.has_method("step_cosmic_age"):
			_world.step_cosmic_age(0.05)
		if k >= 80:
			var st: Dictionary = _civ.get_civ_stats()
			var sh_tot: int = int(st.get("shuttles_total", int(st.get("shuttles", 0)) + int(st.get("shuttles_launched", 0))))
			var cp: Dictionary = _find_charged_shield_pylon(0.25)
			if int(st.get("cities", 0)) >= 2 and int(st.get("tech_tier", 0)) >= 3 and sh_tot >= 1 and bool(cp.get("found", false)):
				break

	var charged_pylon: Dictionary = _find_charged_shield_pylon(0.25)
	if bool(charged_pylon.get("found", false)):
		var shield_probe_pos: Vector2 = charged_pylon.get("pos", anchor1)
		_execute_orbital_or_meteor(shield_probe_pos, 14, true)
	elif _civ.has_method("get_shield_pylons"):
		var pylons: Array = _civ.get_shield_pylons()
		if not pylons.is_empty():
			var fallback_pos: Vector2 = pylons[0].get("pos", anchor1)
			_execute_orbital_or_meteor(fallback_pos, 14, true)
	_execute_orbital_or_meteor(test_spot, 12, true)
	for _k in range(6):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)
		_civ.step_civ(0.05)
		if _combat != null and _combat.has_method("step_combat"):
			_combat.step_combat(0.05)
		_fx.step_fx(0.05)

	var possession_ok := 0
	if _physics.has_method("set_possessed_unit"):
		var possess_probe: Vector2 = _physics.get_first_unit_pos()
		var u_probe: Dictionary = _physics.inspect_unit_at(possess_probe)
		if bool(u_probe.get("found", false)):
			var p_uid := int(u_probe.get("uid", -1))
			var p_res: Dictionary = _physics.set_possessed_unit(p_uid, Vector2(1.0, 0.0), true)
			for _k in range(4):
				_physics.step_physics(0.05)
				_fx.step_fx(0.05)
			if bool(p_res.get("active", false)):
				possession_ok = 1
			_physics.set_possessed_unit(-1, Vector2.ZERO, false)

	if _physics.get_mutant_count() == 0:
		_physics.bless_or_mutate_area(anchor1, 36.0, false)
	if _physics.get_mutant_count() == 0:
		_physics.bless_or_mutate_area(_physics.get_first_unit_pos(), 48.0, false)
	if _physics.get_mutant_count() == 0 and _physics.has_method("spawn_free_settlers"):
		_physics.spawn_free_settlers(test_spot, 0, 2)
		_physics.bless_or_mutate_area(test_spot, 52.0, false)

	_night_mix = 0.80
	_update_lightmap_frame()
	_night_mix = 0.0
	return possession_ok


func _finish_smoke_civ_report(bench: Dictionary, possession_ok: int) -> void:
	var ticks: float = float(bench["ticks"])
	var world_ms: float = float(bench["world_ms"])
	var phys_ms: float = float(bench["phys_ms"])
	var civ_ms: float = float(bench["civ_ms"])
	var combat_ms: float = float(bench["combat_ms"])
	var fx_ms: float = float(bench["fx_ms"])
	var world_tick_ms: float = world_ms / ticks
	var phys_tick_ms: float = phys_ms / ticks
	var civ_tick_ms: float = civ_ms / ticks
	var phys_civ_ms: float = phys_ms + civ_ms
	var phys_civ_tick_ms: float = phys_civ_ms / ticks
	var fx_tick_ms: float = fx_ms / ticks
	var sim_ms: float = world_ms + phys_civ_ms + combat_ms + fx_ms
	var sim_tick_ms: float = sim_ms / ticks

	var stats: Dictionary = _civ.get_civ_stats()
	var unit_stats: Dictionary = _physics.get_unit_stats() if _physics.has_method("get_unit_stats") else {}
	var fire_stats: Dictionary = _world.get_fire_stats()
	var cities: int = int(stats.get("cities", 0))
	var zones_owned: int = int(stats.get("zones_owned", 0))
	var buildings: int = int(stats.get("buildings", 0))
	var tech_tier: int = maxi(int(stats.get("max_tech_tier", 0)), int(stats.get("tech_tier", 0)))
	var storage_total: float = float(stats.get("storage_total", 0.0))
	var shuttles: int = int(stats.get("shuttles", 0)) + int(stats.get("shuttles_launched", 0))
	var shuttles_total: int = int(stats.get("shuttles_total", shuttles))
	var shield_pylons: int = int(stats.get("shield_pylons", 0))
	var shield_blocked: int = int(stats.get("shield_blocked", 0))
	var clashes: int = int(stats.get("clashes", 0))
	var dodges: int = int(unit_stats.get("dodges", 0))
	var fire_events: int = int(fire_stats.get("fire_events", 0))
	var mutants: int = int(_physics.get_mutant_count())
	var cosmic_age_name: String = COSMIC_AGE_KEYS[clampi(_cosmic_age_id, 0, COSMIC_AGE_KEYS.size() - 1)]

	var ok: bool = (
		cities >= 2 and zones_owned >= 8 and buildings >= 6 and tech_tier >= 2
		and storage_total > 0.0 and fire_events >= 1 and mutants >= 1
		and shuttles_total >= 1 and shield_pylons >= 1 and shield_blocked >= 1
		and dodges >= 1 and possession_ok == 1
	)
	var metrics_tail := (
		"cities=%d zones_owned=%d buildings=%d tech_tier=%d storage_total=%.2f "
		+ "world_ms=%.3f world_tick_ms=%.3f phys_ms=%.3f phys_tick_ms=%.3f "
		+ "civ_ms=%.3f civ_tick_ms=%.3f phys_civ_ms=%.3f phys_civ_tick_ms=%.3f "
		+ "fx_ms=%.3f fx_tick_ms=%.3f sim_ms=%.3f sim_tick_ms=%.3f "
		+ "fire_events=%d mutants=%d shuttles=%d shuttles_total=%d clashes=%d "
		+ "cosmic_age=%s shield_pylons=%d shield_blocked=%d dodges=%d possession_ok=%d"
	) % [
		cities, zones_owned, buildings, tech_tier, storage_total,
		world_ms, world_tick_ms, phys_ms, phys_tick_ms,
		civ_ms, civ_tick_ms, phys_civ_ms, phys_civ_tick_ms,
		fx_ms, fx_tick_ms, sim_ms, sim_tick_ms,
		fire_events, mutants, shuttles, shuttles_total, clashes,
		cosmic_age_name, shield_pylons, shield_blocked, dodges, possession_ok
	]
	if not ok:
		var fail_msg := "SMOKE_CIV_FAIL " + metrics_tail
		push_error(fail_msg)
		print(fail_msg)
		get_tree().quit(1)
		return
	print("SMOKE_CIV_PASS " + metrics_tail)
	get_tree().quit(0)


func _count_water_samples_between(a: Vector2, b: Vector2) -> int:
	var water_hits := 0
	for step_idx in range(1, 24):
		var p := a.lerp(b, float(step_idx) / 24.0)
		var px := clampi(int(p.x), 0, int(_world.map_w) - 1)
		var py := clampi(int(p.y), 0, int(_world.map_h) - 1)
		if _world.is_water(px, py):
			water_hits += 1
	return water_hits


func _find_war_continent_anchors() -> Array[Vector2]:
	var candidates: Array[Dictionary] = []
	for py in range(52, int(_world.map_h) - 52, 14):
		for px in range(52, int(_world.map_w) - 52, 14):
			if not _is_colony_patch(px, py, 10):
				continue
			var sc := _score_colony_patch(px, py)
			if sc <= -99999.0:
				sc = 0.0
			candidates.append({
				"pos": Vector2(float(px) + 0.5, float(py) + 0.5),
				"score": sc,
			})

	var best_a := Vector2.ZERO
	var best_b := Vector2.ZERO
	var best_sea_score := -1000000.0
	var fallback_a := Vector2.ZERO
	var fallback_b := Vector2.ZERO
	var fallback_score := -1000000.0

	for i in range(candidates.size()):
		var ca: Dictionary = candidates[i]
		var pa: Vector2 = ca["pos"]
		var sa: float = float(ca["score"])
		for j in range(i + 1, candidates.size()):
			var cb: Dictionary = candidates[j]
			var pb: Vector2 = cb["pos"]
			var sb: float = float(cb["score"])
			var dist := pa.distance_to(pb)
			if dist < 102.0 or dist > 188.0:
				continue
			var wh := _count_water_samples_between(pa, pb)
			var base_sc := sa + sb - absf(dist - 140.0) * 0.55 - absf(pa.y - pb.y) * 0.35
			if wh >= 6:
				var sea_sc := base_sc + float(mini(wh, 14)) * 22.0
				if sea_sc > best_sea_score:
					best_sea_score = sea_sc
					if pa.x <= pb.x:
						best_a = pa
						best_b = pb
					else:
						best_a = pb
						best_b = pa
			var fb_sc := base_sc + float(wh) * 18.0
			if fb_sc > fallback_score:
				fallback_score = fb_sc
				if pa.x <= pb.x:
					fallback_a = pa
					fallback_b = pb
				else:
					fallback_a = pb
					fallback_b = pa

	if best_sea_score > -999999.0:
		return [best_a, best_b]

	if fallback_score > -999999.0:
		var mid := (fallback_a + fallback_b) * 0.5
		var dir := (fallback_b - fallback_a).normalized()
		var perp := Vector2(-dir.y, dir.x)
		for offset in [-14.0, 0.0, 14.0]:
			_world.apply_brush(_clamp_to_world(mid + perp * offset, 18.0), BRUSH_CANAL, 12)
		return [fallback_a, fallback_b]

	var a1 := _find_colony_land_anchor()
	var a2 := _find_second_colony_anchor(a1)
	return [a1, a2]


func _find_war_neighbor_anchor(
	near_pos: Vector2,
	avoid: Array[Vector2],
	min_dist: float,
	max_dist: float,
	same_landmass: bool = true
) -> Vector2:
	var best_pos := Vector2(-1.0, -1.0)
	var best_score := -1000000.0
	var mid_dist := (min_dist + max_dist) * 0.5

	for py in range(34, int(_world.map_h) - 34, 8):
		for px in range(34, int(_world.map_w) - 34, 8):
			if not _is_colony_patch(px, py, 8):
				continue
			var p := Vector2(float(px) + 0.5, float(py) + 0.5)
			var d := p.distance_to(near_pos)
			if d < min_dist or d > max_dist:
				continue
			var too_close := false
			for ap in avoid:
				if p.distance_to(ap) < 42.0:
					too_close = true
					break
			if too_close:
				continue
			var sc := _score_colony_patch(px, py)
			if sc <= -99999.0:
				sc = 0.0
			var wh := _count_water_samples_between(near_pos, p)
			var land_bonus := 0.0
			if same_landmass:
				land_bonus = 90.0 if wh <= 1 else -180.0
			else:
				land_bonus = 45.0 if wh >= 3 else 0.0
			var total := sc + land_bonus - absf(d - mid_dist) * 0.55
			if total > best_score:
				best_score = total
				best_pos = p

	if best_pos.x >= 0.0:
		return best_pos

	for py in range(24, int(_world.map_h) - 24, 6):
		for px in range(24, int(_world.map_w) - 24, 6):
			if not _is_dry_patch(px, py, 6):
				continue
			var p := Vector2(float(px) + 0.5, float(py) + 0.5)
			var too_close := false
			for ap in avoid:
				if p.distance_to(ap) < 38.0:
					too_close = true
					break
			if not too_close:
				return p
	return _clamp_to_world(near_pos + Vector2(56.0, 12.0), 28.0)


func _setup_stage3b_war_scenario(seed_val: int) -> Dictionary:
	_seed_counter = seed_val
	_world.generate_planet(seed_val)
	var anchors := _find_war_continent_anchors()
	var west: Vector2 = anchors[0]
	var east_ally: Vector2 = anchors[1]
	var east_robot: Vector2 = _find_war_neighbor_anchor(east_ally, [west, east_ally], 42.0, 64.0, true)
	var rebel_pos: Vector2 = _find_war_neighbor_anchor(east_ally, [west, east_ally, east_robot], 44.0, 76.0, true)
	var spore_pos: Vector2 = _find_war_neighbor_anchor(west, [west, east_ally, east_robot, rebel_pos], 48.0, 145.0, false)

	_world.apply_brush(west, WorldTerrainScript.BrushMode.TERRAFORM_LIFE, 8)
	_world.apply_brush(east_ally, WorldTerrainScript.BrushMode.TERRAFORM_LIFE, 8)
	for _i in range(10):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)
		_fx.step_fx(0.05)

	var cid_west: int = _civ.spawn_colony(west, 0)
	var cid_east_ally: int = _civ.spawn_colony(east_ally, 0)
	var cid_robot: int = _civ.spawn_colony(east_robot, 1)
	var cid_rebel_host: int = _civ.spawn_colony(rebel_pos, 0)
	var cid_spore: int = _civ.spawn_colony(spore_pos, 2)

	if _civ.has_method("grant_tech_tier_for_test"):
		if cid_west >= 0:
			_civ.grant_tech_tier_for_test(cid_west, 4)
		if cid_east_ally >= 0:
			_civ.grant_tech_tier_for_test(cid_east_ally, 4)
		if cid_robot >= 0:
			_civ.grant_tech_tier_for_test(cid_robot, 3)
		if cid_rebel_host >= 0:
			_civ.grant_tech_tier_for_test(cid_rebel_host, 1)
		if cid_spore >= 0:
			_civ.grant_tech_tier_for_test(cid_spore, 2)

	var gate_west := west
	var gate_east := east_ally
	if _civ.has_method("spawn_building_for_test"):
		if cid_west >= 0:
			var gw: Vector2 = _civ.spawn_building_for_test(cid_west, 9)
			if gw.x >= 0.0:
				gate_west = gw
		if cid_east_ally >= 0:
			var ge: Vector2 = _civ.spawn_building_for_test(cid_east_ally, 9)
			if ge.x >= 0.0:
				gate_east = ge
			_civ.spawn_building_for_test(cid_east_ally, 8)

	if _civ.has_method("set_diplomacy"):
		if cid_west >= 0 and cid_east_ally >= 0:
			_civ.set_diplomacy(cid_west, cid_east_ally, 1)
		if cid_west >= 0 and cid_robot >= 0:
			_civ.set_diplomacy(cid_west, cid_robot, 2)
		if cid_east_ally >= 0 and cid_robot >= 0:
			_civ.set_diplomacy(cid_east_ally, cid_robot, 2)
		if cid_east_ally >= 0 and cid_spore >= 0:
			_civ.set_diplomacy(cid_east_ally, cid_spore, 2)
		if cid_west >= 0 and cid_spore >= 0:
			_civ.set_diplomacy(cid_west, cid_spore, 2)

	if _civ.has_method("trigger_diplomacy_spark") and cid_rebel_host >= 0:
		_civ.trigger_diplomacy_spark(rebel_pos, 3)

	return {
		"west": west,
		"east_ally": east_ally,
		"east_robot": east_robot,
		"rebel_pos": rebel_pos,
		"spore_pos": spore_pos,
		"gate_west": gate_west,
		"gate_east": gate_east,
		"cid_west": cid_west,
		"cid_east_ally": cid_east_ally,
		"cid_robot": cid_robot,
		"cid_rebel_host": cid_rebel_host,
		"cid_spore": cid_spore,
	}


func _run_headless_smoke_combat() -> void:
	_physics.rebuild_population(0)
	_apply_sim_pace(18.0)
	var ctx := _setup_stage3b_war_scenario(int(TUNING_KNOBS["CIV_SMOKE_SEED"]))
	var west: Vector2 = ctx["west"]
	var east_robot: Vector2 = ctx["east_robot"]
	var rebel_pos: Vector2 = ctx["rebel_pos"]
	var spore_pos: Vector2 = ctx["spore_pos"]
	var gate_west: Vector2 = ctx["gate_west"]
	var gate_east: Vector2 = ctx["gate_east"]
	var cid_west: int = int(ctx["cid_west"])

	var ticks: int = 180
	var world_usec: int = 0
	var phys_civ_usec: int = 0
	var sim_usec: int = 0
	var peak_max_speed: float = _physics.get_max_unit_speed()

	for tick_idx in range(ticks):
		if tick_idx == 40:
			if _civ.has_method("apply_ai_glitch"):
				_civ.apply_ai_glitch(rebel_pos, 22.0)
			if _physics.has_method("apply_ai_glitch_units"):
				_physics.apply_ai_glitch_units(rebel_pos, 22.0)
		elif tick_idx == 55:
			if _combat != null and _combat.has_method("fire_orbital_strike"):
				_combat.fire_orbital_strike(east_robot, 10.0)
			peak_max_speed = maxf(peak_max_speed, _physics.get_max_unit_speed())
		elif tick_idx == 80:
			if _physics.has_method("apply_xeno_virus"):
				_physics.apply_xeno_virus(spore_pos, 22.0)
		elif tick_idx == 95:
			if _physics.has_method("plant_bio_seeder"):
				_physics.plant_bio_seeder(west, 22.0)

		var t0 := Time.get_ticks_usec()
		_world.step_environment(0.05)
		var t1 := Time.get_ticks_usec()
		_physics.step_physics(0.05)
		_civ.step_civ(0.05)
		var t2 := Time.get_ticks_usec()
		if _combat != null and _combat.has_method("step_combat"):
			_combat.step_combat(0.05)
		_fx.step_fx(0.05)
		var t3 := Time.get_ticks_usec()

		world_usec += (t1 - t0)
		phys_civ_usec += (t2 - t1)
		sim_usec += (t3 - t0)
		peak_max_speed = maxf(peak_max_speed, _physics.get_max_unit_speed())

	var cid_east_ally: int = int(ctx["cid_east_ally"])
	if _combat != null and _combat.has_method("get_combat_stats"):
		var pre_combat: Dictionary = _combat.get_combat_stats()
		if int(pre_combat.get("portal_transfers", 0)) < 4 and _combat.has_method("transfer_squad_portal"):
			var moved_smoke: int = 0
			if cid_west >= 0:
				moved_smoke = int(_combat.transfer_squad_portal(gate_west, gate_east, cid_west))
			if moved_smoke <= 0 and cid_east_ally >= 0:
				_combat.transfer_squad_portal(gate_east, gate_west, cid_east_ally)
			for _k in range(12):
				_world.step_environment(0.05)
				_physics.step_physics(0.05)
				_civ.step_civ(0.05)
				_combat.step_combat(0.05)
				_fx.step_fx(0.05)

	var snap := pack_world_state()
	var save_ok := unpack_world_state(snap)

	var combat_stats: Dictionary = _combat.get_combat_stats() if (_combat != null and _combat.has_method("get_combat_stats")) else {}
	var civ_stats: Dictionary = _civ.get_civ_stats()
	var unit_stats: Dictionary = _physics.get_unit_stats() if _physics.has_method("get_unit_stats") else {}

	var beams_fired: int = int(combat_stats.get("beams_fired", 0))
	var portal_transfers: int = int(combat_stats.get("portal_transfers", 0))
	var casualties: int = int(unit_stats.get("deaths", 0))
	var tech_tier: int = maxi(int(civ_stats.get("max_tech_tier", 0)), int(civ_stats.get("tech_tier", 0)))
	var wars_active: int = int(civ_stats.get("wars_active", 0))
	var rebellions_total: int = int(civ_stats.get("rebellions_total", 0))
	var water_stranded: int = _physics.count_water_stranded_units() if _physics.has_method("count_water_stranded_units") else 0
	var max_speed: float = peak_max_speed
	var world_tick_ms: float = (float(world_usec) / 1000.0) / float(ticks)
	var phys_civ_tick_ms: float = (float(phys_civ_usec) / 1000.0) / float(ticks)
	var sim_tick_ms: float = (float(sim_usec) / 1000.0) / float(ticks)

	var ok: bool = (
		beams_fired >= 5
		and portal_transfers >= 4
		and casualties >= 1
		and tech_tier >= 4
		and wars_active >= 1
		and rebellions_total >= 1
		and water_stranded == 0
		and max_speed > 40.0
		and save_ok
	)
	var metrics_tail := (
		"beams_fired=%d portal_transfers=%d casualties=%d tech_tier=%d "
		+ "wars_active=%d rebellions_total=%d water_stranded=%d max_speed=%.2f "
		+ "world_tick_ms=%.3f phys_civ_tick_ms=%.3f sim_tick_ms=%.3f save_ok=%d"
	) % [
		beams_fired, portal_transfers, casualties, tech_tier,
		wars_active, rebellions_total, water_stranded, max_speed,
		world_tick_ms, phys_civ_tick_ms, sim_tick_ms, 1 if save_ok else 0
	]
	if not ok:
		var fail_msg := "SMOKE_COMBAT_FAIL " + metrics_tail
		push_error(fail_msg)
		print(fail_msg)
		get_tree().quit(1)
		return

	print("SMOKE_COMBAT_PASS " + metrics_tail)
	get_tree().quit(0)


func _wb_collect_building_positions(target_btype: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if _civ == null or not _civ.has_method("get_building_footprints"):
		return out
	var fp: Dictionary = _civ.get_building_footprints()
	var cnt: int = int(fp.get("count", 0))
	var pos_v: Variant = fp.get("pos", PackedVector2Array())
	var type_v: Variant = fp.get("type", PackedByteArray())
	if not (pos_v is PackedVector2Array) or not (type_v is PackedByteArray):
		return out
	var pos_arr: PackedVector2Array = pos_v
	var type_arr: PackedByteArray = type_v
	var limit: int = mini(cnt, mini(pos_arr.size(), type_arr.size()))
	for i in range(limit):
		if int(type_arr[i]) == target_btype:
			out.append(pos_arr[i])
	return out


func _wb_count_upgraded_biodomes(tent_positions: Array[Vector2]) -> int:
	var domes := _wb_collect_building_positions(5)
	var matched := 0
	for tp in tent_positions:
		for dp in domes:
			if tp.distance_to(dp) <= 3.5:
				matched += 1
				break
	return matched


func _wb_sample_ecology(center: Vector2) -> Dictionary:
	var cx: int = clampi(int(round(center.x)), 20, int(_world.map_w) - 21)
	var cy: int = clampi(int(round(center.y)), 20, int(_world.map_h) - 21)
	var temp_sum := 0.0
	var moist_sum := 0.0
	var lush_cnt := 0
	for dy in range(-18, 19, 3):
		for dx in range(-18, 19, 3):
			var px := cx + dx
			var py := cy + dy
			temp_sum += float(_world.get_temp(px, py))
			moist_sum += float(_world.get_moisture(px, py))
			if int(_world.get_biome(px, py)) == WorldTerrainScript.Biome.LUSH:
				lush_cnt += 1
	return {"temp_sum": temp_sum, "moist_sum": moist_sum, "lush_cnt": lush_cnt}


func _wb_calc_eco_delta(before: Dictionary, after: Dictionary, civ_stats: Dictionary) -> float:
	var dt := absf(float(after.get("temp_sum", 0.0)) - float(before.get("temp_sum", 0.0)))
	var dm := absf(float(after.get("moist_sum", 0.0)) - float(before.get("moist_sum", 0.0))) * 100.0
	var dl := float(absi(int(after.get("lush_cnt", 0)) - int(before.get("lush_cnt", 0)))) * 5.0
	var ev := float(int(civ_stats.get("ecology_events_sent", 0)))
	return dt + dm + dl + ev


func _wb_count_kingdom_cities(kingdom_id: int, civ_stats: Dictionary) -> int:
	if _civ != null and _civ.has_method("get_macro_badges"):
		var badges: Array = _civ.get_macro_badges()
		for raw_b in badges:
			if not (raw_b is Dictionary):
				continue
			var b: Dictionary = raw_b
			if kingdom_id < 0 or int(b.get("kingdom_id", -1)) == kingdom_id:
				var c_cnt: int = int(b.get("cities_count", b.get("cities", 0)))
				if c_cnt > 0:
					return c_cnt
	var child_cnt: int = int(civ_stats.get("child_cities", 0))
	if child_cnt > 0:
		return child_cnt + 1
	return int(civ_stats.get("cities", 0))


func _wb_run_step_ticks(ticks: int) -> void:
	for _i in range(ticks):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)
		_civ.step_civ(0.05)
		if _combat != null and _combat.has_method("step_combat"):
			_combat.step_combat(0.05)
		_fx.step_fx(0.05)
		if _world.has_method("step_cosmic_age"):
			_world.step_cosmic_age(0.05)


func _wb_run_skirmish_check(first_cid: int, first_pos: Vector2) -> Dictionary:
	var enemy_pos := _find_war_neighbor_anchor(first_pos, [first_pos], 48.0, 72.0, true)
	var cid_enemy: int = _civ.spawn_colony(enemy_pos, 1)
	if cid_enemy < 0:
		enemy_pos = _find_war_neighbor_anchor(first_pos, [first_pos], 54.0, 108.0, true)
		cid_enemy = _civ.spawn_colony(enemy_pos, 1)
	if cid_enemy >= 0:
		if _civ.has_method("grant_tech_tier_for_test"):
			_civ.grant_tech_tier_for_test(cid_enemy, 2)
		if _civ.has_method("set_diplomacy") and first_cid >= 0:
			_civ.set_diplomacy(first_cid, cid_enemy, 2)
	_apply_sim_pace(18.0)

	var observed_shots := 0
	var peak_shot_dist := 0.0
	for t in range(180):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)
		var bs_v: Variant = _physics.get("_beam_starts")
		var be_v: Variant = _physics.get("_beam_ends")
		if (bs_v is PackedVector2Array) and (be_v is PackedVector2Array):
			var bs: PackedVector2Array = bs_v
			var be: PackedVector2Array = be_v
			var n: int = mini(bs.size(), be.size())
			for i in range(n):
				observed_shots += 1
				peak_shot_dist = maxf(peak_shot_dist, bs[i].distance_to(be[i]))
		_civ.step_civ(0.05)
		if _combat != null and _combat.has_method("step_combat"):
			_combat.step_combat(0.05)
		_fx.step_fx(0.05)
		if t >= 30 and observed_shots >= 8:
			break

	var u_st: Dictionary = _physics.get_unit_stats() if _physics.has_method("get_unit_stats") else {}
	var stat_max_dist := float(u_st.get("max_shot_dist", 0.0))
	var skirmishes := int(u_st.get("skirmishes", 0))
	return {
		"shots": maxi(observed_shots, skirmishes),
		"max_dist": maxf(peak_shot_dist, stat_max_dist),
	}


func _run_headless_smoke_worldbox_pace() -> void:
	_world.generate_planet(int(TUNING_KNOBS["CIV_SMOKE_SEED"]))
	_physics.rebuild_population(0)
	_apply_sim_pace(1.0)
	if _world_laws_ui != null:
		_broadcast_world_laws(_world_laws_ui.get_laws())

	var anchor := _find_colony_land_anchor()
	var spawned: int = int(_physics.spawn_free_settlers(anchor, 0, 4)) if _physics.has_method("spawn_free_settlers") else 0
	var founded_sec := -1.0
	var first_cid := -1
	var first_kid := -1
	var first_pos := anchor

	for tick_i in range(600):
		_wb_run_step_ticks(1)
		if founded_sec < 0.0:
			var st_chk: Dictionary = _civ.get_civ_stats()
			if int(st_chk.get("cities", 0)) >= 1:
				founded_sec = float(tick_i + 1) * 0.05
				first_pos = _civ.get_primary_city_pos()
				var c_found: Dictionary = _civ.inspect_city_at(first_pos)
				first_cid = int(c_found.get("city_id", 0))
				first_kid = int(c_found.get("kingdom_id", -1))

	var st30: Dictionary = _civ.get_civ_stats()
	var c30: Dictionary = _civ.inspect_city_at(first_pos)
	var tier_at_30s := int(c30.get("tech_tier", st30.get("tech_tier", 0)))
	var tents_at_30s := int(c30.get("tents", c30.get("buildings_by_type", {}).get("Tent", 0)))
	var roads_at_30s := maxi(int(st30.get("dirt_roads", 0)), int(st30.get("roads", 0)))
	var tent_positions := _wb_collect_building_positions(1)
	var eco_before := _wb_sample_ecology(first_pos)

	_apply_sim_pace(70.0)
	for tick_w in range(800):
		_wb_run_step_ticks(1)
		if tick_w >= 80 and (tick_w % 10 == 0):
			var st_w: Dictionary = _civ.get_civ_stats()
			var t_w := maxi(int(st_w.get("max_tech_tier", 0)), int(st_w.get("tech_tier", 0)))
			var bd_w := maxi(int(st_w.get("biodomes", 0)), _wb_collect_building_positions(5).size())
			var kc_w := _wb_count_kingdom_cities(first_kid, st_w)
			var eco_w := _wb_calc_eco_delta(eco_before, _wb_sample_ecology(first_pos), st_w)
			if t_w >= 3 and bd_w >= 1 and kc_w >= 2 and eco_w > 0.1 and _wb_count_upgraded_biodomes(tent_positions) >= 1:
				break

	var st_end: Dictionary = _civ.get_civ_stats()
	var max_tier := maxi(int(st_end.get("max_tech_tier", 0)), int(st_end.get("tech_tier", 0)))
	var biodomes := maxi(int(st_end.get("biodomes", 0)), _wb_collect_building_positions(5).size())
	var upgraded_in_place := _wb_count_upgraded_biodomes(tent_positions)
	var kingdom_cities := _wb_count_kingdom_cities(first_kid, st_end)
	var eco_delta := _wb_calc_eco_delta(eco_before, _wb_sample_ecology(first_pos), st_end)
	var war_res := _wb_run_skirmish_check(first_cid, first_pos)
	var unit_shots := int(war_res["shots"])
	var max_shot_dist := float(war_res["max_dist"])

	var ok := (
		spawned == 4 and founded_sec > 0.0 and founded_sec <= 15.0
		and tier_at_30s == 0 and tents_at_30s >= 1 and roads_at_30s >= 1
		and max_tier >= 3 and biodomes >= 1 and upgraded_in_place >= 1
		and kingdom_cities >= 2 and eco_delta > 0.1
		and unit_shots >= 1 and max_shot_dist > 0.0 and max_shot_dist <= 36.0
	)
	var tail := (
		"spawned=%d founded_sec=%.2f tier_at_30s=%d tents_at_30s=%d roads_at_30s=%d "
		+ "max_tier=%d biodomes=%d upgraded_in_place=%d kingdom_cities=%d eco_delta=%.2f "
		+ "unit_shots=%d max_shot_dist=%.2f"
	) % [
		spawned, founded_sec, tier_at_30s, tents_at_30s, roads_at_30s,
		max_tier, biodomes, upgraded_in_place, kingdom_cities, eco_delta,
		unit_shots, max_shot_dist
	]
	if not ok:
		var fail_msg := "SMOKE_WORLDBOX_PACE_FAIL " + tail
		push_error(fail_msg)
		print(fail_msg)
		get_tree().quit(1)
		return
	print("SMOKE_WORLDBOX_PACE_PASS " + tail)
	get_tree().quit(0)


func _prepare_combat_capture_mode() -> void:
	_physics.rebuild_population(0)
	_apply_sim_pace(18.0)
	var ctx := _setup_stage3b_war_scenario(int(TUNING_KNOBS["CIV_SMOKE_SEED"]))
	_combat_shot_ctx = ctx
	var east_ally: Vector2 = ctx["east_ally"]
	var east_robot: Vector2 = ctx["east_robot"]
	var gate_east: Vector2 = ctx["gate_east"]
	var rebel_pos: Vector2 = ctx["rebel_pos"]

	for tick_idx in range(140):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)
		_civ.step_civ(0.05)
		if _combat != null and _combat.has_method("step_combat"):
			_combat.step_combat(0.05)
		_fx.step_fx(0.05)
		if tick_idx == 88 and _civ.has_method("apply_ai_glitch"):
			_civ.apply_ai_glitch(rebel_pos, 22.0)

	var pts: Array[Vector2] = [east_ally, gate_east, east_robot, rebel_pos]
	var min_pt := pts[0]
	var max_pt := pts[0]
	for p in pts:
		min_pt.x = minf(min_pt.x, p.x)
		min_pt.y = minf(min_pt.y, p.y)
		max_pt.x = maxf(max_pt.x, p.x)
		max_pt.y = maxf(max_pt.y, p.y)

	var span := max_pt - min_pt
	var raw_zoom := clampf(minf(920.0 / maxf(span.x + 72.0, 120.0), 540.0 / maxf(span.y + 72.0, 90.0)), 3.0, 5.0)
	_target_zoom = roundf(raw_zoom)
	var center := (min_pt + max_pt) * 0.5 + Vector2(8.0, 2.0)
	var half_w := 640.0 / _target_zoom
	var half_h := 360.0 / _target_zoom
	_cam_base_pos = Vector2(
		clampf(center.x, half_w, float(_world.map_w) - half_w),
		clampf(center.y, half_h, float(_world.map_h) - half_h)
	).round()
	_camera.zoom = Vector2(_target_zoom, _target_zoom)
	_camera.position = _cam_base_pos
	_showcase_anchor = (gate_east + east_robot) * 0.5
	_hover_world_pos = east_ally

	_locked_unit_uid = -1
	_locked_city_id = int(ctx["cid_east_ally"])
	_locked_city_pos = east_ally

	if _world.has_method("set_cosmic_age"):
		_world.set_cosmic_age(4, true)
	_set_light_mode(LightMode.DUSK)
	_night_mix = 0.28
	_sync_cosmic_age_state()

	_select_power_tab(POWER_TAB_WAR, false)
	_select_brush(BRUSH_ORBITAL_STRIKE)
	_update_hud_telemetry()
	_sync_hud_layouts()
	_world_overlay.queue_redraw()


func _find_charged_shield_pylon(min_charge: float = 0.25) -> Dictionary:
	if _civ == null or not _civ.has_method("get_shield_pylons"):
		return {"found": false}
	var pylons: Array = _civ.get_shield_pylons()
	var best_charge: float = -1.0
	var best_pylon: Dictionary = {}
	for raw_p in pylons:
		if not (raw_p is Dictionary):
			continue
		var p: Dictionary = raw_p
		var ch: float = float(p.get("charge", 0.0))
		if ch >= min_charge and ch > best_charge:
			best_charge = ch
			best_pylon = p
	if best_charge >= min_charge:
		var res := best_pylon.duplicate()
		res["found"] = true
		return res
	return {"found": false}


func _frame_detail_camera(focus: Vector2) -> void:
	_target_zoom = float(TUNING_KNOBS["ZOOM_DETAIL_SHOT"])
	var half_w := 640.0 / _target_zoom
	var half_h := 360.0 / _target_zoom
	_cam_base_pos = Vector2(
		clampf(focus.x, half_w, float(_world.map_w) - half_w),
		clampf(focus.y, half_h, float(_world.map_h) - half_h)
	).round()


func _prepare_civ_capture_mode(is_night: bool) -> void:
	_world.generate_planet(int(TUNING_KNOBS["CIV_SMOKE_SEED"]))
	_physics.rebuild_population(0)
	_apply_sim_pace(40.0)
	for _i in range(10):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)
		_fx.step_fx(0.05)

	var anchors: Array[Vector2] = _find_multi_colony_anchors()
	var a1: Vector2 = anchors[0]
	var a2: Vector2 = anchors[1]
	var cid1: int = _civ.spawn_colony(a1, 0)
	var cid2: int = _civ.spawn_colony(a2, 1)
	if cid1 < 0:
		push_warning("Shot-civ fallback: spawn_colony 1 returned -1 at %s" % str(a1))
	if cid2 < 0:
		push_warning("Shot-civ fallback: spawn_colony 2 returned -1 at %s" % str(a2))

	var min_ticks: int = int(TUNING_KNOBS["CIV_SHOT_TICKS"])
	var max_ticks: int = 920 if is_night else 540
	var settled_after_ready := 0
	var night_fx_seeded := false
	for tick_idx in range(max_ticks):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)
		_civ.step_civ(0.05)
		_fx.step_fx(0.05)
		if _world.has_method("step_cosmic_age"):
			var age_res: Dictionary = _world.step_cosmic_age(0.05)
			if bool(age_res.get("changed", false)):
				_sync_cosmic_age_state()

		if is_night and not night_fx_seeded and tick_idx == 240:
			night_fx_seeded = true
			var mid: Vector2 = (a1 + a2) * 0.5
			var c_spot := _find_corner_feature_spot(mid, a1, a2, Vector2(-74.0, 28.0))
			if c_spot.x >= 0.0:
				_world.apply_brush(c_spot, WorldTerrainScript.BrushMode.CRYSTAL_FLORA, 7)
			var l_spot := _find_corner_feature_spot(mid, a1, a2, Vector2(74.0, 28.0))
			if l_spot.x >= 0.0:
				_world.apply_brush(l_spot, WorldTerrainScript.BrushMode.LAVA_VOLCANO, 6)

		if tick_idx + 1 >= min_ticks:
			var st: Dictionary = _civ.get_civ_stats()
			var ready: bool = false
			if is_night:
				ready = int(st.get("tech_tier", 0)) >= 3 and bool(_find_charged_shield_pylon(0.35).get("found", false))
			else:
				var c1_st: Dictionary = _civ.inspect_city_at(a1)
				var road_cnt: int = int(st.get("roads", 0))
				ready = (
					bool(c1_st.get("found", false))
					and int(c1_st.get("tech_tier", 0)) >= 1
					and int(c1_st.get("farms", 0)) >= 1
					and int(c1_st.get("buildings", 0)) >= 4
					and road_cnt >= 6
				)
			if ready:
				settled_after_ready += 1
				if settled_after_ready >= 50:
					break

	var primary_pos: Vector2 = _civ.get_primary_city_pos()
	if primary_pos == Vector2.ZERO:
		primary_pos = a1

	var focus_pos := primary_pos
	if not is_night:
		var c1_focus: Dictionary = _civ.inspect_city_at(a1)
		if bool(c1_focus.get("found", false)):
			focus_pos = c1_focus.get("center", a1)
	else:
		var cp: Dictionary = _find_charged_shield_pylon(0.25)
		if bool(cp.get("found", false)):
			focus_pos = cp.get("pos", primary_pos)
		elif _civ.has_method("get_shield_pylons"):
			var pylons: Array = _civ.get_shield_pylons()
			if not pylons.is_empty():
				focus_pos = pylons[0].get("pos", primary_pos)
	_showcase_anchor = focus_pos
	_frame_detail_camera(focus_pos)
	if _civ.has_method("set_zoom_lod"):
		_civ.set_zoom_lod(_target_zoom)
	for _s in range(6):
		_civ.step_civ(0.05)
	_camera.zoom = Vector2(_target_zoom, _target_zoom)
	_camera.position = _cam_base_pos.round()
	_hover_world_pos = focus_pos

	if is_night:
		if _world.has_method("set_cosmic_age"):
			_world.set_cosmic_age(4, true)
		_set_light_mode(LightMode.NIGHT)
	else:
		if _world.has_method("set_cosmic_age"):
			_world.set_cosmic_age(0, true)
		_set_light_mode(LightMode.DAY)
	_sync_cosmic_age_state()

	_update_hud_telemetry()
	_sync_hud_layouts()
	_world_overlay.queue_redraw()


func _prepare_capture_mode() -> void:
	_sep_fps.visible = false
	_fps_label.visible = false
	_reticle.visible = false
	if _world_laws_ui != null:
		_world_laws_ui.hide_all_for_capture()

	if _shot_combat_path != "":
		_prepare_combat_capture_mode()
		return
	if _shot_night_path != "":
		_prepare_civ_capture_mode(true)
		return
	if _shot_civ_path != "":
		_prepare_civ_capture_mode(false)
		return

	_set_light_mode(LightMode.DAY)

	if _zoom_shot_path != "":
		for _i in range(42):
			_world.step_environment(0.05)
			_physics.step_physics(0.05)
			_fx.step_fx(0.05)

		_showcase_anchor = _find_showcase_anchor()
		var crystal_pos := _clamp_to_world(_showcase_anchor + Vector2(-38.0, -12.0), 20.0)
		var lava_pos := _clamp_to_world(_showcase_anchor + Vector2(36.0, 8.0), 20.0)
		_world.apply_brush(crystal_pos, WorldTerrainScript.BrushMode.CRYSTAL_FLORA, 17)
		_world.apply_brush(lava_pos, WorldTerrainScript.BrushMode.LAVA_VOLCANO, 14)

		for _i in range(7):
			_world.step_environment(0.05)
			_physics.step_physics(0.05)
			_fx.step_fx(0.05)
		_frame_detail_camera(_showcase_anchor)
	else:
		_target_zoom = float(TUNING_KNOBS["ZOOM_MACRO_SHOT"])
		_cam_base_pos = Vector2(float(_world.map_w) * 0.5, float(_world.map_h) * 0.5)
		_prepare_macro_kingdoms_showcase()
		_showcase_anchor = _cam_base_pos

	_camera.zoom = Vector2(_target_zoom, _target_zoom)
	_camera.position = _cam_base_pos.round()
	_hover_world_pos = _showcase_anchor
	_update_hud_telemetry()
	_sync_hud_layouts()


func _prepare_macro_kingdoms_showcase() -> void:
	_apply_sim_pace(40.0)
	if _civ.has_method("set_zoom_lod"):
		_civ.set_zoom_lod(float(TUNING_KNOBS["ZOOM_MACRO_SHOT"]))
	var k1 := _find_colony_land_anchor()
	var k2 := _find_war_neighbor_anchor(k1, [k1], 115.0, 260.0, false)
	var k3 := _find_war_neighbor_anchor(k1, [k1, k2], 95.0, 250.0, false)
	_civ.spawn_colony(k1, 0)
	_civ.spawn_colony(k2, 1)
	_civ.spawn_colony(k3, 2)
	for _i in range(150):
		_world.step_environment(0.05)
		_physics.step_physics(0.05)
		_civ.step_civ(0.05)
		_fx.step_fx(0.05)
	_apply_sim_pace(1.0)


func _is_colony_patch(cx: int, cy: int, check_r: int) -> bool:
	var step: int = maxi(1, check_r >> 1)
	for dy in range(-check_r, check_r + 1, step):
		for dx in range(-check_r, check_r + 1, step):
			var px := cx + dx
			var py := cy + dy
			if px < 8 or px >= int(_world.map_w) - 8 or py < 8 or py >= int(_world.map_h) - 8:
				return false
			if _world.is_water(px, py):
				return false
			if _world.get_tier(px, py) >= WorldTerrainScript.Tier.SUMMIT:
				return false
			if _world.get_biome(px, py) == WorldTerrainScript.Biome.LAVA:
				return false
			if _world.get_temp(px, py) > 52.0:
				return false
	return true


func _score_colony_patch(px: int, py: int) -> float:
	if not _is_colony_patch(px, py, 14):
		return -100000.0
	var tier: int = _world.get_tier(px, py)
	if tier < WorldTerrainScript.Tier.SAND or tier > WorldTerrainScript.Tier.SOIL_HIGH:
		return -100000.0
	var biome: int = _world.get_biome(px, py)
	if biome != WorldTerrainScript.Biome.LUSH and biome != WorldTerrainScript.Biome.RUST:
		return -100000.0

	var score: float = 160.0 if biome == WorldTerrainScript.Biome.LUSH else 70.0
	if tier == WorldTerrainScript.Tier.SOIL_LOW or tier == WorldTerrainScript.Tier.SOIL_HIGH:
		score += 40.0
	elif tier == WorldTerrainScript.Tier.SAND:
		score += 10.0

	for oy in range(-28, 29, 7):
		for ox in range(-28, 29, 7):
			var sx: int = clampi(px + ox, 0, int(_world.map_w) - 1)
			var sy: int = clampi(py + oy, 0, int(_world.map_h) - 1)
			var sb: int = _world.get_biome(sx, sy)
			var st: int = _world.get_tier(sx, sy)
			var near_core: bool = absi(ox) <= 20 and absi(oy) <= 20
			if sb == WorldTerrainScript.Biome.LAVA or (near_core and st >= WorldTerrainScript.Tier.MOUNTAINS):
				return -100000.0
			if sb == WorldTerrainScript.Biome.LUSH and (st == WorldTerrainScript.Tier.SOIL_LOW or st == WorldTerrainScript.Tier.SOIL_HIGH):
				score += 14.0
			elif sb == WorldTerrainScript.Biome.RUST and (st == WorldTerrainScript.Tier.SOIL_LOW or st == WorldTerrainScript.Tier.SOIL_HIGH):
				score += 4.0
			elif sb == WorldTerrainScript.Biome.CRYSTAL:
				score -= 50.0 if near_core else 30.0
			elif sb == WorldTerrainScript.Biome.SCORCHED:
				score -= 55.0 if near_core else 35.0
			if st >= WorldTerrainScript.Tier.MOUNTAINS:
				score -= 45.0
			elif st == WorldTerrainScript.Tier.HILLS and absi(ox) <= 14 and absi(oy) <= 14:
				score -= 10.0

	for oy_v in [-36, 0, 36]:
		var oy: int = int(oy_v)
		for ox_v in [-36, 0, 36]:
			var ox: int = int(ox_v)
			if ox == 0 and oy == 0:
				continue
			var sx2: int = clampi(px + ox, 0, int(_world.map_w) - 1)
			var sy2: int = clampi(py + oy, 0, int(_world.map_h) - 1)
			if _world.get_biome(sx2, sy2) == WorldTerrainScript.Biome.LAVA:
				return -100000.0

	var cx: int = int(_world.map_w) >> 1
	var cy: int = int(_world.map_h) >> 1
	score -= Vector2(float(px - cx), float(py - cy)).length() * 0.04
	return score


func _find_colony_land_anchor() -> Vector2:
	var best_pos: Vector2 = Vector2(float(_world.map_w) * 0.5, float(_world.map_h) * 0.5)
	var best_score: float = -99999.0
	for py in range(56, int(_world.map_h) - 56, 6):
		for px in range(72, int(_world.map_w) - 72, 6):
			var sc := _score_colony_patch(px, py)
			if sc > best_score:
				best_score = sc
				best_pos = Vector2(float(px) + 0.5, float(py) + 0.5)
	if best_score > -99999.0:
		return best_pos
	for py in range(28, int(_world.map_h) - 28, 6):
		for px in range(28, int(_world.map_w) - 28, 6):
			if _is_colony_patch(px, py, 10):
				return Vector2(float(px) + 0.5, float(py) + 0.5)
	for py in range(16, int(_world.map_h) - 16, 4):
		for px in range(16, int(_world.map_w) - 16, 4):
			if _world.is_walkable(px, py):
				return Vector2(float(px) + 0.5, float(py) + 0.5)
	return _clamp_to_world(best_pos, 48.0)


func _find_multi_colony_anchors() -> Array[Vector2]:
	var best_a := Vector2.ZERO
	var best_b := Vector2.ZERO
	var best_pair_score := -100000.0

	for py in range(58, int(_world.map_h) - 58, 8):
		for px in range(76, int(_world.map_w) - 76, 8):
			var sa := _score_colony_patch(px, py)
			if sa <= -99999.0:
				continue
			for dy_v in [-18, -6, 6, 18]:
				var dy: int = int(dy_v)
				for dx_v in [-82, -70, 70, 82]:
					var dx: int = int(dx_v)
					var qx: int = px + dx
					var qy: int = py + dy
					if qx < 32 or qx >= int(_world.map_w) - 32 or qy < 32 or qy >= int(_world.map_h) - 32:
						continue
					if not _is_colony_patch(qx, qy, 12):
						continue
					var sb: float = _score_colony_patch(qx, qy)
					if sb <= -99999.0:
						sb = 20.0
					var pair_score: float = sa + sb - float(absi(dy)) * 0.5
					if pair_score > best_pair_score:
						best_pair_score = pair_score
						best_a = Vector2(float(px) + 0.5, float(py) + 0.5)
						best_b = Vector2(float(qx) + 0.5, float(qy) + 0.5)

	if best_pair_score > -99999.0:
		return [best_a, best_b]

	var a1 := _find_colony_land_anchor()
	var a2 := _find_second_colony_anchor(a1)
	return [a1, a2]


func _find_second_colony_anchor(first: Vector2) -> Vector2:
	var best_pos := Vector2(-1.0, -1.0)
	var best_score := -100000.0
	for py in range(36, int(_world.map_h) - 36, 8):
		for px in range(44, int(_world.map_w) - 44, 8):
			var p := Vector2(float(px) + 0.5, float(py) + 0.5)
			var dist := p.distance_to(first)
			if dist < 58.0:
				continue
			if not _is_colony_patch(px, py, 10):
				continue
			var sc := _score_colony_patch(px, py)
			if sc <= -99999.0:
				sc = 0.0
			sc -= absf(dist - 84.0) * 0.65
			if sc > best_score:
				best_score = sc
				best_pos = p
	if best_pos.x >= 0.0:
		return best_pos
	for py in range(20, int(_world.map_h) - 20, 6):
		for px in range(20, int(_world.map_w) - 20, 6):
			var p := Vector2(float(px) + 0.5, float(py) + 0.5)
			if p.distance_to(first) >= 54.0 and _world.is_walkable(px, py):
				return p
	return _clamp_to_world(first + Vector2(68.0, 0.0), 24.0)


func _find_safe_far_land(a1: Vector2, a2: Vector2, min_dist: float) -> Vector2:
	for py in range(36, int(_world.map_h) - 36, 10):
		for px in range(36, int(_world.map_w) - 36, 10):
			var p := Vector2(float(px) + 0.5, float(py) + 0.5)
			if p.distance_to(a1) < min_dist or p.distance_to(a2) < min_dist:
				continue
			if _is_dry_patch(px, py, 8):
				return p
	return _find_element_point(false)


func _find_corner_feature_spot(center: Vector2, a1: Vector2, a2: Vector2, offset: Vector2) -> Vector2:
	var base := _clamp_to_world(center + offset, 18.0)
	for r in range(0, 18, 4):
		for dy_v in [-r, 0, r]:
			var dy: int = int(dy_v)
			for dx_v in [-r, 0, r]:
				var dx: int = int(dx_v)
				var px: int = clampi(int(base.x) + dx, 14, int(_world.map_w) - 15)
				var py: int = clampi(int(base.y) + dy, 14, int(_world.map_h) - 15)
				var p := Vector2(float(px) + 0.5, float(py) + 0.5)
				if p.distance_to(a1) >= 48.0 and p.distance_to(a2) >= 48.0 and _is_dry_patch(px, py, 6):
					return p
	return Vector2(-1.0, -1.0)


func _is_dry_patch(cx: int, cy: int, check_r: int) -> bool:
	for dy in range(-check_r, check_r + 1, maxi(1, check_r >> 1)):
		for dx in range(-check_r, check_r + 1, maxi(1, check_r >> 1)):
			var px := cx + dx
			var py := cy + dy
			if px < 8 or px >= int(_world.map_w) - 8 or py < 8 or py >= int(_world.map_h) - 8:
				return false
			if _world.is_water(px, py):
				return false
			if _world.get_tier(px, py) >= WorldTerrainScript.Tier.SUMMIT:
				return false
	return true


func _find_showcase_anchor() -> Vector2:
	var cx: int = int(_world.map_w) >> 1
	var cy: int = int(_world.map_h) >> 1
	var best_pos: Vector2 = _physics.get_first_unit_pos()
	var best_score: float = -10000.0

	for py in range(68, int(_world.map_h) - 68, 6):
		for px in range(88, int(_world.map_w) - 88, 6):
			var meteor_x := px - 4
			var meteor_y := py + 6
			var m_tier: int = _world.get_tier(meteor_x, meteor_y)
			if m_tier < WorldTerrainScript.Tier.SOIL_HIGH or m_tier > WorldTerrainScript.Tier.MOUNTAINS:
				continue
			if not _is_dry_patch(px, py, 20):
				continue
			if not _is_dry_patch(px - 38, py - 12, 14):
				continue
			if not _is_dry_patch(px + 36, py + 8, 12):
				continue

			var c_tier: int = _world.get_tier(px - 38, py - 12)
			var l_tier: int = _world.get_tier(px + 36, py + 8)
			if c_tier < WorldTerrainScript.Tier.SAND or c_tier > WorldTerrainScript.Tier.HILLS:
				continue
			if l_tier < WorldTerrainScript.Tier.SAND:
				continue

			var score := 100.0
			if m_tier == WorldTerrainScript.Tier.HILLS:
				score += 75.0
			elif m_tier == WorldTerrainScript.Tier.MOUNTAINS:
				score += 40.0
			elif m_tier == WorldTerrainScript.Tier.SOIL_HIGH:
				score += 20.0

			var bg_water: int = 0
			for wy_v in [-60, -48, 48, 60]:
				var wy: int = int(wy_v)
				for wx_v in [-88, -66, 66, 88]:
					var wx: int = int(wx_v)
					if _world.is_water(px + wx, py + wy):
						bg_water += 1
			score += float(mini(bg_water, 5)) * 6.0

			var center_dist := Vector2(float(px - cx), float(py - cy)).length()
			score -= center_dist * 0.18

			if score > best_score:
				best_score = score
				best_pos = Vector2(float(px) + 0.5, float(py) + 0.5)

	if best_score <= -9999.0:
		for py in range(48, int(_world.map_h) - 48, 8):
			for px in range(56, int(_world.map_w) - 56, 8):
				if _world.is_water(px, py) or _world.is_water(px - 4, py + 6):
					continue
				if _is_dry_patch(px, py, 10):
					var t: int = _world.get_tier(px - 4, py + 6)
					var fallback_score := float(t) * 10.0 - Vector2(float(px - cx), float(py - cy)).length() * 0.2
					if fallback_score > best_score:
						best_score = fallback_score
						best_pos = Vector2(float(px) + 0.5, float(py) + 0.5)

	return _clamp_to_world(best_pos, 64.0)


func _clamp_to_world(pos: Vector2, margin: float) -> Vector2:
	return Vector2(
		clampf(pos.x, margin, float(_world.map_w) - margin),
		clampf(pos.y, margin, float(_world.map_h) - margin)
	)


func _unhandled_input(event: InputEvent) -> void:
	if _smoke_mode or _smoke_civ_mode or _smoke_combat_mode or _smoke_worldbox_pace_mode or _is_capture_mode():
		return
	if event is InputEventKey:
		_handle_key_input(event as InputEventKey)
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		_handle_mouse_input(event)


func _handle_key_input(kev: InputEventKey) -> void:
	if not kev.pressed or kev.echo:
		if kev.keycode == KEY_SHIFT:
			_reticle.queue_redraw()
		return
	match kev.keycode:
		KEY_Q:
			_select_power_tab(posmod(_active_power_tab - 1, 4), true)
			_fx.play_sfx("ui")
		KEY_E:
			_select_power_tab(posmod(_active_power_tab + 1, 4), true)
			_fx.play_sfx("ui")
		KEY_TAB:
			var dir_tab := -1 if kev.shift_pressed else 1
			_select_power_tab(posmod(_active_power_tab + dir_tab, 4), true)
			_fx.play_sfx("ui")
		KEY_1:
			if kev.alt_pressed:
				_select_active_tab_slot(0)
			else:
				_select_brush(WorldTerrainScript.BrushMode.TERRAFORM_LIFE)
				_fx.play_sfx("ui")
		KEY_2:
			if kev.alt_pressed:
				_select_active_tab_slot(1)
			else:
				_select_brush(WorldTerrainScript.BrushMode.CRYSTAL_FLORA)
				_fx.play_sfx("ui")
		KEY_3:
			if kev.alt_pressed:
				_select_active_tab_slot(2)
			else:
				_select_brush(WorldTerrainScript.BrushMode.LAVA_VOLCANO)
				_fx.play_sfx("ui")
		KEY_4:
			if kev.alt_pressed:
				_select_active_tab_slot(3)
			else:
				_select_brush(WorldTerrainScript.BrushMode.METEOR_CRATER)
				_fx.play_sfx("ui")
		KEY_5:
			_select_brush(WorldTerrainScript.BrushMode.VORTEX_PULL)
			_fx.play_sfx("ui")
		KEY_6:
			_select_brush(BRUSH_COLONY)
			_fx.play_sfx("ui")
		KEY_7:
			_select_brush(BRUSH_BLESS)
			_fx.play_sfx("ui")
		KEY_8, KEY_I:
			_select_brush(BRUSH_INSPECT)
			_fx.play_sfx("ui")
		KEY_9:
			_select_brush(BRUSH_ORBITAL_STRIKE)
			_fx.play_sfx("ui")
		KEY_0:
			_select_brush(BRUSH_DIPLO_SPARK)
			_fx.play_sfx("ui")
		KEY_F5:
			if save_world_to_file():
				_fx.play_sfx("ui")
		KEY_F9:
			if load_world_from_file():
				_fx.play_sfx("ui")
		KEY_F:
			_select_faction(_selected_faction + 1)
			_select_brush(BRUSH_COLONY)
			_fx.play_sfx("ui")
		KEY_G:
			_on_cosmic_age_clicked()
		KEY_P:
			_toggle_possession_hotkey()
		KEY_L:
			_set_light_mode((_light_mode + 1) % 4)
			_fx.play_sfx("ui")
		KEY_ESCAPE:
			if _world_laws_ui != null and _world_laws_ui.is_laws_panel_open():
				_world_laws_ui.set_laws_panel_open(false)
			elif _possessing_uid >= 0:
				_exit_possession()
				_update_hud_telemetry()
			else:
				_clear_inspector_lock()
			_fx.play_sfx("ui")
		KEY_BRACKETLEFT:
			_step_brush_size(-1)
		KEY_BRACKETRIGHT:
			_step_brush_size(1)
		KEY_SPACE:
			if _possessing_uid >= 0:
				_possess_pulse_queued = true
				if _sim_speed <= 0.0:
					_set_sim_speed(_last_nonzero_speed)
			else:
				_set_sim_speed(0.0 if _sim_speed > 0.0 else _last_nonzero_speed)
				_fx.play_sfx("ui")


func _toggle_possession_hotkey() -> void:
	if _possessing_uid >= 0:
		_exit_possession()
		_fx.play_sfx("ui")
		_update_hud_telemetry()
		return
	var p_target := _locked_unit_uid if _locked_unit_uid >= 0 else _last_inspect_unit_uid
	if p_target < 0 and _has_mouse_hover:
		var u_probe: Dictionary = _physics.inspect_unit_at(_hover_world_pos)
		if bool(u_probe.get("found", false)):
			var u_pos: Vector2 = u_probe.get("pos", _hover_world_pos)
			if u_pos.distance_to(_hover_world_pos) <= 14.0:
				p_target = int(u_probe.get("uid", -1))
	if p_target >= 0:
		_enter_possession(p_target)
	else:
		_fx.play_sfx("ui")


func _step_zoom_level(dir: int) -> void:
	var best_idx := 0
	var best_err := 999.0
	for i in range(ZOOM_STOPS.size()):
		var err := absf(_target_zoom - ZOOM_STOPS[i])
		if err < best_err:
			best_err = err
			best_idx = i
	var next_idx := clampi(best_idx + dir, 0, ZOOM_STOPS.size() - 1)
	_target_zoom = ZOOM_STOPS[next_idx]


func _handle_mouse_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_step_zoom_level(1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_step_zoom_level(-1)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_panning_rmb = mb.pressed
			if mb.pressed:
				_follow_locked_unit = false
				_cam_focus_active = false
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if _possessing_uid >= 0:
				_painting_lmb = false
				if mb.pressed:
					_possess_pulse_queued = true
			else:
				_painting_lmb = mb.pressed
				if mb.pressed:
					_hover_world_pos = get_global_mouse_position()
					_has_mouse_hover = true
					_apply_active_brush(_hover_world_pos, true)
	elif event is InputEventMouseMotion:
		_hover_world_pos = get_global_mouse_position()
		_has_mouse_hover = true
		_reticle.queue_redraw()
		if _panning_rmb:
			var mm := event as InputEventMouseMotion
			_follow_locked_unit = false
			_cam_focus_active = false
			_cam_base_pos -= mm.relative / maxf(_camera.zoom.x, 0.1)
			_clamp_camera_base()
		elif _possessing_uid < 0 and _painting_lmb and _current_brush != WorldTerrainScript.BrushMode.VORTEX_PULL and _current_brush != BRUSH_COLONY and _current_brush != BRUSH_INSPECT and _current_brush != BRUSH_DIPLO_SPARK:
			_apply_active_brush(_hover_world_pos, false)


func _step_brush_size(dir: int) -> void:
	var sizes: Array[int] = [
		int(TUNING_KNOBS["BRUSH_SIZE_XS"]),
		int(TUNING_KNOBS["BRUSH_SIZE_S"]),
		int(TUNING_KNOBS["BRUSH_SIZE_M"]),
		int(TUNING_KNOBS["BRUSH_SIZE_L"]),
		int(TUNING_KNOBS["BRUSH_SIZE_XL"]),
	]
	var idx: int = sizes.find(_brush_radius)
	if idx < 0:
		idx = 2
	idx = clampi(idx + dir, 0, sizes.size() - 1)
	_select_brush_size(sizes[idx])
	_fx.play_sfx("ui")


func _handle_inspector_click(world_pos: Vector2) -> void:
	var c_info: Dictionary = _civ.inspect_city_at(world_pos)
	var in_city := bool(c_info.get("found", false))
	var unit_pick_r := 4.5 if in_city else 10.0

	var u_info: Dictionary = _physics.inspect_unit_at(world_pos)
	if bool(u_info.get("found", false)):
		var u_pos: Vector2 = u_info.get("pos", world_pos)
		if u_pos.distance_to(world_pos) <= unit_pick_r:
			var new_uid := int(u_info.get("uid", -1))
			if _possessing_uid >= 0 and _possessing_uid != new_uid:
				_exit_possession()
			_locked_unit_uid = new_uid
			_locked_city_id = -1
			_follow_locked_unit = (_locked_unit_uid >= 0)
			_fx.play_sfx("ui")
			_update_hud_telemetry()
			return

	if in_city:
		_exit_possession()
		_locked_unit_uid = -1
		_follow_locked_unit = false
		_locked_city_id = int(c_info.get("city_id", -1))
		_locked_city_pos = c_info.get("center", world_pos)
		_cam_base_pos = _locked_city_pos.round()
		_clamp_camera_base()
		_fx.play_sfx("ui")
		_update_hud_telemetry()
		return

	_clear_inspector_lock()
	_fx.play_sfx("ui")
	_update_hud_telemetry()


func _execute_orbital_or_meteor(world_pos: Vector2, radius: int, is_orbital_beam: bool) -> void:
	var rad_f := float(radius)
	if is_orbital_beam and _combat != null and _combat.has_method("fire_orbital_strike"):
		var strike_res: Dictionary = _combat.fire_orbital_strike(world_pos, rad_f)
		if not _combat.has_signal("impact_trauma"):
			if bool(strike_res.get("intercepted", false)):
				_on_impact_trauma(0.15, 0.0)
			else:
				_on_impact_trauma(0.42, 0.045)
		_world_overlay.queue_redraw()
		return

	var intercept: Dictionary = _civ.try_intercept_orbital_impact(world_pos, rad_f) if _civ.has_method("try_intercept_orbital_impact") else {}
	if bool(intercept.get("intercepted", false)):
		var pylon_pos: Vector2 = intercept.get("pylon_pos", world_pos)
		var shield_r: float = float(intercept.get("radius", 48.0))
		var diff := world_pos - pylon_pos
		var stop_pos := pylon_pos + (diff.normalized() * minf(diff.length(), shield_r * 0.92) if diff.length_squared() > 1.0 else Vector2(0.0, -shield_r * 0.7))
		if _world.has_method("apply_orbital_strike"):
			_world.apply_orbital_strike(world_pos, rad_f, true)
		_fx.emit_shield_deflect(pylon_pos, shield_r, stop_pos)
		if is_orbital_beam:
			_fx.emit_orbital_beam(world_pos, true, stop_pos)
		_on_impact_trauma(0.15, 0.0)
		_world_overlay.queue_redraw()
		return

	if is_orbital_beam:
		if _world.has_method("apply_orbital_strike"):
			_world.apply_orbital_strike(world_pos, rad_f, false)
		else:
			_world.apply_brush(world_pos, WorldTerrainScript.BrushMode.METEOR_CRATER, radius)
		_fx.emit_orbital_beam(world_pos, false)
		_civ.on_terrain_damaged(world_pos, rad_f)
		_on_impact_trauma(0.38, 0.04)
	else:
		_world.apply_brush(world_pos, WorldTerrainScript.BrushMode.METEOR_CRATER, radius)
		_civ.on_terrain_damaged(world_pos, rad_f)


func _apply_active_brush(world_pos: Vector2, is_initial_press: bool) -> void:
	if _possessing_uid >= 0:
		return

	if _current_brush == BRUSH_INSPECT:
		if is_initial_press:
			_handle_inspector_click(world_pos)
		return

	if _current_brush == BRUSH_COLONY:
		if is_initial_press:
			_apply_colony_brush(world_pos)
		return

	if _current_brush == BRUSH_DIPLO_SPARK:
		if is_initial_press:
			_apply_diplo_brush(world_pos)
		return

	if _current_brush == BRUSH_STORM_RAIN or _current_brush == BRUSH_STORM_FIRE or _current_brush == BRUSH_STORM_ION:
		_apply_storm_brush(world_pos, is_initial_press)
		return

	if _current_brush == BRUSH_AI_GLITCH or _current_brush == BRUSH_XENO_VIRUS or _current_brush == BRUSH_BIO_SEEDER:
		_apply_evo_brush(world_pos, is_initial_press)
		return

	if _current_brush == BRUSH_BLESS:
		if not is_initial_press and _bless_cooldown > 0.0:
			return
		_bless_cooldown = float(TUNING_KNOBS["BLESS_REPEAT_SEC"])
		var do_bless := not Input.is_key_pressed(KEY_SHIFT)
		_physics.bless_or_mutate_area(world_pos, float(_brush_radius), do_bless)
		return

	if _current_brush == WorldTerrainScript.BrushMode.METEOR_CRATER:
		if not is_initial_press and _meteor_cooldown > 0.0:
			return
		_meteor_cooldown = float(TUNING_KNOBS["METEOR_REPEAT_SEC"])
		_execute_orbital_or_meteor(world_pos, _brush_radius, false)
		return

	if _current_brush == BRUSH_ORBITAL_STRIKE:
		if not is_initial_press and _orbital_strike_cooldown > 0.0:
			return
		_orbital_strike_cooldown = 0.24
		_execute_orbital_or_meteor(world_pos, _brush_radius, true)
		return

	if _current_brush == WorldTerrainScript.BrushMode.VORTEX_PULL:
		return

	var brush_mode: int = _current_brush
	var digging_canal := (
		brush_mode == BRUSH_CANAL
		or (brush_mode == WorldTerrainScript.BrushMode.TERRAFORM_LIFE and Input.is_key_pressed(KEY_SHIFT))
	)
	if digging_canal:
		brush_mode = WorldTerrainScript.BrushMode.LOWER_CANAL

	_world.apply_brush(world_pos, brush_mode, _brush_radius)
	if brush_mode == WorldTerrainScript.BrushMode.LAVA_VOLCANO:
		_civ.on_terrain_damaged(world_pos, float(_brush_radius))
		if is_initial_press or _sfx_cooldown <= 0.0:
			_fx.spawn_burst(world_pos, 8, Color(1.0, 0.48, 0.16, 1.0), 20.0, 0.44, -8.0)
			_play_brush_sfx("lava")
	elif digging_canal:
		if is_initial_press or _sfx_cooldown <= 0.0:
			_fx.spawn_burst(world_pos, 6, Color(0.42, 0.84, 1.0, 0.95), 18.0, 0.36, 16.0)
			_play_brush_sfx("terraform")
	elif brush_mode == WorldTerrainScript.BrushMode.TERRAFORM_LIFE:
		if is_initial_press or _sfx_cooldown <= 0.0:
			_fx.spawn_burst(world_pos, 8, Color(0.45, 1.35, 0.60, 1.0), 20.0, 0.42, -8.0)
			_play_brush_sfx("terraform")
	elif brush_mode == WorldTerrainScript.BrushMode.CRYSTAL_FLORA:
		if is_initial_press or _sfx_cooldown <= 0.0:
			_fx.spawn_burst(world_pos, 10, Color(0.35, 1.85, 2.25, 1.0), 24.0, 0.48, -10.0)
			_play_brush_sfx("crystal")


func _apply_diplo_brush(world_pos: Vector2) -> void:
	var force_mode := 3 if Input.is_key_pressed(KEY_SHIFT) else -1
	if _civ.has_method("trigger_diplomacy_spark"):
		var res: Dictionary = _civ.trigger_diplomacy_spark(world_pos, force_mode)
		if bool(res.get("triggered", res.get("ok", false))):
			var st := int(res.get("state", 0))
			var is_rebel := bool(res.get("rebellion", false)) or st == 3
			var is_war := st == 2
			var is_pact := st == 1
			var strip_id := STRIP_REBEL if is_rebel else (STRIP_WAR if is_war else STRIP_PACT)
			var wave_col := Color("#FF9B26") if is_rebel else (Color("#FF4646") if is_war else (Color("#46E5FF") if is_pact else Color("#FFB84D")))
			if (is_rebel or is_war or is_pact) and _fx.has_method("spawn_reaction_strip"):
				_fx.spawn_reaction_strip(world_pos + Vector2(0.0, -14.0), strip_id)
			_fx.spawn_shockwave(world_pos, 18.0, wave_col, 0.28)
			_fx.play_sfx("emp_glitch" if is_rebel else "ui")
			_world_overlay.queue_redraw()
			_update_hud_telemetry()
			return
	_fx.spawn_burst(world_pos, 3, Color(0.68, 0.80, 0.92, 0.65), 10.0, 0.20, 0.0)
	_fx.play_sfx("ui")


func _apply_storm_brush(world_pos: Vector2, is_initial_press: bool) -> void:
	if not is_initial_press and _storm_cooldown > 0.0:
		return
	_storm_cooldown = float(TUNING_KNOBS["STORM_REPEAT_SEC"])
	var storm_kind := "rainburst"
	var burst_col := Color(0.45, 0.86, 1.0, 0.95)
	if _current_brush == BRUSH_STORM_FIRE:
		storm_kind = "firestorm"
		burst_col = Color(1.0, 0.56, 0.22, 0.95)
	elif _current_brush == BRUSH_STORM_ION:
		storm_kind = "ion_storm"
		burst_col = Color(0.32, 0.95, 1.0, 1.0)
		_fx.spawn_shockwave(world_pos, float(_brush_radius), Color("#46F2FF"), 0.26)
	if _world.has_method("apply_elemental_storm"):
		_world.apply_elemental_storm(world_pos, float(_brush_radius), storm_kind)
	if is_initial_press or _sfx_cooldown <= 0.0:
		_fx.spawn_burst(world_pos, 8, burst_col, 22.0, 0.42, 8.0)
		_play_brush_sfx("storm")


func _apply_evo_brush(world_pos: Vector2, is_initial_press: bool) -> void:
	if not is_initial_press and _evo_cooldown > 0.0:
		return
	_evo_cooldown = float(TUNING_KNOBS["EVO_REPEAT_SEC"])
	if _current_brush == BRUSH_AI_GLITCH:
		var civ_hits: int = 0
		if _civ.has_method("apply_ai_glitch"):
			var g_res: Dictionary = _civ.apply_ai_glitch(world_pos, float(_brush_radius))
			civ_hits = int(g_res.get("affected_cities", 0))
		var u_hits: int = int(_physics.apply_ai_glitch_units(world_pos, float(_brush_radius))) if _physics.has_method("apply_ai_glitch_units") else 0
		if civ_hits + u_hits > 0:
			_fx.spawn_shockwave(world_pos, float(_brush_radius), Color("#FF466E"), 0.28)
			_play_brush_sfx("emp_glitch")
			_world_overlay.queue_redraw()
		elif is_initial_press:
			_fx.spawn_burst(world_pos, 3, Color(0.38, 0.72, 0.88, 0.65), 10.0, 0.22, 0.0)
			_fx.play_sfx("ui")
	elif _current_brush == BRUSH_XENO_VIRUS:
		var v_hits: int = int(_physics.apply_xeno_virus(world_pos, float(_brush_radius))) if _physics.has_method("apply_xeno_virus") else 0
		if v_hits > 0:
			_play_brush_sfx("mutate")
		elif is_initial_press:
			_fx.spawn_burst(world_pos, 3, Color(0.66, 0.42, 0.88, 0.65), 10.0, 0.22, -4.0)
			_fx.play_sfx("ui")
	else:
		_world.apply_brush(world_pos, WorldTerrainScript.BrushMode.TERRAFORM_LIFE, _brush_radius)
		var seeded: int = int(_physics.plant_bio_seeder(world_pos, float(_brush_radius))) if _physics.has_method("plant_bio_seeder") else 0
		if seeded > 0:
			_play_brush_sfx("terraform")
		elif is_initial_press:
			_fx.spawn_burst(world_pos, 3, Color("#68F078"), 10.0, 0.22, -4.0)
			_fx.play_sfx("ui")
	_update_hud_telemetry()


func _apply_colony_brush(world_pos: Vector2) -> void:
	if Input.is_key_pressed(KEY_SHIFT):
		var city_id: int = _civ.spawn_colony(world_pos, _selected_faction)
		if city_id >= 0:
			_fx.emit_build_pop(world_pos)
			_update_hud_telemetry()
			_reticle.queue_redraw()
		else:
			_fx.play_sfx("ui")
		return
	var count := 1 if _brush_radius <= 4 else (4 if _brush_radius <= 8 else 8)
	var spawned: int = int(_physics.spawn_free_settlers(world_pos, _selected_faction, count)) if _physics.has_method("spawn_free_settlers") else 0
	if spawned > 0:
		var f_col: Color = FACTION_RETICLE_COLORS[posmod(_selected_faction, FACTION_RETICLE_COLORS.size())]
		_fx.spawn_burst(world_pos, mini(spawned + 2, 8), f_col, 14.0, 0.30, -6.0)
		_fx.play_sfx("build_pop", world_pos.x)
		_update_hud_telemetry()
		_reticle.queue_redraw()
	else:
		_fx.play_sfx("ui")


func _play_brush_sfx(kind: String) -> void:
	if _sfx_cooldown <= 0.0:
		_fx.play_sfx(kind)
		_sfx_cooldown = float(TUNING_KNOBS["BRUSH_SFX_COOLDOWN_SEC"])


func _process(delta: float) -> void:
	if _smoke_mode or _smoke_civ_mode or _smoke_combat_mode or _smoke_worldbox_pace_mode or _capturing_now:
		return

	_elapsed_time += delta
	_meteor_cooldown = maxf(0.0, _meteor_cooldown - delta)
	_orbital_strike_cooldown = maxf(0.0, _orbital_strike_cooldown - delta)
	_bless_cooldown = maxf(0.0, _bless_cooldown - delta)
	_storm_cooldown = maxf(0.0, _storm_cooldown - delta)
	_evo_cooldown = maxf(0.0, _evo_cooldown - delta)
	_terrain_hold_cooldown = maxf(0.0, _terrain_hold_cooldown - delta)
	_vortex_terrain_cooldown = maxf(0.0, _vortex_terrain_cooldown - delta)
	_sfx_cooldown = maxf(0.0, _sfx_cooldown - delta)
	_possess_cooldown = maxf(0.0, _possess_cooldown - delta)

	if _is_capture_mode():
		_process_capture_sequence(delta)
		return

	_update_orbital_lighting(delta)
	_update_camera_controls(delta)
	_update_camera_shake(delta)
	_process_active_input_tools(delta)
	_fx.step_fx(delta)
	_step_simulation_substeps(delta)

	if _world_laws_ui != null:
		if _civ != null and _civ.has_method("pop_chronicle_events"):
			var evs: Array = _civ.pop_chronicle_events()
			if not evs.is_empty():
				_world_laws_ui.push_chronicle_events(evs)
		_world_laws_ui.step_ui(delta)

	var cur_spd := _hover_world_pos.distance_to(_prev_hover_world_pos) / maxf(delta, 0.001)
	_prev_hover_world_pos = _hover_world_pos
	_cursor_speed_ema = lerpf(_cursor_speed_ema, clampf(cur_spd / 220.0, 0.0, 1.0), 0.25)

	var z := _camera.zoom.x
	if _civ.has_method("set_zoom_lod"):
		_civ.set_zoom_lod(z)
	if _physics.has_method("set_zoom_lod"):
		_physics.set_zoom_lod(z)
	if _fx.has_method("set_audio_telemetry"):
		_fx.set_audio_telemetry(z, _cursor_speed_ema)
	if _fx.has_method("set_camera_center_x"):
		_fx.set_camera_center_x(_cam_base_pos.x)

	_update_lightmap_frame()
	_update_fps_ema(delta)
	_update_hud_telemetry()
	_world_overlay.queue_redraw()
	_macro_badges.visible = (z <= 2.6)
	if _macro_badges.visible:
		_macro_badges.queue_redraw()
	if _has_mouse_hover:
		_reticle.queue_redraw()


func _process_active_input_tools(delta: float) -> void:
	if _possessing_uid >= 0 and _physics.has_method("set_possessed_unit"):
		var p_dir := _read_wasd_dir()
		var fire_pulse := false
		if _possess_pulse_queued and _possess_cooldown <= 0.0:
			fire_pulse = true
			_possess_pulse_queued = false
			_possess_cooldown = 0.22
		var p_res: Dictionary = _physics.set_possessed_unit(_possessing_uid, p_dir, fire_pulse)
		if not bool(p_res.get("active", false)):
			_exit_possession()
		elif fire_pulse:
			_fx.play_sfx("skirmish")
			_fx.spawn_shockwave(p_res.get("pos", _cam_base_pos), 16.0, Color("#45E9FF"), 0.25)
	elif _possessing_uid < 0 and _painting_lmb:
		var mouse_world := get_global_mouse_position()
		_hover_world_pos = mouse_world
		if _current_brush == WorldTerrainScript.BrushMode.VORTEX_PULL:
			var vortex_dt := maxf(delta * maxf(_sim_speed, 1.0), 0.016)
			_physics.apply_vortex(mouse_world, float(_brush_radius) * float(TUNING_KNOBS["VORTEX_RADIUS_MULT"]), float(TUNING_KNOBS["VORTEX_STRENGTH"]), vortex_dt)
			if _vortex_terrain_cooldown <= 0.0:
				_vortex_terrain_cooldown = 0.12
				_world.apply_brush(mouse_world, WorldTerrainScript.BrushMode.VORTEX_PULL, _brush_radius)
		elif _current_brush != BRUSH_COLONY and _current_brush != BRUSH_INSPECT and _current_brush != BRUSH_DIPLO_SPARK:
			if get_viewport().gui_get_hovered_control() == null:
				var is_terrain_paint := (
					_current_brush == WorldTerrainScript.BrushMode.TERRAFORM_LIFE
					or _current_brush == BRUSH_CANAL
					or _current_brush == WorldTerrainScript.BrushMode.CRYSTAL_FLORA
					or _current_brush == WorldTerrainScript.BrushMode.LAVA_VOLCANO
				)
				if not is_terrain_paint:
					_apply_active_brush(mouse_world, false)
				elif _terrain_hold_cooldown <= 0.0:
					_terrain_hold_cooldown = 0.08
					_apply_active_brush(mouse_world, false)


func _step_simulation_substeps(delta: float) -> void:
	if _hit_stop_timer > 0.0:
		_hit_stop_timer = maxf(0.0, _hit_stop_timer - delta)
		if _combat != null and _combat.has_method("step_visual_fade"):
			_combat.step_visual_fade(delta)
		return
	if _sim_speed <= 0.0:
		return
	var total_sim_dt := delta * _sim_speed
	var max_step: float = 0.05 if _sim_speed > 5.0 else float(TUNING_KNOBS["SIM_SUBSTEP_MAX_DT"])
	var steps := 0
	var max_substeps: int = int(TUNING_KNOBS["SIM_MAX_SUBSTEPS"])
	var budget_usec: int = int(TUNING_KNOBS["SIM_FRAME_BUDGET_USEC"])
	var sim_start_usec := Time.get_ticks_usec()
	while total_sim_dt > 0.0001 and steps < max_substeps:
		if steps >= 2 and (Time.get_ticks_usec() - sim_start_usec) >= budget_usec:
			break
		var step_dt := minf(total_sim_dt, max_step)
		_world.step_environment(step_dt)
		if _world.has_method("step_cosmic_age"):
			var age_step: Dictionary = _world.step_cosmic_age(step_dt)
			if bool(age_step.get("changed", false)):
				_sync_cosmic_age_state()
			if bool(age_step.get("strike_pending", false)):
				_execute_orbital_or_meteor(age_step.get("strike_pos", Vector2(320.0, 180.0)), 13, true)
		_physics.step_physics(step_dt)
		_civ.step_civ(step_dt)
		if _combat != null and _combat.has_method("step_combat"):
			_combat.step_combat(step_dt)
		total_sim_dt -= step_dt
		steps += 1


func _process_capture_sequence(delta: float) -> void:
	_capture_frames_waited += 1
	_fx.step_fx(delta)
	_update_camera_shake(delta)

	if _capture_frames_waited == 2:
		if _shot_combat_path != "":
			var gate_west: Vector2 = _combat_shot_ctx.get("gate_west", _showcase_anchor + Vector2(-60.0, 0.0))
			var gate_east: Vector2 = _combat_shot_ctx.get("gate_east", _showcase_anchor)
			var east_ally: Vector2 = _combat_shot_ctx.get("east_ally", gate_east)
			var east_robot: Vector2 = _combat_shot_ctx.get("east_robot", _showcase_anchor + Vector2(36.0, 0.0))
			var rebel_pos: Vector2 = _combat_shot_ctx.get("rebel_pos", _showcase_anchor + Vector2(18.0, 32.0))
			var cid_west: int = int(_combat_shot_ctx.get("cid_west", -1))
			var cid_east_ally: int = int(_combat_shot_ctx.get("cid_east_ally", -1))
			if _combat != null:
				if _combat.has_method("transfer_squad_portal"):
					var moved: int = 0
					if cid_west >= 0:
						moved = int(_combat.transfer_squad_portal(gate_west, gate_east, cid_west))
					if moved <= 0 and cid_east_ally >= 0:
						moved = int(_combat.transfer_squad_portal(gate_east, gate_west, cid_east_ally))
					if moved <= 0 and _combat.has_method("get_combat_stats"):
						var cs: Dictionary = _combat.get_combat_stats()
						if int(cs.get("active_arcs", 0)) == 0:
							if cid_west >= 0:
								moved = int(_combat.transfer_squad_portal(gate_east, gate_west, cid_west))
							if moved <= 0 and cid_east_ally >= 0:
								_combat.transfer_squad_portal(gate_west, gate_east, cid_east_ally)
				if _combat.has_method("fire_orbital_strike"):
					var strike_off := (east_robot - east_ally).normalized() * 3.0 if east_robot.distance_squared_to(east_ally) > 1.0 else Vector2(3.0, 0.0)
					_combat.fire_orbital_strike(east_robot + strike_off, 11.0)
				if _combat.has_method("step_combat"):
					_combat.step_combat(0.03)
			if _fx.has_method("spawn_reaction_strip"):
				_fx.spawn_reaction_strip(east_ally + Vector2(0.0, -14.0), STRIP_WAR)
				_fx.spawn_reaction_strip(rebel_pos + Vector2(0.0, -14.0), STRIP_REBEL)
			_physics.step_physics(0.03)
			_fx.step_fx(0.03)
			_hit_stop_timer = 0.0
			_update_hud_telemetry()
		elif _zoom_shot_path != "":
			var meteor_pos := _clamp_to_world(_showcase_anchor + Vector2(-4.0, 6.0), 24.0)
			_world.apply_brush(meteor_pos, WorldTerrainScript.BrushMode.METEOR_CRATER, 15)
			_fx.step_fx(0.125)
			_physics.step_physics(0.05)
			_hit_stop_timer = 0.0
			_hover_world_pos = meteor_pos
			_update_hud_telemetry()
		elif _shot_night_path != "":
			var cp: Dictionary = _find_charged_shield_pylon(0.25)
			var strike_target := _showcase_anchor + Vector2(6.0, -4.0)
			if bool(cp.get("found", false)):
				strike_target = Vector2(cp.get("pos", _showcase_anchor)) + Vector2(8.0, -4.0)
			elif _civ.has_method("get_shield_pylons"):
				var pylons: Array = _civ.get_shield_pylons()
				if not pylons.is_empty():
					strike_target = pylons[0].get("pos", _showcase_anchor) + Vector2(8.0, -4.0)
			_execute_orbital_or_meteor(strike_target, 14, true)
			if _fx.has_method("spawn_reaction_strip"):
				_fx.spawn_reaction_strip(_showcase_anchor + Vector2(-28.0, -14.0), 0)
				_fx.spawn_reaction_strip(_showcase_anchor + Vector2(28.0, -16.0), 2)
			_fx.step_fx(0.05)
			_hit_stop_timer = 0.0
			_update_hud_telemetry()
	elif _capture_frames_waited == 3 and _shot_combat_path != "":
		if _combat != null and _combat.has_method("step_combat"):
			_combat.step_combat(0.016)
		_physics.step_physics(0.016)
		_fx.step_fx(0.016)
		_hit_stop_timer = 0.0

	var z := _camera.zoom.x
	if _civ.has_method("set_zoom_lod"):
		_civ.set_zoom_lod(z)
	if _physics.has_method("set_zoom_lod"):
		_physics.set_zoom_lod(z)
	if _fx.has_method("set_camera_center_x"):
		_fx.set_camera_center_x(_cam_base_pos.x)
	_update_lightmap_frame()
	_world_overlay.queue_redraw()
	_macro_badges.visible = (z <= 2.6)
	if _macro_badges.visible:
		_macro_badges.queue_redraw()

	if _capture_frames_waited >= 4:
		_capturing_now = true
		call_deferred("_finish_capture")


func _update_lightmap_frame() -> void:
	if _fx == null or not _fx.has_method("begin_light_frame"):
		return
	_fx.begin_light_frame(_night_mix, _cosmic_age_tint)
	if _civ != null and _civ.has_method("push_lights_to_fx"):
		_civ.push_lights_to_fx(_fx)
	if _physics != null and _physics.has_method("push_lights_to_fx"):
		_physics.push_lights_to_fx(_fx)
	if _combat != null and _combat.has_method("push_lights_to_fx"):
		_combat.push_lights_to_fx(_fx)
	if _night_mix > 0.04 and _has_mouse_hover and get_viewport().gui_get_hovered_control() == null:
		_fx.push_light(_hover_world_pos, float(_brush_radius) * 1.45, Color(0.45, 0.85, 1.0, 1.0), 0.72)
	_fx.end_light_frame()


func _read_wasd_dir() -> Vector2:
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move.y += 1.0
	return move


func _finish_capture() -> void:
	await RenderingServer.frame_post_draw
	var out_path := _shot_combat_path if _shot_combat_path != "" else (
		_shot_night_path if _shot_night_path != "" else (
			_shot_civ_path if _shot_civ_path != "" else (_zoom_shot_path if _zoom_shot_path != "" else _screenshot_path)
		)
	)
	if out_path != "" and not out_path.is_absolute_path() and not out_path.begins_with("res://") and not out_path.begins_with("user://"):
		out_path = ProjectSettings.globalize_path("res://" + out_path.trim_prefix("./"))
	var dir_path := out_path.get_base_dir()
	if dir_path != "":
		DirAccess.make_dir_recursive_absolute(dir_path)
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(out_path)
	if err != OK:
		push_error("Failed saving screenshot to %s: error %d" % [out_path, err])
		get_tree().quit(1)
		return
	print("SCREENSHOT_SAVED=%s" % out_path)
	get_tree().quit(0)


func _update_camera_controls(delta: float) -> void:
	if _possessing_uid >= 0:
		_cam_focus_active = false
		var p_pos: Vector2 = _physics.get_unit_follow_pos(_possessing_uid)
		if p_pos.x >= 0.0:
			var p_alpha := 1.0 - exp(-float(TUNING_KNOBS["FOLLOW_SMOOTH_RATE"]) * delta)
			_cam_base_pos = _cam_base_pos.lerp(p_pos, p_alpha)
			_clamp_camera_base()
	else:
		var move := _read_wasd_dir()
		if move != Vector2.ZERO:
			_follow_locked_unit = false
			_cam_focus_active = false
			_cam_base_pos += move.normalized() * (float(TUNING_KNOBS["PAN_SPEED"]) / maxf(_camera.zoom.x, 0.5)) * delta
			_clamp_camera_base()
		elif _follow_locked_unit and _locked_unit_uid >= 0:
			_cam_focus_active = false
			var follow_pos: Vector2 = _physics.get_unit_follow_pos(_locked_unit_uid)
			if follow_pos.x >= 0.0:
				var f_alpha := 1.0 - exp(-float(TUNING_KNOBS["FOLLOW_SMOOTH_RATE"]) * delta)
				_cam_base_pos = _cam_base_pos.lerp(follow_pos, f_alpha)
				_clamp_camera_base()
			else:
				_follow_locked_unit = false
		elif _cam_focus_active:
			var c_alpha := 1.0 - exp(-9.0 * delta)
			_cam_base_pos = _cam_base_pos.lerp(_cam_focus_target, c_alpha)
			_clamp_camera_base()
			if _cam_base_pos.distance_to(_cam_focus_target) < 0.4:
				_cam_base_pos = _cam_focus_target
				_cam_focus_active = false

	var zoom_alpha := 1.0 - exp(-float(TUNING_KNOBS["ZOOM_SMOOTH_RATE"]) * delta)
	var z := lerpf(_camera.zoom.x, _target_zoom, zoom_alpha)
	if absf(z - _target_zoom) < 0.004:
		z = _target_zoom
	_camera.zoom = Vector2(z, z)


func _clamp_camera_base() -> void:
	_cam_base_pos.x = clampf(_cam_base_pos.x, -24.0, float(_world.map_w) + 24.0)
	_cam_base_pos.y = clampf(_cam_base_pos.y, -24.0, float(_world.map_h) + 24.0)


func _is_camera_moving() -> bool:
	if _panning_rmb or _follow_locked_unit or _cam_focus_active:
		return true
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_S):
		return true
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_DOWN):
		return true
	return absf(_camera.zoom.x - _target_zoom) > 0.004


func _update_camera_shake(delta: float) -> void:
	_trauma = maxf(0.0, _trauma - float(TUNING_KNOBS["TRAUMA_DECAY"]) * delta)
	var shake := 0.0 if _is_capture_mode() else (_trauma * _trauma * lerpf(0.75, 1.0, _trauma))

	var z_cur := maxf(_camera.zoom.x, 1.0)
	var dist_to_int := absf(z_cur - roundf(z_cur))
	var is_int_zoom := dist_to_int < 0.02
	var breathe_w := 0.0 if (z_cur >= 1.9 or is_int_zoom) else smoothstep(0.015, 0.14, dist_to_int)
	if _is_capture_mode() or (not _is_camera_moving() and shake <= 0.0005 and breathe_w <= 0.001):
		_camera.position = _cam_base_pos.round()
	else:
		var b_amp := (float(TUNING_KNOBS["BREATHE_AMPLITUDE_PX"]) * breathe_w) / maxf(z_cur * 0.5, 1.0)
		var breathe := Vector2(
			sin(_elapsed_time * float(TUNING_KNOBS["BREATHE_FREQ_X"])) * b_amp,
			cos(_elapsed_time * float(TUNING_KNOBS["BREATHE_FREQ_Y"])) * b_amp * 0.75
		)
		var cam_target := _cam_base_pos + breathe
		if is_int_zoom:
			var snap_z := maxf(roundf(z_cur), 1.0)
			_camera.position = (cam_target * snap_z).round() / snap_z
		else:
			_camera.position = cam_target.round() if breathe_w <= 0.001 else cam_target

	if shake > 0.0005:
		var t_noise := _elapsed_time * float(TUNING_KNOBS["SHAKE_NOISE_SPEED"])
		var nx := _shake_noise.get_noise_2d(t_noise, 11.3)
		var ny := _shake_noise.get_noise_2d(t_noise, 47.9)
		var nr := _shake_noise.get_noise_2d(t_noise, 89.7)
		var zoom_scale := 1.0 / maxf(_camera.zoom.x * 0.45, 1.0)
		var max_off := float(TUNING_KNOBS["SHAKE_MAX_OFFSET_PX"]) * zoom_scale
		_camera.offset = Vector2(shake * max_off * nx, shake * max_off * ny)
		_camera.rotation = shake * float(TUNING_KNOBS["SHAKE_MAX_ROLL_RAD"]) * nr
	else:
		_camera.offset = Vector2.ZERO
		_camera.rotation = 0.0


func _update_fps_ema(delta: float) -> void:
	if _fps_frames_skipped < 2:
		_fps_frames_skipped += 1
		return
	var inst_fps := clampf(1.0 / maxf(delta, 0.001), 1.0, 240.0)
	_fps_ema = lerpf(_fps_ema, inst_fps, 0.12)
	_fps_accum_time += delta
	if _fps_accum_time >= float(TUNING_KNOBS["FPS_UPDATE_INTERVAL_SEC"]):
		_fps_accum_time = 0.0
		_fps_label.text = "FPS: %d" % int(round(_fps_ema))


func _set_entity_rows(header: String, detail: String, extra: String, header_col: Color) -> void:
	_entity_header_label.visible = (header != "")
	_entity_header_label.text = header
	_entity_header_label.add_theme_color_override("font_color", header_col)
	_entity_detail_label.visible = (detail != "")
	_entity_detail_label.text = detail
	_entity_extra_label.visible = (extra != "")
	_entity_extra_label.text = extra


func _format_unit_inspector(u_info: Dictionary, locked: bool) -> void:
	var uid := int(u_info.get("uid", -1))
	if uid >= 0:
		_last_inspect_unit_uid = uid
	var fac := int(u_info.get("faction", 255))
	var f_col: Color = FACTION_RETICLE_COLORS[fac] if (fac >= 0 and fac < FACTION_RETICLE_COLORS.size()) else Color("#E2ECF5")
	if bool(u_info.get("mutated", false)):
		f_col = Color("#D264FF")
	var tag := "[Управление] " if (uid >= 0 and uid == _possessing_uid) else ("[Слежение] " if locked else "")
	var header := "%s%s · %s" % [tag, str(u_info.get("role_name", "Юнит")), str(u_info.get("faction_name", "Скиталец"))]
	var hp := int(round(float(u_info.get("hp", 100.0))))
	var max_hp := int(round(float(u_info.get("max_hp", 100.0))))
	var detail := "HP: %d/%d · %s" % [hp, max_hp, str(u_info.get("task_name", "Idle"))]
	var cargo_amt := float(u_info.get("cargo_amount", 0.0))
	var rad_exp := float(u_info.get("rad_exposure", 0.0))
	var dodges := int(u_info.get("dodges", 0))
	var extra := ""
	if cargo_amt > 0.05:
		extra = "Груз: %s (%.1f) · Рад: %.2f" % [str(u_info.get("cargo_name", "")), cargo_amt, rad_exp]
	elif dodges > 0:
		extra = "Бой: %d · Укл: %d · Рад: %.2f" % [int(u_info.get("kills", 0)), dodges, rad_exp]
	else:
		extra = "Бой: %d · Рад: %.2f" % [int(u_info.get("kills", 0)), rad_exp]
	_set_entity_rows(header, detail, extra, f_col)

	var mem_raw: Variant = u_info.get("memory", [])
	var mem_lines: PackedStringArray = []
	if mem_raw is Array:
		var mem_arr := mem_raw as Array
		var start_idx := maxi(0, mem_arr.size() - 6)
		for idx in range(mem_arr.size() - 1, start_idx - 1, -1):
			var entry := str(mem_arr[idx]).strip_edges()
			if entry != "":
				mem_lines.append("· " + entry)
	_memory_label.visible = (not mem_lines.is_empty())
	if _memory_label.visible:
		_memory_label.text = "Память:\n" + "\n".join(mem_lines)
	_btn_possess.visible = (uid >= 0 or _possessing_uid >= 0)
	_btn_possess.button_pressed = (_possessing_uid >= 0 and _possessing_uid == uid)
	_btn_possess.text = "Выйти [Esc]" if _btn_possess.button_pressed else "Взять управление [P]"


func _format_city_inspector(c_info: Dictionary, locked: bool) -> void:
	_btn_possess.visible = (_possessing_uid >= 0)
	var fac := clampi(int(c_info.get("faction", 0)), 0, FACTION_RETICLE_COLORS.size() - 1)
	var f_col: Color = FACTION_RETICLE_COLORS[fac]
	var is_rebel := bool(c_info.get("is_rebel", false))
	if is_rebel:
		f_col = Color("#FF9B26")
	var tag := "[Город] " if locked else ""
	var rebel_tag := "[МЯТЕЖ] " if is_rebel else ""
	var header := "%s%s%s (%s) · Т%d/4" % [
		tag,
		rebel_tag,
		str(c_info.get("name", "Колония")),
		str(c_info.get("faction_name", "Люди")),
		int(c_info.get("tech_tier", 0)),
	]
	var raw_state := str(c_info.get("state", "Thriving"))
	var ru_state := str(STATE_NAMES_RU.get(raw_state, raw_state))
	var proj := str(c_info.get("project", "None"))
	var state_tail := "%s: %s" % [ru_state, proj] if (raw_state == "Constructing" and proj != "None") else ru_state
	var detail := "Нас: %d/%d · Зд: %d · %s" % [
		int(c_info.get("pop", 0)),
		int(c_info.get("housing_cap", 0)),
		int(c_info.get("buildings", 0)),
		state_tail,
	]
	var war_state := int(c_info.get("war_state", 0))
	var war_partners := int(c_info.get("war_partners", -1))
	var pact_partners := int(c_info.get("pact_partners", -1))
	var diplo_name := "Мятежник" if is_rebel else (
		"Война" if (war_partners > 0 or war_state >= 2) else (
			"Пакт" if (pact_partners > 0 or war_state == 1) else "Мир"
		)
	)
	if war_partners >= 0 or pact_partners >= 0:
		diplo_name += "(В:%d П:%d)" % [maxi(war_partners, 0), maxi(pact_partners, 0)]
	var loyalty := int(round(float(c_info.get("loyalty", 100.0))))
	var loy_reason := str(c_info.get("loyalty_reason", "")).strip_edges()
	var loy_str := "%d%%" % loyalty
	if loy_reason != "" and loy_reason != "Мятеж":
		loy_str += " (%s)" % loy_reason
	var gates := int(c_info.get("quantum_gates", 0))
	var extra := "Дип: %s · Лоял: %s · Врата: %d" % [diplo_name, loy_str, gates]
	_set_entity_rows(header, detail, extra, f_col)

	var res_line := "Еда:%d Руд:%d Эн:%d Нау:%d" % [
		int(round(float(c_info.get("food", 0.0)))),
		int(round(float(c_info.get("ore", 0.0)))),
		int(round(float(c_info.get("energy", 0.0)))),
		int(round(float(c_info.get("science", 0.0)))),
	]
	if c_info.has("energy_net"):
		res_line += " · ΔЭ:%+.1f" % float(c_info.get("energy_net", 0.0))
	var emp_t := float(c_info.get("emp_timer", 0.0))
	if emp_t > 0.05:
		res_line += " · ЭМИ: %.1fс" % emp_t
	_memory_label.visible = true
	_memory_label.text = res_line


func _update_hud_telemetry() -> void:
	var units: int = _physics.get_unit_count()
	var flora: int = _physics.get_flora_count()
	var avg_temp: float = _world.get_avg_temp()
	var civ_stats: Dictionary = _civ.get_civ_stats()
	var cities: int = int(civ_stats.get("cities", 0))
	var tech_tier: int = maxi(int(civ_stats.get("max_tech_tier", 0)), int(civ_stats.get("tech_tier", 0)))
	var wars_active: int = int(civ_stats.get("wars_active", 0))
	var rebels_total: int = int(civ_stats.get("rebellions_total", 0))
	_colonists_label.text = "Юниты: %d" % units
	_cities_label.text = "Города: %d" % cities
	_tech_label.text = "Тех: %d/4" % tech_tier
	_wars_label.text = "Войн: %d · М:%d" % [wars_active, rebels_total]
	if wars_active > 0:
		_wars_label.add_theme_color_override("font_color", Color("#FF7474"))
	elif rebels_total > 0:
		_wars_label.add_theme_color_override("font_color", Color("#FF9B26"))
	else:
		_wars_label.add_theme_color_override("font_color", Color("#E2ECF5"))
	_flora_label.text = "Флора: %d" % flora
	_temp_label.text = "Темп: %s%.1f°C" % ["+" if avg_temp >= 0.0 else "", avg_temp]

	var probe_pos := _hover_world_pos if (_has_mouse_hover or _is_capture_mode()) else _cam_base_pos
	var entity_shown := false

	if _locked_unit_uid >= 0:
		var u_locked: Dictionary = _physics.inspect_unit_by_id(_locked_unit_uid)
		if bool(u_locked.get("found", false)):
			var locked_u_pos: Vector2 = u_locked.get("pos", probe_pos)
			probe_pos = locked_u_pos
			_format_unit_inspector(u_locked, true)
			entity_shown = true
		else:
			_locked_unit_uid = -1
			_follow_locked_unit = false
	elif _locked_city_id >= 0:
		var c_locked: Dictionary = _civ.inspect_city_at(_locked_city_pos)
		if bool(c_locked.get("found", false)) and int(c_locked.get("city_id", -1)) == _locked_city_id:
			var locked_c_pos: Vector2 = c_locked.get("center", _locked_city_pos)
			_locked_city_pos = locked_c_pos
			probe_pos = _locked_city_pos
			_format_city_inspector(c_locked, true)
			entity_shown = true
		else:
			_locked_city_id = -1

	if not entity_shown:
		var c_hover: Dictionary = _civ.inspect_city_at(probe_pos)
		var in_hover_city := bool(c_hover.get("found", false))
		var u_hover: Dictionary = {}
		if not _is_capture_mode():
			u_hover = _physics.inspect_unit_at(probe_pos)
		var u_found := bool(u_hover.get("found", false))
		var u_hover_pos: Vector2 = u_hover.get("pos", probe_pos)
		var u_pick_r := 4.5 if in_hover_city else 7.0
		var u_close := u_found and u_hover_pos.distance_to(probe_pos) <= u_pick_r
		if u_close:
			_format_unit_inspector(u_hover, false)
			entity_shown = true
		else:
			if in_hover_city:
				_format_city_inspector(c_hover, false)
				entity_shown = true
			elif bool(c_hover.get("ruin_found", false)):
				var r_header := "Руины колонии"
				var r_detail := "Залежи: +%.0f Руды · +%.0f Науки" % [
					float(c_hover.get("ruin_ore", 0.0)),
					float(c_hover.get("ruin_science", 0.0)),
				]
				_memory_label.visible = false
				_btn_possess.visible = (_possessing_uid >= 0)
				_set_entity_rows(r_header, r_detail, "", Color("#F0B121"))
				entity_shown = true
			elif u_found:
				_format_unit_inspector(u_hover, false)
				entity_shown = true

	if not entity_shown:
		_set_entity_rows("", "", "", Color("#7CE7FF"))
		var hovering_hud := get_viewport().gui_get_hovered_control() != null
		if _possessing_uid < 0 and _locked_unit_uid < 0 and not hovering_hud:
			_last_inspect_unit_uid = -1
			_memory_label.visible = false
			_btn_possess.visible = false

	var info: Dictionary = _world.get_tile_info(probe_pos)
	if bool(info.get("in_bounds", false)):
		var biome_name := str(info.get("biome_name", "—"))
		var tier_name := str(info.get("tier_name", "—"))
		var temp_val := float(info.get("temp", 0.0))
		var rad_val := float(info.get("rad", 0.0))
		var fire_val := float(info.get("fire", 0.0))
		var ash_val := float(info.get("ash", 0.0))
		var env_tag := ""
		if fire_val > 0.05:
			env_tag = " · Огонь"
		elif ash_val > 0.25:
			env_tag = " · Пепел"
		_loc_label.text = "Биом: %s · %s" % [biome_name, tier_name]
		_metrics_label.text = "Темп: %s%.1f°C · Рад: %.2f%s" % ["+" if temp_val >= 0.0 else "", temp_val, rad_val, env_tag]
	else:
		_loc_label.text = "Сектор: Орбита"
		_metrics_label.text = "Вне границ планеты"

	_sync_inspector_layout()


func _draw_bresenham_circle(target: CanvasItem, geom: Vector3i, colors: PackedColorArray) -> void:
	var cx: int = geom.x
	var cy: int = geom.y
	var r: int = maxi(geom.z, 1)
	var rim_col: Color = colors[0] if colors.size() > 0 else Color.WHITE
	var fill_col: Color = colors[1] if colors.size() > 1 else Color(0, 0, 0, 0)
	if fill_col.a > 0.005:
		var r2 := r * r
		for dy in range(-r, r + 1):
			var hw := int(floor(sqrt(float(maxi(0, r2 - dy * dy)))))
			target.draw_rect(Rect2(float(cx - hw), float(cy + dy), float(hw * 2 + 1), 1.0), fill_col, true)

	var x := 0
	var y := r
	var d := 1 - r
	while x <= y:
		_plot_circle_octants(target, Vector3i(cx, cy, x), Vector2i(y, 0), rim_col)
		x += 1
		if d < 0:
			d += 2 * x + 1
		else:
			y -= 1
			d += 2 * (x - y) + 1


func _plot_circle_octants(target: CanvasItem, origin_x: Vector3i, y_pad: Vector2i, col: Color) -> void:
	var cx: int = origin_x.x
	var cy: int = origin_x.y
	var x: int = origin_x.z
	var y: int = y_pad.x
	target.draw_rect(Rect2(float(cx + x), float(cy + y), 1.0, 1.0), col, true)
	if x != 0:
		target.draw_rect(Rect2(float(cx - x), float(cy + y), 1.0, 1.0), col, true)
	if y != 0:
		target.draw_rect(Rect2(float(cx + x), float(cy - y), 1.0, 1.0), col, true)
	if x != 0 and y != 0:
		target.draw_rect(Rect2(float(cx - x), float(cy - y), 1.0, 1.0), col, true)
	if x != y:
		target.draw_rect(Rect2(float(cx + y), float(cy + x), 1.0, 1.0), col, true)
		if y != 0:
			target.draw_rect(Rect2(float(cx - y), float(cy + x), 1.0, 1.0), col, true)
		if x != 0:
			target.draw_rect(Rect2(float(cx + y), float(cy - x), 1.0, 1.0), col, true)
		if x != 0 and y != 0:
			target.draw_rect(Rect2(float(cx - y), float(cy - x), 1.0, 1.0), col, true)


func _on_world_overlay_draw() -> void:
	if _smoke_mode or _smoke_civ_mode or _smoke_combat_mode or _smoke_worldbox_pace_mode:
		return
	var zoom_x := maxf(_camera.zoom.x, 1.0)
	_draw_overlay_diplo_arcs(zoom_x)
	_draw_overlay_capture_bars(zoom_x)
	_draw_overlay_shields()
	_draw_overlay_army_banners()
	_draw_overlay_active_plots()
	_draw_overlay_possession_ring()


func _draw_overlay_diplo_arcs(zoom_x: float) -> void:
	var show_diplo_arcs := (_camera.zoom.x <= 1.8) or (_current_brush == BRUSH_DIPLO_SPARK)
	if not show_diplo_arcs or _civ == null or not _civ.has_method("get_diplomacy_links"):
		return
	var arc_w := clampf(1.45 / zoom_x, 0.45, 0.95)
	var links: Array = _civ.get_diplomacy_links()
	for idx in range(links.size()):
		var raw_l: Variant = links[idx]
		if not (raw_l is Dictionary):
			continue
		var lnk: Dictionary = raw_l
		var st := int(lnk.get("state", 0))
		if st <= 0:
			continue
		var pa: Vector2 = lnk.get("pos_a", Vector2.ZERO)
		var pb: Vector2 = lnk.get("pos_b", Vector2.ZERO)
		var diff := pb - pa
		var dist := diff.length()
		if dist < 8.0:
			continue
		var perp := Vector2(-diff.y, diff.x) / dist
		var lift := minf(dist * 0.16, 18.0)
		if st == 1:
			lift = -lift * 0.75
		var ctrl := (pa + pb) * 0.5 + perp * lift
		var pulse := 0.5 + 0.5 * sin(_elapsed_time * 3.8 + float(idx) * 1.1)
		var col := Color(0.28, 0.90, 1.0, 0.22 + 0.12 * pulse)
		if st == 2:
			col = Color(1.0, 0.24, 0.28, 0.30 + 0.24 * pulse)
		elif st == 3:
			var rebel_mix := 0.5 + 0.5 * sin(_elapsed_time * 5.2 + float(idx))
			col = Color("#FF9B26").lerp(Color("#FFE156"), rebel_mix)
			col.a = 0.34 + 0.24 * pulse

		var segs := 10
		var prev := pa
		for s in range(1, segs + 1):
			var t := float(s) / float(segs)
			var u := 1.0 - t
			var pt := (u * u) * pa + (2.0 * u * t) * ctrl + (t * t) * pb
			if st != 1 or (s % 2) == 1:
				_world_overlay.draw_line(prev, pt, col, arc_w, false)
			prev = pt

		if st >= 2:
			var pt_t := fmod(_elapsed_time * 0.42 + float(idx) * 0.31, 1.0)
			var u_p := 1.0 - pt_t
			var pip := ((u_p * u_p) * pa + (2.0 * u_p * pt_t) * ctrl + (pt_t * pt_t) * pb).round()
			_world_overlay.draw_rect(Rect2(pip - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(col.r, col.g, col.b, minf(col.a + 0.3, 0.92)), true)


func _draw_overlay_capture_bars(zoom_x: float) -> void:
	if _civ == null or not _civ.has_method("get_contested_capture_spots"):
		return
	var spots: Array = _civ.get_contested_capture_spots()
	for raw_s in spots:
		if not (raw_s is Dictionary):
			continue
		var spot: Dictionary = raw_s
		var prog := clampf(float(spot.get("progress", 0.0)), 0.0, 1.0)
		if prog <= 0.01:
			continue
		var spos: Vector2 = spot.get("pos", Vector2.ZERO)
		var scol: Color = spot.get("color", Color("#FF9B26"))
		var bar_w := 6.0
		var bar_h := clampf(2.6 / zoom_x, 0.9, 1.5)
		var bpos := (spos + Vector2(-bar_w * 0.5, -4.0)).round()
		_world_overlay.draw_rect(Rect2(bpos - Vector2(0.5, 0.5), Vector2(bar_w + 1.0, bar_h + 1.0)), Color(0.03, 0.05, 0.09, 0.72), true)
		_world_overlay.draw_rect(Rect2(bpos, Vector2(bar_w * prog, bar_h)), Color(scol.r, scol.g, scol.b, 0.92), true)


func _draw_overlay_shields() -> void:
	if _civ == null or not _civ.has_method("get_shield_pylons"):
		return
	var pylons: Array = _civ.get_shield_pylons()
	for raw_p in pylons:
		if not (raw_p is Dictionary):
			continue
		var pylon: Dictionary = raw_p
		var charge := float(pylon.get("charge", 1.0))
		var flash := float(pylon.get("flash", 0.0))
		if charge <= 0.01 and flash <= 0.01:
			continue
		var pos: Vector2 = pylon.get("pos", Vector2.ZERO)
		var rad := maxi(int(round(float(pylon.get("radius", 48.0)))), 8)
		var pulse := 0.85 + 0.15 * sin(_elapsed_time * 3.4 + pos.x * 0.07)
		var rim_a := clampf((0.24 + 0.54 * flash) * pulse * clampf(charge + 0.30, 0.0, 1.0), 0.14, 0.88)
		var rim_col := Color(0.32, 0.94, 1.0, rim_a)
		var fill_col := Color(0.24, 0.88, 1.0, rim_a * 0.05)
		_draw_bresenham_circle(_world_overlay, Vector3i(int(round(pos.x)), int(round(pos.y)), rad), PackedColorArray([rim_col, fill_col]))


func _draw_overlay_possession_ring() -> void:
	if _possessing_uid < 0 or _physics == null:
		return
	var p_pos: Vector2 = _physics.get_unit_follow_pos(_possessing_uid)
	if p_pos.x < 0.0:
		return
	var cx := int(round(p_pos.x))
	var cy := int(round(p_pos.y))
	var ring_r := maxi(int(round(5.5 + 0.8 * sin(_elapsed_time * 6.0))), 4)
	_draw_bresenham_circle(_world_overlay, Vector3i(cx, cy, ring_r), PackedColorArray([Color("#45E9FF")]))
	_draw_bresenham_circle(_world_overlay, Vector3i(cx, cy, ring_r + 2), PackedColorArray([Color(1.0, 0.88, 0.35, 0.72)]))


func _draw_overlay_army_banners() -> void:
	if _physics == null or not _physics.has_method("get_army_banners"):
		return
	var banners: Array = _physics.get_army_banners()
	if banners.is_empty():
		return
	var edge_col := Color("#1C2738")
	var pole_col := Color("#DCE4EE")
	var finial_col := Color("#FFD84A")
	var wave := int(floor(_elapsed_time * 4.0)) % 2
	for raw_b in banners:
		if not (raw_b is Dictionary):
			continue
		var b: Dictionary = raw_b
		var bpos: Vector2 = b.get("pos", Vector2.ZERO)
		var bx := int(round(bpos.x))
		var by := int(round(bpos.y))
		var fac := clampi(int(b.get("faction", 0)), 0, FACTION_RETICLE_COLORS.size() - 1)
		var col: Color = b.get("color", FACTION_RETICLE_COLORS[fac])
		var shade_col := col.darkened(0.32)
		var cnt := int(b.get("count", 1))
		_world_overlay.draw_rect(Rect2(float(bx - 2), float(by - 11), 1.0, 1.0), finial_col, true)
		_world_overlay.draw_rect(Rect2(float(bx - 2), float(by - 10), 1.0, 9.0), pole_col, true)
		_world_overlay.draw_rect(Rect2(float(bx - 2), float(by - 1), 1.0, 1.0), edge_col, true)
		_world_overlay.draw_rect(Rect2(float(bx - 1), float(by - 10), 4.0, 1.0), edge_col, true)
		_world_overlay.draw_rect(Rect2(float(bx - 1), float(by - 6), 4.0, 1.0), edge_col, true)
		_world_overlay.draw_rect(Rect2(float(bx - 1), float(by - 9), 4.0, 2.0), col, true)
		_world_overlay.draw_rect(Rect2(float(bx - 1), float(by - 7), 4.0, 1.0), shade_col, true)
		_world_overlay.draw_rect(Rect2(float(bx + 3), float(by - 9 + wave), 1.0, 2.0), col, true)
		if cnt >= 4:
			var bar_w := clampi(cnt / 2, 2, 6)
			_world_overlay.draw_rect(Rect2(float(bx - 2), float(by + 1), float(bar_w), 1.0), finial_col, true)


func _draw_overlay_active_plots() -> void:
	if _civ == null or not _civ.has_method("get_active_plots"):
		return
	var plots: Array = _civ.get_active_plots()
	if plots.is_empty():
		return
	var edge := Color("#101824")
	for raw_p in plots:
		if not (raw_p is Dictionary):
			continue
		var p: Dictionary = raw_p
		var pos: Vector2 = p.get("pos", Vector2.ZERO)
		var kind := str(p.get("kind", "war")).to_lower()
		var prog := clampf(float(p.get("progress", 0.0)), 0.0, 1.0)
		var ox := int(round(pos.x)) - 4
		var oy := int(round(pos.y)) - 19
		var accent := Color("#FF4646") if kind == "war" else (Color("#FF9B26") if kind == "rebel" else Color("#46E5FF"))
		_world_overlay.draw_rect(Rect2(float(ox), float(oy), 8.0, 7.0), Color(0.06, 0.09, 0.14, 0.85), true)
		_world_overlay.draw_rect(Rect2(float(ox), float(oy), 8.0, 1.0), accent, true)
		if kind == "war":
			for k in range(5):
				_world_overlay.draw_rect(Rect2(float(ox + 1 + k), float(oy + 1 + k), 1.0, 1.0), Color("#FFD84A") if k == 2 else accent, true)
				_world_overlay.draw_rect(Rect2(float(ox + 6 - k), float(oy + 1 + k), 1.0, 1.0), Color("#FFD84A") if k == 2 else accent, true)
		elif kind == "rebel":
			_world_overlay.draw_rect(Rect2(float(ox + 3), float(oy + 1), 2.0, 3.0), Color("#FFE156"), true)
			_world_overlay.draw_rect(Rect2(float(ox + 2), float(oy + 4), 4.0, 2.0), accent, true)
		else:
			_world_overlay.draw_rect(Rect2(float(ox + 1), float(oy + 2), 3.0, 3.0), accent, false)
			_world_overlay.draw_rect(Rect2(float(ox + 4), float(oy + 2), 3.0, 3.0), Color("#FFD15C"), false)
		_world_overlay.draw_rect(Rect2(float(ox), float(oy + 8), 8.0, 2.0), edge, true)
		var fill_w := int(round(prog * 8.0))
		if fill_w > 0:
			_world_overlay.draw_rect(Rect2(float(ox), float(oy + 8), float(fill_w), 1.0), accent, true)


func _collect_kingdom_badges() -> Array[Dictionary]:
	var raw_badges: Array = _civ.get_macro_badges()
	var grouped: Dictionary = {}
	var ordered: Array[Dictionary] = []
	for raw_b in raw_badges:
		if not (raw_b is Dictionary):
			continue
		var b: Dictionary = raw_b
		var kid := int(b.get("kingdom_id", -1))
		if kid < 0:
			ordered.append(b)
			continue
		if not grouped.has(kid):
			var fac := clampi(int(b.get("faction", 0)), 0, 2)
			var kname := str(b.get("kingdom_name", b.get("name", FACTION_NAMES_RU[fac])))
			var entry := {
				"kingdom_id": kid,
				"name": kname,
				"pos": b.get("pos", Vector2.ZERO),
				"pop": int(b.get("total_pop", b.get("pop", 0))),
				"weight_sum": maxf(float(b.get("pop", 1)), 1.0),
				"pos_sum": Vector2(b.get("pos", Vector2.ZERO)) * maxf(float(b.get("pop", 1)), 1.0),
				"faction": fac,
				"color": b.get("color", FACTION_RETICLE_COLORS[fac]),
				"is_rebel": bool(b.get("is_rebel", false)),
				"war_state": int(b.get("war_state", 0)),
				"cities_count": int(b.get("cities_count", 1)),
				"pre_grouped": b.has("total_pop") or b.has("cities_count") or b.has("kingdom_name"),
			}
			grouped[kid] = entry
			ordered.append(entry)
		else:
			var existing: Dictionary = grouped[kid]
			if bool(existing.get("pre_grouped", false)):
				continue
			var p_add := int(b.get("pop", 0))
			var w_add := maxf(float(p_add), 1.0)
			existing["pop"] = int(existing["pop"]) + p_add
			existing["weight_sum"] = float(existing["weight_sum"]) + w_add
			existing["pos_sum"] = Vector2(existing["pos_sum"]) + Vector2(b.get("pos", Vector2.ZERO)) * w_add
			existing["pos"] = Vector2(existing["pos_sum"]) / float(existing["weight_sum"])
			existing["war_state"] = maxi(int(existing["war_state"]), int(b.get("war_state", 0)))
	return ordered


func _draw_pixel_crown(canvas: CanvasItem, origin: Vector2, col: Color) -> void:
	var x := roundf(origin.x)
	var y := roundf(origin.y)
	canvas.draw_rect(Rect2(x, y, 1.0, 4.0), col, true)
	canvas.draw_rect(Rect2(x + 3.0, y, 1.0, 4.0), col, true)
	canvas.draw_rect(Rect2(x + 6.0, y, 1.0, 4.0), col, true)
	canvas.draw_rect(Rect2(x, y + 2.0, 7.0, 2.0), col, true)
	canvas.draw_rect(Rect2(x, y + 4.0, 7.0, 1.0), col.darkened(0.30), true)


func _on_macro_badges_draw() -> void:
	if _smoke_mode or _smoke_civ_mode or _smoke_combat_mode or _smoke_worldbox_pace_mode or _camera.zoom.x > 2.6:
		return
	if _civ == null or not _civ.has_method("get_macro_badges"):
		return
	var badges := _collect_kingdom_badges()
	if badges.is_empty():
		return
	var font := ThemeDB.fallback_font
	var xform := get_viewport().get_canvas_transform()
	var offset_y := clampf(-12.0 - _camera.zoom.x * 4.0, -28.0, -18.0)
	for b in badges:
		var wpos: Vector2 = b.get("pos", Vector2.ZERO)
		var sp := (xform * wpos + Vector2(0.0, offset_y)).round()
		if sp.x < 42.0 or sp.x > 1238.0 or sp.y < 52.0 or sp.y > 650.0:
			continue
		var fac := clampi(int(b.get("faction", 0)), 0, 2)
		var col: Color = b.get("color", FACTION_RETICLE_COLORS[fac])
		if bool(b.get("is_rebel", false)):
			col = Color("#FF9B26")
		elif int(b.get("war_state", 0)) >= 2:
			col = Color("#FF4A4A")
		var k_name := str(b.get("name", b.get("kingdom_name", FACTION_NAMES_RU[fac])))
		var pop := int(b.get("pop", b.get("total_pop", 0)))
		var label_txt := "%s · %d" % [k_name, pop]
		var txt_sz := font.get_string_size(label_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		var pill_w := roundf(txt_sz.x + 20.0)
		var pill_h := 16.0
		var rect := Rect2(roundf(sp.x - pill_w * 0.5), roundf(sp.y - pill_h * 0.5), pill_w, pill_h)
		_macro_badges.draw_rect(rect, Color(0.047, 0.078, 0.125, 0.84), true)
		_macro_badges.draw_rect(rect, Color(col.r, col.g, col.b, 0.88), false, 1.0)
		_draw_pixel_crown(_macro_badges, Vector2(rect.position.x + 5.0, rect.position.y + 5.0), col.lightened(0.25))
		_macro_badges.draw_string(font, Vector2(rect.position.x + 15.0, rect.position.y + 12.0), label_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#E7F3FF"))


func _on_reticle_draw() -> void:
	if _smoke_mode or _smoke_civ_mode or _smoke_combat_mode or _smoke_worldbox_pace_mode or _is_capture_mode() or not _has_mouse_hover:
		return
	if _possessing_uid >= 0:
		return
	if get_viewport().gui_get_hovered_control() != null:
		return
	if _hover_world_pos.x < 0.0 or _hover_world_pos.y < 0.0 or _hover_world_pos.x >= float(_world.map_w) or _hover_world_pos.y >= float(_world.map_h):
		return

	var cx := int(floor(_hover_world_pos.x))
	var cy := int(floor(_hover_world_pos.y))
	var shift_held := Input.is_key_pressed(KEY_SHIFT)

	if _current_brush == BRUSH_INSPECT:
		var insp_col := Color(0.88, 0.94, 1.0, 0.85)
		for d_v in [-4, -3, 3, 4]:
			var d: int = int(d_v)
			_reticle.draw_rect(Rect2(float(cx + d), float(cy), 1.0, 1.0), insp_col, true)
			_reticle.draw_rect(Rect2(float(cx), float(cy + d), 1.0, 1.0), insp_col, true)
		_reticle.draw_rect(Rect2(float(cx), float(cy), 1.0, 1.0), Color("#7CE7FF"), true)
		return

	var rim_col := Color(0.35, 0.90, 1.0, 0.82)
	var fill_alpha := 0.11
	var r := _brush_radius
	if _current_brush == BRUSH_COLONY:
		var f_col: Color = FACTION_RETICLE_COLORS[posmod(_selected_faction, FACTION_RETICLE_COLORS.size())]
		rim_col = Color(f_col.r, f_col.g, f_col.b, 0.90)
		fill_alpha = 0.16
		r = 8 if shift_held else _brush_radius
	elif _current_brush == BRUSH_BLESS:
		rim_col = Color("#C855FF") if shift_held else Color("#FFD857")
		rim_col.a = 0.88
		fill_alpha = 0.14
	elif _current_brush == BRUSH_ORBITAL_STRIKE:
		rim_col = Color("#FFD15C")
		rim_col.a = 0.92
		fill_alpha = 0.15
	elif _current_brush == BRUSH_DIPLO_SPARK:
		rim_col = Color("#FF9B26") if shift_held else Color("#FF4C5B")
		rim_col.a = 0.90
		fill_alpha = 0.14
		r = 10
	elif _current_brush == BRUSH_STORM_RAIN:
		rim_col = Color(0.30, 0.83, 1.0, 0.88)
	elif _current_brush == BRUSH_STORM_FIRE:
		rim_col = Color(1.0, 0.48, 0.18, 0.88)
	elif _current_brush == BRUSH_STORM_ION:
		rim_col = Color(0.28, 0.95, 1.0, 0.92)
		fill_alpha = 0.14
	elif _current_brush == BRUSH_AI_GLITCH:
		rim_col = Color(1.0, 0.28, 0.43, 0.90)
		fill_alpha = 0.14
	elif _current_brush == BRUSH_XENO_VIRUS:
		rim_col = Color(0.72, 0.30, 1.0, 0.90)
		fill_alpha = 0.14
	elif _current_brush == BRUSH_BIO_SEEDER:
		rim_col = Color(0.41, 0.94, 0.47, 0.90)
		fill_alpha = 0.14
	elif _current_brush == BRUSH_CANAL:
		rim_col = Color("#42A3D1")
		rim_col.a = 0.86
	elif _current_brush == WorldTerrainScript.BrushMode.TERRAFORM_LIFE:
		rim_col = Color("#42A3D1") if shift_held else Color("#59E072")
		rim_col.a = 0.84
	elif _current_brush == WorldTerrainScript.BrushMode.LAVA_VOLCANO or _current_brush == WorldTerrainScript.BrushMode.METEOR_CRATER:
		rim_col = Color(0.98, 0.55, 0.24, 0.86)
	elif _current_brush == WorldTerrainScript.BrushMode.VORTEX_PULL:
		var elem: String = str(_world.sample_dominant_element(_hover_world_pos, float(_brush_radius))) if _world.has_method("sample_dominant_element") else "earth"
		if elem == "lava" or elem == "fire":
			rim_col = Color(1.0, 0.52, 0.18, 0.88)
		elif elem == "water":
			rim_col = Color(0.36, 0.86, 1.0, 0.88)
		elif elem == "crystal":
			rim_col = Color(0.55, 0.95, 1.0, 0.90)
		else:
			rim_col = Color(0.62, 0.72, 1.0, 0.84)

	var fill_col := Color(rim_col.r, rim_col.g, rim_col.b, fill_alpha)
	_draw_bresenham_circle(_reticle, Vector3i(cx, cy, r), PackedColorArray([rim_col, fill_col]))
	_reticle.draw_rect(Rect2(float(cx), float(cy), 1.0, 1.0), rim_col, true)
	_reticle.draw_rect(Rect2(float(cx - 1), float(cy), 1.0, 1.0), rim_col, true)
	_reticle.draw_rect(Rect2(float(cx + 1), float(cy), 1.0, 1.0), rim_col, true)
	_reticle.draw_rect(Rect2(float(cx), float(cy - 1), 1.0, 1.0), rim_col, true)
	_reticle.draw_rect(Rect2(float(cx), float(cy + 1), 1.0, 1.0), rim_col, true)
