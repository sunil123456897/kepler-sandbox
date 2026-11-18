extends RefCounted

# Worker harvesting, forestry regrowth, self-founding settlement detector,
# and steering helpers for UnitPhysics (zero class_name, zero per-tick allocations).

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
const RES_WOOD: int = 5
const CARRY_NONE: int = 255

const BIOME_RUST: int = 0
const BIOME_LUSH: int = 1
const BIOME_CRYSTAL: int = 2
const BIOME_SCORCHED: int = 3
const BIOME_LAVA: int = 4

const TIER_SHALLOW: int = 2
const TIER_SAND: int = 3
const TIER_HILLS: int = 6
const TIER_SUMMIT: int = 8

const FLORA_TREE_LUSH: int = 0
const FLORA_SHROOM_LUSH: int = 1
const FLORA_RUST_SCRUB: int = 2
const FLORA_CRYSTAL_SMALL: int = 3
const FLORA_CRYSTAL_TALL: int = 4
const FLORA_BOULDER: int = 5
const FLORA_FROST_PINE: int = 7
const FLORA_TREE_CHARRED: int = 8
const FLORA_TREE_ASH: int = 9
const FLORA_SPORE_POD: int = 10
const FLORA_CRYSTAL_CLUSTER: int = 11
const FLORA_LUSH_SAPLING: int = 12
const FLORA_BURNING_BUSH: int = 13
const FLORA_XENO_PALM: int = 14
const FLORA_CRYO_CRYSTAL: int = 15
const FLORA_ACID_WEED: int = 16
const FLORA_SILICA_CACTUS: int = 17
const FLORA_BIOLUM_BELL: int = 18
const FLORA_VOID_TENDRIL: int = 19
const FLORA_MYCELIUM_NODE: int = 20
const FLORA_CYBER_SPIRE: int = 21
const FLORA_MUTAGEN_BULB: int = 22
const FLORA_MONOLITH_SHARD: int = 23

const MASK_CHOP: int = (1 << FLORA_TREE_LUSH) | (1 << FLORA_FROST_PINE) | (1 << FLORA_RUST_SCRUB) | (1 << FLORA_XENO_PALM)
const MASK_FOOD: int = (1 << FLORA_SHROOM_LUSH) | (1 << FLORA_SPORE_POD) | (1 << FLORA_BIOLUM_BELL) | (1 << FLORA_MYCELIUM_NODE)
const MASK_MINERAL: int = (1 << FLORA_CRYSTAL_SMALL) | (1 << FLORA_CRYSTAL_TALL) | (1 << FLORA_CRYSTAL_CLUSTER) | (1 << FLORA_BOULDER) | (1 << FLORA_CRYO_CRYSTAL) | (1 << FLORA_CYBER_SPIRE) | (1 << FLORA_MONOLITH_SHARD)

const ST_CRYO_MASK: int = 1 << 2
const ST_SLEEP_MASK: int = 1 << 11
const TR_GENIUS_BIT: int = 1 << 17
const TR_PACIFIST_BIT: int = 1 << 27

const LAYER_ROUTINE: int = 0
const LAYER_LOGISTICS: int = 1

const MEM_GATHERED: int = 3
const MEM_BUILT: int = 4
const STRIP_FOOD: int = 4

const REGROW_SAPLING_T: float = 25.0
const REGROW_MATURE_T: float = 75.0
const SETTLE_GROUP_RADIUS_PX: float = 24.0
const SETTLE_GROUP_TIME_SEC: float = 4.5
const SETTLE_SOLO_TIME_SEC: float = 12.0

var _sf_group_slots: PackedInt32Array
var _sf_group_count: int = 0
var _sf_group_cx: float = 0.0
var _sf_group_cy: float = 0.0
var _regrow_real_cd: float = 0.0
var _regrow_pace_acc: float = 0.0
var _u_tracked_build_pos: PackedVector2Array = PackedVector2Array()


func _init() -> void:
	_sf_group_slots.resize(32)
	_sf_group_slots.fill(-1)
	_u_tracked_build_pos.resize(720)
	_u_tracked_build_pos.fill(Vector2(-1.0, -1.0))


func reset_state() -> void:
	_sf_group_count = 0
	_regrow_real_cd = 0.0
	_regrow_pace_acc = 0.0
	_u_tracked_build_pos.resize(720)
	_u_tracked_build_pos.fill(Vector2(-1.0, -1.0))


func is_choppable_tree(col: int) -> bool:
	return col == FLORA_TREE_LUSH or col == FLORA_FROST_PINE or col == FLORA_RUST_SCRUB or col == FLORA_XENO_PALM


func is_food_flora(col: int) -> bool:
	return col == FLORA_SHROOM_LUSH or col == FLORA_SPORE_POD or col == FLORA_BIOLUM_BELL or col == FLORA_MYCELIUM_NODE


func is_mineral_flora(col: int) -> bool:
	return col == FLORA_CRYSTAL_SMALL or col == FLORA_CRYSTAL_TALL or col == FLORA_CRYSTAL_CLUSTER or col == FLORA_BOULDER or col == FLORA_CRYO_CRYSTAL or col == FLORA_CYBER_SPIRE or col == FLORA_MONOLITH_SHARD


func _sample_regrow_rate(up: Node2D, fp: Vector2) -> float:
	var moist: float = 0.45
	if up._world != null and up._has_world_moisture:
		var px: int = clampi(int(fp.x), 0, up._map_w - 1)
		var py: int = clampi(int(fp.y), 0, up._map_h - 1)
		moist = clampf(float(up._world.get_moisture(px, py)), 0.0, 1.0)
	return 0.833333 + moist * 0.416667


func convert_tree_to_stump(up: Node2D, f: int) -> void:
	if f < 0 or f >= up._flora_count:
		return
	var fp: Vector2 = up._flora_pos[f]
	up._flora_col[f] = FLORA_TREE_ASH
	up._flora_burn[f] = 0.0
	up._flora_grow[f] = 0.001
	if f < up._flora_grow_rate.size():
		up._flora_grow_rate[f] = _sample_regrow_rate(up, fp)
	up._flora_spring[f] = 0.72
	up._flora_spring_vel[f] = 2.0
	up._flora_shake[f] = 0.9
	up.mark_flora_anim(f)


