extends Node2D
class_name CivSim

## Civilization simulation core: 8x8 TileZones, water-clipped chamfered 1px borders
## with dark backing, steel-railed dirt/conduit roads, 3 asymmetric factions,
## worker-driven construction with scaffolds, failure-forward ruins/meltdowns,
## archipelago shuttles, border clashes, and city inspection.

const UNIT_SPRITE_SHADER := preload("res://shaders/unit_sprite.gdshader")
const BUILDINGS_ATLAS_PATH := "res://assets/atlases/buildings_atlas.png"
const BUILDINGS_MASK_PATH := "res://assets/atlases/buildings_atlas_mask.png"

const TUNING_KNOBS := {
	"MAP_WIDTH": 640,
	"MAP_HEIGHT": 360,
	"TILE_ZONE_PX": 8,
	"MAX_CITIES": 64,
	"MAX_BUILDINGS": 512,
	"MAX_CITY_BUILDINGS": 32,
	"MAX_RUINS": 64,
	"MAX_SHUTTLES": 32,
	"START_CITY_POP": 16,
	"MAX_PLANET_UNITS": 2500,
	"MIN_CITY_SPACING_PX": 48.0,
	"TIER_DUP_DIMINISH_COUNT": 3,
	"DUP_MID_WEIGHT": 0.25,
	"BORDER_TINT_ALPHA": 0.11,
	"BORDER_LINE_ALPHA": 0.90,
	"BORDER_BACKING_ALPHA": 0.84,
	"CONDUIT_VEIN_LUMINANCE": 0.55,
	"BORDER_CLASH_DIST_PX": 88.0,
	"BASE_STORAGE_CAP": 200.0,
	"DEPOT_STORAGE_BONUS": 150.0,
	"LAUNCHPAD_STORAGE_BONUS": 300.0,
	"FIRST_EXPAND_DELAY_SEC": 0.50,
	"ZONE_EXPAND_INTERVAL_SEC": 1.25,
	"ZONE_EXPAND_COST_ORE": 3.0,
	"POP_GROWTH_INTERVAL_SEC": 4.5,
	"POP_GROWTH_FOOD_COST": 10.0,
	"SPRING_OMEGA": 18.0,
	"SPRING_ZETA": 0.25,
	"DOME_PROTECTION_RADIUS": 18.0,
	"REACTOR_MELTDOWN_RADIUS": 12.0,
	"SHUTTLE_HOP_MIN_DIST_PX": 42.0,
	"SHUTTLE_HOP_MAX_DIST_PX": 185.0,
	"SHUTTLE_LAUNCH_ORE": 12.0,
	"SHUTTLE_LAUNCH_ENERGY": 8.0,
	"SHUTTLE_COOLDOWN_SEC": 10.0,
	"SHUTTLE_SPEED_PX": 34.0,
	"ROBOT_RAD_ENERGY_GAIN": 16.0,
	"SPORE_EXPAND_INTERVAL_MUL": 0.68,
	"SPORE_EXPAND_ORE_MUL": 0.65,
	"SPORE_FIRE_DMG_MUL": 2.4,
	"RUIN_SALVAGE_RADIUS_PX": 26.0,
	"SHIELD_PYLON_RADIUS_PX": 48.0,
	"SHIELD_INTERCEPT_COST": 0.35,
	"SHIELD_MIN_CHARGE": 0.25,
	"SHIELD_IMPACT_RAD_MUL": 0.35,
	"SHIELD_BASE_RECHARGE": 0.12,
	"SHIELD_FLASH_DECAY": 2.4,
	"SHADOW_GROUP_ALPHA": 0.34,
	"SHADOW_FADE_START_ZOOM": 2.2,
	"SHADOW_FADE_END_ZOOM": 1.8,
	"SHADOW_HIDE_ZOOM": 1.65,
	"SUPPLY_SCAN_SEC": 1.8,
	"SUPPLY_RICH_FOOD": 90.0,
	"SUPPLY_RICH_ORE": 75.0,
	"SUPPLY_NEED_SUM": 40.0,
	"SUPPLY_FOOD": 25.0,
	"SUPPLY_ORE": 25.0,
	"SUPPLY_ENERGY": 15.0,
	"TIER3_SCI_REQ": 420.0,
	"TIER3_SCORE_REQ": 15.0,
	"TIER4_SCI_REQ": 980.0,
	"TIER4_SCORE_REQ": 20.5,
	"QUANTUM_GATE_MAX_PER_CITY": 2,
	"QUANTUM_GATE_ENERGY_MIN": 12.0,
	"DIPLO_SCAN_SEC": 0.50,
	"DIPLO_WAR_TENSION_THRESHOLD": 35.0,
	"DIPLO_PACT_TENSION_THRESHOLD": -24.0,
	"DIPLO_WAR_COOLDOWN_SEC": 18.0,
	"WAR_CAPTURE_SCAN_SEC": 0.25,
	"WAR_ZONE_CAPTURE_SEC": 4.0,
	"REBEL_LOYALTY_THRESHOLD": 25.0,
	"REBEL_CAPITAL_DIST_PX": 140.0,
	"REBEL_LOYALTY_DECAY_PER_SEC": 1.8,
	"REBEL_LOYALTY_RECOVER_PER_SEC": 0.9,
	"EMP_GLITCH_DURATION_SEC": 8.0,
	"AI_GLITCH_LOYALTY_HIT": 42.0,
}

enum Faction {
	HUMAN = 0,
	ROBOT = 1,
	SPORE = 2,
}

enum Diplomacy {
	NEUTRAL = 0,
	PACT = 1,
	TOTAL_WAR = 2,
	REBELLION = 3,
}

enum BuildingType {
	CAMPFIRE = 0,
	TENT = 1,
	DRILL = 2,
	DEPOT = 3,
	SOLAR_ARRAY = 4,
	BIODOME = 5,
	FUSION_REACTOR = 6,
	LAUNCHPAD = 7,
	SHIELD_PYLON = 8,
	QUANTUM_GATE = 9,
}

enum ResourceType {
	FOOD = 0,
	ORE = 1,
	ENERGY = 2,
	SCIENCE = 3,
	BUILD_WORK = 4,
}

# WorldTerrain Tier/Biome mirrors (avoid cross-file class_name dependencies)
const TIER_CLOSE_OCEAN: int = 1
const TIER_SHALLOW: int = 2
const TIER_SAND: int = 3
const TIER_SOIL_LOW: int = 4
const TIER_SOIL_HIGH: int = 5
const TIER_HILLS: int = 6
const TIER_MOUNTAINS: int = 7
const TIER_SUMMIT: int = 8

const BIOME_RUST: int = 0
const BIOME_LUSH: int = 1
const BIOME_CRYSTAL: int = 2
const BIOME_SCORCHED: int = 3
const BIOME_LAVA: int = 4

const ZONE_FLAG_FARM: int = 1
const ZONE_FLAG_ROAD: int = 2
const ZONE_FLAG_BUILT: int = 4
const ZONE_FLAG_POWERED: int = 8

const ROAD_NONE: int = 0
const ROAD_DIRT: int = 1
const ROAD_CONDUIT: int = 2

const BLD_TYPE_COUNT: int = 10
const ATLAS_COLS: int = 38
const BUILDING_CELL_PX: float = 24.0
const SAVE_MAGIC: int = 0x43495632 # "CIV2"
const SAVE_VERSION: int = 5

const SHUTTLE_KIND_COLONIZE: int = 0
const SHUTTLE_KIND_SUPPLY: int = 1

const STRIP_PACT: int = 8
const STRIP_WAR: int = 9
const STRIP_REBEL: int = 10
const STRIP_PORTAL: int = 11

# buildings_atlas.png columns (matching @art_shader / @s3b_art)
const BLD_COL_RUINS: int = 17
const BLD_COL_SCAFFOLD: int = 18
const BLD_COL_SCAFFOLD_LG: int = 19
const BLD_COL_SHUTTLE: int = 32
const BLD_COL_SHUTTLE_BOOST: int = 33
const BLD_COL_BIODOME_DAMAGED: int = 13
const BLD_COL_LAUNCHPAD_EMPTY: int = 15
const BLD_COL_LAUNCHPAD_SCORCHED: int = 16
const BLD_COL_SHIELD: int = 34
const BLD_COL_SHIELD_ACTIVE: int = 35
const BLD_COL_QUANTUM_GATE: int = 36
const BLD_COL_QUANTUM_GATE_ACTIVE: int = 37

const BLD_COLS_HUMAN := [0, 1, 2, 3, 4, 5, 6, 7, BLD_COL_SHIELD, BLD_COL_QUANTUM_GATE]
const BLD_COLS_HUMAN_ALT := [8, 9, 10, 11, 12, 5, 14, 7, BLD_COL_SHIELD, BLD_COL_QUANTUM_GATE]
const BLD_COLS_ROBOT := [22, 9, 20, 21, 22, 21, 23, 24, BLD_COL_SHIELD, BLD_COL_QUANTUM_GATE]
const BLD_COLS_SPORE := [25, 27, 26, 27, 28, 29, 30, 31, BLD_COL_SHIELD, BLD_COL_QUANTUM_GATE]

const FACTION_NAMES := ["Human", "Robot", "Spore"]
const BUILDING_NAMES := ["Campfire", "Tent", "Drill", "Depot", "Solar Array", "Biodome", "Fusion Reactor", "Launchpad", "Shield Pylon", "Quantum Gate"]
const CITY_NAME_POOLS := [
	["Kepler Outpost", "Basalt Haven", "Caldera Port", "Meridian Reach", "Redoubt Seven", "Vesper Ridge", "Cinder Bay", "Atoll Station"],
	["Ferrite Node", "Grid Kiln", "Anode Basin", "Relay Array", "Quartz Matrix", "Silica Foundry", "Torus Core", "Lattice Four"],
	["Mycelia Crown", "Lichen Shelf", "Fern Hollow", "Moss Spire", "Spore Delta", "Kelp Trench", "Rhizome Crest", "Pollen Verge"],
]

const REBEL_TERRITORY_COLOR := Color("#FF9B26")
const REBEL_ACCENT_COLOR := Color("#FFE156")

const FACTION_BORDER_COLORS := [
	Color("#38F0FF"), # HUMAN
	Color("#E63B3B"), # ROBOT
	Color("#B84DFF"), # SPORE
]

const FACTION_TINT_COLORS := [
	Color("#38D8EE"), # HUMAN (<= 0.95)
	Color("#E03B3B"), # ROBOT (<= 0.95)
	Color("#A846E6"), # SPORE (<= 0.95)
]

const BLD_TECH_POINTS: Array[float] = [1.0, 1.5, 2.5, 2.5, 3.5, 4.0, 5.0, 6.0, 5.5, 7.0]
const BLD_ORE_COSTS: Array[float] = [2.0, 4.0, 7.0, 6.0, 9.0, 11.0, 14.0, 16.0, 14.0, 18.0]
const BLD_ENERGY_COSTS: Array[float] = [0.0, 0.5, 1.5, 1.2, 0.0, 2.5, 4.0, 4.0, 3.5, 8.0]
const BLD_BUILD_TIMES: Array[float] = [1.0, 1.5, 2.0, 1.7, 2.4, 2.6, 3.0, 2.8, 2.3, 2.8]
const BLD_FOOTPRINTS: Array[float] = [10.0, 13.0, 14.0, 14.0, 14.0, 18.0, 18.0, 22.0, 18.0, 18.0]
const BLD_AVOID_RADII: Array[float] = [8.0, 10.0, 10.5, 10.5, 10.5, 12.5, 12.5, 13.5, 12.0, 12.0]

var _world: Node2D = null
var _physics: Node2D = null
var _fx: Node2D = null

var _map_w: int = int(TUNING_KNOBS["MAP_WIDTH"])
var _map_h: int = int(TUNING_KNOBS["MAP_HEIGHT"])
var _zone_px: int = int(TUNING_KNOBS["TILE_ZONE_PX"])
var _zone_w: int = 80
var _zone_h: int = 45
var _zone_count: int = 3600

# Zone grid SoA (80x45 = 3600 zones)
var _zone_city_id: PackedInt32Array
var _zone_faction_id: PackedByteArray
var _zone_flags: PackedByteArray
var _zone_ore: PackedInt32Array
var _zone_fertility: PackedFloat32Array
var _zone_close_n: PackedByteArray
var _zone_land_n: PackedByteArray

# Road pixel mask (640x360) for clean dirty-rect rebuilds without extra draw calls
var _road_mask: PackedByteArray
var _road_px_count: int = 0

# Border & road overlay rendering (1 draw call)
var _border_buf: PackedByteArray
var _border_image: Image
var _border_texture: ImageTexture
var _border_sprite: Sprite2D
var _border_dirty: bool = false
var _dirty_zx0: int = 80
var _dirty_zy0: int = 45
var _dirty_zx1: int = -1
var _dirty_zy1: int = -1

# Reusable border flush scratch buffers (zero per-flush allocation)
var _tmp_own_grid: PackedInt32Array
var _tmp_eff_grid: PackedInt32Array
var _tmp_edge_grid: PackedByteArray

# Cities SoA (MAX_CITIES = 64)
var _max_cities: int = int(TUNING_KNOBS["MAX_CITIES"])
var _city_active: PackedByteArray
var _city_faction: PackedByteArray
var _city_name: PackedStringArray
var _city_center: PackedVector2Array
var _city_mine_pos: PackedVector2Array
var _city_build_pos: PackedVector2Array
var _city_patrol_pos: PackedVector2Array
var _city_threat_pos: PackedVector2Array
var _city_alerted: PackedByteArray
var _city_alert_timer: PackedFloat32Array
var _city_tech_tier: PackedByteArray
var _city_tech_score: PackedFloat32Array
var _city_color: PackedColorArray
var _city_pop: PackedInt32Array
var _city_zones_count: PackedInt32Array
var _city_food: PackedFloat32Array
var _city_ore: PackedFloat32Array
var _city_energy: PackedFloat32Array
var _city_energy_spend_acc: PackedFloat32Array
var _city_energy_net: PackedFloat32Array
var _city_science: PackedFloat32Array
var _city_storage_cap: PackedFloat32Array
var _city_expand_timer: PackedFloat32Array
var _city_pop_timer: PackedFloat32Array
var _city_shuttle_cd: PackedFloat32Array
var _city_shuttles_launched: PackedInt32Array
var _city_proj_type: PackedInt32Array
var _city_proj_prog: PackedFloat32Array
var _city_proj_work: PackedFloat32Array
var _city_proj_retry: PackedFloat32Array
var _city_tech_dirty: PackedByteArray
var _city_coastal_cache: PackedByteArray # 0=unknown, 1=inland, 2=coastal
var _city_bld_counts: PackedInt32Array # flat: city_id * BLD_TYPE_COUNT + bld_type

# Diplomacy, Rebellions & EMP SoA (MAX_CITIES = 64)
var _diplo_matrix: PackedByteArray # _max_cities * _max_cities
var _diplo_tension: PackedFloat32Array # _max_cities * _max_cities
var _diplo_pair_cd: PackedFloat32Array # _max_cities * _max_cities
var _city_loyalty: PackedFloat32Array # 0..100, default 100.0
var _city_is_rebel: PackedByteArray # 0/1
var _city_war_state: PackedByteArray # max active Diplomacy for city (0..3)
var _city_emp_timer: PackedFloat32Array # >0 disables turrets & quantum gates
var _city_war_cooldown: PackedFloat32Array
var _city_overlord: PackedInt32Array
var _city_tech_floor: PackedByteArray

# Wartime zone capture scratch & timers (3600 zones, zero per-tick allocations)
var _zone_capture_cid: PackedInt32Array
var _zone_capture_timer: PackedFloat32Array
var _zone_in_contested: PackedByteArray
var _contested_z_list: PackedInt32Array
var _contested_z_count: int = 0
var _tmp_zone_att_cid: PackedInt32Array
var _tmp_zone_att_cnt: PackedInt32Array
var _tmp_zone_def_cnt: PackedInt32Array
var _tmp_zone_att_sol: PackedByteArray
var _active_cap_zones: PackedInt32Array
var _zone_in_active_cap: PackedByteArray
var _active_cap_count: int = 0
var _tmp_frontier_contacts: PackedInt32Array

# Buildings SoA (MAX_BUILDINGS = 512), swap-removed
var _max_buildings: int = int(TUNING_KNOBS["MAX_BUILDINGS"])
var _bld_count: int = 0
var _bld_pos: PackedVector2Array
var _bld_type: PackedByteArray
var _bld_radius: PackedFloat32Array
var _bld_city_id: PackedInt32Array
var _bld_hp: PackedFloat32Array
var _bld_spring: PackedFloat32Array
var _bld_spring_vel: PackedFloat32Array
var _bld_shake: PackedFloat32Array
var _bld_phase: PackedFloat32Array
var _bld_color: PackedColorArray
var _bld_shield_charge: PackedFloat32Array
var _bld_shield_flash: PackedFloat32Array

# Ruins SoA (Failure-Forward interactive salvageable ruins), swap-removed
var _max_ruins: int = int(TUNING_KNOBS["MAX_RUINS"])
var _ruin_count: int = 0
var _ruin_pos: PackedVector2Array
var _ruin_ore: PackedFloat32Array
var _ruin_sci: PackedFloat32Array
var _ruin_faction: PackedByteArray
var _ruin_phase: PackedFloat32Array

# Shuttles SoA (Archipelago Strait-Crossing Colonizers & Supply Cargo), swap-removed
var _max_shuttles: int = int(TUNING_KNOBS["MAX_SHUTTLES"])
var _shuttle_count: int = 0
var _shuttle_start: PackedVector2Array
var _shuttle_target: PackedVector2Array
var _shuttle_pos: PackedVector2Array
var _shuttle_t: PackedFloat32Array
var _shuttle_dur: PackedFloat32Array
var _shuttle_faction: PackedByteArray
var _shuttle_src_city: PackedInt32Array
var _shuttle_trail_t: PackedFloat32Array
var _shuttle_kind: PackedByteArray
var _shuttle_target_city: PackedInt32Array

var _shadow_group: CanvasGroup
var _mm_bld_shadows: MultiMeshInstance2D
var _shadow_tex: Texture2D
var _zoom_val: float = 2.4

var _mm_buildings: MultiMeshInstance2D
var _bld_mat: ShaderMaterial
var _atlas_tex: Texture2D
var _mask_tex: Texture2D

var _goal_buffers: Dictionary = {}
var _goals_dirty: bool = true
var _bld_footprints_dirty: bool = false
var _buildings_dirty: bool = false
var _bld_anim_step: int = -1
var _goal_version: int = 0
var _pushed_goal_version: int = -1
var _last_pushed_physics: Node2D = null
var _rng := RandomNumberGenerator.new()
var _rng_seed: int = 20261114
var _sim_time: float = 0.0
var _total_harvested: float = 0.0
var _total_shuttles_launched: int = 0
var _shield_blocked_total: int = 0
var _supply_deliveries: int = 0
var _border_clash_count: int = 0
var _clash_scan_timer: float = 0.0
var _env_check_timer: float = 0.0
var _ruin_tick_timer: float = 0.0
var _shuttle_launch_timer: float = 0.0
var _supply_scan_timer: float = 0.0
var _rebellions_total: int = 0
var _diplo_scan_timer: float = 0.0
var _capture_scan_timer: float = 0.0
var _solar_mul: float = 1.0
var _crop_mul: float = 1.0
var _fire_mul: float = 1.0
var _age_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
var _age_tint_strength: float = 0.0
var _initialized: bool = false


func _ready() -> void:
	_ensure_initialized()


func _exit_tree() -> void:
	if _world != null and is_instance_valid(_world):
		var cb_rebuilt := Callable(self, "_on_world_map_rebuilt")
		if _world.has_signal("map_rebuilt") and _world.is_connected("map_rebuilt", cb_rebuilt):
			_world.disconnect("map_rebuilt", cb_rebuilt)
	_world = null
	_physics = null
	_fx = null
	_last_pushed_physics = null
	_goal_buffers.clear()

	if _border_sprite != null and is_instance_valid(_border_sprite):
		_border_sprite.texture = null
	if _mm_bld_shadows != null and is_instance_valid(_mm_bld_shadows):
		_mm_bld_shadows.texture = null
		_mm_bld_shadows.multimesh = null
	_mm_bld_shadows = null
	_shadow_group = null
	_shadow_tex = null
	if _mm_buildings != null and is_instance_valid(_mm_buildings):
		_mm_buildings.texture = null
		_mm_buildings.material = null
		_mm_buildings.multimesh = null
	if _bld_mat != null:
		_bld_mat.set_shader_parameter("mask_tex", null)
	_bld_mat = null
	_atlas_tex = null
	_mask_tex = null
	_border_texture = null
	_border_image = null


func set_rng_seed(seed_val: int) -> void:
	_rng_seed = seed_val
	_rng.seed = seed_val


func set_day_phase(phase: float, night_mix: float) -> void:
	if _bld_mat != null:
		_bld_mat.set_shader_parameter("day_phase", phase)
		_bld_mat.set_shader_parameter("night_mix", clampf(night_mix, 0.0, 1.0))


func get_faction_color(faction: int) -> Color:
	var idx: int = clampi(faction, 0, FACTION_BORDER_COLORS.size() - 1)
	return FACTION_BORDER_COLORS[idx]


func _get_city_border_color(city_id: int) -> Color:
	if city_id < 0 or city_id >= _max_cities or _city_active[city_id] == 0:
		return FACTION_BORDER_COLORS[0]
	if _city_is_rebel[city_id] != 0:
		return REBEL_TERRITORY_COLOR
	var f_id: int = clampi(int(_city_faction[city_id]), 0, FACTION_BORDER_COLORS.size() - 1)
	return FACTION_BORDER_COLORS[f_id]


func _get_city_tint_color(city_id: int) -> Color:
	if city_id < 0 or city_id >= _max_cities or _city_active[city_id] == 0:
		return FACTION_TINT_COLORS[0]
	if _city_is_rebel[city_id] != 0:
		return REBEL_TERRITORY_COLOR
	var f_id: int = clampi(int(_city_faction[city_id]), 0, FACTION_TINT_COLORS.size() - 1)
	return FACTION_TINT_COLORS[f_id]


func _are_cities_hostile(city_a: int, city_b: int) -> bool:
	if city_a < 0 or city_a >= _max_cities or city_b < 0 or city_b >= _max_cities:
		return false
	if city_a == city_b:
		return false
	if _city_active[city_a] == 0 or _city_active[city_b] == 0:
		return false
	var d_state: int = int(_diplo_matrix[city_a * _max_cities + city_b])
	return d_state == Diplomacy.TOTAL_WAR or d_state == Diplomacy.REBELLION


func _recompute_city_war_state(city_id: int) -> void:
	if city_id < 0 or city_id >= _max_cities:
		return
	if _city_active[city_id] == 0:
		_city_war_state[city_id] = Diplomacy.NEUTRAL
		return
	if _city_is_rebel[city_id] != 0:
		_city_war_state[city_id] = Diplomacy.REBELLION
		return
	var max_state: int = Diplomacy.NEUTRAL
	var row_off: int = city_id * _max_cities
	for b in range(_max_cities):
		if b == city_id or _city_active[b] == 0:
			continue
		var st: int = int(_diplo_matrix[row_off + b])
		if st == Diplomacy.REBELLION:
			st = Diplomacy.TOTAL_WAR
		if st > max_state:
			max_state = st
	_city_war_state[city_id] = max_state


func _mark_city_zones_dirty(city_id: int) -> void:
	for zy in range(_zone_h):
		for zx in range(_zone_w):
			if _get_zone_owner(zx, zy) == city_id:
				_mark_zone_dirty(zx, zy)


func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_rng.seed = _rng_seed
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_zone_px = maxi(1, int(TUNING_KNOBS["TILE_ZONE_PX"]))
	_zone_w = ceili(float(_map_w) / float(_zone_px))
	_zone_h = ceili(float(_map_h) / float(_zone_px))
	_zone_count = _zone_w * _zone_h

	_alloc_buffers()
	_build_border_layer()
	_build_shadows_layer()
	_build_buildings_layer()
	_reset_state_arrays()


func _alloc_buffers() -> void:
	_zone_city_id.resize(_zone_count)
	_zone_faction_id.resize(_zone_count)
	_zone_flags.resize(_zone_count)
	_zone_ore.resize(_zone_count)
	_zone_fertility.resize(_zone_count)
	_zone_close_n.resize(_zone_count)
	_zone_land_n.resize(_zone_count)

	var total_px: int = _map_w * _map_h
	_road_mask.resize(total_px)
	_border_buf.resize(total_px * 4)

	_city_active.resize(_max_cities)
	_city_faction.resize(_max_cities)
	_city_name.resize(_max_cities)
	_city_center.resize(_max_cities)
	_city_mine_pos.resize(_max_cities)
	_city_build_pos.resize(_max_cities)
	_city_patrol_pos.resize(_max_cities)
	_city_threat_pos.resize(_max_cities)
	_city_alerted.resize(_max_cities)
	_city_alert_timer.resize(_max_cities)
	_city_tech_tier.resize(_max_cities)
	_city_tech_score.resize(_max_cities)
	_city_color.resize(_max_cities)
	_city_pop.resize(_max_cities)
	_city_zones_count.resize(_max_cities)
	_city_food.resize(_max_cities)
	_city_ore.resize(_max_cities)
	_city_energy.resize(_max_cities)
	_city_energy_spend_acc.resize(_max_cities)
	_city_energy_net.resize(_max_cities)
	_city_science.resize(_max_cities)
	_city_storage_cap.resize(_max_cities)
	_city_expand_timer.resize(_max_cities)
	_city_pop_timer.resize(_max_cities)
	_city_shuttle_cd.resize(_max_cities)
	_city_shuttles_launched.resize(_max_cities)
	_city_proj_type.resize(_max_cities)
	_city_proj_prog.resize(_max_cities)
	_city_proj_work.resize(_max_cities)
	_city_proj_retry.resize(_max_cities)
	_city_tech_dirty.resize(_max_cities)
	_city_coastal_cache.resize(_max_cities)
	_city_bld_counts.resize(_max_cities * BLD_TYPE_COUNT)

	var matrix_sz: int = _max_cities * _max_cities
	_diplo_matrix.resize(matrix_sz)
	_diplo_tension.resize(matrix_sz)
	_diplo_pair_cd.resize(matrix_sz)
	_city_loyalty.resize(_max_cities)
	_city_is_rebel.resize(_max_cities)
	_city_war_state.resize(_max_cities)
	_city_emp_timer.resize(_max_cities)
	_city_war_cooldown.resize(_max_cities)
	_city_overlord.resize(_max_cities)
	_city_tech_floor.resize(_max_cities)

	_zone_capture_cid.resize(_zone_count)
	_zone_capture_timer.resize(_zone_count)
	_zone_in_contested.resize(_zone_count)
	_contested_z_list.resize(_zone_count)
	_tmp_zone_att_cid.resize(_zone_count)
	_tmp_zone_att_cnt.resize(_zone_count)
	_tmp_zone_def_cnt.resize(_zone_count)
	_tmp_zone_att_sol.resize(_zone_count)
	_active_cap_zones.resize(_zone_count)
	_zone_in_active_cap.resize(_zone_count)
	_tmp_frontier_contacts.resize(matrix_sz)

	_bld_pos.resize(_max_buildings)
	_bld_type.resize(_max_buildings)
	_bld_radius.resize(_max_buildings)
	_bld_city_id.resize(_max_buildings)
	_bld_hp.resize(_max_buildings)
	_bld_spring.resize(_max_buildings)
	_bld_spring_vel.resize(_max_buildings)
	_bld_shake.resize(_max_buildings)
	_bld_phase.resize(_max_buildings)
	_bld_color.resize(_max_buildings)
	_bld_shield_charge.resize(_max_buildings)
	_bld_shield_flash.resize(_max_buildings)

	_ruin_pos.resize(_max_ruins)
	_ruin_ore.resize(_max_ruins)
	_ruin_sci.resize(_max_ruins)
	_ruin_faction.resize(_max_ruins)
	_ruin_phase.resize(_max_ruins)

	_shuttle_start.resize(_max_shuttles)
	_shuttle_target.resize(_max_shuttles)
	_shuttle_pos.resize(_max_shuttles)
	_shuttle_t.resize(_max_shuttles)
	_shuttle_dur.resize(_max_shuttles)
	_shuttle_faction.resize(_max_shuttles)
	_shuttle_src_city.resize(_max_shuttles)
	_shuttle_trail_t.resize(_max_shuttles)
	_shuttle_kind.resize(_max_shuttles)
	_shuttle_target_city.resize(_max_shuttles)


