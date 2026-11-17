extends Node2D
class_name WorldTerrain

## Procedural pixel-art planetary terrain, biome climate, fire/alchemy & environment simulation.
## Maintains 640x360 flat PackedArrays, dirty-chunk-only GPU texture updates,
## NW-SE faceted relief shading, and an atmospheric drifting cloud/dust layer (z=4).

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
	"TEMP_EQUILIBRIUM_MAX_C": 29.0,
	"TEMP_STEADY_EPS_C": 0.04,
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
}

const CHUNK_SIZE := 16
const CHUNK_SHIFT := 4
const STRUCT_CLUSTER_MAX_SPAN_PX := 64
const STRUCT_CLUSTER_MAX_GAP_PX := 16
const STRUCT_MAX_RECTS_PER_FLUSH := 6
const INV_65536 := 1.0 / 65536.0

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

const COL_EDGE_OCEAN := Color(0.114, 0.298, 0.471, 1.0)
const COL_EDGE_OCEAN_DEEP := Color(0.086, 0.224, 0.369, 1.0)
const COL_EDGE_HILLS := Color(0.192, 0.200, 0.200, 1.0)
const COL_EDGE_MTN := Color(0.173, 0.188, 0.196, 1.0)

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
var _plasma_glow: PackedByteArray
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

var _chunks_w: int = 0
var _chunks_h: int = 0
var _chunk_active: PackedByteArray
var _chunk_dirty: PackedByteArray
var _chunk_struct_dirty: PackedByteArray
var _chunk_row_mask: PackedInt32Array
var _chunk_dirty_bounds: PackedInt32Array
var _active_chunks: PackedInt32Array
var _active_chunk_pos: PackedInt32Array
var _dirty_chunks: PackedInt32Array
var _structural_dirty_chunks: PackedInt32Array
var _work_stamp: PackedInt32Array
var _work_stamp_id: int = 1

var _rng := RandomNumberGenerator.new()
var _cosmic_age_rng := RandomNumberGenerator.new()
var current_seed: int = 20261114
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
}
var _avg_temp_cached: float = 18.0
var _temp_total_sum: float = 0.0
var _inv_total_tiles: float = 0.0
var _temp_scan_row: int = 0
var _temp_scan_accum: float = 0.0
var _env_chunk_cursor: int = 0
var _env_step_count: int = 0
var _steam_cooldown: float = 0.0
var _fire_events_total: int = 0
var _active_fire_tiles: int = 0
var _ash_tiles: int = 0
var _initialized: bool = false


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


func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var total: int = map_w * map_h
	_tiers.resize(total)
	_biomes.resize(total)
	_river_mask.resize(total)
	_vent_mask.resize(total)
	_ash.resize(total)
	_plasma_glow.resize(total)
	_plasma_glow.fill(0)
	_height.resize(total)
	_temp.resize(total)
	_rad.resize(total)
	_moisture.resize(total)
	_fire.resize(total)
	_work_stamp.resize(total)
	_work_stamp.fill(0)

	var age_seed: int = (current_seed ^ 0xA6E5301) & 0x7FFFFFFF
	_cosmic_age_rng.seed = age_seed if age_seed != 0 else 0xA6E5301

	_rgba_buf.resize(total * 4)
	_mask_buf.resize(total * 4)

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
	add_child(_mm_clouds)


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


func generate_planet(seed_val: int) -> void:
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

	_river_mask.fill(0)
	_vent_mask.fill(0)
	_ash.fill(0)
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

	_generate_relief(seed_val)
	_carve_rivers()
	_generate_biomes_and_climate(seed_val)
	_carve_volcanic_fissures()

	_recompute_all_chunk_flags()
	_recompute_avg_temp_full()
	_render_rect(0, 0, map_w, map_h, true)
	_init_clouds()
	set_cosmic_age(CosmicAge.GOLD, true)

	map_rebuilt.emit()


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
		var lat_factor: float = 1.0 - absf(float(y) / float(map_h) - 0.5) * 1.15
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
			var temp_c: float = base_amb + (lat_factor - 0.5) * 12.0 - lapse
			if t <= Tier.SHALLOW:
				temp_c = lerpf(base_amb - 3.5, temp_c, 0.35)
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
	var mm: MultiMesh = _mm_clouds.multimesh
	mm.instance_count = n

	var base_vx: float = float(TUNING_KNOBS["CLOUD_SPEED_X"])
	var base_vy: float = float(TUNING_KNOBS["CLOUD_SPEED_Y"])

	for i in range(n):
		var is_haze: bool = (i >= int(n * 0.68))
		_cloud_pos[i] = Vector2(_rng.randf_range(0.0, float(map_w)), _rng.randf_range(0.0, float(map_h)))
		var spd_mul: float = _rng.randf_range(0.75, 1.35)
		_cloud_vel[i] = Vector2(base_vx * spd_mul, base_vy * spd_mul + _rng.randf_range(-0.4, 0.4))
		# Keep quad scale 1:1 world pixel locked; vary footprint smoothly via density_scale in shader
		_cloud_scale[i] = Vector2(1.0, 1.0)
		mm.set_instance_color(i, Color(1.0, 1.0, 1.0, 1.0))
		mm.set_instance_custom_data(i, Color(
			_rng.randf(),
			1.0 if is_haze else 0.0,
			_rng.randf_range(0.72, 1.12) if not is_haze else _rng.randf_range(0.92, 1.24),
			_rng.randf_range(0.76, 1.0)
		))
	_sync_cloud_multimesh()


func _sync_cloud_multimesh() -> void:
	var mm: MultiMesh = _mm_clouds.multimesh
	for i in range(_cloud_pos.size()):
		var t := Transform2D(0.0, _cloud_scale[i], 0.0, _cloud_pos[i])
		mm.set_instance_transform_2d(i, t)


