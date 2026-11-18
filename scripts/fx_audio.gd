extends Node2D
class_name FxAudio

const UNIT_SPRITE_SHADER := preload("res://shaders/unit_sprite.gdshader")
const FX_STRIPS_ATLAS_PATH := "res://assets/atlases/fx_strips_atlas.png"
const FX_STRIPS_MASK_PATH := "res://assets/atlases/fx_strips_atlas_mask.png"

const TUNING_KNOBS := {
	"MAX_PARTICLES": 1600,
	"PARTICLE_QUAD_PX": 4.0,
	"MAX_STRIPS": 256,
	"STRIP_CELL_PX": 8.0,
	"STRIP_LIFETIME_SEC": 0.85,
	"STRIP_FLOAT_SPEED": 12.0,
	"LIGHTMAP_WIDTH": 214,
	"LIGHTMAP_HEIGHT": 120,
	"LIGHTMAP_SCALE": 3.0,
	"MAX_LIGHTS": 256,
	"MAX_TRANSIENT_LIGHTS": 32,
	"SHOCKWAVE_RING_COUNT": 16,
	"SHOCKWAVE_SPARK_COUNT": 16,
	"SHOCKWAVE_LIFETIME": 0.36,
	"AUDIO_MIX_RATE": 22050.0,
	"AUDIO_BUFFER_SEC": 0.14,
	"AUDIO_CHUNK_SIZE": 256,
	"AUDIO_VOLUME_DB": -4.0,
	"PITCH_JITTER_MIN": 0.90,
	"PITCH_JITTER_MAX": 1.10,
	"BUILD_POP_TRAUMA": 0.04,
	"BUILD_POP_DUST_COUNT": 3,
	"BUILD_POP_COOLDOWN_SEC": 0.04,
	"BUILD_POP_DURATION_SEC": 0.08,
	"STEREO_PAN_HALF_WIDTH_PX": 280.0,
	"SHIELD_DEFLECT_LIGHT_MAX_RADIUS": 44.0,
	"SHIELD_DEFLECT_LIGHT_MAX_INTENSITY": 1.15,
}

const MAX_PARTICLES: int = 1600
const PARTICLE_QUAD_PX: float = 4.0
const MAX_STRIPS: int = 256
const DEFAULT_STRIP_ATLAS_COLS: int = 18
const STRIP_CELL_PX: float = 8.0
const LIGHTMAP_W: int = 214
const LIGHTMAP_H: int = 120
const LIGHTMAP_SCALE: float = 3.0
const INV_LIGHTMAP_SCALE: float = 1.0 / 3.0
const MAX_LIGHTS: int = 256
const MAX_TRANSIENT_LIGHTS: int = 32
const AUDIO_CHUNK_SIZE: int = 256
const VOICE_COUNT: int = 16
const SFX_KIND_COUNT: int = 29
const MAX_SYNTH_FREQ_HZ: float = 8500.0
const MAX_DROPS: int = 512
const DROP_QUAD_PX: float = 4.0
const DROP_ATLAS_COLS: int = 4

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
const STRIP_PLOT_WAR: int = 12
const STRIP_PLOT_PACT: int = 13
const STRIP_PLOT_REBEL: int = 14
const STRIP_CROWN_BANNER: int = 15
const STRIP_RELIC_DIAMOND: int = 16
const STRIP_FEUD_SWORDS: int = 17

const P_COL_EMBER: int = 0
const P_COL_PUFF: int = 1
const P_COL_SPARKLE: int = 2
const P_COL_RING: int = 3
const P_COL_FLASH: int = 4
const P_COL_BOLT: int = 5
const PARTICLE_ATLAS_COLS: int = 6

const MODE_BALLISTIC: int = 0
const MODE_SHOCKWAVE: int = 1
const MODE_TRACER: int = 2

enum SfxKind {
	METEOR = 0,
	TERRAFORM = 1,
	CRYSTAL = 2,
	LAVA = 3,
	VORTEX = 4,
	UI = 5,
	BUILD_POP = 6,
	SKIRMISH = 7,
	MELTDOWN = 8,
	STORM = 9,
	SHUTTLE = 10,
	MUTATE = 11,
	ORBITAL_BEAM = 12,
	SHIELD_DEFLECT = 13,
	LASER_LIGHT = 14,
	LASER_HEAVY = 15,
	TELEPORT_HUM = 16,
	EMP_GLITCH = 17,
	UI_TAB = 18,
	UI_PIN = 19,
	UI_DENIED = 20,
	DROP_RAIN = 21,
	DROP_IMPACT = 22,
	EARTHQUAKE = 23,
	VOLCANO_TORNADO = 24,
	FOOTSTEP_WORK = 25,
	UI_HOVER = 26,
	WINDOW_WHOOSH = 27,
	BIT_SCALE_WHOOSH = 28,
}

signal impact_trauma(trauma: float, hit_stop_sec: float)

var _mm_particles: MultiMeshInstance2D
var _mm_strips: MultiMeshInstance2D
var _mm_drops: MultiMeshInstance2D
var _strips_mat: ShaderMaterial
var _strip_atlas_cols: int = DEFAULT_STRIP_ATLAS_COLS
var _initialized: bool = false
var _drop_flash_budget: int = 24

# Flat SoA particle buffers (zero GC)
var _p_pos: PackedVector2Array
var _p_vel: PackedVector2Array
var _p_age: PackedFloat32Array
var _p_life: PackedFloat32Array
var _p_gravity: PackedFloat32Array
var _p_size: PackedFloat32Array
var _p_aspect: PackedFloat32Array
var _p_rot: PackedFloat32Array
var _p_hdr: PackedFloat32Array
var _p_color: PackedColorArray
var _p_col_idx: PackedByteArray
var _p_mode: PackedByteArray
var _p_origin: PackedVector2Array
var _p_dir: PackedVector2Array
var _p_max_r: PackedFloat32Array
var _active_count: int = 0
var _evict_cursor: int = 0

# Flat SoA reaction strip buffers (zero GC)
var _s_pos: PackedVector2Array
var _s_vel: PackedVector2Array
var _s_age: PackedFloat32Array
var _s_life: PackedFloat32Array
var _s_hdr: PackedFloat32Array
var _s_col_idx: PackedByteArray
var _s_active_count: int = 0
var _s_evict_cursor: int = 0

# 1/3-Resolution World-Locked Lightmap Pass
var _light_viewport: SubViewport
var _light_mm: MultiMeshInstance2D
var _light_sprite: Sprite2D
var _light_shader: Shader
var _light_mat: ShaderMaterial
var _light_night_mix: float = 0.0
var _light_age_tint: Color = Color.WHITE
var _light_count: int = 0

# Preallocated transient impact lights (zero GC)
var _tl_pos: PackedVector2Array
var _tl_rad: PackedFloat32Array
var _tl_col: PackedColorArray
var _tl_intensity: PackedFloat32Array
var _tl_age: PackedFloat32Array
var _tl_life: PackedFloat32Array
var _tl_count: int = 0
var _tl_evict_cursor: int = 0

# Procedural audio synth state (zero GC)
var _audio_player: AudioStreamPlayer
var _audio_supported: bool = false
var _audio_unlocked: bool = false
var _mix_chunk: PackedVector2Array
var _was_silent: bool = true
var _rng := RandomNumberGenerator.new()
var _cam_zoom: float = 2.0
var _cam_center_x: float = 320.0
var _cam_rect: Rect2 = Rect2(0.0, 0.0, 320.0, 180.0)
var _sim_speed: float = 1.0
var _cursor_speed_norm: float = 0.0
var _ambient_age_id: int = 0
var _ambient_biome_id: int = 1
var _biome_scan_timer: float = 0.0
var _amb_pause_gain: float = 1.0
var _amb_pause_target: float = 1.0
var _amb_biome_f_mul: float = 1.0
var _amb_biome_wind_mul: float = 1.0
var _world_ref: Node2D = null
var _amb_noise_state: int = 0x51A7F00D
var _amb_wind_prev: float = 0.0
var _amb_wind_curr: float = 0.0
var _amb_wind_lpf: float = 0.0
var _amb_drone_ph1: float = 0.0
var _amb_drone_ph2: float = 0.0
var _amb_lfo_ph: float = 0.0
var _amb_freq1: float = 110.0
var _amb_freq2: float = 165.0
var _amb_target_f1: float = 110.0
var _amb_target_f2: float = 165.0

var _v_active: PackedByteArray
var _v_kind: PackedByteArray
var _v_t: PackedFloat32Array
var _v_dur: PackedFloat32Array
var _v_phase: PackedFloat32Array
var _v_phase2: PackedFloat32Array
var _v_pitch: PackedFloat32Array
var _v_gain: PackedFloat32Array
var _v_pan: PackedFloat32Array
var _v_lpf: PackedFloat32Array
var _v_bp: PackedFloat32Array
var _v_noise_state: PackedInt32Array
var _sfx_cooldown: PackedFloat32Array


func _ready() -> void:
	_ensure_initialized()


func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_rng.seed = 90125
	_init_particle_buffers()
	_init_particle_multimesh()
	_init_drops_multimesh()
	_init_strip_buffers()
	_init_strips_multimesh()
	_init_lightmap_pass()
	_init_audio_synth()


func _exit_tree() -> void:
	if _audio_player != null:
		if _audio_player.playing:
			_audio_player.stop()
		_audio_player.stream = null
		if _audio_player.get_parent() == self:
			remove_child(_audio_player)
		_audio_player.free()
		_audio_player = null
	if _mm_particles != null:
		_mm_particles.multimesh = null
		_mm_particles.material = null
		_mm_particles.texture = null
		_mm_particles = null
	if _mm_drops != null:
		_mm_drops.multimesh = null
		_mm_drops.material = null
		_mm_drops.texture = null
		_mm_drops = null
	if _mm_strips != null:
		_mm_strips.multimesh = null
		_mm_strips.material = null
		_mm_strips.texture = null
		_mm_strips = null
	_world_ref = null
	_strips_mat = null
	if _light_sprite != null:
		_light_sprite.texture = null
		_light_sprite.material = null
		_light_sprite = null
	if _light_mm != null:
		_light_mm.multimesh = null
		_light_mm.material = null
		_light_mm.texture = null
		_light_mm = null
	_light_viewport = null
	_light_mat = null
	_light_shader = null


func _init_particle_buffers() -> void:
	_p_pos.resize(MAX_PARTICLES)
	_p_vel.resize(MAX_PARTICLES)
	_p_age.resize(MAX_PARTICLES)
	_p_life.resize(MAX_PARTICLES)
	_p_gravity.resize(MAX_PARTICLES)
	_p_size.resize(MAX_PARTICLES)
	_p_aspect.resize(MAX_PARTICLES)
	_p_rot.resize(MAX_PARTICLES)
	_p_hdr.resize(MAX_PARTICLES)
	_p_color.resize(MAX_PARTICLES)
	_p_col_idx.resize(MAX_PARTICLES)
	_p_mode.resize(MAX_PARTICLES)
	_p_origin.resize(MAX_PARTICLES)
	_p_dir.resize(MAX_PARTICLES)
	_p_max_r.resize(MAX_PARTICLES)
	_p_aspect.fill(1.0)
	_p_rot.fill(0.0)
	_active_count = 0
	_evict_cursor = 0


func _init_particle_multimesh() -> void:
	_mm_particles = MultiMeshInstance2D.new()
	_mm_particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mm_particles.texture = _make_particle_atlas()

	var mat := ShaderMaterial.new()
	mat.shader = UNIT_SPRITE_SHADER
	mat.set_shader_parameter("sprite_mode", 2)
	mat.set_shader_parameter("atlas_cols", PARTICLE_ATLAS_COLS)
	mat.set_shader_parameter("sprite_size", Vector2(PARTICLE_QUAD_PX, PARTICLE_QUAD_PX))
	_mm_particles.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2(PARTICLE_QUAD_PX, PARTICLE_QUAD_PX)
	mm.mesh = q
	mm.instance_count = MAX_PARTICLES
	mm.visible_instance_count = 0
	_mm_particles.multimesh = mm
	add_child(_mm_particles)