func _reset_state_arrays() -> void:
	_sim_time = 0.0
	_total_harvested = 0.0
	_total_shuttles_launched = 0
	_shield_blocked_total = 0
	_supply_deliveries = 0
	_border_clash_count = 0
	_clash_scan_timer = 0.25
	_env_check_timer = 0.25
	_ruin_tick_timer = 0.25
	_shuttle_launch_timer = 0.5
	_supply_scan_timer = 1.0
	_rebellions_total = 0
	_diplo_scan_timer = float(TUNING_KNOBS["DIPLO_SCAN_SEC"])
	_capture_scan_timer = float(TUNING_KNOBS["WAR_CAPTURE_SCAN_SEC"])
	_road_px_count = 0
	_bld_count = 0
	_ruin_count = 0
	_shuttle_count = 0

	_zone_city_id.fill(-1)
	_zone_faction_id.fill(255)
	_zone_flags.fill(0)
	_zone_ore.fill(0)
	_zone_fertility.fill(0.5)
	_zone_close_n.fill(255)
	_zone_land_n.fill(255)
	_road_mask.fill(ROAD_NONE)
	_border_buf.fill(0)

	_city_active.fill(0)
	_city_faction.fill(0)
	for cid in range(_max_cities):
		_city_name[cid] = ""
	_city_center.fill(Vector2.ZERO)
	_city_mine_pos.fill(Vector2(-1.0, -1.0))
	_city_build_pos.fill(Vector2(-1.0, -1.0))
	_city_patrol_pos.fill(Vector2(-1.0, -1.0))
	_city_threat_pos.fill(Vector2.ZERO)
	_city_alerted.fill(0)
	_city_alert_timer.fill(0.0)
	_city_tech_tier.fill(0)
	_city_tech_score.fill(0.0)
	_city_color.fill(FACTION_BORDER_COLORS[0])
	_city_pop.fill(0)
	_city_zones_count.fill(0)
	_city_food.fill(0.0)
	_city_ore.fill(0.0)
	_city_energy.fill(0.0)
	_city_energy_spend_acc.fill(0.0)
	_city_energy_net.fill(0.0)
	_city_science.fill(0.0)
	_city_storage_cap.fill(float(TUNING_KNOBS["BASE_STORAGE_CAP"]))
	_city_expand_timer.fill(0.0)
	_city_pop_timer.fill(0.0)
	_city_shuttle_cd.fill(0.0)
	_city_shuttles_launched.fill(0)
	_city_proj_type.fill(-1)
	_city_proj_prog.fill(0.0)
	_city_proj_work.fill(0.0)
	_city_proj_retry.fill(0.0)
	_city_tech_dirty.fill(0)
	_city_coastal_cache.fill(0)
	_city_bld_counts.fill(0)

	_diplo_matrix.fill(Diplomacy.NEUTRAL)
	_diplo_tension.fill(0.0)
	_diplo_pair_cd.fill(0.0)
	_city_loyalty.fill(100.0)
	_city_is_rebel.fill(0)
	_city_war_state.fill(Diplomacy.NEUTRAL)
	_city_emp_timer.fill(0.0)
	_city_war_cooldown.fill(0.0)
	_city_overlord.fill(-1)
	_city_tech_floor.fill(0)

	_zone_capture_cid.fill(-1)
	_zone_capture_timer.fill(0.0)
	_zone_in_contested.fill(0)
	_contested_z_count = 0
	_tmp_zone_att_cid.fill(-1)
	_tmp_zone_att_cnt.fill(0)
	_tmp_zone_def_cnt.fill(0)
	_tmp_zone_att_sol.fill(0)
	_zone_in_active_cap.fill(0)
	_active_cap_count = 0
	_tmp_frontier_contacts.fill(0)

	_bld_radius.fill(0.0)
	_bld_shield_charge.fill(0.0)
	_bld_shield_flash.fill(0.0)
	_shuttle_kind.fill(SHUTTLE_KIND_COLONIZE)
	_shuttle_target_city.fill(-1)

	if _border_image != null and _border_texture != null:
		_border_image.set_data(_map_w, _map_h, false, Image.FORMAT_RGBA8, _border_buf)
		_border_texture.update(_border_image)
	_border_dirty = false
	_dirty_zx0 = _zone_w
	_dirty_zy0 = _zone_h
	_dirty_zx1 = -1
	_dirty_zy1 = -1

	_goals_dirty = true
	_bld_footprints_dirty = true
	_buildings_dirty = true
	_bld_anim_step = -1

	if _mm_bld_shadows != null and _mm_bld_shadows.multimesh != null:
		_mm_bld_shadows.multimesh.visible_instance_count = 0
	if _mm_buildings != null and _mm_buildings.multimesh != null:
		_mm_buildings.multimesh.visible_instance_count = 0


func _build_border_layer() -> void:
	_border_image = Image.create(_map_w, _map_h, false, Image.FORMAT_RGBA8)
	_border_image.fill(Color(0.0, 0.0, 0.0, 0.0))
	_border_texture = ImageTexture.create_from_image(_border_image)

	_border_sprite = Sprite2D.new()
	_border_sprite.centered = false
	_border_sprite.z_index = 0
	_border_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_border_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	_border_sprite.texture = _border_texture
	add_child(_border_sprite)


func _make_soft_oval_texture() -> Texture2D:
	var w: int = 16
	var h: int = 10
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	for py in range(h):
		var ny: float = (float(py) + 0.5 - float(h) * 0.5) / (float(h) * 0.45)
		for px in range(w):
			var nx: float = (float(px) + 0.5 - float(w) * 0.5) / (float(w) * 0.46)
			if nx * nx + ny * ny <= 1.0:
				img.set_pixel(px, py, Color(1.0, 1.0, 1.0, 1.0))
	return ImageTexture.create_from_image(img)


func _build_shadows_layer() -> void:
	_shadow_tex = _make_soft_oval_texture()
	_shadow_group = CanvasGroup.new()
	_shadow_group.z_index = 0
	_shadow_group.self_modulate = Color(0.04, 0.06, 0.14, float(TUNING_KNOBS["SHADOW_GROUP_ALPHA"]))
	_shadow_group.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_mm_bld_shadows = MultiMeshInstance2D.new()
	_mm_bld_shadows.z_index = 0
	_mm_bld_shadows.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mm_bld_shadows.texture = _shadow_tex

	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = false
	mm.use_custom_data = false
	mm.mesh = quad
	mm.instance_count = _max_buildings + _max_cities + _max_ruins + _max_shuttles
	mm.visible_instance_count = 0
	_mm_bld_shadows.multimesh = mm

	_shadow_group.add_child(_mm_bld_shadows)
	add_child(_shadow_group)
	set_zoom_lod(_zoom_val)


func _load_png_texture(res_path: String) -> Texture2D:
	# Read raw PNG bytes first so cold --headless runs succeed before .godot/imported/ exists.
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(res_path)
	if not bytes.is_empty():
		var img := Image.new()
		if img.load_png_from_buffer(bytes) == OK:
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(res_path):
		var res: Resource = load(res_path)
		if res is Texture2D:
			return res as Texture2D
	return null


func _build_buildings_layer() -> void:
	_atlas_tex = _load_png_texture(BUILDINGS_ATLAS_PATH)
	_mask_tex = _load_png_texture(BUILDINGS_MASK_PATH)
	if _atlas_tex == null:
		var fallback := Image.create(ATLAS_COLS * 24, 24, false, Image.FORMAT_RGBA8)
		fallback.fill(Color(0.85, 0.85, 0.90, 1.0))
		_atlas_tex = ImageTexture.create_from_image(fallback)
	if _mask_tex == null:
		var fallback_m := Image.create(ATLAS_COLS * 24, 24, false, Image.FORMAT_RGBA8)
		fallback_m.fill(Color(0.0, 0.0, 0.0, 1.0))
		_mask_tex = ImageTexture.create_from_image(fallback_m)

	_mm_buildings = MultiMeshInstance2D.new()
	_mm_buildings.z_index = 1
	_mm_buildings.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mm_buildings.texture = _atlas_tex

	_bld_mat = ShaderMaterial.new()
	_bld_mat.shader = UNIT_SPRITE_SHADER
	_bld_mat.set_shader_parameter("sprite_mode", 3)
	_bld_mat.set_shader_parameter("motion_mode", 0)
	_bld_mat.set_shader_parameter("atlas_cols", ATLAS_COLS)
	_bld_mat.set_shader_parameter("sprite_size", Vector2(BUILDING_CELL_PX, BUILDING_CELL_PX))
	_bld_mat.set_shader_parameter("mask_tex", _mask_tex)
	_bld_mat.set_shader_parameter("hdr_emissive", 2.6)
	_bld_mat.set_shader_parameter("blueprint_col", float(BLD_COL_SCAFFOLD))
	_bld_mat.set_shader_parameter("blueprint_col_hi", float(BLD_COL_SCAFFOLD_LG))
	_bld_mat.set_shader_parameter("age_tint", Vector3(_age_tint.r, _age_tint.g, _age_tint.b))
	_bld_mat.set_shader_parameter("age_tint_strength", _age_tint_strength)
	_mm_buildings.material = _bld_mat

	var quad := QuadMesh.new()
	quad.size = Vector2(BUILDING_CELL_PX, BUILDING_CELL_PX)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = _max_buildings + _max_cities + _max_ruins + _max_shuttles
	mm.visible_instance_count = 0
	_mm_buildings.multimesh = mm
	add_child(_mm_buildings)


func bind_systems(world: Node2D, physics: Node2D, fx: Node2D = null) -> void:
	_ensure_initialized()
	if _world != null and is_instance_valid(_world):
		var old_cb := Callable(self, "_on_world_map_rebuilt")
		if _world.has_signal("map_rebuilt") and _world.is_connected("map_rebuilt", old_cb):
			_world.disconnect("map_rebuilt", old_cb)

	_world = world
	_physics = physics
	_fx = fx

	if _world != null:
		var mw_v: Variant = _world.get("map_w")
		var mh_v: Variant = _world.get("map_h")
		if mw_v is int and mh_v is int:
			if int(mw_v) != _map_w or int(mh_v) != _map_h:
				_map_w = maxi(32, int(mw_v))
				_map_h = maxi(32, int(mh_v))
				_zone_w = ceili(float(_map_w) / float(_zone_px))
				_zone_h = ceili(float(_map_h) / float(_zone_px))
				_zone_count = _zone_w * _zone_h
				_alloc_buffers()
		if _world.has_signal("map_rebuilt"):
			var cb := Callable(self, "_on_world_map_rebuilt")
			if not _world.is_connected("map_rebuilt", cb):
				_world.connect("map_rebuilt", cb)
		_scan_world_resources()

	if _physics != null and _physics.has_method("bind_civ"):
		_physics.bind_civ(self)
	_goals_dirty = true
	if _bld_count > 0:
		_bld_footprints_dirty = true
	_last_pushed_physics = null
	_push_goal_buffers()


func _on_world_map_rebuilt() -> void:
	reset_civ()


func reset_civ() -> void:
	_ensure_initialized()
	_rng.seed = _rng_seed
	_reset_state_arrays()
	_scan_world_resources()
	_goals_dirty = true
	_bld_footprints_dirty = true
	_push_goal_buffers()


func _scan_world_resources() -> void:
	if _world == null:
		return
	_scan_zone_range(0, 0, _zone_w - 1, _zone_h - 1)


func _scan_zone_range(zx0: int, zy0: int, zx1: int, zy1: int, track_border_changes: bool = false) -> bool:
	if _world == null:
		return false
	var cx0: int = clampi(zx0, 0, _zone_w - 1)
	var cy0: int = clampi(zy0, 0, _zone_h - 1)
	var cx1: int = clampi(zx1, 0, _zone_w - 1)
	var cy1: int = clampi(zy1, 0, _zone_h - 1)
	var any_coast_changed: bool = false
	for zy in range(cy0, cy1 + 1):
		var py0: int = zy * _zone_px
		var py1: int = mini(_map_h, py0 + _zone_px)
		for zx in range(cx0, cx1 + 1):
			var px0: int = zx * _zone_px
			var px1: int = mini(_map_w, px0 + _zone_px)
			var land_n: int = 0
			var hill_n: int = 0
			var mtn_n: int = 0
			var crys_n: int = 0
			var lush_n: int = 0
			var scorch_n: int = 0
			var water_near: int = 0
			var close_n: int = 0

			for py in range(py0, py1, 2):
				for px in range(px0, px1, 2):
					var t: int = _world.get_tier(px, py)
					if t <= TIER_SHALLOW:
						if t <= TIER_CLOSE_OCEAN:
							close_n += 1
						water_near += 1
						continue
					if t >= TIER_SUMMIT:
						continue
					land_n += 1
					var b: int = _world.get_biome(px, py)
					if t == TIER_HILLS:
						hill_n += 1
					elif t == TIER_MOUNTAINS:
						mtn_n += 1
					if b == BIOME_CRYSTAL:
						crys_n += 1
					elif b == BIOME_LUSH:
						lush_n += 1
					elif b == BIOME_SCORCHED:
						scorch_n += 1

			var zidx: int = zy * _zone_w + zx
			var ore: int = mtn_n * 6 + hill_n * 3 + crys_n * 4 + scorch_n
			if ore == 0 and land_n >= 8:
				# Surface rock pocket on inland soil so every continent can bootstrap drills/miners
				var h_val: int = ((zx * 73856093) ^ (zy * 19349663)) & 7
				if h_val <= 2:
					ore = 10 + h_val * 4
			_zone_ore[zidx] = ore

			var fert: float = 0.40
			if lush_n >= 4:
				fert = 1.00
			if water_near > 0 and land_n >= 4:
				fert = maxf(fert, 1.35)
			_zone_fertility[zidx] = fert

			var cl_b: int = mini(254, close_n)
			var ln_b: int = mini(254, land_n)
			var prev_close: int = int(_zone_close_n[zidx])
			var prev_land: int = int(_zone_land_n[zidx])
			_zone_close_n[zidx] = cl_b
			_zone_land_n[zidx] = ln_b
			if track_border_changes and (prev_close != cl_b or prev_land != ln_b):
				any_coast_changed = true
				var has_near_overlay: bool = false
				for ny in range(maxi(0, zy - 1), mini(_zone_h, zy + 2)):
					var n_row: int = ny * _zone_w
					for nx in range(maxi(0, zx - 1), mini(_zone_w, zx + 2)):
						var n_zi: int = n_row + nx
						var o: int = _zone_city_id[n_zi]
						if (o >= 0 and _city_active[o] != 0) or (_zone_flags[n_zi] & ZONE_FLAG_ROAD) != 0:
							has_near_overlay = true
							break
					if has_near_overlay:
						break
				if has_near_overlay:
					_mark_zone_dirty(zx, zy)
	return any_coast_changed


func refresh_resource_zone(rect: Rect2i) -> void:
	_ensure_initialized()
	if _world == null:
		return
	var rx0: int = clampi(rect.position.x, 0, _map_w - 1)
	var ry0: int = clampi(rect.position.y, 0, _map_h - 1)
	var rx1: int = clampi(rect.position.x + maxi(1, rect.size.x) - 1, 0, _map_w - 1)
	var ry1: int = clampi(rect.position.y + maxi(1, rect.size.y) - 1, 0, _map_h - 1)
	var zx0: int = clampi(rx0 / _zone_px, 0, _zone_w - 1)
	var zy0: int = clampi(ry0 / _zone_px, 0, _zone_h - 1)
	var zx1: int = clampi(rx1 / _zone_px, 0, _zone_w - 1)
	var zy1: int = clampi(ry1 / _zone_px, 0, _zone_h - 1)

	var coast_changed: bool = _scan_zone_range(zx0, zy0, zx1, zy1, true)
	if coast_changed:
		_city_coastal_cache.fill(0)

	# Only run flood/walkability checks on owned zones in rect (coast border dirties handled in scan above)
	var touched_owned: bool = false
	for zy in range(zy0, zy1 + 1):
		var row_off: int = zy * _zone_w
		for zx in range(zx0, zx1 + 1):
			var zidx: int = row_off + zx
			var owner: int = _zone_city_id[zidx]
			if owner >= 0 and _city_active[owner] != 0:
				touched_owned = true
				var fid: int = int(_city_faction[owner])
				if not _is_zone_walkable_enough_for(zx, zy, fid):
					_zone_city_id[zidx] = -1
					_zone_faction_id[zidx] = 255
					_zone_flags[zidx] = 0
					_city_zones_count[owner] = maxi(0, _city_zones_count[owner] - 1)
					_city_coastal_cache[owner] = 0
					_mark_zone_dirty(zx, zy)
					_goals_dirty = true

	if touched_owned:
		var bi: int = _bld_count - 1
		var fallen_cities: Dictionary = {}
		while bi >= 0:
			var bpos: Vector2 = _bld_pos[bi]
			var bx: int = clampi(int(floor(bpos.x)), 0, _map_w - 1)
			var by: int = clampi(int(floor(bpos.y)), 0, _map_h - 1)
			if bx >= rx0 and bx <= rx1 and by >= ry0 and by <= ry1:
				var cid: int = _bld_city_id[bi]
				var fid: int = int(_city_faction[clampi(cid, 0, _max_cities - 1)])
				var flooded: bool = int(_world.get_tier(bx, by)) <= TIER_CLOSE_OCEAN or _world.get_biome(bx, by) == BIOME_LAVA
				if flooded or not _is_pixel_walkable_for_faction(bx, by, fid):
					if _bld_type[bi] == BuildingType.FUSION_REACTOR:
						_trigger_reactor_meltdown(bpos, cid)
					if cid >= 0 and cid < _max_cities:
						fallen_cities[cid] = true
					_remove_building(bi)
			bi -= 1
		var keys: Array = fallen_cities.keys()
		for k_i in range(keys.size()):
			var cid: int = int(keys[k_i])
			if cid >= 0 and cid < _max_cities and _city_active[cid] != 0:
				_verify_city_integrity_after_damage(cid)


func _get_zone_owner(zx: int, zy: int) -> int:
	if zx < 0 or zx >= _zone_w or zy < 0 or zy >= _zone_h:
		return -1
	return _zone_city_id[zy * _zone_w + zx]


func get_zone_owner_at(world_pos: Vector2) -> int:
	var zx: int = int(floor(world_pos.x / float(_zone_px)))
	var zy: int = int(floor(world_pos.y / float(_zone_px)))
	return _get_zone_owner(zx, zy)


func get_zone_faction_at(world_pos: Vector2) -> int:
	var zx: int = int(floor(world_pos.x / float(_zone_px)))
	var zy: int = int(floor(world_pos.y / float(_zone_px)))
	if zx < 0 or zx >= _zone_w or zy < 0 or zy >= _zone_h:
		return 255
	return int(_zone_faction_id[zy * _zone_w + zx])


func is_road_at(world_pos: Vector2) -> bool:
	var px: int = int(floor(world_pos.x))
	var py: int = int(floor(world_pos.y))
	if px < 0 or px >= _map_w or py < 0 or py >= _map_h:
		return false
	return _road_mask[py * _map_w + px] != ROAD_NONE


func _mark_zone_dirty(zx: int, zy: int) -> void:
	var x0: int = maxi(0, zx - 1)
	var y0: int = maxi(0, zy - 1)
	var x1: int = mini(_zone_w - 1, zx + 1)
	var y1: int = mini(_zone_h - 1, zy + 1)
	if not _border_dirty:
		_border_dirty = true
		_dirty_zx0 = x0
		_dirty_zy0 = y0
		_dirty_zx1 = x1
		_dirty_zy1 = y1
	else:
		_dirty_zx0 = mini(_dirty_zx0, x0)
		_dirty_zy0 = mini(_dirty_zy0, y0)
		_dirty_zx1 = maxi(_dirty_zx1, x1)
		_dirty_zy1 = maxi(_dirty_zy1, y1)


func _mark_all_borders_dirty() -> void:
	_border_dirty = true
	_dirty_zx0 = 0
	_dirty_zy0 = 0
	_dirty_zx1 = _zone_w - 1
	_dirty_zy1 = _zone_h - 1


func _flush_dirty_borders() -> void:
	if not _border_dirty or _border_image == null or _border_texture == null:
		return
	_border_dirty = false
	if _dirty_zx1 < _dirty_zx0 or _dirty_zy1 < _dirty_zy0:
		_dirty_zx0 = _zone_w
		_dirty_zy0 = _zone_h
		_dirty_zx1 = -1
		_dirty_zy1 = -1
		return

	var zx0: int = clampi(_dirty_zx0, 0, _zone_w - 1)
	var zy0: int = clampi(_dirty_zy0, 0, _zone_h - 1)
	var zx1: int = clampi(_dirty_zx1, 0, _zone_w - 1)
	var zy1: int = clampi(_dirty_zy1, 0, _zone_h - 1)

	# Clear dirty bounding sentinels immediately after capturing dirty rect
	_dirty_zx0 = _zone_w
	_dirty_zy0 = _zone_h
	_dirty_zx1 = -1
	_dirty_zy1 = -1

	var px0: int = clampi(zx0 * _zone_px, 0, _map_w - 1)
	var py0: int = clampi(zy0 * _zone_px, 0, _map_h - 1)
	var px1: int = clampi((zx1 + 1) * _zone_px, 0, _map_w)
	var py1: int = clampi((zy1 + 1) * _zone_px, 0, _map_h)
	var bw: int = px1 - px0
	var bh: int = py1 - py0
	if bw <= 0 or bh <= 0:
		return

	var pad: int = 3
	var pw: int = bw + pad * 2
	var ph: int = bh + pad * 2
	var grid_len: int = pw * ph
	if _tmp_own_grid.size() < grid_len:
		_tmp_own_grid.resize(grid_len)
		_tmp_eff_grid.resize(grid_len)
		_tmp_edge_grid.resize(grid_len)

	# Pass 1: Sample raw territory owner clipped out of deep/close ocean (<= CLOSE_OCEAN)
	for gy in range(ph):
		var wy: int = py0 - pad + gy
		var row_g: int = gy * pw
		if wy < 0 or wy >= _map_h:
			for gx in range(pw):
				_tmp_own_grid[row_g + gx] = -1
			continue
		var zy: int = wy / _zone_px
		var prev_zx: int = -1
		var cached_cid: int = -1
		for gx in range(pw):
			var wx: int = px0 - pad + gx
			if wx < 0 or wx >= _map_w:
				_tmp_own_grid[row_g + gx] = -1
				continue
			var zx_c: int = wx / _zone_px
			if zx_c != prev_zx:
				prev_zx = zx_c
				cached_cid = _get_zone_owner(zx_c, zy)
			var cid: int = cached_cid
			if cid < 0 or _city_active[cid] == 0:
				_tmp_own_grid[row_g + gx] = -1
				continue
			if _world != null and int(_world.get_tier(wx, wy)) <= TIER_CLOSE_OCEAN:
				_tmp_own_grid[row_g + gx] = -1
				continue
			_tmp_own_grid[row_g + gx] = cid

	# Pass 2: Chamfer convex outer 90-degree corners diagonally
	for gy in range(1, ph - 1):
		var row_g: int = gy * pw
		var row_n: int = (gy - 1) * pw
		var row_s: int = (gy + 1) * pw
		for gx in range(1, pw - 1):
			var gi: int = row_g + gx
			var c: int = _tmp_own_grid[gi]
			if c < 0:
				_tmp_eff_grid[gi] = -1
				continue
			var n: int = _tmp_own_grid[row_n + gx]
			var s: int = _tmp_own_grid[row_s + gx]
			var w: int = _tmp_own_grid[gi - 1]
			var e: int = _tmp_own_grid[gi + 1]
			var nw: int = _tmp_own_grid[row_n + gx - 1]
			var ne: int = _tmp_own_grid[row_n + gx + 1]
			var sw: int = _tmp_own_grid[row_s + gx - 1]
			var se: int = _tmp_own_grid[row_s + gx + 1]
			var is_outer_corner: bool = (
				(n < 0 and w < 0 and s == c and e == c and se == c)
				or (n < 0 and e < 0 and s == c and w == c and sw == c)
				or (s < 0 and w < 0 and n == c and e == c and ne == c)
				or (s < 0 and e < 0 and n == c and w == c and nw == c)
			)
			_tmp_eff_grid[gi] = -1 if is_outer_corner else c

	# Pass 3: Detect 1px faction border pixels on margin-2 neighborhood
	for gy in range(2, ph - 2):
		var row_g: int = gy * pw
		for gx in range(2, pw - 2):
			var gi: int = row_g + gx
			var c: int = _tmp_eff_grid[gi]
			if c < 0:
				_tmp_edge_grid[gi] = 0
				continue
			var is_e: bool = (
				_tmp_eff_grid[gi - pw] != c
				or _tmp_eff_grid[gi + pw] != c
				or _tmp_eff_grid[gi - 1] != c
				or _tmp_eff_grid[gi + 1] != c
			)
			_tmp_edge_grid[gi] = 1 if is_e else 0

	var tint_a: int = clampi(int(round(float(TUNING_KNOBS["BORDER_TINT_ALPHA"]) * 255.0)), 4, 64)
	var edge_a: int = clampi(int(round(float(TUNING_KNOBS["BORDER_LINE_ALPHA"]) * 255.0)), 180, 255)
	var back_a: int = clampi(int(round(float(TUNING_KNOBS["BORDER_BACKING_ALPHA"]) * 255.0)), 160, 245)
	var vein_lum: float = float(TUNING_KNOBS["CONDUIT_VEIN_LUMINANCE"])

	# Pass 4: Write crisp RGBA pixels (border + dark #101824 backing + steel-railed roads + tint)
	for py in range(py0, py1):
		var gy: int = (py - py0) + pad
		var row_g: int = gy * pw
		var row_off: int = py * _map_w
		for px in range(px0, px1):
			var gx: int = (px - px0) + pad
			var gi: int = row_g + gx
			var idx: int = row_off + px
			var p: int = idx * 4

			var owner: int = _tmp_eff_grid[gi]
			if owner >= 0 and _tmp_edge_grid[gi] == 1:
				var bcol: Color = _get_city_border_color(owner)
				if _city_is_rebel[owner] != 0 and ((px + py) & 3) == 0:
					bcol = REBEL_ACCENT_COLOR
				_border_buf[p] = int(round(bcol.r * 255.0))
				_border_buf[p + 1] = int(round(bcol.g * 255.0))
				_border_buf[p + 2] = int(round(bcol.b * 255.0))
				_border_buf[p + 3] = edge_a
				continue

			# 1px #101824 dark contrast backing immediately outside outer territory edges
			if owner < 0:
				var adj_edge: bool = (
					_tmp_edge_grid[gi - pw] == 1
					or _tmp_edge_grid[gi + pw] == 1
					or _tmp_edge_grid[gi - 1] == 1
					or _tmp_edge_grid[gi + 1] == 1
				)
				if adj_edge:
					_border_buf[p] = 16
					_border_buf[p + 1] = 24
					_border_buf[p + 2] = 36
					_border_buf[p + 3] = back_a
					continue

			var road_val: int = _road_mask[idx]
			if road_val != ROAD_NONE and (owner >= 0 or _world == null or int(_world.get_tier(px, py)) > TIER_CLOSE_OCEAN):
				var is_conduit: bool = road_val == ROAD_CONDUIT or (owner >= 0 and int(_city_tech_tier[owner]) >= 2)
				if is_conduit:
					var base_col: Color = Color(0.28, 0.52, 0.62)
					if owner >= 0:
						base_col = _get_city_border_color(owner).lerp(Color(0.32, 0.56, 0.66), 0.45)
					_border_buf[p] = clampi(int(round(base_col.r * vein_lum * 255.0)), 18, 160)
					_border_buf[p + 1] = clampi(int(round(base_col.g * vein_lum * 255.0)), 18, 160)
					_border_buf[p + 2] = clampi(int(round(base_col.b * vein_lum * 255.0)), 18, 168)
					_border_buf[p + 3] = 232
				else:
					# Subdued compacted earth vein (~0.55x luminance)
					var grain: int = ((px * 73856093) ^ (py * 19349663)) & 1
					_border_buf[p] = 104 if grain == 0 else 92
					_border_buf[p + 1] = 84 if grain == 0 else 74
					_border_buf[p + 2] = 66 if grain == 0 else 58
					_border_buf[p + 3] = 222
				continue

			# Dark steel outer rails (#3A4859) framing roads cleanly away from borders
			if _road_px_count > 0:
				var has_adj_road: bool = (
					(py > 0 and _road_mask[idx - _map_w] != ROAD_NONE)
					or (py + 1 < _map_h and _road_mask[idx + _map_w] != ROAD_NONE)
					or (px > 0 and _road_mask[idx - 1] != ROAD_NONE)
					or (px + 1 < _map_w and _road_mask[idx + 1] != ROAD_NONE)
				)
				if has_adj_road and (owner >= 0 or _world == null or int(_world.get_tier(px, py)) > TIER_CLOSE_OCEAN):
					_border_buf[p] = 58
					_border_buf[p + 1] = 72
					_border_buf[p + 2] = 89
					_border_buf[p + 3] = 220
					continue

			if owner >= 0:
				var bcol: Color = _get_city_border_color(owner)
				_border_buf[p] = int(round(bcol.r * 255.0))
				_border_buf[p + 1] = int(round(bcol.g * 255.0))
				_border_buf[p + 2] = int(round(bcol.b * 255.0))
				_border_buf[p + 3] = tint_a
			else:
				_border_buf[p] = 0
				_border_buf[p + 1] = 0
				_border_buf[p + 2] = 0
				_border_buf[p + 3] = 0

	_border_image.set_data(_map_w, _map_h, false, Image.FORMAT_RGBA8, _border_buf)
	_border_texture.update(_border_image)


