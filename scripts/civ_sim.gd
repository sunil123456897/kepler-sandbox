extends Node2D
class_name CivSim

## Civilization simulation core: delegates territory/roads/farms/borders to
## CivTerritory (`civ_territory.gd`) and kingdoms/plots/diplomacy/expeditions
## to CivDiplomacy (`civ_diplomacy.gd`), keeping SoA buffers zero-GC.

const UNIT_SPRITE_SHADER := preload("res://shaders/unit_sprite.gdshader")
const CivTerritoryScript := preload("res://scripts/civ_territory.gd")
const CivDiplomacyScript := preload("res://scripts/civ_diplomacy.gd")
const CivMetaScript := preload("res://scripts/civ_meta_noosphere.gd")
const BUILDINGS_ATLAS_PATH := "res://assets/atlases/buildings_atlas.png"
const BUILDINGS_MASK_PATH := "res://assets/atlases/buildings_atlas_mask.png"
const BUILDINGS_ATLAS_JSON_PATH := "res://assets/atlases/buildings_atlas.json"

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
	"MAX_PLANET_UNITS": 720,
	"MIN_CITY_SPACING_PX": 48.0,
	"SELF_FOUND_SPACING_PX": 64.0,
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
	"FIRST_EXPAND_DELAY_SEC": 8.0,
	"ZONE_EXPAND_INTERVAL_SEC": 14.0,
	"ZONE_EXPAND_COST_ORE": 3.0,
	"POP_GROWTH_INTERVAL_SEC": 8.0,
	"POP_GROWTH_FOOD_COST": 8.0,
	"SPRING_OMEGA": 18.0,
	"SPRING_ZETA": 0.25,
	"DOME_PROTECTION_RADIUS": 18.0,
	"REACTOR_MELTDOWN_RADIUS": 12.0,
	"SHUTTLE_HOP_MIN_DIST_PX": 48.0,
	"SHUTTLE_HOP_MAX_DIST_PX": 185.0,
	"SHUTTLE_LAUNCH_ORE": 12.0,
	"SHUTTLE_LAUNCH_ENERGY": 8.0,
	"SHUTTLE_COOLDOWN_SEC": 18.0,
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
	"SPORE_CREEP_INTERVAL_SEC": 12.0,
	"SUPPLY_SCAN_SEC": 4.0,
	"SUPPLY_RICH_FOOD": 90.0,
	"SUPPLY_RICH_ORE": 75.0,
	"SUPPLY_NEED_SUM": 40.0,
	"SUPPLY_FOOD": 25.0,
	"SUPPLY_ORE": 25.0,
	"SUPPLY_ENERGY": 15.0,
	"TIER1_AGE_SEC": 195.0,
	"TIER2_AGE_SEC": 480.0,
	"TIER3_AGE_SEC": 750.0,
	"TIER4_AGE_SEC": 1320.0,
	"TIER3_SCI_REQ": 195.0,
	"TIER3_SCORE_REQ": 11.0,
	"TIER4_SCI_REQ": 650.0,
	"TIER4_SCORE_REQ": 18.0,
	"QUANTUM_GATE_MAX_PER_CITY": 2,
	"QUANTUM_GATE_ENERGY_MIN": 12.0,
	"DIPLO_SCAN_SEC": 0.65,
	"DIPLO_WAR_TENSION_THRESHOLD": 35.0,
	"DIPLO_PACT_TENSION_THRESHOLD": -24.0,
	"DIPLO_WAR_COOLDOWN_SEC": 20.0,
	"WAR_CAPTURE_SCAN_SEC": 0.30,
	"WAR_ZONE_CAPTURE_SEC": 4.0,
	"REBEL_LOYALTY_THRESHOLD": 25.0,
	"REBEL_CAPITAL_DIST_PX": 140.0,
	"REBEL_LOYALTY_DECAY_PER_SEC": 1.8,
	"REBEL_LOYALTY_RECOVER_PER_SEC": 0.9,
	"EMP_GLITCH_DURATION_SEC": 8.0,
	"AI_GLITCH_LOYALTY_HIT": 42.0,
	"ECOLOGY_BATCH_INTERVAL_SEC": 1.25,
	"SMOKE_PUFF_INTERVAL_SEC": 0.45,
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
	DOCK = 10,
	BARRACKS = 11,
	DEFENSE_TURRET = 12,
	TRADE_HUB = 13,
	ARCHIVE = 14,
	MONOLITH = 15,
}

enum ResourceType {
	FOOD = 0,
	ORE = 1,
	ENERGY = 2,
	SCIENCE = 3,
	BUILD_WORK = 4,
	WOOD = 5,
	CREDITS = 6,
}

const TIER_CLOSE_OCEAN: int = 1
const TIER_SHALLOW: int = 2
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

const BLD_TYPE_COUNT: int = 16
const ATLAS_COLS: int = 60
const MAX_SHIPS: int = 32
const BUILDING_CELL_PX: float = 24.0
const SAVE_MAGIC: int = 0x43495632 # "CIV2"
const SAVE_VERSION: int = 7

const SHUTTLE_KIND_COLONIZE: int = 0
const SHUTTLE_KIND_SUPPLY: int = 1
const SHUTTLE_KIND_BOAT: int = 2

const STRIP_PACT: int = 8
const STRIP_WAR: int = 9
const STRIP_REBEL: int = 10
const STRIP_PORTAL: int = 11

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
const BLD_COL_HUMAN_ARK_SPIRE: int = 41
const BLD_COL_ROBOT_MIRROR_NODE: int = 42
const BLD_COL_SPORE_LEVIATHAN_HEART: int = 43
const BLD_COL_DOCK: int = 44
const BLD_COL_BARRACKS: int = 45
const BLD_COL_DEFENSE_TURRET: int = 46
const BLD_COL_TRADE_HUB: int = 47
const BLD_COL_ARCHIVE: int = 48
const BLD_COL_MONOLITH: int = 49
const BLD_COL_HQ_L2_HUMAN: int = 50
const BLD_COL_HQ_L2_ROBOT: int = 51
const BLD_COL_HQ_L2_SPORE: int = 52

const BLD_COLS_HUMAN := [0, 1, 2, 3, 4, 5, 6, 7, BLD_COL_SHIELD, BLD_COL_QUANTUM_GATE, BLD_COL_DOCK, BLD_COL_BARRACKS, BLD_COL_DEFENSE_TURRET, BLD_COL_TRADE_HUB, BLD_COL_ARCHIVE, BLD_COL_MONOLITH]
const BLD_COLS_ROBOT := [38, 39, 20, 21, 22, 40, 23, 24, BLD_COL_SHIELD, BLD_COL_QUANTUM_GATE, BLD_COL_DOCK, BLD_COL_BARRACKS, BLD_COL_DEFENSE_TURRET, BLD_COL_TRADE_HUB, BLD_COL_ARCHIVE, BLD_COL_MONOLITH]
const BLD_COLS_SPORE := [25, 27, 26, 27, 28, 29, 30, 31, BLD_COL_SHIELD, BLD_COL_QUANTUM_GATE, BLD_COL_DOCK, BLD_COL_BARRACKS, BLD_COL_DEFENSE_TURRET, BLD_COL_TRADE_HUB, BLD_COL_ARCHIVE, BLD_COL_MONOLITH]
const TIER_SCIENCE_CAPS: Array[float] = [42.0, 135.0, 360.0, 880.0, 1600.0, 2500.0]

const FACTION_NAMES := ["Human", "Robot", "Spore"]
const BUILDING_NAMES := ["Campfire", "Tent", "Drill", "Depot", "Solar Array", "Biodome", "Fusion Reactor", "Launchpad", "Shield Pylon", "Quantum Gate", "Dock", "Barracks", "Defense Turret", "Trade Hub", "Archive", "Monolith"]
const CITY_NAME_POOLS := [
	["Пост Кеплера", "Базальт-Гавань", "Кальдера-Порт", "Меридиан", "Редут Семь", "Вечерний Хребет", "Пепельная Бухта", "Станция Атолл"],
	["Узел Феррит", "Сетка-Печь", "Анодный Бассейн", "Релейный Луч", "Кварц-Сборка", "Кремневый Цех", "Ядро Торуса", "Решётка Четыре"],
	["Венец Мицелия", "Лишайный Уступ", "Папоротниковый Лог", "Моховой Шпиль", "Споровая Дельта", "Водорослевый Ров", "Гребень Ризомы", "Пыльцевой Край"],
]

const REBEL_TERRITORY_COLOR := Color("#FF9B26")
const REBEL_ACCENT_COLOR := Color("#FFE156")
const FACTION_BORDER_COLORS := [Color("#38F0FF"), Color("#E63B3B"), Color("#B84DFF")]
const FACTION_TINT_COLORS := [Color("#38D8EE"), Color("#E03B3B"), Color("#A846E6")]

const BLD_TECH_POINTS: Array[float] = [1.0, 1.5, 2.5, 2.5, 3.5, 4.0, 5.0, 6.0, 5.5, 7.0, 2.8, 2.6, 3.0, 3.2, 3.8, 6.5]
const BLD_ORE_COSTS: Array[float] = [2.0, 4.0, 7.0, 6.0, 9.0, 11.0, 14.0, 16.0, 14.0, 18.0, 10.0, 9.0, 11.0, 10.0, 11.0, 22.0]
const BLD_ENERGY_COSTS: Array[float] = [0.0, 0.5, 1.5, 1.2, 0.0, 2.5, 4.0, 4.0, 3.5, 8.0, 1.0, 1.5, 2.5, 1.5, 2.0, 6.0]
const BLD_BUILD_TIMES: Array[float] = [12.0, 8.5, 15.0, 14.5, 17.0, 18.5, 21.0, 22.0, 18.5, 22.0, 16.0, 15.0, 17.0, 16.0, 18.0, 24.0]
const BLD_FOOTPRINTS: Array[float] = [10.0, 13.5, 14.0, 14.0, 14.0, 18.0, 18.0, 22.0, 14.5, 18.0, 15.0, 14.5, 12.5, 15.0, 15.0, 19.0]
const BLD_AVOID_RADII: Array[float] = [8.0, 10.0, 10.5, 10.5, 10.5, 12.5, 12.5, 13.5, 10.5, 12.0, 11.0, 10.5, 9.5, 11.0, 11.0, 13.0]

var _territory: RefCounted = null
var _diplomacy: RefCounted = null
var _meta: RefCounted = null
var _world: Node2D = null
var _physics: Node2D = null
var _fx: Node2D = null

var _map_w: int = int(TUNING_KNOBS["MAP_WIDTH"])
var _map_h: int = int(TUNING_KNOBS["MAP_HEIGHT"])
var _zone_px: int = int(TUNING_KNOBS["TILE_ZONE_PX"])
var _zone_w: int = 80
var _zone_h: int = 45
var _zone_count: int = 3600

var _zone_city_id: PackedInt32Array
var _zone_faction_id: PackedByteArray
var _zone_flags: PackedByteArray
var _zone_ore: PackedInt32Array
var _zone_ore_frac: PackedFloat32Array
var _zone_fertility: PackedFloat32Array
var _zone_close_n: PackedByteArray
var _zone_land_n: PackedByteArray
var _zone_farm_growth: PackedFloat32Array

var _road_mask: PackedByteArray
var _foot_traffic: PackedByteArray
var _road_px_count: int = 0
var _road_dirt_count: int = 0
var _road_conduit_count: int = 0

var _border_buf: PackedByteArray
var _border_image: Image
var _border_texture: ImageTexture
var _border_sprite: Sprite2D
var _border_dirty: bool = false
var _dirty_zx0: int = 80
var _dirty_zy0: int = 45
var _dirty_zx1: int = -1
var _dirty_zy1: int = -1
var _border_tint_alpha_cache: int = -1
var _border_thick_cache: int = -1
var _border_flush_cd: float = 0.0
var _sim_tick_idx: int = 0

var _tmp_own_grid: PackedInt32Array
var _tmp_eff_grid: PackedInt32Array
var _tmp_edge_grid: PackedByteArray

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
var _city_wood: PackedFloat32Array
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
var _city_tech_cd: PackedFloat32Array
var _city_damaged_blds: PackedByteArray
var _city_farm_count: PackedInt32Array
var _city_farm_scan_cd: PackedFloat32Array
var _city_coastal_cache: PackedByteArray
var _city_bld_counts: PackedInt32Array
var _city_kingdom_id: PackedInt32Array
var _city_age_sec: PackedFloat32Array
var _city_dome_powered: PackedByteArray
var _city_tier5_done: PackedByteArray
var _city_spore_creep_cd: PackedFloat32Array
var _city_drill_dep_mul: PackedFloat32Array
var _city_credits: PackedFloat32Array
var _city_hq_level: PackedByteArray
var _tmp_city_drill_cnt: PackedInt32Array
var _tmp_city_drill_sum: PackedFloat32Array

var _kingdom_active: PackedByteArray
var _kingdom_faction: PackedByteArray
var _kingdom_capital_cid: PackedInt32Array
var _kingdom_name: PackedStringArray
var _kingdom_color: PackedColorArray
var _kingdom_city_count: PackedInt32Array

var _diplo_matrix: PackedByteArray
var _diplo_tension: PackedFloat32Array
var _diplo_pair_cd: PackedFloat32Array
var _city_loyalty: PackedFloat32Array
var _city_is_rebel: PackedByteArray
var _city_war_state: PackedByteArray
var _city_emp_timer: PackedFloat32Array
var _city_war_cooldown: PackedFloat32Array
var _city_overlord: PackedInt32Array
var _city_tech_floor: PackedByteArray

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
var _bld_level: PackedByteArray

var _max_ruins: int = int(TUNING_KNOBS["MAX_RUINS"])
var _ruin_count: int = 0
var _ruin_pos: PackedVector2Array
var _ruin_ore: PackedFloat32Array
var _ruin_sci: PackedFloat32Array
var _ruin_faction: PackedByteArray
var _ruin_phase: PackedFloat32Array

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
var _shuttle_cargo_food: PackedFloat32Array
var _shuttle_cargo_ore: PackedFloat32Array
var _shuttle_cargo_energy: PackedFloat32Array

var _zoom_val: float = 2.4
var _bld_atlas_cols: int = ATLAS_COLS
var _mm_buildings: MultiMeshInstance2D
var _bld_mat: ShaderMaterial
var _atlas_tex: Texture2D
var _mask_tex: Texture2D

var _goal_buffers: Dictionary = {}
var _goals_dirty: bool = true
var _light_goals_dirty: bool = false
var _diplo_dirty_seq: int = 0
var _bld_footprints_dirty: bool = false
var _bld_removed_dirty: bool = false
var _bld_upg_idx: int = -1
var _road_mask_dirty: bool = true
var _buildings_dirty: bool = false
var _ships_mm_slot_base: int = 0
var _has_bld_springs: bool = false
var _spring_cache_dirty: bool = false
var _spring_indices: PackedInt32Array
var _spring_dirty_ids: PackedInt32Array
var _shield_cache_dirty: bool = true
var _shield_indices: PackedInt32Array
var _drill_cache_dirty: bool = true
var _drill_indices: PackedInt32Array
var _drill_pace_acc: float = 0.0
var _drill_active_cnt: int = 0
var _physics_has_get_city_pop: bool = false
var _physics_has_set_goal_buffers: bool = false
var _physics_has_sync_light_goals: bool = false
var _physics_has_spawn_colony_units: bool = false
var _physics_has_get_unit_count: bool = false
var _physics_has_unit_capture_api: bool = false
var _physics_has_get_unit_roles: bool = false
var _physics_has_clear_footprint: bool = false
var _fx_has_spawn_burst: bool = false
var _fx_has_play_sfx: bool = false
var _fx_has_campfire_ember: bool = false
var _fx_has_emit_build_pop: bool = false
var _fx_has_spawn_reaction_strip: bool = false
var _world_has_apply_ecology_batch: bool = false
var _world_has_get_fire: bool = false
var _world_has_get_moisture: bool = false
var _bld_anim_step: int = -1
var _goal_version: int = 0
var _pushed_goal_version: int = -1
var _last_pushed_physics: Node2D = null

var _k_border_line_a: int = 230
var _k_border_back_a: int = 214
var _k_conduit_vein_lum: float = 0.55
var _k_border_clash_dist: float = 88.0
var _k_base_storage_cap: float = 200.0
var _k_depot_storage_bonus: float = 150.0
var _k_launchpad_storage_bonus: float = 300.0
var _k_first_expand_delay: float = 8.0
var _k_zone_expand_int: float = 14.0
var _k_zone_expand_ore: float = 3.0
var _k_pop_growth_int: float = 8.0
var _k_pop_growth_food: float = 8.0
var _k_max_planet_units: int = 720
var _k_self_found_spacing: float = 64.0
var _k_min_city_spacing: float = 48.0
var _k_start_city_pop: int = 16
var _k_dim_count: int = 3
var _k_dup_mid_w: float = 0.25
var _k_max_city_blds: int = 32
var _k_gate_max: int = 2
var _k_gate_e_min: float = 12.0
var _k_spring_omega: float = 18.0
var _k_spring_zeta: float = 0.25
var _k_dome_prot_r: float = 18.0
var _k_meltdown_r: float = 12.0
var _k_shuttle_hop_min: float = 48.0
var _k_shuttle_hop_max: float = 185.0
var _k_shuttle_ore: float = 12.0
var _k_shuttle_energy: float = 8.0
var _k_shuttle_cd: float = 18.0
var _k_shuttle_speed: float = 34.0
var _k_robot_rad_gain: float = 16.0
var _k_spore_exp_int_mul: float = 0.68
var _k_spore_exp_ore_mul: float = 0.65
var _k_spore_fire_mul: float = 2.4
var _k_ruin_salvage_r: float = 26.0
var _k_shield_r: float = 48.0
var _k_shield_cost: float = 0.35
var _k_shield_min_ch: float = 0.25
var _k_shield_impact_mul: float = 0.35
var _k_shield_recharge: float = 0.12
var _k_shield_flash_decay: float = 2.4
var _k_spore_creep_int: float = 12.0
var _k_supply_scan_sec: float = 4.0
var _k_supply_rich_food: float = 90.0
var _k_supply_rich_ore: float = 75.0
var _k_supply_need_sum: float = 40.0
var _k_supply_food: float = 25.0
var _k_supply_ore: float = 25.0
var _k_supply_energy: float = 15.0
var _k_tier1_age: float = 195.0
var _k_tier2_age: float = 480.0
var _k_tier3_age: float = 750.0
var _k_tier4_age: float = 1320.0
var _k_tier3_sci: float = 195.0
var _k_tier3_score: float = 11.0
var _k_tier4_sci: float = 650.0
var _k_tier4_score: float = 18.0
var _k_diplo_scan_sec: float = 0.65
var _k_diplo_war_th: float = 35.0
var _k_diplo_pact_th: float = -24.0
var _k_diplo_war_cd: float = 20.0
var _k_war_cap_scan_sec: float = 0.30
var _k_war_zone_cap_sec: float = 4.0
var _k_rebel_loy_thresh: float = 25.0
var _k_rebel_cap_dist: float = 140.0
var _k_rebel_loy_decay: float = 1.8
var _k_rebel_loy_recover: float = 0.9
var _k_emp_glitch_dur: float = 8.0
var _k_ai_glitch_loy_hit: float = 42.0
var _k_eco_batch_int: float = 1.25
var _k_smoke_int: float = 0.45
var _rng := RandomNumberGenerator.new()
var _rng_seed: int = 20261114
var _sim_time: float = 0.0
var _sim_pace_mult: float = 1.0
var _law_self_founding: bool = true
var _law_diplomacy_wars: bool = true
var _law_rebellions: bool = true
var _law_cosmic_ages: bool = true
var _law_disasters: bool = true
var _law_rad_mutations: bool = true
var _world_laws_dict: Dictionary = {}

var _total_harvested: float = 0.0
var _total_shuttles_launched: int = 0
var _shield_blocked_total: int = 0
var _supply_deliveries: int = 0
var _border_clash_count: int = 0
var _rebellions_total: int = 0
var _tier5_victories: int = 0
var _ecology_events_sent_total: int = 0
var _ecology_cursor: int = 0
var _ecology_events_scratch: Array = []

var _clash_scan_timer: float = 0.0
var _clash_raw_cd: float = 0.0
var _clash_pace_acc: float = 0.0
var _env_check_timer: float = 0.0
var _ruin_tick_timer: float = 0.0
var _ruin_raw_cd: float = 0.0
var _shuttle_launch_timer: float = 0.0
var _supply_scan_timer: float = 0.0
var _diplo_scan_timer: float = 0.0
var _diplo_raw_cd: float = 0.0
var _diplo_pace_acc: float = 0.0
var _capture_scan_timer: float = 0.0
var _capture_raw_cd: float = 0.0
var _capture_pace_acc: float = 0.0
var _ecology_timer: float = 0.0
var _ecology_raw_cd: float = 0.0
var _smoke_puff_timer: float = 0.0

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
	_physics_has_get_city_pop = false
	_physics_has_set_goal_buffers = false
	_physics_has_sync_light_goals = false
	_physics_has_spawn_colony_units = false
	_physics_has_get_unit_count = false
	_physics_has_unit_capture_api = false
	_physics_has_get_unit_roles = false
	_physics_has_clear_footprint = false
	_fx_has_spawn_burst = false
	_fx_has_play_sfx = false
	_fx_has_campfire_ember = false
	_fx_has_emit_build_pop = false
	_fx_has_spawn_reaction_strip = false
	_world_has_apply_ecology_batch = false
	_world_has_get_fire = false
	_world_has_get_moisture = false
	_last_pushed_physics = null
	_goal_buffers.clear()
	_ecology_events_scratch.clear()
	_world_laws_dict.clear()
	_territory = null
	_diplomacy = null
	_meta = null

	if _border_sprite != null and is_instance_valid(_border_sprite):
		_border_sprite.texture = null
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


func set_sim_pace(mult: float) -> void:
	_sim_pace_mult = clampf(mult, 0.05, 120.0)


func set_world_laws(laws: Dictionary) -> void:
	for k in laws:
		_world_laws_dict[str(k)] = laws[k]
	_law_self_founding = bool(laws.get("self_founding", _law_self_founding))
	_law_diplomacy_wars = bool(laws.get("diplomacy_wars", _law_diplomacy_wars))
	_law_rebellions = bool(laws.get("rebellions", _law_rebellions))
	_law_cosmic_ages = bool(laws.get("cosmic_ages", _law_cosmic_ages))
	_law_disasters = bool(laws.get("disasters", _law_disasters))
	_law_rad_mutations = bool(laws.get("rad_mutations", _law_rad_mutations))


func is_law_enabled(law_key: String, default_val: bool = true) -> bool:
	if _world_laws_dict.has(law_key):
		return bool(_world_laws_dict[law_key])
	match law_key:
		"self_founding":
			return _law_self_founding
		"diplomacy_wars":
			return _law_diplomacy_wars
		"rebellions":
			return _law_rebellions
		"cosmic_ages":
			return _law_cosmic_ages
		"disasters":
			return _law_disasters
		"rad_mutations":
			return _law_rad_mutations
	return default_val


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
	var kid: int = _city_kingdom_id[city_id]
	if kid >= 0 and kid < _max_cities and _kingdom_active[kid] != 0:
		return _kingdom_color[kid]
	var f_id: int = clampi(int(_city_faction[city_id]), 0, FACTION_BORDER_COLORS.size() - 1)
	return FACTION_BORDER_COLORS[f_id]


func _get_city_tint_color(city_id: int) -> Color:
	if city_id < 0 or city_id >= _max_cities or _city_active[city_id] == 0:
		return FACTION_TINT_COLORS[0]
	if _city_is_rebel[city_id] != 0:
		return REBEL_TERRITORY_COLOR
	var kid: int = _city_kingdom_id[city_id]
	if kid >= 0 and kid < _max_cities and _kingdom_active[kid] != 0:
		return _kingdom_color[kid].lerp(FACTION_TINT_COLORS[clampi(int(_city_faction[city_id]), 0, 2)], 0.35)
	var f_id: int = clampi(int(_city_faction[city_id]), 0, FACTION_TINT_COLORS.size() - 1)
	return FACTION_TINT_COLORS[f_id]


func _are_cities_hostile(city_a: int, city_b: int) -> bool:
	if city_a < 0 or city_a >= _max_cities or city_b < 0 or city_b >= _max_cities or city_a == city_b:
		return false
	if _city_active[city_a] == 0 or _city_active[city_b] == 0:
		return false
	var d_state: int = int(_diplo_matrix[city_a * _max_cities + city_b])
	return d_state == Diplomacy.TOTAL_WAR or d_state == Diplomacy.REBELLION


func _recompute_city_war_state(city_id: int) -> void:
	if city_id < 0 or city_id >= _max_cities:
		return
	var prev_war: int = int(_city_war_state[city_id])
	if _city_active[city_id] == 0:
		_city_war_state[city_id] = Diplomacy.NEUTRAL
		if prev_war != Diplomacy.NEUTRAL:
			_diplo_dirty_seq += 1
		return
	if _city_is_rebel[city_id] != 0:
		_city_war_state[city_id] = Diplomacy.REBELLION
		if prev_war != Diplomacy.REBELLION:
			_diplo_dirty_seq += 1
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
	if prev_war != max_state:
		_diplo_dirty_seq += 1


func _mark_city_zones_dirty(city_id: int) -> void:
	for zy in range(_zone_h):
		for zx in range(_zone_w):
			if _get_zone_owner(zx, zy) == city_id:
				_territory.mark_zone_dirty(self, zx, zy)