func _step_clouds(dt: float) -> void:
	var n: int = _cloud_pos.size()
	var mm: MultiMesh = _mm_clouds.multimesh
	var max_x: float = float(map_w + 96)
	var max_y: float = float(map_h + 48)
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
		mm.set_instance_transform_2d(i, Transform2D(0.0, _cloud_scale[i], 0.0, cp))


func apply_brush(world_pos: Vector2, brush_mode: int, radius: float = 12.0) -> void:
	_ensure_initialized()
	var mode: int = BrushMode.LOWER_CANAL if brush_mode < 0 else brush_mode
	if mode == BrushMode.ORBITAL_STRIKE:
		apply_orbital_strike(world_pos, radius, false)
		return
	var cx: int = int(floor(world_pos.x))
	var cy: int = int(floor(world_pos.y))
	var r: int = clampi(int(round(radius)), 1, 64)
	var r2: float = float(r * r)
	var touched_water_lava: bool = false
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

			if mode == BrushMode.TERRAFORM_LIFE:
				any_changed = true
				_vent_mask[idx] = 0
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

			elif mode == BrushMode.LOWER_CANAL:
				any_changed = true
				_vent_mask[idx] = 0
				if _fire[idx] > 0.0:
					_fire[idx] = 0.0
					_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
				var sink: float = 0.06 + falloff * 0.20
				_height[idx] = clampf(_height[idx] - sink, 0.08, 0.95)
				_tiers[idx] = _classify_height(_height[idx])
				if _tiers[idx] <= Tier.SHALLOW:
					if _temp[idx] > 120.0 or _biomes[idx] == Biome.LAVA:
						touched_water_lava = true
					_biomes[idx] = Biome.RUST
					_temp[idx] = minf(_temp[idx], 28.0)
					_moisture[idx] = 1.0
					if _ash[idx] > 0:
						_ash[idx] = 0
						_ash_tiles = maxi(0, _ash_tiles - 1)
				else:
					if _biomes[idx] == Biome.LAVA:
						_biomes[idx] = Biome.SCORCHED
					_moisture[idx] = maxf(_moisture[idx], 0.32 * falloff)

			elif mode == BrushMode.CRYSTAL_FLORA:
				any_changed = true
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

			elif mode == BrushMode.LAVA_VOLCANO:
				any_changed = true
				if _tiers[idx] <= Tier.CLOSE_OCEAN:
					_height[idx] = clampf(_height[idx] + falloff * 0.22, 0.0, 0.72)
					_tiers[idx] = _classify_height(_height[idx])
					if _tiers[idx] >= Tier.SAND:
						_biomes[idx] = Biome.SCORCHED
						_temp[idx] = maxf(_temp[idx], 220.0)
						_river_mask[idx] = 0
						touched_water_lava = true
				else:
					_height[idx] = clampf(_height[idx] + falloff * 0.14, 0.0, 0.88)
					_tiers[idx] = maxi(_tiers[idx], _classify_height(_height[idx]))
					_river_mask[idx] = 0
					var ang_f: float = atan2(float(dy), float(dx))
					var crack_wave: float = absf(sin(ang_f * 5.0 + float(cx) * 0.17 + norm_d * 4.5))
					var vein_hash: int = ((px * 73856093) ^ (py * 19349663)) & 7
					var is_core: bool = norm_d < 0.24
					var is_fissure: bool = norm_d < 0.74 and crack_wave > 0.82 and vein_hash < 5
					if is_core or is_fissure:
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

			elif mode == BrushMode.METEOR_CRATER:
				any_changed = true
				_vent_mask[idx] = 0
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
						touched_water_lava = true
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

			elif mode == BrushMode.VORTEX_PULL:
				if _temp[idx] > 35.0:
					_temp[idx] = maxf(24.0, _temp[idx] - 18.0 * falloff)
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

	if mode != BrushMode.VORTEX_PULL:
		region_changed.emit(Rect2i(rx0, ry0, rx1 - rx0, ry1 - ry0))

	if mode == BrushMode.METEOR_CRATER:
		surface_impact.emit(world_pos, float(r), "meteor")
	elif mode == BrushMode.LAVA_VOLCANO:
		surface_impact.emit(world_pos, float(r), "steam" if touched_water_lava else "lava")
	elif touched_water_lava:
		surface_impact.emit(world_pos, float(r), "steam")


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
	var is_rain: bool = (k_low == "rain" or k_low == "rainburst" or k_low == "monsoon" or k_low == "water")
	var is_fire: bool = (k_low == "firestorm" or k_low == "fire" or k_low == "lava")
	var is_ion: bool = (k_low == "ion_storm" or k_low == "ion" or k_low == "crystal")
	var is_meltdown: bool = (k_low == "meltdown_crater" or k_low == "meltdown")
	if not is_rain and not is_fire and not is_ion and not is_meltdown:
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
			var t: int = _tiers[idx]
			var b: int = _biomes[idx]

			if is_rain:
				any_changed = true
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
					if b == Biome.RUST or (b == Biome.SCORCHED and (_ash[idx] > 0 or falloff > 0.35)):
						var p_h: int = ((px * 73856093) ^ (py * 19349663)) & 7
						if falloff > 0.40 or p_h < 5:
							_biomes[idx] = Biome.LUSH
							if _ash[idx] > 0:
								_ash[idx] = maxi(0, int(_ash[idx]) - 120)
								if _ash[idx] == 0:
									_ash_tiles = maxi(0, _ash_tiles - 1)

			elif is_fire:
				if t >= Tier.SAND and t < Tier.SUMMIT:
					any_changed = true
					_moisture[idx] = maxf(0.0, _moisture[idx] * (0.45 - 0.25 * falloff))
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

			elif is_ion:
				any_changed = true
				_rad[idx] = clampf(_rad[idx] + 0.55 * falloff + 0.12, 0.0, 1.0)
				if t >= Tier.SAND and t <= Tier.HILLS and b != Biome.LAVA:
					var c_h: int = ((px * 73856093) ^ (py * 19349663)) & 7
					if norm_d < 0.45 or (norm_d < 0.85 and c_h < 4):
						_biomes[idx] = Biome.CRYSTAL
						if _fire[idx] > 0.0:
							_fire[idx] = 0.0
							_active_fire_tiles = maxi(0, _active_fire_tiles - 1)

			elif is_meltdown:
				any_changed = true
				_vent_mask[idx] = 0
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

	if is_meltdown:
		surface_impact.emit(world_pos, float(r), "meltdown")
	elif is_fire:
		surface_impact.emit(world_pos, float(r), "firestorm")
	elif is_ion:
		surface_impact.emit(world_pos, float(r), "ion_storm")
	elif is_rain:
		surface_impact.emit(world_pos, float(r), "rain")


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
	_env_time += eff_dt
	_env_step_count += 1
	_steam_cooldown = maxf(0.0, _steam_cooldown - eff_dt)
	_step_clouds(eff_dt)

	var diff_k: float = clampf(float(TUNING_KNOBS["TEMP_DIFFUSE_RATE"]) * eff_dt * 0.22, 0.0, 0.20)
	var cool_k: float = clampf(float(TUNING_KNOBS["TEMP_COOL_RATE"]) * eff_dt, 0.0, 0.50)
	var rad_decay: float = float(TUNING_KNOBS["RAD_DECAY_RATE"]) * eff_dt
	var rad_crys_floor: float = float(TUNING_KNOBS["RAD_CRYSTAL_FLOOR"])
	var lava_min: float = float(TUNING_KNOBS["LAVA_MIN_TEMP_C"])
	var lava_floor: float = float(TUNING_KNOBS["LAVA_VENT_FLOOR_C"])
	var amb_c: float = float(TUNING_KNOBS["TEMP_AMBIENT_C"])
	var eq_max_c: float = float(TUNING_KNOBS["TEMP_EQUILIBRIUM_MAX_C"])
	var steady_eps: float = float(TUNING_KNOBS["TEMP_STEADY_EPS_C"])
	var fire_decay: float = float(TUNING_KNOBS["FIRE_BURN_DECAY"]) * eff_dt
	var fire_spread_base: float = float(TUNING_KNOBS["FIRE_SPREAD_CHANCE"]) * eff_dt * _cosmic_fire_mul
	var crystal_prob: float = float(TUNING_KNOBS["CRYSTAL_SPREAD_CHANCE"]) * eff_dt
	var lush_prob: float = float(TUNING_KNOBS["LUSH_RECOVER_CHANCE"]) * eff_dt
	var ash_prob: float = float(TUNING_KNOBS["ASH_RECOVER_CHANCE"]) * eff_dt
	var ash_decay_step: int = maxi(1, int(round(8.0 * eff_dt)))
	var plasma_decay_step: int = maxi(1, int(round(float(TUNING_KNOBS["PLASMA_SHIMMER_DECAY_PER_SEC"]) * eff_dt)))

	var crystal_prob_i: int = int(ceil(crystal_prob * 65536.0))
	var lush_prob_i: int = int(ceil(lush_prob * 65536.0))
	var ash_prob_i: int = int(ceil(ash_prob * 65536.0))

	var steam_emitted_this_step: bool = false
	var active_n: int = _active_chunks.size()
	var active_budget: int = int(TUNING_KNOBS["ACTIVE_CHUNK_BUDGET"])
	var process_n: int = mini(active_n, active_budget)
	var mw: int = map_w
	var mh: int = map_h
	var rng_s: int = _fast_rng_seed
	var temp_sum_delta: float = 0.0

	if process_n > 0:
		var start_cursor: int = _env_chunk_cursor % active_n
		for step_i in range(process_n):
			var cidx: int = _active_chunks[(start_cursor + step_i) % active_n]
			var row_mask: int = _chunk_row_mask[cidx]
			if row_mask == 0:
				_chunk_active[cidx] = 0
				continue
			_chunk_row_mask[cidx] = 0
			@warning_ignore("integer_division")
			var cy: int = cidx / _chunks_w
			var cx: int = cidx % _chunks_w
			var y0: int = cy << CHUNK_SHIFT
			var y1: int = mini(mh - 1, y0 + CHUNK_SIZE)
			var start_y: int = maxi(1, y0)
			var x0: int = cx << CHUNK_SHIFT
			var x1: int = mini(mw - 1, x0 + CHUNK_SIZE)
			var start_x: int = maxi(1, x0)
			var still_active: bool = false

			for py in range(start_y, y1):
				var ly: int = py & 15
				var row_bit: int = 1 << ly
				if ((row_mask | _chunk_row_mask[cidx]) & row_bit) == 0:
					continue
				var row_still_active: bool = false
				var row_off: int = py * mw
				for px in range(start_x, x1):
					var idx: int = row_off + px
					var f_cur: float = _fire[idx]
					var a_cur: int = _ash[idx]
					var t_cur: float = _temp[idx]
					var b_cur: int = _biomes[idx]
					var pg_cur: int = _plasma_glow[idx]

					# Fast skip for calm ambient tiles
					if f_cur <= 0.0 and a_cur == 0 and t_cur <= eq_max_c and b_cur != Biome.LAVA and pg_cur == 0:
						if _rad[idx] <= (rad_crys_floor if b_cur == Biome.CRYSTAL else 0.02):
							continue

					var r_cur: float = _rad[idx]
					var tier_cur: int = _tiers[idx]
					var r_floor: float = rad_crys_floor if b_cur == Biome.CRYSTAL else 0.02

					# 1. Active Fire & Ash succession
					if f_cur > 0.0:
						if tier_cur <= Tier.SHALLOW or _moisture[idx] >= 0.86 or b_cur == Biome.LAVA:
							_fire[idx] = 0.0
							_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
							_mark_chunk_dirty_local(cidx, px & 15, ly, px & 15, ly, f_cur > 0.05)
						else:
							row_still_active = true
							var fire_t: float = 195.0 + f_cur * 120.0
							if fire_t > t_cur:
								_temp[idx] = fire_t
								temp_sum_delta += fire_t - t_cur
								t_cur = fire_t
							_moisture[idx] = maxf(0.0, _moisture[idx] - 0.14 * eff_dt)

							# Organic fire spread across dry LUSH / RUST
							rng_s = (rng_s * 1664525 + 1013904223) & 0x7FFFFFFF
							var dir_r: int = (rng_s >> 16) & 3
							var nidx_f: int = idx - 1 if dir_r == 0 else (idx + 1 if dir_r == 1 else (idx - mw if dir_r == 2 else idx + mw))
							if _fire[nidx_f] <= 0.0 and _tiers[nidx_f] >= Tier.SAND and _tiers[nidx_f] < Tier.SUMMIT:
								var nb_b_f: int = _biomes[nidx_f]
								if nb_b_f == Biome.LUSH or nb_b_f == Biome.RUST:
									var nb_moist: float = _moisture[nidx_f]
									var moist_lim: float = 0.78 if nb_b_f == Biome.LUSH else 0.45
									if nb_moist < moist_lim:
										rng_s = (rng_s * 1664525 + 1013904223) & 0x7FFFFFFF
										var roll_f: float = float(rng_s & 0xFFFF) * INV_65536
										var p_spread: float = fire_spread_base * (1.1 - nb_moist) * (1.2 if nb_b_f == Biome.LUSH else 0.55)
										if roll_f < p_spread:
											_ignite_tile(nidx_f, clampf(f_cur * 0.92 + 0.15, 0.35, 1.0))
											var nx_f: int = nidx_f % mw
											@warning_ignore("integer_division")
											var ny_f: int = nidx_f / mw
											_mark_tile_dirty(nx_f, ny_f, true, 0)

							var next_f: float = f_cur - fire_decay
							if next_f <= 0.0:
								_fire[idx] = 0.0
								_active_fire_tiles = maxi(0, _active_fire_tiles - 1)
								_biomes[idx] = Biome.SCORCHED
								b_cur = Biome.SCORCHED
								r_floor = 0.02
								if _ash[idx] == 0:
									_ash_tiles += 1
								_ash[idx] = 225
								a_cur = 225
								_mark_chunk_dirty_local(cidx, px & 15, ly, px & 15, ly, true)
							else:
								_fire[idx] = next_f

					# 2. Thermal diffusion, lava quenching & cooling
					if b_cur == Biome.LAVA:
						var is_vent: bool = _vent_mask[idx] > 0
						if not is_vent and (
							_tiers[idx - 1] <= Tier.SHALLOW
							or _tiers[idx + 1] <= Tier.SHALLOW
							or _tiers[idx - mw] <= Tier.SHALLOW
							or _tiers[idx + mw] <= Tier.SHALLOW
						):
							_biomes[idx] = Biome.SCORCHED
							_tiers[idx] = maxi(tier_cur, Tier.SAND)
							var q_t: float = maxf(160.0, t_cur * 0.36)
							_temp[idx] = q_t
							temp_sum_delta += q_t - t_cur
							_mark_tile_dirty(px, py, true, 2)
							row_still_active = true
							if not steam_emitted_this_step and _steam_cooldown <= 0.0:
								steam_emitted_this_step = true
								_steam_cooldown = float(TUNING_KNOBS["STEAM_COOLDOWN_SEC"])
								surface_impact.emit(Vector2(float(px) + 0.5, float(py) + 0.5), 10.0, "steam")
							continue

						var nb_avg: float = (_temp[idx - 1] + _temp[idx + 1] + _temp[idx - mw] + _temp[idx + mw]) * 0.25
						var next_t: float = t_cur + (nb_avg - t_cur) * diff_k - (t_cur - amb_c) * (cool_k * 0.14)
						if is_vent:
							next_t = maxf(next_t, lava_floor)
						_temp[idx] = next_t
						temp_sum_delta += next_t - t_cur

						# Non-vent lava must keep cooling; vents sleep once thermally steady
						if not is_vent or absf(next_t - t_cur) >= steady_eps:
							row_still_active = true
							# Active hot lava can ignite directly adjacent dry lush brush
							rng_s = (rng_s * 1664525 + 1013904223) & 0x7FFFFFFF
							var ld: int = (rng_s >> 16) & 3
							var ln_idx: int = idx - 1 if ld == 0 else (idx + 1 if ld == 1 else (idx - mw if ld == 2 else idx + mw))
							if _biomes[ln_idx] == Biome.LUSH and _fire[ln_idx] <= 0.0 and _moisture[ln_idx] < 0.65:
								_ignite_tile(ln_idx, 0.78)
								var lnx: int = ln_idx % mw
								@warning_ignore("integer_division")
								var lny: int = ln_idx / mw
								_mark_tile_dirty(lnx, lny, true, 0)

						if not is_vent and next_t < lava_min:
							_biomes[idx] = Biome.SCORCHED
							_mark_tile_dirty(px, py, true, 1)
					elif t_cur > eq_max_c:
						var target_amb: float = amb_c - maxf(0.0, _height[idx] - 0.42) * 86.0
						var nb_avg_h: float = (_temp[idx - 1] + _temp[idx + 1] + _temp[idx - mw] + _temp[idx + mw]) * 0.25
						var cooled: float = t_cur + (nb_avg_h - t_cur) * diff_k - (t_cur - target_amb) * cool_k
						_temp[idx] = cooled
						temp_sum_delta += cooled - t_cur
						if absf(cooled - t_cur) >= steady_eps or (cooled > eq_max_c and nb_avg_h <= t_cur):
							row_still_active = true
						if b_cur == Biome.SCORCHED and (((px * 73856093) ^ (py * 19349663)) & 3) == 0 and ((t_cur >= 95.0 and cooled < 95.0) or (t_cur >= 185.0 and cooled < 185.0)):
							_mark_chunk_dirty_local(cidx, px & 15, ly, px & 15, ly, false)
						t_cur = cooled

					# 3. Excess radiation decay (above biome floor)
					if r_cur > r_floor:
						var next_r: float = maxf(r_floor if b_cur == Biome.CRYSTAL else 0.0, r_cur - rad_decay)
						_rad[idx] = next_r
						if next_r > r_floor:
							row_still_active = true
						r_cur = next_r

					# 4. Active fallout crystal spread (only while excess rad > crystal floor)
					if b_cur == Biome.CRYSTAL and r_cur > rad_crys_floor + 0.02 and _moisture[idx] >= 0.22 and t_cur < 55.0:
						row_still_active = true
						rng_s = (rng_s * 1664525 + 1013904223) & 0x7FFFFFFF
						if (rng_s & 0xFFFF) < crystal_prob_i:
							var c_dir: int = (rng_s >> 16) & 3
							var nidx_c: int = idx - 1 if c_dir == 0 else (idx + 1 if c_dir == 1 else (idx - mw if c_dir == 2 else idx + mw))
							if _tiers[nidx_c] >= Tier.SAND and _tiers[nidx_c] <= Tier.HILLS:
								var nb_bc: int = _biomes[nidx_c]
								if nb_bc == Biome.RUST or nb_bc == Biome.LUSH:
									_biomes[nidx_c] = Biome.CRYSTAL
									_rad[nidx_c] = maxf(_rad[nidx_c], rad_crys_floor + 0.08)
									var nx_c: int = nidx_c % mw
									@warning_ignore("integer_division")
									var ny_c: int = nidx_c / mw
									_mark_tile_dirty(nx_c, ny_c, true, 0)

					# 5. Cooled Ash -> Lush fertile regrowth (or decay if barren)
					elif a_cur > 0 and f_cur <= 0.0 and t_cur < 44.0:
						row_still_active = true
						if b_cur == Biome.SCORCHED and r_cur < 0.22:
							var m_next: float = minf(0.56, _moisture[idx] + 0.032 * eff_dt)
							_moisture[idx] = m_next
							if m_next >= 0.34 and not _has_hot_lava_within_two(px, py):
								rng_s = (rng_s * 1664525 + 1013904223) & 0x7FFFFFFF
								if (rng_s & 0xFFFF) < ash_prob_i:
									_biomes[idx] = Biome.LUSH
									_mark_chunk_dirty_local(cidx, px & 15, ly, px & 15, ly, true)
						var next_a: int = maxi(0, a_cur - ash_decay_step)
						_ash[idx] = next_a
						if next_a == 0:
							_ash_tiles = maxi(0, _ash_tiles - 1)
							_mark_chunk_dirty_local(cidx, px & 15, ly, px & 15, ly, false)

					elif b_cur == Biome.SCORCHED and t_cur < 32.0 and r_cur < 0.14 and _moisture[idx] > 0.45:
						rng_s = (rng_s * 1664525 + 1013904223) & 0x7FFFFFFF
						if (rng_s & 0xFFFF) < lush_prob_i and not _has_hot_lava_within_two(px, py):
							var l_dir: int = (rng_s >> 16) & 3
							var nidx_l: int = idx - 1 if l_dir == 0 else (idx + 1 if l_dir == 1 else (idx - mw if l_dir == 2 else idx + mw))
							if _biomes[nidx_l] == Biome.LUSH:
								_biomes[idx] = Biome.LUSH
								_mark_chunk_dirty_local(cidx, px & 15, ly, px & 15, ly, true)

					# 6. Conductive plasma / vitrified rim shimmer decay (visual-only)
					if pg_cur > 0:
						var pg_new: int = maxi(0, pg_cur - plasma_decay_step)
						_plasma_glow[idx] = pg_new
						if pg_new > 0:
							row_still_active = true
						if (pg_cur >> 5) != (pg_new >> 5) or pg_new == 0:
							_mark_chunk_dirty_local(cidx, px & 15, ly, px & 15, ly, false)

				if row_still_active:
					_chunk_row_mask[cidx] |= row_bit
					still_active = true

			if _chunk_row_mask[cidx] != 0:
				still_active = true
			if not still_active:
				_chunk_active[cidx] = 0

		_env_chunk_cursor = (start_cursor + process_n) % active_n
		_fast_rng_seed = rng_s

		# Compact any chunks that went to sleep this tick in O(process_n)
		var scan_i: int = 0
		while scan_i < _active_chunks.size():
			var chk_id: int = _active_chunks[scan_i]
			if _chunk_active[chk_id] == 0:
				_deactivate_chunk_at(scan_i)
			else:
				scan_i += 1
	else:
		_env_chunk_cursor = 0

	if temp_sum_delta != 0.0:
		_temp_total_sum += temp_sum_delta
		_avg_temp_cached = _temp_total_sum * _inv_total_tiles
	if (_env_step_count & 63) == 0 and (not _active_chunks.is_empty() or _temp_scan_row > 0):
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
	var crys_floor: float = float(TUNING_KNOBS["RAD_CRYSTAL_FLOOR"])
	_active_chunks.clear()
	_active_chunk_pos.fill(-1)
	_chunk_active.fill(0)
	_chunk_row_mask.fill(0)

	for cy in range(_chunks_h):
		var y0: int = cy << CHUNK_SHIFT
		var y1: int = mini(map_h, y0 + CHUNK_SIZE)
		for cx in range(_chunks_w):
			var x0: int = cx << CHUNK_SHIFT
			var x1: int = mini(map_w, x0 + CHUNK_SIZE)
			var rmask: int = 0
			for py in range(y0, y1):
				var row_off: int = py * map_w
				for px in range(x0, x1):
					var idx: int = row_off + px
					var b: int = _biomes[idx]
					var r_floor: float = crys_floor if b == Biome.CRYSTAL else 0.02
					if _fire[idx] > 0.0 or _ash[idx] > 0 or b == Biome.LAVA or _temp[idx] > eq_max or _rad[idx] > r_floor or _plasma_glow[idx] > 0:
						rmask |= 1 << (py & 15)
						break
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
	var mw: int = map_w
	var mh: int = map_h
	var upload_flags: int = 0
	for y in range(ry0, ry1):
		var row_off: int = y * mw
		var y_prev: int = maxi(0, y - 1)
		var y_prev2: int = maxi(0, y - 2)
		var y_next: int = mini(mh - 1, y + 1)
		var row_n: int = y_prev * mw
		var row_n2: int = y_prev2 * mw
		var row_s: int = y_next * mw
		for x in range(rx0, rx1):
			var idx: int = row_off + x
			var x_prev: int = maxi(0, x - 1)
			var x_next: int = mini(mw - 1, x + 1)
			var t: int = _tiers[idx]
			var b: int = _biomes[idx]
			var h: float = _height[idx]
			var hv: int = ((x * 73856093) ^ (y * 19349663)) & 63
			var temp_v: float = _temp[idx]
			var fire_v: float = _fire[idx]
			var ash_v: int = _ash[idx]

			var tn: int = _tiers[row_n + x]
			var ts: int = _tiers[row_s + x]
			var tw: int = _tiers[row_off + x_prev]
			var te: int = _tiers[row_off + x_next]
			var nw_lit: float = 0.0
			if (t >= Tier.HILLS and b != Biome.LAVA and b != Biome.SCORCHED) or ((t == Tier.SOIL_LOW or t == Tier.SOIL_HIGH) and b == Biome.RUST):
				var gx: float = (_height[row_off + x_next] - _height[row_off + x_prev]) * 0.5
				var gy: float = (_height[row_s + x] - _height[row_n + x]) * 0.5
				nw_lit = (gx + gy) * 0.7071

			var scorch_crack: bool = false
			if b == Biome.SCORCHED and t >= Tier.SAND and (hv & 3) == 0:
				var crack_v: float = sin(float(x) * 0.45 + float(y) * 0.35) + cos(float(x - y) * 0.52)
				scorch_crack = crack_v > 1.38

			var col: Color
			var crys_role: int = 0

			if t == Tier.DEEP_OCEAN:
				# Organic bathymetric shelf contours
				var shelf_w: float = h + sin(float(x) * 0.042 + float(y) * 0.031) * 0.009
				var depth_t: float = clampf(shelf_w / 0.21, 0.0, 1.0)
				var band: float = floorf(clampf(depth_t, 0.0, 0.999) * 4.0) / 3.0
				var blend_d: float = lerpf(depth_t, band, 0.55)
				if blend_d < 0.35:
					col = COL_DEEP_ABYSS.lerp(COL_DEEP_A, blend_d / 0.35)
				else:
					col = COL_DEEP_A.lerp(COL_DEEP_B, (blend_d - 0.35) / 0.65)
			elif t == Tier.CLOSE_OCEAN:
				var close_t: float = clampf((h - 0.21) / 0.08, 0.0, 1.0)
				var band_c: float = floorf(clampf(close_t, 0.0, 0.999) * 3.0) / 2.0
				col = COL_CLOSE_A.lerp(COL_CLOSE_B, lerpf(close_t, band_c, 0.35))
			elif t == Tier.SHALLOW:
				if _river_mask[idx] > 0:
					col = COL_RIVER_WATER
				else:
					var shal_t: float = clampf((h - 0.29) / 0.065, 0.0, 1.0)
					col = COL_SHALLOW_A.lerp(COL_SHALLOW_B, shal_t)
			elif t == Tier.SAND:
				var card_water: bool = (tw <= Tier.SHALLOW or te <= Tier.SHALLOW or tn <= Tier.SHALLOW or ts <= Tier.SHALLOW)
				if card_water:
					col = COL_SAND_WET
				else:
					var diag_water: bool = (
						_tiers[row_n + x_prev] <= Tier.SHALLOW
						or _tiers[row_n + x_next] <= Tier.SHALLOW
						or _tiers[row_s + x_prev] <= Tier.SHALLOW
						or _tiers[row_s + x_next] <= Tier.SHALLOW
					)
					if diag_water:
						col = COL_SAND_DRY.lerp(COL_SAND_WET, 0.45)
					else:
						col = COL_SAND_DRY
						if hv == 7 or hv == 43:
							col = COL_SAND_PEBBLE
						elif hv == 21:
							col = COL_SAND_SHELL
			elif t == Tier.SOIL_LOW or t == Tier.SOIL_HIGH:
				if b == Biome.LUSH:
					col = COL_LUSH_LOW if t == Tier.SOIL_LOW else COL_LUSH_HIGH
					if hv < 5:
						col = COL_LUSH_TUFT
					elif hv == 19:
						col = COL_LUSH_FLOWER_A
					elif hv == 41:
						col = COL_LUSH_FLOWER_B
				elif b == Biome.CRYSTAL:
					crys_role = _crystal_cluster_role(x, y)
					if crys_role == 3:
						col = COL_CRYS_TIP
					elif crys_role == 2:
						col = COL_CRYS_VEIN
					elif crys_role == 1:
						col = COL_CRYS_SLATE
					else:
						col = COL_CRYS_LOW if t == Tier.SOIL_LOW else COL_CRYS_HIGH
						if hv > 54:
							col = COL_CRYS_SLATE
				elif b == Biome.SCORCHED:
					col = _scorched_color_at(t, temp_v, hv, scorch_crack)
				elif b == Biome.LAVA:
					col = _lava_color_at(temp_v, hv)
				else:
					# RUST biome: smooth Martian dunes without diagonal modulo grid
					col = COL_RUST_LOW if t == Tier.SOIL_LOW else COL_RUST_HIGH
					var dune_w: float = sin(float(x) * 0.14 + float(y) * 0.22 + h * 14.0) + nw_lit * 18.0
					if dune_w > 0.68:
						col = COL_RUST_DUNE
					elif dune_w < -0.78 or hv > 58:
						col = COL_RUST_DARK
			elif t == Tier.HILLS:
				if b == Biome.LAVA:
					col = _lava_color_at(temp_v, hv)
				elif b == Biome.SCORCHED:
					col = _scorched_color_at(t, temp_v, hv, scorch_crack)
				else:
					if b == Biome.CRYSTAL:
						crys_role = _crystal_cluster_role(x, y)
					if crys_role == 3:
						col = COL_CRYS_TIP
					elif crys_role == 2:
						col = COL_CRYS_VEIN
					else:
						if nw_lit > 0.0075:
							col = COL_HILLS_SPEC
						elif nw_lit < -0.0065:
							col = COL_HILLS_CRACK
						else:
							col = COL_HILLS
						if b == Biome.LUSH:
							col = col.lerp(COL_LUSH_LOW, 0.18)
						elif b == Biome.RUST:
							col = col.lerp(COL_RUST_DARK, 0.22)
						elif b == Biome.CRYSTAL:
							col = col.lerp(COL_CRYS_SLATE, 0.35)
			elif t == Tier.MOUNTAINS:
				if b == Biome.LAVA:
					col = _lava_color_at(temp_v, hv)
				elif b == Biome.SCORCHED:
					col = _scorched_color_at(t, temp_v, hv, scorch_crack)
				else:
					# NW-SE faceted height-gradient mountain ridges (zero checkerboards)
					var strata: float = sin(h * 72.0 + float(x - y) * 0.10) * 0.0022
					var m_shade: float = nw_lit + strata
					if m_shade > 0.0085:
						col = COL_MTN_RIDGE
					elif m_shade > 0.0020:
						col = COL_MTN.lerp(COL_MTN_RIDGE, 0.48)
					elif m_shade < -0.0110:
						col = COL_MTN_DEEP
					elif m_shade < -0.0030:
						col = COL_MTN_CRAG
					else:
						col = COL_MTN
			else:
				# SUMMIT: slope + height alpine snowcap (zero static confetti)
				if b == Biome.LAVA:
					col = _lava_color_at(temp_v, hv)
				elif b == Biome.SCORCHED:
					col = _scorched_color_at(t, temp_v, hv, scorch_crack)
				elif nw_lit < -0.0125 and h < 0.830:
					col = COL_MTN_CRAG
				elif h < 0.770 and nw_lit < 0.0:
					col = COL_SNOW_EDGE
				elif nw_lit > 0.0035 or h >= 0.825:
					col = COL_SNOW
				else:
					col = COL_SNOW_SHADE

			# Charred soil transition near lava/heat & active wildfire/ash overlay
			if fire_v > 0.05 and t >= Tier.SAND and b != Biome.LAVA:
				var f_norm: float = clampf(fire_v, 0.0, 1.0)
				if f_norm > 0.65 and ((hv & 3) == 0):
					col = COL_LAVA_CORE
				elif f_norm > 0.30 and ((hv & 1) == 0):
					col = COL_LAVA_MID
				else:
					col = COL_FIRE_CHAR.lerp(COL_LAVA_CRUST, f_norm * 0.75)
			else:
				if ash_v > 0 and t >= Tier.SAND and b != Biome.LAVA:
					var ash_t: float = (float(ash_v) / 255.0) * 0.70
					col = col.lerp(COL_ASH_TINT, ash_t)
				elif (b == Biome.LUSH or b == Biome.RUST) and t >= Tier.SAND:
					if temp_v > 65.0 or _biomes[row_off + x_prev] == Biome.LAVA or _biomes[row_off + x_next] == Biome.LAVA or _biomes[row_n + x] == Biome.LAVA or _biomes[row_s + x] == Biome.LAVA:
						col = col.lerp(COL_SCORCH_HIGH, 0.62)

			# 2.5D WorldLayerEdges bevels + NW-SE cliff drop-shadows (zero checkerboards)
			var shore_bevel_n: bool = false
			if t <= Tier.SHALLOW:
				if y > 0 and tn >= Tier.SAND:
					shore_bevel_n = true
					if t == Tier.SHALLOW:
						col = col.lerp(COL_EDGE_OCEAN, 0.78) if _river_mask[idx] > 0 else COL_EDGE_OCEAN
					else:
						col = col.lerp(COL_EDGE_OCEAN_DEEP, 0.85)
				elif x > 0 and tw >= Tier.SAND and t == Tier.SHALLOW:
					col = col.lerp(COL_EDGE_OCEAN, 0.42)
			elif b != Biome.LAVA and fire_v <= 0.05:
				var shadow_n: bool = (y > 0 and tn > t)
				var shadow_w: bool = (x > 0 and tw > t)
				if shadow_n:
					if tn >= Tier.MOUNTAINS:
						var mtn_t: float = 0.76 if (shadow_w and tw >= Tier.MOUNTAINS) else 0.66
						col = col.lerp(COL_EDGE_MTN, mtn_t)
					elif tn == Tier.HILLS:
						var hill_t: float = 0.66 if shadow_w else 0.58
						col = col.lerp(COL_EDGE_HILLS, hill_t)
					else:
						var dm_n: float = 0.72 if shadow_w else 0.78
						col.r *= dm_n
						col.g *= dm_n
						col.b *= dm_n
				elif shadow_w:
					var dm_w: float = 0.76 if tw >= Tier.HILLS else 0.82
					col.r *= dm_w
					col.g *= dm_w
					col.b *= dm_w
				else:
					var drop2_n: bool = (y > 1 and _tiers[row_n2 + x] >= t + 2)
					var drop2_w: bool = (x > 1 and _tiers[row_off + (x - 2)] >= t + 2)
					if drop2_n or drop2_w:
						col.r *= 0.88
						col.g *= 0.88
						col.b *= 0.88
					else:
						var rim_n: bool = (y > 0 and t > tn)
						var rim_w: bool = (x > 0 and t > tw)
						if rim_n or rim_w:
							var light_amt: float = 0.06 if t == Tier.SUMMIT else (0.14 if (rim_n and rim_w) else 0.11)
							col.r = minf(0.95, col.r + (1.0 - col.r) * light_amt)
							col.g = minf(0.95, col.g + (1.0 - col.g) * light_amt)
							col.b = minf(0.95, col.b + (1.0 - col.b) * light_amt)
				if not shadow_n and t >= Tier.HILLS and y + 1 < mh and t > ts:
					var ridge_lit: float = 0.08 if t == Tier.SUMMIT else (0.22 if t == Tier.MOUNTAINS else 0.17)
					col.r = minf(0.95, col.r + (1.0 - col.r) * ridge_lit)
					col.g = minf(0.95, col.g + (1.0 - col.g) * ridge_lit)
					col.b = minf(0.95, col.b + (1.0 - col.b) * ridge_lit)

			var pg: int = _plasma_glow[idx]
			if pg > 0:
				var pg_t: float = (float(pg) / 255.0) * 0.42
				col = col.lerp(COL_CRYS_TIP, pg_t)
				col.r = minf(0.95, col.r)
				col.g = minf(0.95, col.g)
				col.b = minf(0.95, col.b)

			var p: int = idx * 4
			var r_b: int = col.r8
			var g_b: int = col.g8
			var b_b: int = col.b8
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
				if tw >= Tier.SAND or te >= Tier.SAND or tn >= Tier.SAND or ts >= Tier.SAND:
					m_foam = 115
			elif t == Tier.SHALLOW:
				m_water = 255
				if _river_mask[idx] > 0:
					m_foam = 86
				elif shore_bevel_n:
					m_foam = 152
				elif tw >= Tier.SAND or te >= Tier.SAND or tn >= Tier.SAND or ts >= Tier.SAND:
					m_foam = 242
				elif (
					_tiers[row_n + x_prev] >= Tier.SAND
					or _tiers[row_n + x_next] >= Tier.SAND
					or _tiers[row_s + x_prev] >= Tier.SAND
					or _tiers[row_s + x_next] >= Tier.SAND
				):
					m_foam = 188
				elif _has_land_within_two(x, y):
					m_foam = 128

			var m_lava: int = 0
			var m_cryst: int = 0
			if b == Biome.LAVA and t >= Tier.SAND:
				m_lava = clampi(int(clampf((temp_v - 340.0) / 560.0, 0.35, 1.0) * 255.0), 0, 255)
			else:
				if fire_v > 0.05 and t >= Tier.SAND:
					# Land wildfire channel (mask.r <= 0.10 && mask.g > 0.04 triggers 15Hz flame flicker in shader)
					m_foam = clampi(int(clampf(fire_v, 0.15, 1.0) * 245.0), 40, 250)
				if scorch_crack and temp_v > 185.0:
					m_lava = clampi(int(clampf((temp_v - 185.0) / 360.0, 0.14, 0.58) * 255.0), 0, 255)
				elif b == Biome.CRYSTAL and t >= Tier.SAND and t <= Tier.HILLS:
					if crys_role == 3:
						m_cryst = 235
					elif crys_role == 2:
						m_cryst = 82
			m_cryst = maxi(m_cryst, pg)

			if _mask_buf[p] != m_water or _mask_buf[p + 1] != m_foam or _mask_buf[p + 2] != m_lava or _mask_buf[p + 3] != m_cryst:
				_mask_buf[p] = m_water
				_mask_buf[p + 1] = m_foam
				_mask_buf[p + 2] = m_lava
				_mask_buf[p + 3] = m_cryst
				upload_flags |= 2

	return upload_flags


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
	var i_start: int = _temp_scan_row * map_w
	var i_end: int = end_row * map_w
	var acc: float = _temp_scan_accum
	for i in range(i_start, i_end):
		acc += _temp[i]
	_temp_scan_accum = acc
	_temp_scan_row = end_row
	if _temp_scan_row >= map_h:
		_temp_total_sum = acc
		_avg_temp_cached = acc * _inv_total_tiles
		_temp_scan_row = 0
		_temp_scan_accum = 0.0