func _is_pixel_walkable(px: int, py: int) -> bool:
	return _is_pixel_walkable_for_faction(px, py, Faction.HUMAN)


func _is_pixel_walkable_for_faction(px: int, py: int, faction_id: int) -> bool:
	if px < 4 or px >= _map_w - 4 or py < 4 or py >= _map_h - 4:
		return false
	if _world == null:
		return true
	if not _world.is_walkable(px, py):
		return false
	var biome: int = _world.get_biome(px, py)
	if biome == BIOME_LAVA:
		return false
	var temp_c: float = _world.get_temp(px, py)
	# ROBOT built-in tolerance for SCORCHED & CRYSTAL heat
	if faction_id == Faction.ROBOT:
		return temp_c <= 95.0
	return temp_c <= 65.0


func _is_zone_claimable(zx: int, zy: int, faction_id: int = 0) -> bool:
	if zx < 0 or zx >= _zone_w or zy < 0 or zy >= _zone_h:
		return false
	var zidx: int = zy * _zone_w + zx
	if _zone_city_id[zidx] != -1:
		return false
	return _is_zone_walkable_enough_for(zx, zy, faction_id)


func _zone_walkable_center(zx: int, zy: int, faction_id: int = 0) -> Vector2:
	var px0: int = zx * _zone_px
	var py0: int = zy * _zone_px
	var cx: int = clampi(px0 + 4, 4, _map_w - 5)
	var cy: int = clampi(py0 + 4, 4, _map_h - 5)
	if _is_pixel_walkable_for_faction(cx, cy, faction_id):
		return Vector2(float(cx) + 0.5, float(cy) + 0.5)
	for dy in range(1, _zone_px, 2):
		for dx in range(1, _zone_px, 2):
			var tx: int = clampi(px0 + dx, 4, _map_w - 5)
			var ty: int = clampi(py0 + dy, 4, _map_h - 5)
			if _is_pixel_walkable_for_faction(tx, ty, faction_id):
				return Vector2(float(tx) + 0.5, float(ty) + 0.5)
	return Vector2(-1.0, -1.0)


func _find_walkable_near(world_pos: Vector2, max_r: int = 18, faction_id: int = 0) -> Vector2:
	var cx: int = clampi(int(floor(world_pos.x)), 4, _map_w - 5)
	var cy: int = clampi(int(floor(world_pos.y)), 4, _map_h - 5)
	if _is_pixel_walkable_for_faction(cx, cy, faction_id):
		return Vector2(float(cx) + 0.5, float(cy) + 0.5)
	for r in range(2, max_r + 1, 2):
		for k in range(12):
			var ang: float = float(k) * (TAU / 12.0)
			var tx: int = clampi(cx + int(round(cos(ang) * float(r))), 4, _map_w - 5)
			var ty: int = clampi(cy + int(round(sin(ang) * float(r))), 4, _map_h - 5)
			if _is_pixel_walkable_for_faction(tx, ty, faction_id):
				return Vector2(float(tx) + 0.5, float(ty) + 0.5)
	return Vector2(-1.0, -1.0)


func _pick_city_name(faction_id: int, cid: int) -> String:
	var f_idx: int = clampi(faction_id, 0, CITY_NAME_POOLS.size() - 1)
	var pool: Array = CITY_NAME_POOLS[f_idx]
	var base_idx: int = (cid + _rng.randi()) % pool.size()
	for offset in range(pool.size()):
		var cand: String = str(pool[(base_idx + offset) % pool.size()])
		var used: bool = false
		for other in range(_max_cities):
			if _city_active[other] != 0 and _city_name[other] == cand:
				used = true
				break
		if not used:
			return cand
	return "%s %d" % [str(pool[cid % pool.size()]), cid + 1]


func _claim_zone(zx: int, zy: int, city_id: int, faction_id: int) -> bool:
	if zx < 0 or zx >= _zone_w or zy < 0 or zy >= _zone_h:
		return false
	var zidx: int = zy * _zone_w + zx
	var prev_city: int = _get_zone_owner(zx, zy)
	if prev_city == city_id:
		return false
	if prev_city >= 0 and prev_city < _max_cities and _city_active[prev_city] != 0:
		_city_zones_count[prev_city] = maxi(0, _city_zones_count[prev_city] - 1)
		_city_coastal_cache[prev_city] = 0

	_zone_city_id[zidx] = city_id
	_zone_faction_id[zidx] = faction_id
	_zone_capture_cid[zidx] = -1
	_zone_capture_timer[zidx] = 0.0
	_city_zones_count[city_id] += 1
	_city_coastal_cache[city_id] = 0
	_mark_zone_dirty(zx, zy)
	_goals_dirty = true
	return true


func spawn_colony(world_pos: Vector2, faction_id: int = 0) -> int:
	_ensure_initialized()
	var f_clamped: int = clampi(faction_id, 0, FACTION_BORDER_COLORS.size() - 1)
	var safe_pos: Vector2 = _find_walkable_near(world_pos, 22, f_clamped)
	if safe_pos.x < 0.0:
		return -1

	var min_spacing: float = float(TUNING_KNOBS["MIN_CITY_SPACING_PX"])
	var min_sp2: float = min_spacing * min_spacing
	var free_cid: int = -1
	for cid in range(_max_cities):
		if _city_active[cid] == 0:
			if free_cid < 0:
				free_cid = cid
			continue
		if _city_center[cid].distance_squared_to(safe_pos) < min_sp2:
			return -1

	if free_cid < 0:
		return -1

	var zx: int = clampi(int(floor(safe_pos.x / float(_zone_px))), 0, _zone_w - 1)
	var zy: int = clampi(int(floor(safe_pos.y / float(_zone_px))), 0, _zone_h - 1)

	_city_active[free_cid] = 1
	_city_faction[free_cid] = f_clamped
	_city_name[free_cid] = _pick_city_name(f_clamped, free_cid)
	_city_center[free_cid] = safe_pos
	_city_threat_pos[free_cid] = Vector2.ZERO
	_city_alerted[free_cid] = 0
	_city_alert_timer[free_cid] = 0.0
	_city_tech_tier[free_cid] = 0
	_city_tech_score[free_cid] = 0.0
	_city_pop[free_cid] = 0
	_city_zones_count[free_cid] = 0
	_city_food[free_cid] = 8.0 if f_clamped == Faction.ROBOT else 14.0
	_city_ore[free_cid] = 22.0 if f_clamped == Faction.ROBOT else 18.0
	_city_energy[free_cid] = 12.0 if f_clamped == Faction.ROBOT else 8.0
	_city_energy_spend_acc[free_cid] = 0.0
	_city_energy_net[free_cid] = 0.0
	_city_science[free_cid] = 6.0
	_city_storage_cap[free_cid] = float(TUNING_KNOBS["BASE_STORAGE_CAP"])
	_city_expand_timer[free_cid] = float(TUNING_KNOBS["FIRST_EXPAND_DELAY_SEC"]) * (0.75 if f_clamped == Faction.SPORE else 1.0)
	_city_pop_timer[free_cid] = float(TUNING_KNOBS["POP_GROWTH_INTERVAL_SEC"])
	_city_shuttle_cd[free_cid] = 2.0
	_city_shuttles_launched[free_cid] = 0
	_city_proj_type[free_cid] = -1
	_city_proj_prog[free_cid] = 0.0
	_city_proj_work[free_cid] = 0.0
	_city_proj_retry[free_cid] = 0.0
	_city_tech_dirty[free_cid] = 1

	_city_loyalty[free_cid] = 100.0
	_city_is_rebel[free_cid] = 0
	_city_war_state[free_cid] = Diplomacy.NEUTRAL
	_city_emp_timer[free_cid] = 0.0
	_city_war_cooldown[free_cid] = 0.0
	_city_overlord[free_cid] = -1
	_city_tech_floor[free_cid] = 0
	_city_color[free_cid] = _get_city_tint_color(free_cid)

	var row_cid: int = free_cid * _max_cities
	for other in range(_max_cities):
		var st: int = Diplomacy.NEUTRAL
		if other != free_cid and _city_active[other] != 0:
			if int(_city_faction[other]) == f_clamped and _city_is_rebel[other] == 0:
				st = Diplomacy.PACT
		_diplo_matrix[row_cid + other] = st
		_diplo_matrix[other * _max_cities + free_cid] = st
		_diplo_tension[row_cid + other] = 0.0
		_diplo_tension[other * _max_cities + free_cid] = 0.0
		_diplo_pair_cd[row_cid + other] = 0.0
		_diplo_pair_cd[other * _max_cities + free_cid] = 0.0
		if other != free_cid and _city_active[other] != 0:
			_recompute_city_war_state(other)
	_recompute_city_war_state(free_cid)

	var base_b: int = free_cid * BLD_TYPE_COUNT
	for bt in range(BLD_TYPE_COUNT):
		_city_bld_counts[base_b + bt] = 0

	_claim_zone(zx, zy, free_cid, f_clamped)
	for k in range(4):
		var dx: int = 1 if k == 0 else (-1 if k == 1 else 0)
		var dy: int = 1 if k == 2 else (-1 if k == 3 else 0)
		var nzx: int = zx + dx
		var nzy: int = zy + dy
		if _is_zone_claimable(nzx, nzy, f_clamped):
			_claim_zone(nzx, nzy, free_cid, f_clamped)
			break

	# Starter structures: campfire/beacon/pod at center + housing tent/pod/hive nearby
	_place_building(free_cid, BuildingType.CAMPFIRE, safe_pos, true)
	var tent_spot: Vector2 = _find_building_spot(free_cid, BuildingType.TENT)
	if tent_spot.x >= 0.0:
		_place_building(free_cid, BuildingType.TENT, tent_spot, true)

	_recompute_city_tech(free_cid)
	_refresh_city_targets(free_cid)
	_start_next_project(free_cid)
	_flush_dirty_borders()
	_sync_buildings_multimesh()
	_buildings_dirty = false
	_bld_anim_step = int(floor(_sim_time * 8.0))
	_goals_dirty = true
	_bld_footprints_dirty = true
	_push_goal_buffers()

	if _physics != null and _physics.has_method("spawn_colony_units"):
		var start_pop: int = int(TUNING_KNOBS["START_CITY_POP"])
		var spawned: int = int(_physics.spawn_colony_units(free_cid, safe_pos, start_pop))
		_city_pop[free_cid] = spawned

	return free_cid


func _place_building(city_id: int, bld_type: int, pos: Vector2, quiet_audio: bool = false) -> int:
	if _bld_count >= _max_buildings:
		return -1
	var bidx: int = _bld_count
	_bld_count += 1

	var f_id: int = int(_city_faction[city_id]) % FACTION_TINT_COLORS.size()
	var avoid_r: float = BLD_AVOID_RADII[clampi(bld_type, 0, BLD_TYPE_COUNT - 1)]
	_bld_pos[bidx] = pos
	_bld_type[bidx] = bld_type
	_bld_radius[bidx] = avoid_r
	_bld_city_id[bidx] = city_id
	_bld_hp[bidx] = _building_max_hp(bld_type, f_id)
	_bld_spring[bidx] = 0.08
	_bld_spring_vel[bidx] = 4.6
	_bld_shake[bidx] = 0.0
	_bld_phase[bidx] = _rng.randf_range(0.0, TAU)
	_bld_color[bidx] = _get_city_tint_color(city_id)
	_bld_shield_charge[bidx] = 0.85 if bld_type == BuildingType.SHIELD_PYLON else 0.0
	_bld_shield_flash[bidx] = 0.0

	_city_bld_counts[city_id * BLD_TYPE_COUNT + bld_type] += 1
	_city_tech_dirty[city_id] = 1
	_buildings_dirty = true
	_bld_footprints_dirty = true
	_goals_dirty = true
	if bld_type == BuildingType.DEPOT:
		_city_storage_cap[city_id] += float(TUNING_KNOBS["DEPOT_STORAGE_BONUS"])
	elif bld_type == BuildingType.LAUNCHPAD:
		_city_storage_cap[city_id] += float(TUNING_KNOBS["LAUNCHPAD_STORAGE_BONUS"])

	var zx: int = clampi(int(floor(pos.x / float(_zone_px))), 0, _zone_w - 1)
	var zy: int = clampi(int(floor(pos.y / float(_zone_px))), 0, _zone_h - 1)
	if _zone_city_id[zy * _zone_w + zx] == -1:
		_claim_zone(zx, zy, city_id, int(_city_faction[city_id]))
	_zone_flags[zy * _zone_w + zx] |= ZONE_FLAG_BUILT

	if pos.distance_squared_to(_city_center[city_id]) > 9.0:
		var kind: int = ROAD_CONDUIT if int(_city_tech_tier[city_id]) >= 2 else ROAD_DIRT
		_stamp_road(_city_center[city_id], pos, kind)

	if _physics != null and _physics.has_method("clear_footprint"):
		_physics.clear_footprint(pos, avoid_r)

	if not quiet_audio and _fx != null:
		if _fx.has_method("emit_build_pop"):
			_fx.emit_build_pop(pos)
		else:
			if _fx.has_method("play_sfx"):
				_fx.play_sfx("build_pop")
			if _fx.has_method("spawn_burst"):
				_fx.spawn_burst(pos, 3, Color(0.84, 0.78, 0.68, 0.85), 14.0, 0.35, -10.0)

	return bidx


func _remove_building(bidx: int) -> void:
	if bidx < 0 or bidx >= _bld_count:
		return
	var cid: int = _bld_city_id[bidx]
	var btype: int = int(_bld_type[bidx])
	if cid >= 0 and cid < _max_cities:
		var slot: int = cid * BLD_TYPE_COUNT + btype
		_city_bld_counts[slot] = maxi(0, _city_bld_counts[slot] - 1)
		_city_tech_dirty[cid] = 1
		if btype == BuildingType.DEPOT:
			_city_storage_cap[cid] = maxf(float(TUNING_KNOBS["BASE_STORAGE_CAP"]), _city_storage_cap[cid] - float(TUNING_KNOBS["DEPOT_STORAGE_BONUS"]))
		elif btype == BuildingType.LAUNCHPAD:
			_city_storage_cap[cid] = maxf(float(TUNING_KNOBS["BASE_STORAGE_CAP"]), _city_storage_cap[cid] - float(TUNING_KNOBS["LAUNCHPAD_STORAGE_BONUS"]))

	var last: int = _bld_count - 1
	if bidx != last:
		_bld_pos[bidx] = _bld_pos[last]
		_bld_type[bidx] = _bld_type[last]
		_bld_radius[bidx] = _bld_radius[last]
		_bld_city_id[bidx] = _bld_city_id[last]
		_bld_hp[bidx] = _bld_hp[last]
		_bld_spring[bidx] = _bld_spring[last]
		_bld_spring_vel[bidx] = _bld_spring_vel[last]
		_bld_shake[bidx] = _bld_shake[last]
		_bld_phase[bidx] = _bld_phase[last]
		_bld_color[bidx] = _bld_color[last]
		_bld_shield_charge[bidx] = _bld_shield_charge[last]
		_bld_shield_flash[bidx] = _bld_shield_flash[last]
	_bld_count = last
	_buildings_dirty = true
	_bld_footprints_dirty = true
	_goals_dirty = true


func _stamp_road(p0: Vector2, p1: Vector2, road_kind: int) -> void:
	var x0: int = clampi(int(floor(p0.x)), 1, _map_w - 2)
	var y0: int = clampi(int(floor(p0.y)), 1, _map_h - 2)
	var x1: int = clampi(int(floor(p1.x)), 1, _map_w - 2)
	var y1: int = clampi(int(floor(p1.y)), 1, _map_h - 2)

	# 1px crisp L-shaped vein centerline; steel #3A4859 outer rails render automatically around it
	var step_x: int = 1 if x1 >= x0 else -1
	var cx: int = x0
	while cx != x1:
		_stamp_road_1px(cx, y0, road_kind)
		cx += step_x

	var step_y: int = 1 if y1 >= y0 else -1
	var cy: int = y0
	while cy != y1:
		_stamp_road_1px(x1, cy, road_kind)
		cy += step_y
	_stamp_road_1px(x1, y1, road_kind)


func _stamp_road_1px(tx: int, ty: int, road_kind: int) -> void:
	if tx < 1 or tx >= _map_w - 1 or ty < 1 or ty >= _map_h - 1:
		return
	if _world != null and int(_world.get_tier(tx, ty)) <= TIER_CLOSE_OCEAN:
		return
	var idx: int = ty * _map_w + tx
	var old_r: int = _road_mask[idx]
	if road_kind <= old_r:
		return
	if old_r == ROAD_NONE:
		_road_px_count += 1
	_road_mask[idx] = road_kind
	var zx: int = tx / _zone_px
	var zy: int = ty / _zone_px
	_zone_flags[zy * _zone_w + zx] |= ZONE_FLAG_ROAD
	_mark_zone_dirty(zx, zy)
	_goals_dirty = true


func _is_building_spot_valid(pos: Vector2, bld_type: int, faction_id: int = 0) -> bool:
	var px: int = int(floor(pos.x))
	var py: int = int(floor(pos.y))
	if px < 10 or px >= _map_w - 10 or py < 14 or py >= _map_h - 8:
		return false
	if _world != null:
		for sy in range(3):
			var oy: int = -3 if sy == 0 else (0 if sy == 1 else 2)
			for sx in range(3):
				var ox: int = (sx - 1) * 4
				if not _is_pixel_walkable_for_faction(px + ox, py + oy, faction_id):
					return false
	var min_sep: float = BLD_FOOTPRINTS[bld_type]
	for i in range(_bld_count):
		var other_sep: float = BLD_FOOTPRINTS[int(_bld_type[i])]
		var req: float = (min_sep + other_sep) * 0.5
		if _bld_pos[i].distance_squared_to(pos) < req * req:
			return false
	return true


func _find_building_spot(city_id: int, bld_type: int) -> Vector2:
	var center: Vector2 = _city_center[city_id]
	var f_id: int = int(_city_faction[city_id])
	var best_pos: Vector2 = Vector2(-1.0, -1.0)
	var best_score: float = -1e9

	var czx: int = clampi(int(floor(center.x / float(_zone_px))), 0, _zone_w - 1)
	var czy: int = clampi(int(floor(center.y / float(_zone_px))), 0, _zone_h - 1)
	var scan_r: int = 7 if _city_zones_count[city_id] >= 12 else 5

	for zy in range(maxi(0, czy - scan_r), mini(_zone_h, czy + scan_r + 1)):
		for zx in range(maxi(0, czx - scan_r), mini(_zone_w, czx + scan_r + 1)):
			var zidx: int = zy * _zone_w + zx
			var owner: int = _zone_city_id[zidx]
			if owner != city_id and owner != -1:
				continue
			if owner == -1 and not _is_zone_claimable(zx, zy, f_id):
				continue

			var cand: Vector2 = _zone_walkable_center(zx, zy, f_id)
			if cand.x < 0.0:
				continue
			if not _is_building_spot_valid(cand, bld_type, f_id):
				cand += Vector2(_rng.randf_range(-2.0, 2.0), _rng.randf_range(-2.0, 2.0))
				if not _is_building_spot_valid(cand, bld_type, f_id):
					continue

			var d: float = cand.distance_to(center)
			var score: float = 100.0 - d * 1.15
			if owner == city_id:
				score += 48.0
			if bld_type == BuildingType.DRILL:
				score += float(_zone_ore[zidx]) * 3.2
			elif bld_type == BuildingType.BIODOME:
				score += _zone_fertility[zidx] * 20.0
			elif bld_type == BuildingType.LAUNCHPAD and _is_zone_coastal(zx, zy):
				score += 36.0
			elif bld_type == BuildingType.SHIELD_PYLON and d <= 28.0:
				score += 32.0
			elif bld_type == BuildingType.QUANTUM_GATE:
				if _is_zone_coastal(zx, zy):
					score += 18.0
				if d >= 18.0 and d <= 48.0:
					score += 28.0
			if score > best_score:
				best_score = score
				best_pos = cand

	if best_pos.x >= 0.0:
		return best_pos

	for ring in range(1, 6):
		var rad: float = 10.0 + float(ring) * 6.5
		for k in range(12):
			var ang: float = float(k) * (TAU / 12.0) + float(ring) * 0.35
			var cand: Vector2 = center + Vector2(cos(ang), sin(ang)) * rad
			if _is_building_spot_valid(cand, bld_type, f_id):
				return cand
	return Vector2(-1.0, -1.0)


func _recompute_city_tech(city_id: int) -> void:
	var dim_count: int = int(TUNING_KNOBS["TIER_DUP_DIMINISH_COUNT"])
	var mid_w: float = float(TUNING_KNOBS["DUP_MID_WEIGHT"])
	var base_b: int = city_id * BLD_TYPE_COUNT
	var score: float = 0.0

	for bt in range(BLD_TYPE_COUNT):
		var n: int = _city_bld_counts[base_b + bt]
		if n <= 0:
			continue
		var full_n: int = mini(n, dim_count)
		var mid_n: int = clampi(n - dim_count, 0, dim_count)
		var pts: float = BLD_TECH_POINTS[bt]
		score += float(full_n) * pts + float(mid_n) * pts * mid_w

	_city_tech_score[city_id] = score
	var sci: float = _city_science[city_id]
	var pop: int = maxi(_city_pop[city_id], int(TUNING_KNOBS["START_CITY_POP"]) if _city_bld_counts[base_b + BuildingType.TENT] >= 1 else 0)
	var drills: int = _city_bld_counts[base_b + BuildingType.DRILL]
	var reactors: int = _city_bld_counts[base_b + BuildingType.FUSION_REACTOR]
	var pads: int = _city_bld_counts[base_b + BuildingType.LAUNCHPAD]

	var tier: int = 0
	if sci >= 24.0 and pop >= 10 and score >= 4.5:
		tier = 1
	if tier >= 1 and sci >= 70.0 and drills >= 1 and score >= 7.5:
		tier = 2
	if tier >= 2 and sci >= float(TUNING_KNOBS["TIER3_SCI_REQ"]) and reactors >= 1 and score >= float(TUNING_KNOBS["TIER3_SCORE_REQ"]):
		tier = 3
	if tier >= 3 and sci >= float(TUNING_KNOBS["TIER4_SCI_REQ"]) and pads >= 1 and score >= float(TUNING_KNOBS["TIER4_SCORE_REQ"]):
		tier = 4

	var floor_tier: int = clampi(int(_city_tech_floor[city_id]), 0, 4)
	if floor_tier > tier:
		tier = floor_tier

	var prev_tier: int = int(_city_tech_tier[city_id])
	_city_tech_dirty[city_id] = 0
	if tier != prev_tier:
		_city_tech_tier[city_id] = tier
		_goals_dirty = true
		if tier >= 2 and prev_tier < 2:
			_upgrade_city_roads_to_conduits(city_id)


func _upgrade_city_roads_to_conduits(city_id: int) -> void:
	for zy in range(_zone_h):
		for zx in range(_zone_w):
			var zidx: int = zy * _zone_w + zx
			if _zone_city_id[zidx] != city_id:
				continue
			if (_zone_flags[zidx] & ZONE_FLAG_ROAD) == 0:
				continue
			_zone_flags[zidx] |= ZONE_FLAG_POWERED
			var changed_zone: bool = false
			var py0: int = zy * _zone_px
			var px0: int = zx * _zone_px
			for py in range(py0, mini(_map_h, py0 + _zone_px)):
				var row_off: int = py * _map_w
				for px in range(px0, mini(_map_w, px0 + _zone_px)):
					if _road_mask[row_off + px] == ROAD_DIRT:
						_road_mask[row_off + px] = ROAD_CONDUIT
						changed_zone = true
			if changed_zone:
				_mark_zone_dirty(zx, zy)
				_goals_dirty = true


func _pick_next_building_type(city_id: int) -> int:
	var base_b: int = city_id * BLD_TYPE_COUNT
	var f_id: int = int(_city_faction[city_id])
	var tier: int = int(_city_tech_tier[city_id])
	var campfires: int = _city_bld_counts[base_b + BuildingType.CAMPFIRE]
	var tents: int = _city_bld_counts[base_b + BuildingType.TENT]
	var depots: int = _city_bld_counts[base_b + BuildingType.DEPOT]
	var drills: int = _city_bld_counts[base_b + BuildingType.DRILL]
	var solars: int = _city_bld_counts[base_b + BuildingType.SOLAR_ARRAY]
	var domes: int = _city_bld_counts[base_b + BuildingType.BIODOME]
	var reactors: int = _city_bld_counts[base_b + BuildingType.FUSION_REACTOR]
	var pads: int = _city_bld_counts[base_b + BuildingType.LAUNCHPAD]
	var pylons: int = _city_bld_counts[base_b + BuildingType.SHIELD_PYLON]
	var gates: int = _city_bld_counts[base_b + BuildingType.QUANTUM_GATE]

	var city_total: int = campfires + tents + depots + drills + solars + domes + reactors + pads + pylons + gates
	var max_city_blds: int = clampi(12 + _city_zones_count[city_id] / 2 + tier * 4, 12, int(TUNING_KNOBS["MAX_CITY_BUILDINGS"]))
	if city_total >= max_city_blds:
		return -1

	# Rebuild critical hub structures immediately if blasted
	if campfires < 1:
		return BuildingType.CAMPFIRE
	if _city_energy[city_id] < 3.0 and solars < 2:
		return BuildingType.SOLAR_ARRAY

	# Core economy & Tier 2..4 flagship unlocks take precedence over border clash defense
	var pop: int = _city_pop[city_id]
	var h_cap: int = _city_housing_cap(city_id)
	if drills < 1:
		return BuildingType.DRILL
	if depots < 1:
		return BuildingType.DEPOT
	var pylon_cap: int = 2 if (_city_zones_count[city_id] >= 16 or tier >= 3) else 1
	if tier >= 2:
		if pylons < 1:
			return BuildingType.SHIELD_PYLON
		if pads < 1:
			return BuildingType.LAUNCHPAD
	var gate_cap: int = clampi(int(TUNING_KNOBS["QUANTUM_GATE_MAX_PER_CITY"]), 1, 2)
	var gate_e_min: float = float(TUNING_KNOBS["QUANTUM_GATE_ENERGY_MIN"])
	if tier >= 4 and gates < 1 and _city_energy[city_id] >= gate_e_min:
		return BuildingType.QUANTUM_GATE
	if tier >= 3 and reactors < 1:
		return BuildingType.FUSION_REACTOR

	# Border clash defense shift: prioritize logistics, grid pylons & housing for patrol sustain
	if _city_alerted[city_id] != 0:
		if depots < 2:
			return BuildingType.DEPOT
		if solars < 2 and tier >= 1:
			return BuildingType.SOLAR_ARRAY
		if drills < 3:
			return BuildingType.DRILL
		if domes < 2 and tier >= 2 and f_id != Faction.ROBOT:
			return BuildingType.BIODOME

	if pop >= h_cap - 1 and tents < 2:
		return BuildingType.TENT
	if tents < 2:
		return BuildingType.TENT

	if f_id == Faction.ROBOT:
		# Robots favor extractors, power pylons, reactors, launch gantries; skip biological farming early
		if drills < 2:
			return BuildingType.DRILL
		if solars < 1:
			return BuildingType.SOLAR_ARRAY
		if tier >= 1 and drills < 3:
			return BuildingType.DRILL
		if tier >= 2:
			if reactors < 1:
				return BuildingType.FUSION_REACTOR
			if depots < 2:
				return BuildingType.DEPOT
			if solars < 3:
				return BuildingType.SOLAR_ARRAY
			if pylons < pylon_cap:
				return BuildingType.SHIELD_PYLON
		if pop >= h_cap - 2 and tents < 7:
			return BuildingType.TENT
		if drills < 5:
			return BuildingType.DRILL
		if tier >= 2 and reactors < 2:
			return BuildingType.FUSION_REACTOR
	elif f_id == Faction.SPORE:
		# Spore expands bio-domes/hives early alongside extractors and spires
		if drills < 2 and tier >= 1:
			return BuildingType.DRILL
		if tier >= 1 and domes < 1:
			return BuildingType.BIODOME
		if tents < 3:
			return BuildingType.TENT
		if tier >= 2:
			if solars < 1:
				return BuildingType.SOLAR_ARRAY
			if domes < 3:
				return BuildingType.BIODOME
			if reactors < 1:
				return BuildingType.FUSION_REACTOR
			if pylons < pylon_cap:
				return BuildingType.SHIELD_PYLON
		if pop >= h_cap - 2 and domes < 4:
			return BuildingType.BIODOME
		if drills < 4:
			return BuildingType.DRILL
		if solars < 3:
			return BuildingType.SOLAR_ARRAY
	else:
		# Human balanced progression
		if tier >= 1 and drills < 2:
			return BuildingType.DRILL
		if tents < 3:
			return BuildingType.TENT
		if tier >= 2:
			if solars < 1:
				return BuildingType.SOLAR_ARRAY
			if domes < 1:
				return BuildingType.BIODOME
			if reactors < 1:
				return BuildingType.FUSION_REACTOR
			if pylons < pylon_cap:
				return BuildingType.SHIELD_PYLON
		if drills < 3:
			return BuildingType.DRILL
		if depots < 2:
			return BuildingType.DEPOT
		if pop >= h_cap - 2:
			return BuildingType.BIODOME if tier >= 2 and domes < 4 else BuildingType.TENT
		if tier >= 2 and solars < 3:
			return BuildingType.SOLAR_ARRAY
		if tier >= 2 and domes < 3:
			return BuildingType.BIODOME
		if tier >= 3 and pads < 2:
			return BuildingType.LAUNCHPAD

	if tier >= 4 and gates < gate_cap and _city_zones_count[city_id] >= 12 and _city_energy[city_id] >= gate_e_min * 1.35:
		return BuildingType.QUANTUM_GATE
	if tier >= 3 and pylons < pylon_cap:
		return BuildingType.SHIELD_PYLON
	if tier >= 3 and reactors < 2:
		return BuildingType.FUSION_REACTOR
	if tier >= 3 and pads < 2 and _is_city_coastal(city_id):
		return BuildingType.LAUNCHPAD

	# Ongoing district outpost scaling beyond basic quota while under max_city_blds
	if _city_zones_count[city_id] >= 12:
		var cycle: int = city_total % 4
		if cycle == 0 and drills < 6:
			return BuildingType.DRILL
		if cycle == 1 and solars < 5:
			return BuildingType.SOLAR_ARRAY
		if cycle == 2 and f_id != Faction.ROBOT and domes < 5:
			return BuildingType.BIODOME
		if depots < 4:
			return BuildingType.DEPOT
	return -1