func _make_particle_atlas() -> ImageTexture:
	# 24x4 atlas: 6 columns of 4x4 pixel-art FX primitives
	var img := Image.create(PARTICLE_ATLAS_COLS * 4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Col 0: Crisp ember / debris pixel (tight 2x2 core + subtle cardinal glint)
	for y in range(1, 3):
		for x in range(1, 3):
			img.set_pixel(x, y, Color(1, 1, 1, 1))
	img.set_pixel(1, 0, Color(1, 1, 1, 0.42))
	img.set_pixel(0, 1, Color(1, 1, 1, 0.42))
	img.set_pixel(3, 2, Color(1, 1, 1, 0.42))
	img.set_pixel(2, 3, Color(1, 1, 1, 0.42))

	# Col 1: Compact pixel puff (smoke / dust / ash)
	for y in range(4):
		for x in range(4):
			var dx := float(x) - 1.5
			var dy := float(y) - 1.5
			var dist := sqrt(dx * dx + dy * dy)
			if dist < 0.85:
				img.set_pixel(4 + x, y, Color(1, 1, 1, 0.88))
			elif dist < 1.55:
				img.set_pixel(4 + x, y, Color(1, 1, 1, 0.40))

	# Col 2: Diamond crystal / ion sparkle
	img.set_pixel(8 + 1, 1, Color(1, 1, 1, 1))
	img.set_pixel(8 + 2, 1, Color(1, 1, 1, 0.88))
	img.set_pixel(8 + 1, 2, Color(1, 1, 1, 0.88))
	img.set_pixel(8 + 2, 2, Color(1, 1, 1, 1))
	img.set_pixel(8 + 1, 0, Color(1, 1, 1, 0.72))
	img.set_pixel(8 + 2, 3, Color(1, 1, 1, 0.72))
	img.set_pixel(8 + 0, 2, Color(1, 1, 1, 0.72))
	img.set_pixel(8 + 3, 1, Color(1, 1, 1, 0.72))

	# Col 3: Thin horizontal shockwave arc dash (tiled tangentially -> crisp unbroken wave)
	for x in range(4):
		img.set_pixel(12 + x, 1, Color(1, 1, 1, 1.0))
		img.set_pixel(12 + x, 2, Color(1, 1, 1, 0.50))

	# Col 4: Starburst impact flash
	for y in range(1, 3):
		for x in range(1, 3):
			img.set_pixel(16 + x, y, Color(1, 1, 1, 1.0))
	img.set_pixel(16 + 1, 0, Color(1, 1, 1, 0.85))
	img.set_pixel(16 + 2, 0, Color(1, 1, 1, 0.85))
	img.set_pixel(16 + 1, 3, Color(1, 1, 1, 0.85))
	img.set_pixel(16 + 2, 3, Color(1, 1, 1, 0.85))
	img.set_pixel(16 + 0, 1, Color(1, 1, 1, 0.85))
	img.set_pixel(16 + 0, 2, Color(1, 1, 1, 0.85))
	img.set_pixel(16 + 3, 1, Color(1, 1, 1, 0.85))
	img.set_pixel(16 + 3, 2, Color(1, 1, 1, 0.85))

	# Col 5: Directional laser / spark bolt streak
	for x in range(4):
		var edge := 0.72 if (x == 0 or x == 3) else 1.0
		img.set_pixel(20 + x, 1, Color(1, 1, 1, edge))
		img.set_pixel(20 + x, 2, Color(1, 1, 1, edge * 0.88))

	return ImageTexture.create_from_image(img)


func _make_drops_atlas() -> ImageTexture:
	# 16x4 atlas: 4 columns of 4x4 sky-drop silhouettes (streak, orb, capsule, crystal/snow)
	var img := Image.create(DROP_ATLAS_COLS * 4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Col 0: vertical droplet streak
	for y in range(4):
		img.set_pixel(1, y, Color(1.0, 1.0, 1.0, 0.72 if y == 0 else 1.0))
		img.set_pixel(2, y, Color(1.0, 1.0, 1.0, 0.45 if y == 3 else 0.90))
	# Col 1: glowing orb / seed
	for y in range(1, 3):
		for x in range(1, 3):
			img.set_pixel(4 + x, y, Color(1.0, 1.0, 1.0, 1.0))
	img.set_pixel(5, 0, Color(1.0, 1.0, 1.0, 0.60))
	img.set_pixel(4, 1, Color(1.0, 1.0, 1.0, 0.60))
	img.set_pixel(7, 2, Color(1.0, 1.0, 1.0, 0.60))
	img.set_pixel(6, 3, Color(1.0, 1.0, 1.0, 0.60))
	# Col 2: meteor / plasma bomb capsule
	for y in range(4):
		for x in range(4):
			var d := absf(float(x) - 1.5) + absf(float(y) - 1.5)
			if d <= 1.2:
				img.set_pixel(8 + x, y, Color(1.0, 1.0, 1.0, 1.0))
			elif d <= 2.1:
				img.set_pixel(8 + x, y, Color(1.0, 1.0, 1.0, 0.65))
	# Col 3: diamond snow / crystal flake
	img.set_pixel(13, 1, Color(1.0, 1.0, 1.0, 1.0))
	img.set_pixel(14, 2, Color(1.0, 1.0, 1.0, 1.0))
	img.set_pixel(13, 0, Color(1.0, 1.0, 1.0, 0.80))
	img.set_pixel(12, 1, Color(1.0, 1.0, 1.0, 0.80))
	img.set_pixel(14, 1, Color(1.0, 1.0, 1.0, 0.80))
	img.set_pixel(13, 2, Color(1.0, 1.0, 1.0, 0.80))
	return ImageTexture.create_from_image(img)


func _init_drops_multimesh() -> void:
	_mm_drops = MultiMeshInstance2D.new()
	_mm_drops.z_as_relative = false
	_mm_drops.z_index = 4
	_mm_drops.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mm_drops.texture = _make_drops_atlas()

	var mat := ShaderMaterial.new()
	mat.shader = UNIT_SPRITE_SHADER
	mat.set_shader_parameter("sprite_mode", 2)
	mat.set_shader_parameter("atlas_cols", DROP_ATLAS_COLS)
	mat.set_shader_parameter("sprite_size", Vector2(DROP_QUAD_PX, DROP_QUAD_PX))
	_mm_drops.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2(DROP_QUAD_PX, DROP_QUAD_PX)
	mm.mesh = q
	mm.instance_count = MAX_DROPS
	mm.visible_instance_count = 0
	_mm_drops.multimesh = mm
	_mm_drops.visible = false
	add_child(_mm_drops)


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


func _stamp_pattern(img: Image, col_idx: int, rows: PackedStringArray, palette: Dictionary) -> void:
	var ox := col_idx * 8
	for y in range(mini(8, rows.size())):
		var row_str: String = rows[y]
		for x in range(mini(8, row_str.length())):
			var ch := row_str.substr(x, 1)
			if palette.has(ch):
				img.set_pixel(ox + x, y, palette[ch])


func _make_fallback_strips_atlas() -> ImageTexture:
	var img := Image.create(DEFAULT_STRIP_ATLAS_COLS * 8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var pal := {
		"K": Color("#1C2738"),
		"W": Color("#F2FAFF"),
		"C": Color("#45E9FF"),
		"D": Color("#1E88B8"),
		"G": Color("#5EE66D"),
		"E": Color("#5FE848"),
		"Y": Color("#FFD94D"),
		"A": Color("#F0B121"),
		"O": Color("#F58B28"),
		"R": Color("#FF4A4A"),
		"P": Color("#C75CFF"),
		"M": Color("#8D35BD"),
	}
	_stamp_fallback_strips_primary(img, pal)
	_stamp_fallback_strips_diplo(img, pal)
	return ImageTexture.create_from_image(img)


func _stamp_fallback_strips_primary(img: Image, pal: Dictionary) -> void:
	# 0: DODGE wind chevron
	_stamp_pattern(img, STRIP_DODGE, [
		"........", "..KK....", ".KWWK...", "KKWWKK..",
		".KCCWWK.", "..KCCK..", "...KK...", "........",
	], pal)
	# 1: BLOCK shield spark
	_stamp_pattern(img, STRIP_BLOCK, [
		"..KKKK..", ".KCCCCK.", "KCCWWCCK", "KCWWWWCK",
		".KCWWCK.", "..KCCK..", "...KK...", "........",
	], pal)
	# 2: HAPPY green-gold heart/sun
	_stamp_pattern(img, STRIP_HAPPY, [
		".KK..KK.", "KGGKKGGK", "KGYGGYGK", "KGGGGGGK",
		".KGGGGK.", "..KGGK..", "...KK...", "........",
	], pal)
	# 3: ANGRY red exclamation
	_stamp_pattern(img, STRIP_ANGRY, [
		"...KK...", "..KRRK..", "..KRRK..", "..KRRK..",
		"...KK...", "..KWWK..", "...KK...", "........",
	], pal)
	# 4: FOOD golden ration/berry
	_stamp_pattern(img, STRIP_FOOD, [
		"...KK...", "..KGGK..", ".KYYYYK.", "KYYOOYYK",
		"KOOOOOOK", ".KOOOOK.", "..KKKK..", "........",
	], pal)
	# 5: SHIELD cyan dome deflect
	_stamp_pattern(img, STRIP_SHIELD, [
		"..KKKK..", ".KCCCCK.", "KCWWWWCK", "KCDDDDCK",
		"KCCCCCCK", ".KKKKKK.", "........", "........",
	], pal)
	# 6: LVLUP bright star
	_stamp_pattern(img, STRIP_LVLUP, [
		"...KK...", "..KYYK..", "KKYWWYKK", "KYYWWYYK",
		".KYYYYK.", "KYK..KYK", "KK....KK", "........",
	], pal)
	# 7: MUTATE violet helix
	_stamp_pattern(img, STRIP_MUTATE, [
		".KK..KK.", "KPPKKPPK", ".KCMMCK.", "..KPPK..",
		".KCMMCK.", "KPPKKPPK", ".KK..KK.", "........",
	], pal)


func _stamp_fallback_strips_diplo(img: Image, pal: Dictionary) -> void:
	# 8: PACT glowing cyan-gold link emblem
	_stamp_pattern(img, STRIP_PACT, [
		"..KK.KK.", ".KCCKYYK", "KCWWKWYK", "KCYWKCCK",
		".KYYKCCK", "..KK.KK.", "........", "........",
	], pal)
	# 9: WAR crimson-orange crossed spark emblem
	_stamp_pattern(img, STRIP_WAR, [
		"KK....KK", "KRK..KRO", ".KRKKOK.", "..KWWK..",
		".KOKKRK.", "OKK..KRK", "KK....KK", "........",
	], pal)
	# 10: REBEL emerald-acid & gold rebellion emblem
	_stamp_pattern(img, STRIP_REBEL, [
		"...KK...", "..KEEK..", ".KEAAEK.", "KEAWAEEK",
		"KEEEEEAK", ".KEAAEK.", "..KKKK..", "........",
	], pal)
	# 11: PORTAL cyan-violet warp vortex emblem
	_stamp_pattern(img, STRIP_PORTAL, [
		"..KKKK..", ".KPPPPK.", "KPMCCMPK", "KMCWWCMK",
		"KPMCCMPK", ".KPPPPK.", "..KKKK..", "........",
	], pal)
	# 12..15: Fallback plot & crown banner strips
	_stamp_pattern(img, STRIP_PLOT_WAR, [
		"KK....KK", "KRK..KRK", ".KRKKRK.", "..KWWK..",
		".KRKKRK.", "KRK..KRK", "KK....KK", "........",
	], pal)
	_stamp_pattern(img, STRIP_PLOT_PACT, [
		"..KKKK..", ".KCCCCK.", "KCWKKWCK", "KCKYYKCK",
		"KCCYYCCK", ".KCCCCK.", "..KKKK..", "........",
	], pal)
	_stamp_pattern(img, STRIP_PLOT_REBEL, [
		"..KKKK..", ".KOOYYK.", "KOYWWYOK", "KOOOOOOK",
		".KOOOOOK", "..KKKK..", "........", "........",
	], pal)
	_stamp_pattern(img, STRIP_CROWN_BANNER, [
		"........", "KY.YY.YK", "KYYYYYYK", "KYYAAYYK",
		"KYYYYYYK", ".KKKKKK.", "........", "........",
	], pal)
	_stamp_pattern(img, STRIP_RELIC_DIAMOND, [
		"...KK...", "..KYYK..", ".KYWWYK.", "KYWWWWYK",
		".KYAAYK.", "..KAAK..", "...KK...", "........",
	], pal)
	_stamp_pattern(img, STRIP_FEUD_SWORDS, [
		"KK....KK", "KWK..KWK", ".KRKKRK.", "..KRRK..",
		".KRKKRK.", "KYK..KYK", "KK....KK", "........",
	], pal)


func _init_strip_buffers() -> void:
	_s_pos.resize(MAX_STRIPS)
	_s_vel.resize(MAX_STRIPS)
	_s_age.resize(MAX_STRIPS)
	_s_life.resize(MAX_STRIPS)
	_s_hdr.resize(MAX_STRIPS)
	_s_col_idx.resize(MAX_STRIPS)
	_s_active_count = 0
	_s_evict_cursor = 0

	_tl_pos.resize(MAX_TRANSIENT_LIGHTS)
	_tl_rad.resize(MAX_TRANSIENT_LIGHTS)
	_tl_col.resize(MAX_TRANSIENT_LIGHTS)
	_tl_intensity.resize(MAX_TRANSIENT_LIGHTS)
	_tl_age.resize(MAX_TRANSIENT_LIGHTS)
	_tl_life.resize(MAX_TRANSIENT_LIGHTS)
	_tl_count = 0
	_tl_evict_cursor = 0


func _init_strips_multimesh() -> void:
	var strip_tex := _load_png_texture(FX_STRIPS_ATLAS_PATH)
	var mask_tex: Texture2D = null
	if strip_tex != null:
		mask_tex = _load_png_texture(FX_STRIPS_MASK_PATH)
	if strip_tex == null:
		strip_tex = _make_fallback_strips_atlas()

	_mm_strips = MultiMeshInstance2D.new()
	_mm_strips.z_as_relative = false
	_mm_strips.z_index = 5
	_mm_strips.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_mm_strips.texture = strip_tex

	var tex_w: int = strip_tex.get_width() if strip_tex != null else (DEFAULT_STRIP_ATLAS_COLS * int(STRIP_CELL_PX))
	_strip_atlas_cols = maxi(1, int(tex_w / int(STRIP_CELL_PX)))

	_strips_mat = ShaderMaterial.new()
	_strips_mat.shader = UNIT_SPRITE_SHADER
	_strips_mat.set_shader_parameter("atlas_cols", _strip_atlas_cols)
	_strips_mat.set_shader_parameter("sprite_size", Vector2(STRIP_CELL_PX, STRIP_CELL_PX))
	_strips_mat.set_shader_parameter("motion_mode", 0)
	if mask_tex != null:
		_strips_mat.set_shader_parameter("sprite_mode", 3)
		_strips_mat.set_shader_parameter("mask_tex", mask_tex)
		_strips_mat.set_shader_parameter("hdr_emissive", 2.6)
	else:
		_strips_mat.set_shader_parameter("sprite_mode", 2)
	_mm_strips.material = _strips_mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.use_custom_data = true
	var q := QuadMesh.new()
	q.size = Vector2(STRIP_CELL_PX, STRIP_CELL_PX)
	mm.mesh = q
	mm.instance_count = MAX_STRIPS
	mm.visible_instance_count = 0
	_mm_strips.multimesh = mm
	add_child(_mm_strips)


func _make_radial_light_disc() -> ImageTexture:
	var sz := 64
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var half := float(sz) * 0.5
	for y in range(sz):
		var dy := (float(y) + 0.5 - half) / half
		for x in range(sz):
			var dx := (float(x) + 0.5 - half) / half
			var d := sqrt(dx * dx + dy * dy)
			var f := clampf(1.0 - d, 0.0, 1.0)
			var glow := f * f * (0.45 + 0.55 * f)
			img.set_pixel(x, y, Color(glow, glow, glow, glow))
	return ImageTexture.create_from_image(img)


func _init_lightmap_pass() -> void:
	_light_viewport = SubViewport.new()
	_light_viewport.name = "LightViewport"
	_light_viewport.size = Vector2i(LIGHTMAP_W, LIGHTMAP_H)
	_light_viewport.transparent_bg = true
	_light_viewport.disable_3d = true
	_light_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_light_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_light_viewport)

	_light_mm = MultiMeshInstance2D.new()
	_light_mm.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_light_mm.texture = _make_radial_light_disc()
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_light_mm.material = add_mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.use_custom_data = false
	var q := QuadMesh.new()
	q.size = Vector2(2.0, 2.0)
	mm.mesh = q
	mm.instance_count = MAX_LIGHTS
	mm.visible_instance_count = 0
	_light_mm.multimesh = mm
	_light_viewport.add_child(_light_mm)

	_light_shader = Shader.new()
	_light_shader.code = """shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float night_mix : hint_range(0.0, 1.0) = 0.0;
uniform vec3 age_tint = vec3(1.0, 1.0, 1.0);

float bayer4(vec2 p) {
	int x = int(mod(floor(p.x), 4.0));
	int y = int(mod(floor(p.y), 4.0));
	int x0 = x & 1;
	int y0 = y & 1;
	int x1 = (x >> 1) & 1;
	int y1 = (y >> 1) & 1;
	int m = (((x0 ^ y0) << 3) | (y0 << 2) | ((x1 ^ y1) << 1) | y1);
	return (float(m) + 0.5) / 16.0;
}

void fragment() {
	vec4 lt = texture(TEXTURE, UV);
	float gain = mix(0.46, 0.86, clamp(night_mix, 0.0, 1.0));
	float luma = max(lt.r, max(lt.g, lt.b));
	float dither = bayer4(floor(UV * vec2(214.0, 120.0)));
	float stepped = floor(clamp(luma, 0.0, 1.6) * 5.0 + dither * 0.72) / 5.0;
	vec3 quant_rgb = (luma > 0.005) ? (lt.rgb * (stepped / luma)) : vec3(0.0);
	vec3 soft = quant_rgb / (vec3(1.0) + quant_rgb * 0.42);
	vec3 halo = soft * mix(vec3(1.0), age_tint, 0.25) * gain;
	COLOR = vec4(halo, 1.0);
}
"""
	_light_mat = ShaderMaterial.new()
	_light_mat.shader = _light_shader

	_light_sprite = Sprite2D.new()
	_light_sprite.name = "LightmapSprite"
	_light_sprite.centered = false
	_light_sprite.position = Vector2.ZERO
	_light_sprite.scale = Vector2(LIGHTMAP_SCALE, LIGHTMAP_SCALE)
	_light_sprite.z_as_relative = false
	_light_sprite.z_index = 4
	_light_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_light_sprite.texture = _light_viewport.get_texture()
	_light_sprite.material = _light_mat
	_light_sprite.visible = false
	add_child(_light_sprite)


func _is_non_interactive_audio_disabled() -> bool:
	var drv := AudioServer.get_driver_name()
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless" or drv == "Dummy":
		return true
	for raw_arg in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		var arg := str(raw_arg)
		if arg.begins_with("--shot") or arg.begins_with("--screenshot") or arg.begins_with("--zoom-shot") or arg.begins_with("--smoke"):
			return true
	return false


func _init_audio_synth() -> void:
	_v_active.resize(VOICE_COUNT)
	_v_kind.resize(VOICE_COUNT)
	_v_t.resize(VOICE_COUNT)
	_v_dur.resize(VOICE_COUNT)
	_v_phase.resize(VOICE_COUNT)
	_v_phase2.resize(VOICE_COUNT)
	_v_pitch.resize(VOICE_COUNT)
	_v_gain.resize(VOICE_COUNT)
	_v_pan.resize(VOICE_COUNT)
	_v_lpf.resize(VOICE_COUNT)
	_v_bp.resize(VOICE_COUNT)
	_v_noise_state.resize(VOICE_COUNT)
	_sfx_cooldown.resize(SFX_KIND_COUNT)
	_v_active.fill(0)
	_v_gain.fill(1.0)
	_v_pan.fill(0.0)
	_v_lpf.fill(0.0)
	_v_bp.fill(0.0)
	_sfx_cooldown.fill(0.0)

	_mix_chunk.resize(AUDIO_CHUNK_SIZE)
	_mix_chunk.fill(Vector2.ZERO)

	if _is_non_interactive_audio_disabled():
		_audio_supported = false
		return

	_audio_supported = true
	_audio_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = TUNING_KNOBS["AUDIO_MIX_RATE"]
	gen.buffer_length = TUNING_KNOBS["AUDIO_BUFFER_SEC"]
	_audio_player.stream = gen
	_audio_player.volume_db = TUNING_KNOBS["AUDIO_VOLUME_DB"]
	add_child(_audio_player)


func _alloc_particle_slot() -> int:
	if _active_count < MAX_PARTICLES:
		var free_slot := _active_count
		_active_count += 1
		return free_slot
	var evict_slot := _evict_cursor % MAX_PARTICLES
	_evict_cursor += 1
	return evict_slot


func _classify_burst_visual(color: Color, gravity: float) -> Vector2:
	# Returns Vector2(col_idx, hdr_mult)
	var max_c := maxf(color.r, maxf(color.g, color.b))
	if max_c > 1.25:
		# Caller supplied HDR energy already
		if color.b > color.r and color.g > 0.55:
			return Vector2(float(P_COL_SPARKLE), 1.25)
		return Vector2(float(P_COL_EMBER), 1.15)
	if color.r > 0.80 and color.g < 0.78 and color.b < 0.45:
		return Vector2(float(P_COL_EMBER), 2.6)
	if color.b > 0.72 and color.g > 0.62 and color.r < 0.55:
		return Vector2(float(P_COL_SPARKLE), 2.2)
	if color.b > 0.72 and color.r < 0.58 and gravity > 10.0:
		return Vector2(float(P_COL_EMBER), 1.35)
	if max_c < 0.30:
		return Vector2(float(P_COL_EMBER), 1.05)
	return Vector2(float(P_COL_PUFF), 0.85)


func spawn_burst(world_pos: Vector2, count: int, color: Color, speed: float, lifetime: float, gravity: float = 0.0) -> void:
	_ensure_initialized()
	if count <= 0:
		return
	var vis := _classify_burst_visual(color, gravity)
	var col_idx := int(vis.x)
	var hdr_mult := vis.y
	var safe_life := maxf(lifetime, 0.05)

	for _i in range(count):
		var slot := _alloc_particle_slot()
		var ang := _rng.randf_range(0.0, TAU)
		var spd := _rng.randf_range(0.32, 1.15) * speed
		var jitter := Vector2(_rng.randf_range(-1.5, 1.5), _rng.randf_range(-1.5, 1.5))

		_p_mode[slot] = MODE_BALLISTIC
		_p_pos[slot] = world_pos + jitter
		_p_vel[slot] = Vector2(cos(ang), sin(ang)) * spd
		_p_age[slot] = 0.0
		_p_life[slot] = safe_life * _rng.randf_range(0.75, 1.2)
		_p_gravity[slot] = gravity
		_p_col_idx[slot] = col_idx
		_p_hdr[slot] = hdr_mult
		if col_idx == P_COL_PUFF:
			_p_color[slot] = Color(color.r * 0.86, color.g * 0.86, color.b * 0.86, minf(color.a, 0.42))
			_p_size[slot] = _rng.randf_range(0.36, 0.50)
		else:
			_p_color[slot] = color
			_p_size[slot] = _rng.randf_range(0.45, 0.82)
		_p_aspect[slot] = 1.0
		_p_rot[slot] = 0.0
		_write_instance_visual(slot)

	_mm_particles.multimesh.visible_instance_count = _active_count


func spawn_shockwave(world_pos: Vector2, max_radius: float, color: Color, life_override: float = -1.0) -> void:
	_ensure_initialized()
	var ring_count: int = int(TUNING_KNOBS["SHOCKWAVE_RING_COUNT"])
	var spark_count: int = int(TUNING_KNOBS["SHOCKWAVE_SPARK_COUNT"])
	var life: float = life_override if life_override > 0.0 else float(TUNING_KNOBS["SHOCKWAVE_LIFETIME"])
	var safe_r := maxf(max_radius, 8.0)

	# 1) Brief central starburst flash (zero muddy P_COL_PUFF scorch disc over craters)
	var flash_slot := _alloc_particle_slot()
	_p_mode[flash_slot] = MODE_BALLISTIC
	_p_pos[flash_slot] = world_pos
	_p_vel[flash_slot] = Vector2.ZERO
	_p_age[flash_slot] = 0.0
	_p_life[flash_slot] = 0.13
	_p_gravity[flash_slot] = 0.0
	_p_col_idx[flash_slot] = P_COL_FLASH
	_p_hdr[flash_slot] = 2.4
	_p_color[flash_slot] = color.lightened(0.20)
	_p_size[flash_slot] = clampf(safe_r * 0.10, 1.0, 1.9)
	_p_aspect[flash_slot] = 1.0
	_p_rot[flash_slot] = _rng.randf_range(0.0, TAU)
	_write_instance_visual(flash_slot)

	# 2) Crisp pixel-art expanding spark ring (no smooth vector polygon chords)
	for i in range(ring_count):
		var slot := _alloc_particle_slot()
		var base_ang := (float(i) / float(ring_count)) * TAU
		var dir := Vector2(cos(base_ang), sin(base_ang))
		_p_mode[slot] = MODE_SHOCKWAVE
		_p_origin[slot] = world_pos
		_p_dir[slot] = dir
		_p_max_r[slot] = safe_r
		_p_pos[slot] = (world_pos + dir * (safe_r * 0.18)).round()
		_p_vel[slot] = dir * (safe_r / life)
		_p_age[slot] = 0.0
		_p_life[slot] = life
		_p_gravity[slot] = 0.0
		_p_col_idx[slot] = P_COL_SPARKLE if (i % 2 == 0) else P_COL_EMBER
		_p_hdr[slot] = 2.4
		_p_color[slot] = color.lightened(0.18)
		_p_size[slot] = 0.42
		_p_aspect[slot] = 1.0
		_p_rot[slot] = 0.0
		_write_instance_visual(slot)

	# 3) Fast directional debris embers + compact dust puffs
	for j in range(spark_count):
		var slot := _alloc_particle_slot()
		var ang := _rng.randf_range(0.0, TAU)
		var spd := _rng.randf_range(0.85, 1.85) * safe_r * 1.45
		var is_streak := (j % 3 == 0)
		_p_mode[slot] = MODE_BALLISTIC
		_p_pos[slot] = world_pos + Vector2(cos(ang), sin(ang)) * 2.5
		_p_vel[slot] = Vector2(cos(ang), sin(ang)) * spd
		_p_age[slot] = 0.0
		_p_life[slot] = life * _rng.randf_range(0.50, 0.88)
		_p_gravity[slot] = 32.0
		_p_col_idx[slot] = P_COL_BOLT if is_streak else P_COL_EMBER
		_p_hdr[slot] = 2.55
		_p_color[slot] = color.lightened(0.28)
		_p_size[slot] = 0.45 if is_streak else _rng.randf_range(0.55, 0.82)
		_p_aspect[slot] = 2.1 if is_streak else 1.0
		_p_rot[slot] = ang if is_streak else 0.0
		_write_instance_visual(slot)

	_mm_particles.multimesh.visible_instance_count = _active_count
	_spawn_transient_light(world_pos, clampf(safe_r * 1.6, 18.0, 72.0), color.lightened(0.2), 1.65, 0.36)


func emit_campfire_ember(world_pos: Vector2, drift: Vector2 = Vector2.ZERO, color: Color = Color(1.0, 0.58, 0.18, 0.92)) -> void:
	_ensure_initialized()
	var slot := _alloc_particle_slot()
	_p_mode[slot] = MODE_BALLISTIC
	_p_pos[slot] = world_pos + Vector2(_rng.randf_range(-2.5, 2.5), _rng.randf_range(-2.0, 1.0))
	_p_vel[slot] = drift + Vector2(_rng.randf_range(-6.0, 6.0), _rng.randf_range(-20.0, -10.0))
	_p_age[slot] = 0.0
	_p_life[slot] = _rng.randf_range(0.50, 0.90)
	_p_gravity[slot] = -6.0
	_p_col_idx[slot] = P_COL_EMBER
	_p_hdr[slot] = 2.4
	_p_color[slot] = color
	_p_size[slot] = _rng.randf_range(0.38, 0.58)
	_p_aspect[slot] = 1.0
	_p_rot[slot] = 0.0
	_write_instance_visual(slot)
	_mm_particles.multimesh.visible_instance_count = _active_count


func emit_spark_arc(world_pos: Vector2, dir: Vector2 = Vector2.RIGHT, color: Color = Color(0.55, 0.92, 1.0, 1.0)) -> void:
	_ensure_initialized()
	var base_dir := dir.normalized() if dir.length_squared() > 0.0001 else Vector2.RIGHT
	var base_ang := base_dir.angle()
	for i in range(4):
		var slot := _alloc_particle_slot()
		var ang := base_ang + _rng.randf_range(-0.62, 0.62)
		var spd := _rng.randf_range(48.0, 96.0)
		var is_bolt := (i == 0)
		_p_mode[slot] = MODE_BALLISTIC
		_p_pos[slot] = world_pos + Vector2(cos(ang), sin(ang)) * 1.5
		_p_vel[slot] = Vector2(cos(ang), sin(ang)) * spd
		_p_age[slot] = 0.0
		_p_life[slot] = _rng.randf_range(0.14, 0.24)
		_p_gravity[slot] = 22.0
		_p_col_idx[slot] = P_COL_BOLT if is_bolt else P_COL_SPARKLE
		_p_hdr[slot] = 2.75
		_p_color[slot] = color
		_p_size[slot] = 0.40 if is_bolt else _rng.randf_range(0.45, 0.68)
		_p_aspect[slot] = 2.2 if is_bolt else 1.0
		_p_rot[slot] = ang
		_write_instance_visual(slot)
	_mm_particles.multimesh.visible_instance_count = _active_count


func emit_laser_tracer(start_pos: Vector2, end_pos: Vector2, color: Color = Color(1.0, 0.35, 0.25, 1.0)) -> void:
	_ensure_initialized()
	var delta := end_pos - start_pos
	var dist := delta.length()
	if dist < 1.0:
		emit_spark_arc(end_pos, Vector2.UP, color)
		return
	var dir := delta / dist
	var ang := delta.angle()
	var beam_len := clampf(dist * 0.65, 4.0, 26.0)
	var life := 0.095
	var thickness := 0.40

	var b_slot := _alloc_particle_slot()
	_p_mode[b_slot] = MODE_TRACER
	_p_pos[b_slot] = start_pos + dir * (beam_len * 0.45)
	_p_vel[b_slot] = dir * (maxf(dist - beam_len * 0.5, 8.0) / life)
	_p_age[b_slot] = 0.0
	_p_life[b_slot] = life
	_p_gravity[b_slot] = 0.0
	_p_col_idx[b_slot] = P_COL_BOLT
	_p_hdr[b_slot] = 2.95
	_p_color[b_slot] = color
	_p_size[b_slot] = thickness
	_p_aspect[b_slot] = beam_len / (PARTICLE_QUAD_PX * thickness)
	_p_rot[b_slot] = ang
	_write_instance_visual(b_slot)

	var m_slot := _alloc_particle_slot()
	_p_mode[m_slot] = MODE_BALLISTIC
	_p_pos[m_slot] = start_pos
	_p_vel[m_slot] = Vector2.ZERO
	_p_age[m_slot] = 0.0
	_p_life[m_slot] = 0.065
	_p_gravity[m_slot] = 0.0
	_p_col_idx[m_slot] = P_COL_FLASH
	_p_hdr[m_slot] = 2.85
	_p_color[m_slot] = color.lightened(0.35)
	_p_size[m_slot] = 0.55
	_p_aspect[m_slot] = 1.0
	_p_rot[m_slot] = ang
	_write_instance_visual(m_slot)

	for _k in range(2):
		var s_slot := _alloc_particle_slot()
		var s_ang := ang + PI + _rng.randf_range(-0.9, 0.9)
		_p_mode[s_slot] = MODE_BALLISTIC
		_p_pos[s_slot] = end_pos
		_p_vel[s_slot] = Vector2(cos(s_ang), sin(s_ang)) * _rng.randf_range(26.0, 56.0)
		_p_age[s_slot] = 0.0
		_p_life[s_slot] = _rng.randf_range(0.12, 0.22)
		_p_gravity[s_slot] = 26.0
		_p_col_idx[s_slot] = P_COL_SPARKLE
		_p_hdr[s_slot] = 2.65
		_p_color[s_slot] = color.lightened(0.2)
		_p_size[s_slot] = 0.48
		_p_aspect[s_slot] = 1.0
		_p_rot[s_slot] = 0.0
		_write_instance_visual(s_slot)

	_mm_particles.multimesh.visible_instance_count = _active_count


func apply_vortex_to_particles(world_pos: Vector2, radius: float, strength: float, dt: float) -> void:
	if _active_count <= 0 or radius <= 1.0:
		return
	var r2 := radius * radius
	for i in range(_active_count):
		if _p_mode[i] == MODE_SHOCKWAVE or _p_mode[i] == MODE_TRACER:
			continue
		var diff := world_pos - _p_pos[i]
		var d2 := diff.length_squared()
		if d2 <= r2 and d2 > 0.25:
			var dist := sqrt(d2)
			var falloff := 1.0 - (dist / radius)
			var inward := diff / dist
			var tangent := Vector2(-inward.y, inward.x)
			var accel := (tangent * 1.45 + inward * 0.95) * strength * falloff
			_p_vel[i] += accel * dt


func _alloc_strip_slot() -> int:
	if _s_active_count < MAX_STRIPS:
		var free_slot := _s_active_count
		_s_active_count += 1
		return free_slot
	var evict_slot := _s_evict_cursor % MAX_STRIPS
	_s_evict_cursor += 1
	return evict_slot


func _copy_strip(src: int, dst: int) -> void:
	_s_pos[dst] = _s_pos[src]
	_s_vel[dst] = _s_vel[src]
	_s_age[dst] = _s_age[src]
	_s_life[dst] = _s_life[src]
	_s_hdr[dst] = _s_hdr[src]
	_s_col_idx[dst] = _s_col_idx[src]


func _write_strip_visual(i: int) -> void:
	var life := maxf(_s_life[i], 0.01)
	var t := clampf(_s_age[i] / life, 0.0, 1.0)
	var scale_s := 0.5 if (t < 0.08 or t > 0.88) else 1.0
	var fade_in := clampf(t / 0.08, 0.0, 1.0)
	var fade_out := 1.0
	if t > 0.58:
		var u := clampf((t - 0.58) / 0.42, 0.0, 1.0)
		fade_out = 1.0 - u * u
	var alpha := clampf(fade_in * fade_out, 0.0, 1.0)

	var mm := _mm_strips.multimesh
	mm.set_instance_transform_2d(i, Transform2D(0.0, Vector2(scale_s, scale_s), 0.0, _s_pos[i].round()))
	mm.set_instance_color(i, Color(1.0, 1.0, 1.0, alpha))
	mm.set_instance_custom_data(i, Color(_s_hdr[i], 0.0, 1.0, float(_s_col_idx[i])))


func spawn_reaction_strip(world_pos: Vector2, strip_id: int) -> void:
	_ensure_initialized()
	var slot := _alloc_strip_slot()
	var cid := clampi(strip_id, 0, maxi(0, _strip_atlas_cols - 1))
	_s_pos[slot] = world_pos + Vector2(_rng.randf_range(-2.2, 2.2), -5.5)
	_s_vel[slot] = Vector2(_rng.randf_range(-2.2, 2.2), -float(TUNING_KNOBS["STRIP_FLOAT_SPEED"]))
	_s_age[slot] = 0.0
	_s_life[slot] = float(TUNING_KNOBS["STRIP_LIFETIME_SEC"])
	_s_hdr[slot] = 1.65
	_s_col_idx[slot] = cid
	_write_strip_visual(slot)
	_mm_strips.multimesh.visible_instance_count = _s_active_count


func _spawn_transient_light(world_pos: Vector2, radius: float, color: Color, intensity: float, life_sec: float) -> void:
	var slot := -1
	if _tl_count < MAX_TRANSIENT_LIGHTS:
		slot = _tl_count
		_tl_count += 1
	else:
		slot = _tl_evict_cursor % MAX_TRANSIENT_LIGHTS
		_tl_evict_cursor += 1
	_tl_pos[slot] = world_pos
	_tl_rad[slot] = maxf(radius, 6.0)
	_tl_col[slot] = color
	_tl_intensity[slot] = maxf(intensity, 0.1)
	_tl_age[slot] = 0.0
	_tl_life[slot] = maxf(life_sec, 0.05)


func _push_light_raw(world_pos: Vector2, radius: float, color: Color, eff_intensity: float) -> void:
	if _light_count >= MAX_LIGHTS or eff_intensity <= 0.015:
		return
	var r_vp := maxf(radius * INV_LIGHTMAP_SCALE, 1.0)
	var pos_vp := world_pos * INV_LIGHTMAP_SCALE
	var xform := Transform2D(0.0, Vector2(r_vp, r_vp), 0.0, pos_vp)
	var c := Color(
		clampf(color.r * eff_intensity, 0.0, 2.5),
		clampf(color.g * eff_intensity, 0.0, 2.5),
		clampf(color.b * eff_intensity, 0.0, 2.5),
		clampf(eff_intensity, 0.0, 1.0)
	)
	var mm := _light_mm.multimesh
	mm.set_instance_transform_2d(_light_count, xform)
	mm.set_instance_color(_light_count, c)
	_light_count += 1


func begin_light_frame(night_mix: float, age_tint: Color) -> void:
	_ensure_initialized()
	_light_night_mix = clampf(night_mix, 0.0, 1.0)
	_light_age_tint = age_tint
	_light_count = 0
	if _light_mat != null:
		_light_mat.set_shader_parameter("night_mix", _light_night_mix)
		_light_mat.set_shader_parameter("age_tint", Vector3(age_tint.r, age_tint.g, age_tint.b))


func push_light(world_pos: Vector2, radius: float, color: Color, intensity: float = 1.0) -> void:
	if _light_count >= MAX_LIGHTS:
		return
	var eff := 0.0
	if intensity > 1.05:
		eff = intensity * lerpf(0.55, 1.0, _light_night_mix)
	else:
		eff = intensity * clampf(_light_night_mix * 1.65, 0.0, 1.0)
	_push_light_raw(world_pos, radius, color, eff)


func end_light_frame() -> void:
	_ensure_initialized()
	var day_scale := lerpf(0.55, 1.0, _light_night_mix)
	for i in range(_tl_count):
		var life := maxf(_tl_life[i], 0.01)
		var remain := clampf(1.0 - (_tl_age[i] / life), 0.0, 1.0)
		var eff := _tl_intensity[i] * remain * remain * day_scale
		_push_light_raw(_tl_pos[i], _tl_rad[i], _tl_col[i], eff)
	if _light_mm != null and _light_mm.multimesh != null:
		_light_mm.multimesh.visible_instance_count = _light_count
	var any_light := (_light_count > 0)
	if _light_sprite != null:
		_light_sprite.visible = any_light
	if _light_viewport != null:
		_light_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if any_light else SubViewport.UPDATE_DISABLED


func is_light_layer_visible() -> bool:
	return _light_sprite != null and _light_sprite.visible


func emit_orbital_beam(world_pos: Vector2, intercepted: bool, stop_pos: Vector2 = Vector2.ZERO) -> void:
	_ensure_initialized()
	var hit := stop_pos if (intercepted and stop_pos != Vector2.ZERO) else world_pos
	play_sfx(SfxKind.ORBITAL_BEAM, hit.x)
	var sky_y := maxf(hit.y - 240.0, -48.0)
	var span_bot := maxf(sky_y + 12.0, hit.y - 22.0)
	var steps := 12
	for k in range(steps):
		var u := float(k) / float(maxi(steps - 1, 1))
		var start_y := lerpf(sky_y, span_bot, u)
		var spd := _rng.randf_range(400.0, 580.0)
		var p := Vector2(hit.x + _rng.randf_range(-1.0, 1.0), start_y)
		var slot := _alloc_particle_slot()
		_p_pos[slot] = p
		_p_vel[slot] = Vector2(0.0, spd)
		_p_origin[slot] = p
		_p_dir[slot] = Vector2.DOWN
		_p_max_r[slot] = 0.0
		_p_mode[slot] = MODE_TRACER
		_p_age[slot] = 0.0
		# Clamp bolt lifetime before crossing hit.y so tracers terminate cleanly at the impact point
		_p_life[slot] = clampf((hit.y - 10.0 - start_y) / spd, 0.03, 0.22)
		_p_gravity[slot] = 0.0
		_p_col_idx[slot] = P_COL_BOLT
		_p_hdr[slot] = 3.6 if (k % 2 == 0) else 2.8
		_p_color[slot] = Color(0.88, 0.99, 1.0, 1.0) if (k % 3 == 0) else Color(0.28, 0.90, 1.0, 0.96)
		_p_size[slot] = 1.0 if (k % 2 == 0) else 0.70
		_p_aspect[slot] = 5.4
		_p_rot[slot] = PI * 0.5
		_write_instance_visual(slot)

	for c_idx in range(3):
		var cy := hit.y - (13.0 + float(c_idx) * 20.0)
		var c_slot := _alloc_particle_slot()
		var cp := Vector2(hit.x, cy)
		_p_pos[c_slot] = cp
		_p_vel[c_slot] = Vector2.ZERO
		_p_origin[c_slot] = cp
		_p_dir[c_slot] = Vector2.DOWN
		_p_max_r[c_slot] = 0.0
		_p_mode[c_slot] = MODE_TRACER
		_p_age[c_slot] = 0.0
		_p_life[c_slot] = 0.20
		_p_gravity[c_slot] = 0.0
		_p_col_idx[c_slot] = P_COL_BOLT
		_p_hdr[c_slot] = 3.8
		_p_color[c_slot] = Color(0.85, 0.99, 1.0, 1.0)
		_p_size[c_slot] = 1.15
		_p_aspect[c_slot] = 5.6
		_p_rot[c_slot] = PI * 0.5
		_write_instance_visual(c_slot)

	var f_slot := _alloc_particle_slot()
	_p_pos[f_slot] = hit
	_p_vel[f_slot] = Vector2.ZERO
	_p_origin[f_slot] = hit
	_p_dir[f_slot] = Vector2.ZERO
	_p_max_r[f_slot] = 0.0
	_p_mode[f_slot] = MODE_BALLISTIC
	_p_age[f_slot] = 0.0
	_p_life[f_slot] = 0.24
	_p_gravity[f_slot] = 0.0
	_p_col_idx[f_slot] = P_COL_FLASH
	_p_hdr[f_slot] = 3.8
	_p_color[f_slot] = Color(0.62, 0.96, 1.0, 1.0)
	_p_size[f_slot] = 3.2 if not intercepted else 2.1
	_p_aspect[f_slot] = 1.0
	_p_rot[f_slot] = 0.0
	_write_instance_visual(f_slot)
	_mm_particles.multimesh.visible_instance_count = _active_count

	_spawn_transient_light(
		hit,
		64.0 if not intercepted else float(TUNING_KNOBS["SHIELD_DEFLECT_LIGHT_MAX_RADIUS"]),
		Color(0.35, 0.92, 1.0, 1.0),
		2.15 if not intercepted else float(TUNING_KNOBS["SHIELD_DEFLECT_LIGHT_MAX_INTENSITY"]),
		0.36
	)
	if not intercepted:
		spawn_shockwave(hit, 28.0, Color(0.45, 0.92, 1.0, 0.95), 0.34)
		spawn_burst(hit, 14, Color(0.55, 0.95, 1.0, 0.95), 54.0, 0.42, 42.0)


func emit_shield_deflect(pylon_pos: Vector2, radius: float, hit_pos: Vector2) -> void:
	_ensure_initialized()
	var safe_r := maxf(radius, 18.0)
	var dir_vec := (hit_pos - pylon_pos)
	var hit_dir := dir_vec.normalized() if dir_vec.length_squared() > 1.0 else Vector2.UP
	var arc_pos := pylon_pos + hit_dir * minf(dir_vec.length(), safe_r * 0.94)
	var tangent := Vector2(-hit_dir.y, hit_dir.x)

	play_sfx(SfxKind.SHIELD_DEFLECT, arc_pos.x)
	spawn_reaction_strip(arc_pos + Vector2(0.0, -6.0), STRIP_SHIELD)

	# Localized cyan rim ripple + compact starburst strictly at intercept impact (zero grey P_COL_PUFF smear)
	var ripple_r := clampf(safe_r * 0.34, 10.0, 16.0)
	var flash_slot := _alloc_particle_slot()
	_p_mode[flash_slot] = MODE_BALLISTIC
	_p_pos[flash_slot] = arc_pos
	_p_vel[flash_slot] = Vector2.ZERO
	_p_age[flash_slot] = 0.0
	_p_life[flash_slot] = 0.12
	_p_gravity[flash_slot] = 0.0
	_p_col_idx[flash_slot] = P_COL_FLASH
	_p_hdr[flash_slot] = 1.95
	_p_color[flash_slot] = Color(0.34, 0.94, 1.0, 0.92)
	_p_size[flash_slot] = 1.25
	_p_aspect[flash_slot] = 1.0
	_p_rot[flash_slot] = _rng.randf_range(0.0, TAU)
	_write_instance_visual(flash_slot)

	var ring_segs := 12
	for r_idx in range(ring_segs):
		var r_slot := _alloc_particle_slot()
		var base_ang := (float(r_idx) / float(ring_segs)) * TAU
		var r_dir := Vector2(cos(base_ang), sin(base_ang))
		_p_mode[r_slot] = MODE_SHOCKWAVE
		_p_origin[r_slot] = arc_pos
		_p_dir[r_slot] = r_dir
		_p_max_r[r_slot] = ripple_r
		_p_pos[r_slot] = (arc_pos + r_dir * (ripple_r * 0.20)).round()
		_p_vel[r_slot] = r_dir * (ripple_r / 0.24)
		_p_age[r_slot] = 0.0
		_p_life[r_slot] = 0.24
		_p_gravity[r_slot] = 0.0
		_p_col_idx[r_slot] = P_COL_SPARKLE
		_p_hdr[r_slot] = 2.1
		_p_color[r_slot] = Color(0.32, 0.92, 1.0, 0.92)
		_p_size[r_slot] = 0.36
		_p_aspect[r_slot] = 1.0
		_p_rot[r_slot] = 0.0
		_write_instance_visual(r_slot)

	for i in range(12):
		var slot := _alloc_particle_slot()
		var t_ang := lerpf(-1.15, 1.15, float(i) / 11.0)
		var b_dir := hit_dir.rotated(t_ang * 0.85)
		var spd := _rng.randf_range(26.0, 62.0)
		var vel := b_dir * spd + tangent * _rng.randf_range(-18.0, 18.0)
		_p_pos[slot] = arc_pos
		_p_vel[slot] = vel
		_p_origin[slot] = arc_pos
		_p_dir[slot] = b_dir
		_p_max_r[slot] = 0.0
		_p_mode[slot] = MODE_TRACER if (i % 2 == 0) else MODE_BALLISTIC
		_p_age[slot] = 0.0
		_p_life[slot] = _rng.randf_range(0.18, 0.32)
		_p_gravity[slot] = 18.0
		_p_col_idx[slot] = P_COL_BOLT if (i % 2 == 0) else P_COL_SPARKLE
		_p_hdr[slot] = 2.45
		_p_color[slot] = Color(0.42, 0.96, 1.0, 0.96)
		_p_size[slot] = 0.62
		_p_aspect[slot] = 2.3 if (i % 2 == 0) else 1.0
		_p_rot[slot] = vel.angle() if (i % 2 == 0) else 0.0
		_write_instance_visual(slot)

	_mm_particles.multimesh.visible_instance_count = _active_count
	var light_r := clampf(safe_r * 0.72, 22.0, float(TUNING_KNOBS["SHIELD_DEFLECT_LIGHT_MAX_RADIUS"]))
	var light_i := minf(1.05, float(TUNING_KNOBS["SHIELD_DEFLECT_LIGHT_MAX_INTENSITY"]))
	_spawn_transient_light(arc_pos, light_r, Color(0.28, 0.94, 1.0, 1.0), light_i, 0.28)


func set_audio_telemetry(cam_zoom: float, cursor_speed_norm: float) -> void:
	_cam_zoom = clampf(cam_zoom, 0.5, 16.0)
	_cursor_speed_norm = clampf(cursor_speed_norm, 0.0, 1.0)


func set_camera_center_x(cx: float) -> void:
	_cam_center_x = cx


func set_camera_audio_context(cam_rect: Rect2, zoom_val: float, sim_speed: float) -> void:
	_ensure_initialized()
	_cam_rect = cam_rect
	_cam_zoom = clampf(zoom_val, 0.5, 16.0)
	_sim_speed = clampf(sim_speed, 0.0, 200.0)
	if cam_rect.size.x > 0.0:
		_cam_center_x = cam_rect.position.x + cam_rect.size.x * 0.5
	_amb_pause_target = 0.0 if _sim_speed <= 0.001 else 1.0
	if _biome_scan_timer <= 0.0:
		_scan_visible_biome_audio()
		_biome_scan_timer = 0.50


func get_audio_context_state() -> Dictionary:
	return {
		"cam_zoom": _cam_zoom,
		"sim_speed": _sim_speed,
		"pause_gain": _amb_pause_gain,
		"pause_target": _amb_pause_target,
		"ambient_biome_id": _ambient_biome_id,
		"biome_f_mul": _amb_biome_f_mul,
		"biome_wind_mul": _amb_biome_wind_mul,
		"drop_instances": _mm_drops.multimesh.visible_instance_count if (_mm_drops != null and _mm_drops.multimesh != null) else 0,
	}


func _resolve_world_ref() -> Node2D:
	if _world_ref != null and is_instance_valid(_world_ref):
		return _world_ref
	var p := get_parent()
	if p != null:
		var cand := p.get_node_or_null("WorldTerrain") as Node2D
		if cand != null:
			_world_ref = cand
			return _world_ref
	_world_ref = get_node_or_null("../WorldTerrain") as Node2D
	return _world_ref


func _scan_visible_biome_audio() -> void:
	var w := _resolve_world_ref()
	if w == null:
		return
	var dom_b: int = 1
	if w.has_method("get_dominant_biome_in_rect"):
		dom_b = int(w.call("get_dominant_biome_in_rect", _cam_rect))
	elif w.has_method("get_biome"):
		var mw: int = int(w.get("map_w"))
		var mh: int = int(w.get("map_h"))
		var sx: int = clampi(int(_cam_rect.position.x + _cam_rect.size.x * 0.5), 0, maxi(0, mw - 1))
		var sy: int = clampi(int(_cam_rect.position.y + _cam_rect.size.y * 0.5), 0, maxi(0, mh - 1))
		dom_b = int(w.call("get_biome", sx, sy))
	_ambient_biome_id = dom_b
	match dom_b:
		4, 3, 7:
			_amb_biome_f_mul = 0.78
			_amb_biome_wind_mul = 1.25
		6:
			_amb_biome_f_mul = 1.32
			_amb_biome_wind_mul = 1.35
		2, 11:
			_amb_biome_f_mul = 1.44
			_amb_biome_wind_mul = 0.85
		9, 5:
			_amb_biome_f_mul = 1.16
			_amb_biome_wind_mul = 1.08
		10:
			_amb_biome_f_mul = 0.86
			_amb_biome_wind_mul = 0.92
		0, 8:
			_amb_biome_f_mul = 0.94
			_amb_biome_wind_mul = 1.18
		_:
			_amb_biome_f_mul = 1.0
			_amb_biome_wind_mul = 1.0


func sync_sky_drops(positions: PackedVector2Array, colors: PackedColorArray, z_heights: PackedFloat32Array) -> void:
	_ensure_initialized()
	if _mm_drops == null or _mm_drops.multimesh == null:
		return
	var mm := _mm_drops.multimesh
	var n := mini(positions.size(), mini(colors.size(), mini(z_heights.size(), MAX_DROPS)))
	if n <= 0:
		mm.visible_instance_count = 0
		_mm_drops.visible = false
		return
	_mm_drops.visible = true
	mm.visible_instance_count = n
	for i in range(n):
		var pos: Vector2 = positions[i]
		var z: float = clampf(z_heights[i], 0.0, 120.0)
		var col: Color = colors[i]
		var col_idx: int = 1
		var hdr: float = 1.75
		var sc: float = 0.68
		if col.r > 0.90 and col.g < 0.62 and col.b < 0.30:
			col_idx = 2
			hdr = 2.45
			sc = 0.78
		elif col.r > 0.86 and col.g > 0.90 and col.b > 0.92:
			col_idx = 3
			hdr = 1.35
			sc = 0.66
		elif col.b > 0.80 and col.r < 0.60:
			col_idx = 0
			hdr = 1.65
			sc = 0.66
		var draw_pos := Vector2(pos.x, pos.y - z)
		mm.set_instance_transform_2d(i, Transform2D(0.0, Vector2(sc, sc), 0.0, draw_pos))
		mm.set_instance_color(i, col)
		mm.set_instance_custom_data(i, Color(hdr, 1.0, 1.0, float(col_idx)))


func emit_drop_land_flash(world_pos: Vector2, color: Color) -> void:
	_ensure_initialized()
	if _drop_flash_budget <= 0:
		return
	_drop_flash_budget -= 1
	var slot := _alloc_particle_slot()
	_p_mode[slot] = MODE_BALLISTIC
	_p_pos[slot] = world_pos
	_p_vel[slot] = Vector2.ZERO
	_p_age[slot] = 0.0
	_p_life[slot] = 0.05
	_p_gravity[slot] = 0.0
	_p_col_idx[slot] = P_COL_FLASH
	_p_hdr[slot] = 2.55
	_p_color[slot] = Color(1.0, 0.98, 0.92, 0.96).lerp(color, 0.25)
	_p_size[slot] = 0.54
	_p_aspect[slot] = 1.0
	_p_rot[slot] = 0.0
	_write_instance_visual(slot)
	_mm_particles.multimesh.visible_instance_count = _active_count


func activate_audio() -> void:
	_ensure_initialized()
	if not _audio_supported:
		return
	_audio_unlocked = true
	_pump_audio(AUDIO_CHUNK_SIZE * 2)


func set_ambient_age(age_id: int) -> void:
	_ambient_age_id = clampi(age_id, 0, 4)
	match _ambient_age_id:
		1:
			_amb_target_f1 = 55.0
			_amb_target_f2 = 82.5
		2:
			_amb_target_f1 = 293.6
			_amb_target_f2 = 146.8
		3:
			_amb_target_f1 = 98.0
			_amb_target_f2 = 147.0
		4:
			_amb_target_f1 = 220.0
			_amb_target_f2 = 330.0
		_:
			_amb_target_f1 = 110.0
			_amb_target_f2 = 165.0


func _parse_sfx_kind(kind: Variant) -> int:
	if kind is int or kind is float:
		return clampi(int(kind), 0, SFX_KIND_COUNT - 1)
	match str(kind).to_lower():
		"meteor":
			return SfxKind.METEOR
		"terraform":
			return SfxKind.TERRAFORM
		"crystal":
			return SfxKind.CRYSTAL
		"lava":
			return SfxKind.LAVA
		"vortex":
			return SfxKind.VORTEX
		"build_pop", "build":
			return SfxKind.BUILD_POP
		"skirmish", "laser", "combat":
			return SfxKind.SKIRMISH
		"meltdown", "nuke":
			return SfxKind.MELTDOWN
		"storm", "rainburst", "firestorm", "ion_storm":
			return SfxKind.STORM
		"shuttle", "launch":
			return SfxKind.SHUTTLE
		"mutate", "mutation", "bless":
			return SfxKind.MUTATE
		"orbital_beam", "orbital", "beam":
			return SfxKind.ORBITAL_BEAM
		"shield_deflect", "shield", "deflect":
			return SfxKind.SHIELD_DEFLECT
		"laser_light", "turret", "laser_bolt":
			return SfxKind.LASER_LIGHT
		"laser_heavy", "heavy_laser", "orbital_laser":
			return SfxKind.LASER_HEAVY
		"teleport_hum", "teleport", "portal", "warp":
			return SfxKind.TELEPORT_HUM
		"emp_glitch", "emp", "glitch":
			return SfxKind.EMP_GLITCH
		"ui_tab", "tab":
			return SfxKind.UI_TAB
		"ui_pin", "pin":
			return SfxKind.UI_PIN
		"ui_denied", "denied":
			return SfxKind.UI_DENIED
		"drop_rain", "rain", "drop":
			return SfxKind.DROP_RAIN
		"drop_impact", "seed", "powder":
			return SfxKind.DROP_IMPACT
		"earthquake", "quake":
			return SfxKind.EARTHQUAKE
		"volcano", "tornado", "geyser", "volcano_tornado":
			return SfxKind.VOLCANO_TORNADO
		"footstep", "chop", "mine", "repair", "work", "footstep_work":
			return SfxKind.FOOTSTEP_WORK
		"ui_hover", "hover":
			return SfxKind.UI_HOVER
		"window_whoosh", "window", "whoosh":
			return SfxKind.WINDOW_WHOOSH
		"bit_scale_whoosh", "zoom_whoosh", "zoom":
			return SfxKind.BIT_SCALE_WHOOSH
		_:
			return SfxKind.UI


func _sfx_cooldown_for(k: int) -> float:
	match k:
		SfxKind.METEOR, SfxKind.UI, SfxKind.UI_TAB, SfxKind.UI_PIN, SfxKind.UI_DENIED:
			return 0.02
		SfxKind.UI_HOVER:
			return 0.045
		SfxKind.WINDOW_WHOOSH, SfxKind.BIT_SCALE_WHOOSH:
			return 0.075
		SfxKind.DROP_RAIN, SfxKind.DROP_IMPACT:
			return 0.045
		SfxKind.FOOTSTEP_WORK:
			return 0.065
		SfxKind.EARTHQUAKE, SfxKind.VOLCANO_TORNADO:
			return 0.18
		SfxKind.BUILD_POP:
			return float(TUNING_KNOBS["BUILD_POP_COOLDOWN_SEC"])
		SfxKind.SKIRMISH:
			return 0.075
		SfxKind.MELTDOWN, SfxKind.STORM, SfxKind.SHUTTLE:
			return 0.16
		SfxKind.ORBITAL_BEAM:
			return 0.10
		SfxKind.SHIELD_DEFLECT:
			return 0.08
		SfxKind.MUTATE:
			return 0.09
		SfxKind.LASER_LIGHT:
			return 0.035
		SfxKind.LASER_HEAVY:
			return 0.060
		SfxKind.TELEPORT_HUM:
			return 0.120
		SfxKind.EMP_GLITCH:
			return 0.110
		_:
			return 0.055


func _sfx_duration_for(k: int) -> float:
	match k:
		SfxKind.METEOR:
			return 0.52
		SfxKind.TERRAFORM:
			return 0.20
		SfxKind.CRYSTAL:
			return 0.24
		SfxKind.LAVA:
			return 0.30
		SfxKind.VORTEX:
			return 0.22
		SfxKind.UI:
			return 0.050
		SfxKind.UI_TAB:
			return 0.055
		SfxKind.UI_PIN:
			return 0.110
		SfxKind.UI_DENIED:
			return 0.085
		SfxKind.DROP_RAIN:
			return 0.065
		SfxKind.DROP_IMPACT:
			return 0.055
		SfxKind.EARTHQUAKE:
			return 0.68
		SfxKind.VOLCANO_TORNADO:
			return 0.52
		SfxKind.FOOTSTEP_WORK:
			return 0.042
		SfxKind.UI_HOVER:
			return 0.028
		SfxKind.WINDOW_WHOOSH:
			return 0.16
		SfxKind.BIT_SCALE_WHOOSH:
			return 0.18
		SfxKind.BUILD_POP:
			return float(TUNING_KNOBS["BUILD_POP_DURATION_SEC"])
		SfxKind.SKIRMISH:
			return 0.12
		SfxKind.MELTDOWN:
			return 0.72
		SfxKind.STORM:
			return 0.42
		SfxKind.SHUTTLE:
			return 0.52
		SfxKind.MUTATE:
			return 0.28
		SfxKind.ORBITAL_BEAM:
			return 0.48
		SfxKind.SHIELD_DEFLECT:
			return 0.38
		SfxKind.LASER_LIGHT:
			return 0.095
		SfxKind.LASER_HEAVY:
			return 0.180
		SfxKind.TELEPORT_HUM:
			return 0.420
		SfxKind.EMP_GLITCH:
			return 0.320
		_:
			return 0.13


func play_sfx(kind: Variant, world_x: float = -1.0) -> void:
	_ensure_initialized()
	var k := _parse_sfx_kind(kind)
	if k == SfxKind.FOOTSTEP_WORK and _cam_zoom <= 2.2:
		return
	if _sfx_cooldown[k] > 0.0:
		return
	_sfx_cooldown[k] = _sfx_cooldown_for(k)

	var slot := 0
	var best_progress := -1.0
	for v in range(VOICE_COUNT):
		if _v_active[v] == 0:
			slot = v
			break
		var prog := _v_t[v] / maxf(_v_dur[v], 0.01)
		if prog > best_progress:
			best_progress = prog
			slot = v

	var dur := _sfx_duration_for(k)
	var macro_t := clampf((_cam_zoom - 1.2) / 3.8, 0.0, 1.0)
	var zoom_gain := 1.0
	match k:
		SfxKind.BUILD_POP, SfxKind.SKIRMISH, SfxKind.MUTATE, SfxKind.LASER_LIGHT, SfxKind.TERRAFORM, SfxKind.CRYSTAL, SfxKind.LAVA, SfxKind.VORTEX:
			zoom_gain = lerpf(0.28, 1.0, macro_t)
		SfxKind.DROP_RAIN, SfxKind.DROP_IMPACT, SfxKind.FOOTSTEP_WORK:
			zoom_gain = lerpf(0.22, 0.85, macro_t)
		SfxKind.LASER_HEAVY, SfxKind.SHIELD_DEFLECT, SfxKind.EMP_GLITCH, SfxKind.SHUTTLE, SfxKind.VOLCANO_TORNADO:
			zoom_gain = lerpf(0.52, 1.0, macro_t)
		SfxKind.METEOR, SfxKind.MELTDOWN, SfxKind.STORM, SfxKind.ORBITAL_BEAM, SfxKind.TELEPORT_HUM, SfxKind.EARTHQUAKE:
			zoom_gain = lerpf(0.72, 1.0, macro_t)
		SfxKind.UI, SfxKind.UI_TAB, SfxKind.UI_PIN, SfxKind.UI_DENIED, SfxKind.UI_HOVER, SfxKind.WINDOW_WHOOSH, SfxKind.BIT_SCALE_WHOOSH:
			zoom_gain = lerpf(0.90, 1.0, macro_t)
		_:
			zoom_gain = lerpf(0.65, 1.0, macro_t)

	var pan := 0.0
	if world_x >= 0.0 and not is_nan(world_x) and not is_inf(world_x):
		var pan_half := maxf(320.0 / clampf(_cam_zoom, 0.65, 6.0), 32.0)
		pan = clampf((world_x - _cam_center_x) / pan_half, -0.75, 0.75)

	var pitch_mul := _rng.randf_range(TUNING_KNOBS["PITCH_JITTER_MIN"], TUNING_KNOBS["PITCH_JITTER_MAX"])
	if k == SfxKind.TERRAFORM or k == SfxKind.CRYSTAL or k == SfxKind.LAVA or k == SfxKind.VORTEX:
		pitch_mul *= 1.0 + 0.16 * _cursor_speed_norm

	_v_active[slot] = 1
	_v_kind[slot] = k
	_v_t[slot] = 0.0
	_v_dur[slot] = dur
	_v_phase[slot] = 0.0
	_v_phase2[slot] = 0.0
	_v_pitch[slot] = pitch_mul
	_v_gain[slot] = zoom_gain
	_v_pan[slot] = pan
	_v_lpf[slot] = 0.0
	_v_bp[slot] = 0.0
	_v_noise_state[slot] = int(_rng.randi() | 1)

	if _audio_supported:
		_audio_unlocked = true
		_pump_audio(AUDIO_CHUNK_SIZE * 2)


func emit_build_pop(world_pos: Vector2) -> void:
	_ensure_initialized()
	play_sfx(SfxKind.BUILD_POP, world_pos.x)
	spawn_burst(
		world_pos,
		int(TUNING_KNOBS["BUILD_POP_DUST_COUNT"]),
		Color(0.82, 0.74, 0.60, 0.72),
		14.0,
		0.38,
		-8.0
	)
	impact_trauma.emit(float(TUNING_KNOBS["BUILD_POP_TRAUMA"]), 0.0)


func step_fx(dt: float) -> void:
	_ensure_initialized()
	var safe_dt := clampf(dt, 0.0, 0.1)
	_drop_flash_budget = 24
	if _biome_scan_timer > 0.0:
		_biome_scan_timer = maxf(0.0, _biome_scan_timer - safe_dt)
	else:
		_scan_visible_biome_audio()
		_biome_scan_timer = 0.50
	_amb_pause_gain = lerpf(_amb_pause_gain, _amb_pause_target, clampf(safe_dt * 8.0, 0.0, 1.0))

	for k in range(SFX_KIND_COUNT):
		if _sfx_cooldown[k] > 0.0:
			_sfx_cooldown[k] = maxf(0.0, _sfx_cooldown[k] - safe_dt)

	var i := 0
	while i < _active_count:
		var age := _p_age[i] + safe_dt
		var life := _p_life[i]
		if age >= life:
			var last := _active_count - 1
			if i != last:
				_copy_particle(last, i)
			_active_count = last
			continue

		_p_age[i] = age
		if _p_mode[i] == MODE_SHOCKWAVE:
			var t := clampf(age / life, 0.0, 1.0)
			var ease_r := 0.18 + 0.82 * (1.0 - pow(1.0 - t, 2.3))
			_p_pos[i] = _p_origin[i] + _p_dir[i] * (_p_max_r[i] * ease_r)
		elif _p_mode[i] == MODE_TRACER:
			_p_pos[i] += _p_vel[i] * safe_dt
		else:
			var vel := _p_vel[i]
			vel.y += _p_gravity[i] * safe_dt
			var drag := exp(-2.4 * safe_dt) if _p_col_idx[i] == P_COL_PUFF else exp(-1.1 * safe_dt)
			vel *= drag
			_p_vel[i] = vel
			_p_pos[i] += vel * safe_dt

		_write_instance_visual(i)
		i += 1

	_mm_particles.multimesh.visible_instance_count = _active_count

	var s_idx := 0
	var strip_drag := exp(-1.4 * safe_dt)
	while s_idx < _s_active_count:
		var s_age := _s_age[s_idx] + safe_dt
		if s_age >= _s_life[s_idx]:
			var s_last := _s_active_count - 1
			if s_idx != s_last:
				_copy_strip(s_last, s_idx)
			_s_active_count = s_last
			continue
		_s_age[s_idx] = s_age
		var s_vel := _s_vel[s_idx] * strip_drag
		_s_vel[s_idx] = s_vel
		_s_pos[s_idx] += s_vel * safe_dt
		_write_strip_visual(s_idx)
		s_idx += 1
	_mm_strips.multimesh.visible_instance_count = _s_active_count

	var tl_idx := 0
	while tl_idx < _tl_count:
		var tl_age := _tl_age[tl_idx] + safe_dt
		if tl_age >= _tl_life[tl_idx]:
			var tl_last := _tl_count - 1
			if tl_idx != tl_last:
				_tl_pos[tl_idx] = _tl_pos[tl_last]
				_tl_rad[tl_idx] = _tl_rad[tl_last]
				_tl_col[tl_idx] = _tl_col[tl_last]
				_tl_intensity[tl_idx] = _tl_intensity[tl_last]
				_tl_age[tl_idx] = _tl_age[tl_last]
				_tl_life[tl_idx] = _tl_life[tl_last]
			_tl_count = tl_last
			continue
		_tl_age[tl_idx] = tl_age
		tl_idx += 1

	if _audio_supported and _audio_unlocked:
		_pump_audio(AUDIO_CHUNK_SIZE * 4)


func _copy_particle(src: int, dst: int) -> void:
	_p_pos[dst] = _p_pos[src]
	_p_vel[dst] = _p_vel[src]
	_p_age[dst] = _p_age[src]
	_p_life[dst] = _p_life[src]
	_p_gravity[dst] = _p_gravity[src]
	_p_size[dst] = _p_size[src]
	_p_aspect[dst] = _p_aspect[src]
	_p_rot[dst] = _p_rot[src]
	_p_hdr[dst] = _p_hdr[src]
	_p_color[dst] = _p_color[src]
	_p_col_idx[dst] = _p_col_idx[src]
	_p_mode[dst] = _p_mode[src]
	_p_origin[dst] = _p_origin[src]
	_p_dir[dst] = _p_dir[src]
	_p_max_r[dst] = _p_max_r[src]


func _write_instance_visual(i: int) -> void:
	var life := maxf(_p_life[i], 0.01)
	var t := clampf(_p_age[i] / life, 0.0, 1.0)
	var remain := 1.0 - t
	var col_idx := _p_col_idx[i]
	var mode := _p_mode[i]

	var scale_x := _p_size[i] * _p_aspect[i]
	var scale_y := _p_size[i]
	var alpha_mult := remain
	var hdr_val := _p_hdr[i]

	if mode == MODE_SHOCKWAVE:
		var ps := _p_size[i] * (1.05 - 0.45 * t)
		scale_x = ps
		scale_y = ps
		alpha_mult = (1.0 - t * t)
		hdr_val *= (1.10 - 0.35 * t)
	elif mode == MODE_TRACER:
		scale_y = _p_size[i] * (1.0 - 0.35 * t)
		alpha_mult = (1.0 - t * t)
		hdr_val *= (1.1 - 0.35 * t)
	elif col_idx == P_COL_PUFF:
		var puff_s := _p_size[i] * (0.38 + 0.24 * t)
		scale_x = puff_s * _p_aspect[i]
		scale_y = puff_s
		alpha_mult = sin(clampf(remain, 0.0, 1.0) * PI * 0.5) * 0.56
	elif col_idx == P_COL_FLASH:
		var flash_s := _p_size[i] * (0.85 + 0.45 * t)
		scale_x = flash_s
		scale_y = flash_s
		alpha_mult = (1.0 - t * t)
		hdr_val *= (1.15 - 0.55 * t)
	else:
		var p_s := _p_size[i] * (1.02 - 0.58 * t)
		scale_x = p_s * _p_aspect[i]
		scale_y = p_s
		alpha_mult = remain * (1.18 - 0.20 * t)
		hdr_val *= (0.55 + 0.45 * remain)

	var xform := Transform2D(_p_rot[i], Vector2(scale_x, scale_y), 0.0, _p_pos[i])
	var c := _p_color[i]
	c.a *= clampf(alpha_mult, 0.0, 1.0)

	var mm := _mm_particles.multimesh
	mm.set_instance_transform_2d(i, xform)
	mm.set_instance_color(i, c)
	mm.set_instance_custom_data(i, Color(hdr_val, remain, 1.0, float(col_idx)))


func _count_active_voices() -> int:
	var n := 0
	for v in range(VOICE_COUNT):
		if _v_active[v] != 0:
			n += 1
	return n


func _pump_audio(max_frames: int) -> void:
	if _audio_player == null or not _audio_unlocked:
		return
	if not _audio_player.playing:
		_audio_player.play()
	var pb_raw := _audio_player.get_stream_playback()
	if pb_raw == null or not (pb_raw is AudioStreamGeneratorPlayback):
		return
	var pb := pb_raw as AudioStreamGeneratorPlayback

	var avail := pb.get_frames_available()
	var pushed := 0
	while avail >= AUDIO_CHUNK_SIZE and pushed < max_frames:
		_was_silent = false
		_fill_audio_chunk()
		pb.push_buffer(_mix_chunk)
		avail -= AUDIO_CHUNK_SIZE
		pushed += AUDIO_CHUNK_SIZE


func _step_ambient_sample(s: int, inv_sr: float, amb_gain: float) -> float:
	if (s & 1) == 0:
		var ns := _amb_noise_state
		ns = (ns ^ (ns << 13)) & 0xFFFFFFFF
		ns = (ns ^ (ns >> 17)) & 0xFFFFFFFF
		ns = (ns ^ (ns << 5)) & 0xFFFFFFFF
		_amb_noise_state = ns | 1
		var white := float((ns & 65535) - 32768) / 32768.0
		_amb_wind_lpf += 0.045 * (white - _amb_wind_lpf)
		_amb_wind_prev = _amb_wind_curr
		_amb_wind_curr = _amb_wind_lpf
	var wind := 0.5 * (_amb_wind_prev + _amb_wind_curr) if (s & 1) != 0 else _amb_wind_curr
	_amb_lfo_ph = fmod(_amb_lfo_ph + TAU * 0.14 * inv_sr, TAU)
	var wind_env := 0.55 + 0.45 * sin(_amb_lfo_ph)
	_amb_drone_ph1 = fmod(_amb_drone_ph1 + TAU * minf(_amb_freq1 - 0.6, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
	_amb_drone_ph2 = fmod(_amb_drone_ph2 + TAU * minf(_amb_freq2 + 0.6, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
	var drone := (sin(_amb_drone_ph1) * 0.62 + sin(_amb_drone_ph2) * 0.38) * 0.42
	return (wind * wind_env * 0.52 * _amb_biome_wind_mul + drone) * amb_gain


func _fill_audio_chunk() -> void:
	var sr: float = TUNING_KNOBS["AUDIO_MIX_RATE"]
	var inv_sr := 1.0 / sr
	_amb_freq1 = lerpf(_amb_freq1, _amb_target_f1 * _amb_biome_f_mul, 0.06)
	_amb_freq2 = lerpf(_amb_freq2, _amb_target_f2 * _amb_biome_f_mul, 0.06)
	_amb_pause_gain = lerpf(_amb_pause_gain, _amb_pause_target, 0.08)
	var active_n := _count_active_voices()
	var macro_t := clampf((_cam_zoom - 1.2) / 3.8, 0.0, 1.0)
	var duck := 0.18 if active_n >= 10 else lerpf(1.0, 0.45, clampf(float(active_n) / 10.0, 0.0, 1.0))
	var amb_gain := lerpf(0.055, 0.032, macro_t) * duck * _amb_pause_gain

	for s in range(AUDIO_CHUNK_SIZE):
		var amb := _step_ambient_sample(s, inv_sr, amb_gain)
		var mix_l := amb
		var mix_r := amb
		for v in range(VOICE_COUNT):
			if _v_active[v] == 0:
				continue
			var t := _v_t[v]
			var dur := _v_dur[v]
			if t >= dur:
				_v_active[v] = 0
				continue
			var sample := _synth_voice_sample(v, t, dur, inv_sr)
			_v_t[v] = t + inv_sr
			var voice_out := sample * _v_gain[v]
			var pan_ang := (_v_pan[v] + 1.0) * (PI * 0.25)
			mix_l += voice_out * (1.41421356 * cos(pan_ang))
			mix_r += voice_out * (1.41421356 * sin(pan_ang))
		_mix_chunk[s] = Vector2(tanh(mix_l * 0.85) * 0.45, tanh(mix_r * 0.85) * 0.45)


func _next_voice_noise(v: int) -> float:
	var ns := _v_noise_state[v]
	ns = (ns ^ (ns << 13)) & 0xFFFFFFFF
	ns = (ns ^ (ns >> 17)) & 0xFFFFFFFF
	ns = (ns ^ (ns << 5)) & 0xFFFFFFFF
	_v_noise_state[v] = ns | 1
	return float((ns & 65535) - 32768) / 32768.0


func _synth_voice_sample(v: int, t: float, dur: float, inv_sr: float) -> float:
	var u := t / dur
	var pitch := _v_pitch[v]
	var kind := _v_kind[v]
	var noise := _next_voice_noise(v)
	if kind <= SfxKind.MUTATE:
		return _synth_env_voice(v, kind, u, t, pitch, noise, inv_sr)
	if kind >= SfxKind.DROP_RAIN:
		return _synth_world_ext_voice(v, kind, u, t, pitch, noise, inv_sr)
	return _synth_combat_ui_voice(v, kind, u, t, pitch, noise, inv_sr)


func _synth_env_voice(v: int, kind: int, u: float, t: float, pitch: float, noise: float, inv_sr: float) -> float:
	var ph := _v_phase[v]
	var ph2 := _v_phase2[v]
	var sample := 0.0
	match kind:
		SfxKind.METEOR:
			var sub_f := minf(lerpf(118.0, 32.0, minf(u * 2.1, 1.0)) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * sub_f * inv_sr, TAU)
			var rc := TAU * (40.0 + 760.0 * exp(-t * 6.0)) * inv_sr
			var lpf := _v_lpf[v] + (rc / (1.0 + rc)) * (noise - _v_lpf[v])
			_v_lpf[v] = lpf
			sample = sin(ph) * exp(-t * 7.5) * 0.65 + lpf * exp(-t * 3.8) * 1.45
		SfxKind.TERRAFORM:
			var f_t := minf(lerpf(320.0, 660.0, u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_t * inv_sr, TAU)
			ph2 = fmod(ph2 + TAU * minf(f_t * 1.5, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
			sample = (sin(ph) * 0.55 + sin(ph2) * 0.25 + noise * 0.08) * sin(u * PI) * exp(-u * 1.6) * 0.48
		SfxKind.CRYSTAL:
			var f_c := minf(lerpf(880.0, 1320.0, u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph2 = fmod(ph2 + TAU * minf(f_c * 2.4, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
			ph = fmod(ph + TAU * f_c * inv_sr, TAU)
			sample = sin(ph + sin(ph2) * 1.3 * exp(-u * 5.0)) * exp(-u * 4.5) * minf(u * 18.0, 1.0) * 0.42
		SfxKind.LAVA:
			var f_l := minf(lerpf(170.0, 72.0, u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_l * inv_sr, TAU)
			var lpf_l := _v_lpf[v] + 0.09 * (noise - _v_lpf[v])
			_v_lpf[v] = lpf_l
			sample = (sin(ph) * 0.35 + lpf_l * (0.45 + 0.55 * (0.5 + 0.5 * sin(t * TAU * 22.0)))) * sin(u * PI) * 0.41
		SfxKind.VORTEX:
			var f_v := minf(lerpf(150.0, 290.0, u) * pitch * (1.0 + 0.14 * sin(t * TAU * 24.0)), MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_v * inv_sr, TAU)
			var lpf_v := _v_lpf[v] + 0.18 * (noise - _v_lpf[v])
			_v_lpf[v] = lpf_v
			sample = (sin(ph) * 0.4 + lpf_v * 0.45) * sin(u * PI) * 0.48
		SfxKind.UI:
			var f_u := minf(lerpf(660.0, 880.0, u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_u * inv_sr, TAU)
			sample = sin(ph) * exp(-u * 4.8) * minf(u * 22.0, 1.0) * 0.36
		SfxKind.BUILD_POP:
			var f_b := minf(lerpf(240.0, 580.0, clampf(t / 0.045, 0.0, 1.0)) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_b * inv_sr, TAU)
			ph2 = fmod(ph2 + TAU * minf(f_b * 2.0, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
			var tri := 1.0 - 4.0 * absf((ph / TAU) - 0.5)
			var env_b := minf(t / 0.003, 1.0) * (1.0 - u) * exp(-maxf(t - 0.035, 0.0) * 30.0)
			var click := sin(ph2) * exp(-t * 95.0) * minf(t / 0.002, 1.0) * 0.22
			sample = (tri * 0.50 + click) * env_b
		SfxKind.SKIRMISH:
			var f_k := minf(lerpf(1180.0, 260.0, pow(u, 0.65)) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_k * inv_sr, TAU)
			var lpf_k := _v_lpf[v] + 0.35 * (noise - _v_lpf[v])
			_v_lpf[v] = lpf_k
			sample = (sin(ph) * 0.45 + lpf_k * 0.24) * exp(-u * 6.0) * minf(t / 0.002, 1.0) * 0.55
		SfxKind.MELTDOWN:
			var sub_m := minf(lerpf(92.0, 26.0, minf(u * 1.6, 1.0)) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * sub_m * inv_sr, TAU)
			ph2 = fmod(ph2 + TAU * minf(lerpf(540.0, 310.0, u) * pitch, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
			var lpf_m := _v_lpf[v] + 0.06 * (noise - _v_lpf[v])
			_v_lpf[v] = lpf_m
			sample = (sin(ph) * 0.62 + lpf_m * 0.85 + sin(ph2) * 0.22 * (0.5 + 0.5 * sin(t * TAU * 12.0))) * exp(-u * 2.6) * minf(t / 0.006, 1.0)
		SfxKind.STORM:
			var f_s := minf(lerpf(210.0, 370.0, sin(u * PI)) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_s * inv_sr, TAU)
			var lpf_s := _v_lpf[v] + (0.08 + 0.14 * sin(u * PI)) * (noise - _v_lpf[v])
			_v_lpf[v] = lpf_s
			sample = (lpf_s * 0.72 * (0.65 + 0.35 * sin(t * TAU * 5.5)) + sin(ph) * 0.26) * sin(u * PI)
		SfxKind.SHUTTLE:
			var f_sh := minf(lerpf(160.0, 740.0, u * u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_sh * inv_sr, TAU)
			ph2 = fmod(ph2 + TAU * minf(f_sh * 1.5, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
			var lpf_sh := _v_lpf[v] + 0.12 * (noise - _v_lpf[v])
			_v_lpf[v] = lpf_sh
			sample = (lpf_sh * 0.52 + (sin(ph) * 0.32 + sin(ph2) * 0.18)) * sin(u * PI) * 0.88
		SfxKind.MUTATE:
			var f_mu := minf(lerpf(480.0, 920.0, u) * pitch * (1.0 + 0.08 * sin(t * TAU * 28.0)), MAX_SYNTH_FREQ_HZ)
			ph2 = fmod(ph2 + TAU * minf(f_mu * 1.73, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
			ph = fmod(ph + TAU * f_mu * inv_sr, TAU)
			sample = sin(ph + sin(ph2) * 1.45 * sin(u * PI)) * exp(-u * 3.2) * minf(t / 0.005, 1.0) * 0.45
	_v_phase[v] = ph
	_v_phase2[v] = ph2
	return sample


func _synth_combat_ui_voice(v: int, kind: int, u: float, t: float, pitch: float, noise: float, inv_sr: float) -> float:
	var ph := _v_phase[v]
	var ph2 := _v_phase2[v]
	var sample := 0.0
	match kind:
		SfxKind.ORBITAL_BEAM:
			if u < 0.24:
				var cu := u / 0.24
				var f_ch := minf(lerpf(180.0, 940.0, cu * cu) * pitch, MAX_SYNTH_FREQ_HZ)
				ph = fmod(ph + TAU * f_ch * inv_sr, TAU)
				ph2 = fmod(ph2 + TAU * minf(f_ch * 1.5, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
				sample = (sin(ph) * 0.65 + sin(ph2) * 0.35) * cu * 0.55
			else:
				var bu := (u - 0.24) / 0.76
				ph = fmod(ph + TAU * minf(lerpf(145.0, 34.0, minf(bu * 1.9, 1.0)) * pitch, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
				ph2 = fmod(ph2 + TAU * minf(lerpf(520.0, 110.0, bu) * pitch, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
				var lpf_o := _v_lpf[v] + 0.14 * (noise - _v_lpf[v])
				_v_lpf[v] = lpf_o
				sample = (sin(ph) * 0.68 + sin(ph2) * 0.22 + lpf_o * 0.46) * exp(-bu * 3.4) * minf(bu * 16.0, 1.0) * 0.92
		SfxKind.SHIELD_DEFLECT:
			var f_sd := minf(lerpf(660.0, 520.0, u * 0.4) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_sd * inv_sr, TAU)
			ph2 = fmod(ph2 + TAU * minf(f_sd * 2.25, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
			var fm_sd := sin(ph2) * (1.25 * exp(-u * 4.5))
			sample = (sin(ph + fm_sd) * 0.58 + sin(ph * 1.5) * 0.28) * (0.78 + 0.22 * sin(t * TAU * 34.0)) * exp(-u * 4.0) * minf(t / 0.003, 1.0) * 0.75
		SfxKind.LASER_LIGHT:
			var f_ll := minf(1380.0 * pow(280.0 / 1380.0, pow(u, 0.72)) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_ll * inv_sr, TAU)
			ph2 = fmod(ph2 + TAU * minf(f_ll * 1.5, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
			var sig_ll := sin(ph + sin(ph2) * (1.15 * exp(-u * 6.5))) + 0.22 * sin(ph * 2.0) * (1.0 - u)
			sample = tanh(sig_ll * 1.25) * exp(-u * 5.2) * minf(t / 0.002, 1.0) * 0.42
		SfxKind.LASER_HEAVY:
			var f_lh := minf(540.0 * pow(90.0 / 540.0, u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_lh * inv_sr, TAU)
			ph2 = fmod(ph2 + TAU * minf(f_lh * 1.7, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
			var click_lh := noise * exp(-t * 140.0) * (1.0 if t < 0.015 else 0.0) * 0.35
			sample = (sin(ph + sin(ph2) * (1.35 * exp(-u * 3.8))) * 0.62 + sin(ph * 0.5) * 0.25) * exp(-u * 3.6) * minf(t / 0.0025, 1.0) * 0.72 + click_lh
		SfxKind.TELEPORT_HUM:
			var f_base := minf(lerpf(110.0, 220.0, u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_base * inv_sr, TAU)
			ph2 = fmod(ph2 + TAU * minf((f_base + 3.0 * pitch), MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
			var svf_f := minf(2.0 * sin(PI * lerpf(1500.0, 480.0, u) * inv_sr), 0.85)
			var lp_th := _v_lpf[v] + svf_f * _v_bp[v]
			var bp_th := _v_bp[v] + svf_f * (noise - lp_th - 0.22 * _v_bp[v])
			_v_lpf[v] = clampf(lp_th, -4.0, 4.0)
			_v_bp[v] = clampf(bp_th, -4.0, 4.0)
			sample = ((sin(ph) + sin(ph2)) * 0.34 + bp_th * 0.26) * sin(u * PI) * minf(t / 0.025, 1.0) * 0.65
		SfxKind.EMP_GLITCH:
			var step_u := floorf(u * 12.0) / 12.0
			var f_eg := minf(lerpf(1320.0, 95.0, step_u) * pitch * (1.0 + 0.18 * sin(t * TAU * 47.0)), MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_eg * inv_sr, TAU)
			ph2 = fmod(ph2 + TAU * minf(f_eg * 2.31, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
			var bit_carrier := tanh(sin(ph) * 1.65)
			var crackle := noise * (1.0 if absf(sin(t * TAU * 29.0)) > 0.72 else 0.15)
			sample = (bit_carrier * sin(ph2) * 0.45 + sin(ph) * 0.30 + crackle * 0.28) * exp(-u * 3.4) * minf(t / 0.002, 1.0) * 0.62
		SfxKind.UI_TAB:
			var f_ut := minf(lerpf(440.0, 587.0, u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_ut * inv_sr, TAU)
			sample = sin(ph) * exp(-u * 4.5) * minf(u * 20.0, 1.0) * 0.34
		SfxKind.UI_PIN:
			ph = fmod(ph + TAU * minf(523.25 * pitch, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
			ph2 = fmod(ph2 + TAU * minf(783.99 * pitch, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
			sample = (sin(ph) * 0.55 + sin(ph2) * 0.45) * exp(-u * 3.8) * minf(u * 18.0, 1.0) * 0.38
		SfxKind.UI_DENIED:
			var f_ud := minf(lerpf(165.0, 110.0, u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_ud * inv_sr, TAU)
			var dbl := 1.0 if (u < 0.38 or u > 0.52) else 0.25
			sample = tanh(sin(ph) * 1.5) * dbl * exp(-u * 3.2) * 0.40
		_:
			var f_def := minf(880.0 * pow(0.125, u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_def * inv_sr, TAU)
			sample = sin(ph) * exp(-u * 5.5) * minf(u * 25.0, 1.0) * 0.36
	_v_phase[v] = ph
	_v_phase2[v] = ph2
	return sample


func _synth_world_ext_voice(v: int, kind: int, u: float, t: float, pitch: float, noise: float, inv_sr: float) -> float:
	var ph := _v_phase[v]
	var ph2 := _v_phase2[v]
	var sample := 0.0
	match kind:
		SfxKind.DROP_RAIN:
			var f_dr := minf(lerpf(620.0, 1180.0, u * u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_dr * inv_sr, TAU)
			sample = (sin(ph) * 0.42 + noise * 0.09) * exp(-u * 5.0) * minf(u * 24.0, 1.0) * 0.32
		SfxKind.DROP_IMPACT:
			var f_di := minf(lerpf(360.0, 145.0, u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_di * inv_sr, TAU)
			sample = (sin(ph) * 0.48 + noise * 0.14 * exp(-u * 6.0)) * exp(-u * 4.6) * minf(t / 0.002, 1.0) * 0.36
		SfxKind.EARTHQUAKE:
			var f_eq := minf(lerpf(68.0, 28.0, u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_eq * inv_sr, TAU)
			var lpf_eq := _v_lpf[v] + 0.045 * (noise - _v_lpf[v])
			_v_lpf[v] = lpf_eq
			sample = (sin(ph) * 0.60 + lpf_eq * 1.15) * sin(u * PI) * 0.85
		SfxKind.VOLCANO_TORNADO:
			var f_vt := minf(lerpf(95.0, 165.0, sin(u * PI)) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_vt * inv_sr, TAU)
			var lpf_vt := _v_lpf[v] + (0.07 + 0.10 * sin(u * PI)) * (noise - _v_lpf[v])
			_v_lpf[v] = lpf_vt
			sample = (sin(ph) * 0.38 + lpf_vt * 0.86) * sin(u * PI) * 0.72
		SfxKind.FOOTSTEP_WORK:
			var f_fw := minf(lerpf(210.0, 110.0, u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_fw * inv_sr, TAU)
			sample = (sin(ph) * 0.34 + noise * 0.16) * exp(-u * 6.2) * minf(t / 0.002, 1.0) * 0.24
		SfxKind.UI_HOVER:
			var f_uh := minf(lerpf(960.0, 1160.0, u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_uh * inv_sr, TAU)
			sample = sin(ph) * exp(-u * 6.5) * minf(u * 20.0, 1.0) * 0.18
		SfxKind.WINDOW_WHOOSH:
			var f_ww := minf(lerpf(280.0, 520.0, u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_ww * inv_sr, TAU)
			ph2 = fmod(ph2 + TAU * minf(f_ww * 1.5, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
			var lpf_ww := _v_lpf[v] + 0.16 * (noise - _v_lpf[v])
			_v_lpf[v] = lpf_ww
			sample = ((sin(ph) * 0.28 + sin(ph2) * 0.14) + lpf_ww * 0.35) * sin(u * PI) * 0.44
		SfxKind.BIT_SCALE_WHOOSH:
			var f_bs := minf(lerpf(340.0, 880.0, u * u) * pitch, MAX_SYNTH_FREQ_HZ)
			ph = fmod(ph + TAU * f_bs * inv_sr, TAU)
			ph2 = fmod(ph2 + TAU * minf(f_bs * 1.25, MAX_SYNTH_FREQ_HZ) * inv_sr, TAU)
			var lpf_bs := _v_lpf[v] + 0.12 * (noise - _v_lpf[v])
			_v_lpf[v] = lpf_bs
			sample = (sin(ph) * 0.32 + sin(ph2) * 0.20 + lpf_bs * 0.22) * sin(u * PI) * 0.46
	_v_phase[v] = ph
	_v_phase2[v] = ph2
	return sample