func _mature_col_for_tile(up: Node2D, fp: Vector2) -> int:
	if up._world == null:
		return FLORA_TREE_LUSH
	var px: int = clampi(int(fp.x), 0, up._map_w - 1)
	var py: int = clampi(int(fp.y), 0, up._map_h - 1)
	var t_idx: int = py * up._map_w + px
	var biome: int = int(up._w_biomes[t_idx]) if not up._w_biomes.is_empty() else int(up._world.get_biome(px, py))
	var tier: int = up._get_tile_tier(px, py)
	if biome == BIOME_CRYSTAL:
		return FLORA_CRYSTAL_SMALL
	if biome >= 5:
		match biome:
			5:
				return FLORA_XENO_PALM
			6:
				return FLORA_CRYO_CRYSTAL
			7:
				return FLORA_ACID_WEED
			8:
				return FLORA_SILICA_CACTUS
			9:
				return FLORA_BIOLUM_BELL
			10:
				return FLORA_MYCELIUM_NODE
			_:
				return FLORA_CYBER_SPIRE
	if tier >= TIER_HILLS:
		return FLORA_FROST_PINE
	if biome == BIOME_LUSH:
		return FLORA_SHROOM_LUSH if up._rng.randf() < 0.25 else FLORA_TREE_LUSH
	return FLORA_RUST_SCRUB if up._rng.randf() < 0.45 else FLORA_TREE_LUSH


func step_flora(up: Node2D, dt: float) -> void:
	var pace_dt: float = dt * clampf(up._sim_pace_mult, 0.05, 80.0)
	_step_flora_sync_slice(up, pace_dt)
	_step_flora_regrowth_timers(up, dt, pace_dt)
	_step_flora_ambient_regrow(up, pace_dt)
	_step_campfire_embers(up)
	_step_flora_burn_and_springs(up, dt, pace_dt)


func _step_flora_sync_slice(up: Node2D, _pace_dt: float) -> void:
	var count: int = mini(up._flora_count, up._flora_pos.size())
	if up._world == null or count <= 0 or (up._tick_idx & 15) != 0:
		return
	var slice: int = mini(8, mini(up._k_flora_sync_slice, count))
	var has_moist: bool = up._has_world_moisture
	up._flora_sync_cursor = up._flora_sync_cursor % count
	for _s in range(slice):
		var cf: int = up._flora_sync_cursor
		up._sync_single_flora(cf, false)
		if cf < up._flora_burn.size() and up._flora_burn[cf] > 0.0 and has_moist:
			var px: int = clampi(int(up._flora_pos[cf].x), 0, up._map_w - 1)
			var py: int = clampi(int(up._flora_pos[cf].y), 0, up._map_h - 1)
			if float(up._world.get_moisture(px, py)) > 0.60 and float(up._world.get_fire(px, py)) < 0.05:
				up._flora_burn[cf] = 0.0
				up._flora_col[cf] = FLORA_TREE_CHARRED
				up.mark_flora_anim(cf)
		up._flora_sync_cursor = (up._flora_sync_cursor + 1) % count


func _step_flora_regrowth_timers(up: Node2D, dt: float, pace_dt: float) -> void:
	_regrow_pace_acc += pace_dt
	_regrow_real_cd -= dt
	if _regrow_real_cd > 0.0:
		return
	_regrow_real_cd = 0.30
	var batch_pace: float = _regrow_pace_acc
	_regrow_pace_acc = 0.0
	var count: int = mini(up._flora_count, mini(up._flora_grow.size(), up._flora_col.size()))
	if count <= 0:
		return
	var grow_mul: float = batch_pace * up._flora_mul
	var grow_rates: PackedFloat32Array = up._flora_grow_rate
	var f_pos: PackedVector2Array = up._flora_pos
	var rates_sz: int = grow_rates.size()
	var any_growing: bool = false
	for f in range(count):
		var g: float = up._flora_grow[f]
		var col: int = int(up._flora_col[f])
		if g <= 0.0:
			if col != FLORA_LUSH_SAPLING:
				continue
			g = REGROW_SAPLING_T
		any_growing = true
		var rate: float = grow_rates[f] if (f < rates_sz and grow_rates[f] > 0.1) else 1.0
		g += grow_mul * rate
		if col == FLORA_TREE_ASH and g >= REGROW_SAPLING_T:
			up._flora_col[f] = FLORA_LUSH_SAPLING
			up._flora_spring[f] = 0.45
			up._flora_spring_vel[f] = 2.8
			up.mark_flora_anim(f)
		elif col == FLORA_LUSH_SAPLING and g >= REGROW_MATURE_T:
			up._flora_col[f] = _mature_col_for_tile(up, f_pos[f])
			g = 0.0
			up._flora_spring[f] = 0.48
			up._flora_spring_vel[f] = 3.2
			up.mark_flora_anim(f)
		up._flora_grow[f] = g
	if not any_growing:
		_regrow_real_cd = 2.4


func _step_flora_ambient_regrow(up: Node2D, pace_dt: float) -> void:
	if up._world == null or up._flora_count >= up.MAX_FLORA:
		return
	up._flora_regrow_cd -= minf(pace_dt, 0.14)
	if up._flora_regrow_cd > 0.0:
		return
	up._flora_regrow_cd = 1.6 / clampf(up._flora_mul, 0.20, 3.0)
	var has_env: bool = up._has_tile_env
	for _try in range(2):
		if up._flora_count >= up.MAX_FLORA:
			break
		var gx: int = up._rng.randi_range(6, up._map_w - 7)
		var gy: int = up._rng.randi_range(6, up._map_h - 7)
		if not up._is_flora_allowed_tile(gx, gy):
			continue
		var cand := Vector2(float(gx) + 0.5, float(gy) + 0.5)
		if up._bld_count > 0 and up._is_inside_any_building(cand, 5.0):
			continue
		var g_biome: int = up._world.get_biome(gx, gy)
		var env: Vector4 = up._world.get_tile_env(gx, gy) if has_env else Vector4(up._world.get_temp(gx, gy), 0.0, 0.0, 0.0)
		if g_biome == BIOME_LAVA or env.x > 65.0 or env.z > 0.10:
			continue
		if g_biome == BIOME_CRYSTAL or env.w >= 0.22 or (g_biome == BIOME_LUSH and up._rng.randf() < 0.45):
			var sprout: int = FLORA_CRYSTAL_CLUSTER if g_biome == BIOME_CRYSTAL else FLORA_LUSH_SAPLING
			var nf: int = up._append_flora_slot(cand, sprout, true)
			if nf >= 0 and sprout == FLORA_LUSH_SAPLING:
				up._flora_grow[nf] = REGROW_SAPLING_T
				if nf < up._flora_grow_rate.size():
					up._flora_grow_rate[nf] = _sample_regrow_rate(up, cand)
				_regrow_real_cd = minf(_regrow_real_cd, 0.30)
			break


