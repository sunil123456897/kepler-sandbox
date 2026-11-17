extends RefCounted

# Regiment banner-bearer coordination, tech-tiered combat ranges (<=36 px),
# and faction-asymmetric combat resolution for UnitPhysics (no class_name, zero tick allocs).

const MAX_CITIES: int = 64
const MAX_UNITS: int = 720

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

const TASK_HARVEST: int = 2
const TASK_HAUL_DEPOT: int = 3
const CARRY_NONE: int = 255
const RES_FOOD: int = 0

const DIPLO_TOTAL_WAR: int = 2
const DIPLO_REBELLION: int = 3

const MEM_FOUGHT: int = 6
const MEM_DODGED: int = 5
const MEM_SHIELD_SAVED: int = 7
const MEM_INFECTED: int = 13

const STRIP_DODGE: int = 0
const STRIP_BLOCK: int = 1
const STRIP_SHIELD: int = 5
const STRIP_MUTATE: int = 7

const REG_IDLE: int = 0
const REG_GATHER: int = 1
const REG_MARCH: int = 2

var _reg_active: PackedByteArray
var _reg_state: PackedByteArray
var _reg_faction: PackedByteArray
var _reg_color: PackedColorArray
var _reg_leader_uid: PackedInt32Array
var _reg_leader_idx: PackedInt32Array
var _reg_leader_pos: PackedVector2Array
var _reg_rally_pos: PackedVector2Array
var _reg_target_pos: PackedVector2Array
var _reg_count: PackedInt32Array
var _reg_assembled: PackedInt32Array
var _reg_min_squad: PackedInt32Array
var _reg_max_squad: PackedInt32Array
var _reg_gather_timer: PackedFloat32Array
var _reg_has_portal: PackedByteArray
var _reg_use_portal: PackedByteArray
var _reg_portal_pos: PackedVector2Array
var _order_refresh_cd: float = 0.0
var _reg_assign_cd: float = 0.0

var _u_reg_slot: PackedByteArray
var _reg_slot_offsets: PackedVector2Array


func _init() -> void:
	_reg_slot_offsets.resize(12)
	for s in range(12):
		var ang: float = float(s) * 2.399963
		var ring_r: float = 3.5 + float(s % 3) * 2.2
		_reg_slot_offsets[s] = Vector2(cos(ang) * ring_r, sin(ang) * ring_r)
	_reg_active.resize(MAX_CITIES)
	_reg_state.resize(MAX_CITIES)
	_reg_faction.resize(MAX_CITIES)
	_reg_color.resize(MAX_CITIES)
	_reg_leader_uid.resize(MAX_CITIES)
	_reg_leader_idx.resize(MAX_CITIES)
	_reg_leader_pos.resize(MAX_CITIES)
	_reg_rally_pos.resize(MAX_CITIES)
	_reg_target_pos.resize(MAX_CITIES)
	_reg_count.resize(MAX_CITIES)
	_reg_assembled.resize(MAX_CITIES)
	_reg_min_squad.resize(MAX_CITIES)
	_reg_max_squad.resize(MAX_CITIES)
	_reg_gather_timer.resize(MAX_CITIES)
	_reg_has_portal.resize(MAX_CITIES)
	_reg_use_portal.resize(MAX_CITIES)
	_reg_portal_pos.resize(MAX_CITIES)
	_u_reg_slot.resize(MAX_UNITS)
	reset_state()


func reset_state() -> void:
	_reg_active.fill(0)
	_reg_state.fill(REG_IDLE)
	_reg_faction.fill(0)
	_reg_leader_uid.fill(-1)
	_reg_leader_idx.fill(-1)
	_reg_count.fill(0)
	_reg_assembled.fill(0)
	_reg_min_squad.fill(6)
	_reg_max_squad.fill(12)
	_reg_gather_timer.fill(0.0)
	_reg_has_portal.fill(0)
	_reg_use_portal.fill(0)
	_u_reg_slot.fill(0)
	_order_refresh_cd = 0.0
	_reg_assign_cd = 0.0


