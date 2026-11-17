extends Node2D
class_name UnitPhysics

const UNIT_SPRITE_SHADER := preload("res://shaders/unit_sprite.gdshader")

const TUNING_KNOBS := {
	"POPULATION_COUNT": 110,
	"FLORA_COUNT": 520,
	"MAX_FLORA": 900,
	"CELL_SIZE": 16,
	"COLONIST_SPEED": 16.0,
	"UNIT_QUAD_PX": 8.0,
	"MAX_NEIGHBORS_CHECKED": 10,
	"SEPARATION_RADIUS": 4.4,
	"FLOCK_RADIUS": 10.5,
	"SEPARATION_WEIGHT": 54.0,
	"COHESION_WEIGHT": 3.5,
	"ALIGNMENT_WEIGHT": 7.0,
	"WANDER_WEIGHT": 18.0,
	"WANDERER_BEACON_RADIUS_PX": 96.0,
	"SKIRMISH_RANGE_PX": 16.0,
	"SKIRMISH_COOLDOWN_SEC": 0.58,
	"RAD_MUTATE_THRESHOLD": 0.55,
	"FLORA_BURN_DURATION": 6.5,
	"SLOPE_RESIST": 0.45,
	"SLOPE_SLIDE": 26.0,
	"WATER_AVOID_FORCE": 64.0,
	"LAVA_FLEE_SPEED_MULT": 1.75,
	"HOT_TEMP_THRESHOLD": 70.0,
	"METEOR_TRAUMA": 0.35,
	"METEOR_HIT_STOP": 0.06,
	"SPRING_OMEGA": 18.0,
	"SPRING_ZETA": 0.25,
	"FLORA_SYNC_SLICE": 24,
	"MAX_UNITS": 720,
	"HARVEST_DURATION_FARM": 1.15,
	"HARVEST_DURATION_MINE": 1.35,
	"BUILD_WORK_INTERVAL": 0.85,
	"WORKER_REACH_PX": 5.5,
	"DEPOT_REACH_PX": 6.5,
	"PATROL_RADIUS_PX": 20.0,
	"ROAD_SPEED_BONUS": 1.35,
	"HUMAN_ATTACK_RANGE_PX": 130.0,
	"HUMAN_ATTACK_CD_SEC": 0.62,
	"HUMAN_DAMAGE": 15.0,
	"HUMAN_DODGE_CHANCE": 0.30,
	"HUMAN_DODGE_SPEED": 62.0,
	"ROBOT_ATTACK_RANGE_PX": 160.0,
	"ROBOT_ATTACK_CD_SEC": 0.92,
	"ROBOT_DAMAGE": 24.0,
	"ROBOT_SPEED_MULT": 0.84,
	"ROBOT_ARMOR_MULT": 0.68,
	"SPORE_ATTACK_RANGE_PX": 105.0,
	"SPORE_ATTACK_CD_SEC": 0.50,
	"SPORE_DAMAGE": 13.0,
	"SPORE_SPEED_MULT": 1.16,
	"SPORE_REGEN_MYCELIUM": 15.0,
	"SPORE_CORRODE_DPS": 5.5,
	"SPORE_CORRODE_SEC": 3.0,
	"GLITCH_DURATION_SEC": 6.5,
	"VIRUS_DURATION_SEC": 9.0,
	"VIRUS_DPS": 6.5,
	"PORTAL_MAX_SQUAD": 8,
	"PORTAL_SELECT_RADIUS_PX": 110.0,
	"PORTAL_LAND_SEARCH_PX": 44.0,
	"PORTAL_INVULN_SEC": 1.8,
	"BIO_SEEDER_UNITS": 5,
}

# Canonical WorldTerrain enum mirrors (avoid cross-file class_name dependencies)
const TIER_DEEP_OCEAN: int = 0
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

# Worker roles, tasks, and CivSim resource constants (mirror CivSim without class_name hints)
const MAX_UNITS: int = 720
const MAX_FLORA: int = 900
const MAX_CITIES: int = 64

const FACTION_HUMAN: int = 0
const FACTION_ROBOT: int = 1
const FACTION_SPORE: int = 2
const FACTION_MUTANT: int = 3
const FACTION_NONE: int = 255

const ROLE_FREE: int = 0
const ROLE_FARMER: int = 1
const ROLE_MINER: int = 2
const ROLE_BUILDER: int = 3
const ROLE_SOLDIER: int = 4
const ROLE_MUTANT: int = 5

const TASK_IDLE: int = 0
const TASK_MOVE_GOAL: int = 1
const TASK_HARVEST: int = 2
const TASK_HAUL_DEPOT: int = 3
const TASK_PATROL: int = 4

const RES_FOOD: int = 0
const RES_ORE: int = 1
const RES_ENERGY: int = 2
const RES_SCIENCE: int = 3
const RES_BUILD_WORK: int = 4
const CARRY_NONE: int = 255

const ROLE_PATTERN: Array[int] = [
	ROLE_FARMER, ROLE_MINER, ROLE_BUILDER, ROLE_FARMER,
	ROLE_MINER, ROLE_SOLDIER, ROLE_FARMER, ROLE_BUILDER,
]
const ROLE_PATTERN_ROBOT: Array[int] = [
	ROLE_MINER, ROLE_SOLDIER, ROLE_BUILDER, ROLE_MINER,
	ROLE_MINER, ROLE_SOLDIER, ROLE_BUILDER, ROLE_SOLDIER,
]
const ROLE_PATTERN_SPORE: Array[int] = [
	ROLE_FARMER, ROLE_SOLDIER, ROLE_BUILDER, ROLE_FARMER,
	ROLE_SOLDIER, ROLE_MINER, ROLE_SOLDIER, ROLE_BUILDER,
]

# Units atlas columns (192x8, 24 tiles of 8x8, sprite_mode=3 motion_mode=2)
const UNITS_ATLAS_PATH: String = "res://assets/atlases/units_atlas.png"
const UNITS_MASK_PATH: String = "res://assets/atlases/units_atlas_mask.png"
const UNIT_ATLAS_COLS: int = 24
const UCOL_HUMAN_WALK_A: int = 0
const UCOL_HUMAN_WALK_B: int = 1
const UCOL_HUMAN_WORK: int = 2
const UCOL_HUMAN_CARGO: int = 3
const UCOL_HUMAN_SOLDIER_A: int = 4
const UCOL_HUMAN_SOLDIER_B: int = 5
const UCOL_HUMAN_ENGINEER: int = 6
const UCOL_HUMAN_JETPACK: int = 7
const UCOL_ROBOT_DRONE_A: int = 8
const UCOL_ROBOT_DRONE_B: int = 9
const UCOL_ROBOT_WALKER_A: int = 10
const UCOL_ROBOT_WALKER_B: int = 11
const UCOL_ROBOT_HEAVY_A: int = 12
const UCOL_ROBOT_HEAVY_B: int = 13
const UCOL_ROBOT_CARGO: int = 14
const UCOL_SPORE_CRAWLER_A: int = 15
const UCOL_SPORE_CRAWLER_B: int = 16
const UCOL_SPORE_STALKER_A: int = 17
const UCOL_SPORE_STALKER_B: int = 18
const UCOL_SPORE_CARGO: int = 19
const UCOL_MUTANT_CRYSTAL_A: int = 20
const UCOL_MUTANT_CRYSTAL_B: int = 21
const UCOL_HUMAN_FARMER: int = 22
const UCOL_CARGO_PIP: int = 23

# Flora atlas columns (168x12, 14 tiles of 12x12, sprite_mode=3 motion_mode=1)
const FLORA_ATLAS_PATH: String = "res://assets/atlases/flora_atlas.png"
const FLORA_MASK_PATH: String = "res://assets/atlases/flora_atlas_mask.png"
const FLORA_ATLAS_COLS: int = 14
const FLORA_TREE_LUSH: int = 0
const FLORA_SHROOM_LUSH: int = 1
const FLORA_RUST_SCRUB: int = 2
const FLORA_CRYSTAL_SMALL: int = 3
const FLORA_CRYSTAL_TALL: int = 4
const FLORA_BOULDER: int = 5
const FLORA_MAGMA_VENT: int = 6
const FLORA_FROST_PINE: int = 7
const FLORA_TREE_CHARRED: int = 8
const FLORA_TREE_ASH: int = 9
const FLORA_SPORE_POD: int = 10
const FLORA_CRYSTAL_CLUSTER: int = 11
const FLORA_LUSH_SAPLING: int = 12
const FLORA_BURNING_BUSH: int = 13

const DEATH_BURN: int = 0
const DEATH_DROWN: int = 1
const DEATH_COMBAT: int = 2

const SUIT_PALETTE := [
	Color("#D8E2EE"), # Wanderer Slate
	Color("#DFB85C"), # Expedition Ochre
	Color("#6EC4DB"), # Science Teal
	Color("#DF8D5E"), # Pioneer Rust
	Color("#75D49B"), # Scout Mint
]

const ROLE_TINTS := [
	Color("#DCE4EC"), # Free
	Color("#7AD9A0"), # Farmer Mint
	Color("#E2BC58"), # Miner Gold
	Color("#DF8D5B"), # Builder Amber
	Color("#68C8E6"), # Soldier Cyan
	Color("#C864EE"), # Mutant Violet
]

const CARGO_COLORS := [
	Color("#55DF68"), # RES_FOOD
	Color("#EAAC38"), # RES_ORE
	Color("#3CE4FF"), # RES_ENERGY
	Color("#CA68F0"), # RES_SCIENCE
	Color("#E0C070"), # RES_BUILD_WORK
]

const ROLE_NAMES := ["Wanderer", "Farmer", "Miner", "Builder", "Soldier", "Mutant"]
const TASK_NAMES := ["Idle", "Moving", "Working", "Hauling", "Patrol"]
const FACTION_NAMES := ["Human", "Robot", "Spore", "Mutant"]
const CARGO_NAMES := ["Food", "Ore", "Energy", "Science", "Build"]

const MEMORY_SLOTS: int = 8
const MEM_AWOKE: int = 1
const MEM_JOINED_COLONY: int = 2
const MEM_GATHERED: int = 3
const MEM_BUILT: int = 4
const MEM_DODGED: int = 5
const MEM_FOUGHT: int = 6
const MEM_SHIELD_SAVED: int = 7
const MEM_BLESSED: int = 8
const MEM_MUTATED: int = 9
const MEM_POSSESSED: int = 10
const MEM_PORTAL_JUMP: int = 11
const MEM_GLITCHED: int = 12
const MEM_INFECTED: int = 13
const MEM_NAMES_RU := [
	"",
	"Пробудился",
	"Вступил в колонию",
	"Добыл ресурсы",
	"Построил объект",
	"Увернулся в бою",
	"Сразился",
	"Спасён щитом",
	"Благословлён",
	"Мутировал",
	"Власть Демиурга",
	"Прыжок через портал",
	"Сбой ИИ-ядра",
	"Ксено-инфекция",
]

const STRIP_DODGE: int = 0
const STRIP_BLOCK: int = 1
const STRIP_HAPPY: int = 2
const STRIP_ANGRY: int = 3
const STRIP_FOOD: int = 4
const STRIP_SHIELD: int = 5
const STRIP_LVLUP: int = 6
const STRIP_MUTATE: int = 7
const STRIP_PACT: int = 8
const STRIP_WAR: int = 9
const STRIP_REBEL: int = 10
const STRIP_PORTAL: int = 11
const STRIP_SKULL: int = STRIP_MUTATE

const DIPLO_NEUTRAL: int = 0
const DIPLO_PACT: int = 1
const DIPLO_TOTAL_WAR: int = 2
const DIPLO_REBELLION: int = 3
const BLD_TYPE_QUANTUM_GATE: int = 9

const BEAM_COL_HUMAN := Color(0.282, 0.961, 1.0, 1.0)
const BEAM_COL_ROBOT := Color(1.0, 0.220, 0.220, 1.0)
const BEAM_COL_SPORE := Color(0.384, 1.0, 0.478, 1.0)
const BEAM_COL_REBEL := Color(1.0, 0.882, 0.337, 1.0)
const BEAM_COL_MUTANT := Color(0.85, 0.42, 1.0, 1.0)

const LAYER_ROUTINE: int = 0
const LAYER_LOGISTICS: int = 1
const LAYER_COMBAT: int = 2
const LAYER_CRITICAL: int = 3

const SHADOW_BASE_COLOR := Color(0.04, 0.06, 0.14, 0.34)

signal impact_trauma(trauma: float, hit_stop_sec: float)

var _world: Node2D = null
var _fx: Node2D = null
var _civ: Node2D = null

var _map_w: int = 640
var _map_h: int = 360
var _cell_size: int = 16
var _grid_w: int = 40
var _grid_h: int = 23

var _shadow_group: CanvasGroup
var _mm_ground_shadows: MultiMeshInstance2D
var _mm_flora: MultiMeshInstance2D
var _mm_units: MultiMeshInstance2D
var _mm_cargo: MultiMeshInstance2D
var _flora_mat: ShaderMaterial
var _unit_mat: ShaderMaterial
var _cargo_mat: ShaderMaterial

# Flat SoA arrays for colonists & units (zero Node2D per unit)
var _unit_count: int = 0
var _target_pop_count: int = 110
var _pos: PackedVector2Array
var _vel: PackedVector2Array
var _px: PackedFloat32Array
var _py: PackedFloat32Array
var _vx: PackedFloat32Array
var _vy: PackedFloat32Array
var _pos_dirty: bool = false
var _acc: PackedVector2Array
var _phase: PackedFloat32Array
var _hp: PackedFloat32Array
var _knockback_timer: PackedFloat32Array
var _facing: PackedFloat32Array
var _suit_tint: PackedColorArray
var _wander_angle: PackedFloat32Array

# Stage 2 / 2.5 economy, survival, combat & stable UID SoA arrays
var _u_uid: PackedInt32Array
var _next_uid: int = 1
var _uid_to_idx: Dictionary = {}
var _u_city_id: PackedInt32Array
var _u_faction_id: PackedByteArray
var _u_role: PackedByteArray
var _u_task: PackedByteArray
var _u_target_pos: PackedVector2Array
var _u_depot_pos: PackedVector2Array
var _u_flora_idx: PackedInt32Array
var _u_carry_type: PackedByteArray
var _u_carry_amt: PackedFloat32Array
var _u_work_timer: PackedFloat32Array
var _u_stuck_timer: PackedFloat32Array
var _u_detour_timer: PackedFloat32Array
var _u_detour_dir: PackedVector2Array
var _u_detour_side: PackedFloat32Array
var _u_last_dist: PackedFloat32Array
var _u_rad_exp: PackedFloat32Array
var _u_rad_now: PackedFloat32Array
var _u_fire_now: PackedFloat32Array
var _hit_flash_timer: PackedFloat32Array
var _u_attack_cd: PackedFloat32Array
var _u_lava_grace: PackedFloat32Array
var _u_beacon_pos: PackedVector2Array
var _u_kills: PackedInt32Array
var _u_dodge_cd: PackedFloat32Array
var _u_dodges: PackedInt32Array
var _u_sparring_cd: PackedFloat32Array
var _u_alert_layer: PackedByteArray
var _u_glitch_timer: PackedFloat32Array
var _u_infected_timer: PackedFloat32Array
var _u_corrode_timer: PackedFloat32Array
var _u_invuln_timer: PackedFloat32Array
var _u_latent_timer: PackedFloat32Array
var _u_target_idx: PackedInt32Array
var _u_target_uid: PackedInt32Array
var _u_acq_cd: PackedFloat32Array

# 8-slot circular Unit Memory Chronicle (flat SoA, zero per-tick alloc)
var _u_mem_type: PackedByteArray
var _u_mem_time: PackedFloat32Array
var _u_mem_head: PackedByteArray
var _u_mem_count: PackedByteArray

# Flat spatial hash grid linked list (zero per-frame dict allocations)
var _cell_head: PackedInt32Array
var _unit_next: PackedInt32Array
var _macro_w: int = 10
var _macro_h: int = 6
var _macro_pop: PackedInt32Array
var _macro_head: PackedInt32Array
var _macro_next: PackedInt32Array
var _any_infected_unit: bool = false
var _any_glitched_unit: bool = false

# Flat SoA arrays for flora & props + spatial hash (preallocated up to MAX_FLORA)
var _flora_count: int = 0
var _flora_pos: PackedVector2Array
var _flora_col: PackedByteArray
var _flora_sway_phase: PackedFloat32Array
var _flora_shake: PackedFloat32Array
var _flora_spring: PackedFloat32Array
var _flora_spring_vel: PackedFloat32Array
var _flora_burn: PackedFloat32Array
var _flora_grow: PackedFloat32Array
var _flora_tint: PackedColorArray
var _flora_sync_cursor: int = 0
var _flora_cell_head: PackedInt32Array
var _flora_next: PackedInt32Array
var _flora_hash_dirty: bool = true

# Synced CivSim goal buffers (pushed by CivSim via set_goal_buffers)
var _city_active: PackedByteArray
var _city_faction: PackedByteArray
var _city_depot_pos: PackedVector2Array
var _city_center: PackedVector2Array
var _city_mine_pos: PackedVector2Array
var _city_build_pos: PackedVector2Array
var _city_patrol_pos: PackedVector2Array
var _city_alerted: PackedByteArray
var _city_threat_pos: PackedVector2Array
var _city_tech_tier: PackedByteArray
var _city_color: PackedColorArray
var _city_pop_counts: PackedInt32Array
var _zone_city_id: PackedInt32Array
var _zone_w: int = 80
var _zone_h: int = 45
var _road_mask: PackedByteArray
var _diplo_matrix: PackedByteArray
var _diplo_max_cities: int = MAX_CITIES
var _city_war_state: PackedByteArray
var _city_loyalty: PackedFloat32Array
var _city_is_rebel: PackedByteArray
var _city_emp_timer: PackedFloat32Array
var _prev_city_rebel: PackedByteArray
var _prev_city_war: PackedByteArray

# Packed beam-event queues consumed by CombatAndBeams via pop_fired_beams()
var _beam_starts: PackedVector2Array = PackedVector2Array()
var _beam_ends: PackedVector2Array = PackedVector2Array()
var _beam_colors: PackedColorArray = PackedColorArray()
var _beam_widths: PackedFloat32Array = PackedFloat32Array()
var _beam_heavy: PackedByteArray = PackedByteArray()

# Synced building footprints for flora clearance & colonist roof avoidance
var _bld_pos: PackedVector2Array
var _bld_type: PackedByteArray
var _bld_count: int = 0
var _bld_half_w: PackedFloat32Array
var _bld_top_h: PackedFloat32Array
var _bld_occ: PackedByteArray
var _bld_cell_head: PackedInt32Array
var _bld_next: PackedInt32Array
var _bld_synced_count: int = -1
var _bld_synced_sum: Vector2 = Vector2(-1.0, -1.0)
var _unit_colors_dirty: bool = true
var _flora_dirty_all: bool = true
var _flora_has_anim: bool = false
var _flora_active_custom: PackedByteArray

# Per-unit terrain caches + bulk MultiMesh buffers (16 floats/instance)
var _tc_tier: PackedByteArray
var _tc_biome: PackedByteArray
var _tc_grad_x: PackedFloat32Array
var _tc_grad_y: PackedFloat32Array
var _u_last_tile: PackedInt32Array
var _u_tier: PackedByteArray
var _u_biome: PackedByteArray
var _u_temp: PackedFloat32Array
var _u_grad_x: PackedFloat32Array
var _u_grad_y: PackedFloat32Array
var _u_boids_ax: PackedFloat32Array
var _u_boids_ay: PackedFloat32Array
var _u_wan_ang: PackedFloat32Array
var _u_wan_dx: PackedFloat32Array
var _u_wan_dy: PackedFloat32Array
var _unit_mm_buf: PackedFloat32Array
var _shadow_mm_buf: PackedFloat32Array
var _shadow_flora_count: int = 0
var _flora_shadows_dirty: bool = true
var _shadows_dirty: bool = true
var _zoom_lod_val: float = 2.0
var _tick_idx: int = 0
var _spatial_hash_dirty: bool = true

var _rng := RandomNumberGenerator.new()
var _sim_time: float = 0.0
var _vortex_fx_cd: float = 0.0
var _vortex_alchemy_cd: float = 0.0
var _impact_fx_cd: float = 0.0
var _area_fx_cd: float = 0.0
var _flora_regrow_cd: float = 0.0
var _campfire_ember_cd: float = 0.0
var _skirmish_sfx_cd: float = 0.0
var _spar_fx_cd: float = 0.0
var _work_fx_budget: int = 4
var _strip_fx_budget: int = 6
var _death_count: int = 0
var _skirmish_count: int = 0
var _total_dodges: int = 0
var _possessed_uid: int = -1
var _possess_move: Vector2 = Vector2.ZERO
var _possess_pulse: bool = false
var _possess_cd: float = 0.0
var _flora_mul: float = 1.0
var _crop_mul: float = 1.0
var _age_tint: Vector3 = Vector3.ONE
var _age_tint_strength: float = 0.0
var _city_hunger_cache: PackedFloat32Array
var _layers_built: bool = false


func _ready() -> void:
	_ensure_layers()


func _load_png_texture(res_path: String) -> Texture2D:
	if res_path.is_empty():
		return null
	var bytes := FileAccess.get_file_as_bytes(res_path)
	if bytes.size() > 0:
		var img := Image.new()
		if img.load_png_from_buffer(bytes) == OK:
			return ImageTexture.create_from_image(img)
	var res: Variant = load(res_path)
	if res is Texture2D:
		return res as Texture2D
	return null


func _make_fallback_atlas(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.85, 0.85, 0.85, 1.0))
	return ImageTexture.create_from_image(img)


func _ensure_layers() -> void:
	if _layers_built:
		return
	_layers_built = true
	_ensure_layers_rng_and_grid()


func _ensure_layers_rng_and_grid() -> void:
	_rng.seed = 20261114
	_resize_grid(_map_w, _map_h)
	_city_hunger_cache.resize(MAX_CITIES)
	_city_hunger_cache.fill(0.0)

	_shadow_group = CanvasGroup.new()
	_shadow_group.z_index = 0
	_shadow_group.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_shadow_group.self_modulate = SHADOW_BASE_COLOR

	_mm_ground_shadows = MultiMeshInstance2D.new()
	_mm_ground_shadows.z_index = 0
	_mm_ground_shadows.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mm_ground_shadows.texture = _build_ground_shadow_texture()

	var shadow_mm := MultiMesh.new()
	shadow_mm.transform_format = MultiMesh.TRANSFORM_2D
	shadow_mm.use_colors = false
	shadow_mm.use_custom_data = false
	var shadow_quad := QuadMesh.new()
	shadow_quad.size = Vector2(6.0, 4.0)
	shadow_mm.mesh = shadow_quad
	var shadow_cap := MAX_UNITS + MAX_FLORA
	shadow_mm.instance_count = shadow_cap
	shadow_mm.visible_instance_count = 0
	_mm_ground_shadows.multimesh = shadow_mm
	_shadow_mm_buf.resize(shadow_cap * 8)
	_shadow_mm_buf.fill(0.0)
	for si in range(shadow_cap):
		var sb := si * 8
		_shadow_mm_buf[sb] = 1.0
		_shadow_mm_buf[sb + 5] = 1.0

	_shadow_group.add_child(_mm_ground_shadows)
	add_child(_shadow_group)

	var flora_tex := _load_png_texture(FLORA_ATLAS_PATH)
	if flora_tex == null:
		flora_tex = _make_fallback_atlas(FLORA_ATLAS_COLS * 12, 12)
	var flora_mask := _load_png_texture(FLORA_MASK_PATH)
	if flora_mask == null:
		flora_mask = _make_fallback_atlas(FLORA_ATLAS_COLS * 12, 12)

	_mm_flora = MultiMeshInstance2D.new()
	_mm_flora.z_index = 0
	_mm_flora.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mm_flora.texture = flora_tex
	_flora_mat = ShaderMaterial.new()
	_flora_mat.shader = UNIT_SPRITE_SHADER
	_flora_mat.set_shader_parameter("sprite_mode", 3)
	_flora_mat.set_shader_parameter("motion_mode", 1)
	_flora_mat.set_shader_parameter("atlas_cols", FLORA_ATLAS_COLS)
	_flora_mat.set_shader_parameter("sprite_size", Vector2(12.0, 12.0))
	_flora_mat.set_shader_parameter("mask_tex", flora_mask)
	_flora_mat.set_shader_parameter("hdr_emissive", 2.6)
	_flora_mat.set_shader_parameter("age_tint", _age_tint)
	_flora_mat.set_shader_parameter("age_tint_strength", _age_tint_strength)
	_mm_flora.material = _flora_mat

	var flora_mm := MultiMesh.new()
	flora_mm.transform_format = MultiMesh.TRANSFORM_2D
	flora_mm.use_colors = true
	flora_mm.use_custom_data = true
	var flora_quad := QuadMesh.new()
	flora_quad.size = Vector2(12.0, 12.0)
	flora_mm.mesh = flora_quad
	flora_mm.instance_count = MAX_FLORA
	flora_mm.visible_instance_count = 0
	_mm_flora.multimesh = flora_mm
	add_child(_mm_flora)

	var unit_tex := _load_png_texture(UNITS_ATLAS_PATH)
	if unit_tex == null:
		unit_tex = _make_fallback_atlas(UNIT_ATLAS_COLS * 8, 8)
	var unit_mask := _load_png_texture(UNITS_MASK_PATH)
	if unit_mask == null:
		unit_mask = _make_fallback_atlas(UNIT_ATLAS_COLS * 8, 8)

	var u_px: float = TUNING_KNOBS["UNIT_QUAD_PX"]
	_mm_units = MultiMeshInstance2D.new()
	_mm_units.z_index = 1
	_mm_units.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mm_units.texture = unit_tex
	_unit_mat = ShaderMaterial.new()
	_unit_mat.shader = UNIT_SPRITE_SHADER
	_unit_mat.set_shader_parameter("sprite_mode", 3)
	_unit_mat.set_shader_parameter("motion_mode", 2)
	_unit_mat.set_shader_parameter("atlas_cols", UNIT_ATLAS_COLS)
	_unit_mat.set_shader_parameter("sprite_size", Vector2(u_px, u_px))
	_unit_mat.set_shader_parameter("mask_tex", unit_mask)
	_unit_mat.set_shader_parameter("hdr_emissive", 2.6)
	_unit_mat.set_shader_parameter("age_tint", _age_tint)
	_unit_mat.set_shader_parameter("age_tint_strength", _age_tint_strength)
	_mm_units.material = _unit_mat

	var unit_mm := MultiMesh.new()
	unit_mm.transform_format = MultiMesh.TRANSFORM_2D
	unit_mm.use_colors = true
	unit_mm.use_custom_data = true
	var unit_quad := QuadMesh.new()
	unit_quad.size = Vector2(u_px, u_px)
	unit_mm.mesh = unit_quad
	unit_mm.instance_count = maxi(int(TUNING_KNOBS["POPULATION_COUNT"]), 1)
	unit_mm.visible_instance_count = 0
	_mm_units.multimesh = unit_mm
	add_child(_mm_units)

	_mm_cargo = MultiMeshInstance2D.new()
	_mm_cargo.z_index = 2
	_mm_cargo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mm_cargo.texture = unit_tex
	_cargo_mat = ShaderMaterial.new()
	_cargo_mat.shader = UNIT_SPRITE_SHADER
	_cargo_mat.set_shader_parameter("sprite_mode", 3)
	_cargo_mat.set_shader_parameter("motion_mode", 2)
	_cargo_mat.set_shader_parameter("atlas_cols", UNIT_ATLAS_COLS)
	_cargo_mat.set_shader_parameter("sprite_size", Vector2(u_px, u_px))
	_cargo_mat.set_shader_parameter("mask_tex", unit_mask)
	_cargo_mat.set_shader_parameter("hdr_emissive", 2.2)
	_cargo_mat.set_shader_parameter("age_tint", _age_tint)
	_cargo_mat.set_shader_parameter("age_tint_strength", _age_tint_strength)
	_mm_cargo.material = _cargo_mat

	var cargo_mm := MultiMesh.new()
	cargo_mm.transform_format = MultiMesh.TRANSFORM_2D
	cargo_mm.use_colors = true
	cargo_mm.use_custom_data = true
	var cargo_quad := QuadMesh.new()
	cargo_quad.size = Vector2(u_px, u_px)
	cargo_mm.mesh = cargo_quad
	cargo_mm.instance_count = MAX_UNITS
	cargo_mm.visible_instance_count = 0
	_mm_cargo.multimesh = cargo_mm
	add_child(_mm_cargo)
	set_zoom_lod(_zoom_lod_val)


func _build_ground_shadow_texture() -> ImageTexture:
	var img := Image.create(6, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	for y in range(4):
		var x0 := 1 if (y == 0 or y == 3) else 0
		var x1 := 5 if (y == 0 or y == 3) else 6
		for x in range(x0, x1):
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, 1.0))
	return ImageTexture.create_from_image(img)


func set_day_phase(phase: float, night_mix: float) -> void:
	_ensure_layers()
	var nm := clampf(night_mix, 0.0, 1.0)
	if _flora_mat != null:
		_flora_mat.set_shader_parameter("day_phase", phase)
		_flora_mat.set_shader_parameter("night_mix", nm)
	if _unit_mat != null:
		_unit_mat.set_shader_parameter("day_phase", phase)
		_unit_mat.set_shader_parameter("night_mix", nm)
	if _cargo_mat != null:
		_cargo_mat.set_shader_parameter("day_phase", phase)
		_cargo_mat.set_shader_parameter("night_mix", nm)


func set_zoom_lod(zoom_val: float) -> void:
	_zoom_lod_val = zoom_val
	if _shadow_group != null:
		if zoom_val <= 1.70:
			_shadow_group.visible = false
		else:
			var fade := clampf((zoom_val - 1.70) / 0.35, 0.0, 1.0)
			_shadow_group.visible = true
			_shadow_group.self_modulate = Color(SHADOW_BASE_COLOR.r, SHADOW_BASE_COLOR.g, SHADOW_BASE_COLOR.b, SHADOW_BASE_COLOR.a * fade)
			if _shadows_dirty or _flora_shadows_dirty:
				_sync_ground_shadows()
	if _mm_cargo != null:
		var show_cargo := zoom_val > 1.55
		var was_vis := _mm_cargo.visible
		_mm_cargo.visible = show_cargo
		if show_cargo and not was_vis:
			_sync_cargo_multimesh()


func set_cosmic_age_mods(flora_mul: float, crop_mul: float, tint: Color, tint_strength: float) -> void:
	_flora_mul = clampf(flora_mul, 0.05, 4.0)
	_crop_mul = clampf(crop_mul, 0.15, 3.0)
	_age_tint = Vector3(tint.r, tint.g, tint.b)
	_age_tint_strength = clampf(tint_strength, 0.0, 1.0)
	if _flora_mat != null:
		_flora_mat.set_shader_parameter("age_tint", _age_tint)
		_flora_mat.set_shader_parameter("age_tint_strength", _age_tint_strength)
	if _unit_mat != null:
		_unit_mat.set_shader_parameter("age_tint", _age_tint)
		_unit_mat.set_shader_parameter("age_tint_strength", _age_tint_strength)
	if _cargo_mat != null:
		_cargo_mat.set_shader_parameter("age_tint", _age_tint)
		_cargo_mat.set_shader_parameter("age_tint_strength", _age_tint_strength)


func notify_shield_saved(world_pos: Vector2, radius: float) -> int:
	if _unit_count <= 0 or radius <= 0.5:
		return 0
	var r2 := radius * radius
	var saved_n := 0
	var strips_shown := 0
	var can_strip := _fx != null and _fx.has_method("spawn_reaction_strip")
	for i in range(_unit_count):
		var dx := _px[i] - world_pos.x
		var dy := _py[i] - world_pos.y
		if dx * dx + dy * dy <= r2:
			_hit_flash_timer[i] = maxf(_hit_flash_timer[i], 0.22)
			_record_memory(i, MEM_SHIELD_SAVED)
			saved_n += 1
			if can_strip and strips_shown < 4 and _strip_fx_budget > 0:
				_strip_fx_budget -= 1
				strips_shown += 1
				_fx.call("spawn_reaction_strip", Vector2(_px[i], _py[i] - 7.0), STRIP_SHIELD)
	return saved_n


func set_possessed_unit(uid: int, move_dir: Vector2, trigger_pulse: bool) -> Dictionary:
	_ensure_layers()
	if uid < 0:
		_possessed_uid = -1
		_possess_move = Vector2.ZERO
		_possess_pulse = false
		return {"active": false, "uid": -1, "pos": Vector2.ZERO, "struck_targets": 0}

	var idx := int(_uid_to_idx.get(uid, -1))
	if idx < 0 or idx >= _unit_count:
		_possessed_uid = -1
		_possess_move = Vector2.ZERO
		_possess_pulse = false
		return {"active": false, "uid": -1, "pos": Vector2.ZERO, "struck_targets": 0}

	var was_new := (_possessed_uid != uid)
	_possessed_uid = uid
	_possess_move = move_dir.normalized() if move_dir.length_squared() > 0.0001 else Vector2.ZERO
	_possess_pulse = trigger_pulse

	if was_new:
		_record_memory(idx, MEM_POSSESSED)
		_hit_flash_timer[idx] = maxf(_hit_flash_timer[idx], 0.24)
		if _fx != null and _fx.has_method("spawn_reaction_strip"):
			_fx.call("spawn_reaction_strip", Vector2(_px[idx], _py[idx] - 7.0), STRIP_LVLUP)

	var struck := 0
	if trigger_pulse:
		struck = _execute_possessed_kinetic_pulse(idx)
		idx = int(_uid_to_idx.get(uid, -1))
		if idx < 0 or idx >= _unit_count:
			return {"active": false, "uid": -1, "pos": Vector2.ZERO, "struck_targets": struck}

	return {
		"active": true,
		"uid": uid,
		"pos": Vector2(_px[idx], _py[idx]),
		"struck_targets": struck,
	}


func _execute_possessed_kinetic_pulse(idx: int) -> int:
	if idx < 0 or idx >= _unit_count or _possess_cd > 0.0:
		return 0
	_possess_cd = 0.36
	_possess_pulse = false

	var p_uid := _u_uid[idx]
	var pos := Vector2(_px[idx], _py[idx])
	var my_cid := _u_city_id[idx]
	var radius := 22.0
	var r2 := radius * radius
	var struck := 0

	var i := _unit_count - 1
	while i >= 0:
		if _u_uid[i] != p_uid:
			var dvec := Vector2(_px[i] - pos.x, _py[i] - pos.y)
			var d2 := dvec.length_squared()
			if d2 <= r2:
				var hostile := _are_units_hostile(idx, i)
				var push_dir := dvec.normalized() if d2 > 0.01 else Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU))
				_vx[i] += push_dir.x * 46.0
				_vy[i] += push_dir.y * 46.0
				_vel[i] = Vector2(_vx[i], _vy[i])
				_knockback_timer[i] = maxf(_knockback_timer[i], 0.24)
				if hostile:
					_hp[i] -= 34.0
					_hit_flash_timer[i] = 0.16
					struck += 1
					if _hp[i] <= 0.0:
						var cur_self := int(_uid_to_idx.get(p_uid, -1))
						if cur_self >= 0:
							_u_kills[cur_self] += 1
						_kill_unit(i, DEATH_COMBAT)
		i -= 1

	var f := _flora_count - 1
	while f >= 0:
		var fp := _flora_pos[f]
		if fp.distance_squared_to(pos) <= r2:
			var fc := int(_flora_col[f])
			if fc == FLORA_CRYSTAL_SMALL or fc == FLORA_CRYSTAL_TALL or fc == FLORA_CRYSTAL_CLUSTER or fc == FLORA_BOULDER:
				struck += 1
				if _fx != null:
					_fx.emit_spark_arc(fp, Vector2.UP, Color(0.55, 0.92, 1.0, 1.0))
					_fx.spawn_burst(fp + Vector2(0.0, -3.0), 4, Color(0.65, 0.94, 1.0, 0.92), 20.0, 0.26, -12.0)
				if my_cid >= 0:
					_deposit_to_civ(my_cid, RES_ENERGY if fc != FLORA_BOULDER else RES_ORE, 2.0)
				_remove_flora_slot(f)
			else:
				_flora_shake[f] = 1.0
				_flora_spring[f] = 0.68
				_flora_spring_vel[f] = 4.2
				_flora_has_anim = true
				if f < _flora_active_custom.size():
					_flora_active_custom[f] = 1
		f -= 1

	var self_idx := int(_uid_to_idx.get(p_uid, -1))
	if self_idx >= 0:
		_hit_flash_timer[self_idx] = maxf(_hit_flash_timer[self_idx], 0.18)
		if struck > 0:
			_record_memory(self_idx, MEM_FOUGHT)

	if _fx != null:
		_fx.emit_spark_arc(pos, Vector2.RIGHT, Color(1.0, 0.86, 0.38, 1.0))
		_fx.spawn_burst(pos, 8, Color(1.0, 0.88, 0.42, 0.95), 34.0, 0.28, 0.0)
		_fx.play_sfx("skirmish")
	return struck