func _step_campfire_embers(up: Node2D) -> void:
	if up._fx == null or up._campfire_ember_cd > 0.0 or up._city_active.is_empty():
		return
	up._campfire_ember_cd = 0.28
	var nc: int = up._city_active.size()
	var pick: int = up._rng.randi_range(0, nc - 1)
	for step_c in range(nc):
		var c_id: int = (pick + step_c) % nc
		if up._city_active[c_id] != 0 and c_id < up._city_depot_pos.size() and up._city_depot_pos[c_id].x >= 0.0:
			var cpos: Vector2 = up._city_center[c_id] if c_id < up._city_center.size() else up._city_depot_pos[c_id]
			var fac_c: int = int(up._city_faction[c_id]) if c_id < up._city_faction.size() else FACTION_HUMAN
			var ember_c := Color(0.45, 0.92, 1.0, 0.90) if fac_c == FACTION_ROBOT else (Color(0.55, 1.0, 0.48, 0.88) if fac_c == FACTION_SPORE else Color(1.0, 0.58, 0.18, 0.92))
			up._fx.emit_campfire_ember(cpos + Vector2(up._rng.randf_range(-4.0, 4.0), -3.0), Vector2.ZERO, ember_c)
			break


func _step_flora_burn_and_springs(up: Node2D, dt: float, pace_dt: float) -> void:
	if not up._flora_has_anim or up._flora_anim_count <= 0:
		up._flora_has_anim = false
		return
	up._flora_custom_dirty = true
	var omega: float = up._k_spring_omega
	var zeta: float = up._k_spring_zeta
	var any_anim: bool = false
	var anim_list: PackedInt32Array = up._flora_anim_list
	for k in range(up._flora_anim_count):
		var f: int = anim_list[k]
		if f < 0 or f >= up._flora_count:
			continue
		if up._flora_burn[f] > 0.0:
			var nb: float = up._flora_burn[f] - pace_dt
			up._flora_burn[f] = nb
			if nb <= 0.0:
				up._flora_burn[f] = 0.0
				up._flora_col[f] = FLORA_TREE_ASH
				up._flora_grow[f] = 0.001
				_regrow_real_cd = minf(_regrow_real_cd, 0.30)
				if f < up._flora_grow_rate.size():
					up._flora_grow_rate[f] = _sample_regrow_rate(up, up._flora_pos[f])
				if up._fx != null and up._rng.randf() < 0.35:
					up._fx.spawn_burst(up._flora_pos[f] + Vector2(0.0, -4.0), 2, Color(0.42, 0.40, 0.38, 0.72), 10.0, 0.45, -8.0)
			else:
				any_anim = true
				if up._fx != null and up._rng.randf() < dt * 0.65:
					up._fx.emit_campfire_ember(up._flora_pos[f] + Vector2(0.0, -5.0), Vector2.ZERO, Color(1.0, 0.52, 0.14, 0.95))
		var sh: float = up._flora_shake[f]
		if sh > 0.0:
			var nsh: float = maxf(0.0, sh - dt * 2.4)
			up._flora_shake[f] = nsh
			if nsh > 0.0:
				any_anim = true
		var sp: float = up._flora_spring[f]
		var sv: float = up._flora_spring_vel[f]
		if absf(sp - 1.0) > 0.002 or absf(sv) > 0.002:
			var force: float = -omega * omega * (sp - 1.0) - 2.0 * zeta * omega * sv
			sv += force * dt
			sp += sv * dt
			if absf(sp - 1.0) < 0.002 and absf(sv) < 0.01:
				sp = 1.0
				sv = 0.0
			else:
				any_anim = true
			up._flora_spring[f] = clampf(sp, 0.42, 1.35)
			up._flora_spring_vel[f] = sv
	up._flora_has_anim = any_anim


func _fast_water_hits_capped(up: Node2D, w_tiers: PackedByteArray, dims: Vector2i, a: Vector2, b: Vector2, max_hits: int) -> int:
	if up._world == null:
		return 0
	var mw: int = dims.x
	var mh: int = dims.y
	if up._cur_frost_tiles == 0 and w_tiers.size() == mw * mh:
		var hits: int = 0
		var ax: float = a.x
		var ay: float = a.y
		var dx: float = b.x - ax
		var dy: float = b.y - ay
		for s in range(1, 4):
			var t: float = float(s) * 0.25
			var px: int = clampi(int(ax + dx * t), 0, mw - 1)
			var py: int = clampi(int(ay + dy * t), 0, mh - 1)
			var tier: int = int(w_tiers[py * mw + px])
			if tier <= TIER_SHALLOW or tier >= TIER_SUMMIT:
				hits += 1
				if hits > max_hits:
					return hits
		return hits
	return up._count_water_hits(a, b)


func find_nearest_flora(up: Node2D, unit_idx: int, mode: int) -> int:
	# mode: 0 = farm/wood, 1 = mineral/ore, 2 = food priority
	if up._flora_count <= 0:
		return -1
	if unit_idx >= 0 and unit_idx < up._u_goal_cd.size() and up._u_goal_cd[unit_idx] > 0.0:
		if mode != 2 or int(up._u_alert_layer[unit_idx]) != LAYER_LOGISTICS:
			return -1
	if up._flora_hash_dirty:
		up._rebuild_flora_hash()
	var anchor: Vector2 = up._harv_anchor
	var max_radius: float = up._harv_radius
	var cr: int = clampi(ceili(max_radius / float(up._cell_size)), 1, 6)
	var acx: int = clampi(int(anchor.x) >> 4, 0, up._grid_w - 1)
	var acy: int = clampi(int(anchor.y) >> 4, 0, up._grid_h - 1)
	var x0: int = maxi(0, acx - cr)
	var x1: int = mini(up._grid_w - 1, acx + cr)
	var y0: int = maxi(0, acy - cr)
	var y1: int = mini(up._grid_h - 1, acy + cr)
	var max_r2: float = max_radius * max_radius
	var unit_pos := Vector2(up._px[unit_idx], up._py[unit_idx])
	var fac: int = int(up._u_faction_id[unit_idx])
	var best_f: int = -1
	var best_score: float = 1e18
	var f_head: PackedInt32Array = up._flora_cell_head
	var f_next: PackedInt32Array = up._flora_next
	var f_col: PackedByteArray = up._flora_col
	var f_pos: PackedVector2Array = up._flora_pos
	var w_tiers: PackedByteArray = up._w_tiers
	var dims := Vector2i(up._map_w, up._map_h)
	var gw: int = up._grid_w
	var kind_mask: int = MASK_MINERAL if mode == 1 else (MASK_CHOP | MASK_FOOD)

	for cy in range(y0, y1 + 1):
		var row_off: int = cy * gw
		for cx in range(x0, x1 + 1):
			var f: int = f_head[row_off + cx]
			while f != -1:
				var col: int = int(f_col[f])
				var bit: int = (1 << col) if col < 32 else 0
				if (bit & kind_mask) != 0:
					var fp: Vector2 = f_pos[f]
					var fdx: float = fp.x - anchor.x
					var fdy: float = fp.y - anchor.y
					var d2: float = fdx * fdx + fdy * fdy
					if d2 <= max_r2:
						var spread: float = float((unit_idx * 17 + f * 31) & 15) * 18.0
						var bonus: float = 0.0
						if mode == 2 and (bit & MASK_FOOD) != 0:
							bonus = -280.0
						elif mode == 0 and (bit & MASK_CHOP) != 0:
							bonus = -90.0
						if fac == FACTION_SPORE and (bit & MASK_FOOD) != 0:
							bonus -= 140.0
						var base_score: float = d2 + spread + bonus
						if base_score < best_score:
							var max_hits: int = 0 if (base_score + 900.0 >= best_score) else 1
							var water_hits: int = _fast_water_hits_capped(up, w_tiers, dims, unit_pos, fp, max_hits)
							if water_hits <= max_hits:
								var score: float = base_score + float(water_hits) * 900.0
								if score < best_score:
									best_score = score
									best_f = f
				f = f_next[f]
	if best_f < 0 and unit_idx >= 0 and unit_idx < up._u_goal_cd.size():
		up._u_goal_cd[unit_idx] = 0.85 + float(unit_idx & 7) * 0.08
	return best_f


