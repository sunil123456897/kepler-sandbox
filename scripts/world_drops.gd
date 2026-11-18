extends RefCounted

# 2.5D sky-drop SoA pool (rain, biome seeds, magma, acid, snow, crystal, bombs, meteors, grey goo, conway, trait/gear/bless).
# Strict RefCounted module: zero class_name, zero preload, zero per-tick allocations.

const MAX_DROPS: int = 512

enum DropKind {
	RAIN = 0,
	FIRE = 1,
	LAVA = 2,
	ACID = 3,
	SNOW = 4,
	CRYSTAL = 5,
	PLASMA_BOMB = 6,
	METEOR_SHARD = 7,
	GREY_GOO = 8,
	CONWAY = 9,
	TRAIT_RAIN = 10,
	GEAR_RAIN = 11,
	BLESS = 12,
	SEED_LUSH = 13,
	SEED_RUST = 14,
	SEED_XENO_JUNGLE = 15,
	SEED_CRYO_TUNDRA = 16,
	SEED_ACID_WASTE = 17,
	SEED_SILICA_DUNES = 18,
	SEED_BIOLUM_OASIS = 19,
	SEED_CREEP_MYCELIUM = 20,
	SEED_CREEP_CYBER = 21,
	STEAM = 22,
	FERTILIZER = 23,
	PLASMA_ARC = 24,
}

var _x: PackedFloat32Array
var _y: PackedFloat32Array
var _pos_z: PackedFloat32Array
var _vel_z: PackedFloat32Array
var _vx: PackedFloat32Array
var _vy: PackedFloat32Array
var _grav_z: PackedFloat32Array
var _sway_phase: PackedFloat32Array
var _sway_amp: PackedFloat32Array
var _kind: PackedByteArray
var _parabolic: PackedByteArray
var _color: PackedColorArray

var _snap_pos: PackedVector2Array
var _snap_col: PackedColorArray
var _snap_z: PackedFloat32Array

var _active_count: int = 0
var _evict_cursor: int = 0
var _landed_total: int = 0
var _map_w: int = 640
var _map_h: int = 360
var _drop_rng := RandomNumberGenerator.new()


func _init() -> void:
	_alloc_buffers()
	_drop_rng.seed = 0x44524F50


func _alloc_buffers() -> void:
	_x.resize(MAX_DROPS)
	_y.resize(MAX_DROPS)
	_pos_z.resize(MAX_DROPS)
	_vel_z.resize(MAX_DROPS)
	_vx.resize(MAX_DROPS)
	_vy.resize(MAX_DROPS)
	_grav_z.resize(MAX_DROPS)
	_sway_phase.resize(MAX_DROPS)
	_sway_amp.resize(MAX_DROPS)
	_kind.resize(MAX_DROPS)
	_parabolic.resize(MAX_DROPS)
	_color.resize(MAX_DROPS)
	_snap_pos.resize(0)
	_snap_col.resize(0)
	_snap_z.resize(0)


func set_map_bounds(bounds: Vector2i) -> void:
	_map_w = maxi(bounds.x, 16)
	_map_h = maxi(bounds.y, 16)


func reset(seed_val: int) -> void:
	var s: int = (seed_val ^ 0x44524F50) & 0x7FFFFFFF
	_drop_rng.seed = s if s != 0 else 0x44524F50
	_active_count = 0
	_evict_cursor = 0
	_landed_total = 0
	_snap_pos.resize(0)
	_snap_col.resize(0)
	_snap_z.resize(0)


func get_count() -> int:
	return _active_count


func get_landed_total() -> int:
	return _landed_total


func _alloc_slot() -> int:
	if _active_count < MAX_DROPS:
		var idx: int = _active_count
		_active_count += 1
		return idx
	var slot: int = _evict_cursor % MAX_DROPS
	_evict_cursor += 1
	return slot


func _copy_slot(src: int, dst: int) -> void:
	_x[dst] = _x[src]
	_y[dst] = _y[src]
	_pos_z[dst] = _pos_z[src]
	_vel_z[dst] = _vel_z[src]
	_vx[dst] = _vx[src]
	_vy[dst] = _vy[src]
	_grav_z[dst] = _grav_z[src]
	_sway_phase[dst] = _sway_phase[src]
	_sway_amp[dst] = _sway_amp[src]
	_kind[dst] = _kind[src]
	_parabolic[dst] = _parabolic[src]
	_color[dst] = _color[src]