func _refresh_army_orders(up: Node2D) -> void:
	_reg_active.fill(0)
	_reg_has_portal.fill(0)
	_reg_use_portal.fill(0)
	if up._civ != null and up._has_get_army_orders:
		var raw: Variant = up._civ.call("get_army_orders")
		if raw is Dictionary:
			var orders: Dictionary = raw
			for k in orders.keys():
				var cid: int = int(k)
				if cid < 0 or cid >= MAX_CITIES:
					continue
				var entry_v: Variant = orders[k]
				if not (entry_v is Dictionary):
					continue
				var ord: Dictionary = entry_v
				if not bool(ord.get("active", false)):
					continue
				var is_reb: bool = (cid < up._city_is_rebel.size() and up._city_is_rebel[cid] != 0)
				if is_reb and not up._law_rebellions:
					continue
				if not is_reb and not up._law_diplomacy_wars:
					continue
				_reg_active[cid] = 1
				_reg_faction[cid] = clampi(int(ord.get("faction", up._city_faction[cid] if cid < up._city_faction.size() else 0)), 0, 2)
				var def_col: Color = up._city_color[cid] if cid < up._city_color.size() else Color.CYAN
				var col_v: Variant = ord.get("color", def_col)
				_reg_color[cid] = col_v if col_v is Color else def_col
				var def_dep: Vector2 = up._city_depot_pos[cid] if cid < up._city_depot_pos.size() else Vector2(320.0, 180.0)
				_reg_rally_pos[cid] = Vector2(ord.get("rally_pos", def_dep))
				_reg_target_pos[cid] = Vector2(ord.get("target_pos", def_dep))
				_reg_min_squad[cid] = clampi(int(ord.get("min_squad", 6)), 2, 12)
				_reg_max_squad[cid] = clampi(int(ord.get("max_squad", 12)), 6, 12)
				if bool(ord.get("has_portal", false)):
					_reg_has_portal[cid] = 1
					_reg_portal_pos[cid] = Vector2(ord.get("portal_pos", _reg_rally_pos[cid]))
					if up._count_water_hits(_reg_rally_pos[cid], _reg_target_pos[cid]) >= 2:
						_reg_use_portal[cid] = 1
				elif up._count_water_hits(_reg_rally_pos[cid], _reg_target_pos[cid]) >= 2:
					var dir_s: Vector2 = _reg_target_pos[cid] - _reg_rally_pos[cid]
					if dir_s.length_squared() > 1.0:
						var n_dir: Vector2 = dir_s.normalized()
						var dry_edge: Vector2 = _reg_rally_pos[cid]
						for s in range(1, 48):
							var test_p: Vector2 = _reg_rally_pos[cid] + n_dir * (float(s) * 4.0)
							if test_p.x < 4.0 or test_p.x >= float(up._map_w - 5) or test_p.y < 4.0 or test_p.y >= float(up._map_h - 5):
								break
							if not up._is_walkable_pos(test_p):
								break
							dry_edge = test_p
						_reg_target_pos[cid] = dry_edge

	var n_cities: int = mini(MAX_CITIES, up._city_active.size())
	for cid in range(n_cities):
		if up._city_active[cid] == 0 or _reg_active[cid] != 0:
			continue
		if not up._is_city_at_war(cid):
			_reg_state[cid] = REG_IDLE
			_reg_leader_uid[cid] = -1
			_reg_gather_timer[cid] = 0.0
			continue
		var dep: Vector2 = up._city_depot_pos[cid] if cid < up._city_depot_pos.size() else Vector2(320.0, 180.0)
		if dep.x < 0.0:
			continue
		var tgt: Vector2 = up._find_war_rally_pos(cid, dep)
		var rally: Vector2 = dep.lerp(tgt, 0.25)
		if rally.distance_squared_to(dep) > 400.0:
			rally = dep + (tgt - dep).normalized() * 18.0
		if not up._is_walkable_pos(rally):
			rally = dep
		_reg_active[cid] = 1
		_reg_faction[cid] = up._city_faction[cid] if cid < up._city_faction.size() else 0
		_reg_color[cid] = up._city_color[cid] if cid < up._city_color.size() else Color.CYAN
		_reg_rally_pos[cid] = rally
		_reg_target_pos[cid] = tgt
		_reg_min_squad[cid] = 6
		_reg_max_squad[cid] = 12


func step_regiments(up: Node2D, safe_dt: float) -> void:
	_order_refresh_cd -= safe_dt
	var need_reassign: bool = false
	if _order_refresh_cd <= 0.0:
		_order_refresh_cd = 0.30
		_refresh_army_orders(up)
		need_reassign = true

	var u_cnt: int = mini(up._unit_count, MAX_UNITS)
	var any_active: bool = false
	for cid in range(MAX_CITIES):
		if _reg_active[cid] != 0:
			any_active = true
			var li: int = _reg_leader_idx[cid]
			if li < 0 or li >= u_cnt or up._hp[li] <= 0.0:
				need_reassign = true
	if not any_active or u_cnt <= 0:
		up._u_in_regiment.fill(0)
		_reg_count.fill(0)
		return

	_reg_assign_cd -= safe_dt
	if need_reassign or _reg_assign_cd <= 0.0:
		_reg_assign_cd = 0.22
		_reg_count.fill(0)
		_reg_leader_idx.fill(-1)
		up._u_in_regiment.fill(0)
		_u_reg_slot.fill(0)
		_assign_regiment_members(up, u_cnt)
	_update_regiment_states(up, safe_dt)


