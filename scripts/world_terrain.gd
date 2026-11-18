extends Node2D
class_name WorldTerrain

## Procedural pixel-art planetary terrain, biome climate, sky drops, disasters, CA & environment simulation.
## Maintains 640x360 flat PackedArrays, dirty-chunk-only GPU texture updates,
## NW-SE faceted relief shading, and an atmospheric drifting cloud/dust layer (z=4).

const WorldDropsScript = preload("res://scripts/world_drops.gd")

const TUNING_KNOBS := {
	"MAP_WIDTH": 640,
	"MAP_HEIGHT": 360,
	"DEFAULT_SEED": 20261114,
	"RIVER_COUNT": 16,
	"VOLCANO_HUB_COUNT": 3,
	"CRYSTAL_POCKET_COUNT": 4,
	"CLOUD_COUNT": 26,
	"CLOUD_SPEED_X": 7.5,
	"CLOUD_SPEED_Y": 2.1,
	"TEMP_AMBIENT_C": 18.0,
	"TEMP_DIFFUSE_RATE": 1.35,
	"TEMP_COOL_RATE": 0.16,
	"TEMP_EQUILIBRIUM_MIN_C": 5.0,
	"TEMP_EQUILIBRIUM_MAX_C": 29.0,
	"TEMP_STEADY_EPS_C": 0.04,
	"CLOUD_RAIN_THRESH": 1.2,
	"WATER_FLOW_TILES_PER_TICK": 48,
	"ICE_FREEZE_TEMP_C": -2.0,
	"ICE_MELT_TEMP_C": 5.0,
	"CO2_HEAT_GAIN_PER_C": 6.5,
	"OCEAN_THERMAL_DAMP_K": 0.22,
	"GLOBAL_HEAT_PENALTY_C": 36.0,
	"VORTEX_ADVECTION_RATE": 0.35,
	"EVAP_RATE": 0.28,
	"RAIN_DEPOSIT": 0.24,
	"ASH_FERTILITY_BOOST": 0.55,
	"LAVA_MIN_TEMP_C": 480.0,
	"LAVA_VENT_FLOOR_C": 790.0,
	"LAVA_SOURCE_TEMP_C": 910.0,
	"RAD_DECAY_RATE": 0.018,
	"RAD_CRYSTAL_FLOOR": 0.42,
	"CRYSTAL_SPREAD_CHANCE": 0.016,
	"LUSH_RECOVER_CHANCE": 0.012,
	"ASH_RECOVER_CHANCE": 0.055,
	"FIRE_IGNITE_TEMP_C": 210.0,
	"FIRE_BURN_DECAY": 0.22,
	"FIRE_SPREAD_CHANCE": 0.42,
	"ACTIVE_CHUNK_BUDGET": 14,
	"DIRTY_FLUSH_INTERVAL": 4,
	"TEMP_AVG_ROWS_PER_TICK": 4,
	"STEAM_COOLDOWN_SEC": 0.25,
	"COSMIC_AGE_DURATION_SEC": 420.0,
	"ION_STORM_STRIKE_INTERVAL_SEC": 4.2,
	"ION_STORM_FIRST_STRIKE_DELAY_SEC": 1.6,
	"PLASMA_SHIMMER_DECAY_PER_SEC": 38.0,
}

enum BrushMode {
	TERRAFORM_LIFE = 0,
	CRYSTAL_FLORA = 1,
	LAVA_VOLCANO = 2,
	METEOR_CRATER = 3,
	VORTEX_PULL = 4,
	LOWER_CANAL = 5,
	ORBITAL_STRIKE = 6,
	WALL_ROCK = 7,
	WALL_ENERGY = 8,
	SPONGE_DRAIN = 9,
	ERASER = 10,
	BIOME_XENO_JUNGLE = 11,
	BIOME_CRYO_TUNDRA = 12,
	BIOME_ACID_WASTE = 13,
	BIOME_SILICA_DUNES = 14,
	BIOME_BIOLUM_OASIS = 15,
	BIOME_CREEP_MYCELIUM = 16,
	BIOME_CREEP_CYBER = 17,
	DROP_RAIN = 18,
	DROP_FIRE = 19,
	DROP_ACID = 20,
	DROP_SNOW = 21,
	PLACE_BOMB = 22,
	PLACE_MINE = 23,
	PLACE_GREY_GOO = 24,
	PLACE_CONWAY = 25,
}

enum BrushShape {
	CIRCLE = 0,
	SQUARE = 1,
	DIAMOND = 2,
	SPRAY = 3,
}

enum MapTemplate {
	CONTINENTS = 0,
	PANGAEA = 1,
	ARCHIPELAGO = 2,
	ATOLL = 3,
	CRATER = 4,
	RIFT = 5,
	TWIN_WORLDS = 6,
	ICE_CROWN = 7,
}

enum DisasterKind {
	VOLCANO_ERUPTION = 0,
	GEYSER_STEAM = 1,
	GEYSER_ACID = 2,
	TORNADO = 3,
	EARTHQUAKE = 4,
	CHAIN_BOMB = 5,
	GREY_GOO = 6,
	CONWAY_LIFE = 7,
	METEOR_SHOWER = 8,
	CREEP_BLOOM = 9,
	ION_LIGHTNING = 10,
	HEATWAVE = 11,
}

const BRUSH_LOWER_CANAL: int = BrushMode.LOWER_CANAL
const BRUSH_ORBITAL_STRIKE: int = BrushMode.ORBITAL_STRIKE

enum CosmicAge {
	GOLD = 0,
	SOLAR_FLARE = 1,
	ICE_SHADOW = 2,
	SPORE_BLOOM = 3,
	ION_STORM = 4,
}

const COSMIC_AGE_DEFS := [
	{
		"id": CosmicAge.GOLD,
		"name_ru": "Золотое окно",
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"tint_strength": 0.0,
		"flora_mul": 1.15,
		"crop_mul": 1.20,
		"solar_mul": 1.0,
		"fire_mul": 0.85,
		"temp_offset": 0.0,
	},
	{
		"id": CosmicAge.SOLAR_FLARE,
		"name_ru": "Солнечная вспышка",
		"tint": Color(1.10, 0.90, 0.72, 1.0),
		"tint_strength": 0.24,
		"flora_mul": 0.90,
		"crop_mul": 0.95,
		"solar_mul": 1.55,
		"fire_mul": 1.45,
		"temp_offset": 9.5,
	},
	{
		"id": CosmicAge.ICE_SHADOW,
		"name_ru": "Ледниковая тень",
		"tint": Color(0.76, 0.88, 1.12, 1.0),
		"tint_strength": 0.26,
		"flora_mul": 0.65,
		"crop_mul": 0.45,
		"solar_mul": 0.68,
		"fire_mul": 0.55,
		"temp_offset": -11.0,
	},
	{
		"id": CosmicAge.SPORE_BLOOM,
		"name_ru": "Споровый расцвет",
		"tint": Color(0.78, 1.06, 0.94, 1.0),
		"tint_strength": 0.20,
		"flora_mul": 1.55,
		"crop_mul": 1.35,
		"solar_mul": 0.90,
		"fire_mul": 0.80,
		"temp_offset": 2.5,
	},
	{
		"id": CosmicAge.ION_STORM,
		"name_ru": "Ионная буря",
		"tint": Color(0.84, 0.82, 1.16, 1.0),
		"tint_strength": 0.28,
		"flora_mul": 1.0,
		"crop_mul": 0.85,
		"solar_mul": 1.15,
		"fire_mul": 1.25,
		"temp_offset": -2.0,
	},
]

# Calm cosmic rhythm: GOLD >= 0.55, (GOLD + SPORE_BLOOM) >= 0.65
const COSMIC_AGE_WEIGHTS: Array[float] = [0.56, 0.10, 0.10, 0.14, 0.10]

enum Tier {
	DEEP_OCEAN = 0,
	CLOSE_OCEAN = 1,
	SHALLOW = 2,
	SAND = 3,
	SOIL_LOW = 4,
	SOIL_HIGH = 5,
	HILLS = 6,
	MOUNTAINS = 7,
	SUMMIT = 8,
}

enum Biome {
	RUST = 0,
	LUSH = 1,
	CRYSTAL = 2,
	SCORCHED = 3,
	LAVA = 4,
	XENO_JUNGLE = 5,
	CRYO_TUNDRA = 6,
	ACID_WASTE = 7,
	SILICA_DUNES = 8,
	BIOLUM_OASIS = 9,
	CREEP_MYCELIUM = 10,
	CREEP_CYBER = 11,
}

const CHUNK_SIZE := 16
const CHUNK_SHIFT := 4
const STRUCT_CLUSTER_MAX_SPAN_PX := 64
const STRUCT_CLUSTER_MAX_GAP_PX := 16
const STRUCT_MAX_RECTS_PER_FLUSH := 6
const INV_65536 := 1.0 / 65536.0
const WATER_QUEUE_CAP := 2048
const RAW_STATE_MAGIC := 0x57545231
const RAW_STATE_VERSION := 2
const RAW_STATE_LEGACY_VERSION := 1
const RAW_STATE_HEADER_BYTES := 16
const RAW_STATE_CLOUD_REC_BYTES := 13
const RAW_STATE_META_FIXED := 28
const CREEP_NODE_RADIUS := 38.0
const CREEP_NODE_RADIUS_SQ := 1444
const MAX_CREEP_NODES := 64
const MAX_GEYSERS := 32
const MAX_TORNADOES := 8
const MAX_CONWAY_CELLS := 2048
const MAX_GOO_ACTIVE := 4096

const TIER_NAMES: PackedStringArray = [
	"Глубокий океан",
	"Океан",
	"Мелководье",
	"Пляж",
	"Низина",
	"Равнина",
	"Холмы",
	"Горы",
	"Снежный пик",
]

const BIOME_NAMES: PackedStringArray = [
	"Ржавая степь",
	"Оазис",
	"Кристаллы",
	"Базальт",
	"Лава",
	"Ксено-джунгли",
	"Крио-тундра",
	"Кислотные пустоши",
	"Силикатные дюны",
	"Биолюм-оазис",
	"Мицелий-крип",
	"Кибер-сеть",
]

const BIOME_GROW_STRENGTH: Array[int] = [4, 6, 7, 2, 0, 8, 6, 7, 5, 7, 9, 9]

const TEMPLATE_NAMES: PackedStringArray = [
	"Континенты",
	"Пангея",
	"Архипелаг",
	"Атолл",
	"Кратер",
	"Разлом",
	"Два мира",
	"Ледяная корона",
]

# Pre-parsed palette constants for fast zero-allocation per-pixel rendering (non-emissives <= 0.95)
const COL_DEEP_ABYSS := Color(0.051, 0.129, 0.278, 1.0)
const COL_DEEP_A := Color(0.075, 0.180, 0.349, 1.0)
const COL_DEEP_B := Color(0.106, 0.243, 0.451, 1.0)
const COL_CLOSE_A := Color(0.122, 0.322, 0.561, 1.0)
const COL_CLOSE_B := Color(0.161, 0.412, 0.659, 1.0)
const COL_SHALLOW_A := Color(0.188, 0.518, 0.729, 1.0)
const COL_SHALLOW_B := Color(0.259, 0.639, 0.820, 1.0)
const COL_RIVER_WATER := Color(0.290, 0.714, 0.898, 1.0)

const COL_SAND_DRY := Color(0.898, 0.792, 0.549, 1.0)
const COL_SAND_PEBBLE := Color(0.808, 0.694, 0.447, 1.0)
const COL_SAND_SHELL := Color(0.941, 0.855, 0.624, 1.0)
const COL_SAND_WET := Color(0.624, 0.510, 0.341, 1.0)

const COL_RUST_LOW := Color(0.604, 0.333, 0.216, 1.0)
const COL_RUST_HIGH := Color(0.722, 0.427, 0.282, 1.0)
const COL_RUST_DARK := Color(0.490, 0.255, 0.165, 1.0)
const COL_RUST_DUNE := Color(0.816, 0.533, 0.369, 1.0)

const COL_LUSH_LOW := Color(0.243, 0.490, 0.267, 1.0)
const COL_LUSH_HIGH := Color(0.341, 0.624, 0.314, 1.0)
const COL_LUSH_TUFT := Color(0.451, 0.753, 0.376, 1.0)
const COL_LUSH_FLOWER_A := Color(0.686, 0.894, 0.478, 1.0)
const COL_LUSH_FLOWER_B := Color(0.902, 0.851, 0.416, 1.0)

const COL_CRYS_LOW := Color(0.133, 0.290, 0.349, 1.0)
const COL_CRYS_HIGH := Color(0.192, 0.416, 0.490, 1.0)
const COL_CRYS_SLATE := Color(0.090, 0.196, 0.247, 1.0)
const COL_CRYS_VEIN := Color(0.247, 0.620, 0.710, 1.0)
const COL_CRYS_TIP := Color(0.349, 0.920, 0.945, 1.0)

const COL_SCORCH_LOW := Color(0.137, 0.118, 0.133, 1.0)
const COL_SCORCH_HIGH := Color(0.220, 0.176, 0.169, 1.0)
const COL_SCORCH_ASH := Color(0.290, 0.255, 0.259, 1.0)
const COL_SCORCH_WARM_CRACK := Color(0.580, 0.239, 0.125, 1.0)
const COL_SCORCH_COLD_CRACK := Color(0.094, 0.078, 0.090, 1.0)

const COL_LAVA_CRUST := Color(0.760, 0.212, 0.063, 1.0)
const COL_LAVA_MID := Color(0.910, 0.467, 0.114, 1.0)
const COL_LAVA_CORE := Color(0.945, 0.800, 0.341, 1.0)
const COL_FIRE_CHAR := Color(0.110, 0.090, 0.102, 1.0)
const COL_ASH_TINT := Color(0.20, 0.18, 0.19, 1.0)

const COL_HILLS := Color(0.361, 0.373, 0.400, 1.0)
const COL_HILLS_SPEC := Color(0.447, 0.467, 0.502, 1.0)
const COL_HILLS_CRACK := Color(0.275, 0.286, 0.314, 1.0)

const COL_MTN := Color(0.259, 0.275, 0.306, 1.0)
const COL_MTN_RIDGE := Color(0.376, 0.404, 0.447, 1.0)
const COL_MTN_CRAG := Color(0.184, 0.200, 0.227, 1.0)
const COL_MTN_DEEP := Color(0.145, 0.157, 0.180, 1.0)

const COL_SNOW := Color(0.816, 0.875, 0.922, 1.0)
const COL_SNOW_SHADE := Color(0.659, 0.757, 0.847, 1.0)
const COL_SNOW_EDGE := Color(0.502, 0.565, 0.624, 1.0)
const COL_ICE_CORE := Color(0.753, 0.910, 0.976, 1.0)
const COL_ICE_MID := Color(0.545, 0.808, 0.945, 1.0)
const COL_ICE_RIM := Color(0.325, 0.620, 0.855, 1.0)
const COL_ICE_DEEP := Color(0.847, 0.949, 0.992, 1.0)

const COL_EDGE_OCEAN := Color(0.114, 0.298, 0.471, 1.0)
const COL_EDGE_OCEAN_DEEP := Color(0.086, 0.224, 0.369, 1.0)
const COL_EDGE_HILLS := Color(0.192, 0.200, 0.200, 1.0)
const COL_EDGE_MTN := Color(0.173, 0.188, 0.196, 1.0)

const COL_XENO_LOW := Color(0.102, 0.294, 0.255, 1.0)
const COL_XENO_HIGH := Color(0.157, 0.420, 0.337, 1.0)
const COL_XENO_VINE := Color(0.271, 0.659, 0.463, 1.0)
const COL_XENO_SPORE := Color(0.847, 0.361, 0.941, 1.0)

const COL_CRYO_LOW := Color(0.424, 0.541, 0.639, 1.0)
const COL_CRYO_HIGH := Color(0.549, 0.698, 0.800, 1.0)
const COL_CRYO_FROST := Color(0.769, 0.894, 0.945, 1.0)
const COL_CRYO_CRACK := Color(0.235, 0.325, 0.420, 1.0)

const COL_ACID_LOW := Color(0.290, 0.345, 0.125, 1.0)
const COL_ACID_HIGH := Color(0.420, 0.486, 0.157, 1.0)
const COL_ACID_POOL := Color(0.620, 0.820, 0.180, 1.0)
const COL_ACID_SLAG := Color(0.184, 0.212, 0.094, 1.0)

const COL_SILICA_LOW := Color(0.788, 0.616, 0.353, 1.0)
const COL_SILICA_HIGH := Color(0.875, 0.718, 0.451, 1.0)
const COL_SILICA_CREST := Color(0.941, 0.812, 0.557, 1.0)
const COL_SILICA_TROUGH := Color(0.620, 0.451, 0.227, 1.0)

const COL_BIOLUM_LOW := Color(0.075, 0.239, 0.282, 1.0)
const COL_BIOLUM_HIGH := Color(0.110, 0.361, 0.400, 1.0)
const COL_BIOLUM_GLOW := Color(0.220, 0.847, 0.722, 1.0)
const COL_BIOLUM_BLOOM := Color(0.420, 0.933, 0.945, 1.0)

const COL_MYC_LOW := Color(0.239, 0.110, 0.220, 1.0)
const COL_MYC_HIGH := Color(0.357, 0.157, 0.322, 1.0)
const COL_MYC_VEIN := Color(0.690, 0.298, 0.627, 1.0)
const COL_MYC_SPORE := Color(0.886, 0.541, 0.878, 1.0)

const COL_CYBER_LOW := Color(0.086, 0.114, 0.173, 1.0)
const COL_CYBER_HIGH := Color(0.125, 0.173, 0.259, 1.0)
const COL_CYBER_GRID := Color(0.208, 0.659, 0.839, 1.0)
const COL_CYBER_NODE := Color(0.447, 0.918, 0.945, 1.0)

const COL_WALL_ROCK := Color(0.227, 0.247, 0.282, 1.0)
const COL_WALL_ROCK_HI := Color(0.424, 0.455, 0.510, 1.0)
const COL_WALL_ENERGY := Color(0.102, 0.267, 0.388, 1.0)
const COL_WALL_ENERGY_CORE := Color(0.329, 0.922, 0.945, 1.0)
const COL_GOO_A := Color(0.435, 0.408, 0.510, 1.0)
const COL_GOO_B := Color(0.627, 0.588, 0.745, 1.0)
const COL_CONWAY_CELL := Color(0.275, 0.933, 0.667, 1.0)
const COL_BOMB_BODY := Color(0.180, 0.157, 0.173, 1.0)
const COL_BOMB_FUSE := Color(0.945, 0.353, 0.165, 1.0)
const COL_MINE_BODY := Color(0.235, 0.290, 0.337, 1.0)

signal map_rebuilt
signal surface_impact(world_pos: Vector2, radius: float, kind: String)
signal region_changed(rect: Rect2i)
signal cosmic_age_changed(age_id: int)

var map_w: int = int(TUNING_KNOBS["MAP_WIDTH"])
var map_h: int = int(TUNING_KNOBS["MAP_HEIGHT"])

var _tiers: PackedByteArray
var _biomes: PackedByteArray
var _river_mask: PackedByteArray
var _vent_mask: PackedByteArray
var _ash: PackedByteArray
var _frost: PackedByteArray
var _plasma_glow: PackedByteArray
var _wall_mask: PackedByteArray
var _bomb_map: PackedByteArray
var _goo_map: PackedByteArray
var _conway_map: PackedByteArray
var _height: PackedFloat32Array
var _temp: PackedFloat32Array
var _rad: PackedFloat32Array
var _moisture: PackedFloat32Array
var _fire: PackedFloat32Array

var _rgba_buf: PackedByteArray
var _mask_buf: PackedByteArray
var _image: Image
var _mask_image: Image
var _texture: ImageTexture
var _mask_texture: ImageTexture
var _terrain_sprite: Sprite2D
var _terrain_mat: ShaderMaterial

var _mm_clouds: MultiMeshInstance2D
var _cloud_mat: ShaderMaterial
var _cloud_pos: PackedVector2Array
var _cloud_vel: PackedVector2Array
var _cloud_scale: PackedVector2Array
var _cloud_vapor: PackedFloat32Array
var _cloud_raining: PackedByteArray
var _clouds_suppressed: bool = false
var _global_vapor_pool: float = 0.0
var _co2_load: float = 0.0
var _frost_tiles: int = 0
var _cloud_rain_fx_cd: float = 0.0
var _water_queue: PackedInt32Array
var _wq_head: int = 0
var _wq_tail: int = 0
var _wq_count: int = 0
var _wq_stamp_id: int = 100

var _chunks_w: int = 0
var _chunks_h: int = 0
var _chunk_active: PackedByteArray
var _chunk_dirty: PackedByteArray
var _chunk_struct_dirty: PackedByteArray
var _chunk_row_mask: PackedInt32Array
var _chunk_dirty_bounds: PackedInt32Array
var _active_chunks: PackedInt32Array
var _active_chunk_pos: PackedInt32Array
var _bio_chunk_active: PackedByteArray
var _bio_active_chunks: PackedInt32Array
var _dirty_chunks: PackedInt32Array
var _structural_dirty_chunks: PackedInt32Array
var _work_stamp: PackedInt32Array
var _work_stamp_id: int = 1
var _vent_tiles: PackedInt32Array
var _goo_active: PackedInt32Array
var _conway_active: PackedInt32Array
var _detonate_queue: PackedInt32Array
var _creep_nodes: Array[Dictionary] = []
var _geysers: Array[Dictionary] = []
var _tornadoes: Array[Dictionary] = []
var _quake_steps: Array[Vector3i] = []

var _rng := RandomNumberGenerator.new()
var _cosmic_age_rng := RandomNumberGenerator.new()
var _drop_rng := RandomNumberGenerator.new()
var _template_rng := RandomNumberGenerator.new()
var _biome_rng := RandomNumberGenerator.new()
var _drops: RefCounted = null
var _fx_ref: Node2D = null
var current_seed: int = 20261114
var _template_id: int = MapTemplate.CONTINENTS
var _fast_rng_seed: int = 1357911
var _env_time: float = 0.0
var _day_phase: float = 0.0
var _night_mix: float = 0.0
var _cosmic_age: int = CosmicAge.GOLD
var _cosmic_age_elapsed: float = 0.0
var _cosmic_temp_offset: float = 0.0
var _cosmic_fire_mul: float = 0.85
var _last_crisis_age: int = 0
var _ion_strike_timer: float = 0.0
var _sim_pace_mult: float = 1.0
var _world_laws: Dictionary = {
	"self_founding": true,
	"diplomacy_wars": true,
	"rebellions": true,
	"cosmic_ages": true,
	"disasters": true,
	"rad_mutations": true,
	"biome_growth": true,
	"biome_overgrowth": true,
	"creep_decay": true,
	"volcanoes_geysers": true,
}
var _avg_temp_cached: float = 18.0
var _temp_total_sum: float = 0.0
var _inv_total_tiles: float = 0.0
var _temp_scan_row: int = 0
var _temp_scan_accum: float = 0.0
var _env_chunk_cursor: int = 0
var _bio_chunk_cursor: int = 0
var _env_step_count: int = 0
var _steam_cooldown: float = 0.0
var _ca_10hz_accum: float = 0.0
var _vent_erupt_accum: float = 0.0
var _had_drops_synced: bool = false
var _fire_events_total: int = 0
var _active_fire_tiles: int = 0
var _ash_tiles: int = 0
var _bomb_count: int = 0
var _chain_detonations_total: int = 0
var _volcano_eruptions_total: int = 0
var _volcanoes_sealed_total: int = 0
var _goo_decayed_total: int = 0
var _initialized: bool = false

var _env_eff_dt: float = 0.0
var _env_diff_k: float = 0.0
var _env_cool_k: float = 0.0
var _env_rad_decay: float = 0.0
var _env_rad_crys_floor: float = 0.42
var _env_lava_min: float = 480.0
var _env_lava_floor: float = 790.0
var _env_amb_c: float = 18.0
var _env_eq_min_c: float = 5.0
var _env_eq_max_c: float = 29.0
var _env_steady_eps: float = 0.04
var _env_freeze_c: float = -2.0
var _env_melt_c: float = 5.0
var _env_evap_rate: float = 0.28
var _env_fire_decay: float = 0.22
var _env_fire_spread_base: float = 0.42
var _env_crystal_prob_i: int = 0
var _env_lush_prob_i: int = 0
var _env_ash_boost_prob_i: int = 0
var _env_ash_decay_step: int = 1
var _env_plasma_decay_step: int = 1
var _env_eq_shift: float = 0.0
var _env_ocean_damp: float = 0.0
var _env_frost_grow_base: int = 0
var _env_frost_grow_rem: int = 0
var _env_frost_melt_base: int = 0
var _env_frost_melt_rem: int = 0
var _env_steam_emitted: bool = false
var _env_temp_delta: float = 0.0
var _env_row_active: bool = false
var _env_t_cur: float = 18.0
var _env_b_cur: int = 0
var _env_a_cur: int = 0
var _env_r_cur: float = 0.0
var _env_r_floor: float = 0.02
var _env_frost_cur: int = 0
var _env_f_orig: float = 0.0
var _ren_crys_role: int = 0
var _ren_shore_bevel_n: bool = false
var _ren_row_col: PackedColorArray
var _ren_row_crys: PackedByteArray


func _ready() -> void:
	_ensure_initialized()
	generate_planet(int(TUNING_KNOBS["DEFAULT_SEED"]))


func _exit_tree() -> void:
	_terrain_mat = null
	_cloud_mat = null
	_image = null
	_mask_image = null
	_texture = null
	_mask_texture = null
	_fx_ref = null
	_drops = null
	_creep_nodes.clear()
	_geysers.clear()
	_tornadoes.clear()
	_quake_steps.clear()


func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if _drops == null:
		_drops = WorldDropsScript.new()
	_drops.set_map_bounds(Vector2i(map_w, map_h))

	var total: int = map_w * map_h
	_tiers.resize(total)
	_biomes.resize(total)
	_river_mask.resize(total)
	_vent_mask.resize(total)
	_ash.resize(total)
	_frost.resize(total)
	_frost.fill(0)
	_plasma_glow.resize(total)
	_plasma_glow.fill(0)
	_wall_mask.resize(total)
	_wall_mask.fill(0)
	_bomb_map.resize(total)
	_bomb_map.fill(0)
	_goo_map.resize(total)
	_goo_map.fill(0)
	_conway_map.resize(total)
	_conway_map.fill(0)
	_height.resize(total)
	_temp.resize(total)
	_rad.resize(total)
	_moisture.resize(total)
	_fire.resize(total)
	_work_stamp.resize(total)
	_work_stamp.fill(0)
	_water_queue.resize(WATER_QUEUE_CAP)
	_water_queue.fill(0)
	var cloud_n: int = int(TUNING_KNOBS["CLOUD_COUNT"])
	_cloud_vapor.resize(cloud_n)
	_cloud_vapor.fill(0.0)
	_cloud_raining.resize(cloud_n)
	_cloud_raining.fill(0)

	var age_seed: int = (current_seed ^ 0xA6E5301) & 0x7FFFFFFF
	_cosmic_age_rng.seed = age_seed if age_seed != 0 else 0xA6E5301
	_drop_rng.seed = (current_seed ^ 0x44524F50) & 0x7FFFFFFF
	_template_rng.seed = (current_seed ^ 0x54454D50) & 0x7FFFFFFF
	_biome_rng.seed = (current_seed ^ 0x42494F4D) & 0x7FFFFFFF

	_rgba_buf.resize(total * 4)
	_mask_buf.resize(total * 4)
	_ren_row_col.resize(map_w)
	_ren_row_crys.resize(map_w)

	_chunks_w = (map_w + CHUNK_SIZE - 1) >> CHUNK_SHIFT
	_chunks_h = (map_h + CHUNK_SIZE - 1) >> CHUNK_SHIFT
	var total_chunks: int = _chunks_w * _chunks_h
	_chunk_active.resize(total_chunks)
	_chunk_active.fill(0)
	_chunk_dirty.resize(total_chunks)
	_chunk_dirty.fill(0)
	_chunk_struct_dirty.resize(total_chunks)
	_chunk_struct_dirty.fill(0)
	_chunk_row_mask.resize(total_chunks)
	_chunk_row_mask.fill(0)
	_chunk_dirty_bounds.resize(total_chunks)
	_chunk_dirty_bounds.fill(0)
	_active_chunk_pos.resize(total_chunks)
	_active_chunk_pos.fill(-1)
	_bio_chunk_active.resize(total_chunks)
	_bio_chunk_active.fill(0)

	_image = Image.create(map_w, map_h, false, Image.FORMAT_RGBA8)
	_mask_image = Image.create(map_w, map_h, false, Image.FORMAT_RGBA8)
	_texture = ImageTexture.create_from_image(_image)
	_mask_texture = ImageTexture.create_from_image(_mask_image)

	_terrain_sprite = Sprite2D.new()
	_terrain_sprite.centered = false
	_terrain_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_terrain_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	_terrain_sprite.texture = _texture

	var terrain_shader: Shader = load("res://shaders/terrain_water.gdshader") as Shader
	if terrain_shader != null:
		_terrain_mat = ShaderMaterial.new()
		_terrain_mat.shader = terrain_shader
		_terrain_mat.set_shader_parameter("mask_tex", _mask_texture)
		_terrain_mat.set_shader_parameter("map_size", Vector2(float(map_w), float(map_h)))
		_terrain_mat.set_shader_parameter("day_phase", _day_phase)
		_terrain_mat.set_shader_parameter("night_mix", _night_mix)
		_sync_cosmic_age_shader()
		_terrain_sprite.material = _terrain_mat

	add_child(_terrain_sprite)
	_build_cloud_layer()


func _build_cloud_layer() -> void:
	var white_img: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	white_img.set_pixel(0, 0, Color(1.0, 1.0, 1.0, 1.0))
	var white_tex: ImageTexture = ImageTexture.create_from_image(white_img)

	_mm_clouds = MultiMeshInstance2D.new()
	_mm_clouds.z_index = 4
	_mm_clouds.z_as_relative = false
	_mm_clouds.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mm_clouds.texture = white_tex

	var cloud_shader: Shader = load("res://shaders/cloud_shadow.gdshader") as Shader
	if cloud_shader != null:
		_cloud_mat = ShaderMaterial.new()
		_cloud_mat.shader = cloud_shader
		_cloud_mat.set_shader_parameter("quad_size", Vector2(96.0, 48.0))
		_cloud_mat.set_shader_parameter("day_phase", _day_phase)
		_cloud_mat.set_shader_parameter("night_mix", _night_mix)
		_mm_clouds.material = _cloud_mat

	var quad := QuadMesh.new()
	quad.size = Vector2(96.0, 48.0)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = int(TUNING_KNOBS["CLOUD_COUNT"])
	_mm_clouds.multimesh = mm
	_mm_clouds.visible = not _clouds_suppressed
	add_child(_mm_clouds)


func set_clouds_suppressed(suppressed: bool) -> void:
	var was_suppressed: bool = _clouds_suppressed
	_clouds_suppressed = suppressed
	if _mm_clouds != null:
		_mm_clouds.visible = not suppressed
		if was_suppressed and not suppressed:
			_sync_cloud_multimesh()


func set_day_phase(phase: float, night_mix: float) -> void:
	_day_phase = phase
	_night_mix = clampf(night_mix, 0.0, 1.0)
	if _terrain_mat != null:
		_terrain_mat.set_shader_parameter("day_phase", _day_phase)
		_terrain_mat.set_shader_parameter("night_mix", _night_mix)
		_sync_cosmic_age_shader()
	if _cloud_mat != null:
		_cloud_mat.set_shader_parameter("day_phase", _day_phase)
		_cloud_mat.set_shader_parameter("night_mix", _night_mix)


func _sync_cosmic_age_shader() -> void:
	if _terrain_mat == null or _terrain_mat.shader == null:
		return
	var cfg: Dictionary = COSMIC_AGE_DEFS[clampi(_cosmic_age, 0, COSMIC_AGE_DEFS.size() - 1)]
	var c: Color = cfg["tint"]
	_terrain_mat.set_shader_parameter("age_tint", Vector3(c.r, c.g, c.b))
	_terrain_mat.set_shader_parameter("age_tint_strength", float(cfg["tint_strength"]))


func get_cosmic_age() -> int:
	return _cosmic_age


func get_cosmic_age_info() -> Dictionary:
	var cfg: Dictionary = COSMIC_AGE_DEFS[clampi(_cosmic_age, 0, COSMIC_AGE_DEFS.size() - 1)]
	var duration: float = maxf(1.0, float(TUNING_KNOBS["COSMIC_AGE_DURATION_SEC"]))
	return {
		"id": _cosmic_age,
		"name_ru": String(cfg["name_ru"]),
		"progress": clampf(_cosmic_age_elapsed / duration, 0.0, 1.0),
		"duration": duration,
		"tint": cfg["tint"],
		"tint_strength": float(cfg["tint_strength"]),
		"flora_mul": float(cfg["flora_mul"]),
		"crop_mul": float(cfg["crop_mul"]),
		"solar_mul": float(cfg["solar_mul"]),
		"fire_mul": float(cfg["fire_mul"]),
		"temp_offset": float(cfg["temp_offset"]),
	}


