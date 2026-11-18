extends Node2D
class_name CombatAndBeams

## Stage 3B pooled beam renderer, city perimeter turrets, orbital strikes,
## and Quantum Gate intercontinental Bezier portal arc system (zero Node2D per shot).

const TELEPORT_ARC_SHADER_PATH := "res://shaders/teleport_arc.gdshader"
const MAGIC_STATE: int = 0x4B434D42
const SAVE_VERSION: int = 6

const TUNING_KNOBS := {
	"MAX_BEAMS": 256,
	"MAX_ARCS": 32,
	"MAX_CITIES": 64,
	"BEAM_HDR_CAP": 2.95,
	"BEAM_DECAY_RATE": 11.5,
	"BEAM_HEAVY_DECAY_RATE": 7.5,
	"ARC_DURATION_SEC": 2.4,
	"ARC_HOLD_SEC": 0.65,
	"ARC_DECAY_RATE": 2.2,
	"ARC_RIBBON_HALF_W": 5.5,
	"ARC_SEGMENTS": 16,
	"ARC_LIFT_MIN_PX": 75.0,
	"ARC_LIFT_MAX_PX": 150.0,
	"ARC_LIFT_RATIO": 0.42,
	"ARC_PULSE_FREQ": 2.6,
	"TURRET_INTERVAL_SEC": 1.25,
	"TURRET_MISS_COOLDOWN_SEC": 0.28,
	"TURRET_RANGE_PX": 46.0,
	"TURRET_RANGE_PER_TIER_PX": 2.0,
	"TURRET_ENERGY_COST": 4.0,
	"TURRET_DAMAGE": 24.0,
	"TURRET_DAMAGE_PER_TIER": 4.0,
	"PORTAL_INTERVAL_SEC": 4.0,
	"PORTAL_ENERGY_COST": 14.0,
	"PORTAL_PEACE_ENERGY_MARGIN": 35.0,
	"PORTAL_MIN_DIST_PX": 32.0,
	"ORBITAL_SKY_HEIGHT_PX": 240.0,
	"ORBITAL_RING_SEGS": 12,
	"ORBITAL_DAMAGE": 110.0,
	"ORBITAL_BURN": 0.85,
	"ORBITAL_IMPULSE": 95.0,
	"ORBITAL_TRAUMA": 0.42,
	"ORBITAL_HIT_STOP": 0.045,
	"ORBITAL_INTERCEPT_TRAUMA": 0.15,
	"MAX_STEP_LIGHTS": 64,
}

const MAX_BEAMS: int = 256
const MAX_ARCS: int = 32
const MAX_CITIES: int = 64
const MAX_PROJECTILES: int = 192

enum ProjKind { PLASMA = 0, BOLT = 1, GRENADE = 2, SHARD = 3 }

const DIPLO_NEUTRAL: int = 0
const DIPLO_PACT: int = 1
const DIPLO_TOTAL_WAR: int = 2
const DIPLO_REBELLION: int = 3

const FACTION_MUTANT: int = 3
const STRIP_PORTAL: int = 11

const COL_HUMAN := Color("#48F5FF")
const COL_ROBOT := Color("#FF3838")
const COL_SPORE := Color("#62FF7A")
const COL_REBEL := Color("#FFE156")
const COL_ORBITAL_CORE := Color("#FFD466")
const COL_ORBITAL_INTERCEPT_CORE := Color("#78F4FF")
const COL_ORBITAL_SHEATH := Color("#FF8E24")
const COL_ORBITAL_RING := Color("#FFD466")
const COL_PORTAL_VIOLET := Color("#B56BFF")
const COL_PORTAL_CYAN := Color("#62ECFF")

signal impact_trauma(trauma: float, hit_stop_sec: float)

var _world: Node2D
var _physics: Node2D
var _civ: Node2D
var _fx: Node2D

var _initialized: bool = false
var _mm_beams: MultiMeshInstance2D
var _mm_teleport_arcs: MultiMeshInstance2D
var _mm_projectiles: MultiMeshInstance2D
var _beam_mesh: ArrayMesh
var _arc_mesh: ArrayMesh
var _proj_mesh: ArrayMesh
var _beam_mat: CanvasItemMaterial
var _arc_mat: ShaderMaterial
var _proj_mat: CanvasItemMaterial

# Preallocated beam pool (SoA, zero GC)
var _beam_count: int = 0
var _beam_src: PackedVector2Array
var _beam_dst: PackedVector2Array
var _beam_color: PackedColorArray
var _beam_width: PackedFloat32Array
var _beam_hdr: PackedFloat32Array
var _beam_alpha: PackedFloat32Array
var _beam_rate: PackedFloat32Array

# Preallocated 3D ballistic projectile pool (SoA, zero GC)
var _proj_count: int = 0
var _proj_px: PackedFloat32Array
var _proj_py: PackedFloat32Array
var _proj_pz: PackedFloat32Array
var _proj_vx: PackedFloat32Array
var _proj_vy: PackedFloat32Array
var _proj_vz: PackedFloat32Array
var _proj_grav: PackedFloat32Array
var _proj_kind: PackedByteArray
var _proj_dmg: PackedFloat32Array
var _proj_owner: PackedInt32Array
var _proj_color: PackedColorArray
var _projectiles_fired: int = 0
var _proj_was_vis: bool = false
var _proj_fx_cd: float = 0.0

# Preallocated Bezier portal arc pool (SoA, zero GC)
var _arc_count: int = 0
var _arc_src: PackedVector2Array
var _arc_dst: PackedVector2Array
var _arc_color: PackedColorArray
var _arc_age: PackedFloat32Array
var _arc_dur: PackedFloat32Array
var _arc_alpha: PackedFloat32Array
var _arc_lift: PackedFloat32Array
var _arc_phase: PackedFloat32Array
var _arc_pulse: PackedFloat32Array

# Combat loop state & stats
var _city_turret_cd: PackedFloat32Array
var _portal_timer: float = 0.0
var _sim_time: float = 0.0
var _phase_cursor: float = 0.0

var _beams_fired: int = 0
var _portal_transfers: int = 0
var _turret_shots: int = 0
var _orbital_strikes: int = 0

var _sim_pace_mult: float = 1.0
var _law_diplomacy_wars: bool = true
var _law_rebellions: bool = true
var _law_disasters: bool = true
var _has_get_gates: bool = false
var _has_fauna_cnt: bool = false
var _cur_has_fauna: bool = false
var _turret_raw_cd: float = 0.0
var _turret_pace_acc: float = 0.0
var _portal_raw_cd: float = 0.0
var _portal_pace_acc: float = 0.0


func _ready() -> void:
	_ensure_initialized()


func _exit_tree() -> void:
	if _mm_beams != null:
		_mm_beams.multimesh = null
		_mm_beams.material = null
		_mm_beams = null
	if _mm_teleport_arcs != null:
		_mm_teleport_arcs.multimesh = null
		_mm_teleport_arcs.material = null
		_mm_teleport_arcs = null
	if _mm_projectiles != null:
		_mm_projectiles.multimesh = null
		_mm_projectiles.material = null
		_mm_projectiles = null
	_beam_mesh = null
	_arc_mesh = null
	_proj_mesh = null
	_beam_mat = null
	_arc_mat = null
	_proj_mat = null
	_world = null
	_physics = null
	_civ = null
	_fx = null


func bind_systems(world: Node2D, physics: Node2D, civ: Node2D) -> void:
	_ensure_initialized()
	_world = world
	_physics = physics
	_civ = civ
	_has_get_gates = (_civ != null and _civ.has_method("get_quantum_gates"))
	_has_fauna_cnt = (_physics != null and _physics.has_method("get_fauna_count"))
	if _fx == null:
		_fx = get_node_or_null("../FxAudio") as Node2D


func set_sim_pace(mult: float) -> void:
	_sim_pace_mult = clampf(mult, 0.05, 50.0)


func set_world_laws(laws: Dictionary) -> void:
	if laws.has("diplomacy_wars"):
		_law_diplomacy_wars = bool(laws["diplomacy_wars"])
	if laws.has("rebellions"):
		_law_rebellions = bool(laws["rebellions"])
	if laws.has("disasters"):
		_law_disasters = bool(laws["disasters"])


