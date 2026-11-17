extends RefCounted

## Territory, tile-zone resource scanning, road/foot-traffic evolution,
## pixel farm furrows, semantic-zoom border rendering, and ecology batches.
## No class_name to avoid cyclic GDScript references.

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

const FACTION_HUMAN: int = 0
const FACTION_ROBOT: int = 1
const FACTION_SPORE: int = 2

const ZONE_FLAG_FARM: int = 1
const ZONE_FLAG_ROAD: int = 2
const ZONE_FLAG_BUILT: int = 4
const ZONE_FLAG_POWERED: int = 8

const ROAD_NONE: int = 0
const ROAD_DIRT: int = 1
const ROAD_CONDUIT: int = 2

const BLD_DRILL: int = 2
const BLD_FUSION_REACTOR: int = 6

const ECO_HEATING: int = 0
const ECO_ROBOT_PLATE: int = 1
const ECO_SPORE_MYCELIUM: int = 2
const ECO_ORE_DEPLETE: int = 3

const FOOT_TRAFFIC_ROAD_TH: int = 3
const BORDER_CHUNK_PX: int = 32
const BORDER_CHUNK_ZONES: int = 4

var _chunk_w: int = 0
var _chunk_h: int = 0
var _dirty_chunk_mask: PackedByteArray
var _dirty_chunks: PackedInt32Array
var _dirty_chunk_count: int = 0
var _all_borders_dirty: bool = false
var _city_rgb_lut: PackedByteArray
var _city_div_lut: PackedByteArray
var _w_tiers_cache: PackedByteArray
var _w_biomes_cache: PackedByteArray
var _w_temp_cache: PackedFloat32Array
var _w_rad_cache: PackedFloat32Array
var _w_cache_owner: Node2D = null
var _patrol_scratch: Array[Vector2i] = []


func _ensure_chunk_grid(civ: Node2D) -> void:
	var max_c: int = maxi(64, civ._max_cities)
	if _city_rgb_lut.size() != max_c * 3:
		_city_rgb_lut.resize(max_c * 3)
		_city_div_lut.resize(max_c * 3)
	var cw: int = maxi(1, ceili(float(civ._map_w) / float(BORDER_CHUNK_PX)))
	var ch: int = maxi(1, ceili(float(civ._map_h) / float(BORDER_CHUNK_PX)))
	if cw == _chunk_w and ch == _chunk_h and _dirty_chunk_mask.size() == cw * ch:
		return
	_chunk_w = cw
	_chunk_h = ch
	var total: int = cw * ch
	_dirty_chunk_mask.resize(total)
	_dirty_chunks.resize(total)
	_dirty_chunk_mask.fill(0)
	_dirty_chunk_count = 0


func reset_border_chunks() -> void:
	if not _dirty_chunk_mask.is_empty():
		_dirty_chunk_mask.fill(0)
	_dirty_chunk_count = 0
	_all_borders_dirty = false
	_w_cache_owner = null
	_w_tiers_cache = PackedByteArray()
	_w_biomes_cache = PackedByteArray()
	_w_temp_cache = PackedFloat32Array()
	_w_rad_cache = PackedFloat32Array()
	_patrol_scratch.clear()


func _refresh_world_byte_caches(civ: Node2D) -> void:
	if civ._world == null:
		_w_cache_owner = null
		_w_tiers_cache = PackedByteArray()
		_w_biomes_cache = PackedByteArray()
		_w_temp_cache = PackedFloat32Array()
		_w_rad_cache = PackedFloat32Array()
		return
	var map_sz: int = civ._map_w * civ._map_h
	if _w_cache_owner == civ._world and _w_tiers_cache.size() == map_sz and _w_biomes_cache.size() == map_sz and _w_temp_cache.size() == map_sz:
		return
	_w_cache_owner = civ._world
	var wt: Variant = civ._world.get("_tiers")
	var wb: Variant = civ._world.get("_biomes")
	var wtmp: Variant = civ._world.get("_temp")
	var wrad: Variant = civ._world.get("_rad")
	_w_tiers_cache = (wt as PackedByteArray) if (wt is PackedByteArray and (wt as PackedByteArray).size() == map_sz) else PackedByteArray()
	_w_biomes_cache = (wb as PackedByteArray) if (wb is PackedByteArray and (wb as PackedByteArray).size() == map_sz) else PackedByteArray()
	_w_temp_cache = (wtmp as PackedFloat32Array) if (wtmp is PackedFloat32Array and (wtmp as PackedFloat32Array).size() == map_sz) else PackedFloat32Array()
	_w_rad_cache = (wrad as PackedFloat32Array) if (wrad is PackedFloat32Array and (wrad as PackedFloat32Array).size() == map_sz) else PackedFloat32Array()


func scan_zone_range(civ: Node2D, zrect: Rect2i, track_border_changes: bool = false) -> bool:
	if civ._world == null:
		return false
	var cx0: int = clampi(zrect.position.x, 0, civ._zone_w - 1)
	var cy0: int = clampi(zrect.position.y, 0, civ._zone_h - 1)
	var cx1: int = clampi(zrect.position.x + zrect.size.x - 1, 0, civ._zone_w - 1)
	var cy1: int = clampi(zrect.position.y + zrect.size.y - 1, 0, civ._zone_h - 1)
	var any_coast_changed: bool = false
	for zy in range(cy0, cy1 + 1):
		for zx in range(cx0, cx1 + 1):
			if _scan_single_zone(civ, zx, zy, track_border_changes):
				any_coast_changed = true
	return any_coast_changed


func _scan_single_zone(civ: Node2D, zx: int, zy: int, track_border_changes: bool) -> bool:
	var w: Node2D = civ._world
	var px0: int = zx * civ._zone_px
	var py0: int = zy * civ._zone_px
	var px1: int = mini(civ._map_w, px0 + civ._zone_px)
	var py1: int = mini(civ._map_h, py0 + civ._zone_px)
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
			var t: int = w.get_tier(px, py)
			if t <= TIER_SHALLOW:
				if t <= TIER_CLOSE_OCEAN:
					close_n += 1
				water_near += 1
				continue
			if t >= TIER_SUMMIT:
				continue
			land_n += 1
			var b: int = w.get_biome(px, py)
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

	var zidx: int = zy * civ._zone_w + zx
	var ore: int = mtn_n * 6 + hill_n * 3 + crys_n * 4 + scorch_n
	if ore == 0 and land_n >= 8:
		var h_val: int = ((zx * 73856093) ^ (zy * 19349663)) & 7
		if h_val <= 2:
			ore = 10 + h_val * 4
	civ._zone_ore[zidx] = ore

	var fert: float = 0.40
	if lush_n >= 4:
		fert = 1.00
	if water_near > 0 and land_n >= 4:
		fert = maxf(fert, 1.35)
	civ._zone_fertility[zidx] = fert

	var cl_b: int = mini(254, close_n)
	var ln_b: int = mini(254, land_n)
	var prev_close: int = int(civ._zone_close_n[zidx])
	var prev_land: int = int(civ._zone_land_n[zidx])
	civ._zone_close_n[zidx] = cl_b
	civ._zone_land_n[zidx] = ln_b
	if track_border_changes and (prev_close != cl_b or prev_land != ln_b):
		_dirty_if_near_overlay(civ, zx, zy)
		return true
	return false


func _dirty_if_near_overlay(civ: Node2D, zx: int, zy: int) -> void:
	for ny in range(maxi(0, zy - 1), mini(civ._zone_h, zy + 2)):
		var n_row: int = ny * civ._zone_w
		for nx in range(maxi(0, zx - 1), mini(civ._zone_w, zx + 2)):
			var n_zi: int = n_row + nx
			var o: int = civ._zone_city_id[n_zi]
			if (o >= 0 and civ._city_active[o] != 0) or (civ._zone_flags[n_zi] & ZONE_FLAG_ROAD) != 0:
				mark_zone_dirty(civ, zx, zy)
				return