func assign_worker_goal(up: Node2D, unit_idx: int, city_id: int) -> void:
	if unit_idx < 0 or unit_idx >= up._unit_count or city_id < 0:
		return
	var depot: Vector2 = up._u_depot_pos[unit_idx]
	if city_id < up._city_depot_pos.size() and up._city_depot_pos[city_id].x >= 0.0:
		depot = up._city_depot_pos[city_id]
		up._u_depot_pos[unit_idx] = depot

	var unit_pos := Vector2(up._px[unit_idx], up._py[unit_idx])
	var role: int = int(up._u_role[unit_idx])
	up._u_flora_idx[unit_idx] = -1
	up._u_stuck_timer[unit_idx] = 0.0
	up._u_detour_timer[unit_idx] = 0.0

	var hunger: float = up._city_hunger_cache[city_id] if (city_id < up._city_hunger_cache.size()) else 0.0
	var has_build_site: bool = (city_id < up._city_build_pos.size() and up._city_build_pos[city_id].x >= 0.0)
	var urgent_food: bool = hunger >= 0.45 and (role == ROLE_FARMER or role == ROLE_FREE or (role == ROLE_MINER and hunger >= 0.65 and (unit_idx & 1) == 0) or (role == ROLE_BUILDER and not has_build_site and hunger >= 0.65))
	if urgent_food:
		up._u_alert_layer[unit_idx] = LAYER_LOGISTICS
		up._harv_anchor = depot
		up._harv_radius = 78.0
		var f_food: int = find_nearest_flora(up, unit_idx, 2)
		if f_food >= 0:
			up._u_flora_idx[unit_idx] = f_food
			up._u_target_pos[unit_idx] = up._flora_pos[f_food]
		else:
			up._u_target_pos[unit_idx] = up._find_walkable_offset(depot, 6.0, 28.0, true)
		up._u_task[unit_idx] = TASK_MOVE_GOAL
		up._u_last_dist[unit_idx] = unit_pos.distance_to(up._u_target_pos[unit_idx])
		return

	if up._u_alert_layer[unit_idx] == LAYER_LOGISTICS:
		up._u_alert_layer[unit_idx] = LAYER_ROUTINE

	if up._is_city_at_war(city_id) and role == ROLE_FREE:
		var wrally: Vector2 = up._find_war_rally_pos(city_id, unit_pos)
		up._u_target_pos[unit_idx] = up._find_walkable_offset(wrally, 2.0, 14.0, false)
		up._u_task[unit_idx] = TASK_PATROL
		up._u_work_timer[unit_idx] = 1.25
		up._u_last_dist[unit_idx] = unit_pos.distance_to(up._u_target_pos[unit_idx])
		return

	_assign_role_goal(up, unit_idx, city_id)
	up._u_last_dist[unit_idx] = unit_pos.distance_to(up._u_target_pos[unit_idx])


func _assign_role_goal(up: Node2D, unit_idx: int, city_id: int) -> void:
	var depot: Vector2 = up._u_depot_pos[unit_idx]
	var unit_pos := Vector2(up._px[unit_idx], up._py[unit_idx])
	var role: int = int(up._u_role[unit_idx])
	match role:
		ROLE_FARMER:
			up._harv_anchor = depot
			up._harv_radius = 72.0
			var mode: int = 2 if (unit_idx & 1) == 0 else 0
			var f: int = find_nearest_flora(up, unit_idx, mode)
			if f >= 0:
				up._u_flora_idx[unit_idx] = f
				up._u_target_pos[unit_idx] = up._flora_pos[f]
			else:
				up._u_target_pos[unit_idx] = up._find_walkable_offset(depot, 6.0, 26.0, true)
			up._u_task[unit_idx] = TASK_MOVE_GOAL
		ROLE_MINER:
			var anchor: Vector2 = depot
			if city_id < up._city_mine_pos.size() and up._city_mine_pos[city_id].x >= 0.0:
				var mpos: Vector2 = up._city_mine_pos[city_id]
				if up._is_walkable_pos(mpos) and up._count_water_hits(unit_pos, mpos) < 2:
					anchor = mpos
			up._harv_anchor = anchor
			up._harv_radius = 72.0
			var mf: int = find_nearest_flora(up, unit_idx, 1)
			if mf >= 0:
				up._u_flora_idx[unit_idx] = mf
				up._u_target_pos[unit_idx] = up._flora_pos[mf]
			elif anchor != depot:
				up._u_target_pos[unit_idx] = up._find_walkable_offset(anchor, 2.0, 9.0, false)
			else:
				up._u_target_pos[unit_idx] = up._find_walkable_offset(depot, 8.0, 30.0, false)
			up._u_task[unit_idx] = TASK_MOVE_GOAL
		ROLE_BUILDER:
			_assign_builder_goal(up, unit_idx, city_id)
		ROLE_SOLDIER:
			_assign_soldier_goal(up, unit_idx, city_id)
		_:
			up._u_task[unit_idx] = TASK_IDLE
			up._u_target_pos[unit_idx] = depot