func push_lights_to_fx(fx: Node2D) -> void:
	_fx = fx
	if fx == null or not fx.has_method("push_light"):
		return
	var cap: int = int(TUNING_KNOBS["MAX_STEP_LIGHTS"])
	var pushed: int = 0

	for i in range(_arc_count):
		if pushed >= cap:
			break
		var alpha: float = _arc_alpha[i]
		if alpha <= 0.04:
			continue
		var col: Color = _arc_color[i]
		var s: Vector2 = _arc_src[i]
		var d: Vector2 = _arc_dst[i]
		var delta: Vector2 = d - s
		var angle: float = delta.angle()
		var y_axis := Vector2(-sin(angle), cos(angle))
		var mid: Vector2 = (s + d) * 0.5 - y_axis * _arc_lift[i]
		var inten: float = clampf(1.35 * alpha, 0.0, 2.2)
		fx.push_light(s, 30.0, col, inten)
		fx.push_light(mid, 38.0, col, inten * 0.92)
		fx.push_light(d, 30.0, col, inten)
		pushed += 3

	for b in range(_beam_count):
		if pushed >= cap:
			break
		var b_alpha: float = _beam_alpha[b]
		if b_alpha <= 0.06:
			continue
		var w: float = _beam_width[b]
		if w < 1.8 and (b & 1) == 1:
			continue
		var mid_b: Vector2 = (_beam_src[b] + _beam_dst[b]) * 0.5
		var rad: float = clampf(14.0 + w * 4.5, 16.0, 62.0)
		var b_inten: float = clampf(b_alpha * (1.55 if w >= 3.0 else 0.95), 0.1, 2.2)
		fx.push_light(_beam_dst[b], rad, _beam_color[b], b_inten)
		pushed += 1
		if w >= 4.0 and pushed < cap:
			fx.push_light(mid_b, rad * 0.85, _beam_color[b], b_inten * 0.8)
			pushed += 1

	for p in range(_proj_count):
		if pushed >= cap:
			break
		var pk := int(_proj_kind[p])
		if pk == ProjKind.BOLT and (p & 1) == 1:
			continue
		var p_pos := Vector2(_proj_px[p], _proj_py[p] - _proj_pz[p])
		fx.push_light(p_pos, 18.0 if pk == ProjKind.GRENADE else 14.0, _proj_color[p], 0.95)
		pushed += 1


func step_combat(dt: float) -> void:
	_ensure_initialized()
	var safe_dt: float = clampf(dt, 0.0, 0.1)
	_sim_time += safe_dt
	_proj_fx_cd = maxf(0.0, _proj_fx_cd - safe_dt)
	_turret_raw_cd = maxf(0.0, _turret_raw_cd - safe_dt)
	_portal_raw_cd = maxf(0.0, _portal_raw_cd - safe_dt)

	var pace_dt: float = safe_dt * clampf(_sim_pace_mult, 0.05, 80.0)
	_turret_pace_acc += pace_dt
	_portal_pace_acc += pace_dt
	_update_beams(safe_dt)
	_update_arcs(safe_dt)
	if _proj_count > 0:
		_update_projectiles(pace_dt)
	_pull_unit_beams()
	_pull_unit_projectiles()
	_step_city_turrets(pace_dt)
	_step_quantum_gates(pace_dt)

	_sync_beam_multimesh()
	_sync_arc_multimesh()
	if _proj_count > 0 or _proj_was_vis:
		_sync_projectile_multimesh()


func step_visual_fade(dt: float) -> void:
	_ensure_initialized()
	var safe_dt: float = clampf(dt, 0.0, 0.1)
	if safe_dt <= 0.0:
		return
	_update_beams(safe_dt)
	_update_arcs(safe_dt)
	_sync_beam_multimesh()
	_sync_arc_multimesh()
	if _proj_count > 0 or _proj_was_vis:
		_sync_projectile_multimesh()


func fire_orbital_strike(world_pos: Vector2, radius: float) -> Dictionary:
	_ensure_initialized()
	var safe_r: float = clampf(radius, 4.0, 64.0)
	var goals: Dictionary = _civ.get_goal_buffers() if (_civ != null and _civ.has_method("get_goal_buffers")) else {}

	var intercepted: bool = false
	var pylon_pos: Vector2 = world_pos
	var shield_r: float = 48.0
	var stop_pos: Vector2 = world_pos

	if _civ != null and _civ.has_method("try_intercept_orbital_impact"):
		var intercept_res: Variant = _civ.try_intercept_orbital_impact(world_pos, safe_r)
		if intercept_res is Dictionary:
			var intercept_dict: Dictionary = intercept_res
			intercepted = bool(intercept_dict.get("intercepted", false))
			if intercepted:
				pylon_pos = Vector2(intercept_dict.get("pylon_pos", world_pos))
				shield_r = maxf(float(intercept_dict.get("radius", 48.0)), 18.0)
				var diff: Vector2 = world_pos - pylon_pos
				if diff.length_squared() > 1.0:
					stop_pos = pylon_pos + diff.normalized() * minf(diff.length(), shield_r * 0.92)
				else:
					stop_pos = pylon_pos + Vector2(0.0, -shield_r * 0.7)

	var sky_y: float = maxf(stop_pos.y - float(TUNING_KNOBS["ORBITAL_SKY_HEIGHT_PX"]), -96.0)
	var sky_pos := Vector2(stop_pos.x, sky_y)
	var spawned_beams: int = 0

	if intercepted:
		_spawn_beam(sky_pos, stop_pos, COL_HUMAN, clampf(safe_r * 0.45, 3.0, 8.0), 1.25, 8.2)
		_spawn_beam(sky_pos, stop_pos, COL_ORBITAL_INTERCEPT_CORE, clampf(safe_r * 0.18, 1.5, 3.5), 2.85, 10.5)
		spawned_beams += 2
		if _world != null and _world.has_method("apply_orbital_strike"):
			_world.apply_orbital_strike(world_pos, safe_r, true)
		if _fx != null:
			if _fx.has_method("emit_shield_deflect"):
				_fx.emit_shield_deflect(pylon_pos, shield_r, stop_pos)
			if _fx.has_method("play_sfx"):
				_fx.play_sfx("orbital_beam", stop_pos.x)
		_beams_fired += 1
		_orbital_strikes += 1
		_sync_beam_multimesh()
		impact_trauma.emit(float(TUNING_KNOBS["ORBITAL_INTERCEPT_TRAUMA"]), 0.0)
		return {"beams": spawned_beams, "hits": 0, "intercepted": true}

	# Unintercepted amber-gold orbital plasma beam + tinted core (capped under AgX white=6.0)
	_spawn_beam(sky_pos, world_pos, COL_ORBITAL_SHEATH, clampf(safe_r * 0.85, 6.0, 18.0), 1.25, 5.6)
	_spawn_beam(sky_pos, world_pos, COL_ORBITAL_CORE, clampf(safe_r * 0.34, 2.5, 7.0), 2.95, 7.8)
	spawned_beams += 2

	if _world != null:
		if _world.has_method("apply_orbital_strike"):
			_world.apply_orbital_strike(world_pos, safe_r, false)
		elif _world.has_method("apply_brush"):
			_world.apply_brush(world_pos, 3, int(roundf(safe_r)))
	if _civ != null and _civ.has_method("on_terrain_damaged"):
		_civ.on_terrain_damaged(world_pos, safe_r)

	if _physics != null and not _physics.has_method("apply_external_damage") and _physics.has_method("trigger_impulse"):
		_physics.trigger_impulse(world_pos, maxf(safe_r * 1.45, 22.0), float(TUNING_KNOBS["ORBITAL_IMPULSE"]), false)

	var hits: int = _damage_units(
		world_pos,
		maxf(safe_r * 1.15, 10.0),
		float(TUNING_KNOBS["ORBITAL_DAMAGE"]),
		float(TUNING_KNOBS["ORBITAL_BURN"]),
		-1,
		-1,
		goals
	)

	if _fx != null:
		if _fx.has_method("play_sfx"):
			_fx.play_sfx("orbital_beam", world_pos.x)
			_fx.play_sfx("laser_heavy", world_pos.x)
		if _fx.has_method("spawn_shockwave"):
			_fx.spawn_shockwave(world_pos, maxf(safe_r * 1.45, 24.0), COL_ORBITAL_RING, 0.36)
		if _fx.has_method("spawn_burst"):
			_fx.spawn_burst(world_pos, 16, Color("#2B2E36"), 36.0, 0.65, -18.0)
			_fx.spawn_burst(world_pos, 14, COL_ORBITAL_RING, 58.0, 0.38, 36.0)

	_beams_fired += 1
	_orbital_strikes += 1
	_sync_beam_multimesh()
	impact_trauma.emit(float(TUNING_KNOBS["ORBITAL_TRAUMA"]), float(TUNING_KNOBS["ORBITAL_HIT_STOP"]))
	return {"beams": spawned_beams, "hits": hits, "intercepted": false}