func _assign_regiment_members(up: Node2D, u_cnt: int) -> void:
	var hp_arr: PackedFloat32Array = up._hp
	var cid_arr: PackedInt32Array = up._u_city_id
	var role_arr: PackedByteArray = up._u_role
	var uid_arr: PackedInt32Array = up._u_uid
	var carry_arr: PackedByteArray = up._u_carry_type
	# Pass 1: assign professional soldiers and match existing banner-bearers
	for i in range(u_cnt):
		if hp_arr[i] <= 0.0:
			continue
		var cid: int = cid_arr[i]
		if cid < 0 or cid >= MAX_CITIES or _reg_active[cid] == 0:
			continue
		if role_arr[i] != ROLE_SOLDIER:
			continue
		var cnt: int = _reg_count[cid]
		if cnt >= _reg_max_squad[cid]:
			continue
		up._u_in_regiment[i] = 1
		_u_reg_slot[i] = cnt
		_reg_count[cid] = cnt + 1
		if uid_arr[i] == _reg_leader_uid[cid]:
			_reg_leader_idx[cid] = i

	# Pass 2: levy militia (keep builders 100% building; keep >=75% of farmers/miners producing)
	for i in range(u_cnt):
		if hp_arr[i] <= 45.0 or up._u_in_regiment[i] != 0:
			continue
		var cid: int = cid_arr[i]
		if cid < 0 or cid >= MAX_CITIES or _reg_active[cid] == 0:
			continue
		var role: int = int(role_arr[i])
		if role == ROLE_BUILDER or role == ROLE_MUTANT or carry_arr[i] != CARRY_NONE:
			continue
		if (role == ROLE_FARMER or role == ROLE_MINER) and (i & 3) != 0:
			continue
		var target_levy: int = mini(_reg_max_squad[cid], 8)
		var cnt: int = _reg_count[cid]
		if cnt >= target_levy:
			continue
		up._u_in_regiment[i] = 1
		_u_reg_slot[i] = cnt
		_reg_count[cid] = cnt + 1
		if uid_arr[i] == _reg_leader_uid[cid]:
			_reg_leader_idx[cid] = i

	# Pass 3: elect banner-bearer if previous leader fell or unassigned
	for i in range(u_cnt):
		if up._u_in_regiment[i] == 0:
			continue
		var cid: int = cid_arr[i]
		if _reg_leader_idx[cid] < 0:
			_reg_leader_idx[cid] = i
			_reg_leader_uid[cid] = uid_arr[i]
		elif role_arr[i] == ROLE_SOLDIER and role_arr[_reg_leader_idx[cid]] != ROLE_SOLDIER:
			_reg_leader_idx[cid] = i
			_reg_leader_uid[cid] = uid_arr[i]


func _update_regiment_states(up: Node2D, safe_dt: float) -> void:
	var u_cnt: int = mini(up._unit_count, MAX_UNITS)
	var need_gather_count: bool = false
	for cid in range(MAX_CITIES):
		if _reg_active[cid] == 0 or _reg_count[cid] <= 0 or _reg_leader_idx[cid] < 0 or _reg_leader_idx[cid] >= u_cnt:
			_reg_state[cid] = REG_IDLE
			continue
		var l_idx: int = _reg_leader_idx[cid]
		_reg_leader_pos[cid] = Vector2(up._px[l_idx], up._py[l_idx])
		if _reg_state[cid] == REG_GATHER:
			need_gather_count = true

	if need_gather_count and (up._tick_idx & 3) == 0:
		_reg_assembled.fill(0)
		var in_reg: PackedByteArray = up._u_in_regiment
		var cid_arr2: PackedInt32Array = up._u_city_id
		var px_arr: PackedFloat32Array = up._px
		var py_arr: PackedFloat32Array = up._py
		for i in range(u_cnt):
			if in_reg[i] == 0:
				continue
			var cid: int = cid_arr2[i]
			if cid < 0 or cid >= MAX_CITIES or _reg_state[cid] != REG_GATHER:
				continue
			var anchor: Vector2 = _reg_rally_pos[cid]
			var dx: float = px_arr[i] - anchor.x
			var dy: float = py_arr[i] - anchor.y
			if dx * dx + dy * dy <= 576.0:
				_reg_assembled[cid] += 1

	var pace_dt: float = safe_dt * clampf(up._sim_pace_mult, 0.05, 80.0)
	for cid in range(MAX_CITIES):
		if _reg_active[cid] == 0 or _reg_count[cid] <= 0:
			continue
		if _reg_state[cid] == REG_IDLE:
			_reg_state[cid] = REG_GATHER
			_reg_gather_timer[cid] = 0.0
		elif _reg_state[cid] == REG_GATHER:
			_reg_gather_timer[cid] += pace_dt
			var need_n: int = mini(_reg_min_squad[cid], _reg_count[cid])
			if _reg_assembled[cid] >= need_n or _reg_gather_timer[cid] >= 3.5:
				_reg_state[cid] = REG_MARCH
		elif _reg_state[cid] == REG_MARCH:
			if _reg_count[cid] < 2:
				_reg_state[cid] = REG_GATHER
				_reg_gather_timer[cid] = 0.0