func _start_next_project(city_id: int) -> void:
	var prev_type: int = _city_proj_type[city_id]
	var prev_pos: Vector2 = _city_build_pos[city_id]
	var fallback_pos: Vector2 = _city_center[city_id]
	if _bld_count >= _max_buildings:
		_city_proj_type[city_id] = -1
		if prev_pos.distance_squared_to(fallback_pos) > 0.25:
			_city_build_pos[city_id] = fallback_pos
			_goals_dirty = true
		return
	var next_t: int = _pick_next_building_type(city_id)
	if next_t < 0:
		# Attempt in-place modernization (upgrade old Tent into Biodome on dense hubs)
		var base_b: int = city_id * BLD_TYPE_COUNT
		if int(_city_tech_tier[city_id]) >= 2 and int(_city_faction[city_id]) != Faction.ROBOT and _city_bld_counts[base_b + BuildingType.TENT] >= 3 and _city_ore[city_id] >= BLD_ORE_COSTS[BuildingType.BIODOME]:
			for bi in range(_bld_count):
				if _bld_city_id[bi] == city_id and _bld_type[bi] == BuildingType.TENT and _bld_pos[bi].distance_squared_to(_city_center[city_id]) > 25.0:
					var up_pos: Vector2 = _bld_pos[bi]
					_remove_building(bi)
					_city_proj_type[city_id] = BuildingType.BIODOME
					_city_proj_prog[city_id] = 0.0
					_city_proj_work[city_id] = 0.0
					_city_build_pos[city_id] = up_pos
					_buildings_dirty = true
					_goals_dirty = true
					return
		_city_proj_type[city_id] = -1
		if prev_pos.distance_squared_to(fallback_pos) > 0.25:
			_city_build_pos[city_id] = fallback_pos
			_goals_dirty = true
		return
	var spot: Vector2 = _find_building_spot(city_id, next_t)
	if spot.x < 0.0:
		_city_proj_type[city_id] = -1
		if prev_pos.distance_squared_to(fallback_pos) > 0.25:
			_city_build_pos[city_id] = fallback_pos
			_goals_dirty = true
		return
	_city_proj_type[city_id] = next_t
	_city_proj_prog[city_id] = 0.0
	_city_proj_work[city_id] = 0.0
	_buildings_dirty = true
	if prev_type != next_t or prev_pos.distance_squared_to(spot) > 0.25:
		_city_build_pos[city_id] = spot
		_goals_dirty = true


func _expand_city_territory(city_id: int) -> bool:
	var best_zx: int = -1
	var best_zy: int = -1
	var best_score: float = -1e9
	var center: Vector2 = _city_center[city_id]
	var f_id: int = int(_city_faction[city_id])
	var czx: int = clampi(int(floor(center.x / float(_zone_px))), 0, _zone_w - 1)
	var czy: int = clampi(int(floor(center.y / float(_zone_px))), 0, _zone_h - 1)
	var scan_r: int = clampi(8 + _city_zones_count[city_id] / 3, 10, 24)
	var zx0: int = maxi(0, czx - scan_r)
	var zy0: int = maxi(0, czy - scan_r)
	var zx1: int = mini(_zone_w - 1, czx + scan_r)
	var zy1: int = mini(_zone_h - 1, czy + scan_r)

	for zy in range(zy0, zy1 + 1):
		var row_off: int = zy * _zone_w
		for zx in range(zx0, zx1 + 1):
			var zidx: int = row_off + zx
			if _zone_city_id[zidx] != -1:
				continue
			var adj_owned: bool = (
				_get_zone_owner(zx - 1, zy) == city_id
				or _get_zone_owner(zx + 1, zy) == city_id
				or _get_zone_owner(zx, zy - 1) == city_id
				or _get_zone_owner(zx, zy + 1) == city_id
			)
			if not adj_owned:
				continue

			var z_pos := Vector2((float(zx) + 0.5) * float(_zone_px), (float(zy) + 0.5) * float(_zone_px))
			var score: float = 50.0 - z_pos.distance_to(center) * 0.45
			if f_id == Faction.SPORE:
				score += _zone_fertility[zidx] * 26.0 + float(_zone_ore[zidx]) * 0.8
			elif f_id == Faction.ROBOT:
				score += float(_zone_ore[zidx]) * 2.4 + _zone_fertility[zidx] * 6.0
			else:
				score += float(_zone_ore[zidx]) * 1.6 + _zone_fertility[zidx] * 14.0
			if score <= best_score:
				continue
			if not _is_zone_claimable(zx, zy, f_id):
				continue
			best_score = score
			best_zx = zx
			best_zy = zy

	if best_zx < 0:
		return false

	_claim_zone(best_zx, best_zy, city_id, f_id)
	return true


func _refresh_city_targets(city_id: int) -> void:
	var center: Vector2 = _city_center[city_id]
	var f_id: int = int(_city_faction[city_id])
	var czx: int = clampi(int(floor(center.x / float(_zone_px))), 0, _zone_w - 1)
	var czy: int = clampi(int(floor(center.y / float(_zone_px))), 0, _zone_h - 1)

	# 1) Best ore/crystal target near city (evaluate score before walkability check)
	var best_mine: Vector2 = center
	var best_mine_score: float = -1e9
	for zy in range(maxi(0, czy - 10), mini(_zone_h, czy + 11)):
		var row_off: int = zy * _zone_w
		for zx in range(maxi(0, czx - 10), mini(_zone_w, czx + 11)):
			var zidx: int = row_off + zx
			var owner: int = _zone_city_id[zidx]
			if owner != -1 and owner != city_id:
				continue
			var ore: int = _zone_ore[zidx]
			if ore <= 0:
				continue
			var approx_pos := Vector2((float(zx) + 0.5) * float(_zone_px), (float(zy) + 0.5) * float(_zone_px))
			var score: float = float(ore) * 3.0 - approx_pos.distance_to(center) * 1.1
			if owner == city_id:
				score += 20.0
			if score <= best_mine_score:
				continue
			var pos: Vector2 = _zone_walkable_center(zx, zy, f_id)
			if pos.x >= 0.0:
				best_mine_score = score
				best_mine = pos
	if _city_mine_pos[city_id].distance_squared_to(best_mine) > 0.25:
		_city_mine_pos[city_id] = best_mine
		_goals_dirty = true

	# 2) Outer perimeter patrol point (only query walkability on selected zone!)
	var new_patrol: Vector2 = center
	if _city_alerted[city_id] != 0 and _city_threat_pos[city_id].length_squared() > 1.0:
		new_patrol = _city_threat_pos[city_id]
	else:
		var patrol_zones: Array[Vector2i] = []
		for zy in range(maxi(0, czy - 9), mini(_zone_h, czy + 10)):
			for zx in range(maxi(0, czx - 9), mini(_zone_w, czx + 10)):
				if _get_zone_owner(zx, zy) != city_id:
					continue
				if (
					_get_zone_owner(zx - 1, zy) != city_id
					or _get_zone_owner(zx + 1, zy) != city_id
					or _get_zone_owner(zx, zy - 1) != city_id
					or _get_zone_owner(zx, zy + 1) != city_id
				):
					patrol_zones.append(Vector2i(zx, zy))
		if not patrol_zones.is_empty():
			var pick: int = int(floor(_sim_time * 0.5 + float(city_id))) % patrol_zones.size()
			var pz: Vector2i = patrol_zones[pick]
			var ppos: Vector2 = _zone_walkable_center(pz.x, pz.y, f_id)
			if ppos.x >= 0.0:
				new_patrol = ppos
	if _city_patrol_pos[city_id].distance_squared_to(new_patrol) > 0.25:
		_city_patrol_pos[city_id] = new_patrol
		_goals_dirty = true


func _building_max_hp(bld_type: int, faction_id: int) -> float:
	var base_hp: float = 180.0 if bld_type == BuildingType.QUANTUM_GATE else (140.0 if bld_type == BuildingType.SHIELD_PYLON else (120.0 if bld_type >= BuildingType.BIODOME else 100.0))
	if faction_id == Faction.ROBOT:
		return base_hp * 1.15
	if faction_id == Faction.SPORE:
		return base_hp * 0.95
	return base_hp


func _city_housing_cap(city_id: int) -> int:
	var base_b: int = city_id * BLD_TYPE_COUNT
	var tents: int = _city_bld_counts[base_b + BuildingType.TENT]
	var depots: int = _city_bld_counts[base_b + BuildingType.DEPOT]
	var domes: int = _city_bld_counts[base_b + BuildingType.BIODOME]
	var f_id: int = int(_city_faction[city_id])
	var cap: int = int(TUNING_KNOBS["START_CITY_POP"]) + tents * 4 + domes * 8
	if f_id == Faction.ROBOT:
		cap += depots * 3
	return cap


func _is_zone_walkable_enough_for(zx: int, zy: int, faction_id: int) -> bool:
	if _world == null:
		return true
	var px0: int = zx * _zone_px
	var py0: int = zy * _zone_px
	var px1: int = mini(_map_w, px0 + _zone_px)
	var py1: int = mini(_map_h, py0 + _zone_px)
	var walk_n: int = 0
	for py in range(py0, py1, 2):
		for px in range(px0, px1, 2):
			if _is_pixel_walkable_for_faction(px, py, faction_id):
				walk_n += 1
	return walk_n >= 4


func _is_zone_coastal(zx: int, zy: int) -> bool:
	if _world == null:
		return false
	for dy in range(-2, 3):
		var nzy: int = zy + dy
		if nzy < 0 or nzy >= _zone_h:
			continue
		for dx in range(-2, 3):
			var nzx: int = zx + dx
			if nzx < 0 or nzx >= _zone_w:
				continue
			var px: int = clampi(nzx * _zone_px + 4, 0, _map_w - 1)
			var py: int = clampi(nzy * _zone_px + 4, 0, _map_h - 1)
			if int(_world.get_tier(px, py)) <= TIER_SHALLOW:
				return true
	return false


func _is_city_coastal(city_id: int) -> bool:
	if city_id >= 0 and city_id < _max_cities:
		var cached: int = int(_city_coastal_cache[city_id])
		if cached != 0:
			return cached == 2
	var c: Vector2 = _city_center[city_id]
	var czx: int = clampi(int(floor(c.x / float(_zone_px))), 0, _zone_w - 1)
	var czy: int = clampi(int(floor(c.y / float(_zone_px))), 0, _zone_h - 1)
	var coastal: bool = _is_zone_coastal(czx, czy)
	if not coastal:
		for zy in range(maxi(0, czy - 5), mini(_zone_h, czy + 6)):
			var row_off: int = zy * _zone_w
			for zx in range(maxi(0, czx - 5), mini(_zone_w, czx + 6)):
				if _zone_city_id[row_off + zx] == city_id and _is_zone_coastal(zx, zy):
					coastal = true
					break
			if coastal:
				break
	if city_id >= 0 and city_id < _max_cities:
		_city_coastal_cache[city_id] = 2 if coastal else 1
	return coastal


func step_civ(dt: float) -> void:
	_ensure_initialized()
	var safe_dt: float = clampf(dt, 0.0, 0.25)
	if safe_dt <= 0.0:
		return
	_sim_time += safe_dt

	for cid in range(_max_cities):
		if _city_active[cid] == 0:
			continue
		_step_single_city(cid, safe_dt)

	_env_check_timer -= safe_dt
	if _env_check_timer <= 0.0:
		_env_check_timer = 0.50
		_step_buildings_environment(0.50)

	_clash_scan_timer -= safe_dt
	if _clash_scan_timer <= 0.0:
		_clash_scan_timer = 0.45
		_update_border_clashes(0.45)

	_diplo_scan_timer -= safe_dt
	if _diplo_scan_timer <= 0.0:
		var d_step: float = float(TUNING_KNOBS["DIPLO_SCAN_SEC"])
		_diplo_scan_timer = d_step
		_step_diplomacy_and_loyalty(d_step)

	_capture_scan_timer -= safe_dt
	if _capture_scan_timer <= 0.0:
		var c_step: float = float(TUNING_KNOBS["WAR_CAPTURE_SCAN_SEC"])
		_capture_scan_timer = c_step
		_step_wartime_capture(c_step)

	_ruin_tick_timer -= safe_dt
	if _ruin_tick_timer <= 0.0:
		_ruin_tick_timer = 0.45
		_step_ruins_salvage()

	_shuttle_launch_timer -= safe_dt
	if _shuttle_launch_timer <= 0.0:
		_shuttle_launch_timer = 1.0
		_try_launch_shuttles()

	_supply_scan_timer -= safe_dt
	if _supply_scan_timer <= 0.0:
		_supply_scan_timer = float(TUNING_KNOBS["SUPPLY_SCAN_SEC"])
		_try_supply_sister_cities()

	if _shuttle_count > 0:
		_step_shuttles(safe_dt)
		_buildings_dirty = true

	_step_shield_pylons(safe_dt)
	var springs_moved: bool = _step_building_springs(safe_dt)
	_flush_dirty_borders()
	var anim_step: int = int(floor(_sim_time * 8.0))
	var has_dyn_slots: bool = (_bld_count > 0 or _ruin_count > 0 or _shuttle_count > 0)
	if _buildings_dirty or springs_moved or (has_dyn_slots and anim_step != _bld_anim_step):
		_sync_buildings_multimesh(_buildings_dirty)
		_buildings_dirty = false
		_bld_anim_step = anim_step
	_push_goal_buffers()


func _step_single_city(cid: int, dt: float) -> void:
	if _city_emp_timer[cid] > 0.0:
		_city_emp_timer[cid] = maxf(0.0, _city_emp_timer[cid] - dt)
		if _city_emp_timer[cid] <= 0.0:
			_goals_dirty = true
			_buildings_dirty = true
	if _city_war_cooldown[cid] > 0.0:
		_city_war_cooldown[cid] = maxf(0.0, _city_war_cooldown[cid] - dt)

	var base_b: int = cid * BLD_TYPE_COUNT
	var f_id: int = int(_city_faction[cid])
	var cap: float = _city_storage_cap[cid]
	var pop: int = _city_pop[cid]
	if _physics != null and _physics.has_method("get_city_pop"):
		var live_pop: int = int(_physics.get_city_pop(cid))
		if live_pop != pop:
			pop = live_pop
			_city_pop[cid] = pop
			_city_tech_dirty[cid] = 1

	var campfires: int = _city_bld_counts[base_b + BuildingType.CAMPFIRE]
	var drills: int = _city_bld_counts[base_b + BuildingType.DRILL]
	var solars: int = _city_bld_counts[base_b + BuildingType.SOLAR_ARRAY]
	var domes: int = _city_bld_counts[base_b + BuildingType.BIODOME]
	var reactors: int = _city_bld_counts[base_b + BuildingType.FUSION_REACTOR]
	var tents: int = _city_bld_counts[base_b + BuildingType.TENT]

	# Sample center terrain for asymmetric faction bonuses
	var cpx: int = clampi(int(floor(_city_center[cid].x)), 0, _map_w - 1)
	var cpy: int = clampi(int(floor(_city_center[cid].y)), 0, _map_h - 1)
	var center_biome: int = BIOME_RUST
	var center_rad: float = 0.0
	var center_moist: float = 0.35
	if _world != null:
		center_biome = int(_world.get_biome(cpx, cpy))
		center_rad = float(_world.get_rad(cpx, cpy))
		if _world.has_method("get_moisture"):
			center_moist = float(_world.call("get_moisture", cpx, cpy))

	var early_scavenge: float = 0.95 if drills == 0 else 0.0
	var ore_mult: float = 1.0
	var food_mult: float = 1.0
	var rad_energy_bonus: float = 0.0
	if f_id == Faction.ROBOT:
		# Robots gain ore bonus on SCORCHED/CRYSTAL terrain and harvest ambient radiation into Energy
		if center_biome == BIOME_CRYSTAL or center_biome == BIOME_SCORCHED:
			ore_mult = 1.28
		rad_energy_bonus = maxf(0.0, center_rad) * float(TUNING_KNOBS["ROBOT_RAD_ENERGY_GAIN"]) * (1.0 + float(solars) * 0.35)
		food_mult = 0.25
	elif f_id == Faction.SPORE:
		# Spore thrives on LUSH flora & moisture/water
		if center_biome == BIOME_LUSH or center_moist >= 0.45:
			food_mult = 1.45
		elif _is_city_coastal(cid):
			food_mult = 1.25

	var ore_gain: float = (float(drills) * 2.4 + early_scavenge) * ore_mult * dt
	var food_gain: float = (float(domes) * 2.5 + (0.65 if f_id == Faction.SPORE and center_biome == BIOME_LUSH else 0.0)) * food_mult * _crop_mul * dt
	var campfire_energy: float = float(campfires) * (0.95 if f_id == Faction.ROBOT else 0.65)
	var energy_gain: float = (campfire_energy + float(solars) * 3.0 * _solar_mul + float(reactors) * 12.0 + rad_energy_bonus) * dt
	var sci_gain: float = (1.1 + float(pop) * 0.24 + float(tents) * 0.35 + float(domes) * 1.5 + float(reactors) * 2.0) * dt

	# Human & Spore consume slow food upkeep; Robot has zero food starvation
	var food_upkeep: float = 0.0
	if f_id != Faction.ROBOT and pop > 4:
		food_upkeep = float(pop - 4) * (0.045 if f_id == Faction.HUMAN else 0.032) * dt

	_city_ore[cid] = minf(cap, _city_ore[cid] + ore_gain)
	_city_food[cid] = clampf(_city_food[cid] + food_gain - food_upkeep, 0.0, cap)
	_city_energy[cid] = minf(cap, _city_energy[cid] + energy_gain)
	_city_science[cid] = minf(maxf(cap * 4.0, 2000.0), _city_science[cid] + sci_gain)

	if _city_shuttle_cd[cid] > 0.0:
		_city_shuttle_cd[cid] = maxf(0.0, _city_shuttle_cd[cid] - dt)

	# Territory expansion (Spore expands much faster & cheaper on lush/bio ground)
	_city_expand_timer[cid] -= dt
	if _city_expand_timer[cid] <= 0.0:
		var exp_cost: float = float(TUNING_KNOBS["ZONE_EXPAND_COST_ORE"])
		var exp_int: float = float(TUNING_KNOBS["ZONE_EXPAND_INTERVAL_SEC"])
		if f_id == Faction.SPORE:
			exp_cost *= float(TUNING_KNOBS["SPORE_EXPAND_ORE_MUL"])
			exp_int *= float(TUNING_KNOBS["SPORE_EXPAND_INTERVAL_MUL"])
		if _city_zones_count[cid] >= 10:
			exp_int *= 1.65
		var proj_t: int = _city_proj_type[cid]
		var proj_reserve: float = BLD_ORE_COSTS[proj_t] * 0.65 if (proj_t >= 0 and proj_t < BLD_TYPE_COUNT) else 0.0
		var pads_n: int = _city_bld_counts[base_b + BuildingType.LAUNCHPAD]
		var shuttle_reserve: float = float(TUNING_KNOBS["SHUTTLE_LAUNCH_ORE"]) if (int(_city_tech_tier[cid]) >= 2 and (pads_n > 0 or _is_city_coastal(cid)) and _city_shuttle_cd[cid] <= 1.0 and not _city_has_active_shuttle(cid)) else 0.0
		var ore_reserve: float = maxf(8.0 if drills == 0 else 5.0, maxf(proj_reserve + 2.0, shuttle_reserve))
		var can_expand_ore: bool = _city_ore[cid] >= exp_cost + ore_reserve
		var can_expand_food: bool = _city_food[cid] >= exp_cost * 1.4
		if can_expand_ore or can_expand_food:
			if _expand_city_territory(cid):
				if f_id == Faction.SPORE and can_expand_food:
					_city_food[cid] -= exp_cost * 1.35
				elif can_expand_ore:
					_city_ore[cid] -= exp_cost
				else:
					_city_food[cid] -= exp_cost * 1.4
				_refresh_city_targets(cid)
			_city_expand_timer[cid] = exp_int
		else:
			_city_expand_timer[cid] = 0.5

	# Consume worker BUILD_WORK deposits cleanly for repairs & construction (NO free self-build)
	var worker_work: float = _city_proj_work[cid]
	_city_proj_work[cid] = 0.0
	if worker_work > 0.0 and _city_ore[cid] >= 0.4:
		worker_work = _apply_worker_repairs(cid, worker_work, f_id)

	# Autonomous worker-driven building construction with live scaffolding
	if _city_proj_type[cid] < 0:
		_city_proj_retry[cid] -= dt
		if _city_proj_retry[cid] <= 0.0:
			_start_next_project(cid)
			if _city_proj_type[cid] < 0:
				_city_proj_retry[cid] = 1.0
	var ptype: int = _city_proj_type[cid]
	if ptype >= 0 and worker_work > 0.0:
		var req_ore: float = BLD_ORE_COSTS[ptype]
		var req_energy: float = BLD_ENERGY_COSTS[ptype]
		var build_dur: float = BLD_BUILD_TIMES[ptype]
		var energy_ok: bool = (req_energy <= 0.0) or (_city_energy[cid] >= minf(req_energy * 0.25, 0.5))
		var mat_ok: bool = (_city_ore[cid] >= req_ore * 0.25) or (_city_proj_prog[cid] > 0.20) or (ptype == BuildingType.DRILL and drills == 0)
		if energy_ok and mat_ok:
			var speed_mul: float = 1.15 if (f_id == Faction.ROBOT and (center_biome == BIOME_CRYSTAL or center_biome == BIOME_SCORCHED)) else 1.0
			var prog_step: float = (worker_work / maxf(build_dur * 0.55, 0.35)) * speed_mul
			_city_proj_prog[cid] += prog_step
			if req_energy > 0.0:
				var e_step_sp: float = minf(_city_energy[cid], req_energy * minf(prog_step, 1.0) * 0.35)
				_city_energy[cid] = maxf(0.0, _city_energy[cid] - e_step_sp)
				_city_energy_spend_acc[cid] += e_step_sp
		if _city_proj_prog[cid] >= 1.0:
			var bspot: Vector2 = _city_build_pos[cid]
			if not _is_building_spot_valid(bspot, ptype, f_id):
				bspot = _find_building_spot(cid, ptype)
			if bspot.x >= 0.0:
				_city_ore[cid] = maxf(0.0, _city_ore[cid] - minf(req_ore, _city_ore[cid] * 0.55))
				var e_done_sp: float = minf(req_energy * 0.4, _city_energy[cid])
				_city_energy[cid] = maxf(0.0, _city_energy[cid] - e_done_sp)
				_city_energy_spend_acc[cid] += e_done_sp
				_place_building(cid, ptype, bspot, false)
				_city_science[cid] += 15.0
				_recompute_city_tech(cid)
			_city_proj_type[cid] = -1
			_city_proj_prog[cid] = 0.0
			_city_proj_retry[cid] = 0.0
			_buildings_dirty = true
			_start_next_project(cid)
			if _city_proj_type[cid] < 0:
				_city_proj_retry[cid] = 1.0

	var tech_check: bool = _city_tech_dirty[cid] != 0
	if not tech_check:
		var cur_tier: int = int(_city_tech_tier[cid])
		var sci_now: float = _city_science[cid]
		if cur_tier == 0 and sci_now >= 24.0:
			tech_check = true
		elif cur_tier == 1 and sci_now >= 70.0:
			tech_check = true
		elif cur_tier == 2 and sci_now >= float(TUNING_KNOBS["TIER3_SCI_REQ"]):
			tech_check = true
		elif cur_tier == 3 and sci_now >= float(TUNING_KNOBS["TIER4_SCI_REQ"]):
			tech_check = true
	if tech_check:
		_recompute_city_tech(cid)

	_step_city_loyalty(cid, dt)

	# Population growth / free wanderer recruitment tied to housing & faction metabolism
	var housing_cap: int = _city_housing_cap(cid)
	_city_pop_timer[cid] -= dt
	if _city_pop_timer[cid] <= 0.0:
		_city_pop_timer[cid] = float(TUNING_KNOBS["POP_GROWTH_INTERVAL_SEC"]) * (0.85 if f_id == Faction.SPORE else 1.0)
		if pop < housing_cap and _physics != null and _physics.has_method("spawn_colony_units"):
			var total_u: int = int(_physics.get_unit_count()) if _physics.has_method("get_unit_count") else 0
			if total_u + 2 <= int(TUNING_KNOBS["MAX_PLANET_UNITS"]):
				var can_grow: bool = false
				if f_id == Faction.ROBOT:
					if _city_ore[cid] >= 7.0 and _city_energy[cid] >= 6.0:
						_city_ore[cid] -= 5.0
						_city_energy[cid] -= 5.0
						_city_energy_spend_acc[cid] += 5.0
						can_grow = true
				else:
					var food_cost: float = float(TUNING_KNOBS["POP_GROWTH_FOOD_COST"]) * (0.75 if f_id == Faction.SPORE else 1.0)
					if _city_food[cid] >= food_cost + 5.0:
						_city_food[cid] -= food_cost
						can_grow = true
				if can_grow:
					var added: int = int(_physics.spawn_colony_units(cid, _city_center[cid], 2))
					_city_pop[cid] += added
					if added > 0:
						_city_tech_dirty[cid] = 1

	var e_spent_step: float = _city_energy_spend_acc[cid]
	_city_energy_spend_acc[cid] = 0.0
	var inst_e_net: float = (energy_gain - e_spent_step) / maxf(0.001, dt)
	_city_energy_net[cid] = lerpf(_city_energy_net[cid], inst_e_net, minf(1.0, dt * 3.5))


func _apply_worker_repairs(city_id: int, work_avail: float, faction_id: int) -> float:
	var best_idx: int = -1
	var worst_ratio: float = 0.72 if _city_proj_type[city_id] >= 0 else 0.94
	var best_max_hp: float = 100.0
	for i in range(_bld_count):
		if _bld_city_id[i] != city_id:
			continue
		var m_hp: float = _building_max_hp(int(_bld_type[i]), faction_id)
		var r: float = _bld_hp[i] / m_hp
		if r < worst_ratio:
			worst_ratio = r
			best_idx = i
			best_max_hp = m_hp
	if best_idx < 0:
		return work_avail
	var repair_share: float = minf(work_avail, 0.35)
	var heal: float = repair_share * 65.0
	_bld_hp[best_idx] = minf(best_max_hp, _bld_hp[best_idx] + heal)
	if _city_ore[city_id] >= 2.0:
		_city_ore[city_id] = maxf(0.0, _city_ore[city_id] - minf(0.15, _city_ore[city_id] * 0.1))
	_buildings_dirty = true
	return work_avail - repair_share