func _cache_tuning_knobs() -> void:
	_k_border_line_a = clampi(int(round(float(TUNING_KNOBS["BORDER_LINE_ALPHA"]) * 255.0)), 180, 255)
	_k_border_back_a = clampi(int(round(float(TUNING_KNOBS["BORDER_BACKING_ALPHA"]) * 255.0)), 160, 245)
	_k_conduit_vein_lum = float(TUNING_KNOBS["CONDUIT_VEIN_LUMINANCE"])
	_k_border_clash_dist = float(TUNING_KNOBS["BORDER_CLASH_DIST_PX"])
	_k_base_storage_cap = float(TUNING_KNOBS["BASE_STORAGE_CAP"])
	_k_depot_storage_bonus = float(TUNING_KNOBS["DEPOT_STORAGE_BONUS"])
	_k_launchpad_storage_bonus = float(TUNING_KNOBS["LAUNCHPAD_STORAGE_BONUS"])
	_k_first_expand_delay = float(TUNING_KNOBS["FIRST_EXPAND_DELAY_SEC"])
	_k_zone_expand_int = float(TUNING_KNOBS["ZONE_EXPAND_INTERVAL_SEC"])
	_k_zone_expand_ore = float(TUNING_KNOBS["ZONE_EXPAND_COST_ORE"])
	_k_pop_growth_int = float(TUNING_KNOBS["POP_GROWTH_INTERVAL_SEC"])
	_k_pop_growth_food = float(TUNING_KNOBS["POP_GROWTH_FOOD_COST"])
	_k_max_planet_units = int(TUNING_KNOBS["MAX_PLANET_UNITS"])
	_k_self_found_spacing = float(TUNING_KNOBS["SELF_FOUND_SPACING_PX"])
	_k_min_city_spacing = float(TUNING_KNOBS["MIN_CITY_SPACING_PX"])
	_k_start_city_pop = int(TUNING_KNOBS["START_CITY_POP"])
	_k_dim_count = int(TUNING_KNOBS["TIER_DUP_DIMINISH_COUNT"])
	_k_dup_mid_w = float(TUNING_KNOBS["DUP_MID_WEIGHT"])
	_k_max_city_blds = int(TUNING_KNOBS["MAX_CITY_BUILDINGS"])
	_k_gate_max = clampi(int(TUNING_KNOBS["QUANTUM_GATE_MAX_PER_CITY"]), 1, 2)
	_k_gate_e_min = float(TUNING_KNOBS["QUANTUM_GATE_ENERGY_MIN"])
	_k_spring_omega = float(TUNING_KNOBS["SPRING_OMEGA"])
	_k_spring_zeta = float(TUNING_KNOBS["SPRING_ZETA"])
	_k_dome_prot_r = float(TUNING_KNOBS["DOME_PROTECTION_RADIUS"])
	_k_meltdown_r = float(TUNING_KNOBS["REACTOR_MELTDOWN_RADIUS"])
	_k_shuttle_hop_min = maxf(64.0, float(TUNING_KNOBS["SHUTTLE_HOP_MIN_DIST_PX"]))
	_k_shuttle_hop_max = float(TUNING_KNOBS["SHUTTLE_HOP_MAX_DIST_PX"])
	_k_shuttle_ore = float(TUNING_KNOBS["SHUTTLE_LAUNCH_ORE"])
	_k_shuttle_energy = float(TUNING_KNOBS["SHUTTLE_LAUNCH_ENERGY"])
	_k_shuttle_cd = float(TUNING_KNOBS["SHUTTLE_COOLDOWN_SEC"])
	_k_shuttle_speed = float(TUNING_KNOBS["SHUTTLE_SPEED_PX"])
	_k_robot_rad_gain = float(TUNING_KNOBS["ROBOT_RAD_ENERGY_GAIN"])
	_k_spore_exp_int_mul = float(TUNING_KNOBS["SPORE_EXPAND_INTERVAL_MUL"])
	_k_spore_exp_ore_mul = float(TUNING_KNOBS["SPORE_EXPAND_ORE_MUL"])
	_k_spore_fire_mul = float(TUNING_KNOBS["SPORE_FIRE_DMG_MUL"])
	_k_ruin_salvage_r = float(TUNING_KNOBS["RUIN_SALVAGE_RADIUS_PX"])
	_k_shield_r = float(TUNING_KNOBS["SHIELD_PYLON_RADIUS_PX"])
	_k_shield_cost = float(TUNING_KNOBS["SHIELD_INTERCEPT_COST"])
	_k_shield_min_ch = float(TUNING_KNOBS["SHIELD_MIN_CHARGE"])
	_k_shield_impact_mul = float(TUNING_KNOBS["SHIELD_IMPACT_RAD_MUL"])
	_k_shield_recharge = float(TUNING_KNOBS["SHIELD_BASE_RECHARGE"])
	_k_shield_flash_decay = float(TUNING_KNOBS["SHIELD_FLASH_DECAY"])
	_k_spore_creep_int = float(TUNING_KNOBS["SPORE_CREEP_INTERVAL_SEC"])
	_k_supply_scan_sec = float(TUNING_KNOBS["SUPPLY_SCAN_SEC"])
	_k_supply_rich_food = float(TUNING_KNOBS["SUPPLY_RICH_FOOD"])
	_k_supply_rich_ore = float(TUNING_KNOBS["SUPPLY_RICH_ORE"])
	_k_supply_need_sum = float(TUNING_KNOBS["SUPPLY_NEED_SUM"])
	_k_supply_food = float(TUNING_KNOBS["SUPPLY_FOOD"])
	_k_supply_ore = float(TUNING_KNOBS["SUPPLY_ORE"])
	_k_supply_energy = float(TUNING_KNOBS["SUPPLY_ENERGY"])
	_k_tier1_age = float(TUNING_KNOBS["TIER1_AGE_SEC"])
	_k_tier2_age = float(TUNING_KNOBS["TIER2_AGE_SEC"])
	_k_tier3_age = float(TUNING_KNOBS["TIER3_AGE_SEC"])
	_k_tier4_age = float(TUNING_KNOBS["TIER4_AGE_SEC"])
	_k_tier3_sci = float(TUNING_KNOBS["TIER3_SCI_REQ"])
	_k_tier3_score = float(TUNING_KNOBS["TIER3_SCORE_REQ"])
	_k_tier4_sci = float(TUNING_KNOBS["TIER4_SCI_REQ"])
	_k_tier4_score = float(TUNING_KNOBS["TIER4_SCORE_REQ"])
	_k_diplo_scan_sec = float(TUNING_KNOBS["DIPLO_SCAN_SEC"])
	_k_diplo_war_th = float(TUNING_KNOBS["DIPLO_WAR_TENSION_THRESHOLD"])
	_k_diplo_pact_th = float(TUNING_KNOBS["DIPLO_PACT_TENSION_THRESHOLD"])
	_k_diplo_war_cd = float(TUNING_KNOBS["DIPLO_WAR_COOLDOWN_SEC"])
	_k_war_cap_scan_sec = float(TUNING_KNOBS["WAR_CAPTURE_SCAN_SEC"])
	_k_war_zone_cap_sec = float(TUNING_KNOBS["WAR_ZONE_CAPTURE_SEC"])
	_k_rebel_loy_thresh = float(TUNING_KNOBS["REBEL_LOYALTY_THRESHOLD"])
	_k_rebel_cap_dist = float(TUNING_KNOBS["REBEL_CAPITAL_DIST_PX"])
	_k_rebel_loy_decay = float(TUNING_KNOBS["REBEL_LOYALTY_DECAY_PER_SEC"])
	_k_rebel_loy_recover = float(TUNING_KNOBS["REBEL_LOYALTY_RECOVER_PER_SEC"])
	_k_emp_glitch_dur = float(TUNING_KNOBS["EMP_GLITCH_DURATION_SEC"])
	_k_ai_glitch_loy_hit = float(TUNING_KNOBS["AI_GLITCH_LOYALTY_HIT"])
	_k_eco_batch_int = float(TUNING_KNOBS["ECOLOGY_BATCH_INTERVAL_SEC"])
	_k_smoke_int = float(TUNING_KNOBS["SMOKE_PUFF_INTERVAL_SEC"])


func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_cache_tuning_knobs()
	_rng.seed = _rng_seed
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_territory = CivTerritoryScript.new()
	_diplomacy = CivDiplomacyScript.new()
	_meta = CivMetaScript.new()
	_meta.ensure_allocated()

	_zone_px = maxi(1, int(TUNING_KNOBS["TILE_ZONE_PX"]))
	_zone_w = ceili(float(_map_w) / float(_zone_px))
	_zone_h = ceili(float(_map_h) / float(_zone_px))
	_zone_count = _zone_w * _zone_h

	_alloc_buffers()
	_build_border_layer()
	_build_buildings_layer()
	_reset_state_arrays()


func _alloc_buffers() -> void:
	_alloc_zone_and_road_buffers()
	_alloc_city_and_kingdom_buffers()
	_alloc_entity_and_capture_buffers()


func _alloc_zone_and_road_buffers() -> void:
	_zone_city_id.resize(_zone_count)
	_zone_faction_id.resize(_zone_count)
	_zone_flags.resize(_zone_count)
	_zone_ore.resize(_zone_count)
	_zone_ore_frac.resize(_zone_count)
	_zone_fertility.resize(_zone_count)
	_zone_close_n.resize(_zone_count)
	_zone_land_n.resize(_zone_count)
	_zone_farm_growth.resize(_zone_count)

	var total_px: int = _map_w * _map_h
	_road_mask.resize(total_px)
	_foot_traffic.resize(total_px)
	_border_buf.resize(total_px * 4)


func _alloc_city_and_kingdom_buffers() -> void:
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
	_city_wood.resize(_max_cities)
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
	_city_tech_cd.resize(_max_cities)
	_city_damaged_blds.resize(_max_cities)
	_city_farm_count.resize(_max_cities)
	_city_farm_scan_cd.resize(_max_cities)
	_city_coastal_cache.resize(_max_cities)
	_city_bld_counts.resize(_max_cities * BLD_TYPE_COUNT)
	_city_kingdom_id.resize(_max_cities)
	_city_age_sec.resize(_max_cities)
	_city_dome_powered.resize(_max_cities)
	_city_tier5_done.resize(_max_cities)
	_city_spore_creep_cd.resize(_max_cities)
	_city_drill_dep_mul.resize(_max_cities)
	_city_credits.resize(_max_cities)
	_city_hq_level.resize(_max_cities)
	_tmp_city_drill_cnt.resize(_max_cities)
	_tmp_city_drill_sum.resize(_max_cities)

	_kingdom_active.resize(_max_cities)
	_kingdom_faction.resize(_max_cities)
	_kingdom_capital_cid.resize(_max_cities)
	_kingdom_name.resize(_max_cities)
	_kingdom_color.resize(_max_cities)
	_kingdom_city_count.resize(_max_cities)


func _alloc_entity_and_capture_buffers() -> void:
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
	_bld_level.resize(_max_buildings)

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
	_shuttle_cargo_food.resize(_max_shuttles)
	_shuttle_cargo_ore.resize(_max_shuttles)
	_shuttle_cargo_energy.resize(_max_shuttles)


func _reset_state_arrays() -> void:
	_sim_time = 0.0
	_total_harvested = 0.0
	_total_shuttles_launched = 0
	_shield_blocked_total = 0
	_supply_deliveries = 0
	_border_clash_count = 0
	_rebellions_total = 0
	_tier5_victories = 0
	_ecology_events_sent_total = 0
	_ecology_cursor = 0
	_clash_scan_timer = 0.25
	_clash_raw_cd = 0.05
	_clash_pace_acc = 0.0
	_env_check_timer = 0.25
	_ruin_tick_timer = 0.25
	_ruin_raw_cd = 0.30
	_shuttle_launch_timer = 2.0
	_supply_scan_timer = 2.0
	_diplo_scan_timer = _k_diplo_scan_sec
	_diplo_raw_cd = 0.15
	_diplo_pace_acc = 0.0
	_capture_scan_timer = _k_war_cap_scan_sec
	_capture_raw_cd = 0.25
	_capture_pace_acc = 0.0
	_ecology_timer = _k_eco_batch_int
	_ecology_raw_cd = 0.0
	_sim_tick_idx = 0
	_smoke_puff_timer = _k_smoke_int
	_road_px_count = 0
	_road_dirt_count = 0
	_road_conduit_count = 0
	_bld_count = 0
	_ruin_count = 0
	_shuttle_count = 0

	_reset_zone_and_city_arrays()
	_diplomacy.reset_all()
	if _meta != null:
		_meta.reset_all(_rng_seed + 7919)
	_territory.reset_border_chunks()
	_border_flush_cd = 0.0

	if _border_image != null and _border_texture != null:
		_border_image.set_data(_map_w, _map_h, false, Image.FORMAT_RGBA8, _border_buf)
		_border_texture.update(_border_image)
	_border_dirty = false
	_dirty_zx0 = _zone_w
	_dirty_zy0 = _zone_h
	_dirty_zx1 = -1
	_dirty_zy1 = -1
	_border_tint_alpha_cache = -1
	_border_thick_cache = -1

	_goals_dirty = true
	_light_goals_dirty = false
	_diplo_dirty_seq += 1
	_bld_footprints_dirty = true
	_bld_removed_dirty = true
	_bld_upg_idx = -1
	_road_mask_dirty = true
	_buildings_dirty = true
	_ships_mm_slot_base = 0
	_has_bld_springs = false
	_spring_cache_dirty = false
	_spring_indices.clear()
	_spring_dirty_ids.clear()
	_shield_cache_dirty = true
	_shield_indices.clear()
	_drill_cache_dirty = true
	_drill_indices.clear()
	_drill_pace_acc = 0.0
	_drill_active_cnt = 0
	_bld_anim_step = -1
	if _mm_buildings != null and _mm_buildings.multimesh != null:
		_mm_buildings.multimesh.visible_instance_count = 0


func _reset_zone_and_city_arrays() -> void:
	_zone_city_id.fill(-1)
	_zone_faction_id.fill(255)
	_zone_flags.fill(0)
	_zone_ore.fill(0)
	_zone_ore_frac.fill(0.0)
	_zone_fertility.fill(0.5)
	_zone_close_n.fill(255)
	_zone_land_n.fill(255)
	_zone_farm_growth.fill(0.0)
	_road_mask.fill(ROAD_NONE)
	_foot_traffic.fill(0)
	_border_buf.fill(0)

	_city_active.fill(0)
	_city_faction.fill(0)
	for cid in range(_max_cities):
		_city_name[cid] = ""
		_kingdom_name[cid] = ""
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
	_city_wood.fill(0.0)
	_city_ore.fill(0.0)
	_city_energy.fill(0.0)
	_city_energy_spend_acc.fill(0.0)
	_city_energy_net.fill(0.0)
	_city_science.fill(0.0)
	_city_storage_cap.fill(_k_base_storage_cap)
	_city_expand_timer.fill(0.0)
	_city_pop_timer.fill(0.0)
	_city_shuttle_cd.fill(0.0)
	_city_shuttles_launched.fill(0)
	_city_proj_type.fill(-1)
	_city_proj_prog.fill(0.0)
	_city_proj_work.fill(0.0)
	_city_proj_retry.fill(0.0)
	_city_tech_dirty.fill(0)
	_city_tech_cd.fill(0.0)
	_city_damaged_blds.fill(0)
	_city_farm_count.fill(0)
	_city_farm_scan_cd.fill(0.0)
	_city_coastal_cache.fill(0)
	_city_bld_counts.fill(0)
	_city_kingdom_id.fill(-1)
	_city_age_sec.fill(0.0)
	_city_dome_powered.fill(1)
	_city_tier5_done.fill(0)
	_city_spore_creep_cd.fill(_k_spore_creep_int)
	_city_drill_dep_mul.fill(1.0)
	_city_credits.fill(10.0)
	_city_hq_level.fill(0)

	_kingdom_active.fill(0)
	_kingdom_faction.fill(0)
	_kingdom_capital_cid.fill(-1)
	_kingdom_color.fill(FACTION_BORDER_COLORS[0])
	_kingdom_city_count.fill(0)

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
	_bld_level.fill(0)
	_shuttle_kind.fill(SHUTTLE_KIND_COLONIZE)
	_shuttle_target_city.fill(-1)
	_shuttle_cargo_food.fill(0.0)
	_shuttle_cargo_ore.fill(0.0)
	_shuttle_cargo_energy.fill(0.0)


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


func _load_png_texture(res_path: String) -> Texture2D:
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


func _read_atlas_cols_from_json(json_path: String, fallback_cols: int) -> int:
	if not FileAccess.file_exists(json_path):
		return maxi(1, fallback_cols)
	var txt: String = FileAccess.get_file_as_string(json_path)
	if txt.is_empty():
		return maxi(1, fallback_cols)
	var parsed: Variant = JSON.parse_string(txt)
	if parsed is Dictionary:
		var d: Dictionary = parsed as Dictionary
		if d.has("atlas_cols"):
			return maxi(1, int(d["atlas_cols"]))
		if d.has("cols"):
			return maxi(1, int(d["cols"]))
	return maxi(1, fallback_cols)


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
	var tex_cols: int = maxi(1, int(_atlas_tex.get_width() / 24))
	_bld_atlas_cols = _read_atlas_cols_from_json(BUILDINGS_ATLAS_JSON_PATH, tex_cols)
	if tex_cols > 0 and _bld_atlas_cols > tex_cols:
		_bld_atlas_cols = tex_cols

	_mm_buildings = MultiMeshInstance2D.new()
	_mm_buildings.z_index = 1
	_mm_buildings.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mm_buildings.texture = _atlas_tex
	_bld_mat = ShaderMaterial.new()
	_bld_mat.shader = UNIT_SPRITE_SHADER
	_bld_mat.set_shader_parameter("sprite_mode", 3)
	_bld_mat.set_shader_parameter("motion_mode", 0)
	_bld_mat.set_shader_parameter("atlas_cols", _bld_atlas_cols)
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
	mm.instance_count = _max_buildings + _max_cities + _max_ruins + _max_shuttles + MAX_SHIPS
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
	_physics_has_get_city_pop = _physics != null and _physics.has_method("get_city_pop")
	_physics_has_set_goal_buffers = _physics != null and _physics.has_method("set_goal_buffers")
	_physics_has_sync_light_goals = _physics != null and _physics.has_method("sync_light_goals")
	_physics_has_spawn_colony_units = _physics != null and _physics.has_method("spawn_colony_units")
	_physics_has_get_unit_count = _physics != null and _physics.has_method("get_unit_count")
	_physics_has_unit_capture_api = _physics != null and _physics.has_method("get_unit_positions") and _physics.has_method("get_unit_cities")
	_physics_has_get_unit_roles = _physics != null and _physics.has_method("get_unit_roles")
	_physics_has_clear_footprint = _physics != null and _physics.has_method("clear_footprint")
	_fx_has_spawn_burst = _fx != null and _fx.has_method("spawn_burst")
	_fx_has_play_sfx = _fx != null and _fx.has_method("play_sfx")
	_fx_has_campfire_ember = _fx != null and _fx.has_method("emit_campfire_ember")
	_fx_has_emit_build_pop = _fx != null and _fx.has_method("emit_build_pop")
	_fx_has_spawn_reaction_strip = _fx != null and _fx.has_method("spawn_reaction_strip")
	_world_has_apply_ecology_batch = _world != null and _world.has_method("apply_civ_ecology_batch")
	_world_has_get_fire = _world != null and _world.has_method("get_fire")
	_world_has_get_moisture = _world != null and _world.has_method("get_moisture")

	if _world != null:
		var mw_v: Variant = _world.get("map_w")
		var mh_v: Variant = _world.get("map_h")
		if mw_v is int and mh_v is int and (int(mw_v) != _map_w or int(mh_v) != _map_h):
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
		_territory._refresh_world_byte_caches(self)
		_territory.scan_zone_range(self, Rect2i(0, 0, _zone_w, _zone_h))

	if _physics != null and _physics.has_method("bind_civ"):
		_physics.bind_civ(self)
	_goals_dirty = true
	_bld_removed_dirty = _bld_count > 0
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
	if _world != null:
		_territory._refresh_world_byte_caches(self)
		_territory.scan_zone_range(self, Rect2i(0, 0, _zone_w, _zone_h))
	_goals_dirty = true
	_bld_footprints_dirty = true
	_bld_removed_dirty = true
	_bld_upg_idx = -1
	_road_mask_dirty = true
	_push_goal_buffers()


func refresh_resource_zone(rect: Rect2i) -> void:
	_ensure_initialized()
	_territory.refresh_resource_zone(self, rect)


func _get_zone_owner(zx: int, zy: int) -> int:
	if zx < 0 or zx >= _zone_w or zy < 0 or zy >= _zone_h:
		return -1
	return _zone_city_id[zy * _zone_w + zx]


func get_zone_owner_at(world_pos: Vector2) -> int:
	return _get_zone_owner(int(floor(world_pos.x / float(_zone_px))), int(floor(world_pos.y / float(_zone_px))))


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


func record_foot_step(world_pos: Vector2, city_id: int) -> void:
	_ensure_initialized()
	_territory.record_foot_step(self, world_pos, city_id)


func can_settle_near(world_pos: Vector2) -> bool:
	_ensure_initialized()
	return _territory.can_settle_near(self, world_pos, _k_self_found_spacing)


func _is_zone_claimable(zx: int, zy: int, faction_id: int = 0) -> bool:
	return _territory.is_zone_claimable(self, Vector2i(zx, zy), faction_id)


func _is_city_coastal(city_id: int) -> bool:
	return _territory.is_city_coastal(self, city_id)


func _claim_zone(zx: int, zy: int, city_id: int, _faction_id: int) -> bool:
	return _territory.claim_zone(self, Vector2i(zx, zy), city_id)


func _refresh_city_targets(city_id: int) -> void:
	_territory.refresh_city_targets(self, city_id)


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


func _allocate_city_slot(safe_pos: Vector2, min_spacing: float) -> int:
	var min_sp2: float = min_spacing * min_spacing
	var free_cid: int = -1
	for cid in range(_max_cities):
		if _city_active[cid] == 0:
			if free_cid < 0:
				free_cid = cid
			continue
		if _city_center[cid].distance_squared_to(safe_pos) < min_sp2:
			return -1
	return free_cid


func _init_city_record(cid: int, safe_pos: Vector2, f_clamped: int, kingdom_id: int, overlord_cid: int) -> void:
	_city_farm_scan_cd[cid] = 0.0
	_city_farm_count[cid] = 0
	_city_damaged_blds[cid] = 0
	_city_active[cid] = 1
	_city_faction[cid] = f_clamped
	_city_name[cid] = _pick_city_name(f_clamped, cid)
	_city_center[cid] = safe_pos
	_city_threat_pos[cid] = Vector2.ZERO
	_city_alerted[cid] = 0
	_city_alert_timer[cid] = 0.0
	_city_tech_tier[cid] = 0
	_city_tech_score[cid] = 0.0
	_city_pop[cid] = 0
	_city_zones_count[cid] = 0
	_city_food[cid] = 8.0 if f_clamped == Faction.ROBOT else 18.0
	_city_wood[cid] = 14.0
	_city_ore[cid] = 22.0 if f_clamped == Faction.ROBOT else 18.0
	_city_energy[cid] = 12.0 if f_clamped == Faction.ROBOT else 8.0
	_city_energy_spend_acc[cid] = 0.0
	_city_energy_net[cid] = 0.0
	_city_science[cid] = 6.0
	_city_storage_cap[cid] = _k_base_storage_cap
	_city_expand_timer[cid] = _k_first_expand_delay * (0.75 if f_clamped == Faction.SPORE else 1.0) + float(cid % 5) * 0.6
	_city_pop_timer[cid] = _k_pop_growth_int
	_city_shuttle_cd[cid] = 6.0
	_city_shuttles_launched[cid] = 0
	_city_proj_type[cid] = -1
	_city_proj_prog[cid] = 0.0
	_city_proj_work[cid] = 0.0
	_city_proj_retry[cid] = 0.0
	_city_tech_dirty[cid] = 1
	_city_tech_cd[cid] = 0.0
	_city_age_sec[cid] = 0.0
	_city_loyalty[cid] = 100.0
	_city_is_rebel[cid] = 0
	_city_war_state[cid] = Diplomacy.NEUTRAL
	_city_emp_timer[cid] = 0.0
	_city_war_cooldown[cid] = 0.0
	_city_overlord[cid] = overlord_cid
	_city_tech_floor[cid] = 0
	_city_dome_powered[cid] = 1
	_city_tier5_done[cid] = 0
	_city_spore_creep_cd[cid] = _k_spore_creep_int
	_city_drill_dep_mul[cid] = 1.0
	_city_credits[cid] = 10.0
	_city_hq_level[cid] = 0

	if kingdom_id >= 0 and kingdom_id < _max_cities and _kingdom_active[kingdom_id] != 0:
		_diplomacy.assign_city_to_kingdom(self, cid, kingdom_id)
	else:
		_diplomacy.create_kingdom(self, cid, false)
	if _meta != null:
		_meta.on_city_created(self, cid, overlord_cid)
	_city_color[cid] = _get_city_tint_color(cid)

	var base_b: int = cid * BLD_TYPE_COUNT
	for bt in range(BLD_TYPE_COUNT):
		_city_bld_counts[base_b + bt] = 0
	_init_city_diplo_row(cid, f_clamped)


func _init_city_diplo_row(cid: int, f_clamped: int) -> void:
	var row_cid: int = cid * _max_cities
	var my_kid: int = _city_kingdom_id[cid]
	for other in range(_max_cities):
		var st: int = Diplomacy.NEUTRAL
		if other != cid and _city_active[other] != 0:
			var same_k: bool = (my_kid >= 0 and _city_kingdom_id[other] == my_kid and _city_is_rebel[other] == 0)
			if same_k or (int(_city_faction[other]) == f_clamped and _city_is_rebel[other] == 0):
				st = Diplomacy.PACT
		_diplo_matrix[row_cid + other] = st
		_diplo_matrix[other * _max_cities + cid] = st
		_diplo_tension[row_cid + other] = 0.0
		_diplo_tension[other * _max_cities + cid] = 0.0
		_diplo_pair_cd[row_cid + other] = 0.0
		_diplo_pair_cd[other * _max_cities + cid] = 0.0
		if other != cid and _city_active[other] != 0:
			_recompute_city_war_state(other)
	_recompute_city_war_state(cid)
	_diplo_dirty_seq += 1


func _finalize_city_spawn(cid: int, safe_pos: Vector2, _f_clamped: int, place_tent: bool, immediate_gpu_sync: bool = true) -> void:
	_territory.claim_starter_quad(self, safe_pos, cid)
	_place_building(cid, BuildingType.CAMPFIRE, safe_pos, true)
	if place_tent:
		var tent_spot: Vector2 = _find_building_spot(cid, BuildingType.TENT)
		if tent_spot.x >= 0.0:
			_place_building(cid, BuildingType.TENT, tent_spot, true)

	_recompute_city_tech(cid)
	_refresh_city_targets(cid)
	_start_next_project(cid)
	if immediate_gpu_sync:
		_territory.flush_dirty_borders(self)
		_sync_buildings_multimesh()
		_buildings_dirty = false
		_bld_anim_step = int(floor(_sim_time * 8.0))
	else:
		_border_dirty = true
		_buildings_dirty = true
	_goals_dirty = true
	_bld_footprints_dirty = true
	_push_goal_buffers()