func get_regiment_steer(up: Node2D, unit_idx: int, safe_dt: float) -> Vector2:
	if unit_idx >= up._u_in_regiment.size() or up._u_in_regiment[unit_idx] == 0:
		return Vector2.ZERO
	var cid: int = up._u_city_id[unit_idx]
	if cid < 0 or cid >= MAX_CITIES or _reg_active[cid] == 0:
		return Vector2.ZERO

	var phase: int = (unit_idx + up._tick_idx) & 3
	if phase != 0 and up._u_detour_timer[unit_idx] <= 0.0:
		var cached_dir: Vector2 = up._u_steer_dir[unit_idx]
		if cached_dir != Vector2.ZERO:
			var tgt_c: Vector2 = _reg_portal_pos[cid] if (_reg_state[cid] == REG_MARCH and _reg_use_portal[cid] != 0) else (_reg_target_pos[cid] if _reg_state[cid] == REG_MARCH else _reg_rally_pos[cid])
			if absf(up._px[unit_idx] - tgt_c.x) > 8.0 or absf(up._py[unit_idx] - tgt_c.y) > 8.0:
				if up._u_stuck_timer[unit_idx] <= 1.80:
					if phase != 2 or up._is_walkable_tile(int(up._px[unit_idx] + cached_dir.x * 4.5), int(up._py[unit_idx] + cached_dir.y * 4.5)):
						return cached_dir
				elif (phase & 1) != 0:
					return cached_dir

	var slot: int = int(_u_reg_slot[unit_idx])
	var offset: Vector2 = _reg_slot_offsets[slot % 12]
	var goal: Vector2 = _reg_rally_pos[cid] + offset
	if _reg_state[cid] == REG_MARCH:
		var tgt: Vector2 = _reg_portal_pos[cid] if _reg_use_portal[cid] != 0 else _reg_target_pos[cid]
		var lpos: Vector2 = _reg_leader_pos[cid]
		if unit_idx == _reg_leader_idx[cid]:
			goal = tgt
		elif lpos.distance_squared_to(tgt) <= 484.0:
			goal = tgt + offset * 0.75
		else:
			goal = lpos + offset
	if not up._is_walkable_tile(int(goal.x), int(goal.y)):
		goal = _reg_leader_pos[cid] if unit_idx != _reg_leader_idx[cid] else _reg_rally_pos[cid]
	up._cur_steer_goal = goal
	var res: Vector2 = up._harvest_ai.steer_worker(up, unit_idx, safe_dt)
	up._u_steer_dir[unit_idx] = res
	return res