func _step_buildings_environment(dt: float) -> void:
	if _world == null or _bld_count <= 0:
		return
	var has_fire_api: bool = _world.has_method("get_fire")
	var has_moist_api: bool = _world.has_method("get_moisture")
	var spore_fire_mul: float = float(TUNING_KNOBS["SPORE_FIRE_DMG_MUL"])
	var meltdowns: Array[Vector2] = []
	var melt_cids: Array[int] = []
	var touched_cities: Dictionary = {}

	var bi: int = _bld_count - 1
	while bi >= 0:
		var bpos: Vector2 = _bld_pos[bi]
		var bpx: int = clampi(int(floor(bpos.x)), 0, _map_w - 1)
		var bpy: int = clampi(int(floor(bpos.y)), 0, _map_h - 1)
		var cid: int = _bld_city_id[bi]
		var fid: int = int(_city_faction[clampi(cid, 0, _max_cities - 1)])
		var fire_val: float = float(_world.call("get_fire", bpx, bpy)) if has_fire_api else 0.0
		var biome: int = _world.get_biome(bpx, bpy)
		var temp_c: float = _world.get_temp(bpx, bpy)

		var env_dmg: float = 0.0
		if biome == BIOME_LAVA:
			env_dmg = 42.0 * dt
		elif fire_val > 0.06:
			env_dmg = (18.0 + fire_val * 26.0) * _fire_mul * dt
		elif temp_c > 70.0 and fid != Faction.ROBOT:
			env_dmg = (temp_c - 65.0) * 0.35 * _fire_mul * dt

		if env_dmg > 0.0:
			if fid == Faction.SPORE:
				env_dmg *= spore_fire_mul
			elif fid == Faction.ROBOT and biome != BIOME_LAVA:
				env_dmg *= 0.25 if fire_val > 0.50 else 0.0
			if env_dmg > 0.0:
				if _has_active_dome_near(bpos) and biome != BIOME_LAVA:
					env_dmg *= 0.60
				_bld_hp[bi] -= env_dmg
				_bld_shake[bi] = maxf(_bld_shake[bi], 2.0 + clampf(fire_val, 0.25, 1.0))
				_buildings_dirty = true
				touched_cities[cid] = true
				if _bld_hp[bi] <= 0.0:
					if _bld_type[bi] == BuildingType.FUSION_REACTOR:
						meltdowns.append(bpos)
						melt_cids.append(cid)
					_remove_building(bi)
		elif fid == Faction.SPORE:
			# Spore mycelial regen on cool, lush/moist ground
			var moist: float = float(_world.call("get_moisture", bpx, bpy)) if has_moist_api else 0.3
			if biome == BIOME_LUSH or moist >= 0.45:
				var max_hp: float = _building_max_hp(int(_bld_type[bi]), fid)
				if _bld_hp[bi] < max_hp:
					_bld_hp[bi] = minf(max_hp, _bld_hp[bi] + 2.5 * dt)
					_buildings_dirty = true
		bi -= 1

	for mi in range(meltdowns.size()):
		_trigger_reactor_meltdown(meltdowns[mi], melt_cids[mi])

	var keys: Array = touched_cities.keys()
	for ki in range(keys.size()):
		var tcid: int = int(keys[ki])
		if tcid >= 0 and tcid < _max_cities and _city_active[tcid] != 0:
			_verify_city_integrity_after_damage(tcid)


func _trigger_reactor_meltdown(melt_pos: Vector2, src_cid: int) -> void:
	var melt_r: float = float(TUNING_KNOBS["REACTOR_MELTDOWN_RADIUS"])
	if _fx != null:
		if _fx.has_method("spawn_burst"):
			_fx.spawn_burst(melt_pos, 18, Color(0.35, 1.95, 2.35, 1.0), 58.0, 0.60, 20.0)
		if _fx.has_method("play_sfx"):
			_fx.play_sfx(8)

	if _world != null and _world.has_method("apply_elemental_storm"):
		_world.call("apply_elemental_storm", melt_pos, melt_r, "meltdown_crater")

	if _physics != null and _physics.has_method("bless_or_mutate_area"):
		_physics.call("bless_or_mutate_area", melt_pos, melt_r * 1.6, false)

	if src_cid >= 0 and src_cid < _max_cities and _city_active[src_cid] != 0:
		_city_alerted[src_cid] = 1
		_city_alert_timer[src_cid] = 5.0
		_city_threat_pos[src_cid] = melt_pos
		_goals_dirty = true


func _verify_city_integrity_after_damage(cid: int) -> void:
	var has_bld: bool = false
	var first_bld_pos: Vector2 = Vector2.ZERO
	for i in range(_bld_count):
		if _bld_city_id[i] == cid:
			has_bld = true
			first_bld_pos = _bld_pos[i]
			break
	if not has_bld or _city_zones_count[cid] <= 0:
		_collapse_city(cid)
		return
	var cpx: int = clampi(int(floor(_city_center[cid].x)), 0, _map_w - 1)
	var cpy: int = clampi(int(floor(_city_center[cid].y)), 0, _map_h - 1)
	var fid: int = int(_city_faction[cid])
	if not _is_pixel_walkable_for_faction(cpx, cpy, fid):
		_city_center[cid] = first_bld_pos
		_goals_dirty = true
	if _city_proj_type[cid] >= 0 and not _is_building_spot_valid(_city_build_pos[cid], _city_proj_type[cid], fid):
		_city_proj_type[cid] = -1
		_city_proj_prog[cid] = 0.0
		_city_build_pos[cid] = _city_center[cid]
		_buildings_dirty = true
		_goals_dirty = true
	_recompute_city_tech(cid)
	_refresh_city_targets(cid)


func _update_border_clashes(dt: float) -> void:
	var clash_r: float = float(TUNING_KNOBS["BORDER_CLASH_DIST_PX"])
	var clash_r2: float = clash_r * clash_r
	var changed: bool = false
	var prev_alerted: PackedByteArray = _city_alerted.duplicate()
	var prev_threat: PackedVector2Array = _city_threat_pos.duplicate()
	_tmp_frontier_contacts.fill(0)

	for cid in range(_max_cities):
		if _city_active[cid] == 0:
			_city_alerted[cid] = 0
			_city_alert_timer[cid] = 0.0
			continue
		if _city_alert_timer[cid] > 0.0:
			_city_alert_timer[cid] = maxf(0.0, _city_alert_timer[cid] - dt)
			_city_alerted[cid] = 1
		else:
			_city_alerted[cid] = 0

	var active_cids: Array[int] = []
	for cid in range(_max_cities):
		if _city_active[cid] != 0:
			active_cids.append(cid)

	var best_dist2 := PackedFloat32Array()
	best_dist2.resize(_max_cities)
	best_dist2.fill(1e12)

	var pairs: int = 0
	for i in range(active_cids.size()):
		var a: int = active_cids[i]
		for j in range(i + 1, active_cids.size()):
			var b: int = active_cids[j]
			var d_state: int = int(_diplo_matrix[a * _max_cities + b])
			if d_state == Diplomacy.PACT:
				continue
			var hostile: bool = _are_cities_hostile(a, b)
			if not hostile and _city_faction[a] == _city_faction[b]:
				continue
			var d2: float = _city_center[a].distance_squared_to(_city_center[b])
			if d2 <= clash_r2:
				_tmp_frontier_contacts[a * _max_cities + b] += 1
				_tmp_frontier_contacts[b * _max_cities + a] += 1
				pairs += 1
				var mid: Vector2 = (_city_center[a] + _city_center[b]) * 0.5
				_city_alerted[a] = 1
				_city_alerted[b] = 1
				if d2 < best_dist2[a]:
					best_dist2[a] = d2
					_city_threat_pos[a] = mid
				if d2 < best_dist2[b]:
					best_dist2[b] = d2
					_city_threat_pos[b] = mid

	# Bounded zone frontier adjacency check around active cities (avoids 3600-zone full scan)
	for i in range(active_cids.size()):
		var c_id: int = active_cids[i]
		var cc: Vector2 = _city_center[c_id]
		var czx: int = clampi(int(floor(cc.x / float(_zone_px))), 0, _zone_w - 1)
		var czy: int = clampi(int(floor(cc.y / float(_zone_px))), 0, _zone_h - 1)
		var b_r: int = clampi(4 + _city_zones_count[c_id] / 3, 5, 11)
		var zx0: int = maxi(0, czx - b_r)
		var zy0: int = maxi(0, czy - b_r)
		var zx1: int = mini(_zone_w - 1, czx + b_r)
		var zy1: int = mini(_zone_h - 1, czy + b_r)
		for zy in range(zy0, zy1 + 1):
			for zx in range(zx0, zx1 + 1):
				var oa: int = _get_zone_owner(zx, zy)
				if oa != c_id:
					continue
				var fa: int = int(_city_faction[oa])
				if zx + 1 < _zone_w:
					var ob: int = _get_zone_owner(zx + 1, zy)
					if ob >= 0 and ob != oa and _city_active[ob] != 0:
						var st_ab: int = int(_diplo_matrix[oa * _max_cities + ob])
						if st_ab != Diplomacy.PACT:
							_tmp_frontier_contacts[oa * _max_cities + ob] += 1
							_tmp_frontier_contacts[ob * _max_cities + oa] += 1
							if _are_cities_hostile(oa, ob) or int(_city_faction[ob]) != fa:
								var fx_pos := Vector2(float(zx + 1) * float(_zone_px), (float(zy) + 0.5) * float(_zone_px))
								_mark_hostile_frontier(oa, ob, fx_pos, best_dist2)
								pairs += 1
				if zy + 1 < _zone_h:
					var oc: int = _get_zone_owner(zx, zy + 1)
					if oc >= 0 and oc != oa and _city_active[oc] != 0:
						var st_ac: int = int(_diplo_matrix[oa * _max_cities + oc])
						if st_ac != Diplomacy.PACT:
							_tmp_frontier_contacts[oa * _max_cities + oc] += 1
							_tmp_frontier_contacts[oc * _max_cities + oa] += 1
							if _are_cities_hostile(oa, oc) or int(_city_faction[oc]) != fa:
								var fy_pos := Vector2((float(zx) + 0.5) * float(_zone_px), float(zy + 1) * float(_zone_px))
								_mark_hostile_frontier(oa, oc, fy_pos, best_dist2)
								pairs += 1

	_border_clash_count = pairs
	for idx in range(active_cids.size()):
		var cid: int = active_cids[idx]
		if _city_alerted[cid] != prev_alerted[cid] or _city_threat_pos[cid].distance_squared_to(prev_threat[cid]) > 4.0:
			changed = true
			if _city_alerted[cid] != 0:
				_refresh_city_targets(cid)
	if changed:
		_goals_dirty = true


func _mark_hostile_frontier(ca: int, cb: int, fpos: Vector2, best_dist2: PackedFloat32Array) -> void:
	_city_alerted[ca] = 1
	_city_alerted[cb] = 1
	var da2: float = _city_center[ca].distance_squared_to(fpos)
	if da2 < best_dist2[ca]:
		best_dist2[ca] = da2
		_city_threat_pos[ca] = fpos
	var db2: float = _city_center[cb].distance_squared_to(fpos)
	if db2 < best_dist2[cb]:
		best_dist2[cb] = db2
		_city_threat_pos[cb] = fpos


func _apply_diplomacy_state(city_a: int, city_b: int, new_state: int, manual: bool = false) -> void:
	if city_a < 0 or city_a >= _max_cities or city_b < 0 or city_b >= _max_cities or city_a == city_b:
		return
	if _city_active[city_a] == 0 or _city_active[city_b] == 0:
		return
	var st: int = clampi(new_state, Diplomacy.NEUTRAL, Diplomacy.REBELLION)
	if st == Diplomacy.PACT and int(_city_faction[city_a]) != int(_city_faction[city_b]):
		if int(_city_faction[city_a]) == Faction.SPORE or int(_city_faction[city_b]) == Faction.SPORE:
			if not manual:
				return
	var idx_ab: int = city_a * _max_cities + city_b
	var idx_ba: int = city_b * _max_cities + city_a
	var prev_st: int = int(_diplo_matrix[idx_ab])
	_diplo_matrix[idx_ab] = st
	_diplo_matrix[idx_ba] = st
	if st == Diplomacy.PACT:
		_diplo_tension[idx_ab] = -40.0
		_diplo_tension[idx_ba] = -40.0
	elif st == Diplomacy.TOTAL_WAR:
		_diplo_tension[idx_ab] = 65.0
		_diplo_tension[idx_ba] = 65.0
	elif st == Diplomacy.REBELLION:
		_diplo_tension[idx_ab] = 85.0
		_diplo_tension[idx_ba] = 85.0
	else:
		_diplo_tension[idx_ab] = 0.0
		_diplo_tension[idx_ba] = 0.0

	var cd: float = float(TUNING_KNOBS["DIPLO_WAR_COOLDOWN_SEC"]) if (manual or st >= Diplomacy.TOTAL_WAR) else 8.0
	_diplo_pair_cd[idx_ab] = cd
	_diplo_pair_cd[idx_ba] = cd

	if st == Diplomacy.TOTAL_WAR or st == Diplomacy.REBELLION:
		_city_alerted[city_a] = 1
		_city_alerted[city_b] = 1
		_city_alert_timer[city_a] = maxf(_city_alert_timer[city_a], 6.0)
		_city_alert_timer[city_b] = maxf(_city_alert_timer[city_b], 6.0)
		_city_threat_pos[city_a] = _city_center[city_b]
		_city_threat_pos[city_b] = _city_center[city_a]
		_refresh_city_targets(city_a)
		_refresh_city_targets(city_b)

	_recompute_city_war_state(city_a)
	_recompute_city_war_state(city_b)
	_goals_dirty = true

	if prev_st != st and _fx != null and _fx.has_method("spawn_reaction_strip"):
		var mid: Vector2 = (_city_center[city_a] + _city_center[city_b]) * 0.5 + Vector2(0.0, -8.0)
		if st == Diplomacy.PACT:
			_fx.call("spawn_reaction_strip", mid, STRIP_PACT)
		elif st == Diplomacy.TOTAL_WAR:
			_fx.call("spawn_reaction_strip", mid, STRIP_WAR)
		elif st == Diplomacy.REBELLION:
			_fx.call("spawn_reaction_strip", mid, STRIP_REBEL)


func _trigger_city_rebellion(cid: int) -> void:
	if cid < 0 or cid >= _max_cities or _city_active[cid] == 0:
		return
	if _city_is_rebel[cid] != 0:
		return
	_city_is_rebel[cid] = 1
	_rebellions_total += 1
	_city_loyalty[cid] = minf(_city_loyalty[cid], 20.0)
	_city_color[cid] = REBEL_TERRITORY_COLOR
	_city_alerted[cid] = 1
	_city_alert_timer[cid] = maxf(_city_alert_timer[cid], 10.0)

	for bi in range(_bld_count):
		if _bld_city_id[bi] == cid:
			_bld_color[bi] = REBEL_TERRITORY_COLOR
	_buildings_dirty = true
	_mark_city_zones_dirty(cid)

	var c_pos: Vector2 = _city_center[cid]
	var c_fac: int = int(_city_faction[cid])
	var overlord: int = _city_overlord[cid]
	var flipped: int = 0
	var nearest_cid: int = -1
	var nearest_d2: float = 1e18

	for other in range(_max_cities):
		if other == cid or _city_active[other] == 0:
			continue
		var d2: float = c_pos.distance_squared_to(_city_center[other])
		if d2 < nearest_d2:
			nearest_d2 = d2
			nearest_cid = other
		var should_flip: bool = (other == overlord) or (int(_city_faction[other]) == c_fac) or (d2 <= 320.0 * 320.0)
		if should_flip:
			_apply_diplomacy_state(cid, other, Diplomacy.REBELLION, true)
			flipped += 1
		elif int(_diplo_matrix[cid * _max_cities + other]) == Diplomacy.PACT:
			_apply_diplomacy_state(cid, other, Diplomacy.NEUTRAL, true)

	if flipped == 0 and nearest_cid >= 0:
		_apply_diplomacy_state(cid, nearest_cid, Diplomacy.REBELLION, true)

	_city_war_state[cid] = Diplomacy.REBELLION
	_goals_dirty = true

	if _fx != null:
		if _fx.has_method("spawn_burst"):
			_fx.spawn_burst(c_pos, 14, REBEL_TERRITORY_COLOR, 26.0, 0.55, -14.0)
		if _fx.has_method("spawn_reaction_strip"):
			_fx.call("spawn_reaction_strip", c_pos + Vector2(0.0, -10.0), STRIP_REBEL)


func _step_city_loyalty(cid: int, dt: float) -> void:
	if _city_is_rebel[cid] != 0:
		return
	var stress: float = 0.0
	var hunger: float = get_city_hunger_pressure(cid)
	if hunger > 0.45:
		stress += (hunger - 0.35) * 1.35
	if _city_emp_timer[cid] > 0.0:
		stress += 0.85
	var ov: int = _city_overlord[cid]
	if ov >= 0 and ov < _max_cities and _city_active[ov] != 0:
		var dist_cap: float = _city_center[cid].distance_to(_city_center[ov])
		if dist_cap > float(TUNING_KNOBS["REBEL_CAPITAL_DIST_PX"]):
			stress += 0.55

	var prev_loy: float = _city_loyalty[cid]
	if stress > 0.0:
		_city_loyalty[cid] = maxf(0.0, prev_loy - stress * float(TUNING_KNOBS["REBEL_LOYALTY_DECAY_PER_SEC"]) * dt)
	else:
		_city_loyalty[cid] = minf(100.0, prev_loy + float(TUNING_KNOBS["REBEL_LOYALTY_RECOVER_PER_SEC"]) * dt)

	if int(prev_loy * 0.2) != int(_city_loyalty[cid] * 0.2):
		_goals_dirty = true
	if _city_loyalty[cid] < float(TUNING_KNOBS["REBEL_LOYALTY_THRESHOLD"]):
		_trigger_city_rebellion(cid)


func _step_diplomacy_and_loyalty(dt: float) -> void:
	var war_th: float = float(TUNING_KNOBS["DIPLO_WAR_TENSION_THRESHOLD"])
	var pact_th: float = float(TUNING_KNOBS["DIPLO_PACT_TENSION_THRESHOLD"])
	var max_dist2: float = 280.0 * 280.0

	for a in range(_max_cities):
		if _city_active[a] == 0:
			continue
		var fa: int = int(_city_faction[a])
		var reb_a: bool = _city_is_rebel[a] != 0
		for b in range(a + 1, _max_cities):
			if _city_active[b] == 0:
				continue
			var fb: int = int(_city_faction[b])
			var reb_b: bool = _city_is_rebel[b] != 0
			var idx_ab: int = a * _max_cities + b
			var idx_ba: int = b * _max_cities + a
			if _diplo_pair_cd[idx_ab] > 0.0:
				var next_cd: float = maxf(0.0, _diplo_pair_cd[idx_ab] - dt)
				_diplo_pair_cd[idx_ab] = next_cd
				_diplo_pair_cd[idx_ba] = next_cd

			var st: int = int(_diplo_matrix[idx_ab])
			if st == Diplomacy.REBELLION or reb_a or reb_b:
				continue

			var contacts: int = _tmp_frontier_contacts[idx_ab]
			var d2: float = _city_center[a].distance_squared_to(_city_center[b])
			var ten: float = _diplo_tension[idx_ab]

			if fa == fb:
				ten = move_toward(ten, -35.0, 2.4 * dt)
			else:
				if contacts > 0:
					var growth: float = minf(float(contacts) * 0.9, 3.2)
					if int(_city_tech_tier[a]) >= 2 and int(_city_tech_tier[b]) >= 2 and d2 < 220.0 * 220.0:
						growth += 1.2
					ten = minf(100.0, ten + growth * dt)
				elif d2 > max_dist2:
					var floor_ten: float = -4.0 if (fa == Faction.SPORE or fb == Faction.SPORE) else -30.0
					ten = move_toward(ten, floor_ten, 1.5 * dt)

			_diplo_tension[idx_ab] = ten
			_diplo_tension[idx_ba] = ten

			if _diplo_pair_cd[idx_ab] > 0.0 or _city_war_cooldown[a] > 0.0 or _city_war_cooldown[b] > 0.0:
				continue

			if st != Diplomacy.TOTAL_WAR and ten >= war_th:
				_apply_diplomacy_state(a, b, Diplomacy.TOTAL_WAR, false)
			elif st == Diplomacy.TOTAL_WAR and contacts == 0 and ten < 8.0:
				_apply_diplomacy_state(a, b, Diplomacy.NEUTRAL, false)
			elif st == Diplomacy.NEUTRAL and ten <= pact_th:
				if fa == fb or (fa != Faction.SPORE and fb != Faction.SPORE):
					_apply_diplomacy_state(a, b, Diplomacy.PACT, false)


func _capture_zone_by_war(zx: int, zy: int, new_owner: int) -> void:
	if zx < 0 or zx >= _zone_w or zy < 0 or zy >= _zone_h:
		return
	if new_owner < 0 or new_owner >= _max_cities or _city_active[new_owner] == 0:
		return
	var prev_owner: int = _get_zone_owner(zx, zy)
	if prev_owner == new_owner or prev_owner < 0 or prev_owner >= _max_cities:
		return
	if not _are_cities_hostile(new_owner, prev_owner):
		return

	var new_fac: int = int(_city_faction[new_owner])
	_claim_zone(zx, zy, new_owner, new_fac)

	var px0: float = float(zx * _zone_px)
	var py0: float = float(zy * _zone_px)
	var px1: float = float((zx + 1) * _zone_px)
	var py1: float = float((zy + 1) * _zone_px)

	var bi: int = _bld_count - 1
	while bi >= 0:
		if _bld_city_id[bi] == prev_owner:
			var bp: Vector2 = _bld_pos[bi]
			if bp.x >= px0 and bp.x < px1 and bp.y >= py0 and bp.y < py1:
				var bt: int = int(_bld_type[bi])
				if bt == BuildingType.CAMPFIRE:
					_remove_building(bi)
				elif bt == BuildingType.QUANTUM_GATE and int(_city_tech_tier[new_owner]) < 4:
					_spawn_ruin(_bld_pos[bi], BLD_ORE_COSTS[bt] * 0.55, 18.0, int(_city_faction[prev_owner]))
					_remove_building(bi)
				else:
					_city_bld_counts[prev_owner * BLD_TYPE_COUNT + bt] = maxi(0, _city_bld_counts[prev_owner * BLD_TYPE_COUNT + bt] - 1)
					_city_bld_counts[new_owner * BLD_TYPE_COUNT + bt] += 1
					_bld_city_id[bi] = new_owner
					_bld_color[bi] = _get_city_tint_color(new_owner)
					_bld_hp[bi] = maxf(12.0, _bld_hp[bi] * 0.55)
					_bld_shake[bi] = 1.6
					if bt == BuildingType.SHIELD_PYLON:
						_bld_shield_charge[bi] = 0.0
					_city_tech_dirty[prev_owner] = 1
					_city_tech_dirty[new_owner] = 1
					if bt == BuildingType.DEPOT:
						_city_storage_cap[prev_owner] = maxf(float(TUNING_KNOBS["BASE_STORAGE_CAP"]), _city_storage_cap[prev_owner] - float(TUNING_KNOBS["DEPOT_STORAGE_BONUS"]))
						_city_storage_cap[new_owner] += float(TUNING_KNOBS["DEPOT_STORAGE_BONUS"])
					elif bt == BuildingType.LAUNCHPAD:
						_city_storage_cap[prev_owner] = maxf(float(TUNING_KNOBS["BASE_STORAGE_CAP"]), _city_storage_cap[prev_owner] - float(TUNING_KNOBS["LAUNCHPAD_STORAGE_BONUS"]))
						_city_storage_cap[new_owner] += float(TUNING_KNOBS["LAUNCHPAD_STORAGE_BONUS"])
					_buildings_dirty = true
					_bld_footprints_dirty = true
					_goals_dirty = true
		bi -= 1

	var z_mid := Vector2((float(zx) + 0.5) * float(_zone_px), (float(zy) + 0.5) * float(_zone_px))
	if _fx != null and _fx.has_method("spawn_burst"):
		_fx.spawn_burst(z_mid, 8, _get_city_border_color(new_owner), 18.0, 0.45, -10.0)

	if _city_zones_count[prev_owner] <= 0:
		_collapse_city(prev_owner)
	else:
		_verify_city_integrity_after_damage(prev_owner)
	_refresh_city_targets(new_owner)


func _step_wartime_capture(dt: float) -> void:
	if _physics == null or not _physics.has_method("get_unit_positions") or not _physics.has_method("get_unit_cities"):
		return
	var u_pos: PackedVector2Array = _physics.get_unit_positions()
	var u_city: PackedInt32Array = _physics.get_unit_cities()
	var has_roles: bool = _physics.has_method("get_unit_roles")
	var u_role: PackedByteArray = _physics.get_unit_roles() if has_roles else PackedByteArray()
	var u_cnt: int = int(_physics.get_unit_count()) if _physics.has_method("get_unit_count") else u_pos.size()
	u_cnt = mini(u_cnt, mini(u_pos.size(), u_city.size()))

	for prev_k in range(_contested_z_count):
		var pzi: int = _contested_z_list[prev_k]
		_zone_in_contested[pzi] = 0
		_tmp_zone_att_cid[pzi] = -1
		_tmp_zone_att_cnt[pzi] = 0
		_tmp_zone_def_cnt[pzi] = 0
		_tmp_zone_att_sol[pzi] = 0
	_contested_z_count = 0

	for i in range(u_cnt):
		var ucid: int = u_city[i]
		if ucid < 0 or ucid >= _max_cities or _city_active[ucid] == 0:
			continue
		var zx: int = clampi(int(floor(u_pos[i].x / float(_zone_px))), 0, _zone_w - 1)
		var zy: int = clampi(int(floor(u_pos[i].y / float(_zone_px))), 0, _zone_h - 1)
		var owner: int = _get_zone_owner(zx, zy)
		if owner < 0 or owner >= _max_cities or _city_active[owner] == 0:
			continue
		var zidx: int = zy * _zone_w + zx
		var is_sol: bool = has_roles and i < u_role.size() and int(u_role[i]) == 4
		var w: int = 2 if is_sol else 1
		if owner == ucid:
			_tmp_zone_def_cnt[zidx] += w
			if _zone_in_contested[zidx] == 0:
				_zone_in_contested[zidx] = 1
				_contested_z_list[_contested_z_count] = zidx
				_contested_z_count += 1
		elif _are_cities_hostile(ucid, owner):
			if _zone_in_contested[zidx] == 0:
				_zone_in_contested[zidx] = 1
				_contested_z_list[_contested_z_count] = zidx
				_contested_z_count += 1
			if _tmp_zone_att_cid[zidx] < 0 or _tmp_zone_att_cid[zidx] == ucid:
				_tmp_zone_att_cid[zidx] = ucid
				_tmp_zone_att_cnt[zidx] += w
				if is_sol:
					_tmp_zone_att_sol[zidx] = 1
			elif is_sol and _tmp_zone_att_sol[zidx] == 0:
				_tmp_zone_att_cid[zidx] = ucid
				_tmp_zone_att_cnt[zidx] += w
				_tmp_zone_att_sol[zidx] = 1
			else:
				_tmp_zone_att_cnt[zidx] += w

	var hold_sec: float = float(TUNING_KNOBS["WAR_ZONE_CAPTURE_SEC"])
	for k in range(_contested_z_count):
		var zidx: int = _contested_z_list[k]
		var att_cid: int = _tmp_zone_att_cid[zidx]
		var att_n: int = _tmp_zone_att_cnt[zidx]
		var def_n: int = _tmp_zone_def_cnt[zidx]
		var can_cap: bool = att_cid >= 0 and att_n > def_n and (not has_roles or _tmp_zone_att_sol[zidx] != 0 or (def_n == 0 and att_n >= 2))
		if can_cap:
			if _zone_capture_cid[zidx] == att_cid:
				_zone_capture_timer[zidx] += dt
			else:
				_zone_capture_cid[zidx] = att_cid
				_zone_capture_timer[zidx] = dt
				if _zone_in_active_cap[zidx] == 0:
					_zone_in_active_cap[zidx] = 1
					_active_cap_zones[_active_cap_count] = zidx
					_active_cap_count += 1
			if _zone_capture_timer[zidx] >= hold_sec:
				var czx: int = zidx % _zone_w
				var czy: int = zidx / _zone_w
				_capture_zone_by_war(czx, czy, att_cid)

	var ai: int = _active_cap_count - 1
	while ai >= 0:
		var zidx: int = _active_cap_zones[ai]
		var cap_cid: int = _zone_capture_cid[zidx]
		if cap_cid < 0:
			_zone_in_active_cap[zidx] = 0
			_active_cap_count -= 1
			if ai < _active_cap_count:
				_active_cap_zones[ai] = _active_cap_zones[_active_cap_count]
		else:
			var att_n: int = _tmp_zone_att_cnt[zidx]
			var def_n: int = _tmp_zone_def_cnt[zidx]
			var still_holding: bool = (
				_zone_in_contested[zidx] != 0
				and _tmp_zone_att_cid[zidx] == cap_cid
				and att_n > def_n
				and (not has_roles or _tmp_zone_att_sol[zidx] != 0 or (def_n == 0 and att_n >= 2))
			)
			if not still_holding:
				_zone_capture_timer[zidx] = maxf(0.0, _zone_capture_timer[zidx] - dt * 1.25)
				if _zone_capture_timer[zidx] <= 0.0:
					_zone_capture_cid[zidx] = -1
					_zone_in_active_cap[zidx] = 0
					_active_cap_count -= 1
					if ai < _active_cap_count:
						_active_cap_zones[ai] = _active_cap_zones[_active_cap_count]
		ai -= 1


func get_contested_capture_spots() -> Array[Dictionary]:
	_ensure_initialized()
	var out: Array[Dictionary] = []
	if _active_cap_count <= 0:
		return out
	var hold_sec: float = maxf(0.1, float(TUNING_KNOBS["WAR_ZONE_CAPTURE_SEC"]))
	for i in range(_active_cap_count):
		var zidx: int = _active_cap_zones[i]
		if zidx < 0 or zidx >= _zone_count:
			continue
		var att_cid: int = _zone_capture_cid[zidx]
		var t: float = _zone_capture_timer[zidx]
		if att_cid < 0 or att_cid >= _max_cities or _city_active[att_cid] == 0 or t <= 0.0:
			continue
		var def_cid: int = _zone_city_id[zidx]
		if def_cid < 0 or def_cid == att_cid:
			continue
		var zx: int = zidx % _zone_w
		var zy: int = zidx / _zone_w
		out.append({
			"pos": Vector2((float(zx) + 0.5) * float(_zone_px), (float(zy) + 0.5) * float(_zone_px)),
			"attacker_id": att_cid,
			"defender_id": def_cid,
			"color": _get_city_border_color(att_cid),
			"progress": clampf(t / hold_sec, 0.0, 1.0),
		})
		if out.size() >= 16:
			break
	return out