func spawn_colony(world_pos: Vector2, faction_id: int = 0) -> int:
	_ensure_initialized()
	var f_clamped: int = clampi(faction_id, 0, FACTION_BORDER_COLORS.size() - 1)
	var safe_pos: Vector2 = _territory.find_walkable_near(self, world_pos, Vector2i(22, f_clamped))
	if safe_pos.x < 0.0:
		return -1
	var cid: int = _allocate_city_slot(safe_pos, _k_min_city_spacing)
	if cid < 0:
		return -1

	_init_city_record(cid, safe_pos, f_clamped, -1, -1)
	_finalize_city_spawn(cid, safe_pos, f_clamped, true)
	if _physics != null and _physics_has_spawn_colony_units:
		_city_pop[cid] = int(_physics.spawn_colony_units(cid, safe_pos, _k_start_city_pop))
	_diplomacy.sync_notables(self, 0.0)
	var k_name: String = _kingdom_name[_city_kingdom_id[cid]] if _city_kingdom_id[cid] >= 0 else _city_name[cid]
	_diplomacy.push_chronicle("Основана колония %s (%s)" % [_city_name[cid], k_name], safe_pos, _get_city_border_color(cid))
	return cid


func try_self_found_settlement(world_pos: Vector2, faction_id: int, founder_uids: PackedInt32Array) -> int:
	_ensure_initialized()
	if not _law_self_founding:
		return -1
	if not can_settle_near(world_pos):
		return -1
	var f_clamped: int = clampi(faction_id, 0, FACTION_BORDER_COLORS.size() - 1)
	var safe_pos: Vector2 = _territory.find_walkable_near(self, world_pos, Vector2i(6, f_clamped))
	if safe_pos.x < 0.0 or not can_settle_near(safe_pos):
		return -1
	var cid: int = _allocate_city_slot(safe_pos, _k_self_found_spacing)
	if cid < 0:
		return -1

	_init_city_record(cid, safe_pos, f_clamped, -1, -1)
	_finalize_city_spawn(cid, safe_pos, f_clamped, false)

	var recruited: int = 0
	if _physics != null and _physics.has_method("recruit_settlers_to_city"):
		recruited = int(_physics.recruit_settlers_to_city(cid, founder_uids))
	_city_pop[cid] = maxi(recruited, founder_uids.size())
	_diplomacy.sync_notables(self, 0.0)

	var k_name: String = _kingdom_name[_city_kingdom_id[cid]] if _city_kingdom_id[cid] >= 0 else _city_name[cid]
	_diplomacy.push_chronicle("Лагерь %s (%s)" % [_city_name[cid], k_name], safe_pos, _get_city_border_color(cid))
	if _fx != null:
		if _fx_has_emit_build_pop:
			_fx.emit_build_pop(safe_pos)
		if _fx_has_spawn_burst:
			_fx.spawn_burst(safe_pos, 10, _get_city_border_color(cid), 20.0, 0.45, -10.0)
	return cid


func _found_daughter_settlement(src_cid: int, world_pos: Vector2, settlers_count: int) -> int:
	if src_cid < 0 or src_cid >= _max_cities or _city_active[src_cid] == 0:
		return -1
	var f_clamped: int = clampi(int(_city_faction[src_cid]), 0, FACTION_BORDER_COLORS.size() - 1)
	var kid: int = _city_kingdom_id[src_cid]
	var safe_pos: Vector2 = _territory.find_walkable_near(self, world_pos, Vector2i(10, f_clamped))
	if safe_pos.x < 0.0 or not can_settle_near(safe_pos):
		return -1
	var cid: int = _allocate_city_slot(safe_pos, _k_self_found_spacing)
	if cid < 0:
		return -1

	_init_city_record(cid, safe_pos, f_clamped, kid, src_cid)
	_finalize_city_spawn(cid, safe_pos, f_clamped, false, false)
	if _physics != null and _physics_has_spawn_colony_units:
		_city_pop[cid] = int(_physics.spawn_colony_units(cid, safe_pos, clampi(settlers_count, 4, 5)))
	_diplomacy.sync_notables(self, 0.0)
	var k_name: String = _kingdom_name[kid] if kid >= 0 else _city_name[src_cid]
	_diplomacy.push_chronicle("Дочерняя деревня %s (%s)" % [_city_name[cid], k_name], safe_pos, _get_city_border_color(cid))
	return cid


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
	_bld_level[bidx] = 0

	_city_bld_counts[city_id * BLD_TYPE_COUNT + bld_type] += 1
	_city_tech_dirty[city_id] = 1
	_buildings_dirty = true
	_has_bld_springs = true
	_spring_cache_dirty = true
	if bld_type == BuildingType.SHIELD_PYLON:
		_shield_cache_dirty = true
	elif bld_type == BuildingType.DRILL:
		_drill_cache_dirty = true
	_bld_footprints_dirty = true
	_goals_dirty = true
	if bld_type == BuildingType.BIODOME:
		_bld_upg_idx = bidx
	if bld_type == BuildingType.DEPOT:
		_city_storage_cap[city_id] += _k_depot_storage_bonus
	elif bld_type == BuildingType.LAUNCHPAD:
		_city_storage_cap[city_id] += _k_launchpad_storage_bonus

	var zx: int = clampi(int(floor(pos.x / float(_zone_px))), 0, _zone_w - 1)
	var zy: int = clampi(int(floor(pos.y / float(_zone_px))), 0, _zone_h - 1)
	var zidx: int = zy * _zone_w + zx
	if _zone_city_id[zidx] == -1 and (_city_zones_count[city_id] == 0 or _territory.has_cardinal_owner(self, Vector2i(zx, zy), city_id)):
		_claim_zone(zx, zy, city_id, int(_city_faction[city_id]))
	if (_zone_flags[zidx] & ZONE_FLAG_FARM) != 0:
		_city_farm_scan_cd[city_id] = 0.0
	_zone_flags[zidx] = (_zone_flags[zidx] | ZONE_FLAG_BUILT) & ~ZONE_FLAG_FARM

	if pos.distance_squared_to(_city_center[city_id]) > 9.0:
		var kind: int = ROAD_CONDUIT if (f_id != Faction.SPORE and int(_city_tech_tier[city_id]) >= 2) else ROAD_DIRT
		_territory.stamp_road(self, Rect2(_city_center[city_id], pos), kind)

	if _physics != null and _physics_has_clear_footprint:
		_physics.clear_footprint(pos, avoid_r)
	if not quiet_audio and _fx != null:
		if _fx_has_emit_build_pop:
			_fx.emit_build_pop(pos)
		elif _fx_has_play_sfx:
			_fx.play_sfx("build_pop")
	return bidx


func _remove_building(bidx: int) -> void:
	if bidx < 0 or bidx >= _bld_count:
		return
	_shield_cache_dirty = true
	_drill_cache_dirty = true
	_spring_cache_dirty = true
	var cid: int = _bld_city_id[bidx]
	var btype: int = int(_bld_type[bidx])
	if cid >= 0 and cid < _max_cities:
		var slot: int = cid * BLD_TYPE_COUNT + btype
		_city_bld_counts[slot] = maxi(0, _city_bld_counts[slot] - 1)
		_city_tech_dirty[cid] = 1
		if btype == BuildingType.DEPOT:
			_city_storage_cap[cid] = maxf(_k_base_storage_cap, _city_storage_cap[cid] - _k_depot_storage_bonus)
		elif btype == BuildingType.LAUNCHPAD:
			_city_storage_cap[cid] = maxf(_k_base_storage_cap, _city_storage_cap[cid] - _k_launchpad_storage_bonus)

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
		_bld_level[bidx] = _bld_level[last]
	_bld_count = last
	_buildings_dirty = true
	_bld_footprints_dirty = true
	_bld_removed_dirty = true
	_goals_dirty = true


func _has_clear_walk_line(a: Vector2, b: Vector2, f_id: int) -> bool:
	if _world == null:
		return true
	if _territory._w_cache_owner != _world:
		_territory._refresh_world_byte_caches(self)
	var mw: int = _map_w
	var mh: int = _map_h
	var w_tiers: PackedByteArray = _territory._w_tiers_cache
	var w_biomes: PackedByteArray = _territory._w_biomes_cache
	var w_temp: PackedFloat32Array = _territory._w_temp_cache
	if w_tiers.size() == mw * mh and w_biomes.size() == mw * mh and w_temp.size() == mw * mh:
		var c_off: float = _territory.get_cosmic_temp_offset(self)
		var max_t: float = 95.0 if f_id == Faction.ROBOT else 65.0
		for s in range(1, 9):
			var pt: Vector2 = a.lerp(b, float(s) / 9.0)
			var px: int = int(floor(pt.x))
			var py: int = int(floor(pt.y))
			if px < 4 or px >= mw - 4 or py < 4 or py >= mh - 4:
				return false
			var idx: int = py * mw + px
			var t: int = int(w_tiers[idx])
			if t <= TIER_SHALLOW or t >= TIER_SUMMIT or int(w_biomes[idx]) == BIOME_LAVA or (w_temp[idx] + c_off) > max_t:
				return false
		return true
	for s in range(1, 9):
		var pt2: Vector2 = a.lerp(b, float(s) / 9.0)
		if not _territory.is_pixel_walkable(self, Vector2i(int(floor(pt2.x)), int(floor(pt2.y))), f_id):
			return false
	return true


func _is_building_spot_valid(pos: Vector2, bld_type: int, faction_id: int = 0) -> bool:
	var px: int = int(floor(pos.x))
	var py: int = int(floor(pos.y))
	if px < 10 or px >= _map_w - 10 or py < 14 or py >= _map_h - 8:
		return false
	if _world != null:
		if _territory._w_cache_owner != _world:
			_territory._refresh_world_byte_caches(self)
		var mw: int = _map_w
		var mh: int = _map_h
		var w_tiers: PackedByteArray = _territory._w_tiers_cache
		var w_biomes: PackedByteArray = _territory._w_biomes_cache
		var w_temp: PackedFloat32Array = _territory._w_temp_cache
		var use_cache: bool = (w_tiers.size() == mw * mh and w_biomes.size() == mw * mh and w_temp.size() == mw * mh)
		var t_center: int = int(w_tiers[py * mw + px]) if use_cache else int(_world.get_tier(px, py))
		if bld_type != BuildingType.DRILL and t_center >= 7:
			return false
		if use_cache:
			var c_off: float = _territory.get_cosmic_temp_offset(self)
			var max_t: float = 95.0 if faction_id == Faction.ROBOT else 65.0
			for sy in range(3):
				var ty: int = py + (-3 if sy == 0 else (0 if sy == 1 else 2))
				if ty < 4 or ty >= mh - 4:
					return false
				var row_off: int = ty * mw
				for sx in range(3):
					var tx: int = px + (sx - 1) * 4
					if tx < 4 or tx >= mw - 4:
						return false
					var idx: int = row_off + tx
					var t: int = int(w_tiers[idx])
					if t <= TIER_SHALLOW or t >= TIER_SUMMIT or int(w_biomes[idx]) == BIOME_LAVA or (w_temp[idx] + c_off) > max_t:
						return false
		else:
			for sy in range(3):
				var oy: int = -3 if sy == 0 else (0 if sy == 1 else 2)
				for sx in range(3):
					if not _territory.is_pixel_walkable(self, Vector2i(px + (sx - 1) * 4, py + oy), faction_id):
						return false
	var min_sep: float = BLD_FOOTPRINTS[bld_type]
	if bld_type == BuildingType.DOCK and not _has_water_near(px, py, 24):
		return false
	var px_f: float = pos.x
	var py_f: float = pos.y
	var b_pos: PackedVector2Array = _bld_pos
	var b_type: PackedByteArray = _bld_type
	for i in range(_bld_count):
		var req: float = (min_sep + BLD_FOOTPRINTS[int(b_type[i])]) * 0.5
		var bp: Vector2 = b_pos[i]
		var dx: float = bp.x - px_f
		if absf(dx) >= req:
			continue
		var dy: float = bp.y - py_f
		if absf(dy) >= req:
			continue
		if dx * dx + dy * dy < req * req:
			return false
	return true


func _find_building_spot(city_id: int, bld_type: int) -> Vector2:
	var center: Vector2 = _city_center[city_id]
	var f_id: int = int(_city_faction[city_id])
	var best_pos := Vector2(-1.0, -1.0)
	var best_score: float = -1e9
	var fb_pos := Vector2(-1.0, -1.0)
	var fb_score: float = -1e9
	var czx: int = clampi(int(floor(center.x / float(_zone_px))), 0, _zone_w - 1)
	var czy: int = clampi(int(floor(center.y / float(_zone_px))), 0, _zone_h - 1)
	var scan_r: int = 7 if _city_zones_count[city_id] >= 12 else 5

	for zy in range(maxi(0, czy - scan_r), mini(_zone_h, czy + scan_r + 1)):
		for zx in range(maxi(0, czx - scan_r), mini(_zone_w, czx + scan_r + 1)):
			var zidx: int = zy * _zone_w + zx
			var owner: int = _zone_city_id[zidx]
			if owner != city_id:
				if owner != -1 or not _is_zone_claimable(zx, zy, f_id) or not _territory.has_cardinal_owner(self, Vector2i(zx, zy), city_id):
					continue
			var cand: Vector2 = _territory.zone_walkable_center(self, Vector2i(zx, zy), f_id)
			if cand.x < 0.0:
				continue
			if not _is_building_spot_valid(cand, bld_type, f_id):
				cand += Vector2(_rng.randf_range(-2.0, 2.0), _rng.randf_range(-2.0, 2.0))
				if not _is_building_spot_valid(cand, bld_type, f_id):
					continue
			var sc: float = _score_building_spot(cand, center, zidx, zx, zy, owner == city_id, bld_type)
			if sc <= best_score and sc <= fb_score:
				continue
			if sc > best_score and _has_clear_walk_line(center, cand, f_id):
				best_score = sc
				best_pos = cand
			elif sc > fb_score:
				fb_score = sc
				fb_pos = cand
	if best_pos.x >= 0.0:
		return best_pos
	var ring_clear: Vector2 = _find_ring_building_spot(center, bld_type, f_id, true)
	if ring_clear.x >= 0.0:
		return ring_clear
	if fb_pos.x >= 0.0:
		return fb_pos
	var ring_pos: Vector2 = _find_ring_building_spot(center, bld_type, f_id, false)
	if ring_pos.x >= 0.0 or bld_type != BuildingType.SHIELD_PYLON:
		return ring_pos
	return _find_fallback_test_spot(center, bld_type, f_id)


func _has_water_near(px: int, py: int, max_r: int) -> bool:
	if _world == null:
		return false
	var mw: int = _map_w
	var mh: int = _map_h
	var w_tiers: PackedByteArray = _territory._w_tiers_cache
	var has_cache: bool = w_tiers.size() == mw * mh
	for dist in [10, 16, max_r]:
		for k in range(8):
			var ang: float = float(k) * (TAU / 8.0)
			var wx: int = px + int(round(cos(ang) * float(dist)))
			var wy: int = py + int(round(sin(ang) * float(dist)))
			if wx < 2 or wx >= mw - 2 or wy < 2 or wy >= mh - 2:
				continue
			var t: int = int(w_tiers[wy * mw + wx]) if has_cache else int(_world.get_tier(wx, wy))
			if t <= TIER_SHALLOW:
				return true
	return false


func _score_building_spot(cand: Vector2, center: Vector2, zidx: int, zx: int, zy: int, owned: bool, bld_type: int) -> float:
	var d: float = cand.distance_to(center)
	var score: float = 100.0 - d * 1.15 + (48.0 if owned else 0.0)
	var coastal: bool = _territory.is_zone_coastal(self, zx, zy)
	if bld_type == BuildingType.DRILL:
		score += float(_zone_ore[zidx]) * 3.2
	elif bld_type == BuildingType.BIODOME:
		score += _zone_fertility[zidx] * 20.0
	elif bld_type == BuildingType.LAUNCHPAD and coastal:
		score += 36.0
	elif bld_type == BuildingType.DOCK:
		score += 56.0 if coastal else -40.0
	elif bld_type == BuildingType.BARRACKS and d >= 14.0 and d <= 38.0:
		score += 24.0
	elif bld_type == BuildingType.DEFENSE_TURRET and d >= 22.0:
		score += 30.0
	elif bld_type == BuildingType.TRADE_HUB:
		score += (30.0 if coastal else 16.0) + (12.0 if d <= 26.0 else 0.0)
	elif bld_type == BuildingType.ARCHIVE and d <= 26.0:
		score += 26.0
	elif bld_type == BuildingType.MONOLITH:
		score += 32.0 if d <= 30.0 else 10.0
	elif bld_type == BuildingType.SHIELD_PYLON and d <= 28.0:
		score += 32.0
	elif bld_type == BuildingType.QUANTUM_GATE and d >= 18.0 and d <= 48.0:
		score += 28.0 + (18.0 if coastal else 0.0)
	var ocid: int = _zone_city_id[zidx]
	if _meta != null and ocid >= 0:
		var plan: int = _meta.get_city_town_plan(ocid)
		var delta: Vector2 = cand - center
		if plan == 1 and absf(d - 28.0) < 9.0:
			score += 12.0
		elif plan == 3 and (absf(delta.x) < 10.0 or absf(delta.y) < 10.0):
			score += 12.0
		elif plan == 5 and d < 24.0:
			score += 10.0
	return score


func _find_ring_building_spot(center: Vector2, bld_type: int, f_id: int, require_clear: bool = false) -> Vector2:
	var fallback := Vector2(-1.0, -1.0)
	for ring in range(1, 9):
		var rad: float = 10.0 + float(ring) * 6.5
		for k in range(12):
			var ang: float = float(k) * (TAU / 12.0) + float(ring) * 0.35
			var cand: Vector2 = center + Vector2(cos(ang), sin(ang)) * rad
			if not _is_building_spot_valid(cand, bld_type, f_id):
				continue
			if _has_clear_walk_line(center, cand, f_id):
				return cand
			if not require_clear and fallback.x < 0.0:
				fallback = cand
	return fallback


func _get_tier_science_cap(tier: int) -> float:
	return TIER_SCIENCE_CAPS[clampi(tier, 0, TIER_SCIENCE_CAPS.size() - 1)]


func _clamp_city_science(cid: int) -> void:
	if cid < 0 or cid >= _max_cities:
		return
	var cap_s: float = _get_tier_science_cap(int(_city_tech_tier[cid]))
	if _city_science[cid] > cap_s:
		_city_science[cid] = cap_s


func _add_city_science(cid: int, delta: float) -> void:
	if cid < 0 or cid >= _max_cities or delta <= 0.0:
		return
	var cap_s: float = _get_tier_science_cap(int(_city_tech_tier[cid]))
	_city_science[cid] = minf(cap_s, _city_science[cid] + delta)


func _recompute_city_tech(city_id: int) -> void:
	var dim_count: int = _k_dim_count
	var mid_w: float = _k_dup_mid_w
	var base_b: int = city_id * BLD_TYPE_COUNT
	var score: float = 0.0
	for bt in range(BLD_TYPE_COUNT):
		var n: int = _city_bld_counts[base_b + bt]
		if n <= 0:
			continue
		var full_n: int = mini(n, dim_count)
		var mid_n: int = clampi(n - dim_count, 0, dim_count)
		score += (float(full_n) + float(mid_n) * mid_w) * BLD_TECH_POINTS[bt]

	_city_tech_score[city_id] = score
	var tier: int = _eval_city_tier_unlocked(city_id, base_b, score)
	var prev_tier: int = int(_city_tech_tier[city_id])
	if _city_zones_count[city_id] > 0 and _city_bld_counts[base_b + BuildingType.CAMPFIRE] > 0:
		tier = maxi(tier, prev_tier)
	_city_tech_dirty[city_id] = 0
	if tier != prev_tier:
		_city_tech_tier[city_id] = tier
		_light_goals_dirty = true
		if tier > prev_tier:
			_city_proj_retry[city_id] = 0.0
		if tier >= 2 and prev_tier < 2:
			_territory.upgrade_city_roads_to_conduits(self, city_id)
			_road_mask_dirty = true
		if tier >= 5 and _city_tier5_done[city_id] == 0:
			_on_city_tier5_victory(city_id)
		else:
			_diplomacy.push_chronicle("%s достиг эпохи Т%d" % [_city_name[city_id], tier], _city_center[city_id], _get_city_border_color(city_id))
	_clamp_city_science(city_id)
	if tier >= 3 and prev_tier < 3 and _city_bld_counts[base_b + BuildingType.SHIELD_PYLON] == 0:
		var pt: int = _city_proj_type[city_id]
		var keep_first_dome: bool = (
			pt == BuildingType.BIODOME
			and int(_city_faction[city_id]) != Faction.ROBOT
			and _city_bld_counts[base_b + BuildingType.BIODOME] == 0
		)
		if pt >= 0 and pt != BuildingType.SHIELD_PYLON and not keep_first_dome:
			var saved_w: float = _city_proj_work[city_id]
			_city_proj_type[city_id] = -1
			_city_proj_prog[city_id] = 0.0
			_start_next_project(city_id)
			if _city_proj_type[city_id] >= 0:
				_city_proj_work[city_id] = saved_w
	if tier > prev_tier and _city_proj_type[city_id] < 0:
		_start_next_project(city_id)


func _on_city_tier5_victory(cid: int) -> void:
	_city_tier5_done[cid] = 1
	_tier5_victories += 1
	_buildings_dirty = true
	var fid: int = int(_city_faction[cid])
	var msg: String = "Триумф Т5: %s возводит Шпиль Ковчега!" % _city_name[cid]
	if fid == Faction.ROBOT:
		msg = "Триумф Т5: %s разворачивает Солнечный Коллектор!" % _city_name[cid]
	elif fid == Faction.SPORE:
		msg = "Триумф Т5: %s пробуждает Великое Цветение!" % _city_name[cid]
	_diplomacy.push_chronicle(msg, _city_center[cid], Color("#FFD84A"))


func _eval_city_tier_unlocked(cid: int, base_b: int, score: float) -> int:
	var sci: float = _city_science[cid]
	var age: float = _city_age_sec[cid]
	var pop: int = _city_pop[cid]
	var fid: int = int(_city_faction[cid])
	var tents: int = _city_bld_counts[base_b + BuildingType.TENT]
	var drills: int = _city_bld_counts[base_b + BuildingType.DRILL]
	var depots: int = _city_bld_counts[base_b + BuildingType.DEPOT]
	var solars: int = _city_bld_counts[base_b + BuildingType.SOLAR_ARRAY]
	var domes: int = _city_bld_counts[base_b + BuildingType.BIODOME]
	var reactors: int = _city_bld_counts[base_b + BuildingType.FUSION_REACTOR]
	var pads: int = _city_bld_counts[base_b + BuildingType.LAUNCHPAD]
	var gates: int = _city_bld_counts[base_b + BuildingType.QUANTUM_GATE]

	var tier: int = 0
	if age >= _k_tier1_age and sci >= 28.0 and pop >= 6 and (tents >= 2 or domes >= 1):
		tier = 1
	if tier >= 1 and age >= _k_tier2_age and sci >= 95.0 and drills >= 1 and depots >= 1 and score >= 6.5:
		tier = 2
	var t3_bio_ok: bool = (domes >= 1) if fid != Faction.ROBOT else (drills >= 2)
	if tier >= 2 and age >= _k_tier3_age and sci >= _k_tier3_sci and solars >= 1 and t3_bio_ok and score >= _k_tier3_score:
		tier = 3
	if tier >= 3 and age >= _k_tier4_age and sci >= _k_tier4_sci and reactors >= 1 and pads >= 1 and score >= _k_tier4_score:
		tier = 4
	var t5_asym_ok: bool = (domes >= 2 or gates >= 1) if fid == Faction.HUMAN else ((drills >= 2 or gates >= 1) if fid == Faction.ROBOT else (_city_zones_count[cid] >= 20 or gates >= 1))
	if tier >= 4 and age >= 1650.0 and sci >= 1100.0 and gates >= 1 and score >= 22.0 and t5_asym_ok:
		tier = 5
	return maxi(tier, clampi(int(_city_tech_floor[cid]), 0, 5))


func _pick_next_building_type(city_id: int) -> int:
	var base_b: int = city_id * BLD_TYPE_COUNT
	var f_id: int = int(_city_faction[city_id])
	var tier: int = int(_city_tech_tier[city_id])
	var campfires: int = _city_bld_counts[base_b + BuildingType.CAMPFIRE]
	var tents: int = _city_bld_counts[base_b + BuildingType.TENT]
	var drills: int = _city_bld_counts[base_b + BuildingType.DRILL]
	var depots: int = _city_bld_counts[base_b + BuildingType.DEPOT]
	var docks: int = _city_bld_counts[base_b + BuildingType.DOCK]

	var city_total: int = 0
	for bt in range(BLD_TYPE_COUNT):
		city_total += _city_bld_counts[base_b + bt]
	var max_blds: int = clampi(12 + _city_zones_count[city_id] / 2 + tier * 4, 12, _k_max_city_blds + (12 if tier >= 5 else 0))
	if campfires < 1:
		return BuildingType.CAMPFIRE
	if city_total >= max_blds:
		return -1
	if tier == 0:
		return BuildingType.TENT if tents < 4 else -1
	if tier == 1:
		return _pick_tier1_building(city_id, tents, drills, depots, docks)
	if tier == 2:
		return _pick_tier2_building(city_id, f_id)
	return _pick_tier34_building(city_id, f_id, tier, city_total)


func _pick_tier1_building(city_id: int, tents: int, drills: int, depots: int, docks: int) -> int:
	if tents < 2:
		return BuildingType.TENT
	if drills < 1:
		return BuildingType.DRILL
	if depots < 1:
		return BuildingType.DEPOT
	if tents < 3:
		return BuildingType.TENT
	if drills < 2:
		return BuildingType.DRILL
	if docks < 1 and _is_city_coastal(city_id):
		return BuildingType.DOCK
	return -1