func _remove_flora_slot(f: int) -> void:
	if f < 0 or f >= _flora_count:
		return
	var last := _flora_count - 1
	if f != last:
		_flora_pos[f] = _flora_pos[last]
		_flora_col[f] = _flora_col[last]
		_flora_sway_phase[f] = _flora_sway_phase[last]
		_flora_shake[f] = _flora_shake[last]
		_flora_spring[f] = _flora_spring[last]
		_flora_spring_vel[f] = _flora_spring_vel[last]
		_flora_burn[f] = _flora_burn[last]
		_flora_grow[f] = _flora_grow[last]
		_flora_tint[f] = _flora_tint[last]
		if f < _flora_active_custom.size() and last < _flora_active_custom.size():
			_flora_active_custom[f] = _flora_active_custom[last]
	_flora_count = last
	for u in range(_unit_count):
		var uf := _u_flora_idx[u]
		if uf == f:
			_u_flora_idx[u] = -1
		elif uf == last:
			_u_flora_idx[u] = f
	_flora_hash_dirty = true
	_flora_dirty_all = true
	_flora_shadows_dirty = true
	if _mm_flora != null and _mm_flora.multimesh != null:
		_mm_flora.multimesh.visible_instance_count = _flora_count


func _resize_grid(w: int, h: int) -> void:
	_map_w = maxi(w, 32)
	_map_h = maxi(h, 32)
	_cell_size = TUNING_KNOBS["CELL_SIZE"]
	_grid_w = maxi(1, ceili(float(_map_w) / float(_cell_size)))
	_grid_h = maxi(1, ceili(float(_map_h) / float(_cell_size)))
	var total_cells := _grid_w * _grid_h
	_cell_head.resize(total_cells)
	_cell_head.fill(-1)
	_flora_cell_head.resize(total_cells)
	_flora_cell_head.fill(-1)
	_bld_cell_head.resize(total_cells)
	_bld_cell_head.fill(-1)
	_macro_w = maxi(1, ceili(float(_map_w) / 64.0))
	_macro_h = maxi(1, ceili(float(_map_h) / 64.0))
	_macro_pop.resize(_macro_w * _macro_h)
	_macro_pop.fill(0)
	_macro_head.resize(_macro_w * _macro_h)
	_macro_head.fill(-1)
	_clear_tc()
	_flora_hash_dirty = true


func _clear_tc() -> void:
	var total := _map_w * _map_h
	_tc_tier.resize(total)
	_tc_tier.fill(0)
	_tc_biome.resize(total)
	_tc_biome.fill(0)
	_tc_grad_x.resize(total)
	_tc_grad_y.resize(total)


func _invalidate_tc_rect_i(rect: Rect2i) -> void:
	var tc_need := _map_w * _map_h
	if _tc_tier.size() < tc_need or _tc_biome.size() < tc_need:
		return
	var x0 := clampi(rect.position.x - 1, 0, _map_w - 1)
	var x1 := clampi(rect.position.x + rect.size.x + 1, 0, _map_w - 1)
	var y0 := clampi(rect.position.y - 1, 0, _map_h - 1)
	var y1 := clampi(rect.position.y + rect.size.y + 1, 0, _map_h - 1)
	if (x1 - x0 + 1) * (y1 - y0 + 1) >= (tc_need >> 1):
		_tc_tier.fill(0)
		_tc_biome.fill(0)
		return
	for iy in range(y0, y1 + 1):
		var row_off := iy * _map_w
		for ix in range(x0, x1 + 1):
			var idx := row_off + ix
			_tc_tier[idx] = 0
			_tc_biome[idx] = 0


func _invalidate_tc_rect(world_pos: Vector2, radius: float) -> void:
	var ir := ceili(maxf(radius, 4.0)) + 4
	_invalidate_tc_rect_i(Rect2i(int(world_pos.x) - ir, int(world_pos.y) - ir, ir * 2, ir * 2))


func bind_systems(world: Node2D, fx: Node2D) -> void:
	_ensure_layers()
	_world = world
	_fx = fx
	if _world != null:
		var mw_var: Variant = _world.get("map_w")
		var mh_var: Variant = _world.get("map_h")
		if mw_var is int and mh_var is int:
			_resize_grid(int(mw_var), int(mh_var))
		if _world.has_signal("map_rebuilt"):
			var cb := Callable(self, "_on_world_map_rebuilt")
			if not _world.is_connected("map_rebuilt", cb):
				_world.connect("map_rebuilt", cb)
		if _world.has_signal("surface_impact"):
			var cb_imp := Callable(self, "_on_world_surface_impact")
			if not _world.is_connected("surface_impact", cb_imp):
				_world.connect("surface_impact", cb_imp)


func bind_civ(civ: Node2D) -> void:
	_ensure_layers()
	_civ = civ
	if _civ != null and _civ.has_method("get_goal_buffers"):
		var bufs: Variant = _civ.call("get_goal_buffers")
		if bufs is Dictionary:
			set_goal_buffers(bufs as Dictionary)


func set_goal_buffers(buffers: Dictionary) -> void:
	if buffers.is_empty():
		return
	var v_active: Variant = buffers.get("city_active", PackedByteArray())
	if v_active is PackedByteArray:
		_city_active = v_active
	var v_faction: Variant = buffers.get("city_faction", PackedByteArray())
	if v_faction is PackedByteArray:
		_city_faction = v_faction
	var v_depot: Variant = buffers.get("city_depot_pos", PackedVector2Array())
	if v_depot is PackedVector2Array:
		_city_depot_pos = v_depot
	var v_center: Variant = buffers.get("city_center", _city_depot_pos)
	if v_center is PackedVector2Array:
		_city_center = v_center
	var v_mine: Variant = buffers.get("city_mine_pos", PackedVector2Array())
	if v_mine is PackedVector2Array:
		_city_mine_pos = v_mine
	var v_build: Variant = buffers.get("city_build_pos", PackedVector2Array())
	if v_build is PackedVector2Array:
		_city_build_pos = v_build
	var v_patrol: Variant = buffers.get("city_patrol_pos", PackedVector2Array())
	if v_patrol is PackedVector2Array:
		_city_patrol_pos = v_patrol
	var v_alerted: Variant = buffers.get("city_alerted", PackedByteArray())
	if v_alerted is PackedByteArray:
		_city_alerted = v_alerted
	var v_threat: Variant = buffers.get("city_threat_pos", PackedVector2Array())
	if v_threat is PackedVector2Array:
		_city_threat_pos = v_threat
	var v_tier: Variant = buffers.get("city_tech_tier", PackedByteArray())
	if v_tier is PackedByteArray:
		_city_tech_tier = v_tier
	var v_col: Variant = buffers.get("city_color", PackedColorArray())
	if v_col is PackedColorArray:
		_city_color = v_col
	var v_zcity: Variant = buffers.get("zone_city_id", PackedInt32Array())
	if v_zcity is PackedInt32Array:
		_zone_city_id = v_zcity
	_zone_w = int(buffers.get("zone_w", _zone_w))
	_zone_h = int(buffers.get("zone_h", _zone_h))
	var v_road: Variant = buffers.get("road_mask", PackedByteArray())
	if v_road is PackedByteArray:
		_road_mask = v_road

	_diplo_max_cities = clampi(int(buffers.get("max_cities", MAX_CITIES)), 1, MAX_CITIES)
	var v_diplo: Variant = buffers.get("diplo_matrix", PackedByteArray())
	if v_diplo is PackedByteArray:
		_diplo_matrix = v_diplo
	var v_war: Variant = buffers.get("city_war_state", PackedByteArray())
	if v_war is PackedByteArray:
		_city_war_state = v_war
	var v_loy: Variant = buffers.get("city_loyalty", PackedFloat32Array())
	if v_loy is PackedFloat32Array:
		_city_loyalty = v_loy
	var v_reb: Variant = buffers.get("city_is_rebel", PackedByteArray())
	if v_reb is PackedByteArray:
		_city_is_rebel = v_reb
	var v_emp: Variant = buffers.get("city_emp_timer", PackedFloat32Array())
	if v_emp is PackedFloat32Array:
		_city_emp_timer = v_emp

	if _prev_city_war.size() < MAX_CITIES:
		_prev_city_war.resize(MAX_CITIES)
		_prev_city_war.fill(0)
	if _prev_city_rebel.size() < MAX_CITIES:
		_prev_city_rebel.resize(MAX_CITIES)
		_prev_city_rebel.fill(0)

	var newly_war_mask: int = 0
	var newly_rebel_mask: int = 0
	for c in range(mini(_city_war_state.size(), MAX_CITIES)):
		var ws := int(_city_war_state[c])
		if ws >= DIPLO_TOTAL_WAR and int(_prev_city_war[c]) < DIPLO_TOTAL_WAR:
			newly_war_mask |= 1
			if _fx != null and _fx.has_method("spawn_reaction_strip") and c < _city_depot_pos.size() and _city_depot_pos[c].x >= 0.0:
				_fx.call("spawn_reaction_strip", _city_depot_pos[c] + Vector2(0.0, -10.0), STRIP_WAR)
		_prev_city_war[c] = ws
	for c in range(mini(_city_is_rebel.size(), MAX_CITIES)):
		var rb := int(_city_is_rebel[c])
		if rb != 0 and int(_prev_city_rebel[c]) == 0:
			newly_rebel_mask |= 1
			if _fx != null and _fx.has_method("spawn_reaction_strip") and c < _city_depot_pos.size() and _city_depot_pos[c].x >= 0.0:
				_fx.call("spawn_reaction_strip", _city_depot_pos[c] + Vector2(0.0, -10.0), STRIP_REBEL)
		_prev_city_rebel[c] = rb

	if (newly_war_mask != 0 or newly_rebel_mask != 0) and _unit_count > 0:
		for u in range(_unit_count):
			var ucid := _u_city_id[u]
			if ucid < 0 or ucid >= MAX_CITIES:
				continue
			if ucid < _city_war_state.size() and int(_city_war_state[ucid]) >= DIPLO_TOTAL_WAR:
				if _u_role[u] == ROLE_SOLDIER or _u_role[u] == ROLE_FREE:
					_u_work_timer[u] = minf(_u_work_timer[u], 0.05)
			if newly_rebel_mask != 0 and ucid < _city_is_rebel.size() and _city_is_rebel[ucid] != 0:
				var ccol: Color = _city_color[ucid] if ucid < _city_color.size() else BEAM_COL_REBEL
				var base_t := _compute_worker_tint(ccol, int(_u_role[u]), int(_u_faction_id[u]))
				var r_tint := base_t.lerp(BEAM_COL_REBEL, 0.35)
				_suit_tint[u] = Color(minf(r_tint.r, 0.94), minf(r_tint.g, 0.94), minf(r_tint.b, 0.94), 1.0)
				_unit_colors_dirty = true

	if buffers.has("bld_pos") or buffers.has("bld_count"):
		var new_cnt := clampi(int(buffers.get("bld_count", 0)), 0, 512)
		var v_bpos: Variant = buffers.get("bld_pos", PackedVector2Array())
		var v_btype: Variant = buffers.get("bld_type", PackedByteArray())
		var b_dirty := bool(buffers.get("bld_dirty", false))
		var b_sum := Vector2.ZERO
		if v_bpos is PackedVector2Array and new_cnt > 0:
			var bp_arr := v_bpos as PackedVector2Array
			if bp_arr.size() >= new_cnt:
				b_sum = bp_arr[0] + bp_arr[new_cnt - 1]
		if b_dirty or new_cnt != _bld_synced_count or b_sum != _bld_synced_sum:
			if v_bpos is PackedVector2Array:
				_bld_pos = v_bpos as PackedVector2Array
			if v_btype is PackedByteArray:
				_bld_type = v_btype as PackedByteArray
			_bld_count = mini(new_cnt, _bld_pos.size())
			_bld_synced_count = new_cnt
			_bld_synced_sum = b_sum
			_rebuild_building_index(true)


func _exit_tree() -> void:
	if _flora_mat != null:
		_flora_mat.set_shader_parameter("mask_tex", null)
		_flora_mat = null
	if _unit_mat != null:
		_unit_mat.set_shader_parameter("mask_tex", null)
		_unit_mat = null
	if _cargo_mat != null:
		_cargo_mat.set_shader_parameter("mask_tex", null)
		_cargo_mat = null
	for mm_inst: MultiMeshInstance2D in [_mm_ground_shadows, _mm_flora, _mm_units, _mm_cargo]:
		if mm_inst != null:
			mm_inst.multimesh = null
			mm_inst.material = null
			mm_inst.texture = null
	_mm_ground_shadows = null
	_shadow_group = null
	_mm_flora = null
	_mm_units = null
	_mm_cargo = null
	_shadow_mm_buf.clear()
	_uid_to_idx.clear()
	_civ = null
	_world = null
	_fx = null


func _on_world_map_rebuilt() -> void:
	rebuild_population(_target_pop_count)


func _on_world_surface_impact(world_pos: Vector2, radius: float, kind: String) -> void:
	_invalidate_tc_rect(world_pos, radius)
	var ir := ceili(maxf(radius, 4.0)) + 4
	if _u_last_tile.size() >= _unit_count and _cell_head.size() > 0:
		var inv_r := float(ir + 6)
		var inv_r2 := inv_r * inv_r
		var min_cx := clampi(int(world_pos.x - inv_r) >> 4, 0, _grid_w - 1)
		var max_cx := clampi(int(world_pos.x + inv_r) >> 4, 0, _grid_w - 1)
		var min_cy := clampi(int(world_pos.y - inv_r) >> 4, 0, _grid_h - 1)
		var max_cy := clampi(int(world_pos.y + inv_r) >> 4, 0, _grid_h - 1)
		for cy in range(min_cy, max_cy + 1):
			var row_off := cy * _grid_w
			for cx in range(min_cx, max_cx + 1):
				var u := _cell_head[row_off + cx]
				while u != -1:
					var dx := _px[u] - world_pos.x
					var dy := _py[u] - world_pos.y
					if dx * dx + dy * dy <= inv_r2:
						_u_last_tile[u] = -1
					u = _unit_next[u]
	if kind == "meteor":
		trigger_impulse(world_pos, maxf(radius * 2.8, 36.0), 140.0, true)
		return
	if kind == "orbital_strike":
		trigger_impulse(world_pos, maxf(radius * 2.4, 34.0), 135.0, true)
		return
	if kind == "meltdown":
		trigger_impulse(world_pos, maxf(radius * 2.2, 30.0), 125.0, false)
		bless_or_mutate_area(world_pos, maxf(radius * 1.35, 18.0), false)
		return
	if kind == "ion_storm":
		_apply_ion_storm_unit_effects(world_pos, maxf(radius, 22.0))
	if _fx == null or _impact_fx_cd > 0.0:
		return
	_impact_fx_cd = 0.045
	if kind == "steam":
		_fx.spawn_burst(world_pos, 8, Color(0.86, 0.93, 0.98, 0.78), 18.0, 0.65, -22.0)
		_fx.play_sfx("lava")
	elif kind == "lava" or kind == "volcano" or kind == "firestorm":
		_fx.spawn_burst(world_pos, 10, Color(1.0, 0.45, 0.12, 1.0), 36.0, 0.48, 42.0)
		_fx.play_sfx("lava")
	elif kind == "rain":
		_fx.spawn_burst(world_pos, 10, Color(0.45, 0.85, 1.0, 0.85), 24.0, 0.45, 48.0)
	elif kind == "ion_storm":
		_fx.emit_spark_arc(world_pos, Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU)), Color(0.45, 0.95, 1.0, 1.0))
	else:
		_fx.spawn_burst(world_pos, 6, Color(0.75, 0.85, 0.95, 0.7), 16.0, 0.4, -10.0)


func rebuild_population(count: int = 110) -> void:
	_ensure_layers()
	_target_pop_count = clampi(count, 0, MAX_UNITS)
	var raw_seed: Variant = _world.get("current_seed") if _world != null else null
	var world_seed: int = int(raw_seed) if raw_seed != null else 20261114
	_rng.seed = (world_seed ^ 0x5A17C0DE) if world_seed != 0 else 20261114
	_clear_tc()
	_spatial_hash_dirty = true
	_flora_shadows_dirty = true
	_shadows_dirty = true
	_death_count = 0
	_skirmish_count = 0
	_total_dodges = 0
	_possessed_uid = -1
	_possess_move = Vector2.ZERO
	_possess_pulse = false
	_possess_cd = 0.0
	if _city_hunger_cache.size() == MAX_CITIES:
		_city_hunger_cache.fill(0.0)
	if _prev_city_war.size() == MAX_CITIES:
		_prev_city_war.fill(0)
	if _prev_city_rebel.size() == MAX_CITIES:
		_prev_city_rebel.fill(0)
	_beam_starts = PackedVector2Array()
	_beam_ends = PackedVector2Array()
	_beam_colors = PackedColorArray()
	_beam_widths = PackedFloat32Array()
	_beam_heavy = PackedByteArray()
	_any_infected_unit = false
	_any_glitched_unit = false

	_spawn_colonists(_target_pop_count)
	_spawn_flora(int(TUNING_KNOBS["FLORA_COUNT"]))
	_sync_unit_multimesh()
	_sync_flora_multimesh()


func _get_tile_tier(px: int, py: int) -> int:
	if px < 0 or px >= _map_w or py < 0 or py >= _map_h:
		return TIER_DEEP_OCEAN
	var idx := py * _map_w + px
	if idx < _tc_tier.size():
		var cached := _tc_tier[idx]
		if cached != 0:
			return int(cached) - 1
		if _world == null:
			return TIER_SOIL_LOW
		var t: int = _world.get_tier(px, py)
		_tc_tier[idx] = t + 1
		return t
	return _world.get_tier(px, py) if _world != null else TIER_SOIL_LOW


func _is_safe_spawn_tile(px: int, py: int) -> bool:
	if _world == null:
		return true
	var tier: int = _get_tile_tier(px, py)
	if tier <= TIER_SHALLOW or tier > TIER_MOUNTAINS:
		return false
	var biome: int = _world.get_biome(px, py)
	if biome == BIOME_LAVA or _world.get_temp(px, py) > 65.0:
		return false
	return true


func _find_land_pos(allow_lava: bool = false) -> Vector2:
	for _attempt in range(120):
		var px := _rng.randi_range(6, _map_w - 7)
		var py := _rng.randi_range(6, _map_h - 7)
		if _world == null:
			return Vector2(float(px) + 0.5, float(py) + 0.5)
		if _world.is_water(px, py):
			continue
		var tier: int = _world.get_tier(px, py)
		if tier < TIER_SAND or tier > TIER_MOUNTAINS:
			continue
		if not allow_lava and (_world.get_biome(px, py) == BIOME_LAVA or _world.get_temp(px, py) > 65.0):
			continue
		return Vector2(float(px) + _rng.randf_range(0.15, 0.85), float(py) + _rng.randf_range(0.15, 0.85))
	return Vector2(float(_map_w) * 0.5, float(_map_h) * 0.5)


func _resize_unit_arrays(count: int) -> void:
	_pos.resize(count)
	_vel.resize(count)
	_px.resize(count)
	_py.resize(count)
	_vx.resize(count)
	_vy.resize(count)
	_acc.resize(count)
	_phase.resize(count)
	_hp.resize(count)
	_knockback_timer.resize(count)
	_facing.resize(count)
	_suit_tint.resize(count)
	_wander_angle.resize(count)
	_unit_next.resize(count)
	_u_uid.resize(count)
	_u_city_id.resize(count)
	_u_faction_id.resize(count)
	_u_role.resize(count)
	_u_task.resize(count)
	_u_target_pos.resize(count)
	_u_depot_pos.resize(count)
	_u_flora_idx.resize(count)
	_u_carry_type.resize(count)
	_u_carry_amt.resize(count)
	_u_work_timer.resize(count)
	_u_stuck_timer.resize(count)
	_u_detour_timer.resize(count)
	_u_detour_dir.resize(count)
	_u_detour_side.resize(count)
	_u_last_dist.resize(count)
	_u_rad_exp.resize(count)
	_u_rad_now.resize(count)
	_u_fire_now.resize(count)
	_hit_flash_timer.resize(count)
	_u_attack_cd.resize(count)
	_u_lava_grace.resize(count)
	_u_beacon_pos.resize(count)
	_u_kills.resize(count)
	_u_dodge_cd.resize(count)
	_u_dodges.resize(count)
	_u_sparring_cd.resize(count)
	_u_alert_layer.resize(count)
	_u_glitch_timer.resize(count)
	_u_infected_timer.resize(count)
	_u_corrode_timer.resize(count)
	_u_invuln_timer.resize(count)
	_u_latent_timer.resize(count)
	_u_target_idx.resize(count)
	_u_target_uid.resize(count)
	_u_acq_cd.resize(count)
	_macro_next.resize(count)
	_u_mem_head.resize(count)
	_u_mem_count.resize(count)
	_u_mem_type.resize(count * MEMORY_SLOTS)
	_u_mem_time.resize(count * MEMORY_SLOTS)
	_u_last_tile.resize(count)
	_u_tier.resize(count)
	_u_biome.resize(count)
	_u_temp.resize(count)
	_u_grad_x.resize(count)
	_u_grad_y.resize(count)
	_u_boids_ax.resize(count)
	_u_boids_ay.resize(count)
	_u_wan_ang.resize(count)
	_u_wan_dx.resize(count)
	_u_wan_dy.resize(count)


func _copy_unit_slot(src: int, dst: int) -> void:
	_pos[dst] = _pos[src]
	_vel[dst] = _vel[src]
	_px[dst] = _px[src]
	_py[dst] = _py[src]
	_vx[dst] = _vx[src]
	_vy[dst] = _vy[src]
	_acc[dst] = _acc[src]
	_phase[dst] = _phase[src]
	_hp[dst] = _hp[src]
	_knockback_timer[dst] = _knockback_timer[src]
	_facing[dst] = _facing[src]
	_suit_tint[dst] = _suit_tint[src]
	_wander_angle[dst] = _wander_angle[src]
	_unit_next[dst] = _unit_next[src]
	_u_uid[dst] = _u_uid[src]
	_u_city_id[dst] = _u_city_id[src]
	_u_faction_id[dst] = _u_faction_id[src]
	_u_role[dst] = _u_role[src]
	_u_task[dst] = _u_task[src]
	_u_target_pos[dst] = _u_target_pos[src]
	_u_depot_pos[dst] = _u_depot_pos[src]
	_u_flora_idx[dst] = _u_flora_idx[src]
	_u_carry_type[dst] = _u_carry_type[src]
	_u_carry_amt[dst] = _u_carry_amt[src]
	_u_work_timer[dst] = _u_work_timer[src]
	_u_stuck_timer[dst] = _u_stuck_timer[src]
	_u_detour_timer[dst] = _u_detour_timer[src]
	_u_detour_dir[dst] = _u_detour_dir[src]
	_u_detour_side[dst] = _u_detour_side[src]
	_u_last_dist[dst] = _u_last_dist[src]
	_u_rad_exp[dst] = _u_rad_exp[src]
	_u_rad_now[dst] = _u_rad_now[src]
	_u_fire_now[dst] = _u_fire_now[src]
	_hit_flash_timer[dst] = _hit_flash_timer[src]
	_u_attack_cd[dst] = _u_attack_cd[src]
	_u_lava_grace[dst] = _u_lava_grace[src]
	_u_beacon_pos[dst] = _u_beacon_pos[src]
	_u_kills[dst] = _u_kills[src]
	_u_dodge_cd[dst] = _u_dodge_cd[src]
	_u_dodges[dst] = _u_dodges[src]
	_u_sparring_cd[dst] = _u_sparring_cd[src]
	_u_alert_layer[dst] = _u_alert_layer[src]
	_u_glitch_timer[dst] = _u_glitch_timer[src]
	_u_infected_timer[dst] = _u_infected_timer[src]
	_u_corrode_timer[dst] = _u_corrode_timer[src]
	_u_invuln_timer[dst] = _u_invuln_timer[src]
	_u_latent_timer[dst] = _u_latent_timer[src]
	_u_target_idx[dst] = _u_target_idx[src]
	_u_target_uid[dst] = _u_target_uid[src]
	_u_acq_cd[dst] = _u_acq_cd[src]
	_u_mem_head[dst] = _u_mem_head[src]
	_u_mem_count[dst] = _u_mem_count[src]
	var mem_s := src * MEMORY_SLOTS
	var mem_d := dst * MEMORY_SLOTS
	for m in range(MEMORY_SLOTS):
		_u_mem_type[mem_d + m] = _u_mem_type[mem_s + m]
		_u_mem_time[mem_d + m] = _u_mem_time[mem_s + m]
	_u_last_tile[dst] = _u_last_tile[src]
	_u_tier[dst] = _u_tier[src]
	_u_biome[dst] = _u_biome[src]
	_u_temp[dst] = _u_temp[src]
	_u_grad_x[dst] = _u_grad_x[src]
	_u_grad_y[dst] = _u_grad_y[src]
	_u_boids_ax[dst] = _u_boids_ax[src]
	_u_boids_ay[dst] = _u_boids_ay[src]
	_u_wan_ang[dst] = _u_wan_ang[src]
	_u_wan_dx[dst] = _u_wan_dx[src]
	_u_wan_dy[dst] = _u_wan_dy[src]


func _compute_worker_tint(city_col: Color, role: int, faction_id: int = FACTION_HUMAN) -> Color:
	if role == ROLE_MUTANT or faction_id == FACTION_MUTANT:
		return Color(0.88, 0.44, 0.94, 1.0)
	var role_col: Color = ROLE_TINTS[clampi(role, 0, ROLE_TINTS.size() - 1)]
	var blend_w := 0.46 if faction_id == FACTION_HUMAN else 0.30
	var tinted := city_col.lerp(role_col, blend_w)
	# Keep albedo <= 0.94 so non-emissive surfaces respect HDR threshold 1.0
	return Color(
		minf(tinted.r, 0.94),
		minf(tinted.g, 0.94),
		minf(tinted.b, 0.94),
		1.0
	)


func _init_unit_slot(idx: int, pos_val: Vector2, city_id: int, faction_id: int, role: int, depot_pos: Vector2, tint: Color) -> void:
	var base_speed: float = TUNING_KNOBS["COLONIST_SPEED"]
	var ang := _rng.randf_range(0.0, TAU)
	var ca := cos(ang)
	var sa := sin(ang)
	var spd0 := base_speed * _rng.randf_range(0.75, 1.15)
	var vx0 := ca * spd0
	var vy0 := sa * spd0
	var uid := _next_uid
	_next_uid += 1
	_u_uid[idx] = uid
	_uid_to_idx[uid] = idx

	_pos[idx] = pos_val
	_px[idx] = pos_val.x
	_py[idx] = pos_val.y
	_wander_angle[idx] = ang
	_u_wan_ang[idx] = ang
	_u_wan_dx[idx] = ca
	_u_wan_dy[idx] = sa
	_vel[idx] = Vector2(vx0, vy0)
	_vx[idx] = vx0
	_vy[idx] = vy0
	_acc[idx] = Vector2.ZERO
	_phase[idx] = _rng.randf_range(0.0, TAU)
	_hp[idx] = 130.0 if role == ROLE_MUTANT else 100.0
	_knockback_timer[idx] = 0.0
	_facing[idx] = 1.0 if vx0 >= 0.0 else -1.0
	_suit_tint[idx] = tint
	_unit_next[idx] = -1
	_u_city_id[idx] = city_id
	_u_faction_id[idx] = faction_id
	_u_role[idx] = role
	_u_task[idx] = TASK_IDLE
	_u_target_pos[idx] = depot_pos
	_u_depot_pos[idx] = depot_pos
	_u_flora_idx[idx] = -1
	_u_carry_type[idx] = CARRY_NONE
	_u_carry_amt[idx] = 0.0
	_u_work_timer[idx] = 0.0
	_u_stuck_timer[idx] = 0.0
	_u_detour_timer[idx] = 0.0
	_u_detour_dir[idx] = Vector2.ZERO
	_u_detour_side[idx] = 1.0 if (idx & 1) == 0 else -1.0
	_u_last_dist[idx] = 0.0
	_u_rad_exp[idx] = 1.0 if role == ROLE_MUTANT else 0.0
	_u_rad_now[idx] = 0.0
	_u_fire_now[idx] = 0.0
	_hit_flash_timer[idx] = 0.0
	_u_attack_cd[idx] = _rng.randf_range(0.0, 0.25)
	_u_lava_grace[idx] = 2.4 if faction_id == FACTION_ROBOT else 0.0
	_u_beacon_pos[idx] = Vector2(-1.0, -1.0)
	_u_kills[idx] = 0
	_u_dodge_cd[idx] = 0.0
	_u_dodges[idx] = 0
	_u_sparring_cd[idx] = _rng.randf_range(0.6, 4.2)
	_u_alert_layer[idx] = LAYER_ROUTINE
	_u_glitch_timer[idx] = 0.0
	_u_infected_timer[idx] = 0.0
	_u_corrode_timer[idx] = 0.0
	_u_invuln_timer[idx] = 0.0
	_u_latent_timer[idx] = 0.0
	_u_target_idx[idx] = -1
	_u_target_uid[idx] = -1
	_u_acq_cd[idx] = float((idx * 7) % 10) * 0.035
	_macro_next[idx] = -1
	_u_mem_head[idx] = 0
	_u_mem_count[idx] = 0
	var mem_b := idx * MEMORY_SLOTS
	for m in range(MEMORY_SLOTS):
		_u_mem_type[mem_b + m] = 0
		_u_mem_time[mem_b + m] = 0.0
	if role == ROLE_MUTANT:
		_record_memory(idx, MEM_MUTATED)
	elif city_id >= 0:
		_record_memory(idx, MEM_AWOKE)
		_record_memory(idx, MEM_JOINED_COLONY)
	else:
		_record_memory(idx, MEM_AWOKE)
	_u_last_tile[idx] = -1
	_u_tier[idx] = TIER_SOIL_LOW
	_u_biome[idx] = BIOME_RUST
	_u_temp[idx] = 22.0
	_u_grad_x[idx] = 0.0
	_u_grad_y[idx] = 0.0
	_u_boids_ax[idx] = 0.0
	_u_boids_ay[idx] = 0.0


func _record_memory(idx: int, mem_type: int) -> void:
	if idx < 0 or idx >= _unit_count or idx >= _u_mem_head.size():
		return
	if mem_type <= 0 or mem_type >= MEM_NAMES_RU.size():
		return
	var base := idx * MEMORY_SLOTS
	var head := int(_u_mem_head[idx]) % MEMORY_SLOTS
	var cnt := int(_u_mem_count[idx])
	if cnt > 0:
		var prev_slot := (head + MEMORY_SLOTS - 1) % MEMORY_SLOTS
		var prev_idx := base + prev_slot
		if int(_u_mem_type[prev_idx]) == mem_type:
			var dedup_win := 4.5 if (mem_type == MEM_GATHERED or mem_type == MEM_BUILT or mem_type == MEM_FOUGHT) else 0.45
			if (_sim_time - _u_mem_time[prev_idx]) < dedup_win:
				_u_mem_time[prev_idx] = _sim_time
				return
	_u_mem_type[base + head] = mem_type
	_u_mem_time[base + head] = _sim_time
	_u_mem_head[idx] = (head + 1) % MEMORY_SLOTS
	if cnt < MEMORY_SLOTS:
		_u_mem_count[idx] = cnt + 1


func _kill_unit(idx: int, death_cause: int) -> void:
	if idx < 0 or idx >= _unit_count:
		return
	var pos := Vector2(_px[idx], _py[idx])
	var cid := _u_city_id[idx]
	var fac := int(_u_faction_id[idx])
	var role := int(_u_role[idx])

	if cid >= 0 and cid < _city_pop_counts.size():
		_city_pop_counts[cid] = maxi(0, _city_pop_counts[cid] - 1)

	if _fx != null and _impact_fx_cd <= 0.0:
		if death_cause == DEATH_DROWN:
			_fx.spawn_burst(pos, 5, Color(0.55, 0.85, 0.98, 0.88), 22.0, 0.36, 26.0)
		elif role == ROLE_MUTANT:
			_fx.spawn_burst(pos, 8, Color(0.88, 0.42, 1.0, 0.95), 34.0, 0.40, 20.0)
		elif fac == FACTION_ROBOT:
			_fx.emit_spark_arc(pos, Vector2.UP, Color(0.45, 0.90, 1.0, 1.0))
			_fx.spawn_burst(pos, 5, Color(0.48, 0.54, 0.62, 0.85), 24.0, 0.45, 18.0)
		elif fac == FACTION_SPORE:
			_fx.spawn_burst(pos, 7, Color(0.52, 0.96, 0.42, 0.90), 22.0, 0.44, -8.0)
		elif death_cause == DEATH_BURN:
			_fx.spawn_burst(pos, 6, Color(0.98, 0.48, 0.16, 0.92), 26.0, 0.40, -14.0)
		else:
			_fx.spawn_burst(pos, 6, Color(0.76, 0.72, 0.68, 0.85), 24.0, 0.38, 12.0)

	var dead_uid := _u_uid[idx]
	_uid_to_idx.erase(dead_uid)
	if dead_uid == _possessed_uid:
		_possessed_uid = -1
		_possess_move = Vector2.ZERO
		_possess_pulse = false
	var last := _unit_count - 1
	if idx != last:
		_copy_unit_slot(last, idx)
		_uid_to_idx[_u_uid[idx]] = idx
	_unit_count = last
	_death_count += 1
	_spatial_hash_dirty = true
	_unit_colors_dirty = true
	_shadows_dirty = true


func _mutate_unit(idx: int, emit_fx: bool = true) -> void:
	if idx < 0 or idx >= _unit_count:
		return
	if _u_role[idx] == ROLE_MUTANT or _u_faction_id[idx] == FACTION_ROBOT:
		return
	var old_cid := _u_city_id[idx]
	if old_cid >= 0 and old_cid < _city_pop_counts.size():
		_city_pop_counts[old_cid] = maxi(0, _city_pop_counts[old_cid] - 1)
	_u_city_id[idx] = -1
	_u_faction_id[idx] = FACTION_MUTANT
	_u_role[idx] = ROLE_MUTANT
	_u_task[idx] = TASK_IDLE
	_u_flora_idx[idx] = -1
	_u_carry_type[idx] = CARRY_NONE
	_u_carry_amt[idx] = 0.0
	_u_rad_exp[idx] = 1.0
	_hit_flash_timer[idx] = 0.35
	_hp[idx] = 130.0
	_suit_tint[idx] = _compute_worker_tint(Color(0.88, 0.44, 0.94, 1.0), ROLE_MUTANT, FACTION_MUTANT)
	_unit_colors_dirty = true
	_record_memory(idx, MEM_MUTATED)

	if emit_fx and _fx != null:
		var pos := Vector2(_px[idx], _py[idx])
		_fx.emit_spark_arc(pos, Vector2.UP, Color(0.85, 0.42, 1.0, 1.0))
		if _fx.has_method("spawn_reaction_strip") and _strip_fx_budget > 0:
			_strip_fx_budget -= 1
			_fx.call("spawn_reaction_strip", pos + Vector2(0.0, -7.0), STRIP_MUTATE)
		_fx.play_sfx("mutate")