func refresh_resource_zone(civ: Node2D, rect: Rect2i) -> void:
	if civ._world == null:
		return
	var rx0: int = clampi(rect.position.x, 0, civ._map_w - 1)
	var ry0: int = clampi(rect.position.y, 0, civ._map_h - 1)
	var rx1: int = clampi(rect.position.x + maxi(1, rect.size.x) - 1, 0, civ._map_w - 1)
	var ry1: int = clampi(rect.position.y + maxi(1, rect.size.y) - 1, 0, civ._map_h - 1)
	var zx0: int = clampi(rx0 / civ._zone_px, 0, civ._zone_w - 1)
	var zy0: int = clampi(ry0 / civ._zone_px, 0, civ._zone_h - 1)
	var zx1: int = clampi(rx1 / civ._zone_px, 0, civ._zone_w - 1)
	var zy1: int = clampi(ry1 / civ._zone_px, 0, civ._zone_h - 1)

	if scan_zone_range(civ, Rect2i(zx0, zy0, zx1 - zx0 + 1, zy1 - zy0 + 1), true):
		civ._city_coastal_cache.fill(0)

	var touched_owned: bool = false
	for zy in range(zy0, zy1 + 1):
		var row_off: int = zy * civ._zone_w
		for zx in range(zx0, zx1 + 1):
			var zidx: int = row_off + zx
			var owner: int = civ._zone_city_id[zidx]
			if owner >= 0 and civ._city_active[owner] != 0:
				touched_owned = true
				if not is_zone_walkable(civ, Vector2i(zx, zy), int(civ._city_faction[owner])):
					civ._zone_city_id[zidx] = -1
					civ._zone_faction_id[zidx] = 255
					civ._zone_flags[zidx] = 0
					civ._zone_farm_growth[zidx] = 0.0
					civ._city_zones_count[owner] = maxi(0, civ._city_zones_count[owner] - 1)
					civ._city_coastal_cache[owner] = 0
					civ._city_farm_scan_cd[owner] = 0.0
					mark_zone_dirty(civ, zx, zy)
					civ._goals_dirty = true

	if touched_owned:
		_prune_flooded_buildings_in_rect(civ, rx0, ry0, rx1, ry1)


func _prune_flooded_buildings_in_rect(civ: Node2D, rx0: int, ry0: int, rx1: int, ry1: int) -> void:
	var bi: int = civ._bld_count - 1
	var fallen_cities: Dictionary = {}
	var meltdowns: Array[Vector2] = []
	var melt_cids: Array[int] = []
	while bi >= 0:
		var bpos: Vector2 = civ._bld_pos[bi]
		var bx: int = clampi(int(floor(bpos.x)), 0, civ._map_w - 1)
		var by: int = clampi(int(floor(bpos.y)), 0, civ._map_h - 1)
		if bx >= rx0 and bx <= rx1 and by >= ry0 and by <= ry1:
			var cid: int = civ._bld_city_id[bi]
			var fid: int = int(civ._city_faction[clampi(cid, 0, civ._max_cities - 1)])
			var flooded: bool = int(civ._world.get_tier(bx, by)) <= TIER_CLOSE_OCEAN or civ._world.get_biome(bx, by) == BIOME_LAVA
			if flooded or not is_pixel_walkable(civ, Vector2i(bx, by), fid):
				if civ._bld_type[bi] == BLD_FUSION_REACTOR:
					meltdowns.append(bpos)
					melt_cids.append(cid)
				if cid >= 0 and cid < civ._max_cities:
					fallen_cities[cid] = true
				civ._remove_building(bi)
		bi -= 1
	var keys: Array = fallen_cities.keys()
	for ki in range(keys.size()):
		var cid: int = int(keys[ki])
		if cid >= 0 and cid < civ._max_cities and civ._city_active[cid] != 0:
			civ._verify_city_integrity_after_damage(cid)
	for mi in range(meltdowns.size()):
		civ._trigger_reactor_meltdown(meltdowns[mi], melt_cids[mi])


func is_pixel_walkable(civ: Node2D, pt: Vector2i, faction_id: int = 0) -> bool:
	var px: int = pt.x
	var py: int = pt.y
	if px < 4 or px >= civ._map_w - 4 or py < 4 or py >= civ._map_h - 4:
		return false
	if civ._world == null:
		return true
	_refresh_world_byte_caches(civ)
	var max_t: float = 95.0 if faction_id == FACTION_ROBOT else 65.0
	if not _w_tiers_cache.is_empty() and not _w_biomes_cache.is_empty() and not _w_temp_cache.is_empty():
		var idx: int = py * civ._map_w + px
		var t: int = int(_w_tiers_cache[idx])
		if t < TIER_SAND or t > TIER_MOUNTAINS or int(_w_biomes_cache[idx]) == BIOME_LAVA:
			return false
		var c_off: float = float(civ._world.get("_cosmic_temp_offset"))
		return (_w_temp_cache[idx] + c_off) <= max_t
	if not civ._world.is_walkable(px, py):
		return false
	if int(civ._world.get_biome(px, py)) == BIOME_LAVA:
		return false
	return float(civ._world.get_temp(px, py)) <= max_t


func can_settle_near(civ: Node2D, world_pos: Vector2, min_spacing: float = 64.0) -> bool:
	var px: int = int(floor(world_pos.x))
	var py: int = int(floor(world_pos.y))
	if px < 8 or px >= civ._map_w - 8 or py < 8 or py >= civ._map_h - 8:
		return false
	if civ._world != null:
		var t: int = int(civ._world.get_tier(px, py))
		if t <= TIER_SHALLOW or t >= TIER_SUMMIT:
			return false
		if not civ._world.is_walkable(px, py):
			return false
		var b: int = int(civ._world.get_biome(px, py))
		if b == BIOME_LAVA:
			return false
		if float(civ._world.get_temp(px, py)) > 85.0:
			return false
	var sp2: float = min_spacing * min_spacing
	for cid in range(civ._max_cities):
		if civ._city_active[cid] != 0 and civ._city_center[cid].distance_squared_to(world_pos) < sp2:
			return false
	return true


func is_zone_walkable(civ: Node2D, zpt: Vector2i, faction_id: int = 0) -> bool:
	if civ._world == null:
		return true
	_refresh_world_byte_caches(civ)
	var px0: int = maxi(4, zpt.x * civ._zone_px)
	var py0: int = maxi(4, zpt.y * civ._zone_px)
	var px1: int = mini(civ._map_w - 4, zpt.x * civ._zone_px + civ._zone_px)
	var py1: int = mini(civ._map_h - 4, zpt.y * civ._zone_px + civ._zone_px)
	var walk_n: int = 0
	if not _w_tiers_cache.is_empty() and not _w_biomes_cache.is_empty() and not _w_temp_cache.is_empty():
		var w_tiers: PackedByteArray = _w_tiers_cache
		var w_biomes: PackedByteArray = _w_biomes_cache
		var w_temp: PackedFloat32Array = _w_temp_cache
		var c_off: float = float(civ._world.get("_cosmic_temp_offset"))
		var max_t: float = 95.0 if faction_id == FACTION_ROBOT else 65.0
		var mw: int = civ._map_w
		for py in range(py0, py1, 2):
			var row_off: int = py * mw
			for px in range(px0, px1, 2):
				var idx: int = row_off + px
				var t: int = int(w_tiers[idx])
				if t >= TIER_SAND and t <= TIER_MOUNTAINS and int(w_biomes[idx]) != BIOME_LAVA and (w_temp[idx] + c_off) <= max_t:
					walk_n += 1
					if walk_n >= 4:
						return true
		return false
	for py in range(py0, py1, 2):
		for px in range(px0, px1, 2):
			if is_pixel_walkable(civ, Vector2i(px, py), faction_id):
				walk_n += 1
				if walk_n >= 4:
					return true
	return false