func _assign_builder_goal(up: Node2D, unit_idx: int, city_id: int) -> void:
	var depot: Vector2 = up._u_depot_pos[unit_idx]
	var unit_pos := Vector2(up._px[unit_idx], up._py[unit_idx])
	var has_site: bool = (city_id >= 0 and city_id < up._city_build_pos.size() and up._city_build_pos[city_id].x >= 0.0 and up._city_build_pos[city_id].distance_squared_to(depot) > 1.0)
	if unit_idx >= 0 and unit_idx < _u_tracked_build_pos.size():
		_u_tracked_build_pos[unit_idx] = Vector2(-1.0, -1.0)
	if not has_site and (unit_idx & 1) == 1:
		up._harv_anchor = depot
		up._harv_radius = 68.0
		var tf: int = find_nearest_flora(up, unit_idx, 0)
		if tf >= 0:
			up._u_flora_idx[unit_idx] = tf
			up._u_target_pos[unit_idx] = up._flora_pos[tf]
			up._u_task[unit_idx] = TASK_MOVE_GOAL
			return
	var bgoal: Vector2 = depot
	if city_id >= 0 and city_id < up._city_build_pos.size() and up._city_build_pos[city_id].x >= 0.0:
		bgoal = up._city_build_pos[city_id]
		if unit_idx >= 0 and unit_idx < _u_tracked_build_pos.size():
			_u_tracked_build_pos[unit_idx] = bgoal
	if not up._is_walkable_pos(bgoal) or up._count_water_hits(unit_pos, bgoal) >= 2:
		var near_b: Vector2 = up._find_walkable_near(bgoal, 8.0)
		if up._is_walkable_pos(near_b) and up._count_water_hits(unit_pos, near_b) < 2:
			bgoal = near_b
		else:
			bgoal = up._find_walkable_offset(depot, 5.0, 16.0, false)
	up._u_target_pos[unit_idx] = bgoal
	up._u_task[unit_idx] = TASK_MOVE_GOAL


func _assign_soldier_goal(up: Node2D, unit_idx: int, city_id: int) -> void:
	var depot: Vector2 = up._u_depot_pos[unit_idx]
	var unit_pos := Vector2(up._px[unit_idx], up._py[unit_idx])
	var panchor: Vector2 = depot
	var patrol_r: float = up._k_patrol_radius
	var at_war: bool = up._is_city_at_war(city_id)
	var alerted: bool = (city_id < up._city_alerted.size() and up._city_alerted[city_id] != 0)
	if at_war:
		panchor = up._find_war_rally_pos(city_id, unit_pos)
		patrol_r = 14.0
	elif alerted and city_id < up._city_threat_pos.size() and up._city_threat_pos[city_id].x >= 0.0:
		var tpos: Vector2 = up._city_threat_pos[city_id]
		if up._is_walkable_pos(tpos) and up._count_water_hits(unit_pos, tpos) < 2:
			panchor = tpos
			patrol_r = 12.0
	elif city_id < up._city_patrol_pos.size() and up._city_patrol_pos[city_id].x >= 0.0:
		var ppos: Vector2 = up._city_patrol_pos[city_id]
		if up._is_walkable_pos(ppos) and up._count_water_hits(unit_pos, ppos) < 2:
			panchor = ppos
	up._u_target_pos[unit_idx] = up._find_walkable_offset(panchor, 2.0, patrol_r, false)
	up._u_task[unit_idx] = TASK_PATROL
	up._u_work_timer[unit_idx] = 0.95 if at_war else (1.2 if alerted else up._rng.randf_range(1.6, 3.0))


func steer_worker(up: Node2D, unit_idx: int, safe_dt: float) -> Vector2:
	var target: Vector2 = up._cur_steer_goal
	var px_f: float = up._px[unit_idx]
	var py_f: float = up._py[unit_idx]
	var dx: float = target.x - px_f
	var dy: float = target.y - py_f
	var dist2: float = dx * dx + dy * dy
	if dist2 < 0.000001:
		return Vector2.ZERO
	var phase: int = (unit_idx + up._tick_idx) & 3
	var det_t: float = up._u_detour_timer[unit_idx]
	var stuck_t: float = up._u_stuck_timer[unit_idx]
	if det_t > 0.0:
		up._u_detour_timer[unit_idx] = maxf(0.0, det_t - safe_dt)
		var d_dir: Vector2 = up._u_detour_dir[unit_idx]
		if (phase & 1) != 0 and d_dir != Vector2.ZERO:
			return d_dir
	elif dist2 > 9.0:
		var cached_s: Vector2 = up._u_steer_dir[unit_idx]
		if phase != 0 and cached_s != Vector2.ZERO:
			if stuck_t <= 1.80:
				if phase != 2 or up._world == null or up._is_walkable_tile(int(px_f + cached_s.x * 4.5), int(py_f + cached_s.y * 4.5)):
					return cached_s
			elif (phase & 1) != 0:
				return cached_s
	var dist: float = sqrt(dist2)
	var dir_x: float = dx / dist
	var dir_y: float = dy / dist
	var direct := Vector2(dir_x, dir_y)
	var eff_dt: float = (safe_dt * 2.0) if det_t > 0.0 else ((safe_dt * 4.0 if (phase == 0 and stuck_t <= 1.80) else (safe_dt * 2.0 if stuck_t > 1.80 else safe_dt)) if dist2 > 9.0 else safe_dt)

	if dist < up._u_last_dist[unit_idx] - maxf(0.01, up._cur_speed_target * eff_dt * 0.20):
		up._u_last_dist[unit_idx] = dist
		stuck_t = maxf(0.0, stuck_t - eff_dt * 1.4)
	else:
		stuck_t += eff_dt
		up._u_last_dist[unit_idx] = minf(up._u_last_dist[unit_idx], dist + 0.05)
	up._u_stuck_timer[unit_idx] = stuck_t

	if det_t > 0.0:
		var d_dir2: Vector2 = up._u_detour_dir[unit_idx]
		if up._world == null or up._is_walkable_tile(int(px_f + d_dir2.x * 4.5), int(py_f + d_dir2.y * 4.5)):
			up._u_steer_dir[unit_idx] = d_dir2
			return d_dir2
		up._u_detour_side[unit_idx] = -up._u_detour_side[unit_idx]
		up._u_detour_dir[unit_idx] = direct.rotated(up._u_detour_side[unit_idx] * 1.65)
		up._u_steer_dir[unit_idx] = up._u_detour_dir[unit_idx]
		return up._u_detour_dir[unit_idx]

	if up._world != null and not up._is_walkable_tile(int(px_f + dir_x * 4.5), int(py_f + dir_y * 4.5)):
		var s: float = up._u_detour_side[unit_idx]
		var cand_a: Vector2 = direct.rotated(s * 1.15)
		var cand_t: Vector2 = direct.rotated(s * 1.65)
		var cand_b: Vector2 = direct.rotated(-s * 1.15)
		if up._is_walkable_tile(int(px_f + cand_a.x * 5.0), int(py_f + cand_a.y * 5.0)):
			up._u_detour_dir[unit_idx] = cand_a
		elif up._is_walkable_tile(int(px_f + cand_t.x * 5.0), int(py_f + cand_t.y * 5.0)):
			up._u_detour_dir[unit_idx] = cand_t
		elif up._is_walkable_tile(int(px_f + cand_b.x * 5.0), int(py_f + cand_b.y * 5.0)):
			up._u_detour_side[unit_idx] = -s
			up._u_detour_dir[unit_idx] = cand_b
		else:
			up._u_detour_side[unit_idx] = -s
			up._u_detour_dir[unit_idx] = -direct
		up._u_detour_timer[unit_idx] = 0.55
		up._u_steer_dir[unit_idx] = up._u_detour_dir[unit_idx]
		return up._u_detour_dir[unit_idx]

	if up._u_stuck_timer[unit_idx] > 1.8:
		var alt: Vector2 = direct.rotated(up._u_detour_side[unit_idx] * 1.1)
		if up._world == null or up._is_walkable_tile(int(px_f + alt.x * 5.0), int(py_f + alt.y * 5.0)):
			up._u_detour_dir[unit_idx] = alt
			up._u_detour_timer[unit_idx] = 0.65
			up._u_steer_dir[unit_idx] = alt
			return alt
	up._u_steer_dir[unit_idx] = direct
	return direct