func get_banners(up: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for cid in range(MAX_CITIES):
		if _reg_active[cid] == 0 or _reg_count[cid] < 2:
			continue
		var l_idx: int = _reg_leader_idx[cid]
		if l_idx < 0 or l_idx >= up._unit_count:
			continue
		out.append({
			"pos": Vector2(up._px[l_idx], up._py[l_idx]),
			"faction": int(_reg_faction[cid]),
			"color": _reg_color[cid],
			"count": int(_reg_count[cid]),
		})
	return out


func compute_combat_params(up: Node2D, i: int) -> Vector3:
	var cid: int = up._u_city_id[i]
	var fac: int = int(up._u_faction_id[i])
	var role: int = int(up._u_role[i])
	var tier: int = int(up._city_tech_tier[cid]) if (cid >= 0 and cid < up._city_tech_tier.size()) else 0

	var rng_px: float = 9.5
	var cd_sec: float = up._k_skirmish_cd
	var dmg: float = 10.0

	if role == ROLE_MUTANT:
		return Vector3(10.0, cd_sec * 0.85, 16.0)

	if fac == FACTION_ROBOT:
		cd_sec = up._k_robot_cd
		dmg = up._k_robot_dmg
		if tier <= 1:
			rng_px = 11.0 if role == ROLE_SOLDIER else 8.5
		else:
			rng_px = (28.0 + float(mini(tier, 4) - 2) * 4.0) if role == ROLE_SOLDIER else 11.5
	elif fac == FACTION_SPORE:
		cd_sec = up._k_spore_cd
		dmg = up._k_spore_dmg
		if tier <= 1:
			rng_px = 10.5 if role == ROLE_SOLDIER else 8.0
		else:
			rng_px = (22.0 + float(mini(tier, 4) - 2) * 2.5) if role == ROLE_SOLDIER else 11.0
	else:
		cd_sec = up._k_human_cd
		dmg = up._k_human_dmg
		if tier <= 1:
			rng_px = 9.5 if role == ROLE_SOLDIER else 7.5
		else:
			rng_px = (24.0 + float(mini(tier, 4) - 2) * 3.0) if role == ROLE_SOLDIER else 11.0

	if role != ROLE_SOLDIER:
		cd_sec *= 1.40
		dmg *= 0.58
	if up._cur_is_emp:
		cd_sec *= 1.45
	if up._cur_is_infected:
		cd_sec *= (0.72 if fac == FACTION_SPORE else 0.82)
		if fac == FACTION_SPORE:
			dmg *= 1.18
	return Vector3(rng_px, cd_sec, dmg)


func resolve_target(up: Node2D, i: int, range_px: float) -> void:
	var enemy_idx: int = up._cur_enemy_idx
	if enemy_idx >= 0:
		up._u_target_idx[i] = enemy_idx
		up._u_target_uid[i] = up._u_uid[enemy_idx]
		return

	var role: int = int(up._u_role[i])
	var in_reg: bool = i < up._u_in_regiment.size() and up._u_in_regiment[i] != 0
	var cand_uid: int = up._u_target_uid[i]
	var can_seek: bool = (role == ROLE_SOLDIER or in_reg or up._cur_is_infected or up._cur_is_glitched or up._cur_is_alerted)
	if not can_seek and cand_uid < 0:
		return

	var acq_cd: float = up._u_acq_cd[i] if i < up._u_acq_cd.size() else 0.0
	var px_f: float = up._px[i]
	var py_f: float = up._py[i]
	var cand_slot: int = up._u_target_idx[i]
	var seek_r: float = maxf(range_px, 34.0)
	var seek_r2: float = seek_r * seek_r

	if cand_slot >= 0 and cand_slot < up._unit_count and up._u_uid[cand_slot] == cand_uid and up._hp[cand_slot] > 0.0:
		var cdx: float = px_f - up._px[cand_slot]
		var cdy: float = py_f - up._py[cand_slot]
		var cd2: float = cdx * cdx + cdy * cdy
		if cd2 <= seek_r2 and (((i + up._tick_idx) & 7) != 0 or up._are_units_hostile(i, cand_slot)):
			up._cur_enemy_idx = cand_slot
			up._cur_enemy_x = up._px[cand_slot]
			up._cur_enemy_y = up._py[cand_slot]
			up._cur_enemy_d2 = cd2
			return
		up._u_target_idx[i] = -1
		up._u_target_uid[i] = -1
	elif cand_uid >= 0:
		up._u_target_idx[i] = -1
		up._u_target_uid[i] = -1

	if acq_cd <= 0.0 and can_seek:
		var r_enemy: int = up._find_ranged_enemy_idx(i, px_f, py_f, seek_r)
		if r_enemy >= 0:
			up._u_acq_cd[i] = 0.28 + float((i + up._tick_idx) & 3) * 0.03
			up._u_target_idx[i] = r_enemy
			up._u_target_uid[i] = up._u_uid[r_enemy]
			up._cur_enemy_idx = r_enemy
			up._cur_enemy_x = up._px[r_enemy]
			up._cur_enemy_y = up._py[r_enemy]
			var edx: float = px_f - up._cur_enemy_x
			var edy: float = py_f - up._cur_enemy_y
			up._cur_enemy_d2 = edx * edx + edy * edy
		else:
			up._u_acq_cd[i] = (0.42 if (role == ROLE_SOLDIER or in_reg) else 0.78) + float((i + up._tick_idx) & 3) * 0.06


func execute_attack(up: Node2D, attacker: int, my_range_px: float) -> bool:
	var enemy_idx: int = up._cur_enemy_idx
	if enemy_idx < 0 or up._u_attack_cd[attacker] > 0.0:
		return false
	var atk_r2: float = my_range_px * my_range_px
	if up._cur_enemy_d2 > atk_r2:
		return false

	up._u_attack_cd[attacker] = up._cur_cd_sec
	var px_f: float = up._px[attacker]
	var py_f: float = up._py[attacker]
	var ex: float = up._cur_enemy_x
	var ey: float = up._cur_enemy_y
	var k_dist: float = maxf(sqrt(up._cur_enemy_d2), 0.5)
	var kdx: float = (ex - px_f) / k_dist
	var kdy: float = (ey - py_f) / k_dist
	up._facing[attacker] = 1.0 if kdx >= 0.0 else -1.0
	up._skirmish_count += 1

	var role: int = int(up._u_role[attacker])
	var fac: int = int(up._u_faction_id[attacker])
	var p_src := Vector2(px_f, py_f - 2.5)
	var p_dst := Vector2(ex, ey - 2.5)
	var beam_col: Color = up._get_faction_beam_color(attacker)
	var is_ranged_beam: bool = (role != ROLE_MUTANT and my_range_px > 14.0)
	if is_ranged_beam:
		up._max_shot_dist = maxf(up._max_shot_dist, k_dist)
		var is_heavy: int = 1 if fac == FACTION_ROBOT else 0
		var b_width: float = 1.65 if is_heavy != 0 else (1.25 if fac == FACTION_SPORE else 1.0)
		up._beam_starts.append(p_src)
		up._beam_ends.append(p_dst)
		up._beam_colors.append(beam_col)
		up._beam_widths.append(b_width)
		up._beam_heavy.append(is_heavy)

	up._cur_hit_kdx = kdx
	up._cur_hit_kdy = kdy
	up._cur_hit_src = p_src
	up._cur_hit_dst = p_dst
	up._cur_hit_col = beam_col
	up._cur_hit_ranged = is_ranged_beam

	if _try_defender_dodge(up, enemy_idx):
		return false

	return _apply_hit_damage(up, attacker, enemy_idx)


func _try_defender_dodge(up: Node2D, def_idx: int) -> bool:
	var kdx: float = up._cur_hit_kdx
	var kdy: float = up._cur_hit_kdy
	var def_role: int = int(up._u_role[def_idx])
	var def_fac: int = int(up._u_faction_id[def_idx])
	var def_glitched: bool = (def_idx < up._u_glitch_timer.size() and up._u_glitch_timer[def_idx] > 0.0)
	var human_dodge_p: float = up._k_human_dodge_p
	var dodge_p: float = (human_dodge_p if def_fac == FACTION_HUMAN else (0.14 if def_fac == FACTION_ROBOT else 0.24)) if (def_role == ROLE_SOLDIER or def_role == ROLE_MUTANT) else (0.18 if def_fac == FACTION_HUMAN else 0.10)
	if def_glitched or (def_fac == FACTION_ROBOT and up._is_unit_rain_stunned(def_idx)):
		dodge_p *= 0.20
	if up._u_dodge_cd[def_idx] > 0.0 or up._rng.randf() >= dodge_p:
		return false

	var d_sign: float = 1.0 if ((def_idx + up._tick_idx) & 1) == 0 else -1.0
	var d_spd: float = up._k_human_dodge_spd if def_fac == FACTION_HUMAN else 56.0
	var dvx: float = -kdy * d_sign
	var dvy: float = kdx * d_sign
	if up._world != null and not up._is_walkable_pos(Vector2(up._px[def_idx] + dvx * 5.0, up._py[def_idx] + dvy * 5.0)):
		d_sign = -d_sign
		dvx = -kdy * d_sign
		dvy = kdx * d_sign
		if not up._is_walkable_pos(Vector2(up._px[def_idx] + dvx * 5.0, up._py[def_idx] + dvy * 5.0)):
			dvx = 0.0
			dvy = 0.0
	up._vx[def_idx] = dvx * d_spd
	up._vy[def_idx] = dvy * d_spd
	up._vel[def_idx] = Vector2(up._vx[def_idx], up._vy[def_idx])
	up._knockback_timer[def_idx] = maxf(up._knockback_timer[def_idx], 0.18)
	up._u_dodge_cd[def_idx] = 1.65 if def_fac == FACTION_HUMAN else 1.85
	up._u_dodges[def_idx] += 1
	up._total_dodges += 1
	up._hit_flash_timer[def_idx] = maxf(up._hit_flash_timer[def_idx], 0.14)
	up._record_memory(def_idx, MEM_DODGED)
	if up._fx != null and up._fx.has_method("spawn_reaction_strip") and up._strip_fx_budget > 0:
		up._strip_fx_budget -= 1
		up._fx.call("spawn_reaction_strip", Vector2(up._px[def_idx], up._py[def_idx] - 7.0), STRIP_DODGE)
	if up._skirmish_fx_budget > 0 and up._fx != null:
		up._skirmish_fx_budget -= 1
		if up._cur_hit_ranged:
			up._fx.emit_laser_tracer(up._cur_hit_src, up._cur_hit_dst, up._cur_hit_col)
		up._fx.emit_spark_arc(up._cur_hit_dst, Vector2(-kdy * d_sign, kdx * d_sign), Color(0.55, 0.96, 1.0, 0.95))
	return true


func _apply_hit_damage(up: Node2D, attacker: int, def_idx: int) -> bool:
	var kdx: float = up._cur_hit_kdx
	var kdy: float = up._cur_hit_kdy
	var fac: int = int(up._u_faction_id[attacker])
	var role: int = int(up._u_role[attacker])
	var def_fac: int = int(up._u_faction_id[def_idx])
	var def_cid: int = up._u_city_id[def_idx]
	var def_invuln: bool = (def_idx < up._u_invuln_timer.size() and up._u_invuln_timer[def_idx] > 0.0)
	var died: bool = false

	if not def_invuln:
		var final_dmg: float = up._cur_dmg
		var def_glitched: bool = (def_idx < up._u_glitch_timer.size() and up._u_glitch_timer[def_idx] > 0.0)
		var def_emp: bool = (def_cid >= 0 and def_cid < up._city_emp_timer.size() and up._city_emp_timer[def_cid] > 0.0)
		if def_fac == FACTION_ROBOT and not def_glitched and not def_emp and not up._is_unit_rain_stunned(def_idx):
			final_dmg *= up._k_robot_armor
		elif def_fac == FACTION_HUMAN and up._has_any_biodome and up._is_inside_biodome(up._px[def_idx], up._py[def_idx]):
			final_dmg *= 0.55
			if up._rng.randf() < 0.25:
				up._record_memory(def_idx, MEM_SHIELD_SAVED)
		elif def_fac == FACTION_SPORE and up._cur_hit_ranged:
			final_dmg *= 1.40
			up._u_fire_now[def_idx] = maxf(up._u_fire_now[def_idx], 0.24)
			up._u_has_status[def_idx] = 1
		up._hp[def_idx] -= final_dmg
		if fac == FACTION_SPORE and def_idx < up._u_corrode_timer.size():
			up._u_corrode_timer[def_idx] = maxf(up._u_corrode_timer[def_idx], up._k_spore_corrode_sec)
			up._u_has_status[def_idx] = 1
		if up._cur_is_infected and up._cur_enemy_d2 <= 400.0 and def_fac != FACTION_ROBOT and def_idx < up._u_infected_timer.size() and up._rng.randf() < 0.30:
			var was_clean: bool = up._u_infected_timer[def_idx] <= 0.0
			up._u_infected_timer[def_idx] = maxf(up._u_infected_timer[def_idx], 4.5)
			if was_clean and def_idx < up._u_latent_timer.size():
				up._u_latent_timer[def_idx] = 0.0
			up._u_has_status[def_idx] = 1
			up._record_memory(def_idx, MEM_INFECTED)
			up._next_any_inf = true
			up._any_infected_unit = true
			if was_clean and up._fx != null and up._fx.has_method("spawn_reaction_strip") and up._strip_fx_budget > 0:
				up._strip_fx_budget -= 1
				up._fx.call("spawn_reaction_strip", Vector2(up._px[def_idx], up._py[def_idx] - 7.0), STRIP_MUTATE)

	up._vx[def_idx] += kdx * 36.0
	up._vy[def_idx] += kdy * 36.0
	up._knockback_timer[def_idx] = maxf(up._knockback_timer[def_idx], 0.18)
	up._hit_flash_timer[def_idx] = maxf(up._hit_flash_timer[def_idx], 0.16)
	up._record_memory(attacker, MEM_FOUGHT)
	up._record_memory(def_idx, MEM_FOUGHT)
	if up._hp[def_idx] <= 0.0:
		up._u_kills[attacker] += 1
		died = true
	if up._skirmish_fx_budget > 0 and up._fx != null:
		up._skirmish_fx_budget -= 1
		if up._cur_hit_ranged:
			up._fx.emit_laser_tracer(up._cur_hit_src, up._cur_hit_dst, up._cur_hit_col)
		if not up._cur_hit_ranged or fac == FACTION_SPORE:
			up._fx.emit_spark_arc(up._cur_hit_dst, Vector2(kdx, kdy), up._cur_hit_col if role != ROLE_MUTANT else up.BEAM_COL_MUTANT)
		if role == ROLE_MUTANT and up._skirmish_sfx_cd <= 0.0:
			up._skirmish_sfx_cd = 0.09
			up._fx.play_sfx("skirmish")
	return died


func execute_sparring(up: Node2D, attacker: int, partner: int) -> void:
	var d2: float = up._cur_spar_d2
	up._u_attack_cd[attacker] = 0.85
	up._u_sparring_cd[attacker] = up._rng.randf_range(12.0, 22.0)
	up._u_sparring_cd[partner] = up._rng.randf_range(12.0, 22.0)
	var sx: float = up._px[partner]
	var sy: float = up._py[partner]
	var s_dist: float = maxf(sqrt(d2), 0.5)
	var sdx: float = (sx - up._px[attacker]) / s_dist
	var sdy: float = (sy - up._py[attacker]) / s_dist
	up._facing[attacker] = 1.0 if sdx >= 0.0 else -1.0
	up._skirmish_count += 1
	var sp_dodge_p: float = 0.25 if up._u_role[partner] == ROLE_SOLDIER else 0.15
	if up._u_dodge_cd[partner] <= 0.0 and up._rng.randf() < sp_dodge_p:
		var sd_sign: float = 1.0 if ((partner + up._tick_idx) & 1) == 0 else -1.0
		var svx: float = -sdy * sd_sign
		var svy: float = sdx * sd_sign
		if up._world != null and not up._is_walkable_pos(Vector2(sx + svx * 4.5, sy + svy * 4.5)):
			sd_sign = -sd_sign
			svx = -sdy * sd_sign
			svy = sdx * sd_sign
			if not up._is_walkable_pos(Vector2(sx + svx * 4.5, sy + svy * 4.5)):
				svx = 0.0
				svy = 0.0
		up._vx[partner] = svx * 54.0
		up._vy[partner] = svy * 54.0
		up._vel[partner] = Vector2(up._vx[partner], up._vy[partner])
		up._knockback_timer[partner] = maxf(up._knockback_timer[partner], 0.16)
		up._u_dodge_cd[partner] = 1.8
		up._u_dodges[partner] += 1
		up._total_dodges += 1
		up._hit_flash_timer[partner] = maxf(up._hit_flash_timer[partner], 0.14)
		up._record_memory(partner, MEM_DODGED)
		if up._fx != null and up._fx.has_method("spawn_reaction_strip") and up._strip_fx_budget > 0:
			up._strip_fx_budget -= 1
			up._fx.call("spawn_reaction_strip", Vector2(sx, sy - 7.0), STRIP_DODGE)
	else:
		up._hp[partner] = maxf(45.0, up._hp[partner] - 9.0)
		up._vx[partner] += sdx * 30.0
		up._vy[partner] += sdy * 30.0
		up._knockback_timer[partner] = maxf(up._knockback_timer[partner], 0.18)
		up._hit_flash_timer[partner] = maxf(up._hit_flash_timer[partner], 0.14)
		up._record_memory(attacker, MEM_FOUGHT)
		up._record_memory(partner, MEM_FOUGHT)
		if up._fx != null and up._fx.has_method("spawn_reaction_strip") and up._strip_fx_budget > 0:
			up._strip_fx_budget -= 1
			up._fx.call("spawn_reaction_strip", Vector2(sx, sy - 7.0), STRIP_BLOCK)
		if up._fx != null and up._spar_fx_cd <= 0.0:
			up._spar_fx_cd = 0.25
			up._fx.emit_spark_arc(Vector2(sx, sy - 2.5), Vector2(sdx, sdy), Color(0.95, 0.85, 0.42, 0.90))


func process_spore_biomass_on_death(up: Node2D, dead_idx: int) -> void:
	var sx: float = up._px[dead_idx]
	var sy: float = up._py[dead_idx]
	var r: float = 22.0
	var r2: float = 484.0
	var min_cx: int = clampi(int(sx - r) >> 4, 0, up._grid_w - 1)
	var max_cx: int = clampi(int(sx + r) >> 4, 0, up._grid_w - 1)
	var min_cy: int = clampi(int(sy - r) >> 4, 0, up._grid_h - 1)
	var max_cy: int = clampi(int(sy + r) >> 4, 0, up._grid_h - 1)
	var healed: int = 0
	var deposit_cid: int = -1
	for cy in range(min_cy, max_cy + 1):
		var row_off: int = cy * up._grid_w
		for cx in range(min_cx, max_cx + 1):
			var j: int = up._cell_head[row_off + cx]
			while j != -1:
				if j != dead_idx and up._hp[j] > 0.0 and int(up._u_faction_id[j]) == FACTION_SPORE:
					var dx: float = up._px[j] - sx
					var dy: float = up._py[j] - sy
					if dx * dx + dy * dy <= r2:
						up._hp[j] = minf(100.0, up._hp[j] + 18.0)
						up._hit_flash_timer[j] = maxf(up._hit_flash_timer[j], 0.14)
						if deposit_cid < 0 and up._u_city_id[j] >= 0:
							deposit_cid = up._u_city_id[j]
						healed += 1
						if healed >= 3:
							break
				j = up._unit_next[j]
			if healed >= 3:
				break
		if healed >= 3:
			break
	if deposit_cid >= 0:
		up._deposit_to_civ(deposit_cid, RES_FOOD, 1.2)
	if healed > 0 and up._fx != null and up._impact_fx_cd <= 0.0:
		up._fx.spawn_burst(Vector2(sx, sy), 4, Color(0.45, 0.96, 0.42, 0.85), 14.0, 0.32, -8.0)