func _spawn_colonists(target_count: int) -> void:
	_unit_count = mini(target_count, MAX_UNITS)
	_uid_to_idx.clear()
	_next_uid = 1
	_resize_unit_arrays(_unit_count)
	_city_pop_counts.resize(MAX_CITIES)
	_city_pop_counts.fill(0)

	var palette_len := SUIT_PALETTE.size()
	var fallback_spots: Array[Vector2] = []

	for i in range(_unit_count):
		var spawned_pos := Vector2(-1.0, -1.0)
		for _try in range(96):
			var px := _rng.randi_range(6, _map_w - 7)
			var py := _rng.randi_range(6, _map_h - 7)
			if _is_safe_spawn_tile(px, py):
				spawned_pos = Vector2(float(px) + _rng.randf_range(0.15, 0.85), float(py) + _rng.randf_range(0.15, 0.85))
				fallback_spots.append(spawned_pos)
				break
		if spawned_pos.x < 0.0:
			if not fallback_spots.is_empty():
				spawned_pos = fallback_spots[i % fallback_spots.size()]
			else:
				spawned_pos = _find_land_pos(true)

		_init_unit_slot(i, spawned_pos, -1, FACTION_NONE, ROLE_FREE, spawned_pos, SUIT_PALETTE[i % palette_len])

	_mm_units.multimesh.instance_count = MAX_UNITS
	_mm_units.multimesh.visible_instance_count = _unit_count
	_unit_colors_dirty = true
	_rebuild_spatial_hash()


func spawn_colony_units(city_id: int, world_pos: Vector2, count: int = 16) -> int:
	_ensure_layers()
	if city_id < 0 or city_id >= MAX_CITIES:
		return 0
	if _city_pop_counts.size() < MAX_CITIES:
		_city_pop_counts.resize(MAX_CITIES)
		_city_pop_counts.fill(0)
	if _civ != null and _civ.has_method("get_goal_buffers") and (city_id >= _city_depot_pos.size() or _city_depot_pos.is_empty()):
		var bufs: Variant = _civ.call("get_goal_buffers")
		if bufs is Dictionary:
			set_goal_buffers(bufs as Dictionary)

	var faction_id: int = int(_city_faction[city_id]) if city_id < _city_faction.size() else FACTION_HUMAN
	var city_col: Color = _city_color[city_id] if city_id < _city_color.size() else SUIT_PALETTE[0]
	var depot_pos: Vector2 = _city_depot_pos[city_id] if (city_id < _city_depot_pos.size() and _city_depot_pos[city_id].x >= 0.0) else world_pos

	var req := clampi(count, 1, 256)
	var free_idx: Array[int] = []
	var free_d2: Array[float] = []
	for i in range(_unit_count):
		if _u_city_id[i] < 0 and _u_role[i] == ROLE_FREE:
			var dx := _px[i] - depot_pos.x
			var dy := _py[i] - depot_pos.y
			free_idx.append(i)
			free_d2.append(dx * dx + dy * dy)

	# Recruit closest free Wanderers first (partial selection pass, O(free * req))
	var chosen: PackedInt32Array = PackedInt32Array()
	var n_free := free_idx.size()
	var n_recruit := mini(req, n_free)
	for _pick in range(n_recruit):
		var best_k := -1
		var best_d2 := 1e18
		for k in range(n_free):
			var cand_d2 := free_d2[k]
			if cand_d2 >= 0.0 and cand_d2 < best_d2:
				best_d2 = cand_d2
				best_k = k
		if best_k < 0:
			break
		chosen.append(free_idx[best_k])
		free_d2[best_k] = -1.0

	var recruited_n := chosen.size()
	var rem_needed := req - recruited_n
	var old_count := _unit_count
	var append_n := mini(rem_needed, MAX_UNITS - old_count)
	var total_spawned := recruited_n + append_n
	if total_spawned <= 0:
		return 0

	# 1) Convert recruited Wanderers first (keep local nearby wanderers in place!)
	for r_i in range(recruited_n):
		var idx := chosen[r_i]
		var role := _pick_faction_role(faction_id, idx)
		var cur_p := Vector2(_px[idx], _py[idx])
		var keep_local := cur_p.distance_squared_to(depot_pos) <= (64.0 * 64.0) and _is_walkable_pos(cur_p) and _count_water_hits(cur_p, depot_pos) < 2
		var dest_pt := cur_p if keep_local else _find_walkable_near(depot_pos, 10.0)
		_px[idx] = dest_pt.x
		_py[idx] = dest_pt.y
		_pos[idx] = dest_pt
		_u_city_id[idx] = city_id
		_u_faction_id[idx] = faction_id
		_u_role[idx] = role
		_u_task[idx] = TASK_IDLE
		_u_depot_pos[idx] = depot_pos
		_u_target_pos[idx] = depot_pos
		_u_flora_idx[idx] = -1
		_u_carry_type[idx] = CARRY_NONE
		_u_carry_amt[idx] = 0.0
		_u_lava_grace[idx] = 2.4 if faction_id == FACTION_ROBOT else 0.0
		_hit_flash_timer[idx] = 0.25
		_u_last_tile[idx] = -1
		_u_glitch_timer[idx] = 0.0
		_u_infected_timer[idx] = 0.0
		_u_corrode_timer[idx] = 0.0
		_u_invuln_timer[idx] = 0.0
		_u_latent_timer[idx] = 0.0
		_u_target_idx[idx] = -1
		_u_target_uid[idx] = -1
		_u_acq_cd[idx] = float((idx * 7) % 10) * 0.035
		_suit_tint[idx] = _compute_worker_tint(city_col, role, faction_id)
		_city_pop_counts[city_id] += 1
		_record_memory(idx, MEM_JOINED_COLONY)
		_assign_worker_goal(idx, city_id)

	# 2) Append remaining fresh slots up to MAX_UNITS
	if append_n > 0:
		_unit_count = old_count + append_n
		_resize_unit_arrays(_unit_count)
		for k in range(append_n):
			var idx := old_count + k
			var role := _pick_faction_role(faction_id, idx)
			var spawn_pt := _find_walkable_near(depot_pos, 10.0)
			_init_unit_slot(idx, spawn_pt, city_id, faction_id, role, depot_pos, _compute_worker_tint(city_col, role, faction_id))
			_city_pop_counts[city_id] += 1
			_assign_worker_goal(idx, city_id)

	_mm_units.multimesh.instance_count = MAX_UNITS
	_mm_units.multimesh.visible_instance_count = _unit_count
	_unit_colors_dirty = true
	_spatial_hash_dirty = true
	_sync_unit_multimesh()
	return total_spawned


func release_city_units(city_id: int) -> int:
	if city_id < 0 or city_id >= MAX_CITIES:
		return 0
	var released := 0
	var palette_len := SUIT_PALETTE.size()
	for i in range(_unit_count):
		if _u_city_id[i] == city_id:
			_u_city_id[i] = -1
			_u_faction_id[i] = FACTION_NONE
			_u_role[i] = ROLE_FREE
			_u_task[i] = TASK_IDLE
			_u_flora_idx[i] = -1
			_u_carry_type[i] = CARRY_NONE
			_u_carry_amt[i] = 0.0
			_u_work_timer[i] = 0.0
			_u_stuck_timer[i] = 0.0
			_u_detour_timer[i] = 0.0
			_suit_tint[i] = SUIT_PALETTE[i % palette_len]
			released += 1
	if city_id < _city_pop_counts.size():
		_city_pop_counts[city_id] = 0
	if released > 0:
		_unit_colors_dirty = true
	return released


func get_city_pop(city_id: int) -> int:
	if city_id < 0 or city_id >= _city_pop_counts.size():
		return 0
	return _city_pop_counts[city_id]


func _pick_flora_col_for_tile(tier: int, biome: int, temp: float) -> int:
	if biome == BIOME_CRYSTAL:
		var cr_r := _rng.randf()
		if cr_r < 0.34:
			return FLORA_CRYSTAL_TALL
		if cr_r < 0.68:
			return FLORA_CRYSTAL_SMALL
		return FLORA_CRYSTAL_CLUSTER
	if biome == BIOME_LAVA:
		return FLORA_MAGMA_VENT if _rng.randf() < 0.68 else FLORA_BOULDER
	if biome == BIOME_SCORCHED:
		if temp > 55.0 and _rng.randf() < 0.35:
			return FLORA_MAGMA_VENT
		return FLORA_BOULDER
	if tier >= TIER_MOUNTAINS:
		if temp < 30.0 and tier == TIER_MOUNTAINS and _rng.randf() < 0.40:
			return FLORA_FROST_PINE
		return FLORA_BOULDER
	if tier == TIER_HILLS:
		var r := _rng.randf()
		if r < 0.48:
			return FLORA_BOULDER
		if r < 0.80:
			return FLORA_FROST_PINE
		return FLORA_TREE_LUSH if biome == BIOME_LUSH else FLORA_RUST_SCRUB
	if biome == BIOME_LUSH:
		var lr := _rng.randf()
		if lr < 0.56:
			return FLORA_TREE_LUSH
		if lr < 0.86:
			return FLORA_SHROOM_LUSH
		return FLORA_SPORE_POD
	if tier == TIER_SAND:
		return FLORA_RUST_SCRUB if _rng.randf() < 0.72 else FLORA_BOULDER
	return FLORA_RUST_SCRUB if _rng.randf() < 0.74 else FLORA_BOULDER


func _is_flora_allowed_tile(px: int, py: int) -> bool:
	if _world == null:
		return true
	if px <= 4 or py <= 4 or px >= _map_w - 5 or py >= _map_h - 5:
		return false
	var tier: int = _get_tile_tier(px, py)
	if tier < TIER_SAND or tier >= TIER_SUMMIT:
		return false
	if _get_tile_tier(px - 1, py) <= TIER_SHALLOW or _get_tile_tier(px + 1, py) <= TIER_SHALLOW or _get_tile_tier(px, py - 1) <= TIER_SHALLOW or _get_tile_tier(px, py + 1) <= TIER_SHALLOW:
		return false
	return true


func _is_col_valid_for_biome(col: int, tier: int, biome: int) -> bool:
	if tier < TIER_SAND or tier >= TIER_SUMMIT:
		return false
	if col == FLORA_TREE_CHARRED or col == FLORA_TREE_ASH or col == FLORA_BURNING_BUSH:
		return true
	match biome:
		BIOME_CRYSTAL:
			return col == FLORA_CRYSTAL_SMALL or col == FLORA_CRYSTAL_TALL or col == FLORA_CRYSTAL_CLUSTER
		BIOME_LAVA:
			return col == FLORA_MAGMA_VENT or col == FLORA_BOULDER
		BIOME_SCORCHED:
			return col == FLORA_BOULDER or col == FLORA_MAGMA_VENT
		BIOME_LUSH:
			if tier <= TIER_SOIL_HIGH:
				return col == FLORA_TREE_LUSH or col == FLORA_SHROOM_LUSH or col == FLORA_SPORE_POD or col == FLORA_LUSH_SAPLING
			return col == FLORA_BOULDER or col == FLORA_FROST_PINE or col == FLORA_TREE_LUSH or col == FLORA_LUSH_SAPLING
		_:
			if tier >= TIER_MOUNTAINS:
				return col == FLORA_BOULDER or col == FLORA_FROST_PINE
			return col == FLORA_RUST_SCRUB or col == FLORA_BOULDER or col == FLORA_FROST_PINE or col == FLORA_LUSH_SAPLING


func _is_flammable_flora(col: int) -> bool:
	return col == FLORA_TREE_LUSH or col == FLORA_SHROOM_LUSH or col == FLORA_RUST_SCRUB or col == FLORA_FROST_PINE or col == FLORA_SPORE_POD or col == FLORA_LUSH_SAPLING


func _append_flora_slot(fp: Vector2, col: int, spring_pop: bool = true) -> int:
	if _flora_count >= MAX_FLORA:
		return -1
	var f := _flora_count
	_flora_count += 1
	_flora_pos[f] = fp
	_flora_col[f] = col
	_flora_sway_phase[f] = fp.x * 0.08 + fp.y * 0.04 + _rng.randf_range(0.0, 1.4)
	_flora_shake[f] = 0.0
	_flora_spring[f] = 0.12 if spring_pop else 1.0
	_flora_spring_vel[f] = 2.8 if spring_pop else 0.0
	_flora_burn[f] = 0.0
	_flora_grow[f] = 0.0
	var v := _rng.randf_range(0.92, 1.06)
	_flora_tint[f] = Color(v, v, v, 1.0)
	_flora_active_custom[f] = 1
	if spring_pop:
		_flora_has_anim = true
	_flora_hash_dirty = true
	_flora_dirty_all = true
	if _mm_flora != null and _mm_flora.multimesh != null:
		_mm_flora.multimesh.visible_instance_count = _flora_count
	return f


func _spawn_flora(target_count: int) -> void:
	_flora_pos.resize(MAX_FLORA)
	_flora_col.resize(MAX_FLORA)
	_flora_sway_phase.resize(MAX_FLORA)
	_flora_shake.resize(MAX_FLORA)
	_flora_spring.resize(MAX_FLORA)
	_flora_spring_vel.resize(MAX_FLORA)
	_flora_burn.resize(MAX_FLORA)
	_flora_grow.resize(MAX_FLORA)
	_flora_tint.resize(MAX_FLORA)
	_flora_active_custom.resize(MAX_FLORA)
	_flora_active_custom.fill(0)
	_flora_burn.fill(0.0)
	_flora_grow.fill(0.0)

	var positions: Array[Vector2] = []
	var cols: Array[int] = []
	var goal_n := clampi(target_count, 0, MAX_FLORA)
	var attempts := 0
	var max_attempts := goal_n * 25

	while positions.size() < goal_n and attempts < max_attempts:
		attempts += 1
		var px := _rng.randi_range(6, _map_w - 7)
		var py := _rng.randi_range(6, _map_h - 7)
		if not _is_flora_allowed_tile(px, py):
			continue
		if _bld_count > 0 and _is_inside_any_building(Vector2(float(px) + 0.5, float(py) + 0.5), 5.0):
			continue
		var tier: int = _world.get_tier(px, py) if _world != null else TIER_SOIL_LOW
		var biome: int = _world.get_biome(px, py) if _world != null else BIOME_LUSH
		if tier == TIER_SAND and _rng.randf() > 0.35:
			continue
		var temp: float = _world.get_temp(px, py) if _world != null else 22.0
		positions.append(Vector2(float(px) + 0.5, float(py) + 0.5))
		cols.append(_pick_flora_col_for_tile(tier, biome, temp))

	_flora_count = positions.size()
	# Insertion-sort index order by Y for clean 2.5D painter overlap without lambda allocations
	var idx_arr: PackedInt32Array = PackedInt32Array()
	idx_arr.resize(_flora_count)
	for i in range(_flora_count):
		idx_arr[i] = i
	for i in range(1, _flora_count):
		var key := idx_arr[i]
		var ky := positions[key].y
		var j := i - 1
		while j >= 0 and positions[idx_arr[j]].y > ky:
			idx_arr[j + 1] = idx_arr[j]
			j -= 1
		idx_arr[j + 1] = key

	for out_i in range(_flora_count):
		var src_i := idx_arr[out_i]
		var fp := positions[src_i]
		_flora_pos[out_i] = fp
		_flora_col[out_i] = cols[src_i]
		_flora_sway_phase[out_i] = fp.x * 0.08 + fp.y * 0.04 + _rng.randf_range(0.0, 1.4)
		_flora_shake[out_i] = 0.0
		_flora_spring[out_i] = 1.0
		_flora_spring_vel[out_i] = 0.0
		_flora_burn[out_i] = 0.0
		_flora_grow[out_i] = 0.0
		var v := _rng.randf_range(0.92, 1.06)
		_flora_tint[out_i] = Color(v, v, v, 1.0)
		_flora_active_custom[out_i] = 1

	_flora_sync_cursor = 0
	_flora_hash_dirty = true
	_flora_dirty_all = true
	_mm_flora.multimesh.instance_count = MAX_FLORA
	_mm_flora.multimesh.visible_instance_count = _flora_count


func sync_flora_region(rect: Rect2i) -> void:
	_ensure_layers()
	_invalidate_tc_rect_i(rect)
	if _world == null:
		return
	var r := rect.grow(2)
	var x0 := clampi(r.position.x, 5, _map_w - 6)
	var y0 := clampi(r.position.y, 5, _map_h - 6)
	var x1 := clampi(r.position.x + r.size.x, 5, _map_w - 6)
	var y1 := clampi(r.position.y + r.size.y, 5, _map_h - 6)
	if x1 < x0 or y1 < y0:
		return

	var has_env := _world.has_method("get_tile_env")
	var has_moist := _world.has_method("get_moisture")
	if _flora_count > 0 and _grid_w > 0 and _grid_h > 0 and _flora_cell_head.size() >= _grid_w * _grid_h:
		if _flora_hash_dirty:
			_rebuild_flora_hash()
		var fx0 := clampi(x0 >> 4, 0, _grid_w - 1)
		var fx1 := clampi(x1 >> 4, 0, _grid_w - 1)
		var fy0 := clampi(y0 >> 4, 0, _grid_h - 1)
		var fy1 := clampi(y1 >> 4, 0, _grid_h - 1)
		for cy in range(fy0, fy1 + 1):
			var row_off := cy * _grid_w
			for cx in range(fx0, fx1 + 1):
				var f := _flora_cell_head[row_off + cx]
				while f != -1:
					var fp := _flora_pos[f]
					var fx_i := int(fp.x)
					var fy_i := int(fp.y)
					if fx_i >= x0 and fx_i <= x1 and fy_i >= y0 and fy_i <= y1:
						_sync_single_flora(f, false)
					f = _flora_next[f]

	# Dynamic planting/regrowth on fertile crystal, lush, or ash tiles up to MAX_FLORA
	if _flora_count < MAX_FLORA:
		var area := (x1 - x0 + 1) * (y1 - y0 + 1)
		var samples := clampi(area / 64, 1, 6)
		var existing_near := 0
		for _s in range(samples):
			if _flora_count >= MAX_FLORA:
				break
			var sx := _rng.randi_range(x0, x1)
			var sy := _rng.randi_range(y0, y1)
			if not _is_flora_allowed_tile(sx, sy):
				continue
			var cand := Vector2(float(sx) + 0.5, float(sy) + 0.5)
			if _bld_count > 0 and _is_inside_any_building(cand, 5.0):
				continue
			var biome: int = _world.get_biome(sx, sy)
			var env: Vector4 = _world.get_tile_env(sx, sy) if has_env else Vector4(_world.get_temp(sx, sy), 0.0, 0.0, 0.0)
			if env.z > 0.10 or biome == BIOME_LAVA or env.x > 65.0:
				continue
			var moist: float = float(_world.get_moisture(sx, sy)) if has_moist else 0.35
			var ash_v: float = env.w
			if biome != BIOME_CRYSTAL and biome != BIOME_LUSH and ash_v < 0.15 and moist < 0.45:
				continue
			if existing_near == 0 and _flora_count > 0:
				var crowded := false
				for f2 in range(maxi(0, _flora_count - 120), _flora_count):
					if _flora_pos[f2].distance_squared_to(cand) < 20.0:
						crowded = true
						break
				if crowded:
					continue
			var col := FLORA_CRYSTAL_CLUSTER if biome == BIOME_CRYSTAL else (FLORA_LUSH_SAPLING if (ash_v >= 0.15 or moist >= 0.50) else _pick_flora_col_for_tile(_get_tile_tier(sx, sy), biome, env.x))
			_append_flora_slot(cand, col, true)
			existing_near += 1
	if _flora_dirty_all:
		_sync_flora_multimesh()


func _rebuild_flora_hash() -> void:
	_flora_hash_dirty = false
	_flora_cell_head.fill(-1)
	_flora_next.resize(_flora_count)
	_flora_next.fill(-1)
	for f in range(_flora_count):
		var fp := _flora_pos[f]
		var cx := clampi(int(fp.x) >> 4, 0, _grid_w - 1)
		var cy := clampi(int(fp.y) >> 4, 0, _grid_h - 1)
		var c := cy * _grid_w + cx
		_flora_next[f] = _flora_cell_head[c]
		_flora_cell_head[c] = f


func _is_walkable_tile(px: int, py: int) -> bool:
	if px < 2 or px >= _map_w - 2 or py < 2 or py >= _map_h - 2:
		return false
	if _world == null:
		return true
	var t: int = _get_tile_tier(px, py)
	return t >= TIER_SAND and t < TIER_SUMMIT


func _is_walkable_pos(p: Vector2) -> bool:
	return _is_walkable_tile(int(p.x), int(p.y))


func _count_water_hits(a: Vector2, b: Vector2) -> int:
	if _world == null:
		return 0
	var hits := 0
	for s in range(1, 4):
		var t := float(s) * 0.25
		var p := a.lerp(b, t)
		var px := clampi(int(p.x), 0, _map_w - 1)
		var py := clampi(int(p.y), 0, _map_h - 1)
		var tier: int = _get_tile_tier(px, py)
		if tier < TIER_SAND or tier >= TIER_SUMMIT:
			hits += 1
	return hits


func _find_walkable_near(center: Vector2, max_r: float) -> Vector2:
	var c_clamped := Vector2(
		clampf(center.x, 4.0, float(_map_w - 5)),
		clampf(center.y, 4.0, float(_map_h - 5))
	)
	if _world == null:
		var a := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(2.0, maxf(3.0, max_r))
		return Vector2(
			clampf(c_clamped.x + cos(a) * r, 4.0, float(_map_w - 5)),
			clampf(c_clamped.y + sin(a) * r, 4.0, float(_map_h - 5))
		)
	for attempt in range(20):
		var a := float(attempt) * 2.399963 + _rng.randf_range(-0.3, 0.3)
		var r := _rng.randf_range(2.0, maxf(3.0, max_r))
		var cand := Vector2(
			clampf(c_clamped.x + cos(a) * r, 4.0, float(_map_w - 5)),
			clampf(c_clamped.y + sin(a) * r, 4.0, float(_map_h - 5))
		)
		var px := int(cand.x)
		var py := int(cand.y)
		if _is_safe_spawn_tile(px, py) and _count_water_hits(c_clamped, cand) == 0 and not _is_inside_any_building(cand, 2.0):
			return cand
	for attempt2 in range(12):
		var a2 := float(attempt2) * (TAU / 12.0)
		var cand2 := Vector2(
			clampf(c_clamped.x + cos(a2) * 8.0, 4.0, float(_map_w - 5)),
			clampf(c_clamped.y + sin(a2) * 8.0, 4.0, float(_map_h - 5))
		)
		if _is_walkable_pos(cand2) and not _is_inside_any_building(cand2, 1.0):
			return cand2
	var safe_ring := _find_dry_landing_spots(c_clamped, 40.0, 1)
	if not safe_ring.is_empty():
		return safe_ring[0]
	return c_clamped


func _is_strictly_dry_land_tile(px: int, py: int) -> bool:
	if px < 4 or px >= _map_w - 4 or py < 4 or py >= _map_h - 4:
		return false
	if _world == null:
		return true
	if _world.has_method("is_water") and _world.is_water(px, py):
		return false
	var t: int = _get_tile_tier(px, py)
	if t <= TIER_SHALLOW or t >= TIER_SUMMIT:
		return false
	if _world.has_method("get_biome") and int(_world.get_biome(px, py)) == BIOME_LAVA:
		return false
	return true


func _find_dry_landing_spots(center: Vector2, max_r: float, needed: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	if needed <= 0:
		return out
	var c := Vector2(
		clampf(center.x, 4.0, float(_map_w - 5)),
		clampf(center.y, 4.0, float(_map_h - 5))
	)
	var min_sep2 := 9.0
	var max_rad := maxf(max_r, 8.0)
	var rad := 2.0
	while rad <= max_rad and out.size() < needed:
		var steps := maxi(8, int(round(rad * 1.3)))
		for s in range(steps):
			var ang := float(s) * (TAU / float(steps)) + rad * 0.37
			var cand := Vector2(
				clampf(c.x + cos(ang) * rad, 4.0, float(_map_w - 5)),
				clampf(c.y + sin(ang) * rad, 4.0, float(_map_h - 5))
			)
			var px := int(cand.x)
			var py := int(cand.y)
			if not _is_strictly_dry_land_tile(px, py):
				continue
			if _is_inside_any_building(cand, 2.5):
				continue
			var too_close := false
			for e in out:
				if cand.distance_squared_to(e) < min_sep2:
					too_close = true
					break
			if too_close:
				continue
			out.append(cand)
			if out.size() >= needed:
				return out
		rad += 3.5
	# Second pass without min-spacing constraint so tight islands still work safely
	if out.size() < needed:
		var rad2 := 1.0
		while rad2 <= max_rad and out.size() < needed:
			for s2 in range(16):
				var ang2 := float(s2) * (TAU / 16.0) + rad2 * 0.21
				var cand2 := Vector2(
					clampf(c.x + cos(ang2) * rad2, 4.0, float(_map_w - 5)),
					clampf(c.y + sin(ang2) * rad2, 4.0, float(_map_h - 5))
				)
				if _is_strictly_dry_land_tile(int(cand2.x), int(cand2.y)) and not _is_inside_any_building(cand2, 1.5):
					out.append(cand2)
					if out.size() >= needed:
						return out
			rad2 += 3.0
	return out


func _find_walkable_offset(anchor: Vector2, min_r: float, max_r: float, prefer_lush: bool) -> Vector2:
	var best := anchor
	var best_score := -1.0
	for attempt in range(12):
		var a := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(min_r, max_r)
		var cand := Vector2(
			clampf(anchor.x + cos(a) * r, 4.0, float(_map_w - 5)),
			clampf(anchor.y + sin(a) * r, 4.0, float(_map_h - 5))
		)
		var px := int(cand.x)
		var py := int(cand.y)
		if not _is_walkable_tile(px, py):
			continue
		if _count_water_hits(anchor, cand) > 0:
			continue
		if _is_inside_any_building(cand, 2.0):
			continue
		var score := 1.0
		if _world != null:
			var biome: int = _world.get_biome(px, py)
			var tier: int = _world.get_tier(px, py)
			if biome == BIOME_LAVA or _world.get_temp(px, py) > 65.0:
				continue
			if prefer_lush and biome == BIOME_LUSH:
				score += 4.0
			elif not prefer_lush and (tier >= TIER_HILLS or biome == BIOME_CRYSTAL):
				score += 4.0
		if score > best_score:
			best_score = score
			best = cand
			if score >= 5.0:
				return best
	return best


func _find_nearest_flora(unit_idx: int, anchor: Vector2, want_mineral: bool, max_radius: float) -> int:
	if _flora_count <= 0:
		return -1
	if _flora_hash_dirty:
		_rebuild_flora_hash()

	var cr := clampi(ceili(max_radius / float(_cell_size)), 1, 6)
	var acx := clampi(int(anchor.x) >> 4, 0, _grid_w - 1)
	var acy := clampi(int(anchor.y) >> 4, 0, _grid_h - 1)
	var x0 := maxi(0, acx - cr)
	var x1 := mini(_grid_w - 1, acx + cr)
	var y0 := maxi(0, acy - cr)
	var y1 := mini(_grid_h - 1, acy + cr)
	var max_r2 := max_radius * max_radius
	var unit_pos := Vector2(_px[unit_idx], _py[unit_idx])

	var best_f := -1
	var best_score := 1e18

	for cy in range(y0, y1 + 1):
		var row_off := cy * _grid_w
		for cx in range(x0, x1 + 1):
			var f := _flora_cell_head[row_off + cx]
			while f != -1:
				var col := _flora_col[f]
				var match_kind := false
				if want_mineral:
					match_kind = (col == FLORA_CRYSTAL_SMALL or col == FLORA_CRYSTAL_TALL or col == FLORA_CRYSTAL_CLUSTER or col == FLORA_BOULDER)
				else:
					match_kind = (col == FLORA_TREE_LUSH or col == FLORA_SHROOM_LUSH or col == FLORA_RUST_SCRUB or col == FLORA_FROST_PINE or col == FLORA_SPORE_POD or col == FLORA_LUSH_SAPLING)
				if match_kind:
					var fp := _flora_pos[f]
					var d2 := (fp - anchor).length_squared()
					if d2 <= max_r2:
						var water_hits := _count_water_hits(unit_pos, fp)
						if water_hits < 2:
							var spread := float((unit_idx * 17 + f * 31) & 15) * 18.0
							var spore_bonus := -140.0 if (_u_faction_id[unit_idx] == FACTION_SPORE and (col == FLORA_SPORE_POD or col == FLORA_SHROOM_LUSH)) else 0.0
							var score := d2 + float(water_hits) * 900.0 + spread + spore_bonus
							if score < best_score:
								best_score = score
								best_f = f
				f = _flora_next[f]
	return best_f


func _rebuild_spatial_hash() -> void:
	_spatial_hash_dirty = false
	_cell_head.fill(-1)
	if _macro_pop.size() > 0:
		_macro_pop.fill(0)
	if _macro_head.size() > 0:
		_macro_head.fill(-1)
	var grid_w_m1 := _grid_w - 1
	var grid_h_m1 := _grid_h - 1
	var grid_w_i := _grid_w
	var macro_w_m1 := maxi(0, _macro_w - 1)
	var macro_h_m1 := maxi(0, _macro_h - 1)
	var macro_w_i := _macro_w
	var has_macro := (_macro_pop.size() >= _macro_w * _macro_h and _macro_head.size() >= _macro_w * _macro_h and _macro_next.size() >= _unit_count)
	for i in range(_unit_count):
		var cx := clampi(int(_px[i]) >> 4, 0, grid_w_m1)
		var cy := clampi(int(_py[i]) >> 4, 0, grid_h_m1)
		var c := cy * grid_w_i + cx
		_unit_next[i] = _cell_head[c]
		_cell_head[c] = i
		if has_macro:
			var mcx := mini(cx >> 2, macro_w_m1)
			var mcy := mini(cy >> 2, macro_h_m1)
			var m_idx := mcy * macro_w_i + mcx
			_macro_pop[m_idx] += 1
			_macro_next[i] = _macro_head[m_idx]
			_macro_head[m_idx] = i


func trigger_impulse(world_pos: Vector2, radius: float, force: float, is_meteor: bool) -> void:
	_ensure_layers()
	if radius <= 0.5:
		return
	_rebuild_spatial_hash()

	var min_cx := clampi(int(world_pos.x - radius) >> 4, 0, _grid_w - 1)
	var max_cx := clampi(int(world_pos.x + radius) >> 4, 0, _grid_w - 1)
	var min_cy := clampi(int(world_pos.y - radius) >> 4, 0, _grid_h - 1)
	var max_cy := clampi(int(world_pos.y + radius) >> 4, 0, _grid_h - 1)
	var r2 := radius * radius

	for cy in range(min_cy, max_cy + 1):
		var row_off := cy * _grid_w
		for cx in range(min_cx, max_cx + 1):
			var idx := _cell_head[row_off + cx]
			while idx != -1:
				var diff := Vector2(_px[idx] - world_pos.x, _py[idx] - world_pos.y)
				var d2 := diff.length_squared()
				if d2 <= r2:
					var dist := sqrt(d2)
					var dir := Vector2.ZERO
					if dist < 0.5:
						var a := float(idx) * 2.399963
						dir = Vector2(cos(a), sin(a))
					else:
						dir = diff / dist
					var falloff := clampf(10.0 / maxf(dist, 6.0), 0.15, 1.4) * (1.0 - dist / radius)
					var nvx := _vx[idx] + dir.x * (force * falloff)
					var nvy := _vy[idx] + dir.y * (force * falloff)
					_vx[idx] = nvx
					_vy[idx] = nvy
					_vel[idx] = Vector2(nvx, nvy)
					_knockback_timer[idx] = maxf(_knockback_timer[idx], 0.35 + 0.55 * clampf(falloff, 0.0, 1.0))
					_facing[idx] = 1.0 if nvx >= 0.0 else -1.0
					if is_meteor and dist < radius * 0.55:
						var blast_dmg := (1.0 - dist / (radius * 0.55)) * 42.0
						_hp[idx] -= blast_dmg
						_hit_flash_timer[idx] = maxf(_hit_flash_timer[idx], 0.25)
				idx = _unit_next[idx]

	# Shake, scorch, and update nearby flora inside impact zone
	var flora_r2 := (radius * 1.45) * (radius * 1.45)
	for f in range(_flora_count):
		var fd2 := (_flora_pos[f] - world_pos).length_squared()
		if fd2 <= flora_r2:
			var fdist := sqrt(fd2)
			var strength := clampf(1.0 - fdist / (radius * 1.45), 0.15, 1.0)
			_flora_shake[f] = maxf(_flora_shake[f], strength)
			_flora_has_anim = true
			if f < _flora_active_custom.size():
				_flora_active_custom[f] = 1
			if is_meteor and fdist <= radius * 0.72 and _is_flammable_flora(int(_flora_col[f])):
				_flora_burn[f] = float(TUNING_KNOBS["FLORA_BURN_DURATION"]) * _rng.randf_range(0.65, 1.0)
				_flora_col[f] = FLORA_BURNING_BUSH if _flora_col[f] == FLORA_RUST_SCRUB else FLORA_TREE_CHARRED
				_flora_dirty_all = true
			elif fdist <= radius * 0.9:
				_sync_single_flora(f, is_meteor)

	if is_meteor:
		impact_trauma.emit(TUNING_KNOBS["METEOR_TRAUMA"], TUNING_KNOBS["METEOR_HIT_STOP"])
		if _fx != null:
			_fx.spawn_shockwave(world_pos, radius * 1.15, Color(1.0, 0.62, 0.22, 1.0))
			_fx.spawn_burst(world_pos, 32, Color(1.0, 0.45, 0.12, 1.0), 85.0, 0.65, 65.0)
			_fx.spawn_burst(world_pos, 14, Color(0.88, 0.82, 0.76, 0.72), 28.0, 0.75, -18.0)
			_fx.play_sfx("meteor")
	else:
		impact_trauma.emit(0.14, 0.03)
		if _fx != null:
			_fx.spawn_shockwave(world_pos, radius * 0.85, Color(0.35, 0.92, 1.0, 1.0))
			_fx.spawn_burst(world_pos, 16, Color(0.45, 0.92, 1.0, 0.95), 48.0, 0.45, 20.0)
			_fx.play_sfx("terraform")


func apply_vortex(world_pos: Vector2, radius: float, strength: float, dt: float) -> void:
	_ensure_layers()
	if radius <= 1.0 or dt <= 0.0:
		return
	_rebuild_spatial_hash()

	var min_cx := clampi(int(world_pos.x - radius) >> 4, 0, _grid_w - 1)
	var max_cx := clampi(int(world_pos.x + radius) >> 4, 0, _grid_w - 1)
	var min_cy := clampi(int(world_pos.y - radius) >> 4, 0, _grid_h - 1)
	var max_cy := clampi(int(world_pos.y + radius) >> 4, 0, _grid_h - 1)
	var r2 := radius * radius

	for cy in range(min_cy, max_cy + 1):
		var row_off := cy * _grid_w
		for cx in range(min_cx, max_cx + 1):
			var idx := _cell_head[row_off + cx]
			while idx != -1:
				var to_center := Vector2(world_pos.x - _px[idx], world_pos.y - _py[idx])
				var d2 := to_center.length_squared()
				if d2 <= r2:
					var dist := sqrt(d2)
					var dir_in := Vector2.ZERO if dist < 0.25 else to_center / dist
					var tangent := Vector2(-dir_in.y, dir_in.x)
					var falloff := 0.25 + 0.75 * (1.0 - dist / radius)
					var accel := (tangent * 1.45 + dir_in * 0.85) * strength * falloff
					var nvel := Vector2(_vx[idx], _vy[idx]) + accel * dt
					var max_vortex_spd := maxf(absf(strength) * 0.65, 65.0)
					if nvel.length_squared() > max_vortex_spd * max_vortex_spd:
						nvel = nvel.normalized() * max_vortex_spd
					_vx[idx] = nvel.x
					_vy[idx] = nvel.y
					_vel[idx] = nvel
					_knockback_timer[idx] = maxf(_knockback_timer[idx], 0.16)
					_facing[idx] = 1.0 if nvel.x >= 0.0 else -1.0
				idx = _unit_next[idx]

	var flora_r2 := radius * radius
	for f in range(_flora_count):
		var fd2 := (_flora_pos[f] - world_pos).length_squared()
		if fd2 <= flora_r2:
			_flora_shake[f] = maxf(_flora_shake[f], 0.55)
			_flora_has_anim = true
			if f < _flora_active_custom.size():
				_flora_active_custom[f] = 1

	# Vortex Alchemy: sample dominant terrain element to unleash secondary elemental storms
	if _world != null and _vortex_alchemy_cd <= 0.0 and _world.has_method("sample_dominant_element"):
		_vortex_alchemy_cd = 0.22
		var elem := str(_world.call("sample_dominant_element", world_pos, radius))
		if elem == "water":
			if _world.has_method("apply_elemental_storm"):
				_world.call("apply_elemental_storm", world_pos, radius * 1.15, "rainburst")
			for f in range(_flora_count):
				if (_flora_pos[f] - world_pos).length_squared() <= flora_r2 and _flora_burn[f] > 0.0:
					_flora_burn[f] = 0.0
					_flora_col[f] = FLORA_LUSH_SAPLING
					_flora_dirty_all = true
			for cy in range(min_cy, max_cy + 1):
				var row_off := cy * _grid_w
				for cx in range(min_cx, max_cx + 1):
					var u := _cell_head[row_off + cx]
					while u != -1:
						if Vector2(_px[u] - world_pos.x, _py[u] - world_pos.y).length_squared() <= r2:
							var max_hp := 130.0 if _u_role[u] == ROLE_MUTANT else 100.0
							_hp[u] = minf(max_hp, _hp[u] + 18.0)
							_u_rad_exp[u] = maxf(0.0, _u_rad_exp[u] - 0.15)
						u = _unit_next[u]
			if _fx != null:
				_fx.spawn_burst(world_pos + Vector2(_rng.randf_range(-radius * 0.4, radius * 0.4), _rng.randf_range(-radius * 0.4, radius * 0.4)), 6, Color(0.45, 0.88, 1.0, 0.90), 28.0, 0.42, 42.0)
				_fx.play_sfx("storm")
		elif elem == "lava" or elem == "fire":
			if _world.has_method("apply_elemental_storm"):
				_world.call("apply_elemental_storm", world_pos, radius * 1.15, "firestorm")
			for f in range(_flora_count):
				if (_flora_pos[f] - world_pos).length_squared() <= flora_r2 and _is_flammable_flora(int(_flora_col[f])):
					_flora_burn[f] = float(TUNING_KNOBS["FLORA_BURN_DURATION"]) * 0.85
					_flora_col[f] = FLORA_BURNING_BUSH if _flora_col[f] == FLORA_RUST_SCRUB else FLORA_TREE_CHARRED
					_flora_has_anim = true
					_flora_active_custom[f] = 1
					_flora_dirty_all = true
			if _fx != null:
				_fx.spawn_burst(world_pos + Vector2(_rng.randf_range(-radius * 0.3, radius * 0.3), _rng.randf_range(-radius * 0.3, radius * 0.3)), 8, Color(1.0, 0.48, 0.14, 1.0), 42.0, 0.46, 28.0)
				_fx.play_sfx("storm")
		elif elem == "crystal":
			if _world.has_method("apply_elemental_storm"):
				_world.call("apply_elemental_storm", world_pos, radius * 1.15, "ion_storm")
			var core_r2 := (radius * 0.55) * (radius * 0.55)
			for cy in range(min_cy, max_cy + 1):
				var row_off := cy * _grid_w
				for cx in range(min_cx, max_cx + 1):
					var u := _cell_head[row_off + cx]
					while u != -1:
						var du2 := Vector2(_px[u] - world_pos.x, _py[u] - world_pos.y).length_squared()
						if du2 <= r2:
							if _u_faction_id[u] == FACTION_ROBOT:
								_hp[u] = minf(100.0, _hp[u] + 15.0)
							elif _u_role[u] != ROLE_MUTANT:
								_u_rad_exp[u] += 0.36 if du2 <= core_r2 else 0.18
								if _u_rad_exp[u] >= 1.0 and _rng.randf() < 0.55:
									_mutate_unit(u)
						u = _unit_next[u]
			if _fx != null:
				_fx.emit_spark_arc(world_pos, Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU)), Color(0.55, 0.94, 1.0, 1.0))
				_fx.play_sfx("storm")

	if _fx != null:
		if _fx.has_method("apply_vortex_to_particles"):
			_fx.apply_vortex_to_particles(world_pos, radius, strength, dt)
		if _vortex_fx_cd <= 0.0:
			_vortex_fx_cd = 0.055
			var rim_ang := _rng.randf_range(0.0, TAU)
			var rim_pos := world_pos + Vector2(cos(rim_ang), sin(rim_ang)) * _rng.randf_range(radius * 0.25, radius * 0.75)
			_fx.spawn_burst(rim_pos, 3, Color(0.45, 0.90, 1.0, 0.92), 26.0, 0.38, 0.0)
			_fx.play_sfx("vortex")


