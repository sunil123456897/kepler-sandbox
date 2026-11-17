extends RefCounted

## Kingdom hierarchy, overland/maritime colonizer expeditions, 10-14s plots,
## honest rebellions, diplomacy matrix, wartime zone capture, army orders, and chronicle.
## No class_name to avoid cyclic GDScript references.

const DIPLO_NEUTRAL: int = 0
const DIPLO_PACT: int = 1
const DIPLO_TOTAL_WAR: int = 2
const DIPLO_REBELLION: int = 3

const PLOT_WAR: int = 0
const PLOT_PACT: int = 1
const PLOT_REBEL: int = 2

const FACTION_HUMAN: int = 0
const FACTION_ROBOT: int = 1
const FACTION_SPORE: int = 2

const BLD_CAMPFIRE: int = 0
const BLD_DEPOT: int = 3
const BLD_LAUNCHPAD: int = 7
const BLD_SHIELD_PYLON: int = 8
const BLD_QUANTUM_GATE: int = 9

const SHUTTLE_KIND_COLONIZE: int = 0
const SHUTTLE_KIND_SUPPLY: int = 1
const SHUTTLE_KIND_BOAT: int = 2

const ZONE_FLAG_BUILT: int = 4
const ZONE_FLAG_FARM: int = 1

const STRIP_PACT: int = 8
const STRIP_WAR: int = 9
const STRIP_REBEL: int = 10

const MAX_KINGDOMS: int = 64
const MAX_PLOTS: int = 16
const MAX_EXPEDITIONS: int = 16
const MAX_CHRONICLE: int = 32

const REBEL_IMMUNITY_SEC: float = 180.0
const PLOT_MIN_SEC: float = 10.0
const PLOT_MAX_SEC: float = 14.0
const EXPEDITION_MIN_DIST_PX: float = 72.0
const EXPEDITION_MAX_DIST_PX: float = 160.0

const KINGDOM_PALETTES := [
	[Color("#38F0FF"), Color("#56B8FF"), Color("#2BE0AC"), Color("#78D8FF"), Color("#4AE6D2")],
	[Color("#E63B3B"), Color("#FF6A48"), Color("#D93872"), Color("#FF884D"), Color("#E64C66")],
	[Color("#B84DFF"), Color("#7E5CFF"), Color("#DF52F0"), Color("#9958FF"), Color("#C864E8")],
]

const KINGDOM_NAME_POOLS := [
	["Кеплер", "Меридиан", "Базальт", "Аврора", "Эгида", "Орион", "Зенит", "Веспер"],
	["Феррит", "Матрица", "Анод", "Кварц", "Торус", "Сигма", "Вектор", "Логика"],
	["Мицелий", "Ризома", "Споры", "Крона", "Мхи", "Венец", "Симбиоз", "Гифы"],
]

var _plot_active: PackedByteArray
var _plot_kind: PackedByteArray
var _plot_src_cid: PackedInt32Array
var _plot_dst_cid: PackedInt32Array
var _plot_elapsed: PackedFloat32Array
var _plot_dur: PackedFloat32Array

var _exp_active: PackedByteArray
var _exp_src_cid: PackedInt32Array
var _exp_kingdom_id: PackedInt32Array
var _exp_faction: PackedByteArray
var _exp_pos: PackedVector2Array
var _exp_target: PackedVector2Array
var _exp_settlers: PackedInt32Array
var _exp_step_accum: PackedFloat32Array

var _chronicle: Array[Dictionary] = []
var _army_orders_cache: Dictionary = {}
var _orders_dirty: bool = true
var _allocated: bool = false

var _kingdom_colonize_cd: PackedFloat32Array
var _prev_alerted: PackedByteArray
var _prev_threat: PackedVector2Array
var _best_dist2: PackedFloat32Array
var _active_cids: Array[int] = []


func ensure_allocated() -> void:
	if _allocated:
		return
	_allocated = true
	_plot_active.resize(MAX_PLOTS)
	_plot_kind.resize(MAX_PLOTS)
	_plot_src_cid.resize(MAX_PLOTS)
	_plot_dst_cid.resize(MAX_PLOTS)
	_plot_elapsed.resize(MAX_PLOTS)
	_plot_dur.resize(MAX_PLOTS)

	_exp_active.resize(MAX_EXPEDITIONS)
	_exp_src_cid.resize(MAX_EXPEDITIONS)
	_exp_kingdom_id.resize(MAX_EXPEDITIONS)
	_exp_faction.resize(MAX_EXPEDITIONS)
	_exp_pos.resize(MAX_EXPEDITIONS)
	_exp_target.resize(MAX_EXPEDITIONS)
	_exp_settlers.resize(MAX_EXPEDITIONS)
	_exp_step_accum.resize(MAX_EXPEDITIONS)

	_kingdom_colonize_cd.resize(MAX_KINGDOMS)
	_prev_alerted.resize(MAX_KINGDOMS)
	_prev_threat.resize(MAX_KINGDOMS)
	_best_dist2.resize(MAX_KINGDOMS)
	reset_all()


func reset_all() -> void:
	ensure_allocated()
	_plot_active.fill(0)
	_plot_kind.fill(0)
	_plot_src_cid.fill(-1)
	_plot_dst_cid.fill(-1)
	_plot_elapsed.fill(0.0)
	_plot_dur.fill(12.0)

	_exp_active.fill(0)
	_exp_src_cid.fill(-1)
	_exp_kingdom_id.fill(-1)
	_exp_faction.fill(0)
	_exp_pos.fill(Vector2.ZERO)
	_exp_target.fill(Vector2.ZERO)
	_exp_settlers.fill(4)
	_exp_step_accum.fill(0.0)

	_kingdom_colonize_cd.fill(0.0)
	_prev_alerted.fill(0)
	_prev_threat.fill(Vector2.ZERO)
	_best_dist2.fill(1e12)
	_active_cids.clear()
	_chronicle.clear()
	_army_orders_cache.clear()
	_orders_dirty = true


func push_chronicle(text: String, pos: Vector2, color: Color) -> void:
	if text == "":
		return
	if _chronicle.size() >= MAX_CHRONICLE:
		_chronicle.remove_at(0)
	_chronicle.append({"text": text, "pos": pos, "color": color})


func pop_chronicle_events() -> Array[Dictionary]:
	if _chronicle.is_empty():
		return []
	var out: Array[Dictionary] = _chronicle.duplicate()
	_chronicle.clear()
	return out


func mark_orders_dirty() -> void:
	_orders_dirty = true


func create_kingdom(civ: Node2D, capital_cid: int, is_rebel: bool = false) -> int:
	ensure_allocated()
	var f_id: int = clampi(int(civ._city_faction[capital_cid]), 0, KINGDOM_PALETTES.size() - 1)
	var free_kid: int = -1
	var same_f_count: int = 0
	for kid in range(MAX_KINGDOMS):
		if civ._kingdom_active[kid] == 0:
			if free_kid < 0:
				free_kid = kid
		elif int(civ._kingdom_faction[kid]) == f_id:
			same_f_count += 1
	if free_kid < 0:
		return -1

	civ._kingdom_active[free_kid] = 1
	civ._kingdom_faction[free_kid] = f_id
	civ._kingdom_capital_cid[free_kid] = capital_cid
	civ._kingdom_city_count[free_kid] = 0
	civ._kingdom_name[free_kid] = _pick_kingdom_name(civ, f_id, free_kid, is_rebel)
	if is_rebel:
		civ._kingdom_color[free_kid] = civ.REBEL_TERRITORY_COLOR
	else:
		var pal: Array = KINGDOM_PALETTES[f_id]
		civ._kingdom_color[free_kid] = pal[same_f_count % pal.size()]
	assign_city_to_kingdom(civ, capital_cid, free_kid)
	return free_kid