func is_zone_claimable(civ: Node2D, zpt: Vector2i, faction_id: int = 0) -> bool:
	if zpt.x < 0 or zpt.x >= civ._zone_w or zpt.y < 0 or zpt.y >= civ._zone_h:
		return false
	var zidx: int = zpt.y * civ._zone_w + zpt.x
	if civ._zone_city_id[zidx] != -1:
		return false
	return is_zone_walkable(civ, zpt, faction_id)


func zone_walkable_center(civ: Node2D, zpt: Vector2i, faction_id: int = 0) -> Vector2:
	var px0: int = zpt.x * civ._zone_px
	var py0: int = zpt.y * civ._zone_px
	var cx: int = clampi(px0 + 4, 4, civ._map_w - 5)
	var cy: int = clampi(py0 + 4, 4, civ._map_h - 5)
	if is_pixel_walkable(civ, Vector2i(cx, cy), faction_id):
		return Vector2(float(cx) + 0.5, float(cy) + 0.5)
	for dy in range(1, civ._zone_px, 2):
		for dx in range(1, civ._zone_px, 2):
			var tx: int = clampi(px0 + dx, 4, civ._map_w - 5)
			var ty: int = clampi(py0 + dy, 4, civ._map_h - 5)
			if is_pixel_walkable(civ, Vector2i(tx, ty), faction_id):
				return Vector2(float(tx) + 0.5, float(ty) + 0.5)
	return Vector2(-1.0, -1.0)


func find_walkable_near(civ: Node2D, world_pos: Vector2, opts: Vector2i = Vector2i(18, 0)) -> Vector2:
	var max_r: int = opts.x
	var faction_id: int = opts.y
	var cx: int = clampi(int(floor(world_pos.x)), 4, civ._map_w - 5)
	var cy: int = clampi(int(floor(world_pos.y)), 4, civ._map_h - 5)
	if is_pixel_walkable(civ, Vector2i(cx, cy), faction_id):
		return Vector2(float(cx) + 0.5, float(cy) + 0.5)
	for r in range(2, max_r + 1, 2):
		for k in range(12):
			var ang: float = float(k) * (TAU / 12.0)
			var tx: int = clampi(cx + int(round(cos(ang) * float(r))), 4, civ._map_w - 5)
			var ty: int = clampi(cy + int(round(sin(ang) * float(r))), 4, civ._map_h - 5)
			if is_pixel_walkable(civ, Vector2i(tx, ty), faction_id):
				return Vector2(float(tx) + 0.5, float(ty) + 0.5)
	return Vector2(-1.0, -1.0)


func is_zone_coastal(civ: Node2D, zx: int, zy: int) -> bool:
	if civ._world == null:
		return false
	for dy in range(-2, 3):
		var nzy: int = zy + dy
		if nzy < 0 or nzy >= civ._zone_h:
			continue
		for dx in range(-2, 3):
			var nzx: int = zx + dx
			if nzx < 0 or nzx >= civ._zone_w:
				continue
			var px: int = clampi(nzx * civ._zone_px + 4, 0, civ._map_w - 1)
			var py: int = clampi(nzy * civ._zone_px + 4, 0, civ._map_h - 1)
			if int(civ._world.get_tier(px, py)) <= TIER_SHALLOW:
				return true
	return false


func is_city_coastal(civ: Node2D, city_id: int) -> bool:
	if city_id >= 0 and city_id < civ._max_cities:
		var cached: int = int(civ._city_coastal_cache[city_id])
		if cached != 0:
			return cached == 2
	var c: Vector2 = civ._city_center[city_id]
	var czx: int = clampi(int(floor(c.x / float(civ._zone_px))), 0, civ._zone_w - 1)
	var czy: int = clampi(int(floor(c.y / float(civ._zone_px))), 0, civ._zone_h - 1)
	var coastal: bool = is_zone_coastal(civ, czx, czy)
	if not coastal:
		for zy in range(maxi(0, czy - 5), mini(civ._zone_h, czy + 6)):
			var row_off: int = zy * civ._zone_w
			for zx in range(maxi(0, czx - 5), mini(civ._zone_w, czx + 6)):
				if civ._zone_city_id[row_off + zx] == city_id and is_zone_coastal(civ, zx, zy):
					coastal = true
					break
			if coastal:
				break
	if city_id >= 0 and city_id < civ._max_cities:
		civ._city_coastal_cache[city_id] = 2 if coastal else 1
	return coastal


func claim_zone(civ: Node2D, zpt: Vector2i, city_id: int) -> bool:
	var zx: int = zpt.x
	var zy: int = zpt.y
	if zx < 0 or zx >= civ._zone_w or zy < 0 or zy >= civ._zone_h:
		return false
	var zidx: int = zy * civ._zone_w + zx
	var prev_city: int = civ._get_zone_owner(zx, zy)
	if prev_city == city_id:
		return false
	if prev_city >= 0 and prev_city < civ._max_cities and civ._city_active[prev_city] != 0:
		civ._city_zones_count[prev_city] = maxi(0, civ._city_zones_count[prev_city] - 1)
		civ._city_coastal_cache[prev_city] = 0
		if (civ._zone_flags[zidx] & ZONE_FLAG_FARM) != 0:
			civ._city_farm_scan_cd[prev_city] = 0.0
		civ._zone_flags[zidx] &= ~ZONE_FLAG_FARM
		civ._zone_farm_growth[zidx] = 0.0

	civ._zone_city_id[zidx] = city_id
	civ._zone_faction_id[zidx] = int(civ._city_faction[city_id])
	civ._zone_capture_cid[zidx] = -1
	civ._zone_capture_timer[zidx] = 0.0
	civ._city_zones_count[city_id] += 1
	civ._city_coastal_cache[city_id] = 0
	mark_zone_dirty(civ, zx, zy)
	civ._goals_dirty = true
	return true


func claim_starter_quad(civ: Node2D, center_pos: Vector2, city_id: int) -> void:
	var f_id: int = int(civ._city_faction[city_id])
	var zx: int = clampi(int(floor(center_pos.x / float(civ._zone_px))), 0, civ._zone_w - 1)
	var zy: int = clampi(int(floor(center_pos.y / float(civ._zone_px))), 0, civ._zone_h - 1)
	claim_zone(civ, Vector2i(zx, zy), city_id)
	var lx: int = int(floor(center_pos.x)) - zx * civ._zone_px
	var ly: int = int(floor(center_pos.y)) - zy * civ._zone_px
	var sx: int = 1 if lx >= (civ._zone_px >> 1) else -1
	var sy: int = 1 if ly >= (civ._zone_px >> 1) else -1
	var offsets := [Vector2i(sx, 0), Vector2i(0, sy), Vector2i(sx, sy), Vector2i(-sx, 0), Vector2i(0, -sy)]
	for off in offsets:
		if civ._city_zones_count[city_id] >= 4:
			break
		var npt := Vector2i(zx + off.x, zy + off.y)
		if is_zone_claimable(civ, npt, f_id):
			claim_zone(civ, npt, city_id)