func _sync_single_flora(f: int, from_meteor: bool = false) -> void:
	if _world == null:
		return
	var fp := _flora_pos[f]
	var px := clampi(int(fp.x), 0, _map_w - 1)
	var py := clampi(int(fp.y), 0, _map_h - 1)

	if not _is_flora_allowed_tile(px, py) or (_bld_count > 0 and _is_inside_any_building(fp, 4.5)):
		var relocated := false
		for _try in range(24):
			var nx := _rng.randi_range(6, _map_w - 7)
			var ny := _rng.randi_range(6, _map_h - 7)
			if _is_flora_allowed_tile(nx, ny) and not (_bld_count > 0 and _is_inside_any_building(Vector2(float(nx) + 0.5, float(ny) + 0.5), 5.0)):
				_flora_pos[f] = Vector2(float(nx) + 0.5, float(ny) + 0.5)
				var nt: int = _world.get_tier(nx, ny)
				var nb: int = _world.get_biome(nx, ny)
				var ntemp: float = _world.get_temp(nx, ny)
				_flora_col[f] = _pick_flora_col_for_tile(nt, nb, ntemp)
				_flora_spring[f] = 0.08
				_flora_spring_vel[f] = 2.5
				_flora_shake[f] = 0.0
				_flora_burn[f] = 0.0
				_flora_grow[f] = 0.0
				_flora_hash_dirty = true
				_flora_dirty_all = true
				_flora_has_anim = true
				if f < _flora_active_custom.size():
					_flora_active_custom[f] = 1
				relocated = true
				break
		if not relocated and from_meteor:
			_flora_shake[f] = 0.0
			if f < _flora_active_custom.size():
				_flora_active_custom[f] = 1
		return

	var tier: int = _world.get_tier(px, py)
	var biome: int = _world.get_biome(px, py)
	var has_env := _world.has_method("get_tile_env")
	var env: Vector4 = _world.get_tile_env(px, py) if has_env else Vector4(_world.get_temp(px, py), 0.0, 0.0, 0.0)
	var temp := env.x
	var fire_v := env.z
	var cur_col := int(_flora_col[f])

	# Ignite flammable trees near world fire/lava
	if _is_flammable_flora(cur_col) and (fire_v > 0.14 or temp > 75.0 or biome == BIOME_LAVA):
		if _flora_burn[f] <= 0.0:
			_flora_burn[f] = float(TUNING_KNOBS["FLORA_BURN_DURATION"]) * _rng.randf_range(0.75, 1.1)
			_flora_col[f] = FLORA_BURNING_BUSH if cur_col == FLORA_RUST_SCRUB else FLORA_TREE_CHARRED
			_flora_has_anim = true
			_flora_dirty_all = true
			if f < _flora_active_custom.size():
				_flora_active_custom[f] = 1
		return

	if not _is_col_valid_for_biome(cur_col, tier, biome):
		_flora_col[f] = _pick_flora_col_for_tile(tier, biome, temp)
		_flora_burn[f] = 0.0
		_flora_grow[f] = 0.0
		_flora_spring[f] = 0.12
		_flora_spring_vel[f] = 3.2
		_flora_hash_dirty = true
		_flora_dirty_all = true
		_flora_has_anim = true
		if f < _flora_active_custom.size():
			_flora_active_custom[f] = 1


func _find_shore_dir(pos: Vector2) -> Vector2:
	if _world == null:
		return Vector2.ZERO
	for r_step: float in [4.0, 8.0, 14.0, 22.0, 34.0]:
		for k in range(8):
			var ang := float(k) * (TAU / 8.0)
			var probe: Vector2 = pos + Vector2(cos(ang), sin(ang)) * r_step
			var tx := clampi(int(probe.x), 0, _map_w - 1)
			var ty := clampi(int(probe.y), 0, _map_h - 1)
			if not _world.is_water(tx, ty):
				return Vector2(cos(ang), sin(ang))
	return Vector2.ZERO


func _release_single_worker(unit_idx: int, cid: int) -> void:
	if _u_role[unit_idx] == ROLE_MUTANT:
		_u_city_id[unit_idx] = -1
		_u_faction_id[unit_idx] = FACTION_MUTANT
		return
	var palette_len := SUIT_PALETTE.size()
	_u_city_id[unit_idx] = -1
	_u_faction_id[unit_idx] = FACTION_NONE
	_u_role[unit_idx] = ROLE_FREE
	_u_task[unit_idx] = TASK_IDLE
	_u_flora_idx[unit_idx] = -1
	_u_carry_type[unit_idx] = CARRY_NONE
	_u_carry_amt[unit_idx] = 0.0
	_u_work_timer[unit_idx] = 0.0
	_u_stuck_timer[unit_idx] = 0.0
	_u_detour_timer[unit_idx] = 0.0
	_suit_tint[unit_idx] = SUIT_PALETTE[unit_idx % palette_len]
	_unit_colors_dirty = true
	if cid >= 0 and cid < _city_pop_counts.size():
		_city_pop_counts[cid] = maxi(0, _city_pop_counts[cid] - 1)


func _deposit_to_civ(city_id: int, res_type: int, amount: float) -> void:
	if _civ == null or city_id < 0 or amount <= 0.0:
		return
	if _civ.has_method("deposit_resource"):
		_civ.call("deposit_resource", city_id, res_type, amount)


func _is_on_road(pos: Vector2) -> bool:
	var rsize := _road_mask.size()
	if rsize <= 0:
		return false
	var map_need := _map_w * _map_h
	if rsize >= map_need:
		var px := clampi(int(pos.x), 0, _map_w - 1)
		var py := clampi(int(pos.y), 0, _map_h - 1)
		return _road_mask[py * _map_w + px] != 0
	if _zone_w > 0 and _zone_h > 0 and rsize >= _zone_w * _zone_h:
		var zx := clampi(int(pos.x) >> 3, 0, _zone_w - 1)
		var zy := clampi(int(pos.y) >> 3, 0, _zone_h - 1)
		return _road_mask[zy * _zone_w + zx] != 0
	return false


func _footprint_dims_for_type(btype: int) -> Vector2:
	match btype:
		0:
			return Vector2(5.0, 8.0)
		1, 2, 3, 4:
			return Vector2(7.0, 12.0)
		5, 6:
			return Vector2(9.0, 16.0)
		7:
			return Vector2(9.5, 18.0)
		8:
			return Vector2(7.5, 14.0)
		9:
			return Vector2(8.0, 14.0)
		_:
			return Vector2(7.5, 12.0)


func _is_near_building(pos: Vector2) -> bool:
	if _bld_count <= 0 or _zone_w <= 0 or _zone_h <= 0:
		return false
	if _bld_occ.size() < _zone_w * _zone_h:
		return false
	var zx := clampi(int(pos.x) >> 3, 0, _zone_w - 1)
	var zy := clampi(int(pos.y) >> 3, 0, _zone_h - 1)
	return _bld_occ[zy * _zone_w + zx] != 0


func _is_inside_any_building(pos: Vector2, pad: float) -> bool:
	if _bld_count <= 0:
		return false
	if _bld_occ.size() >= _zone_w * _zone_h and not _is_near_building(pos) and pad <= 4.0:
		return false
	var cx := clampi(int(pos.x) >> 4, 0, _grid_w - 1)
	var cy := clampi(int(pos.y) >> 4, 0, _grid_h - 1)
	var x0 := maxi(0, cx - 1)
	var x1 := mini(_grid_w - 1, cx + 1)
	var y0 := maxi(0, cy - 1)
	var y1 := mini(_grid_h - 1, cy + 1)
	for gy in range(y0, y1 + 1):
		var row_off := gy * _grid_w
		for gx in range(x0, x1 + 1):
			var b := _bld_cell_head[row_off + gx]
			while b != -1:
				var bp := _bld_pos[b]
				var hw := _bld_half_w[b] + pad
				var th := _bld_top_h[b] + pad
				if absf(pos.x - bp.x) <= hw and pos.y >= bp.y - th and pos.y <= bp.y + pad + 2.0:
					return true
				b = _bld_next[b]
	return false


func _mark_building_zones(bpos: Vector2, hw: float, th: float) -> void:
	if _zone_w <= 0 or _zone_h <= 0 or _bld_occ.size() < _zone_w * _zone_h:
		return
	var zx0 := clampi(int(bpos.x - hw - 6.0) >> 3, 0, _zone_w - 1)
	var zx1 := clampi(int(bpos.x + hw + 6.0) >> 3, 0, _zone_w - 1)
	var zy0 := clampi(int(bpos.y - th - 6.0) >> 3, 0, _zone_h - 1)
	var zy1 := clampi(int(bpos.y + 7.0) >> 3, 0, _zone_h - 1)
	for zy in range(zy0, zy1 + 1):
		var roff := zy * _zone_w
		for zx in range(zx0, zx1 + 1):
			_bld_occ[roff + zx] = 1


func _find_flora_relocate_pos(avoid_pos: Vector2) -> Vector2:
	for attempt in range(28):
		var a := float(attempt) * 2.399963 + _rng.randf_range(-0.25, 0.25)
		var r := _rng.randf_range(16.0, 52.0)
		var nx := clampi(int(avoid_pos.x + cos(a) * r), 6, _map_w - 7)
		var ny := clampi(int(avoid_pos.y + sin(a) * r), 6, _map_h - 7)
		var cand := Vector2(float(nx) + 0.5, float(ny) + 0.5)
		if _is_flora_allowed_tile(nx, ny) and not _is_inside_any_building(cand, 5.5):
			return cand
	for _try2 in range(24):
		var rx := _rng.randi_range(6, _map_w - 7)
		var ry := _rng.randi_range(6, _map_h - 7)
		var cand2 := Vector2(float(rx) + 0.5, float(ry) + 0.5)
		if _is_flora_allowed_tile(rx, ry) and not _is_inside_any_building(cand2, 5.5):
			return cand2
	return Vector2(-1.0, -1.0)


func _clear_flora_around(bpos: Vector2, hw: float, th: float) -> void:
	if _flora_count <= 0:
		return
	if _flora_hash_dirty:
		_rebuild_flora_hash()
	var vc := Vector2(bpos.x, bpos.y - th * 0.45)
	var cx := clampi(int(vc.x) >> 4, 0, _grid_w - 1)
	var cy := clampi(int(vc.y) >> 4, 0, _grid_h - 1)
	var x0 := maxi(0, cx - 1)
	var x1 := mini(_grid_w - 1, cx + 1)
	var y0 := maxi(0, cy - 1)
	var y1 := mini(_grid_h - 1, cy + 1)
	var pad_x := hw + 4.0
	var y_top := bpos.y - th - 3.5
	var y_bot := bpos.y + 4.5
	var moved_any := false

	for gy in range(y0, y1 + 1):
		var row_off := gy * _grid_w
		for gx in range(x0, x1 + 1):
			var f := _flora_cell_head[row_off + gx]
			while f != -1:
				var fp := _flora_pos[f]
				if absf(fp.x - bpos.x) <= pad_x and fp.y >= y_top and fp.y <= y_bot:
					var np := _find_flora_relocate_pos(bpos)
					if np.x >= 0.0:
						_flora_pos[f] = np
						if _world != null:
							var tx := int(np.x)
							var ty := int(np.y)
							_flora_col[f] = _pick_flora_col_for_tile(_world.get_tier(tx, ty), _world.get_biome(tx, ty), _world.get_temp(tx, ty))
						_flora_shake[f] = 0.0
						_flora_spring[f] = 1.0
						_flora_spring_vel[f] = 0.0
						_flora_burn[f] = 0.0
						_flora_grow[f] = 0.0
						if f < _flora_active_custom.size():
							_flora_active_custom[f] = 1
						moved_any = true
				f = _flora_next[f]
	if moved_any:
		_flora_hash_dirty = true
		_flora_dirty_all = true
		_rebuild_flora_hash()


func _nudge_units_off_footprint(bpos: Vector2, hw: float, th: float) -> void:
	if _unit_count <= 0:
		return
	var vc := Vector2(bpos.x, bpos.y - th * 0.45)
	var cx := clampi(int(vc.x) >> 4, 0, _grid_w - 1)
	var cy := clampi(int(vc.y) >> 4, 0, _grid_h - 1)
	var x0 := maxi(0, cx - 1)
	var x1 := mini(_grid_w - 1, cx + 1)
	var y0 := maxi(0, cy - 1)
	var y1 := mini(_grid_h - 1, cy + 1)
	var rx := hw + 1.8
	var y_top := bpos.y - th - 1.5
	var y_bot := bpos.y + 2.5

	for gy in range(y0, y1 + 1):
		var row_off := gy * _grid_w
		for gx in range(x0, x1 + 1):
			var u := _cell_head[row_off + gx]
			while u != -1:
				var up := Vector2(_px[u], _py[u])
				if absf(up.x - bpos.x) < rx and up.y > y_top and up.y < y_bot:
					var exit_pt := Vector2(up.x, y_bot + 1.0)
					if not _is_walkable_pos(exit_pt):
						var side_x := bpos.x + (rx + 1.2 if up.x >= bpos.x else -(rx + 1.2))
						var side_pt := Vector2(side_x, clampf(up.y, 4.0, float(_map_h - 5)))
						if _is_walkable_pos(side_pt):
							exit_pt = side_pt
					if _is_walkable_pos(exit_pt):
						_px[u] = exit_pt.x
						_py[u] = exit_pt.y
						_pos[u] = exit_pt
				u = _unit_next[u]


func _rebuild_building_index(clear_overlap: bool) -> void:
	_bld_half_w.resize(_bld_count)
	_bld_top_h.resize(_bld_count)
	_bld_next.resize(_bld_count)
	_bld_next.fill(-1)
	_bld_cell_head.fill(-1)

	var ztotal := maxi(1, _zone_w * _zone_h)
	if _bld_occ.size() != ztotal:
		_bld_occ.resize(ztotal)
	_bld_occ.fill(0)

	for b in range(_bld_count):
		var btype := int(_bld_type[b]) if b < _bld_type.size() else 1
		var dims := _footprint_dims_for_type(btype)
		_bld_half_w[b] = dims.x
		_bld_top_h[b] = dims.y
		var bp := _bld_pos[b]
		var vc := Vector2(bp.x, bp.y - dims.y * 0.45)
		var cx := clampi(int(vc.x) >> 4, 0, _grid_w - 1)
		var cy := clampi(int(vc.y) >> 4, 0, _grid_h - 1)
		var c := cy * _grid_w + cx
		_bld_next[b] = _bld_cell_head[c]
		_bld_cell_head[c] = b
		_mark_building_zones(bp, dims.x, dims.y)

	if clear_overlap:
		_rebuild_spatial_hash()
		for b2 in range(_bld_count):
			_clear_flora_around(_bld_pos[b2], _bld_half_w[b2], _bld_top_h[b2])
			_nudge_units_off_footprint(_bld_pos[b2], _bld_half_w[b2], _bld_top_h[b2])
		if _flora_dirty_all:
			_sync_flora_multimesh()


func clear_footprint(world_pos: Vector2, radius: float = 10.0) -> void:
	_ensure_layers()
	var hw := clampf(radius * 0.72, 4.5, 11.0)
	var th := clampf(radius * 1.15, 8.0, 18.0)
	var found := false
	for b in range(_bld_count):
		if _bld_pos[b].distance_squared_to(world_pos) <= 4.0:
			found = true
			break
	if not found and _bld_count < 512:
		if _bld_pos.size() <= _bld_count:
			_bld_pos.resize(_bld_count + 1)
		if _bld_type.size() <= _bld_count:
			_bld_type.resize(_bld_count + 1)
		_bld_pos[_bld_count] = world_pos
		_bld_type[_bld_count] = 5 if radius >= 11.0 else (1 if radius >= 7.5 else 0)
		_bld_count += 1
		_bld_synced_count = _bld_count
		_rebuild_building_index(false)
	_rebuild_spatial_hash()
	_clear_flora_around(world_pos, hw, th)
	_nudge_units_off_footprint(world_pos, hw, th)
	if _flora_dirty_all:
		_sync_flora_multimesh()


func _building_avoid_force(pos: Vector2, target_pos: Vector2, is_bld_goal: bool) -> Vector2:
	var force := Vector2.ZERO
	var cx := clampi(int(pos.x) >> 4, 0, _grid_w - 1)
	var cy := clampi(int(pos.y) >> 4, 0, _grid_h - 1)
	var x0 := maxi(0, cx - 1)
	var x1 := mini(_grid_w - 1, cx + 1)
	var y0 := maxi(0, cy - 1)
	var y1 := mini(_grid_h - 1, cy + 1)

	for gy in range(y0, y1 + 1):
		var row_off := gy * _grid_w
		for gx in range(x0, x1 + 1):
			var b := _bld_cell_head[row_off + gx]
			while b != -1:
				var bp := _bld_pos[b]
				var rx := _bld_half_w[b] + 2.2
				var y_top := bp.y - _bld_top_h[b] - 2.0
				var y_bot := bp.y + 2.8
				var dx := pos.x - bp.x
				if absf(dx) < rx + 3.0 and pos.y > y_top - 2.0 and pos.y < y_bot + 1.5:
					var targeting_this := is_bld_goal and target_pos.distance_squared_to(bp) <= 25.0
					if targeting_this and pos.y >= bp.y - 1.5:
						b = _bld_next[b]
						continue
					if pos.y < bp.y - 1.0:
						var side_sign := 1.0 if dx >= 0.0 else -1.0
						force += Vector2(side_sign * 1.15, -0.35 if not targeting_this else 0.35)
					else:
						var vc := Vector2(bp.x, 0.5 * (y_top + y_bot))
						var away := pos - vc
						if away.length_squared() > 0.01:
							force += away.normalized()
						else:
							force += Vector2(0.0, 1.0)
				b = _bld_next[b]
	return force


func _clamp_out_of_buildings(next_pos: Vector2) -> Vector2:
	if not _is_near_building(next_pos):
		return next_pos
	var p := next_pos
	var cx := clampi(int(p.x) >> 4, 0, _grid_w - 1)
	var cy := clampi(int(p.y) >> 4, 0, _grid_h - 1)
	var x0 := maxi(0, cx - 1)
	var x1 := mini(_grid_w - 1, cx + 1)
	var y0 := maxi(0, cy - 1)
	var y1 := mini(_grid_h - 1, cy + 1)

	for gy in range(y0, y1 + 1):
		var row_off := gy * _grid_w
		for gx in range(x0, x1 + 1):
			var b := _bld_cell_head[row_off + gx]
			while b != -1:
				var bp := _bld_pos[b]
				var rx := _bld_half_w[b] + 1.6
				var y_top := bp.y - _bld_top_h[b] - 1.2
				var y_bot := bp.y + 2.2
				if absf(p.x - bp.x) < rx and p.y > y_top and p.y < y_bot:
					var d_left := p.x - (bp.x - rx)
					var d_right := (bp.x + rx) - p.x
					var d_top := p.y - y_top
					var d_bot := y_bot - p.y
					var cand := p
					if d_bot <= d_top and d_bot <= d_left and d_bot <= d_right:
						cand.y = y_bot
					elif d_left <= d_right and d_left <= d_top:
						cand.x = bp.x - rx
					elif d_right <= d_top:
						cand.x = bp.x + rx
					else:
						cand.y = y_top
					if _is_walkable_pos(cand):
						p = cand
					else:
						var fallback := Vector2(p.x, y_bot)
						if _is_walkable_pos(fallback):
							p = fallback
				b = _bld_next[b]
	return p


func _spawn_work_chips(pos: Vector2, role: int) -> void:
	if _fx == null:
		return
	if role == ROLE_MINER:
		_fx.spawn_burst(pos + Vector2(0.0, -2.0), 2, Color(0.55, 0.88, 0.92, 0.88), 18.0, 0.26, 32.0)
	elif role == ROLE_BUILDER:
		_fx.spawn_burst(pos + Vector2(0.0, -2.0), 2, Color(0.92, 0.76, 0.48, 0.85), 16.0, 0.24, 30.0)
	else:
		_fx.spawn_burst(pos + Vector2(0.0, -2.0), 2, Color(0.45, 0.85, 0.40, 0.85), 14.0, 0.28, 28.0)


func _pick_faction_role(faction_id: int, idx: int) -> int:
	var slot := idx & 7
	if faction_id == FACTION_ROBOT:
		return ROLE_PATTERN_ROBOT[slot]
	if faction_id == FACTION_SPORE:
		return ROLE_PATTERN_SPORE[slot]
	return ROLE_PATTERN[slot]


func _is_unit_active_infected(u: int) -> bool:
	if u < 0 or u >= _u_infected_timer.size() or _u_infected_timer[u] <= 0.0:
		return false
	return u >= _u_latent_timer.size() or _u_latent_timer[u] <= 0.0


func _get_diplo_relation(c1: int, c2: int) -> int:
	if c1 < 0 or c2 < 0 or c1 == c2 or _diplo_max_cities <= 0:
		return DIPLO_NEUTRAL
	if c1 >= _diplo_max_cities or c2 >= _diplo_max_cities:
		return DIPLO_NEUTRAL
	var dsz := _diplo_matrix.size()
	var i1 := c1 * _diplo_max_cities + c2
	var i2 := c2 * _diplo_max_cities + c1
	if i1 >= dsz or i2 >= dsz:
		return DIPLO_NEUTRAL
	return maxi(int(_diplo_matrix[i1]), int(_diplo_matrix[i2]))


func _are_units_hostile(i: int, j: int) -> bool:
	if i == j:
		return false
	var mut_i := (_u_role[i] == ROLE_MUTANT or _u_faction_id[i] == FACTION_MUTANT)
	var mut_j := (_u_role[j] == ROLE_MUTANT or _u_faction_id[j] == FACTION_MUTANT)
	if mut_i != mut_j:
		return true
	var inf_i := _is_unit_active_infected(i)
	var inf_j := _is_unit_active_infected(j)
	var ci := _u_city_id[i]
	var cj := _u_city_id[j]
	if inf_i != inf_j:
		if int(_u_faction_id[i]) == FACTION_SPORE and int(_u_faction_id[j]) == FACTION_SPORE and ci >= 0 and ci == cj:
			return false
		return true
	if i < _u_glitch_timer.size() and _u_glitch_timer[i] > 0.0:
		return true
	if ci < 0 or cj < 0 or ci == cj:
		return false
	var rel := _get_diplo_relation(ci, cj)
	return rel == DIPLO_TOTAL_WAR or rel == DIPLO_REBELLION


func _is_hostile_to_city(u: int, friendly_city: int) -> bool:
	if u < 0 or u >= _unit_count or _hp[u] <= 0.0:
		return false
	if _u_role[u] == ROLE_MUTANT or _u_faction_id[u] == FACTION_MUTANT:
		return true
	var ucid := _u_city_id[u]
	if _is_unit_active_infected(u):
		if int(_u_faction_id[u]) == FACTION_SPORE and friendly_city >= 0 and ucid == friendly_city:
			return false
		return true
	if friendly_city < 0:
		if u < _u_glitch_timer.size() and _u_glitch_timer[u] > 0.0:
			return true
		return ucid >= 0 and _is_city_at_war(ucid)
	if ucid == friendly_city:
		return false
	if u < _u_glitch_timer.size() and _u_glitch_timer[u] > 0.0:
		return true
	if ucid < 0:
		return false
	var rel := _get_diplo_relation(friendly_city, ucid)
	return rel == DIPLO_TOTAL_WAR or rel == DIPLO_REBELLION


func _is_city_at_war(cid: int) -> bool:
	if cid < 0:
		return false
	if cid < _city_war_state.size() and int(_city_war_state[cid]) >= DIPLO_TOTAL_WAR:
		return true
	if cid < _city_is_rebel.size() and _city_is_rebel[cid] != 0:
		return true
	return false


func _get_faction_beam_color(unit_idx: int) -> Color:
	var cid := _u_city_id[unit_idx]
	if cid >= 0 and cid < _city_is_rebel.size() and _city_is_rebel[cid] != 0:
		return BEAM_COL_REBEL
	match int(_u_faction_id[unit_idx]):
		FACTION_HUMAN:
			return BEAM_COL_HUMAN
		FACTION_ROBOT:
			return BEAM_COL_ROBOT
		FACTION_SPORE:
			return BEAM_COL_SPORE
		_:
			return BEAM_COL_MUTANT


func _find_war_rally_pos(cid: int, unit_pos: Vector2) -> Vector2:
	var fallback := _u_depot_pos[0] if _u_depot_pos.size() > 0 else unit_pos
	if cid >= 0 and cid < _city_depot_pos.size() and _city_depot_pos[cid].x >= 0.0:
		fallback = _city_depot_pos[cid]
	if cid >= 0 and cid < _city_threat_pos.size() and _city_threat_pos[cid].x >= 0.0:
		var tpos := _city_threat_pos[cid]
		if _is_walkable_pos(tpos) and _count_water_hits(unit_pos, tpos) < 2:
			return tpos
	var best_enemy_dep := Vector2(-1.0, -1.0)
	var best_d2 := 1e18
	var max_c := mini(MAX_CITIES, mini(_city_active.size(), _city_depot_pos.size()))
	for ec in range(max_c):
		if ec == cid or _city_active[ec] == 0:
			continue
		var rel := _get_diplo_relation(cid, ec)
		if rel < DIPLO_TOTAL_WAR:
			continue
		var edep := _city_depot_pos[ec]
		if edep.x < 0.0:
			continue
		var d2 := unit_pos.distance_squared_to(edep)
		if d2 < best_d2:
			best_d2 = d2
			best_enemy_dep = edep
	if best_enemy_dep.x >= 0.0:
		if _count_water_hits(unit_pos, best_enemy_dep) < 2:
			var push_pt := fallback.lerp(best_enemy_dep, 0.72)
			if _is_walkable_pos(push_pt) and _count_water_hits(unit_pos, push_pt) < 2:
				return push_pt
			return _find_walkable_near(best_enemy_dep, 16.0)
		# Enemy across ocean -> rally to friendly Quantum Gate near home depot first
		var best_gate := Vector2(-1.0, -1.0)
		var best_gd2 := 1e18
		for b in range(_bld_count):
			if int(_bld_type[b]) != BLD_TYPE_QUANTUM_GATE:
				continue
			var gp := _bld_pos[b]
			if gp.distance_squared_to(fallback) <= 19600.0 and _count_water_hits(unit_pos, gp) < 2:
				var gd2 := unit_pos.distance_squared_to(gp)
				if gd2 < best_gd2:
					best_gd2 = gd2
					best_gate = gp
		if best_gate.x >= 0.0:
			return _find_walkable_near(best_gate, 12.0)
		# Otherwise march toward shoreline border facing enemy without entering water
		var step_dir := (best_enemy_dep - unit_pos)
		if step_dir.length_squared() > 1.0:
			var n_dir := step_dir.normalized()
			var dry_edge := unit_pos
			for s in range(1, 12):
				var test_p := unit_pos + n_dir * (float(s) * 8.0)
				if test_p.x < 4.0 or test_p.x >= float(_map_w - 5) or test_p.y < 4.0 or test_p.y >= float(_map_h - 5):
					break
				if not _is_walkable_pos(test_p):
					break
				dry_edge = test_p
			if dry_edge != unit_pos:
				return dry_edge
	if cid >= 0 and cid < _city_patrol_pos.size() and _city_patrol_pos[cid].x >= 0.0:
		var ppos := _city_patrol_pos[cid]
		if _is_walkable_pos(ppos) and _count_water_hits(unit_pos, ppos) < 2:
			return ppos
	return fallback


func _find_ranged_enemy_idx(seeker: int, px_f: float, py_f: float, max_range: float) -> int:
	if _macro_w <= 0 or _macro_h <= 0 or _macro_head.size() < _macro_w * _macro_h:
		return -1
	var r2 := max_range * max_range
	var best_idx := -1
	var best_d2 := r2
	var mcx0 := clampi(int(px_f) >> 6, 0, _macro_w - 1)
	var mcy0 := clampi(int(py_f) >> 6, 0, _macro_h - 1)
	var max_mr := int(max_range / 64.0) + 1
	var edge_min := maxf(0.0, minf(minf(px_f - float(mcx0 << 6), float((mcx0 + 1) << 6) - px_f), minf(py_f - float(mcy0 << 6), float((mcy0 + 1) << 6) - py_f)))
	var my_cid := _u_city_id[seeker]
	var my_fac := int(_u_faction_id[seeker])
	var my_mut := (_u_role[seeker] == ROLE_MUTANT or my_fac == FACTION_MUTANT)
	var any_inf := _any_infected_unit
	var inf_sz := _u_infected_timer.size()
	var lat_sz := _u_latent_timer.size()
	var my_inf := any_inf and seeker < inf_sz and _u_infected_timer[seeker] > 0.0 and (seeker >= lat_sz or _u_latent_timer[seeker] <= 0.0)
	var my_glitch := _any_glitched_unit and seeker < _u_glitch_timer.size() and _u_glitch_timer[seeker] > 0.0
	var diplo_sz := _diplo_matrix.size()
	var diplo_stride := _diplo_max_cities

	for mr in range(max_mr + 1):
		var y0 := maxi(0, mcy0 - mr)
		var y1 := mini(_macro_h - 1, mcy0 + mr)
		var x_lft := mcx0 - mr
		var x_rgt := mcx0 + mr
		for my in range(y0, y1 + 1):
			var at_y_edge := (mr == 0 or my == mcy0 - mr or my == mcy0 + mr)
			var step_x := 1 if at_y_edge else (mr << 1)
			var mx := x_lft
			while mx <= x_rgt:
				if mx >= 0 and mx < _macro_w:
					var j := _macro_head[my * _macro_w + mx]
					if j != -1:
						var min_x := float(mx << 6)
						var max_x := float((mx + 1) << 6)
						var min_y := float(my << 6)
						var max_y := float((my + 1) << 6)
						var bdx := maxf(0.0, maxf(min_x - px_f, px_f - max_x))
						var bdy := maxf(0.0, maxf(min_y - py_f, py_f - max_y))
						if bdx * bdx + bdy * bdy <= best_d2:
							while j != -1:
								if j != seeker and _hp[j] > 0.0:
									var j_cid := _u_city_id[j]
									var j_fac := int(_u_faction_id[j])
									var j_mut := (_u_role[j] == ROLE_MUTANT or j_fac == FACTION_MUTANT)
									var j_inf := any_inf and j < inf_sz and _u_infected_timer[j] > 0.0 and (j >= lat_sz or _u_latent_timer[j] <= 0.0)
									var hostile := false
									if my_mut != j_mut:
										hostile = true
									elif my_inf != j_inf and (my_fac != FACTION_SPORE or j_fac != FACTION_SPORE or my_cid < 0 or my_cid != j_cid):
										hostile = true
									elif my_glitch:
										hostile = true
									elif my_cid >= 0 and j_cid >= 0 and my_cid != j_cid and diplo_stride > 0 and my_cid < diplo_stride and j_cid < diplo_stride:
										var di1 := my_cid * diplo_stride + j_cid
										var di2 := j_cid * diplo_stride + my_cid
										if di1 < diplo_sz and di2 < diplo_sz:
											var r1 := int(_diplo_matrix[di1])
											var r2_d := int(_diplo_matrix[di2])
											var rel := r1 if r1 >= r2_d else r2_d
											hostile = (rel == DIPLO_TOTAL_WAR or rel == DIPLO_REBELLION)
									if hostile:
										var dx := px_f - _px[j]
										var dy := py_f - _py[j]
										var d2 := dx * dx + dy * dy
										if d2 <= best_d2:
											best_d2 = d2
											best_idx = j
								j = _macro_next[j]
				mx += step_x
		if best_idx >= 0:
			var next_d := edge_min + float(mr) * 64.0
			if best_d2 <= next_d * next_d:
				return best_idx
	return best_idx