func _spawn_ruin(pos: Vector2, ore_amt: float, sci_amt: float, faction_id: int) -> void:
	if _ruin_count >= _max_ruins or pos.x < 4.0 or pos.y < 4.0:
		return
	var ridx: int = _ruin_count
	_ruin_count += 1
	_ruin_pos[ridx] = pos
	_ruin_ore[ridx] = maxf(6.0, ore_amt)
	_ruin_sci[ridx] = maxf(6.0, sci_amt)
	_ruin_faction[ridx] = clampi(faction_id, 0, FACTION_TINT_COLORS.size() - 1)
	_ruin_phase[ridx] = _rng.randf_range(0.0, TAU)
	_buildings_dirty = true
	_goals_dirty = true


func _remove_ruin(ridx: int) -> void:
	if ridx < 0 or ridx >= _ruin_count:
		return
	var last: int = _ruin_count - 1
	if ridx != last:
		_ruin_pos[ridx] = _ruin_pos[last]
		_ruin_ore[ridx] = _ruin_ore[last]
		_ruin_sci[ridx] = _ruin_sci[last]
		_ruin_faction[ridx] = _ruin_faction[last]
		_ruin_phase[ridx] = _ruin_phase[last]
	_ruin_count = last
	_buildings_dirty = true
	_goals_dirty = true


func _step_ruins_salvage() -> void:
	if _ruin_count <= 0:
		return
	var salvage_r: float = float(TUNING_KNOBS["RUIN_SALVAGE_RADIUS_PX"])
	var salvage_r2: float = salvage_r * salvage_r
	var ri: int = _ruin_count - 1
	while ri >= 0:
		var rpos: Vector2 = _ruin_pos[ri]
		var zowner: int = get_zone_owner_at(rpos)
		var claimer: int = -1
		if zowner >= 0 and _city_active[zowner] != 0:
			claimer = zowner
		else:
			var best_d2: float = salvage_r2
			for cid in range(_max_cities):
				if _city_active[cid] == 0:
					continue
				var d2: float = _city_center[cid].distance_squared_to(rpos)
				if d2 <= best_d2:
					best_d2 = d2
					claimer = cid
		if claimer >= 0:
			var ore_chunk: float = minf(_ruin_ore[ri], 6.0)
			var sci_chunk: float = minf(_ruin_sci[ri], 5.0)
			_ruin_ore[ri] -= ore_chunk
			_ruin_sci[ri] -= sci_chunk
			var cap: float = _city_storage_cap[claimer]
			_city_ore[claimer] = minf(cap, _city_ore[claimer] + ore_chunk)
			_city_science[claimer] = minf(cap * 4.0, _city_science[claimer] + sci_chunk)
			_total_harvested += ore_chunk + sci_chunk
			_city_tech_dirty[claimer] = 1
			if _fx != null and _fx.has_method("spawn_burst"):
				_fx.spawn_burst(rpos, 3, Color(0.95, 0.82, 0.35, 0.9), 18.0, 0.35, -12.0)
			if _ruin_ore[ri] <= 0.25 and _ruin_sci[ri] <= 0.25:
				_remove_ruin(ri)
		ri -= 1


func salvage_ruins_near(world_pos: Vector2, radius: float = 28.0) -> Dictionary:
	_ensure_initialized()
	var r2: float = maxf(4.0, radius) * maxf(4.0, radius)
	var total_ore: float = 0.0
	var total_sci: float = 0.0
	var count_salvaged: int = 0
	var best_cid: int = -1
	var best_d2: float = 1e12
	for cid in range(_max_cities):
		if _city_active[cid] == 0:
			continue
		var d2: float = _city_center[cid].distance_squared_to(world_pos)
		if d2 < best_d2:
			best_d2 = d2
			best_cid = cid

	var ri: int = _ruin_count - 1
	while ri >= 0:
		if _ruin_pos[ri].distance_squared_to(world_pos) <= r2:
			total_ore += _ruin_ore[ri]
			total_sci += _ruin_sci[ri]
			count_salvaged += 1
			if _fx != null and _fx.has_method("spawn_burst"):
				_fx.spawn_burst(_ruin_pos[ri], 8, Color(1.0, 0.85, 0.40, 0.95), 24.0, 0.45, -10.0)
			_remove_ruin(ri)
		ri -= 1

	if best_cid >= 0 and count_salvaged > 0:
		var cap: float = _city_storage_cap[best_cid]
		_city_ore[best_cid] = minf(cap, _city_ore[best_cid] + total_ore)
		_city_science[best_cid] = minf(cap * 4.0, _city_science[best_cid] + total_sci)
		_total_harvested += total_ore + total_sci
		_city_tech_dirty[best_cid] = 1

	return {
		"salvaged": count_salvaged,
		"ore": total_ore,
		"science": total_sci,
		"city_id": best_cid,
	}


func _city_has_active_shuttle(cid: int) -> bool:
	for si in range(_shuttle_count):
		if _shuttle_src_city[si] == cid:
			return true
	return false


func _find_shuttle_island_target(cid: int) -> Vector2:
	var launch_pos: Vector2 = _city_center[cid]
	var f_id: int = int(_city_faction[cid])
	var min_d: float = float(TUNING_KNOBS["SHUTTLE_HOP_MIN_DIST_PX"])
	var max_d: float = float(TUNING_KNOBS["SHUTTLE_HOP_MAX_DIST_PX"])
	var min_spacing: float = float(TUNING_KNOBS["MIN_CITY_SPACING_PX"])
	var min_sp2: float = min_spacing * min_spacing

	var best_target := Vector2(-1.0, -1.0)
	var best_score: float = -1e9
	for sample_i in range(48):
		var ang: float = float(sample_i) * (TAU / 48.0) + _rng.randf_range(-0.06, 0.06)
		var dist: float = _rng.randf_range(min_d, max_d)
		var cand := Vector2(
			clampf(launch_pos.x + cos(ang) * dist, 18.0, float(_map_w) - 18.0),
			clampf(launch_pos.y + sin(ang) * dist, 18.0, float(_map_h) - 18.0)
		)
		var cpx: int = int(floor(cand.x))
		var cpy: int = int(floor(cand.y))
		if not _is_pixel_walkable_for_faction(cpx, cpy, f_id):
			continue
		var czx: int = clampi(cpx / _zone_px, 0, _zone_w - 1)
		var czy: int = clampi(cpy / _zone_px, 0, _zone_h - 1)
		if not _is_zone_claimable(czx, czy, f_id):
			continue

		var too_close: bool = false
		for other in range(_max_cities):
			if _city_active[other] != 0 and _city_center[other].distance_squared_to(cand) < min_sp2:
				too_close = true
				break
		if too_close:
			continue

		# Check straight flight path for ocean/strait crossing
		var water_hops: int = 0
		if _world != null:
			for step in range(1, 9):
				var t: float = float(step) / 9.0
				var mp: Vector2 = launch_pos.lerp(cand, t)
				if int(_world.get_tier(clampi(int(mp.x), 0, _map_w - 1), clampi(int(mp.y), 0, _map_h - 1))) <= TIER_SHALLOW:
					water_hops += 1

		var score: float = float(water_hops) * 35.0 + float(_zone_ore[czy * _zone_w + czx]) * 1.8 + dist * 0.15
		if water_hops == 0 and dist < 105.0:
			score -= 12.0
		if score > best_score:
			best_score = score
			best_target = cand

	if best_score < 0.0:
		return Vector2(-1.0, -1.0)
	return best_target


func _try_launch_shuttles() -> void:
	if _shuttle_count >= _max_shuttles:
		return
	var active_cities: int = 0
	for cid in range(_max_cities):
		if _city_active[cid] != 0:
			active_cities += 1
	if active_cities >= _max_cities - 4:
		return

	var req_ore: float = float(TUNING_KNOBS["SHUTTLE_LAUNCH_ORE"])
	var req_energy: float = float(TUNING_KNOBS["SHUTTLE_LAUNCH_ENERGY"])
	var speed_px: float = maxf(12.0, float(TUNING_KNOBS["SHUTTLE_SPEED_PX"]))

	for cid in range(_max_cities):
		if _shuttle_count >= _max_shuttles:
			break
		if _city_active[cid] == 0 or _city_shuttle_cd[cid] > 0.0:
			continue
		if _city_has_active_shuttle(cid):
			continue
		var pads: int = _city_bld_counts[cid * BLD_TYPE_COUNT + BuildingType.LAUNCHPAD]
		var eligible: bool = pads > 0 or (int(_city_tech_tier[cid]) >= 2 and _is_city_coastal(cid))
		if not eligible:
			continue
		if _city_ore[cid] < req_ore or _city_energy[cid] < req_energy:
			continue

		var target: Vector2 = _find_shuttle_island_target(cid)
		if target.x < 0.0:
			_city_shuttle_cd[cid] = 4.0
			continue

		var launch_pos: Vector2 = _city_center[cid]
		for bi in range(_bld_count):
			if _bld_city_id[bi] == cid and _bld_type[bi] == BuildingType.LAUNCHPAD:
				launch_pos = _bld_pos[bi]
				break

		_city_ore[cid] -= req_ore
		_city_energy[cid] -= req_energy
		_city_energy_spend_acc[cid] += req_energy
		_city_shuttle_cd[cid] = float(TUNING_KNOBS["SHUTTLE_COOLDOWN_SEC"])
		_city_shuttles_launched[cid] += 1
		_total_shuttles_launched += 1

		var sidx: int = _shuttle_count
		_shuttle_count += 1
		var dist: float = launch_pos.distance_to(target)
		_shuttle_start[sidx] = launch_pos
		_shuttle_target[sidx] = target
		_shuttle_pos[sidx] = launch_pos
		_shuttle_t[sidx] = 0.0
		_shuttle_dur[sidx] = clampf(dist / speed_px, 1.4, 7.5)
		_shuttle_faction[sidx] = _city_faction[cid]
		_shuttle_src_city[sidx] = cid
		_shuttle_trail_t[sidx] = 0.0
		_shuttle_kind[sidx] = SHUTTLE_KIND_COLONIZE
		_shuttle_target_city[sidx] = -1
		_buildings_dirty = true

		if _fx != null:
			if _fx.has_method("play_sfx"):
				_fx.play_sfx(10)
			if _fx.has_method("spawn_burst"):
				_fx.spawn_burst(launch_pos, 10, Color(1.4, 0.85, 0.35, 1.0), 28.0, 0.45, 16.0)
		break


func _city_has_incoming_supply(dst_cid: int) -> bool:
	for si in range(_shuttle_count):
		if int(_shuttle_kind[si]) == SHUTTLE_KIND_SUPPLY and _shuttle_target_city[si] == dst_cid:
			return true
	return false


func _try_supply_sister_cities() -> void:
	if _shuttle_count >= _max_shuttles:
		return
	var rich_food: float = float(TUNING_KNOBS["SUPPLY_RICH_FOOD"])
	var rich_ore: float = float(TUNING_KNOBS["SUPPLY_RICH_ORE"])
	var need_sum: float = float(TUNING_KNOBS["SUPPLY_NEED_SUM"])
	var speed_px: float = maxf(14.0, float(TUNING_KNOBS["SHUTTLE_SPEED_PX"]) * 1.15)

	for src in range(_max_cities):
		if _shuttle_count >= _max_shuttles:
			break
		if _city_active[src] == 0 or int(_city_tech_tier[src]) < 1:
			continue
		if _city_shuttle_cd[src] > 0.0 or _city_has_active_shuttle(src):
			continue
		if _city_food[src] <= rich_food and _city_ore[src] <= rich_ore:
			continue

		var f_id: int = int(_city_faction[src])
		var best_dst: int = -1
		var lowest_sum: float = need_sum
		for dst in range(_max_cities):
			if dst == src or _city_active[dst] == 0 or int(_city_faction[dst]) != f_id:
				continue
			var dst_sum: float = _city_food[dst] + _city_ore[dst]
			if dst_sum >= lowest_sum:
				continue
			if _city_has_incoming_supply(dst):
				continue
			lowest_sum = dst_sum
			best_dst = dst
		if best_dst < 0:
			continue

		var launch_pos: Vector2 = _city_center[src]
		for bi in range(_bld_count):
			if _bld_city_id[bi] == src and _bld_type[bi] == BuildingType.LAUNCHPAD:
				launch_pos = _bld_pos[bi]
				break

		if _city_food[src] > 40.0:
			_city_food[src] = maxf(0.0, _city_food[src] - 15.0)
		if _city_ore[src] > 40.0:
			_city_ore[src] = maxf(0.0, _city_ore[src] - 15.0)
		_city_energy[src] = maxf(0.0, _city_energy[src] - minf(6.0, _city_energy[src] * 0.25))
		_city_shuttle_cd[src] = 6.0
		_city_shuttles_launched[src] += 1
		_total_shuttles_launched += 1

		var target: Vector2 = _city_center[best_dst]
		var sidx: int = _shuttle_count
		_shuttle_count += 1
		var dist: float = launch_pos.distance_to(target)
		_shuttle_start[sidx] = launch_pos
		_shuttle_target[sidx] = target
		_shuttle_pos[sidx] = launch_pos
		_shuttle_t[sidx] = 0.0
		_shuttle_dur[sidx] = clampf(dist / speed_px, 1.2, 6.5)
		_shuttle_faction[sidx] = f_id
		_shuttle_src_city[sidx] = src
		_shuttle_trail_t[sidx] = 0.0
		_shuttle_kind[sidx] = SHUTTLE_KIND_SUPPLY
		_shuttle_target_city[sidx] = best_dst
		_buildings_dirty = true

		if _fx != null:
			if _fx.has_method("play_sfx"):
				_fx.play_sfx(10)
			if _fx.has_method("spawn_burst"):
				_fx.spawn_burst(launch_pos, 8, Color(0.45, 0.95, 0.65, 1.0), 22.0, 0.40, 14.0)
		break


func _step_shuttles(dt: float) -> void:
	var si: int = _shuttle_count - 1
	while si >= 0:
		var dur: float = maxf(0.5, _shuttle_dur[si])
		_shuttle_t[si] += dt / dur
		var t: float = clampf(_shuttle_t[si], 0.0, 1.0)
		var smooth_t: float = t * t * (3.0 - 2.0 * t)
		var base_pos: Vector2 = _shuttle_start[si].lerp(_shuttle_target[si], smooth_t)
		var alt: float = sin(t * PI) * 18.0
		_shuttle_pos[si] = base_pos + Vector2(0.0, -4.0 - alt)

		_shuttle_trail_t[si] -= dt
		if _shuttle_trail_t[si] <= 0.0 and _fx != null and _fx.has_method("spawn_burst"):
			_shuttle_trail_t[si] = 0.14
			var trail_col := Color(0.45, 0.95, 0.65, 0.95) if int(_shuttle_kind[si]) == SHUTTLE_KIND_SUPPLY else Color(1.3, 0.72, 0.28, 0.95)
			_fx.spawn_burst(_shuttle_pos[si] + Vector2(0.0, 3.0), 1, trail_col, 8.0, 0.25, 10.0)

		if _shuttle_t[si] >= 1.0:
			var tpos: Vector2 = _shuttle_target[si]
			var fid: int = int(_shuttle_faction[si])
			if int(_shuttle_kind[si]) == SHUTTLE_KIND_SUPPLY:
				var tcid: int = _shuttle_target_city[si]
				if tcid >= 0 and tcid < _max_cities and _city_active[tcid] != 0:
					var cap: float = _city_storage_cap[tcid]
					_city_food[tcid] = minf(cap, _city_food[tcid] + float(TUNING_KNOBS["SUPPLY_FOOD"]))
					_city_ore[tcid] = minf(cap, _city_ore[tcid] + float(TUNING_KNOBS["SUPPLY_ORE"]))
					_city_energy[tcid] = minf(cap, _city_energy[tcid] + float(TUNING_KNOBS["SUPPLY_ENERGY"]))
					_supply_deliveries += 1
					if _fx != null:
						if _fx.has_method("emit_build_pop"):
							_fx.emit_build_pop(tpos)
						if _fx.has_method("spawn_burst"):
							_fx.spawn_burst(tpos, 10, Color(0.45, 0.95, 0.65, 1.0), 22.0, 0.45, 12.0)
						if _fx.has_method("spawn_reaction_strip"):
							_fx.call("spawn_reaction_strip", tpos + Vector2(0.0, -8.0), 4)
			else:
				var src_cid: int = _shuttle_src_city[si]
				var new_cid: int = spawn_colony(tpos, fid)
				if new_cid >= 0:
					if src_cid >= 0 and src_cid < _max_cities and _city_active[src_cid] != 0:
						_city_overlord[new_cid] = src_cid
					if _fx != null:
						if _fx.has_method("emit_build_pop"):
							_fx.emit_build_pop(tpos)
						if _fx.has_method("spawn_burst"):
							_fx.spawn_burst(tpos, 10, get_faction_color(fid), 24.0, 0.45, 14.0)
			var last: int = _shuttle_count - 1
			if si != last:
				_shuttle_start[si] = _shuttle_start[last]
				_shuttle_target[si] = _shuttle_target[last]
				_shuttle_pos[si] = _shuttle_pos[last]
				_shuttle_t[si] = _shuttle_t[last]
				_shuttle_dur[si] = _shuttle_dur[last]
				_shuttle_faction[si] = _shuttle_faction[last]
				_shuttle_src_city[si] = _shuttle_src_city[last]
				_shuttle_trail_t[si] = _shuttle_trail_t[last]
				_shuttle_kind[si] = _shuttle_kind[last]
				_shuttle_target_city[si] = _shuttle_target_city[last]
			_shuttle_count = last
		si -= 1


func _step_shield_pylons(dt: float) -> void:
	if _bld_count <= 0:
		return
	var base_rate: float = float(TUNING_KNOBS["SHIELD_BASE_RECHARGE"])
	var flash_decay: float = float(TUNING_KNOBS["SHIELD_FLASH_DECAY"])
	var solar_boost: float = maxf(0.45, _solar_mul)
	for i in range(_bld_count):
		if _bld_type[i] != BuildingType.SHIELD_PYLON:
			continue
		var fl: float = _bld_shield_flash[i]
		if fl > 0.0:
			_bld_shield_flash[i] = maxf(0.0, fl - dt * flash_decay)
			_buildings_dirty = true
		var ch: float = _bld_shield_charge[i]
		if ch < 1.0:
			var cid: int = clampi(_bld_city_id[i], 0, _max_cities - 1)
			var e_mul: float = clampf(0.5 + _city_energy[cid] * 0.04, 0.5, 2.0)
			var new_ch: float = minf(1.0, ch + base_rate * solar_boost * e_mul * dt)
			_bld_shield_charge[i] = new_ch
			if ch < 0.25 and new_ch >= 0.25:
				_buildings_dirty = true


func _step_building_springs(dt: float) -> bool:
	var omega: float = float(TUNING_KNOBS["SPRING_OMEGA"])
	var zeta: float = float(TUNING_KNOBS["SPRING_ZETA"])
	var moved: bool = false
	for i in range(_bld_count):
		var sh: float = _bld_shake[i]
		if sh > 0.0:
			_bld_shake[i] = maxf(0.0, sh - dt * 2.5)
			moved = true
		var sp: float = _bld_spring[i]
		var sv: float = _bld_spring_vel[i]
		if absf(sp - 1.0) > 0.002 or absf(sv) > 0.002:
			var force: float = -omega * omega * (sp - 1.0) - 2.0 * zeta * omega * sv
			sv += force * dt
			sp += sv * dt
			if absf(sp - 1.0) < 0.002 and absf(sv) < 0.01:
				sp = 1.0
				sv = 0.0
			_bld_spring[i] = clampf(sp, 0.08, 1.35)
			_bld_spring_vel[i] = sv
			moved = true
	return moved


func _building_anim_col(i: int, btype: int) -> int:
	var ph: float = _bld_phase[i]
	var hp: float = _bld_hp[i]
	var cid: int = clampi(_bld_city_id[i], 0, _max_cities - 1)
	var f_id: int = int(_city_faction[cid])
	var tier: int = int(_city_tech_tier[cid])
	var m_hp: float = _building_max_hp(btype, f_id)
	var damaged: bool = hp < m_hp * 0.62

	if btype == BuildingType.SHIELD_PYLON:
		if _bld_shield_flash[i] > 0.05 or (_bld_shield_charge[i] >= float(TUNING_KNOBS["SHIELD_MIN_CHARGE"]) and fmod(_sim_time * 1.4 + ph, 2.0) > 1.0):
			return BLD_COL_SHIELD_ACTIVE
		return BLD_COL_SHIELD
	if btype == BuildingType.QUANTUM_GATE:
		if _city_emp_timer[cid] > 0.0 or _city_energy[cid] < 2.0:
			return BLD_COL_QUANTUM_GATE
		return BLD_COL_QUANTUM_GATE_ACTIVE
	if btype == BuildingType.BIODOME and damaged and f_id != Faction.SPORE:
		return BLD_COL_BIODOME_DAMAGED
	if btype == BuildingType.LAUNCHPAD and damaged:
		return BLD_COL_LAUNCHPAD_SCORCHED
	if btype == BuildingType.LAUNCHPAD and _city_has_active_shuttle(cid) and f_id == Faction.HUMAN:
		return BLD_COL_LAUNCHPAD_EMPTY

	if f_id == Faction.ROBOT:
		return int(BLD_COLS_ROBOT[clampi(btype, 0, BLD_TYPE_COUNT - 1)])
	if f_id == Faction.SPORE:
		return int(BLD_COLS_SPORE[clampi(btype, 0, BLD_TYPE_COUNT - 1)])

	# HUMAN animated / tiered variants
	match btype:
		BuildingType.CAMPFIRE:
			return 8 if (int(floor(_sim_time * 8.0 + ph)) & 1) == 1 else 0
		BuildingType.TENT:
			return 9 if tier >= 1 else 1
		BuildingType.DRILL:
			return 10 if (int(floor(_sim_time * 4.5 + ph)) & 1) == 1 else 2
		BuildingType.DEPOT:
			return 11 if (int(floor(_sim_time * 1.6 + ph)) & 1) == 1 else 3
		BuildingType.SOLAR_ARRAY:
			return 12 if fmod(_sim_time + ph, 4.0) > 3.2 else 4
		BuildingType.FUSION_REACTOR:
			return 14 if (int(floor(_sim_time * 3.0 + ph)) & 1) == 1 else 6
		_:
			return int(BLD_COLS_HUMAN[clampi(btype, 0, BLD_TYPE_COUNT - 1)])


func _sync_buildings_multimesh(_full_sync: bool = true) -> void:
	if _mm_buildings == null or _mm_buildings.multimesh == null:
		return
	var mm: MultiMesh = _mm_buildings.multimesh
	var cap_inst: int = mm.instance_count
	var smm: MultiMesh = _mm_bld_shadows.multimesh if _mm_bld_shadows != null else null
	var sh_cap: int = smm.instance_count if smm != null else 0
	var anchor_off := Vector2(0.0, -BUILDING_CELL_PX * 0.5)
	var slot_i: int = 0
	var sh_i: int = 0

	# 1) Completed buildings
	for i in range(_bld_count):
		if slot_i >= cap_inst:
			break
		var btype: int = int(_bld_type[i])
		var col_idx: int = _building_anim_col(i, btype)
		var shake_val: float = _bld_shake[i]
		if btype == BuildingType.DRILL and (col_idx == 10 or col_idx == 20):
			shake_val = maxf(shake_val, 0.14)
		var b_col: Color = _bld_color[i]
		if btype == BuildingType.SHIELD_PYLON and _bld_shield_flash[i] > 0.05:
			var fl: float = clampf(_bld_shield_flash[i], 0.0, 1.0)
			shake_val = maxf(shake_val, fl * 0.45)
			b_col = b_col.lerp(Color(0.55, 0.96, 1.0, 1.0), fl * 0.65)
		elif btype == BuildingType.QUANTUM_GATE:
			var qcid: int = clampi(_bld_city_id[i], 0, _max_cities - 1)
			if _city_emp_timer[qcid] > 0.0:
				b_col = b_col.lerp(Color(0.32, 0.42, 0.54, 1.0), 0.55)
		mm.set_instance_transform_2d(slot_i, Transform2D(0.0, _bld_pos[i] + anchor_off))
		mm.set_instance_color(slot_i, b_col)
		mm.set_instance_custom_data(slot_i, Color(_bld_phase[i], shake_val, _bld_spring[i], float(col_idx)))
		slot_i += 1
		if smm != null and sh_i < sh_cap:
			var sw: float = BLD_FOOTPRINTS[clampi(btype, 0, BLD_TYPE_COUNT - 1)] * 1.12
			var sh: float = sw * 0.44
			smm.set_instance_transform_2d(sh_i, Transform2D(Vector2(sw, 0.0), Vector2(0.0, sh), _bld_pos[i] + Vector2(0.0, 1.0)))
			sh_i += 1

	# 2) Active Construction Scaffolds while _city_proj_prog < 1.0
	for cid in range(_max_cities):
		if slot_i >= cap_inst:
			break
		if _city_active[cid] == 0 or _city_proj_type[cid] < 0:
			continue
		var ptype: int = _city_proj_type[cid]
		var prog_cl: float = clampf(_city_proj_prog[cid], 0.0, 1.0)
		var sc_col: int = BLD_COL_SCAFFOLD_LG if ptype >= BuildingType.BIODOME else BLD_COL_SCAFFOLD
		var sc_spring: float = lerpf(0.62, 0.96, prog_cl)
		mm.set_instance_transform_2d(slot_i, Transform2D(0.0, _city_build_pos[cid] + anchor_off))
		mm.set_instance_color(slot_i, _city_color[cid])
		mm.set_instance_custom_data(slot_i, Color(float(cid) * 0.7, -0.5, sc_spring, float(sc_col)))
		slot_i += 1
		if smm != null and sh_i < sh_cap:
			var sw_sc: float = BLD_FOOTPRINTS[clampi(ptype, 0, BLD_TYPE_COUNT - 1)] * lerpf(0.65, 1.0, prog_cl)
			var sh_sc: float = sw_sc * 0.44
			smm.set_instance_transform_2d(sh_i, Transform2D(Vector2(sw_sc, 0.0), Vector2(0.0, sh_sc), _city_build_pos[cid] + Vector2(0.0, 1.0)))
			sh_i += 1

	# 3) Salvageable Failure-Forward Ruins
	for ri in range(_ruin_count):
		if slot_i >= cap_inst:
			break
		var rf_col: Color = FACTION_TINT_COLORS[clampi(int(_ruin_faction[ri]), 0, FACTION_TINT_COLORS.size() - 1)].lerp(Color(0.65, 0.68, 0.72), 0.55)
		mm.set_instance_transform_2d(slot_i, Transform2D(0.0, _ruin_pos[ri] + anchor_off))
		mm.set_instance_color(slot_i, rf_col)
		mm.set_instance_custom_data(slot_i, Color(_ruin_phase[ri], 0.0, 0.92, float(BLD_COL_RUINS)))
		slot_i += 1
		if smm != null and sh_i < sh_cap:
			smm.set_instance_transform_2d(sh_i, Transform2D(Vector2(13.0, 0.0), Vector2(0.0, 5.8), _ruin_pos[ri] + Vector2(0.0, 1.0)))
			sh_i += 1

	# 4) Archipelago Strait-Crossing & Supply Shuttles
	for si in range(_shuttle_count):
		if slot_i >= cap_inst:
			break
		var fid: int = clampi(int(_shuttle_faction[si]), 0, FACTION_TINT_COLORS.size() - 1)
		var facing: float = -1.0 if _shuttle_target[si].x < _shuttle_start[si].x else 1.0
		var sh_col: int = BLD_COL_SHUTTLE_BOOST if _shuttle_t[si] < 0.75 else BLD_COL_SHUTTLE
		var shuttle_tint: Color = FACTION_BORDER_COLORS[fid].lerp(Color(0.35, 0.98, 0.62, 1.0), 0.55) if int(_shuttle_kind[si]) == SHUTTLE_KIND_SUPPLY else FACTION_BORDER_COLORS[fid]
		mm.set_instance_transform_2d(slot_i, Transform2D(0.0, _shuttle_pos[si]))
		mm.set_instance_color(slot_i, shuttle_tint)
		mm.set_instance_custom_data(slot_i, Color(float(si), 0.0, facing, float(sh_col)))
		slot_i += 1
		if smm != null and sh_i < sh_cap:
			var t_s: float = clampf(_shuttle_t[si], 0.0, 1.0)
			var sm_t: float = t_s * t_s * (3.0 - 2.0 * t_s)
			var ground_p: Vector2 = _shuttle_start[si].lerp(_shuttle_target[si], sm_t) + Vector2(0.0, 1.5)
			var alt_scale: float = lerpf(1.0, 0.58, sin(t_s * PI))
			smm.set_instance_transform_2d(sh_i, Transform2D(Vector2(14.0 * alt_scale, 0.0), Vector2(0.0, 6.2 * alt_scale), ground_p))
			sh_i += 1

	mm.visible_instance_count = slot_i
	if smm != null:
		smm.visible_instance_count = sh_i