func color_for_kind(kind: int) -> Color:
	match kind:
		DropKind.RAIN:
			return Color(0.32, 0.78, 1.0, 0.92)
		DropKind.FIRE:
			return Color(1.0, 0.45, 0.12, 0.96)
		DropKind.LAVA:
			return Color(1.0, 0.38, 0.08, 0.98)
		DropKind.ACID:
			return Color(0.62, 0.94, 0.22, 0.94)
		DropKind.SNOW:
			return Color(0.90, 0.96, 1.0, 0.92)
		DropKind.CRYSTAL:
			return Color(0.30, 0.95, 1.0, 0.96)
		DropKind.PLASMA_BOMB:
			return Color(1.0, 0.26, 0.16, 0.98)
		DropKind.METEOR_SHARD:
			return Color(1.0, 0.56, 0.18, 0.98)
		DropKind.GREY_GOO:
			return Color(0.66, 0.58, 0.78, 0.95)
		DropKind.CONWAY:
			return Color(0.34, 1.0, 0.74, 0.95)
		DropKind.TRAIT_RAIN:
			return Color(0.90, 0.38, 1.0, 0.96)
		DropKind.GEAR_RAIN:
			return Color(1.0, 0.84, 0.30, 0.96)
		DropKind.BLESS:
			return Color(1.0, 0.94, 0.52, 0.96)
		DropKind.SEED_LUSH, DropKind.FERTILIZER:
			return Color(0.45, 0.88, 0.38, 0.95)
		DropKind.SEED_RUST:
			return Color(0.84, 0.48, 0.30, 0.95)
		DropKind.SEED_XENO_JUNGLE:
			return Color(0.24, 0.82, 0.62, 0.95)
		DropKind.SEED_CRYO_TUNDRA:
			return Color(0.64, 0.86, 0.98, 0.95)
		DropKind.SEED_ACID_WASTE:
			return Color(0.72, 0.88, 0.24, 0.95)
		DropKind.SEED_SILICA_DUNES:
			return Color(0.92, 0.76, 0.44, 0.95)
		DropKind.SEED_BIOLUM_OASIS:
			return Color(0.28, 0.94, 0.84, 0.96)
		DropKind.SEED_CREEP_MYCELIUM:
			return Color(0.80, 0.38, 0.74, 0.96)
		DropKind.SEED_CREEP_CYBER:
			return Color(0.30, 0.76, 0.98, 0.96)
		DropKind.STEAM:
			return Color(0.82, 0.92, 0.98, 0.84)
		_:
			return Color(0.42, 0.92, 1.0, 0.96)


func spawn_shower(world_pos: Vector2, radius: float, drop_kind: int) -> int:
	var safe_r: float = clampf(radius, 1.0, 64.0)
	var kind: int = clampi(drop_kind, 0, DropKind.PLASMA_ARC)
	var target_count: int = clampi(int(round(safe_r * 0.65)), 2, 20)
	if kind == DropKind.PLASMA_BOMB or kind == DropKind.METEOR_SHARD:
		target_count = clampi(int(round(safe_r * 0.25)), 1, 6)
	elif kind == DropKind.GREY_GOO or kind == DropKind.CONWAY:
		target_count = clampi(int(round(safe_r * 0.35)), 1, 8)

	var col: Color = color_for_kind(kind)
	var mw: float = float(maxi(_map_w - 1, 1))
	var mh: float = float(maxi(_map_h - 1, 1))
	var spawned: int = 0
	for i in range(target_count):
		var ang: float = _drop_rng.randf_range(0.0, TAU)
		var dist: float = 0.0 if i == 0 else sqrt(_drop_rng.randf()) * safe_r
		var sx: float = clampf(world_pos.x + cos(ang) * dist, 1.0, mw - 1.0)
		var sy: float = clampf(world_pos.y + sin(ang) * dist, 1.0, mh - 1.0)
		var slot: int = _alloc_slot()
		_setup_straight_drop(slot, Vector2(sx, sy), kind, col)
		spawned += 1
	return spawned


func _setup_straight_drop(slot: int, pos: Vector2, kind: int, col: Color) -> void:
	var z0: float = _drop_rng.randf_range(18.0, 34.0)
	var vz: float = _drop_rng.randf_range(42.0, 58.0)
	var sway_a: float = 3.5
	if kind == DropKind.SNOW or kind == DropKind.SEED_LUSH or kind == DropKind.SEED_XENO_JUNGLE or kind == DropKind.SEED_BIOLUM_OASIS:
		z0 = _drop_rng.randf_range(22.0, 38.0)
		vz = _drop_rng.randf_range(24.0, 36.0)
		sway_a = 8.5
	elif kind == DropKind.PLASMA_BOMB or kind == DropKind.METEOR_SHARD:
		z0 = _drop_rng.randf_range(48.0, 68.0)
		vz = _drop_rng.randf_range(76.0, 96.0)
		sway_a = 1.0
	elif kind == DropKind.RAIN or kind == DropKind.ACID or kind == DropKind.FIRE or kind == DropKind.LAVA:
		z0 = _drop_rng.randf_range(26.0, 44.0)
		vz = _drop_rng.randf_range(54.0, 72.0)
		sway_a = 4.2
	_x[slot] = pos.x
	_y[slot] = pos.y
	_pos_z[slot] = z0
	_vel_z[slot] = vz
	_vx[slot] = _drop_rng.randf_range(-10.0, 10.0) if kind == DropKind.METEOR_SHARD else 0.0
	_vy[slot] = _drop_rng.randf_range(-4.0, 6.0) if kind == DropKind.METEOR_SHARD else 0.0
	_grav_z[slot] = 0.0
	_sway_phase[slot] = _drop_rng.randf_range(0.0, TAU)
	_sway_amp[slot] = sway_a
	_kind[slot] = kind
	_parabolic[slot] = 0
	_color[slot] = col