func _find_nearest_dry_escape(pos: Vector2, max_r: float) -> Vector2:
	var c := Vector2(
		clampf(pos.x, 4.0, float(_map_w - 5)),
		clampf(pos.y, 4.0, float(_map_h - 5))
	)
	var rad := 1.5
	while rad <= max_r:
		for s in range(12):
			var ang := float(s) * (TAU / 12.0)
			var cand := Vector2(
				clampf(c.x + cos(ang) * rad, 4.0, float(_map_w - 5)),
				clampf(c.y + sin(ang) * rad, 4.0, float(_map_h - 5))
			)
			if _is_strictly_dry_land_tile(int(cand.x), int(cand.y)) and not _is_inside_any_building(cand, 1.0):
				return cand
		rad += 2.0
	return Vector2(-1.0, -1.0)


func _assign_worker_goal(unit_idx: int, city_id: int) -> void:
	if unit_idx < 0 or unit_idx >= _unit_count or city_id < 0:
		return
	var depot := _u_depot_pos[unit_idx]
	if city_id < _city_depot_pos.size() and _city_depot_pos[city_id].x >= 0.0:
		depot = _city_depot_pos[city_id]
		_u_depot_pos[unit_idx] = depot

	var unit_pos := Vector2(_px[unit_idx], _py[unit_idx])
	var role := int(_u_role[unit_idx])
	_u_flora_idx[unit_idx] = -1
	_u_stuck_timer[unit_idx] = 0.0
	_u_detour_timer[unit_idx] = 0.0

	var hunger := _city_hunger_cache[city_id] if (city_id >= 0 and city_id < _city_hunger_cache.size()) else 0.0
	var at_war := _is_city_at_war(city_id)
	var has_build_site := (city_id < _city_build_pos.size() and _city_build_pos[city_id].x >= 0.0)
	var urgent_food := hunger >= 0.45 and (role == ROLE_FARMER or role == ROLE_FREE or (role == ROLE_MINER and hunger >= 0.65 and (unit_idx & 1) == 0) or (role == ROLE_BUILDER and not has_build_site and hunger >= 0.65))
	if urgent_food:
		_u_alert_layer[unit_idx] = LAYER_LOGISTICS
		var f_food := _find_nearest_flora(unit_idx, depot, false, 78.0)
		if f_food >= 0:
			_u_flora_idx[unit_idx] = f_food
			_u_target_pos[unit_idx] = _flora_pos[f_food]
		else:
			_u_target_pos[unit_idx] = _find_walkable_offset(depot, 6.0, 28.0, true)
		_u_task[unit_idx] = TASK_MOVE_GOAL
		_u_last_dist[unit_idx] = unit_pos.distance_to(_u_target_pos[unit_idx])
		return

	if _u_alert_layer[unit_idx] == LAYER_LOGISTICS:
		_u_alert_layer[unit_idx] = LAYER_ROUTINE

	if at_war and role != ROLE_SOLDIER and (role == ROLE_FREE or (hunger < 0.55 and (unit_idx & 1) == 0 and _u_carry_type[unit_idx] == CARRY_NONE)):
		var wrally := _find_war_rally_pos(city_id, unit_pos)
		_u_target_pos[unit_idx] = _find_walkable_offset(wrally, 2.0, 14.0, false)
		_u_task[unit_idx] = TASK_PATROL
		_u_work_timer[unit_idx] = 1.25
		_u_last_dist[unit_idx] = unit_pos.distance_to(_u_target_pos[unit_idx])
		return

	match role:
		ROLE_FARMER:
			var f := _find_nearest_flora(unit_idx, depot, false, 72.0)
			if f >= 0:
				_u_flora_idx[unit_idx] = f
				_u_target_pos[unit_idx] = _flora_pos[f]
			else:
				_u_target_pos[unit_idx] = _find_walkable_offset(depot, 6.0, 26.0, true)
			_u_task[unit_idx] = TASK_MOVE_GOAL
		ROLE_MINER:
			var anchor := depot
			if city_id < _city_mine_pos.size() and _city_mine_pos[city_id].x >= 0.0:
				var mpos := _city_mine_pos[city_id]
				if _is_walkable_pos(mpos) and _count_water_hits(unit_pos, mpos) < 2:
					anchor = mpos
			var mf := _find_nearest_flora(unit_idx, anchor, true, 72.0)
			if mf >= 0:
				_u_flora_idx[unit_idx] = mf
				_u_target_pos[unit_idx] = _flora_pos[mf]
			elif anchor != depot:
				_u_target_pos[unit_idx] = _find_walkable_offset(anchor, 2.0, 9.0, false)
			else:
				_u_target_pos[unit_idx] = _find_walkable_offset(depot, 8.0, 30.0, false)
			_u_task[unit_idx] = TASK_MOVE_GOAL
		ROLE_BUILDER:
			var bgoal := depot
			if city_id < _city_build_pos.size() and _city_build_pos[city_id].x >= 0.0:
				bgoal = _city_build_pos[city_id]
			if not _is_walkable_pos(bgoal) or _count_water_hits(unit_pos, bgoal) >= 2:
				var near_b := _find_walkable_near(bgoal, 8.0)
				if _is_walkable_pos(near_b) and _count_water_hits(unit_pos, near_b) < 2:
					bgoal = near_b
				else:
					bgoal = _find_walkable_offset(depot, 5.0, 16.0, false)
			_u_target_pos[unit_idx] = bgoal
			_u_task[unit_idx] = TASK_MOVE_GOAL
		ROLE_SOLDIER:
			var panchor := depot
			var patrol_r: float = TUNING_KNOBS["PATROL_RADIUS_PX"]
			var alerted := (city_id < _city_alerted.size() and _city_alerted[city_id] != 0)
			if at_war:
				panchor = _find_war_rally_pos(city_id, unit_pos)
				patrol_r = 14.0
			elif alerted and city_id < _city_threat_pos.size() and _city_threat_pos[city_id].x >= 0.0:
				var tpos := _city_threat_pos[city_id]
				if _is_walkable_pos(tpos) and _count_water_hits(unit_pos, tpos) < 2:
					panchor = tpos
					patrol_r = 12.0
			elif city_id < _city_patrol_pos.size() and _city_patrol_pos[city_id].x >= 0.0:
				var ppos := _city_patrol_pos[city_id]
				if _is_walkable_pos(ppos) and _count_water_hits(unit_pos, ppos) < 2:
					panchor = ppos
			_u_target_pos[unit_idx] = _find_walkable_offset(panchor, 2.0, patrol_r, false)
			_u_task[unit_idx] = TASK_PATROL
			_u_work_timer[unit_idx] = 0.95 if at_war else (1.2 if alerted else _rng.randf_range(1.6, 3.0))
		_:
			_u_task[unit_idx] = TASK_IDLE
			_u_target_pos[unit_idx] = depot

	_u_last_dist[unit_idx] = unit_pos.distance_to(_u_target_pos[unit_idx])


func _steer_worker(unit_idx: int, pos: Vector2, target: Vector2, speed: float, safe_dt: float) -> Vector2:
	var to_t := target - pos
	var dist := to_t.length()
	if dist < 0.001:
		return Vector2.ZERO

	var direct := to_t / dist
	if dist < _u_last_dist[unit_idx] - maxf(0.01, speed * safe_dt * 0.20):
		_u_last_dist[unit_idx] = dist
		_u_stuck_timer[unit_idx] = maxf(0.0, _u_stuck_timer[unit_idx] - safe_dt * 1.4)
	else:
		_u_stuck_timer[unit_idx] += safe_dt
		_u_last_dist[unit_idx] = minf(_u_last_dist[unit_idx], dist + 0.05)

	var det_t := _u_detour_timer[unit_idx]
	if det_t > 0.0:
		_u_detour_timer[unit_idx] = maxf(0.0, det_t - safe_dt)
		var d_dir := _u_detour_dir[unit_idx]
		if _world == null or _is_walkable_pos(pos + d_dir * 4.5):
			return d_dir
		_u_detour_side[unit_idx] = -_u_detour_side[unit_idx]
		_u_detour_dir[unit_idx] = direct.rotated(_u_detour_side[unit_idx] * 1.65)
		return _u_detour_dir[unit_idx]

	if _world != null:
		var probe := pos + direct * 4.5
		if not _is_walkable_pos(probe):
			var s := _u_detour_side[unit_idx]
			var cand_a := direct.rotated(s * 1.15)
			var cand_t := direct.rotated(s * 1.65)
			var cand_b := direct.rotated(-s * 1.15)
			if _is_walkable_pos(pos + cand_a * 5.0):
				_u_detour_dir[unit_idx] = cand_a
			elif _is_walkable_pos(pos + cand_t * 5.0):
				_u_detour_dir[unit_idx] = cand_t
			elif _is_walkable_pos(pos + cand_b * 5.0):
				_u_detour_side[unit_idx] = -s
				_u_detour_dir[unit_idx] = cand_b
			else:
				_u_detour_side[unit_idx] = -s
				_u_detour_dir[unit_idx] = -direct
			_u_detour_timer[unit_idx] = 0.55
			return _u_detour_dir[unit_idx]

	if _u_stuck_timer[unit_idx] > 1.8:
		var alt := direct.rotated(_u_detour_side[unit_idx] * 1.1)
		if _world == null or _is_walkable_pos(pos + alt * 5.0):
			_u_detour_dir[unit_idx] = alt
			_u_detour_timer[unit_idx] = 0.65
			return alt

	return direct


func _finish_harvest_cycle(unit_idx: int, cid: int) -> void:
	var f := _u_flora_idx[unit_idx]
	if f >= 0 and f < _flora_count:
		_flora_shake[f] = 1.0
		_flora_spring_vel[f] = -2.2
		_flora_has_anim = true
		if f < _flora_active_custom.size():
			_flora_active_custom[f] = 1
	var role := int(_u_role[unit_idx])
	var urgent_food := (_u_alert_layer[unit_idx] == LAYER_LOGISTICS)
	if _work_fx_budget > 0:
		_work_fx_budget -= 1
		_spawn_work_chips(_u_target_pos[unit_idx], ROLE_FARMER if urgent_food else role)

	if role == ROLE_BUILDER and not urgent_food:
		_deposit_to_civ(cid, RES_BUILD_WORK, 1.25)
		_record_memory(unit_idx, MEM_BUILT)
		_u_flora_idx[unit_idx] = -1
		_u_task[unit_idx] = TASK_IDLE
		return

	var res_type := RES_FOOD
	var res_amt := (1.65 if urgent_food else 1.5) * _crop_mul
	if role == ROLE_MINER and not urgent_food:
		res_type = RES_ORE
		res_amt = 1.5
		if f >= 0 and f < _flora_count:
			var col := _flora_col[f]
			if col == FLORA_CRYSTAL_TALL:
				if ((unit_idx + _tick_idx) & 1) == 0:
					res_type = RES_ORE
					res_amt = 1.35
				else:
					res_type = RES_SCIENCE
					res_amt = 1.2
			elif col == FLORA_CRYSTAL_SMALL:
				if ((unit_idx + _tick_idx) & 1) == 0:
					res_type = RES_ORE
					res_amt = 1.4
				else:
					res_type = RES_ENERGY
					res_amt = 1.4
		elif _world != null:
			var tp := _u_target_pos[unit_idx]
			var bx := clampi(int(tp.x), 0, _map_w - 1)
			var by := clampi(int(tp.y), 0, _map_h - 1)
			if _world.get_biome(bx, by) == BIOME_CRYSTAL:
				if ((unit_idx + _tick_idx) & 1) == 0:
					res_type = RES_ORE
					res_amt = 1.35
				else:
					res_type = RES_ENERGY
					res_amt = 1.3

	_u_carry_type[unit_idx] = res_type
	_u_carry_amt[unit_idx] = res_amt
	_u_flora_idx[unit_idx] = -1
	_u_task[unit_idx] = TASK_HAUL_DEPOT
	_u_target_pos[unit_idx] = _u_depot_pos[unit_idx]
	_u_stuck_timer[unit_idx] = 0.0
	_u_detour_timer[unit_idx] = 0.0
	var ddx := _u_depot_pos[unit_idx].x - _px[unit_idx]
	var ddy := _u_depot_pos[unit_idx].y - _py[unit_idx]
	_u_last_dist[unit_idx] = sqrt(ddx * ddx + ddy * ddy)


func _step_worker_state(unit_idx: int, cid: int, pos: Vector2, speed: float, safe_dt: float) -> Vector2:
	if cid < _city_depot_pos.size() and _city_depot_pos[cid].x >= 0.0:
		_u_depot_pos[unit_idx] = _city_depot_pos[cid]

	if _u_task[unit_idx] == TASK_IDLE:
		_assign_worker_goal(unit_idx, cid)

	var task := int(_u_task[unit_idx])
	var role := int(_u_role[unit_idx])

	if task == TASK_HARVEST:
		var dx := _u_target_pos[unit_idx].x - pos.x
		if absf(dx) > 0.1:
			_facing[unit_idx] = 1.0 if dx >= 0.0 else -1.0
		var f := _u_flora_idx[unit_idx]
		if f >= 0 and f < _flora_count:
			_flora_shake[f] = maxf(_flora_shake[f], 0.55)
			_flora_has_anim = true
			if f < _flora_active_custom.size():
				_flora_active_custom[f] = 1
		_u_work_timer[unit_idx] -= safe_dt
		if _work_fx_budget > 0 and _rng.randf() < safe_dt * 1.6:
			_work_fx_budget -= 1
			_spawn_work_chips(_u_target_pos[unit_idx], role)
		if _u_work_timer[unit_idx] <= 0.0:
			_finish_harvest_cycle(unit_idx, cid)
		return Vector2.ZERO

	if task == TASK_MOVE_GOAL:
		var tracked_f := _u_flora_idx[unit_idx]
		if tracked_f >= 0 and tracked_f < _flora_count:
			if _flora_pos[tracked_f].distance_squared_to(_u_target_pos[unit_idx]) > 4.0:
				_u_flora_idx[unit_idx] = -1
				_u_task[unit_idx] = TASK_IDLE
				return Vector2.ZERO
		if role == ROLE_BUILDER and _u_alert_layer[unit_idx] != LAYER_LOGISTICS and cid < _city_build_pos.size() and _city_build_pos[cid].x >= 0.0:
			if _city_build_pos[cid].distance_squared_to(_u_target_pos[unit_idx]) > 144.0:
				_assign_worker_goal(unit_idx, cid)
		var dist := pos.distance_to(_u_target_pos[unit_idx])
		var reach: float = TUNING_KNOBS["WORKER_REACH_PX"]
		if (role == ROLE_BUILDER and _u_alert_layer[unit_idx] != LAYER_LOGISTICS) or _is_near_building(_u_target_pos[unit_idx]):
			reach = maxf(reach, 11.5)
		if dist <= reach:
			_u_task[unit_idx] = TASK_HARVEST
			if _u_alert_layer[unit_idx] == LAYER_LOGISTICS:
				_u_work_timer[unit_idx] = float(TUNING_KNOBS["HARVEST_DURATION_FARM"]) * 0.85
			elif role == ROLE_BUILDER:
				_u_work_timer[unit_idx] = TUNING_KNOBS["BUILD_WORK_INTERVAL"]
			elif role == ROLE_MINER:
				_u_work_timer[unit_idx] = TUNING_KNOBS["HARVEST_DURATION_MINE"]
			else:
				_u_work_timer[unit_idx] = TUNING_KNOBS["HARVEST_DURATION_FARM"]
			var f_hit := _u_flora_idx[unit_idx]
			if f_hit >= 0 and f_hit < _flora_count:
				_flora_shake[f_hit] = maxf(_flora_shake[f_hit], 0.85)
				_flora_has_anim = true
				if f_hit < _flora_active_custom.size():
					_flora_active_custom[f_hit] = 1
			if _work_fx_budget > 0:
				_work_fx_budget -= 1
				_spawn_work_chips(_u_target_pos[unit_idx], role)
			return Vector2.ZERO
		if _u_stuck_timer[unit_idx] > 3.6:
			_u_flora_idx[unit_idx] = -1
			_u_task[unit_idx] = TASK_IDLE
			return Vector2.ZERO
		return _steer_worker(unit_idx, pos, _u_target_pos[unit_idx], speed, safe_dt)

	if task == TASK_HAUL_DEPOT:
		_u_target_pos[unit_idx] = _u_depot_pos[unit_idx]
		var dist_d := pos.distance_to(_u_depot_pos[unit_idx])
		var depot_reach: float = TUNING_KNOBS["DEPOT_REACH_PX"]
		if _is_near_building(_u_depot_pos[unit_idx]):
			depot_reach = maxf(depot_reach, 11.5)
		if dist_d <= depot_reach:
			var carry_type := int(_u_carry_type[unit_idx])
			_deposit_to_civ(cid, carry_type, _u_carry_amt[unit_idx])
			_record_memory(unit_idx, MEM_GATHERED)
			if carry_type == RES_FOOD and cid >= 0 and cid < _city_hunger_cache.size() and _city_hunger_cache[cid] >= 0.45:
				if _fx != null and _fx.has_method("spawn_reaction_strip") and _strip_fx_budget > 0 and _rng.randf() < 0.30:
					_strip_fx_budget -= 1
					_fx.call("spawn_reaction_strip", Vector2(_px[unit_idx], _py[unit_idx] - 7.0), STRIP_FOOD)
			_u_carry_type[unit_idx] = CARRY_NONE
			_u_carry_amt[unit_idx] = 0.0
			_u_task[unit_idx] = TASK_IDLE
			_assign_worker_goal(unit_idx, cid)
			if _u_task[unit_idx] == TASK_HARVEST:
				return Vector2.ZERO
			return _steer_worker(unit_idx, pos, _u_target_pos[unit_idx], speed, safe_dt)
		return _steer_worker(unit_idx, pos, _u_target_pos[unit_idx], speed, safe_dt)

	if task == TASK_PATROL:
		_u_work_timer[unit_idx] -= safe_dt
		var dist_p := pos.distance_to(_u_target_pos[unit_idx])
		if dist_p <= TUNING_KNOBS["WORKER_REACH_PX"] or _u_work_timer[unit_idx] <= 0.0 or _u_stuck_timer[unit_idx] > 2.8:
			_assign_worker_goal(unit_idx, cid)
			return Vector2.ZERO
		return _steer_worker(unit_idx, pos, _u_target_pos[unit_idx], speed, safe_dt)

	return Vector2.ZERO


func _ensure_unit_mm_buf(mm: MultiMesh) -> bool:
	var cap := mm.instance_count
	var need_floats := cap * 16
	if _unit_mm_buf.size() != need_floats:
		_unit_mm_buf.resize(need_floats)
		_unit_mm_buf.fill(0.0)
		for k in range(cap):
			var base := k * 16
			_unit_mm_buf[base] = 1.0
			_unit_mm_buf[base + 5] = 1.0
			_unit_mm_buf[base + 11] = 1.0
		_unit_colors_dirty = true
	return _unit_colors_dirty


func _pick_unit_col(fac: int, role: int, task: int, spd: float, kb: float, pt_i: int, harv_frame: int, idx: int) -> int:
	if role == ROLE_MUTANT or fac == FACTION_MUTANT:
		return UCOL_MUTANT_CRYSTAL_A + (pt_i & 1)
	if kb > 0.14 and fac != FACTION_ROBOT and fac != FACTION_SPORE:
		return UCOL_HUMAN_JETPACK
	if fac == FACTION_ROBOT:
		if task == TASK_HAUL_DEPOT:
			return UCOL_ROBOT_CARGO
		if role == ROLE_SOLDIER:
			return UCOL_ROBOT_HEAVY_A + ((pt_i & 1) if (spd > 2.5 or task == TASK_PATROL) else 0)
		if role == ROLE_FARMER:
			return UCOL_ROBOT_DRONE_A + ((pt_i ^ idx) & 1)
		return UCOL_ROBOT_WALKER_A + ((harv_frame + idx) & 1 if task == TASK_HARVEST else ((pt_i & 1) if spd > 2.5 else 0))
	if fac == FACTION_SPORE:
		if task == TASK_HAUL_DEPOT:
			return UCOL_SPORE_CARGO
		if role == ROLE_SOLDIER:
			return UCOL_SPORE_STALKER_A + ((pt_i & 1) if (spd > 2.5 or task == TASK_PATROL) else 0)
		return UCOL_SPORE_CRAWLER_A + ((harv_frame + idx) & 1 if task == TASK_HARVEST else ((pt_i & 1) if spd > 2.5 else 0))
	if task == TASK_HAUL_DEPOT:
		return UCOL_HUMAN_CARGO
	if task == TASK_HARVEST:
		return UCOL_HUMAN_ENGINEER if role == ROLE_BUILDER else UCOL_HUMAN_WORK
	if role == ROLE_SOLDIER:
		return UCOL_HUMAN_SOLDIER_A + ((pt_i & 1) if (spd > 2.5 or task == TASK_PATROL) else 0)
	if role == ROLE_BUILDER:
		return UCOL_HUMAN_ENGINEER
	if role == ROLE_FARMER:
		return UCOL_HUMAN_FARMER
	return UCOL_HUMAN_WALK_A + ((pt_i & 1) if spd > 3.0 else 0)


func _update_wanderer_beacon(unit_idx: int, px_f: float, py_f: float) -> void:
	var n_cities := mini(_city_active.size(), _city_depot_pos.size())
	if _city_center.size() > 0:
		n_cities = mini(_city_active.size(), _city_center.size())
	var beacon_r: float = TUNING_KNOBS["WANDERER_BEACON_RADIUS_PX"]
	var best_d2 := beacon_r * beacon_r
	var best_pos := Vector2(-1.0, -1.0)
	for c in range(n_cities):
		if _city_active[c] == 0:
			continue
		var cp := _city_center[c] if c < _city_center.size() else _city_depot_pos[c]
		if cp.x < 0.0:
			continue
		var dx := cp.x - px_f
		var dy := cp.y - py_f
		var d2 := dx * dx + dy * dy
		if d2 <= best_d2:
			best_d2 = d2
			best_pos = cp
	_u_beacon_pos[unit_idx] = best_pos


func _find_cool_or_water_dir(pos: Vector2) -> Vector2:
	if _world == null:
		return Vector2.ZERO
	var cur_x := clampi(int(pos.x), 0, _map_w - 1)
	var cur_y := clampi(int(pos.y), 0, _map_h - 1)
	var best_score := float(_world.get_temp(cur_x, cur_y))
	var best_dir := Vector2.ZERO
	var has_env := _world.has_method("get_tile_env")
	for k in range(6):
		var a := float(k) * (TAU / 6.0)
		var d := Vector2(cos(a), sin(a))
		var sx := clampi(int(pos.x + d.x * 9.0), 0, _map_w - 1)
		var sy := clampi(int(pos.y + d.y * 9.0), 0, _map_h - 1)
		var st: int = _get_tile_tier(sx, sy)
		if st == TIER_SHALLOW:
			return d
		if st <= TIER_CLOSE_OCEAN or st >= TIER_SUMMIT:
			continue
		var s_temp: float = _world.get_temp(sx, sy)
		var s_fire := 0.0
		if has_env:
			var env: Vector4 = _world.get_tile_env(sx, sy)
			s_temp = env.x
			s_fire = env.z
		var sc := s_temp + s_fire * 95.0
		if sc < best_score - 2.0:
			best_score = sc
			best_dir = d
	return best_dir