func expand_city_territory(civ: Node2D, city_id: int) -> bool:
	_refresh_world_byte_caches(civ)
	var best_zx: int = -1
	var best_zy: int = -1
	var best_score: float = -1e9
	var center: Vector2 = civ._city_center[city_id]
	var f_id: int = int(civ._city_faction[city_id])
	var zw: int = civ._zone_w
	var zh: int = civ._zone_h
	var zpx: float = float(civ._zone_px)
	var czx: int = clampi(int(floor(center.x / zpx)), 0, zw - 1)
	var czy: int = clampi(int(floor(center.y / zpx)), 0, zh - 1)
	var scan_r: int = clampi(8 + civ._city_zones_count[city_id] / 3, 10, 24)
	var zx0: int = maxi(0, czx - scan_r)
	var zy0: int = maxi(0, czy - scan_r)
	var zx1: int = mini(zw - 1, czx + scan_r)
	var zy1: int = mini(zh - 1, czy + scan_r)
	var z_owners: PackedInt32Array = civ._zone_city_id
	var z_fert: PackedFloat32Array = civ._zone_fertility
	var z_ore: PackedInt32Array = civ._zone_ore

	for zy in range(zy0, zy1 + 1):
		var row_off: int = zy * zw
		for zx in range(zx0, zx1 + 1):
			var zidx: int = row_off + zx
			if z_owners[zidx] != -1:
				continue
			var adj: bool = (
				(zx > 0 and z_owners[zidx - 1] == city_id)
				or (zx + 1 < zw and z_owners[zidx + 1] == city_id)
				or (zy > 0 and z_owners[zidx - zw] == city_id)
				or (zy + 1 < zh and z_owners[zidx + zw] == city_id)
			)
			if not adj:
				continue
			var z_pos := Vector2((float(zx) + 0.5) * zpx, (float(zy) + 0.5) * zpx)
			var score: float = 50.0 - z_pos.distance_to(center) * 0.45
			if f_id == FACTION_SPORE:
				score += z_fert[zidx] * 26.0 + float(z_ore[zidx]) * 0.8
			elif f_id == FACTION_ROBOT:
				score += float(z_ore[zidx]) * 2.4 + z_fert[zidx] * 6.0
			else:
				score += float(z_ore[zidx]) * 1.6 + z_fert[zidx] * 14.0
			if score <= best_score or not is_zone_claimable(civ, Vector2i(zx, zy), f_id):
				continue
			best_score = score
			best_zx = zx
			best_zy = zy

	if best_zx < 0:
		return false
	claim_zone(civ, Vector2i(best_zx, best_zy), city_id)
	return true


func refresh_city_targets(civ: Node2D, city_id: int) -> void:
	var center: Vector2 = civ._city_center[city_id]
	var f_id: int = int(civ._city_faction[city_id])
	var czx: int = clampi(int(floor(center.x / float(civ._zone_px))), 0, civ._zone_w - 1)
	var czy: int = clampi(int(floor(center.y / float(civ._zone_px))), 0, civ._zone_h - 1)

	var changed: bool = false
	var best_mine: Vector2 = _find_best_mine_target(civ, city_id, f_id, center, czx, czy)
	if civ._city_mine_pos[city_id].distance_squared_to(best_mine) > 0.25:
		civ._city_mine_pos[city_id] = best_mine
		changed = true

	var new_patrol: Vector2 = _find_patrol_target(civ, city_id, f_id, center, czx, czy)
	if civ._city_patrol_pos[city_id].distance_squared_to(new_patrol) > 0.25:
		civ._city_patrol_pos[city_id] = new_patrol
		changed = true
	if changed:
		civ._light_goals_dirty = true


func _find_best_mine_target(civ: Node2D, city_id: int, f_id: int, center: Vector2, czx: int, czy: int) -> Vector2:
	var best_mine: Vector2 = center
	var best_score: float = -1e9
	for zy in range(maxi(0, czy - 10), mini(civ._zone_h, czy + 11)):
		var row_off: int = zy * civ._zone_w
		for zx in range(maxi(0, czx - 10), mini(civ._zone_w, czx + 11)):
			var zidx: int = row_off + zx
			var owner: int = civ._zone_city_id[zidx]
			if owner != -1 and owner != city_id:
				continue
			var ore: int = civ._zone_ore[zidx]
			if ore <= 0:
				continue
			var approx_pos := Vector2((float(zx) + 0.5) * float(civ._zone_px), (float(zy) + 0.5) * float(civ._zone_px))
			var score: float = float(ore) * 3.0 - approx_pos.distance_to(center) * 1.1
			if owner == city_id:
				score += 20.0
			if score <= best_score:
				continue
			var pos: Vector2 = zone_walkable_center(civ, Vector2i(zx, zy), f_id)
			if pos.x >= 0.0:
				best_score = score
				best_mine = pos
	return best_mine


func _find_patrol_target(civ: Node2D, city_id: int, f_id: int, center: Vector2, czx: int, czy: int) -> Vector2:
	if civ._city_alerted[city_id] != 0 and civ._city_threat_pos[city_id].length_squared() > 1.0:
		return civ._city_threat_pos[city_id]
	_patrol_scratch.clear()
	var z_owners: PackedInt32Array = civ._zone_city_id
	var zw: int = civ._zone_w
	var zh: int = civ._zone_h
	var zy1: int = mini(zh, czy + 10)
	var zx0: int = maxi(0, czx - 9)
	var zx1: int = mini(zw, czx + 10)
	for zy in range(maxi(0, czy - 9), zy1):
		var row_off: int = zy * zw
		for zx in range(zx0, zx1):
			var zidx: int = row_off + zx
			if z_owners[zidx] != city_id:
				continue
			if (
				(zx <= 0 or z_owners[zidx - 1] != city_id)
				or (zx + 1 >= zw or z_owners[zidx + 1] != city_id)
				or (zy <= 0 or z_owners[zidx - zw] != city_id)
				or (zy + 1 >= zh or z_owners[zidx + zw] != city_id)
			):
				_patrol_scratch.append(Vector2i(zx, zy))
	if not _patrol_scratch.is_empty():
		var pick: int = int(floor(civ._sim_time * 0.5 + float(city_id))) % _patrol_scratch.size()
		var pz: Vector2i = _patrol_scratch[pick]
		var ppos: Vector2 = zone_walkable_center(civ, pz, f_id)
		if ppos.x >= 0.0:
			return ppos
	return center


func record_foot_step(civ: Node2D, world_pos: Vector2, city_id: int) -> void:
	var px: int = int(floor(world_pos.x))
	var py: int = int(floor(world_pos.y))
	if px < 1 or px >= civ._map_w - 1 or py < 1 or py >= civ._map_h - 1:
		return
	var idx: int = py * civ._map_w + px
	if civ._world != null:
		_refresh_world_byte_caches(civ)
		var t: int = int(_w_tiers_cache[idx]) if not _w_tiers_cache.is_empty() else int(civ._world.get_tier(px, py))
		if t <= TIER_SHALLOW or t >= TIER_SUMMIT:
			return
		var b: int = int(_w_biomes_cache[idx]) if not _w_biomes_cache.is_empty() else int(civ._world.get_biome(px, py))
		if b == BIOME_LAVA:
			return
	var cnt: int = mini(255, int(civ._foot_traffic[idx]) + 1)
	civ._foot_traffic[idx] = cnt
	if cnt < FOOT_TRAFFIC_ROAD_TH:
		return

	var owner_cid: int = city_id
	if owner_cid < 0 or owner_cid >= civ._max_cities or civ._city_active[owner_cid] == 0:
		owner_cid = civ.get_zone_owner_at(world_pos)
	var target_kind: int = ROAD_DIRT
	if owner_cid >= 0 and owner_cid < civ._max_cities and civ._city_active[owner_cid] != 0:
		var fid: int = int(civ._city_faction[owner_cid])
		var tier: int = int(civ._city_tech_tier[owner_cid])
		if fid != FACTION_SPORE and tier >= 2:
			target_kind = ROAD_CONDUIT
	stamp_road_1px(civ, Vector2i(px, py), target_kind)