func is_walkable(px: int, py: int) -> bool:
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return false
	var t: int = _tiers[py * map_w + px]
	return t >= Tier.SAND and t <= Tier.MOUNTAINS


func is_water(px: int, py: int) -> bool:
	if px < 0 or px >= map_w or py < 0 or py >= map_h:
		return false
	return _tiers[py * map_w + px] <= Tier.SHALLOW


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
	return flags


func get_fire_stats() -> Dictionary:
	return {
		"fire_events": _fire_events_total,
		"active_fire_tiles": _active_fire_tiles,
		"ash_tiles": _ash_tiles,
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
		}
	var idx: int = py * map_w + px
	var t: int = _tiers[idx]
	var b: int = _biomes[idx]
	var b_name: String = BIOME_NAMES[b]
	if t <= Tier.SHALLOW:
		b_name = "Река" if _river_mask[idx] > 0 else "Океан"
	elif _fire[idx] > 0.05:
		b_name = "Пожар"
	elif _ash[idx] > 40 and b == Biome.SCORCHED:
		b_name = "Пепел"
	return {
		"in_bounds": true,
		"tier": t,
		"biome": b,
		"tier_name": TIER_NAMES[t],
		"biome_name": b_name,
		"temp": _temp[idx] + _cosmic_temp_offset,
		"rad": _rad[idx],
		"fire": _fire[idx],
		"ash": float(_ash[idx]) / 255.0,
		"moisture": _moisture[idx],
	}