func step_physics(dt: float) -> void:
	_ensure_layers()
	var safe_dt := clampf(dt, 0.0, 0.1)
	if safe_dt <= 0.0:
		return

	_sim_time += safe_dt
	_tick_idx += 1
	_vortex_fx_cd = maxf(0.0, _vortex_fx_cd - safe_dt)
	_vortex_alchemy_cd = maxf(0.0, _vortex_alchemy_cd - safe_dt)
	_impact_fx_cd = maxf(0.0, _impact_fx_cd - safe_dt)
	_area_fx_cd = maxf(0.0, _area_fx_cd - safe_dt)
	_flora_regrow_cd = maxf(0.0, _flora_regrow_cd - safe_dt)
	_campfire_ember_cd = maxf(0.0, _campfire_ember_cd - safe_dt)
	_skirmish_sfx_cd = maxf(0.0, _skirmish_sfx_cd - safe_dt)
	_possess_cd = maxf(0.0, _possess_cd - safe_dt)
	_spar_fx_cd = maxf(0.0, _spar_fx_cd - safe_dt)
	_work_fx_budget = 4
	_strip_fx_budget = 6

	if _civ != null and _city_hunger_cache.size() >= MAX_CITIES and _civ.has_method("get_city_hunger_pressure"):
		var c_lim := mini(_city_active.size(), MAX_CITIES)
		for c in range(c_lim):
			if _city_active[c] != 0:
				_city_hunger_cache[c] = float(_civ.call("get_city_hunger_pressure", c))
			else:
				_city_hunger_cache[c] = 0.0

	var tick_i := _tick_idx
	if _spatial_hash_dirty or (tick_i & 1) == 0:
		_rebuild_spatial_hash()

	var mm := _mm_units.multimesh
	var upload_colors := _ensure_unit_mm_buf(mm)

	var base_speed: float = TUNING_KNOBS["COLONIST_SPEED"]
	var sep_r: float = TUNING_KNOBS["SEPARATION_RADIUS"]
	var sep_r2 := sep_r * sep_r
	var inv_sep_r := 1.0 / sep_r
	var flock_r: float = TUNING_KNOBS["FLOCK_RADIUS"]
	var flock_r2 := flock_r * flock_r
	var sep_w: float = TUNING_KNOBS["SEPARATION_WEIGHT"]
	var coh_w: float = TUNING_KNOBS["COHESION_WEIGHT"]
	var ali_w: float = TUNING_KNOBS["ALIGNMENT_WEIGHT"]
	var wan_w: float = TUNING_KNOBS["WANDER_WEIGHT"]
	var slope_resist: float = TUNING_KNOBS["SLOPE_RESIST"]
	var slope_slide: float = TUNING_KNOBS["SLOPE_SLIDE"]
	var water_avoid: float = TUNING_KNOBS["WATER_AVOID_FORCE"]
	var lava_mult: float = TUNING_KNOBS["LAVA_FLEE_SPEED_MULT"]
	var hot_thresh: float = TUNING_KNOBS["HOT_TEMP_THRESHOLD"]
	var road_bonus: float = TUNING_KNOBS["ROAD_SPEED_BONUS"]
	var max_neighbors: int = TUNING_KNOBS["MAX_NEIGHBORS_CHECKED"]
	var skirmish_range: float = TUNING_KNOBS["SKIRMISH_RANGE_PX"]
	var skirmish_r2 := skirmish_range * skirmish_range
	var skirmish_cd_base: float = TUNING_KNOBS["SKIRMISH_COOLDOWN_SEC"]
	var rad_mut_thresh: float = TUNING_KNOBS["RAD_MUTATE_THRESHOLD"]
	var human_range_px: float = TUNING_KNOBS["HUMAN_ATTACK_RANGE_PX"]
	var human_cd_sec: float = TUNING_KNOBS["HUMAN_ATTACK_CD_SEC"]
	var human_dmg: float = TUNING_KNOBS["HUMAN_DAMAGE"]
	var human_dodge_p: float = TUNING_KNOBS["HUMAN_DODGE_CHANCE"]
	var human_dodge_spd: float = TUNING_KNOBS["HUMAN_DODGE_SPEED"]
	var robot_range_px: float = TUNING_KNOBS["ROBOT_ATTACK_RANGE_PX"]
	var robot_cd_sec: float = TUNING_KNOBS["ROBOT_ATTACK_CD_SEC"]
	var robot_dmg: float = TUNING_KNOBS["ROBOT_DAMAGE"]
	var robot_speed_mult: float = TUNING_KNOBS["ROBOT_SPEED_MULT"]
	var robot_armor_mult: float = TUNING_KNOBS["ROBOT_ARMOR_MULT"]
	var spore_range_px: float = TUNING_KNOBS["SPORE_ATTACK_RANGE_PX"]
	var spore_cd_sec: float = TUNING_KNOBS["SPORE_ATTACK_CD_SEC"]
	var spore_dmg: float = TUNING_KNOBS["SPORE_DAMAGE"]
	var spore_speed_mult: float = TUNING_KNOBS["SPORE_SPEED_MULT"]
	var spore_regen_myc: float = TUNING_KNOBS["SPORE_REGEN_MYCELIUM"]
	var spore_corrode_dps: float = TUNING_KNOBS["SPORE_CORRODE_DPS"]
	var spore_corrode_sec: float = TUNING_KNOBS["SPORE_CORRODE_SEC"]
	var virus_dps: float = TUNING_KNOBS["VIRUS_DPS"]

	var blend_kb := exp(-3.2 * safe_dt)
	var harv_keep := exp(-14.0 * safe_dt)
	var blend_vel := 1.0 - exp(-6.5 * safe_dt)
	var hp_regen := 8.0 * safe_dt
	var hp_burn := 28.0 * safe_dt
	var wan_p := minf(1.0, safe_dt * 1.8)
	var scan_p := safe_dt * 0.65
	var dust_p := safe_dt * 0.35

	var has_world := _world != null
	var has_tile_env := has_world and _world.has_method("get_tile_env")
	var has_moist := has_world and _world.has_method("get_moisture")
	var has_fx := _fx != null
	var city_active_sz := _city_active.size()
	var city_alerted_sz := _city_alerted.size()
	var city_war_sz := _city_war_state.size()
	var city_rebel_sz := _city_is_rebel.size()
	var city_emp_sz := _city_emp_timer.size()
	var map_w_i := _map_w
	var map_h_i := _map_h
	var map_w_m1 := _map_w - 1
	var map_h_m1 := _map_h - 1
	var grid_w_i := _grid_w
	var grid_w_m1 := _grid_w - 1
	var grid_h_m1 := _grid_h - 1
	var has_tc := has_world and _tc_tier.size() >= map_w_i * map_h_i
	var has_tc_env := has_tc and _tc_biome.size() >= map_w_i * map_h_i and _tc_grad_x.size() >= map_w_i * map_h_i

	var check_blds := _bld_count > 0 and _zone_w > 0 and _zone_h > 0 and _bld_occ.size() >= _zone_w * _zone_h
	var zone_wi := _zone_w
	var zone_wm1 := _zone_w - 1
	var zone_hm1 := _zone_h - 1
	var road_len := _road_mask.size()
	var road_is_map := road_len >= map_w_i * map_h_i
	var road_is_zone := (not road_is_map) and (_zone_w > 0 and _zone_h > 0 and road_len >= _zone_w * _zone_h)

	var spark_budget := 6
	var splash_budget := 5
	var scan_budget := 4
	var dust_budget := 4
	var skirmish_fx_budget := 4
	var min_x := 2.0
	var max_x := float(map_w_i - 3)
	var min_y := 2.0
	var max_y := float(map_h_i - 3)

	var scan_edge_sep := 16.0 - sep_r
	var scan_edge_flk := 16.0 - flock_r
	var inv_pi := 0.318309886
	var tau4 := TAU * 4.0
	var harv_frame := int(_sim_time * 7.5)
	var harv_t := _sim_time * 5.729578
	var any_died := false
	var next_any_inf := false
	var next_any_glitch := false
	var any_inf := _any_infected_unit
	var inf_sz := _u_infected_timer.size()
	var lat_sz := _u_latent_timer.size()
	var diplo_sz := _diplo_matrix.size()
	var diplo_stride := _diplo_max_cities

	for i in range(_unit_count):
		var hp_val := _hp[i]
		if hp_val <= 0.0:
			any_died = true
			continue

		var cid := _u_city_id[i]
		if cid >= 0 and cid < city_active_sz and _city_active[cid] == 0:
			_release_single_worker(i, cid)
			cid = -1
		var fac := int(_u_faction_id[i])
		var role := int(_u_role[i])
		var uid_val := _u_uid[i]
		var is_possessed := (uid_val == _possessed_uid)
		var kb := _knockback_timer[i]
		var flash_val := maxf(0.0, _hit_flash_timer[i] - safe_dt)
		_hit_flash_timer[i] = flash_val
		var atk_cd := maxf(0.0, _u_attack_cd[i] - safe_dt)
		_u_attack_cd[i] = atk_cd
		var dodge_cd := maxf(0.0, _u_dodge_cd[i] - safe_dt)
		_u_dodge_cd[i] = dodge_cd
		var spar_cd := maxf(0.0, _u_sparring_cd[i] - safe_dt)
		_u_sparring_cd[i] = spar_cd
		var acq_cd := maxf(0.0, _u_acq_cd[i] - safe_dt) if i < _u_acq_cd.size() else 0.0
		if i < _u_acq_cd.size():
			_u_acq_cd[i] = acq_cd
		var glitch_t := maxf(0.0, _u_glitch_timer[i] - safe_dt) if i < _u_glitch_timer.size() else 0.0
		if i < _u_glitch_timer.size():
			_u_glitch_timer[i] = glitch_t
		var inf_t := maxf(0.0, _u_infected_timer[i] - safe_dt) if i < inf_sz else 0.0
		if i < inf_sz:
			_u_infected_timer[i] = inf_t
		var corr_t := maxf(0.0, _u_corrode_timer[i] - safe_dt) if i < _u_corrode_timer.size() else 0.0
		if i < _u_corrode_timer.size():
			_u_corrode_timer[i] = corr_t
		var invuln_t := maxf(0.0, _u_invuln_timer[i] - safe_dt) if i < _u_invuln_timer.size() else 0.0
		if i < _u_invuln_timer.size():
			_u_invuln_timer[i] = invuln_t
		var latent_t := maxf(0.0, _u_latent_timer[i] - safe_dt) if i < lat_sz else 0.0
		if i < lat_sz:
			_u_latent_timer[i] = latent_t

		var is_glitched := glitch_t > 0.0
		var is_infected_raw := inf_t > 0.0
		var is_latent := is_infected_raw and latent_t > 0.0
		var is_infected := is_infected_raw and not is_latent
		if is_glitched:
			next_any_glitch = true
		if is_infected_raw:
			next_any_inf = true
		var is_invuln := invuln_t > 0.0
		var is_emp := (cid >= 0 and cid < city_emp_sz and _city_emp_timer[cid] > 0.0)
		var is_war := (cid >= 0 and ((cid < city_war_sz and _city_war_state[cid] >= DIPLO_TOTAL_WAR) or (cid < city_rebel_sz and _city_is_rebel[cid] != 0)))

		if is_infected and fac == FACTION_SPORE:
			hp_val = minf(100.0, hp_val + 2.0 * safe_dt)
			_hp[i] = hp_val
		if not is_invuln:
			if is_infected and fac != FACTION_SPORE:
				hp_val -= (virus_dps * (0.38 if fac == FACTION_ROBOT else 1.0)) * safe_dt
				_hp[i] = hp_val
			if corr_t > 0.0:
				hp_val -= (spore_corrode_dps * (0.55 if fac == FACTION_ROBOT and not is_glitched and not is_emp else 1.0)) * safe_dt
				_hp[i] = hp_val
			if hp_val <= 0.0:
				_hp[i] = hp_val
				any_died = true
				continue

		var px_f := _px[i]
		var py_f := _py[i]
		var vx := _vx[i]
		var vy := _vy[i]

		# 1) Spatial-hash boids + diplomacy hostility / asymmetric combat / sparring scan
		var my_range_px := skirmish_range
		var my_cd_sec := skirmish_cd_base * 1.45
		var my_dmg := 8.0
		if role == ROLE_MUTANT:
			my_range_px = skirmish_range
			my_cd_sec = skirmish_cd_base * 0.85
			my_dmg = 16.0
		elif fac == FACTION_ROBOT:
			my_range_px = robot_range_px
			my_cd_sec = robot_cd_sec
			my_dmg = robot_dmg
		elif fac == FACTION_SPORE:
			my_range_px = spore_range_px
			my_cd_sec = spore_cd_sec
			my_dmg = spore_dmg
		elif fac == FACTION_HUMAN:
			my_range_px = human_range_px
			my_cd_sec = human_cd_sec
			my_dmg = human_dmg
		if role != ROLE_SOLDIER and role != ROLE_MUTANT:
			my_range_px = minf(my_range_px * 0.45, 58.0)
			my_cd_sec *= 1.45
			my_dmg *= 0.55
		if is_emp:
			my_cd_sec *= 1.45
		if is_infected:
			my_cd_sec *= (0.72 if fac == FACTION_SPORE else 0.82)
			if fac == FACTION_SPORE:
				my_dmg *= 1.18

		var ax := 0.0
		var ay := 0.0
		var is_combat := (role == ROLE_SOLDIER or role == ROLE_MUTANT)
		var is_alerted_local := (cid >= 0 and cid < city_alerted_sz and _city_alerted[cid] != 0)
		var is_alerted := is_alerted_local or is_war
		var do_boids := true if (is_combat or is_alerted_local or is_possessed or is_infected or is_glitched) else (((i + tick_i) & 1) == 0 if cid >= 0 else ((i + tick_i) & 3) == 0)
		var enemy_idx := -1
		var enemy_d2 := 1e18
		var enemy_x := 0.0
		var enemy_y := 0.0
		var spar_idx := -1
		var spar_d2 := 1e18
		var spar_x := 0.0
		var spar_y := 0.0
		var hunger_c := _city_hunger_cache[cid] if (cid >= 0 and cid < MAX_CITIES) else 0.0
		var can_spar := (cid >= 0 and role == ROLE_SOLDIER and atk_cd <= 0.0 and spar_cd <= 0.0 and not is_alerted and not is_possessed and not is_infected and not is_glitched and hp_val > 55.0 and hunger_c < 0.45)

		if do_boids:
			var cx := clampi(int(px_f) >> 4, 0, grid_w_m1)
			var cy := clampi(int(py_f) >> 4, 0, grid_h_m1)
			var use_flock := (cid < 0 and role != ROLE_MUTANT)
			var nb_cap := mini(8, max_neighbors)
			var scan_r := maxf(flock_r, skirmish_range) if (use_flock or is_combat or is_alerted_local) else sep_r
			var edge_r := 16.0 - scan_r
			var fx_cell := px_f - float(cx << 4)
			var fy_cell := py_f - float(cy << 4)
			var x0 := cx - 1 if (cx > 0 and fx_cell < scan_r) else cx
			var x1 := cx + 1 if (cx < grid_w_m1 and fx_cell > edge_r) else cx
			var y0 := cy - 1 if (cy > 0 and fy_cell < scan_r) else cy
			var y1 := cy + 1 if (cy < grid_h_m1 and fy_cell > edge_r) else cy

			var sep_x := 0.0
			var sep_y := 0.0
			var fp_x := 0.0
			var fp_y := 0.0
			var fv_x := 0.0
			var fv_y := 0.0
			var flock_count := 0
			var checked := 0
			var combat_scan_r2 := (28.0 * 28.0) if (is_combat or is_war or is_infected or is_glitched) else (skirmish_r2 if fac != FACTION_NONE else 144.0)
			var mut_i := (role == ROLE_MUTANT or fac == FACTION_MUTANT)

			for gy in range(y0, y1 + 1):
				var row_off := gy * grid_w_i
				for gx in range(x0, x1 + 1):
					var j := _cell_head[row_off + gx]
					while j != -1:
						if j != i and _hp[j] > 0.0:
							var jpx := _px[j]
							var jpy := _py[j]
							var dx := px_f - jpx
							var dy := py_f - jpy
							var d2 := dx * dx + dy * dy
							var j_fac := int(_u_faction_id[j])
							var j_cid := _u_city_id[j]
							var j_mut := (_u_role[j] == ROLE_MUTANT or j_fac == FACTION_MUTANT)
							var j_inf := any_inf and j < inf_sz and _u_infected_timer[j] > 0.0 and (j >= lat_sz or _u_latent_timer[j] <= 0.0)
							var hostile := false
							if mut_i != j_mut:
								hostile = true
							elif is_infected != j_inf and (fac != FACTION_SPORE or j_fac != FACTION_SPORE or cid < 0 or cid != j_cid):
								hostile = true
							elif is_glitched:
								hostile = true
							elif cid >= 0 and j_cid >= 0 and cid != j_cid and diplo_stride > 0 and cid < diplo_stride and j_cid < diplo_stride:
								var di1 := cid * diplo_stride + j_cid
								var di2 := j_cid * diplo_stride + cid
								if di1 < diplo_sz and di2 < diplo_sz:
									var r1 := int(_diplo_matrix[di1])
									var r2_d := int(_diplo_matrix[di2])
									var rel := r1 if r1 >= r2_d else r2_d
									hostile = (rel == DIPLO_TOTAL_WAR or rel == DIPLO_REBELLION)
							if hostile and d2 < combat_scan_r2 and d2 < enemy_d2:
								enemy_d2 = d2
								enemy_idx = j
								enemy_x = jpx
								enemy_y = jpy
							elif can_spar and not hostile and _u_city_id[j] == cid and j_fac == fac and _u_role[j] == ROLE_SOLDIER and d2 < 196.0 and d2 < spar_d2 and _hp[j] > 55.0 and _u_sparring_cd[j] <= 0.0 and _u_uid[j] != _possessed_uid:
								spar_d2 = d2
								spar_idx = j
								spar_x = jpx
								spar_y = jpy
							if d2 < sep_r2:
								if d2 > 0.0025:
									var d := sqrt(d2)
									var inv_d := ((sep_r - d) * inv_sep_r) / d
									sep_x += dx * inv_d
									sep_y += dy * inv_d
								else:
									var ang := float(i) * 1.618
									sep_x += cos(ang)
									sep_y += sin(ang)
							elif use_flock and not hostile and d2 < flock_r2:
								fp_x += jpx
								fp_y += jpy
								fv_x += _vx[j]
								fv_y += _vy[j]
								flock_count += 1
							checked += 1
							if checked >= nb_cap:
								break
						j = _unit_next[j]
					if checked >= nb_cap:
						break
				if checked >= nb_cap:
					break

			var sep_mult := 1.0
			if cid >= 0:
				sep_mult = 0.25 if _u_task[i] == TASK_HARVEST else 0.45
			var sw := sep_w * sep_mult
			ax = sep_x * sw
			ay = sep_y * sw
			if use_flock and flock_count > 0:
				var inv_fc := 1.0 / float(flock_count)
				var coh_x := (fp_x * inv_fc) - px_f
				var coh_y := (fp_y * inv_fc) - py_f
				var coh_l2 := coh_x * coh_x + coh_y * coh_y
				if coh_l2 > 1.0:
					var inv_c := coh_w / sqrt(coh_l2)
					ax += coh_x * inv_c
					ay += coh_y * inv_c
				var av_x := fv_x * inv_fc
				var av_y := fv_y * inv_fc
				var av_l2 := av_x * av_x + av_y * av_y
				if av_l2 > 1.0:
					var inv_a := ali_w / sqrt(av_l2)
					ax += av_x * inv_a
					ay += av_y * inv_a
			_u_boids_ax[i] = ax
			_u_boids_ay[i] = ay
		else:
			ax = _u_boids_ax[i] * 0.90
			ay = _u_boids_ay[i] * 0.90

		var atk_r2 := my_range_px * my_range_px
		if enemy_idx >= 0:
			_u_target_idx[i] = enemy_idx
			_u_target_uid[i] = _u_uid[enemy_idx]
		elif my_range_px > 20.0:
			var cand_slot := _u_target_idx[i]
			var cand_uid := _u_target_uid[i]
			if cand_slot >= 0 and cand_slot < _unit_count and _u_uid[cand_slot] == cand_uid and _hp[cand_slot] > 0.0:
				var cdx := px_f - _px[cand_slot]
				var cdy := py_f - _py[cand_slot]
				var cd2 := cdx * cdx + cdy * cdy
				if cd2 <= atk_r2 and _are_units_hostile(i, cand_slot):
					enemy_idx = cand_slot
					enemy_x = _px[cand_slot]
					enemy_y = _py[cand_slot]
					enemy_d2 = cd2
				else:
					_u_target_idx[i] = -1
					_u_target_uid[i] = -1
			elif cand_uid >= 0:
				_u_target_idx[i] = -1
				_u_target_uid[i] = -1

			if enemy_idx < 0 and acq_cd <= 0.0 and (role == ROLE_SOLDIER or is_infected or is_glitched or (is_alerted and (_u_task[i] == TASK_PATROL or _u_task[i] == TASK_IDLE))):
				var r_enemy := _find_ranged_enemy_idx(i, px_f, py_f, my_range_px)
				if r_enemy >= 0:
					_u_acq_cd[i] = 0.24 + float((i + tick_i) & 3) * 0.02
					_u_target_idx[i] = r_enemy
					_u_target_uid[i] = _u_uid[r_enemy]
					enemy_idx = r_enemy
					enemy_x = _px[r_enemy]
					enemy_y = _py[r_enemy]
					var edx := px_f - enemy_x
					var edy := py_f - enemy_y
					enemy_d2 = edx * edx + edy * edy
				else:
					_u_acq_cd[i] = (0.36 if (role == ROLE_SOLDIER or is_infected or is_glitched) else 0.72) + float((i + tick_i) & 3) * 0.05

		# Execute diplomacy/mutant ranged or melee combat hit (with WorldBox Side-Step dodge) or non-lethal sparring
		if enemy_idx >= 0 and atk_cd <= 0.0 and enemy_d2 <= atk_r2:
			_u_attack_cd[i] = my_cd_sec
			var dmg := my_dmg
			var k_dist := maxf(sqrt(enemy_d2), 0.5)
			var kdx := (enemy_x - px_f) / k_dist
			var kdy := (enemy_y - py_f) / k_dist
			_facing[i] = 1.0 if kdx >= 0.0 else -1.0
			_skirmish_count += 1

			var p_src := Vector2(px_f, py_f - 2.5)
			var p_dst := Vector2(enemy_x, enemy_y - 2.5)
			var beam_col := _get_faction_beam_color(i)
			if role != ROLE_MUTANT:
				var is_heavy: int = 1 if fac == FACTION_ROBOT else 0
				var b_width: float = 1.65 if is_heavy != 0 else (1.25 if fac == FACTION_SPORE else 1.0)
				_beam_starts.append(p_src)
				_beam_ends.append(p_dst)
				_beam_colors.append(beam_col)
				_beam_widths.append(b_width)
				_beam_heavy.append(is_heavy)

			var def_role := int(_u_role[enemy_idx])
			var def_fac := int(_u_faction_id[enemy_idx])
			var def_cid := _u_city_id[enemy_idx]
			var def_glitched := (enemy_idx < _u_glitch_timer.size() and _u_glitch_timer[enemy_idx] > 0.0)
			var def_invuln := (enemy_idx < _u_invuln_timer.size() and _u_invuln_timer[enemy_idx] > 0.0)
			var dodge_p := (human_dodge_p if def_fac == FACTION_HUMAN else (0.14 if def_fac == FACTION_ROBOT else 0.24)) if (def_role == ROLE_SOLDIER or def_role == ROLE_MUTANT) else (0.18 if def_fac == FACTION_HUMAN else 0.10)
			if def_glitched:
				dodge_p *= 0.25
			if _u_dodge_cd[enemy_idx] <= 0.0 and _rng.randf() < dodge_p:
				var d_sign := 1.0 if ((enemy_idx + tick_i) & 1) == 0 else -1.0
				var d_spd := human_dodge_spd if def_fac == FACTION_HUMAN else 56.0
				var dvx := -kdy * d_sign
				var dvy := kdx * d_sign
				if has_world and not _is_walkable_pos(Vector2(enemy_x + dvx * 5.0, enemy_y + dvy * 5.0)):
					d_sign = -d_sign
					dvx = -kdy * d_sign
					dvy = kdx * d_sign
					if not _is_walkable_pos(Vector2(enemy_x + dvx * 5.0, enemy_y + dvy * 5.0)):
						dvx = 0.0
						dvy = 0.0
				var pvx := dvx * d_spd
				var pvy := dvy * d_spd
				_vx[enemy_idx] = pvx
				_vy[enemy_idx] = pvy
				_vel[enemy_idx] = Vector2(pvx, pvy)
				_knockback_timer[enemy_idx] = maxf(_knockback_timer[enemy_idx], 0.18)
				_u_dodge_cd[enemy_idx] = 1.65 if def_fac == FACTION_HUMAN else 1.85
				_u_dodges[enemy_idx] += 1
				_total_dodges += 1
				_hit_flash_timer[enemy_idx] = maxf(_hit_flash_timer[enemy_idx], 0.14)
				_record_memory(enemy_idx, MEM_DODGED)
				if has_fx and _fx.has_method("spawn_reaction_strip") and _strip_fx_budget > 0:
					_strip_fx_budget -= 1
					_fx.call("spawn_reaction_strip", Vector2(enemy_x, enemy_y - 7.0), STRIP_DODGE)
				if skirmish_fx_budget > 0 and has_fx:
					skirmish_fx_budget -= 1
					if role != ROLE_MUTANT:
						_fx.emit_laser_tracer(p_src, p_dst, beam_col)
					_fx.emit_spark_arc(p_dst, Vector2(-kdy * d_sign, kdx * d_sign), Color(0.55, 0.96, 1.0, 0.95))
			else:
				if not def_invuln:
					var final_dmg := dmg
					var def_emp := (def_cid >= 0 and def_cid < city_emp_sz and _city_emp_timer[def_cid] > 0.0)
					if def_fac == FACTION_ROBOT and not def_glitched and not def_emp:
						final_dmg *= robot_armor_mult
					_hp[enemy_idx] -= final_dmg
					if fac == FACTION_SPORE and enemy_idx < _u_corrode_timer.size():
						_u_corrode_timer[enemy_idx] = maxf(_u_corrode_timer[enemy_idx], spore_corrode_sec)
					if is_infected and enemy_d2 <= 400.0 and def_fac != FACTION_ROBOT and enemy_idx < inf_sz and _rng.randf() < 0.30:
						var was_clean := _u_infected_timer[enemy_idx] <= 0.0
						_u_infected_timer[enemy_idx] = maxf(_u_infected_timer[enemy_idx], 4.5)
						if was_clean and enemy_idx < lat_sz:
							_u_latent_timer[enemy_idx] = 0.0
						_record_memory(enemy_idx, MEM_INFECTED)
						next_any_inf = true
						_any_infected_unit = true
						if was_clean and has_fx and _fx.has_method("spawn_reaction_strip") and _strip_fx_budget > 0:
							_strip_fx_budget -= 1
							_fx.call("spawn_reaction_strip", Vector2(enemy_x, enemy_y - 7.0), STRIP_SKULL)
				_vx[enemy_idx] += kdx * 36.0
				_vy[enemy_idx] += kdy * 36.0
				_knockback_timer[enemy_idx] = maxf(_knockback_timer[enemy_idx], 0.18)
				_hit_flash_timer[enemy_idx] = maxf(_hit_flash_timer[enemy_idx], 0.16)
				_record_memory(i, MEM_FOUGHT)
				_record_memory(enemy_idx, MEM_FOUGHT)
				if _hp[enemy_idx] <= 0.0:
					_u_kills[i] += 1
					any_died = true
				if skirmish_fx_budget > 0 and has_fx:
					skirmish_fx_budget -= 1
					if role == ROLE_MUTANT:
						_fx.emit_spark_arc(p_dst, Vector2(kdx, kdy), BEAM_COL_MUTANT)
					elif fac == FACTION_SPORE:
						_fx.emit_laser_tracer(p_src, p_dst, beam_col)
						_fx.emit_spark_arc(p_dst, Vector2(kdx, kdy), beam_col)
					else:
						_fx.emit_laser_tracer(p_src, p_dst, beam_col)
					if role == ROLE_MUTANT and _skirmish_sfx_cd <= 0.0:
						_skirmish_sfx_cd = 0.09
						_fx.play_sfx("skirmish")
		elif can_spar and spar_idx >= 0 and spar_d2 <= 100.0:
			_u_attack_cd[i] = 0.85
			_u_sparring_cd[i] = _rng.randf_range(12.0, 22.0)
			_u_sparring_cd[spar_idx] = _rng.randf_range(12.0, 22.0)
			var s_dist := maxf(sqrt(spar_d2), 0.5)
			var sdx := (spar_x - px_f) / s_dist
			var sdy := (spar_y - py_f) / s_dist
			_facing[i] = 1.0 if sdx >= 0.0 else -1.0
			_skirmish_count += 1
			var sp_dodge_p := 0.25 if _u_role[spar_idx] == ROLE_SOLDIER else 0.15
			if _u_dodge_cd[spar_idx] <= 0.0 and _rng.randf() < sp_dodge_p:
				var sd_sign := 1.0 if ((spar_idx + tick_i) & 1) == 0 else -1.0
				var svx := -sdy * sd_sign
				var svy := sdx * sd_sign
				if has_world and not _is_walkable_pos(Vector2(spar_x + svx * 4.5, spar_y + svy * 4.5)):
					sd_sign = -sd_sign
					svx = -sdy * sd_sign
					svy = sdx * sd_sign
					if not _is_walkable_pos(Vector2(spar_x + svx * 4.5, spar_y + svy * 4.5)):
						svx = 0.0
						svy = 0.0
				_vx[spar_idx] = svx * 54.0
				_vy[spar_idx] = svy * 54.0
				_vel[spar_idx] = Vector2(_vx[spar_idx], _vy[spar_idx])
				_knockback_timer[spar_idx] = maxf(_knockback_timer[spar_idx], 0.16)
				_u_dodge_cd[spar_idx] = 1.8
				_u_dodges[spar_idx] += 1
				_total_dodges += 1
				_hit_flash_timer[spar_idx] = maxf(_hit_flash_timer[spar_idx], 0.14)
				_record_memory(spar_idx, MEM_DODGED)
				if has_fx and _fx.has_method("spawn_reaction_strip") and _strip_fx_budget > 0:
					_strip_fx_budget -= 1
					_fx.call("spawn_reaction_strip", Vector2(spar_x, spar_y - 7.0), STRIP_DODGE)
			else:
				_hp[spar_idx] = maxf(45.0, _hp[spar_idx] - 9.0)
				_vx[spar_idx] += sdx * 30.0
				_vy[spar_idx] += sdy * 30.0
				_knockback_timer[spar_idx] = maxf(_knockback_timer[spar_idx], 0.18)
				_hit_flash_timer[spar_idx] = maxf(_hit_flash_timer[spar_idx], 0.14)
				_record_memory(i, MEM_FOUGHT)
				_record_memory(spar_idx, MEM_FOUGHT)
				if has_fx and _fx.has_method("spawn_reaction_strip") and _strip_fx_budget > 0:
					_strip_fx_budget -= 1
					_fx.call("spawn_reaction_strip", Vector2(spar_x, spar_y - 7.0), STRIP_BLOCK)
				if has_fx and _spar_fx_cd <= 0.0:
					_spar_fx_cd = 0.25
					_fx.emit_spark_arc(Vector2(spar_x, spar_y - 2.5), Vector2(sdx, sdy), Color(0.95, 0.85, 0.42, 0.90))

		# 2) Cached 1px tier + biome/temp/rad/fire affinities + asymmetric speed & mortality
		var speed_target := base_speed
		if role == ROLE_MUTANT:
			speed_target *= 1.24
		elif fac == FACTION_ROBOT:
			speed_target *= robot_speed_mult
		elif fac == FACTION_SPORE:
			speed_target *= spore_speed_mult
		elif fac == FACTION_HUMAN:
			speed_target *= 1.02
		if is_infected:
			speed_target *= (1.38 if fac == FACTION_SPORE else 1.28)
		if is_glitched:
			speed_target *= 0.72
		if is_emp:
			speed_target *= 0.72
		var was_in_water := false
		var on_lava := false
		var px := 0
		var py := 0
		var tile_idx := 0
		var tier := TIER_SOIL_LOW
		var biome := BIOME_RUST
		var temp := 22.0
		var rad_v := 0.0
		var fire_v := 0.0
		if has_world:
			px = clampi(int(px_f), 0, map_w_m1)
			py = clampi(int(py_f), 0, map_h_m1)
			tile_idx = py * map_w_i + px
			var cached_tile := _u_last_tile[i]
			var need_full := (cached_tile < 0)
			if cached_tile == tile_idx:
				tier = int(_u_tier[i])
			else:
				if has_tc:
					var tc_v := _tc_tier[tile_idx]
					if tc_v != 0:
						tier = int(tc_v) - 1
					else:
						tier = _world.get_tier(px, py)
						_tc_tier[tile_idx] = tier + 1
				else:
					tier = _world.get_tier(px, py)
				_u_last_tile[i] = tile_idx
				_u_tier[i] = tier

			var gx := 0.0
			var gy := 0.0
			if has_tc_env:
				var tc_b := _tc_biome[tile_idx]
				if tc_b != 0:
					biome = int(tc_b) - 1
				else:
					biome = _world.get_biome(px, py)
					_tc_biome[tile_idx] = biome + 1
					if tier > TIER_SHALLOW:
						var q_grad: Vector2 = _world.get_height_grad(px, py)
						_tc_grad_x[tile_idx] = q_grad.x
						_tc_grad_y[tile_idx] = q_grad.y
					else:
						_tc_grad_x[tile_idx] = 0.0
						_tc_grad_y[tile_idx] = 0.0
				gx = _tc_grad_x[tile_idx]
				gy = _tc_grad_y[tile_idx]
			else:
				if need_full or ((i + tick_i) & 7) == 0:
					_u_biome[i] = _world.get_biome(px, py)
					if tier > TIER_SHALLOW:
						var q_grad2: Vector2 = _world.get_height_grad(px, py)
						_u_grad_x[i] = q_grad2.x
						_u_grad_y[i] = q_grad2.y
					else:
						_u_grad_x[i] = 0.0
						_u_grad_y[i] = 0.0
				biome = int(_u_biome[i])
				gx = _u_grad_x[i]
				gy = _u_grad_y[i]
			_u_biome[i] = biome

			var prev_hot := (biome == BIOME_LAVA or _u_fire_now[i] > 0.10 or _u_temp[i] > hot_thresh or _u_rad_now[i] > 0.15)
			if need_full or ((i + tick_i) & 7) == 0 or (prev_hot and ((i + tick_i) & 3) == 0):
				if has_tile_env:
					var env: Vector4 = _world.get_tile_env(px, py)
					_u_temp[i] = env.x
					_u_rad_now[i] = env.y
					_u_fire_now[i] = env.z
				else:
					_u_temp[i] = _world.get_temp(px, py)
					_u_rad_now[i] = _world.get_rad(px, py) if _world.has_method("get_rad") else 0.0
					_u_fire_now[i] = 0.0
			temp = _u_temp[i]
			rad_v = _u_rad_now[i]
			fire_v = _u_fire_now[i]

			var in_water := tier <= TIER_SHALLOW
			was_in_water = in_water

			if in_water:
				if kb > 0.04 and splash_budget > 0 and has_fx:
					splash_budget -= 1
					_fx.spawn_burst(Vector2(px_f, py_f), 4, Color(0.55, 0.90, 1.0, 0.9), 20.0, 0.30, 32.0)

				var shore := _find_shore_dir(Vector2(px_f, py_f))
				if kb <= 0.04:
					var dry_esc := _find_nearest_dry_escape(Vector2(px_f, py_f), 12.0)
					if dry_esc.x >= 0.0:
						px_f = dry_esc.x
						py_f = dry_esc.y
						_u_last_tile[i] = -1
						px = clampi(int(px_f), 0, map_w_m1)
						py = clampi(int(py_f), 0, map_h_m1)
						tier = _get_tile_tier(px, py)
						in_water = (tier <= TIER_SHALLOW)
						was_in_water = in_water
				if in_water and shore != Vector2.ZERO:
					ax = shore.x * 135.0
					ay = shore.y * 135.0
					speed_target = base_speed * 2.3
					_wander_angle[i] = atan2(shore.y, shore.x)
				if in_water:
					if fac == FACTION_SPORE:
						if tier == TIER_SHALLOW:
							hp_val = minf(100.0, hp_val + 12.0 * safe_dt)
						else:
							hp_val -= 8.0 * safe_dt
					elif tier == TIER_SHALLOW:
						if shore == Vector2.ZERO or kb <= 0.02:
							hp_val -= (7.0 if fac == FACTION_ROBOT else 10.0) * safe_dt
					else:
						hp_val -= (14.0 if fac == FACTION_ROBOT else 26.0) * safe_dt
					_hp[i] = hp_val
					if hp_val <= 0.0:
						any_died = true
			if not in_water:
				# Slope resistance & downhill slide
				var g_len_sq := gx * gx + gy * gy
				if g_len_sq > 0.0004:
					var g_len := sqrt(g_len_sq)
					var inv_gl := 1.0 / g_len
					var gd_x := gx * inv_gl
					var gd_y := gy * inv_gl
					var uphill := vx * gd_x + vy * gd_y
					if uphill > 0.0:
						var ur := uphill * slope_resist * clampf(g_len * 6.0, 0.2, 2.5)
						ax -= gd_x * ur
						ay -= gd_y * ur
					if g_len > 0.07:
						var ss := slope_slide * clampf(g_len * 4.0, 0.0, 2.0)
						ax -= gd_x * ss
						ay -= gd_y * ss

				# Faction hazard affinities & real burn mortality
				var is_hot := (biome == BIOME_LAVA or fire_v > 0.14 or temp > hot_thresh)
				if fac == FACTION_SPORE and (fire_v > 0.08 or temp > 60.0):
					is_hot = true

				if is_hot:
					on_lava = true
					var burn_dmg := hp_burn
					if fac == FACTION_ROBOT:
						if _u_lava_grace[i] > 0.0 and temp < 115.0:
							_u_lava_grace[i] = maxf(0.0, _u_lava_grace[i] - safe_dt)
							burn_dmg = 0.0
						else:
							burn_dmg = 10.0 * safe_dt
					elif fac == FACTION_SPORE:
						burn_dmg = hp_burn * 1.75
					hp_val -= burn_dmg
					_hp[i] = hp_val
					speed_target = base_speed * lava_mult
					var cool_dir := _find_cool_or_water_dir(Vector2(px_f, py_f)) if (fire_v > 0.25 or temp > hot_thresh) else Vector2.ZERO
					if cool_dir != Vector2.ZERO:
						_wander_angle[i] = atan2(cool_dir.y, cool_dir.x)
						ax += cool_dir.x * 84.0
						ay += cool_dir.y * 84.0
					else:
						var flee_ang := _wander_angle[i] + _rng.randf_range(-0.6, 0.6)
						_wander_angle[i] = flee_ang
						ax += cos(flee_ang) * 68.0
						ay += sin(flee_ang) * 68.0
					if spark_budget > 0 and has_fx and _rng.randf() < 0.35:
						spark_budget -= 1
						_fx.spawn_burst(Vector2(px_f, py_f), 2, Color(1.0, 0.55, 0.14, 1.0), 22.0, 0.32, 30.0)
					if hp_val <= 0.0:
						any_died = true
				else:
					if fac == FACTION_ROBOT:
						_u_lava_grace[i] = minf(2.4, _u_lava_grace[i] + safe_dt * 0.45)
						if rad_v > 0.06:
							hp_val = minf(100.0, hp_val + (6.0 + rad_v * 18.0) * safe_dt)
							speed_target *= 1.18
							if scan_budget > 0 and has_fx and _rng.randf() < scan_p:
								scan_budget -= 1
								_fx.spawn_burst(Vector2(px_f, py_f - 2.0), 1, Color(0.32, 0.95, 1.0, 0.9), 8.0, 0.40, -6.0)
						elif hp_val < 100.0:
							hp_val = minf(100.0, hp_val + 2.5 * safe_dt)
					elif fac == FACTION_SPORE:
						var wet := (biome == BIOME_LUSH or biome == BIOME_CRYSTAL)
						if not wet and has_moist and ((i + tick_i) & 7) == 0:
							wet = float(_world.get_moisture(px, py)) > 0.48
						var spore_regen := (spore_regen_myc * safe_dt) if wet else (5.0 * safe_dt)
						if hp_val < 100.0:
							hp_val = minf(100.0, hp_val + spore_regen)
					elif role == ROLE_MUTANT:
						var m_regen := (9.0 * safe_dt) if rad_v > 0.05 else (3.5 * safe_dt)
						if hp_val < 130.0:
							hp_val = minf(130.0, hp_val + m_regen)
					else:
						if hp_val < 100.0 and rad_v < 0.20:
							hp_val = minf(100.0, hp_val + hp_regen)

					# Radiation exposure & Crystal Mutant transformation
					if role != ROLE_MUTANT and fac != FACTION_ROBOT:
						if rad_v > 0.16:
							_u_rad_exp[i] += rad_v * 0.55 * safe_dt
							if _u_rad_exp[i] >= 1.0 or (rad_v >= rad_mut_thresh and _u_rad_exp[i] >= 0.42):
								_mutate_unit(i)
								cid = -1
								fac = FACTION_MUTANT
								role = ROLE_MUTANT
								hp_val = _hp[i]
						elif rad_v < 0.05 and _u_rad_exp[i] > 0.0:
							_u_rad_exp[i] = maxf(0.0, _u_rad_exp[i] - 0.04 * safe_dt)
					_hp[i] = hp_val

					if cid >= 0 and road_len > 0:
						var on_road := false
						if road_is_map:
							on_road = (_road_mask[tile_idx] != 0)
						elif road_is_zone:
							on_road = (_road_mask[clampi(py >> 3, 0, zone_hm1) * zone_wi + clampi(px >> 3, 0, zone_wm1)] != 0)
						if on_road:
							speed_target *= road_bonus
					if scan_budget > 0 and biome == BIOME_CRYSTAL and has_fx and _rng.randf() < scan_p:
						scan_budget -= 1
						_fx.spawn_burst(Vector2(px_f, py_f - 2.0), 1, Color(0.32, 0.95, 1.0, 0.9), 8.0, 0.50, -6.0)
					elif dust_budget > 0 and (tier == TIER_SAND or biome == BIOME_RUST or biome == BIOME_SCORCHED) and has_fx and _rng.randf() < dust_p:
						dust_budget -= 1
						_fx.spawn_burst(Vector2(px_f, py_f + 2.5), 1, Color(0.76, 0.65, 0.52, 0.42), 5.0, 0.30, -4.0)

				# Water avoidance lookahead for free colonists & mutants
				if cid < 0 and ((i + tick_i) & 3) == 0:
					var v_len2 := vx * vx + vy * vy
					if v_len2 > 1.0:
						var inv_vl := 1.0 / sqrt(v_len2)
						var fx_d := vx * inv_vl
						var fy_d := vy * inv_vl
						var p_ax := clampi(int(px_f + fx_d * 7.5), 0, map_w_m1)
						var p_ay := clampi(int(py_f + fy_d * 7.5), 0, map_h_m1)
						var a_idx := p_ay * map_w_i + p_ax
						var pt: int = TIER_SOIL_LOW
						if has_tc:
							var c_pt := _tc_tier[a_idx]
							if c_pt != 0:
								pt = int(c_pt) - 1
							else:
								pt = _world.get_tier(p_ax, p_ay)
								_tc_tier[a_idx] = pt + 1
						else:
							pt = _world.get_tier(p_ax, p_ay)
						if pt <= TIER_SHALLOW or pt >= TIER_SUMMIT:
							var fwd := Vector2(fx_d, fy_d)
							var left := fwd.rotated(-1.25)
							var right := fwd.rotated(1.25)
							var lx := clampi(int(px_f + left.x * 5.0), 0, map_w_m1)
							var ly := clampi(int(py_f + left.y * 5.0), 0, map_h_m1)
							var lt: int = _get_tile_tier(lx, ly)
							if lt > TIER_SHALLOW:
								ax += left.x * water_avoid
								ay += left.y * water_avoid
								_wander_angle[i] = atan2(left.y, left.x)
							else:
								var rx_p := clampi(int(px_f + right.x * 5.0), 0, map_w_m1)
								var ry_p := clampi(int(py_f + right.y * 5.0), 0, map_h_m1)
								var rt: int = _get_tile_tier(rx_p, ry_p)
								if rt > TIER_SHALLOW:
									ax += right.x * water_avoid
									ay += right.y * water_avoid
									_wander_angle[i] = atan2(right.y, right.x)
								else:
									ax -= fx_d * water_avoid
									ay -= fy_d * water_avoid
									_wander_angle[i] = atan2(-fy_d, -fx_d)

		if hp_val <= 0.0:
			continue

		# 3) 4-Layer SoA Task Interrupter + Direct Possession Override
		# Layer 3 (CRITICAL) > Layer 2 (COMBAT/SPARRING) > Layer 1 (URGENT_LOGISTICS) > Layer 0 (ROUTINE)
		var is_harvesting := false
		var wan_ready := false
		var wx := 0.0
		var wy := 0.0
		var low_hp_thresh := 36.4 if role == ROLE_MUTANT else 28.0
		var need_retreat := (hp_val < low_hp_thresh) and (enemy_idx >= 0 or is_alerted)
		var critical_fire := was_in_water or on_lava or fire_v > 0.25

		if is_possessed:
			_u_alert_layer[i] = LAYER_ROUTINE
			if _possess_pulse and _possess_cd <= 0.0:
				_execute_possessed_kinetic_pulse(i)
				if i >= _unit_count or _u_uid[i] != uid_val:
					continue
			if _possess_move.length_squared() > 0.0001:
				speed_target = 38.0
				ax += _possess_move.x * 240.0
				ay += _possess_move.y * 240.0
			else:
				speed_target = 0.0
		elif critical_fire:
			_u_alert_layer[i] = LAYER_CRITICAL
			if _u_task[i] == TASK_HARVEST:
				_u_task[i] = TASK_IDLE
		elif need_retreat and kb <= 0.02:
			_u_alert_layer[i] = LAYER_CRITICAL
			if _u_task[i] == TASK_HARVEST:
				_u_task[i] = TASK_IDLE
			var ret_vec := Vector2.ZERO
			if cid >= 0 and _count_water_hits(Vector2(px_f, py_f), _u_depot_pos[i]) < 2:
				ret_vec = _u_depot_pos[i] - Vector2(px_f, py_f)
			elif enemy_idx >= 0:
				ret_vec = Vector2(px_f - enemy_x, py_f - enemy_y)
			if ret_vec.length_squared() > 1.0:
				var rdir := ret_vec.normalized()
				ax += rdir.x * 96.0
				ay += rdir.y * 96.0
				speed_target *= 1.32
		elif (is_combat and enemy_idx >= 0) or (enemy_idx >= 0 and (is_war or is_infected or is_glitched or (enemy_d2 <= 256.0 and is_alerted))):
			if kb <= 0.02:
				_u_alert_layer[i] = LAYER_COMBAT
				var to_e := Vector2(enemy_x - px_f, enemy_y - py_f)
				var ed := to_e.length()
				if ed > 1.5:
					var edir := to_e / ed
					if role == ROLE_MUTANT or my_range_px <= 28.0:
						ax += edir.x * 96.0
						ay += edir.y * 96.0
						speed_target *= 1.25
					elif ed > my_range_px * 0.78:
						ax += edir.x * 96.0
						ay += edir.y * 96.0
						speed_target *= 1.20
					elif ed < my_range_px * 0.35:
						ax -= edir.x * 42.0
						ay -= edir.y * 42.0
					else:
						var strafe_s := 1.0 if ((i + (tick_i >> 4)) & 1) == 0 else -1.0
						ax += -edir.y * strafe_s * 34.0
						ay += edir.x * strafe_s * 34.0
						speed_target *= 0.92
		elif can_spar and spar_idx >= 0 and kb <= 0.02 and _u_task[i] != TASK_HAUL_DEPOT:
			_u_alert_layer[i] = LAYER_COMBAT
			var to_s := Vector2(spar_x - px_f, spar_y - py_f)
			var sd := to_s.length()
			if sd > 3.5:
				var sdir := to_s / sd
				ax += sdir.x * 74.0
				ay += sdir.y * 74.0
		elif cid >= 0 and kb <= 0.02:
			if hunger_c >= 0.45 and role == ROLE_FREE and _u_task[i] == TASK_MOVE_GOAL and _u_alert_layer[i] != LAYER_LOGISTICS:
				_assign_worker_goal(i, cid)
			if _u_alert_layer[i] != LAYER_LOGISTICS:
				_u_alert_layer[i] = LAYER_ROUTINE
			var goal_dir := _step_worker_state(i, cid, Vector2(px_f, py_f), speed_target, safe_dt)
			is_harvesting = (_u_task[i] == TASK_HARVEST)
			if _u_task[i] == TASK_HAUL_DEPOT and _u_stuck_timer[i] > 4.8:
				var rp_h := _find_walkable_near(_u_depot_pos[i], 8.0)
				px_f = rp_h.x
				py_f = rp_h.y
				_u_last_tile[i] = -1
				_u_stuck_timer[i] = 0.0
				_u_detour_timer[i] = 0.0
				px = clampi(int(px_f), 0, map_w_m1)
				py = clampi(int(py_f), 0, map_h_m1)
				tier = _get_tile_tier(px, py)
				var to_dep := _u_depot_pos[i] - rp_h
				goal_dir = to_dep.normalized() if to_dep.length_squared() > 1.0 else Vector2.ZERO
			if not is_harvesting:
				if goal_dir != Vector2.ZERO:
					ax += goal_dir.x * 86.0
					ay += goal_dir.y * 86.0
				else:
					var w_ang_w := _wander_angle[i]
					wx = _u_wan_dx[i]
					wy = _u_wan_dy[i]
					if w_ang_w != _u_wan_ang[i]:
						wx = cos(w_ang_w)
						wy = sin(w_ang_w)
						_u_wan_ang[i] = w_ang_w
						_u_wan_dx[i] = wx
						_u_wan_dy[i] = wy
					wan_ready = true
					ax += wx * (wan_w * 0.4)
					ay += wy * (wan_w * 0.4)
		else:
			var jitter_p := wan_p * (2.6 if role == ROLE_MUTANT else 1.0)
			if _rng.randf() < jitter_p:
				_wander_angle[i] += _rng.randf_range(-1.35, 1.35) if role == ROLE_MUTANT else _rng.randf_range(-0.95, 0.95)
			var w_ang := _wander_angle[i]
			wx = _u_wan_dx[i]
			wy = _u_wan_dy[i]
			if w_ang != _u_wan_ang[i]:
				wx = cos(w_ang)
				wy = sin(w_ang)
				_u_wan_ang[i] = w_ang
				_u_wan_dx[i] = wx
				_u_wan_dy[i] = wy
			wan_ready = true
			ax += wx * wan_w
			ay += wy * wan_w

			# Wanderer gravitation toward nearby colony campfires (96 px beacon)
			if cid < 0 and role == ROLE_FREE:
				if ((i + tick_i) & 15) == 0:
					_update_wanderer_beacon(i, px_f, py_f)
				var bp := _u_beacon_pos[i]
				if bp.x >= 0.0:
					var bdx := bp.x - px_f
					var bdy := bp.y - py_f
					var bd2 := bdx * bdx + bdy * bdy
					if bd2 > 16.0 and bd2 <= 9216.0:
						var bd := sqrt(bd2)
						var binv := 1.0 / bd
						var bnx := bdx * binv
						var bny := bdy * binv
						if bd > 26.0:
							ax += bnx * 24.0
							ay += bny * 24.0
						elif bd > 12.0:
							ax += -bny * 14.0 + bnx * 6.0
							ay += bnx * 14.0 + bny * 6.0
						else:
							ax -= bnx * 18.0
							ay -= bny * 18.0

		if check_blds and kb <= 0.02 and not is_harvesting:
			var bzx := clampi(int(px_f) >> 3, 0, zone_wm1)
			var bzy := clampi(int(py_f) >> 3, 0, zone_hm1)
			if _bld_occ[bzy * zone_wi + bzx] != 0:
				var is_bld_goal := cid >= 0 and (_u_task[i] == TASK_HAUL_DEPOT or (_u_role[i] == ROLE_BUILDER and _u_task[i] == TASK_MOVE_GOAL))
				var b_avoid := _building_avoid_force(Vector2(px_f, py_f), _u_target_pos[i], is_bld_goal)
				if b_avoid != Vector2.ZERO:
					ax += b_avoid.x * 76.0
					ay += b_avoid.y * 76.0

		# 4) 100% Frame-Rate Scalar Integration (knockback vs harvesting vs movement)
		if kb > 0.0:
			_knockback_timer[i] = maxf(0.0, kb - safe_dt)
			vx = (vx + ax * (0.35 * safe_dt)) * blend_kb
			vy = (vy + ay * (0.35 * safe_dt)) * blend_kb
		elif is_harvesting:
			vx *= harv_keep
			vy *= harv_keep
		elif is_possessed and _possess_move.length_squared() <= 0.0001:
			vx *= harv_keep
			vy *= harv_keep
		else:
			var des_x := vx + ax * safe_dt
			var des_y := vy + ay * safe_dt
			var des_l2 := des_x * des_x + des_y * des_y
			if is_possessed and _possess_move.length_squared() > 0.0001:
				des_x = _possess_move.x * speed_target
				des_y = _possess_move.y * speed_target
			elif des_l2 > 0.01:
				var s_inv := speed_target / sqrt(des_l2)
				des_x *= s_inv
				des_y *= s_inv
			else:
				if not wan_ready:
					var w_ang2 := _wander_angle[i]
					wx = _u_wan_dx[i]
					wy = _u_wan_dy[i]
					if w_ang2 != _u_wan_ang[i]:
						wx = cos(w_ang2)
						wy = sin(w_ang2)
						_u_wan_ang[i] = w_ang2
						_u_wan_dx[i] = wx
						_u_wan_dy[i] = wy
				des_x = wx * speed_target
				des_y = wy * speed_target
			vx += (des_x - vx) * blend_vel
			vy += (des_y - vy) * blend_vel

		var nx_f := px_f + vx * safe_dt
		var ny_f := py_f + vy * safe_dt
		if nx_f < min_x:
			nx_f = min_x
			vx = absf(vx)
			_wander_angle[i] = atan2(vy, vx)
		elif nx_f > max_x:
			nx_f = max_x
			vx = -absf(vx)
			_wander_angle[i] = atan2(vy, vx)
		if ny_f < min_y:
			ny_f = min_y
			vy = absf(vy)
			_wander_angle[i] = atan2(vy, vx)
		elif ny_f > max_y:
			ny_f = max_y
			vy = -absf(vy)
			_wander_angle[i] = atan2(vy, vx)

		# Hard shoreline boundary using cached 1px tile tier (keeps combat hits/dodges kb <= 0.24 dry)
		if has_world and kb <= 0.24 and not was_in_water:
			var nx := clampi(int(nx_f), 0, map_w_m1)
			var ny := clampi(int(ny_f), 0, map_h_m1)
			var n_idx := ny * map_w_i + nx
			var nt := tier
			if nx != px or ny != py:
				if has_tc:
					var c_nt := _tc_tier[n_idx]
					if c_nt != 0:
						nt = int(c_nt) - 1
					else:
						nt = _world.get_tier(nx, ny)
						_tc_tier[n_idx] = nt + 1
				else:
					nt = _world.get_tier(nx, ny)
			if nt > TIER_SHALLOW and nt < TIER_SUMMIT:
				if n_idx != tile_idx:
					_u_last_tile[i] = n_idx
					_u_tier[i] = nt
			else:
				var cx_cur := clampi(int(px_f), 0, map_w_m1)
				var cy_cur := clampi(int(py_f), 0, map_h_m1)
				var sx_idx := cy_cur * map_w_i + nx
				var tx_tier: int = TIER_DEEP_OCEAN
				if has_tc:
					var c_xt := _tc_tier[sx_idx]
					if c_xt != 0:
						tx_tier = int(c_xt) - 1
					else:
						tx_tier = _world.get_tier(nx, cy_cur)
						_tc_tier[sx_idx] = tx_tier + 1
				else:
					tx_tier = _world.get_tier(nx, cy_cur)
				if tx_tier > TIER_SHALLOW and tx_tier < TIER_SUMMIT:
					ny_f = py_f
					vy = -vy
					if sx_idx != tile_idx:
						_u_last_tile[i] = sx_idx
						_u_tier[i] = tx_tier
				else:
					var sy_idx := ny * map_w_i + cx_cur
					var ty_tier: int = TIER_DEEP_OCEAN
					if has_tc:
						var c_yt := _tc_tier[sy_idx]
						if c_yt != 0:
							ty_tier = int(c_yt) - 1
						else:
							ty_tier = _world.get_tier(cx_cur, ny)
							_tc_tier[sy_idx] = ty_tier + 1
					else:
						ty_tier = _world.get_tier(cx_cur, ny)
					if ty_tier > TIER_SHALLOW and ty_tier < TIER_SUMMIT:
						nx_f = px_f
						vx = -vx
						if sy_idx != tile_idx:
							_u_last_tile[i] = sy_idx
							_u_tier[i] = ty_tier
					else:
						nx_f = px_f
						ny_f = py_f
						var b_v := (-Vector2(vx, vy)).rotated(_rng.randf_range(-0.6, 0.6))
						vx = b_v.x
						vy = b_v.y
						if cid >= 0 and (vx * vx + vy * vy) > 0.01:
							_u_detour_side[i] = -_u_detour_side[i]
							_u_detour_dir[i] = b_v.normalized().rotated(_u_detour_side[i] * 0.9)
							_u_detour_timer[i] = maxf(_u_detour_timer[i], 0.45)
				_wander_angle[i] = atan2(vy, vx)

		if check_blds and kb <= 0.0:
			var nzx := clampi(int(nx_f) >> 3, 0, zone_wm1)
			var nzy := clampi(int(ny_f) >> 3, 0, zone_hm1)
			if _bld_occ[nzy * zone_wi + nzx] != 0:
				var cur_np := Vector2(nx_f, ny_f)
				var b_clamped := _clamp_out_of_buildings(cur_np)
				if b_clamped != cur_np:
					var push_n := (b_clamped - cur_np).normalized()
					nx_f = b_clamped.x
					ny_f = b_clamped.y
					var vn := vx * push_n.x + vy * push_n.y
					if vn < 0.0:
						vx -= push_n.x * (vn * 1.35)
						vy -= push_n.y * (vn * 1.35)
						if vx * vx + vy * vy > 0.1:
							_wander_angle[i] = atan2(vy, vx)

		var spd := sqrt(vx * vx + vy * vy)
		_px[i] = nx_f
		_py[i] = ny_f
		_vx[i] = vx
		_vy[i] = vy
		var ph := _phase[i] + (2.5 + spd * 0.38) * safe_dt
		if ph >= tau4:
			ph -= tau4
		_phase[i] = ph
		var facing_val := _facing[i]
		if vx > 0.25:
			facing_val = 1.0
			_facing[i] = 1.0
		elif vx < -0.25:
			facing_val = -1.0
			_facing[i] = -1.0

		# 5) Pack sprite_mode=3 MultiMesh buffer inline (crisp 8x8 quad, zero extra pass)
		var pt_u := ph * inv_pi
		var pt_i := int(pt_u)
		var tri := 1.0 - 2.0 * absf(2.0 * (pt_u - float(pt_i)) - 1.0)
		var squash := 1.0 + 0.06 * tri
		var task := int(_u_task[i]) if cid >= 0 else TASK_IDLE
		if kb > 0.05:
			squash = 1.12
		elif cid >= 0 and task == TASK_HARVEST:
			var ht := harv_t + pt_u
			squash = 1.0 + 0.10 * (1.0 - 2.0 * absf(2.0 * (ht - float(int(ht))) - 1.0))

		var col_idx := _pick_unit_col(fac, role, task, spd, kb, pt_i, harv_frame, i)
		var custom_g := minf(spd * 0.025, 1.8)
		if flash_val > 0.005:
			custom_g = -2.0 - clampf(flash_val / 0.16, 0.20, 1.0)
		elif is_possessed:
			custom_g = -2.0 - (0.28 + 0.16 * sin(_sim_time * 9.0))
		elif on_lava or fire_v > 0.20:
			custom_g = 2.0 + clampf(maxf(fire_v, 0.55 if on_lava else 0.25), 0.15, 1.0)
		elif is_glitched:
			custom_g = -2.0 - (0.26 + 0.20 * sin(_sim_time * 16.0 + float(i & 7)))
		elif is_infected_raw:
			custom_g = -2.0 - (0.18 + 0.12 * sin(_sim_time * 8.0 + float(i & 7)))

		var off := i * 16
		_unit_mm_buf[off + 3] = nx_f
		_unit_mm_buf[off + 7] = ny_f - 3.2
		if upload_colors:
			var c := _suit_tint[i]
			_unit_mm_buf[off + 8] = c.r
			_unit_mm_buf[off + 9] = c.g
			_unit_mm_buf[off + 10] = c.b
			_unit_mm_buf[off + 11] = c.a
		_unit_mm_buf[off + 12] = ph
		_unit_mm_buf[off + 13] = custom_g
		_unit_mm_buf[off + 14] = facing_val * squash
		_unit_mm_buf[off + 15] = float(col_idx)

	# Post-loop deferred mortality cleanup (never invalidates spatial hash mid-step)
	if any_died:
		if _any_infected_unit or next_any_inf:
			if _spatial_hash_dirty:
				_rebuild_spatial_hash()
			for d_i in range(_unit_count):
				if _hp[d_i] <= 0.0 and d_i < inf_sz and _u_infected_timer[d_i] > 0.0:
					if _spread_death_contagion(d_i):
						next_any_inf = true
		var k := 0
		while k < _unit_count:
			if _hp[k] <= 0.0:
				var cause := DEATH_COMBAT
				if _u_biome[k] == BIOME_LAVA or _u_fire_now[k] > 0.14 or _u_temp[k] > hot_thresh:
					cause = DEATH_BURN
				elif _u_tier[k] <= TIER_SHALLOW:
					cause = DEATH_DROWN
				var prev_last := _unit_count - 1
				_kill_unit(k, cause)
				if k < _unit_count and prev_last != k:
					var src_off := prev_last * 16
					var dst_off := k * 16
					for m in range(16):
						_unit_mm_buf[dst_off + m] = _unit_mm_buf[src_off + m]
				continue
			k += 1

	_any_infected_unit = next_any_inf
	_any_glitched_unit = next_any_glitch
	_pos_dirty = true
	mm.visible_instance_count = _unit_count
	mm.buffer = _unit_mm_buf
	_unit_colors_dirty = false

	_sync_cargo_multimesh()
	_sync_ground_shadows()
	_step_flora(safe_dt)
	_sync_flora_multimesh()