func transfer_squad_portal(src_pos: Vector2, dst_pos: Vector2, city_id: int) -> int:
	_ensure_initialized()
	if _physics == null or not _physics.has_method("transfer_squad_portal"):
		return 0
	var transferred: int = int(_physics.transfer_squad_portal(src_pos, dst_pos, city_id))
	if transferred > 0:
		_portal_transfers += transferred
		var fac_col: Color = _resolve_city_color(city_id)
		var arc_col: Color = fac_col.lerp(COL_PORTAL_VIOLET, 0.58)
		_spawn_teleport_arc(src_pos, dst_pos, arc_col)
		if _fx != null:
			if _fx.has_method("spawn_reaction_strip"):
				_fx.spawn_reaction_strip(src_pos + Vector2(0.0, -8.0), STRIP_PORTAL)
				_fx.spawn_reaction_strip(dst_pos + Vector2(0.0, -8.0), STRIP_PORTAL)
			if _fx.has_method("spawn_burst"):
				_fx.spawn_burst(src_pos, 6, COL_PORTAL_VIOLET, 24.0, 0.30, -8.0)
				_fx.spawn_burst(dst_pos, 8, COL_PORTAL_CYAN, 28.0, 0.34, -8.0)
			if _fx.has_method("play_sfx"):
				_fx.play_sfx("teleport_hum", (src_pos.x + dst_pos.x) * 0.5)
		_sync_arc_multimesh()
	return transferred


func get_combat_stats() -> Dictionary:
	return {
		"beams_fired": _beams_fired,
		"active_beams": _beam_count,
		"portal_transfers": _portal_transfers,
		"active_arcs": _arc_count,
		"turret_shots": _turret_shots,
		"orbital_strikes": _orbital_strikes,
		"active_projectiles": _proj_count,
		"projectiles_fired": _projectiles_fired,
	}


func get_projectile_count() -> int:
	return _proj_count


func spawn_ballistic_projectile(src_dst: Rect2, kind_and_dmg: Vector2, owner_fac: int = -1) -> void:
	_ensure_initialized()
	var src: Vector2 = src_dst.position
	var dst: Vector2 = src_dst.size
	var kind: int = clampi(int(kind_and_dmg.x), 0, 3)
	var dmg: float = maxf(kind_and_dmg.y, 1.0)
	var dist: float = src.distance_to(dst)
	var spd: float = 115.0 if (kind == ProjKind.BOLT or kind == ProjKind.SHARD) else (65.0 if kind == ProjKind.GRENADE else 88.0)
	var grav: float = 145.0 if kind == ProjKind.GRENADE else (110.0 if (kind == ProjKind.BOLT or kind == ProjKind.SHARD) else 125.0)
	var min_t: float = 0.35 if kind == ProjKind.GRENADE else 0.18
	var max_t: float = 1.80 if kind == ProjKind.GRENADE else 1.35
	var t_flight: float = clampf(dist / maxf(spd, 10.0), min_t, max_t)
	var slot: int = _proj_count
	if slot >= MAX_PROJECTILES:
		slot = 0
	else:
		_proj_count += 1
	_proj_px[slot] = src.x
	_proj_py[slot] = src.y
	_proj_pz[slot] = 3.5
	_proj_vx[slot] = (dst.x - src.x) / t_flight
	_proj_vy[slot] = (dst.y - src.y) / t_flight
	_proj_vz[slot] = 0.5 * grav * t_flight
	_proj_grav[slot] = grav
	_proj_kind[slot] = kind
	_proj_dmg[slot] = dmg
	_proj_owner[slot] = owner_fac
	var col: Color = Color(1.0, 0.52, 0.22, 1.0)
	if kind == ProjKind.GRENADE:
		col = Color(1.0, 0.56, 0.18, 1.0)
	elif kind == ProjKind.SHARD:
		col = Color(0.86, 0.44, 1.0, 1.0)
	elif owner_fac == 0:
		col = COL_HUMAN
	elif owner_fac == 1:
		col = COL_ROBOT
	elif owner_fac == 2:
		col = COL_SPORE
	_proj_color[slot] = col
	_projectiles_fired += 1


func get_save_state() -> Dictionary:
	return {"version": SAVE_VERSION, "blob": pack_state()}


func load_save_state(state: Variant) -> bool:
	if state is PackedByteArray:
		return unpack_state(state as PackedByteArray)
	if state is Dictionary and (state as Dictionary).has("blob"):
		var b: Variant = (state as Dictionary)["blob"]
		if b is PackedByteArray:
			return unpack_state(b as PackedByteArray)
	return false


func pack_state() -> PackedByteArray:
	_ensure_initialized()
	var spb := StreamPeerBuffer.new()
	spb.put_32(MAGIC_STATE)
	spb.put_16(SAVE_VERSION)
	spb.put_64(_beams_fired)
	spb.put_64(_portal_transfers)
	spb.put_64(_turret_shots)
	spb.put_64(_orbital_strikes)
	spb.put_float(_portal_timer)
	spb.put_float(_sim_time)

	spb.put_u16(MAX_CITIES)
	for cid in range(MAX_CITIES):
		spb.put_float(_city_turret_cd[cid])

	spb.put_u16(_arc_count)
	for a in range(_arc_count):
		spb.put_float(_arc_src[a].x)
		spb.put_float(_arc_src[a].y)
		spb.put_float(_arc_dst[a].x)
		spb.put_float(_arc_dst[a].y)
		var c: Color = _arc_color[a]
		spb.put_float(c.r)
		spb.put_float(c.g)
		spb.put_float(c.b)
		spb.put_float(c.a)
		spb.put_float(_arc_age[a])
		spb.put_float(_arc_dur[a])
		spb.put_float(_arc_alpha[a])
		spb.put_float(_arc_lift[a])
		spb.put_float(_arc_phase[a])
		spb.put_float(_arc_pulse[a])

	spb.put_u16(_beam_count)
	for b in range(_beam_count):
		spb.put_float(_beam_src[b].x)
		spb.put_float(_beam_src[b].y)
		spb.put_float(_beam_dst[b].x)
		spb.put_float(_beam_dst[b].y)
		var bc: Color = _beam_color[b]
		spb.put_float(bc.r)
		spb.put_float(bc.g)
		spb.put_float(bc.b)
		spb.put_float(bc.a)
		spb.put_float(_beam_width[b])
		spb.put_float(_beam_hdr[b])
		spb.put_float(_beam_alpha[b])
		spb.put_float(_beam_rate[b])

	_pack_projectiles(spb)
	return spb.data_array


func _pack_projectiles(spb: StreamPeerBuffer) -> void:
	spb.put_64(_projectiles_fired)
	spb.put_u16(_proj_count)
	for p in range(_proj_count):
		spb.put_float(_proj_px[p])
		spb.put_float(_proj_py[p])
		spb.put_float(_proj_pz[p])
		spb.put_float(_proj_vx[p])
		spb.put_float(_proj_vy[p])
		spb.put_float(_proj_vz[p])
		spb.put_float(_proj_grav[p])
		spb.put_u8(_proj_kind[p])
		spb.put_float(_proj_dmg[p])
		spb.put_32(_proj_owner[p])
		var pc: Color = _proj_color[p]
		spb.put_float(pc.r)
		spb.put_float(pc.g)
		spb.put_float(pc.b)
		spb.put_float(pc.a)


func unpack_state(raw: PackedByteArray) -> bool:
	_ensure_initialized()
	if raw.size() < 42:
		return false
	var spb := StreamPeerBuffer.new()
	spb.data_array = raw
	spb.seek(0)
	if spb.get_32() != MAGIC_STATE:
		return false
	var ver: int = spb.get_16()
	if ver != 5 and ver != SAVE_VERSION:
		return false

	_beams_fired = spb.get_64()
	_portal_transfers = spb.get_64()
	_turret_shots = spb.get_64()
	_orbital_strikes = spb.get_64()
	_portal_timer = spb.get_float()
	_sim_time = spb.get_float()

	var cd_count: int = spb.get_u16()
	_city_turret_cd.fill(0.0)
	for cid in range(cd_count):
		var v: float = spb.get_float()
		if cid < MAX_CITIES:
			_city_turret_cd[cid] = maxf(v, 0.0)

	_arc_count = 0
	if spb.get_position() + 2 <= spb.get_size():
		var saved_arcs: int = mini(spb.get_u16(), MAX_ARCS)
		for a in range(saved_arcs):
			if spb.get_position() + 56 > spb.get_size():
				break
			var sx: float = spb.get_float()
			var sy: float = spb.get_float()
			var dx: float = spb.get_float()
			var dy: float = spb.get_float()
			var cr: float = spb.get_float()
			var cg: float = spb.get_float()
			var cb: float = spb.get_float()
			var ca: float = spb.get_float()
			var age: float = spb.get_float()
			var dur: float = spb.get_float()
			var alpha: float = spb.get_float()
			var lift: float = spb.get_float()
			var phase: float = spb.get_float()
			var pulse: float = spb.get_float()
			_arc_src[a] = Vector2(sx, sy)
			_arc_dst[a] = Vector2(dx, dy)
			_arc_color[a] = Color(cr, cg, cb, ca)
			_arc_age[a] = age
			_arc_dur[a] = maxf(dur, 0.1)
			_arc_alpha[a] = clampf(alpha, 0.0, 1.0)
			_arc_lift[a] = lift
			_arc_phase[a] = phase
			_arc_pulse[a] = pulse
			_arc_count += 1

	_beam_count = 0
	if spb.get_position() + 2 <= spb.get_size():
		var saved_beams: int = mini(spb.get_u16(), MAX_BEAMS)
		for b in range(saved_beams):
			if spb.get_position() + 48 > spb.get_size():
				break
			var bsx: float = spb.get_float()
			var bsy: float = spb.get_float()
			var bdx: float = spb.get_float()
			var bdy: float = spb.get_float()
			var bcr: float = spb.get_float()
			var bcg: float = spb.get_float()
			var bcb: float = spb.get_float()
			var bca: float = spb.get_float()
			var bw: float = spb.get_float()
			var bhdr: float = spb.get_float()
			var balpha: float = spb.get_float()
			var brate: float = spb.get_float()
			_beam_src[b] = Vector2(bsx, bsy)
			_beam_dst[b] = Vector2(bdx, bdy)
			_beam_color[b] = Color(bcr, bcg, bcb, bca)
			_beam_width[b] = bw
			_beam_hdr[b] = bhdr
			_beam_alpha[b] = clampf(balpha, 0.0, 1.0)
			_beam_rate[b] = maxf(brate, 0.5)
			_beam_count += 1

	if ver >= 6:
		_unpack_projectiles(spb)
	else:
		_proj_count = 0
		_projectiles_fired = 0

	_sync_beam_multimesh()
	_sync_arc_multimesh()
	_sync_projectile_multimesh()
	return true