func _pick_kingdom_name(civ: Node2D, f_id: int, kid: int, is_rebel: bool) -> String:
	var pool: Array = KINGDOM_NAME_POOLS[clampi(f_id, 0, KINGDOM_NAME_POOLS.size() - 1)]
	var base: int = (kid + civ._rng.randi()) % pool.size()
	for off in range(pool.size()):
		var raw_name: String = str(pool[(base + off) % pool.size()])
		var cand: String = ("Вольн. %s" % raw_name) if is_rebel else raw_name
		var used: bool = false
		for other in range(MAX_KINGDOMS):
			if civ._kingdom_active[other] != 0 and civ._kingdom_name[other] == cand:
				used = true
				break
		if not used:
			return cand
	return "%s-%d" % [str(pool[kid % pool.size()]), kid + 1]


func assign_city_to_kingdom(civ: Node2D, cid: int, kid: int) -> void:
	if cid < 0 or cid >= civ._max_cities or kid < 0 or kid >= MAX_KINGDOMS:
		return
	var prev_kid: int = civ._city_kingdom_id[cid]
	if prev_kid == kid:
		return
	if prev_kid >= 0 and prev_kid < MAX_KINGDOMS and civ._kingdom_active[prev_kid] != 0:
		civ._kingdom_city_count[prev_kid] = maxi(0, civ._kingdom_city_count[prev_kid] - 1)
	civ._city_kingdom_id[cid] = kid
	civ._kingdom_city_count[kid] += 1
	civ._city_color[cid] = civ._get_city_tint_color(cid)
	civ._diplo_dirty_seq += 1
	civ._light_goals_dirty = true
	_orders_dirty = true


func on_city_collapsed(civ: Node2D, cid: int) -> void:
	var kid: int = civ._city_kingdom_id[cid]
	civ._city_kingdom_id[cid] = -1
	_cancel_plots_involving(cid)
	_cancel_expeditions_from(cid)
	if kid >= 0 and kid < MAX_KINGDOMS and civ._kingdom_active[kid] != 0:
		civ._kingdom_city_count[kid] = maxi(0, civ._kingdom_city_count[kid] - 1)
		if civ._kingdom_capital_cid[kid] == cid:
			var new_cap: int = -1
			for other in range(civ._max_cities):
				if other != cid and civ._city_active[other] != 0 and civ._city_kingdom_id[other] == kid:
					new_cap = other
					break
			if new_cap >= 0:
				civ._kingdom_capital_cid[kid] = new_cap
				civ._city_overlord[new_cap] = -1
			else:
				civ._kingdom_active[kid] = 0
				civ._kingdom_capital_cid[kid] = -1
	civ._diplo_dirty_seq += 1
	_orders_dirty = true