func _spread_death_contagion(src_idx: int) -> bool:
	var sx := _px[src_idx]
	var sy := _py[src_idx]
	var r := 20.0
	var r2 := 400.0
	var min_cx := clampi(int(sx - r) >> 4, 0, _grid_w - 1)
	var max_cx := clampi(int(sx + r) >> 4, 0, _grid_w - 1)
	var min_cy := clampi(int(sy - r) >> 4, 0, _grid_h - 1)
	var max_cy := clampi(int(sy + r) >> 4, 0, _grid_h - 1)
	var inf_sz := _u_infected_timer.size()
	var lat_sz := _u_latent_timer.size()
	var best_nb := -1
	var best_d2 := r2
	for cy in range(min_cy, max_cy + 1):
		var row_off := cy * _grid_w
		for cx in range(min_cx, max_cx + 1):
			var nb := _cell_head[row_off + cx]
			while nb != -1:
				if nb != src_idx and _hp[nb] > 0.0 and int(_u_faction_id[nb]) != FACTION_ROBOT and nb < inf_sz and _u_infected_timer[nb] <= 0.0:
					var dx := _px[nb] - sx
					var dy := _py[nb] - sy
					var d2 := dx * dx + dy * dy
					if d2 <= best_d2:
						best_d2 = d2
						best_nb = nb
				nb = _unit_next[nb]
	if best_nb < 0:
		return false
	_u_infected_timer[best_nb] = 4.5
	if best_nb < lat_sz:
		_u_latent_timer[best_nb] = 0.0
	_hit_flash_timer[best_nb] = maxf(_hit_flash_timer[best_nb], 0.18)
	_record_memory(best_nb, MEM_INFECTED)
	if _fx != null and _strip_fx_budget > 0:
		_strip_fx_budget -= 1
		if _fx.has_method("spawn_reaction_strip"):
			_fx.call("spawn_reaction_strip", Vector2(_px[best_nb], _py[best_nb] - 7.0), STRIP_SKULL)
		_fx.spawn_burst(Vector2(sx, sy), 4, Color(0.52, 1.0, 0.42, 0.90), 18.0, 0.35, -8.0)
	return true


func _apply_ion_storm_unit_effects(world_pos: Vector2, radius: float) -> void:
	_ensure_layers()
	if _unit_count <= 0:
		return
	if _spatial_hash_dirty:
		_rebuild_spatial_hash()
	var r := maxf(radius, 22.0)
	var r2 := r * r
	var min_cx := clampi(int(world_pos.x - r) >> 4, 0, _grid_w - 1)
	var max_cx := clampi(int(world_pos.x + r) >> 4, 0, _grid_w - 1)
	var min_cy := clampi(int(world_pos.y - r) >> 4, 0, _grid_h - 1)
	var max_cy := clampi(int(world_pos.y + r) >> 4, 0, _grid_h - 1)
	var glitch_sz := _u_glitch_timer.size()
	var invuln_sz := _u_invuln_timer.size()
	var emp_sz := _city_emp_timer.size()
	var inf_sz := _u_infected_timer.size()
	var chain_sources: Array[int] = []
	var any_died := false

	for cy in range(min_cy, max_cy + 1):
		var row_off := cy * _grid_w
		for cx in range(min_cx, max_cx + 1):
			var u := _cell_head[row_off + cx]
			while u != -1:
				if _hp[u] > 0.0:
					var diff_x := _px[u] - world_pos.x
					var diff_y := _py[u] - world_pos.y
					var d2 := diff_x * diff_x + diff_y * diff_y
					if d2 <= r2:
						var is_robot := int(_u_faction_id[u]) == FACTION_ROBOT
						var was_glitched := (u < glitch_sz and _u_glitch_timer[u] > 0.0)
						var u_cid := _u_city_id[u]
						var is_emp := (u_cid >= 0 and u_cid < emp_sz and _city_emp_timer[u_cid] > 0.0)
						if is_robot or was_glitched:
							if u < glitch_sz:
								_u_glitch_timer[u] = maxf(_u_glitch_timer[u], 1.6)
							_u_attack_cd[u] = maxf(_u_attack_cd[u], 0.25)
							_hit_flash_timer[u] = maxf(_hit_flash_timer[u], 0.18)
							_any_glitched_unit = true
							_record_memory(u, MEM_GLITCHED)
							if d2 > 0.01:
								var inv_d := 1.0 / sqrt(d2)
								_vx[u] += diff_x * inv_d * 20.0
								_vy[u] += diff_y * inv_d * 20.0
								_knockback_timer[u] = maxf(_knockback_timer[u], 0.14)
							if was_glitched or is_emp:
								if u >= invuln_sz or _u_invuln_timer[u] <= 0.0:
									_hp[u] -= 10.0
									if _hp[u] <= 0.0:
										any_died = true
								if chain_sources.size() < 3:
									chain_sources.append(u)
				u = _unit_next[u]

	var ch_r := 26.0
	var ch_r2 := 676.0
	for s_i in range(chain_sources.size()):
		var su := chain_sources[s_i]
		var sx := _px[su]
		var sy := _py[su]
		var c_min_x := clampi(int(sx - ch_r) >> 4, 0, _grid_w - 1)
		var c_max_x := clampi(int(sx + ch_r) >> 4, 0, _grid_w - 1)
		var c_min_y := clampi(int(sy - ch_r) >> 4, 0, _grid_h - 1)
		var c_max_y := clampi(int(sy + ch_r) >> 4, 0, _grid_h - 1)
		var best1 := -1
		var best1_sc := ch_r2
		var best2 := -1
		var best2_sc := ch_r2
		for cy in range(c_min_y, c_max_y + 1):
			var row_off := cy * _grid_w
			for cx in range(c_min_x, c_max_x + 1):
				var nb := _cell_head[row_off + cx]
				while nb != -1:
					if nb != su and _hp[nb] > 0.0:
						var ndx := _px[nb] - sx
						var ndy := _py[nb] - sy
						var nd2 := ndx * ndx + ndy * ndy
						if nd2 <= ch_r2:
							var nb_rob := int(_u_faction_id[nb]) == FACTION_ROBOT
							var nb_gl := (nb < glitch_sz and _u_glitch_timer[nb] > 0.0)
							var sc := nd2 * (0.45 if (nb_rob or nb_gl) else 1.0)
							if sc < best1_sc:
								best2 = best1
								best2_sc = best1_sc
								best1 = nb
								best1_sc = sc
							elif sc < best2_sc:
								best2 = nb
								best2_sc = sc
					nb = _unit_next[nb]
		for t_i in range(2):
			var tgt := best1 if t_i == 0 else best2
			if tgt < 0:
				continue
			if tgt < glitch_sz:
				_u_glitch_timer[tgt] = maxf(_u_glitch_timer[tgt], 1.2)
			_any_glitched_unit = true
			_hit_flash_timer[tgt] = maxf(_hit_flash_timer[tgt], 0.18)
			_record_memory(tgt, MEM_GLITCHED)
			if tgt >= invuln_sz or _u_invuln_timer[tgt] <= 0.0:
				var dmg_arc := 6.0 if (int(_u_faction_id[tgt]) == FACTION_ROBOT) else 3.5
				_hp[tgt] -= dmg_arc
				if _hp[tgt] <= 0.0:
					any_died = true
			if _fx != null:
				var adiff := Vector2(_px[tgt] - sx, _py[tgt] - sy)
				var adir := adiff.normalized() if adiff.length_squared() > 0.01 else Vector2.RIGHT
				_fx.emit_spark_arc(Vector2(sx, sy - 2.0), adir, Color(0.45, 0.95, 1.0, 0.95))

	if any_died:
		if _any_infected_unit:
			for d_i in range(_unit_count):
				if _hp[d_i] <= 0.0 and d_i < inf_sz and _u_infected_timer[d_i] > 0.0:
					if _spread_death_contagion(d_i):
						_any_infected_unit = true
		var k := 0
		while k < _unit_count:
			if _hp[k] <= 0.0:
				var prev_last := _unit_count - 1
				_kill_unit(k, DEATH_COMBAT)
				if k < _unit_count and prev_last != k:
					var src_off := prev_last * 16
					var dst_off := k * 16
					for m in range(16):
						_unit_mm_buf[dst_off + m] = _unit_mm_buf[src_off + m]
				continue
			k += 1
		if _mm_units != null and _mm_units.multimesh != null:
			_mm_units.multimesh.visible_instance_count = _unit_count
			_mm_units.multimesh.buffer = _unit_mm_buf
		_rebuild_spatial_hash()


func _sync_cargo_multimesh() -> void:
	if _mm_cargo == null or _mm_cargo.multimesh == null or not _mm_cargo.visible:
		return
	var cmm := _mm_cargo.multimesh
	var hauler_n := 0
	var cargo_cols_len := CARGO_COLORS.size()
	for i in range(_unit_count):
		if _u_city_id[i] >= 0 and _u_task[i] == TASK_HAUL_DEPOT and _u_carry_type[i] != CARRY_NONE:
			var bob := sin(_phase[i] * 2.0) * 0.45
			var ct := clampi(int(_u_carry_type[i]), 0, cargo_cols_len - 1)
			cmm.set_instance_transform_2d(hauler_n, Transform2D(0.0, Vector2(_px[i], _py[i] - 7.8 + bob)))
			cmm.set_instance_color(hauler_n, CARGO_COLORS[ct])
			cmm.set_instance_custom_data(hauler_n, Color(_phase[i], 0.0, 1.0, float(UCOL_CARGO_PIP)))
			hauler_n += 1
			if hauler_n >= MAX_UNITS:
				break
	cmm.visible_instance_count = hauler_n


func _step_flora(dt: float) -> void:
	var burn_dur: float = TUNING_KNOBS["FLORA_BURN_DURATION"]
	var omega: float = TUNING_KNOBS["SPRING_OMEGA"]
	var zeta: float = TUNING_KNOBS["SPRING_ZETA"]

	# Incrementally sync flora against terrain edits, fire ignition & sapling growth every 4th tick
	if _world != null and _flora_count > 0 and (_tick_idx & 3) == 0:
		var slice: int = mini(20, mini(int(TUNING_KNOBS["FLORA_SYNC_SLICE"]), _flora_count))
		var has_moist := _world.has_method("get_moisture")
		for _s in range(slice):
			var cf := _flora_sync_cursor
			_sync_single_flora(cf, false)
			if _flora_burn[cf] > 0.0 and has_moist:
				var px := clampi(int(_flora_pos[cf].x), 0, _map_w - 1)
				var py := clampi(int(_flora_pos[cf].y), 0, _map_h - 1)
				if float(_world.get_moisture(px, py)) > 0.60 and float(_world.get_fire(px, py)) < 0.05:
					_flora_burn[cf] = 0.0
					_flora_col[cf] = FLORA_TREE_CHARRED
					_flora_dirty_all = true
			elif _flora_col[cf] == FLORA_LUSH_SAPLING:
				_flora_grow[cf] += dt * 16.0 * _flora_mul
				if _flora_grow[cf] >= 12.0:
					var px2 := clampi(int(_flora_pos[cf].x), 0, _map_w - 1)
					var py2 := clampi(int(_flora_pos[cf].y), 0, _map_h - 1)
					var b2: int = _world.get_biome(px2, py2)
					_flora_col[cf] = FLORA_CRYSTAL_SMALL if b2 == BIOME_CRYSTAL else (FLORA_SHROOM_LUSH if (_rng.randf() < 0.35 and b2 == BIOME_LUSH) else FLORA_TREE_LUSH)
					_flora_grow[cf] = 0.0
					_flora_spring[cf] = 0.14
					_flora_spring_vel[cf] = 2.8
					_flora_has_anim = true
					_flora_active_custom[cf] = 1
					_flora_dirty_all = true
			_flora_sync_cursor = (_flora_sync_cursor + 1) % _flora_count

	# Dynamic regrowth on lush / crystal / fertile ash up to MAX_FLORA (modulated by Cosmic Age flora_mul)
	if _world != null and _flora_count < MAX_FLORA and _flora_regrow_cd <= 0.0:
		_flora_regrow_cd = 0.65 / clampf(_flora_mul, 0.20, 3.0)
		var has_env := _world.has_method("get_tile_env")
		for _try in range(2):
			if _flora_count >= MAX_FLORA:
				break
			var gx := _rng.randi_range(6, _map_w - 7)
			var gy := _rng.randi_range(6, _map_h - 7)
			if not _is_flora_allowed_tile(gx, gy):
				continue
			var cand := Vector2(float(gx) + 0.5, float(gy) + 0.5)
			if _bld_count > 0 and _is_inside_any_building(cand, 5.0):
				continue
			var g_biome: int = _world.get_biome(gx, gy)
			var env: Vector4 = _world.get_tile_env(gx, gy) if has_env else Vector4(_world.get_temp(gx, gy), 0.0, 0.0, 0.0)
			if g_biome == BIOME_LAVA or env.x > 65.0 or env.z > 0.10:
				continue
			if g_biome == BIOME_CRYSTAL or env.w >= 0.22 or (g_biome == BIOME_LUSH and _rng.randf() < 0.45):
				var sprout := FLORA_CRYSTAL_CLUSTER if g_biome == BIOME_CRYSTAL else FLORA_LUSH_SAPLING
				_append_flora_slot(cand, sprout, true)
				break

	# Ambient colony campfire embers
	if _fx != null and _campfire_ember_cd <= 0.0 and _city_active.size() > 0:
		_campfire_ember_cd = 0.28
		var nc := _city_active.size()
		var pick := _rng.randi_range(0, nc - 1)
		for step_c in range(nc):
			var c_id := (pick + step_c) % nc
			if _city_active[c_id] != 0 and c_id < _city_depot_pos.size() and _city_depot_pos[c_id].x >= 0.0:
				var cpos := _city_center[c_id] if c_id < _city_center.size() else _city_depot_pos[c_id]
				var fac_c := int(_city_faction[c_id]) if c_id < _city_faction.size() else FACTION_HUMAN
				var ember_c := Color(0.45, 0.92, 1.0, 0.90) if fac_c == FACTION_ROBOT else (Color(0.55, 1.0, 0.48, 0.88) if fac_c == FACTION_SPORE else Color(1.0, 0.58, 0.18, 0.92))
				_fx.emit_campfire_ember(cpos + Vector2(_rng.randf_range(-4.0, 4.0), -3.0), Vector2.ZERO, ember_c)
				break

	if not _flora_has_anim or _flora_count <= 0:
		return

	var any_anim := false
	for f in range(_flora_count):
		if _flora_burn[f] > 0.0:
			var nb := _flora_burn[f] - dt
			_flora_burn[f] = nb
			if f < _flora_active_custom.size():
				_flora_active_custom[f] = 1
			if nb <= 0.0:
				_flora_burn[f] = 0.0
				_flora_col[f] = FLORA_TREE_ASH
				_flora_dirty_all = true
				if _fx != null and _rng.randf() < 0.35:
					_fx.spawn_burst(_flora_pos[f] + Vector2(0.0, -4.0), 2, Color(0.42, 0.40, 0.38, 0.72), 10.0, 0.45, -8.0)
			else:
				any_anim = true
				if _fx != null and _rng.randf() < dt * 0.65:
					_fx.emit_campfire_ember(_flora_pos[f] + Vector2(0.0, -5.0), Vector2.ZERO, Color(1.0, 0.52, 0.14, 0.95))

		var sh := _flora_shake[f]
		if sh > 0.0:
			var nsh := maxf(0.0, sh - dt * 2.4)
			_flora_shake[f] = nsh
			if f < _flora_active_custom.size():
				_flora_active_custom[f] = 1
			if nsh > 0.0:
				any_anim = true
		var sp := _flora_spring[f]
		var sv := _flora_spring_vel[f]
		if absf(sp - 1.0) > 0.002 or absf(sv) > 0.002:
			var force := -omega * omega * (sp - 1.0) - 2.0 * zeta * omega * sv
			sv += force * dt
			sp += sv * dt
			if absf(sp - 1.0) < 0.002 and absf(sv) < 0.01:
				sp = 1.0
				sv = 0.0
			else:
				any_anim = true
			_flora_spring[f] = clampf(sp, 0.08, 1.35)
			_flora_spring_vel[f] = sv
			if f < _flora_active_custom.size():
				_flora_active_custom[f] = 1
	_flora_has_anim = any_anim


func _sync_unit_multimesh() -> void:
	var mm := _mm_units.multimesh
	mm.visible_instance_count = _unit_count
	var upload_colors := _ensure_unit_mm_buf(mm)
	var offset_y := -3.2
	var harv_frame := int(_sim_time * 7.5)
	var harv_t := _sim_time * 5.729578
	var inv_pi := 0.318309886

	for i in range(_unit_count):
		var vx := _vx[i]
		var vy := _vy[i]
		var spd := sqrt(vx * vx + vy * vy)
		var kb := _knockback_timer[i]
		var ph := _phase[i]
		var pt_u := ph * inv_pi
		var pt_i := int(pt_u)
		var tri := 1.0 - 2.0 * absf(2.0 * (pt_u - float(pt_i)) - 1.0)
		var squash := 1.0 + 0.06 * tri
		var cid := _u_city_id[i]
		var task := int(_u_task[i]) if cid >= 0 else TASK_IDLE
		if kb > 0.05:
			squash = 1.12
		elif cid >= 0 and task == TASK_HARVEST:
			var ht := harv_t + pt_u
			squash = 1.0 + 0.10 * (1.0 - 2.0 * absf(2.0 * (ht - float(int(ht))) - 1.0))

		var col_idx := _pick_unit_col(int(_u_faction_id[i]), int(_u_role[i]), task, spd, kb, pt_i, harv_frame, i)
		var off := i * 16
		_unit_mm_buf[off + 3] = _px[i]
		_unit_mm_buf[off + 7] = _py[i] + offset_y
		if upload_colors:
			var c := _suit_tint[i]
			_unit_mm_buf[off + 8] = c.r
			_unit_mm_buf[off + 9] = c.g
			_unit_mm_buf[off + 10] = c.b
			_unit_mm_buf[off + 11] = c.a
		_unit_mm_buf[off + 12] = ph
		var flash_t := _hit_flash_timer[i]
		var custom_g := minf(spd * 0.025, 1.8)
		if flash_t > 0.005:
			custom_g = -2.0 - clampf(flash_t / 0.16, 0.20, 1.0)
		elif _u_uid[i] == _possessed_uid:
			custom_g = -2.0 - (0.28 + 0.16 * sin(_sim_time * 9.0))
		elif _u_fire_now[i] > 0.25:
			custom_g = 2.0 + clampf(_u_fire_now[i], 0.15, 1.0)
		elif i < _u_glitch_timer.size() and _u_glitch_timer[i] > 0.0:
			custom_g = -2.0 - (0.26 + 0.20 * sin(_sim_time * 16.0 + float(i & 7)))
		elif i < _u_infected_timer.size() and _u_infected_timer[i] > 0.0:
			custom_g = -2.0 - (0.18 + 0.12 * sin(_sim_time * 8.0 + float(i & 7)))
		_unit_mm_buf[off + 13] = custom_g
		_unit_mm_buf[off + 14] = _facing[i] * squash
		_unit_mm_buf[off + 15] = float(col_idx)

	mm.buffer = _unit_mm_buf
	_unit_colors_dirty = false
	_sync_cargo_multimesh()
	_sync_ground_shadows()


func _sync_flora_multimesh() -> void:
	var mm := _mm_flora.multimesh
	mm.visible_instance_count = _flora_count
	var offset_y := -5.5
	var burn_dur: float = TUNING_KNOBS["FLORA_BURN_DURATION"]
	if _flora_dirty_all:
		for f in range(_flora_count):
			var fp := _flora_pos[f]
			var xform := Transform2D(0.0, Vector2(fp.x, fp.y + offset_y))
			mm.set_instance_transform_2d(f, xform)
			mm.set_instance_color(f, _flora_tint[f])
			var g_val := _flora_shake[f] if _flora_burn[f] <= 0.0 else (2.0 + clampf(_flora_burn[f] / burn_dur, 0.12, 1.0))
			mm.set_instance_custom_data(f, Color(_flora_sway_phase[f], g_val, _flora_spring[f], float(_flora_col[f])))
		_flora_dirty_all = false
		_flora_active_custom.fill(0)
		_flora_shadows_dirty = true
		_sync_ground_shadows()
		return

	var custom_sz := _flora_active_custom.size()
	for f in range(mini(_flora_count, custom_sz)):
		if _flora_active_custom[f] != 0:
			var g_val := _flora_shake[f] if _flora_burn[f] <= 0.0 else (2.0 + clampf(_flora_burn[f] / burn_dur, 0.12, 1.0))
			mm.set_instance_custom_data(f, Color(_flora_sway_phase[f], g_val, _flora_spring[f], float(_flora_col[f])))
			if _flora_burn[f] <= 0.0 and _flora_shake[f] <= 0.0 and absf(_flora_spring[f] - 1.0) <= 0.002 and absf(_flora_spring_vel[f]) <= 0.002:
				_flora_active_custom[f] = 0
	if _flora_shadows_dirty or _shadows_dirty:
		_sync_ground_shadows()


func _flora_shadow_scale(col: int) -> Vector2:
	match col:
		FLORA_TREE_LUSH, FLORA_FROST_PINE, FLORA_TREE_CHARRED, FLORA_BURNING_BUSH:
			return Vector2(1.45, 1.05)
		FLORA_CRYSTAL_TALL, FLORA_BOULDER, FLORA_CRYSTAL_CLUSTER, FLORA_SPORE_POD:
			return Vector2(1.22, 0.90)
		FLORA_SHROOM_LUSH, FLORA_RUST_SCRUB, FLORA_CRYSTAL_SMALL:
			return Vector2(0.95, 0.74)
		_:
			return Vector2(0.72, 0.58)