func _finish_harvest_cycle(up: Node2D, unit_idx: int, cid: int) -> void:
	var f: int = up._u_flora_idx[unit_idx]
	var fcol: int = -1
	if f >= 0 and f < up._flora_count:
		fcol = int(up._flora_col[f])
		up._flora_shake[f] = 1.0
		up._flora_spring_vel[f] = -2.2
		up.mark_flora_anim(f)
	var role: int = int(up._u_role[unit_idx])
	var urgent_food: bool = (up._u_alert_layer[unit_idx] == LAYER_LOGISTICS)
	if up._work_fx_budget > 0:
		up._work_fx_budget -= 1
		up._spawn_work_chips(up._u_target_pos[unit_idx], ROLE_FARMER if urgent_food else role)

	if role == ROLE_BUILDER and not urgent_food and f < 0:
		up._deposit_to_civ(cid, RES_BUILD_WORK, 1.25)
		up._record_memory(unit_idx, MEM_BUILT)
		up._u_flora_idx[unit_idx] = -1
		up._u_task[unit_idx] = TASK_IDLE
		return

	var res_type: int = RES_FOOD
	var res_amt: float = (1.65 if urgent_food else 1.5) * up._crop_mul
	if f >= 0 and is_choppable_tree(fcol):
		convert_tree_to_stump(up, f)
		if not urgent_food:
			res_type = RES_WOOD
			res_amt = 1.60
	elif role == ROLE_MINER and not urgent_food:
		res_type = RES_ORE
		res_amt = 1.5
		if fcol == FLORA_CRYSTAL_TALL:
			res_type = RES_ORE if ((unit_idx + up._tick_idx) & 1) == 0 else RES_SCIENCE
			res_amt = 1.35 if res_type == RES_ORE else 1.2
		elif fcol == FLORA_CRYSTAL_SMALL or fcol == FLORA_CRYSTAL_CLUSTER:
			res_type = RES_ORE if ((unit_idx + up._tick_idx) & 1) == 0 else RES_ENERGY
			res_amt = 1.4
		elif fcol < 0 and up._world != null:
			var tp: Vector2 = up._u_target_pos[unit_idx]
			if up._world.get_biome(clampi(int(tp.x), 0, up._map_w - 1), clampi(int(tp.y), 0, up._map_h - 1)) == BIOME_CRYSTAL:
				res_type = RES_ORE if ((unit_idx + up._tick_idx) & 1) == 0 else RES_ENERGY
				res_amt = 1.35

	var tm: int = up._u_trait_mask[unit_idx] if unit_idx < up._u_trait_mask.size() else 0
	if (tm & (TR_GENIUS_BIT | TR_PACIFIST_BIT)) != 0:
		res_amt *= 1.20
	if res_type == RES_FOOD and up._traits_fauna != null:
		var food_kind: int = 0 if (fcol == FLORA_SHROOM_LUSH or fcol == FLORA_MYCELIUM_NODE) else (2 if fcol == FLORA_SPORE_POD else (4 if fcol == FLORA_BIOLUM_BELL else -1))
		res_amt = up._traits_fauna.on_food_eaten(up, unit_idx, food_kind, res_amt)

	up._u_carry_type[unit_idx] = res_type
	up._u_carry_amt[unit_idx] = res_amt
	up._u_flora_idx[unit_idx] = -1
	up._u_task[unit_idx] = TASK_HAUL_DEPOT
	up._u_target_pos[unit_idx] = up._u_depot_pos[unit_idx]
	up._u_stuck_timer[unit_idx] = 0.0
	up._u_detour_timer[unit_idx] = 0.0
	var ddx: float = up._u_depot_pos[unit_idx].x - up._px[unit_idx]
	var ddy: float = up._u_depot_pos[unit_idx].y - up._py[unit_idx]
	up._u_last_dist[unit_idx] = sqrt(ddx * ddx + ddy * ddy)


func complete_harvest(up: Node2D, unit_idx: int, cid: int) -> void:
	if cid >= 0 and cid < up._city_depot_pos.size() and up._city_depot_pos[cid].x >= 0.0:
		up._u_depot_pos[unit_idx] = up._city_depot_pos[cid]
	_finish_harvest_cycle(up, unit_idx, cid)


func step_worker(up: Node2D, unit_idx: int, safe_dt: float) -> Vector2:
	if unit_idx < up._u_status_mask.size() and (up._u_status_mask[unit_idx] & (ST_CRYO_MASK | ST_SLEEP_MASK)) != 0:
		return Vector2.ZERO
	var cid: int = up._u_city_id[unit_idx]
	if cid < up._city_depot_pos.size() and up._city_depot_pos[cid].x >= 0.0:
		up._u_depot_pos[unit_idx] = up._city_depot_pos[cid]
	if up._u_task[unit_idx] == TASK_IDLE:
		if unit_idx < up._u_goal_cd.size() and up._u_goal_cd[unit_idx] > 0.0:
			return Vector2.ZERO
		assign_worker_goal(up, unit_idx, cid)
		if up._u_task[unit_idx] == TASK_IDLE and unit_idx < up._u_goal_cd.size():
			up._u_goal_cd[unit_idx] = maxf(up._u_goal_cd[unit_idx], 0.65 + float(unit_idx & 7) * 0.06)
			return Vector2.ZERO

	var pos := Vector2(up._px[unit_idx], up._py[unit_idx])
	var task: int = int(up._u_task[unit_idx])
	var role: int = int(up._u_role[unit_idx])
	var pace_dt: float = safe_dt * clampf(up._sim_pace_mult, 0.05, 80.0)

	if task == TASK_HARVEST:
		var dx: float = up._u_target_pos[unit_idx].x - pos.x
		if absf(dx) > 0.1:
			up._facing[unit_idx] = 1.0 if dx >= 0.0 else -1.0
		var f: int = up._u_flora_idx[unit_idx]
		if f >= 0 and f < up._flora_count:
			up._flora_shake[f] = maxf(up._flora_shake[f], 0.55)
			up.mark_flora_anim(f)
		up._u_work_timer[unit_idx] -= pace_dt
		if up._work_fx_budget > 0 and up._rng.randf() < safe_dt * 1.6:
			up._work_fx_budget -= 1
			up._spawn_work_chips(up._u_target_pos[unit_idx], role)
		if up._u_work_timer[unit_idx] <= 0.0:
			_finish_harvest_cycle(up, unit_idx, cid)
		return Vector2.ZERO

	if task == TASK_MOVE_GOAL:
		return _step_worker_move_goal(up, unit_idx, safe_dt)
	if task == TASK_HAUL_DEPOT:
		return _step_worker_haul_depot(up, unit_idx, safe_dt)
	if task == TASK_PATROL:
		up._u_work_timer[unit_idx] -= pace_dt
		var dist_p: float = pos.distance_to(up._u_target_pos[unit_idx])
		if dist_p <= up._k_worker_reach or up._u_work_timer[unit_idx] <= 0.0 or up._u_stuck_timer[unit_idx] > 2.8:
			assign_worker_goal(up, unit_idx, cid)
			return Vector2.ZERO
		up._cur_steer_goal = up._u_target_pos[unit_idx]
		return steer_worker(up, unit_idx, safe_dt)
	return Vector2.ZERO