func get_macro_badges(civ: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for kid in range(MAX_KINGDOMS):
		if civ._kingdom_active[kid] == 0:
			continue
		var cap_cid: int = civ._kingdom_capital_cid[kid]
		var total_pop: int = 0
		var cities_cnt: int = 0
		var max_tier: int = 0
		var max_war: int = DIPLO_NEUTRAL
		var has_shield: bool = false
		var is_rebel: bool = false
		var min_loy: float = 100.0
		var max_emp: float = 0.0
		var anchor_cid: int = cap_cid if (cap_cid >= 0 and cap_cid < civ._max_cities and civ._city_active[cap_cid] != 0) else -1

		for cid in range(civ._max_cities):
			if civ._city_active[cid] == 0 or civ._city_kingdom_id[cid] != kid:
				continue
			if anchor_cid < 0:
				anchor_cid = cid
			cities_cnt += 1
			total_pop += civ._city_pop[cid]
			max_tier = maxi(max_tier, int(civ._city_tech_tier[cid]))
			max_war = maxi(max_war, int(civ._city_war_state[cid]))
			if civ._city_bld_counts[cid * civ.BLD_TYPE_COUNT + BLD_SHIELD_PYLON] > 0:
				has_shield = true
			if civ._city_is_rebel[cid] != 0:
				is_rebel = true
			min_loy = minf(min_loy, civ._city_loyalty[cid])
			max_emp = maxf(max_emp, civ._city_emp_timer[cid])

		if cities_cnt <= 0 or anchor_cid < 0:
			continue
		var k_col: Color = civ.REBEL_TERRITORY_COLOR if is_rebel else civ._kingdom_color[kid]
		out.append({
			"kingdom_id": kid,
			"city_id": anchor_cid,
			"name": civ._kingdom_name[kid],
			"kingdom_name": civ._kingdom_name[kid],
			"pos": civ._city_center[anchor_cid],
			"faction": int(civ._kingdom_faction[kid]),
			"color": k_col,
			"pop": total_pop,
			"total_pop": total_pop,
			"cities_count": cities_cnt,
			"cities": cities_cnt,
			"tech_tier": max_tier,
			"war_state": max_war,
			"is_rebel": is_rebel,
			"has_shield": has_shield,
			"loyalty": min_loy,
			"emp_timer": max_emp,
		})
	return out


func can_city_rebel(civ: Node2D, cid: int) -> bool:
	if not civ._law_rebellions:
		return false
	if cid < 0 or cid >= civ._max_cities or civ._city_active[cid] == 0 or civ._city_is_rebel[cid] != 0:
		return false
	var kid: int = civ._city_kingdom_id[cid]
	if kid < 0 or kid >= MAX_KINGDOMS or civ._kingdom_active[kid] == 0:
		return false
	if civ._kingdom_city_count[kid] < 2:
		return false
	if civ._kingdom_capital_cid[kid] == cid:
		return false
	if civ._city_age_sec[cid] < REBEL_IMMUNITY_SEC:
		return false
	return true


func update_border_clashes(civ: Node2D, pace_dt: float) -> void:
	ensure_allocated()
	var clash_r: float = civ._k_border_clash_dist
	var clash_r2: float = clash_r * clash_r
	var max_c: int = mini(civ._max_cities, MAX_KINGDOMS)
	for cid in range(max_c):
		_prev_alerted[cid] = civ._city_alerted[cid]
		_prev_threat[cid] = civ._city_threat_pos[cid]
		_best_dist2[cid] = 1e12
	civ._tmp_frontier_contacts.fill(0)

	var active_cids: Array[int] = _refresh_alert_timers(civ, pace_dt)
	var pairs: int = _scan_city_proximity_clashes(civ, active_cids, clash_r2, _best_dist2)
	pairs += _scan_zone_frontier_clashes(civ, active_cids, _best_dist2)
	civ._border_clash_count = pairs

	var changed: bool = false
	for cid in active_cids:
		if civ._city_alerted[cid] != _prev_alerted[cid] or civ._city_threat_pos[cid].distance_squared_to(_prev_threat[cid]) > 4.0:
			changed = true
			if civ._city_alerted[cid] != 0:
				civ._refresh_city_targets(cid)
	if changed:
		civ._light_goals_dirty = true
		_orders_dirty = true


func _refresh_alert_timers(civ: Node2D, pace_dt: float) -> Array[int]:
	_active_cids.clear()
	for cid in range(civ._max_cities):
		if civ._city_active[cid] == 0:
			civ._city_alerted[cid] = 0
			civ._city_alert_timer[cid] = 0.0
			continue
		_active_cids.append(cid)
		if civ._city_alert_timer[cid] > 0.0:
			civ._city_alert_timer[cid] = maxf(0.0, civ._city_alert_timer[cid] - pace_dt)
			civ._city_alerted[cid] = 1
		else:
			civ._city_alerted[cid] = 0
	return _active_cids


func _scan_city_proximity_clashes(civ: Node2D, active_cids: Array[int], clash_r2: float, best_dist2: PackedFloat32Array) -> int:
	var pairs: int = 0
	for i in range(active_cids.size()):
		var a: int = active_cids[i]
		for j in range(i + 1, active_cids.size()):
			var b: int = active_cids[j]
			if int(civ._diplo_matrix[a * civ._max_cities + b]) == DIPLO_PACT:
				continue
			if not civ._are_cities_hostile(a, b) and civ._city_kingdom_id[a] == civ._city_kingdom_id[b]:
				continue
			if not civ._are_cities_hostile(a, b) and civ._city_faction[a] == civ._city_faction[b]:
				continue
			var d2: float = civ._city_center[a].distance_squared_to(civ._city_center[b])
			if d2 <= clash_r2:
				civ._tmp_frontier_contacts[a * civ._max_cities + b] += 1
				civ._tmp_frontier_contacts[b * civ._max_cities + a] += 1
				pairs += 1
				_mark_hostile_frontier(civ, a, b, (civ._city_center[a] + civ._city_center[b]) * 0.5, best_dist2)
	return pairs


func _scan_zone_frontier_clashes(civ: Node2D, active_cids: Array[int], best_dist2: PackedFloat32Array) -> int:
	var pairs: int = 0
	var z_owners: PackedInt32Array = civ._zone_city_id
	var zw: int = civ._zone_w
	var zh: int = civ._zone_h
	var zpx: float = float(civ._zone_px)
	for c_id in active_cids:
		var cc: Vector2 = civ._city_center[c_id]
		var czx: int = clampi(int(floor(cc.x / zpx)), 0, zw - 1)
		var czy: int = clampi(int(floor(cc.y / zpx)), 0, zh - 1)
		var b_r: int = clampi(4 + civ._city_zones_count[c_id] / 3, 5, 11)
		var zy_end: int = mini(zh, czy + b_r + 1)
		var zx0: int = maxi(0, czx - b_r)
		var zx_end: int = mini(zw, czx + b_r + 1)
		for zy in range(maxi(0, czy - b_r), zy_end):
			var row_off: int = zy * zw
			for zx in range(zx0, zx_end):
				var zidx: int = row_off + zx
				if z_owners[zidx] != c_id:
					continue
				if zx + 1 < zw:
					var ob_e: int = z_owners[zidx + 1]
					if ob_e != c_id and ob_e >= 0:
						pairs += _check_frontier_pair(civ, c_id, ob_e, Vector2(float(zx + 1) * zpx, (float(zy) + 0.5) * zpx), best_dist2)
				if zy + 1 < zh:
					var ob_s: int = z_owners[zidx + zw]
					if ob_s != c_id and ob_s >= 0:
						pairs += _check_frontier_pair(civ, c_id, ob_s, Vector2((float(zx) + 0.5) * zpx, float(zy + 1) * zpx), best_dist2)
	return pairs


func _check_frontier_pair(civ: Node2D, oa: int, ob: int, fpos: Vector2, best_dist2: PackedFloat32Array) -> int:
	if ob < 0 or ob == oa or civ._city_active[ob] == 0:
		return 0
	if int(civ._diplo_matrix[oa * civ._max_cities + ob]) == DIPLO_PACT:
		return 0
	civ._tmp_frontier_contacts[oa * civ._max_cities + ob] += 1
	civ._tmp_frontier_contacts[ob * civ._max_cities + oa] += 1
	if civ._are_cities_hostile(oa, ob) or int(civ._city_faction[ob]) != int(civ._city_faction[oa]):
		_mark_hostile_frontier(civ, oa, ob, fpos, best_dist2)
		return 1
	return 0


func _mark_hostile_frontier(civ: Node2D, ca: int, cb: int, fpos: Vector2, best_dist2: PackedFloat32Array) -> void:
	civ._city_alerted[ca] = 1
	civ._city_alerted[cb] = 1
	var da2: float = civ._city_center[ca].distance_squared_to(fpos)
	if da2 < best_dist2[ca]:
		best_dist2[ca] = da2
		civ._city_threat_pos[ca] = fpos
	var db2: float = civ._city_center[cb].distance_squared_to(fpos)
	if db2 < best_dist2[cb]:
		best_dist2[cb] = db2
		civ._city_threat_pos[cb] = fpos


func step_city_loyalty(civ: Node2D, cid: int, pace_dt: float) -> void:
	if civ._city_is_rebel[cid] != 0:
		return
	var stress: float = 0.0
	var hunger: float = civ.get_city_hunger_pressure(cid)
	if hunger > 0.45:
		stress += (hunger - 0.35) * 1.35
	if civ._city_emp_timer[cid] > 0.0:
		stress += 0.85
	var ov: int = civ._city_overlord[cid]
	if ov >= 0 and ov < civ._max_cities and civ._city_active[ov] != 0:
		if civ._city_center[cid].distance_to(civ._city_center[ov]) > civ._k_rebel_cap_dist:
			stress += 0.55

	var prev_loy: float = civ._city_loyalty[cid]
	if stress > 0.0:
		civ._city_loyalty[cid] = maxf(0.0, prev_loy - stress * civ._k_rebel_loy_decay * pace_dt)
	else:
		civ._city_loyalty[cid] = minf(100.0, prev_loy + civ._k_rebel_loy_recover * pace_dt)

	if civ._city_loyalty[cid] < civ._k_rebel_loy_thresh and can_city_rebel(civ, cid):
		if not has_plot_for(cid, -1, PLOT_REBEL):
			start_plot(civ, PLOT_REBEL, Vector2i(cid, -1))


func step_diplomacy_and_plots(civ: Node2D, pace_dt: float) -> void:
	_step_diplomacy_tension(civ, pace_dt)
	_step_active_plots(civ, pace_dt)


func _step_diplomacy_tension(civ: Node2D, pace_dt: float) -> void:
	var war_th: float = civ._k_diplo_war_th
	var pact_th: float = civ._k_diplo_pact_th
	var max_dist2: float = 280.0 * 280.0

	for a in range(civ._max_cities):
		if civ._city_active[a] == 0:
			continue
		var fa: int = int(civ._city_faction[a])
		var reb_a: bool = civ._city_is_rebel[a] != 0
		for b in range(a + 1, civ._max_cities):
			if civ._city_active[b] == 0:
				continue
			var fb: int = int(civ._city_faction[b])
			var reb_b: bool = civ._city_is_rebel[b] != 0
			var idx_ab: int = a * civ._max_cities + b
			var idx_ba: int = b * civ._max_cities + a
			if civ._diplo_pair_cd[idx_ab] > 0.0:
				var next_cd: float = maxf(0.0, civ._diplo_pair_cd[idx_ab] - pace_dt)
				civ._diplo_pair_cd[idx_ab] = next_cd
				civ._diplo_pair_cd[idx_ba] = next_cd

			var st: int = int(civ._diplo_matrix[idx_ab])
			if st == DIPLO_REBELLION or reb_a or reb_b:
				continue

			var contacts: int = civ._tmp_frontier_contacts[idx_ab]
			var d2: float = civ._city_center[a].distance_squared_to(civ._city_center[b])
			var ten: float = civ._diplo_tension[idx_ab]

			if fa == fb or (civ._city_kingdom_id[a] >= 0 and civ._city_kingdom_id[a] == civ._city_kingdom_id[b]):
				ten = move_toward(ten, -35.0, 2.4 * pace_dt)
			else:
				if contacts > 0:
					var growth: float = minf(float(contacts) * 0.9, 3.2)
					if int(civ._city_tech_tier[a]) >= 2 and int(civ._city_tech_tier[b]) >= 2 and d2 < 220.0 * 220.0:
						growth += 1.2
					ten = minf(100.0, ten + growth * pace_dt)
				elif d2 > max_dist2:
					var floor_ten: float = -4.0 if (fa == FACTION_SPORE or fb == FACTION_SPORE) else -30.0
					ten = move_toward(ten, floor_ten, 1.5 * pace_dt)

			civ._diplo_tension[idx_ab] = ten
			civ._diplo_tension[idx_ba] = ten

			if civ._diplo_pair_cd[idx_ab] > 0.0 or civ._city_war_cooldown[a] > 0.0 or civ._city_war_cooldown[b] > 0.0:
				continue

			if st != DIPLO_TOTAL_WAR and ten >= war_th and civ._law_diplomacy_wars:
				if not has_plot_for(a, b, PLOT_WAR):
					start_plot(civ, PLOT_WAR, Vector2i(a, b))
			elif st == DIPLO_TOTAL_WAR and contacts == 0 and ten < 8.0:
				apply_diplomacy_state(civ, Vector2i(a, b), Vector2i(DIPLO_NEUTRAL, 0))
			elif st == DIPLO_NEUTRAL and ten <= pact_th:
				if fa == fb or (fa != FACTION_SPORE and fb != FACTION_SPORE):
					if not has_plot_for(a, b, PLOT_PACT):
						start_plot(civ, PLOT_PACT, Vector2i(a, b))


func has_plot_for(src_cid: int, dst_cid: int, kind: int) -> bool:
	for i in range(MAX_PLOTS):
		if _plot_active[i] == 0 or int(_plot_kind[i]) != kind:
			continue
		if kind == PLOT_REBEL and _plot_src_cid[i] == src_cid:
			return true
		if (_plot_src_cid[i] == src_cid and _plot_dst_cid[i] == dst_cid) or (_plot_src_cid[i] == dst_cid and _plot_dst_cid[i] == src_cid):
			return true
	return false


func start_plot(civ: Node2D, kind: int, pair: Vector2i) -> bool:
	var src_cid: int = pair.x
	var dst_cid: int = pair.y
	if kind == PLOT_WAR and not civ._law_diplomacy_wars:
		return false
	if kind == PLOT_REBEL and not can_city_rebel(civ, src_cid):
		return false
	for i in range(MAX_PLOTS):
		if _plot_active[i] == 0:
			_plot_active[i] = 1
			_plot_kind[i] = kind
			_plot_src_cid[i] = src_cid
			_plot_dst_cid[i] = dst_cid
			_plot_elapsed[i] = 0.0
			_plot_dur[i] = civ._rng.randf_range(PLOT_MIN_SEC, PLOT_MAX_SEC)
			return true
	return false


func _step_active_plots(civ: Node2D, pace_dt: float) -> void:
	for i in range(MAX_PLOTS):
		if _plot_active[i] == 0:
			continue
		var kind: int = int(_plot_kind[i])
		var src: int = _plot_src_cid[i]
		var dst: int = _plot_dst_cid[i]
		if src < 0 or src >= civ._max_cities or civ._city_active[src] == 0:
			_plot_active[i] = 0
			continue
		if kind == PLOT_WAR and not civ._law_diplomacy_wars:
			_plot_active[i] = 0
			continue
		if kind == PLOT_REBEL and not civ._law_rebellions:
			_plot_active[i] = 0
			continue
		if kind != PLOT_REBEL and (dst < 0 or dst >= civ._max_cities or civ._city_active[dst] == 0):
			_plot_active[i] = 0
			continue

		_plot_elapsed[i] += pace_dt
		if _plot_elapsed[i] < _plot_dur[i]:
			continue

		_plot_active[i] = 0
		_resolve_plot(civ, kind, src, dst)


func _resolve_plot(civ: Node2D, kind: int, src: int, dst: int) -> void:
	if kind == PLOT_WAR:
		if not civ._law_diplomacy_wars:
			return
		apply_diplomacy_state(civ, Vector2i(src, dst), Vector2i(DIPLO_TOTAL_WAR, 0))
		push_chronicle("Война: %s против %s" % [civ._city_name[src], civ._city_name[dst]], civ._city_center[src], Color("#FF6A5C"))
	elif kind == PLOT_PACT:
		apply_diplomacy_state(civ, Vector2i(src, dst), Vector2i(DIPLO_PACT, 0))
		push_chronicle("Пакт: %s и %s" % [civ._city_name[src], civ._city_name[dst]], civ._city_center[src], Color("#5AE88E"))
	elif kind == PLOT_REBEL:
		if can_city_rebel(civ, src) and civ._city_loyalty[src] < civ._k_rebel_loy_thresh + 20.0:
			trigger_city_rebellion(civ, src, false)


func _cancel_plots_involving(cid: int) -> void:
	for i in range(MAX_PLOTS):
		if _plot_active[i] != 0 and (_plot_src_cid[i] == cid or _plot_dst_cid[i] == cid):
			_plot_active[i] = 0


func get_active_plots(civ: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(MAX_PLOTS):
		if _plot_active[i] == 0:
			continue
		var src: int = _plot_src_cid[i]
		if src < 0 or src >= civ._max_cities or civ._city_active[src] == 0:
			continue
		var kind_i: int = int(_plot_kind[i])
		var kind_s: String = "war" if kind_i == PLOT_WAR else ("pact" if kind_i == PLOT_PACT else "rebel")
		out.append({
			"pos": civ._city_center[src] + Vector2(0.0, -10.0),
			"kind": kind_s,
			"progress": clampf(_plot_elapsed[i] / maxf(0.1, _plot_dur[i]), 0.0, 1.0),
			"faction": int(civ._city_faction[src]),
		})
	return out


func get_active_plot_count() -> int:
	var n: int = 0
	for i in range(MAX_PLOTS):
		if _plot_active[i] != 0:
			n += 1
	return n


func apply_diplomacy_state(civ: Node2D, pair: Vector2i, state_opts: Vector2i) -> void:
	var city_a: int = pair.x
	var city_b: int = pair.y
	var new_state: int = state_opts.x
	var manual: bool = state_opts.y != 0
	if city_a < 0 or city_a >= civ._max_cities or city_b < 0 or city_b >= civ._max_cities or city_a == city_b:
		return
	if civ._city_active[city_a] == 0 or civ._city_active[city_b] == 0:
		return
	var st: int = clampi(new_state, DIPLO_NEUTRAL, DIPLO_REBELLION)
	if st == DIPLO_PACT and int(civ._city_faction[city_a]) != int(civ._city_faction[city_b]):
		if (int(civ._city_faction[city_a]) == FACTION_SPORE or int(civ._city_faction[city_b]) == FACTION_SPORE) and not manual:
			return
	var idx_ab: int = city_a * civ._max_cities + city_b
	var idx_ba: int = city_b * civ._max_cities + city_a
	var prev_st: int = int(civ._diplo_matrix[idx_ab])
	civ._diplo_matrix[idx_ab] = st
	civ._diplo_matrix[idx_ba] = st
	civ._diplo_tension[idx_ab] = -40.0 if st == DIPLO_PACT else (65.0 if st == DIPLO_TOTAL_WAR else (85.0 if st == DIPLO_REBELLION else 0.0))
	civ._diplo_tension[idx_ba] = civ._diplo_tension[idx_ab]

	var cd: float = civ._k_diplo_war_cd if (manual or st >= DIPLO_TOTAL_WAR) else 8.0
	civ._diplo_pair_cd[idx_ab] = cd
	civ._diplo_pair_cd[idx_ba] = cd

	if st == DIPLO_TOTAL_WAR or st == DIPLO_REBELLION:
		civ._city_alerted[city_a] = 1
		civ._city_alerted[city_b] = 1
		civ._city_alert_timer[city_a] = maxf(civ._city_alert_timer[city_a], 6.0)
		civ._city_alert_timer[city_b] = maxf(civ._city_alert_timer[city_b], 6.0)
		civ._city_threat_pos[city_a] = civ._city_center[city_b]
		civ._city_threat_pos[city_b] = civ._city_center[city_a]
		civ._refresh_city_targets(city_a)
		civ._refresh_city_targets(city_b)

	civ._recompute_city_war_state(city_a)
	civ._recompute_city_war_state(city_b)
	civ._diplo_dirty_seq += 1
	civ._light_goals_dirty = true
	_orders_dirty = true

	if prev_st != st and civ._fx != null and civ._fx_has_spawn_reaction_strip:
		var mid: Vector2 = (civ._city_center[city_a] + civ._city_center[city_b]) * 0.5 + Vector2(0.0, -8.0)
		if st == DIPLO_PACT:
			civ._fx.call("spawn_reaction_strip", mid, STRIP_PACT)
		elif st == DIPLO_TOTAL_WAR:
			civ._fx.call("spawn_reaction_strip", mid, STRIP_WAR)
		elif st == DIPLO_REBELLION:
			civ._fx.call("spawn_reaction_strip", mid, STRIP_REBEL)


func trigger_city_rebellion(civ: Node2D, cid: int, allow_bypass: bool = false) -> void:
	if cid < 0 or cid >= civ._max_cities or civ._city_active[cid] == 0 or civ._city_is_rebel[cid] != 0:
		return
	if not allow_bypass and not can_city_rebel(civ, cid):
		return

	var old_kid: int = civ._city_kingdom_id[cid]
	civ._city_is_rebel[cid] = 1
	civ._rebellions_total += 1
	civ._city_loyalty[cid] = minf(civ._city_loyalty[cid], 20.0)
	civ._city_overlord[cid] = -1
	create_kingdom(civ, cid, true)
	civ._city_color[cid] = civ.REBEL_TERRITORY_COLOR
	civ._city_alerted[cid] = 1
	civ._city_alert_timer[cid] = maxf(civ._city_alert_timer[cid], 10.0)

	for bi in range(civ._bld_count):
		if civ._bld_city_id[bi] == cid:
			civ._bld_color[bi] = civ.REBEL_TERRITORY_COLOR
	civ._buildings_dirty = true
	civ._mark_city_zones_dirty(cid)

	var c_pos: Vector2 = civ._city_center[cid]
	var c_fac: int = int(civ._city_faction[cid])
	var flipped: int = 0
	var nearest_cid: int = -1
	var nearest_d2: float = 1e18
	for other in range(civ._max_cities):
		if other == cid or civ._city_active[other] == 0:
			continue
		var d2: float = c_pos.distance_squared_to(civ._city_center[other])
		if d2 < nearest_d2:
			nearest_d2 = d2
			nearest_cid = other
		var same_old_k: bool = old_kid >= 0 and civ._city_kingdom_id[other] == old_kid
		if same_old_k or int(civ._city_faction[other]) == c_fac or d2 <= 320.0 * 320.0:
			apply_diplomacy_state(civ, Vector2i(cid, other), Vector2i(DIPLO_REBELLION, 1))
			flipped += 1
		elif int(civ._diplo_matrix[cid * civ._max_cities + other]) == DIPLO_PACT:
			apply_diplomacy_state(civ, Vector2i(cid, other), Vector2i(DIPLO_NEUTRAL, 1))

	if flipped == 0 and nearest_cid >= 0:
		apply_diplomacy_state(civ, Vector2i(cid, nearest_cid), Vector2i(DIPLO_REBELLION, 1))

	civ._city_war_state[cid] = DIPLO_REBELLION
	civ._diplo_dirty_seq += 1
	civ._light_goals_dirty = true
	_orders_dirty = true
	push_chronicle("Мятеж: %s провозгласил независимость" % civ._city_name[cid], c_pos, civ.REBEL_TERRITORY_COLOR)

	if civ._fx != null:
		if civ._fx_has_spawn_burst:
			civ._fx.spawn_burst(c_pos, 14, civ.REBEL_TERRITORY_COLOR, 26.0, 0.55, -14.0)
		if civ._fx_has_spawn_reaction_strip:
			civ._fx.call("spawn_reaction_strip", c_pos + Vector2(0.0, -10.0), STRIP_REBEL)


func step_wartime_capture(civ: Node2D, pace_dt: float) -> void:
	if civ._physics == null or not civ._physics_has_unit_capture_api:
		return
	var u_pos: PackedVector2Array = civ._physics.get_unit_positions()
	var u_city: PackedInt32Array = civ._physics.get_unit_cities()
	var has_roles: bool = civ._physics_has_get_unit_roles
	var u_role: PackedByteArray = civ._physics.get_unit_roles() if has_roles else PackedByteArray()
	var u_cnt: int = int(civ._physics.get_unit_count()) if civ._physics_has_get_unit_count else u_pos.size()
	u_cnt = mini(u_cnt, mini(u_pos.size(), u_city.size()))

	_reset_contested_scratch(civ)
	_accumulate_zone_combat_weights(civ, u_pos, u_city, u_role, has_roles, u_cnt)
	_advance_zone_captures(civ, pace_dt, has_roles)
	_decay_inactive_captures(civ, pace_dt, has_roles)


func _reset_contested_scratch(civ: Node2D) -> void:
	for prev_k in range(civ._contested_z_count):
		var pzi: int = civ._contested_z_list[prev_k]
		civ._zone_in_contested[pzi] = 0
		civ._tmp_zone_att_cid[pzi] = -1
		civ._tmp_zone_att_cnt[pzi] = 0
		civ._tmp_zone_def_cnt[pzi] = 0
		civ._tmp_zone_att_sol[pzi] = 0
	civ._contested_z_count = 0


func _accumulate_zone_combat_weights(civ: Node2D, u_pos: PackedVector2Array, u_city: PackedInt32Array, u_role: PackedByteArray, has_roles: bool, u_cnt: int) -> void:
	for i in range(u_cnt):
		var ucid: int = u_city[i]
		if ucid < 0 or ucid >= civ._max_cities or civ._city_active[ucid] == 0:
			continue
		var zx: int = clampi(int(floor(u_pos[i].x / float(civ._zone_px))), 0, civ._zone_w - 1)
		var zy: int = clampi(int(floor(u_pos[i].y / float(civ._zone_px))), 0, civ._zone_h - 1)
		var owner: int = civ._get_zone_owner(zx, zy)
		if owner < 0 or owner >= civ._max_cities or civ._city_active[owner] == 0:
			continue
		var zidx: int = zy * civ._zone_w + zx
		var is_sol: bool = has_roles and i < u_role.size() and int(u_role[i]) == 4
		var w: int = 2 if is_sol else 1
		if owner == ucid:
			civ._tmp_zone_def_cnt[zidx] += w
			_mark_contested(civ, zidx)
		elif civ._are_cities_hostile(ucid, owner):
			_mark_contested(civ, zidx)
			if civ._tmp_zone_att_cid[zidx] < 0 or civ._tmp_zone_att_cid[zidx] == ucid:
				civ._tmp_zone_att_cid[zidx] = ucid
				civ._tmp_zone_att_cnt[zidx] += w
				if is_sol:
					civ._tmp_zone_att_sol[zidx] = 1
			elif is_sol and civ._tmp_zone_att_sol[zidx] == 0:
				civ._tmp_zone_att_cid[zidx] = ucid
				civ._tmp_zone_att_cnt[zidx] += w
				civ._tmp_zone_att_sol[zidx] = 1
			else:
				civ._tmp_zone_att_cnt[zidx] += w


func _mark_contested(civ: Node2D, zidx: int) -> void:
	if civ._zone_in_contested[zidx] == 0:
		civ._zone_in_contested[zidx] = 1
		civ._contested_z_list[civ._contested_z_count] = zidx
		civ._contested_z_count += 1


func _advance_zone_captures(civ: Node2D, pace_dt: float, has_roles: bool) -> void:
	var hold_sec: float = civ._k_war_zone_cap_sec
	for k in range(civ._contested_z_count):
		var zidx: int = civ._contested_z_list[k]
		var att_cid: int = civ._tmp_zone_att_cid[zidx]
		var att_n: int = civ._tmp_zone_att_cnt[zidx]
		var def_n: int = civ._tmp_zone_def_cnt[zidx]
		var can_cap: bool = att_cid >= 0 and att_n > def_n and (not has_roles or civ._tmp_zone_att_sol[zidx] != 0 or (def_n == 0 and att_n >= 2))
		if not can_cap:
			continue
		if civ._zone_capture_cid[zidx] == att_cid:
			civ._zone_capture_timer[zidx] += pace_dt
		else:
			civ._zone_capture_cid[zidx] = att_cid
			civ._zone_capture_timer[zidx] = pace_dt
			if civ._zone_in_active_cap[zidx] == 0:
				civ._zone_in_active_cap[zidx] = 1
				civ._active_cap_zones[civ._active_cap_count] = zidx
				civ._active_cap_count += 1
		if civ._zone_capture_timer[zidx] >= hold_sec:
			capture_zone_by_war(civ, Vector2i(zidx % civ._zone_w, zidx / civ._zone_w), att_cid)


func _decay_inactive_captures(civ: Node2D, pace_dt: float, has_roles: bool) -> void:
	var ai: int = civ._active_cap_count - 1
	while ai >= 0:
		var zidx: int = civ._active_cap_zones[ai]
		var cap_cid: int = civ._zone_capture_cid[zidx]
		if cap_cid < 0:
			civ._zone_in_active_cap[zidx] = 0
			civ._active_cap_count -= 1
			if ai < civ._active_cap_count:
				civ._active_cap_zones[ai] = civ._active_cap_zones[civ._active_cap_count]
		else:
			var att_n: int = civ._tmp_zone_att_cnt[zidx]
			var def_n: int = civ._tmp_zone_def_cnt[zidx]
			var still_holding: bool = (
				civ._zone_in_contested[zidx] != 0
				and civ._tmp_zone_att_cid[zidx] == cap_cid
				and att_n > def_n
				and (not has_roles or civ._tmp_zone_att_sol[zidx] != 0 or (def_n == 0 and att_n >= 2))
			)
			if not still_holding:
				civ._zone_capture_timer[zidx] = maxf(0.0, civ._zone_capture_timer[zidx] - pace_dt * 1.25)
				if civ._zone_capture_timer[zidx] <= 0.0:
					civ._zone_capture_cid[zidx] = -1
					civ._zone_in_active_cap[zidx] = 0
					civ._active_cap_count -= 1
					if ai < civ._active_cap_count:
						civ._active_cap_zones[ai] = civ._active_cap_zones[civ._active_cap_count]
		ai -= 1


func capture_zone_by_war(civ: Node2D, zpt: Vector2i, new_owner: int) -> void:
	var zx: int = zpt.x
	var zy: int = zpt.y
	if zx < 0 or zx >= civ._zone_w or zy < 0 or zy >= civ._zone_h:
		return
	if new_owner < 0 or new_owner >= civ._max_cities or civ._city_active[new_owner] == 0:
		return
	var prev_owner: int = civ._get_zone_owner(zx, zy)
	if prev_owner == new_owner or prev_owner < 0 or prev_owner >= civ._max_cities:
		return
	if not civ._are_cities_hostile(new_owner, prev_owner):
		return

	civ._claim_zone(zx, zy, new_owner, int(civ._city_faction[new_owner]))
	_transfer_buildings_in_zone(civ, zx, zy, prev_owner, new_owner)

	var z_mid := Vector2((float(zx) + 0.5) * float(civ._zone_px), (float(zy) + 0.5) * float(civ._zone_px))
	if civ._fx != null and civ._fx_has_spawn_burst:
		civ._fx.spawn_burst(z_mid, 8, civ._get_city_border_color(new_owner), 18.0, 0.45, -10.0)

	if civ._city_zones_count[prev_owner] <= 0:
		civ._collapse_city(prev_owner)
	else:
		civ._verify_city_integrity_after_damage(prev_owner)
	civ._refresh_city_targets(new_owner)
	_orders_dirty = true


func _transfer_buildings_in_zone(civ: Node2D, zx: int, zy: int, prev_owner: int, new_owner: int) -> void:
	var px0: float = float(zx * civ._zone_px)
	var py0: float = float(zy * civ._zone_px)
	var px1: float = float((zx + 1) * civ._zone_px)
	var py1: float = float((zy + 1) * civ._zone_px)
	var bi: int = civ._bld_count - 1
	while bi >= 0:
		if civ._bld_city_id[bi] == prev_owner:
			var bp: Vector2 = civ._bld_pos[bi]
			if bp.x >= px0 and bp.x < px1 and bp.y >= py0 and bp.y < py1:
				var bt: int = int(civ._bld_type[bi])
				if bt == BLD_CAMPFIRE:
					civ._remove_building(bi)
				elif bt == BLD_QUANTUM_GATE and int(civ._city_tech_tier[new_owner]) < 4:
					civ._spawn_ruin(bp, civ.BLD_ORE_COSTS[bt] * 0.55, 18.0, int(civ._city_faction[prev_owner]))
					civ._remove_building(bi)
				else:
					_reassign_building(civ, bi, bt, prev_owner, new_owner)
		bi -= 1


func _reassign_building(civ: Node2D, bi: int, bt: int, prev_owner: int, new_owner: int) -> void:
	civ._city_bld_counts[prev_owner * civ.BLD_TYPE_COUNT + bt] = maxi(0, civ._city_bld_counts[prev_owner * civ.BLD_TYPE_COUNT + bt] - 1)
	civ._city_bld_counts[new_owner * civ.BLD_TYPE_COUNT + bt] += 1
	civ._bld_city_id[bi] = new_owner
	civ._bld_color[bi] = civ._get_city_tint_color(new_owner)
	civ._bld_hp[bi] = maxf(12.0, civ._bld_hp[bi] * 0.55)
	civ._city_damaged_blds[new_owner] = 1
	civ._bld_shake[bi] = 1.6
	civ._has_bld_springs = true
	civ._spring_cache_dirty = true
	if bt == BLD_SHIELD_PYLON:
		civ._bld_shield_charge[bi] = clampf(civ._bld_shield_charge[bi] * 0.5, 0.25, 0.50)
		civ._shield_cache_dirty = true
	civ._city_tech_dirty[prev_owner] = 1
	civ._city_tech_dirty[new_owner] = 1
	if bt == BLD_DEPOT:
		civ._city_storage_cap[prev_owner] = maxf(civ._k_base_storage_cap, civ._city_storage_cap[prev_owner] - civ._k_depot_storage_bonus)
		civ._city_storage_cap[new_owner] += civ._k_depot_storage_bonus
	elif bt == BLD_LAUNCHPAD:
		civ._city_storage_cap[prev_owner] = maxf(civ._k_base_storage_cap, civ._city_storage_cap[prev_owner] - civ._k_launchpad_storage_bonus)
		civ._city_storage_cap[new_owner] += civ._k_launchpad_storage_bonus
	civ._buildings_dirty = true
	civ._bld_footprints_dirty = true
	civ._light_goals_dirty = true


func try_colonize_and_shuttles(civ: Node2D) -> void:
	if not civ._law_self_founding:
		return
	var active_cities: int = 0
	for cid in range(civ._max_cities):
		if civ._city_active[cid] != 0:
			active_cities += 1
	var shuttle_cap: int = mini(civ._max_cities - 2, 10 if civ._total_shuttles_launched == 0 else 8)
	if active_cities >= shuttle_cap:
		return
	var active_exps: int = 0
	for ei in range(MAX_EXPEDITIONS):
		if _exp_active[ei] != 0:
			active_exps += 1
	if active_exps >= 2:
		return

	var req_ore: float = civ._k_shuttle_ore
	var req_energy: float = civ._k_shuttle_energy
	for cid in range(civ._max_cities):
		if civ._city_active[cid] == 0 or civ._city_shuttle_cd[cid] > 0.0:
			continue
		var kid: int = civ._city_kingdom_id[cid]
		var tier: int = int(civ._city_tech_tier[cid])
		var base_b: int = cid * civ.BLD_TYPE_COUNT
		var pads: int = civ._city_bld_counts[base_b + BLD_LAUNCHPAD]
		var max_kc: int = 3 if (tier >= 3 and pads > 0) else 2
		if kid < 0 or kid >= MAX_KINGDOMS or civ._kingdom_city_count[kid] >= max_kc or _kingdom_colonize_cd[kid] > 0.0:
			continue
		if civ._city_has_active_shuttle(cid) or _city_has_active_expedition(cid):
			continue
		if civ._city_pop[cid] < 16 or civ._city_zones_count[cid] < 6 or civ._city_age_sec[cid] < 60.0:
			continue
		var has_infra: bool = (civ._city_bld_counts[base_b + 2] >= 1 or civ._city_bld_counts[base_b + BLD_DEPOT] >= 1)
		if tier < 1 or not has_infra:
			continue
		var coastal: bool = civ._is_city_coastal(cid)
		var launched: bool = false
		if (pads > 0 or (tier >= 2 and coastal)) and civ._shuttle_count < civ._max_shuttles and civ._city_ore[cid] >= req_ore + 6.0 and civ._city_energy[cid] >= req_energy + 2.0:
			var kind: int = SHUTTLE_KIND_COLONIZE if (tier >= 3 and pads > 0) else SHUTTLE_KIND_BOAT
			launched = _try_launch_colonizer_craft(civ, cid, kind, req_ore, req_energy)
		if not launched and active_cities < 7 and (civ._city_ore[cid] + civ._city_wood[cid] >= 16.0):
			launched = _try_dispatch_overland_expedition(civ, cid)
		if launched:
			_kingdom_colonize_cd[kid] = 180.0
			break


func _try_launch_colonizer_craft(civ: Node2D, cid: int, kind: int, req_ore: float, req_energy: float) -> bool:
	var require_water: bool = (kind == SHUTTLE_KIND_BOAT)
	var target: Vector2 = _find_shuttle_island_target(civ, cid, require_water)
	if target.x < 0.0:
		return false
	var launch_pos: Vector2 = civ._city_center[cid]
	if kind == SHUTTLE_KIND_COLONIZE:
		for bi in range(civ._bld_count):
			if civ._bld_city_id[bi] == cid and civ._bld_type[bi] == BLD_LAUNCHPAD:
				launch_pos = civ._bld_pos[bi]
				break

	civ._city_ore[cid] -= req_ore
	civ._city_energy[cid] -= req_energy
	civ._city_energy_spend_acc[cid] += req_energy
	civ._city_shuttle_cd[cid] = maxf(90.0, civ._k_shuttle_cd)
	civ._city_shuttles_launched[cid] += 1
	civ._total_shuttles_launched += 1

	var speed_px: float = maxf(12.0, civ._k_shuttle_speed * (0.72 if kind == SHUTTLE_KIND_BOAT else 1.0))
	var sidx: int = civ._shuttle_count
	civ._shuttle_count += 1
	civ._shuttle_start[sidx] = launch_pos
	civ._shuttle_target[sidx] = target
	civ._shuttle_pos[sidx] = launch_pos
	civ._shuttle_t[sidx] = 0.0
	civ._shuttle_dur[sidx] = clampf(launch_pos.distance_to(target) / speed_px, 1.4, 8.5)
	civ._shuttle_faction[sidx] = civ._city_faction[cid]
	civ._shuttle_src_city[sidx] = cid
	civ._shuttle_trail_t[sidx] = 0.0
	civ._shuttle_kind[sidx] = kind
	civ._shuttle_target_city[sidx] = -1
	civ._buildings_dirty = true

	if civ._fx != null:
		if civ._fx_has_play_sfx:
			civ._fx.play_sfx(10)
		if civ._fx_has_spawn_burst:
			var burst_col := Color(0.45, 0.85, 1.0, 1.0) if kind == SHUTTLE_KIND_BOAT else Color(1.4, 0.85, 0.35, 1.0)
			civ._fx.spawn_burst(launch_pos, 10, burst_col, 24.0, 0.45, 12.0)
	return true


func _find_shuttle_island_target(civ: Node2D, cid: int, require_water: bool) -> Vector2:
	var launch_pos: Vector2 = civ._city_center[cid]
	var f_id: int = int(civ._city_faction[cid])
	var min_d: float = maxf(64.0, civ._k_shuttle_hop_min)
	var max_d: float = civ._k_shuttle_hop_max
	var best_target := Vector2(-1.0, -1.0)
	var best_score: float = -1e9

	for sample_i in range(48):
		var ang: float = float(sample_i) * (TAU / 48.0) + civ._rng.randf_range(-0.06, 0.06)
		var dist: float = civ._rng.randf_range(min_d, max_d)
		var cand := Vector2(
			clampf(launch_pos.x + cos(ang) * dist, 18.0, float(civ._map_w) - 18.0),
			clampf(launch_pos.y + sin(ang) * dist, 18.0, float(civ._map_h) - 18.0)
		)
		if not civ.can_settle_near(cand):
			continue
		var czx: int = clampi(int(floor(cand.x)) / civ._zone_px, 0, civ._zone_w - 1)
		var czy: int = clampi(int(floor(cand.y)) / civ._zone_px, 0, civ._zone_h - 1)
		if not civ._is_zone_claimable(czx, czy, f_id):
			continue
		var water_hops: int = _count_water_hops(civ, launch_pos, cand)
		if require_water and water_hops < 1:
			continue
		var score: float = float(water_hops) * 35.0 + float(civ._zone_ore[czy * civ._zone_w + czx]) * 1.8 + dist * 0.15
		if score > best_score:
			best_score = score
			best_target = cand
	return best_target


func _count_water_hops(civ: Node2D, a: Vector2, b: Vector2) -> int:
	if civ._world == null:
		return 0
	var hits: int = 0
	for step in range(1, 10):
		var mp: Vector2 = a.lerp(b, float(step) / 10.0)
		var mx: int = clampi(int(mp.x), 0, civ._map_w - 1)
		var my: int = clampi(int(mp.y), 0, civ._map_h - 1)
		if int(civ._world.get_tier(mx, my)) <= 2:
			hits += 1
	return hits


func _try_dispatch_overland_expedition(civ: Node2D, cid: int) -> bool:
	var slot: int = -1
	for i in range(MAX_EXPEDITIONS):
		if _exp_active[i] == 0:
			slot = i
			break
	if slot < 0:
		return false

	var origin: Vector2 = civ._city_center[cid]
	var f_id: int = int(civ._city_faction[cid])
	var best_target := Vector2(-1.0, -1.0)
	var best_score: float = -1e9
	for sample_i in range(36):
		var ang: float = float(sample_i) * (TAU / 36.0) + civ._rng.randf_range(-0.08, 0.08)
		var dist: float = civ._rng.randf_range(EXPEDITION_MIN_DIST_PX, EXPEDITION_MAX_DIST_PX)
		var cand := Vector2(
			clampf(origin.x + cos(ang) * dist, 18.0, float(civ._map_w) - 18.0),
			clampf(origin.y + sin(ang) * dist, 18.0, float(civ._map_h) - 18.0)
		)
		if not civ.can_settle_near(cand):
			continue
		if _count_water_hops(civ, origin, cand) > 0:
			continue
		var czx: int = clampi(int(floor(cand.x)) / civ._zone_px, 0, civ._zone_w - 1)
		var czy: int = clampi(int(floor(cand.y)) / civ._zone_px, 0, civ._zone_h - 1)
		if not civ._is_zone_claimable(czx, czy, f_id):
			continue
		var sc: float = float(civ._zone_ore[czy * civ._zone_w + czx]) + civ._zone_fertility[czy * civ._zone_w + czx] * 14.0
		if sc > best_score:
			best_score = sc
			best_target = cand

	if best_target.x < 0.0:
		return false

	var spend_w: float = minf(civ._city_wood[cid], 6.0)
	civ._city_wood[cid] -= spend_w
	civ._city_ore[cid] = maxf(0.0, civ._city_ore[cid] - (8.0 - spend_w))
	civ._city_shuttle_cd[cid] = 90.0

	_exp_active[slot] = 1
	_exp_src_cid[slot] = cid
	_exp_kingdom_id[slot] = civ._city_kingdom_id[cid]
	_exp_faction[slot] = f_id
	_exp_pos[slot] = origin
	_exp_target[slot] = best_target
	_exp_settlers[slot] = civ._rng.randi_range(4, 5)
	_exp_step_accum[slot] = 0.0
	return true


func step_expeditions(civ: Node2D, pace_dt: float) -> void:
	for kid in range(MAX_KINGDOMS):
		if _kingdom_colonize_cd[kid] > 0.0:
			_kingdom_colonize_cd[kid] = maxf(0.0, _kingdom_colonize_cd[kid] - pace_dt)
	for i in range(MAX_EXPEDITIONS):
		if _exp_active[i] == 0:
			continue
		var src_cid: int = _exp_src_cid[i]
		if src_cid < 0 or src_cid >= civ._max_cities or civ._city_active[src_cid] == 0:
			_exp_active[i] = 0
			continue
		var pos: Vector2 = _exp_pos[i]
		var target: Vector2 = _exp_target[i]
		var delta_v: Vector2 = target - pos
		var dist: float = delta_v.length()
		var step_dist: float = 16.0 * pace_dt
		if dist <= maxf(4.0, step_dist):
			_exp_active[i] = 0
			if civ.can_settle_near(target):
				civ._found_daughter_settlement(src_cid, target, _exp_settlers[i])
			continue
		var next_pos: Vector2 = pos + (delta_v / dist) * step_dist
		_exp_pos[i] = next_pos
		_exp_step_accum[i] += pace_dt
		var foot_int: float = maxf(0.35, pace_dt * 3.0) if civ._sim_pace_mult >= 15.0 else 0.35
		if _exp_step_accum[i] >= foot_int:
			_exp_step_accum[i] = 0.0
			civ.record_foot_step(next_pos, src_cid)
			if civ._sim_pace_mult < 15.0 and civ._fx != null and civ._fx_has_spawn_burst:
				civ._fx.spawn_burst(next_pos, 1, Color(0.85, 0.80, 0.65, 0.55), 5.0, 0.35, -4.0)


func _city_has_active_expedition(cid: int) -> bool:
	for i in range(MAX_EXPEDITIONS):
		if _exp_active[i] != 0 and _exp_src_cid[i] == cid:
			return true
	return false


func _cancel_expeditions_from(cid: int) -> void:
	for i in range(MAX_EXPEDITIONS):
		if _exp_active[i] != 0 and _exp_src_cid[i] == cid:
			_exp_active[i] = 0


func get_army_orders(civ: Node2D) -> Dictionary:
	if not _orders_dirty:
		return _army_orders_cache
	_orders_dirty = false
	_army_orders_cache.clear()
	for cid in range(civ._max_cities):
		if civ._city_active[cid] == 0:
			continue
		var war_st: int = int(civ._city_war_state[cid])
		var alerted: bool = civ._city_alerted[cid] != 0
		if war_st < DIPLO_TOTAL_WAR and not alerted:
			continue
		var order: Dictionary = _build_city_army_order(civ, cid, war_st)
		if not order.is_empty():
			_army_orders_cache[cid] = order
	return _army_orders_cache


func _build_city_army_order(civ: Node2D, cid: int, war_st: int) -> Dictionary:
	var c_pos: Vector2 = civ._city_center[cid]
	var target_cid: int = -1
	var best_d2: float = 1e18
	for other in range(civ._max_cities):
		if other == cid or civ._city_active[other] == 0:
			continue
		if civ._are_cities_hostile(cid, other):
			var d2: float = c_pos.distance_squared_to(civ._city_center[other])
			if d2 < best_d2:
				best_d2 = d2
				target_cid = other

	var target_pos: Vector2 = civ._city_threat_pos[cid]
	if target_cid >= 0:
		target_pos = civ._city_center[target_cid]
	elif target_pos.length_squared() < 1.0:
		target_pos = c_pos

	var dir: Vector2 = (target_pos - c_pos).normalized() if target_pos.distance_squared_to(c_pos) > 4.0 else Vector2.RIGHT
	var rally_raw: Vector2 = c_pos + dir * 20.0
	var rally_pos: Vector2 = civ._territory.find_walkable_near(civ, rally_raw, Vector2i(10, int(civ._city_faction[cid])))
	if rally_pos.x < 0.0:
		rally_pos = c_pos

	var portal_pos: Vector2 = Vector2.ZERO
	var has_portal: bool = false
	if civ._city_emp_timer[cid] <= 0.0 and civ._city_energy[cid] >= 2.0:
		for bi in range(civ._bld_count):
			if civ._bld_city_id[bi] == cid and int(civ._bld_type[bi]) == BLD_QUANTUM_GATE and civ._bld_hp[bi] > 0.0:
				has_portal = true
				portal_pos = civ._bld_pos[bi]
				break

	var mode_s: String = "march" if (target_cid >= 0 and civ._city_pop[cid] >= 8) else ("rally" if war_st >= DIPLO_TOTAL_WAR else "defend")
	return {
		"city_id": cid,
		"kingdom_id": civ._city_kingdom_id[cid],
		"faction": int(civ._city_faction[cid]),
		"active": true,
		"mode": mode_s,
		"rally_pos": rally_pos,
		"target_pos": target_pos,
		"target_city_id": target_cid,
		"min_squad": 6,
		"max_squad": 12,
		"has_portal": has_portal,
		"portal_pos": portal_pos,
		"color": civ._get_city_border_color(cid),
	}