func _sync_ground_shadows() -> void:
	if _shadow_group == null or not _shadow_group.visible or _mm_ground_shadows == null or _mm_ground_shadows.multimesh == null:
		_shadows_dirty = true
		return
	var shadow_mm := _mm_ground_shadows.multimesh
	var cap := shadow_mm.instance_count
	if _shadow_mm_buf.size() != cap * 8:
		return
	var flora_vis := mini(_flora_count, cap)
	if _flora_shadows_dirty or _shadow_flora_count != flora_vis:
		for f in range(flora_vis):
			var fp := _flora_pos[f]
			var sc := _flora_shadow_scale(int(_flora_col[f]))
			var sb := f * 8
			_shadow_mm_buf[sb] = sc.x
			_shadow_mm_buf[sb + 3] = fp.x
			_shadow_mm_buf[sb + 5] = sc.y
			_shadow_mm_buf[sb + 7] = fp.y + 0.2
		_shadow_flora_count = flora_vis
		_flora_shadows_dirty = false

	var unit_vis := mini(_unit_count, cap - flora_vis)
	for i in range(unit_vis):
		var s := 1.02 if int(_u_role[i]) == ROLE_MUTANT else 0.85
		var sb := (flora_vis + i) * 8
		_shadow_mm_buf[sb] = s
		_shadow_mm_buf[sb + 3] = _px[i]
		_shadow_mm_buf[sb + 5] = s * 0.80
		_shadow_mm_buf[sb + 7] = _py[i] + 0.6

	shadow_mm.visible_instance_count = flora_vis + unit_vis
	shadow_mm.buffer = _shadow_mm_buf
	_shadows_dirty = false


func get_unit_count() -> int:
	return _unit_count


func get_flora_count() -> int:
	return _flora_count


func get_unit_positions() -> PackedVector2Array:
	if _pos_dirty:
		_pos_dirty = false
		_pos.resize(_unit_count)
		for i in range(_unit_count):
			_pos[i] = Vector2(_px[i], _py[i])
	return _pos


func get_unit_cities() -> PackedInt32Array:
	return _u_city_id


func get_unit_roles() -> PackedByteArray:
	return _u_role


func get_first_unit_pos() -> Vector2:
	if _unit_count > 0:
		return Vector2(_px[0], _py[0])
	return Vector2(float(_map_w) * 0.5, float(_map_h) * 0.5)


func get_max_unit_speed() -> float:
	var max_sq := 0.0
	for i in range(_unit_count):
		var vx := _vx[i]
		var vy := _vy[i]
		var s2 := vx * vx + vy * vy
		if s2 > max_sq:
			max_sq = s2
	return sqrt(max_sq)


func _build_inspect_dict(idx: int) -> Dictionary:
	var fac := int(_u_faction_id[idx])
	var role := int(_u_role[idx])
	var task := int(_u_task[idx])
	var carry_type := int(_u_carry_type[idx])
	var max_hp := 130.0 if role == ROLE_MUTANT else 100.0
	var mem_out: Array[String] = []
	if idx >= 0 and idx < _u_mem_count.size():
		var cnt := mini(int(_u_mem_count[idx]), MEMORY_SLOTS)
		var head := int(_u_mem_head[idx]) % MEMORY_SLOTS
		var base := idx * MEMORY_SLOTS
		for k in range(cnt):
			var slot := (head - 1 - k + MEMORY_SLOTS * 2) % MEMORY_SLOTS
			var m_type := int(_u_mem_type[base + slot])
			if m_type > 0 and m_type < MEM_NAMES_RU.size():
				mem_out.append("[%dс] %s" % [int(_u_mem_time[base + slot]), MEM_NAMES_RU[m_type]])
	return {
		"found": true,
		"uid": _u_uid[idx],
		"unit_idx": idx,
		"pos": Vector2(_px[idx], _py[idx]),
		"vel": Vector2(_vx[idx], _vy[idx]),
		"hp": _hp[idx],
		"max_hp": max_hp,
		"faction": fac,
		"faction_name": FACTION_NAMES[fac] if fac < FACTION_NAMES.size() else "Wild",
		"role": role,
		"role_name": ROLE_NAMES[role] if role < ROLE_NAMES.size() else "Unknown",
		"city_id": _u_city_id[idx],
		"task": task,
		"task_name": TASK_NAMES[task] if task < TASK_NAMES.size() else "Idle",
		"cargo_type": carry_type,
		"cargo_name": CARGO_NAMES[carry_type] if carry_type < CARGO_NAMES.size() else "None",
		"cargo_amount": _u_carry_amt[idx],
		"rad_exposure": _u_rad_exp[idx],
		"mutated": role == ROLE_MUTANT,
		"kills": _u_kills[idx],
		"dodges": _u_dodges[idx] if idx < _u_dodges.size() else 0,
		"possessed": _u_uid[idx] == _possessed_uid,
		"memory": mem_out,
	}


func inspect_unit_at(world_pos: Vector2) -> Dictionary:
	if _unit_count <= 0:
		return {"found": false}
	if _spatial_hash_dirty:
		_rebuild_spatial_hash()
	var search_r := 14.0
	var best_d2 := search_r * search_r
	var best_idx := -1
	var min_cx := clampi(int(world_pos.x - search_r) >> 4, 0, _grid_w - 1)
	var max_cx := clampi(int(world_pos.x + search_r) >> 4, 0, _grid_w - 1)
	var min_cy := clampi(int(world_pos.y - search_r) >> 4, 0, _grid_h - 1)
	var max_cy := clampi(int(world_pos.y + search_r) >> 4, 0, _grid_h - 1)
	for cy in range(min_cy, max_cy + 1):
		var row_off := cy * _grid_w
		for cx in range(min_cx, max_cx + 1):
			var u := _cell_head[row_off + cx]
			while u != -1:
				var dx := _px[u] - world_pos.x
				var dy := _py[u] - world_pos.y
				var d2 := dx * dx + dy * dy
				if d2 <= best_d2:
					best_d2 = d2
					best_idx = u
				u = _unit_next[u]
	if best_idx < 0:
		return {"found": false}
	return _build_inspect_dict(best_idx)


func inspect_unit_by_id(uid: int) -> Dictionary:
	if not _uid_to_idx.has(uid):
		return {"found": false}
	var idx: int = int(_uid_to_idx[uid])
	if idx < 0 or idx >= _unit_count:
		return {"found": false}
	return _build_inspect_dict(idx)


func get_unit_follow_pos(uid: int) -> Vector2:
	if not _uid_to_idx.has(uid):
		return Vector2(-1.0, -1.0)
	var idx: int = int(_uid_to_idx[uid])
	if idx < 0 or idx >= _unit_count:
		return Vector2(-1.0, -1.0)
	return Vector2(_px[idx], _py[idx])


func bless_or_mutate_area(world_pos: Vector2, radius: float, bless: bool) -> int:
	var r := maxf(radius, 4.0)
	var r2 := r * r
	var affected := 0
	var happy_strips := 0
	var can_strip := _fx != null and _fx.has_method("spawn_reaction_strip")

	if _unit_count > 0:
		if _spatial_hash_dirty:
			_rebuild_spatial_hash()
		var min_cx := clampi(int(world_pos.x - r) >> 4, 0, _grid_w - 1)
		var max_cx := clampi(int(world_pos.x + r) >> 4, 0, _grid_w - 1)
		var min_cy := clampi(int(world_pos.y - r) >> 4, 0, _grid_h - 1)
		var max_cy := clampi(int(world_pos.y + r) >> 4, 0, _grid_h - 1)
		for cy in range(min_cy, max_cy + 1):
			var row_off := cy * _grid_w
			for cx in range(min_cx, max_cx + 1):
				var u := _cell_head[row_off + cx]
				while u != -1:
					var dx := _px[u] - world_pos.x
					var dy := _py[u] - world_pos.y
					if dx * dx + dy * dy <= r2:
						if bless:
							_u_rad_exp[u] = 0.0
							_u_fire_now[u] = 0.0
							_hit_flash_timer[u] = 0.25
							_record_memory(u, MEM_BLESSED)
							if can_strip and happy_strips < 3 and _strip_fx_budget > 0:
								_strip_fx_budget -= 1
								happy_strips += 1
								_fx.call("spawn_reaction_strip", Vector2(_px[u], _py[u] - 7.0), STRIP_HAPPY)
							if _u_role[u] == ROLE_MUTANT:
								_u_city_id[u] = -1
								_u_faction_id[u] = FACTION_NONE
								_u_role[u] = ROLE_FREE
								_u_task[u] = TASK_IDLE
								_u_flora_idx[u] = -1
								_u_carry_type[u] = CARRY_NONE
								_u_carry_amt[u] = 0.0
								_u_beacon_pos[u] = Vector2(-1.0, -1.0)
								_hp[u] = 100.0
								_suit_tint[u] = _compute_worker_tint(SUIT_PALETTE[u % SUIT_PALETTE.size()], ROLE_FREE, FACTION_NONE)
								_unit_colors_dirty = true
							else:
								_hp[u] = 100.0
							affected += 1
						else:
							if _u_faction_id[u] == FACTION_ROBOT:
								_hp[u] = 100.0
								_hit_flash_timer[u] = 0.28
								affected += 1
							elif _u_role[u] != ROLE_MUTANT:
								_mutate_unit(u, false)
								affected += 1
							else:
								_hp[u] = 130.0
								_hit_flash_timer[u] = 0.25
								affected += 1
					u = _unit_next[u]

	if _flora_count > 0:
		if _flora_hash_dirty:
			_rebuild_flora_hash()
		var fmin_cx := clampi(int(world_pos.x - r) >> 4, 0, _grid_w - 1)
		var fmax_cx := clampi(int(world_pos.x + r) >> 4, 0, _grid_w - 1)
		var fmin_cy := clampi(int(world_pos.y - r) >> 4, 0, _grid_h - 1)
		var fmax_cy := clampi(int(world_pos.y + r) >> 4, 0, _grid_h - 1)
		for cy in range(fmin_cy, fmax_cy + 1):
			var row_off := cy * _grid_w
			for cx in range(fmin_cx, fmax_cx + 1):
				var f := _flora_cell_head[row_off + cx]
				while f != -1:
					var fp := _flora_pos[f]
					var dx := fp.x - world_pos.x
					var dy := fp.y - world_pos.y
					if dx * dx + dy * dy <= r2:
						var fc := int(_flora_col[f])
						if bless:
							if fc == FLORA_TREE_CHARRED or fc == FLORA_TREE_ASH or fc == FLORA_BURNING_BUSH:
								_flora_col[f] = FLORA_LUSH_SAPLING
								_flora_burn[f] = 0.0
								_flora_grow[f] = 0.0
								_flora_spring[f] = 0.55
								_flora_spring_vel[f] = 2.5
								_flora_tint[f] = Color.WHITE
								_flora_dirty_all = true
								_flora_has_anim = true
								affected += 1
						else:
							if fc != FLORA_CRYSTAL_CLUSTER and fc != FLORA_CRYSTAL_TALL and fc != FLORA_CRYSTAL_SMALL and fc != FLORA_BOULDER and fc != FLORA_MAGMA_VENT:
								_flora_col[f] = FLORA_CRYSTAL_CLUSTER
								_flora_burn[f] = 0.0
								_flora_grow[f] = 0.0
								_flora_spring[f] = 0.5
								_flora_spring_vel[f] = 2.0
								_flora_tint[f] = Color(0.95, 0.72, 1.1, 1.0)
								_flora_dirty_all = true
								_flora_has_anim = true
								affected += 1
					f = _flora_next[f]

	if _fx != null and _area_fx_cd <= 0.0:
		_area_fx_cd = 0.22
		if bless:
			_fx.spawn_shockwave(world_pos, clampf(r * 0.9, 12.0, 56.0), Color(1.0, 0.88, 0.35, 1.0))
			_fx.spawn_burst(world_pos, 16, Color(1.0, 0.92, 0.48, 0.95), 42.0, 0.55, -22.0)
			_fx.play_sfx("terraform")
		else:
			_fx.spawn_shockwave(world_pos, clampf(r * 0.95, 12.0, 58.0), Color(0.86, 0.35, 1.0, 1.0))
			_fx.spawn_burst(world_pos, 18, Color(0.88, 0.42, 1.0, 0.95), 48.0, 0.52, -16.0)
			_fx.play_sfx("mutate")

	return affected


func get_mutant_count() -> int:
	var m := 0
	for i in range(_unit_count):
		if _u_role[i] == ROLE_MUTANT:
			m += 1
	return m


func get_unit_stats() -> Dictionary:
	var free_cnt := 0
	var col_cnt := 0
	var sol_cnt := 0
	var mut_cnt := 0
	for i in range(_unit_count):
		var r := int(_u_role[i])
		if r == ROLE_FREE:
			free_cnt += 1
		elif r == ROLE_MUTANT:
			mut_cnt += 1
		elif r == ROLE_SOLDIER:
			sol_cnt += 1
			col_cnt += 1
		else:
			col_cnt += 1
	var burn_flora := 0
	for f in range(_flora_count):
		if _flora_burn[f] > 0.0:
			burn_flora += 1
	return {
		"total": _unit_count,
		"free": free_cnt,
		"colonists": col_cnt,
		"soldiers": sol_cnt,
		"mutants": mut_cnt,
		"flora": _flora_count,
		"burning_flora": burn_flora,
		"deaths": _death_count,
		"skirmishes": _skirmish_count,
		"dodges": _total_dodges,
	}


func pop_fired_beams() -> Dictionary:
	var out := {
		"starts": _beam_starts,
		"ends": _beam_ends,
		"colors": _beam_colors,
		"widths": _beam_widths,
		"heavy": _beam_heavy,
	}
	_beam_starts = PackedVector2Array()
	_beam_ends = PackedVector2Array()
	_beam_colors = PackedColorArray()
	_beam_widths = PackedFloat32Array()
	_beam_heavy = PackedByteArray()
	return out


func count_water_stranded_units() -> int:
	if _unit_count <= 0:
		return 0
	var has_world := _world != null
	var has_is_water := has_world and _world.has_method("is_water")
	var map_w_m1 := _map_w - 1
	var map_h_m1 := _map_h - 1
	var stranded := 0
	for i in range(_unit_count):
		if _hp[i] <= 0.0:
			continue
		var px := clampi(int(_px[i]), 0, map_w_m1)
		var py := clampi(int(_py[i]), 0, map_h_m1)
		if has_is_water:
			if _world.is_water(px, py):
				stranded += 1
		elif _get_tile_tier(px, py) <= TIER_SHALLOW:
			stranded += 1
	return stranded


func transfer_squad_portal(src_pos: Vector2, dst_pos: Vector2, city_id: int) -> int:
	_ensure_layers()
	if _unit_count <= 0:
		return 0
	var max_squad: int = maxi(1, int(TUNING_KNOBS["PORTAL_MAX_SQUAD"]))
	var sel_r: float = float(TUNING_KNOBS["PORTAL_SELECT_RADIUS_PX"])
	var land_r: float = float(TUNING_KNOBS["PORTAL_LAND_SEARCH_PX"])
	var invuln_s: float = float(TUNING_KNOBS["PORTAL_INVULN_SEC"])
	var spots := _find_dry_landing_spots(dst_pos, land_r, max_squad)
	if spots.is_empty():
		return 0

	var sel_r2 := sel_r * sel_r
	var cand_idx: Array[int] = []
	var cand_score: Array[float] = []
	var inf_sz := _u_infected_timer.size()
	var lat_sz := _u_latent_timer.size()
	for i in range(_unit_count):
		if _hp[i] <= 0.0 or _u_city_id[i] != city_id:
			continue
		if _u_uid[i] == _possessed_uid:
			continue
		if _u_carry_type[i] != CARRY_NONE:
			continue
		var role := int(_u_role[i])
		var is_inf_carrier := (i < inf_sz and _u_infected_timer[i] > 0.0)
		var is_idle_free := (role == ROLE_FREE and _u_task[i] == TASK_IDLE)
		if role != ROLE_SOLDIER and not is_idle_free and not is_inf_carrier:
			continue
		var dx := _px[i] - src_pos.x
		var dy := _py[i] - src_pos.y
		var d2 := dx * dx + dy * dy
		if d2 > sel_r2:
			continue
		var w := 0.25 if role == ROLE_SOLDIER else (0.65 if is_idle_free else 0.90)
		cand_idx.append(i)
		cand_score.append((d2 + 16.0) * w)

	var n_cand := cand_idx.size()
	if n_cand <= 0:
		return 0

	var cap := mini(mini(max_squad, spots.size()), n_cand)
	var chosen := PackedInt32Array()
	for _k in range(cap):
		var best_c := -1
		var best_sc := 1e18
		for c in range(n_cand):
			var sc := cand_score[c]
			if sc >= 0.0 and sc < best_sc:
				best_sc = sc
				best_c = c
		if best_c < 0:
			break
		chosen.append(cand_idx[best_c])
		cand_score[best_c] = -1.0

	var transferred := chosen.size()
	if transferred <= 0:
		return 0

	for k in range(transferred):
		var u := chosen[k]
		var lpt := spots[k]
		_px[u] = lpt.x
		_py[u] = lpt.y
		_pos[u] = lpt
		_vx[u] = 0.0
		_vy[u] = 0.0
		_vel[u] = Vector2.ZERO
		_knockback_timer[u] = 0.0
		var is_carrier := (u < inf_sz and _u_infected_timer[u] > 0.0)
		if is_carrier:
			if u < lat_sz:
				_u_latent_timer[u] = maxf(_u_latent_timer[u], 2.5)
			_u_infected_timer[u] = maxf(_u_infected_timer[u], 7.0)
			_u_invuln_timer[u] = maxf(invuln_s, 2.5)
		else:
			_u_invuln_timer[u] = invuln_s
		_u_attack_cd[u] = 0.12
		_u_target_idx[u] = -1
		_u_target_uid[u] = -1
		_u_acq_cd[u] = 0.0
		_hit_flash_timer[u] = 0.24
		_u_last_tile[u] = -1
		_u_flora_idx[u] = -1
		_u_task[u] = TASK_PATROL
		_u_target_pos[u] = _find_walkable_offset(dst_pos, 2.0, 14.0, false)
		_u_work_timer[u] = 8.0
		_record_memory(u, MEM_PORTAL_JUMP)
		var off := u * 16
		if off + 7 < _unit_mm_buf.size():
			_unit_mm_buf[off + 3] = lpt.x
			_unit_mm_buf[off + 7] = lpt.y - 3.2

	if _fx != null:
		_fx.spawn_burst(src_pos, 10, Color(0.282, 0.961, 1.0, 0.92), 36.0, 0.42, -14.0)
		_fx.spawn_burst(dst_pos, 14, Color(0.95, 0.85, 0.45, 0.95), 42.0, 0.48, -16.0)
		if _fx.has_method("spawn_reaction_strip") and transferred > 0:
			_fx.call("spawn_reaction_strip", spots[0] + Vector2(0.0, -7.0), STRIP_PORTAL)

	_rebuild_spatial_hash()
	_pos_dirty = true
	_shadows_dirty = true
	return transferred


func apply_ai_glitch_units(world_pos: Vector2, radius: float) -> int:
	_ensure_layers()
	if _unit_count <= 0:
		return 0
	_rebuild_spatial_hash()
	var r := maxf(radius, 4.0)
	var r2 := r * r
	var glitch_dur: float = float(TUNING_KNOBS["GLITCH_DURATION_SEC"])
	var min_cx := clampi(int(world_pos.x - r) >> 4, 0, _grid_w - 1)
	var max_cx := clampi(int(world_pos.x + r) >> 4, 0, _grid_w - 1)
	var min_cy := clampi(int(world_pos.y - r) >> 4, 0, _grid_h - 1)
	var max_cy := clampi(int(world_pos.y + r) >> 4, 0, _grid_h - 1)
	var hit_cnt := 0
	var any_died := false

	for cy in range(min_cy, max_cy + 1):
		var row_off := cy * _grid_w
		for cx in range(min_cx, max_cx + 1):
			var u := _cell_head[row_off + cx]
			while u != -1:
				if _hp[u] > 0.0:
					var dx := _px[u] - world_pos.x
					var dy := _py[u] - world_pos.y
					if dx * dx + dy * dy <= r2:
						if u < _u_glitch_timer.size():
							_u_glitch_timer[u] = maxf(_u_glitch_timer[u], glitch_dur)
						_u_attack_cd[u] = maxf(_u_attack_cd[u], 0.35)
						var jit := Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU))
						_vx[u] += jit.x * 26.0
						_vy[u] += jit.y * 26.0
						_knockback_timer[u] = maxf(_knockback_timer[u], 0.18)
						_hit_flash_timer[u] = maxf(_hit_flash_timer[u], 0.25)
						if _u_faction_id[u] == FACTION_ROBOT and (u >= _u_invuln_timer.size() or _u_invuln_timer[u] <= 0.0):
							_hp[u] -= 6.0
							if _hp[u] <= 0.0:
								any_died = true
						_record_memory(u, MEM_GLITCHED)
						hit_cnt += 1
				u = _unit_next[u]
	if hit_cnt > 0:
		_any_glitched_unit = true

	if any_died:
		var k := 0
		while k < _unit_count:
			if _hp[k] <= 0.0:
				var prev_last := _unit_count - 1
				_kill_unit(k, DEATH_COMBAT)
				if k < _unit_count and prev_last != k:
					var src_off := prev_last * 16
					var dst_off := k * 16
					for m in range(16):
						_unit_mm_buf[dst_off + m] = _unit_mm_buf[src_off + m]
				continue
			k += 1
		if _mm_units != null and _mm_units.multimesh != null:
			_mm_units.multimesh.visible_instance_count = _unit_count
			_mm_units.multimesh.buffer = _unit_mm_buf
		_rebuild_spatial_hash()

	if _fx != null:
		_fx.spawn_shockwave(world_pos, clampf(r * 0.9, 10.0, 54.0), Color(0.282, 0.961, 1.0, 1.0))
		_fx.emit_spark_arc(world_pos, Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU)), Color(0.282, 0.961, 1.0, 1.0))
		_fx.spawn_burst(world_pos, 16, Color(0.282, 0.961, 1.0, 0.95), 42.0, 0.45, -14.0)
	return hit_cnt


func apply_xeno_virus(world_pos: Vector2, radius: float) -> int:
	_ensure_layers()
	if _unit_count <= 0:
		return 0
	_rebuild_spatial_hash()
	var r := maxf(radius, 4.0)
	var r2 := r * r
	var virus_dur: float = float(TUNING_KNOBS["VIRUS_DURATION_SEC"])
	var min_cx := clampi(int(world_pos.x - r) >> 4, 0, _grid_w - 1)
	var max_cx := clampi(int(world_pos.x + r) >> 4, 0, _grid_w - 1)
	var min_cy := clampi(int(world_pos.y - r) >> 4, 0, _grid_h - 1)
	var max_cy := clampi(int(world_pos.y + r) >> 4, 0, _grid_h - 1)
	var infected_cnt := 0

	for cy in range(min_cy, max_cy + 1):
		var row_off := cy * _grid_w
		for cx in range(min_cx, max_cx + 1):
			var u := _cell_head[row_off + cx]
			while u != -1:
				if _hp[u] > 0.0:
					var dx := _px[u] - world_pos.x
					var dy := _py[u] - world_pos.y
					if dx * dx + dy * dy <= r2:
						if u < _u_infected_timer.size():
							_u_infected_timer[u] = maxf(_u_infected_timer[u], virus_dur)
						if u < _u_latent_timer.size():
							_u_latent_timer[u] = 0.0
						_u_task[u] = TASK_IDLE
						_hit_flash_timer[u] = maxf(_hit_flash_timer[u], 0.25)
						_record_memory(u, MEM_INFECTED)
						infected_cnt += 1
				u = _unit_next[u]
	if infected_cnt > 0:
		_any_infected_unit = true

	if _fx != null:
		_fx.spawn_shockwave(world_pos, clampf(r * 0.9, 10.0, 56.0), BEAM_COL_SPORE)
		_fx.spawn_burst(world_pos, 18, Color(0.52, 1.0, 0.42, 0.95), 40.0, 0.55, -12.0)
	return infected_cnt


func plant_bio_seeder(world_pos: Vector2, radius: float) -> int:
	_ensure_layers()
	var r := maxf(radius, 8.0)
	var want_units: int = clampi(int(TUNING_KNOBS["BIO_SEEDER_UNITS"]), 0, MAX_UNITS - _unit_count)
	var spots := _find_dry_landing_spots(world_pos, r, maxi(want_units, 12))
	var spawned_units := 0
	if want_units > 0 and not spots.is_empty():
		var n_add := mini(want_units, spots.size())
		var old_cnt := _unit_count
		_unit_count = old_cnt + n_add
		_resize_unit_arrays(_unit_count)
		var bio_tint := Color(0.45, 0.88, 0.46, 1.0)
		for k in range(n_add):
			var idx := old_cnt + k
			var sp := spots[k]
			_init_unit_slot(idx, sp, -1, FACTION_SPORE, ROLE_FREE, sp, bio_tint)
			spawned_units += 1
		if _mm_units != null and _mm_units.multimesh != null:
			_mm_units.multimesh.visible_instance_count = _unit_count
		_unit_colors_dirty = true
		_spatial_hash_dirty = true
		_shadows_dirty = true

	var flora_added := 0
	var max_flora_add := mini(8, MAX_FLORA - _flora_count)
	var flora_cols := [FLORA_LUSH_SAPLING, FLORA_SHROOM_LUSH, FLORA_SPORE_POD]
	for t in range(max_flora_add):
		var fa := _rng.randf_range(0.0, TAU)
		var fr := _rng.randf_range(2.0, r)
		var fp := Vector2(
			clampf(world_pos.x + cos(fa) * fr, 4.0, float(_map_w - 5)),
			clampf(world_pos.y + sin(fa) * fr, 4.0, float(_map_h - 5))
		)
		if _is_strictly_dry_land_tile(int(fp.x), int(fp.y)) and not _is_inside_any_building(fp, 2.0):
			var fcol: int = flora_cols[t % flora_cols.size()]
			if _append_flora_slot(fp, fcol, true) >= 0:
				flora_added += 1

	var total := spawned_units + flora_added
	if total > 0:
		if spawned_units > 0:
			_rebuild_spatial_hash()
			_sync_unit_multimesh()
		if flora_added > 0:
			_sync_flora_multimesh()
		if _fx != null:
			_fx.spawn_shockwave(world_pos, clampf(r * 0.85, 10.0, 50.0), BEAM_COL_SPORE)
			_fx.spawn_burst(world_pos, 16, BEAM_COL_SPORE, 32.0, 0.50, -18.0)
	return total


func find_nearest_hostile_pos(world_pos: Vector2, max_range: float, friendly_city: int) -> Dictionary:
	if _unit_count <= 0 or max_range <= 0.5 or _macro_w <= 0 or _macro_h <= 0:
		return {"found": false, "unit_idx": -1, "pos": Vector2.ZERO, "faction": FACTION_NONE}
	if _spatial_hash_dirty:
		_rebuild_spatial_hash()
	if _macro_head.size() < _macro_w * _macro_h:
		return {"found": false, "unit_idx": -1, "pos": Vector2.ZERO, "faction": FACTION_NONE}
	var r2 := max_range * max_range
	var best_idx := -1
	var best_d2 := r2
	var mcx0 := clampi(int(world_pos.x) >> 6, 0, _macro_w - 1)
	var mcy0 := clampi(int(world_pos.y) >> 6, 0, _macro_h - 1)
	var max_mr := int(max_range / 64.0) + 1
	var edge_min := maxf(0.0, minf(minf(world_pos.x - float(mcx0 << 6), float((mcx0 + 1) << 6) - world_pos.x), minf(world_pos.y - float(mcy0 << 6), float((mcy0 + 1) << 6) - world_pos.y)))
	var any_inf := _any_infected_unit
	var any_glitch := _any_glitched_unit
	var inf_sz := _u_infected_timer.size()
	var lat_sz := _u_latent_timer.size()
	var glitch_sz := _u_glitch_timer.size()
	var diplo_sz := _diplo_matrix.size()
	var diplo_stride := _diplo_max_cities

	for mr in range(max_mr + 1):
		var y0 := maxi(0, mcy0 - mr)
		var y1 := mini(_macro_h - 1, mcy0 + mr)
		var x_lft := mcx0 - mr
		var x_rgt := mcx0 + mr
		for my in range(y0, y1 + 1):
			var at_y_edge := (mr == 0 or my == mcy0 - mr or my == mcy0 + mr)
			var step_x := 1 if at_y_edge else (mr << 1)
			var mx := x_lft
			while mx <= x_rgt:
				if mx >= 0 and mx < _macro_w:
					var j := _macro_head[my * _macro_w + mx]
					if j != -1:
						var min_x := float(mx << 6)
						var max_x := float((mx + 1) << 6)
						var min_y := float(my << 6)
						var max_y := float((my + 1) << 6)
						var bdx := maxf(0.0, maxf(min_x - world_pos.x, world_pos.x - max_x))
						var bdy := maxf(0.0, maxf(min_y - world_pos.y, world_pos.y - max_y))
						if bdx * bdx + bdy * bdy <= best_d2:
							while j != -1:
								if _hp[j] > 0.0:
									var j_cid := _u_city_id[j]
									var j_mut := (_u_role[j] == ROLE_MUTANT or _u_faction_id[j] == FACTION_MUTANT)
									var j_inf := any_inf and j < inf_sz and _u_infected_timer[j] > 0.0 and (j >= lat_sz or _u_latent_timer[j] <= 0.0)
									var hostile := false
									if j_mut or (j_inf and not (int(_u_faction_id[j]) == FACTION_SPORE and friendly_city >= 0 and j_cid == friendly_city)):
										hostile = true
									elif friendly_city < 0:
										if any_glitch and j < glitch_sz and _u_glitch_timer[j] > 0.0:
											hostile = true
										elif j_cid >= 0:
											hostile = _is_city_at_war(j_cid)
									elif j_cid != friendly_city:
										if any_glitch and j < glitch_sz and _u_glitch_timer[j] > 0.0:
											hostile = true
										elif j_cid >= 0 and diplo_stride > 0 and friendly_city < diplo_stride and j_cid < diplo_stride:
											var di1 := friendly_city * diplo_stride + j_cid
											var di2 := j_cid * diplo_stride + friendly_city
											if di1 < diplo_sz and di2 < diplo_sz:
												var r1 := int(_diplo_matrix[di1])
												var r2_d := int(_diplo_matrix[di2])
												var rel := r1 if r1 >= r2_d else r2_d
												hostile = (rel == DIPLO_TOTAL_WAR or rel == DIPLO_REBELLION)
									if hostile:
										var dx := _px[j] - world_pos.x
										var dy := _py[j] - world_pos.y
										var d2 := dx * dx + dy * dy
										if d2 <= best_d2:
											best_d2 = d2
											best_idx = j
								j = _macro_next[j]
				mx += step_x
		if best_idx >= 0:
			var next_d := edge_min + float(mr) * 64.0
			if best_d2 <= next_d * next_d:
				break

	if best_idx >= 0:
		return {
			"found": true,
			"unit_idx": best_idx,
			"pos": Vector2(_px[best_idx], _py[best_idx]),
			"faction": int(_u_faction_id[best_idx]),
		}
	return {"found": false, "unit_idx": -1, "pos": Vector2.ZERO, "faction": FACTION_NONE}


func apply_external_damage(world_pos: Vector2, radius: float, spec: Dictionary) -> int:
	if _unit_count <= 0:
		return 0
	var dmg: float = float(spec.get("damage", 24.0))
	var burn: float = float(spec.get("burn", 0.0))
	var target_idx: int = int(spec.get("unit_idx", -1))
	var friendly_city: int = int(spec.get("friendly_city", -1))
	var armor_pierce: bool = bool(spec.get("armor_pierce", false))
	var imp: float = float(spec.get("impulse", 0.0))
	var robot_armor_mult: float = float(TUNING_KNOBS["ROBOT_ARMOR_MULT"])
	var city_emp_sz := _city_emp_timer.size()
	var hits := 0
	var any_died := false

	if target_idx >= 0:
		if target_idx < _unit_count and _hp[target_idx] > 0.0:
			if target_idx >= _u_invuln_timer.size() or _u_invuln_timer[target_idx] <= 0.0:
				var fdmg := dmg
				var t_cid := _u_city_id[target_idx]
				var t_emp := (t_cid >= 0 and t_cid < city_emp_sz and _city_emp_timer[t_cid] > 0.0)
				var t_glitch := (target_idx < _u_glitch_timer.size() and _u_glitch_timer[target_idx] > 0.0)
				if int(_u_faction_id[target_idx]) == FACTION_ROBOT and not armor_pierce and not t_glitch and not t_emp:
					fdmg *= robot_armor_mult
				_hp[target_idx] -= fdmg
				if burn > 0.0:
					_u_fire_now[target_idx] = maxf(_u_fire_now[target_idx], minf(burn, 1.0))
					if target_idx < _u_corrode_timer.size():
						_u_corrode_timer[target_idx] = maxf(_u_corrode_timer[target_idx], burn)
				_hit_flash_timer[target_idx] = maxf(_hit_flash_timer[target_idx], 0.18)
				_record_memory(target_idx, MEM_FOUGHT)
				if imp > 0.0:
					var pvec := Vector2(_px[target_idx] - world_pos.x, _py[target_idx] - world_pos.y)
					var pdir := pvec.normalized() if pvec.length_squared() > 0.01 else Vector2.RIGHT
					_vx[target_idx] += pdir.x * imp
					_vy[target_idx] += pdir.y * imp
					_knockback_timer[target_idx] = maxf(_knockback_timer[target_idx], 0.18)
				if _hp[target_idx] <= 0.0:
					any_died = true
				hits = 1
	else:
		if _spatial_hash_dirty:
			_rebuild_spatial_hash()
		var r := maxf(radius, 4.0)
		var r2 := r * r
		var min_cx := clampi(int(world_pos.x - r) >> 4, 0, _grid_w - 1)
		var max_cx := clampi(int(world_pos.x + r) >> 4, 0, _grid_w - 1)
		var min_cy := clampi(int(world_pos.y - r) >> 4, 0, _grid_h - 1)
		var max_cy := clampi(int(world_pos.y + r) >> 4, 0, _grid_h - 1)
		for cy in range(min_cy, max_cy + 1):
			var row_off := cy * _grid_w
			for cx in range(min_cx, max_cx + 1):
				var u := _cell_head[row_off + cx]
				while u != -1:
					if _hp[u] > 0.0 and (friendly_city < 0 or _is_hostile_to_city(u, friendly_city)):
						var diff := Vector2(_px[u] - world_pos.x, _py[u] - world_pos.y)
						var d2 := diff.length_squared()
						if d2 <= r2:
							if u >= _u_invuln_timer.size() or _u_invuln_timer[u] <= 0.0:
								var dist := sqrt(d2)
								var falloff := clampf(1.0 - (dist / r) * 0.55, 0.35, 1.0)
								var fdmg := dmg * falloff
								var u_cid := _u_city_id[u]
								var u_emp := (u_cid >= 0 and u_cid < city_emp_sz and _city_emp_timer[u_cid] > 0.0)
								var u_glitch := (u < _u_glitch_timer.size() and _u_glitch_timer[u] > 0.0)
								if int(_u_faction_id[u]) == FACTION_ROBOT and not armor_pierce and not u_glitch and not u_emp:
									fdmg *= robot_armor_mult
								_hp[u] -= fdmg
								if burn > 0.0:
									_u_fire_now[u] = maxf(_u_fire_now[u], minf(burn, 1.0))
									if u < _u_corrode_timer.size():
										_u_corrode_timer[u] = maxf(_u_corrode_timer[u], burn)
								_hit_flash_timer[u] = maxf(_hit_flash_timer[u], 0.20)
								_record_memory(u, MEM_FOUGHT)
								if imp > 0.0:
									var pdir := diff / maxf(dist, 0.5) if d2 > 0.01 else Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU))
									_vx[u] += pdir.x * (imp * falloff)
									_vy[u] += pdir.y * (imp * falloff)
									_knockback_timer[u] = maxf(_knockback_timer[u], 0.20)
								if _hp[u] <= 0.0:
									any_died = true
								hits += 1
					u = _unit_next[u]

	if any_died:
		var k := 0
		while k < _unit_count:
			if _hp[k] <= 0.0:
				var cause := DEATH_BURN if burn > 0.0 else DEATH_COMBAT
				var prev_last := _unit_count - 1
				_kill_unit(k, cause)
				if k < _unit_count and prev_last != k:
					var src_off := prev_last * 16
					var dst_off := k * 16
					for m in range(16):
						_unit_mm_buf[dst_off + m] = _unit_mm_buf[src_off + m]
				continue
			k += 1
		if _mm_units != null and _mm_units.multimesh != null:
			_mm_units.multimesh.visible_instance_count = _unit_count
			_mm_units.multimesh.buffer = _unit_mm_buf
		_rebuild_spatial_hash()

	return hits