func _step_worker_move_goal(up: Node2D, unit_idx: int, safe_dt: float) -> Vector2:
	var cid: int = up._u_city_id[unit_idx]
	var pos := Vector2(up._px[unit_idx], up._py[unit_idx])
	var role: int = int(up._u_role[unit_idx])
	var tracked_f: int = up._u_flora_idx[unit_idx]
	if tracked_f >= 0 and tracked_f < up._flora_count:
		var fc: int = int(up._flora_col[tracked_f])
		if up._flora_pos[tracked_f].distance_squared_to(up._u_target_pos[unit_idx]) > 4.0 or fc == FLORA_TREE_ASH or fc == FLORA_LUSH_SAPLING:
			up._u_flora_idx[unit_idx] = -1
			up._u_task[unit_idx] = TASK_IDLE
			return Vector2.ZERO
	if role == ROLE_BUILDER and up._u_alert_layer[unit_idx] != LAYER_LOGISTICS and cid >= 0 and cid < up._city_build_pos.size() and up._city_build_pos[cid].x >= 0.0 and up._city_build_pos[cid].distance_squared_to(up._u_depot_pos[unit_idx]) > 1.0:
		var tracked_bp: Vector2 = _u_tracked_build_pos[unit_idx] if (unit_idx >= 0 and unit_idx < _u_tracked_build_pos.size()) else up._u_target_pos[unit_idx]
		if tracked_bp.x < 0.0 or up._city_build_pos[cid].distance_squared_to(tracked_bp) > 4.0:
			assign_worker_goal(up, unit_idx, cid)
	var tgt_pos: Vector2 = up._u_target_pos[unit_idx]
	var dx_g: float = tgt_pos.x - pos.x
	var dy_g: float = tgt_pos.y - pos.y
	if absf(dx_g) <= 12.0 and absf(dy_g) <= 12.0:
		var dist2: float = dx_g * dx_g + dy_g * dy_g
		var reach: float = up._k_worker_reach
		if (role == ROLE_BUILDER and up._u_alert_layer[unit_idx] != LAYER_LOGISTICS) or up._is_near_building(tgt_pos):
			reach = maxf(reach, 11.5)
		if dist2 <= reach * reach:
			up._u_task[unit_idx] = TASK_HARVEST
			if up._u_alert_layer[unit_idx] == LAYER_LOGISTICS:
				up._u_work_timer[unit_idx] = up._k_harv_farm * 0.85
			elif role == ROLE_BUILDER and tracked_f < 0:
				up._u_work_timer[unit_idx] = up._k_build_ivl
			elif role == ROLE_MINER:
				up._u_work_timer[unit_idx] = up._k_harv_mine
			else:
				up._u_work_timer[unit_idx] = up._k_harv_farm
			if tracked_f >= 0 and tracked_f < up._flora_count:
				up._flora_shake[tracked_f] = maxf(up._flora_shake[tracked_f], 0.85)
				up.mark_flora_anim(tracked_f)
			if up._work_fx_budget > 0:
				up._work_fx_budget -= 1
				up._spawn_work_chips(tgt_pos, role)
			return Vector2.ZERO
	if role == ROLE_BUILDER and tracked_f < 0 and up._u_stuck_timer[unit_idx] > 2.4:
		up._u_target_pos[unit_idx] = up._find_walkable_offset(up._u_depot_pos[unit_idx], 4.0, 12.0, false)
		up._u_stuck_timer[unit_idx] = 0.0
		tgt_pos = up._u_target_pos[unit_idx]
	elif up._u_stuck_timer[unit_idx] > 3.6:
		up._u_flora_idx[unit_idx] = -1
		up._u_task[unit_idx] = TASK_IDLE
		return Vector2.ZERO
	up._cur_steer_goal = tgt_pos
	return steer_worker(up, unit_idx, safe_dt)


func _step_worker_haul_depot(up: Node2D, unit_idx: int, safe_dt: float) -> Vector2:
	var cid: int = up._u_city_id[unit_idx]
	var px_f: float = up._px[unit_idx]
	var py_f: float = up._py[unit_idx]
	var dep_pos: Vector2 = up._u_depot_pos[unit_idx]
	if up._u_target_pos[unit_idx] != dep_pos:
		up._u_target_pos[unit_idx] = dep_pos
	var dx_d: float = dep_pos.x - px_f
	var dy_d: float = dep_pos.y - py_f
	if absf(dx_d) <= 12.0 and absf(dy_d) <= 12.0:
		var depot_reach: float = up._k_depot_reach
		if up._is_near_building(dep_pos):
			depot_reach = maxf(depot_reach, 11.5)
		if dx_d * dx_d + dy_d * dy_d <= depot_reach * depot_reach:
			var carry_type: int = int(up._u_carry_type[unit_idx])
			up._deposit_to_civ(cid, carry_type, up._u_carry_amt[unit_idx])
			up._record_memory(unit_idx, MEM_GATHERED)
			if carry_type == RES_FOOD and cid < up._city_hunger_cache.size() and up._city_hunger_cache[cid] >= 0.45:
				if up._traits_fauna != null:
					up._traits_fauna.on_food_eaten(up, unit_idx, 1, 0.0)
				if up._fx != null and up._fx.has_method("spawn_reaction_strip") and up._strip_fx_budget > 0 and up._rng.randf() < 0.30:
					up._strip_fx_budget -= 1
					up._fx.call("spawn_reaction_strip", Vector2(px_f, py_f - 7.0), STRIP_FOOD)
			up._u_carry_type[unit_idx] = CARRY_NONE
			up._u_carry_amt[unit_idx] = 0.0
			up._u_task[unit_idx] = TASK_IDLE
			assign_worker_goal(up, unit_idx, cid)
			if up._u_task[unit_idx] == TASK_HARVEST:
				return Vector2.ZERO
			up._cur_steer_goal = up._u_target_pos[unit_idx]
			return steer_worker(up, unit_idx, safe_dt)
	up._cur_steer_goal = dep_pos
	return steer_worker(up, unit_idx, safe_dt)