func stamp_road(civ: Node2D, seg: Rect2, road_kind: int) -> void:
	var p0: Vector2 = seg.position
	var p1: Vector2 = seg.size
	var x0: int = clampi(int(floor(p0.x)), 1, civ._map_w - 2)
	var y0: int = clampi(int(floor(p0.y)), 1, civ._map_h - 2)
	var x1: int = clampi(int(floor(p1.x)), 1, civ._map_w - 2)
	var y1: int = clampi(int(floor(p1.y)), 1, civ._map_h - 2)

	var step_x: int = 1 if x1 >= x0 else -1
	var cx: int = x0
	while cx != x1:
		stamp_road_1px(civ, Vector2i(cx, y0), road_kind)
		cx += step_x

	var step_y: int = 1 if y1 >= y0 else -1
	var cy: int = y0
	while cy != y1:
		stamp_road_1px(civ, Vector2i(x1, cy), road_kind)
		cy += step_y
	stamp_road_1px(civ, Vector2i(x1, y1), road_kind)


func stamp_road_1px(civ: Node2D, pt: Vector2i, road_kind: int) -> void:
	var tx: int = pt.x
	var ty: int = pt.y
	if tx < 1 or tx >= civ._map_w - 1 or ty < 1 or ty >= civ._map_h - 1:
		return
	var idx: int = ty * civ._map_w + tx
	if civ._world != null:
		var wt: int = int(_w_tiers_cache[idx]) if not _w_tiers_cache.is_empty() else int(civ._world.get_tier(tx, ty))
		if wt <= TIER_CLOSE_OCEAN:
			return
	var zx: int = tx / civ._zone_px
	var zy: int = ty / civ._zone_px
	var zidx: int = zy * civ._zone_w + zx
	var z_owner: int = civ._zone_city_id[zidx]
	var eff_kind: int = road_kind
	if eff_kind == ROAD_CONDUIT and z_owner >= 0 and z_owner < civ._max_cities and civ._city_active[z_owner] != 0:
		if int(civ._city_faction[z_owner]) == FACTION_SPORE:
			eff_kind = ROAD_DIRT

	var old_r: int = int(civ._road_mask[idx])
	if eff_kind <= old_r:
		return
	if old_r == ROAD_NONE:
		civ._road_px_count += 1
	elif old_r == ROAD_DIRT:
		civ._road_dirt_count = maxi(0, civ._road_dirt_count - 1)
	if eff_kind == ROAD_DIRT:
		civ._road_dirt_count += 1
	elif eff_kind == ROAD_CONDUIT:
		civ._road_conduit_count += 1
	civ._road_mask[idx] = eff_kind
	civ._zone_flags[zidx] |= ZONE_FLAG_ROAD
	mark_zone_dirty(civ, zx, zy)


func clear_road_pixel(civ: Node2D, idx: int) -> void:
	var old_r: int = int(civ._road_mask[idx])
	if old_r == ROAD_NONE:
		return
	civ._road_mask[idx] = ROAD_NONE
	civ._road_px_count = maxi(0, civ._road_px_count - 1)
	if old_r == ROAD_DIRT:
		civ._road_dirt_count = maxi(0, civ._road_dirt_count - 1)
	elif old_r == ROAD_CONDUIT:
		civ._road_conduit_count = maxi(0, civ._road_conduit_count - 1)


func recount_roads(civ: Node2D) -> void:
	var total: int = 0
	var dirt: int = 0
	var conduit: int = 0
	for i in range(civ._road_mask.size()):
		var r: int = int(civ._road_mask[i])
		if r == ROAD_DIRT:
			dirt += 1
			total += 1
		elif r == ROAD_CONDUIT:
			conduit += 1
			total += 1
	civ._road_px_count = total
	civ._road_dirt_count = dirt
	civ._road_conduit_count = conduit


func upgrade_city_roads_to_conduits(civ: Node2D, city_id: int) -> void:
	if city_id < 0 or city_id >= civ._max_cities:
		return
	if int(civ._city_faction[city_id]) == FACTION_SPORE:
		return
	for zy in range(civ._zone_h):
		for zx in range(civ._zone_w):
			var zidx: int = zy * civ._zone_w + zx
			if civ._zone_city_id[zidx] != city_id:
				continue
			if (civ._zone_flags[zidx] & ZONE_FLAG_ROAD) == 0:
				continue
			civ._zone_flags[zidx] |= ZONE_FLAG_POWERED
			var changed_zone: bool = false
			var py0: int = zy * civ._zone_px
			var px0: int = zx * civ._zone_px
			for py in range(py0, mini(civ._map_h, py0 + civ._zone_px)):
				var row_off: int = py * civ._map_w
				for px in range(px0, mini(civ._map_w, px0 + civ._zone_px)):
					var idx: int = row_off + px
					if civ._road_mask[idx] == ROAD_DIRT:
						civ._road_mask[idx] = ROAD_CONDUIT
						civ._road_dirt_count = maxi(0, civ._road_dirt_count - 1)
						civ._road_conduit_count += 1
						changed_zone = true
			if changed_zone:
				mark_zone_dirty(civ, zx, zy)


func step_city_farms(civ: Node2D, cid: int, dt_and_crop: Vector2) -> float:
	var pace_dt: float = dt_and_crop.x
	var crop_mul: float = dt_and_crop.y
	var fid: int = int(civ._city_faction[cid])
	var tier: int = int(civ._city_tech_tier[cid])
	if tier < 1 or fid == FACTION_ROBOT:
		return 0.0

	if civ._city_farm_scan_cd[cid] > 0.0:
		civ._city_farm_scan_cd[cid] -= pace_dt
		return float(civ._city_farm_count[cid]) * 0.42 * pace_dt * crop_mul
	_ensure_chunk_grid(civ)

	var desired_farms: int = clampi(1 + civ._city_pop[cid] / 5, 2, 6)
	var scan_step: float = maxf(12.0, pace_dt * 12.0) if civ._sim_pace_mult >= 10.0 else maxf(6.0, pace_dt * 3.0)
	civ._city_farm_scan_cd[cid] = scan_step
	if _w_cache_owner != civ._world:
		_refresh_world_byte_caches(civ)

	var current_farms: int = 0
	var center: Vector2 = civ._city_center[cid]
	var czx: int = clampi(int(floor(center.x / float(civ._zone_px))), 0, civ._zone_w - 1)
	var czy: int = clampi(int(floor(center.y / float(civ._zone_px))), 0, civ._zone_h - 1)
	var scan_r: int = clampi(6 + civ._city_zones_count[cid] / 3, 6, 16)
	var zx0: int = maxi(0, czx - scan_r)
	var zy0: int = maxi(0, czy - scan_r)
	var zx1: int = mini(civ._zone_w - 1, czx + scan_r)
	var zy1: int = mini(civ._zone_h - 1, czy + scan_r)
	var z_owners: PackedInt32Array = civ._zone_city_id
	var z_flags: PackedByteArray = civ._zone_flags
	var z_growth: PackedFloat32Array = civ._zone_farm_growth

	var best_zidx: int = -1
	var best_zx: int = -1
	var best_zy: int = -1
	var best_score: float = -1e9
	var food_yield: float = 0.0
	var need_new_farm: bool = civ._city_farm_count[cid] < desired_farms

	for zy in range(zy0, zy1 + 1):
		var row_off: int = zy * civ._zone_w
		for zx in range(zx0, zx1 + 1):
			var zidx: int = row_off + zx
			if z_owners[zidx] != cid:
				continue
			var fl: int = int(z_flags[zidx])
			if (fl & ZONE_FLAG_FARM) != 0:
				current_farms += 1
				var prev_g: float = z_growth[zidx]
				var next_g: float = minf(1.0, prev_g + scan_step * 0.018 * crop_mul)
				z_growth[zidx] = next_g
				food_yield += (0.28 + next_g * 0.42) * pace_dt * crop_mul
				if int(prev_g * 3.0) != int(next_g * 3.0):
					mark_zone_dirty(civ, zx, zy)
				continue
			if not need_new_farm or (fl & ZONE_FLAG_BUILT) != 0:
				continue
			var score: float = _score_farm_candidate(civ, zx, zy, zidx, fid)
			if score > best_score:
				best_score = score
				best_zidx = zidx
				best_zx = zx
				best_zy = zy

	if current_farms < desired_farms and best_zidx >= 0 and best_score > 0.0:
		z_flags[best_zidx] |= ZONE_FLAG_FARM
		z_growth[best_zidx] = 0.10
		current_farms += 1
		mark_zone_dirty(civ, best_zx, best_zy)
	civ._city_farm_count[cid] = current_farms
	return food_yield