func deposit_resource(city_id: int, res_type: int, amount: float) -> void:
	_ensure_initialized()
	if city_id < 0 or city_id >= _max_cities or _city_active[city_id] == 0:
		return
	if amount <= 0.0:
		return
	var cap: float = _city_storage_cap[city_id]
	var f_id: int = int(_city_faction[city_id])
	match res_type:
		ResourceType.FOOD:
			var f_amt: float = amount * (1.20 if f_id == Faction.SPORE else 1.0) * _crop_mul
			_city_food[city_id] = minf(cap, _city_food[city_id] + f_amt)
			_city_science[city_id] += f_amt * 0.65
			_total_harvested += f_amt
		ResourceType.ORE:
			var o_amt: float = amount * (1.18 if f_id == Faction.ROBOT else 1.0)
			_city_ore[city_id] = minf(cap, _city_ore[city_id] + o_amt)
			_city_science[city_id] += o_amt * 0.90
			_total_harvested += o_amt
		ResourceType.ENERGY:
			_city_energy[city_id] = minf(cap, _city_energy[city_id] + amount)
			_city_ore[city_id] = minf(cap, _city_ore[city_id] + amount * 0.35)
			_city_science[city_id] += amount * 0.50
			_total_harvested += amount
		ResourceType.SCIENCE:
			_city_science[city_id] += amount
			_total_harvested += amount
		ResourceType.BUILD_WORK:
			_city_proj_work[city_id] += amount * 0.85
			_city_science[city_id] += amount * 0.50


func _has_active_dome_near(pos: Vector2) -> bool:
	var dome_r2: float = float(TUNING_KNOBS["DOME_PROTECTION_RADIUS"])
	dome_r2 *= dome_r2
	for i in range(_bld_count):
		if _bld_type[i] == BuildingType.BIODOME and _bld_pos[i].distance_squared_to(pos) <= dome_r2:
			return true
	return false


func on_terrain_damaged(world_pos: Vector2, radius: float) -> void:
	_ensure_initialized()
	if radius <= 0.5:
		return

	var r_eff: float = maxf(radius, 2.0)
	var r2: float = r_eff * r_eff
	var touched_cities: Dictionary = {}

	# 1) Clear damaged road pixels inside radius
	var px0: int = clampi(int(floor(world_pos.x - r_eff)), 0, _map_w - 1)
	var py0: int = clampi(int(floor(world_pos.y - r_eff)), 0, _map_h - 1)
	var px1: int = clampi(int(ceil(world_pos.x + r_eff)), 0, _map_w - 1)
	var py1: int = clampi(int(ceil(world_pos.y + r_eff)), 0, _map_h - 1)
	for py in range(py0, py1 + 1):
		var dy: float = float(py) - world_pos.y
		var row_off: int = py * _map_w
		for px in range(px0, px1 + 1):
			var dx: float = float(px) - world_pos.x
			if dx * dx + dy * dy <= r2:
				if _road_mask[row_off + px] != ROAD_NONE:
					_road_mask[row_off + px] = ROAD_NONE
					_road_px_count = maxi(0, _road_px_count - 1)
					_mark_zone_dirty(px / _zone_px, py / _zone_px)
					_goals_dirty = true

	# 2) Damage or destroy affected buildings
	var reactor_meltdowns: Array[Vector2] = []
	var reactor_cids: Array[int] = []
	var bi: int = _bld_count - 1
	while bi >= 0:
		var bpos: Vector2 = _bld_pos[bi]
		var d2: float = bpos.distance_squared_to(world_pos)
		var bpx: int = clampi(int(floor(bpos.x)), 0, _map_w - 1)
		var bpy: int = clampi(int(floor(bpos.y)), 0, _map_h - 1)
		var flooded_or_lava: bool = _world != null and (int(_world.get_tier(bpx, bpy)) <= TIER_CLOSE_OCEAN or _world.get_biome(bpx, bpy) == BIOME_LAVA)
		if flooded_or_lava or d2 <= r2:
			var cid: int = _bld_city_id[bi]
			touched_cities[cid] = true
			var dmg: float = 1000.0 if flooded_or_lava else (130.0 * clampf(1.0 - sqrt(d2) / r_eff, 0.25, 1.0))
			if not flooded_or_lava and _has_active_dome_near(bpos):
				dmg *= 0.60
			_bld_hp[bi] -= dmg
			_bld_shake[bi] = 1.0
			_buildings_dirty = true
			if cid >= 0 and cid < _max_cities and _city_active[cid] != 0:
				_city_alerted[cid] = 1
				_city_alert_timer[cid] = 5.0
				_city_threat_pos[cid] = world_pos
			if _bld_hp[bi] <= 0.0:
				if _bld_type[bi] == BuildingType.FUSION_REACTOR:
					reactor_meltdowns.append(bpos)
					reactor_cids.append(cid)
				_remove_building(bi)
		bi -= 1

	for melt_i in range(reactor_meltdowns.size()):
		_trigger_reactor_meltdown(reactor_meltdowns[melt_i], reactor_cids[melt_i])

	# 3) Unclaim flooded or blasted TileZones
	var zx0: int = clampi(int(floor((world_pos.x - r_eff) / float(_zone_px))), 0, _zone_w - 1)
	var zy0: int = clampi(int(floor((world_pos.y - r_eff) / float(_zone_px))), 0, _zone_h - 1)
	var zx1: int = clampi(int(floor((world_pos.x + r_eff) / float(_zone_px))), 0, _zone_w - 1)
	var zy1: int = clampi(int(floor((world_pos.y + r_eff) / float(_zone_px))), 0, _zone_h - 1)
	var core_r2: float = (r_eff * 0.72) * (r_eff * 0.72)

	for zy in range(zy0, zy1 + 1):
		for zx in range(zx0, zx1 + 1):
			var zidx: int = zy * _zone_w + zx
			var owner: int = _zone_city_id[zidx]
			if owner < 0:
				continue
			var zc := Vector2((float(zx) + 0.5) * float(_zone_px), (float(zy) + 0.5) * float(_zone_px))
			var blasted: bool = zc.distance_squared_to(world_pos) <= core_r2
			var fid: int = int(_city_faction[clampi(owner, 0, _max_cities - 1)])
			var unusable: bool = not _is_zone_walkable_enough_for(zx, zy, fid)
			if blasted or unusable:
				_zone_city_id[zidx] = -1
				_zone_faction_id[zidx] = 255
				_zone_flags[zidx] = 0
				_city_zones_count[owner] = maxi(0, _city_zones_count[owner] - 1)
				touched_cities[owner] = true
				_goals_dirty = true
			_mark_zone_dirty(zx, zy)

	# 4) Handle fallen cities (Failure-Forward: ruins + refugee scatter + center relocation)
	var touched_keys: Array = touched_cities.keys()
	for t_i in range(touched_keys.size()):
		var cid: int = int(touched_keys[t_i])
		if cid < 0 or cid >= _max_cities or _city_active[cid] == 0:
			continue
		_verify_city_integrity_after_damage(cid)

	_flush_dirty_borders()
	if _buildings_dirty:
		_sync_buildings_multimesh()
		_buildings_dirty = false
	_push_goal_buffers()


func _is_zone_walkable_enough(zx: int, zy: int) -> bool:
	return _is_zone_walkable_enough_for(zx, zy, Faction.HUMAN)


func _collapse_city(cid: int) -> void:
	var c_center: Vector2 = _city_center[cid]
	var f_id: int = int(_city_faction[cid])
	var ruin_ore: float = clampf(16.0 + _city_ore[cid] * 0.45, 16.0, 50.0)
	var ruin_sci: float = clampf(12.0 + _city_science[cid] * 0.15 + float(_city_tech_tier[cid]) * 8.0, 12.0, 45.0)
	var cpx: int = clampi(int(floor(c_center.x)), 0, _map_w - 1)
	var cpy: int = clampi(int(floor(c_center.y)), 0, _map_h - 1)
	if _world == null or int(_world.get_tier(cpx, cpy)) > TIER_CLOSE_OCEAN:
		_spawn_ruin(c_center, ruin_ore, ruin_sci, f_id)

	_city_active[cid] = 0
	_city_zones_count[cid] = 0
	_city_pop[cid] = 0
	_city_alerted[cid] = 0
	_city_alert_timer[cid] = 0.0
	_city_proj_type[cid] = -1
	_city_proj_retry[cid] = 0.0
	_city_tech_dirty[cid] = 0
	_city_coastal_cache[cid] = 0
	_city_loyalty[cid] = 100.0
	_city_is_rebel[cid] = 0
	_city_war_state[cid] = Diplomacy.NEUTRAL
	_city_emp_timer[cid] = 0.0
	_city_war_cooldown[cid] = 0.0
	_city_overlord[cid] = -1
	_city_tech_floor[cid] = 0
	_city_energy_spend_acc[cid] = 0.0
	_city_energy_net[cid] = 0.0
	_goals_dirty = true

	var row_cid: int = cid * _max_cities
	for other in range(_max_cities):
		_diplo_matrix[row_cid + other] = Diplomacy.NEUTRAL
		_diplo_matrix[other * _max_cities + cid] = Diplomacy.NEUTRAL
		_diplo_tension[row_cid + other] = 0.0
		_diplo_tension[other * _max_cities + cid] = 0.0
		_diplo_pair_cd[row_cid + other] = 0.0
		_diplo_pair_cd[other * _max_cities + cid] = 0.0
		if other != cid and _city_active[other] != 0:
			_recompute_city_war_state(other)

	var bi: int = _bld_count - 1
	while bi >= 0:
		if _bld_city_id[bi] == cid:
			_remove_building(bi)
		bi -= 1

	for zy in range(_zone_h):
		for zx in range(_zone_w):
			var zidx: int = zy * _zone_w + zx
			if _zone_capture_cid[zidx] == cid:
				_zone_capture_cid[zidx] = -1
				_zone_capture_timer[zidx] = 0.0
			if _zone_city_id[zidx] == cid:
				_zone_city_id[zidx] = -1
				_zone_faction_id[zidx] = 255
				_zone_flags[zidx] = 0
				_zone_capture_cid[zidx] = -1
				_zone_capture_timer[zidx] = 0.0
				_mark_zone_dirty(zx, zy)

	if _physics != null:
		if _physics.has_method("release_city_units"):
			_physics.release_city_units(cid)
		if _physics.has_method("trigger_impulse"):
			_physics.call("trigger_impulse", c_center, 30.0, 42.0)


func _refresh_goal_buffers() -> void:
	if _goals_dirty or _goal_buffers.is_empty():
		_goal_version += 1
		_goal_buffers["city_active"] = _city_active
		_goal_buffers["city_faction"] = _city_faction
		_goal_buffers["city_center"] = _city_center
		_goal_buffers["city_depot_pos"] = _city_center
		_goal_buffers["city_mine_pos"] = _city_mine_pos
		_goal_buffers["city_build_pos"] = _city_build_pos
		_goal_buffers["city_patrol_pos"] = _city_patrol_pos
		_goal_buffers["city_threat_pos"] = _city_threat_pos
		_goal_buffers["city_alerted"] = _city_alerted
		_goal_buffers["city_tech_tier"] = _city_tech_tier
		_goal_buffers["city_color"] = _city_color
		_goal_buffers["zone_city_id"] = _zone_city_id
		_goal_buffers["zone_w"] = _zone_w
		_goal_buffers["zone_h"] = _zone_h
		_goal_buffers["road_mask"] = _road_mask
		_goal_buffers["bld_count"] = _bld_count
		_goal_buffers["bld_pos"] = _bld_pos
		_goal_buffers["bld_radius"] = _bld_radius
		_goal_buffers["bld_type"] = _bld_type
		_goal_buffers["bld_dirty"] = _bld_footprints_dirty
		_goal_buffers["ruin_count"] = _ruin_count
		_goal_buffers["ruin_pos"] = _ruin_pos
		_goal_buffers["diplo_matrix"] = _diplo_matrix
		_goal_buffers["max_cities"] = _max_cities
		_goal_buffers["city_war_state"] = _city_war_state
		_goal_buffers["city_loyalty"] = _city_loyalty
		_goal_buffers["city_is_rebel"] = _city_is_rebel
		_goal_buffers["city_emp_timer"] = _city_emp_timer
		_goal_buffers["version"] = _goal_version
		_goals_dirty = false


func _push_goal_buffers() -> void:
	_refresh_goal_buffers()
	if _physics == null or not _physics.has_method("set_goal_buffers"):
		return
	if _pushed_goal_version == _goal_version and _last_pushed_physics == _physics:
		return
	_physics.set_goal_buffers(_goal_buffers)
	_pushed_goal_version = _goal_version
	_last_pushed_physics = _physics
	_bld_footprints_dirty = false
	_goal_buffers["bld_dirty"] = false


func get_goal_buffers() -> Dictionary:
	_ensure_initialized()
	_refresh_goal_buffers()
	return _goal_buffers


func get_goal_version() -> int:
	return _goal_version


func get_building_footprints() -> Dictionary:
	_ensure_initialized()
	return {
		"count": _bld_count,
		"pos": _bld_pos,
		"radius": _bld_radius,
		"type": _bld_type,
	}


func get_primary_city_pos() -> Vector2:
	var stats: Dictionary = get_civ_stats()
	var pos_v: Variant = stats.get("primary_city_pos", Vector2(float(_map_w) * 0.5, float(_map_h) * 0.5))
	if pos_v is Vector2:
		return pos_v as Vector2
	return Vector2(float(_map_w) * 0.5, float(_map_h) * 0.5)


func try_intercept_orbital_impact(world_pos: Vector2, impact_radius: float) -> Dictionary:
	_ensure_initialized()
	var shield_r: float = float(TUNING_KNOBS["SHIELD_PYLON_RADIUS_PX"])
	var eff_r: float = shield_r + maxf(0.0, impact_radius) * float(TUNING_KNOBS["SHIELD_IMPACT_RAD_MUL"])
	var eff_r2: float = eff_r * eff_r
	var min_charge: float = float(TUNING_KNOBS["SHIELD_MIN_CHARGE"])
	var cost: float = float(TUNING_KNOBS["SHIELD_INTERCEPT_COST"])

	var best_i: int = -1
	var best_d2: float = eff_r2 + 0.001
	for i in range(_bld_count):
		if _bld_type[i] != BuildingType.SHIELD_PYLON or _bld_hp[i] <= 0.0:
			continue
		if _bld_shield_charge[i] < min_charge:
			continue
		var d2: float = _bld_pos[i].distance_squared_to(world_pos)
		if d2 <= eff_r2 and d2 < best_d2:
			best_d2 = d2
			best_i = i

	if best_i < 0:
		return {"intercepted": false}

	_bld_shield_charge[best_i] = maxf(0.0, _bld_shield_charge[best_i] - cost)
	_bld_shield_flash[best_i] = 1.0
	_bld_spring[best_i] = 1.24
	_bld_spring_vel[best_i] = 2.5
	_shield_blocked_total += 1
	_buildings_dirty = true

	var ppos: Vector2 = _bld_pos[best_i]
	var cid: int = int(_bld_city_id[best_i])
	if _physics != null and _physics.has_method("notify_shield_saved"):
		_physics.call("notify_shield_saved", ppos, shield_r)
	if _fx != null and _fx.has_method("spawn_burst"):
		_fx.spawn_burst(ppos, 10, Color(0.42, 0.92, 1.45, 1.0), 30.0, 0.40, 12.0)

	return {
		"intercepted": true,
		"pylon_pos": ppos,
		"city_id": cid,
		"radius": shield_r,
		"charge_left": _bld_shield_charge[best_i],
	}


func get_shield_pylons() -> Array[Dictionary]:
	_ensure_initialized()
	var out: Array[Dictionary] = []
	var shield_r: float = float(TUNING_KNOBS["SHIELD_PYLON_RADIUS_PX"])
	for i in range(_bld_count):
		if _bld_type[i] != BuildingType.SHIELD_PYLON:
			continue
		var cid: int = clampi(int(_bld_city_id[i]), 0, _max_cities - 1)
		out.append({
			"pos": _bld_pos[i],
			"radius": shield_r,
			"charge": _bld_shield_charge[i],
			"flash": _bld_shield_flash[i],
			"faction": int(_city_faction[cid]),
			"city_id": cid,
		})
	return out


func set_zoom_lod(zoom_val: float) -> void:
	_zoom_val = zoom_val
	if _shadow_group == null or not is_instance_valid(_shadow_group):
		return
	var fade_hi: float = float(TUNING_KNOBS["SHADOW_FADE_START_ZOOM"])
	var fade_lo: float = float(TUNING_KNOBS["SHADOW_FADE_END_ZOOM"])
	var hide_z: float = float(TUNING_KNOBS["SHADOW_HIDE_ZOOM"])
	var base_a: float = float(TUNING_KNOBS["SHADOW_GROUP_ALPHA"])
	var alpha: float = base_a * clampf((zoom_val - fade_lo) / maxf(0.05, fade_hi - fade_lo), 0.0, 1.0)
	var col: Color = _shadow_group.self_modulate
	col.a = alpha
	_shadow_group.self_modulate = col
	_shadow_group.visible = zoom_val >= hide_z


func get_city_hunger_pressure(cid: int) -> float:
	if cid < 0 or cid >= _max_cities or _city_active[cid] == 0:
		return 0.0
	if int(_city_faction[cid]) == Faction.ROBOT:
		return 0.0
	return clampf(1.0 - _city_food[cid] / maxf(float(_city_pop[cid]) * 2.5, 16.0), 0.0, 1.0)


func set_cosmic_age_mods(solar_mul: float, crop_mul: float, fire_mul: float, tint: Color, tint_strength: float) -> void:
	_solar_mul = clampf(solar_mul, 0.1, 4.0)
	_crop_mul = clampf(crop_mul, 0.1, 4.0)
	_fire_mul = clampf(fire_mul, 0.1, 4.0)
	_age_tint = tint
	_age_tint_strength = clampf(tint_strength, 0.0, 1.0)
	if _bld_mat != null:
		_bld_mat.set_shader_parameter("age_tint", Vector3(tint.r, tint.g, tint.b))
		_bld_mat.set_shader_parameter("age_tint_strength", _age_tint_strength)


func push_lights_to_fx(fx: Node2D) -> void:
	if fx == null or not fx.has_method("push_light"):
		return
	for i in range(_bld_count):
		var btype: int = int(_bld_type[i])
		var pos: Vector2 = _bld_pos[i]
		match btype:
			BuildingType.CAMPFIRE:
				fx.push_light(pos + Vector2(0.0, -2.0), 22.0, Color(1.0, 0.58, 0.22, 1.0), 0.72)
			BuildingType.BIODOME:
				fx.push_light(pos + Vector2(0.0, -4.0), 28.0, Color(0.28, 0.95, 0.62, 1.0), 0.65)
			BuildingType.FUSION_REACTOR:
				fx.push_light(pos + Vector2(0.0, -5.0), 34.0, Color(0.32, 0.85, 1.0, 1.0), 0.88)
			BuildingType.SHIELD_PYLON:
				var ch_lit: float = clampf(_bld_shield_charge[i], 0.2, 1.0)
				var fl_lit: float = _bld_shield_flash[i]
				fx.push_light(pos + Vector2(0.0, -6.0), 38.0 + fl_lit * 14.0, Color(0.30, 0.88, 1.0, 1.0), 0.55 + ch_lit * 0.35 + fl_lit * 0.45)
			BuildingType.LAUNCHPAD:
				fx.push_light(pos + Vector2(0.0, -3.0), 26.0, Color(1.0, 0.72, 0.32, 1.0), 0.68)
			BuildingType.QUANTUM_GATE:
				var qcid: int = clampi(_bld_city_id[i], 0, _max_cities - 1)
				if _city_emp_timer[qcid] <= 0.0 and _city_energy[qcid] >= 2.0:
					fx.push_light(pos + Vector2(0.0, -5.0), 42.0, Color(0.75, 0.45, 1.0, 1.0), 0.92)
	for ri in range(_ruin_count):
		fx.push_light(_ruin_pos[ri] + Vector2(0.0, -2.0), 14.0, Color(1.0, 0.65, 0.25, 1.0), 0.42)
	for si in range(_shuttle_count):
		var s_col := Color(0.42, 0.95, 0.68, 1.0) if int(_shuttle_kind[si]) == SHUTTLE_KIND_SUPPLY else Color(1.0, 0.74, 0.34, 1.0)
		fx.push_light(_shuttle_pos[si], 24.0, s_col, 0.85)


func get_macro_badges() -> Array[Dictionary]:
	_ensure_initialized()
	var out: Array[Dictionary] = []
	for cid in range(_max_cities):
		if _city_active[cid] == 0:
			continue
		var fid: int = clampi(int(_city_faction[cid]), 0, FACTION_BORDER_COLORS.size() - 1)
		var pylons: int = _city_bld_counts[cid * BLD_TYPE_COUNT + BuildingType.SHIELD_PYLON]
		out.append({
			"city_id": cid,
			"pos": _city_center[cid],
			"faction": fid,
			"color": _get_city_border_color(cid),
			"pop": _city_pop[cid],
			"tech_tier": int(_city_tech_tier[cid]),
			"has_shield": pylons > 0,
			"is_rebel": _city_is_rebel[cid] != 0,
			"war_state": int(_city_war_state[cid]),
			"loyalty": _city_loyalty[cid],
			"emp_timer": _city_emp_timer[cid],
		})
	return out


func inspect_city_at(world_pos: Vector2) -> Dictionary:
	_ensure_initialized()
	var cid: int = get_zone_owner_at(world_pos)
	if cid < 0 or _city_active[cid] == 0:
		var best_d2: float = 40.0 * 40.0
		cid = -1
		for i in range(_max_cities):
			if _city_active[i] == 0:
				continue
			var d2: float = _city_center[i].distance_squared_to(world_pos)
			if d2 <= best_d2:
				best_d2 = d2
				cid = i

	if cid < 0:
		for ri in range(_ruin_count):
			if _ruin_pos[ri].distance_squared_to(world_pos) <= 484.0:
				return {
					"found": false,
					"ruin_found": true,
					"ruin_pos": _ruin_pos[ri],
					"ruin_ore": snappedf(_ruin_ore[ri], 0.1),
					"ruin_science": snappedf(_ruin_sci[ri], 0.1),
				}
		return {"found": false}

	var f_id: int = clampi(int(_city_faction[cid]), 0, FACTION_NAMES.size() - 1)
	var base_b: int = cid * BLD_TYPE_COUNT
	var total_b: int = 0
	var b_counts: Dictionary = {}
	for bt in range(BLD_TYPE_COUNT):
		var n: int = _city_bld_counts[base_b + bt]
		total_b += n
		if n > 0:
			b_counts[BUILDING_NAMES[bt]] = n

	var war_partners: int = 0
	var pact_partners: int = 0
	var rebel_partners: int = 0
	var row_off: int = cid * _max_cities
	for other in range(_max_cities):
		if other == cid or _city_active[other] == 0:
			continue
		var st_o: int = int(_diplo_matrix[row_off + other])
		if st_o == Diplomacy.PACT:
			pact_partners += 1
		elif st_o == Diplomacy.TOTAL_WAR:
			war_partners += 1
		elif st_o == Diplomacy.REBELLION:
			war_partners += 1
			rebel_partners += 1

	var loyalty_reason: String = ""
	if _city_is_rebel[cid] != 0:
		loyalty_reason = "Мятеж"
	elif _city_emp_timer[cid] > 0.0:
		loyalty_reason = "ЭМИ"
	elif get_city_hunger_pressure(cid) > 0.45:
		loyalty_reason = "Голод"
	else:
		var ov: int = _city_overlord[cid]
		if ov >= 0 and ov < _max_cities and _city_active[ov] != 0 and _city_center[cid].distance_to(_city_center[ov]) > float(TUNING_KNOBS["REBEL_CAPITAL_DIST_PX"]):
			loyalty_reason = "Дальн."
		elif _city_loyalty[cid] < 99.5:
			loyalty_reason = "Стресс"

	var ptype: int = _city_proj_type[cid]
	var proj_name: String = BUILDING_NAMES[ptype] if (ptype >= 0 and ptype < BUILDING_NAMES.size()) else "None"
	var state_str: String = "Thriving"
	if _city_is_rebel[cid] != 0:
		state_str = "Rebellion"
	elif int(_city_war_state[cid]) == Diplomacy.TOTAL_WAR:
		state_str = "Total War"
	elif _city_emp_timer[cid] > 0.0:
		state_str = "EMP Glitch"
	elif _city_alerted[cid] != 0:
		state_str = "Alerted"
	elif f_id != Faction.ROBOT and _city_food[cid] <= 0.1 and _city_pop[cid] > 4:
		state_str = "Starving"
	elif ptype >= 0:
		state_str = "Constructing"

	return {
		"found": true,
		"city_id": cid,
		"name": _city_name[cid],
		"center": _city_center[cid],
		"faction": f_id,
		"faction_name": FACTION_NAMES[f_id],
		"tech": int(_city_tech_tier[cid]),
		"tech_tier": int(_city_tech_tier[cid]),
		"pop": _city_pop[cid],
		"housing_cap": _city_housing_cap(cid),
		"zones_owned": _city_zones_count[cid],
		"food": snappedf(_city_food[cid], 0.1),
		"ore": snappedf(_city_ore[cid], 0.1),
		"energy": snappedf(_city_energy[cid], 0.1),
		"energy_net": snappedf(_city_energy_net[cid], 0.1),
		"science": snappedf(_city_science[cid], 0.1),
		"storage_cap": _city_storage_cap[cid],
		"buildings": total_b,
		"buildings_by_type": b_counts,
		"shield_pylons": _city_bld_counts[base_b + BuildingType.SHIELD_PYLON],
		"has_shield": _city_bld_counts[base_b + BuildingType.SHIELD_PYLON] > 0,
		"quantum_gates": _city_bld_counts[base_b + BuildingType.QUANTUM_GATE],
		"project": proj_name,
		"project_progress": snappedf(_city_proj_prog[cid], 0.01),
		"alerted": _city_alerted[cid] != 0,
		"loyalty": snappedf(_city_loyalty[cid], 0.1),
		"loyalty_reason": loyalty_reason,
		"is_rebel": _city_is_rebel[cid] != 0,
		"war_state": int(_city_war_state[cid]),
		"war_partners": war_partners,
		"pact_partners": pact_partners,
		"rebel_partners": rebel_partners,
		"emp_timer": snappedf(_city_emp_timer[cid], 0.1),
		"state": state_str,
		"shuttles_launched": _city_shuttles_launched[cid],
	}


func get_civ_stats() -> Dictionary:
	_ensure_initialized()
	var active_cities: int = 0
	var owned_zones: int = 0
	var max_tier: int = 0
	var total_food: float = 0.0
	var total_ore: float = 0.0
	var total_energy: float = 0.0
	var total_science: float = 0.0
	var total_pop: int = 0
	var active_scaffolds: int = 0
	var alerted_cities: int = 0
	var shield_pylons_n: int = 0
	var quantum_gates_n: int = 0
	var rebellions_active_n: int = 0
	var emp_cities_n: int = 0
	var wars_active_n: int = 0
	var pacts_active_n: int = 0
	var primary_id: int = -1
	var primary_score: float = -1.0
	var primary_pos := Vector2(float(_map_w) * 0.5, float(_map_h) * 0.5)

	for cid in range(_max_cities):
		if _city_active[cid] == 0:
			continue
		active_cities += 1
		owned_zones += _city_zones_count[cid]
		if _city_proj_type[cid] >= 0:
			active_scaffolds += 1
		if _city_alerted[cid] != 0:
			alerted_cities += 1
		if _city_is_rebel[cid] != 0:
			rebellions_active_n += 1
		if _city_emp_timer[cid] > 0.0:
			emp_cities_n += 1
		shield_pylons_n += _city_bld_counts[cid * BLD_TYPE_COUNT + BuildingType.SHIELD_PYLON]
		quantum_gates_n += _city_bld_counts[cid * BLD_TYPE_COUNT + BuildingType.QUANTUM_GATE]
		var t: int = int(_city_tech_tier[cid])
		if t > max_tier:
			max_tier = t
		total_food += _city_food[cid]
		total_ore += _city_ore[cid]
		total_energy += _city_energy[cid]
		total_science += _city_science[cid]
		total_pop += _city_pop[cid]

		var rank: float = float(_city_zones_count[cid]) * 10.0 + float(t) * 50.0 + float(_city_pop[cid])
		if rank > primary_score:
			primary_score = rank
			primary_id = cid
			primary_pos = _city_center[cid]

	for a in range(_max_cities):
		if _city_active[a] == 0:
			continue
		for b in range(a + 1, _max_cities):
			if _city_active[b] == 0:
				continue
			var st: int = int(_diplo_matrix[a * _max_cities + b])
			if st == Diplomacy.PACT:
				pacts_active_n += 1
			elif st == Diplomacy.TOTAL_WAR or st == Diplomacy.REBELLION:
				wars_active_n += 1

	var storage_total: float = total_food + total_ore + total_energy + total_science
	return {
		"cities": active_cities,
		"zones_owned": owned_zones,
		"buildings": _bld_count,
		"scaffolds": active_scaffolds,
		"ruins": _ruin_count,
		"shuttles": _shuttle_count,
		"shuttles_launched": _total_shuttles_launched,
		"shuttles_total": _total_shuttles_launched,
		"shield_pylons": shield_pylons_n,
		"shield_blocked": _shield_blocked_total,
		"quantum_gates": quantum_gates_n,
		"supply_deliveries": _supply_deliveries,
		"clashes": _border_clash_count,
		"alerted_cities": alerted_cities,
		"wars_active": wars_active_n,
		"pacts_active": pacts_active_n,
		"rebellions_active": rebellions_active_n,
		"rebellions_total": _rebellions_total,
		"emp_cities": emp_cities_n,
		"tech_tier": max_tier,
		"max_tech_tier": max_tier,
		"storage_total": storage_total,
		"food": total_food,
		"ore": total_ore,
		"energy": total_energy,
		"science": total_science,
		"harvested_total": _total_harvested,
		"population": total_pop,
		"roads": _road_px_count,
		"primary_city_id": primary_id,
		"primary_city_pos": primary_pos,
	}