func _gather_same_faction_settlers(up: Node2D, seed_idx: int, fac: int) -> void:
	_sf_group_count = 0
	var sx: float = up._px[seed_idx]
	var sy: float = up._py[seed_idx]
	var r2: float = SETTLE_GROUP_RADIUS_PX * SETTLE_GROUP_RADIUS_PX
	var min_cx: int = clampi(int(sx - SETTLE_GROUP_RADIUS_PX) >> 4, 0, up._grid_w - 1)
	var max_cx: int = clampi(int(sx + SETTLE_GROUP_RADIUS_PX) >> 4, 0, up._grid_w - 1)
	var min_cy: int = clampi(int(sy - SETTLE_GROUP_RADIUS_PX) >> 4, 0, up._grid_h - 1)
	var max_cy: int = clampi(int(sy + SETTLE_GROUP_RADIUS_PX) >> 4, 0, up._grid_h - 1)
	var sum_x: float = 0.0
	var sum_y: float = 0.0
	var cap: int = _sf_group_slots.size()
	for cy in range(min_cy, max_cy + 1):
		var row_off: int = cy * up._grid_w
		for cx in range(min_cx, max_cx + 1):
			var j: int = up._cell_head[row_off + cx]
			while j != -1:
				if up._u_city_id[j] < 0 and up._u_role[j] == ROLE_FREE and int(up._u_faction_id[j]) == fac and up._hp[j] > 0.0:
					if j >= up._u_infected_timer.size() or up._u_infected_timer[j] <= 0.0:
						var dx: float = up._px[j] - sx
						var dy: float = up._py[j] - sy
						if dx * dx + dy * dy <= r2 and _sf_group_count < cap:
							_sf_group_slots[_sf_group_count] = j
							_sf_group_count += 1
							sum_x += up._px[j]
							sum_y += up._py[j]
				j = up._unit_next[j]
	if _sf_group_count > 0:
		var inv_n: float = 1.0 / float(_sf_group_count)
		_sf_group_cx = sum_x * inv_n
		_sf_group_cy = sum_y * inv_n


func step_self_founding(up: Node2D, safe_dt: float) -> void:
	if (up._tick_idx & 3) != 0:
		return
	if not up._law_self_founding or up._civ == null or up._unit_count <= 0:
		return
	if not up._has_can_settle_near or not up._has_try_self_found:
		return
	var eff_dt: float = (safe_dt * 4.0) * clampf(up._sim_pace_mult, 0.05, 80.0)
	var timer_sz: int = up._u_settle_timer.size()
	var inf_sz: int = up._u_infected_timer.size()
	var founded_any: bool = false

	for i in range(up._unit_count):
		if i >= timer_sz or up._u_city_id[i] >= 0 or up._u_role[i] != ROLE_FREE or up._hp[i] <= 0.0:
			continue
		var fac: int = int(up._u_faction_id[i])
		if fac < 0 or fac > FACTION_SPORE:
			continue
		if i < inf_sz and up._u_infected_timer[i] > 0.0:
			up._u_settle_timer[i] = 0.0
			continue
		var tier: int = int(up._u_tier[i])
		if tier < TIER_SAND or tier >= TIER_SUMMIT or up._u_biome[i] == BIOME_LAVA:
			up._u_settle_timer[i] = 0.0
			continue
		var pos := Vector2(up._px[i], up._py[i])
		if up._u_settle_timer[i] <= 0.0 or ((i + (up._tick_idx >> 2)) & 3) == 0:
			if not bool(up._civ.call("can_settle_near", pos)):
				up._u_settle_timer[i] = 0.0
				continue
		up._u_settle_timer[i] += eff_dt
		if founded_any:
			continue
		if up._u_settle_timer[i] < SETTLE_GROUP_TIME_SEC:
			continue
		_gather_same_faction_settlers(up, i, fac)
		var grp_n: int = _sf_group_count
		var req_t: float = SETTLE_GROUP_TIME_SEC if grp_n >= 2 else SETTLE_SOLO_TIME_SEC
		if up._u_settle_timer[i] < req_t or grp_n <= 0:
			continue
		var max_t: float = up._u_settle_timer[i]
		for k in range(grp_n):
			var u_k: int = _sf_group_slots[k]
			if u_k < timer_sz:
				max_t = maxf(max_t, up._u_settle_timer[u_k])
		if max_t < req_t:
			continue
		founded_any = _trigger_self_found(up, i, fac)


func _trigger_self_found(up: Node2D, seed_idx: int, fac: int) -> bool:
	var found_pos := Vector2(_sf_group_cx, _sf_group_cy)
	if not up._is_strictly_dry_land_tile(int(found_pos.x), int(found_pos.y)):
		found_pos = Vector2(up._px[seed_idx], up._py[seed_idx])
	if not bool(up._civ.call("can_settle_near", found_pos)):
		for k in range(_sf_group_count):
			var uk: int = _sf_group_slots[k]
			if uk < up._u_settle_timer.size():
				up._u_settle_timer[uk] = 0.0
		return false

	# Chop nearest resource node to mark pioneer camp clearing
	up._harv_anchor = found_pos
	up._harv_radius = 26.0
	var f_near: int = find_nearest_flora(up, seed_idx, 0)
	if f_near >= 0:
		var fc: int = int(up._flora_col[f_near])
		if is_choppable_tree(fc):
			convert_tree_to_stump(up, f_near)
		else:
			up._flora_shake[f_near] = 1.0
			up.mark_flora_anim(f_near)
		if up._fx != null:
			up._fx.spawn_burst(up._flora_pos[f_near], 5, Color(0.76, 0.62, 0.42, 0.90), 18.0, 0.32, 18.0)

	var founder_uids := PackedInt32Array()
	founder_uids.resize(_sf_group_count)
	for k in range(_sf_group_count):
		founder_uids[k] = up._u_uid[_sf_group_slots[k]]

	var new_cid: int = int(up._civ.call("try_self_found_settlement", found_pos, fac, founder_uids))
	if new_cid >= 0:
		up.recruit_settlers_to_city(new_cid, founder_uids)
		return true

	for k in range(_sf_group_count):
		var uk2: int = _sf_group_slots[k]
		if uk2 < up._u_settle_timer.size():
			up._u_settle_timer[uk2] = 1.5
	return false