func set_cosmic_age(age_id: int, reset_timer: bool = true) -> void:
	_ensure_initialized()
	var prev_age: int = _cosmic_age
	var next_id: int = clampi(age_id, CosmicAge.GOLD, CosmicAge.ION_STORM)
	_cosmic_age = next_id
	if reset_timer:
		_cosmic_age_elapsed = 0.0
	if next_id != CosmicAge.GOLD:
		_last_crisis_age = next_id
	if next_id == CosmicAge.ION_STORM:
		if prev_age != CosmicAge.ION_STORM or reset_timer:
			var interval: float = float(TUNING_KNOBS["ION_STORM_STRIKE_INTERVAL_SEC"])
			var first_delay: float = float(TUNING_KNOBS["ION_STORM_FIRST_STRIKE_DELAY_SEC"])
			_ion_strike_timer = maxf(0.0, interval - first_delay)
	else:
		_ion_strike_timer = 0.0
	var cfg: Dictionary = COSMIC_AGE_DEFS[next_id]
	_cosmic_temp_offset = float(cfg["temp_offset"])
	_cosmic_fire_mul = float(cfg["fire_mul"])
	_sync_cosmic_age_shader()
	cosmic_age_changed.emit(next_id)


func set_sim_pace(mult: float) -> void:
	_sim_pace_mult = clampf(mult, 0.0, 200.0)


func set_fx_audio(fx: Node2D) -> void:
	_fx_ref = fx


func _resolve_fx() -> Node2D:
	if _fx_ref != null and is_instance_valid(_fx_ref):
		return _fx_ref
	var p := get_parent()
	if p != null:
		var cand := p.get_node_or_null("FxAudio") as Node2D
		if cand != null:
			_fx_ref = cand
			return _fx_ref
	_fx_ref = get_node_or_null("../FxAudio") as Node2D
	return _fx_ref


func set_world_laws(laws: Dictionary) -> void:
	for key in laws:
		_world_laws[String(key)] = bool(laws[key])


func get_world_laws() -> Dictionary:
	return _world_laws.duplicate()


func _pick_next_cosmic_age() -> int:
	var total_w: float = 0.0
	for w in COSMIC_AGE_WEIGHTS:
		total_w += w
	var roll: float = _cosmic_age_rng.randf() * total_w
	var acc: float = 0.0
	var picked: int = CosmicAge.GOLD
	for age_i in range(COSMIC_AGE_WEIGHTS.size()):
		acc += COSMIC_AGE_WEIGHTS[age_i]
		if roll <= acc:
			picked = age_i
			break
	if picked != CosmicAge.GOLD and picked != CosmicAge.SPORE_BLOOM and picked == _last_crisis_age:
		return CosmicAge.GOLD
	return picked


func step_cosmic_age(dt: float) -> Dictionary:
	_ensure_initialized()
	var scaled_dt: float = dt * _sim_pace_mult
	if dt <= 0.0 or scaled_dt <= 0.0:
		return {
			"changed": false,
			"age_id": _cosmic_age,
			"strike_pending": false,
			"strike_pos": Vector2.ZERO,
		}

	var duration: float = maxf(1.0, float(TUNING_KNOBS["COSMIC_AGE_DURATION_SEC"]))
	var changed: bool = false
	if bool(_world_laws.get("cosmic_ages", true)):
		_cosmic_age_elapsed += scaled_dt
		var steps: int = 0
		while _cosmic_age_elapsed >= duration and steps < 16:
			_cosmic_age_elapsed -= duration
			steps += 1
			var next_age: int = _pick_next_cosmic_age()
			set_cosmic_age(next_age, false)
			changed = true

	var strike_pending: bool = false
	var strike_pos: Vector2 = Vector2.ZERO
	if _cosmic_age == CosmicAge.ION_STORM and bool(_world_laws.get("disasters", true)):
		var interval: float = maxf(0.5, float(TUNING_KNOBS["ION_STORM_STRIKE_INTERVAL_SEC"]))
		_ion_strike_timer += scaled_dt
		if _ion_strike_timer >= interval:
			_ion_strike_timer = fmod(_ion_strike_timer, interval)
			var cand: Vector2 = _pick_ion_storm_strike_pos()
			if cand.x >= 0.0:
				strike_pending = true
				strike_pos = cand

	return {
		"changed": changed,
		"age_id": _cosmic_age,
		"strike_pending": strike_pending,
		"strike_pos": strike_pos,
	}


func _pick_ion_storm_strike_pos() -> Vector2:
	var mw: int = map_w
	var mh: int = map_h
	for _attempt in range(48):
		var px: int = _cosmic_age_rng.randi_range(16, mw - 17)
		var py: int = _cosmic_age_rng.randi_range(16, mh - 17)
		var idx: int = py * mw + px
		var t: int = _tiers[idx]
		if t >= Tier.SAND and t <= Tier.HILLS and _biomes[idx] != Biome.LAVA:
			return Vector2(float(px) + 0.5, float(py) + 0.5)
	for py in range(20, mh - 20, 12):
		var row_off: int = py * mw
		for px in range(20, mw - 20, 12):
			var t: int = _tiers[row_off + px]
			if t >= Tier.SAND and t <= Tier.MOUNTAINS:
				return Vector2(float(px) + 0.5, float(py) + 0.5)
	return Vector2(-1.0, -1.0)


func _reset_extended_state(seed_val: int) -> void:
	var ds: int = (seed_val ^ 0x44524F50) & 0x7FFFFFFF
	_drop_rng.seed = ds if ds != 0 else 0x44524F50
	var ts: int = (seed_val ^ 0x54454D50) & 0x7FFFFFFF
	_template_rng.seed = ts if ts != 0 else 0x54454D50
	var bs: int = (seed_val ^ 0x42494F4D) & 0x7FFFFFFF
	_biome_rng.seed = bs if bs != 0 else 0x42494F4D
	if _drops != null:
		_drops.set_map_bounds(Vector2i(map_w, map_h))
		_drops.reset(seed_val)
	_wall_mask.fill(0)
	_bomb_map.fill(0)
	_goo_map.fill(0)
	_conway_map.fill(0)
	_bio_chunk_active.fill(0)
	_bio_active_chunks.clear()
	_vent_tiles.clear()
	_goo_active.clear()
	_conway_active.clear()
	_detonate_queue.clear()
	_creep_nodes.clear()
	_geysers.clear()
	_tornadoes.clear()
	_quake_steps.clear()
	_bomb_count = 0
	_ca_10hz_accum = 0.0
	_vent_erupt_accum = 0.0
	_bio_chunk_cursor = 0
	_chain_detonations_total = 0
	_volcano_eruptions_total = 0
	_volcanoes_sealed_total = 0
	_goo_decayed_total = 0
	_had_drops_synced = false
	var fx := _resolve_fx()
	if fx != null and fx.has_method("sync_sky_drops"):
		fx.sync_sky_drops(PackedVector2Array(), PackedColorArray(), PackedFloat32Array())


func _rebuild_vent_tiles_cache() -> void:
	_vent_tiles.clear()
	for idx in range(_vent_mask.size()):
		if _vent_mask[idx] > 0:
			_vent_tiles.append(idx)


func _reset_common_gen(seed_val: int) -> void:
	_ensure_initialized()
	current_seed = seed_val
	_rng.seed = seed_val
	_fast_rng_seed = (seed_val ^ 0x5A17D00D) & 0x7FFFFFFF
	if _fast_rng_seed == 0:
		_fast_rng_seed = 1357911
	var age_seed: int = (seed_val ^ 0xA6E5301) & 0x7FFFFFFF
	_cosmic_age_rng.seed = age_seed if age_seed != 0 else 0xA6E5301
	_last_crisis_age = 0
	_ion_strike_timer = 0.0
	_env_time = 0.0
	_steam_cooldown = 0.0
	_env_chunk_cursor = 0
	_env_step_count = 0
	_fire_events_total = 0
	_active_fire_tiles = 0
	_ash_tiles = 0
	_frost_tiles = 0
	_global_vapor_pool = 0.0
	_co2_load = 0.0
	_cloud_rain_fx_cd = 0.0
	_wq_head = 0
	_wq_tail = 0
	_wq_count = 0
	_river_mask.fill(0)
	_vent_mask.fill(0)
	_ash.fill(0)
	_frost.fill(0)
	_plasma_glow.fill(0)
	_rad.fill(0.0)
	_fire.fill(0.0)
	_chunk_active.fill(0)
	_chunk_dirty.fill(0)
	_chunk_struct_dirty.fill(0)
	_chunk_row_mask.fill(0)
	_chunk_dirty_bounds.fill(0)
	_active_chunks.clear()
	_active_chunk_pos.fill(-1)
	_dirty_chunks.clear()
	_structural_dirty_chunks.clear()
	_reset_extended_state(seed_val)


func generate_planet(seed_val: int) -> void:
	_reset_common_gen(seed_val)
	_template_id = MapTemplate.CONTINENTS

	_generate_relief(seed_val)
	_carve_rivers()
	_wq_stamp_id = _work_stamp_id + 1
	_generate_biomes_and_climate(seed_val)
	_carve_volcanic_fissures()
	_rebuild_vent_tiles_cache()

	_recompute_all_chunk_flags()
	_recompute_avg_temp_full()
	_render_rect(0, 0, map_w, map_h, true)
	_init_clouds()
	set_cosmic_age(CosmicAge.GOLD, true)

	map_rebuilt.emit()


func generate_planet_with_template(seed_val: int, template_id: int) -> void:
	var tid: int = clampi(template_id, MapTemplate.CONTINENTS, MapTemplate.ICE_CROWN)
	if tid == MapTemplate.CONTINENTS:
		generate_planet(seed_val)
		return
	_reset_common_gen(seed_val)
	_template_id = tid
	_generate_template_relief(seed_val, tid)
	if tid != MapTemplate.ARCHIPELAGO and tid != MapTemplate.ATOLL:
		_carve_rivers()
	_wq_stamp_id = _work_stamp_id + 1
	_generate_template_biomes(seed_val, tid)
	if tid == MapTemplate.CRATER or tid == MapTemplate.RIFT or tid == MapTemplate.PANGAEA:
		_carve_volcanic_fissures()
	_rebuild_vent_tiles_cache()
	_recompute_all_chunk_flags()
	_recompute_bio_active_chunks()
	_recompute_avg_temp_full()
	_render_rect(0, 0, map_w, map_h, true)
	_init_clouds()
	set_cosmic_age(CosmicAge.GOLD, true)
	map_rebuilt.emit()


func _generate_template_relief(seed_val: int, tid: int) -> void:
	var elev_noise := FastNoiseLite.new()
	elev_noise.seed = seed_val + tid * 37
	elev_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	elev_noise.frequency = 0.0085 if tid == MapTemplate.ARCHIPELAGO else 0.0072
	elev_noise.fractal_octaves = 5
	elev_noise.fractal_gain = 0.52

	var isl_x := PackedFloat32Array()
	var isl_y := PackedFloat32Array()
	var isl_r := PackedFloat32Array()
	if tid == MapTemplate.ARCHIPELAGO:
		for _k in range(20):
			isl_x.append(_template_rng.randf_range(0.10, 0.90))
			isl_y.append(_template_rng.randf_range(0.14, 0.86))
			isl_r.append(_template_rng.randf_range(0.08, 0.17))

	var inv_w: float = 1.0 / float(map_w)
	var inv_h: float = 1.0 / float(map_h)
	for y in range(map_h):
		var u_y: float = float(y) * inv_h
		var ny: float = (u_y - 0.5) * 2.0
		var row_off: int = y * map_w
		for x in range(map_w):
			var u_x: float = float(x) * inv_w
			var nx: float = (u_x - 0.5) * 2.0
			var n_val: float = elev_noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
			var h_val: float = _eval_template_height(tid, u_x, u_y, nx, ny, n_val, isl_x, isl_y, isl_r)
			var bd: float = minf(minf(float(x), float(map_w - 1 - x)), minf(float(y), float(map_h - 1 - y)))
			if bd < 14.0:
				h_val -= (1.0 - bd / 14.0) * 0.28
			h_val = clampf(h_val, 0.0, 1.0)
			var idx: int = row_off + x
			_height[idx] = h_val
			_tiers[idx] = _classify_height(h_val)


func _eval_template_height(
	tid: int,
	ux: float,
	uy: float,
	nx: float,
	ny: float,
	n_val: float,
	isl_x: PackedFloat32Array,
	isl_y: PackedFloat32Array,
	isl_r: PackedFloat32Array
) -> float:
	var rad_c: float = Vector2(nx, ny * 1.18).length()
	match tid:
		MapTemplate.PANGAEA:
			var fall: float = clampf((rad_c - 0.58) * 1.45, 0.0, 1.0)
			var spine: float = maxf(0.0, 0.24 - absf(ny + sin(nx * 2.6) * 0.18)) * 0.85
			return n_val * 0.72 + 0.24 + spine - fall
		MapTemplate.ARCHIPELAGO:
			var best: float = 0.0
			for i in range(isl_x.size()):
				var d: float = Vector2((ux - isl_x[i]) * 1.65, uy - isl_y[i]).length() / maxf(0.04, isl_r[i])
				best = maxf(best, clampf(1.0 - d, 0.0, 1.0))
			return 0.14 + best * 0.52 + (n_val - 0.45) * 0.34
		MapTemplate.ATOLL:
			var ring: float = 1.0 - absf(rad_c - 0.56) / 0.23
			var gap: float = 0.22 if (absf(ny) < 0.11 and nx > 0.25) or (absf(nx) < 0.09 and ny < -0.25) else 0.0
			var spire: float = clampf(1.0 - rad_c / 0.16, 0.0, 1.0) * 0.62
			return 0.12 + maxf(clampf(ring, 0.0, 1.0) * 0.48 - gap, spire) + (n_val - 0.45) * 0.26
		MapTemplate.CRATER:
			var rim: float = exp(-pow((rad_c - 0.42) / 0.13, 2.0)) * 0.52
			var peak: float = exp(-pow(rad_c / 0.10, 2.0)) * 0.42
			var outer: float = clampf(1.0 - clampf((rad_c - 0.64) * 2.2, 0.0, 1.0), 0.0, 1.0) * 0.24
			var pit: float = -0.22 if rad_c < 0.30 and rad_c > 0.10 else 0.0
			return 0.22 + rim + peak + outer + pit + (n_val - 0.5) * 0.24
		MapTemplate.RIFT:
			var rift_x: float = 0.08 * sin(ny * 3.4)
			var rift_d: float = absf(nx - rift_x)
			var trench: float = -0.58 * exp(-pow(rift_d / 0.12, 2.0))
			var edge_f: float = clampf((rad_c - 0.72) * 1.8, 0.0, 1.0)
			return 0.46 + n_val * 0.38 + trench - edge_f
		MapTemplate.TWIN_WORLDS:
			var d_w: float = Vector2((nx + 0.48) * 1.15, ny * 1.12).length()
			var d_e: float = Vector2((nx - 0.48) * 1.15, ny * 1.12).length()
			var lobe: float = maxf(clampf(1.0 - d_w / 0.56, 0.0, 1.0), clampf(1.0 - d_e / 0.56, 0.0, 1.0))
			return 0.14 + lobe * 0.52 + (n_val - 0.48) * 0.28
		MapTemplate.ICE_CROWN:
			var polar: float = clampf((absf(ny) - 0.12) * 0.45, 0.0, 0.35)
			var fall_i: float = clampf((rad_c - 0.78) * 1.8, 0.0, 1.0)
			return 0.34 + polar + n_val * 0.36 - fall_i
		_:
			return n_val


func _generate_template_biomes(seed_val: int, tid: int) -> void:
	_generate_biomes_and_climate(seed_val)
	var b_noise := FastNoiseLite.new()
	b_noise.seed = seed_val + 991 + tid * 19
	b_noise.frequency = 0.014
	var mw: int = map_w
	var mh: int = map_h
	for y in range(mh):
		var row_off: int = y * mw
		var ny: float = (float(y) / float(mh) - 0.5) * 2.0
		for x in range(mw):
			var idx: int = row_off + x
			var t: int = _tiers[idx]
			var nx: float = (float(x) / float(mw) - 0.5) * 2.0
			var nv: float = b_noise.get_noise_2d(float(x), float(y))
			if tid == MapTemplate.ICE_CROWN:
				_temp[idx] = minf(_temp[idx], -6.0 - absf(ny) * 10.0)
				if t == Tier.SHALLOW:
					_frost[idx] = 225
				elif t >= Tier.SAND and t <= Tier.HILLS:
					_biomes[idx] = Biome.BIOLUM_OASIS if nv > 0.42 else Biome.CRYO_TUNDRA
			elif tid == MapTemplate.PANGAEA and t >= Tier.SAND and t <= Tier.HILLS:
				if absf(nx) < 0.26 and absf(ny) < 0.36 and nv < 0.15:
					_biomes[idx] = Biome.SILICA_DUNES
					_moisture[idx] = 0.12
				elif nv > 0.22:
					_biomes[idx] = Biome.XENO_JUNGLE
			elif tid == MapTemplate.ARCHIPELAGO and t >= Tier.SAND and t <= Tier.HILLS:
				if nv > 0.24:
					_biomes[idx] = Biome.BIOLUM_OASIS
				elif nv < -0.25:
					_biomes[idx] = Biome.XENO_JUNGLE
			elif tid == MapTemplate.ATOLL and t >= Tier.SAND and t <= Tier.HILLS:
				_biomes[idx] = Biome.BIOLUM_OASIS if nv > 0.12 else Biome.XENO_JUNGLE
			elif tid == MapTemplate.CRATER and t >= Tier.SAND and t <= Tier.HILLS:
				var rc: float = Vector2(nx, ny * 1.18).length()
				if rc < 0.22:
					_biomes[idx] = Biome.CRYSTAL
					_rad[idx] = 0.36
				elif rc < 0.46:
					_biomes[idx] = Biome.SCORCHED if nv < 0.1 else Biome.ACID_WASTE
			elif tid == MapTemplate.RIFT and t >= Tier.SAND:
				var rd: float = absf(nx - 0.08 * sin(ny * 3.4))
				if rd < 0.17:
					_biomes[idx] = Biome.LAVA if (rd < 0.06 and nv > 0.15) else Biome.SCORCHED
					_temp[idx] = 620.0 if _biomes[idx] == Biome.LAVA else 145.0
				elif nx > 0.0:
					_biomes[idx] = Biome.SILICA_DUNES if nv < 0.1 else Biome.CRYSTAL
				else:
					_biomes[idx] = Biome.XENO_JUNGLE if nv > 0.05 else Biome.LUSH
			elif tid == MapTemplate.TWIN_WORLDS and t >= Tier.SAND and t <= Tier.HILLS:
				if nx < 0.0:
					_biomes[idx] = Biome.XENO_JUNGLE if nv > 0.15 else Biome.LUSH
				else:
					_biomes[idx] = Biome.SILICA_DUNES if nv > -0.15 else Biome.RUST


func _generate_relief(seed_val: int) -> void:
	var elev_noise := FastNoiseLite.new()
	elev_noise.seed = seed_val
	elev_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	elev_noise.frequency = 0.0072
	elev_noise.fractal_octaves = 5
	elev_noise.fractal_gain = 0.52
	elev_noise.fractal_lacunarity = 2.05

	var warp_noise := FastNoiseLite.new()
	warp_noise.seed = seed_val + 131
	warp_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	warp_noise.frequency = 0.0055
	warp_noise.fractal_octaves = 2

	var ridge_noise := FastNoiseLite.new()
	ridge_noise.seed = seed_val + 409
	ridge_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ridge_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	ridge_noise.frequency = 0.0115
	ridge_noise.fractal_octaves = 3

	var ax: float = _rng.randf_range(-0.46, -0.26)
	var ay: float = _rng.randf_range(-0.14, 0.14)
	var bx: float = _rng.randf_range(0.24, 0.46)
	var by: float = _rng.randf_range(-0.16, 0.16)
	var cx_lobe: float = _rng.randf_range(-0.10, 0.12)
	var cy_lobe: float = _rng.randf_range(-0.34, 0.34)

	var inv_w: float = 1.0 / float(map_w)
	var inv_h: float = 1.0 / float(map_h)

	for y in range(map_h):
		var ny: float = (float(y) * inv_h - 0.5) * 2.0
		var row_off: int = y * map_w
		for x in range(map_w):
			var nx: float = (float(x) * inv_w - 0.5) * 2.0
			var wx: float = float(x) + warp_noise.get_noise_2d(float(x), float(y)) * 34.0
			var wy: float = float(y) + warp_noise.get_noise_2d(float(x) + 180.0, float(y) - 90.0) * 34.0

			var da: float = Vector2(nx - ax, (ny - ay) * 1.12).length()
			var db: float = Vector2(nx - bx, (ny - by) * 1.14).length()
			var dc: float = Vector2((nx - cx_lobe) * 1.25, (ny - cy_lobe) * 1.35).length()
			var edge_dist: float = minf(minf(da, db), dc + 0.12)

			var base_h: float = elev_noise.get_noise_2d(wx, wy) * 0.5 + 0.5
			var falloff: float = clampf((edge_dist - 0.32) * 0.88, 0.0, 1.0)
			var h_val: float = base_h - falloff

			# Tectonic mountain spines appear mainly in continental interiors
			var ridge: float = clampf(ridge_noise.get_noise_2d(wx * 0.9, wy * 0.9) * 0.5 + 0.5, 0.0, 1.0)
			var interior: float = clampf((h_val - 0.42) * 3.0, 0.0, 1.0)
			h_val += (ridge - 0.40) * 0.28 * interior

			# Soft coastal shelf border margin
			var border_d: float = minf(minf(float(x), float(map_w - 1 - x)), minf(float(y), float(map_h - 1 - y)))
			if border_d < 16.0:
				h_val -= (1.0 - border_d / 16.0) * 0.28

			h_val = clampf(h_val, 0.0, 1.0)
			var idx: int = row_off + x
			_height[idx] = h_val
			_tiers[idx] = _classify_height(h_val)