func _pick_tier2_building(city_id: int, f_id: int) -> int:
	# Note: LAUNCHPAD is strictly banned on Tier 2!
	var base_b: int = city_id * BLD_TYPE_COUNT
	var tents: int = _city_bld_counts[base_b + BuildingType.TENT]
	var drills: int = _city_bld_counts[base_b + BuildingType.DRILL]
	var depots: int = _city_bld_counts[base_b + BuildingType.DEPOT]
	var solars: int = _city_bld_counts[base_b + BuildingType.SOLAR_ARRAY]
	var domes: int = _city_bld_counts[base_b + BuildingType.BIODOME]
	if solars < 1:
		return BuildingType.SOLAR_ARRAY
	if f_id == Faction.ROBOT and drills < 2:
		return BuildingType.DRILL
	if f_id != Faction.ROBOT and domes == 0:
		return -2 if tents > 0 else BuildingType.BIODOME
	var t3_ready: bool = solars >= 1 and ((domes >= 1) if f_id != Faction.ROBOT else (drills >= 2))
	if t3_ready and _city_age_sec[city_id] >= _k_tier3_age - 80.0:
		return -1
	if f_id != Faction.ROBOT and domes < 2:
		return -2 if tents > 0 else BuildingType.BIODOME
	if solars < 2:
		return BuildingType.SOLAR_ARRAY
	if drills < 3:
		return BuildingType.DRILL
	if depots < 2:
		return BuildingType.DEPOT
	if _city_bld_counts[base_b + BuildingType.DOCK] < 1 and _is_city_coastal(city_id):
		return BuildingType.DOCK
	if _city_bld_counts[base_b + BuildingType.BARRACKS] < 1:
		return BuildingType.BARRACKS
	if _city_bld_counts[base_b + BuildingType.TRADE_HUB] < 1:
		return BuildingType.TRADE_HUB
	if _city_bld_counts[base_b + BuildingType.ARCHIVE] < 1:
		return BuildingType.ARCHIVE
	if _city_bld_counts[base_b + BuildingType.DEFENSE_TURRET] < 1:
		return BuildingType.DEFENSE_TURRET
	if f_id == Faction.ROBOT and tents < 4:
		return BuildingType.TENT
	return -1


func _pick_tier34_building(cid: int, f_id: int, tier: int, city_total: int) -> int:
	var base_b: int = cid * BLD_TYPE_COUNT
	var tents: int = _city_bld_counts[base_b + BuildingType.TENT]
	var drills: int = _city_bld_counts[base_b + BuildingType.DRILL]
	var depots: int = _city_bld_counts[base_b + BuildingType.DEPOT]
	var solars: int = _city_bld_counts[base_b + BuildingType.SOLAR_ARRAY]
	var domes: int = _city_bld_counts[base_b + BuildingType.BIODOME]
	var reactors: int = _city_bld_counts[base_b + BuildingType.FUSION_REACTOR]
	var pads: int = _city_bld_counts[base_b + BuildingType.LAUNCHPAD]
	var pylons: int = _city_bld_counts[base_b + BuildingType.SHIELD_PYLON]
	var gates: int = _city_bld_counts[base_b + BuildingType.QUANTUM_GATE]
	var pylon_cap: int = 2 if (_city_zones_count[cid] >= 16 or tier >= 3) else 1

	if pylons < 1:
		return BuildingType.SHIELD_PYLON
	if pads < 1:
		return BuildingType.LAUNCHPAD
	if reactors < 1:
		return BuildingType.FUSION_REACTOR
	if tier >= 4 and gates < 1 and _city_energy[cid] >= _k_gate_e_min:
		return BuildingType.QUANTUM_GATE
	if f_id != Faction.ROBOT and tents > 0 and domes < 4:
		return -2
	if pylons < pylon_cap:
		return BuildingType.SHIELD_PYLON
	if solars < 3:
		return BuildingType.SOLAR_ARRAY
	if drills < 4:
		return BuildingType.DRILL
	if depots < 3:
		return BuildingType.DEPOT
	var meta_b: int = _pick_tier34_meta_building(cid, tier, base_b)
	if meta_b >= 0:
		return meta_b
	if reactors < 2:
		return BuildingType.FUSION_REACTOR
	if pads < 2 and _is_city_coastal(cid):
		return BuildingType.LAUNCHPAD
	if tier >= 4 and gates < _k_gate_max and _city_zones_count[cid] >= 12 and _city_energy[cid] >= _k_gate_e_min * 1.35:
		return BuildingType.QUANTUM_GATE
	var cycle: int = city_total % 4
	if cycle == 0 and drills < 6:
		return BuildingType.DRILL
	if cycle == 1 and solars < 5:
		return BuildingType.SOLAR_ARRAY
	if cycle == 2 and f_id != Faction.ROBOT and domes < 5:
		return BuildingType.BIODOME
	return BuildingType.DEPOT if depots < 4 else -1


func _pick_tier34_meta_building(cid: int, tier: int, base_b: int) -> int:
	if _city_bld_counts[base_b + BuildingType.DOCK] < 1 and _is_city_coastal(cid):
		return BuildingType.DOCK
	if _city_bld_counts[base_b + BuildingType.BARRACKS] < 1:
		return BuildingType.BARRACKS
	if _city_bld_counts[base_b + BuildingType.DEFENSE_TURRET] < 2:
		return BuildingType.DEFENSE_TURRET
	if _city_bld_counts[base_b + BuildingType.TRADE_HUB] < 1:
		return BuildingType.TRADE_HUB
	if _city_bld_counts[base_b + BuildingType.ARCHIVE] < 1:
		return BuildingType.ARCHIVE
	if tier >= 4 and _city_bld_counts[base_b + BuildingType.MONOLITH] < 1 and _city_zones_count[cid] >= 12:
		return BuildingType.MONOLITH
	return -1


func _try_start_tent_upgrade(city_id: int) -> bool:
	var best_bi: int = -1
	for bi in range(_bld_count):
		if _bld_city_id[bi] == city_id and int(_bld_type[bi]) == BuildingType.TENT:
			best_bi = bi
			break
	if best_bi < 0:
		return false
	var up_pos: Vector2 = _bld_pos[best_bi]
	_remove_building(best_bi)
	_city_proj_type[city_id] = BuildingType.BIODOME
	_city_proj_prog[city_id] = 0.0
	_city_proj_work[city_id] = 0.0
	_city_build_pos[city_id] = up_pos
	_buildings_dirty = true
	_light_goals_dirty = true
	return true


func _start_next_project(city_id: int) -> void:
	var prev_type: int = _city_proj_type[city_id]
	var prev_pos: Vector2 = _city_build_pos[city_id]
	var fallback_pos: Vector2 = _city_center[city_id]
	if _bld_count >= _max_buildings:
		_clear_project_to_fallback(city_id, prev_pos, fallback_pos)
		return
	var next_t: int = _pick_next_building_type(city_id)
	if next_t == -2:
		if _try_start_tent_upgrade(city_id):
			return
		next_t = BuildingType.BIODOME
	if next_t < 0:
		_clear_project_to_fallback(city_id, prev_pos, fallback_pos)
		return
	var spot: Vector2 = _find_building_spot(city_id, next_t)
	if spot.x < 0.0 and next_t == BuildingType.DOCK:
		next_t = BuildingType.BARRACKS
		spot = _find_building_spot(city_id, next_t)
	if spot.x < 0.0:
		_clear_project_to_fallback(city_id, prev_pos, fallback_pos)
		return
	_city_proj_type[city_id] = next_t
	_city_proj_prog[city_id] = 0.0
	_city_proj_work[city_id] = 0.0
	_buildings_dirty = true
	if prev_type != next_t or prev_pos.distance_squared_to(spot) > 0.25:
		_city_build_pos[city_id] = spot
		_light_goals_dirty = true


func _clear_project_to_fallback(city_id: int, prev_pos: Vector2, fallback_pos: Vector2) -> void:
	_city_proj_type[city_id] = -1
	if prev_pos.distance_squared_to(fallback_pos) > 0.25:
		_city_build_pos[city_id] = fallback_pos
		_light_goals_dirty = true


func _building_max_hp(bld_type: int, faction_id: int, level: int = 0) -> float:
	var base_hp: float = 100.0
	if bld_type == BuildingType.MONOLITH:
		base_hp = 210.0
	elif bld_type == BuildingType.QUANTUM_GATE:
		base_hp = 180.0
	elif bld_type == BuildingType.DEFENSE_TURRET:
		base_hp = 155.0
	elif bld_type == BuildingType.SHIELD_PYLON:
		base_hp = 140.0
	elif bld_type == BuildingType.ARCHIVE or bld_type == BuildingType.TRADE_HUB or bld_type == BuildingType.BARRACKS or bld_type == BuildingType.DOCK:
		base_hp = 130.0
	elif bld_type >= BuildingType.BIODOME:
		base_hp = 120.0
	if level > 0:
		base_hp *= (1.0 + 0.35 * float(level))
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
	var extra: int = _city_bld_counts[base_b + BuildingType.BARRACKS] * 2 + _city_bld_counts[base_b + BuildingType.DOCK] * 2
	var cap: int = 8 + tents * 4 + domes * 8 + extra
	if int(_city_faction[city_id]) == Faction.ROBOT:
		cap += depots * 4
	return cap


func step_civ(dt: float) -> void:
	_ensure_initialized()
	var safe_dt: float = clampf(dt, 0.0, 0.25)
	if safe_dt <= 0.0:
		return
	if _world != null and _territory._w_cache_owner != _world:
		_territory._refresh_world_byte_caches(self)
	var pace_dt: float = safe_dt * _sim_pace_mult
	_sim_time += safe_dt
	_sim_tick_idx += 1
	_border_flush_cd = maxf(0.0, _border_flush_cd - safe_dt)
	_drill_pace_acc += pace_dt
	if _drill_cache_dirty or (_sim_tick_idx & 3) == 0:
		_step_drill_depletion_pass(_drill_pace_acc)
		_drill_pace_acc = 0.0

	for cid in range(_max_cities):
		if _city_active[cid] != 0:
			_step_single_city(cid, pace_dt)

	_step_world_timers(safe_dt, pace_dt)
	_step_shuttles(pace_dt)
	_diplomacy.step_expeditions(self, pace_dt)
	if _meta != null:
		_meta.step_meta_and_fleet(self, safe_dt, pace_dt)
	_step_shield_pylons(pace_dt)
	var springs_moved: bool = _step_building_springs(safe_dt) if _has_bld_springs else false
	if _border_dirty:
		_territory.flush_dirty_borders(self, false)

	var anim_hz: float = 2.0 if _sim_pace_mult >= 10.0 else 8.0
	var anim_step: int = int(floor(_sim_time * anim_hz))
	var ships_n: int = _meta.get_ship_count() if _meta != null else 0
	var has_dyn: bool = (_bld_count > 0 or _ruin_count > 0 or _shuttle_count > 0 or ships_n > 0)
	if _buildings_dirty or (has_dyn and anim_step != _bld_anim_step):
		_sync_buildings_multimesh(_buildings_dirty)
		_buildings_dirty = false
		_bld_anim_step = anim_step
	elif springs_moved:
		_sync_spring_buildings_only()
		if ships_n > 0 and _sim_pace_mult < 10.0 and _shuttle_count == 0:
			_sync_ships_tail_mm()
	elif ships_n > 0 and _sim_pace_mult < 10.0 and _shuttle_count == 0:
		_sync_ships_tail_mm()
	if _goals_dirty or _light_goals_dirty or _goal_buffers.is_empty():
		_push_goal_buffers()


func _step_world_timers(safe_dt: float, pace_dt: float) -> void:
	var raw_hi: bool = _sim_pace_mult >= 10.0
	_env_check_timer -= safe_dt
	if _env_check_timer <= 0.0:
		var env_dt: float = 0.65 if raw_hi else 0.50
		_env_check_timer = env_dt
		_step_buildings_environment(env_dt)

	_clash_raw_cd = maxf(0.0, _clash_raw_cd - safe_dt)
	_clash_pace_acc += pace_dt
	_clash_scan_timer -= pace_dt
	if _clash_scan_timer <= 0.0 and _clash_raw_cd <= 0.0:
		_clash_scan_timer = 0.45
		_clash_raw_cd = 0.65 if raw_hi else 0.12
		_diplomacy.update_border_clashes(self, maxf(0.45, _clash_pace_acc))
		_clash_pace_acc = 0.0

	_diplo_raw_cd = maxf(0.0, _diplo_raw_cd - safe_dt)
	_diplo_pace_acc += pace_dt
	_diplo_scan_timer -= pace_dt
	if _diplo_scan_timer <= 0.0 and _diplo_raw_cd <= 0.0:
		var d_step: float = _k_diplo_scan_sec
		_diplo_scan_timer = d_step
		_diplo_raw_cd = 0.65 if raw_hi else 0.12
		_diplomacy.step_diplomacy_and_plots(self, maxf(d_step, _diplo_pace_acc))
		_diplo_pace_acc = 0.0

	_capture_raw_cd = maxf(0.0, _capture_raw_cd - safe_dt)
	_capture_pace_acc += pace_dt
	_capture_scan_timer -= pace_dt
	if _capture_scan_timer <= 0.0 and _capture_raw_cd <= 0.0:
		var c_step: float = _k_war_cap_scan_sec
		_capture_scan_timer = c_step
		_capture_raw_cd = 0.65 if raw_hi else 0.10
		_diplomacy.step_wartime_capture(self, maxf(c_step, _capture_pace_acc))
		_capture_pace_acc = 0.0

	_ruin_raw_cd = maxf(0.0, _ruin_raw_cd - safe_dt)
	_ruin_tick_timer -= pace_dt
	if _ruin_tick_timer <= 0.0 and _ruin_raw_cd <= 0.0:
		_ruin_tick_timer = 0.45
		_ruin_raw_cd = 0.60 if raw_hi else 0.15
		_step_ruins_salvage()

	_shuttle_launch_timer -= pace_dt
	if _shuttle_launch_timer <= 0.0:
		_shuttle_launch_timer = maxf(4.0, pace_dt * 3.0) if raw_hi else 4.0
		_diplomacy.try_colonize_and_shuttles(self)

	_supply_scan_timer -= pace_dt
	if _supply_scan_timer <= 0.0:
		_supply_scan_timer = maxf(_k_supply_scan_sec, pace_dt * 3.0) if raw_hi else _k_supply_scan_sec
		_try_supply_sister_cities()

	_ecology_raw_cd = maxf(0.0, _ecology_raw_cd - safe_dt)
	_ecology_timer -= pace_dt
	if _ecology_timer <= 0.0 and _ecology_raw_cd <= 0.0:
		_ecology_timer = _k_eco_batch_int
		_ecology_raw_cd = 0.50 if raw_hi else 0.25
		_dispatch_ecology_batch()

	if _sim_pace_mult < 15.0:
		_smoke_puff_timer -= safe_dt
		if _smoke_puff_timer <= 0.0:
			_smoke_puff_timer = _k_smoke_int
			_emit_building_smoke()


func _dispatch_ecology_batch() -> void:
	if _world == null or not _world_has_apply_ecology_batch:
		return
	_ecology_cursor = _territory.collect_ecology_events(self, _ecology_events_scratch, _ecology_cursor)
	if not _ecology_events_scratch.is_empty():
		var applied: int = int(_world.call("apply_civ_ecology_batch", _ecology_events_scratch))
		_ecology_events_sent_total += maxi(applied, _ecology_events_scratch.size())


func _emit_building_smoke() -> void:
	if _sim_pace_mult >= 15.0 or _fx == null or _bld_count <= 0:
		return
	if not _fx_has_spawn_burst and not _fx_has_campfire_ember:
		return
	var puffs: int = 0
	for i in range(_bld_count):
		var bt: int = int(_bld_type[i])
		if bt != BuildingType.CAMPFIRE and bt != BuildingType.DRILL:
			continue
		var pos: Vector2 = _bld_pos[i] + Vector2(_rng.randf_range(-1.5, 1.5), -5.0)
		if _fx_has_spawn_burst:
			_fx.spawn_burst(pos, 1, Color(0.68, 0.70, 0.74, 0.42), 2.8, 0.85, -10.5)
		if bt == BuildingType.CAMPFIRE and _fx_has_campfire_ember and _rng.randf() < 0.35:
			_fx.emit_campfire_ember(_bld_pos[i] + Vector2(0.0, -3.0), Vector2(0.0, -4.0))
		puffs += 1
		if puffs >= 6:
			break


func _step_single_city(cid: int, pace_dt: float) -> void:
	_city_age_sec[cid] += pace_dt
	if _city_emp_timer[cid] > 0.0:
		_city_emp_timer[cid] = maxf(0.0, _city_emp_timer[cid] - pace_dt)
		if _city_emp_timer[cid] <= 0.0:
			_light_goals_dirty = true
			_buildings_dirty = true
	if _city_war_cooldown[cid] > 0.0:
		_city_war_cooldown[cid] = maxf(0.0, _city_war_cooldown[cid] - pace_dt)
	if _city_shuttle_cd[cid] > 0.0:
		_city_shuttle_cd[cid] = maxf(0.0, _city_shuttle_cd[cid] - pace_dt)

	if _physics_has_get_city_pop and (_sim_pace_mult < 10.0 or ((_sim_tick_idx + cid) & 3) == 0):
		var live_pop: int = int(_physics.get_city_pop(cid))
		if live_pop != _city_pop[cid]:
			_city_pop[cid] = live_pop
			_city_tech_dirty[cid] = 1

	var e_gain: float = _step_city_economy(cid, pace_dt)
	_step_city_construction(cid, pace_dt)
	_step_city_tech_check(cid, pace_dt)
	_step_city_expansion(cid, pace_dt)
	_step_spore_creep(cid, pace_dt)
	if ((_sim_tick_idx + cid) & 1) == 0:
		_diplomacy.step_city_loyalty(self, cid, pace_dt * 2.0)
	_step_city_pop_growth(cid, pace_dt)

	var e_spent_step: float = _city_energy_spend_acc[cid]
	_city_energy_spend_acc[cid] = 0.0
	var inst_e_net: float = (e_gain - e_spent_step) / maxf(0.001, pace_dt)
	_city_energy_net[cid] = lerpf(_city_energy_net[cid], inst_e_net, minf(1.0, pace_dt * 0.5))


func _step_drill_depletion_pass(pace_dt: float) -> void:
	if _drill_cache_dirty:
		_drill_cache_dirty = false
		_drill_indices.clear()
		for bi in range(_bld_count):
			if int(_bld_type[bi]) == BuildingType.DRILL:
				_drill_indices.append(bi)
	if _drill_indices.is_empty():
		if _drill_active_cnt != 0:
			_city_drill_dep_mul.fill(1.0)
			_drill_active_cnt = 0
		return
	_drill_active_cnt = _drill_indices.size()
	_tmp_city_drill_cnt.fill(0)
	_tmp_city_drill_sum.fill(0.0)
	var dep_step: float = 0.035 * pace_dt
	for di in range(_drill_indices.size()):
		var bi: int = _drill_indices[di]
		var cid: int = _bld_city_id[bi]
		if cid < 0 or cid >= _max_cities:
			continue
		var zx: int = clampi(int(floor(_bld_pos[bi].x / float(_zone_px))), 0, _zone_w - 1)
		var zy: int = clampi(int(floor(_bld_pos[bi].y / float(_zone_px))), 0, _zone_h - 1)
		var zidx: int = zy * _zone_w + zx
		var ore_v: int = _zone_ore[zidx]
		if ore_v > 0:
			_zone_ore_frac[zidx] += dep_step
			if _zone_ore_frac[zidx] >= 1.0:
				var drop: int = mini(ore_v, int(floor(_zone_ore_frac[zidx])))
				_zone_ore[zidx] -= drop
				_zone_ore_frac[zidx] -= float(drop)
		_tmp_city_drill_cnt[cid] += 1
		var vein_mul: float = clampf(0.55 + float(_zone_ore[zidx]) * 0.13, 0.55, 1.0) if _zone_ore[zidx] > 0 else 0.55
		_tmp_city_drill_sum[cid] += vein_mul
	for cid in range(_max_cities):
		if _city_active[cid] != 0:
			_city_drill_dep_mul[cid] = (_tmp_city_drill_sum[cid] / float(_tmp_city_drill_cnt[cid])) if _tmp_city_drill_cnt[cid] > 0 else 1.0


func _step_city_economy(cid: int, pace_dt: float) -> float:
	var base_b: int = cid * BLD_TYPE_COUNT
	var f_id: int = int(_city_faction[cid])
	var cap: float = _city_storage_cap[cid]
	var pop: int = _city_pop[cid]
	var campfires: int = _city_bld_counts[base_b + BuildingType.CAMPFIRE]
	var drills: int = _city_bld_counts[base_b + BuildingType.DRILL]
	var solars: int = _city_bld_counts[base_b + BuildingType.SOLAR_ARRAY]
	var domes: int = _city_bld_counts[base_b + BuildingType.BIODOME]
	var reactors: int = _city_bld_counts[base_b + BuildingType.FUSION_REACTOR]
	var tents: int = _city_bld_counts[base_b + BuildingType.TENT]
	var hubs: int = _city_bld_counts[base_b + BuildingType.TRADE_HUB]
	var archives: int = _city_bld_counts[base_b + BuildingType.ARCHIVE]
	var monoliths: int = _city_bld_counts[base_b + BuildingType.MONOLITH]

	var ore_mult: float = 1.0
	var rad_e: float = 0.0
	if f_id == Faction.ROBOT:
		var cpx: int = clampi(int(floor(_city_center[cid].x)), 0, _map_w - 1)
		var cpy: int = clampi(int(floor(_city_center[cid].y)), 0, _map_h - 1)
		var cidx: int = cpy * _map_w + cpx
		var center_biome: int = int(_territory._w_biomes_cache[cidx]) if not _territory._w_biomes_cache.is_empty() else (int(_world.get_biome(cpx, cpy)) if _world != null else BIOME_RUST)
		var center_rad: float = _territory._w_rad_cache[cidx] if not _territory._w_rad_cache.is_empty() else (float(_world.get_rad(cpx, cpy)) if _world != null else 0.0)
		if center_biome == BIOME_CRYSTAL or center_biome == BIOME_SCORCHED:
			ore_mult = 1.28
		rad_e = maxf(0.0, center_rad) * _k_robot_rad_gain * (1.0 + float(solars) * 0.35)

	var depleted_mul: float = _city_drill_dep_mul[cid] if drills > 0 else 1.0
	var ore_gain: float = (float(drills) * 0.75 + (0.10 if drills == 0 else 0.0)) * depleted_mul * ore_mult * pace_dt
	var ore_pool: float = _city_ore[cid] + ore_gain
	var reactor_ore_need: float = float(reactors) * 0.22 * pace_dt
	var reactor_ore_used: float = minf(ore_pool, reactor_ore_need)
	var reactor_e: float = 0.0
	if reactors > 0:
		var r_frac: float = clampf(reactor_ore_used / maxf(reactor_ore_need, 0.0001), 0.0, 1.0)
		reactor_e = float(reactors) * lerpf(2.5, 12.0, r_frac) * pace_dt

	var wood_burn: float = minf(_city_wood[cid], float(campfires) * 0.10 * pace_dt) if (f_id != Faction.ROBOT and campfires > 0) else 0.0
	_city_wood[cid] = maxf(0.0, _city_wood[cid] - wood_burn)
	var cf_rate: float = 0.85 if f_id == Faction.ROBOT else (0.50 if wood_burn > 0.0 else 0.25)
	var solar_boost: float = _solar_mul * (1.18 if (f_id == Faction.ROBOT and int(_city_tech_tier[cid]) >= 5) else 1.0)
	var energy_gain: float = (float(campfires) * cf_rate + float(solars) * 2.5 * solar_boost + rad_e) * pace_dt + reactor_e
	var e_avail: float = _city_energy[cid] + energy_gain
	var dome_need: float = float(domes) * 0.65 * pace_dt
	var dome_e_spent: float = minf(e_avail, dome_need)
	_city_energy_spend_acc[cid] += dome_e_spent
	var dome_eff: float = (dome_e_spent / dome_need) if dome_need > 0.0001 else 1.0
	_city_dome_powered[cid] = 1 if (domes <= 0 or dome_eff >= 0.45) else 0

	var farm_food: float = 0.0
	if int(_city_tech_tier[cid]) >= 1 and f_id != Faction.ROBOT:
		if _city_farm_scan_cd[cid] > 0.0:
			_city_farm_scan_cd[cid] -= pace_dt
			farm_food = float(_city_farm_count[cid]) * 0.42 * _crop_mul * pace_dt
		else:
			farm_food = _territory.step_city_farms(self, cid, Vector2(pace_dt, _crop_mul))
	var forage_food: float = 0.25 * pace_dt if (f_id != Faction.ROBOT and campfires > 0) else 0.0
	var food_gain: float = (float(domes) * 1.45 * dome_eff * _crop_mul * pace_dt + farm_food + forage_food) if f_id != Faction.ROBOT else 0.0
	var food_upkeep: float = (float(pop - 6) * (0.04 if f_id == Faction.HUMAN else 0.028) * pace_dt) if (f_id != Faction.ROBOT and pop > 6) else 0.0
	var sci_gain: float = (0.10 + float(pop) * 0.022 + float(tents) * 0.04 + float(domes) * 0.22 + float(reactors) * 0.55 + float(archives) * 0.30 + float(monoliths) * 0.45) * pace_dt
	var credit_gain: float = (float(hubs) * 0.85 + float(pop) * 0.015 + float(int(_city_tech_tier[cid])) * 0.08) * pace_dt

	_city_ore[cid] = minf(cap, maxf(0.0, ore_pool - reactor_ore_used))
	_city_food[cid] = clampf(_city_food[cid] + food_gain - food_upkeep, 0.0, cap)
	_city_energy[cid] = minf(cap, maxf(0.0, e_avail - dome_e_spent))
	_city_credits[cid] = minf(cap * 2.0, _city_credits[cid] + credit_gain)
	_add_city_science(cid, sci_gain)
	return energy_gain


func _step_city_expansion(cid: int, pace_dt: float) -> void:
	_city_expand_timer[cid] -= pace_dt
	if _city_expand_timer[cid] > 0.0:
		return
	var tier: int = int(_city_tech_tier[cid])
	var zone_cap: int = 36 + maxi(0, tier - 2) * 12
	if _city_zones_count[cid] >= zone_cap:
		_city_expand_timer[cid] = maxf(20.0, pace_dt * 10.0)
		return
	var f_id: int = int(_city_faction[cid])
	var exp_cost: float = _k_zone_expand_ore * (_k_spore_exp_ore_mul if f_id == Faction.SPORE else 1.0)
	var exp_int: float = _k_zone_expand_int * (_k_spore_exp_int_mul if f_id == Faction.SPORE else 1.0)
	if _city_zones_count[cid] >= 12:
		exp_int *= 1.65
	var mat_pool: float = _city_ore[cid] + _city_wood[cid]
	if mat_pool >= exp_cost + 4.0 or (f_id != Faction.ROBOT and _city_food[cid] >= exp_cost * 2.0):
		if _territory.expand_city_territory(self, cid):
			if f_id == Faction.SPORE and _city_food[cid] >= exp_cost * 2.0:
				_city_food[cid] -= exp_cost * 1.35
			else:
				var use_w: float = minf(_city_wood[cid], exp_cost)
				_city_wood[cid] -= use_w
				_city_ore[cid] = maxf(0.0, _city_ore[cid] - (exp_cost - use_w))
			_refresh_city_targets(cid)
			_city_expand_timer[cid] = maxf(exp_int, pace_dt * 4.0)
		else:
			_city_expand_timer[cid] = maxf(6.0, pace_dt * 6.0)
	else:
		_city_expand_timer[cid] = maxf(6.0, pace_dt * 6.0)