func _score_farm_candidate(civ: Node2D, zx: int, zy: int, zidx: int, fid: int) -> float:
	var px: int = clampi(zx * civ._zone_px + 4, 0, civ._map_w - 1)
	var py: int = clampi(zy * civ._zone_px + 4, 0, civ._map_h - 1)
	if civ._world == null:
		return 10.0
	var idx: int = py * civ._map_w + px
	var t: int = int(_w_tiers_cache[idx]) if not _w_tiers_cache.is_empty() else int(civ._world.get_tier(px, py))
	var b: int = int(_w_biomes_cache[idx]) if not _w_biomes_cache.is_empty() else int(civ._world.get_biome(px, py))
	if t < TIER_SOIL_LOW or t > TIER_HILLS or b == BIOME_LAVA or b == BIOME_SCORCHED:
		return -1.0
	if fid == FACTION_HUMAN:
		if b == BIOME_LUSH:
			return 40.0 + civ._zone_fertility[zidx] * 10.0
		if t <= TIER_SOIL_HIGH:
			return 14.0 + civ._zone_fertility[zidx] * 8.0
		return 6.0 + civ._zone_fertility[zidx] * 4.0
	if fid == FACTION_SPORE:
		return 24.0 + civ._zone_fertility[zidx] * 14.0
	return -1.0


func mark_zone_dirty(civ: Node2D, zx: int, zy: int) -> void:
	_ensure_chunk_grid(civ)
	civ._border_dirty = true
	if _all_borders_dirty:
		return
	var zx0: int = maxi(0, zx - 1)
	var zy0: int = maxi(0, zy - 1)
	var zx1: int = mini(civ._zone_w - 1, zx + 1)
	var zy1: int = mini(civ._zone_h - 1, zy + 1)
	var cx0: int = clampi(zx0 / BORDER_CHUNK_ZONES, 0, _chunk_w - 1)
	var cy0: int = clampi(zy0 / BORDER_CHUNK_ZONES, 0, _chunk_h - 1)
	var cx1: int = clampi(zx1 / BORDER_CHUNK_ZONES, 0, _chunk_w - 1)
	var cy1: int = clampi(zy1 / BORDER_CHUNK_ZONES, 0, _chunk_h - 1)
	for cy in range(cy0, cy1 + 1):
		var row_c: int = cy * _chunk_w
		for cx in range(cx0, cx1 + 1):
			var cidx: int = row_c + cx
			if _dirty_chunk_mask[cidx] == 0:
				_dirty_chunk_mask[cidx] = 1
				_dirty_chunks[_dirty_chunk_count] = cidx
				_dirty_chunk_count += 1


func mark_all_borders_dirty(civ: Node2D) -> void:
	_ensure_chunk_grid(civ)
	civ._border_dirty = true
	_all_borders_dirty = true


func compute_zoom_tint_alpha(zoom_val: float) -> int:
	# Macro zoom (1.2x..2.4x): alpha 0.22..0.28 -> 0.25; Close diorama (3.0x..12.0x): alpha 0.03..0.05 -> 0.04
	var t: float = clampf((zoom_val - 2.4) / 0.6, 0.0, 1.0)
	var alpha_f: float = lerpf(0.25, 0.04, t)
	return clampi(int(round(alpha_f * 255.0)), 8, 72)


func flush_dirty_borders(civ: Node2D, force: bool = true) -> void:
	if not civ._border_dirty or civ._border_image == null or civ._border_texture == null:
		return
	if not force and not _all_borders_dirty and civ._border_flush_cd > 0.0:
		return
	_ensure_chunk_grid(civ)
	_refresh_world_byte_caches(civ)
	_refresh_city_color_luts(civ)
	var hi_pace: bool = civ._sim_pace_mult >= 10.0
	civ._border_dirty = false
	civ._border_flush_cd = 0.65 if hi_pace else 0.25
	var flushed_any: bool = false
	if _all_borders_dirty:
		_all_borders_dirty = false
		_dirty_chunk_mask.fill(0)
		_dirty_chunk_count = 0
		_flush_border_rect(civ, 0, 0, civ._map_w, civ._map_h)
		flushed_any = true
	elif _dirty_chunk_count > 0:
		var budget: int = _dirty_chunk_count if force else mini(_dirty_chunk_count, 1 if hi_pace else 4)
		while budget > 0 and _dirty_chunk_count > 0:
			_dirty_chunk_count -= 1
			budget -= 1
			var cidx: int = _dirty_chunks[_dirty_chunk_count]
			_dirty_chunk_mask[cidx] = 0
			var cx: int = cidx % _chunk_w
			var cy: int = cidx / _chunk_w
			var px0: int = cx * BORDER_CHUNK_PX
			var py0: int = cy * BORDER_CHUNK_PX
			var px1: int = mini(civ._map_w, px0 + BORDER_CHUNK_PX)
			var py1: int = mini(civ._map_h, py0 + BORDER_CHUNK_PX)
			_flush_border_rect(civ, px0, py0, px1, py1)
		flushed_any = true
		if _dirty_chunk_count > 0:
			civ._border_dirty = true
	_reset_dirty_bounds(civ)
	if flushed_any:
		civ._border_image.set_data(civ._map_w, civ._map_h, false, Image.FORMAT_RGBA8, civ._border_buf)
		civ._border_texture.update(civ._border_image)


func _refresh_city_color_luts(civ: Node2D) -> void:
	var c_active: PackedByteArray = civ._city_active
	for cid in range(civ._max_cities):
		if c_active[cid] == 0:
			continue
		var c3: int = cid * 3
		var bcol: Color = civ._get_city_border_color(cid)
		var r: int = int(round(bcol.r * 255.0))
		var g: int = int(round(bcol.g * 255.0))
		var b: int = int(round(bcol.b * 255.0))
		_city_rgb_lut[c3] = r
		_city_rgb_lut[c3 + 1] = g
		_city_rgb_lut[c3 + 2] = b
		_city_div_lut[c3] = int(r * 0.72)
		_city_div_lut[c3 + 1] = int(g * 0.72)
		_city_div_lut[c3 + 2] = int(b * 0.72)


func _flush_border_rect(civ: Node2D, px0: int, py0: int, px1: int, py1: int) -> void:
	var bw: int = px1 - px0
	var bh: int = py1 - py0
	if bw <= 0 or bh <= 0:
		return
	var pad: int = 3
	var pw: int = bw + pad * 2
	var ph: int = bh + pad * 2
	var grid_len: int = pw * ph
	if civ._tmp_own_grid.size() < grid_len:
		civ._tmp_own_grid.resize(grid_len)
		civ._tmp_eff_grid.resize(grid_len)
		civ._tmp_edge_grid.resize(grid_len)
	_fill_owner_grid(civ, px0, py0, pw, ph, pad)
	_chamfer_owner_grid(civ, pw, ph)
	_detect_edge_grid(civ, pw, ph)
	_paint_border_region(civ, px0, py0, px1, py1, pw, pad)