func _unpack_projectiles(spb: StreamPeerBuffer) -> void:
	_proj_count = 0
	_projectiles_fired = 0
	if spb.get_position() + 10 > spb.get_size():
		return
	_projectiles_fired = spb.get_64()
	var saved_p: int = mini(spb.get_u16(), MAX_PROJECTILES)
	for p in range(saved_p):
		if spb.get_position() + 53 > spb.get_size():
			break
		_proj_px[p] = spb.get_float()
		_proj_py[p] = spb.get_float()
		_proj_pz[p] = spb.get_float()
		_proj_vx[p] = spb.get_float()
		_proj_vy[p] = spb.get_float()
		_proj_vz[p] = spb.get_float()
		_proj_grav[p] = maxf(spb.get_float(), 10.0)
		_proj_kind[p] = spb.get_u8()
		_proj_dmg[p] = spb.get_float()
		_proj_owner[p] = spb.get_32()
		_proj_color[p] = Color(spb.get_float(), spb.get_float(), spb.get_float(), spb.get_float())
		_proj_count += 1


func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_init_pools()
	_init_beam_multimesh()
	_init_arc_multimesh()
	_init_projectile_multimesh()


func _init_pools() -> void:
	_beam_src.resize(MAX_BEAMS)
	_beam_dst.resize(MAX_BEAMS)
	_beam_color.resize(MAX_BEAMS)
	_beam_width.resize(MAX_BEAMS)
	_beam_hdr.resize(MAX_BEAMS)
	_beam_alpha.resize(MAX_BEAMS)
	_beam_rate.resize(MAX_BEAMS)

	_arc_src.resize(MAX_ARCS)
	_arc_dst.resize(MAX_ARCS)
	_arc_color.resize(MAX_ARCS)
	_arc_age.resize(MAX_ARCS)
	_arc_dur.resize(MAX_ARCS)
	_arc_alpha.resize(MAX_ARCS)
	_arc_lift.resize(MAX_ARCS)
	_arc_phase.resize(MAX_ARCS)
	_arc_pulse.resize(MAX_ARCS)

	_proj_px.resize(MAX_PROJECTILES)
	_proj_py.resize(MAX_PROJECTILES)
	_proj_pz.resize(MAX_PROJECTILES)
	_proj_vx.resize(MAX_PROJECTILES)
	_proj_vy.resize(MAX_PROJECTILES)
	_proj_vz.resize(MAX_PROJECTILES)
	_proj_grav.resize(MAX_PROJECTILES)
	_proj_kind.resize(MAX_PROJECTILES)
	_proj_dmg.resize(MAX_PROJECTILES)
	_proj_owner.resize(MAX_PROJECTILES)
	_proj_color.resize(MAX_PROJECTILES)

	_city_turret_cd.resize(MAX_CITIES)
	for cid in range(MAX_CITIES):
		_city_turret_cd[cid] = float(cid % 5) * 0.05