func _step_spore_creep(cid: int, pace_dt: float) -> void:
	if int(_city_faction[cid]) != Faction.SPORE or int(_city_tech_tier[cid]) < 2:
		return
	_city_spore_creep_cd[cid] -= pace_dt
	if _city_spore_creep_cd[cid] > 0.0:
		return
	var mult: float = 0.72 if int(_city_tech_tier[cid]) >= 5 else 1.0
	_city_spore_creep_cd[cid] = maxf(_k_spore_creep_int * mult, pace_dt * 4.0)
	if _city_zones_count[cid] >= 36 + maxi(0, int(_city_tech_tier[cid]) - 2) * 14:
		return
	if _territory.try_spore_creep_zone(self, cid):
		_ecology_events_sent_total += 1
		_refresh_city_targets(cid)


func _step_city_construction(cid: int, pace_dt: float) -> void:
	var f_id: int = int(_city_faction[cid])
	var worker_work: float = _city_proj_work[cid]
	if worker_work > 0.0 and _city_damaged_blds[cid] != 0 and (_city_ore[cid] + _city_wood[cid]) >= 0.4:
		var rem_work: float = _apply_worker_repairs(cid, worker_work, f_id, pace_dt)
		_city_proj_work[cid] = rem_work
		worker_work = rem_work

	if _city_proj_type[cid] < 0:
		_city_proj_retry[cid] -= pace_dt
		if _city_proj_retry[cid] <= 0.0:
			_start_next_project(cid)
			if _city_proj_type[cid] < 0:
				_city_proj_retry[cid] = maxf(6.0, pace_dt * 8.0) if _sim_pace_mult >= 10.0 else 3.0

	var ptype: int = _city_proj_type[cid]
	if ptype < 0 or worker_work <= 0.0:
		return

	var req_ore: float = BLD_ORE_COSTS[ptype]
	var req_energy: float = BLD_ENERGY_COSTS[ptype]
	var build_dur: float = BLD_BUILD_TIMES[ptype]
	var mat_avail: float = _city_ore[cid] + _city_wood[cid]
	var drills: int = _city_bld_counts[cid * BLD_TYPE_COUNT + BuildingType.DRILL]
	if (req_energy > 0.0 and _city_energy[cid] < minf(req_energy * 0.2, 0.4)) or (mat_avail < req_ore * 0.2 and _city_proj_prog[cid] <= 0.15 and not (ptype == BuildingType.DRILL and drills == 0)):
		return

	# Drain buffered builder work at a capped physical rate so buildings take 8.5-22s at 1x and NEVER complete without builders.
	var drain_mul: float = 3.5 if _sim_pace_mult >= 10.0 else 1.65
	var drain: float = minf(_city_proj_work[cid], pace_dt * drain_mul)
	_city_proj_work[cid] -= drain
	var prog_step: float = drain / maxf(build_dur, 1.0)
	_city_proj_prog[cid] += prog_step
	if req_energy > 0.0:
		var e_sp: float = minf(_city_energy[cid], req_energy * minf(prog_step, 1.0) * 0.30)
		_city_energy[cid] = maxf(0.0, _city_energy[cid] - e_sp)
		_city_energy_spend_acc[cid] += e_sp

	if _city_proj_prog[cid] >= 1.0:
		_complete_city_project(cid, ptype, req_ore, req_energy)


func _complete_city_project(cid: int, ptype: int, req_ore: float, req_energy: float) -> void:
	var f_id: int = int(_city_faction[cid])
	var bspot: Vector2 = _city_build_pos[cid]
	if not _is_building_spot_valid(bspot, ptype, f_id):
		if not (ptype == BuildingType.BIODOME and _is_building_spot_valid(bspot, BuildingType.TENT, f_id)):
			bspot = _find_building_spot(cid, ptype)
	if bspot.x >= 0.0:
		var mat_spend: float = minf(req_ore, (_city_ore[cid] + _city_wood[cid]) * 0.45)
		var wood_sp: float = minf(_city_wood[cid], mat_spend * 0.65)
		_city_wood[cid] -= wood_sp
		_city_ore[cid] = maxf(0.0, _city_ore[cid] - (mat_spend - wood_sp))
		var e_done: float = minf(req_energy * 0.35, _city_energy[cid])
		_city_energy[cid] -= e_done
		_city_energy_spend_acc[cid] += e_done
		_place_building(cid, ptype, bspot, false)
		_add_city_science(cid, 12.0)
		_recompute_city_tech(cid)

	_city_proj_type[cid] = -1
	_city_proj_prog[cid] = 0.0
	_city_proj_work[cid] = 0.0
	_city_proj_retry[cid] = 0.0
	_buildings_dirty = true
	_start_next_project(cid)
	if _city_proj_type[cid] < 0:
		_city_proj_retry[cid] = maxf(6.0, _sim_pace_mult * 0.4) if _sim_pace_mult >= 10.0 else 3.0


func _step_city_tech_check(cid: int, pace_dt: float) -> void:
	if _city_tech_dirty[cid] != 0:
		_recompute_city_tech(cid)
		_city_tech_cd[cid] = 2.0
		return
	_city_tech_cd[cid] -= pace_dt
	if _city_tech_cd[cid] > 0.0:
		return
	_city_tech_cd[cid] = maxf(4.0, pace_dt * 8.0)
	var tier: int = int(_city_tech_tier[cid])
	var age: float = _city_age_sec[cid]
	if (tier == 0 and age >= _k_tier1_age) \
		or (tier == 1 and age >= _k_tier2_age) \
		or (tier == 2 and age >= _k_tier3_age) \
		or (tier == 3 and age >= _k_tier4_age) \
		or (tier == 4 and age >= 1650.0):
		_recompute_city_tech(cid)


func _step_city_pop_growth(cid: int, pace_dt: float) -> void:
	var f_id: int = int(_city_faction[cid])
	_city_pop_timer[cid] -= pace_dt
	if _city_pop_timer[cid] > 0.0:
		return
	_city_pop_timer[cid] = _k_pop_growth_int * (0.80 if f_id == Faction.SPORE else 1.0)
	if _city_pop[cid] >= _city_housing_cap(cid) or _physics == null or not _physics_has_spawn_colony_units:
		return
	var total_u: int = int(_physics.get_unit_count()) if _physics_has_get_unit_count else 0
	if total_u + 2 > _k_max_planet_units:
		return

	var can_grow: bool = false
	if f_id == Faction.ROBOT:
		var hold_for_pylon: bool = _city_proj_type[cid] == BuildingType.SHIELD_PYLON and (_city_ore[cid] < 20.0 or _city_energy[cid] < 10.0)
		if not hold_for_pylon and _city_ore[cid] >= 7.0 and _city_energy[cid] >= 6.0:
			_city_ore[cid] -= 5.0
			_city_energy[cid] -= 5.0
			_city_energy_spend_acc[cid] += 5.0
			can_grow = true
	else:
		var food_cost: float = _k_pop_growth_food * (0.75 if f_id == Faction.SPORE else 1.0)
		if _city_food[cid] >= food_cost + 2.0:
			_city_food[cid] -= food_cost
			can_grow = true
	if can_grow:
		var added: int = int(_physics.spawn_colony_units(cid, _city_center[cid], 2))
		_city_pop[cid] += added
		if added > 0:
			_city_tech_dirty[cid] = 1


func _apply_worker_repairs(city_id: int, work_avail: float, faction_id: int, pace_dt: float) -> float:
	var best_idx: int = -1
	var worst_ratio: float = 0.72 if _city_proj_type[city_id] >= 0 else 0.94
	var best_max_hp: float = 100.0
	var any_damaged: bool = false
	for i in range(_bld_count):
		if _bld_city_id[i] != city_id:
			continue
		var m_hp: float = _building_max_hp(int(_bld_type[i]), faction_id)
		if _bld_hp[i] < m_hp:
			any_damaged = true
		var r: float = _bld_hp[i] / m_hp
		if r < worst_ratio:
			worst_ratio = r
			best_idx = i
			best_max_hp = m_hp
	if best_idx < 0:
		if not any_damaged:
			_city_damaged_blds[city_id] = 0
		return work_avail
	var repair_share: float = minf(work_avail, maxf(0.35, pace_dt * 0.45))
	_bld_hp[best_idx] = minf(best_max_hp, _bld_hp[best_idx] + repair_share * 65.0)
	if faction_id == Faction.ROBOT and _city_energy[city_id] >= 0.5:
		_city_energy[city_id] -= 0.25
		_city_energy_spend_acc[city_id] += 0.25
	if _city_ore[city_id] >= 1.5:
		_city_ore[city_id] = maxf(0.0, _city_ore[city_id] - 0.15)
	_buildings_dirty = true
	return work_avail - repair_share


func _step_buildings_environment(dt: float) -> void:
	if _world == null or _bld_count <= 0:
		return
	var has_fire_api: bool = _world_has_get_fire
	var has_moist_api: bool = _world_has_get_moisture
	var spore_fire_mul: float = _k_spore_fire_mul
	var mw: int = _map_w
	var mh: int = _map_h
	var biomes_c: PackedByteArray = _territory._w_biomes_cache
	var has_biomes_c: bool = (_territory._w_cache_owner == _world and biomes_c.size() == mw * mh)
	var dome_r2: float = _k_dome_prot_r * _k_dome_prot_r
	var domes_ready: bool = false
	var dome_spots: PackedVector2Array
	var meltdowns: Array[Vector2] = []
	var melt_cids: Array[int] = []
	var touched_cities: Dictionary = {}

	var bi: int = _bld_count - 1
	while bi >= 0:
		var bpos: Vector2 = _bld_pos[bi]
		var bpx: int = clampi(int(floor(bpos.x)), 0, mw - 1)
		var bpy: int = clampi(int(floor(bpos.y)), 0, mh - 1)
		var cid: int = _bld_city_id[bi]
		var fid: int = int(_city_faction[clampi(cid, 0, _max_cities - 1)])
		var fire_val: float = _world.get_fire(bpx, bpy) if has_fire_api else 0.0
		var biome: int = int(biomes_c[bpy * mw + bpx]) if has_biomes_c else _world.get_biome(bpx, bpy)
		var temp_c: float = _world.get_temp(bpx, bpy)
		var env_dmg: float = _calc_bld_env_dmg(biome, fire_val, temp_c, fid, spore_fire_mul, dt)
		if env_dmg > 0.0:
			if biome != BIOME_LAVA:
				if not domes_ready:
					domes_ready = true
					for di in range(_bld_count):
						if int(_bld_type[di]) == BuildingType.BIODOME:
							var dcid: int = _bld_city_id[di]
							if dcid < 0 or dcid >= _max_cities or _city_dome_powered[dcid] != 0:
								dome_spots.append(_bld_pos[di])
				for dp in dome_spots:
					if dp.distance_squared_to(bpos) <= dome_r2:
						env_dmg *= 0.60
						break
			_bld_hp[bi] -= env_dmg
			if cid >= 0 and cid < _max_cities:
				_city_damaged_blds[cid] = 1
			_bld_shake[bi] = maxf(_bld_shake[bi], 2.0 + clampf(fire_val, 0.25, 1.0))
			_has_bld_springs = true
			_spring_cache_dirty = true
			_buildings_dirty = true
			touched_cities[cid] = true
			if _bld_hp[bi] <= 0.0:
				if _bld_type[bi] == BuildingType.FUSION_REACTOR:
					meltdowns.append(bpos)
					melt_cids.append(cid)
				_remove_building(bi)
		elif fid == Faction.SPORE:
			var moist: float = _world.get_moisture(bpx, bpy) if has_moist_api else 0.3
			if biome == BIOME_LUSH or moist >= 0.45:
				var max_hp: float = _building_max_hp(int(_bld_type[bi]), fid)
				if _bld_hp[bi] < max_hp:
					_bld_hp[bi] = minf(max_hp, _bld_hp[bi] + 2.5 * dt)
					_buildings_dirty = true
		bi -= 1

	for mi in range(meltdowns.size()):
		_trigger_reactor_meltdown(meltdowns[mi], melt_cids[mi])
	for k in touched_cities.keys():
		var tcid: int = int(k)
		if tcid >= 0 and tcid < _max_cities and _city_active[tcid] != 0:
			_verify_city_integrity_after_damage(tcid)


func _calc_bld_env_dmg(biome: int, fire_val: float, temp_c: float, fid: int, spore_fire_mul: float, dt: float) -> float:
	var dmg: float = 0.0
	if biome == BIOME_LAVA:
		dmg = 42.0 * dt
	elif fire_val > 0.06:
		dmg = (18.0 + fire_val * 26.0) * _fire_mul * dt
	elif temp_c > 70.0 and fid != Faction.ROBOT:
		dmg = (temp_c - 65.0) * 0.35 * _fire_mul * dt
	if dmg <= 0.0:
		return 0.0
	if fid == Faction.SPORE:
		return dmg * spore_fire_mul
	if fid == Faction.ROBOT and biome != BIOME_LAVA:
		return dmg * (0.25 if fire_val > 0.50 else 0.0)
	return dmg


func _trigger_reactor_meltdown(melt_pos: Vector2, src_cid: int) -> void:
	var melt_r: float = _k_meltdown_r
	if _fx != null:
		if _fx_has_spawn_burst:
			_fx.spawn_burst(melt_pos, 18, Color(0.35, 1.95, 2.35, 1.0), 58.0, 0.60, 20.0)
		if _fx_has_play_sfx:
			_fx.play_sfx(8)
	if _world != null and _world.has_method("apply_elemental_storm"):
		_world.call("apply_elemental_storm", melt_pos, melt_r, "meltdown_crater")
	if _physics != null and _physics.has_method("bless_or_mutate_area"):
		_physics.call("bless_or_mutate_area", melt_pos, melt_r * 1.6, false)
	if src_cid >= 0 and src_cid < _max_cities and _city_active[src_cid] != 0:
		_city_alerted[src_cid] = 1
		_city_alert_timer[src_cid] = 5.0
		_city_threat_pos[src_cid] = melt_pos
		_light_goals_dirty = true


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
	if not _territory.is_pixel_walkable(self, Vector2i(cpx, cpy), fid):
		_city_center[cid] = first_bld_pos
		_light_goals_dirty = true
	if _city_proj_type[cid] >= 0 and not _is_building_spot_valid(_city_build_pos[cid], _city_proj_type[cid], fid):
		_city_proj_type[cid] = -1
		_city_proj_prog[cid] = 0.0
		_city_build_pos[cid] = _city_center[cid]
		_buildings_dirty = true
		_light_goals_dirty = true
	_recompute_city_tech(cid)
	_refresh_city_targets(cid)