func _reset_dirty_bounds(civ: Node2D) -> void:
	civ._dirty_zx0 = civ._zone_w
	civ._dirty_zy0 = civ._zone_h
	civ._dirty_zx1 = -1
	civ._dirty_zy1 = -1


func _fill_owner_grid(civ: Node2D, px0: int, py0: int, pw: int, ph: int, pad: int) -> void:
	var own_g: PackedInt32Array = civ._tmp_own_grid
	var z_owners: PackedInt32Array = civ._zone_city_id
	var c_active: PackedByteArray = civ._city_active
	var w_tiers: PackedByteArray = _w_tiers_cache
	var has_fast_tiers: bool = not w_tiers.is_empty()
	var mw: int = civ._map_w
	var mh: int = civ._map_h
	var zw: int = civ._zone_w
	var zpx: int = civ._zone_px
	for gy in range(ph):
		var wy: int = py0 - pad + gy
		var row_g: int = gy * pw
		if wy < 0 or wy >= mh:
			for gx in range(pw):
				own_g[row_g + gx] = -1
			continue
		var z_row: int = (wy / zpx) * zw
		var w_row: int = wy * mw
		var prev_zx: int = -1
		var cached_cid: int = -1
		for gx in range(pw):
			var wx: int = px0 - pad + gx
			if wx < 0 or wx >= mw:
				own_g[row_g + gx] = -1
				continue
			var zx_c: int = wx / zpx
			if zx_c != prev_zx:
				prev_zx = zx_c
				cached_cid = z_owners[z_row + zx_c]
			var cid: int = cached_cid
			if cid < 0 or c_active[cid] == 0:
				own_g[row_g + gx] = -1
				continue
			var wt: int = int(w_tiers[w_row + wx]) if has_fast_tiers else (int(civ._world.get_tier(wx, wy)) if civ._world != null else TIER_SOIL_LOW)
			if wt <= TIER_CLOSE_OCEAN:
				own_g[row_g + gx] = -1
				continue
			own_g[row_g + gx] = cid


func _chamfer_owner_grid(civ: Node2D, pw: int, ph: int) -> void:
	var own_g: PackedInt32Array = civ._tmp_own_grid
	var eff_g: PackedInt32Array = civ._tmp_eff_grid
	for gy in range(1, ph - 1):
		var row_g: int = gy * pw
		var row_n: int = (gy - 1) * pw
		var row_s: int = (gy + 1) * pw
		for gx in range(1, pw - 1):
			var gi: int = row_g + gx
			var c: int = own_g[gi]
			if c < 0:
				eff_g[gi] = -1
				continue
			var n: int = own_g[row_n + gx]
			var s: int = own_g[row_s + gx]
			var w: int = own_g[gi - 1]
			var e: int = own_g[gi + 1]
			var nw: int = own_g[row_n + gx - 1]
			var ne: int = own_g[row_n + gx + 1]
			var sw: int = own_g[row_s + gx - 1]
			var se: int = own_g[row_s + gx + 1]
			var outer_c: bool = (
				(n < 0 and w < 0 and s == c and e == c and se == c)
				or (n < 0 and e < 0 and s == c and w == c and sw == c)
				or (s < 0 and w < 0 and n == c and e == c and ne == c)
				or (s < 0 and e < 0 and n == c and w == c and nw == c)
			)
			eff_g[gi] = -1 if outer_c else c


func _detect_edge_grid(civ: Node2D, pw: int, ph: int) -> void:
	var kids: PackedInt32Array = civ._city_kingdom_id
	var eff_g: PackedInt32Array = civ._tmp_eff_grid
	var edge_g: PackedByteArray = civ._tmp_edge_grid
	for gy in range(2, ph - 2):
		var row_g: int = gy * pw
		for gx in range(2, pw - 2):
			var gi: int = row_g + gx
			var c: int = eff_g[gi]
			if c < 0:
				edge_g[gi] = 0
				continue
			var kc: int = kids[c]
			var cn: int = eff_g[gi - pw]
			var cs: int = eff_g[gi + pw]
			var cw: int = eff_g[gi - 1]
			var ce: int = eff_g[gi + 1]
			var is_outer: bool = (
				cn < 0 or cs < 0 or cw < 0 or ce < 0
				or kids[cn] != kc or kids[cs] != kc or kids[cw] != kc or kids[ce] != kc
			)
			if is_outer:
				edge_g[gi] = 1
			elif cn != c or cs != c or cw != c or ce != c:
				edge_g[gi] = 2
			else:
				edge_g[gi] = 0


func _paint_border_region(civ: Node2D, px0: int, py0: int, px1: int, py1: int, pw: int, pad: int) -> void:
	var tint_a: int = compute_zoom_tint_alpha(civ._zoom_val)
	var edge_a: int = civ._k_border_line_a
	var back_a: int = civ._k_border_back_a
	var div_a: int = 135 if civ._zoom_val <= 2.6 else 78
	var vein_lum: float = civ._k_conduit_vein_lum
	var zpx: int = civ._zone_px
	var zw: int = civ._zone_w
	var mw: int = civ._map_w
	var mh: int = civ._map_h
	var has_cond: bool = civ._road_conduit_count > 0
	var eff_g: PackedInt32Array = civ._tmp_eff_grid
	var edge_g: PackedByteArray = civ._tmp_edge_grid
	var buf: PackedByteArray = civ._border_buf
	var rm: PackedByteArray = civ._road_mask
	var zf_arr: PackedByteArray = civ._zone_flags
	var rebels: PackedByteArray = civ._city_is_rebel
	var w_tiers: PackedByteArray = _w_tiers_cache
	var has_fast_tiers: bool = not w_tiers.is_empty()

	for py in range(py0, py1):
		var gy: int = (py - py0) + pad
		var row_g: int = gy * pw
		var row_off: int = py * mw
		var z_row: int = (py / zpx) * zw
		var ly: int = py % zpx
		for px in range(px0, px1):
			var gi: int = row_g + (px - px0) + pad
			var idx: int = row_off + px
			var p: int = idx * 4
			var owner: int = eff_g[gi]
			var edge_v: int = int(edge_g[gi])

			if owner >= 0 and edge_v == 1:
				if rebels[owner] != 0 and ((px + py) & 3) == 0:
					buf[p] = 255
					buf[p + 1] = 225
					buf[p + 2] = 86
				else:
					var o3: int = owner * 3
					buf[p] = _city_rgb_lut[o3]
					buf[p + 1] = _city_rgb_lut[o3 + 1]
					buf[p + 2] = _city_rgb_lut[o3 + 2]
				buf[p + 3] = edge_a
				continue

			if owner < 0 and (edge_g[gi - pw] == 1 or edge_g[gi + pw] == 1 or edge_g[gi - 1] == 1 or edge_g[gi + 1] == 1):
				buf[p] = 16
				buf[p + 1] = 24
				buf[p + 2] = 36
				buf[p + 3] = back_a
				continue

			if owner >= 0 and edge_v == 2 and (((px + py) & 1) == 0):
				var d3: int = owner * 3
				buf[p] = _city_div_lut[d3]
				buf[p + 1] = _city_div_lut[d3 + 1]
				buf[p + 2] = _city_div_lut[d3 + 2]
				buf[p + 3] = div_a
				continue

			var road_val: int = int(rm[idx])
			if road_val != ROAD_NONE and (owner >= 0 or (int(w_tiers[idx]) if has_fast_tiers else (int(civ._world.get_tier(px, py)) if civ._world != null else TIER_SOIL_LOW)) > TIER_CLOSE_OCEAN):
				_write_road_px(civ, p, owner, px, py, road_val, vein_lum)
				continue

			if has_cond and ((py > 0 and rm[idx - mw] == ROAD_CONDUIT) or (py + 1 < mh and rm[idx + mw] == ROAD_CONDUIT) or (px > 0 and rm[idx - 1] == ROAD_CONDUIT) or (px + 1 < mw and rm[idx + 1] == ROAD_CONDUIT)):
				if owner >= 0 or (int(w_tiers[idx]) if has_fast_tiers else (int(civ._world.get_tier(px, py)) if civ._world != null else TIER_SOIL_LOW)) > TIER_CLOSE_OCEAN:
					buf[p] = 58
					buf[p + 1] = 72
					buf[p + 2] = 89
					buf[p + 3] = 215
					continue

			if owner >= 0:
				var zidx: int = z_row + (px / zpx)
				var zf: int = int(zf_arr[zidx])
				var lx: int = px % zpx
				if (zf & ZONE_FLAG_FARM) != 0 and (zf & ZONE_FLAG_BUILT) == 0 and lx >= 1 and lx <= 6 and ly >= 1 and ly <= 6:
					if _try_write_farm_px(civ, p, owner, zidx, px, py, lx, ly):
						continue
				var t3: int = owner * 3
				buf[p] = _city_rgb_lut[t3]
				buf[p + 1] = _city_rgb_lut[t3 + 1]
				buf[p + 2] = _city_rgb_lut[t3 + 2]
				buf[p + 3] = tint_a
			else:
				buf[p] = 0
				buf[p + 1] = 0
				buf[p + 2] = 0
				buf[p + 3] = 0