func _build_beam_mesh() -> ArrayMesh:
	# Crisp 4-segment tapered plasma beam along x in [0, 1], y in [-0.5, +0.5]
	# with luminous spine (alpha=1.0 at y=0) tapering cleanly at emitter & tip.
	var xs := PackedFloat32Array([0.0, 0.12, 0.55, 0.88, 1.0])
	var half_ws := PackedFloat32Array([0.08, 0.50, 0.44, 0.30, 0.04])

	var verts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var indices := PackedInt32Array()

	for k in range(xs.size()):
		var x: float = xs[k]
		var hw: float = half_ws[k]
		verts.append(Vector2(x, -hw))
		uvs.append(Vector2(x, 0.0))
		cols.append(Color(1.0, 1.0, 1.0, 0.08))

		verts.append(Vector2(x, 0.0))
		uvs.append(Vector2(x, 0.5))
		cols.append(Color(1.0, 1.0, 1.0, 1.0))

		verts.append(Vector2(x, hw))
		uvs.append(Vector2(x, 1.0))
		cols.append(Color(1.0, 1.0, 1.0, 0.08))

	for seg in range(xs.size() - 1):
		var base0: int = seg * 3
		var base1: int = (seg + 1) * 3
		# Upper ribbon strip
		indices.append(base0 + 0)
		indices.append(base1 + 0)
		indices.append(base1 + 1)
		indices.append(base0 + 0)
		indices.append(base1 + 1)
		indices.append(base0 + 1)
		# Lower ribbon strip
		indices.append(base0 + 1)
		indices.append(base1 + 1)
		indices.append(base1 + 2)
		indices.append(base0 + 1)
		indices.append(base1 + 2)
		indices.append(base0 + 2)

	var arrays: Array = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = verts
	arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
	arrays[ArrayMesh.ARRAY_COLOR] = cols
	arrays[ArrayMesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.custom_aabb = AABB(Vector3(-0.2, -2.0, -1.0), Vector3(1.4, 4.0, 2.0))
	return mesh


func _build_arc_strip_mesh() -> ArrayMesh:
	var segs: int = int(TUNING_KNOBS["ARC_SEGMENTS"])
	var half_w: float = float(TUNING_KNOBS["ARC_RIBBON_HALF_W"])
	var verts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for s in range(segs + 1):
		var u: float = float(s) / float(segs)
		verts.append(Vector2(u, -half_w))
		uvs.append(Vector2(u, 0.0))
		verts.append(Vector2(u, half_w))
		uvs.append(Vector2(u, 1.0))

	for s in range(segs):
		var b0: int = s * 2
		var b1: int = (s + 1) * 2
		indices.append(b0 + 0)
		indices.append(b1 + 0)
		indices.append(b1 + 1)
		indices.append(b0 + 0)
		indices.append(b1 + 1)
		indices.append(b0 + 1)

	var arrays: Array = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = verts
	arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
	arrays[ArrayMesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# Generously pad vertical AABB so high-lift quadratic Bezier arches (75..150 px) never frustum-cull
	mesh.custom_aabb = AABB(Vector3(-0.2, -220.0, -1.0), Vector3(1.4, 440.0, 2.0))
	return mesh


func _init_beam_multimesh() -> void:
	_beam_mesh = _build_beam_mesh()
	_beam_mat = CanvasItemMaterial.new()
	_beam_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_beam_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

	_mm_beams = MultiMeshInstance2D.new()
	_mm_beams.name = "CombatBeamsPool"
	_mm_beams.material = _beam_mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.use_custom_data = false
	mm.mesh = _beam_mesh
	mm.instance_count = MAX_BEAMS
	mm.visible_instance_count = 0
	mm.custom_aabb = AABB(Vector3(-128.0, -320.0, -1.0), Vector3(1536.0, 1152.0, 2.0))
	_mm_beams.multimesh = mm
	add_child(_mm_beams)


func _init_arc_multimesh() -> void:
	_arc_mesh = _build_arc_strip_mesh()
	_arc_mat = ShaderMaterial.new()
	if ResourceLoader.exists(TELEPORT_ARC_SHADER_PATH):
		var sh: Resource = load(TELEPORT_ARC_SHADER_PATH)
		if sh is Shader:
			_arc_mat.shader = sh

	_mm_teleport_arcs = MultiMeshInstance2D.new()
	_mm_teleport_arcs.name = "TeleportArcsPool"
	_mm_teleport_arcs.material = _arc_mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = _arc_mesh
	mm.instance_count = MAX_ARCS
	mm.visible_instance_count = 0
	mm.custom_aabb = AABB(Vector3(-128.0, -320.0, -1.0), Vector3(1536.0, 1152.0, 2.0))
	_mm_teleport_arcs.multimesh = mm
	add_child(_mm_teleport_arcs)


func _build_proj_mesh() -> ArrayMesh:
	var verts := PackedVector2Array([Vector2.ZERO])
	var cols := PackedColorArray([Color.WHITE])
	var indices := PackedInt32Array()
	var segs: int = 8
	for k in range(segs):
		var ang: float = TAU * float(k) / float(segs)
		verts.append(Vector2(cos(ang) * 0.5, sin(ang) * 0.5))
		cols.append(Color(1.0, 1.0, 1.0, 0.85))
	for k in range(segs):
		indices.append(0)
		indices.append(1 + k)
		indices.append(1 + ((k + 1) % segs))
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


func _init_projectile_multimesh() -> void:
	_proj_mesh = _build_proj_mesh()
	_proj_mat = CanvasItemMaterial.new()
	_proj_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

	_mm_projectiles = MultiMeshInstance2D.new()
	_mm_projectiles.name = "CombatProjectilesPool"
	_mm_projectiles.z_index = 2
	_mm_projectiles.material = _proj_mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = true
	mm.use_custom_data = false
	mm.mesh = _proj_mesh
	mm.instance_count = MAX_PROJECTILES * 2
	mm.visible_instance_count = 0
	mm.custom_aabb = AABB(Vector3(-128.0, -320.0, -1.0), Vector3(1536.0, 1152.0, 2.0))
	_mm_projectiles.multimesh = mm
	add_child(_mm_projectiles)


func _cap_hdr_color(c: Color, mult: float) -> Color:
	var cap: float = float(TUNING_KNOBS["BEAM_HDR_CAP"])
	return Color(
		minf(maxf(c.r, 0.0) * mult, cap),
		minf(maxf(c.g, 0.0) * mult, cap),
		minf(maxf(c.b, 0.0) * mult, cap),
		clampf(c.a, 0.0, 1.0)
	)


func _alloc_beam_slot() -> int:
	if _beam_count < MAX_BEAMS:
		var slot: int = _beam_count
		_beam_count += 1
		return slot
	# Evict dimmest beam when saturated
	var worst: int = 0
	var worst_alpha: float = _beam_alpha[0]
	for i in range(1, MAX_BEAMS):
		if _beam_alpha[i] < worst_alpha:
			worst_alpha = _beam_alpha[i]
			worst = i
	return worst


func _spawn_beam(src: Vector2, dst: Vector2, col: Color, width: float, hdr: float, rate: float) -> void:
	if src.distance_squared_to(dst) < 0.25:
		return
	var slot: int = _alloc_beam_slot()
	_beam_src[slot] = src
	_beam_dst[slot] = dst
	_beam_color[slot] = col
	_beam_width[slot] = clampf(width, 0.8, 28.0)
	_beam_hdr[slot] = clampf(hdr, 0.5, float(TUNING_KNOBS["BEAM_HDR_CAP"]))
	_beam_alpha[slot] = 1.0
	_beam_rate[slot] = maxf(rate, 0.5)


func _alloc_arc_slot() -> int:
	if _arc_count < MAX_ARCS:
		var slot: int = _arc_count
		_arc_count += 1
		return slot
	var worst: int = 0
	var worst_alpha: float = _arc_alpha[0]
	for i in range(1, MAX_ARCS):
		if _arc_alpha[i] < worst_alpha:
			worst_alpha = _arc_alpha[i]
			worst = i
	return worst


func _spawn_teleport_arc(src_pos: Vector2, dst_pos: Vector2, faction_color: Color) -> void:
	var delta: Vector2 = dst_pos - src_pos
	var dist: float = maxf(delta.length(), 1.0)
	var angle: float = delta.angle()
	var base_lift: float = clampf(
		dist * float(TUNING_KNOBS["ARC_LIFT_RATIO"]),
		float(TUNING_KNOBS["ARC_LIFT_MIN_PX"]),
		float(TUNING_KNOBS["ARC_LIFT_MAX_PX"])
	)
	# Match teleport_arc.gdshader (-arch_t * arc_lift_px along transformed local Y)
	# so both left->right and right->left arcs bow cleanly upward in screen space (-Y).
	var sign_y: float = 1.0 if cos(angle) >= 0.0 else -1.0
	var slot: int = _alloc_arc_slot()
	_arc_src[slot] = src_pos
	_arc_dst[slot] = dst_pos
	_arc_color[slot] = Color(clampf(faction_color.r, 0.0, 1.0), clampf(faction_color.g, 0.0, 1.0), clampf(faction_color.b, 0.0, 1.0), 1.0)
	_arc_age[slot] = 0.0
	_arc_dur[slot] = float(TUNING_KNOBS["ARC_DURATION_SEC"])
	_arc_alpha[slot] = 1.0
	_arc_lift[slot] = base_lift * sign_y
	_phase_cursor = fmod(_phase_cursor + 0.37, 1.0)
	_arc_phase[slot] = _phase_cursor
	_arc_pulse[slot] = float(TUNING_KNOBS["ARC_PULSE_FREQ"])


func _update_beams(dt: float) -> void:
	if dt <= 0.0:
		return
	var i: int = 0
	while i < _beam_count:
		var next_a: float = _beam_alpha[i] * exp(-_beam_rate[i] * dt)
		if next_a <= 0.01:
			var last: int = _beam_count - 1
			if i != last:
				_beam_src[i] = _beam_src[last]
				_beam_dst[i] = _beam_dst[last]
				_beam_color[i] = _beam_color[last]
				_beam_width[i] = _beam_width[last]
				_beam_hdr[i] = _beam_hdr[last]
				_beam_alpha[i] = _beam_alpha[last]
				_beam_rate[i] = _beam_rate[last]
			_beam_count = last
			continue
		_beam_alpha[i] = next_a
		i += 1


func _update_arcs(dt: float) -> void:
	if dt <= 0.0:
		return
	var hold_sec: float = float(TUNING_KNOBS["ARC_HOLD_SEC"])
	var decay_rate: float = float(TUNING_KNOBS["ARC_DECAY_RATE"])
	var i: int = 0
	while i < _arc_count:
		var age: float = _arc_age[i] + dt
		var alpha: float = _arc_alpha[i]
		if age > hold_sec:
			alpha *= exp(-decay_rate * dt)
		if age >= _arc_dur[i] or alpha <= 0.008:
			var last: int = _arc_count - 1
			if i != last:
				_arc_src[i] = _arc_src[last]
				_arc_dst[i] = _arc_dst[last]
				_arc_color[i] = _arc_color[last]
				_arc_age[i] = _arc_age[last]
				_arc_dur[i] = _arc_dur[last]
				_arc_alpha[i] = _arc_alpha[last]
				_arc_lift[i] = _arc_lift[last]
				_arc_phase[i] = _arc_phase[last]
				_arc_pulse[i] = _arc_pulse[last]
			_arc_count = last
			continue
		_arc_age[i] = age
		_arc_alpha[i] = alpha
		i += 1


func _sync_beam_multimesh() -> void:
	if _mm_beams == null or _mm_beams.multimesh == null:
		return
	var mm: MultiMesh = _mm_beams.multimesh
	mm.visible_instance_count = _beam_count
	for i in range(_beam_count):
		var s: Vector2 = _beam_src[i]
		var d: Vector2 = _beam_dst[i]
		var delta: Vector2 = d - s
		var dist: float = maxf(delta.length(), 0.5)
		var xform := Transform2D(delta.angle(), Vector2(dist, _beam_width[i]), 0.0, s)
		var col: Color = _cap_hdr_color(_beam_color[i], _beam_hdr[i])
		col.a = clampf(_beam_alpha[i], 0.0, 1.0)
		mm.set_instance_transform_2d(i, xform)
		mm.set_instance_color(i, col)


func _sync_arc_multimesh() -> void:
	if _mm_teleport_arcs == null or _mm_teleport_arcs.multimesh == null:
		return
	var mm: MultiMesh = _mm_teleport_arcs.multimesh
	mm.visible_instance_count = _arc_count
	for i in range(_arc_count):
		var s: Vector2 = _arc_src[i]
		var d: Vector2 = _arc_dst[i]
		var delta: Vector2 = d - s
		var dist: float = maxf(delta.length(), 1.0)
		var xform := Transform2D(delta.angle(), Vector2(dist, 1.0), 0.0, s)
		var custom := Color(_arc_lift[i], _arc_phase[i], _arc_alpha[i], _arc_pulse[i])
		mm.set_instance_transform_2d(i, xform)
		mm.set_instance_color(i, _arc_color[i])
		mm.set_instance_custom_data(i, custom)


func _update_projectiles(dt: float) -> void:
	var i: int = 0
	while i < _proj_count:
		_proj_px[i] += _proj_vx[i] * dt
		_proj_py[i] += _proj_vy[i] * dt
		_proj_vz[i] -= _proj_grav[i] * dt
		var nz: float = _proj_pz[i] + _proj_vz[i] * dt
		if nz <= 0.0:
			_on_projectile_land(i)
			var last: int = _proj_count - 1
			if i != last:
				_proj_px[i] = _proj_px[last]
				_proj_py[i] = _proj_py[last]
				_proj_pz[i] = _proj_pz[last]
				_proj_vx[i] = _proj_vx[last]
				_proj_vy[i] = _proj_vy[last]
				_proj_vz[i] = _proj_vz[last]
				_proj_grav[i] = _proj_grav[last]
				_proj_kind[i] = _proj_kind[last]
				_proj_dmg[i] = _proj_dmg[last]
				_proj_owner[i] = _proj_owner[last]
				_proj_color[i] = _proj_color[last]
			_proj_count = last
			continue
		_proj_pz[i] = minf(nz, 128.0)
		i += 1


func _on_projectile_land(slot: int) -> void:
	var impact_pos := Vector2(_proj_px[slot], _proj_py[slot])
	var kind: int = int(_proj_kind[slot])
	var dmg: float = _proj_dmg[slot]
	var col: Color = _proj_color[slot]
	var rad: float = 14.0 if kind == ProjKind.GRENADE else 7.5
	var burn: float = 0.45 if kind == ProjKind.GRENADE else 0.0
	var imp: float = 55.0 if kind == ProjKind.GRENADE else 22.0
	if _physics != null and _physics.has_method("apply_external_damage"):
		_physics.apply_external_damage(impact_pos, rad, {
			"damage": dmg,
			"burn": burn,
			"impulse": imp,
			"armor_pierce": (kind == ProjKind.SHARD),
		})
	if _fx != null and _proj_fx_cd <= 0.0:
		_proj_fx_cd = 0.05
		if kind == ProjKind.GRENADE:
			_fx.spawn_shockwave(impact_pos, 16.0, col, 0.25)
			_fx.spawn_burst(impact_pos, 8, col, 36.0, 0.34, 18.0)
		else:
			_fx.spawn_burst(impact_pos, 4, col, 20.0, 0.22, 8.0)


func _sync_projectile_multimesh() -> void:
	if _proj_count == 0 and not _proj_was_vis:
		return
	if _mm_projectiles == null or _mm_projectiles.multimesh == null:
		return
	var mm: MultiMesh = _mm_projectiles.multimesh
	var n: int = mini(_proj_count, MAX_PROJECTILES)
	mm.visible_instance_count = n * 2
	_proj_was_vis = (n > 0)
	for i in range(n):
		var px: float = _proj_px[i]
		var py: float = _proj_py[i]
		var pz: float = maxf(_proj_pz[i], 0.0)
		var sh_scale := Vector2(clampf(2.4 - pz * 0.025, 0.9, 2.4), clampf(1.0 - pz * 0.012, 0.45, 1.0))
		mm.set_instance_transform_2d(i, Transform2D(0.0, sh_scale, 0.0, Vector2(px, py)))
		mm.set_instance_color(i, Color(0.02, 0.03, 0.06, clampf(0.42 - pz * 0.007, 0.14, 0.42)))
	for i in range(n):
		var slot: int = n + i
		var pk: int = int(_proj_kind[i])
		var pos := Vector2(_proj_px[i], _proj_py[i] - maxf(_proj_pz[i], 0.0))
		var vel_vis := Vector2(_proj_vx[i], _proj_vy[i] - _proj_vz[i])
		var ang: float = vel_vis.angle() if vel_vis.length_squared() > 0.25 else 0.0
		var sz := Vector2(3.6, 1.4) if (pk == ProjKind.BOLT or pk == ProjKind.SHARD) else (Vector2(2.8, 2.8) if pk == ProjKind.GRENADE else Vector2(2.6, 2.0))
		mm.set_instance_transform_2d(slot, Transform2D(ang, sz, 0.0, pos))
		mm.set_instance_color(slot, _cap_hdr_color(_proj_color[i], 1.65))


func _pull_unit_projectiles() -> void:
	if _physics == null:
		return
	var q_v: Variant = _physics.get("_proj_src")
	if not (q_v is PackedVector2Array) or (q_v as PackedVector2Array).is_empty():
		return
	if not _physics.has_method("pop_fired_projectiles"):
		return
	var res: Variant = _physics.pop_fired_projectiles()
	if not (res is Dictionary):
		return
	var pop: Dictionary = res
	var src_v: Variant = pop.get("src", null)
	var dst_v: Variant = pop.get("dst", null)
	if not (src_v is PackedVector2Array) or not (dst_v is PackedVector2Array):
		return
	var srcs: PackedVector2Array = src_v
	var dsts: PackedVector2Array = dst_v
	var kd_v: Variant = pop.get("kind_dmg", null)
	var own_v: Variant = pop.get("owner", null)
	var kds: PackedVector2Array = kd_v if kd_v is PackedVector2Array else PackedVector2Array()
	var owns: PackedInt32Array = own_v if own_v is PackedInt32Array else PackedInt32Array()
	var n: int = mini(srcs.size(), dsts.size())
	for i in range(n):
		var kd: Vector2 = kds[i] if i < kds.size() else Vector2(0.0, 14.0)
		var ow: int = owns[i] if i < owns.size() else -1
		spawn_ballistic_projectile(Rect2(srcs[i], dsts[i]), kd, ow)


func _pull_unit_beams() -> void:
	if _physics == null or not _physics.has_method("pop_fired_beams"):
		return
	var pop_res: Variant = _physics.pop_fired_beams()
	if not (pop_res is Dictionary):
		return
	var pop: Dictionary = pop_res
	var starts_v: Variant = pop.get("starts", null)
	var ends_v: Variant = pop.get("ends", null)
	if not (starts_v is PackedVector2Array) or not (ends_v is PackedVector2Array):
		return
	var starts: PackedVector2Array = starts_v
	var ends: PackedVector2Array = ends_v
	var n: int = mini(starts.size(), ends.size())
	if n <= 0:
		return

	var colors_v: Variant = pop.get("colors", null)
	var widths_v: Variant = pop.get("widths", null)
	var heavy_v: Variant = pop.get("heavy", null)
	var colors: PackedColorArray = colors_v if colors_v is PackedColorArray else PackedColorArray()
	var widths: PackedFloat32Array = widths_v if widths_v is PackedFloat32Array else PackedFloat32Array()
	var heavy: PackedByteArray = heavy_v if heavy_v is PackedByteArray else PackedByteArray()

	var light_rate: float = float(TUNING_KNOBS["BEAM_DECAY_RATE"])
	var heavy_rate: float = float(TUNING_KNOBS["BEAM_HEAVY_DECAY_RATE"])
	var light_x_sum: float = 0.0
	var light_n: int = 0
	var heavy_x_sum: float = 0.0
	var heavy_n: int = 0
	var spark_budget: int = 3

	for k in range(n):
		var s: Vector2 = starts[k]
		var e: Vector2 = ends[k]
		var col: Color = colors[k] if k < colors.size() else COL_HUMAN
		var w: float = widths[k] if k < widths.size() else 1.5
		var is_heavy: bool = (k < heavy.size() and heavy[k] != 0)
		var hdr: float = 2.85 if is_heavy else 2.35
		var rate: float = heavy_rate if is_heavy else light_rate
		_spawn_beam(s, e, col, maxf(w, 1.3), hdr, rate)
		_beams_fired += 1
		if is_heavy:
			heavy_x_sum += s.x
			heavy_n += 1
		else:
			light_x_sum += s.x
			light_n += 1
		if spark_budget > 0 and _fx != null and _fx.has_method("emit_spark_arc"):
			_fx.emit_spark_arc(e, e - s, col)
			spark_budget -= 1

	if _fx != null and _fx.has_method("play_sfx"):
		if light_n > 0:
			_fx.play_sfx("laser_light", light_x_sum / float(light_n))
		if heavy_n > 0:
			_fx.play_sfx("laser_heavy", heavy_x_sum / float(heavy_n))


func _step_city_turrets(_dt: float) -> void:
	if _civ == null or _physics == null:
		return
	if _sim_pace_mult >= 10.0:
		if _turret_raw_cd > 0.0:
			return
		_turret_raw_cd = 0.12
	var step_dt: float = _turret_pace_acc
	_turret_pace_acc = 0.0
	if not _civ.has_method("get_goal_buffers") or not _civ.has_method("consume_city_energy"):
		return
	var goals: Dictionary = _civ.get_goal_buffers()
	var active_v: Variant = goals.get("city_active", null)
	var center_v: Variant = goals.get("city_center", null)
	var tier_v: Variant = goals.get("city_tech_tier", null)
	if not (active_v is PackedByteArray) or not (center_v is PackedVector2Array) or not (tier_v is PackedByteArray):
		return

	var city_active: PackedByteArray = active_v
	var city_center: PackedVector2Array = center_v
	var city_tier: PackedByteArray = tier_v
	var emp_v: Variant = goals.get("city_emp_timer", null)
	var emp_timers: PackedFloat32Array = emp_v if emp_v is PackedFloat32Array else PackedFloat32Array()

	var n_cities: int = mini(mini(city_active.size(), city_center.size()), mini(city_tier.size(), MAX_CITIES))
	var base_range: float = float(TUNING_KNOBS["TURRET_RANGE_PX"])
	var tier_range: float = float(TUNING_KNOBS["TURRET_RANGE_PER_TIER_PX"])
	var turret_cd: float = float(TUNING_KNOBS["TURRET_INTERVAL_SEC"])
	var miss_cd: float = float(TUNING_KNOBS["TURRET_MISS_COOLDOWN_SEC"])
	var eff_miss_cd: float = maxf(miss_cd, 0.14 * _sim_pace_mult) if _sim_pace_mult >= 10.0 else miss_cd
	var energy_cost: float = float(TUNING_KNOBS["TURRET_ENERGY_COST"])
	var base_dmg: float = float(TUNING_KNOBS["TURRET_DAMAGE"])
	var tier_dmg: float = float(TUNING_KNOBS["TURRET_DAMAGE_PER_TIER"])
	var turret_x_sum: float = 0.0
	var turret_shots_step: int = 0
	_cur_has_fauna = _has_fauna_cnt and int(_physics.call("get_fauna_count")) > 0

	for cid in range(n_cities):
		_city_turret_cd[cid] = maxf(0.0, _city_turret_cd[cid] - step_dt)
		if city_active[cid] == 0:
			continue
		var tier: int = int(city_tier[cid])
		if tier < 1:
			continue
		if cid < emp_timers.size() and emp_timers[cid] > 0.0:
			continue
		if _city_turret_cd[cid] > 0.0:
			continue

		var origin: Vector2 = city_center[cid] + Vector2(0.0, -4.0)
		var scan_r: float = clampf(base_range + float(tier - 1) * tier_range, 42.0, 52.0)
		var target: Dictionary = _find_hostile_target(origin, scan_r, cid, goals)
		if not bool(target.get("found", false)):
			_city_turret_cd[cid] = eff_miss_cd
			continue
		if not _law_diplomacy_wars and not bool(target.get("is_threat", false)):
			var t_fac: int = int(target.get("faction", -1))
			var t_cid: int = int(target.get("city_id", -1))
			if t_fac != FACTION_MUTANT and t_cid >= 0 and t_cid != cid:
				_city_turret_cd[cid] = eff_miss_cd
				continue
		if not _civ.consume_city_energy(cid, energy_cost):
			_city_turret_cd[cid] = eff_miss_cd
			continue

		_city_turret_cd[cid] = turret_cd
		var target_pos: Vector2 = Vector2(target.get("pos", origin))
		var unit_idx: int = int(target.get("unit_idx", -1))
		var dmg: float = base_dmg + float(tier - 1) * tier_dmg
		_damage_units(target_pos, 10.0, dmg, 0.20, cid, unit_idx, goals)

		var beam_col: Color = _resolve_city_color(cid, goals)
		_spawn_beam(origin, target_pos, beam_col, 2.3, 2.75, float(TUNING_KNOBS["BEAM_HEAVY_DECAY_RATE"]))
		_turret_shots += 1
		_beams_fired += 1
		turret_x_sum += origin.x
		turret_shots_step += 1
		if _fx != null and _fx.has_method("emit_spark_arc"):
			_fx.emit_spark_arc(target_pos, target_pos - origin, beam_col)

	if turret_shots_step > 0 and _fx != null and _fx.has_method("play_sfx"):
		_fx.play_sfx("laser_heavy", turret_x_sum / float(turret_shots_step))


func _is_city_hot(city_id: int, war_states: PackedByteArray, alerted: PackedByteArray) -> bool:
	var at_war: bool = _law_diplomacy_wars and city_id >= 0 and city_id < war_states.size() and int(war_states[city_id]) >= DIPLO_TOTAL_WAR
	var is_alerted: bool = city_id >= 0 and city_id < alerted.size() and int(alerted[city_id]) != 0
	return at_war or is_alerted


func _try_paid_portal_hop(src_pos: Vector2, dst_pos: Vector2, src_cid: int) -> int:
	if _civ == null or not _civ.has_method("consume_city_energy"):
		return 0
	var portal_cost: float = float(TUNING_KNOBS["PORTAL_ENERGY_COST"])
	var energy_v: Variant = _civ.get("_city_energy")
	if energy_v is PackedFloat32Array:
		var energies: PackedFloat32Array = energy_v
		if src_cid < 0 or src_cid >= energies.size() or energies[src_cid] < portal_cost:
			return 0
		var moved: int = transfer_squad_portal(src_pos, dst_pos, src_cid)
		if moved > 0:
			_civ.consume_city_energy(src_cid, portal_cost)
		return moved
	if not _civ.consume_city_energy(src_cid, portal_cost):
		return 0
	return transfer_squad_portal(src_pos, dst_pos, src_cid)


func _step_quantum_gates(_dt: float) -> void:
	if _civ == null or _physics == null or not _has_get_gates:
		return
	if _sim_pace_mult >= 10.0:
		if _portal_raw_cd > 0.0:
			return
		_portal_raw_cd = 0.12
	var step_dt: float = _portal_pace_acc
	_portal_pace_acc = 0.0
	_portal_timer -= step_dt
	if _portal_timer > 0.0:
		return
	if not _civ.has_method("consume_city_energy"):
		return
	var gates_raw: Variant = _civ.get_quantum_gates()
	if not (gates_raw is Array):
		return

	var active_gates: Array[Dictionary] = []
	for entry in gates_raw:
		if not (entry is Dictionary):
			continue
		var g: Dictionary = entry
		if bool(g.get("active", false)) and not bool(g.get("emp", false)):
			active_gates.append(g)

	if active_gates.size() < 2:
		_portal_timer = 1.0 if _sim_pace_mult >= 10.0 else 0.4
		return
	_portal_timer = float(TUNING_KNOBS["PORTAL_INTERVAL_SEC"])

	var goals: Dictionary = _civ.get_goal_buffers() if _civ.has_method("get_goal_buffers") else {}
	var war_v: Variant = goals.get("city_war_state", null)
	var alert_v: Variant = goals.get("city_alerted", null)
	var war_states: PackedByteArray = war_v if war_v is PackedByteArray else PackedByteArray()
	var alerted: PackedByteArray = alert_v if alert_v is PackedByteArray else PackedByteArray()
	var portal_cost: float = float(TUNING_KNOBS["PORTAL_ENERGY_COST"])
	var peace_margin: float = float(TUNING_KNOBS["PORTAL_PEACE_ENERGY_MARGIN"])
	var energy_v: Variant = _civ.get("_city_energy")
	var energies: PackedFloat32Array = energy_v if energy_v is PackedFloat32Array else PackedFloat32Array()

	var min_d2: float = float(TUNING_KNOBS["PORTAL_MIN_DIST_PX"]) * float(TUNING_KNOBS["PORTAL_MIN_DIST_PX"])
	var used: PackedByteArray
	used.resize(active_gates.size())
	used.fill(0)

	for i in range(active_gates.size()):
		if used[i] != 0:
			continue
		var ga: Dictionary = active_gates[i]
		var cid_a: int = int(ga.get("city_id", -1))
		var pos_a: Vector2 = Vector2(ga.get("pos", Vector2.ZERO))
		if cid_a < 0:
			continue
		var hot_a: bool = _is_city_hot(cid_a, war_states, alerted)

		var best_j: int = -1
		var best_score: float = -1.0
		for j in range(active_gates.size()):
			if i == j or used[j] != 0:
				continue
			var gb: Dictionary = active_gates[j]
			var cid_b: int = int(gb.get("city_id", -1))
			if cid_b < 0:
				continue
			var allied: bool = (cid_a == cid_b)
			if not allied and _civ.has_method("get_diplomacy"):
				allied = (int(_civ.get_diplomacy(cid_a, cid_b)) == DIPLO_PACT)
			if not allied:
				continue
			var pos_b: Vector2 = Vector2(gb.get("pos", Vector2.ZERO))
			var d2: float = pos_a.distance_squared_to(pos_b)
			if d2 < min_d2:
				continue
			var hot_b: bool = _is_city_hot(cid_b, war_states, alerted)
			var req_e: float = portal_cost if (hot_a or hot_b) else peace_margin
			if not energies.is_empty():
				var e_a: float = energies[cid_a] if cid_a < energies.size() else 0.0
				var e_b: float = energies[cid_b] if cid_b < energies.size() else 0.0
				if e_a < req_e and e_b < req_e:
					continue
			var score: float = d2
			if hot_a or hot_b:
				score += 1.0e9
			if hot_a and hot_b:
				score += 1.0e9
			if score > best_score:
				best_score = score
				best_j = j

		if best_j < 0:
			continue

		var gb_win: Dictionary = active_gates[best_j]
		var pos_b_win: Vector2 = Vector2(gb_win.get("pos", Vector2.ZERO))
		var cid_b_win: int = int(gb_win.get("city_id", -1))
		var hot_b_win: bool = _is_city_hot(cid_b_win, war_states, alerted)

		# Reinforce threatened/wartime gate endpoint first, falling back to reverse direction
		var moved: int = 0
		if hot_a and not hot_b_win:
			moved = _try_paid_portal_hop(pos_b_win, pos_a, cid_b_win)
			if moved <= 0:
				moved = _try_paid_portal_hop(pos_a, pos_b_win, cid_a)
		else:
			moved = _try_paid_portal_hop(pos_a, pos_b_win, cid_a)
			if moved <= 0:
				moved = _try_paid_portal_hop(pos_b_win, pos_a, cid_b_win)
		if moved > 0:
			used[i] = 1
			used[best_j] = 1


func _resolve_city_color(city_id: int, cached_goals: Dictionary = {}) -> Color:
	var goals: Dictionary = cached_goals
	if goals.is_empty() and _civ != null and _civ.has_method("get_goal_buffers"):
		goals = _civ.get_goal_buffers()
	var rebel_v: Variant = goals.get("city_is_rebel", null)
	if rebel_v is PackedByteArray:
		var rebels: PackedByteArray = rebel_v
		if city_id >= 0 and city_id < rebels.size() and rebels[city_id] != 0:
			return COL_REBEL
	var fac_v: Variant = goals.get("city_faction", null)
	if fac_v is PackedByteArray:
		var facs: PackedByteArray = fac_v
		if city_id >= 0 and city_id < facs.size():
			match int(facs[city_id]):
				0:
					return COL_HUMAN
				1:
					return COL_ROBOT
				2:
					return COL_SPORE
	var col_v: Variant = goals.get("city_color", null)
	if col_v is PackedColorArray:
		var cols: PackedColorArray = col_v
		if city_id >= 0 and city_id < cols.size():
			return cols[city_id]
	return COL_HUMAN


func _is_city_hostile_to(owner_cid: int, target_cid: int, target_fac: int, goals: Dictionary) -> bool:
	if target_fac == FACTION_MUTANT:
		return true
	if owner_cid < 0 or target_cid == owner_cid:
		return false
	if target_cid < 0:
		return false
	var diplo_v: Variant = goals.get("diplo_matrix", null)
	var max_c: int = int(goals.get("max_cities", MAX_CITIES))
	if diplo_v is PackedByteArray and owner_cid < max_c and target_cid < max_c:
		var diplo: PackedByteArray = diplo_v
		var idx: int = owner_cid * max_c + target_cid
		if idx >= 0 and idx < diplo.size():
			var st: int = int(diplo[idx])
			if st == DIPLO_TOTAL_WAR:
				return _law_diplomacy_wars
			if st == DIPLO_REBELLION:
				return _law_diplomacy_wars and _law_rebellions
			return false
	var fac_v: Variant = goals.get("city_faction", null)
	if fac_v is PackedByteArray:
		var facs: PackedByteArray = fac_v
		if owner_cid < facs.size():
			return _law_diplomacy_wars and (target_fac != int(facs[owner_cid]))
	return false


func _find_hostile_target(origin: Vector2, max_range: float, owner_cid: int, goals: Dictionary) -> Dictionary:
	if _physics == null:
		return {"found": false}
	if _physics.has_method("find_nearest_hostile_pos"):
		var res: Variant = _physics.find_nearest_hostile_pos(origin, max_range, owner_cid)
		if res is Dictionary and bool((res as Dictionary).get("found", false)):
			return res
		if _cur_has_fauna and _physics.has_method("find_nearest_hostile_fauna"):
			var f_res0: Variant = _physics.call("find_nearest_hostile_fauna", origin, max_range, false)
			if f_res0 is Dictionary and bool((f_res0 as Dictionary).get("found", false)):
				return {
					"found": true,
					"unit_idx": -1,
					"pos": Vector2((f_res0 as Dictionary).get("pos", origin)),
					"is_threat": true,
				}
		if res is Dictionary:
			return res

	if not _physics.has_method("get_unit_positions") or not _physics.has_method("get_unit_cities"):
		return {"found": false}
	var positions: PackedVector2Array = _physics.get_unit_positions()
	var cities: PackedInt32Array = _physics.get_unit_cities()
	var facs_v: Variant = _physics.get("_u_faction_id")
	var hp_v: Variant = _physics.get("_hp")
	var facs: PackedByteArray = facs_v if facs_v is PackedByteArray else PackedByteArray()
	var hp: PackedFloat32Array = hp_v if hp_v is PackedFloat32Array else PackedFloat32Array()

	var n: int = mini(positions.size(), cities.size())
	var best_idx: int = -1
	var best_d2: float = max_range * max_range
	var best_pos: Vector2 = origin
	for i in range(n):
		if i < hp.size() and hp[i] <= 0.0:
			continue
		var t_cid: int = cities[i]
		var t_fac: int = int(facs[i]) if i < facs.size() else 0
		if not _is_city_hostile_to(owner_cid, t_cid, t_fac, goals):
			continue
		var p: Vector2 = positions[i]
		var d2: float = origin.distance_squared_to(p)
		if d2 <= best_d2:
			best_d2 = d2
			best_idx = i
			best_pos = p

	if best_idx < 0:
		if _cur_has_fauna and _physics.has_method("find_nearest_hostile_fauna"):
			var f_res: Variant = _physics.call("find_nearest_hostile_fauna", origin, max_range, false)
			if f_res is Dictionary and bool((f_res as Dictionary).get("found", false)):
				return {
					"found": true,
					"unit_idx": -1,
					"pos": Vector2((f_res as Dictionary).get("pos", origin)),
					"is_threat": true,
				}
		return {"found": false}
	return {"found": true, "unit_idx": best_idx, "pos": best_pos}


func _damage_units(center: Vector2, radius: float, damage: float, burn: float, friendly_cid: int, unit_idx: int, goals: Dictionary) -> int:
	if _physics == null:
		return 0
	if _physics.has_method("apply_external_damage"):
		var spec := {
			"damage": damage,
			"burn": burn,
			"unit_idx": unit_idx,
			"friendly_city": friendly_cid,
			"armor_pierce": (friendly_cid < 0),
			"impulse": float(TUNING_KNOBS["ORBITAL_IMPULSE"]) if friendly_cid < 0 else 0.0,
		}
		return int(_physics.apply_external_damage(center, radius, spec))

	var hp_v: Variant = _physics.get("_hp")
	if not (hp_v is PackedFloat32Array):
		return 0
	var hp: PackedFloat32Array = hp_v
	var flash_v: Variant = _physics.get("_hit_flash_timer")
	var fire_v: Variant = _physics.get("_u_fire_now")
	var flash: PackedFloat32Array = flash_v if flash_v is PackedFloat32Array else PackedFloat32Array()
	var fire_arr: PackedFloat32Array = fire_v if fire_v is PackedFloat32Array else PackedFloat32Array()

	if unit_idx >= 0 and unit_idx < hp.size():
		if hp[unit_idx] <= 0.0:
			return 0
		hp[unit_idx] = maxf(0.0, hp[unit_idx] - damage)
		_physics.set("_hp", hp)
		if unit_idx < flash.size():
			flash[unit_idx] = 0.16
			_physics.set("_hit_flash_timer", flash)
		if burn > 0.0 and unit_idx < fire_arr.size():
			fire_arr[unit_idx] = maxf(fire_arr[unit_idx], burn)
			_physics.set("_u_fire_now", fire_arr)
		return 1

	if not _physics.has_method("get_unit_positions"):
		return 0
	var positions: PackedVector2Array = _physics.get_unit_positions()
	var cities: PackedInt32Array = _physics.get_unit_cities() if _physics.has_method("get_unit_cities") else PackedInt32Array()
	var facs_v: Variant = _physics.get("_u_faction_id")
	var facs: PackedByteArray = facs_v if facs_v is PackedByteArray else PackedByteArray()
	var r2: float = radius * radius
	var n: int = mini(positions.size(), hp.size())
	var hits: int = 0
	for i in range(n):
		if hp[i] <= 0.0:
			continue
		if friendly_cid >= 0:
			var t_cid: int = cities[i] if i < cities.size() else -1
			var t_fac: int = int(facs[i]) if i < facs.size() else 0
			if not _is_city_hostile_to(friendly_cid, t_cid, t_fac, goals):
				continue
		if positions[i].distance_squared_to(center) <= r2:
			hp[i] = maxf(0.0, hp[i] - damage)
			if i < flash.size():
				flash[i] = 0.16
			if burn > 0.0 and i < fire_arr.size():
				fire_arr[i] = maxf(fire_arr[i], burn)
			hits += 1
	if hits > 0:
		_physics.set("_hp", hp)
		if not flash.is_empty():
			_physics.set("_hit_flash_timer", flash)
		if burn > 0.0 and not fire_arr.is_empty():
			_physics.set("_u_fire_now", fire_arr)
	return hits