func get_contested_capture_spots() -> Array[Dictionary]:
	_ensure_initialized()
	var out: Array[Dictionary] = []
	if _active_cap_count <= 0:
		return out
	var hold_sec: float = maxf(0.1, _k_war_zone_cap_sec)
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
		out.append({
			"pos": Vector2((float(zidx % _zone_w) + 0.5) * float(_zone_px), (float(zidx / _zone_w) + 0.5) * float(_zone_px)),
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
	var salvage_r2: float = _k_ruin_salvage_r * _k_ruin_salvage_r
	var ri: int = _ruin_count - 1
	while ri >= 0:
		var rpos: Vector2 = _ruin_pos[ri]
		var zowner: int = get_zone_owner_at(rpos)
		var claimer: int = zowner if (zowner >= 0 and _city_active[zowner] != 0) else -1
		if claimer < 0:
			var best_d2: float = salvage_r2
			for cid in range(_max_cities):
				if _city_active[cid] != 0:
					var d2: float = _city_center[cid].distance_squared_to(rpos)
					if d2 <= best_d2:
						best_d2 = d2
						claimer = cid
		if claimer >= 0:
			var ore_c: float = minf(_ruin_ore[ri], 6.0)
			var sci_c: float = minf(_ruin_sci[ri], 5.0)
			_ruin_ore[ri] -= ore_c
			_ruin_sci[ri] -= sci_c
			_city_ore[claimer] = minf(_city_storage_cap[claimer], _city_ore[claimer] + ore_c)
			_add_city_science(claimer, sci_c)
			_total_harvested += ore_c + sci_c
			_city_tech_dirty[claimer] = 1
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
		if _city_active[cid] != 0:
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
			if _fx != null and _fx_has_spawn_burst:
				_fx.spawn_burst(_ruin_pos[ri], 8, Color(1.0, 0.85, 0.40, 0.95), 24.0, 0.45, -10.0)
			_remove_ruin(ri)
		ri -= 1
	if best_cid >= 0 and count_salvaged > 0:
		_city_ore[best_cid] = minf(_city_storage_cap[best_cid], _city_ore[best_cid] + total_ore)
		_add_city_science(best_cid, total_sci)
		_total_harvested += total_ore + total_sci
		_city_tech_dirty[best_cid] = 1
	return {"salvaged": count_salvaged, "ore": total_ore, "science": total_sci, "city_id": best_cid}


func _city_has_active_shuttle(cid: int) -> bool:
	for si in range(_shuttle_count):
		if _shuttle_src_city[si] == cid:
			return true
	return false


func _city_has_incoming_supply(dst_cid: int) -> bool:
	for si in range(_shuttle_count):
		if int(_shuttle_kind[si]) == SHUTTLE_KIND_SUPPLY and _shuttle_target_city[si] == dst_cid:
			return true
	return false


func _try_supply_sister_cities() -> void:
	if _shuttle_count >= _max_shuttles:
		return
	var rich_food: float = _k_supply_rich_food
	var rich_ore: float = _k_supply_rich_ore
	var need_sum: float = _k_supply_need_sum
	var speed_px: float = maxf(14.0, _k_shuttle_speed * 1.15)
	for src in range(_max_cities):
		if _shuttle_count >= _max_shuttles:
			break
		if _city_active[src] == 0 or int(_city_tech_tier[src]) < 2:
			continue
		if _city_shuttle_cd[src] > 0.0 or _city_has_active_shuttle(src):
			continue
		if _city_food[src] <= rich_food and _city_ore[src] <= rich_ore:
			continue
		var best_dst: int = _find_needy_sister_city(src, need_sum)
		if best_dst < 0:
			continue
		_launch_supply_shuttle(src, best_dst, speed_px)
		break


func _find_needy_sister_city(src: int, lowest_sum: float) -> int:
	var f_id: int = int(_city_faction[src])
	var src_kid: int = _city_kingdom_id[src]
	var best_dst: int = -1
	var low: float = lowest_sum
	for dst in range(_max_cities):
		if dst == src or _city_active[dst] == 0 or int(_city_faction[dst]) != f_id:
			continue
		if src_kid >= 0 and _city_kingdom_id[dst] != src_kid:
			continue
		var dst_sum: float = _city_food[dst] + _city_ore[dst]
		if dst_sum < low and not _city_has_incoming_supply(dst):
			low = dst_sum
			best_dst = dst
	return best_dst


func _launch_supply_shuttle(src: int, dst: int, speed_px: float) -> void:
	var launch_pos: Vector2 = _city_center[src]
	for bi in range(_bld_count):
		if _bld_city_id[bi] == src and _bld_type[bi] == BuildingType.LAUNCHPAD:
			launch_pos = _bld_pos[bi]
			break
	var load_food: float = clampf(_city_food[src] - 25.0, 0.0, _k_supply_food)
	var load_ore: float = clampf(_city_ore[src] - 32.0, 0.0, _k_supply_ore)
	var load_energy: float = clampf(_city_energy[src] - 16.0, 0.0, _k_supply_energy)
	var launch_fuel: float = minf(4.0, maxf(0.0, _city_energy[src] - load_energy - 8.0) * 0.25)
	_city_food[src] = maxf(0.0, _city_food[src] - load_food)
	_city_ore[src] = maxf(0.0, _city_ore[src] - load_ore)
	_city_energy[src] = maxf(0.0, _city_energy[src] - load_energy - launch_fuel)
	_city_energy_spend_acc[src] += launch_fuel
	_city_shuttle_cd[src] = 10.0
	_city_shuttles_launched[src] += 1
	_total_shuttles_launched += 1

	var target: Vector2 = _city_center[dst]
	var sidx: int = _shuttle_count
	_shuttle_count += 1
	_shuttle_start[sidx] = launch_pos
	_shuttle_target[sidx] = target
	_shuttle_pos[sidx] = launch_pos
	_shuttle_t[sidx] = 0.0
	_shuttle_dur[sidx] = clampf(launch_pos.distance_to(target) / speed_px, 1.2, 6.5)
	_shuttle_faction[sidx] = _city_faction[src]
	_shuttle_src_city[sidx] = src
	_shuttle_trail_t[sidx] = 0.0
	_shuttle_kind[sidx] = SHUTTLE_KIND_SUPPLY
	_shuttle_target_city[sidx] = dst
	_shuttle_cargo_food[sidx] = load_food
	_shuttle_cargo_ore[sidx] = load_ore
	_shuttle_cargo_energy[sidx] = load_energy
	_buildings_dirty = true


func _step_shuttles(pace_dt: float) -> void:
	if _shuttle_count <= 0:
		return
	var si: int = _shuttle_count - 1
	while si >= 0:
		var dur: float = maxf(0.5, _shuttle_dur[si])
		_shuttle_t[si] += pace_dt / dur
		var t: float = clampf(_shuttle_t[si], 0.0, 1.0)
		var smooth_t: float = t * t * (3.0 - 2.0 * t)
		var base_pos: Vector2 = _shuttle_start[si].lerp(_shuttle_target[si], smooth_t)
		var is_boat: bool = int(_shuttle_kind[si]) == SHUTTLE_KIND_BOAT
		var alt: float = sin(t * PI) * (3.0 if is_boat else 18.0)
		_shuttle_pos[si] = base_pos + Vector2(0.0, (-1.0 if is_boat else -4.0) - alt)

		if _sim_pace_mult < 15.0:
			_shuttle_trail_t[si] -= pace_dt
			if _shuttle_trail_t[si] <= 0.0 and _fx != null and _fx_has_spawn_burst:
				_shuttle_trail_t[si] = 0.16
				var t_col := Color(0.45, 0.95, 0.65, 0.95) if int(_shuttle_kind[si]) == SHUTTLE_KIND_SUPPLY else (Color(0.55, 0.88, 1.0, 0.85) if is_boat else Color(1.3, 0.72, 0.28, 0.95))
				_fx.spawn_burst(_shuttle_pos[si] + Vector2(0.0, 2.0), 1, t_col, 8.0, 0.25, 10.0)

		if _shuttle_t[si] >= 1.0:
			_on_shuttle_landed(si)
			_remove_shuttle(si)
		si -= 1
	_buildings_dirty = true


func _on_shuttle_landed(si: int) -> void:
	var tpos: Vector2 = _shuttle_target[si]
	if int(_shuttle_kind[si]) == SHUTTLE_KIND_SUPPLY:
		var tcid: int = _shuttle_target_city[si]
		if tcid >= 0 and tcid < _max_cities and _city_active[tcid] != 0:
			var cap: float = _city_storage_cap[tcid]
			_city_food[tcid] = minf(cap, _city_food[tcid] + _shuttle_cargo_food[si])
			_city_ore[tcid] = minf(cap, _city_ore[tcid] + _shuttle_cargo_ore[si])
			_city_energy[tcid] = minf(cap, _city_energy[tcid] + _shuttle_cargo_energy[si])
			_supply_deliveries += 1
	else:
		var src_cid: int = _shuttle_src_city[si]
		if src_cid >= 0 and src_cid < _max_cities and _city_active[src_cid] != 0 and can_settle_near(tpos):
			_found_daughter_settlement(src_cid, tpos, 5)


func _remove_shuttle(si: int) -> void:
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
		_shuttle_cargo_food[si] = _shuttle_cargo_food[last]
		_shuttle_cargo_ore[si] = _shuttle_cargo_ore[last]
		_shuttle_cargo_energy[si] = _shuttle_cargo_energy[last]
	_shuttle_count = last


func _step_shield_pylons(pace_dt: float) -> void:
	if _shield_cache_dirty:
		_shield_cache_dirty = false
		_shield_indices.clear()
		for bi in range(_bld_count):
			if _bld_type[bi] == BuildingType.SHIELD_PYLON:
				_shield_indices.append(bi)
	if _shield_indices.is_empty():
		return
	var base_rate: float = _k_shield_recharge
	var flash_decay: float = _k_shield_flash_decay
	var solar_boost: float = maxf(0.45, _solar_mul)
	for si in range(_shield_indices.size()):
		var i: int = _shield_indices[si]
		var fl: float = _bld_shield_flash[i]
		if fl > 0.0:
			_bld_shield_flash[i] = maxf(0.0, fl - pace_dt * flash_decay)
			_buildings_dirty = true
		var ch: float = _bld_shield_charge[i]
		if ch < 1.0:
			var cid: int = clampi(_bld_city_id[i], 0, _max_cities - 1)
			var full_e: float = 0.45 * pace_dt
			var take_e: float = minf(full_e, _city_energy[cid])
			if take_e > 0.001 and consume_city_energy(cid, take_e):
				var e_mul: float = clampf(0.5 + _city_energy[cid] * 0.04, 0.5, 2.0)
				var ratio: float = clampf(take_e / maxf(full_e, 0.0001), 0.0, 1.0)
				var new_ch: float = minf(1.0, ch + base_rate * solar_boost * e_mul * pace_dt * ratio)
				_bld_shield_charge[i] = new_ch
				if ch < 0.25 and new_ch >= 0.25:
					_buildings_dirty = true


func _step_building_springs(dt: float) -> bool:
	if _spring_cache_dirty:
		_spring_cache_dirty = false
		_spring_indices.clear()
		for bi in range(_bld_count):
			if _bld_shake[bi] > 0.0 or absf(_bld_spring[bi] - 1.0) > 0.002 or absf(_bld_spring_vel[bi]) > 0.002:
				_spring_indices.append(bi)
	_spring_dirty_ids.clear()
	if _spring_indices.is_empty():
		_has_bld_springs = false
		return false
	var omega: float = _k_spring_omega
	var zeta: float = _k_spring_zeta
	var moved: bool = false
	var si: int = _spring_indices.size() - 1
	while si >= 0:
		var i: int = _spring_indices[si]
		if i < 0 or i >= _bld_count:
			var last_s: int = _spring_indices.size() - 1
			if si != last_s:
				_spring_indices[si] = _spring_indices[last_s]
			_spring_indices.resize(last_s)
			si -= 1
			continue
		var active_b: bool = false
		var b_moved: bool = false
		var sh: float = _bld_shake[i]
		if sh > 0.0:
			var next_sh: float = maxf(0.0, sh - dt * 2.5)
			_bld_shake[i] = next_sh
			moved = true
			b_moved = true
			if next_sh > 0.0:
				active_b = true
		var sp: float = _bld_spring[i]
		var sv: float = _bld_spring_vel[i]
		if absf(sp - 1.0) > 0.002 or absf(sv) > 0.002:
			sv += (-omega * omega * (sp - 1.0) - 2.0 * zeta * omega * sv) * dt
			sp += sv * dt
			if absf(sp - 1.0) < 0.002 and absf(sv) < 0.01:
				sp = 1.0
				sv = 0.0
			else:
				active_b = true
			_bld_spring[i] = clampf(sp, 0.08, 1.35)
			_bld_spring_vel[i] = sv
			moved = true
			b_moved = true
		if b_moved:
			_spring_dirty_ids.append(i)
		if not active_b:
			var last_idx: int = _spring_indices.size() - 1
			if si != last_idx:
				_spring_indices[si] = _spring_indices[last_idx]
			_spring_indices.resize(last_idx)
		si -= 1
	if _spring_indices.is_empty():
		_has_bld_springs = false
	return moved


func _is_bld_anim_frame_active(btype: int, ph: float) -> bool:
	match btype:
		BuildingType.CAMPFIRE:
			return (int(floor(_sim_time * 8.0 + ph)) & 1) == 1
		BuildingType.DRILL:
			return (int(floor(_sim_time * 4.5 + ph)) & 1) == 1
		BuildingType.DEPOT:
			return (int(floor(_sim_time * 1.6 + ph)) & 1) == 1
		BuildingType.SOLAR_ARRAY:
			return fmod(_sim_time + ph, 4.0) > 3.2
		BuildingType.FUSION_REACTOR:
			return (int(floor(_sim_time * 3.0 + ph)) & 1) == 1
		BuildingType.BIODOME, BuildingType.TENT:
			return (int(floor(_sim_time * 2.2 + ph)) & 1) == 1
		_:
			return false


func _building_anim_col(i: int, btype: int) -> int:
	var ph: float = _bld_phase[i]
	var hp: float = _bld_hp[i]
	var cid: int = clampi(_bld_city_id[i], 0, _max_cities - 1)
	var f_id: int = int(_city_faction[cid])
	var m_hp: float = _building_max_hp(btype, f_id)
	var damaged: bool = hp < m_hp * 0.62
	var max_col: int = maxi(0, _bld_atlas_cols - 1)

	if btype == BuildingType.CAMPFIRE and _bld_level[i] >= 1:
		var hq_col: int = BLD_COL_HQ_L2_HUMAN + clampi(f_id, 0, 2)
		if hq_col <= max_col:
			return hq_col
	if btype == BuildingType.SHIELD_PYLON:
		var sh_c: int = BLD_COL_SHIELD_ACTIVE if (_bld_shield_flash[i] > 0.05 or (_bld_shield_charge[i] >= _k_shield_min_ch and fmod(_sim_time * 1.4 + ph, 2.0) > 1.0)) else BLD_COL_SHIELD
		return clampi(sh_c, 0, max_col)
	if btype == BuildingType.QUANTUM_GATE:
		var q_c: int = BLD_COL_QUANTUM_GATE if (_city_emp_timer[cid] > 0.0 or _city_energy[cid] < 2.0) else BLD_COL_QUANTUM_GATE_ACTIVE
		return clampi(q_c, 0, max_col)
	if btype == BuildingType.BIODOME and damaged and f_id != Faction.SPORE:
		return clampi(BLD_COL_BIODOME_DAMAGED, 0, max_col)
	if btype == BuildingType.LAUNCHPAD and damaged:
		return clampi(BLD_COL_LAUNCHPAD_SCORCHED, 0, max_col)
	if btype == BuildingType.LAUNCHPAD and int(_city_tech_tier[cid]) >= 5:
		var t5_col: int = BLD_COL_HUMAN_ARK_SPIRE if f_id == Faction.HUMAN else (BLD_COL_ROBOT_MIRROR_NODE if f_id == Faction.ROBOT else BLD_COL_SPORE_LEVIATHAN_HEART)
		return clampi(t5_col, 0, max_col)
	if btype == BuildingType.LAUNCHPAD and _city_has_active_shuttle(cid) and f_id == Faction.HUMAN:
		return clampi(BLD_COL_LAUNCHPAD_EMPTY, 0, max_col)

	if f_id == Faction.HUMAN:
		var anim_on: bool = _is_bld_anim_frame_active(btype, ph)
		if anim_on:
			match btype:
				BuildingType.CAMPFIRE:
					return clampi(8, 0, max_col)
				BuildingType.DRILL:
					return clampi(10, 0, max_col)
				BuildingType.DEPOT:
					return clampi(11, 0, max_col)
				BuildingType.SOLAR_ARRAY:
					return clampi(12, 0, max_col)
				BuildingType.FUSION_REACTOR:
					return clampi(14, 0, max_col)
		return clampi(int(BLD_COLS_HUMAN[clampi(btype, 0, BLD_TYPE_COUNT - 1)]), 0, max_col)
	if f_id == Faction.ROBOT:
		return clampi(int(BLD_COLS_ROBOT[clampi(btype, 0, BLD_TYPE_COUNT - 1)]), 0, max_col)
	return clampi(int(BLD_COLS_SPORE[clampi(btype, 0, BLD_TYPE_COUNT - 1)]), 0, max_col)


func _sync_buildings_multimesh(full_sync: bool = true) -> void:
	if _mm_buildings == null or _mm_buildings.multimesh == null:
		return
	var mm: MultiMesh = _mm_buildings.multimesh
	var cap_inst: int = mm.instance_count
	var anchor_off := Vector2(0.0, -BUILDING_CELL_PX * 0.5)
	var slot_i: int = 0
	slot_i = _write_buildings_mm(mm, cap_inst, anchor_off, slot_i, full_sync)
	slot_i = _write_scaffolds_mm(mm, cap_inst, anchor_off, slot_i)
	slot_i = _write_ruins_mm(mm, cap_inst, anchor_off, slot_i)
	slot_i = _write_shuttles_mm(mm, cap_inst, slot_i)
	_ships_mm_slot_base = slot_i
	if _meta != null:
		slot_i = _meta.write_ships_mm(self, mm, Vector2i(slot_i, cap_inst))
	mm.visible_instance_count = slot_i


func _sync_ships_tail_mm() -> void:
	if _meta == null or _mm_buildings == null or _mm_buildings.multimesh == null:
		return
	var mm: MultiMesh = _mm_buildings.multimesh
	var cap_inst: int = mm.instance_count
	if _ships_mm_slot_base < 0 or _ships_mm_slot_base > cap_inst:
		return
	var end_slot: int = _meta.write_ships_mm(self, mm, Vector2i(_ships_mm_slot_base, cap_inst))
	mm.visible_instance_count = end_slot


func _write_single_building_mm(mm: MultiMesh, i: int, anchor_off: Vector2, full_sync: bool = true) -> void:
	var btype: int = int(_bld_type[i])
	var cid: int = clampi(_bld_city_id[i], 0, _max_cities - 1)
	var f_id: int = int(_city_faction[cid])
	var col_idx: int = _building_anim_col(i, btype)
	var anim_on: bool = _is_bld_anim_frame_active(btype, _bld_phase[i])
	var shake_val: float = _bld_shake[i]
	if btype == BuildingType.DRILL and anim_on:
		shake_val = maxf(shake_val, 0.16)
	var b_col: Color = _bld_color[i]
	var spring_b: float = _bld_spring[i]
	if f_id != Faction.HUMAN and anim_on:
		if absf(spring_b - 1.0) <= 0.01:
			spring_b = 0.94 if f_id == Faction.SPORE else 0.96
		if btype == BuildingType.CAMPFIRE or btype == BuildingType.FUSION_REACTOR or btype == BuildingType.SOLAR_ARRAY:
			spring_b = -spring_b
		b_col = b_col.lightened(0.14)
	if btype == BuildingType.SHIELD_PYLON and _bld_shield_flash[i] > 0.05:
		var fl: float = clampf(_bld_shield_flash[i], 0.0, 1.0)
		shake_val = maxf(shake_val, fl * 0.45)
		b_col = b_col.lerp(Color(0.55, 0.96, 1.0, 1.0), fl * 0.65)
	elif btype == BuildingType.QUANTUM_GATE and _city_emp_timer[cid] > 0.0:
		b_col = b_col.lerp(Color(0.32, 0.42, 0.54, 1.0), 0.55)
	if full_sync:
		mm.set_instance_transform_2d(i, Transform2D(0.0, _bld_pos[i] + anchor_off))
	mm.set_instance_color(i, b_col)
	mm.set_instance_custom_data(i, Color(_bld_phase[i], shake_val, spring_b, float(col_idx)))


func _sync_spring_buildings_only() -> void:
	if _mm_buildings == null or _mm_buildings.multimesh == null:
		return
	var mm: MultiMesh = _mm_buildings.multimesh
	var lim: int = mini(_bld_count, mm.instance_count)
	var anchor_off := Vector2(0.0, -BUILDING_CELL_PX * 0.5)
	for i in _spring_dirty_ids:
		if i >= 0 and i < lim:
			_write_single_building_mm(mm, i, anchor_off, false)


func _write_buildings_mm(mm: MultiMesh, cap_inst: int, anchor_off: Vector2, slot_i: int, full_sync: bool = true) -> int:
	var b_lim: int = mini(_bld_count, cap_inst)
	for i in range(b_lim):
		_write_single_building_mm(mm, i, anchor_off, full_sync)
	return maxi(slot_i, b_lim)


func _write_scaffolds_mm(mm: MultiMesh, cap_inst: int, anchor_off: Vector2, slot_i: int) -> int:
	for cid in range(_max_cities):
		if slot_i >= cap_inst:
			break
		if _city_active[cid] == 0 or _city_proj_type[cid] < 0:
			continue
		var ptype: int = _city_proj_type[cid]
		var prog_cl: float = clampf(_city_proj_prog[cid], 0.0, 1.0)
		var sc_col: int = clampi(BLD_COL_SCAFFOLD_LG if ptype >= BuildingType.BIODOME else BLD_COL_SCAFFOLD, 0, maxi(0, _bld_atlas_cols - 1))
		mm.set_instance_transform_2d(slot_i, Transform2D(0.0, _city_build_pos[cid] + anchor_off))
		mm.set_instance_color(slot_i, _city_color[cid])
		mm.set_instance_custom_data(slot_i, Color(float(cid) * 0.7, -0.5, lerpf(0.62, 0.96, prog_cl), float(sc_col)))
		slot_i += 1
	return slot_i


func _write_ruins_mm(mm: MultiMesh, cap_inst: int, anchor_off: Vector2, slot_i: int) -> int:
	var r_col_idx: int = clampi(BLD_COL_RUINS, 0, maxi(0, _bld_atlas_cols - 1))
	for ri in range(_ruin_count):
		if slot_i >= cap_inst:
			break
		var rf_col: Color = FACTION_TINT_COLORS[clampi(int(_ruin_faction[ri]), 0, FACTION_TINT_COLORS.size() - 1)].lerp(Color(0.65, 0.68, 0.72), 0.55)
		mm.set_instance_transform_2d(slot_i, Transform2D(0.0, _ruin_pos[ri] + anchor_off))
		mm.set_instance_color(slot_i, rf_col)
		mm.set_instance_custom_data(slot_i, Color(_ruin_phase[ri], 0.0, 0.92, float(r_col_idx)))
		slot_i += 1
	return slot_i


func _write_shuttles_mm(mm: MultiMesh, cap_inst: int, slot_i: int) -> int:
	var max_col: int = maxi(0, _bld_atlas_cols - 1)
	for si in range(_shuttle_count):
		if slot_i >= cap_inst:
			break
		var fid: int = clampi(int(_shuttle_faction[si]), 0, FACTION_TINT_COLORS.size() - 1)
		var facing: float = -1.0 if _shuttle_target[si].x < _shuttle_start[si].x else 1.0
		var sh_col: int = clampi(BLD_COL_SHUTTLE_BOOST if _shuttle_t[si] < 0.75 else BLD_COL_SHUTTLE, 0, max_col)
		var s_tint: Color = FACTION_BORDER_COLORS[fid]
		if int(_shuttle_kind[si]) == SHUTTLE_KIND_SUPPLY:
			s_tint = s_tint.lerp(Color(0.35, 0.98, 0.62, 1.0), 0.55)
		elif int(_shuttle_kind[si]) == SHUTTLE_KIND_BOAT:
			s_tint = s_tint.lerp(Color(0.45, 0.82, 1.0, 1.0), 0.40)
		mm.set_instance_transform_2d(slot_i, Transform2D(0.0, _shuttle_pos[si]))
		mm.set_instance_color(slot_i, s_tint)
		mm.set_instance_custom_data(slot_i, Color(float(si), 0.0, facing, float(sh_col)))
		slot_i += 1
	return slot_i


func deposit_resource(city_id: int, res_type: int, amount: float) -> void:
	_ensure_initialized()
	if city_id < 0 or city_id >= _max_cities or _city_active[city_id] == 0 or amount <= 0.0:
		return
	var cap: float = _city_storage_cap[city_id]
	var f_id: int = int(_city_faction[city_id])
	match res_type:
		ResourceType.FOOD:
			if f_id != Faction.ROBOT:
				var f_amt: float = amount * (1.20 if f_id == Faction.SPORE else 1.0) * _crop_mul
				_city_food[city_id] = minf(cap, _city_food[city_id] + f_amt)
				_add_city_science(city_id, f_amt * 0.55)
				_total_harvested += f_amt
		ResourceType.ORE:
			var o_amt: float = amount * (1.18 if f_id == Faction.ROBOT else 1.0)
			_city_ore[city_id] = minf(cap, _city_ore[city_id] + o_amt)
			_add_city_science(city_id, o_amt * 0.75)
			_total_harvested += o_amt
		ResourceType.ENERGY:
			_city_energy[city_id] = minf(cap, _city_energy[city_id] + amount)
			_city_ore[city_id] = minf(cap, _city_ore[city_id] + amount * 0.35)
			_add_city_science(city_id, amount * 0.45)
			_total_harvested += amount
		ResourceType.SCIENCE:
			_add_city_science(city_id, amount)
			_total_harvested += amount
		ResourceType.BUILD_WORK:
			# At 1x scale=1.15 (real 9-20s build); at high sim pace scale unclamped with _sim_pace_mult.
			var pace_comp: float = maxf(1.0, _sim_pace_mult)
			var work_cap: float = maxf(36.0, _sim_pace_mult * 2.5)
			_city_proj_work[city_id] = minf(work_cap, _city_proj_work[city_id] + amount * 1.15 * pace_comp)
			_add_city_science(city_id, amount * 0.35)
		ResourceType.WOOD:
			_city_wood[city_id] = minf(cap, _city_wood[city_id] + amount)
			_add_city_science(city_id, amount * 0.40)
			_total_harvested += amount
		ResourceType.CREDITS:
			_city_credits[city_id] = minf(cap * 2.0, _city_credits[city_id] + amount)
			_total_harvested += amount


func _has_active_dome_near(pos: Vector2) -> bool:
	var dome_r2: float = _k_dome_prot_r
	dome_r2 *= dome_r2
	for i in range(_bld_count):
		if _bld_type[i] == BuildingType.BIODOME and _bld_pos[i].distance_squared_to(pos) <= dome_r2:
			var cid: int = _bld_city_id[i]
			if cid < 0 or cid >= _max_cities or _city_dome_powered[cid] != 0:
				return true
	return false


func on_terrain_damaged(world_pos: Vector2, radius: float) -> void:
	_ensure_initialized()
	if radius <= 0.5:
		return
	var r_eff: float = maxf(radius, 2.0)
	var touched_cities: Dictionary = {}
	_clear_damaged_roads_in_radius(world_pos, r_eff)
	_damage_buildings_in_radius(world_pos, r_eff, touched_cities)
	_unclaim_damaged_zones_in_radius(world_pos, r_eff, touched_cities)
	for cid_k in touched_cities.keys():
		var cid: int = int(cid_k)
		if cid >= 0 and cid < _max_cities and _city_active[cid] != 0:
			_verify_city_integrity_after_damage(cid)
	_territory.flush_dirty_borders(self)
	if _buildings_dirty:
		_sync_buildings_multimesh()
		_buildings_dirty = false
	_push_goal_buffers()


func _clear_damaged_roads_in_radius(world_pos: Vector2, r_eff: float) -> void:
	var r2: float = r_eff * r_eff
	var px0: int = clampi(int(floor(world_pos.x - r_eff)), 0, _map_w - 1)
	var py0: int = clampi(int(floor(world_pos.y - r_eff)), 0, _map_h - 1)
	var px1: int = clampi(int(ceil(world_pos.x + r_eff)), 0, _map_w - 1)
	var py1: int = clampi(int(ceil(world_pos.y + r_eff)), 0, _map_h - 1)
	for py in range(py0, py1 + 1):
		var dy: float = float(py) - world_pos.y
		var row_off: int = py * _map_w
		for px in range(px0, px1 + 1):
			var dx: float = float(px) - world_pos.x
			if dx * dx + dy * dy <= r2 and _road_mask[row_off + px] != ROAD_NONE:
				_territory.clear_road_pixel(self, row_off + px)
				_territory.mark_zone_dirty(self, px / _zone_px, py / _zone_px)
				_road_mask_dirty = true
				_goals_dirty = true


func _damage_buildings_in_radius(world_pos: Vector2, r_eff: float, touched_cities: Dictionary) -> void:
	var r2: float = r_eff * r_eff
	var meltdowns: Array[Vector2] = []
	var melt_cids: Array[int] = []
	var bi: int = _bld_count - 1
	while bi >= 0:
		var bpos: Vector2 = _bld_pos[bi]
		var d2: float = bpos.distance_squared_to(world_pos)
		var bpx: int = clampi(int(floor(bpos.x)), 0, _map_w - 1)
		var bpy: int = clampi(int(floor(bpos.y)), 0, _map_h - 1)
		var bad: bool = _world != null and (int(_world.get_tier(bpx, bpy)) <= TIER_CLOSE_OCEAN or _world.get_biome(bpx, bpy) == BIOME_LAVA)
		if bad or d2 <= r2:
			var cid: int = _bld_city_id[bi]
			touched_cities[cid] = true
			var dmg: float = 1000.0 if bad else (130.0 * clampf(1.0 - sqrt(d2) / r_eff, 0.25, 1.0))
			if not bad and _has_active_dome_near(bpos):
				dmg *= 0.60
			_bld_hp[bi] -= dmg
			_bld_shake[bi] = 1.0
			_has_bld_springs = true
			_spring_cache_dirty = true
			_buildings_dirty = true
			if cid >= 0 and cid < _max_cities and _city_active[cid] != 0:
				_city_damaged_blds[cid] = 1
				_city_alerted[cid] = 1
				_city_alert_timer[cid] = 5.0
				_city_threat_pos[cid] = world_pos
			if _bld_hp[bi] <= 0.0:
				if _bld_type[bi] == BuildingType.FUSION_REACTOR:
					meltdowns.append(bpos)
					melt_cids.append(cid)
				_remove_building(bi)
		bi -= 1
	for mi in range(meltdowns.size()):
		_trigger_reactor_meltdown(meltdowns[mi], melt_cids[mi])


func _unclaim_damaged_zones_in_radius(world_pos: Vector2, r_eff: float, touched_cities: Dictionary) -> void:
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
			var fid: int = int(_city_faction[clampi(owner, 0, _max_cities - 1)])
			if zc.distance_squared_to(world_pos) <= core_r2 or not _territory.is_zone_walkable(self, Vector2i(zx, zy), fid):
				_zone_city_id[zidx] = -1
				_zone_faction_id[zidx] = 255
				_zone_flags[zidx] = 0
				_zone_farm_growth[zidx] = 0.0
				_city_zones_count[owner] = maxi(0, _city_zones_count[owner] - 1)
				_city_farm_scan_cd[owner] = 0.0
				touched_cities[owner] = true
				_goals_dirty = true
			elif (_zone_flags[zidx] & ZONE_FLAG_FARM) != 0:
				_city_farm_scan_cd[owner] = 0.0
			_territory.mark_zone_dirty(self, zx, zy)
	for k in touched_cities.keys():
		_territory.smooth_enclaves_for_city(self, int(k))


func _collapse_city(cid: int) -> void:
	var c_center: Vector2 = _city_center[cid]
	var f_id: int = int(_city_faction[cid])
	var c_name: String = _city_name[cid]
	var c_col: Color = _get_city_border_color(cid)
	var ruin_ore: float = clampf(16.0 + _city_ore[cid] * 0.45, 16.0, 50.0)
	var ruin_sci: float = clampf(12.0 + _city_science[cid] * 0.15 + float(_city_tech_tier[cid]) * 8.0, 12.0, 45.0)
	var cpx: int = clampi(int(floor(c_center.x)), 0, _map_w - 1)
	var cpy: int = clampi(int(floor(c_center.y)), 0, _map_h - 1)
	if _world == null or int(_world.get_tier(cpx, cpy)) > TIER_CLOSE_OCEAN:
		_spawn_ruin(c_center, ruin_ore, ruin_sci, f_id)

	_diplomacy.on_city_collapsed(self, cid)
	_diplomacy.push_chronicle("Пал город %s" % c_name, c_center, c_col)
	_clear_collapsed_city_state(cid)
	_clear_collapsed_city_entities(cid)
	if _physics != null:
		if _physics.has_method("release_city_units"):
			_physics.release_city_units(cid)
		if _physics.has_method("trigger_impulse"):
			_physics.call("trigger_impulse", c_center, 30.0, 42.0, false)


func _clear_collapsed_city_state(cid: int) -> void:
	_city_active[cid] = 0
	_city_zones_count[cid] = 0
	_city_pop[cid] = 0
	_city_alerted[cid] = 0
	_city_alert_timer[cid] = 0.0
	_city_proj_type[cid] = -1
	_city_proj_retry[cid] = 0.0
	_city_tech_dirty[cid] = 0
	_city_damaged_blds[cid] = 0
	_city_farm_count[cid] = 0
	_city_farm_scan_cd[cid] = 0.0
	_city_coastal_cache[cid] = 0
	_city_loyalty[cid] = 100.0
	_city_is_rebel[cid] = 0
	_city_war_state[cid] = Diplomacy.NEUTRAL
	_city_emp_timer[cid] = 0.0
	_city_war_cooldown[cid] = 0.0
	_city_overlord[cid] = -1
	_city_tech_floor[cid] = 0
	_city_age_sec[cid] = 0.0
	_city_energy_spend_acc[cid] = 0.0
	_city_energy_net[cid] = 0.0
	_city_credits[cid] = 0.0
	_city_hq_level[cid] = 0
	_diplo_dirty_seq += 1
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


func _clear_collapsed_city_entities(cid: int) -> void:
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
				_zone_farm_growth[zidx] = 0.0
				_zone_capture_cid[zidx] = -1
				_zone_capture_timer[zidx] = 0.0
				_territory.mark_zone_dirty(self, zx, zy)


func _refresh_goal_buffers() -> void:
	if _goals_dirty or _goal_buffers.is_empty():
		var init_empty: bool = _goal_buffers.is_empty()
		_goal_version += 1
		_goal_buffers["city_active"] = _city_active
		_goal_buffers["city_faction"] = _city_faction
		_goal_buffers["city_kingdom_id"] = _city_kingdom_id
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
		_goal_buffers["zone_flags"] = _zone_flags
		_goal_buffers["zone_w"] = _zone_w
		_goal_buffers["zone_h"] = _zone_h
		if init_empty or _road_mask_dirty or (_sim_tick_idx & 15) == 0:
			_goal_buffers["road_mask"] = _road_mask
			_road_mask_dirty = false
		_goal_buffers["bld_count"] = _bld_count
		_goal_buffers["bld_pos"] = _bld_pos
		_goal_buffers["bld_radius"] = _bld_radius
		_goal_buffers["bld_type"] = _bld_type
		_goal_buffers["bld_dirty"] = _bld_footprints_dirty
		_goal_buffers["bld_removed"] = _bld_removed_dirty
		_goal_buffers["bld_upg_idx"] = _bld_upg_idx
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
		_light_goals_dirty = false


func _push_goal_buffers() -> void:
	if not _goals_dirty and _light_goals_dirty and not _goal_buffers.is_empty():
		if _physics_has_sync_light_goals and _physics != null:
			_physics.sync_light_goals(self)
			_light_goals_dirty = false
			return
		_goals_dirty = true
	_refresh_goal_buffers()
	if not _physics_has_set_goal_buffers or _physics == null:
		return
	if _pushed_goal_version == _goal_version and _last_pushed_physics == _physics:
		return
	_physics.set_goal_buffers(_goal_buffers)
	_pushed_goal_version = _goal_version
	_last_pushed_physics = _physics
	_bld_footprints_dirty = false
	_bld_removed_dirty = false
	_bld_upg_idx = -1
	_goal_buffers["bld_dirty"] = false
	_goal_buffers["bld_removed"] = false
	_goal_buffers["bld_upg_idx"] = -1
	_light_goals_dirty = false


func get_goal_buffers() -> Dictionary:
	_ensure_initialized()
	_refresh_goal_buffers()
	return _goal_buffers


func get_goal_version() -> int:
	return _goal_version


func get_building_footprints() -> Dictionary:
	_ensure_initialized()
	return {"count": _bld_count, "pos": _bld_pos, "radius": _bld_radius, "type": _bld_type}


func get_primary_city_pos() -> Vector2:
	var stats: Dictionary = get_civ_stats()
	var pos_v: Variant = stats.get("primary_city_pos", Vector2(float(_map_w) * 0.5, float(_map_h) * 0.5))
	return pos_v as Vector2 if pos_v is Vector2 else Vector2(float(_map_w) * 0.5, float(_map_h) * 0.5)


func try_intercept_orbital_impact(world_pos: Vector2, impact_radius: float) -> Dictionary:
	_ensure_initialized()
	var shield_r: float = _k_shield_r
	var eff_r: float = shield_r + maxf(0.0, impact_radius) * _k_shield_impact_mul
	var eff_r2: float = eff_r * eff_r
	var min_charge: float = _k_shield_min_ch
	var best_i: int = -1
	var best_d2: float = eff_r2 + 0.001
	for i in range(_bld_count):
		if _bld_type[i] == BuildingType.SHIELD_PYLON and _bld_hp[i] > 0.0 and _bld_shield_charge[i] >= min_charge:
			var d2: float = _bld_pos[i].distance_squared_to(world_pos)
			if d2 <= eff_r2 and d2 < best_d2:
				best_d2 = d2
				best_i = i
	if best_i < 0:
		return {"intercepted": false}
	_bld_shield_charge[best_i] = maxf(0.0, _bld_shield_charge[best_i] - _k_shield_cost)
	_bld_shield_flash[best_i] = 1.0
	_bld_spring[best_i] = 1.24
	_bld_spring_vel[best_i] = 2.5
	_has_bld_springs = true
	_spring_cache_dirty = true
	_shield_blocked_total += 1
	_buildings_dirty = true
	var ppos: Vector2 = _bld_pos[best_i]
	if _physics != null and _physics.has_method("notify_shield_saved"):
		_physics.call("notify_shield_saved", ppos, shield_r)
	if _fx != null and _fx_has_spawn_burst:
		_fx.spawn_burst(ppos, 10, Color(0.42, 0.92, 1.45, 1.0), 30.0, 0.40, 12.0)
	return {"intercepted": true, "pylon_pos": ppos, "city_id": int(_bld_city_id[best_i]), "radius": shield_r, "charge_left": _bld_shield_charge[best_i]}


func get_shield_pylons() -> Array[Dictionary]:
	_ensure_initialized()
	var out: Array[Dictionary] = []
	var shield_r: float = _k_shield_r
	for i in range(_bld_count):
		if _bld_type[i] != BuildingType.SHIELD_PYLON:
			continue
		var cid: int = clampi(int(_bld_city_id[i]), 0, _max_cities - 1)
		out.append({"pos": _bld_pos[i], "radius": shield_r, "charge": _bld_shield_charge[i], "flash": _bld_shield_flash[i], "faction": int(_city_faction[cid]), "city_id": cid})
	return out


func set_zoom_lod(zoom_val: float) -> void:
	_zoom_val = zoom_val
	if _territory != null:
		var new_ta: int = _territory.compute_zoom_tint_alpha(zoom_val)
		var new_thick: int = 1 if zoom_val <= 2.4 else 0
		if abs(new_ta - _border_tint_alpha_cache) >= 2 or new_thick != _border_thick_cache:
			_border_tint_alpha_cache = new_ta
			_border_thick_cache = new_thick
			_territory.mark_all_borders_dirty(self)
			_territory.flush_dirty_borders(self)


func get_city_hunger_pressure(cid: int) -> float:
	if cid < 0 or cid >= _max_cities or _city_active[cid] == 0 or int(_city_faction[cid]) == Faction.ROBOT:
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
		var pos: Vector2 = _bld_pos[i]
		var b_cid: int = clampi(_bld_city_id[i], 0, _max_cities - 1)
		var is_robot: bool = int(_city_faction[b_cid]) == Faction.ROBOT
		match int(_bld_type[i]):
			BuildingType.CAMPFIRE:
				fx.push_light(pos + Vector2(0.0, -2.0), 22.0, Color(0.45, 0.85, 1.0, 1.0) if is_robot else Color(1.0, 0.58, 0.22, 1.0), 0.72)
			BuildingType.TENT:
				fx.push_light(pos + Vector2(0.0, -2.0), 15.0, Color(0.48, 0.82, 1.0, 1.0) if is_robot else Color(1.0, 0.78, 0.40, 1.0), 0.45)
			BuildingType.DRILL:
				fx.push_light(pos + Vector2(0.0, -3.0), 18.0, Color(0.42, 0.86, 1.0, 1.0) if is_robot else Color(1.0, 0.64, 0.28, 1.0), 0.52)
			BuildingType.DEPOT:
				fx.push_light(pos + Vector2(0.0, -3.0), 17.0, Color(0.52, 0.90, 1.0, 1.0), 0.46)
			BuildingType.BIODOME:
				fx.push_light(pos + Vector2(0.0, -4.0), 28.0, Color(0.28, 0.95, 0.62, 1.0), 0.65)
			BuildingType.FUSION_REACTOR:
				fx.push_light(pos + Vector2(0.0, -5.0), 34.0, Color(0.32, 0.85, 1.0, 1.0), 0.88)
			BuildingType.SHIELD_PYLON:
				var ch_l: float = clampf(_bld_shield_charge[i], 0.2, 1.0)
				var fl_l: float = _bld_shield_flash[i]
				fx.push_light(pos + Vector2(0.0, -6.0), 38.0 + fl_l * 14.0, Color(0.30, 0.88, 1.0, 1.0), 0.55 + ch_l * 0.35 + fl_l * 0.45)
			BuildingType.LAUNCHPAD:
				var t5_on: bool = int(_city_tech_tier[b_cid]) >= 5
				fx.push_light(pos + Vector2(0.0, -3.0), 34.0 if t5_on else 26.0, Color(1.0, 0.72, 0.32, 1.0), 0.92 if t5_on else 0.68)
			BuildingType.QUANTUM_GATE:
				if _city_emp_timer[b_cid] <= 0.0 and _city_energy[b_cid] >= 2.0:
					fx.push_light(pos + Vector2(0.0, -5.0), 42.0, Color(0.75, 0.45, 1.0, 1.0), 0.92)
			BuildingType.DOCK:
				fx.push_light(pos + Vector2(0.0, -4.0), 22.0, Color(0.35, 0.85, 1.0, 1.0), 0.52)
			BuildingType.DEFENSE_TURRET:
				fx.push_light(pos + Vector2(0.0, -4.0), 20.0, Color(1.0, 0.36, 0.28, 1.0), 0.58)
			BuildingType.TRADE_HUB:
				fx.push_light(pos + Vector2(0.0, -4.0), 24.0, Color(1.0, 0.82, 0.32, 1.0), 0.58)
			BuildingType.ARCHIVE:
				fx.push_light(pos + Vector2(0.0, -4.0), 26.0, Color(0.42, 0.82, 1.0, 1.0), 0.62)
			BuildingType.MONOLITH:
				fx.push_light(pos + Vector2(0.0, -6.0), 40.0, Color(0.84, 0.56, 1.0, 1.0), 0.90)
	for ri in range(_ruin_count):
		fx.push_light(_ruin_pos[ri] + Vector2(0.0, -2.0), 14.0, Color(1.0, 0.65, 0.25, 1.0), 0.42)
	for si in range(_shuttle_count):
		var s_col := Color(0.42, 0.95, 0.68, 1.0) if int(_shuttle_kind[si]) == SHUTTLE_KIND_SUPPLY else Color(1.0, 0.74, 0.34, 1.0)
		fx.push_light(_shuttle_pos[si], 24.0, s_col, 0.85)


func get_macro_badges() -> Array[Dictionary]:
	_ensure_initialized()
	return _diplomacy.get_macro_badges(self)


func get_active_plots() -> Array[Dictionary]:
	_ensure_initialized()
	return _diplomacy.get_active_plots(self)


func get_army_orders() -> Dictionary:
	_ensure_initialized()
	return _diplomacy.get_army_orders(self)


func pop_chronicle_events() -> Array[Dictionary]:
	_ensure_initialized()
	return _diplomacy.pop_chronicle_events()


func are_all_cities_contiguous() -> bool:
	_ensure_initialized()
	return _territory.are_all_cities_contiguous(self)


func start_test_plot(kind: int = 0) -> bool:
	_ensure_initialized()
	return _diplomacy.start_test_plot(self, kind)


func get_active_plot_count() -> int:
	_ensure_initialized()
	return _diplomacy.get_active_plot_count()


func on_unit_killed(victim_uid: int, killer_uid: int, pos: Vector2) -> void:
	_ensure_initialized()
	_diplomacy.on_unit_killed(self, Vector2i(victim_uid, killer_uid), pos)


func try_avatar_gesture(uid: int, world_pos: Vector2) -> int:
	_ensure_initialized()
	return _diplomacy.try_avatar_gesture(self, uid, world_pos)


func get_notables_summary() -> Array[Dictionary]:
	_ensure_initialized()
	return _diplomacy.get_notables_summary()


func pin_notable(uid: int, pinned: bool) -> bool:
	_ensure_initialized()
	return _diplomacy.pin_notable(uid, pinned)


func get_notable_card(uid: int) -> Dictionary:
	_ensure_initialized()
	return _diplomacy.get_notable_card(uid)


func inspect_city_at(world_pos: Vector2) -> Dictionary:
	_ensure_initialized()
	var cid: int = _find_city_for_inspect(world_pos)
	if cid < 0:
		for ri in range(_ruin_count):
			if _ruin_pos[ri].distance_squared_to(world_pos) <= 484.0:
				return {"found": false, "ruin_found": true, "ruin_pos": _ruin_pos[ri], "ruin_ore": snappedf(_ruin_ore[ri], 0.1), "ruin_science": snappedf(_ruin_sci[ri], 0.1)}
		return {"found": false}
	return _build_city_inspect_dict(cid)


func _find_city_for_inspect(world_pos: Vector2) -> int:
	var cid: int = get_zone_owner_at(world_pos)
	if cid >= 0 and _city_active[cid] != 0:
		return cid
	var best_d2: float = 40.0 * 40.0
	var best_cid: int = -1
	for i in range(_max_cities):
		if _city_active[i] != 0:
			var d2: float = _city_center[i].distance_squared_to(world_pos)
			if d2 <= best_d2:
				best_d2 = d2
				best_cid = i
	return best_cid


func _build_city_inspect_dict(cid: int) -> Dictionary:
	var f_id: int = clampi(int(_city_faction[cid]), 0, FACTION_NAMES.size() - 1)
	var base_b: int = cid * BLD_TYPE_COUNT
	var total_b: int = 0
	var b_counts: Dictionary = {}
	for bt in range(BLD_TYPE_COUNT):
		var n: int = _city_bld_counts[base_b + bt]
		total_b += n
		if n > 0:
			b_counts[BUILDING_NAMES[bt]] = n

	var partners := _count_city_partners(cid)
	var ptype: int = _city_proj_type[cid]
	var proj_name: String = BUILDING_NAMES[ptype] if (ptype >= 0 and ptype < BUILDING_NAMES.size()) else "None"
	var kid: int = _city_kingdom_id[cid]
	var k_name: String = _kingdom_name[kid] if (kid >= 0 and kid < _max_cities and _kingdom_active[kid] != 0) else _city_name[cid]
	var is_cap: bool = (kid >= 0 and kid < _max_cities and _kingdom_capital_cid[kid] == cid)
	var farms_n: int = _count_city_farms(cid)

	return {
		"found": true,
		"city_id": cid,
		"kingdom_id": kid,
		"kingdom_name": k_name,
		"is_capital": is_cap,
		"name": _city_name[cid],
		"center": _city_center[cid],
		"faction": f_id,
		"faction_name": FACTION_NAMES[f_id],
		"tech": int(_city_tech_tier[cid]),
		"tech_tier": int(_city_tech_tier[cid]),
		"pop": _city_pop[cid],
		"housing_cap": _city_housing_cap(cid),
		"zones_owned": _city_zones_count[cid],
		"farms": farms_n,
		"food": snappedf(_city_food[cid], 0.1),
		"wood": snappedf(_city_wood[cid], 0.1),
		"ore": snappedf(_city_ore[cid], 0.1),
		"energy": snappedf(_city_energy[cid], 0.1),
		"energy_net": snappedf(_city_energy_net[cid], 0.1),
		"science": snappedf(_city_science[cid], 0.1),
		"credits": snappedf(_city_credits[cid], 0.1),
		"hq_level": int(_city_hq_level[cid]),
		"storage_cap": _city_storage_cap[cid],
		"buildings": total_b,
		"buildings_by_type": b_counts,
		"tents": _city_bld_counts[base_b + BuildingType.TENT],
		"biodomes": _city_bld_counts[base_b + BuildingType.BIODOME],
		"shield_pylons": _city_bld_counts[base_b + BuildingType.SHIELD_PYLON],
		"has_shield": _city_bld_counts[base_b + BuildingType.SHIELD_PYLON] > 0,
		"quantum_gates": _city_bld_counts[base_b + BuildingType.QUANTUM_GATE],
		"docks": _city_bld_counts[base_b + BuildingType.DOCK],
		"barracks": _city_bld_counts[base_b + BuildingType.BARRACKS],
		"turrets": _city_bld_counts[base_b + BuildingType.DEFENSE_TURRET],
		"trade_hubs": _city_bld_counts[base_b + BuildingType.TRADE_HUB],
		"archives": _city_bld_counts[base_b + BuildingType.ARCHIVE],
		"monoliths": _city_bld_counts[base_b + BuildingType.MONOLITH],
		"culture_id": _meta.get_city_culture_id(cid) if _meta != null else -1,
		"culture_name": _meta.get_city_culture_name(cid) if _meta != null else "",
		"creed_name": _meta.get_city_creed_name(cid) if _meta != null else "",
		"ships": _meta.get_city_ship_count(cid) if _meta != null else 0,
		"army": _meta.get_city_army_info(cid) if _meta != null else {},
		"codices_count": _meta.get_city_book_count(cid) if _meta != null else 0,
		"project": proj_name,
		"project_progress": snappedf(_city_proj_prog[cid], 0.01),
		"alerted": _city_alerted[cid] != 0,
		"loyalty": snappedf(_city_loyalty[cid], 0.1),
		"loyalty_reason": _city_loyalty_reason(cid),
		"is_rebel": _city_is_rebel[cid] != 0,
		"war_state": int(_city_war_state[cid]),
		"war_partners": partners.x,
		"pact_partners": partners.y,
		"rebel_partners": partners.z,
		"emp_timer": snappedf(_city_emp_timer[cid], 0.1),
		"city_age": snappedf(_city_age_sec[cid], 0.1),
		"dirt_roads": _road_dirt_count,
		"conduit_roads": _road_conduit_count,
		"state": _city_state_string(cid, f_id, ptype),
		"shuttles_launched": _city_shuttles_launched[cid],
	}


func _count_city_partners(cid: int) -> Vector3i:
	var wars: int = 0
	var pacts: int = 0
	var rebs: int = 0
	var row_off: int = cid * _max_cities
	for other in range(_max_cities):
		if other == cid or _city_active[other] == 0:
			continue
		var st_o: int = int(_diplo_matrix[row_off + other])
		if st_o == Diplomacy.PACT:
			pacts += 1
		elif st_o == Diplomacy.TOTAL_WAR:
			wars += 1
		elif st_o == Diplomacy.REBELLION:
			wars += 1
			rebs += 1
	return Vector3i(wars, pacts, rebs)


func _count_city_farms(cid: int) -> int:
	var n: int = 0
	for z in range(_zone_count):
		if _zone_city_id[z] == cid and (_zone_flags[z] & ZONE_FLAG_FARM) != 0:
			n += 1
	return n


func _city_loyalty_reason(cid: int) -> String:
	if _city_is_rebel[cid] != 0:
		return "Мятеж"
	if _city_emp_timer[cid] > 0.0:
		return "ЭМИ"
	if get_city_hunger_pressure(cid) > 0.45:
		return "Голод"
	var ov: int = _city_overlord[cid]
	if ov >= 0 and ov < _max_cities and _city_active[ov] != 0 and _city_center[cid].distance_to(_city_center[ov]) > _k_rebel_cap_dist:
		return "Дальн."
	return "Стресс" if _city_loyalty[cid] < 99.5 else ""


func _city_state_string(cid: int, f_id: int, ptype: int) -> String:
	if _city_is_rebel[cid] != 0:
		return "Rebellion"
	if int(_city_war_state[cid]) == Diplomacy.TOTAL_WAR:
		return "Total War"
	if _city_emp_timer[cid] > 0.0:
		return "EMP Glitch"
	if _city_alerted[cid] != 0:
		return "Alerted"
	if f_id != Faction.ROBOT and _city_food[cid] <= 0.1 and _city_pop[cid] > 4:
		return "Starving"
	return "Constructing" if ptype >= 0 else "Thriving"


func _accum_civ_stats_cities() -> Dictionary:
	var active_cities: int = 0
	var active_kingdoms: int = 0
	var child_cities: int = 0
	var owned_zones: int = 0
	var max_tier: int = 0
	var total_food: float = 0.0
	var total_wood: float = 0.0
	var total_ore: float = 0.0
	var total_energy: float = 0.0
	var total_science: float = 0.0
	var total_credits: float = 0.0
	var total_pop: int = 0
	var total_tents: int = 0
	var total_biodomes: int = 0
	var active_scaffolds: int = 0
	var alerted_cities: int = 0
	var shield_pylons_n: int = 0
	var quantum_gates_n: int = 0
	var rebellions_active_n: int = 0
	var emp_cities_n: int = 0
	var primary_id: int = -1
	var primary_score: float = -1.0
	var primary_pos := Vector2(float(_map_w) * 0.5, float(_map_h) * 0.5)

	for kid in range(_max_cities):
		if _kingdom_active[kid] != 0:
			active_kingdoms += 1

	for cid in range(_max_cities):
		if _city_active[cid] == 0:
			continue
		active_cities += 1
		if _city_overlord[cid] >= 0:
			child_cities += 1
		owned_zones += _city_zones_count[cid]
		if _city_proj_type[cid] >= 0:
			active_scaffolds += 1
		if _city_alerted[cid] != 0:
			alerted_cities += 1
		if _city_is_rebel[cid] != 0:
			rebellions_active_n += 1
		if _city_emp_timer[cid] > 0.0:
			emp_cities_n += 1
		var base_b: int = cid * BLD_TYPE_COUNT
		total_tents += _city_bld_counts[base_b + BuildingType.TENT]
		total_biodomes += _city_bld_counts[base_b + BuildingType.BIODOME]
		shield_pylons_n += _city_bld_counts[base_b + BuildingType.SHIELD_PYLON]
		quantum_gates_n += _city_bld_counts[base_b + BuildingType.QUANTUM_GATE]
		var t: int = int(_city_tech_tier[cid])
		max_tier = maxi(max_tier, t)
		total_food += _city_food[cid]
		total_wood += _city_wood[cid]
		total_ore += _city_ore[cid]
		total_energy += _city_energy[cid]
		total_science += _city_science[cid]
		total_credits += _city_credits[cid]
		total_pop += _city_pop[cid]
		var rank: float = float(_city_zones_count[cid]) * 10.0 + float(t) * 50.0 + float(_city_pop[cid])
		if rank > primary_score:
			primary_score = rank
			primary_id = cid
			primary_pos = _city_center[cid]

	return {
		"cities": active_cities, "kingdoms": active_kingdoms, "child_cities": child_cities,
		"zones_owned": owned_zones, "max_tier": max_tier, "food": total_food, "wood": total_wood,
		"ore": total_ore, "energy": total_energy, "science": total_science, "credits": total_credits, "pop": total_pop,
		"tents": total_tents, "biodomes": total_biodomes, "scaffolds": active_scaffolds,
		"alerted": alerted_cities, "pylons": shield_pylons_n, "gates": quantum_gates_n,
		"rebels": rebellions_active_n, "emps": emp_cities_n, "primary_id": primary_id, "primary_pos": primary_pos,
	}


func get_civ_stats() -> Dictionary:
	_ensure_initialized()
	var cs: Dictionary = _accum_civ_stats_cities()
	var dp_counts: Vector2i = _count_active_diplo_pairs()
	var farms_n: int = 0
	for z in range(_zone_count):
		if (_zone_flags[z] & ZONE_FLAG_FARM) != 0:
			farms_n += 1
	var max_tier: int = int(cs["max_tier"])
	var total_food: float = float(cs["food"])
	var total_wood: float = float(cs["wood"])
	var total_ore: float = float(cs["ore"])
	var total_energy: float = float(cs["energy"])
	var total_science: float = float(cs["science"])
	return {
		"cities": int(cs["cities"]),
		"kingdoms": int(cs["kingdoms"]),
		"child_cities": int(cs["child_cities"]),
		"zones_owned": int(cs["zones_owned"]),
		"farms": farms_n,
		"buildings": _bld_count,
		"tents": int(cs["tents"]),
		"biodomes": int(cs["biodomes"]),
		"scaffolds": int(cs["scaffolds"]),
		"ruins": _ruin_count,
		"shuttles": _shuttle_count,
		"shuttles_launched": _total_shuttles_launched,
		"shuttles_total": _total_shuttles_launched,
		"shield_pylons": int(cs["pylons"]),
		"shield_blocked": _shield_blocked_total,
		"quantum_gates": int(cs["gates"]),
		"supply_deliveries": _supply_deliveries,
		"clashes": _border_clash_count,
		"alerted_cities": int(cs["alerted"]),
		"wars_active": dp_counts.x,
		"pacts_active": dp_counts.y,
		"rebellions_active": int(cs["rebels"]),
		"rebellions_total": _rebellions_total,
		"emp_cities": int(cs["emps"]),
		"tech_tier": max_tier,
		"max_tech_tier": max_tier,
		"storage_total": total_food + total_wood + total_ore + total_energy + total_science,
		"food": total_food,
		"wood": total_wood,
		"ore": total_ore,
		"energy": total_energy,
		"science": total_science,
		"harvested_total": _total_harvested,
		"population": int(cs["pop"]),
		"roads": _road_px_count,
		"dirt_roads": _road_dirt_count,
		"conduit_roads": _road_conduit_count,
		"roads_dirt": _road_dirt_count,
		"roads_conduit": _road_conduit_count,
		"ecology_events_sent": _ecology_events_sent_total,
		"active_plots": _diplomacy.get_active_plot_count(),
		"notables_count": _diplomacy.get_notables_count(),
		"relics_count": _diplomacy.get_relics_count(),
		"feuds_count": _diplomacy.get_feuds_count(),
		"tier5_victories": _tier5_victories,
		"credits": float(cs["credits"]),
		"ships": _meta.get_ship_count() if _meta != null else 0,
		"wars_meta": _meta.get_active_war_count() if _meta != null else 0,
		"alliances": _meta.get_active_alliance_count() if _meta != null else 0,
		"cultures": _meta.get_active_culture_count() if _meta != null else 0,
		"creeds": _meta.get_active_creed_count() if _meta != null else 0,
		"clans": _meta.get_active_clan_count() if _meta != null else 0,
		"books": _meta.get_active_book_count() if _meta != null else 0,
		"deaths_total": _meta._world_deaths_total if _meta != null else 0,
		"map_lens": _territory.get_map_lens() if _territory != null else 0,
		"primary_city_id": int(cs["primary_id"]),
		"primary_city_pos": cs["primary_pos"],
	}


func set_map_lens(lens_id: int) -> void:
	_ensure_initialized()
	if _territory != null:
		_territory.set_map_lens(self, lens_id)


func get_map_lens() -> int:
	_ensure_initialized()
	return _territory.get_map_lens() if _territory != null else 0


func get_ship_count() -> int:
	_ensure_initialized()
	return _meta.get_ship_count() if _meta != null else 0


func request_troop_ferry(city_id: int, dst_pos: Vector2) -> bool:
	_ensure_initialized()
	return _meta.request_troop_ferry(self, city_id, dst_pos) if _meta != null else false


func get_wars_summary() -> Array[Dictionary]:
	_ensure_initialized()
	return _meta.get_wars_summary(self) if _meta != null else []


func get_alliances_summary() -> Array[Dictionary]:
	_ensure_initialized()
	return _meta.get_alliances_summary(self) if _meta != null else []


func get_cultures_summary() -> Array[Dictionary]:
	_ensure_initialized()
	return _meta.get_cultures_summary(self) if _meta != null else []


func get_ships_summary() -> Array[Dictionary]:
	_ensure_initialized()
	return _meta.get_ships_summary() if _meta != null else []


func get_clans_summary() -> Array[Dictionary]:
	_ensure_initialized()
	return _meta.get_clans_summary() if _meta != null else []


func get_codices_summary(city_id: int = -1) -> Array[Dictionary]:
	_ensure_initialized()
	return _meta.get_codices_summary(city_id) if _meta != null else []


func get_history_series(scale_id: int, metric_key: String) -> PackedFloat32Array:
	_ensure_initialized()
	return _meta.get_history_series(scale_id, metric_key) if _meta != null else PackedFloat32Array()


func get_kingdom_history_series(kingdom_id: int, scale_id: int, metric_key: String) -> PackedFloat32Array:
	_ensure_initialized()
	return _meta.get_kingdom_history_series(kingdom_id, scale_id, metric_key) if _meta != null else PackedFloat32Array()


func force_diplomatic_plot(plot_type: int, src_cid: int, dst_cid: int) -> bool:
	_ensure_initialized()
	return _diplomacy.force_diplomatic_plot(self, plot_type, Vector2i(src_cid, dst_cid))


func get_diplomacy_factors(city_a: int, city_b: int) -> Dictionary:
	_ensure_initialized()
	return _meta.calc_diplomacy_factors(self, city_a, city_b) if _meta != null else {"found": false}


func get_city_roster() -> Array[Dictionary]:
	_ensure_initialized()
	var out: Array[Dictionary] = []
	for cid in range(_max_cities):
		if _city_active[cid] != 0:
			out.append(_build_city_inspect_dict(cid))
	return out


func get_kingdom_roster() -> Array[Dictionary]:
	_ensure_initialized()
	var badges: Array[Dictionary] = _diplomacy.get_macro_badges(self)
	for i in range(badges.size()):
		var d: Dictionary = badges[i]
		var kid: int = int(d.get("kingdom_id", -1))
		if kid >= 0 and _meta != null:
			var md: Dictionary = _meta.get_kingdom_meta_info(kid)
			for mk in md:
				d[mk] = md[mk]
		var res: Dictionary = _accum_kingdom_resources(kid)
		for rk in res:
			d[rk] = res[rk]
		badges[i] = d
	return badges


func _accum_kingdom_resources(kid: int) -> Dictionary:
	var f_sum: float = 0.0
	var w_sum: float = 0.0
	var o_sum: float = 0.0
	var e_sum: float = 0.0
	var s_sum: float = 0.0
	var c_sum: float = 0.0
	var z_sum: int = 0
	var ships_n: int = 0
	var city_ids: Array[int] = []
	for cid in range(_max_cities):
		if _city_active[cid] != 0 and _city_kingdom_id[cid] == kid:
			city_ids.append(cid)
			f_sum += _city_food[cid]
			w_sum += _city_wood[cid]
			o_sum += _city_ore[cid]
			e_sum += _city_energy[cid]
			s_sum += _city_science[cid]
			c_sum += _city_credits[cid]
			z_sum += _city_zones_count[cid]
			if _meta != null:
				ships_n += _meta.get_city_ship_count(cid)
	return {
		"food": snappedf(f_sum, 0.1), "wood": snappedf(w_sum, 0.1), "ore": snappedf(o_sum, 0.1),
		"energy": snappedf(e_sum, 0.1), "science": snappedf(s_sum, 0.1), "credits": snappedf(c_sum, 0.1),
		"zones_owned": z_sum, "ships": ships_n, "city_ids": city_ids,
	}


func _count_active_diplo_pairs() -> Vector2i:
	var wars: int = 0
	var pacts: int = 0
	for a in range(_max_cities):
		if _city_active[a] == 0:
			continue
		for b in range(a + 1, _max_cities):
			if _city_active[b] == 0:
				continue
			var st: int = int(_diplo_matrix[a * _max_cities + b])
			if st == Diplomacy.PACT:
				pacts += 1
			elif st == Diplomacy.TOTAL_WAR or st == Diplomacy.REBELLION:
				wars += 1
	return Vector2i(wars, pacts)


func get_diplomacy(city_a: int, city_b: int) -> int:
	_ensure_initialized()
	if city_a < 0 or city_a >= _max_cities or city_b < 0 or city_b >= _max_cities or city_a == city_b:
		return Diplomacy.NEUTRAL
	if _city_active[city_a] == 0 or _city_active[city_b] == 0:
		return Diplomacy.NEUTRAL
	return int(_diplo_matrix[city_a * _max_cities + city_b])


func set_diplomacy(city_a: int, city_b: int, state: int) -> void:
	_ensure_initialized()
	_diplomacy.apply_diplomacy_state(self, Vector2i(city_a, city_b), Vector2i(state, 1))
	_push_goal_buffers()


func trigger_diplomacy_spark(world_pos: Vector2, force_mode: int = -1) -> Dictionary:
	_ensure_initialized()
	var pair: Vector2i = _pick_spark_pair(world_pos, force_mode)
	var cid_a: int = pair.x
	var cid_b: int = pair.y
	if cid_a < 0:
		return {"ok": false, "triggered": false, "msg": "Нет колонии рядом", "mode": -1, "state": -1, "city_a": -1, "city_b": -1}

	if force_mode < 0:
		if _city_is_rebel[cid_a] != 0:
			return {"ok": false, "triggered": false, "msg": "%s уже в мятеже" % _city_name[cid_a], "mode": Diplomacy.REBELLION, "state": Diplomacy.REBELLION, "city_a": cid_a, "city_b": cid_b, "rebellion": true, "loyalty": snappedf(_city_loyalty[cid_a], 0.1)}
		_city_loyalty[cid_a] = maxf(0.0, _city_loyalty[cid_a] - 35.0)
		_light_goals_dirty = true

	if force_mode == Diplomacy.REBELLION or (force_mode < 0 and (_city_loyalty[cid_a] < 55.0 or cid_b < 0)):
		_diplomacy.trigger_city_rebellion(self, cid_a, force_mode == Diplomacy.REBELLION)
		if cid_b >= 0 and _city_is_rebel[cid_a] != 0:
			_diplomacy.apply_diplomacy_state(self, Vector2i(cid_a, cid_b), Vector2i(Diplomacy.REBELLION, 1))
		_territory.flush_dirty_borders(self)
		_sync_buildings_multimesh()
		_buildings_dirty = false
		_push_goal_buffers()
		return {"ok": true, "triggered": true, "msg": "Мятеж: %s" % _city_name[cid_a], "mode": Diplomacy.REBELLION, "state": Diplomacy.REBELLION, "city_a": cid_a, "city_b": cid_b, "rebellion": _city_is_rebel[cid_a] != 0, "loyalty": snappedf(_city_loyalty[cid_a], 0.1)}

	if cid_b < 0:
		return {"ok": false, "triggered": false, "msg": "Нет соседа", "mode": force_mode, "state": -1, "city_a": cid_a, "city_b": -1}

	var target_st: int = _resolve_spark_target_state(cid_a, cid_b, force_mode)
	_diplomacy.apply_diplomacy_state(self, Vector2i(cid_a, cid_b), Vector2i(target_st, 1))
	if target_st == Diplomacy.PACT and force_mode == Diplomacy.PACT:
		_city_loyalty[cid_a] = minf(100.0, _city_loyalty[cid_a] + 15.0)
		_city_loyalty[cid_b] = minf(100.0, _city_loyalty[cid_b] + 15.0)
		_light_goals_dirty = true
	if _fx != null and _fx_has_spawn_burst:
		_fx.spawn_burst(world_pos, 12, Color(0.45, 0.95, 0.55, 1.0) if target_st == Diplomacy.PACT else Color(1.0, 0.35, 0.25, 1.0), 24.0, 0.45, -10.0)
	_push_goal_buffers()
	var st_tag: String = "Война" if target_st == Diplomacy.TOTAL_WAR else ("Пакт" if target_st == Diplomacy.PACT else "Нейтр.")
	return {"ok": true, "triggered": true, "msg": "%s (%s · Лоял %d%%)" % [_city_name[cid_a], st_tag, int(round(_city_loyalty[cid_a]))], "mode": target_st, "state": target_st, "city_a": cid_a, "city_b": cid_b, "rebellion": false, "loyalty": snappedf(_city_loyalty[cid_a], 0.1)}


func _pick_spark_pair(world_pos: Vector2, force_mode: int) -> Vector2i:
	var cid_a: int = get_zone_owner_at(world_pos)
	if cid_a < 0 or _city_active[cid_a] == 0:
		cid_a = -1
		var best_d2: float = 1e18
		for cid in range(_max_cities):
			if _city_active[cid] != 0:
				var d2: float = _city_center[cid].distance_squared_to(world_pos)
				if d2 < best_d2:
					best_d2 = d2
					cid_a = cid
		if force_mode < 0 and best_d2 > 140.0 * 140.0:
			cid_a = -1
	var cid_b: int = -1
	if cid_a >= 0:
		var best_b2: float = 1e18
		for cid in range(_max_cities):
			if cid != cid_a and _city_active[cid] != 0:
				var d2: float = _city_center[cid].distance_squared_to(world_pos)
				if d2 < best_b2:
					best_b2 = d2
					cid_b = cid
	return Vector2i(cid_a, cid_b)


func _resolve_spark_target_state(cid_a: int, cid_b: int, force_mode: int) -> int:
	if force_mode >= Diplomacy.NEUTRAL and force_mode <= Diplomacy.REBELLION:
		return force_mode
	var cur_st: int = get_diplomacy(cid_a, cid_b)
	if cur_st == Diplomacy.NEUTRAL or cur_st == Diplomacy.PACT:
		return Diplomacy.TOTAL_WAR
	if cur_st == Diplomacy.TOTAL_WAR:
		var fa: int = int(_city_faction[cid_a])
		var fb: int = int(_city_faction[cid_b])
		return Diplomacy.PACT if (fa == fb or (fa != Faction.SPORE and fb != Faction.SPORE)) else Diplomacy.NEUTRAL
	return Diplomacy.REBELLION


func apply_ai_glitch(world_pos: Vector2, radius: float) -> Dictionary:
	_ensure_initialized()
	var safe_r: float = maxf(12.0, radius)
	var safe_r2: float = safe_r * safe_r
	var hit_map: Dictionary = {}
	var z_cid: int = get_zone_owner_at(world_pos)
	if z_cid >= 0 and z_cid < _max_cities and _city_active[z_cid] != 0:
		hit_map[z_cid] = true
	for cid in range(_max_cities):
		if _city_active[cid] != 0 and _city_center[cid].distance_squared_to(world_pos) <= safe_r2:
			hit_map[cid] = true
	for bi in range(_bld_count):
		if _bld_pos[bi].distance_squared_to(world_pos) <= safe_r2:
			var bcid: int = _bld_city_id[bi]
			if bcid >= 0 and bcid < _max_cities and _city_active[bcid] != 0:
				hit_map[bcid] = true
			_bld_shake[bi] = maxf(_bld_shake[bi], 3.2)
			_has_bld_springs = true
			_spring_cache_dirty = true
			if int(_bld_type[bi]) == BuildingType.SHIELD_PYLON:
				_bld_shield_charge[bi] = maxf(0.0, _bld_shield_charge[bi] - 0.35)

	var emp_dur: float = _k_emp_glitch_dur
	var loy_hit: float = _k_ai_glitch_loy_hit
	var rebel_th: float = _k_rebel_loy_thresh
	var affected_cids: Array[int] = []
	var rebel_count: int = 0
	for k in hit_map.keys():
		var cid: int = int(k)
		affected_cids.append(cid)
		var robot_mul: float = 1.4 if int(_city_faction[cid]) == Faction.ROBOT else 1.0
		_city_emp_timer[cid] = maxf(_city_emp_timer[cid], emp_dur * robot_mul)
		_city_loyalty[cid] = maxf(0.0, _city_loyalty[cid] - loy_hit * robot_mul)
		_city_alerted[cid] = 1
		_city_alert_timer[cid] = maxf(_city_alert_timer[cid], 6.0)
		_light_goals_dirty = true
		if _city_is_rebel[cid] == 0 and _city_loyalty[cid] < rebel_th and _diplomacy.can_city_rebel(self, cid):
			_diplomacy.trigger_city_rebellion(self, cid, false)
			rebel_count += 1

	_buildings_dirty = true
	_territory.flush_dirty_borders(self)
	_sync_buildings_multimesh()
	_buildings_dirty = false
	if _fx != null and _fx_has_spawn_burst:
		_fx.spawn_burst(world_pos, 16, Color(0.35, 0.95, 0.85, 1.0), minf(safe_r, 42.0), 0.55, -12.0)
	_push_goal_buffers()
	return {"affected_cities": affected_cids.size(), "rebellions_triggered": rebel_count, "emp_cities": affected_cids}


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
		out.append({"city_id": cid, "faction": int(_city_faction[cid]), "pos": _bld_pos[i], "active": (not is_emp) and _city_energy[cid] >= 2.0 and _bld_hp[i] > 0.0, "emp": is_emp})
	return out


func consume_city_energy(city_id: int, amount: float) -> bool:
	_ensure_initialized()
	if city_id < 0 or city_id >= _max_cities or _city_active[city_id] == 0 or _city_emp_timer[city_id] > 0.0:
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
			if st != Diplomacy.NEUTRAL:
				out.append({"city_a": a, "city_b": b, "pos_a": _city_center[a], "pos_b": _city_center[b], "state": st})
	return out


func spawn_building_for_test(city_id: int, btype: int) -> Vector2:
	_ensure_initialized()
	if city_id < 0 or city_id >= _max_cities or _city_active[city_id] == 0:
		return Vector2(-1.0, -1.0)
	var bt: int = clampi(btype, 0, BLD_TYPE_COUNT - 1)
	var f_id: int = int(_city_faction[city_id])
	var spot: Vector2 = _find_building_spot(city_id, bt)
	if spot.x < 0.0:
		spot = _find_fallback_test_spot(_city_center[city_id], bt, f_id)
	if spot.x < 0.0:
		return Vector2(-1.0, -1.0)
	_place_building(city_id, bt, spot, true)
	_recompute_city_tech(city_id)
	_refresh_city_targets(city_id)
	_territory.flush_dirty_borders(self)
	_sync_buildings_multimesh()
	_buildings_dirty = false
	_goals_dirty = true
	_bld_footprints_dirty = true
	_push_goal_buffers()
	return spot


func _find_fallback_test_spot(center: Vector2, bt: int, f_id: int) -> Vector2:
	for ring in range(1, 10):
		var rad: float = 10.0 + float(ring) * 6.0
		for k in range(16):
			var ang: float = float(k) * (TAU / 16.0) + float(ring) * 0.25
			var cand: Vector2 = center + Vector2(cos(ang), sin(ang)) * rad
			if _is_building_spot_valid(cand, bt, f_id):
				return cand
	for ring2 in range(1, 12):
		var rad2: float = 8.0 + float(ring2) * 5.0
		for k2 in range(16):
			var ang2: float = float(k2) * (TAU / 16.0)
			var cand2: Vector2 = center + Vector2(cos(ang2), sin(ang2)) * rad2
			var px: int = clampi(int(floor(cand2.x)), 10, _map_w - 11)
			var py: int = clampi(int(floor(cand2.y)), 14, _map_h - 9)
			if _territory.is_pixel_walkable(self, Vector2i(px, py), f_id):
				var clear_ok: bool = true
				for bi in range(_bld_count):
					if _bld_pos[bi].distance_squared_to(cand2) < 64.0:
						clear_ok = false
						break
				if clear_ok:
					return Vector2(float(px), float(py))
	return Vector2(-1.0, -1.0)


func grant_tech_tier_for_test(city_id: int, target_tier: int) -> void:
	_ensure_initialized()
	if city_id < 0 or city_id >= _max_cities or _city_active[city_id] == 0:
		return
	var t: int = clampi(target_tier, 0, 5)
	var prev_t: int = int(_city_tech_tier[city_id])
	_city_tech_floor[city_id] = maxi(int(_city_tech_floor[city_id]), t)
	_city_storage_cap[city_id] = maxf(_city_storage_cap[city_id], 120.0 if t >= 3 else 70.0)
	_city_ore[city_id] = maxf(_city_ore[city_id], 35.0)
	_city_energy[city_id] = maxf(_city_energy[city_id], 45.0 if t >= 4 else 24.0)
	_city_pop[city_id] = maxi(_city_pop[city_id], 10 if t >= 1 else 0)
	var min_ages: Array[float] = [0.0, _k_tier1_age, _k_tier2_age, _k_tier3_age, _k_tier4_age, 1650.0]
	_city_age_sec[city_id] = maxf(_city_age_sec[city_id], min_ages[t] + 5.0)
	var min_sci: Array[float] = [6.0, 36.0, 110.0, _k_tier3_sci + 20.0, _k_tier4_sci + 40.0, 1150.0]
	_city_science[city_id] = maxf(_city_science[city_id], min_sci[t])

	var base_b: int = city_id * BLD_TYPE_COUNT
	if t >= 1 and _city_bld_counts[base_b + BuildingType.DRILL] < 1:
		spawn_building_for_test(city_id, BuildingType.DRILL)
	if t >= 3 and _city_bld_counts[base_b + BuildingType.FUSION_REACTOR] < 1:
		spawn_building_for_test(city_id, BuildingType.FUSION_REACTOR)
	if t >= 4 and _city_bld_counts[base_b + BuildingType.LAUNCHPAD] < 1:
		spawn_building_for_test(city_id, BuildingType.LAUNCHPAD)
	if t >= 5 and _city_bld_counts[base_b + BuildingType.QUANTUM_GATE] < 1:
		spawn_building_for_test(city_id, BuildingType.QUANTUM_GATE)

	_city_tech_tier[city_id] = maxi(prev_t, t)
	_clamp_city_science(city_id)
	_recompute_city_tech(city_id)
	if t >= 2 and prev_t < 2:
		_territory.upgrade_city_roads_to_conduits(self, city_id)
	_territory.flush_dirty_borders(self)
	_sync_buildings_multimesh()
	_buildings_dirty = false
	_light_goals_dirty = true
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
	_pack_zones_and_roads(buf)
	_pack_cities(buf)
	_pack_entities_and_diplo(buf)
	_pack_v6_extensions(buf)
	_pack_v7_extensions(buf)
	return buf.data_array


func _pack_zones_and_roads(buf: StreamPeerBuffer) -> void:
	for z in range(_zone_count):
		buf.put_32(_zone_city_id[z])
		buf.put_u8(_zone_faction_id[z])
		buf.put_u8(_zone_flags[z])
		buf.put_32(_zone_ore[z])
		buf.put_float(_zone_fertility[z])
	buf.put_u32(_road_mask.size())
	buf.put_data(_road_mask)


func _pack_cities(buf: StreamPeerBuffer) -> void:
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


func _pack_entities_and_diplo(buf: StreamPeerBuffer) -> void:
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
	var cap_z := PackedInt32Array()
	for z in range(_zone_count):
		if _zone_capture_cid[z] >= 0 and _zone_capture_timer[z] > 0.0:
			cap_z.append(z)
	buf.put_u16(cap_z.size())
	for k in range(cap_z.size()):
		var zi: int = cap_z[k]
		buf.put_32(zi)
		buf.put_32(_zone_capture_cid[zi])
		buf.put_float(_zone_capture_timer[zi])


func _pack_v6_extensions(buf: StreamPeerBuffer) -> void:
	buf.put_float(_sim_pace_mult)
	buf.put_32(_ecology_events_sent_total)
	for z in range(_zone_count):
		buf.put_float(_zone_farm_growth[z])
	buf.put_u32(_foot_traffic.size())
	buf.put_data(_foot_traffic)
	for c in range(_max_cities):
		buf.put_32(_city_kingdom_id[c])
		buf.put_float(_city_age_sec[c])
		buf.put_float(_city_wood[c])
		buf.put_u8(_kingdom_active[c])
		if _kingdom_active[c] != 0:
			buf.put_u8(_kingdom_faction[c])
			buf.put_32(_kingdom_capital_cid[c])
			buf.put_32(_kingdom_city_count[c])
			buf.put_utf8_string(_kingdom_name[c])
			buf.put_float(_kingdom_color[c].r)
			buf.put_float(_kingdom_color[c].g)
			buf.put_float(_kingdom_color[c].b)
			buf.put_float(_kingdom_color[c].a)
	buf.put_u16(_shuttle_count)
	for s in range(_shuttle_count):
		buf.put_float(_shuttle_cargo_food[s])
		buf.put_float(_shuttle_cargo_ore[s])
		buf.put_float(_shuttle_cargo_energy[s])
	buf.put_32(_tier5_victories)
	buf.put_u16(_max_cities)
	for c in range(_max_cities):
		buf.put_u8(_city_tier5_done[c])
	_diplomacy.pack_social_extensions(buf)


func unpack_state(blob: PackedByteArray) -> bool:
	_ensure_initialized()
	if blob.size() < 24:
		return false
	var buf := StreamPeerBuffer.new()
	buf.data_array = blob
	buf.seek(0)
	if buf.get_32() != SAVE_MAGIC:
		return false
	var ver: int = buf.get_u32()
	if ver < 2 or ver > SAVE_VERSION:
		return false
	if buf.get_u16() != _map_w or buf.get_u16() != _map_h or buf.get_u16() != _zone_w or buf.get_u16() != _zone_h:
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

	if not _unpack_zones_and_roads(buf):
		return false
	var saved_cities: int = _unpack_cities(buf, ver)
	if not _unpack_entities_and_diplo(buf, ver, saved_cities):
		return false
	if ver >= 6:
		_unpack_v6_extensions(buf)
	else:
		_rebuild_legacy_kingdoms()
	if ver >= 7 and buf.get_available_bytes() > 0:
		_unpack_v7_extensions(buf)
	else:
		_hydrate_meta_for_legacy_save()

	_city_proj_retry.fill(0.0)
	_city_tech_dirty.fill(1)
	_goals_dirty = true
	_light_goals_dirty = false
	_diplo_dirty_seq += 1
	_bld_footprints_dirty = true
	_bld_removed_dirty = true
	_bld_upg_idx = -1
	_road_mask_dirty = true
	_buildings_dirty = false
	_bld_anim_step = int(floor(_sim_time * 8.0))
	_last_pushed_physics = null
	_territory._w_cache_owner = null
	_territory._refresh_world_byte_caches(self)
	_territory.mark_all_borders_dirty(self)
	_territory.flush_dirty_borders(self)
	_sync_buildings_multimesh()
	_push_goal_buffers()
	return true


func _unpack_zones_and_roads(buf: StreamPeerBuffer) -> bool:
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
	_territory.recount_roads(self)
	return true


func _unpack_cities(buf: StreamPeerBuffer, ver: int) -> int:
	var saved_cities: int = mini(_max_cities, buf.get_u16())
	for c in range(saved_cities):
		var act: int = buf.get_u8()
		_city_active[c] = act
		if act == 0:
			continue
		var f_id: int = clampi(buf.get_u8(), 0, FACTION_TINT_COLORS.size() - 1)
		_city_faction[c] = f_id
		_city_color[c] = FACTION_TINT_COLORS[f_id]
		_city_name[c] = buf.get_utf8_string() if ver >= 3 else _pick_city_name(f_id, c)
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
		var saved_bt_count: int = 8 if ver < 4 else (9 if ver == 4 else (10 if ver <= 6 else BLD_TYPE_COUNT))
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
		_clamp_city_science(c)
	return saved_cities


func _unpack_entities_and_diplo(buf: StreamPeerBuffer, ver: int, saved_cities: int) -> bool:
	_bld_count = mini(_max_buildings, buf.get_u16())
	for b in range(_bld_count):
		_bld_pos[b] = Vector2(buf.get_float(), buf.get_float())
		var bt_u: int = buf.get_u8()
		_bld_type[b] = bt_u
		_bld_radius[b] = BLD_AVOID_RADII[clampi(bt_u, 0, BLD_TYPE_COUNT - 1)]
		var cid: int = buf.get_32()
		_bld_city_id[b] = cid
		_bld_color[b] = _get_city_tint_color(cid)
		var hp_val: float = buf.get_float()
		_bld_hp[b] = hp_val
		if cid >= 0 and cid < _max_cities and _city_active[cid] != 0 and hp_val < _building_max_hp(bt_u, int(_city_faction[cid])):
			_city_damaged_blds[cid] = 1
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
	_has_bld_springs = _bld_count > 0
	_spring_cache_dirty = _bld_count > 0
	_shield_cache_dirty = true
	if ver >= 3:
		_unpack_ruins_and_shuttles(buf, ver)
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
	return true


func _unpack_ruins_and_shuttles(buf: StreamPeerBuffer, ver: int) -> void:
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


func _unpack_v6_extensions(buf: StreamPeerBuffer) -> void:
	if buf.get_available_bytes() <= 0:
		return
	_sim_pace_mult = clampf(buf.get_float(), 0.05, 120.0)
	_ecology_events_sent_total = buf.get_32()
	for z in range(_zone_count):
		_zone_farm_growth[z] = buf.get_float()
	var ft_sz: int = buf.get_u32()
	if ft_sz == _foot_traffic.size():
		var ft_res: Array = buf.get_data(ft_sz)
		if int(ft_res[0]) == OK:
			_foot_traffic = ft_res[1] as PackedByteArray
	for c in range(_max_cities):
		_city_kingdom_id[c] = buf.get_32()
		_city_age_sec[c] = buf.get_float()
		_city_wood[c] = buf.get_float()
		var ka: int = buf.get_u8()
		_kingdom_active[c] = ka
		if ka != 0:
			_kingdom_faction[c] = buf.get_u8()
			_kingdom_capital_cid[c] = buf.get_32()
			_kingdom_city_count[c] = buf.get_32()
			_kingdom_name[c] = buf.get_utf8_string()
			_kingdom_color[c] = Color(buf.get_float(), buf.get_float(), buf.get_float(), buf.get_float())
	if buf.get_available_bytes() > 0:
		var sc_n: int = buf.get_u16()
		for s in range(sc_n):
			var cf: float = buf.get_float()
			var co: float = buf.get_float()
			var ce: float = buf.get_float()
			if s < _max_shuttles:
				_shuttle_cargo_food[s] = cf
				_shuttle_cargo_ore[s] = co
				_shuttle_cargo_energy[s] = ce
	if buf.get_available_bytes() > 0:
		_tier5_victories = buf.get_32()
		var t5_n: int = buf.get_u16()
		for c in range(t5_n):
			var t5_v: int = buf.get_u8()
			if c < _max_cities:
				_city_tier5_done[c] = t5_v
	if buf.get_available_bytes() > 0:
		_diplomacy.unpack_social_extensions(buf)
	for c in range(_max_cities):
		if _city_active[c] != 0:
			_city_color[c] = _get_city_tint_color(c)
	for b in range(_bld_count):
		_bld_color[b] = _get_city_tint_color(_bld_city_id[b])


func _rebuild_legacy_kingdoms() -> void:
	for c in range(_max_cities):
		if _city_active[c] != 0 and _city_kingdom_id[c] < 0:
			_diplomacy.create_kingdom(self, c, _city_is_rebel[c] != 0)


func _pack_v7_extensions(buf: StreamPeerBuffer) -> void:
	buf.put_u16(_max_cities)
	for c in range(_max_cities):
		buf.put_float(_city_credits[c])
		buf.put_u8(_city_hq_level[c])
	buf.put_u16(_bld_count)
	for b in range(_bld_count):
		buf.put_u8(_bld_level[b])
	buf.put_u8(_territory.get_map_lens() if _territory != null else 0)
	if _meta != null:
		_meta.pack_meta_state(buf)


func _unpack_v7_extensions(buf: StreamPeerBuffer) -> void:
	if buf.get_available_bytes() <= 0:
		return
	var mc: int = buf.get_u16()
	for c in range(mc):
		var cr: float = buf.get_float()
		var hq: int = buf.get_u8()
		if c < _max_cities:
			_city_credits[c] = cr
			_city_hq_level[c] = hq
	var bc: int = buf.get_u16()
	for b in range(bc):
		var lv: int = buf.get_u8()
		if b < _max_buildings:
			_bld_level[b] = lv
	if buf.get_available_bytes() > 0:
		var lens_id: int = buf.get_u8()
		if _territory != null:
			_territory.set_map_lens(self, lens_id)
	if buf.get_available_bytes() > 0 and _meta != null:
		_meta.unpack_meta_state(buf)


func _hydrate_meta_for_legacy_save() -> void:
	if _meta == null:
		return
	for kid in range(_max_cities):
		if _kingdom_active[kid] != 0:
			var cap_cid: int = _kingdom_capital_cid[kid]
			var is_reb: bool = cap_cid >= 0 and _city_is_rebel[cap_cid] != 0
			_meta.on_kingdom_created(self, Vector2i(kid, cap_cid), is_reb)
	for cid in range(_max_cities):
		if _city_active[cid] != 0:
			_meta.on_city_created(self, cid, _city_overlord[cid])