func get_diplomacy(city_a: int, city_b: int) -> int:
	_ensure_initialized()
	if city_a < 0 or city_a >= _max_cities or city_b < 0 or city_b >= _max_cities or city_a == city_b:
		return Diplomacy.NEUTRAL
	if _city_active[city_a] == 0 or _city_active[city_b] == 0:
		return Diplomacy.NEUTRAL
	return int(_diplo_matrix[city_a * _max_cities + city_b])


func set_diplomacy(city_a: int, city_b: int, state: int) -> void:
	_ensure_initialized()
	_apply_diplomacy_state(city_a, city_b, state, true)
	_push_goal_buffers()


func trigger_diplomacy_spark(world_pos: Vector2, force_mode: int = -1) -> Dictionary:
	_ensure_initialized()
	var cid_a: int = get_zone_owner_at(world_pos)
	if cid_a < 0 or _city_active[cid_a] == 0:
		cid_a = -1
		var best_d2: float = 1e18
		for cid in range(_max_cities):
			if _city_active[cid] == 0:
				continue
			var d2: float = _city_center[cid].distance_squared_to(world_pos)
			if d2 < best_d2:
				best_d2 = d2
				cid_a = cid
		if force_mode < 0 and best_d2 > 140.0 * 140.0:
			cid_a = -1
	if cid_a < 0:
		return {"ok": false, "triggered": false, "msg": "Нет колонии рядом", "mode": -1, "state": -1, "city_a": -1, "city_b": -1}

	var cid_b: int = -1
	var best_b2: float = 1e18
	for cid in range(_max_cities):
		if cid == cid_a or _city_active[cid] == 0:
			continue
		var d2: float = _city_center[cid].distance_squared_to(world_pos)
		if d2 < best_b2:
			best_b2 = d2
			cid_b = cid

	if force_mode < 0:
		if _city_is_rebel[cid_a] != 0:
			return {
				"ok": false,
				"triggered": false,
				"msg": "%s уже в мятеже" % _city_name[cid_a],
				"mode": Diplomacy.REBELLION,
				"state": Diplomacy.REBELLION,
				"city_a": cid_a,
				"city_b": cid_b,
				"rebellion": true,
				"loyalty": snappedf(_city_loyalty[cid_a], 0.1),
			}
		_city_loyalty[cid_a] = maxf(0.0, _city_loyalty[cid_a] - 35.0)
		_goals_dirty = true

	if force_mode == Diplomacy.REBELLION or (force_mode < 0 and (_city_loyalty[cid_a] < 55.0 or cid_b < 0)):
		_trigger_city_rebellion(cid_a)
		if cid_b >= 0:
			_apply_diplomacy_state(cid_a, cid_b, Diplomacy.REBELLION, true)
		_flush_dirty_borders()
		_sync_buildings_multimesh()
		_buildings_dirty = false
		_push_goal_buffers()
		return {
			"ok": true,
			"triggered": true,
			"msg": "Мятеж: %s" % _city_name[cid_a],
			"mode": Diplomacy.REBELLION,
			"state": Diplomacy.REBELLION,
			"city_a": cid_a,
			"city_b": cid_b,
			"rebellion": true,
			"loyalty": snappedf(_city_loyalty[cid_a], 0.1),
		}

	if cid_b < 0:
		return {"ok": false, "triggered": false, "msg": "Нет соседа", "mode": force_mode, "state": -1, "city_a": cid_a, "city_b": -1}

	var target_st: int = force_mode
	if target_st < Diplomacy.NEUTRAL or target_st > Diplomacy.REBELLION:
		var cur_st: int = get_diplomacy(cid_a, cid_b)
		if cur_st == Diplomacy.NEUTRAL or cur_st == Diplomacy.PACT:
			target_st = Diplomacy.TOTAL_WAR
		elif cur_st == Diplomacy.TOTAL_WAR:
			var fa: int = int(_city_faction[cid_a])
			var fb: int = int(_city_faction[cid_b])
			target_st = Diplomacy.PACT if (fa == fb or (fa != Faction.SPORE and fb != Faction.SPORE)) else Diplomacy.NEUTRAL
		else:
			target_st = Diplomacy.REBELLION

	_apply_diplomacy_state(cid_a, cid_b, target_st, true)
	if target_st == Diplomacy.PACT and force_mode == Diplomacy.PACT:
		_city_loyalty[cid_a] = minf(100.0, _city_loyalty[cid_a] + 15.0)
		_city_loyalty[cid_b] = minf(100.0, _city_loyalty[cid_b] + 15.0)
		_goals_dirty = true
	if _fx != null and _fx.has_method("spawn_burst"):
		var s_col: Color = Color(0.45, 0.95, 0.55, 1.0) if target_st == Diplomacy.PACT else Color(1.0, 0.35, 0.25, 1.0)
		_fx.spawn_burst(world_pos, 12, s_col, 24.0, 0.45, -10.0)
	_push_goal_buffers()
	var st_tag: String = "Война" if target_st == Diplomacy.TOTAL_WAR else ("Пакт" if target_st == Diplomacy.PACT else "Нейтр.")
	return {
		"ok": true,
		"triggered": true,
		"msg": "%s (%s · Лоял %d%%)" % [_city_name[cid_a], st_tag, int(round(_city_loyalty[cid_a]))],
		"mode": target_st,
		"state": target_st,
		"city_a": cid_a,
		"city_b": cid_b,
		"rebellion": false,
		"loyalty": snappedf(_city_loyalty[cid_a], 0.1),
	}


func apply_ai_glitch(world_pos: Vector2, radius: float) -> Dictionary:
	_ensure_initialized()
	var safe_r: float = maxf(12.0, radius)
	var safe_r2: float = safe_r * safe_r
	var emp_dur: float = float(TUNING_KNOBS["EMP_GLITCH_DURATION_SEC"])
	var loy_hit: float = float(TUNING_KNOBS["AI_GLITCH_LOYALTY_HIT"])
	var rebel_th: float = float(TUNING_KNOBS["REBEL_LOYALTY_THRESHOLD"])

	var hit_map: Dictionary = {}
	var z_cid: int = get_zone_owner_at(world_pos)
	if z_cid >= 0 and z_cid < _max_cities and _city_active[z_cid] != 0:
		hit_map[z_cid] = true
	for cid in range(_max_cities):
		if _city_active[cid] == 0:
			continue
		if _city_center[cid].distance_squared_to(world_pos) <= safe_r2:
			hit_map[cid] = true
	for bi in range(_bld_count):
		if _bld_pos[bi].distance_squared_to(world_pos) <= safe_r2:
			var bcid: int = _bld_city_id[bi]
			if bcid >= 0 and bcid < _max_cities and _city_active[bcid] != 0:
				hit_map[bcid] = true
			_bld_shake[bi] = maxf(_bld_shake[bi], 3.2)
			if int(_bld_type[bi]) == BuildingType.SHIELD_PYLON:
				_bld_shield_charge[bi] = maxf(0.0, _bld_shield_charge[bi] - 0.35)

	var affected_cids: Array[int] = []
	var rebel_count: int = 0
	for k in hit_map.keys():
		var cid: int = int(k)
		affected_cids.append(cid)
		_city_emp_timer[cid] = maxf(_city_emp_timer[cid], emp_dur)
		_city_loyalty[cid] = maxf(0.0, _city_loyalty[cid] - loy_hit)
		_city_alerted[cid] = 1
		_city_alert_timer[cid] = maxf(_city_alert_timer[cid], 6.0)
		_goals_dirty = true
		if _city_is_rebel[cid] == 0 and _city_loyalty[cid] < rebel_th:
			_trigger_city_rebellion(cid)
			rebel_count += 1

	_buildings_dirty = true
	_flush_dirty_borders()
	_sync_buildings_multimesh()
	_buildings_dirty = false
	if _fx != null and _fx.has_method("spawn_burst"):
		_fx.spawn_burst(world_pos, 16, Color(0.35, 0.95, 0.85, 1.0), minf(safe_r, 42.0), 0.55, -12.0)
	_push_goal_buffers()
	return {
		"affected_cities": affected_cids.size(),
		"rebellions_triggered": rebel_count,
		"emp_cities": affected_cids,
	}


func get_quantum_gates() -> Array[Dictionary]:
	_ensure_initialized()
	var out: Array[Dictionary] = []
	for i in range(_bld_count):
		if int(_bld_type[i]) != BuildingType.QUANTUM_GATE:
			continue
		var cid: int = _bld_city_id[i]
		if cid < 0 or cid >= _max_cities or _city_active[cid] == 0:
			continue
		var is_emp: bool = _city_emp_timer[cid] > 0.0
		var is_active: bool = (not is_emp) and _city_energy[cid] >= 2.0 and _bld_hp[i] > 0.0
		out.append({
			"city_id": cid,
			"faction": int(_city_faction[cid]),
			"pos": _bld_pos[i],
			"active": is_active,
			"emp": is_emp,
		})
	return out


func consume_city_energy(city_id: int, amount: float) -> bool:
	_ensure_initialized()
	if city_id < 0 or city_id >= _max_cities or _city_active[city_id] == 0:
		return false
	if _city_emp_timer[city_id] > 0.0:
		return false
	if amount <= 0.0:
		return true
	if _city_energy[city_id] < amount:
		return false
	_city_energy[city_id] -= amount
	_city_energy_spend_acc[city_id] += amount
	return true


func get_diplomacy_links() -> Array[Dictionary]:
	_ensure_initialized()
	var out: Array[Dictionary] = []
	for a in range(_max_cities):
		if _city_active[a] == 0:
			continue
		for b in range(a + 1, _max_cities):
			if _city_active[b] == 0:
				continue
			var st: int = int(_diplo_matrix[a * _max_cities + b])
			if st == Diplomacy.NEUTRAL:
				continue
			out.append({
				"city_a": a,
				"city_b": b,
				"pos_a": _city_center[a],
				"pos_b": _city_center[b],
				"state": st,
			})
	return out


func spawn_building_for_test(city_id: int, btype: int) -> Vector2:
	_ensure_initialized()
	if city_id < 0 or city_id >= _max_cities or _city_active[city_id] == 0:
		return Vector2(-1.0, -1.0)
	var bt: int = clampi(btype, 0, BLD_TYPE_COUNT - 1)
	var f_id: int = int(_city_faction[city_id])
	var spot: Vector2 = _find_building_spot(city_id, bt)
	if spot.x < 0.0:
		var center: Vector2 = _city_center[city_id]
		for ring in range(1, 10):
			var rad: float = 10.0 + float(ring) * 6.0
			for k in range(16):
				var ang: float = float(k) * (TAU / 16.0) + float(ring) * 0.25
				var cand: Vector2 = center + Vector2(cos(ang), sin(ang)) * rad
				if _is_building_spot_valid(cand, bt, f_id):
					spot = cand
					break
			if spot.x >= 0.0:
				break
	if spot.x < 0.0:
		var center2: Vector2 = _city_center[city_id]
		for ring2 in range(1, 12):
			var rad2: float = 8.0 + float(ring2) * 5.0
			for k2 in range(16):
				var ang2: float = float(k2) * (TAU / 16.0)
				var cand2: Vector2 = center2 + Vector2(cos(ang2), sin(ang2)) * rad2
				var px: int = clampi(int(floor(cand2.x)), 10, _map_w - 11)
				var py: int = clampi(int(floor(cand2.y)), 14, _map_h - 9)
				if _is_pixel_walkable_for_faction(px, py, f_id):
					var clear_ok: bool = true
					for bi in range(_bld_count):
						if _bld_pos[bi].distance_squared_to(cand2) < 64.0:
							clear_ok = false
							break
					if clear_ok:
						spot = Vector2(float(px), float(py))
						break
			if spot.x >= 0.0:
				break
	if spot.x < 0.0:
		return Vector2(-1.0, -1.0)

	_place_building(city_id, bt, spot, true)
	_recompute_city_tech(city_id)
	_refresh_city_targets(city_id)
	_flush_dirty_borders()
	_sync_buildings_multimesh()
	_buildings_dirty = false
	_goals_dirty = true
	_bld_footprints_dirty = true
	_push_goal_buffers()
	return spot


func grant_tech_tier_for_test(city_id: int, target_tier: int) -> void:
	_ensure_initialized()
	if city_id < 0 or city_id >= _max_cities or _city_active[city_id] == 0:
		return
	var t: int = clampi(target_tier, 0, 4)
	var prev_t: int = int(_city_tech_tier[city_id])
	_city_tech_floor[city_id] = maxi(int(_city_tech_floor[city_id]), t)
	_city_storage_cap[city_id] = maxf(_city_storage_cap[city_id], 120.0 if t >= 3 else 70.0)
	_city_ore[city_id] = maxf(_city_ore[city_id], 35.0)
	_city_energy[city_id] = maxf(_city_energy[city_id], 45.0 if t >= 4 else 24.0)
	_city_pop[city_id] = maxi(_city_pop[city_id], 10 if t >= 1 else 0)

	var min_sci: float = 0.0
	if t == 1:
		min_sci = 30.0
	elif t == 2:
		min_sci = 85.0
	elif t == 3:
		min_sci = float(TUNING_KNOBS["TIER3_SCI_REQ"]) + 20.0
	elif t >= 4:
		min_sci = float(TUNING_KNOBS["TIER4_SCI_REQ"]) + 40.0
	_city_science[city_id] = maxf(_city_science[city_id], min_sci)

	var base_b: int = city_id * BLD_TYPE_COUNT
	if t >= 2 and _city_bld_counts[base_b + BuildingType.DRILL] < 1:
		spawn_building_for_test(city_id, BuildingType.DRILL)
	if t >= 3 and _city_bld_counts[base_b + BuildingType.FUSION_REACTOR] < 1:
		spawn_building_for_test(city_id, BuildingType.FUSION_REACTOR)
	if t >= 4 and _city_bld_counts[base_b + BuildingType.LAUNCHPAD] < 1:
		spawn_building_for_test(city_id, BuildingType.LAUNCHPAD)

	_city_tech_tier[city_id] = maxi(prev_t, t)
	_recompute_city_tech(city_id)
	if t >= 2 and prev_t < 2:
		_upgrade_city_roads_to_conduits(city_id)
	_flush_dirty_borders()
	_sync_buildings_multimesh()
	_buildings_dirty = false
	_goals_dirty = true
	_push_goal_buffers()


func pack_state() -> PackedByteArray:
	_ensure_initialized()
	var buf := StreamPeerBuffer.new()
	buf.put_32(SAVE_MAGIC)
	buf.put_u32(SAVE_VERSION)
	buf.put_u16(_map_w)
	buf.put_u16(_map_h)
	buf.put_u16(_zone_w)
	buf.put_u16(_zone_h)
	buf.put_float(_sim_time)
	buf.put_float(_total_harvested)
	buf.put_32(_total_shuttles_launched)
	buf.put_32(_shield_blocked_total)
	buf.put_32(_supply_deliveries)
	buf.put_32(_rebellions_total)

	for z in range(_zone_count):
		buf.put_32(_zone_city_id[z])
		buf.put_u8(_zone_faction_id[z])
		buf.put_u8(_zone_flags[z])
		buf.put_32(_zone_ore[z])
		buf.put_float(_zone_fertility[z])

	buf.put_u32(_road_mask.size())
	buf.put_data(_road_mask)

	buf.put_u16(_max_cities)
	for c in range(_max_cities):
		buf.put_u8(_city_active[c])
		if _city_active[c] == 0:
			continue
		buf.put_u8(_city_faction[c])
		buf.put_utf8_string(_city_name[c])
		buf.put_float(_city_center[c].x)
		buf.put_float(_city_center[c].y)
		buf.put_float(_city_mine_pos[c].x)
		buf.put_float(_city_mine_pos[c].y)
		buf.put_float(_city_build_pos[c].x)
		buf.put_float(_city_build_pos[c].y)
		buf.put_float(_city_patrol_pos[c].x)
		buf.put_float(_city_patrol_pos[c].y)
		buf.put_float(_city_threat_pos[c].x)
		buf.put_float(_city_threat_pos[c].y)
		buf.put_u8(_city_alerted[c])
		buf.put_float(_city_alert_timer[c])
		buf.put_u8(_city_tech_tier[c])
		buf.put_float(_city_tech_score[c])
		buf.put_32(_city_pop[c])
		buf.put_32(_city_zones_count[c])
		buf.put_float(_city_food[c])
		buf.put_float(_city_ore[c])
		buf.put_float(_city_energy[c])
		buf.put_float(_city_science[c])
		buf.put_float(_city_storage_cap[c])
		buf.put_float(_city_expand_timer[c])
		buf.put_float(_city_pop_timer[c])
		buf.put_float(_city_shuttle_cd[c])
		buf.put_32(_city_shuttles_launched[c])
		buf.put_32(_city_proj_type[c])
		buf.put_float(_city_proj_prog[c])
		buf.put_float(_city_proj_work[c])
		var base_b: int = c * BLD_TYPE_COUNT
		for bt in range(BLD_TYPE_COUNT):
			buf.put_32(_city_bld_counts[base_b + bt])
		buf.put_float(_city_loyalty[c])
		buf.put_u8(_city_is_rebel[c])
		buf.put_u8(_city_war_state[c])
		buf.put_float(_city_emp_timer[c])
		buf.put_float(_city_war_cooldown[c])
		buf.put_32(_city_overlord[c])
		buf.put_u8(_city_tech_floor[c])

	buf.put_u16(_bld_count)
	for b in range(_bld_count):
		buf.put_float(_bld_pos[b].x)
		buf.put_float(_bld_pos[b].y)
		buf.put_u8(_bld_type[b])
		buf.put_32(_bld_city_id[b])
		buf.put_float(_bld_hp[b])
		buf.put_float(_bld_spring[b])
		buf.put_float(_bld_spring_vel[b])
		buf.put_float(_bld_shake[b])
		buf.put_float(_bld_phase[b])
		buf.put_float(_bld_shield_charge[b])
		buf.put_float(_bld_shield_flash[b])

	buf.put_u16(_ruin_count)
	for r in range(_ruin_count):
		buf.put_float(_ruin_pos[r].x)
		buf.put_float(_ruin_pos[r].y)
		buf.put_float(_ruin_ore[r])
		buf.put_float(_ruin_sci[r])
		buf.put_u8(_ruin_faction[r])
		buf.put_float(_ruin_phase[r])

	buf.put_u16(_shuttle_count)
	for s in range(_shuttle_count):
		buf.put_float(_shuttle_start[s].x)
		buf.put_float(_shuttle_start[s].y)
		buf.put_float(_shuttle_target[s].x)
		buf.put_float(_shuttle_target[s].y)
		buf.put_float(_shuttle_pos[s].x)
		buf.put_float(_shuttle_pos[s].y)
		buf.put_float(_shuttle_t[s])
		buf.put_float(_shuttle_dur[s])
		buf.put_u8(_shuttle_faction[s])
		buf.put_32(_shuttle_src_city[s])
		buf.put_u8(_shuttle_kind[s])
		buf.put_32(_shuttle_target_city[s])

	buf.put_u32(_diplo_matrix.size())
	buf.put_data(_diplo_matrix)
	for m in range(_diplo_matrix.size()):
		buf.put_float(_diplo_tension[m])

	var cap_z_indices := PackedInt32Array()
	for z in range(_zone_count):
		if _zone_capture_cid[z] >= 0 and _zone_capture_timer[z] > 0.0:
			cap_z_indices.append(z)
	buf.put_u16(cap_z_indices.size())
	for k in range(cap_z_indices.size()):
		var zi: int = cap_z_indices[k]
		buf.put_32(zi)
		buf.put_32(_zone_capture_cid[zi])
		buf.put_float(_zone_capture_timer[zi])

	return buf.data_array


func unpack_state(blob: PackedByteArray) -> bool:
	_ensure_initialized()
	if blob.size() < 24:
		return false
	var buf := StreamPeerBuffer.new()
	buf.data_array = blob
	buf.seek(0)

	var magic: int = buf.get_32()
	var ver: int = buf.get_u32()
	if magic != SAVE_MAGIC or ver < 2 or ver > SAVE_VERSION:
		return false

	var mw: int = buf.get_u16()
	var mh: int = buf.get_u16()
	var zw: int = buf.get_u16()
	var zh: int = buf.get_u16()
	if mw != _map_w or mh != _map_h or zw != _zone_w or zh != _zone_h:
		return false

	_reset_state_arrays()
	_sim_time = buf.get_float()
	_total_harvested = buf.get_float()
	if ver >= 3:
		_total_shuttles_launched = buf.get_32()
	if ver >= 4:
		_shield_blocked_total = buf.get_32()
		_supply_deliveries = buf.get_32()
	if ver >= 5:
		_rebellions_total = buf.get_32()

	for z in range(_zone_count):
		_zone_city_id[z] = buf.get_32()
		_zone_faction_id[z] = buf.get_u8()
		_zone_flags[z] = buf.get_u8()
		_zone_ore[z] = buf.get_32()
		_zone_fertility[z] = buf.get_float()

	var r_sz: int = buf.get_u32()
	if r_sz != _road_mask.size():
		return false
	var r_res: Array = buf.get_data(r_sz)
	if int(r_res[0]) != OK:
		return false
	_road_mask = r_res[1] as PackedByteArray
	_road_px_count = 0
	for px_i in range(_road_mask.size()):
		if _road_mask[px_i] != ROAD_NONE:
			_road_px_count += 1

	var saved_cities: int = mini(_max_cities, buf.get_u16())
	for c in range(saved_cities):
		var act: int = buf.get_u8()
		_city_active[c] = act
		if act == 0:
			continue
		var f_id: int = clampi(buf.get_u8(), 0, FACTION_TINT_COLORS.size() - 1)
		_city_faction[c] = f_id
		_city_color[c] = FACTION_TINT_COLORS[f_id]
		if ver >= 3:
			_city_name[c] = buf.get_utf8_string()
		else:
			_city_name[c] = _pick_city_name(f_id, c)
		_city_center[c] = Vector2(buf.get_float(), buf.get_float())
		_city_mine_pos[c] = Vector2(buf.get_float(), buf.get_float())
		_city_build_pos[c] = Vector2(buf.get_float(), buf.get_float())
		_city_patrol_pos[c] = Vector2(buf.get_float(), buf.get_float())
		if ver >= 3:
			_city_threat_pos[c] = Vector2(buf.get_float(), buf.get_float())
			_city_alerted[c] = buf.get_u8()
			_city_alert_timer[c] = buf.get_float()
		_city_tech_tier[c] = buf.get_u8()
		_city_tech_score[c] = buf.get_float()
		_city_pop[c] = buf.get_32()
		_city_zones_count[c] = buf.get_32()
		_city_food[c] = buf.get_float()
		_city_ore[c] = buf.get_float()
		_city_energy[c] = buf.get_float()
		_city_science[c] = buf.get_float()
		_city_storage_cap[c] = buf.get_float()
		_city_expand_timer[c] = buf.get_float()
		_city_pop_timer[c] = buf.get_float()
		if ver >= 3:
			_city_shuttle_cd[c] = buf.get_float()
			_city_shuttles_launched[c] = buf.get_32()
		_city_proj_type[c] = buf.get_32()
		_city_proj_prog[c] = buf.get_float()
		_city_proj_work[c] = buf.get_float()
		var saved_bt_count: int = 8 if ver < 4 else (9 if ver == 4 else BLD_TYPE_COUNT)
		var base_b: int = c * BLD_TYPE_COUNT
		for bt in range(saved_bt_count):
			var cnt: int = buf.get_32()
			if bt < BLD_TYPE_COUNT:
				_city_bld_counts[base_b + bt] = cnt
		if ver >= 5:
			_city_loyalty[c] = buf.get_float()
			_city_is_rebel[c] = buf.get_u8()
			_city_war_state[c] = buf.get_u8()
			_city_emp_timer[c] = buf.get_float()
			_city_war_cooldown[c] = buf.get_float()
			_city_overlord[c] = buf.get_32()
			_city_tech_floor[c] = buf.get_u8()
			_city_color[c] = _get_city_tint_color(c)

	_bld_count = mini(_max_buildings, buf.get_u16())
	for b in range(_bld_count):
		_bld_pos[b] = Vector2(buf.get_float(), buf.get_float())
		var bt_u: int = buf.get_u8()
		_bld_type[b] = bt_u
		_bld_radius[b] = BLD_AVOID_RADII[clampi(bt_u, 0, BLD_TYPE_COUNT - 1)]
		var cid: int = buf.get_32()
		_bld_city_id[b] = cid
		_bld_color[b] = _get_city_tint_color(cid)
		_bld_hp[b] = buf.get_float()
		_bld_spring[b] = buf.get_float()
		_bld_spring_vel[b] = buf.get_float()
		_bld_shake[b] = buf.get_float()
		_bld_phase[b] = buf.get_float()
		if ver >= 4:
			_bld_shield_charge[b] = buf.get_float()
			_bld_shield_flash[b] = buf.get_float()
		else:
			_bld_shield_charge[b] = 1.0 if bt_u == BuildingType.SHIELD_PYLON else 0.0
			_bld_shield_flash[b] = 0.0

	if ver >= 3:
		_ruin_count = mini(_max_ruins, buf.get_u16())
		for r in range(_ruin_count):
			_ruin_pos[r] = Vector2(buf.get_float(), buf.get_float())
			_ruin_ore[r] = buf.get_float()
			_ruin_sci[r] = buf.get_float()
			_ruin_faction[r] = buf.get_u8()
			_ruin_phase[r] = buf.get_float()

		_shuttle_count = mini(_max_shuttles, buf.get_u16())
		for s in range(_shuttle_count):
			_shuttle_start[s] = Vector2(buf.get_float(), buf.get_float())
			_shuttle_target[s] = Vector2(buf.get_float(), buf.get_float())
			_shuttle_pos[s] = Vector2(buf.get_float(), buf.get_float())
			_shuttle_t[s] = buf.get_float()
			_shuttle_dur[s] = buf.get_float()
			_shuttle_faction[s] = buf.get_u8()
			_shuttle_src_city[s] = buf.get_32()
			_shuttle_trail_t[s] = 0.0
			if ver >= 4:
				_shuttle_kind[s] = buf.get_u8()
				_shuttle_target_city[s] = buf.get_32()
			else:
				_shuttle_kind[s] = SHUTTLE_KIND_COLONIZE
				_shuttle_target_city[s] = -1

	if ver >= 5:
		var d_sz: int = buf.get_u32()
		if d_sz != _diplo_matrix.size():
			return false
		var d_res: Array = buf.get_data(d_sz)
		if int(d_res[0]) != OK:
			return false
		_diplo_matrix = d_res[1] as PackedByteArray
		for m in range(_diplo_matrix.size()):
			_diplo_tension[m] = buf.get_float()
		var cap_n: int = buf.get_u16()
		for k in range(cap_n):
			var zi: int = buf.get_32()
			var cid_cap: int = buf.get_32()
			var t_cap: float = buf.get_float()
			if zi >= 0 and zi < _zone_count:
				_zone_capture_cid[zi] = cid_cap
				_zone_capture_timer[zi] = t_cap
				if cid_cap >= 0 and t_cap > 0.0 and _zone_in_active_cap[zi] == 0:
					_zone_in_active_cap[zi] = 1
					_active_cap_zones[_active_cap_count] = zi
					_active_cap_count += 1
		for c in range(saved_cities):
			if _city_active[c] != 0:
				_recompute_city_war_state(c)

	_city_proj_retry.fill(0.0)
	_city_tech_dirty.fill(1)
	_goals_dirty = true
	_bld_footprints_dirty = true
	_buildings_dirty = false
	_bld_anim_step = int(floor(_sim_time * 8.0))
	_last_pushed_physics = null
	_mark_all_borders_dirty()
	_flush_dirty_borders()
	_sync_buildings_multimesh()
	_push_goal_buffers()
	return true