func launch_parabolic(origin: Vector2, vel_3d: Vector3, drop_kind: int) -> void:
	var kind: int = clampi(drop_kind, 0, DropKind.PLASMA_ARC)
	var slot: int = _alloc_slot()
	_x[slot] = origin.x
	_y[slot] = origin.y
	_pos_z[slot] = 2.0
	_vel_z[slot] = maxf(vel_3d.z, 8.0)
	_vx[slot] = vel_3d.x
	_vy[slot] = vel_3d.y
	_grav_z[slot] = 92.0
	_sway_phase[slot] = 0.0
	_sway_amp[slot] = 0.0
	_kind[slot] = kind
	_parabolic[slot] = 1
	_color[slot] = color_for_kind(kind)


func step_drops(dt: float, world: Object, fx: Object) -> int:
	if _active_count <= 0 or dt <= 0.0:
		return 0
	var mw: int = int(world.map_w)
	var mh: int = int(world.map_h)
	var landed_now: int = 0
	var has_flash: bool = fx != null and fx.has_method("emit_drop_land_flash")
	var i: int = 0
	while i < _active_count:
		if _parabolic[i] != 0:
			_x[i] += _vx[i] * dt
			_y[i] += _vy[i] * dt
			_pos_z[i] += _vel_z[i] * dt
			_vel_z[i] -= _grav_z[i] * dt
		else:
			_sway_phase[i] += dt * 7.2
			_x[i] += _vx[i] * dt + sin(_sway_phase[i]) * _sway_amp[i] * dt
			_y[i] += _vy[i] * dt
			_pos_z[i] -= _vel_z[i] * dt
		if _pos_z[i] <= 0.0:
			var tx: int = clampi(int(floor(_x[i])), 1, mw - 2)
			var ty: int = clampi(int(floor(_y[i])), 1, mh - 2)
			var k: int = _kind[i]
			var col: Color = _color[i]
			var last: int = _active_count - 1
			if i != last:
				_copy_slot(last, i)
			_active_count = last
			_landed_total += 1
			landed_now += 1
			world._on_sky_drop_landed(tx, ty, k)
			if has_flash:
				fx.emit_drop_land_flash(Vector2(float(tx) + 0.5, float(ty) + 0.5), col)
			continue
		i += 1
	return landed_now


func build_snapshot() -> Dictionary:
	var n: int = _active_count
	if n <= 0:
		if _snap_pos.size() != 0:
			_snap_pos.resize(0)
			_snap_col.resize(0)
			_snap_z.resize(0)
		return {
			"count": 0,
			"positions": _snap_pos,
			"colors": _snap_col,
			"z_heights": _snap_z,
		}
	_snap_pos.resize(n)
	_snap_col.resize(n)
	_snap_z.resize(n)
	for i in range(n):
		_snap_pos[i] = Vector2(_x[i], _y[i])
		_snap_col[i] = _color[i]
		_snap_z[i] = _pos_z[i]
	return {
		"count": n,
		"positions": _snap_pos,
		"colors": _snap_col,
		"z_heights": _snap_z,
	}


func export_bytes() -> PackedByteArray:
	var n: int = _active_count
	var buf := PackedByteArray()
	buf.resize(2 + n * 38)
	buf.encode_u16(0, n)
	for i in range(n):
		var o: int = 2 + i * 38
		buf.encode_float(o, _x[i])
		buf.encode_float(o + 4, _y[i])
		buf.encode_float(o + 8, _pos_z[i])
		buf.encode_float(o + 12, _vel_z[i])
		buf.encode_float(o + 16, _vx[i])
		buf.encode_float(o + 20, _vy[i])
		buf.encode_float(o + 24, _grav_z[i])
		buf.encode_float(o + 28, _sway_phase[i])
		buf.encode_float(o + 32, _sway_amp[i])
		buf[o + 36] = _kind[i]
		buf[o + 37] = _parabolic[i]
	return buf


func import_bytes(buf: PackedByteArray) -> void:
	_active_count = 0
	if buf.size() < 2:
		return
	var n: int = mini(int(buf.decode_u16(0)), MAX_DROPS)
	if buf.size() < 2 + n * 38:
		return
	for i in range(n):
		var o: int = 2 + i * 38
		_x[i] = buf.decode_float(o)
		_y[i] = buf.decode_float(o + 4)
		_pos_z[i] = buf.decode_float(o + 8)
		_vel_z[i] = buf.decode_float(o + 12)
		_vx[i] = buf.decode_float(o + 16)
		_vy[i] = buf.decode_float(o + 20)
		_grav_z[i] = buf.decode_float(o + 24)
		_sway_phase[i] = buf.decode_float(o + 28)
		_sway_amp[i] = buf.decode_float(o + 32)
		_kind[i] = buf[o + 36]
		_parabolic[i] = buf[o + 37]
		_color[i] = color_for_kind(int(_kind[i]))
	_active_count = n