func _write_road_px(civ: Node2D, p: int, owner: int, px: int, py: int, road_val: int, vein_lum: float) -> void:
	var is_spore: bool = owner >= 0 and int(civ._city_faction[owner]) == FACTION_SPORE
	if road_val == ROAD_CONDUIT and not is_spore:
		var cr: float = 0.28
		var cg: float = 0.52
		var cb: float = 0.62
		if owner >= 0:
			var o3: int = owner * 3
			cr = lerpf(float(_city_rgb_lut[o3]) / 255.0, 0.32, 0.45)
			cg = lerpf(float(_city_rgb_lut[o3 + 1]) / 255.0, 0.56, 0.45)
			cb = lerpf(float(_city_rgb_lut[o3 + 2]) / 255.0, 0.66, 0.45)
		civ._border_buf[p] = clampi(int(round(cr * vein_lum * 255.0)), 18, 160)
		civ._border_buf[p + 1] = clampi(int(round(cg * vein_lum * 255.0)), 18, 160)
		civ._border_buf[p + 2] = clampi(int(round(cb * vein_lum * 255.0)), 18, 168)
		civ._border_buf[p + 3] = 232
		return
	var grain: int = ((px * 73856093) ^ (py * 19349663)) & 1
	if is_spore:
		civ._border_buf[p] = 74 if grain == 0 else 62
		civ._border_buf[p + 1] = 88 if grain == 0 else 74
		civ._border_buf[p + 2] = 68 if grain == 0 else 58
		civ._border_buf[p + 3] = 205
	else:
		civ._border_buf[p] = 114 if grain == 0 else 98
		civ._border_buf[p + 1] = 88 if grain == 0 else 76
		civ._border_buf[p + 2] = 64 if grain == 0 else 54
		civ._border_buf[p + 3] = 216


func _try_write_farm_px(civ: Node2D, p: int, owner: int, zidx: int, px: int, py: int, lx: int, ly: int) -> bool:
	if civ._world != null:
		var idx: int = p >> 2
		var t: int = int(_w_tiers_cache[idx]) if not _w_tiers_cache.is_empty() else int(civ._world.get_tier(px, py))
		var b: int = int(_w_biomes_cache[idx]) if not _w_biomes_cache.is_empty() else int(civ._world.get_biome(px, py))
		if t < TIER_SAND or t > TIER_HILLS or b == BIOME_LAVA:
			return false
	var fid: int = int(civ._city_faction[owner])
	var g: float = clampf(civ._zone_farm_growth[zidx], 0.0, 1.0)
	if (ly & 1) == 1:
		if fid == FACTION_SPORE:
			civ._border_buf[p] = 42
			civ._border_buf[p + 1] = 58
			civ._border_buf[p + 2] = 64
		else:
			civ._border_buf[p] = 96
			civ._border_buf[p + 1] = 68
			civ._border_buf[p + 2] = 44
		civ._border_buf[p + 3] = 210
		return true

	if fid == FACTION_SPORE:
		var node_bio: bool = ((lx + ly) & 1) == 0
		civ._border_buf[p] = 60 if node_bio else 142
		civ._border_buf[p + 1] = 198 if node_bio else 84
		civ._border_buf[p + 2] = 148 if node_bio else 212
		civ._border_buf[p + 3] = 222
	elif g >= 0.65:
		var shine: bool = ((lx + (py & 1)) & 1) == 0
		civ._border_buf[p] = 232 if shine else 210
		civ._border_buf[p + 1] = 198 if shine else 174
		civ._border_buf[p + 2] = 74 if shine else 52
		civ._border_buf[p + 3] = 228
	elif g >= 0.35:
		civ._border_buf[p] = 142
		civ._border_buf[p + 1] = 196
		civ._border_buf[p + 2] = 62
		civ._border_buf[p + 3] = 224
	else:
		civ._border_buf[p] = 76
		civ._border_buf[p + 1] = 172
		civ._border_buf[p + 2] = 66
		civ._border_buf[p + 3] = 220
	return true


func collect_ecology_events(civ: Node2D, events_out: Array, cursor: int) -> int:
	events_out.clear()
	var b_count: int = civ._bld_count
	if b_count > 0:
		var max_b: int = mini(b_count, 10)
		for step in range(max_b):
			var bi: int = (cursor + step) % b_count
			var bt: int = int(civ._bld_type[bi])
			if bt != BLD_DRILL and bt != BLD_FUSION_REACTOR:
				continue
			var bp: Vector2 = civ._bld_pos[bi]
			var bx: int = clampi(int(floor(bp.x)), 0, civ._map_w - 1)
			var by: int = clampi(int(floor(bp.y)), 0, civ._map_h - 1)
			var heat: float = 11.0 if bt == BLD_FUSION_REACTOR else 5.0
			events_out.append({"kind": ECO_HEATING, "x": bx, "y": by, "val": heat})
			if bt == BLD_DRILL:
				events_out.append({"kind": ECO_ORE_DEPLETE, "x": bx, "y": by, "val": 1.0})
			if events_out.size() >= 10:
				break

	for cid in range(civ._max_cities):
		if events_out.size() >= 14:
			break
		if civ._city_active[cid] == 0:
			continue
		var fid: int = int(civ._city_faction[cid])
		if fid != FACTION_ROBOT and fid != FACTION_SPORE:
			continue
		var c: Vector2 = civ._city_center[cid]
		var ox: int = ((cursor * 5 + cid * 7) % 17) - 8
		var oy: int = ((cursor * 3 + cid * 11) % 17) - 8
		var px: int = clampi(int(floor(c.x)) + ox, 4, civ._map_w - 5)
		var py: int = clampi(int(floor(c.y)) + oy, 4, civ._map_h - 5)
		var kind: int = ECO_ROBOT_PLATE if fid == FACTION_ROBOT else ECO_SPORE_MYCELIUM
		events_out.append({"kind": kind, "x": px, "y": py, "val": 1.0})

	return (cursor + 7) % maxi(1, b_count)