func _carve_rivers() -> void:
	var candidates := PackedInt32Array()
	for y in range(20, map_h - 20, 10):
		var row_off: int = y * map_w
		for x in range(20, map_w - 20, 10):
			var idx: int = row_off + x
			if _tiers[idx] == Tier.HILLS or _tiers[idx] == Tier.MOUNTAINS:
				if _height[idx] >= 0.605 and _height[idx] <= 0.775:
					candidates.append(idx)

	var cand_n: int = candidates.size()
	for i in range(cand_n - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: int = candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp

	var target_rivers: int = int(TUNING_KNOBS["RIVER_COUNT"])
	var springs_x := PackedInt32Array()
	var springs_y := PackedInt32Array()
	var carved: int = 0

	for ci in range(cand_n):
		if carved >= target_rivers:
			break
		var s_idx: int = candidates[ci]
		@warning_ignore("integer_division")
		var sy: int = s_idx / map_w
		var sx: int = s_idx % map_w

		var too_close: bool = false
		for si in range(springs_x.size()):
			var dx: int = sx - springs_x[si]
			var dy: int = sy - springs_y[si]
			if dx * dx + dy * dy < 38 * 38:
				too_close = true
				break
		if too_close:
			continue

		var path := _trace_river_path(sx, sy)
		if path.size() < 18:
			continue

		springs_x.append(sx)
		springs_y.append(sy)
		_stamp_river_path(path)
		carved += 1


func _trace_river_path(sx: int, sy: int) -> PackedInt32Array:
	_work_stamp_id += 1
	var stamp: int = _work_stamp_id
	var path := PackedInt32Array()
	var cx: int = sx
	var cy: int = sy
	var uphill_run: int = 0
	var meander_phase: float = _rng.randf_range(0.0, TAU)
	var prev_dx: float = 0.0
	var prev_dy: float = 0.0

	for step in range(230):
		var idx: int = cy * map_w + cx
		path.append(idx)
		_work_stamp[idx] = stamp

		if _tiers[idx] <= Tier.CLOSE_OCEAN or _river_mask[idx] > 0:
			return path

		var best_nx: int = -1
		var best_ny: int = -1
		var best_score: float = 1e9
		var cur_h: float = _height[idx]

		var perp_x: float = -prev_dy
		var perp_y: float = prev_dx
		var meander: float = sin(float(step) * 0.27 + meander_phase) * 0.014

		for dy in range(-1, 2):
			var ny: int = cy + dy
			if ny < 2 or ny >= map_h - 2:
				continue
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var nx: int = cx + dx
				if nx < 2 or nx >= map_w - 2:
					continue
				var nidx: int = ny * map_w + nx
				if _work_stamp[nidx] == stamp:
					continue
				var nh: float = _height[nidx]
				var dir_len: float = sqrt(float(dx * dx + dy * dy))
				var align: float = (float(dx) * prev_dx + float(dy) * prev_dy) / dir_len
				var bend: float = (float(dx) * perp_x + float(dy) * perp_y) / dir_len
				var score: float = nh - align * 0.008 + bend * meander
				if score < best_score:
					best_score = score
					best_nx = nx
					best_ny = ny

		if best_nx < 0:
			break

		var next_idx: int = best_ny * map_w + best_nx
		if _height[next_idx] >= cur_h:
			uphill_run += 1
			if uphill_run > 12:
				return PackedInt32Array()
		else:
			uphill_run = 0

		prev_dx = float(best_nx - cx)
		prev_dy = float(best_ny - cy)
		cx = best_nx
		cy = best_ny

	var end_idx: int = path[path.size() - 1]
	if _tiers[end_idx] <= Tier.SHALLOW or _river_mask[end_idx] > 0:
		return path
	return PackedInt32Array()


func _stamp_river_path(path: PackedInt32Array) -> void:
	var n: int = path.size()
	var monotonic_h: float = _height[path[0]]
	for i in range(n):
		var idx: int = path[i]
		@warning_ignore("integer_division")
		var py: int = idx / map_w
		var px: int = idx % map_w
		monotonic_h = minf(monotonic_h, _height[idx])
		var progress: float = float(i) / float(maxi(1, n - 1))
		var r_chan: int = 0 if progress < 0.38 else (1 if progress < 0.88 else 2)

		for dy in range(-r_chan, r_chan + 1):
			var ny: int = py + dy
			if ny < 1 or ny >= map_h - 1:
				continue
			for dx in range(-r_chan, r_chan + 1):
				var nx: int = px + dx
				if nx < 1 or nx >= map_w - 1:
					continue
				if dx * dx + dy * dy > r_chan * r_chan + 1:
					continue
				var nidx: int = ny * map_w + nx
				if _tiers[nidx] >= Tier.SAND:
					_tiers[nidx] = Tier.SHALLOW if progress < 0.90 else Tier.CLOSE_OCEAN
					_height[nidx] = minf(_height[nidx], minf(monotonic_h, 0.335))
				_river_mask[nidx] = maxi(_river_mask[nidx], 225)
				_moisture[nidx] = 1.0


func _generate_biomes_and_climate(seed_val: int) -> void:
	var biome_noise := FastNoiseLite.new()
	biome_noise.seed = seed_val + 777
	biome_noise.frequency = 0.011
	biome_noise.fractal_octaves = 3

	var moist_noise := FastNoiseLite.new()
	moist_noise.seed = seed_val + 1523
	moist_noise.frequency = 0.009
	moist_noise.fractal_octaves = 3

	var crystal_cx := PackedFloat32Array()
	var crystal_cy := PackedFloat32Array()
	var crystal_r2 := PackedFloat32Array()
	var pocket_target: int = int(TUNING_KNOBS["CRYSTAL_POCKET_COUNT"])
	for _attempt in range(120):
		if crystal_cx.size() >= pocket_target:
			break
		var tx: int = _rng.randi_range(40, map_w - 41)
		var ty: int = _rng.randi_range(30, map_h - 31)
		var t: int = _tiers[ty * map_w + tx]
		if t >= Tier.SOIL_LOW and t <= Tier.HILLS:
			var rad_p: float = _rng.randf_range(24.0, 40.0)
			crystal_cx.append(float(tx))
			crystal_cy.append(float(ty))
			crystal_r2.append(rad_p * rad_p)

	var pocket_count: int = crystal_cx.size()
	var base_amb: float = float(TUNING_KNOBS["TEMP_AMBIENT_C"])
	var crys_rad_floor: float = float(TUNING_KNOBS["RAD_CRYSTAL_FLOOR"])

	for y in range(map_h):
		var lat_shift: float = _row_lat_shift(y)
		var row_off: int = y * map_w
		for x in range(map_w):
			var idx: int = row_off + x
			var h: float = _height[idx]
			var t: int = _tiers[idx]

			var m_val: float = clampf(moist_noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.52, 0.05, 0.95)
			if t <= Tier.SAND:
				m_val = maxf(m_val, 0.82)
			if _river_mask[idx] > 0:
				m_val = 1.0
			else:
				for r_step in range(1, 5):
					if x + r_step < map_w and _river_mask[idx + r_step] > 0:
						m_val = maxf(m_val, 0.85 - float(r_step) * 0.12)
					if x - r_step >= 0 and _river_mask[idx - r_step] > 0:
						m_val = maxf(m_val, 0.85 - float(r_step) * 0.12)
			_moisture[idx] = m_val

			var lapse: float = maxf(0.0, h - 0.42) * 86.0
			var temp_c: float = base_amb + lat_shift - lapse
			if t <= Tier.SHALLOW:
				temp_c = lerpf(base_amb - 2.0, temp_c, 0.85)
			_temp[idx] = temp_c

			var in_crystal: bool = false
			var b_val: float = biome_noise.get_noise_2d(float(x), float(y))
			for pi in range(pocket_count):
				var dx: float = float(x) - crystal_cx[pi]
				var dy: float = float(y) - crystal_cy[pi]
				var d2: float = dx * dx + dy * dy
				var r2: float = crystal_r2[pi]
				if d2 < r2 * (0.72 + b_val * 0.35):
					in_crystal = true
					# Keep natural pocket radiation within baseline crystal floor so passive pockets don't wake CPU
					_rad[idx] = clampf((1.0 - sqrt(d2 / r2)) * 0.28 + 0.14, 0.14, crys_rad_floor)
					break

			if in_crystal and t >= Tier.SAND and t <= Tier.HILLS:
				_biomes[idx] = Biome.CRYSTAL
			elif m_val > 0.46 or b_val > -0.02:
				_biomes[idx] = Biome.LUSH
				_rad[idx] = 0.015
			else:
				_biomes[idx] = Biome.RUST
				_rad[idx] = 0.015


func _row_lat_shift(py: int) -> float:
	var lat_dist: float = absf(float(py) / float(map_h) - 0.5) * 2.0
	return 4.0 - lat_dist * 14.5


func _carve_volcanic_fissures() -> void:
	var peaks := PackedInt32Array()
	for y in range(28, map_h - 28, 8):
		var row_off: int = y * map_w
		for x in range(28, map_w - 28, 8):
			var idx: int = row_off + x
			if _height[idx] >= 0.71 and _river_mask[idx] == 0:
				peaks.append(idx)

	var pn: int = peaks.size()
	for i in range(pn - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: int = peaks[i]
		peaks[i] = peaks[j]
		peaks[j] = tmp

	var hubs_x := PackedInt32Array()
	var hubs_y := PackedInt32Array()
	var target_hubs: int = int(TUNING_KNOBS["VOLCANO_HUB_COUNT"])

	for pi in range(pn):
		if hubs_x.size() >= target_hubs:
			break
		var idx: int = peaks[pi]
		@warning_ignore("integer_division")
		var hy: int = idx / map_w
		var hx: int = idx % map_w

		var too_close: bool = false
		for hi in range(hubs_x.size()):
			var dx: int = hx - hubs_x[hi]
			var dy: int = hy - hubs_y[hi]
			if dx * dx + dy * dy < 95 * 95:
				too_close = true
				break
		if too_close or _has_water_within(hx, hy, 7):
			continue

		hubs_x.append(hx)
		hubs_y.append(hy)
		_stamp_volcano_hub(hx, hy)

	_enforce_hot_lava_borders_rect(0, 0, map_w, map_h, false)


func _has_hot_lava_within_two(px: int, py: int) -> bool:
	var y0: int = maxi(0, py - 2)
	var y1: int = mini(map_h - 1, py + 2)
	var x0: int = maxi(0, px - 2)
	var x1: int = mini(map_w - 1, px + 2)
	for ny in range(y0, y1 + 1):
		var dy: int = ny - py
		var row_off: int = ny * map_w
		for nx in range(x0, x1 + 1):
			var dx: int = nx - px
			if dx * dx + dy * dy > 5:
				continue
			var nidx: int = row_off + nx
			var nb_b: int = _biomes[nidx]
			if nb_b == Biome.LAVA or (nb_b == Biome.SCORCHED and _temp[nidx] >= 165.0):
				return true
	return false


func _enforce_hot_border_at(px: int, py: int, mark_dirty: bool) -> float:
	var idx: int = py * map_w + px
	var is_lava: bool = _biomes[idx] == Biome.LAVA
	var min_ring1_t: float = 115.0 if is_lava else 85.0
	var temp_delta: float = 0.0
	var y0: int = maxi(0, py - 2)
	var y1: int = mini(map_h - 1, py + 2)
	var x0: int = maxi(0, px - 2)
	var x1: int = mini(map_w - 1, px + 2)
	for ny in range(y0, y1 + 1):
		var dy: int = ny - py
		var row_off: int = ny * map_w
		for nx in range(x0, x1 + 1):
			var dx: int = nx - px
			var d2: int = dx * dx + dy * dy
			if d2 == 0 or d2 > 5:
				continue
			var nidx: int = row_off + nx
			if _tiers[nidx] <= Tier.SHALLOW or _biomes[nidx] == Biome.LAVA:
				continue
			var changed: bool = false
			if d2 <= 2:
				if _biomes[nidx] != Biome.SCORCHED:
					_biomes[nidx] = Biome.SCORCHED
					changed = true
					if _temp[nidx] < min_ring1_t:
						temp_delta += min_ring1_t - _temp[nidx]
						_temp[nidx] = min_ring1_t
				if _moisture[nidx] > 0.12:
					_moisture[nidx] = 0.12
			else:
				if _biomes[nidx] == Biome.LUSH:
					_biomes[nidx] = Biome.RUST
					changed = true
				if _moisture[nidx] > 0.24:
					_moisture[nidx] = 0.24
			if changed and mark_dirty:
				_mark_tile_dirty(nx, ny, true, 0)
	return temp_delta


func _enforce_hot_lava_borders_rect(sx0: int, sy0: int, sx1: int, sy1: int, mark_dirty: bool) -> void:
	var x0: int = maxi(0, sx0)
	var y0: int = maxi(0, sy0)
	var x1: int = mini(map_w, sx1)
	var y1: int = mini(map_h, sy1)
	var sum_d: float = 0.0
	for py in range(y0, y1):
		var row_off: int = py * map_w
		for px in range(x0, x1):
			var idx: int = row_off + px
			if _tiers[idx] <= Tier.SHALLOW:
				continue
			var b: int = _biomes[idx]
			if b == Biome.LAVA or (b == Biome.SCORCHED and _temp[idx] >= 165.0):
				sum_d += _enforce_hot_border_at(px, py, mark_dirty)
	if sum_d != 0.0:
		_temp_total_sum += sum_d
		_avg_temp_cached = _temp_total_sum * _inv_total_tiles


func _has_water_within(cx: int, cy: int, rad: int) -> bool:
	for dy in range(-rad, rad + 1, 2):
		var py: int = clampi(cy + dy, 0, map_h - 1)
		for dx in range(-rad, rad + 1, 2):
			var px: int = clampi(cx + dx, 0, map_w - 1)
			if _tiers[py * map_w + px] <= Tier.SHALLOW:
				return true
	return false


func _stamp_volcano_hub(hx: int, hy: int) -> void:
	var core_r: int = 3
	var rim_r: int = 8
	for dy in range(-rim_r, rim_r + 1):
		var py: int = clampi(hy + dy, 1, map_h - 2)
		for dx in range(-rim_r, rim_r + 1):
			var px: int = clampi(hx + dx, 1, map_w - 2)
			var d2: int = dx * dx + dy * dy
			if d2 > rim_r * rim_r:
				continue
			var idx: int = py * map_w + px
			if _tiers[idx] <= Tier.SHALLOW:
				continue
			if d2 <= core_r * core_r:
				_biomes[idx] = Biome.LAVA
				_vent_mask[idx] = 1
				_temp[idx] = 804.0
				_rad[idx] = maxf(_rad[idx], 0.015)
				_moisture[idx] = 0.0
			else:
				_biomes[idx] = Biome.SCORCHED
				_temp[idx] = maxf(_temp[idx], maxf(28.0, 146.0 - float(d2 - 9) * 3.8))
				_rad[idx] = maxf(_rad[idx], 0.015)
				_moisture[idx] = 0.0

	var fissure_count: int = 4
	for f in range(fissure_count):
		var ang: float = (TAU * float(f) / float(fissure_count)) + _rng.randf_range(-0.4, 0.4)
		var fx: float = float(hx)
		var fy: float = float(hy)
		var flen: int = _rng.randi_range(9, 17)
		for step in range(flen):
			ang += _rng.randf_range(-0.42, 0.42)
			fx += cos(ang) * 1.15
			fy += sin(ang) * 1.15
			var px: int = clampi(int(round(fx)), 2, map_w - 3)
			var py: int = clampi(int(round(fy)), 2, map_h - 3)
			if _has_water_within(px, py, 2):
				break
			for sy in range(-1, 2):
				for sx in range(-1, 2):
					var nidx: int = (py + sy) * map_w + (px + sx)
					if _tiers[nidx] <= Tier.SHALLOW:
						continue
					if sx == 0 and sy == 0:
						_biomes[nidx] = Biome.LAVA
						_vent_mask[nidx] = 1
						_temp[nidx] = maxf(float(TUNING_KNOBS["LAVA_VENT_FLOOR_C"]), 802.0 - float(step) * 0.6)
						_moisture[nidx] = 0.0
					elif _biomes[nidx] != Biome.LAVA:
						_biomes[nidx] = Biome.SCORCHED
						_temp[nidx] = maxf(_temp[nidx], 136.0)
						_moisture[nidx] = 0.0


func _classify_height(h_val: float) -> int:
	if h_val < 0.210:
		return Tier.DEEP_OCEAN
	if h_val < 0.290:
		return Tier.CLOSE_OCEAN
	if h_val < 0.355:
		return Tier.SHALLOW
	if h_val < 0.395:
		return Tier.SAND
	if h_val < 0.505:
		return Tier.SOIL_LOW
	if h_val < 0.605:
		return Tier.SOIL_HIGH
	if h_val < 0.685:
		return Tier.HILLS
	if h_val < 0.755:
		return Tier.MOUNTAINS
	return Tier.SUMMIT


func _init_clouds() -> void:
	var n: int = int(TUNING_KNOBS["CLOUD_COUNT"])
	_cloud_pos.resize(n)
	_cloud_vel.resize(n)
	_cloud_scale.resize(n)
	_cloud_vapor.resize(n)
	_cloud_raining.resize(n)
	var mm: MultiMesh = _mm_clouds.multimesh
	mm.instance_count = n

	var base_vx: float = float(TUNING_KNOBS["CLOUD_SPEED_X"])
	var base_vy: float = float(TUNING_KNOBS["CLOUD_SPEED_Y"])

	for i in range(n):
		_cloud_pos[i] = Vector2(_rng.randf_range(0.0, float(map_w)), _rng.randf_range(0.0, float(map_h)))
		var spd_mul: float = _rng.randf_range(0.75, 1.35)
		_cloud_vel[i] = Vector2(base_vx * spd_mul, base_vy * spd_mul + _rng.randf_range(-0.4, 0.4))
		_cloud_scale[i] = Vector2(1.0, 1.0)
		_cloud_vapor[i] = _rng.randf_range(0.10, 0.35)
		_cloud_raining[i] = 0
		mm.set_instance_color(i, Color(1.0, 1.0, 1.0, 1.0))
		mm.set_instance_custom_data(i, Color(
			_rng.randf(),
			0.0,
			_rng.randf_range(0.64, 1.06),
			_rng.randf_range(0.60, 0.90)
		))
	_sync_cloud_multimesh()


func _sync_cloud_multimesh() -> void:
	var mm: MultiMesh = _mm_clouds.multimesh
	for i in range(_cloud_pos.size()):
		mm.set_instance_transform_2d(i, Transform2D(0.0, _cloud_scale[i], 0.0, _cloud_pos[i]))
		var c_t: float = clampf(_cloud_vapor[i] / float(TUNING_KNOBS["CLOUD_RAIN_THRESH"]), 0.0, 1.0)
		var col: Color = Color(0.54, 0.64, 0.80, 1.0) if _cloud_raining[i] > 0 else Color(
			lerpf(1.0, 0.78, c_t), lerpf(1.0, 0.84, c_t), lerpf(1.0, 0.93, c_t), 1.0
		)
		mm.set_instance_color(i, col)


func _step_clouds(dt: float) -> void:
	var n: int = _cloud_pos.size()
	if n <= 0:
		return
	if _global_vapor_pool > 0.0001:
		var share: float = _global_vapor_pool / float(n)
		_global_vapor_pool = 0.0
		for j in range(n):
			_cloud_vapor[j] = minf(2.4, _cloud_vapor[j] + share)

	var mm: MultiMesh = _mm_clouds.multimesh
	var update_vis: bool = not _clouds_suppressed
	var update_col: bool = update_vis and (_env_step_count & 3) == 0
	var check_rain: bool = (_env_step_count & 3) == 0
	var max_x: float = float(map_w + 96)
	var max_y: float = float(map_h + 48)
	var rain_thresh: float = float(TUNING_KNOBS["CLOUD_RAIN_THRESH"])
	var rain_dep: float = float(TUNING_KNOBS["RAIN_DEPOSIT"])
	var rain_bursts: int = 0
	for i in range(n):
		var cp: Vector2 = _cloud_pos[i] + _cloud_vel[i] * dt
		if cp.x > max_x:
			cp.x = -96.0
		elif cp.x < -96.0:
			cp.x = max_x
		if cp.y > max_y:
			cp.y = -48.0
		elif cp.y < -48.0:
			cp.y = max_y
		_cloud_pos[i] = cp
		if update_vis:
			mm.set_instance_transform_2d(i, Transform2D(0.0, _cloud_scale[i], 0.0, cp))

		if check_rain:
			var cx: int = int(floor(cp.x))
			var cy: int = int(floor(cp.y))
			var in_bounds: bool = cx >= 0 and cx < map_w and cy >= 0 and cy < map_h
			if in_bounds and _cloud_vapor[i] >= rain_thresh:
				var idx: int = cy * map_w + cx
				if _height[idx] >= 0.605 or (_temp[idx] + _cosmic_temp_offset) < 14.0:
					_cloud_raining[i] = 1
			if _cloud_raining[i] > 0:
				_cloud_vapor[i] = maxf(0.0, _cloud_vapor[i] - 2.0 * dt)
				if _cloud_vapor[i] <= 0.25:
					_cloud_raining[i] = 0
				elif in_bounds and rain_bursts < 1:
					rain_bursts += 1
					_deposit_cloud_rain(cx, cy, 14, rain_dep * dt * 4.0)

		if update_col:
			var c_t: float = clampf(_cloud_vapor[i] / rain_thresh, 0.0, 1.0)
			var col: Color = Color(0.54, 0.64, 0.80, 1.0) if _cloud_raining[i] > 0 else Color(
				lerpf(1.0, 0.78, c_t), lerpf(1.0, 0.84, c_t), lerpf(1.0, 0.93, c_t), 1.0
			)
			mm.set_instance_color(i, col)


func _deposit_cloud_rain(cx: int, cy: int, rad: int, deposit_amt: float) -> void:
	var r2: int = rad * rad
	var inv_r2: float = 1.0 / float(maxi(1, r2))
	var mw: int = map_w
	var amb_c: float = float(TUNING_KNOBS["TEMP_AMBIENT_C"])
	var lava_min: float = float(TUNING_KNOBS["LAVA_MIN_TEMP_C"])
	var ash_cut: int = int(round(float(TUNING_KNOBS["ASH_FERTILITY_BOOST"]) * 12.0))
	var any_temp_delta: float = 0.0
	var any_dirty: bool = false
	var any_struct: bool = false
	for dy in range(-rad, rad + 1):
		var py: int = cy + dy
		if py < 0 or py >= map_h:
			continue
		var row_off: int = py * mw
		var dy2: int = dy * dy
		for dx in range(-rad, rad + 1):
			var d2: int = dx * dx + dy2
			if d2 > r2:
				continue
			var px: int = cx + dx
			if px < 0 or px >= mw:
				continue
			var idx: int = row_off + px
			var falloff: float = 1.0 - float(d2) * inv_r2
			var b: int = _biomes[idx]
			_moisture[idx] = clampf(_moisture[idx] + deposit_amt * falloff, 0.0, 1.0)
			if _fire[idx] > 0.0:
				_fire[idx] = 0.0
				_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
				any_dirty = true
				any_struct = true
			if b == Biome.LAVA and _vent_mask[idx] == 0 and _tiers[idx] >= Tier.SAND and falloff > 0.25:
				var prev_lt: float = _temp[idx]
				var next_lt: float = maxf(65.0, prev_lt - 55.0 * falloff)
				_temp[idx] = next_lt
				any_temp_delta += next_lt - prev_lt
				if next_lt < lava_min:
					_biomes[idx] = Biome.SCORCHED
					any_dirty = true
					any_struct = true
			elif _temp[idx] > 26.0 and b != Biome.LAVA:
				var prev_t: float = _temp[idx]
				var next_t: float = lerpf(prev_t, amb_c, 0.20 * falloff)
				_temp[idx] = next_t
				any_temp_delta += next_t - prev_t
			if _ash[idx] > 0 and _moisture[idx] >= 0.30 and b == Biome.SCORCHED and _rad[idx] < 0.22 and _temp[idx] < 44.0 and not _has_hot_lava_within_two(px, py):
				var p_h: int = ((px * 73856093) ^ (py * 19349663)) & 15
				if p_h < ash_cut:
					_biomes[idx] = Biome.LUSH
					_ash[idx] = maxi(0, int(_ash[idx]) - 110)
					if _ash[idx] == 0:
						_ash_tiles = maxi(0, _ash_tiles - 1)
					any_dirty = true
					any_struct = true
	if any_dirty:
		_mark_tile_dirty(cx, cy, any_struct, rad + 1)
	if any_temp_delta != 0.0:
		_temp_total_sum += any_temp_delta
		_avg_temp_cached = _temp_total_sum * _inv_total_tiles
	if _cloud_rain_fx_cd <= 0.0:
		_cloud_rain_fx_cd = 0.35
		surface_impact.emit(Vector2(float(cx) + 0.5, float(cy) + 0.5), float(rad), "rain")


func apply_brush(world_pos: Vector2, brush_mode: int, radius: float = 12.0) -> void:
	_ensure_initialized()
	var mode: int = BrushMode.LOWER_CANAL if brush_mode < 0 else brush_mode
	if mode == BrushMode.ORBITAL_STRIKE:
		apply_orbital_strike(world_pos, radius, false)
		return
	var r: int = clampi(int(round(radius)), 1, 64)
	apply_shaped_brush(world_pos, r, Vector2i(mode, BrushShape.CIRCLE))


func apply_shaped_brush(world_pos: Vector2, radius: int, mode_and_shape: Vector2i) -> void:
	_ensure_initialized()
	var mode: int = BrushMode.LOWER_CANAL if mode_and_shape.x < 0 else mode_and_shape.x
	var shape: int = clampi(mode_and_shape.y, BrushShape.CIRCLE, BrushShape.SPRAY)
	if mode == BrushMode.ORBITAL_STRIKE:
		apply_orbital_strike(world_pos, float(radius), false)
		return
	if mode >= BrushMode.DROP_RAIN and mode <= BrushMode.DROP_SNOW:
		var mapped_k: int = WorldDropsScript.DropKind.RAIN
		if mode == BrushMode.DROP_FIRE:
			mapped_k = WorldDropsScript.DropKind.FIRE
		elif mode == BrushMode.DROP_ACID:
			mapped_k = WorldDropsScript.DropKind.ACID
		elif mode == BrushMode.DROP_SNOW:
			mapped_k = WorldDropsScript.DropKind.SNOW
		spawn_sky_drops(world_pos, float(radius), mapped_k)
		return

	var cx: int = int(floor(world_pos.x))
	var cy: int = int(floor(world_pos.y))
	var r: int = clampi(radius, 1, 64)
	var flags: int = _apply_shaped_brush_loop(cx, cy, r, mode, shape)
	if (flags & 1) == 0 and (mode == BrushMode.PLACE_BOMB or mode == BrushMode.PLACE_MINE):
		var scx: int = clampi(cx, 1, map_w - 2)
		var scy: int = clampi(cy, 1, map_h - 2)
		var sidx: int = scy * map_w + scx
		if _tiers[sidx] >= Tier.SAND and _wall_mask[sidx] == 0:
			_place_bomb_at(sidx, 1 if mode == BrushMode.PLACE_BOMB else 2)
			flags |= 1
	if (flags & 1) == 0:
		return

	var touched_water_lava: bool = (flags & 2) != 0
	var rx0: int = maxi(0, cx - r - 2)
	var ry0: int = maxi(0, cy - r - 2)
	var rx1: int = mini(map_w, cx + r + 3)
	var ry1: int = mini(map_h, cy + r + 3)

	if mode == BrushMode.LOWER_CANAL or mode == BrushMode.SPONGE_DRAIN:
		_seed_water_queue_rect(rx0, ry0, rx1, ry1)
	if mode == BrushMode.LAVA_VOLCANO or mode == BrushMode.METEOR_CRATER or mode == BrushMode.ERASER:
		_rebuild_vent_tiles_cache()
	if mode == BrushMode.ERASER:
		_erase_hazards_in_radius(world_pos, float(r))
	elif mode == BrushMode.BIOME_CREEP_MYCELIUM or mode == BrushMode.BIOME_CREEP_CYBER:
		var creep_b: int = Biome.CREEP_MYCELIUM if mode == BrushMode.BIOME_CREEP_MYCELIUM else Biome.CREEP_CYBER
		_ensure_creep_node_near(Vector2i(clampi(cx, 1, map_w - 2), clampi(cy, 1, map_h - 2)), creep_b)
	if touched_water_lava:
		_global_vapor_pool += 0.35

	_enforce_hot_lava_borders_rect(rx0 - 2, ry0 - 2, rx1 + 2, ry1 + 2, false)
	_mark_chunks_in_rect(cx - r - 1, cy - r - 1, r * 2 + 3, r * 2 + 3, false)
	_recompute_bio_chunks_rect(rx0, ry0, rx1, ry1)
	_recompute_avg_temp_full()
	_render_rect(rx0, ry0, rx1 - rx0, ry1 - ry0)

	if mode != BrushMode.VORTEX_PULL:
		region_changed.emit(Rect2i(rx0, ry0, rx1 - rx0, ry1 - ry0))
	if mode == BrushMode.METEOR_CRATER:
		surface_impact.emit(world_pos, float(r), "meteor")
	elif mode == BrushMode.LAVA_VOLCANO:
		surface_impact.emit(world_pos, float(r), "steam" if touched_water_lava else "lava")
	elif touched_water_lava:
		surface_impact.emit(world_pos, float(r), "steam")


func _tile_in_brush_shape(dx: int, dy: int, r: int, shape: int) -> float:
	if shape == BrushShape.SQUARE:
		if absi(dx) > r or absi(dy) > r:
			return -1.0
		return float(maxi(absi(dx), absi(dy))) / float(r)
	if shape == BrushShape.DIAMOND:
		var manh: int = absi(dx) + absi(dy)
		if manh > r:
			return -1.0
		return float(manh) / float(r)
	var d2: float = float(dx * dx + dy * dy)
	if d2 > float(r * r):
		return -1.0
	var norm_d: float = sqrt(d2) / float(r)
	if shape == BrushShape.SPRAY and (dx != 0 or dy != 0):
		if _drop_rng.randf() > (0.62 - 0.38 * norm_d):
			return -1.0
	return norm_d


func _apply_shaped_brush_loop(cx: int, cy: int, r: int, mode: int, shape: int) -> int:
	var any_changed: bool = false
	var touched_wl: bool = false
	for dy in range(-r, r + 1):
		var py: int = cy + dy
		if py < 0 or py >= map_h:
			continue
		var row_off: int = py * map_w
		for dx in range(-r, r + 1):
			var px: int = cx + dx
			if px < 0 or px >= map_w:
				continue
			var norm_d: float = _tile_in_brush_shape(dx, dy, r, shape)
			if norm_d < 0.0:
				continue
			var res: int = _apply_brush_tile(px, py, dx, dy, cx, row_off + px, norm_d, mode)
			if (res & 1) != 0:
				any_changed = true
			if (res & 2) != 0:
				touched_wl = true
	return (1 if any_changed else 0) | (2 if touched_wl else 0)


func _apply_brush_tile(px: int, py: int, dx: int, dy: int, cx: int, idx: int, norm_d: float, mode: int) -> int:
	var falloff: float = 1.0 - norm_d
	match mode:
		BrushMode.TERRAFORM_LIFE:
			return _brush_tile_terraform(idx, falloff)
		BrushMode.LOWER_CANAL:
			return _brush_tile_canal(idx, falloff)
		BrushMode.CRYSTAL_FLORA:
			return _brush_tile_crystal(idx, norm_d, falloff)
		BrushMode.LAVA_VOLCANO:
			return _brush_tile_lava(px, py, dx, dy, cx, idx, norm_d, falloff)
		BrushMode.METEOR_CRATER:
			return _brush_tile_meteor(idx, norm_d, falloff)
		BrushMode.VORTEX_PULL:
			if _temp[idx] > 35.0:
				_temp[idx] = maxf(24.0, _temp[idx] - 18.0 * falloff)
				return 1
			return 0
		_:
			return _brush_tile_extended(px, py, idx, mode)


func _brush_tile_terraform(idx: int, falloff: float) -> int:
	_vent_mask[idx] = 0
	_wall_mask[idx] = 0
	_clear_frost_at(idx)
	if _fire[idx] > 0.0:
		_fire[idx] = 0.0
		_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
	if _ash[idx] > 0:
		_ash[idx] = 0
		_ash_tiles = maxi(0, _ash_tiles - 1)
	if _tiers[idx] <= Tier.SHALLOW:
		var lift: float = falloff * 0.24
		_height[idx] = clampf(_height[idx] + lift, 0.0, 0.62)
		_tiers[idx] = _classify_height(_height[idx])
		if _tiers[idx] >= Tier.SAND:
			_river_mask[idx] = 0
	if _tiers[idx] >= Tier.SAND:
		_biomes[idx] = Biome.LUSH
	_temp[idx] = lerpf(_temp[idx], 21.0, clampf(0.45 + 0.50 * falloff, 0.0, 1.0))
	_moisture[idx] = clampf(maxf(_moisture[idx], 0.55 + 0.35 * falloff), 0.0, 1.0)
	_rad[idx] *= 0.25
	return 1


func _brush_tile_canal(idx: int, falloff: float) -> int:
	var touched_wl: int = 0
	_vent_mask[idx] = 0
	_wall_mask[idx] = 0
	_clear_frost_at(idx)
	if _fire[idx] > 0.0:
		_fire[idx] = 0.0
		_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
	var was_land: bool = _tiers[idx] >= Tier.SAND
	var sink: float = 0.06 + falloff * 0.20
	_height[idx] = clampf(_height[idx] - sink, 0.08, 0.95)
	if was_land:
		_tiers[idx] = Tier.SAND if _height[idx] <= 0.355 else _classify_height(_height[idx])
		if _biomes[idx] == Biome.LAVA:
			_biomes[idx] = Biome.SCORCHED
		_moisture[idx] = maxf(_moisture[idx], 0.32 * falloff)
	else:
		_tiers[idx] = _classify_height(_height[idx])
		if _tiers[idx] <= Tier.SHALLOW:
			if _temp[idx] > 120.0 or _biomes[idx] == Biome.LAVA:
				touched_wl = 2
			_biomes[idx] = Biome.RUST
			_temp[idx] = minf(_temp[idx], 28.0)
			_moisture[idx] = 1.0
			if _ash[idx] > 0:
				_ash[idx] = 0
				_ash_tiles = maxi(0, _ash_tiles - 1)
	return 1 | touched_wl


func _brush_tile_crystal(idx: int, norm_d: float, falloff: float) -> int:
	_clear_frost_at(idx)
	if _fire[idx] > 0.0:
		_fire[idx] = 0.0
		_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
	if _tiers[idx] == Tier.SHALLOW and norm_d < 0.45:
		_height[idx] = maxf(_height[idx], 0.365)
		_tiers[idx] = Tier.SAND
		_river_mask[idx] = 0
	if _tiers[idx] >= Tier.SAND and _tiers[idx] <= Tier.HILLS:
		_biomes[idx] = Biome.CRYSTAL
		_vent_mask[idx] = 0
	_rad[idx] = clampf(maxf(_rad[idx], 0.45 + 0.48 * falloff), 0.0, 1.0)
	_temp[idx] = minf(_temp[idx], 34.0)
	_moisture[idx] = maxf(_moisture[idx], 0.32)
	return 1


func _brush_tile_lava(px: int, py: int, dx: int, dy: int, cx: int, idx: int, norm_d: float, falloff: float) -> int:
	var touched_wl: int = 0
	_clear_frost_at(idx)
	if _tiers[idx] <= Tier.CLOSE_OCEAN:
		_height[idx] = clampf(_height[idx] + falloff * 0.22, 0.0, 0.72)
		_tiers[idx] = _classify_height(_height[idx])
		if _tiers[idx] >= Tier.SAND:
			_biomes[idx] = Biome.SCORCHED
			_temp[idx] = maxf(_temp[idx], 220.0)
			_river_mask[idx] = 0
			touched_wl = 2
	else:
		_height[idx] = clampf(_height[idx] + falloff * 0.14, 0.0, 0.88)
		_tiers[idx] = maxi(_tiers[idx], _classify_height(_height[idx]))
		_river_mask[idx] = 0
		var ang_f: float = atan2(float(dy), float(dx))
		var crack_wave: float = absf(sin(ang_f * 5.0 + float(cx) * 0.17 + norm_d * 4.5))
		var vein_hash: int = ((px * 73856093) ^ (py * 19349663)) & 7
		if norm_d < 0.24 or (norm_d < 0.74 and crack_wave > 0.82 and vein_hash < 5):
			_biomes[idx] = Biome.LAVA
			_temp[idx] = lerpf(580.0, float(TUNING_KNOBS["LAVA_SOURCE_TEMP_C"]), falloff)
			if norm_d < 0.18:
				_vent_mask[idx] = 1
			if _fire[idx] > 0.0:
				_fire[idx] = 0.0
				_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
		else:
			var prev_b: int = _biomes[idx]
			if prev_b != Biome.LAVA:
				if prev_b == Biome.LUSH and norm_d > 0.62 and _moisture[idx] < 0.72:
					_ignite_tile(idx, 0.85)
				else:
					_biomes[idx] = Biome.SCORCHED
			_temp[idx] = maxf(_temp[idx], 155.0 + 240.0 * falloff)
		_moisture[idx] = 0.0
		_rad[idx] = maxf(_rad[idx], 0.18 * falloff)
		if _bomb_map[idx] > 0:
			_enqueue_bomb_detonation(idx)
	return 1 | touched_wl


func _brush_tile_meteor(idx: int, norm_d: float, falloff: float) -> int:
	var touched_wl: int = 0
	_vent_mask[idx] = 0
	_wall_mask[idx] = 0
	_clear_frost_at(idx)
	if _bomb_map[idx] > 0:
		_enqueue_bomb_detonation(idx)
	var orig_land: bool = _height[idx] >= 0.40
	if norm_d < 0.66:
		var bowl: float = 1.0 - (norm_d / 0.66) * (norm_d / 0.66)
		var min_floor: float = 0.362 if orig_land else 0.06
		_height[idx] = clampf(_height[idx] - bowl * 0.18, min_floor, 0.95)
		_tiers[idx] = _classify_height(_height[idx])
		if _tiers[idx] >= Tier.SAND:
			_river_mask[idx] = 0
			if norm_d < 0.20:
				_biomes[idx] = Biome.LAVA
				_temp[idx] = maxf(_temp[idx], 690.0)
				if _fire[idx] > 0.0:
					_fire[idx] = 0.0
					_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
			else:
				_biomes[idx] = Biome.SCORCHED
				_temp[idx] = maxf(_temp[idx], 260.0 + 360.0 * bowl)
				if _ash[idx] == 0:
					_ash[idx] = 120
					_ash_tiles += 1
		else:
			touched_wl = 2
			_temp[idx] = maxf(_temp[idx], 85.0)
			if _fire[idx] > 0.0:
				_fire[idx] = 0.0
				_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
	else:
		var rim_phase: float = sin(((norm_d - 0.66) / 0.34) * PI)
		_height[idx] = clampf(_height[idx] + rim_phase * 0.085, 0.0, 0.96)
		_tiers[idx] = _classify_height(_height[idx])
		if _tiers[idx] >= Tier.SAND:
			if _biomes[idx] == Biome.LUSH and _moisture[idx] < 0.72:
				_ignite_tile(idx, 0.90)
			else:
				_biomes[idx] = Biome.SCORCHED
			_river_mask[idx] = 0
		_temp[idx] = maxf(_temp[idx], 125.0 + 135.0 * rim_phase)
	_rad[idx] = clampf(_rad[idx] + 0.55 * falloff, 0.0, 1.0)
	_moisture[idx] *= 0.25
	return 1 | touched_wl


func _brush_tile_extended(px: int, py: int, idx: int, mode: int) -> int:
	if mode == BrushMode.WALL_ROCK or mode == BrushMode.WALL_ENERGY:
		_wall_mask[idx] = 1 if mode == BrushMode.WALL_ROCK else 2
		_vent_mask[idx] = 0
		_river_mask[idx] = 0
		_clear_frost_at(idx)
		if mode == BrushMode.WALL_ROCK and _height[idx] < 0.74:
			_height[idx] = 0.74
			_tiers[idx] = Tier.MOUNTAINS
		elif _tiers[idx] <= Tier.SHALLOW:
			_height[idx] = 0.42
			_tiers[idx] = Tier.SOIL_LOW
		if _fire[idx] > 0.0:
			_fire[idx] = 0.0
			_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
		return 1
	if mode == BrushMode.SPONGE_DRAIN:
		_set_goo_at(idx, false)
		_clear_frost_at(idx)
		_river_mask[idx] = 0
		_moisture[idx] = minf(_moisture[idx], 0.15)
		if _tiers[idx] <= Tier.SHALLOW:
			_height[idx] = 0.375
			_tiers[idx] = Tier.SAND
		return 1
	if mode == BrushMode.ERASER:
		return _erase_tile_at(idx)
	if mode >= BrushMode.BIOME_XENO_JUNGLE and mode <= BrushMode.BIOME_CREEP_CYBER:
		var target_b: int = Biome.XENO_JUNGLE + (mode - BrushMode.BIOME_XENO_JUNGLE)
		if _tiers[idx] >= Tier.SAND and _tiers[idx] <= Tier.HILLS and _biomes[idx] != Biome.LAVA:
			_biomes[idx] = target_b
			if target_b == Biome.CRYO_TUNDRA:
				_temp[idx] = minf(_temp[idx], -4.0)
			return 1
		return 0
	if mode == BrushMode.PLACE_BOMB or mode == BrushMode.PLACE_MINE:
		if _tiers[idx] >= Tier.SAND and _wall_mask[idx] == 0 and (px & 3) == 0 and (py & 3) == 0:
			_place_bomb_at(idx, 1 if mode == BrushMode.PLACE_BOMB else 2)
			return 1
		return 0
	if mode == BrushMode.PLACE_GREY_GOO and _tiers[idx] >= Tier.SAND:
		_set_goo_at(idx, true)
		return 1
	if mode == BrushMode.PLACE_CONWAY and _tiers[idx] >= Tier.SAND:
		_set_conway_at(idx, true)
		return 1
	return 0


func _clear_frost_at(idx: int) -> void:
	if _frost[idx] > 0:
		_frost[idx] = 0
		_frost_tiles = maxi(0, _frost_tiles - 1)


func _enqueue_water_tile(idx: int) -> void:
	if _wq_count >= WATER_QUEUE_CAP or _work_stamp[idx] == _wq_stamp_id:
		return
	if _tiers[idx] < Tier.SAND or _height[idx] > 0.355:
		return
	_work_stamp[idx] = _wq_stamp_id
	_water_queue[_wq_tail] = idx
	_wq_tail = (_wq_tail + 1) % WATER_QUEUE_CAP
	_wq_count += 1


func _seed_water_queue_rect(rx0: int, ry0: int, rx1: int, ry1: int) -> void:
	var x0: int = maxi(1, rx0 - 1)
	var y0: int = maxi(1, ry0 - 1)
	var x1: int = mini(map_w - 1, rx1 + 1)
	var y1: int = mini(map_h - 1, ry1 + 1)
	var mw: int = map_w
	for py in range(y0, y1):
		var row_off: int = py * mw
		for px in range(x0, x1):
			var idx: int = row_off + px
			if _tiers[idx] >= Tier.SAND and _height[idx] <= 0.355:
				if (
					_tiers[idx - 1] <= Tier.SHALLOW
					or _tiers[idx + 1] <= Tier.SHALLOW
					or _tiers[idx - mw] <= Tier.SHALLOW
					or _tiers[idx + mw] <= Tier.SHALLOW
				):
					_enqueue_water_tile(idx)


func _step_water_flow() -> void:
	if _wq_count <= 0:
		return
	var budget: int = mini(_wq_count, int(TUNING_KNOBS["WATER_FLOW_TILES_PER_TICK"]))
	var mw: int = map_w
	var mh: int = map_h
	var temp_delta: float = 0.0
	for _k in range(budget):
		var idx: int = _water_queue[_wq_head]
		_wq_head = (_wq_head + 1) % WATER_QUEUE_CAP
		_wq_count -= 1
		if _tiers[idx] < Tier.SAND or _height[idx] > 0.355:
			continue
		@warning_ignore("integer_division")
		var py: int = idx / mw
		var px: int = idx % mw
		if px <= 0 or px >= mw - 1 or py <= 0 or py >= mh - 1:
			continue
		if (
			_tiers[idx - 1] > Tier.SHALLOW
			and _tiers[idx + 1] > Tier.SHALLOW
			and _tiers[idx - mw] > Tier.SHALLOW
			and _tiers[idx + mw] > Tier.SHALLOW
		):
			continue
		_tiers[idx] = Tier.SHALLOW
		_biomes[idx] = Biome.RUST
		_vent_mask[idx] = 0
		_moisture[idx] = 1.0
		if _fire[idx] > 0.0:
			_fire[idx] = 0.0
			_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
		if _ash[idx] > 0:
			_ash[idx] = 0
			_ash_tiles = maxi(0, _ash_tiles - 1)
		if _temp[idx] > 28.0:
			temp_delta += 28.0 - _temp[idx]
			_temp[idx] = 28.0
		if _river_mask[idx - 1] > 0 or _river_mask[idx + 1] > 0 or _river_mask[idx - mw] > 0 or _river_mask[idx + mw] > 0:
			_river_mask[idx] = 190
		_mark_tile_dirty(px, py, true, 1)
		_propagate_water_neighbors(px, py)
	if temp_delta != 0.0:
		_temp_total_sum += temp_delta
		_avg_temp_cached = _temp_total_sum * _inv_total_tiles


func _propagate_water_neighbors(px: int, py: int) -> void:
	var mw: int = map_w
	var mh: int = map_h
	for dy in range(-1, 2):
		var ny: int = py + dy
		if ny < 1 or ny >= mh - 1:
			continue
		var row_off: int = ny * mw
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx: int = px + dx
			if nx < 1 or nx >= mw - 1:
				continue
			var nidx: int = row_off + nx
			if _tiers[nidx] >= Tier.SAND:
				if (dx == 0 or dy == 0) and _height[nidx] <= 0.355:
					_enqueue_water_tile(nidx)
				else:
					_moisture[nidx] = clampf(_moisture[nidx] + 0.35, 0.0, 1.0)
					if _ash[nidx] > 0 and _temp[nidx] < 44.0:
						_activate_tile_row(nx, ny)


func apply_vortex_catalyst(world_pos: Vector2, drag_vel: Vector2, cryo_mode: bool) -> void:
	_ensure_initialized()
	var cx: int = int(floor(world_pos.x))
	var cy: int = int(floor(world_pos.y))
	var r: int = 14
	for ci in range(_cloud_pos.size()):
		if _cloud_pos[ci].distance_to(world_pos) <= 56.0:
			var pull_tgt: Vector2 = world_pos + drag_vel.limit_length(24.0)
			_cloud_pos[ci] = _cloud_pos[ci].lerp(pull_tgt, 0.18)
			if cryo_mode and _cloud_vapor[ci] >= float(TUNING_KNOBS["CLOUD_RAIN_THRESH"]):
				_cloud_raining[ci] = 1
	_sync_cloud_multimesh()

	var changed: bool = false
	var struct_hit: bool = false
	if cryo_mode:
		var res: int = _apply_vortex_cryo(cx, cy, r)
		changed = (res & 1) != 0
		struct_hit = (res & 2) != 0
	elif drag_vel.length_squared() > 0.01:
		var dir: Vector2 = drag_vel.normalized()
		var step_px: float = clampf(drag_vel.length() * 0.08, 2.0, 6.0)
		var dx_adv: int = clampi(int(round(dir.x * step_px)), -6, 6)
		var dy_adv: int = clampi(int(round(dir.y * step_px)), -6, 6)
		if dx_adv != 0 or dy_adv != 0:
			changed = _apply_vortex_advect(cx, cy, r, dx_adv, dy_adv)

	if not changed:
		return
	var rx0: int = maxi(0, cx - r - 7)
	var ry0: int = maxi(0, cy - r - 7)
	var rx1: int = mini(map_w, cx + r + 8)
	var ry1: int = mini(map_h, cy + r + 8)
	_avg_temp_cached = _temp_total_sum * _inv_total_tiles
	_render_rect(rx0, ry0, rx1 - rx0, ry1 - ry0)
	if struct_hit:
		region_changed.emit(Rect2i(rx0, ry0, rx1 - rx0, ry1 - ry0))


func _apply_vortex_cryo(cx: int, cy: int, r: int) -> int:
	var r2: float = float(r * r)
	var tgt_c: float = -12.0 - _cosmic_temp_offset
	var flags: int = 0
	var temp_delta: float = 0.0
	for dy in range(-r, r + 1):
		var py: int = cy + dy
		if py < 1 or py >= map_h - 1:
			continue
		var row_off: int = py * map_w
		for dx in range(-r, r + 1):
			var px: int = cx + dx
			if px < 1 or px >= map_w - 1:
				continue
			var d2: float = float(dx * dx + dy * dy)
			if d2 > r2:
				continue
			var falloff: float = 1.0 - sqrt(d2) / float(r)
			var idx: int = row_off + px
			flags |= 1
			if _fire[idx] > 0.0:
				_fire[idx] = 0.0
				_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
			var old_t: float = _temp[idx]
			var new_t: float = lerpf(old_t, tgt_c, clampf(0.45 + 0.50 * falloff, 0.0, 1.0))
			_temp[idx] = new_t
			temp_delta += new_t - old_t
			if _vent_mask[idx] > 0 and new_t < 240.0:
				_seal_vent_tile(idx, px, py)
				flags |= 2
			if _tiers[idx] == Tier.SHALLOW and _biomes[idx] != Biome.LAVA:
				var prev_f: int = _frost[idx]
				var next_f: int = mini(255, prev_f + int(round(72.0 * falloff)))
				if next_f > prev_f:
					_frost[idx] = next_f
					if prev_f == 0:
						_frost_tiles += 1
					if prev_f < 128 and next_f >= 128:
						flags |= 2
			_activate_tile_row(px, py)
	_temp_total_sum += temp_delta
	return flags


func _apply_vortex_advect(cx: int, cy: int, r: int, dx_adv: int, dy_adv: int) -> bool:
	var r2: float = float(r * r)
	var mw: int = map_w
	var mh: int = map_h
	var adv_rate: float = float(TUNING_KNOBS["VORTEX_ADVECTION_RATE"])
	var any_hit: bool = false
	var y_from: int = r if dy_adv > 0 else -r
	var y_to: int = -r - 1 if dy_adv > 0 else r + 1
	var y_step: int = -1 if dy_adv > 0 else 1
	var x_from: int = r if dx_adv > 0 else -r
	var x_to: int = -r - 1 if dx_adv > 0 else r + 1
	var x_step: int = -1 if dx_adv > 0 else 1

	var dy: int = y_from
	while dy != y_to:
		var py: int = cy + dy
		if py >= 1 and py < mh - 1:
			var dx: int = x_from
			while dx != x_to:
				var d2: float = float(dx * dx + dy * dy)
				var px: int = cx + dx
				if d2 <= r2 and px >= 1 and px < mw - 1:
					var falloff: float = 1.0 - sqrt(d2) / float(r)
					var rate: float = adv_rate * falloff
					var idx: int = py * mw + px
					var tx: int = clampi(px + dx_adv, 1, mw - 2)
					var ty: int = clampi(py + dy_adv, 1, mh - 2)
					var tidx: int = ty * mw + tx
					if tidx != idx:
						if _fire[idx] > 0.08:
							var df: float = _fire[idx] * rate
							_fire[idx] -= df
							if _fire[idx] < 0.04:
								_fire[idx] = 0.0
								_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
							if _tiers[tidx] >= Tier.SAND and _tiers[tidx] < Tier.SUMMIT and _biomes[tidx] != Biome.LAVA:
								_ignite_tile(tidx, clampf(df + 0.24, 0.2, 1.1))
							_activate_tile_row(tx, ty)
							any_hit = true
						if _rad[idx] > 0.05:
							var dr: float = (_rad[idx] - 0.015) * rate * 0.65
							_rad[idx] -= dr
							_rad[tidx] = minf(1.0, _rad[tidx] + dr)
							if _rad[tidx] > 0.45:
								_activate_tile_row(tx, ty)
							any_hit = true
						if _moisture[idx] > 0.08:
							var dm: float = _moisture[idx] * rate * 0.45
							_moisture[idx] -= dm
							if _temp[idx] > 45.0:
								_global_vapor_pool += dm * 0.5
								_moisture[tidx] = minf(1.0, _moisture[tidx] + dm * 0.5)
							else:
								_moisture[tidx] = minf(1.0, _moisture[tidx] + dm)
							any_hit = true
						if _temp[idx] > 32.0:
							var dt_hot: float = (_temp[idx] - 25.0) * rate * 0.25
							_temp[idx] -= dt_hot
							_temp[tidx] += dt_hot
							_activate_tile_row(tx, ty)
							any_hit = true
				dx += x_step
		dy += y_step
	return any_hit


func apply_orbital_strike(world_pos: Vector2, radius: float, intercepted: bool) -> void:
	_ensure_initialized()
	var cx: int = int(floor(world_pos.x))
	var cy: int = int(floor(world_pos.y))
	var r: int = clampi(int(round(radius)), 2, 64)
	var r2: float = float(r * r)
	var rad_crys_floor: float = float(TUNING_KNOBS["RAD_CRYSTAL_FLOOR"])
	var any_changed: bool = false

	for dy in range(-r, r + 1):
		var py: int = cy + dy
		if py < 0 or py >= map_h:
			continue
		var row_off: int = py * map_w
		for dx in range(-r, r + 1):
			var px: int = cx + dx
			if px < 0 or px >= map_w:
				continue
			var d2: float = float(dx * dx + dy * dy)
			if d2 > r2:
				continue
			var norm_d: float = sqrt(d2) / float(r)
			var idx: int = row_off + px
			any_changed = true

			if intercepted:
				# Harmless conductive plasma ground shimmer only (zero cratering, fire, or unit/structure damage)
				var ring_wave: float = 0.5 + 0.5 * sin(norm_d * 14.0 + atan2(float(dy), float(dx)) * 3.0)
				var hv_p: int = ((px * 73856093) ^ (py * 19349663)) & 7
				var shimmer: int = 0
				if norm_d >= 0.56:
					shimmer = clampi(int(round(135.0 + 85.0 * sin(((norm_d - 0.56) / 0.44) * PI))), 110, 220)
				elif ring_wave > 0.55 or hv_p < 3:
					shimmer = 115 + (hv_p * 12)
				else:
					shimmer = 72
				var q_shimmer: int = clampi(((shimmer + 16) & 0xE0) - 1, 63, 223)
				_plasma_glow[idx] = maxi(_plasma_glow[idx], q_shimmer)
				continue

			# Unintercepted Orbital Strike: concentrated vitrified scorched crater (depth 0.18 centered)
			_vent_mask[idx] = 0
			_clear_frost_at(idx)
			var orig_land: bool = _height[idx] >= 0.40
			var falloff: float = 1.0 - norm_d
			if norm_d < 0.62:
				var bowl: float = 1.0 - (norm_d / 0.62) * (norm_d / 0.62)
				var min_floor: float = 0.362 if orig_land else 0.06
				_height[idx] = clampf(_height[idx] - bowl * 0.18, min_floor, 0.95)
				_tiers[idx] = _classify_height(_height[idx])
				if _tiers[idx] >= Tier.SAND:
					_river_mask[idx] = 0
					_biomes[idx] = Biome.SCORCHED
					if norm_d < 0.24:
						_temp[idx] = maxf(_temp[idx], 460.0 + 240.0 * bowl)
						_ignite_tile(idx, 1.0)
					else:
						_temp[idx] = maxf(_temp[idx], 240.0 + 240.0 * bowl)
						if _ash[idx] == 0:
							_ash[idx] = 140
							_ash_tiles += 1
						if norm_d < 0.42 and _moisture[idx] < 0.72:
							_ignite_tile(idx, 0.78)
				else:
					_temp[idx] = maxf(_temp[idx], 95.0)
					if _fire[idx] > 0.0:
						_fire[idx] = 0.0
						_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
			else:
				var rim_phase: float = sin(((norm_d - 0.62) / 0.38) * PI)
				_height[idx] = clampf(_height[idx] + rim_phase * 0.065, 0.0, 0.96)
				_tiers[idx] = _classify_height(_height[idx])
				if _tiers[idx] >= Tier.SAND:
					_river_mask[idx] = 0
					var shard_hash: int = ((px * 73856093) ^ (py * 19349663)) & 7
					if _tiers[idx] <= Tier.HILLS and (shard_hash == 1 or shard_hash == 5 or shard_hash == 7):
						_biomes[idx] = Biome.CRYSTAL
						_rad[idx] = clampf(maxf(_rad[idx], 0.32), 0.0, rad_crys_floor)
						_plasma_glow[idx] = maxi(_plasma_glow[idx], 191)
					else:
						_biomes[idx] = Biome.SCORCHED
						if _ash[idx] == 0 and rim_phase < 0.55:
							_ash[idx] = 95
							_ash_tiles += 1
					_temp[idx] = maxf(_temp[idx], 165.0 + 185.0 * rim_phase)
				else:
					_temp[idx] = maxf(_temp[idx], 65.0)
			_rad[idx] = clampf(_rad[idx] + 0.32 * falloff, 0.0, 1.0)
			_moisture[idx] *= 0.20

	if not any_changed:
		return

	var rx0: int = maxi(0, cx - r - 2)
	var ry0: int = maxi(0, cy - r - 2)
	var rx1: int = mini(map_w, cx + r + 3)
	var ry1: int = mini(map_h, cy + r + 3)

	if not intercepted:
		_enforce_hot_lava_borders_rect(rx0 - 2, ry0 - 2, rx1 + 2, ry1 + 2, false)
	_mark_chunks_in_rect(cx - r - 1, cy - r - 1, r * 2 + 3, r * 2 + 3, false)
	if not intercepted:
		_recompute_avg_temp_full()
	_render_rect(rx0, ry0, rx1 - rx0, ry1 - ry0)

	if not intercepted:
		region_changed.emit(Rect2i(rx0, ry0, rx1 - rx0, ry1 - ry0))
		surface_impact.emit(world_pos, float(r), "orbital_strike")


func sample_dominant_element(world_pos: Vector2, radius: float) -> String:
	_ensure_initialized()
	var cx: int = int(floor(world_pos.x))
	var cy: int = int(floor(world_pos.y))
	var r: int = clampi(int(round(radius)), 2, 48)
	var r2: int = r * r
	var step: int = 2 if r > 14 else 1

	var lava_w: float = 0.0
	var fire_w: float = 0.0
	var crystal_w: float = 0.0
	var water_w: float = 0.0

	for dy in range(-r, r + 1, step):
		var py: int = cy + dy
		if py < 0 or py >= map_h:
			continue
		var row_off: int = py * map_w
		for dx in range(-r, r + 1, step):
			if dx * dx + dy * dy > r2:
				continue
			var px: int = cx + dx
			if px < 0 or px >= map_w:
				continue
			var idx: int = row_off + px
			var f_v: float = _fire[idx]
			var b: int = _biomes[idx]
			var t: int = _tiers[idx]
			if f_v > 0.08:
				fire_w += 1.4 + f_v
			if b == Biome.LAVA or _temp[idx] >= 480.0:
				lava_w += 1.8
			elif b == Biome.CRYSTAL or _rad[idx] >= 0.45:
				crystal_w += 1.5
			elif t <= Tier.SHALLOW or _river_mask[idx] > 0:
				water_w += 1.0

	var threshold: float = 2.5 if step == 1 else 1.4
	var best_name: String = "earth"
	var best_w: float = threshold
	if lava_w >= best_w:
		best_w = lava_w
		best_name = "lava"
	if fire_w > best_w:
		best_w = fire_w
		best_name = "fire"
	if crystal_w > best_w:
		best_w = crystal_w
		best_name = "crystal"
	if water_w > best_w:
		best_name = "water"
	return best_name


func apply_elemental_storm(world_pos: Vector2, radius: float, kind: String) -> void:
	_ensure_initialized()
	var cx: int = int(floor(world_pos.x))
	var cy: int = int(floor(world_pos.y))
	var r: int = clampi(int(round(radius)), 2, 48)
	var r2: float = float(r * r)
	var amb_c: float = float(TUNING_KNOBS["TEMP_AMBIENT_C"])
	var k_low: String = kind.to_lower()
	var storm_id: int = _classify_storm_kind(k_low)
	if storm_id < 0:
		return

	var any_changed: bool = false
	for dy in range(-r, r + 1):
		var py: int = cy + dy
		if py < 0 or py >= map_h:
			continue
		var row_off: int = py * map_w
		for dx in range(-r, r + 1):
			var px: int = cx + dx
			if px < 0 or px >= map_w:
				continue
			var d2: float = float(dx * dx + dy * dy)
			if d2 > r2:
				continue
			var norm_d: float = sqrt(d2) / float(r)
			var falloff: float = 1.0 - norm_d
			var idx: int = row_off + px
			if _apply_storm_tile(storm_id, px, py, idx, norm_d, falloff, amb_c):
				any_changed = true

	if not any_changed:
		return

	var rx0: int = maxi(0, cx - r - 2)
	var ry0: int = maxi(0, cy - r - 2)
	var rx1: int = mini(map_w, cx + r + 3)
	var ry1: int = mini(map_h, cy + r + 3)
	_enforce_hot_lava_borders_rect(rx0 - 2, ry0 - 2, rx1 + 2, ry1 + 2, false)
	_mark_chunks_in_rect(cx - r - 1, cy - r - 1, r * 2 + 3, r * 2 + 3, false)
	_recompute_avg_temp_full()
	_render_rect(rx0, ry0, rx1 - rx0, ry1 - ry0)
	region_changed.emit(Rect2i(rx0, ry0, rx1 - rx0, ry1 - ry0))
	var ev_names := ["rain", "firestorm", "ion_storm", "meltdown"]
	surface_impact.emit(world_pos, float(r), ev_names[storm_id])


func _classify_storm_kind(k_low: String) -> int:
	if k_low == "rain" or k_low == "rainburst" or k_low == "monsoon" or k_low == "water":
		return 0
	if k_low == "firestorm" or k_low == "fire" or k_low == "lava":
		return 1
	if k_low == "ion_storm" or k_low == "ion" or k_low == "crystal":
		return 2
	if k_low == "meltdown_crater" or k_low == "meltdown":
		return 3
	return -1


func _apply_storm_tile(storm_id: int, px: int, py: int, idx: int, norm_d: float, falloff: float, amb_c: float) -> bool:
	var t: int = _tiers[idx]
	var b: int = _biomes[idx]
	if storm_id == 0:
		_clear_frost_at(idx)
		if _fire[idx] > 0.0:
			_fire[idx] = 0.0
			_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
		_moisture[idx] = clampf(_moisture[idx] + 0.42 * falloff, 0.0, 1.0)
		_temp[idx] = lerpf(_temp[idx], amb_c, clampf(0.45 + 0.45 * falloff, 0.0, 1.0))
		if b == Biome.LAVA and _vent_mask[idx] == 0 and t >= Tier.SAND:
			_biomes[idx] = Biome.SCORCHED
			if _ash[idx] == 0:
				_ash[idx] = 160
				_ash_tiles += 1
		elif t >= Tier.SAND and t < Tier.SUMMIT and _temp[idx] < 48.0 and _rad[idx] < 0.25:
			if b == Biome.RUST or (b == Biome.SCORCHED and _moisture[idx] >= 0.30 and (_ash[idx] > 0 or falloff > 0.35)):
				var p_h: int = ((px * 73856093) ^ (py * 19349663)) & 7
				if falloff > 0.40 or p_h < 5:
					_biomes[idx] = Biome.LUSH
					if _ash[idx] > 0:
						_ash[idx] = maxi(0, int(_ash[idx]) - 120)
						if _ash[idx] == 0:
							_ash_tiles = maxi(0, _ash_tiles - 1)
		return true
	if storm_id == 1:
		_clear_frost_at(idx)
		if t < Tier.SAND or t >= Tier.SUMMIT:
			return false
		var prev_m_f: float = _moisture[idx]
		var next_m_f: float = maxf(0.0, prev_m_f * (0.45 - 0.25 * falloff))
		_moisture[idx] = next_m_f
		_global_vapor_pool += prev_m_f - next_m_f
		_temp[idx] = maxf(_temp[idx], 165.0 + 260.0 * falloff)
		var f_h: int = ((px * 73856093) ^ (py * 19349663)) & 7
		if norm_d < 0.28 and b != Biome.LAVA:
			_biomes[idx] = Biome.SCORCHED
			if _ash[idx] == 0:
				_ash[idx] = 200
				_ash_tiles += 1
			_ignite_tile(idx, 0.75 + 0.35 * falloff)
		elif b == Biome.LUSH or b == Biome.RUST:
			if falloff > 0.35 or f_h < 5:
				_ignite_tile(idx, 0.55 + 0.55 * falloff)
		if _bomb_map[idx] > 0:
			_enqueue_bomb_detonation(idx)
		return true
	if storm_id == 2:
		_rad[idx] = clampf(_rad[idx] + 0.55 * falloff + 0.12, 0.0, 1.0)
		if t >= Tier.SAND and t <= Tier.HILLS and b != Biome.LAVA:
			var c_h: int = ((px * 73856093) ^ (py * 19349663)) & 7
			if norm_d < 0.45 or (norm_d < 0.85 and c_h < 4):
				_biomes[idx] = Biome.CRYSTAL
				if _fire[idx] > 0.0:
					_fire[idx] = 0.0
					_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
		return true
	return _apply_meltdown_tile(idx, norm_d, falloff)


func _apply_meltdown_tile(idx: int, norm_d: float, falloff: float) -> bool:
	_vent_mask[idx] = 0
	_clear_frost_at(idx)
	if _bomb_map[idx] > 0:
		_enqueue_bomb_detonation(idx)
	var orig_land: bool = _height[idx] >= 0.40
	if norm_d < 0.65:
		var bowl: float = 1.0 - (norm_d / 0.65) * (norm_d / 0.65)
		var min_floor: float = 0.362 if orig_land else 0.06
		_height[idx] = clampf(_height[idx] - bowl * 0.17, min_floor, 0.95)
		_tiers[idx] = _classify_height(_height[idx])
		if _tiers[idx] >= Tier.SAND:
			_river_mask[idx] = 0
			if norm_d < 0.26:
				_biomes[idx] = Biome.LAVA
				_temp[idx] = maxf(_temp[idx], 740.0)
				if _fire[idx] > 0.0:
					_fire[idx] = 0.0
					_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
			else:
				_biomes[idx] = Biome.SCORCHED
				_temp[idx] = maxf(_temp[idx], 320.0 + 340.0 * bowl)
				if _ash[idx] == 0:
					_ash[idx] = 160
					_ash_tiles += 1
		else:
			_temp[idx] = maxf(_temp[idx], 90.0)
	else:
		var rim_phase: float = sin(((norm_d - 0.65) / 0.35) * PI)
		_height[idx] = clampf(_height[idx] + rim_phase * 0.065, 0.0, 0.96)
		_tiers[idx] = _classify_height(_height[idx])
		if _tiers[idx] >= Tier.SAND:
			_river_mask[idx] = 0
			if _biomes[idx] == Biome.LUSH or _biomes[idx] == Biome.RUST:
				_ignite_tile(idx, 0.85)
			else:
				_biomes[idx] = Biome.SCORCHED
		_temp[idx] = maxf(_temp[idx], 150.0 + 160.0 * rim_phase)
	_rad[idx] = clampf(_rad[idx] + 0.78 * falloff + 0.18, 0.0, 1.0)
	_moisture[idx] *= 0.20
	return true


func apply_civ_ecology_batch(events: Array) -> int:
	_ensure_initialized()
	if events.is_empty():
		return 0
	var applied: int = 0
	var prev_sum: float = _temp_total_sum
	for item in events:
		if not (item is Dictionary):
			continue
		var ev: Dictionary = item
		var kind: int = int(ev.get("kind", -1))
		if kind < 0 or kind > 3:
			continue
		var px: int = int(ev.get("x", -1))
		var py: int = int(ev.get("y", -1))
		if px < 0 or px >= map_w or py < 0 or py >= map_h:
			continue
		var val: float = float(ev.get("val", 1.0))
		if val <= 0.0:
			continue
		if _apply_ecology_footprint(kind, px, py, val):
			applied += 1
	if _temp_total_sum != prev_sum:
		_avg_temp_cached = _temp_total_sum * _inv_total_tiles
	return applied


func _apply_ecology_footprint(kind: int, px: int, py: int, val: float) -> bool:
	var rad: int = 1 if (kind == 0 or kind == 1 or kind == 2 or val >= 1.5) else 0
	var any_hit: bool = false
	for dy in range(-rad, rad + 1):
		var ny: int = py + dy
		if ny < 0 or ny >= map_h:
			continue
		for dx in range(-rad, rad + 1):
			var nx: int = px + dx
			if nx < 0 or nx >= map_w:
				continue
			var d2: int = dx * dx + dy * dy
			if kind == 1 and d2 > 1:
				continue
			var w: float = 1.0 if d2 == 0 else (0.55 if d2 == 1 else 0.35)
			if _apply_ecology_at(kind, nx, ny, val * w):
				any_hit = true
	return any_hit


func _apply_ecology_at(kind: int, nx: int, ny: int, val: float) -> bool:
	var idx: int = ny * map_w + nx
	var t: int = _tiers[idx]
	var b: int = _biomes[idx]
	if t <= Tier.SHALLOW or b == Biome.LAVA:
		return false
	var visual_dirty: bool = false
	var structural: bool = false

	if kind == 0:
		var add_t: float = clampf(val, 0.2, 160.0)
		var old_t: float = _temp[idx]
		var new_t: float = clampf(old_t + add_t, -40.0, 520.0)
		_temp[idx] = new_t
		_temp_total_sum += new_t - old_t
		_co2_load = minf(600.0, _co2_load + clampf(add_t * 0.02, 0.0, 2.0))
		_moisture[idx] = maxf(0.0, _moisture[idx] - clampf(add_t * 0.0045, 0.01, 0.25))
		if t == Tier.SUMMIT and new_t >= 8.0:
			_height[idx] = minf(_height[idx], 0.745)
			_tiers[idx] = Tier.MOUNTAINS
			_moisture[idx] = clampf(_moisture[idx] + 0.14, 0.0, 0.85)
			visual_dirty = true
			structural = true
		if new_t >= 105.0 and b != Biome.SCORCHED:
			_biomes[idx] = Biome.SCORCHED
			visual_dirty = true
		elif new_t >= 52.0 and b == Biome.LUSH:
			_biomes[idx] = Biome.RUST
			visual_dirty = true
		if (old_t <= 65.0 and new_t > 65.0) or (old_t <= 95.0 and new_t > 95.0) or (old_t <= 185.0 and new_t > 185.0):
			visual_dirty = true
		if visual_dirty:
			_mark_tile_dirty(nx, ny, structural, 1 if structural else 0)
		elif new_t > float(TUNING_KNOBS["TEMP_EQUILIBRIUM_MAX_C"]):
			_activate_tile_row(nx, ny)
		if new_t >= 165.0:
			_temp_total_sum += _enforce_hot_border_at(nx, ny, true)
		return true

	if kind == 1:
		if t <= Tier.HILLS:
			if b == Biome.LUSH:
				_biomes[idx] = Biome.RUST
				visual_dirty = true
			var old_m1: float = _moisture[idx]
			var new_m1: float = maxf(0.06, old_m1 - clampf(val * 0.22, 0.05, 0.45))
			_moisture[idx] = new_m1
			if _ash[idx] > 0:
				_ash[idx] = 0
				_ash_tiles = maxi(0, _ash_tiles - 1)
				visual_dirty = true
			if visual_dirty:
				var cidx1: int = (ny >> CHUNK_SHIFT) * _chunks_w + (nx >> CHUNK_SHIFT)
				_mark_chunk_dirty_local(cidx1, nx & 15, ny & 15, nx & 15, ny & 15, false)
			return visual_dirty or absf(new_m1 - old_m1) > 0.001
		return false

	if kind == 2:
		if t <= Tier.HILLS and _temp[idx] < 65.0 and _rad[idx] < 0.38:
			# Keep moisture <= 0.72 so SPORE bio-cover stays vigorous yet flammable by lava/beams
			var old_m2: float = _moisture[idx]
			var new_m2: float = clampf(old_m2 + clampf(val * 0.25, 0.05, 0.42), 0.0, 0.72)
			_moisture[idx] = new_m2
			if b == Biome.RUST or (b == Biome.SCORCHED and _temp[idx] < 45.0):
				if not _has_hot_lava_within_two(nx, ny):
					_biomes[idx] = Biome.LUSH
					visual_dirty = true
			if _ash[idx] > 0:
				_ash[idx] = 0
				_ash_tiles = maxi(0, _ash_tiles - 1)
				visual_dirty = true
			if visual_dirty:
				var cidx2: int = (ny >> CHUNK_SHIFT) * _chunks_w + (nx >> CHUNK_SHIFT)
				_mark_chunk_dirty_local(cidx2, nx & 15, ny & 15, nx & 15, ny & 15, false)
			return visual_dirty or absf(new_m2 - old_m2) > 0.001
		return false

	var any_ore_change: bool = false
	if b == Biome.CRYSTAL:
		var old_r: float = _rad[idx]
		var new_r: float = maxf(0.015, old_r - clampf(val * 0.14, 0.04, 0.35))
		_rad[idx] = new_r
		if _plasma_glow[idx] > 0:
			_plasma_glow[idx] = 0
			any_ore_change = true
		if new_r != old_r:
			any_ore_change = true
		if new_r <= 0.22:
			_biomes[idx] = Biome.RUST
			visual_dirty = true
			structural = true
	var old_h: float = _height[idx]
	var min_h: float = 0.405 if old_h >= 0.40 else old_h
	var new_h: float = maxf(min_h, old_h - clampf(val * 0.005, 0.002, 0.016))
	if new_h != old_h:
		_height[idx] = new_h
		any_ore_change = true
	var new_t_tier: int = _classify_height(new_h)
	if new_t_tier != t and new_t_tier >= Tier.SAND:
		_tiers[idx] = new_t_tier
		visual_dirty = true
		structural = true
	if b == Biome.LUSH and val >= 0.8:
		_biomes[idx] = Biome.RUST
		_moisture[idx] *= 0.80
		visual_dirty = true
	if visual_dirty:
		_mark_tile_dirty(nx, ny, structural, 0)
	return visual_dirty or any_ore_change


func _ignite_tile(idx: int, intensity: float) -> void:
	if _tiers[idx] <= Tier.SHALLOW or _tiers[idx] >= Tier.SUMMIT or _biomes[idx] == Biome.LAVA:
		return
	var was_off: bool = _fire[idx] <= 0.0
	_fire[idx] = clampf(maxf(_fire[idx], intensity), 0.1, 1.2)
	var old_t: float = _temp[idx]
	if old_t < 220.0:
		_temp[idx] = 220.0
		_temp_total_sum += 220.0 - old_t
	if was_off:
		_active_fire_tiles += 1
		_fire_events_total += 1


func step_environment(dt: float) -> void:
	_ensure_initialized()
	if dt <= 0.0 or _sim_pace_mult <= 0.0:
		return

	var eff_dt: float = minf(dt, 0.15)
	_env_eff_dt = eff_dt
	_env_time += eff_dt
	_env_step_count += 1
	_steam_cooldown = maxf(0.0, _steam_cooldown - eff_dt)
	_cloud_rain_fx_cd = maxf(0.0, _cloud_rain_fx_cd - eff_dt)
	_co2_load = maxf(0.0, _co2_load - 0.12 * eff_dt)
	_step_clouds(eff_dt)
	_step_water_flow()

	_prepare_env_tick_params(eff_dt)
	_step_env_chunks()
	_step_extended_environment(eff_dt)
	_flush_env_outputs()


func _prepare_env_tick_params(eff_dt: float) -> void:
	_env_diff_k = clampf(float(TUNING_KNOBS["TEMP_DIFFUSE_RATE"]) * eff_dt * 0.22, 0.0, 0.20)
	_env_cool_k = clampf(float(TUNING_KNOBS["TEMP_COOL_RATE"]) * eff_dt, 0.0, 0.50)
	_env_rad_decay = float(TUNING_KNOBS["RAD_DECAY_RATE"]) * eff_dt
	_env_rad_crys_floor = float(TUNING_KNOBS["RAD_CRYSTAL_FLOOR"])
	_env_lava_min = float(TUNING_KNOBS["LAVA_MIN_TEMP_C"])
	_env_lava_floor = float(TUNING_KNOBS["LAVA_VENT_FLOOR_C"])
	_env_amb_c = float(TUNING_KNOBS["TEMP_AMBIENT_C"])
	_env_eq_min_c = float(TUNING_KNOBS["TEMP_EQUILIBRIUM_MIN_C"])
	_env_eq_max_c = float(TUNING_KNOBS["TEMP_EQUILIBRIUM_MAX_C"])
	_env_steady_eps = float(TUNING_KNOBS["TEMP_STEADY_EPS_C"])
	_env_freeze_c = float(TUNING_KNOBS["ICE_FREEZE_TEMP_C"])
	_env_melt_c = float(TUNING_KNOBS["ICE_MELT_TEMP_C"])
	_env_evap_rate = float(TUNING_KNOBS["EVAP_RATE"])
	_env_fire_decay = float(TUNING_KNOBS["FIRE_BURN_DECAY"]) * eff_dt
	_env_fire_spread_base = float(TUNING_KNOBS["FIRE_SPREAD_CHANCE"]) * eff_dt * _cosmic_fire_mul
	var crystal_prob: float = float(TUNING_KNOBS["CRYSTAL_SPREAD_CHANCE"]) * eff_dt
	var lush_prob: float = float(TUNING_KNOBS["LUSH_RECOVER_CHANCE"]) * eff_dt
	var ash_prob: float = float(TUNING_KNOBS["ASH_RECOVER_CHANCE"]) * eff_dt
	_env_ash_decay_step = maxi(1, int(round(8.0 * eff_dt)))
	_env_plasma_decay_step = maxi(1, int(round(float(TUNING_KNOBS["PLASMA_SHIMMER_DECAY_PER_SEC"]) * eff_dt)))
	_env_crystal_prob_i = int(ceil(crystal_prob * 65536.0))
	_env_lush_prob_i = int(ceil(lush_prob * 65536.0))
	_env_ash_boost_prob_i = int(ceil(ash_prob * (1.0 + float(TUNING_KNOBS["ASH_FERTILITY_BOOST"])) * 65536.0))

	var co2_term: float = float(TUNING_KNOBS["CO2_HEAT_GAIN_PER_C"]) * log(1.0 + _co2_load / 400.0)
	var albedo_frac: float = clampf(float(_frost_tiles + _ash_tiles) * _inv_total_tiles * 6.0, 0.0, 1.0)
	var albedo_term: float = 8.0 * albedo_frac
	_env_ocean_damp = float(TUNING_KNOBS["OCEAN_THERMAL_DAMP_K"]) * maxf(0.0, (_avg_temp_cached + _cosmic_temp_offset) - _env_amb_c)
	_env_eq_shift = co2_term - albedo_term - _env_ocean_damp

	var frost_grow_f: float = 28.0 * eff_dt
	_env_frost_grow_base = int(frost_grow_f)
	_env_frost_grow_rem = int(round((frost_grow_f - float(_env_frost_grow_base)) * 4.0))
	var frost_melt_f: float = 22.0 * eff_dt
	_env_frost_melt_base = int(frost_melt_f)
	_env_frost_melt_rem = int(round((frost_melt_f - float(_env_frost_melt_base)) * 4.0))
	_env_steam_emitted = false
	_env_temp_delta = 0.0


func _step_env_chunks() -> void:
	var active_n: int = _active_chunks.size()
	var active_budget: int = int(TUNING_KNOBS["ACTIVE_CHUNK_BUDGET"])
	var process_n: int = mini(active_n, active_budget)
	if process_n <= 0:
		_env_chunk_cursor = 0
		return

	var has_frost: bool = _frost_tiles > 0
	var cold_active: bool = has_frost or _cosmic_temp_offset <= -2.0
	var cold_skip_t: float = (_env_eq_min_c if cold_active else _env_freeze_c) - _cosmic_temp_offset
	var start_cursor: int = _env_chunk_cursor % active_n
	for step_i in range(process_n):
		var cidx: int = _active_chunks[(start_cursor + step_i) % active_n]
		var row_mask: int = _chunk_row_mask[cidx]
		if row_mask == 0:
			_chunk_active[cidx] = 0
			continue
		_chunk_row_mask[cidx] = 0
		if not _step_env_single_chunk(cidx, row_mask, has_frost, cold_skip_t):
			_chunk_active[cidx] = 0

	_env_chunk_cursor = (start_cursor + process_n) % active_n
	var scan_i: int = 0
	while scan_i < _active_chunks.size():
		var chk_id: int = _active_chunks[scan_i]
		if _chunk_active[chk_id] == 0:
			_deactivate_chunk_at(scan_i)
		else:
			scan_i += 1


func _step_env_single_chunk(cidx: int, row_mask: int, has_frost: bool, cold_skip_t: float) -> bool:
	@warning_ignore("integer_division")
	var cy: int = cidx / _chunks_w
	var cx: int = cidx % _chunks_w
	var y0: int = cy << CHUNK_SHIFT
	var y1: int = mini(map_h - 1, y0 + CHUNK_SIZE)
	var start_y: int = maxi(1, y0)
	var x0: int = cx << CHUNK_SHIFT
	var x1: int = mini(map_w - 1, x0 + CHUNK_SIZE)
	var start_x: int = maxi(1, x0)
	var still_active: bool = false

	for py in range(start_y, y1):
		var ly: int = py & 15
		var row_bit: int = 1 << ly
		if ((row_mask | _chunk_row_mask[cidx]) & row_bit) == 0:
			continue
		if _step_env_chunk_row(cidx, py, ly, start_x, x1, has_frost, cold_skip_t):
			_chunk_row_mask[cidx] |= row_bit
			still_active = true

	if _chunk_row_mask[cidx] != 0:
		still_active = true
	return still_active


func _step_env_chunk_row(cidx: int, py: int, ly: int, start_x: int, x1: int, has_frost: bool, cold_skip_t: float) -> bool:
	var mw: int = map_w
	var row_active: bool = false
	var row_lat_shift: float = 4.0 - absf(float(py) / float(map_h) - 0.5) * 29.0
	var row_off: int = py * mw
	var c_off: float = _cosmic_temp_offset
	var freeze_c: float = _env_freeze_c
	var eq_max_c: float = _env_eq_max_c
	var amb_c: float = _env_amb_c
	var eq_shift: float = _env_eq_shift
	var diff_k: float = _env_diff_k
	var cool_k: float = _env_cool_k
	var steady_eps: float = _env_steady_eps
	var crys_floor: float = _env_rad_crys_floor
	var check_cold: bool = has_frost or c_off <= -2.0
	var temp_delta: float = 0.0

	for px in range(start_x, x1):
		var idx: int = row_off + px
		var f_cur: float = _fire[idx]
		var a_cur: int = _ash[idx]
		var t_cur: float = _temp[idx]
		var b_cur: int = _biomes[idx]
		var pg_cur: int = _plasma_glow[idx]
		var frost_cur: int = _frost[idx] if has_frost else 0
		var r_floor: float = crys_floor if b_cur == Biome.CRYSTAL else 0.02

		if f_cur <= 0.0 and a_cur == 0 and t_cur <= eq_max_c and b_cur != Biome.LAVA and pg_cur == 0 and frost_cur == 0:
			if (_tiers[idx] >= Tier.HILLS or t_cur >= cold_skip_t) and _rad[idx] <= r_floor:
				continue

		var tier_cur: int = _tiers[idx]
		var r_cur: float = _rad[idx]
		if f_cur > 0.0:
			_env_f_orig = f_cur
			_env_t_cur = t_cur
			_env_b_cur = b_cur
			_env_a_cur = a_cur
			_env_r_floor = r_floor
			_env_row_active = row_active
			_step_env_fire_at(cidx, px, ly, idx, tier_cur)
			t_cur = _env_t_cur
			b_cur = _env_b_cur
			a_cur = _env_a_cur
			r_floor = _env_r_floor
			row_active = _env_row_active

		if t_cur > 45.0 and f_cur <= 0.0 and _moisture[idx] > 0.005:
			var evap_m: float = minf(_moisture[idx], _env_evap_rate * clampf((t_cur - 45.0) / 120.0, 0.0, 1.0) * _env_eff_dt)
			_moisture[idx] -= evap_m
			_global_vapor_pool += evap_m

		if b_cur == Biome.LAVA:
			_env_t_cur = t_cur
			_env_frost_cur = frost_cur
			_env_row_active = row_active
			var skipped: bool = _step_env_lava_at(px, py, idx, tier_cur)
			t_cur = _env_t_cur
			frost_cur = _env_frost_cur
			row_active = _env_row_active
			if skipped:
				continue
		elif t_cur > eq_max_c or frost_cur > 0 or (tier_cur < Tier.HILLS and (t_cur < cold_skip_t)):
			var t_eff: float = t_cur + c_off
			var lat_s: float = row_lat_shift * 0.85 - 0.30 if tier_cur <= Tier.SHALLOW else row_lat_shift
			var target_amb: float = amb_c + lat_s - maxf(0.0, _height[idx] - 0.42) * 86.0 + eq_shift
			var nb_avg_h: float = (_temp[idx - 1] + _temp[idx + 1] + _temp[idx - mw] + _temp[idx + mw]) * 0.25
			var tile_cool_k: float = cool_k * (0.45 if t_eff <= 0.0 else 1.0)
			var cooled: float = t_cur + (nb_avg_h - t_cur) * diff_k - (t_cur - target_amb) * tile_cool_k
			_temp[idx] = cooled
			temp_delta += cooled - t_cur
			var next_t_eff: float = cooled + c_off
			if absf(cooled - t_cur) >= steady_eps or (cooled > eq_max_c and nb_avg_h <= t_cur) or (check_cold and tier_cur < Tier.HILLS and next_t_eff < _env_eq_min_c and absf(cooled - target_amb) > 1.0):
				row_active = true
			if b_cur == Biome.SCORCHED and (((px * 73856093) ^ (py * 19349663)) & 3) == 0 and ((t_cur >= 95.0 and cooled < 95.0) or (t_cur >= 185.0 and cooled < 185.0)):
				_mark_chunk_dirty_local(cidx, px & 15, ly, px & 15, ly, false)
			t_cur = cooled

		if frost_cur > 0 or (tier_cur == Tier.SHALLOW and (t_cur + c_off) <= freeze_c and b_cur != Biome.LAVA and f_cur <= 0.0):
			_env_frost_cur = frost_cur
			_env_t_cur = t_cur
			_env_b_cur = b_cur
			_env_f_orig = f_cur
			_env_row_active = row_active
			_step_env_frost_tile(px, py, idx, tier_cur)
			row_active = _env_row_active

		if pg_cur > 0:
			var pg_new: int = maxi(0, pg_cur - _env_plasma_decay_step)
			_plasma_glow[idx] = pg_new
			if pg_new > 0:
				row_active = true
			if (pg_cur >> 5) != (pg_new >> 5) or pg_new == 0:
				_mark_chunk_dirty_local(cidx, px & 15, ly, px & 15, ly, false)

		if r_cur > r_floor or a_cur > 0 or (b_cur == Biome.CRYSTAL and _moisture[idx] >= 0.22 and t_cur < 55.0 and r_cur > crys_floor + 0.02) or (b_cur == Biome.SCORCHED and t_cur < 32.0 and r_cur < 0.14 and _moisture[idx] > 0.45):
			_env_r_cur = r_cur
			_env_r_floor = r_floor
			_env_b_cur = b_cur
			_env_t_cur = t_cur
			_env_a_cur = a_cur
			_env_f_orig = f_cur
			_env_row_active = row_active
			_step_env_ecology_at(cidx, px, py, ly, idx, tier_cur)
			row_active = _env_row_active

	_env_temp_delta += temp_delta
	return row_active


func _step_env_fire_at(cidx: int, px: int, ly: int, idx: int, tier_cur: int) -> void:
	var f_cur: float = _env_f_orig
	if tier_cur <= Tier.SHALLOW or _moisture[idx] >= 0.86 or _env_b_cur == Biome.LAVA:
		_fire[idx] = 0.0
		_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
		_mark_chunk_dirty_local(cidx, px & 15, ly, px & 15, ly, f_cur > 0.05)
		return

	_env_row_active = true
	var fire_t: float = 195.0 + f_cur * 120.0
	if fire_t > _env_t_cur:
		_temp[idx] = fire_t
		_env_temp_delta += fire_t - _env_t_cur
		_env_t_cur = fire_t
	var m_dry: float = minf(_moisture[idx], 0.14 * _env_eff_dt)
	_moisture[idx] -= m_dry
	_global_vapor_pool += m_dry
	_co2_load = minf(600.0, _co2_load + 0.02 * _env_eff_dt)

	var mw: int = map_w
	var rng_s: int = (_fast_rng_seed * 1664525 + 1013904223) & 0x7FFFFFFF
	var dir_r: int = (rng_s >> 16) & 3
	var nidx_f: int = idx - 1 if dir_r == 0 else (idx + 1 if dir_r == 1 else (idx - mw if dir_r == 2 else idx + mw))
	if _fire[nidx_f] <= 0.0 and _tiers[nidx_f] >= Tier.SAND and _tiers[nidx_f] < Tier.SUMMIT:
		var nb_b_f: int = _biomes[nidx_f]
		if nb_b_f == Biome.LUSH or nb_b_f == Biome.RUST or nb_b_f == Biome.XENO_JUNGLE or nb_b_f == Biome.CREEP_MYCELIUM:
			var nb_moist: float = _moisture[nidx_f]
			var moist_lim: float = 0.78 if (nb_b_f == Biome.LUSH or nb_b_f == Biome.XENO_JUNGLE) else 0.48
			if nb_moist < moist_lim:
				rng_s = (rng_s * 1664525 + 1013904223) & 0x7FFFFFFF
				var roll_f: float = float(rng_s & 0xFFFF) * INV_65536
				var p_spread: float = _env_fire_spread_base * (1.1 - nb_moist) * (1.2 if nb_b_f == Biome.LUSH else 0.65)
				if roll_f < p_spread:
					_ignite_tile(nidx_f, clampf(f_cur * 0.92 + 0.15, 0.35, 1.0))
					var nx_f: int = nidx_f % mw
					@warning_ignore("integer_division")
					var ny_f: int = nidx_f / mw
					_mark_tile_dirty(nx_f, ny_f, true, 0)
	_fast_rng_seed = rng_s

	if _bomb_count > 0 and (_bomb_map[idx] & 3) > 0:
		_enqueue_bomb_detonation(idx)

	var next_f: float = f_cur - _env_fire_decay
	if next_f <= 0.0:
		_fire[idx] = 0.0
		_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
		_biomes[idx] = Biome.SCORCHED
		_env_b_cur = Biome.SCORCHED
		_env_r_floor = 0.02
		if _ash[idx] == 0:
			_ash_tiles += 1
		_ash[idx] = 225
		_env_a_cur = 225
		_mark_chunk_dirty_local(cidx, px & 15, ly, px & 15, ly, true)
	else:
		_fire[idx] = next_f


func _step_env_lava_at(px: int, py: int, idx: int, tier_cur: int) -> bool:
	var mw: int = map_w
	if _env_frost_cur > 0:
		_clear_frost_at(idx)
		_env_frost_cur = 0
	var is_vent: bool = _vent_mask[idx] > 0
	if not is_vent and (
		_tiers[idx - 1] <= Tier.SHALLOW
		or _tiers[idx + 1] <= Tier.SHALLOW
		or _tiers[idx - mw] <= Tier.SHALLOW
		or _tiers[idx + mw] <= Tier.SHALLOW
	):
		_biomes[idx] = Biome.SCORCHED
		_tiers[idx] = maxi(tier_cur, Tier.SAND)
		var q_t: float = maxf(160.0, _env_t_cur * 0.36)
		_temp[idx] = q_t
		_env_temp_delta += q_t - _env_t_cur
		_global_vapor_pool += 0.25
		_mark_tile_dirty(px, py, true, 2)
		_env_row_active = true
		if not _env_steam_emitted and _steam_cooldown <= 0.0:
			_env_steam_emitted = true
			_steam_cooldown = float(TUNING_KNOBS["STEAM_COOLDOWN_SEC"])
			surface_impact.emit(Vector2(float(px) + 0.5, float(py) + 0.5), 10.0, "steam")
		return true

	var nb_avg: float = (_temp[idx - 1] + _temp[idx + 1] + _temp[idx - mw] + _temp[idx + mw]) * 0.25
	var next_t: float = _env_t_cur + (nb_avg - _env_t_cur) * _env_diff_k - (_env_t_cur - (_env_amb_c - _env_ocean_damp)) * (_env_cool_k * 0.14)
	if is_vent:
		next_t = maxf(next_t, _env_lava_floor)
	_temp[idx] = next_t
	_env_temp_delta += next_t - _env_t_cur

	if not is_vent or absf(next_t - _env_t_cur) >= _env_steady_eps:
		_env_row_active = true
		var rng_s: int = (_fast_rng_seed * 1664525 + 1013904223) & 0x7FFFFFFF
		var ld: int = (rng_s >> 16) & 3
		_fast_rng_seed = rng_s
		var ln_idx: int = idx - 1 if ld == 0 else (idx + 1 if ld == 1 else (idx - mw if ld == 2 else idx + mw))
		if _biomes[ln_idx] == Biome.LUSH and _fire[ln_idx] <= 0.0 and _moisture[ln_idx] < 0.65:
			_ignite_tile(ln_idx, 0.78)
			var lnx: int = ln_idx % mw
			@warning_ignore("integer_division")
			var lny: int = ln_idx / mw
			_mark_tile_dirty(lnx, lny, true, 0)

	if not is_vent and next_t < _env_lava_min:
		_biomes[idx] = Biome.SCORCHED
		_mark_tile_dirty(px, py, true, 1)
	_env_t_cur = next_t
	return false


func _step_env_frost_tile(px: int, py: int, idx: int, tier_cur: int) -> void:
	var mw: int = map_w
	var frost_cur: int = _env_frost_cur
	var t_eff: float = _env_t_cur + _cosmic_temp_offset
	if (t_eff <= _env_freeze_c or frost_cur > 0) and tier_cur == Tier.SHALLOW and _env_b_cur != Biome.LAVA and _env_f_orig <= 0.0:
		if t_eff <= _env_freeze_c and frost_cur < 255:
			var g_step: int = _env_frost_grow_base + (1 if ((_env_step_count + px + py) & 3) < _env_frost_grow_rem else 0)
			if g_step > 0:
				var next_fr: int = mini(255, frost_cur + g_step)
				_frost[idx] = next_fr
				if frost_cur == 0:
					_frost_tiles += 1
				if next_fr < 255:
					_env_row_active = true
				if (frost_cur < 128 and next_fr >= 128) or (frost_cur >> 5) != (next_fr >> 5):
					var froze_bridge: bool = frost_cur < 128 and next_fr >= 128
					_mark_tile_dirty(px, py, froze_bridge, 1 if froze_bridge else 0)
		elif frost_cur > 0 and t_eff >= _env_melt_c:
			var m_step: int = _env_frost_melt_base + (1 if ((_env_step_count + px + py) & 3) < _env_frost_melt_rem else 0)
			if t_eff > _env_melt_c:
				m_step += int(round((t_eff - _env_melt_c) * 1.4 * _env_eff_dt))
			m_step = maxi(1, m_step)
			var next_fr2: int = maxi(0, frost_cur - m_step)
			_frost[idx] = next_fr2
			if next_fr2 == 0:
				_frost_tiles = maxi(0, _frost_tiles - 1)
			else:
				_env_row_active = true
			_moisture[idx] = 1.0
			if _tiers[idx - 1] >= Tier.SAND:
				_moisture[idx - 1] = minf(1.0, _moisture[idx - 1] + 0.02 * _env_eff_dt)
			if _tiers[idx + 1] >= Tier.SAND:
				_moisture[idx + 1] = minf(1.0, _moisture[idx + 1] + 0.02 * _env_eff_dt)
			if _tiers[idx - mw] >= Tier.SAND:
				_moisture[idx - mw] = minf(1.0, _moisture[idx - mw] + 0.02 * _env_eff_dt)
			if _tiers[idx + mw] >= Tier.SAND:
				_moisture[idx + mw] = minf(1.0, _moisture[idx + mw] + 0.02 * _env_eff_dt)
			if (frost_cur >= 128 and next_fr2 < 128) or next_fr2 == 0 or (frost_cur >> 5) != (next_fr2 >> 5):
				var melted_bridge: bool = frost_cur >= 128 and next_fr2 < 128
				_mark_tile_dirty(px, py, melted_bridge, 1 if melted_bridge else 0)
	elif frost_cur > 0:
		_clear_frost_at(idx)
		_mark_tile_dirty(px, py, false, 0)


func _step_env_ecology_at(cidx: int, px: int, py: int, ly: int, idx: int, _tier_cur: int) -> void:
	var mw: int = map_w
	var b_cur: int = _env_b_cur
	var r_cur: float = _env_r_cur
	var r_floor: float = _env_r_floor
	if r_cur > r_floor:
		var next_r: float = maxf(r_floor if b_cur == Biome.CRYSTAL else 0.0, r_cur - _env_rad_decay)
		_rad[idx] = next_r
		if next_r > r_floor:
			_env_row_active = true
		r_cur = next_r

	var t_cur: float = _env_t_cur
	var a_cur: int = _env_a_cur
	var rng_s: int = _fast_rng_seed
	if b_cur == Biome.CRYSTAL and r_cur > _env_rad_crys_floor + 0.02 and _moisture[idx] >= 0.22 and t_cur < 55.0:
		_env_row_active = true
		rng_s = (rng_s * 1664525 + 1013904223) & 0x7FFFFFFF
		if (rng_s & 0xFFFF) < _env_crystal_prob_i:
			var c_dir: int = (rng_s >> 16) & 3
			var nidx_c: int = idx - 1 if c_dir == 0 else (idx + 1 if c_dir == 1 else (idx - mw if c_dir == 2 else idx + mw))
			if _tiers[nidx_c] >= Tier.SAND and _tiers[nidx_c] <= Tier.HILLS:
				var nb_bc: int = _biomes[nidx_c]
				if nb_bc == Biome.RUST or nb_bc == Biome.LUSH:
					_biomes[nidx_c] = Biome.CRYSTAL
					_rad[nidx_c] = maxf(_rad[nidx_c], _env_rad_crys_floor + 0.08)
					var nx_c: int = nidx_c % mw
					@warning_ignore("integer_division")
					var ny_c: int = nidx_c / mw
					_mark_tile_dirty(nx_c, ny_c, true, 0)
	elif a_cur > 0 and _env_f_orig <= 0.0 and t_cur < 44.0:
		_env_row_active = true
		if b_cur == Biome.SCORCHED and r_cur < 0.22 and _moisture[idx] >= 0.30 and not _has_hot_lava_within_two(px, py):
			rng_s = (rng_s * 1664525 + 1013904223) & 0x7FFFFFFF
			if (rng_s & 0xFFFF) < _env_ash_boost_prob_i:
				_biomes[idx] = Biome.LUSH
				_mark_chunk_dirty_local(cidx, px & 15, ly, px & 15, ly, true)
		var next_a: int = maxi(0, a_cur - _env_ash_decay_step)
		_ash[idx] = next_a
		if next_a == 0:
			_ash_tiles = maxi(0, _ash_tiles - 1)
			_mark_chunk_dirty_local(cidx, px & 15, ly, px & 15, ly, false)
	elif b_cur == Biome.SCORCHED and t_cur < 32.0 and r_cur < 0.14 and _moisture[idx] > 0.45:
		rng_s = (rng_s * 1664525 + 1013904223) & 0x7FFFFFFF
		if (rng_s & 0xFFFF) < _env_lush_prob_i and not _has_hot_lava_within_two(px, py):
			var l_dir: int = (rng_s >> 16) & 3
			var nidx_l: int = idx - 1 if l_dir == 0 else (idx + 1 if l_dir == 1 else (idx - mw if l_dir == 2 else idx + mw))
			if _biomes[nidx_l] == Biome.LUSH:
				_biomes[idx] = Biome.LUSH
				_mark_chunk_dirty_local(cidx, px & 15, ly, px & 15, ly, true)
	_fast_rng_seed = rng_s


func _flush_env_outputs() -> void:
	if _env_temp_delta != 0.0:
		_temp_total_sum += _env_temp_delta
		_avg_temp_cached = _temp_total_sum * _inv_total_tiles
	if (_env_step_count & 31) == 0 and (not _active_chunks.is_empty() or _temp_scan_row > 0 or _env_ocean_damp > 0.35 or _cosmic_temp_offset <= -4.0 or _frost_tiles > 0):
		_step_rolling_avg_temp()

	var flush_interval: int = int(TUNING_KNOBS["DIRTY_FLUSH_INTERVAL"])
	var dirty_cap: int = 16
	var struct_cap: int = 12
	if _sim_pace_mult >= 20.0:
		flush_interval = maxi(flush_interval, 8)
		dirty_cap = 32
		struct_cap = 24
	var dirty_n: int = _dirty_chunks.size()
	var struct_n: int = _structural_dirty_chunks.size()
	if dirty_n >= dirty_cap or struct_n >= struct_cap or ((dirty_n > 0 or struct_n > 0) and (_env_step_count % flush_interval) == 0):
		if dirty_n > 0:
			_flush_dirty_chunks()
		if _structural_dirty_chunks.size() > 0:
			_flush_structural_dirty_regions()


func spawn_sky_drops(world_pos: Vector2, radius: float, drop_kind: int) -> int:
	_ensure_initialized()
	if _drops == null:
		return 0
	var r: float = radius if radius > 0.0 else 12.0
	var count: int = _drops.spawn_shower(world_pos, r, drop_kind)
	if count > 0:
		_sync_drops_to_fx()
		var fx := _resolve_fx()
		if fx != null and fx.has_method("play_sfx"):
			fx.play_sfx(21, world_pos.x)
	return count


func _sync_drops_to_fx() -> void:
	if _drops == null:
		return
	var cur_n: int = _drops.get_count()
	if cur_n == 0 and not _had_drops_synced:
		return
	var fx := _resolve_fx()
	if fx != null and fx.has_method("sync_sky_drops"):
		var snap: Dictionary = _drops.build_snapshot()
		fx.sync_sky_drops(snap["positions"], snap["colors"], snap["z_heights"])
		_had_drops_synced = cur_n > 0


func _on_sky_drop_landed(px: int, py: int, drop_kind: int) -> void:
	if px <= 0 or px >= map_w - 1 or py <= 0 or py >= map_h - 1:
		return
	var idx: int = py * map_w + px
	var t: int = _tiers[idx]
	var changed: bool = false
	var fx := _resolve_fx()
	if drop_kind <= WorldDropsScript.DropKind.CRYSTAL or drop_kind >= WorldDropsScript.DropKind.STEAM:
		changed = _land_drop_climate(px, py, idx, t, drop_kind)
	elif drop_kind >= WorldDropsScript.DropKind.SEED_LUSH and drop_kind <= WorldDropsScript.DropKind.SEED_CREEP_CYBER:
		changed = _land_drop_seed(px, py, idx, t, drop_kind)
	else:
		changed = _land_drop_power(px, py, idx, t, drop_kind)

	if changed:
		_mark_tile_dirty(px, py, true, 1)
	if fx != null and fx.has_method("play_sfx"):
		if drop_kind == WorldDropsScript.DropKind.METEOR_SHARD or drop_kind == WorldDropsScript.DropKind.PLASMA_BOMB:
			fx.play_sfx(22, float(px) + 0.5)
		elif (_drops.get_landed_total() & 7) == 0:
			fx.play_sfx(22, float(px) + 0.5)


func _land_drop_climate(px: int, py: int, idx: int, t: int, drop_kind: int) -> bool:
	if drop_kind == WorldDropsScript.DropKind.RAIN or drop_kind == WorldDropsScript.DropKind.SNOW:
		var cool_amt: float = 28.0 if drop_kind == WorldDropsScript.DropKind.RAIN else 46.0
		var prev_t: float = _temp[idx]
		var next_t: float = maxf(-12.0, prev_t - cool_amt)
		_temp[idx] = next_t
		_temp_total_sum += next_t - prev_t
		_moisture[idx] = minf(1.0, _moisture[idx] + (0.28 if drop_kind == WorldDropsScript.DropKind.RAIN else 0.14))
		if _fire[idx] > 0.0:
			_fire[idx] = 0.0
			_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
		if _vent_mask[idx] > 0 and next_t < 240.0:
			_seal_vent_tile(idx, px, py)
		if drop_kind == WorldDropsScript.DropKind.SNOW:
			if t == Tier.SHALLOW:
				if _frost[idx] == 0:
					_frost_tiles += 1
				_frost[idx] = mini(255, _frost[idx] + 96)
			elif t >= Tier.SAND and t <= Tier.HILLS and next_t <= 4.0 and _biomes[idx] != Biome.LAVA:
				_biomes[idx] = Biome.CRYO_TUNDRA
				_activate_bio_chunk_at(px, py)
		return true
	if drop_kind == WorldDropsScript.DropKind.FIRE or drop_kind == WorldDropsScript.DropKind.LAVA:
		if t >= Tier.SAND:
			_ignite_tile(idx, 0.85)
			if drop_kind == WorldDropsScript.DropKind.LAVA:
				_biomes[idx] = Biome.LAVA
				_temp[idx] = maxf(_temp[idx], 860.0)
			if (_bomb_map[idx] & 3) > 0:
				_enqueue_bomb_detonation(idx)
			return true
		return false
	if drop_kind == WorldDropsScript.DropKind.ACID:
		if t >= Tier.SAND and t <= Tier.HILLS and _wall_mask[idx] == 0:
			_biomes[idx] = Biome.ACID_WASTE
			_rad[idx] = clampf(_rad[idx] + 0.04, 0.0, 1.0)
			_activate_bio_chunk_at(px, py)
			return true
		return false
	if drop_kind == WorldDropsScript.DropKind.CRYSTAL:
		if t >= Tier.SAND and t <= Tier.HILLS and _wall_mask[idx] == 0:
			_biomes[idx] = Biome.CRYSTAL
			_rad[idx] = maxf(_rad[idx], 0.56)
			_plasma_glow[idx] = maxi(_plasma_glow[idx], 165)
			return true
		return false
	if drop_kind == WorldDropsScript.DropKind.FERTILIZER:
		if t >= Tier.SAND and t <= Tier.HILLS:
			_moisture[idx] = clampf(_moisture[idx] + 0.25, 0.0, 0.85)
			if _biomes[idx] == Biome.RUST or _biomes[idx] == Biome.SCORCHED:
				_biomes[idx] = Biome.LUSH
			return true
		return false
	if drop_kind == WorldDropsScript.DropKind.STEAM:
		_global_vapor_pool += 0.04
		_moisture[idx] = minf(1.0, _moisture[idx] + 0.06)
		return false
	return false


func _land_drop_power(px: int, py: int, idx: int, t: int, drop_kind: int) -> bool:
	if drop_kind == WorldDropsScript.DropKind.PLASMA_BOMB or drop_kind == WorldDropsScript.DropKind.METEOR_SHARD:
		var r: int = 4 if drop_kind == WorldDropsScript.DropKind.PLASMA_BOMB else 3
		_detonate_crater_at(px, py, r)
		return true
	if drop_kind == WorldDropsScript.DropKind.PLASMA_ARC:
		_plasma_glow[idx] = 255
		_temp[idx] = minf(520.0, _temp[idx] + 85.0)
		if (_bomb_map[idx] & 3) > 0:
			_enqueue_bomb_detonation(idx)
		return true
	if drop_kind == WorldDropsScript.DropKind.GREY_GOO:
		if t >= Tier.SAND:
			_set_goo_at(idx, true)
			return true
		return false
	if drop_kind == WorldDropsScript.DropKind.CONWAY:
		if _wall_mask[idx] == 0:
			_set_conway_at(idx, true)
			return true
		return false
	if drop_kind >= WorldDropsScript.DropKind.TRAIT_RAIN and drop_kind <= WorldDropsScript.DropKind.BLESS:
		_plasma_glow[idx] = maxi(_plasma_glow[idx], 190)
		if t >= Tier.SAND and drop_kind == WorldDropsScript.DropKind.BLESS:
			_temp[idx] = lerpf(_temp[idx], 20.0, 0.35)
			_rad[idx] = maxf(0.0, _rad[idx] - 0.12)
		return true
	return false


func _land_drop_seed(px: int, py: int, idx: int, t: int, drop_kind: int) -> bool:
	if t < Tier.SAND or t > Tier.HILLS or _wall_mask[idx] > 0 or _biomes[idx] == Biome.LAVA:
		return false
	var target_b: int = Biome.LUSH
	if drop_kind == WorldDropsScript.DropKind.SEED_RUST:
		target_b = Biome.RUST
	elif drop_kind == WorldDropsScript.DropKind.SEED_XENO_JUNGLE:
		target_b = Biome.XENO_JUNGLE
	elif drop_kind == WorldDropsScript.DropKind.SEED_CRYO_TUNDRA:
		target_b = Biome.CRYO_TUNDRA
	elif drop_kind == WorldDropsScript.DropKind.SEED_ACID_WASTE:
		target_b = Biome.ACID_WASTE
	elif drop_kind == WorldDropsScript.DropKind.SEED_SILICA_DUNES:
		target_b = Biome.SILICA_DUNES
	elif drop_kind == WorldDropsScript.DropKind.SEED_BIOLUM_OASIS:
		target_b = Biome.BIOLUM_OASIS
	elif drop_kind == WorldDropsScript.DropKind.SEED_CREEP_MYCELIUM:
		target_b = Biome.CREEP_MYCELIUM
	elif drop_kind == WorldDropsScript.DropKind.SEED_CREEP_CYBER:
		target_b = Biome.CREEP_CYBER
	_biomes[idx] = target_b
	if target_b == Biome.CREEP_MYCELIUM or target_b == Biome.CREEP_CYBER:
		_ensure_creep_node_near(Vector2i(px, py), target_b)
	if target_b >= Biome.XENO_JUNGLE:
		_activate_bio_chunk_at(px, py)
	return true


func _step_extended_environment(eff_dt: float) -> void:
	if _drops != null and _drops.get_count() > 0:
		var fx := _resolve_fx()
		_drops.step_drops(eff_dt, self, fx)
		_sync_drops_to_fx()
	elif _had_drops_synced:
		_sync_drops_to_fx()

	if not _detonate_queue.is_empty():
		_step_bomb_chain()
	if not _vent_tiles.is_empty() or not _geysers.is_empty():
		_step_volcanoes_and_geysers(eff_dt)
	if not _tornadoes.is_empty():
		_step_tornadoes(eff_dt)
	if not _quake_steps.is_empty():
		_step_earthquake_fault()

	_ca_10hz_accum += eff_dt
	if _ca_10hz_accum >= 0.1:
		_ca_10hz_accum = minf(_ca_10hz_accum - 0.1, 0.2)
		if not _goo_active.is_empty():
			_step_grey_goo_10hz()
		if not _conway_active.is_empty():
			_step_conway_10hz()
		if not _bio_active_chunks.is_empty():
			_step_biome_competition_10hz()


func _step_volcanoes_and_geysers(eff_dt: float) -> void:
	var law_on: bool = bool(_world_laws.get("volcanoes_geysers", true))
	var mw: int = map_w
	if law_on and not _vent_tiles.is_empty() and _active_chunks.size() <= 14:
		_vent_erupt_accum += eff_dt
		if _vent_erupt_accum >= 6.0:
			_vent_erupt_accum = 0.0
			var v_pick: int = _drop_rng.randi_range(0, _vent_tiles.size() - 1)
			var vidx: int = _vent_tiles[v_pick]
			@warning_ignore("integer_division")
			var vy: int = vidx / mw
			var vx: int = vidx % mw
			var water_adj: int = 0
			if _tiers[vidx - 1] <= Tier.SHALLOW and _frost[vidx - 1] == 0:
				water_adj += 1
			if _tiers[vidx + 1] <= Tier.SHALLOW and _frost[vidx + 1] == 0:
				water_adj += 1
			if _tiers[vidx - mw] <= Tier.SHALLOW and _frost[vidx - mw] == 0:
				water_adj += 1
			if _tiers[vidx + mw] <= Tier.SHALLOW and _frost[vidx + mw] == 0:
				water_adj += 1
			if _temp[vidx] < 240.0 or (water_adj >= 2 and _temp[vidx] < 360.0):
				_seal_vent_tile(vidx, vx, vy)
			elif _drops != null and _drops.get_count() < 360:
				var ang: float = _drop_rng.randf() * TAU
				var spd: float = _drop_rng.randf_range(1.5, 4.2)
				_drops.launch_parabolic(Vector2(float(vx) + 0.5, float(vy) + 0.5), Vector3(cos(ang) * spd, sin(ang) * spd, _drop_rng.randf_range(22.0, 32.0)), WorldDropsScript.DropKind.LAVA)
				_volcano_eruptions_total += 1
				_sync_drops_to_fx()

	var gi: int = _geysers.size() - 1
	while gi >= 0:
		var g: Dictionary = _geysers[gi]
		var glife: float = float(g["life"]) - eff_dt
		var gpos: Vector2i = g["pos"]
		var gidx: int = gpos.y * mw + gpos.x
		if glife <= 0.0 or _wall_mask[gidx] > 0:
			_geysers.remove_at(gi)
			gi -= 1
			continue
		g["life"] = glife
		var gt: float = float(g["timer"]) + eff_dt
		if gt >= 0.9:
			gt -= 0.9
			var gkind: int = int(g["kind"])
			var dk: int = WorldDropsScript.DropKind.STEAM if gkind == 0 else WorldDropsScript.DropKind.ACID
			if _drops != null and _drops.get_count() < 460:
				for _j in range(4):
					var ga: float = _drop_rng.randf() * TAU
					var gs: float = _drop_rng.randf_range(4.0, 14.0)
					_drops.launch_parabolic(Vector2(float(gpos.x) + 0.5, float(gpos.y) + 0.5), Vector3(cos(ga) * gs, sin(ga) * gs, _drop_rng.randf_range(22.0, 36.0)), dk)
				_sync_drops_to_fx()
		g["timer"] = gt
		gi -= 1


func _seal_vent_tile(idx: int, px: int, py: int) -> void:
	if _vent_mask[idx] == 0:
		return
	_vent_mask[idx] = 0
	if _biomes[idx] == Biome.LAVA:
		_biomes[idx] = Biome.SCORCHED
	_temp[idx] = minf(_temp[idx], 110.0)
	_volcanoes_sealed_total += 1
	_rebuild_vent_tiles_cache()
	_mark_tile_dirty(px, py, true, 1)


func _step_tornadoes(eff_dt: float) -> void:
	var mw: int = map_w
	var mh: int = map_h
	var ti: int = _tornadoes.size() - 1
	while ti >= 0:
		var tor: Dictionary = _tornadoes[ti]
		var life: float = float(tor["life"]) - eff_dt
		if life <= 0.0:
			_tornadoes.remove_at(ti)
			ti -= 1
			continue
		tor["life"] = life
		var phase: float = float(tor["phase"]) + eff_dt * 3.4
		tor["phase"] = phase
		var vel: Vector2 = tor["vel"]
		vel = vel.rotated(_drop_rng.randf_range(-0.65, 0.65) * eff_dt * 2.5)
		var pos: Vector2 = tor["pos"] + vel * eff_dt
		if pos.x < 8.0 or pos.x > float(mw - 9):
			vel.x = -vel.x
			pos.x = clampf(pos.x, 8.0, float(mw - 9))
		if pos.y < 8.0 or pos.y > float(mh - 9):
			vel.y = -vel.y
			pos.y = clampf(pos.y, 8.0, float(mh - 9))
		tor["pos"] = pos
		tor["vel"] = vel

		var fx_cd: float = float(tor.get("fx_cd", 0.0)) - eff_dt
		if fx_cd <= 0.0:
			tor["fx_cd"] = 0.28
			var cx: int = int(pos.x)
			var cy: int = int(pos.y)
			var cidx: int = cy * mw + cx
			if _drops != null and _drops.get_count() < 460:
				var dk: int = WorldDropsScript.DropKind.RAIN if _tiers[cidx] <= Tier.SHALLOW else WorldDropsScript.DropKind.STEAM
				_drops.launch_parabolic(pos, Vector3(vel.x * 0.4 + cos(phase) * 14.0, vel.y * 0.4 + sin(phase) * 14.0, 26.0), dk)
				_sync_drops_to_fx()
			surface_impact.emit(pos, 7.0, "wind")
			var fx := _resolve_fx()
			if fx != null and fx.has_method("play_sfx"):
				fx.play_sfx(24, pos.x)
		else:
			tor["fx_cd"] = fx_cd
		ti -= 1


func _step_earthquake_fault() -> void:
	var budget: int = mini(3, _quake_steps.size())
	for _i in range(budget):
		var s: Vector3i = _quake_steps[0]
		_quake_steps.remove_at(0)
		var cx: int = s.x
		var cy: int = s.y
		var rad: int = maxi(1, s.z)
		for dy in range(-rad, rad + 1):
			var py: int = cy + dy
			if py <= 1 or py >= map_h - 2:
				continue
			for dx in range(-rad, rad + 1):
				var px: int = cx + dx
				if px <= 1 or px >= map_w - 2:
					continue
				if dx * dx + dy * dy <= rad * rad:
					_carve_fault_tile(px, py)
		_mark_tile_dirty(cx, cy, true, rad + 1)
	if _quake_steps.is_empty():
		_recompute_avg_temp_full()
		region_changed.emit(Rect2i(0, 0, map_w, map_h))


func _carve_fault_tile(px: int, py: int) -> void:
	var idx: int = py * map_w + px
	if _wall_mask[idx] > 0:
		_wall_mask[idx] = 0
	if _bomb_count > 0 and (_bomb_map[idx] & 3) > 0:
		_enqueue_bomb_detonation(idx)
	var h_new: float = maxf(0.18, _height[idx] - 0.14)
	_height[idx] = h_new
	var nt: int = _classify_height(h_new)
	_tiers[idx] = nt
	if nt >= Tier.SAND and _biomes[idx] != Biome.LAVA:
		_biomes[idx] = Biome.SCORCHED
	elif nt <= Tier.SHALLOW:
		_river_mask[idx] = 0
		_clear_frost_at(idx)
		_enqueue_water_tile(idx)


func _step_bomb_chain() -> void:
	var mw: int = map_w
	var steps: int = 0
	while not _detonate_queue.is_empty() and steps < 4:
		var idx: int = _detonate_queue[0]
		_detonate_queue.remove_at(0)
		var kind: int = _bomb_map[idx] & 3
		if kind == 0:
			continue
		_bomb_map[idx] = 0
		_bomb_count = maxi(0, _bomb_count - 1)
		_chain_detonations_total += 1
		steps += 1
		@warning_ignore("integer_division")
		var by: int = idx / mw
		var bx: int = idx % mw
		var blast_r: int = 6 if kind == 1 else 4
		_detonate_crater_at(bx, by, blast_r)
		var bpos := Vector2(float(bx) + 0.5, float(by) + 0.5)
		surface_impact.emit(bpos, float(blast_r * 2), "meteor")
		var fx := _resolve_fx()
		if fx != null and fx.has_method("play_sfx"):
			fx.play_sfx(0, bpos.x)


func _detonate_crater_at(cx: int, cy: int, radius: int) -> void:
	var mw: int = map_w
	var mh: int = map_h
	var chain_r: int = radius + 6
	var r_sq: int = radius * radius
	var y0: int = maxi(1, cy - chain_r)
	var y1: int = mini(mh - 2, cy + chain_r)
	var x0: int = maxi(1, cx - chain_r)
	var x1: int = mini(mw - 2, cx + chain_r)
	for py in range(y0, y1 + 1):
		var dy: int = py - cy
		var row_off: int = py * mw
		for px in range(x0, x1 + 1):
			var dx: int = px - cx
			var d_sq: int = dx * dx + dy * dy
			var idx: int = row_off + px
			if d_sq <= chain_r * chain_r and (_bomb_map[idx] & 3) > 0:
				_enqueue_bomb_detonation(idx)
			if d_sq <= r_sq:
				var falloff: float = 1.0 - float(d_sq) / maxf(1.0, float(r_sq))
				if _wall_mask[idx] > 0 and d_sq <= (radius >> 1) * (radius >> 1) + 2:
					_wall_mask[idx] = 0
				var h_new: float = maxf(0.10, _height[idx] - 0.13 * falloff)
				_height[idx] = h_new
				var nt: int = _classify_height(h_new)
				_tiers[idx] = nt
				_clear_frost_at(idx)
				var old_t: float = _temp[idx]
				var new_t: float = minf(520.0, old_t + 260.0 * falloff)
				_temp[idx] = new_t
				_temp_total_sum += new_t - old_t
				if nt >= Tier.SAND and _biomes[idx] != Biome.LAVA:
					_biomes[idx] = Biome.SCORCHED
					if _ash[idx] == 0:
						_ash_tiles += 1
					_ash[idx] = maxi(_ash[idx], int(180.0 * falloff))
				elif nt <= Tier.SHALLOW:
					_enqueue_water_tile(idx)
	_mark_tile_dirty(cx, cy, true, radius + 1)
	_seed_water_queue_rect(x0, y0, x1, y1)


func _enqueue_bomb_detonation(idx: int) -> void:
	if (_bomb_map[idx] & 3) == 0 or (_bomb_map[idx] & 4) != 0:
		return
	_bomb_map[idx] |= 4
	_detonate_queue.append(idx)


func _place_bomb_at(idx: int, bomb_kind: int) -> void:
	if idx < 0 or idx >= _bomb_map.size():
		return
	if (_bomb_map[idx] & 3) == 0:
		_bomb_count += 1
	_bomb_map[idx] = clampi(bomb_kind, 1, 2)


func _set_goo_at(idx: int, active: bool) -> void:
	if idx < 0 or idx >= _goo_map.size():
		return
	var cur: int = _goo_map[idx]
	if active and cur == 0:
		if _goo_active.size() >= MAX_GOO_ACTIVE:
			return
		_goo_map[idx] = 1
		_goo_active.append(idx)
	elif not active and cur != 0:
		_goo_map[idx] = 0


func _set_conway_at(idx: int, active: bool) -> void:
	if idx < 0 or idx >= _conway_map.size():
		return
	var cur: int = _conway_map[idx]
	if active and cur == 0:
		if _conway_active.size() >= MAX_CONWAY_CELLS:
			return
		_conway_map[idx] = 1
		_conway_active.append(idx)
	elif not active and cur != 0:
		_conway_map[idx] = 0


func _step_grey_goo_10hz() -> void:
	var mw: int = map_w
	var budget: int = mini(160, _goo_active.size())
	var idx_cursor: int = 0
	var eaten_any: bool = false
	for _s in range(budget):
		if _goo_active.is_empty():
			break
		if idx_cursor >= _goo_active.size():
			idx_cursor = 0
		var pos_in_list: int = _drop_rng.randi_range(0, _goo_active.size() - 1)
		var idx: int = _goo_active[pos_in_list]
		if _goo_map[idx] == 0:
			_goo_active[pos_in_list] = _goo_active[_goo_active.size() - 1]
			_goo_active.remove_at(_goo_active.size() - 1)
			continue
		@warning_ignore("integer_division")
		var py: int = idx / mw
		var px: int = idx % mw
		if px <= 1 or px >= mw - 2 or py <= 1 or py >= map_h - 2 or _tiers[idx] <= Tier.SHALLOW or _wall_mask[idx] > 0 or _temp[idx] >= 240.0:
			_goo_map[idx] = 0
			_goo_active[pos_in_list] = _goo_active[_goo_active.size() - 1]
			_goo_active.remove_at(_goo_active.size() - 1)
			_goo_decayed_total += 1
			_mark_tile_dirty(px, py, true, 0)
			continue

		var h_new: float = maxf(0.24, _height[idx] - 0.07)
		_height[idx] = h_new
		var nt: int = _classify_height(h_new)
		_tiers[idx] = nt
		eaten_any = true
		if nt <= Tier.SHALLOW:
			_goo_map[idx] = 0
			_goo_active[pos_in_list] = _goo_active[_goo_active.size() - 1]
			_goo_active.remove_at(_goo_active.size() - 1)
			_goo_decayed_total += 1
			_river_mask[idx] = 0
			_enqueue_water_tile(idx)
			_mark_tile_dirty(px, py, true, 1)
			continue

		var spread_done: bool = false
		if _goo_active.size() < MAX_GOO_ACTIVE:
			var d: int = _drop_rng.randi() & 3
			var nidx: int = idx - 1 if d == 0 else (idx + 1 if d == 1 else (idx - mw if d == 2 else idx + mw))
			if _goo_map[nidx] == 0 and _wall_mask[nidx] == 0 and _tiers[nidx] >= Tier.SAND:
				_set_goo_at(nidx, true)
				@warning_ignore("integer_division")
				_mark_tile_dirty(nidx % mw, nidx / mw, false, 0)
				spread_done = true
		if not spread_done:
			_mark_tile_dirty(px, py, true, 0)
		idx_cursor += 1
	if eaten_any and _active_chunks.size() < 4:
		_recompute_avg_temp_full()


func _step_conway_10hz() -> void:
	var mw: int = map_w
	var mh: int = map_h
	_work_stamp_id += 1
	if _work_stamp_id > 0x3FFFFFFF:
		_work_stamp.fill(0)
		_work_stamp_id = 1
	var stamp: int = _work_stamp_id

	var cands := PackedInt32Array()
	var n_alive: int = _conway_active.size()
	for i in range(n_alive):
		var aidx: int = _conway_active[i]
		if _conway_map[aidx] == 0:
			continue
		@warning_ignore("integer_division")
		var ay: int = aidx / mw
		var ax: int = aidx % mw
		for dy in range(-1, 2):
			var cy: int = ay + dy
			if cy <= 1 or cy >= mh - 2:
				continue
			var row_off: int = cy * mw
			for dx in range(-1, 2):
				var cx: int = ax + dx
				if cx <= 1 or cx >= mw - 2:
					continue
				var cidx: int = row_off + cx
				if _work_stamp[cidx] != stamp and _wall_mask[cidx] == 0:
					_work_stamp[cidx] = stamp
					cands.append(cidx)

	var next_alive := PackedInt32Array()
	var born := PackedInt32Array()
	var died := PackedInt32Array()
	for cidx in cands:
		var nb: int = _count_conway_neighbors(cidx, mw)
		var is_alive: bool = _conway_map[cidx] != 0
		if is_alive and (nb == 2 or nb == 3):
			next_alive.append(cidx)
		elif (not is_alive) and nb == 3 and next_alive.size() < MAX_CONWAY_CELLS:
			next_alive.append(cidx)
			born.append(cidx)
		elif is_alive:
			died.append(cidx)

	for idx in died:
		_conway_map[idx] = 0
		@warning_ignore("integer_division")
		_mark_tile_dirty(idx % mw, idx / mw, false, 0)
	for idx in born:
		_conway_map[idx] = 1
		@warning_ignore("integer_division")
		_mark_tile_dirty(idx % mw, idx / mw, false, 0)
	_conway_active = next_alive


func _count_conway_neighbors(idx: int, mw: int) -> int:
	var c: int = 0
	if _conway_map[idx - mw - 1] != 0:
		c += 1
	if _conway_map[idx - mw] != 0:
		c += 1
	if _conway_map[idx - mw + 1] != 0:
		c += 1
	if _conway_map[idx - 1] != 0:
		c += 1
	if _conway_map[idx + 1] != 0:
		c += 1
	if _conway_map[idx + mw - 1] != 0:
		c += 1
	if _conway_map[idx + mw] != 0:
		c += 1
	if _conway_map[idx + mw + 1] != 0:
		c += 1
	return c


func _erase_tile_at(idx: int) -> int:
	var did: int = 0
	if _wall_mask[idx] > 0:
		_wall_mask[idx] = 0
		did = 1
	if _vent_mask[idx] > 0:
		_vent_mask[idx] = 0
		did = 1
	if (_bomb_map[idx] & 3) > 0:
		_bomb_map[idx] = 0
		_bomb_count = maxi(0, _bomb_count - 1)
		did = 1
	if _goo_map[idx] > 0:
		_goo_map[idx] = 0
		did = 1
	if _conway_map[idx] > 0:
		_conway_map[idx] = 0
		did = 1
	if _fire[idx] > 0.0:
		_fire[idx] = 0.0
		_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
		did = 1
	if _rad[idx] > 0.0:
		_rad[idx] = 0.0
		did = 1
	if _ash[idx] > 0:
		_ash[idx] = 0
		_ash_tiles = maxi(0, _ash_tiles - 1)
		did = 1
	if _biomes[idx] == Biome.CREEP_MYCELIUM or _biomes[idx] == Biome.CREEP_CYBER or _biomes[idx] == Biome.LAVA:
		_biomes[idx] = Biome.RUST
		did = 1
	return did


func _erase_hazards_in_radius(world_pos: Vector2, radius: float) -> void:
	var r_sq: float = radius * radius
	remove_creep_nodes_in_radius(world_pos, radius)
	var gi: int = _geysers.size() - 1
	while gi >= 0:
		var gp: Vector2i = _geysers[gi]["pos"]
		if Vector2(gp).distance_squared_to(world_pos) <= r_sq:
			_geysers.remove_at(gi)
		gi -= 1
	var ti: int = _tornadoes.size() - 1
	while ti >= 0:
		if Vector2(_tornadoes[ti]["pos"]).distance_squared_to(world_pos) <= r_sq:
			_tornadoes.remove_at(ti)
		ti -= 1


func add_creep_node(world_pos: Vector2, biome_id: int) -> bool:
	_ensure_initialized()
	if biome_id != Biome.CREEP_MYCELIUM and biome_id != Biome.CREEP_CYBER:
		return false
	var px: int = clampi(int(floor(world_pos.x)), 1, map_w - 2)
	var py: int = clampi(int(floor(world_pos.y)), 1, map_h - 2)
	_ensure_creep_node_near(Vector2i(px, py), biome_id)
	return true


func remove_creep_nodes_in_radius(world_pos: Vector2, radius: float) -> int:
	var r_sq: float = radius * radius
	var removed: int = 0
	var i: int = _creep_nodes.size() - 1
	while i >= 0:
		var np: Vector2i = _creep_nodes[i]["pos"]
		if Vector2(float(np.x), float(np.y)).distance_squared_to(world_pos) <= r_sq:
			_creep_nodes.remove_at(i)
			removed += 1
		i -= 1
	return removed


func get_creep_node_count() -> int:
	return _creep_nodes.size()


func _ensure_creep_node_near(tile_pos: Vector2i, biome_id: int) -> void:
	for n in _creep_nodes:
		if int(n["biome"]) == biome_id:
			var np: Vector2i = n["pos"]
			var dx: int = np.x - tile_pos.x
			var dy: int = np.y - tile_pos.y
			if dx * dx + dy * dy <= 144:
				return
	if _creep_nodes.size() >= MAX_CREEP_NODES:
		_creep_nodes.remove_at(0)
	_creep_nodes.append({"pos": tile_pos, "biome": biome_id})


func _has_creep_node_near(px: int, py: int, biome_id: int) -> bool:
	for n in _creep_nodes:
		if int(n["biome"]) == biome_id:
			var np: Vector2i = n["pos"]
			var dx: int = px - np.x
			var dy: int = py - np.y
			if dx * dx + dy * dy <= CREEP_NODE_RADIUS_SQ:
				return true
	return false


func _activate_bio_chunk_at(px: int, py: int) -> void:
	var cx: int = clampi(px >> CHUNK_SHIFT, 0, _chunks_w - 1)
	var cy: int = clampi(py >> CHUNK_SHIFT, 0, _chunks_h - 1)
	var cidx: int = cy * _chunks_w + cx
	if _bio_chunk_active[cidx] == 0:
		_bio_chunk_active[cidx] = 1
		_bio_active_chunks.append(cidx)


func _recompute_bio_chunks_rect(x0: int, y0: int, x1: int, y1: int) -> void:
	var cx0: int = clampi(x0 >> CHUNK_SHIFT, 0, _chunks_w - 1)
	var cy0: int = clampi(y0 >> CHUNK_SHIFT, 0, _chunks_h - 1)
	var cx1: int = clampi((x1 - 1) >> CHUNK_SHIFT, 0, _chunks_w - 1)
	var cy1: int = clampi((y1 - 1) >> CHUNK_SHIFT, 0, _chunks_h - 1)
	var mw: int = map_w
	var mh: int = map_h
	for cy in range(cy0, cy1 + 1):
		var py0: int = cy << CHUNK_SHIFT
		var py1: int = mini(mh, py0 + CHUNK_SIZE)
		for cx in range(cx0, cx1 + 1):
			var px0: int = cx << CHUNK_SHIFT
			var px1: int = mini(mw, px0 + CHUNK_SIZE)
			var cidx: int = cy * _chunks_w + cx
			var has_bio: bool = false
			for py in range(py0, py1):
				var row_off: int = py * mw
				for px in range(px0, px1):
					if _biomes[row_off + px] >= Biome.XENO_JUNGLE:
						has_bio = true
						break
				if has_bio:
					break
			if has_bio and _bio_chunk_active[cidx] == 0:
				_bio_chunk_active[cidx] = 1
				_bio_active_chunks.append(cidx)


func _recompute_bio_active_chunks() -> void:
	_bio_chunk_active.fill(0)
	_bio_active_chunks.clear()
	_recompute_bio_chunks_rect(0, 0, map_w, map_h)


func _step_biome_competition_10hz() -> void:
	var allow_grow: bool = bool(_world_laws.get("biome_growth", true))
	var allow_decay: bool = bool(_world_laws.get("creep_decay", true))
	if not allow_grow and not allow_decay:
		return
	var active_n: int = _bio_active_chunks.size()
	if active_n == 0:
		return

	var budget: int = mini(6, active_n)
	var mw: int = map_w
	var mh: int = map_h
	for _c in range(budget):
		if _bio_chunk_cursor >= _bio_active_chunks.size():
			_bio_chunk_cursor = 0
		var cidx: int = _bio_active_chunks[_bio_chunk_cursor]
		_bio_chunk_cursor += 1
		@warning_ignore("integer_division")
		var cy: int = cidx / _chunks_w
		var cx: int = cidx % _chunks_w
		var x0: int = maxi(1, cx << CHUNK_SHIFT)
		var y0: int = maxi(1, cy << CHUNK_SHIFT)
		var x1: int = mini(mw - 2, x0 + CHUNK_SIZE - 1)
		var y1: int = mini(mh - 2, y0 + CHUNK_SIZE - 1)
		for _s in range(28):
			var px: int = _biome_rng.randi_range(x0, x1)
			var py: int = _biome_rng.randi_range(y0, y1)
			var idx: int = py * mw + px
			var b: int = _biomes[idx]
			if b < Biome.XENO_JUNGLE or _tiers[idx] < Tier.SAND or _tiers[idx] > Tier.HILLS or _wall_mask[idx] > 0:
				continue
			if (b == Biome.CREEP_MYCELIUM or b == Biome.CREEP_CYBER) and allow_decay and not _has_creep_node_near(px, py, b):
				if _biome_rng.randf() < 0.55:
					_biomes[idx] = Biome.LUSH if _moisture[idx] >= 0.48 else Biome.RUST
					_mark_tile_dirty(px, py, true, 0)
				continue
			if allow_grow:
				_try_biome_spread_tile(px, py, idx, b)


func _try_biome_spread_tile(px: int, py: int, idx: int, b: int) -> void:
	var d: int = _biome_rng.randi() & 3
	var nx: int = px + (-1 if d == 0 else (1 if d == 1 else 0))
	var ny: int = py + (-1 if d == 2 else (1 if d == 3 else 0))
	if nx <= 1 or nx >= map_w - 2 or ny <= 1 or ny >= map_h - 2:
		return
	var nidx: int = ny * map_w + nx
	var nt: int = _tiers[nidx]
	if nt < Tier.SAND or nt > Tier.HILLS or _wall_mask[nidx] > 0 or _fire[nidx] > 0.05:
		return
	var nb_b: int = _biomes[nidx]
	if nb_b == b or nb_b == Biome.LAVA:
		return
	if (b == Biome.CREEP_MYCELIUM or b == Biome.CREEP_CYBER) and not _has_creep_node_near(nx, ny, b):
		return

	var my_str: int = BIOME_GROW_STRENGTH[clampi(b, 0, BIOME_GROW_STRENGTH.size() - 1)]
	var nb_str: int = BIOME_GROW_STRENGTH[clampi(nb_b, 0, BIOME_GROW_STRENGTH.size() - 1)]
	var allow_overgrow: bool = bool(_world_laws.get("biome_overgrowth", true))
	if nb_b != Biome.RUST and nb_b != Biome.SCORCHED and (not allow_overgrow or my_str < nb_str):
		return
	var chance: float = 0.42 if (nb_b == Biome.RUST or nb_b == Biome.SCORCHED) else (0.14 if my_str == nb_str else 0.34)
	if _biome_rng.randf() >= chance:
		return
	if b == Biome.CRYO_TUNDRA and _temp[nidx] > 18.0:
		_temp[nidx] = 6.0
	_biomes[nidx] = b
	_activate_bio_chunk_at(nx, ny)
	_mark_tile_dirty(nx, ny, true, 0)


func trigger_world_disaster(world_pos: Vector2, disaster_id: int) -> bool:
	_ensure_initialized()
	if not bool(_world_laws.get("disasters", true)):
		return false
	var cx: int = clampi(int(floor(world_pos.x)), 12, map_w - 13)
	var cy: int = clampi(int(floor(world_pos.y)), 12, map_h - 13)
	var pos := Vector2(float(cx) + 0.5, float(cy) + 0.5)
	var fx := _resolve_fx()

	if disaster_id == DisasterKind.VOLCANO_ERUPTION:
		var cidx: int = cy * map_w + cx
		if _vent_mask[cidx] == 0:
			apply_shaped_brush(pos, 6, Vector2i(BrushMode.LAVA_VOLCANO, BrushShape.CIRCLE))
		if _drops != null:
			for _i in range(14):
				var ang: float = _drop_rng.randf() * TAU
				var spd: float = _drop_rng.randf_range(6.0, 22.0)
				_drops.launch_parabolic(pos, Vector3(cos(ang) * spd, sin(ang) * spd, _drop_rng.randf_range(26.0, 44.0)), WorldDropsScript.DropKind.LAVA)
			_sync_drops_to_fx()
		_volcano_eruptions_total += 1
		if fx != null and fx.has_method("play_sfx"):
			fx.play_sfx(24, pos.x)
		return true

	if disaster_id == DisasterKind.GEYSER_STEAM or disaster_id == DisasterKind.GEYSER_ACID:
		if _geysers.size() >= MAX_GEYSERS:
			_geysers.remove_at(0)
		var gkind: int = 0 if disaster_id == DisasterKind.GEYSER_STEAM else 1
		_geysers.append({"pos": Vector2i(cx, cy), "kind": gkind, "timer": 0.9, "life": 18.0})
		_step_volcanoes_and_geysers(0.05)
		return true

	if disaster_id == DisasterKind.TORNADO:
		if _tornadoes.size() >= MAX_TORNADOES:
			_tornadoes.remove_at(0)
		var ang_t: float = _drop_rng.randf() * TAU
		_tornadoes.append({"pos": pos, "vel": Vector2(cos(ang_t), sin(ang_t)) * 22.0, "life": 14.0, "phase": 0.0, "fx_cd": 0.0})
		if fx != null and fx.has_method("play_sfx"):
			fx.play_sfx(24, pos.x)
		return true

	if disaster_id == DisasterKind.EARTHQUAKE:
		var ang_q: float = _drop_rng.randf() * TAU
		var qpos: Vector2 = pos - Vector2(cos(ang_q), sin(ang_q)) * 28.0
		for step_i in range(28):
			ang_q += _drop_rng.randf_range(-0.42, 0.42)
			qpos += Vector2(cos(ang_q), sin(ang_q)) * 2.5
			var qx: int = clampi(int(qpos.x), 4, map_w - 5)
			var qy: int = clampi(int(qpos.y), 4, map_h - 5)
			_quake_steps.append(Vector3i(qx, qy, 2 + (step_i & 1)))
		_step_earthquake_fault()
		if fx != null and fx.has_method("play_sfx"):
			fx.play_sfx(23, pos.x)
		return true

	return _trigger_disaster_extra(cx, cy, pos, disaster_id)


func _trigger_disaster_extra(cx: int, cy: int, pos: Vector2, disaster_id: int) -> bool:
	if disaster_id == DisasterKind.CHAIN_BOMB:
		var first_idx: int = -1
		for bi in range(7):
			var ang: float = float(bi) * (TAU / 7.0)
			var dist: float = 0.0 if bi == 0 else float(4 + (bi & 1) * 3)
			var bx: int = clampi(cx + int(round(cos(ang) * dist)), 3, map_w - 4)
			var by: int = clampi(cy + int(round(sin(ang) * dist)), 3, map_h - 4)
			var bidx: int = by * map_w + bx
			_wall_mask[bidx] = 0
			_place_bomb_at(bidx, 1 if (bi & 1) == 0 else 2)
			if first_idx < 0:
				first_idx = bidx
		if first_idx >= 0:
			_enqueue_bomb_detonation(first_idx)
		_render_rect(maxi(0, cx - 12), maxi(0, cy - 12), 25, 25)
		return true

	if disaster_id == DisasterKind.GREY_GOO:
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				if dx * dx + dy * dy <= 9:
					var gidx: int = (cy + dy) * map_w + (cx + dx)
					if _tiers[gidx] < Tier.SAND:
						_height[gidx] = 0.42
						_tiers[gidx] = Tier.SOIL_LOW
					_set_goo_at(gidx, true)
		_render_rect(maxi(0, cx - 5), maxi(0, cy - 5), 11, 11)
		region_changed.emit(Rect2i(maxi(0, cx - 5), maxi(0, cy - 5), 11, 11))
		return true

	if disaster_id == DisasterKind.CONWAY_LIFE:
		var offsets: Array[Vector2i] = [
			Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(0, 1),
			Vector2i(4, 0), Vector2i(5, 1), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2),
		]
		for off in offsets:
			var px: int = clampi(cx + off.x, 2, map_w - 3)
			var py: int = clampi(cy + off.y, 2, map_h - 3)
			var cidx: int = py * map_w + px
			_wall_mask[cidx] = 0
			_set_conway_at(cidx, true)
		_render_rect(maxi(0, cx - 3), maxi(0, cy - 3), 11, 8)
		return true

	if disaster_id == DisasterKind.METEOR_SHOWER:
		spawn_sky_drops(pos, 26.0, WorldDropsScript.DropKind.METEOR_SHARD)
		surface_impact.emit(pos, 14.0, "meteor")
		return true

	if disaster_id == DisasterKind.CREEP_BLOOM:
		var mode: int = BrushMode.BIOME_CREEP_MYCELIUM if ((cx + cy) & 1) == 0 else BrushMode.BIOME_CREEP_CYBER
		apply_shaped_brush(pos, 8, Vector2i(mode, BrushShape.CIRCLE))
		return true

	if disaster_id == DisasterKind.ION_LIGHTNING:
		apply_orbital_strike(pos, 18.0, true)
		spawn_sky_drops(pos, 12.0, WorldDropsScript.DropKind.PLASMA_ARC)
		return true

	if disaster_id == DisasterKind.HEATWAVE:
		apply_elemental_storm(pos, 24.0, "firestorm")
		spawn_sky_drops(pos, 18.0, WorldDropsScript.DropKind.FIRE)
		return true

	return false


func get_drop_count() -> int:
	return _drops.get_count() if _drops != null else 0


func get_active_hazard_count() -> int:
	return (
		_vent_tiles.size()
		+ _geysers.size()
		+ _tornadoes.size()
		+ _quake_steps.size()
		+ _detonate_queue.size()
		+ _bomb_count
		+ _goo_active.size()
		+ _conway_active.size()
		+ _creep_nodes.size()
	)


func get_drops_snapshot_data() -> Dictionary:
	if _drops != null:
		return _drops.build_snapshot()
	return {
		"count": 0,
		"positions": PackedVector2Array(),
		"colors": PackedColorArray(),
		"z_heights": PackedFloat32Array(),
	}


func get_preferred_flora_for_tile(px: int, py: int) -> int:
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return 0
	var idx: int = py * map_w + px
	var b: int = _biomes[idx]
	var hv: int = ((px * 73856093) ^ (py * 19349663)) & 31
	if b == Biome.XENO_JUNGLE:
		return 18 if hv < 5 else 14
	if b == Biome.CRYO_TUNDRA:
		return 15
	if b == Biome.ACID_WASTE:
		return 22 if hv < 6 else 16
	if b == Biome.SILICA_DUNES:
		return 17
	if b == Biome.BIOLUM_OASIS:
		return 18
	if b == Biome.CREEP_MYCELIUM:
		return 19 if hv < 8 else 20
	if b == Biome.CREEP_CYBER:
		return 23 if hv < 6 else 21
	if b == Biome.CRYSTAL:
		return 23 if _rad[idx] >= 0.72 else 5
	if b == Biome.LUSH:
		return hv & 3
	return 4


func get_biome_name(biome_id: int) -> String:
	return BIOME_NAMES[clampi(biome_id, 0, BIOME_NAMES.size() - 1)]


func get_template_name(template_id: int) -> String:
	return TEMPLATE_NAMES[clampi(template_id, 0, TEMPLATE_NAMES.size() - 1)]


func get_dominant_biome_in_rect(cam_rect: Rect2) -> int:
	if _biomes.is_empty():
		return Biome.RUST
	var x0: int = clampi(int(floor(cam_rect.position.x)), 0, map_w - 1)
	var y0: int = clampi(int(floor(cam_rect.position.y)), 0, map_h - 1)
	var x1: int = clampi(int(ceil(cam_rect.end.x)), x0 + 1, map_w)
	var y1: int = clampi(int(ceil(cam_rect.end.y)), y0 + 1, map_h)
	var sx: int = maxi(1, (x1 - x0) / 10)
	var sy: int = maxi(1, (y1 - y0) / 8)
	var counts := PackedInt32Array()
	counts.resize(BIOME_NAMES.size())
	var water_cnt: int = 0
	var land_cnt: int = 0
	for py in range(y0, y1, sy):
		var row_off: int = py * map_w
		for px in range(x0, x1, sx):
			var idx: int = row_off + px
			if _tiers[idx] <= Tier.SHALLOW:
				water_cnt += 1
			else:
				var b: int = clampi(_biomes[idx], 0, counts.size() - 1)
				counts[b] += 1
				land_cnt += 1
	if water_cnt > land_cnt * 2:
		return -1
	var best_b: int = Biome.RUST
	var best_n: int = -1
	for bi in range(counts.size()):
		if counts[bi] > best_n:
			best_n = counts[bi]
			best_b = bi
	return best_b


func get_world_extended_stats() -> Dictionary:
	return {
		"template_id": _template_id,
		"drops_active": get_drop_count(),
		"vent_count": _vent_tiles.size(),
		"geyser_count": _geysers.size(),
		"tornado_count": _tornadoes.size(),
		"quake_pending": _quake_steps.size(),
		"bomb_count": _bomb_count,
		"chain_detonations_total": _chain_detonations_total,
		"volcano_eruptions_total": _volcano_eruptions_total,
		"volcanoes_sealed_total": _volcanoes_sealed_total,
		"goo_active": _goo_active.size(),
		"goo_decayed_total": _goo_decayed_total,
		"conway_active": _conway_active.size(),
		"creep_nodes": _creep_nodes.size(),
		"bio_active_chunks": _bio_active_chunks.size(),
	}


func _activate_chunk(cidx: int) -> void:
	if _chunk_active[cidx] != 0:
		return
	_chunk_active[cidx] = 1
	_chunk_row_mask[cidx] = 0xFFFF
	_active_chunk_pos[cidx] = _active_chunks.size()
	_active_chunks.append(cidx)


func _activate_tile_row(px: int, py: int) -> void:
	var cx: int = clampi(px >> CHUNK_SHIFT, 0, _chunks_w - 1)
	var cy: int = clampi(py >> CHUNK_SHIFT, 0, _chunks_h - 1)
	var cidx: int = cy * _chunks_w + cx
	if _chunk_active[cidx] == 0:
		_chunk_active[cidx] = 1
		_chunk_row_mask[cidx] = 0
		_active_chunk_pos[cidx] = _active_chunks.size()
		_active_chunks.append(cidx)
	_chunk_row_mask[cidx] |= 1 << (py & 15)


func _deactivate_chunk_at(pos: int) -> void:
	var cidx: int = _active_chunks[pos]
	_active_chunk_pos[cidx] = -1
	var last_idx: int = _active_chunks.size() - 1
	if pos != last_idx:
		var moved: int = _active_chunks[last_idx]
		_active_chunks[pos] = moved
		_active_chunk_pos[moved] = pos
	_active_chunks.remove_at(last_idx)


func _mark_chunk_dirty(cidx: int, structural: bool = false) -> void:
	if _chunk_dirty[cidx] == 0:
		_chunk_dirty[cidx] = 1
		_dirty_chunks.append(cidx)
	_chunk_dirty_bounds[cidx] = 0xFF00
	if structural and _chunk_struct_dirty[cidx] == 0:
		_chunk_struct_dirty[cidx] = 1
		_structural_dirty_chunks.append(cidx)


func _mark_chunk_dirty_local(cidx: int, lx0: int, ly0: int, lx1: int, ly1: int, structural: bool) -> void:
	if _chunk_dirty[cidx] == 0:
		_chunk_dirty[cidx] = 1
		_dirty_chunks.append(cidx)
		_chunk_dirty_bounds[cidx] = lx0 | (ly0 << 4) | (lx1 << 8) | (ly1 << 12)
	else:
		var b: int = _chunk_dirty_bounds[cidx]
		if b != 0xFF00:
			var nx0: int = mini(b & 15, lx0)
			var ny0: int = mini((b >> 4) & 15, ly0)
			var nx1: int = maxi((b >> 8) & 15, lx1)
			var ny1: int = maxi((b >> 12) & 15, ly1)
			_chunk_dirty_bounds[cidx] = nx0 | (ny0 << 4) | (nx1 << 8) | (ny1 << 12)
	if structural and _chunk_struct_dirty[cidx] == 0:
		_chunk_struct_dirty[cidx] = 1
		_structural_dirty_chunks.append(cidx)


func _mark_tile_dirty(px: int, py: int, structural: bool, neighbor_pad: int) -> void:
	var cx: int = clampi(px >> CHUNK_SHIFT, 0, _chunks_w - 1)
	var cy: int = clampi(py >> CHUNK_SHIFT, 0, _chunks_h - 1)
	var cidx: int = cy * _chunks_w + cx
	_activate_tile_row(px, py)
	if neighbor_pad <= 0:
		var lx: int = px & 15
		var ly: int = py & 15
		_mark_chunk_dirty_local(cidx, lx, ly, lx, ly, structural)
		return
	var x0: int = px - neighbor_pad
	var y0: int = py - neighbor_pad
	var x1: int = px + neighbor_pad
	var y1: int = py + neighbor_pad
	var cx0: int = clampi(x0 >> CHUNK_SHIFT, 0, _chunks_w - 1)
	var cy0: int = clampi(y0 >> CHUNK_SHIFT, 0, _chunks_h - 1)
	var cx1: int = clampi(x1 >> CHUNK_SHIFT, 0, _chunks_w - 1)
	var cy1: int = clampi(y1 >> CHUNK_SHIFT, 0, _chunks_h - 1)
	for ncy in range(cy0, cy1 + 1):
		var by: int = ncy << CHUNK_SHIFT
		var ly0: int = maxi(0, y0 - by)
		var ly1: int = mini(15, y1 - by)
		var row_off: int = ncy * _chunks_w
		for ncx in range(cx0, cx1 + 1):
			var bx: int = ncx << CHUNK_SHIFT
			var lx0: int = maxi(0, x0 - bx)
			var lx1: int = mini(15, x1 - bx)
			var ncidx: int = row_off + ncx
			_mark_chunk_dirty_local(ncidx, lx0, ly0, lx1, ly1, structural and ncidx == cidx)


func _mark_chunks_in_rect(x0: int, y0: int, w: int, h: int, mark_dirty: bool) -> void:
	if w <= 0 or h <= 0:
		return
	var cx0: int = clampi(x0 >> CHUNK_SHIFT, 0, _chunks_w - 1)
	var cy0: int = clampi(y0 >> CHUNK_SHIFT, 0, _chunks_h - 1)
	var cx1: int = clampi((x0 + w - 1) >> CHUNK_SHIFT, 0, _chunks_w - 1)
	var cy1: int = clampi((y0 + h - 1) >> CHUNK_SHIFT, 0, _chunks_h - 1)
	for cy in range(cy0, cy1 + 1):
		var row_off: int = cy * _chunks_w
		for cx in range(cx0, cx1 + 1):
			var cidx: int = row_off + cx
			_activate_chunk(cidx)
			_chunk_row_mask[cidx] = 0xFFFF
			if mark_dirty:
				_mark_chunk_dirty(cidx, false)


func _recompute_all_chunk_flags() -> void:
	var eq_max: float = float(TUNING_KNOBS["TEMP_EQUILIBRIUM_MAX_C"])
	var eq_min: float = float(TUNING_KNOBS["TEMP_EQUILIBRIUM_MIN_C"])
	var amb_c: float = float(TUNING_KNOBS["TEMP_AMBIENT_C"])
	var freeze_c: float = float(TUNING_KNOBS["ICE_FREEZE_TEMP_C"])
	var crys_floor: float = float(TUNING_KNOBS["RAD_CRYSTAL_FLOOR"])
	_active_chunks.clear()
	_active_chunk_pos.fill(-1)
	_chunk_active.fill(0)
	_chunk_row_mask.fill(0)
	_frost_tiles = 0

	for cy in range(_chunks_h):
		var y0: int = cy << CHUNK_SHIFT
		var y1: int = mini(map_h, y0 + CHUNK_SIZE)
		for cx in range(_chunks_w):
			var x0: int = cx << CHUNK_SHIFT
			var x1: int = mini(map_w, x0 + CHUNK_SIZE)
			var rmask: int = 0
			for py in range(y0, y1):
				var row_off: int = py * map_w
				var row_lat_s: float = _row_lat_shift(py)
				var row_on: bool = false
				for px in range(x0, x1):
					var idx: int = row_off + px
					var fr: int = _frost[idx]
					if fr > 0:
						_frost_tiles += 1
					if row_on:
						continue
					var b: int = _biomes[idx]
					var r_floor: float = crys_floor if b == Biome.CRYSTAL else 0.02
					var t_v: float = _temp[idx]
					var t_eff: float = t_v + _cosmic_temp_offset
					var tier_v: int = _tiers[idx]
					var lat_s: float = row_lat_s * 0.85 - 0.30 if tier_v <= Tier.SHALLOW else row_lat_s
					var target_amb: float = amb_c + lat_s - maxf(0.0, _height[idx] - 0.42) * 86.0
					var cold_eligible: bool = _frost_tiles > 0 or _cosmic_temp_offset <= -2.0 or t_eff <= freeze_c
					var cold_on: bool = (fr > 0 and fr < 255) or (cold_eligible and tier_v < Tier.HILLS and t_eff < eq_min and (absf(t_v - target_amb) > 1.0 or (tier_v == Tier.SHALLOW and t_eff <= freeze_c and fr < 255)))
					if _fire[idx] > 0.0 or _ash[idx] > 0 or b == Biome.LAVA or t_v > eq_max or cold_on or _rad[idx] > r_floor or _plasma_glow[idx] > 0:
						rmask |= 1 << (py & 15)
						row_on = true
			if rmask != 0:
				var cidx: int = cy * _chunks_w + cx
				_chunk_active[cidx] = 1
				_chunk_row_mask[cidx] = rmask
				_active_chunk_pos[cidx] = _active_chunks.size()
				_active_chunks.append(cidx)


func _flush_dirty_chunks() -> void:
	var n_dirty: int = _dirty_chunks.size()
	if n_dirty == 0:
		return

	var upload_flags: int = 0
	for i in range(n_dirty):
		var cidx: int = _dirty_chunks[i]
		_chunk_dirty[cidx] = 0
		var b: int = _chunk_dirty_bounds[cidx]
		_chunk_dirty_bounds[cidx] = 0
		@warning_ignore("integer_division")
		var cy: int = cidx / _chunks_w
		var cx: int = cidx % _chunks_w
		var base_x: int = cx << CHUNK_SHIFT
		var base_y: int = cy << CHUNK_SHIFT
		var x0: int = base_x + (b & 15)
		var y0: int = base_y + ((b >> 4) & 15)
		var x1: int = mini(map_w, base_x + ((b >> 8) & 15) + 1)
		var y1: int = mini(map_h, base_y + ((b >> 12) & 15) + 1)
		if x0 < x1 and y0 < y1:
			upload_flags |= _render_pixels_range(x0, y0, x1, y1)

	_dirty_chunks.clear()
	if upload_flags != 0:
		_upload_textures((upload_flags & 1) != 0, (upload_flags & 2) != 0)


func _flush_structural_dirty_regions() -> void:
	var n: int = _structural_dirty_chunks.size()
	if n == 0:
		return

	# Cluster adjacent/nearby structural chunks into bounded patches (<= 64x64 px) so distant continents never merge
	var clusters: Array[Rect2i] = []
	for i in range(n):
		var cidx: int = _structural_dirty_chunks[i]
		@warning_ignore("integer_division")
		var cy: int = cidx / _chunks_w
		var cx: int = cidx % _chunks_w
		var x0: int = cx << CHUNK_SHIFT
		var y0: int = cy << CHUNK_SHIFT
		var x1: int = mini(map_w, x0 + CHUNK_SIZE)
		var y1: int = mini(map_h, y0 + CHUNK_SIZE)

		var merged: bool = false
		for ci in range(clusters.size()):
			var cr: Rect2i = clusters[ci]
			var mx0: int = mini(cr.position.x, x0)
			var my0: int = mini(cr.position.y, y0)
			var mx1: int = maxi(cr.position.x + cr.size.x, x1)
			var my1: int = maxi(cr.position.y + cr.size.y, y1)
			if (mx1 - mx0) <= STRUCT_CLUSTER_MAX_SPAN_PX and (my1 - my0) <= STRUCT_CLUSTER_MAX_SPAN_PX:
				var gap_x: int = maxi(cr.position.x, x0) - mini(cr.position.x + cr.size.x, x1)
				var gap_y: int = maxi(cr.position.y, y0) - mini(cr.position.y + cr.size.y, y1)
				if gap_x <= STRUCT_CLUSTER_MAX_GAP_PX and gap_y <= STRUCT_CLUSTER_MAX_GAP_PX:
					clusters[ci] = Rect2i(mx0, my0, mx1 - mx0, my1 - my0)
					merged = true
					break
		if not merged:
			clusters.append(Rect2i(x0, y0, x1 - x0, y1 - y0))

	var ci_a: int = 0
	while ci_a < clusters.size():
		var ra: Rect2i = clusters[ci_a]
		var ci_b: int = ci_a + 1
		while ci_b < clusters.size():
			var rb: Rect2i = clusters[ci_b]
			var mx0: int = mini(ra.position.x, rb.position.x)
			var my0: int = mini(ra.position.y, rb.position.y)
			var mx1: int = maxi(ra.position.x + ra.size.x, rb.position.x + rb.size.x)
			var my1: int = maxi(ra.position.y + ra.size.y, rb.position.y + rb.size.y)
			if (mx1 - mx0) <= STRUCT_CLUSTER_MAX_SPAN_PX and (my1 - my0) <= STRUCT_CLUSTER_MAX_SPAN_PX:
				var gap_x: int = maxi(ra.position.x, rb.position.x) - mini(ra.position.x + ra.size.x, rb.position.x + rb.size.x)
				var gap_y: int = maxi(ra.position.y, rb.position.y) - mini(ra.position.y + ra.size.y, rb.position.y + rb.size.y)
				if gap_x <= STRUCT_CLUSTER_MAX_GAP_PX and gap_y <= STRUCT_CLUSTER_MAX_GAP_PX:
					ra = Rect2i(mx0, my0, mx1 - mx0, my1 - my0)
					clusters[ci_a] = ra
					clusters.remove_at(ci_b)
					ci_b = ci_a + 1
					continue
			ci_b += 1
		ci_a += 1

	var emit_n: int = mini(clusters.size(), STRUCT_MAX_RECTS_PER_FLUSH)
	if emit_n == clusters.size():
		for i in range(n):
			_chunk_struct_dirty[_structural_dirty_chunks[i]] = 0
		_structural_dirty_chunks.clear()
	else:
		var deferred := PackedInt32Array()
		for i in range(n):
			var cidx: int = _structural_dirty_chunks[i]
			@warning_ignore("integer_division")
			var cy: int = cidx / _chunks_w
			var cx: int = cidx % _chunks_w
			var px0: int = cx << CHUNK_SHIFT
			var py0: int = cy << CHUNK_SHIFT
			var covered: bool = false
			for ei in range(emit_n):
				var er: Rect2i = clusters[ei]
				if px0 >= er.position.x and px0 < er.position.x + er.size.x and py0 >= er.position.y and py0 < er.position.y + er.size.y:
					covered = true
					break
			if covered:
				_chunk_struct_dirty[cidx] = 0
			else:
				deferred.append(cidx)
		_structural_dirty_chunks = deferred

	for ei in range(emit_n):
		region_changed.emit(clusters[ei])


func _render_rect(x0: int, y0: int, w: int, h: int, force_upload: bool = false) -> void:
	var rx0: int = maxi(0, x0)
	var ry0: int = maxi(0, y0)
	var rx1: int = mini(map_w, x0 + w)
	var ry1: int = mini(map_h, y0 + h)
	if rx0 >= rx1 or ry0 >= ry1:
		return
	var upload_flags: int = _render_pixels_range(rx0, ry0, rx1, ry1)
	if force_upload:
		_upload_textures(true, true)
	elif upload_flags != 0:
		_upload_textures((upload_flags & 1) != 0, (upload_flags & 2) != 0)


func _upload_textures(upload_rgba: bool = true, upload_mask: bool = true) -> void:
	if upload_rgba:
		_image.set_data(map_w, map_h, false, Image.FORMAT_RGBA8, _rgba_buf)
		_texture.update(_image)
	if upload_mask:
		_mask_image.set_data(map_w, map_h, false, Image.FORMAT_RGBA8, _mask_buf)
		_mask_texture.update(_mask_image)


func _render_pixels_range(rx0: int, ry0: int, rx1: int, ry1: int) -> int:
	var upload_flags: int = 0
	for y in range(ry0, ry1):
		_render_row_base(y, rx0, rx1)
		upload_flags |= _render_row_commit(y, rx0, rx1)
	return upload_flags


func _render_row_base(y: int, rx0: int, rx1: int) -> void:
	var mw: int = map_w
	var mh: int = map_h
	var row_off: int = y * mw
	var row_n: int = maxi(0, y - 1) * mw
	var row_s: int = mini(mh - 1, y + 1) * mw
	for x in range(rx0, rx1):
		var idx: int = row_off + x
		var t: int = _tiers[idx]
		var b: int = _biomes[idx]
		var h: float = _height[idx]
		var hv: int = ((x * 73856093) ^ (y * 19349663)) & 63
		var crys_role: int = 0
		var col: Color

		if t == Tier.DEEP_OCEAN:
			var shelf_w: float = h + sin(float(x) * 0.042 + float(y) * 0.031) * 0.009
			var depth_t: float = clampf(shelf_w / 0.21, 0.0, 1.0)
			var blend_d: float = lerpf(depth_t, floorf(clampf(depth_t, 0.0, 0.999) * 4.0) / 3.0, 0.55)
			col = COL_DEEP_ABYSS.lerp(COL_DEEP_A, blend_d / 0.35) if blend_d < 0.35 else COL_DEEP_A.lerp(COL_DEEP_B, (blend_d - 0.35) / 0.65)
		elif t == Tier.CLOSE_OCEAN:
			var close_t: float = clampf((h - 0.21) / 0.08, 0.0, 1.0)
			col = COL_CLOSE_A.lerp(COL_CLOSE_B, lerpf(close_t, floorf(clampf(close_t, 0.0, 0.999) * 3.0) / 2.0, 0.35))
		elif t == Tier.SHALLOW:
			var frost_v: int = _frost[idx]
			if frost_v >= 128:
				var xp: int = maxi(0, x - 1)
				var xn: int = mini(mw - 1, x + 1)
				if (_tiers[row_off + xp] <= Tier.SHALLOW and _frost[row_off + xp] < 128) or (_tiers[row_off + xn] <= Tier.SHALLOW and _frost[row_off + xn] < 128) or (_tiers[row_n + x] <= Tier.SHALLOW and _frost[row_n + x] < 128) or (_tiers[row_s + x] <= Tier.SHALLOW and _frost[row_s + x] < 128):
					col = COL_ICE_RIM
				elif y > 0 and _tiers[row_n + x] >= Tier.SAND:
					col = COL_ICE_MID
				else:
					var ic: bool = ((hv & 7) == 0) or (((x + y) & 7) == 0 and (hv & 1) == 0)
					col = COL_ICE_DEEP if ic else (COL_ICE_CORE if (hv & 3) != 0 else COL_ICE_MID)
			else:
				col = COL_RIVER_WATER if _river_mask[idx] > 0 else COL_SHALLOW_A.lerp(COL_SHALLOW_B, clampf((h - 0.29) / 0.065, 0.0, 1.0))
				if frost_v > 0:
					col = col.lerp(COL_ICE_MID, float(frost_v) / 160.0)
		elif t == Tier.SAND:
			var xp_s: int = maxi(0, x - 1)
			var xn_s: int = mini(mw - 1, x + 1)
			if _tiers[row_off + xp_s] <= Tier.SHALLOW or _tiers[row_off + xn_s] <= Tier.SHALLOW or _tiers[row_n + x] <= Tier.SHALLOW or _tiers[row_s + x] <= Tier.SHALLOW:
				col = COL_SAND_WET
			elif _tiers[row_n + xp_s] <= Tier.SHALLOW or _tiers[row_n + xn_s] <= Tier.SHALLOW or _tiers[row_s + xp_s] <= Tier.SHALLOW or _tiers[row_s + xn_s] <= Tier.SHALLOW:
				col = COL_SAND_DRY.lerp(COL_SAND_WET, 0.45)
			else:
				col = COL_SAND_PEBBLE if (hv == 7 or hv == 43) else (COL_SAND_SHELL if hv == 21 else COL_SAND_DRY)
		elif t == Tier.SOIL_LOW or t == Tier.SOIL_HIGH:
			if b == Biome.LUSH:
				col = COL_LUSH_TUFT if hv < 5 else (COL_LUSH_FLOWER_A if hv == 19 else (COL_LUSH_FLOWER_B if hv == 41 else (COL_LUSH_LOW if t == Tier.SOIL_LOW else COL_LUSH_HIGH)))
			elif b == Biome.CRYSTAL:
				crys_role = _crystal_cluster_role(x, y)
				col = COL_CRYS_TIP if crys_role == 3 else (COL_CRYS_VEIN if crys_role == 2 else (COL_CRYS_SLATE if (crys_role == 1 or hv > 54) else (COL_CRYS_LOW if t == Tier.SOIL_LOW else COL_CRYS_HIGH)))
			elif b == Biome.SCORCHED:
				var sc_s: bool = (hv & 3) == 0 and (sin(float(x) * 0.45 + float(y) * 0.35) + cos(float(x - y) * 0.52) > 1.38)
				col = _scorched_color_at(t, _temp[idx], hv, sc_s)
			elif b == Biome.LAVA:
				col = _lava_color_at(_temp[idx], hv)
			elif b >= Biome.XENO_JUNGLE:
				var gx_n: float = (_height[row_off + mini(mw - 1, x + 1)] - _height[row_off + maxi(0, x - 1)]) * 0.5
				var gy_n: float = (_height[row_s + x] - _height[row_n + x]) * 0.5
				_ren_crys_role = 0
				col = _render_tile_new_biome_col(x, y, t, b, h, hv, (gx_n + gy_n) * 0.7071)
				crys_role = _ren_crys_role
			else:
				var gx_r: float = (_height[row_off + mini(mw - 1, x + 1)] - _height[row_off + maxi(0, x - 1)]) * 0.5
				var gy_r: float = (_height[row_s + x] - _height[row_n + x]) * 0.5
				var dw: float = sin(float(x) * 0.14 + float(y) * 0.22 + h * 14.0) + (gx_r + gy_r) * 12.728
				col = COL_RUST_DUNE if dw > 0.68 else (COL_RUST_DARK if (dw < -0.78 or hv > 58) else (COL_RUST_LOW if t == Tier.SOIL_LOW else COL_RUST_HIGH))
		else:
			col = _render_highland_col(x, y, idx, t, b, h, hv, row_off, row_n, row_s)
			crys_role = _ren_crys_role
		_ren_row_col[x] = col
		_ren_row_crys[x] = crys_role


func _render_highland_col(x: int, y: int, idx: int, t: int, b: int, h: float, hv: int, row_off: int, row_n: int, row_s: int) -> Color:
	_ren_crys_role = 0
	if b == Biome.LAVA:
		return _lava_color_at(_temp[idx], hv)
	if b == Biome.SCORCHED:
		var sc: bool = (hv & 3) == 0 and (sin(float(x) * 0.45 + float(y) * 0.35) + cos(float(x - y) * 0.52) > 1.38)
		return _scorched_color_at(t, _temp[idx], hv, sc)
	var mw: int = map_w
	var gx: float = (_height[row_off + mini(mw - 1, x + 1)] - _height[row_off + maxi(0, x - 1)]) * 0.5
	var gy: float = (_height[row_s + x] - _height[row_n + x]) * 0.5
	var nw_lit: float = (gx + gy) * 0.7071
	if t == Tier.HILLS:
		if b == Biome.CRYSTAL:
			_ren_crys_role = _crystal_cluster_role(x, y)
			if _ren_crys_role == 3:
				return COL_CRYS_TIP
			if _ren_crys_role == 2:
				return COL_CRYS_VEIN
		var hc: Color = COL_HILLS_SPEC if nw_lit > 0.0075 else (COL_HILLS_CRACK if nw_lit < -0.0065 else COL_HILLS)
		if b == Biome.LUSH:
			return hc.lerp(COL_LUSH_LOW, 0.18)
		if b == Biome.RUST:
			return hc.lerp(COL_RUST_DARK, 0.22)
		if b == Biome.CRYSTAL:
			return hc.lerp(COL_CRYS_SLATE, 0.35)
		if b >= Biome.XENO_JUNGLE:
			return hc.lerp(_render_tile_new_biome_col(x, y, Tier.SOIL_LOW, b, h, hv, nw_lit), 0.28)
		return hc
	if t == Tier.MOUNTAINS:
		var m_shade: float = nw_lit + sin(h * 72.0 + float(x - y) * 0.10) * 0.0022
		if m_shade > 0.0085:
			return COL_MTN_RIDGE
		if m_shade > 0.0020:
			return COL_MTN.lerp(COL_MTN_RIDGE, 0.48)
		if m_shade < -0.0110:
			return COL_MTN_DEEP
		return COL_MTN_CRAG if m_shade < -0.0030 else COL_MTN
	if nw_lit < -0.0125 and h < 0.830:
		return COL_MTN_CRAG
	if h < 0.770 and nw_lit < 0.0:
		return COL_SNOW_EDGE
	return COL_SNOW if (nw_lit > 0.0035 or h >= 0.825) else COL_SNOW_SHADE


func _render_row_commit(y: int, rx0: int, rx1: int) -> int:
	var mw: int = map_w
	var mh: int = map_h
	var row_off: int = y * mw
	var row_n: int = maxi(0, y - 1) * mw
	var row_n2: int = maxi(0, y - 2) * mw
	var row_s: int = mini(mh - 1, y + 1) * mw
	var upload_flags: int = 0
	for x in range(rx0, rx1):
		var idx: int = row_off + x
		var t: int = _tiers[idx]
		var b: int = _biomes[idx]
		var hv: int = ((x * 73856093) ^ (y * 19349663)) & 63
		var fire_v: float = _fire[idx]
		var ash_v: int = _ash[idx]
		var temp_v: float = _temp[idx]
		var col: Color = _ren_row_col[x]
		var xp: int = maxi(0, x - 1)
		var xn: int = mini(mw - 1, x + 1)
		var tn: int = _tiers[row_n + x]
		var tw: int = _tiers[row_off + xp]

		if fire_v > 0.05 and t >= Tier.SAND and b != Biome.LAVA:
			var fn: float = clampf(fire_v, 0.0, 1.0)
			col = COL_LAVA_CORE if (fn > 0.65 and (hv & 3) == 0) else (COL_LAVA_MID if (fn > 0.30 and (hv & 1) == 0) else COL_FIRE_CHAR.lerp(COL_LAVA_CRUST, fn * 0.75))
		elif ash_v > 0 and t >= Tier.SAND and b != Biome.LAVA:
			col = col.lerp(COL_ASH_TINT, (float(ash_v) / 255.0) * 0.70)
		elif (b == Biome.LUSH or b == Biome.RUST or b == Biome.XENO_JUNGLE) and t >= Tier.SAND:
			if temp_v > 65.0 or _biomes[row_off + xp] == Biome.LAVA or _biomes[row_off + xn] == Biome.LAVA or _biomes[row_n + x] == Biome.LAVA or _biomes[row_s + x] == Biome.LAVA:
				col = col.lerp(COL_SCORCH_HIGH, 0.62)

		var bev: int = 0
		if t <= Tier.SHALLOW:
			if not (t == Tier.SHALLOW and _frost[idx] >= 128):
				if y > 0 and tn >= Tier.SAND:
					bev = 1
					col = (col.lerp(COL_EDGE_OCEAN, 0.78) if _river_mask[idx] > 0 else COL_EDGE_OCEAN) if t == Tier.SHALLOW else col.lerp(COL_EDGE_OCEAN_DEEP, 0.85)
				elif x > 0 and tw >= Tier.SAND and t == Tier.SHALLOW:
					col = col.lerp(COL_EDGE_OCEAN, 0.42)
		elif b != Biome.LAVA and fire_v <= 0.05:
			var sh_n: bool = y > 0 and tn > t
			var sh_w: bool = x > 0 and tw > t
			if sh_n:
				col = col.lerp(COL_EDGE_MTN, 0.76 if (sh_w and tw >= Tier.MOUNTAINS) else 0.66) if tn >= Tier.MOUNTAINS else (col.lerp(COL_EDGE_HILLS, 0.66 if sh_w else 0.58) if tn == Tier.HILLS else col * (0.72 if sh_w else 0.78))
			elif sh_w:
				col = col * (0.76 if tw >= Tier.HILLS else 0.82)
			elif (y > 1 and _tiers[row_n2 + x] >= t + 2) or (x > 1 and _tiers[row_off + (x - 2)] >= t + 2):
				col = col * 0.88
			elif (y > 0 and t > tn) or (x > 0 and t > tw):
				var la: float = 0.06 if t == Tier.SUMMIT else (0.14 if (y > 0 and t > tn and x > 0 and t > tw) else 0.11)
				col = Color(minf(0.95, col.r + (1.0 - col.r) * la), minf(0.95, col.g + (1.0 - col.g) * la), minf(0.95, col.b + (1.0 - col.b) * la), 1.0)
			if not sh_n and t >= Tier.HILLS and y + 1 < mh and t > _tiers[row_s + x]:
				var rl: float = 0.08 if t == Tier.SUMMIT else (0.22 if t == Tier.MOUNTAINS else 0.17)
				col = Color(minf(0.95, col.r + (1.0 - col.r) * rl), minf(0.95, col.g + (1.0 - col.g) * rl), minf(0.95, col.b + (1.0 - col.b) * rl), 1.0)

		var pg: int = _plasma_glow[idx]
		if pg > 0:
			col = col.lerp(COL_CRYS_TIP, (float(pg) / 255.0) * 0.42)
		var w: int = _wall_mask[idx]
		if w > 0 or _goo_map[idx] > 0 or _conway_map[idx] > 0 or (_bomb_count > 0 and (_bomb_map[idx] & 3) > 0):
			col = _render_hazard_overlay(col, x, y, idx, hv, w, row_n, row_off, xp)

		var p: int = idx * 4
		var r_b: int = clampi(col.r8, 0, 243 if pg > 0 else 255)
		var g_b: int = clampi(col.g8, 0, 243 if pg > 0 else 255)
		var b_b: int = clampi(col.b8, 0, 243 if pg > 0 else 255)
		if _rgba_buf[p] != r_b or _rgba_buf[p + 1] != g_b or _rgba_buf[p + 2] != b_b or _rgba_buf[p + 3] != 255:
			_rgba_buf[p] = r_b
			_rgba_buf[p + 1] = g_b
			_rgba_buf[p + 2] = b_b
			_rgba_buf[p + 3] = 255
			upload_flags |= 1

		var m_water: int = 0
		var m_foam: int = 0
		if t == Tier.DEEP_OCEAN:
			m_water = 85
		elif t == Tier.CLOSE_OCEAN:
			m_water = 170
			if tw >= Tier.SAND or _tiers[row_off + xn] >= Tier.SAND or tn >= Tier.SAND or _tiers[row_s + x] >= Tier.SAND:
				m_foam = 115
		elif t == Tier.SHALLOW:
			var mf: int = _frost[idx]
			if mf < 128:
				m_water = 255
				m_foam = _shallow_foam_at(x, y, idx, row_off, row_n, row_s, xp, xn, bev, mf)

		var m_lava: int = 0
		var m_cryst: int = 0
		if b == Biome.LAVA and t >= Tier.SAND:
			m_lava = clampi(int(clampf((temp_v - 340.0) / 560.0, 0.35, 1.0) * 255.0), 0, 255)
		else:
			if fire_v > 0.05 and t >= Tier.SAND:
				m_foam = clampi(int(clampf(fire_v, 0.15, 1.0) * 245.0), 40, 250)
			if b == Biome.SCORCHED and t >= Tier.SAND and temp_v > 185.0 and (hv & 3) == 0 and (sin(float(x) * 0.45 + float(y) * 0.35) + cos(float(x - y) * 0.52) > 1.38):
				m_lava = clampi(int(clampf((temp_v - 185.0) / 360.0, 0.14, 0.58) * 255.0), 0, 255)
			elif (b == Biome.CRYSTAL or b == Biome.BIOLUM_OASIS or b == Biome.CREEP_CYBER) and t >= Tier.SAND and t <= Tier.HILLS:
				var cr: int = _ren_row_crys[x]
				m_cryst = 235 if cr == 3 else (92 if cr == 2 else 0)
		if w == 2:
			m_cryst = maxi(m_cryst, 210)
		if _conway_map[idx] > 0:
			m_cryst = maxi(m_cryst, 110)
		m_cryst = maxi(m_cryst, pg)

		if _mask_buf[p] != m_water or _mask_buf[p + 1] != m_foam or _mask_buf[p + 2] != m_lava or _mask_buf[p + 3] != m_cryst:
			_mask_buf[p] = m_water
			_mask_buf[p + 1] = m_foam
			_mask_buf[p + 2] = m_lava
			_mask_buf[p + 3] = m_cryst
			upload_flags |= 2
	return upload_flags


func _render_hazard_overlay(col: Color, x: int, y: int, idx: int, hv: int, w: int, row_n: int, row_off: int, xp: int) -> Color:
	if w == 1:
		col = COL_WALL_ROCK_HI if ((y > 0 and _wall_mask[row_n + x] != 1) or (x > 0 and _wall_mask[row_off + xp] != 1) or ((x + y * 2) & 3) == 0) else COL_WALL_ROCK
	elif w == 2:
		col = COL_WALL_ENERGY_CORE if ((x & 1) == 0 and (y & 1) == 0) else COL_WALL_ENERGY
	if _goo_map[idx] > 0:
		col = COL_GOO_B if ((hv + (x ^ y)) & 3) == 0 else COL_GOO_A
	if _conway_map[idx] > 0:
		col = COL_CONWAY_CELL
	var bm: int = _bomb_map[idx] & 3
	if bm > 0:
		col = COL_BOMB_FUSE if (hv & 1) == 0 else (COL_BOMB_BODY if bm == 1 else COL_MINE_BODY)
	return col


func _shallow_foam_at(x: int, y: int, idx: int, row_off: int, row_n: int, row_s: int, xp: int, xn: int, bev: int, mf: int) -> int:
	var foam: int = 0
	if _river_mask[idx] > 0:
		foam = 86
	elif bev != 0:
		foam = 152
	elif _tiers[row_off + xp] >= Tier.SAND or _tiers[row_off + xn] >= Tier.SAND or _tiers[row_n + x] >= Tier.SAND or _tiers[row_s + x] >= Tier.SAND:
		foam = 242
	elif _tiers[row_n + xp] >= Tier.SAND or _tiers[row_n + xn] >= Tier.SAND or _tiers[row_s + xp] >= Tier.SAND or _tiers[row_s + xn] >= Tier.SAND:
		foam = 188
	elif _has_land_within_two(x, y):
		foam = 128
	return foam >> 1 if mf > 0 else foam


func _render_tile_new_biome_col(x: int, y: int, t: int, b: int, h: float, hv: int, nw_lit: float) -> Color:
	var low_soil: bool = t == Tier.SOIL_LOW
	if b == Biome.XENO_JUNGLE:
		if hv == 11 or hv == 47:
			return COL_XENO_SPORE
		if sin(float(x) * 0.28 + float(y) * 0.19) > 0.58:
			return COL_XENO_VINE
		return COL_XENO_LOW if low_soil else COL_XENO_HIGH
	if b == Biome.CRYO_TUNDRA:
		if (hv & 15) == 0:
			return COL_CRYO_CRACK
		if hv < 10:
			return COL_CRYO_FROST
		return COL_CRYO_LOW if low_soil else COL_CRYO_HIGH
	if b == Biome.ACID_WASTE:
		if sin(float(x) * 0.32) * cos(float(y) * 0.32) > 0.42:
			return COL_ACID_POOL
		if hv > 54:
			return COL_ACID_SLAG
		return COL_ACID_LOW if low_soil else COL_ACID_HIGH
	if b == Biome.SILICA_DUNES:
		var swave: float = sin(float(x) * 0.16 + float(y) * 0.28 + h * 18.0) + nw_lit * 14.0
		if swave > 0.65:
			return COL_SILICA_CREST
		if swave < -0.72:
			return COL_SILICA_TROUGH
		return COL_SILICA_LOW if low_soil else COL_SILICA_HIGH
	if b == Biome.BIOLUM_OASIS:
		if sin(float(x) * 0.38) * cos(float(y) * 0.38) > 0.52:
			_ren_crys_role = 2
			return COL_BIOLUM_BLOOM
		if ((x * 7 + y * 13) & 15) == 0:
			_ren_crys_role = 2
			return COL_BIOLUM_GLOW
		return COL_BIOLUM_LOW if low_soil else COL_BIOLUM_HIGH
	if b == Biome.CREEP_MYCELIUM:
		if hv == 17 or hv == 51:
			return COL_MYC_SPORE
		if sin(float(x) * 0.42 - float(y) * 0.27) + cos(float(y) * 0.35) > 1.05:
			return COL_MYC_VEIN
		return COL_MYC_LOW if low_soil else COL_MYC_HIGH
	if b == Biome.CREEP_CYBER:
		if (x & 7) == 0 and (y & 7) == 0:
			_ren_crys_role = 3
			return COL_CYBER_NODE
		if ((x & 3) == 0 or (y & 3) == 0) and ((((x >> 2) ^ (y >> 2)) & 1) == 0):
			return COL_CYBER_GRID
		return COL_CYBER_LOW if low_soil else COL_CYBER_HIGH
	return COL_RUST_LOW


func _scorched_color_at(t: int, temp_v: float, hv: int, scorch_crack: bool) -> Color:
	if scorch_crack:
		return COL_SCORCH_WARM_CRACK if temp_v > 95.0 else COL_SCORCH_COLD_CRACK
	if hv > 54:
		return COL_SCORCH_ASH
	return COL_SCORCH_LOW if t == Tier.SOIL_LOW else COL_SCORCH_HIGH


func _lava_color_at(temp_v: float, hv: int) -> Color:
	if temp_v > 780.0 and hv < 22:
		return COL_LAVA_CORE
	if hv > 48:
		return COL_LAVA_CRUST
	return COL_LAVA_MID


func _crystal_cluster_role(x: int, y: int) -> int:
	# Clustered 2-4px crystal spire + slate root inside 8x8 jittered macro cells (zero 1px confetti)
	var gx: int = x >> 3
	var gy: int = y >> 3
	var cell_h: int = ((gx * 374761393) ^ (gy * 668265263)) & 31
	if cell_h > 17:
		return 0
	var ox: int = 2 + (cell_h & 3)
	var oy: int = 3 + ((cell_h >> 2) & 3)
	var lx: int = x & 7
	var ly: int = y & 7
	var lean: int = 1 if ((cell_h >> 4) & 1) == 0 else -1

	if lx == ox and ly == oy - 2:
		return 3
	if lx == ox + lean and ly == oy - 1:
		return 3 if (cell_h & 1) == 0 else 2
	if lx == ox and (ly == oy - 1 or ly == oy):
		return 2
	if lx == ox - lean and ly == oy:
		return 2
	if lx == ox and ly == oy + 1:
		return 1
	return 0


func _has_land_within_two(x: int, y: int) -> bool:
	for dy in range(-2, 3):
		var py: int = y + dy
		if py < 0 or py >= map_h:
			continue
		var row_off: int = py * map_w
		for dx in range(-2, 3):
			if dx == 0 and dy == 0:
				continue
			if dx * dx + dy * dy > 4:
				continue
			var px: int = x + dx
			if px >= 0 and px < map_w and _tiers[row_off + px] >= Tier.SAND:
				return true
	return false


func _recompute_avg_temp_full() -> void:
	var total: int = _temp.size()
	if total == 0:
		_avg_temp_cached = float(TUNING_KNOBS["TEMP_AMBIENT_C"])
		_temp_total_sum = 0.0
		_inv_total_tiles = 0.0
		return
	var acc: float = 0.0
	for i in range(total):
		acc += _temp[i]
	_inv_total_tiles = 1.0 / float(total)
	_temp_total_sum = acc
	_avg_temp_cached = acc * _inv_total_tiles
	_temp_scan_row = 0
	_temp_scan_accum = 0.0


func _step_rolling_avg_temp() -> void:
	var rows_per_tick: int = int(TUNING_KNOBS["TEMP_AVG_ROWS_PER_TICK"])
	var end_row: int = mini(map_h, _temp_scan_row + rows_per_tick)
	var amb_c: float = float(TUNING_KNOBS["TEMP_AMBIENT_C"])
	var ocean_damp: float = float(TUNING_KNOBS["OCEAN_THERMAL_DAMP_K"]) * maxf(0.0, (_avg_temp_cached + _cosmic_temp_offset) - amb_c)
	var do_damp: bool = ocean_damp > 0.35
	var do_frost_scan: bool = (_cosmic_temp_offset <= -4.0 or _frost_tiles > 0)
	var acc: float = _temp_scan_accum
	if not do_damp and not do_frost_scan:
		var i_start: int = _temp_scan_row * map_w
		var i_end: int = end_row * map_w
		for i in range(i_start, i_end):
			acc += _temp[i]
	else:
		var freeze_c: float = float(TUNING_KNOBS["ICE_FREEZE_TEMP_C"])
		var melt_c: float = float(TUNING_KNOBS["ICE_MELT_TEMP_C"])
		for py in range(_temp_scan_row, end_row):
			var row_off: int = py * map_w
			var target_ocean: float = amb_c + _row_lat_shift(py) * 0.85 - 0.30 - ocean_damp
			for px in range(map_w):
				var idx: int = row_off + px
				var t_v: float = _temp[idx]
				var tier_v: int = _tiers[idx]
				var fr_v: int = _frost[idx]
				if do_damp and tier_v <= Tier.SHALLOW and fr_v == 0 and t_v > target_ocean + 0.5:
					t_v = lerpf(t_v, target_ocean, 0.08)
					_temp[idx] = t_v
				acc += t_v
				if do_frost_scan and px > 0 and px < map_w - 1 and py > 0 and py < map_h - 1:
					var t_eff: float = t_v + _cosmic_temp_offset
					if (tier_v == Tier.SHALLOW and t_eff <= freeze_c and fr_v < 255) or (fr_v > 0 and t_eff >= melt_c):
						_activate_tile_row(px, py)
	_temp_scan_accum = acc
	_temp_scan_row = end_row
	if _temp_scan_row >= map_h:
		_temp_total_sum = acc
		_avg_temp_cached = acc * _inv_total_tiles
		_temp_scan_row = 0
		_temp_scan_accum = 0.0


func is_ice_bridge(px: int, py: int) -> bool:
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return false
	var idx: int = py * map_w + px
	return _tiers[idx] == Tier.SHALLOW and _frost[idx] >= 128


func is_walkable(px: int, py: int) -> bool:
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return false
	var idx: int = py * map_w + px
	if _wall_mask[idx] > 0:
		return false
	var t: int = _tiers[idx]
	if t == Tier.SHALLOW and _frost[idx] >= 128:
		return true
	return t >= Tier.SAND and t <= Tier.MOUNTAINS


func is_water(px: int, py: int) -> bool:
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return false
	var idx: int = py * map_w + px
	var t: int = _tiers[idx]
	if t == Tier.SHALLOW and _frost[idx] >= 128:
		return false
	return t <= Tier.SHALLOW


func get_tier(px: int, py: int) -> int:
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return Tier.DEEP_OCEAN
	return _tiers[py * map_w + px]


func get_biome(px: int, py: int) -> int:
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return Biome.RUST
	return _biomes[py * map_w + px]


func get_temp(px: int, py: int) -> float:
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return float(TUNING_KNOBS["TEMP_AMBIENT_C"]) + _cosmic_temp_offset
	return _temp[py * map_w + px] + _cosmic_temp_offset


func get_rad(px: int, py: int) -> float:
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return 0.0
	return _rad[py * map_w + px]


func get_fire(px: int, py: int) -> float:
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return 0.0
	return _fire[py * map_w + px]


func get_ash(px: int, py: int) -> float:
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return 0.0
	return float(_ash[py * map_w + px]) / 255.0


func get_moisture(px: int, py: int) -> float:
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return 0.0
	return _moisture[py * map_w + px]


func get_tile_env(px: int, py: int) -> Vector4:
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return Vector4(float(TUNING_KNOBS["TEMP_AMBIENT_C"]) + _cosmic_temp_offset, 0.0, 0.0, 0.0)
	var idx: int = py * map_w + px
	return Vector4(_temp[idx] + _cosmic_temp_offset, _rad[idx], _fire[idx], float(_ash[idx]) / 255.0)


func get_tile_flags(px: int, py: int) -> int:
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return 0
	var idx: int = py * map_w + px
	var flags: int = (_tiers[idx] & 0xF) | ((_biomes[idx] & 0xF) << 4)
	if _fire[idx] > 0.05:
		flags |= 256
	if _ash[idx] > 0:
		flags |= 512
	if _river_mask[idx] > 0:
		flags |= 1024
	if _frost[idx] >= 128:
		flags |= 2048
	return flags


func get_fire_stats() -> Dictionary:
	return {
		"fire_events": _fire_events_total,
		"active_fire_tiles": _active_fire_tiles,
		"ash_tiles": _ash_tiles,
		"frost_tiles": _frost_tiles,
		"vapor_pool": _global_vapor_pool,
		"active_chunks": _active_chunks.size(),
	}


func get_height_grad(px: int, py: int) -> Vector2:
	var cx: int = clampi(px, 0, map_w - 1)
	var cy: int = clampi(py, 0, map_h - 1)
	var x0: int = clampi(cx - 1, 0, map_w - 1)
	var x1: int = clampi(cx + 1, 0, map_w - 1)
	var y0: int = clampi(cy - 1, 0, map_h - 1)
	var y1: int = clampi(cy + 1, 0, map_h - 1)
	var gx: float = (_height[cy * map_w + x1] - _height[cy * map_w + x0]) * 0.5
	var gy: float = (_height[y1 * map_w + cx] - _height[y0 * map_w + cx]) * 0.5
	return Vector2(gx, gy)


func get_avg_temp() -> float:
	return _avg_temp_cached + _cosmic_temp_offset


func get_tile_info(world_pos: Vector2) -> Dictionary:
	var px: int = int(floor(world_pos.x))
	var py: int = int(floor(world_pos.y))
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return {
			"in_bounds": false,
			"tier": Tier.DEEP_OCEAN,
			"biome": Biome.RUST,
			"tier_name": "Орбита",
			"biome_name": "Космос",
			"temp": -180.0,
			"rad": 0.0,
			"fire": 0.0,
			"ash": 0.0,
			"moisture": 0.0,
			"wall": 0,
		}
	var idx: int = py * map_w + px
	var t: int = _tiers[idx]
	var b: int = clampi(_biomes[idx], 0, BIOME_NAMES.size() - 1)
	var b_name: String = BIOME_NAMES[b]
	if _wall_mask[idx] == 1:
		b_name = "Скальная стена"
	elif _wall_mask[idx] == 2:
		b_name = "Энергостена"
	elif _goo_map[idx] > 0:
		b_name = "Серая слизь"
	elif _conway_map[idx] > 0:
		b_name = "Клетка Конвея"
	elif (_bomb_map[idx] & 3) > 0:
		b_name = "Бомба" if (_bomb_map[idx] & 3) == 1 else "Мина"
	elif t == Tier.SHALLOW and _frost[idx] >= 128:
		b_name = "Ледяной мост"
	elif t <= Tier.SHALLOW:
		b_name = "Река" if _river_mask[idx] > 0 else "Океан"
	elif _fire[idx] > 0.05:
		b_name = "Пожар"
	elif _ash[idx] > 40 and b == Biome.SCORCHED:
		b_name = "Пепел"
	return {
		"in_bounds": true,
		"tier": t,
		"biome": b,
		"tier_name": TIER_NAMES[clampi(t, 0, TIER_NAMES.size() - 1)],
		"biome_name": b_name,
		"temp": _temp[idx] + _cosmic_temp_offset,
		"rad": _rad[idx],
		"fire": _fire[idx],
		"ash": float(_ash[idx]) / 255.0,
		"frost": float(_frost[idx]) / 255.0,
		"moisture": _moisture[idx],
		"wall": _wall_mask[idx],
	}


func get_save_state() -> Dictionary:
	return {
		"version": RAW_STATE_VERSION,
		"raw_blob": export_raw_state(),
		"template_id": _template_id,
		"world_laws": _world_laws.duplicate(),
		"sim_pace_mult": _sim_pace_mult,
	}


func load_save_state(state: Dictionary) -> bool:
	if not (state is Dictionary) or not state.has("raw_blob"):
		return false
	var blob: PackedByteArray = state["raw_blob"]
	if not import_raw_state(blob):
		return false
	if state.has("world_laws") and state["world_laws"] is Dictionary:
		set_world_laws(state["world_laws"])
	if state.has("sim_pace_mult"):
		_sim_pace_mult = clampf(float(state["sim_pace_mult"]), 0.0, 20.0)
	return true


func export_raw_state() -> PackedByteArray:
	_ensure_initialized()
	var total: int = map_w * map_h
	var cloud_n: int = _cloud_pos.size()
	var drop_bytes: PackedByteArray = _drops.export_bytes() if _drops != null else PackedByteArray()
	var creep_n: int = mini(_creep_nodes.size(), 65535)
	var geyser_n: int = mini(_geysers.size(), 65535)
	var tor_n: int = mini(_tornadoes.size(), 65535)
	var base_meta_bytes: int = RAW_STATE_META_FIXED + cloud_n * RAW_STATE_CLOUD_REC_BYTES
	var ext_meta_bytes: int = 14 + creep_n * 5 + geyser_n * 13 + tor_n * 24 + drop_bytes.size()
	var raw_len: int = total * 15 + base_meta_bytes + ext_meta_bytes

	var raw := PackedByteArray()
	raw.append_array(_tiers)
	raw.append_array(_biomes)
	raw.append_array(_river_mask)
	raw.append_array(_vent_mask)
	raw.append_array(_frost)
	raw.resize(raw_len)

	var off_h: int = total * 5
	var off_t: int = total * 7
	var off_rad: int = total * 9
	var off_m: int = total * 10
	for i in range(total):
		raw.encode_u16(off_h + (i << 1), clampi(int(round(_height[i] * 65535.0)), 0, 65535))
		raw.encode_s16(off_t + (i << 1), clampi(int(round(_temp[i] * 16.0)), -32768, 32767))
		raw[off_rad + i] = clampi(int(round(_rad[i] * 255.0)), 0, 255)
		raw[off_m + i] = clampi(int(round(_moisture[i] * 255.0)), 0, 255)

	var moff: int = total * 11
	raw.encode_s32(moff, current_seed)
	raw.encode_s32(moff + 4, _cosmic_age)
	raw.encode_float(moff + 8, _cosmic_age_elapsed)
	raw.encode_float(moff + 12, _env_time)
	raw.encode_float(moff + 16, _global_vapor_pool)
	raw.encode_float(moff + 20, _co2_load)
	raw.encode_u32(moff + 24, cloud_n)
	for ci in range(cloud_n):
		var co: int = moff + RAW_STATE_META_FIXED + ci * RAW_STATE_CLOUD_REC_BYTES
		raw.encode_float(co, _cloud_pos[ci].x)
		raw.encode_float(co + 4, _cloud_pos[ci].y)
		raw.encode_float(co + 8, _cloud_vapor[ci])
		raw[co + 12] = _cloud_raining[ci]

	_encode_v2_extension(raw, moff + base_meta_bytes, total, drop_bytes)
	var comp: PackedByteArray = raw.compress(FileAccess.COMPRESSION_ZSTD)
	var out := PackedByteArray()
	out.resize(RAW_STATE_HEADER_BYTES)
	out.encode_u32(0, RAW_STATE_MAGIC)
	out.encode_u16(4, RAW_STATE_VERSION)
	out.encode_u16(6, map_w)
	out.encode_u16(8, map_h)
	out.encode_u32(10, raw_len)
	out.encode_u16(14, 0)
	out.append_array(comp)
	return out


func _encode_v2_extension(raw: PackedByteArray, ext_off: int, total: int, drop_bytes: PackedByteArray) -> void:
	for i in range(total):
		raw[ext_off + i] = _wall_mask[i]
		raw[ext_off + total + i] = _bomb_map[i]
		raw[ext_off + total * 2 + i] = _goo_map[i]
		raw[ext_off + total * 3 + i] = _conway_map[i]

	var cur: int = ext_off + total * 4
	raw.encode_s32(cur, _template_id)
	cur += 4
	var creep_n: int = mini(_creep_nodes.size(), 65535)
	raw.encode_u16(cur, creep_n)
	cur += 2
	for i in range(creep_n):
		var np: Vector2i = _creep_nodes[i]["pos"]
		raw.encode_u16(cur, np.x)
		raw.encode_u16(cur + 2, np.y)
		raw[cur + 4] = clampi(int(_creep_nodes[i]["biome"]), 0, 255)
		cur += 5

	var geyser_n: int = mini(_geysers.size(), 65535)
	raw.encode_u16(cur, geyser_n)
	cur += 2
	for i in range(geyser_n):
		var gp: Vector2i = _geysers[i]["pos"]
		raw.encode_u16(cur, gp.x)
		raw.encode_u16(cur + 2, gp.y)
		raw[cur + 4] = clampi(int(_geysers[i]["kind"]), 0, 255)
		raw.encode_float(cur + 5, float(_geysers[i]["timer"]))
		raw.encode_float(cur + 9, float(_geysers[i]["life"]))
		cur += 13

	var tor_n: int = mini(_tornadoes.size(), 65535)
	raw.encode_u16(cur, tor_n)
	cur += 2
	for i in range(tor_n):
		var tp: Vector2 = _tornadoes[i]["pos"]
		var tv: Vector2 = _tornadoes[i]["vel"]
		raw.encode_float(cur, tp.x)
		raw.encode_float(cur + 4, tp.y)
		raw.encode_float(cur + 8, tv.x)
		raw.encode_float(cur + 12, tv.y)
		raw.encode_float(cur + 16, float(_tornadoes[i]["life"]))
		raw.encode_float(cur + 20, float(_tornadoes[i]["phase"]))
		cur += 24

	raw.encode_u32(cur, drop_bytes.size())
	cur += 4
	for i in range(drop_bytes.size()):
		raw[cur + i] = drop_bytes[i]


func import_raw_state(blob: PackedByteArray) -> bool:
	_ensure_initialized()
	if blob.size() <= RAW_STATE_HEADER_BYTES:
		return false
	if blob.decode_u32(0) != RAW_STATE_MAGIC:
		return false
	var ver: int = blob.decode_u16(4)
	if ver != RAW_STATE_LEGACY_VERSION and ver != RAW_STATE_VERSION:
		return false
	if blob.decode_u16(6) != map_w or blob.decode_u16(8) != map_h:
		return false
	var total: int = map_w * map_h
	var raw_len: int = blob.decode_u32(10)
	var min_len: int = (total * 11 if ver == RAW_STATE_LEGACY_VERSION else total * 15) + RAW_STATE_META_FIXED
	if raw_len < min_len or raw_len > total * 16 + 32768:
		return false
	var raw: PackedByteArray = blob.slice(RAW_STATE_HEADER_BYTES).decompress(raw_len, FileAccess.COMPRESSION_ZSTD)
	if raw.size() != raw_len:
		return false

	_tiers = raw.slice(0, total)
	_biomes = raw.slice(total, total * 2)
	_river_mask = raw.slice(total * 2, total * 3)
	_vent_mask = raw.slice(total * 3, total * 4)
	_frost = raw.slice(total * 4, total * 5)
	var off_h: int = total * 5
	var off_t: int = total * 7
	var off_rad: int = total * 9
	var off_m: int = total * 10
	for i in range(total):
		_height[i] = float(raw.decode_u16(off_h + (i << 1))) / 65535.0
		_temp[i] = float(raw.decode_s16(off_t + (i << 1))) / 16.0
		_rad[i] = float(raw[off_rad + i]) / 255.0
		_moisture[i] = float(raw[off_m + i]) / 255.0

	_apply_imported_meta(raw, total * 11, ver, total)
	return true


func _apply_imported_meta(raw: PackedByteArray, moff: int, ver: int, total: int) -> void:
	if _cloud_pos.is_empty():
		_init_clouds()
	_fire.fill(0.0)
	_ash.fill(0)
	_plasma_glow.fill(0)
	_active_fire_tiles = 0
	_ash_tiles = 0
	_wq_head = 0
	_wq_tail = 0
	_wq_count = 0
	_work_stamp.fill(0)
	_wq_stamp_id = 1
	_chunk_dirty.fill(0)
	_chunk_struct_dirty.fill(0)
	_dirty_chunks.clear()
	_structural_dirty_chunks.clear()

	var ext_off: int = moff + RAW_STATE_META_FIXED
	if moff + RAW_STATE_META_FIXED <= raw.size():
		current_seed = raw.decode_s32(moff)
		_cosmic_age = clampi(raw.decode_s32(moff + 4), CosmicAge.GOLD, CosmicAge.ION_STORM)
		_cosmic_age_elapsed = maxf(0.0, raw.decode_float(moff + 8))
		_env_time = maxf(0.0, raw.decode_float(moff + 12))
		_global_vapor_pool = maxf(0.0, raw.decode_float(moff + 16))
		_co2_load = maxf(0.0, raw.decode_float(moff + 20))
		var raw_cloud_n: int = raw.decode_u32(moff + 24)
		ext_off = moff + RAW_STATE_META_FIXED + raw_cloud_n * RAW_STATE_CLOUD_REC_BYTES
		var cloud_n: int = mini(_cloud_pos.size(), raw_cloud_n)
		for ci in range(cloud_n):
			var co: int = moff + RAW_STATE_META_FIXED + ci * RAW_STATE_CLOUD_REC_BYTES
			if co + RAW_STATE_CLOUD_REC_BYTES > raw.size():
				break
			_cloud_pos[ci] = Vector2(raw.decode_float(co), raw.decode_float(co + 4))
			_cloud_vapor[ci] = maxf(0.0, raw.decode_float(co + 8))
			_cloud_raining[ci] = raw[co + 12]

	_reset_extended_state(current_seed)
	if ver == RAW_STATE_VERSION and ext_off + total * 4 + 14 <= raw.size():
		_decode_v2_extension(raw, ext_off, total)
	else:
		_template_id = MapTemplate.CONTINENTS

	_rebuild_vent_tiles_cache()
	_rebuild_ca_active_lists()
	_recompute_bio_active_chunks()
	var cfg: Dictionary = COSMIC_AGE_DEFS[clampi(_cosmic_age, 0, COSMIC_AGE_DEFS.size() - 1)]
	_cosmic_temp_offset = float(cfg["temp_offset"])
	_cosmic_fire_mul = float(cfg["fire_mul"])
	_sync_cosmic_age_shader()
	_sync_cloud_multimesh()
	_sync_drops_to_fx()
	_recompute_all_chunk_flags()
	_recompute_avg_temp_full()
	_render_rect(0, 0, map_w, map_h, true)


func _decode_v2_extension(raw: PackedByteArray, ext_off: int, total: int) -> void:
	_wall_mask = raw.slice(ext_off, ext_off + total)
	_bomb_map = raw.slice(ext_off + total, ext_off + total * 2)
	_goo_map = raw.slice(ext_off + total * 2, ext_off + total * 3)
	_conway_map = raw.slice(ext_off + total * 3, ext_off + total * 4)

	var cur: int = ext_off + total * 4
	if cur + 4 > raw.size():
		return
	_template_id = clampi(raw.decode_s32(cur), 0, TEMPLATE_NAMES.size() - 1)
	cur += 4
	if cur + 2 <= raw.size():
		var creep_n: int = raw.decode_u16(cur)
		cur += 2
		for _i in range(creep_n):
			if cur + 5 > raw.size():
				break
			_creep_nodes.append({"pos": Vector2i(raw.decode_u16(cur), raw.decode_u16(cur + 2)), "biome": raw[cur + 4]})
			cur += 5
	if cur + 2 <= raw.size():
		var geyser_n: int = raw.decode_u16(cur)
		cur += 2
		for _i in range(geyser_n):
			if cur + 13 > raw.size():
				break
			_geysers.append({
				"pos": Vector2i(raw.decode_u16(cur), raw.decode_u16(cur + 2)),
				"kind": raw[cur + 4],
				"timer": raw.decode_float(cur + 5),
				"life": raw.decode_float(cur + 9),
			})
			cur += 13
	if cur + 2 <= raw.size():
		var tor_n: int = raw.decode_u16(cur)
		cur += 2
		for _i in range(tor_n):
			if cur + 24 > raw.size():
				break
			_tornadoes.append({
				"pos": Vector2(raw.decode_float(cur), raw.decode_float(cur + 4)),
				"vel": Vector2(raw.decode_float(cur + 8), raw.decode_float(cur + 12)),
				"life": raw.decode_float(cur + 16),
				"phase": raw.decode_float(cur + 20),
				"fx_cd": 0.0,
			})
			cur += 24
	if cur + 4 <= raw.size() and _drops != null:
		var dlen: int = raw.decode_u32(cur)
		cur += 4
		if dlen > 0 and cur + dlen <= raw.size():
			_drops.import_bytes(raw.slice(cur, cur + dlen))


func _rebuild_ca_active_lists() -> void:
	_goo_active.clear()
	_conway_active.clear()
	_detonate_queue.clear()
	_bomb_count = 0
	for i in range(_wall_mask.size()):
		if _goo_map[i] > 0 and _goo_active.size() < MAX_GOO_ACTIVE:
			_goo_active.append(i)
		if _conway_map[i] > 0 and _conway_active.size() < MAX_CONWAY_CELLS:
			_conway_active.append(i)
		if (_bomb_map[i] & 3) > 0:
			_bomb_count += 1
			if (_bomb_map[i] & 4) != 0:
				_detonate_queue.append(i)
