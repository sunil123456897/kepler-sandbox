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
const PLOT_PEACE: int = 3
const PLOT_ALLIANCE_FORM: int = 4
const PLOT_ALLIANCE_JOIN: int = 5
const PLOT_ALLIANCE_BREAK: int = 6
const PLOT_SCHISM: int = 7
const PLOT_CODEX: int = 8
const PLOT_ORBITAL_SHIELD: int = 9
const PLOT_ASCEND_MONOLITH: int = 10
const PLOT_REFORM_SUCCESSION: int = 11

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

const STRIP_SHIELD: int = 5
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
const STRIP_PLOT_PEACE: int = 23
const STRIP_PLOT_ALLIANCE: int = 24
const STRIP_PLOT_SCHISM: int = 25
const STRIP_PLOT_CODEX: int = 26

const MAX_KINGDOMS: int = 64
const MAX_PLOTS: int = 16
const MAX_EXPEDITIONS: int = 16
const MAX_CHRONICLE: int = 32
const MAX_NOTABLES: int = 32
const NOTABLE_MEM_SLOTS: int = 12
const MAX_RELICS: int = 16
const MAX_FEUDS: int = 16

const RANK_HERO: int = 0
const RANK_BANNER: int = 1
const RANK_RULER: int = 2
const RANK_HERETIC: int = 3
const RANK_HERALD: int = 4

const TR_VENGEFUL: int = 1
const TR_SCHISMATIC: int = 2
const TR_ASHBORN: int = 4
const TR_BLESSED_HALO: int = 8
const TR_FERAL_ALPHA: int = 16

const NSTATE_DORMANT: int = 0
const NSTATE_BREWING: int = 1
const NSTATE_RECRUITING: int = 2
const NSTATE_FEUD_HUNT: int = 3
const NSTATE_DUEL: int = 4

const DOC_NEUTRAL: int = 0
const DOC_SOLAR_CULT: int = 1
const DOC_TECH_SKEPTICS: int = 2
const DOC_ORBITAL_WARDENS: int = 3

const MEM_NONE: int = 0
const MEM_FOUNDED: int = 1
const MEM_CROWNED: int = 2
const MEM_DUEL_WON: int = 3
const MEM_RELIC_TAKEN: int = 4
const MEM_FEUD_SWORN: int = 5
const MEM_BETRAYED: int = 6
const MEM_BLESSED: int = 7
const MEM_MUTATED: int = 8
const MEM_SURVIVED: int = 9

const REBEL_IMMUNITY_SEC: float = 180.0
const PLOT_MIN_SEC: float = 10.0
const PLOT_MAX_SEC: float = 14.0
const EXPEDITION_MIN_DIST_PX: float = 72.0
const EXPEDITION_MAX_DIST_PX: float = 160.0
const FEUD_TTL_SEC: float = 300.0
const DUEL_DETECT_RADIUS_PX: float = 14.0

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

const NOTABLE_NAME_POOLS := [
	["Артан", "Веслава", "Корвин", "Мира", "Север", "Злата", "Тарон", "Ярина", "Бран", "Лада", "Глеб", "Орья"],
	["Узел-7", "Ирис-М", "Анод-3", "Спектр", "Кварц-9", "Реле-2", "Вектор", "Омега-4", "Скан-8", "Ротор", "Сигма-1", "Импульс"],
	["Споровик", "Гифа", "Хорд", "Мховик", "Ризома", "Зев", "Крона", "Симб", "Роса", "Лишай", "Пыльца", "Тяж"],
]

const RELIC_NAME_POOLS := [
	["Венец Кеплера", "Клинок Зари", "Компас Базальта", "Искра Меридиана"],
	["Матрица Ядра", "Линза Анода", "Ключ Сигмы", "Контур Ротора"],
	["Сердце Мицелия", "Споровый Венец", "Янтарная Гифа", "Корень Роя"],
]

const RANK_NAMES_RU := ["Герой", "Знаменосец", "Правитель", "Отступник", "Вестник"]
const MEM_VERBS_RU := ["", "Основал", "Коронован", "Победил в дуэли", "Взял реликт", "Клятва мести", "Раскрыт заговор", "Благословлён", "Мутация", "Выжил"]

var _plot_active: PackedByteArray
var _plot_kind: PackedByteArray
var _plot_src_cid: PackedInt32Array
var _plot_dst_cid: PackedInt32Array
var _plot_elapsed: PackedFloat32Array
var _plot_dur: PackedFloat32Array
var _plot_instigator_nid: PackedInt32Array
var _plot_strip_cd: PackedFloat32Array

var _not_active: PackedByteArray
var _not_uid: PackedInt32Array
var _not_slot: PackedInt32Array
var _not_faction: PackedByteArray
var _not_rank: PackedByteArray
var _not_city_id: PackedInt32Array
var _not_kingdom_id: PackedInt32Array
var _not_clan_id: PackedInt32Array
var _not_traits: PackedInt32Array
var _not_relic_id: PackedInt32Array
var _not_state: PackedByteArray
var _not_pinned: PackedByteArray
var _not_duel_uid: PackedInt32Array
var _not_renown: PackedInt32Array
var _not_name: PackedStringArray
var _not_last_pos: PackedVector2Array
var _not_mem_count: PackedByteArray
var _not_mem_head: PackedByteArray
var _not_mem_verb: PackedByteArray
var _not_mem_subj_uid: PackedInt32Array
var _not_mem_city: PackedInt32Array
var _not_mem_time: PackedFloat32Array

var _rel_active: PackedByteArray
var _rel_kind: PackedByteArray
var _rel_holder_uid: PackedInt32Array
var _rel_holder_nid: PackedInt32Array
var _rel_pos: PackedVector2Array
var _rel_origin_cid: PackedInt32Array
var _rel_name: PackedStringArray
var _rel_renown: PackedInt32Array

var _feud_active: PackedByteArray
var _feud_src_clan: PackedInt32Array
var _feud_tgt_uid: PackedInt32Array
var _feud_tgt_clan: PackedInt32Array
var _feud_ttl: PackedFloat32Array
var _feud_reason: PackedByteArray

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
var _relic_strip_cd: float = 0.0
var _notable_sync_cd: float = 0.0
var _notable_last_sync_t: float = -10.0
var _relic_last_scan_t: float = -10.0
var _exp_active_cnt: int = 0
var _colonize_cd_active: bool = false
var _boss_hunt_uid: int = -1
var _boss_hunt_pos: Vector2 = Vector2.ZERO

var _kingdom_colonize_cd: PackedFloat32Array
var _prev_alerted: PackedByteArray
var _prev_threat: PackedVector2Array
var _best_dist2: PackedFloat32Array
var _active_cids: Array[int] = []


func ensure_allocated() -> void:
	if _allocated:
		return
	_allocated = true
	_alloc_plots_and_exp()
	_alloc_social_tables()
	reset_all()


func _alloc_plots_and_exp() -> void:
	_plot_active.resize(MAX_PLOTS)
	_plot_kind.resize(MAX_PLOTS)
	_plot_src_cid.resize(MAX_PLOTS)
	_plot_dst_cid.resize(MAX_PLOTS)
	_plot_elapsed.resize(MAX_PLOTS)
	_plot_dur.resize(MAX_PLOTS)
	_plot_instigator_nid.resize(MAX_PLOTS)
	_plot_strip_cd.resize(MAX_PLOTS)

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


func _alloc_social_tables() -> void:
	_not_active.resize(MAX_NOTABLES)
	_not_uid.resize(MAX_NOTABLES)
	_not_slot.resize(MAX_NOTABLES)
	_not_faction.resize(MAX_NOTABLES)
	_not_rank.resize(MAX_NOTABLES)
	_not_city_id.resize(MAX_NOTABLES)
	_not_kingdom_id.resize(MAX_NOTABLES)
	_not_clan_id.resize(MAX_NOTABLES)
	_not_traits.resize(MAX_NOTABLES)
	_not_relic_id.resize(MAX_NOTABLES)
	_not_state.resize(MAX_NOTABLES)
	_not_pinned.resize(MAX_NOTABLES)
	_not_duel_uid.resize(MAX_NOTABLES)
	_not_renown.resize(MAX_NOTABLES)
	_not_name.resize(MAX_NOTABLES)
	_not_last_pos.resize(MAX_NOTABLES)
	_not_mem_count.resize(MAX_NOTABLES)
	_not_mem_head.resize(MAX_NOTABLES)
	var mem_tot: int = MAX_NOTABLES * NOTABLE_MEM_SLOTS
	_not_mem_verb.resize(mem_tot)
	_not_mem_subj_uid.resize(mem_tot)
	_not_mem_city.resize(mem_tot)
	_not_mem_time.resize(mem_tot)

	_rel_active.resize(MAX_RELICS)
	_rel_kind.resize(MAX_RELICS)
	_rel_holder_uid.resize(MAX_RELICS)
	_rel_holder_nid.resize(MAX_RELICS)
	_rel_pos.resize(MAX_RELICS)
	_rel_origin_cid.resize(MAX_RELICS)
	_rel_name.resize(MAX_RELICS)
	_rel_renown.resize(MAX_RELICS)

	_feud_active.resize(MAX_FEUDS)
	_feud_src_clan.resize(MAX_FEUDS)
	_feud_tgt_uid.resize(MAX_FEUDS)
	_feud_tgt_clan.resize(MAX_FEUDS)
	_feud_ttl.resize(MAX_FEUDS)
	_feud_reason.resize(MAX_FEUDS)


func reset_all() -> void:
	ensure_allocated()
	_plot_active.fill(0)
	_plot_kind.fill(0)
	_plot_src_cid.fill(-1)
	_plot_dst_cid.fill(-1)
	_plot_elapsed.fill(0.0)
	_plot_dur.fill(12.0)
	_plot_instigator_nid.fill(-1)
	_plot_strip_cd.fill(0.0)
	_exp_active.fill(0)
	_exp_src_cid.fill(-1)
	_exp_kingdom_id.fill(-1)
	_exp_faction.fill(0)
	_exp_pos.fill(Vector2.ZERO)
	_exp_target.fill(Vector2.ZERO)
	_exp_settlers.fill(4)
	_exp_step_accum.fill(0.0)
	_reset_social_tables()
	_kingdom_colonize_cd.fill(0.0)
	_prev_alerted.fill(0)
	_prev_threat.fill(Vector2.ZERO)
	_best_dist2.fill(1e12)
	_active_cids.clear()
	_chronicle.clear()
	_army_orders_cache.clear()
	_orders_dirty = true
	_relic_strip_cd = 0.0
	_notable_sync_cd = 0.0
	_notable_last_sync_t = -10.0
	_relic_last_scan_t = -10.0
	_exp_active_cnt = 0
	_colonize_cd_active = false
	_boss_hunt_uid = -1
	_boss_hunt_pos = Vector2.ZERO


func _reset_social_tables() -> void:
	_not_active.fill(0)
	_not_uid.fill(-1)
	_not_slot.fill(-1)
	_not_faction.fill(0)
	_not_rank.fill(0)
	_not_city_id.fill(-1)
	_not_kingdom_id.fill(-1)
	_not_clan_id.fill(-1)
	_not_traits.fill(0)
	_not_relic_id.fill(-1)
	_not_state.fill(NSTATE_DORMANT)
	_not_pinned.fill(0)
	_not_duel_uid.fill(-1)
	_not_renown.fill(0)
	for i in range(MAX_NOTABLES):
		_not_name[i] = ""
	_not_last_pos.fill(Vector2.ZERO)
	_not_mem_count.fill(0)
	_not_mem_head.fill(0)
	_not_mem_verb.fill(0)
	_not_mem_subj_uid.fill(-1)
	_not_mem_city.fill(-1)
	_not_mem_time.fill(0.0)

	_rel_active.fill(0)
	_rel_kind.fill(0)
	_rel_holder_uid.fill(-1)
	_rel_holder_nid.fill(-1)
	_rel_pos.fill(Vector2.ZERO)
	_rel_origin_cid.fill(-1)
	for r in range(MAX_RELICS):
		_rel_name[r] = ""
	_rel_renown.fill(0)

	_feud_active.fill(0)
	_feud_src_clan.fill(-1)
	_feud_tgt_uid.fill(-1)
	_feud_tgt_clan.fill(-1)
	_feud_ttl.fill(0.0)
	_feud_reason.fill(0)


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
	if civ._meta != null:
		civ._meta.on_kingdom_created(civ, Vector2i(free_kid, capital_cid), is_rebel)
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
	if civ._meta != null:
		civ._meta.on_city_collapsed(civ, cid)
	for n in range(MAX_NOTABLES):
		if _not_active[n] != 0 and _not_city_id[n] == cid:
			_not_city_id[n] = -1
			_not_kingdom_id[n] = -1
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
			"doctrine": int(civ._city_doctrine_id[anchor_cid]) if anchor_cid < civ._max_cities else DOC_NEUTRAL,
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
	var max_c: int = civ._max_cities
	var diplo: PackedByteArray = civ._diplo_matrix
	var active: PackedByteArray = civ._city_active
	var facs: PackedByteArray = civ._city_faction
	for c_id in active_cids:
		var cc: Vector2 = civ._city_center[c_id]
		var czx: int = clampi(int(floor(cc.x / zpx)), 0, zw - 1)
		var czy: int = clampi(int(floor(cc.y / zpx)), 0, zh - 1)
		var b_r: int = clampi(4 + civ._city_zones_count[c_id] / 3, 5, 11)
		var zy_end: int = mini(zh, czy + b_r + 1)
		var zx0: int = maxi(0, czx - b_r)
		var zx_end: int = mini(zw, czx + b_r + 1)
		var row_c: int = c_id * max_c
		var fc: int = int(facs[c_id])
		for zy in range(maxi(0, czy - b_r), zy_end):
			var row_off: int = zy * zw
			for zx in range(zx0, zx_end):
				var zidx: int = row_off + zx
				if z_owners[zidx] != c_id:
					continue
				if zx + 1 < zw:
					var ob_e: int = z_owners[zidx + 1]
					if ob_e != c_id and ob_e >= 0 and active[ob_e] != 0:
						var dst_e: int = int(diplo[row_c + ob_e])
						if dst_e != DIPLO_PACT:
							civ._tmp_frontier_contacts[row_c + ob_e] += 1
							civ._tmp_frontier_contacts[ob_e * max_c + c_id] += 1
							if dst_e >= DIPLO_TOTAL_WAR or int(facs[ob_e]) != fc:
								_mark_hostile_frontier(civ, c_id, ob_e, Vector2(float(zx + 1) * zpx, (float(zy) + 0.5) * zpx), best_dist2)
								pairs += 1
				if zy + 1 < zh:
					var ob_s: int = z_owners[zidx + zw]
					if ob_s != c_id and ob_s >= 0 and active[ob_s] != 0:
						var dst_s: int = int(diplo[row_c + ob_s])
						if dst_s != DIPLO_PACT:
							civ._tmp_frontier_contacts[row_c + ob_s] += 1
							civ._tmp_frontier_contacts[ob_s * max_c + c_id] += 1
							if dst_s >= DIPLO_TOTAL_WAR or int(facs[ob_s]) != fc:
								_mark_hostile_frontier(civ, c_id, ob_s, Vector2((float(zx) + 0.5) * zpx, float(zy + 1) * zpx), best_dist2)
								pairs += 1
	return pairs


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
	if int(civ._city_faction[cid]) != FACTION_ROBOT:
		var need_f: float = maxf(float(civ._city_pop[cid]) * 2.5, 16.0)
		var hunger: float = clampf(1.0 - civ._city_food[cid] / need_f, 0.0, 1.0)
		if hunger > 0.45:
			stress += (hunger - 0.35) * 1.35
	if civ._city_emp_timer[cid] > 0.0:
		stress += 0.85
	var ov: int = civ._city_overlord[cid]
	if ov >= 0 and ov < civ._max_cities and civ._city_active[ov] != 0:
		var cap_d: float = civ._k_rebel_cap_dist
		if civ._city_center[cid].distance_squared_to(civ._city_center[ov]) > cap_d * cap_d:
			stress += 0.55
	if civ._meta != null:
		var l_bonus: float = civ._meta.calc_extra_loyalty_bonus_fast(civ, cid)
		if l_bonus < 0.0:
			stress += -l_bonus
		elif stress > 0.0:
			stress = maxf(0.0, stress - minf(0.25, l_bonus * 0.4))

	var doc_id: int = int(civ._city_doctrine_id[cid])
	if doc_id == DOC_SOLAR_CULT and stress > 0.0:
		stress = maxf(0.0, stress - 0.15)
	var prev_loy: float = civ._city_loyalty[cid]
	if stress > 0.0:
		civ._city_loyalty[cid] = maxf(0.0, prev_loy - stress * civ._k_rebel_loy_decay * pace_dt)
	else:
		var rec_mult: float = 1.35 if doc_id == DOC_SOLAR_CULT else 1.0
		civ._city_loyalty[cid] = minf(100.0, prev_loy + civ._k_rebel_loy_recover * rec_mult * pace_dt)

	if civ._city_loyalty[cid] < civ._k_rebel_loy_thresh and can_city_rebel(civ, cid):
		if not has_plot_for(cid, -1, PLOT_REBEL):
			start_plot(civ, PLOT_REBEL, Vector2i(cid, -1))


func step_diplomacy_and_plots(civ: Node2D, pace_dt: float) -> void:
	_step_diplomacy_tension(civ, pace_dt)
	_step_active_plots(civ, pace_dt)
	step_notables_and_relics(civ, pace_dt)


func _step_diplomacy_tension(civ: Node2D, pace_dt: float) -> void:
	var war_th: float = civ._k_diplo_war_th
	var pact_th: float = civ._k_diplo_pact_th
	var max_dist2: float = 280.0 * 280.0
	_active_cids.clear()
	for c in range(civ._max_cities):
		if civ._city_active[c] != 0:
			_active_cids.append(c)
	var act_n: int = _active_cids.size()

	for ai in range(act_n):
		var a: int = _active_cids[ai]
		var fa: int = int(civ._city_faction[a])
		var reb_a: bool = civ._city_is_rebel[a] != 0
		for bi in range(ai + 1, act_n):
			var b: int = _active_cids[bi]
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
			if civ._meta != null and civ._meta.is_kingdom_truce_active(civ._city_kingdom_id[a], civ._city_kingdom_id[b]):
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


func _is_self_only_plot(kind: int) -> bool:
	return (
		kind == PLOT_REBEL
		or kind == PLOT_ALLIANCE_BREAK
		or kind == PLOT_SCHISM
		or kind == PLOT_CODEX
		or kind == PLOT_ORBITAL_SHIELD
		or kind == PLOT_ASCEND_MONOLITH
		or kind == PLOT_REFORM_SUCCESSION
	)


func _plot_strip_id(kind: int) -> int:
	match kind:
		PLOT_WAR:
			return STRIP_PLOT_WAR
		PLOT_PACT:
			return STRIP_PLOT_PACT
		PLOT_REBEL:
			return STRIP_PLOT_REBEL
		PLOT_PEACE:
			return STRIP_PLOT_PEACE
		PLOT_ALLIANCE_FORM, PLOT_ALLIANCE_JOIN, PLOT_ALLIANCE_BREAK:
			return STRIP_PLOT_ALLIANCE
		PLOT_SCHISM:
			return STRIP_PLOT_SCHISM
		PLOT_CODEX, PLOT_REFORM_SUCCESSION:
			return STRIP_PLOT_CODEX
		PLOT_ORBITAL_SHIELD:
			return STRIP_SHIELD
		PLOT_ASCEND_MONOLITH:
			return STRIP_PORTAL
	return STRIP_PLOT_WAR


func has_plot_for(src_cid: int, dst_cid: int, kind: int) -> bool:
	var self_only: bool = _is_self_only_plot(kind)
	for i in range(MAX_PLOTS):
		if _plot_active[i] == 0 or int(_plot_kind[i]) != kind:
			continue
		if self_only and _plot_src_cid[i] == src_cid:
			return true
		if (_plot_src_cid[i] == src_cid and _plot_dst_cid[i] == dst_cid) or (_plot_src_cid[i] == dst_cid and _plot_dst_cid[i] == src_cid):
			return true
	return false


func start_plot(civ: Node2D, kind: int, pair: Vector2i) -> bool:
	var k: int = clampi(kind, PLOT_WAR, PLOT_REFORM_SUCCESSION)
	var src_cid: int = pair.x
	var dst_cid: int = pair.y
	if k == PLOT_WAR and not civ._law_diplomacy_wars:
		return false
	if k == PLOT_REBEL and not can_city_rebel(civ, src_cid):
		return false
	return _insert_plot(civ, k, src_cid, dst_cid)


func force_diplomatic_plot(civ: Node2D, plot_type: int, pair: Vector2i) -> bool:
	ensure_allocated()
	var k: int = clampi(plot_type, PLOT_WAR, PLOT_REFORM_SUCCESSION)
	var src: int = pair.x
	var dst: int = pair.y
	if src < 0 or src >= civ._max_cities or civ._city_active[src] == 0:
		for c in range(civ._max_cities):
			if civ._city_active[c] != 0:
				src = c
				break
	if src < 0 or src >= civ._max_cities or civ._city_active[src] == 0:
		return false
	var self_only: bool = _is_self_only_plot(k)
	if self_only:
		dst = -1
	elif dst < 0 or dst >= civ._max_cities or civ._city_active[dst] == 0 or dst == src:
		dst = -1
		for c in range(civ._max_cities):
			if c != src and civ._city_active[c] != 0:
				dst = c
				break
		if dst < 0:
			return false
	if has_plot_for(src, dst, k):
		return true
	return _insert_plot(civ, k, src, dst)


func start_test_plot(civ: Node2D, kind: int) -> bool:
	ensure_allocated()
	var k: int = clampi(kind, PLOT_WAR, PLOT_REFORM_SUCCESSION)
	var src: int = -1
	var dst: int = -1
	for c in range(civ._max_cities):
		if civ._city_active[c] == 0:
			continue
		if k == PLOT_REBEL and src < 0 and can_city_rebel(civ, c):
			src = c
		elif src < 0:
			src = c
		elif dst < 0 and c != src:
			dst = c
	if src < 0:
		return false
	if not _is_self_only_plot(k) and dst < 0:
		return false
	return _insert_plot(civ, k, src, dst)


func _insert_plot(civ: Node2D, kind: int, src_cid: int, dst_cid: int) -> bool:
	if src_cid < 0 or src_cid >= civ._max_cities or civ._city_active[src_cid] == 0:
		return false
	var self_only: bool = _is_self_only_plot(kind)
	if not self_only and (dst_cid < 0 or dst_cid >= civ._max_cities or civ._city_active[dst_cid] == 0 or dst_cid == src_cid):
		return false
	for i in range(MAX_PLOTS):
		if _plot_active[i] != 0:
			continue
		_plot_active[i] = 1
		_plot_kind[i] = kind
		_plot_src_cid[i] = src_cid
		_plot_dst_cid[i] = -1 if self_only else dst_cid
		_plot_elapsed[i] = 0.0
		if kind <= PLOT_REBEL or civ._meta == null:
			_plot_dur[i] = civ._rng.randf_range(PLOT_MIN_SEC, PLOT_MAX_SEC)
		else:
			_plot_dur[i] = civ._meta._meta_rng.randf_range(PLOT_MIN_SEC, PLOT_MAX_SEC)
		_plot_strip_cd[i] = 1.6
		var inst_nid: int = _assign_plot_instigator(civ, src_cid, kind)
		_plot_instigator_nid[i] = inst_nid
		_emit_plot_start_events(civ, kind, src_cid, _plot_dst_cid[i], inst_nid)
		return true
	return false


func _emit_plot_start_events(civ: Node2D, kind: int, src_cid: int, dst_cid: int, inst_nid: int) -> void:
	var src_name: String = civ._city_name[src_cid]
	var ev_pos: Vector2 = _not_last_pos[inst_nid] if (inst_nid >= 0 and _not_active[inst_nid] != 0) else civ._city_center[src_cid]
	var strip_id: int = _plot_strip_id(kind)
	if kind == PLOT_WAR:
		push_chronicle("Заговор: %s готовит войну с %s" % [src_name, civ._city_name[dst_cid]], ev_pos, Color("#FFB84D"))
	elif kind == PLOT_PACT:
		push_chronicle("Переговоры: %s и %s готовят пакт" % [src_name, civ._city_name[dst_cid]], ev_pos, Color("#7CE7FF"))
	elif kind == PLOT_REBEL:
		push_chronicle("Брожение: %s замышляет мятеж" % src_name, ev_pos, Color("#FF9B26"))
	else:
		var p_ru: String = civ._meta.get_plot_name_ru(kind) if civ._meta != null else "Заговор"
		if dst_cid >= 0 and dst_cid < civ._max_cities and civ._city_active[dst_cid] != 0:
			push_chronicle("%s: %s и %s" % [p_ru, src_name, civ._city_name[dst_cid]], ev_pos, Color("#A8D8FF"))
		else:
			push_chronicle("%s: %s" % [p_ru, src_name], ev_pos, Color("#A8D8FF"))
	if civ._fx != null and civ._fx_has_spawn_reaction_strip:
		civ._fx.call("spawn_reaction_strip", ev_pos + Vector2(0.0, -8.0), strip_id)


func _step_active_plots(civ: Node2D, pace_dt: float) -> void:
	for i in range(MAX_PLOTS):
		if _plot_active[i] == 0:
			continue
		var kind: int = int(_plot_kind[i])
		var src: int = _plot_src_cid[i]
		var dst: int = _plot_dst_cid[i]
		if src < 0 or src >= civ._max_cities or civ._city_active[src] == 0:
			_clear_plot_slot(i)
			continue
		if (kind == PLOT_WAR and not civ._law_diplomacy_wars) or (kind == PLOT_REBEL and not civ._law_rebellions):
			_clear_plot_slot(i)
			continue
		if not _is_self_only_plot(kind) and (dst < 0 or dst >= civ._max_cities or civ._city_active[dst] == 0):
			_clear_plot_slot(i)
			continue
		var nid: int = _plot_instigator_nid[i]
		if nid >= 0 and _not_active[nid] == 0:
			_clear_plot_slot(i)
			continue

		var spd: float = civ._meta.get_plot_speed_mult(civ, src) if civ._meta != null else 1.0
		_plot_elapsed[i] += pace_dt * spd
		if civ._sim_pace_mult < 15.0 and civ._fx != null and civ._fx_has_spawn_reaction_strip:
			_plot_strip_cd[i] -= pace_dt / maxf(1.0, civ._sim_pace_mult)
			if _plot_strip_cd[i] <= 0.0:
				_plot_strip_cd[i] = 1.4
				var s_pos: Vector2 = _not_last_pos[nid] if (nid >= 0 and _not_active[nid] != 0) else civ._city_center[src]
				civ._fx.call("spawn_reaction_strip", s_pos + Vector2(0.0, -8.0), _plot_strip_id(kind))
		if _plot_elapsed[i] < _plot_dur[i]:
			continue

		_clear_plot_slot(i)
		_resolve_plot(civ, kind, src, dst)


func _clear_plot_slot(i: int) -> void:
	var nid: int = _plot_instigator_nid[i]
	if nid >= 0 and nid < MAX_NOTABLES and _not_active[nid] != 0:
		if int(_not_state[nid]) == NSTATE_BREWING or int(_not_state[nid]) == NSTATE_RECRUITING:
			_not_state[nid] = NSTATE_DORMANT
	_plot_active[i] = 0
	_plot_instigator_nid[i] = -1


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
	elif civ._meta != null:
		civ._meta.resolve_extended_plot(civ, kind, Vector2i(src, dst))


func _cancel_plots_involving(cid: int) -> void:
	for i in range(MAX_PLOTS):
		if _plot_active[i] != 0 and (_plot_src_cid[i] == cid or _plot_dst_cid[i] == cid):
			_clear_plot_slot(i)


func _plot_kind_key(kind_i: int) -> String:
	var keys := ["war", "pact", "rebel", "peace", "alliance_form", "alliance_join", "alliance_break", "schism", "codex", "orbital_shield", "ascend_monolith", "reform_succession"]
	return keys[clampi(kind_i, 0, keys.size() - 1)]


func get_active_plots(civ: Node2D) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(MAX_PLOTS):
		if _plot_active[i] == 0:
			continue
		var src: int = _plot_src_cid[i]
		if src < 0 or src >= civ._max_cities or civ._city_active[src] == 0:
			continue
		var kind_i: int = int(_plot_kind[i])
		var nid: int = _plot_instigator_nid[i]
		var p_pos: Vector2 = _not_last_pos[nid] if (nid >= 0 and nid < MAX_NOTABLES and _not_active[nid] != 0) else (civ._city_center[src] + Vector2(0.0, -10.0))
		out.append({
			"pos": p_pos,
			"kind": _plot_kind_key(kind_i),
			"kind_id": kind_i,
			"title_ru": civ._meta.get_plot_name_ru(kind_i) if civ._meta != null else _plot_kind_key(kind_i),
			"progress": clampf(_plot_elapsed[i] / maxf(0.1, _plot_dur[i]), 0.0, 1.0),
			"faction": int(civ._city_faction[src]),
			"instigator_nid": nid,
			"instigator_uid": _not_uid[nid] if nid >= 0 else -1,
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
	if prev_st != st and civ._meta != null:
		civ._meta.on_diplomacy_changed(civ, Vector2i(city_a, city_b), st)


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
	var zw: int = civ._zone_w
	var zh: int = civ._zone_h
	var max_c: int = civ._max_cities
	var zpx_inv: float = 1.0 / float(civ._zone_px)
	var z_owners: PackedInt32Array = civ._zone_city_id
	var c_act: PackedByteArray = civ._city_active
	var diplo: PackedByteArray = civ._diplo_matrix
	var kids: PackedInt32Array = civ._city_kingdom_id
	var in_cont: PackedByteArray = civ._zone_in_contested
	var cont_list: PackedInt32Array = civ._contested_z_list
	var def_cnt: PackedInt32Array = civ._tmp_zone_def_cnt
	var att_cid_a: PackedInt32Array = civ._tmp_zone_att_cid
	var att_cnt_a: PackedInt32Array = civ._tmp_zone_att_cnt
	var att_sol_a: PackedByteArray = civ._tmp_zone_att_sol
	var roles_sz: int = u_role.size()
	for i in range(u_cnt):
		var ucid: int = u_city[i]
		if ucid < 0 or ucid >= max_c or c_act[ucid] == 0:
			continue
		var up: Vector2 = u_pos[i]
		var zx: int = clampi(int(floor(up.x * zpx_inv)), 0, zw - 1)
		var zy: int = clampi(int(floor(up.y * zpx_inv)), 0, zh - 1)
		var zidx: int = zy * zw + zx
		var owner: int = z_owners[zidx]
		if owner < 0 or owner >= max_c or c_act[owner] == 0:
			continue
		var is_sol: bool = has_roles and i < roles_sz and int(u_role[i]) == 4
		var w: int = 2 if is_sol else 1
		if owner == ucid:
			def_cnt[zidx] += w
			if in_cont[zidx] == 0:
				in_cont[zidx] = 1
				cont_list[civ._contested_z_count] = zidx
				civ._contested_z_count += 1
		else:
			var dst: int = int(diplo[ucid * max_c + owner])
			if dst == DIPLO_TOTAL_WAR or dst == DIPLO_REBELLION:
				if in_cont[zidx] == 0:
					in_cont[zidx] = 1
					cont_list[civ._contested_z_count] = zidx
					civ._contested_z_count += 1
				var cur_att: int = att_cid_a[zidx]
				if cur_att < 0 or cur_att == ucid:
					att_cid_a[zidx] = ucid
					att_cnt_a[zidx] += w
					if is_sol and int(att_sol_a[zidx]) < 255:
						att_sol_a[zidx] += 1
				elif is_sol and int(att_sol_a[zidx]) == 0:
					att_cid_a[zidx] = ucid
					att_cnt_a[zidx] = w
					att_sol_a[zidx] = 1
				elif kids[ucid] >= 0 and kids[ucid] == kids[cur_att]:
					att_cnt_a[zidx] += w
					if is_sol and int(att_sol_a[zidx]) < 255:
						att_sol_a[zidx] += 1


func _mark_contested(civ: Node2D, zidx: int) -> void:
	if civ._zone_in_contested[zidx] == 0:
		civ._zone_in_contested[zidx] = 1
		civ._contested_z_list[civ._contested_z_count] = zidx
		civ._contested_z_count += 1


func _zone_has_living_campfire(civ: Node2D, zx: int, zy: int, owner_cid: int) -> bool:
	var px0: float = float(zx * civ._zone_px)
	var py0: float = float(zy * civ._zone_px)
	var px1: float = px0 + float(civ._zone_px)
	var py1: float = py0 + float(civ._zone_px)
	for bi in range(civ._bld_count):
		if civ._bld_city_id[bi] != owner_cid or int(civ._bld_type[bi]) != BLD_CAMPFIRE or civ._bld_hp[bi] <= 0.0:
			continue
		var bp: Vector2 = civ._bld_pos[bi]
		if bp.x >= px0 and bp.x < px1 and bp.y >= py0 and bp.y < py1:
			return true
	return false


func _can_capture_zone(civ: Node2D, zx: int, zy: int, att_cid: int, att_sol: int) -> bool:
	var zidx: int = zy * civ._zone_w + zx
	var prev_owner: int = civ._get_zone_owner(zx, zy)
	if prev_owner < 0 or prev_owner >= civ._max_cities or civ._city_active[prev_owner] == 0:
		return false
	if civ._city_zones_count[prev_owner] > 2:
		var czx: int = clampi(int(floor(civ._city_center[prev_owner].x / float(civ._zone_px))), 0, civ._zone_w - 1)
		var czy: int = clampi(int(floor(civ._city_center[prev_owner].y / float(civ._zone_px))), 0, civ._zone_h - 1)
		if (zx == czx and zy == czy) or ((int(civ._zone_flags[zidx]) & ZONE_FLAG_BUILT) != 0 and _zone_has_living_campfire(civ, zx, zy, prev_owner)):
			return false
	var att_kid: int = civ._city_kingdom_id[att_cid]
	var zw: int = civ._zone_w
	var zh: int = civ._zone_h
	var z_owners: PackedInt32Array = civ._zone_city_id
	var kids: PackedInt32Array = civ._city_kingdom_id
	var active: PackedByteArray = civ._city_active
	if zx > 0:
		var nb_w: int = z_owners[zidx - 1]
		if nb_w >= 0 and active[nb_w] != 0 and (nb_w == att_cid or (att_kid >= 0 and kids[nb_w] == att_kid)):
			return true
	if zx + 1 < zw:
		var nb_e: int = z_owners[zidx + 1]
		if nb_e >= 0 and active[nb_e] != 0 and (nb_e == att_cid or (att_kid >= 0 and kids[nb_e] == att_kid)):
			return true
	if zy > 0:
		var nb_n: int = z_owners[zidx - zw]
		if nb_n >= 0 and active[nb_n] != 0 and (nb_n == att_cid or (att_kid >= 0 and kids[nb_n] == att_kid)):
			return true
	if zy + 1 < zh:
		var nb_s: int = z_owners[zidx + zw]
		if nb_s >= 0 and active[nb_s] != 0 and (nb_s == att_cid or (att_kid >= 0 and kids[nb_s] == att_kid)):
			return true
	return civ._territory.is_zone_coastal(civ, zx, zy) and (att_sol >= 2 or civ._tmp_zone_att_cnt[zidx] >= 4)


func _advance_zone_captures(civ: Node2D, pace_dt: float, has_roles: bool) -> void:
	var hold_sec: float = civ._k_war_zone_cap_sec
	for k in range(civ._contested_z_count):
		var zidx: int = civ._contested_z_list[k]
		var att_cid: int = civ._tmp_zone_att_cid[zidx]
		var att_n: int = civ._tmp_zone_att_cnt[zidx]
		var def_n: int = civ._tmp_zone_def_cnt[zidx]
		var att_sol: int = int(civ._tmp_zone_att_sol[zidx])
		var can_cap: bool = att_cid >= 0 and att_n > def_n and (not has_roles or att_sol > 0 or (def_n == 0 and att_n >= 2))
		if not can_cap:
			continue
		var zx: int = zidx % civ._zone_w
		var zy: int = zidx / civ._zone_w
		if not _can_capture_zone(civ, zx, zy, att_cid, att_sol):
			continue
		var prev_own: int = civ._get_zone_owner(zx, zy)
		var cap_dt: float = pace_dt
		if civ._meta != null and prev_own >= 0 and civ._meta.has_defense_turret_near_zone(civ, Vector2i(zx, zy), prev_own):
			cap_dt = pace_dt * 0.38
		if civ._zone_capture_cid[zidx] == att_cid:
			civ._zone_capture_timer[zidx] += cap_dt
		else:
			civ._zone_capture_cid[zidx] = att_cid
			civ._zone_capture_timer[zidx] = cap_dt
			if civ._zone_in_active_cap[zidx] == 0:
				civ._zone_in_active_cap[zidx] = 1
				civ._active_cap_zones[civ._active_cap_count] = zidx
				civ._active_cap_count += 1
		if civ._zone_capture_timer[zidx] >= hold_sec:
			capture_zone_by_war(civ, Vector2i(zx, zy), att_cid)


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
			var att_sol: int = int(civ._tmp_zone_att_sol[zidx])
			var zx: int = zidx % civ._zone_w
			var zy: int = zidx / civ._zone_w
			var still_holding: bool = (
				civ._zone_in_contested[zidx] != 0
				and civ._tmp_zone_att_cid[zidx] == cap_cid
				and att_n > def_n
				and (not has_roles or att_sol > 0 or (def_n == 0 and att_n >= 2))
				and _can_capture_zone(civ, zx, zy, cap_cid, att_sol)
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
	var zidx: int = zy * civ._zone_w + zx
	if not _can_capture_zone(civ, zx, zy, new_owner, int(civ._tmp_zone_att_sol[zidx])):
		return

	civ._claim_zone(zx, zy, new_owner, int(civ._city_faction[new_owner]))
	_transfer_buildings_in_zone(civ, zx, zy, prev_owner, new_owner)
	civ._territory.smooth_enclaves_for_city(civ, prev_owner)
	civ._territory.smooth_enclaves_for_city(civ, new_owner)
	if civ._meta != null:
		civ._meta.on_zone_captured(civ, prev_owner, new_owner)

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
	civ._turret_cache_dirty = true
	civ._aa_battery_cache_dirty = true
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
	if _exp_active_cnt >= 2:
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
			_colonize_cd_active = true
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
	_exp_active_cnt += 1
	_exp_src_cid[slot] = cid
	_exp_kingdom_id[slot] = civ._city_kingdom_id[cid]
	_exp_faction[slot] = f_id
	_exp_pos[slot] = origin
	_exp_target[slot] = best_target
	_exp_settlers[slot] = civ._rng.randi_range(4, 5)
	_exp_step_accum[slot] = 0.0
	return true


func step_expeditions(civ: Node2D, pace_dt: float) -> void:
	if _colonize_cd_active:
		var any_cd: bool = false
		for kid in range(MAX_KINGDOMS):
			if _kingdom_colonize_cd[kid] > 0.0:
				var next_kcd: float = maxf(0.0, _kingdom_colonize_cd[kid] - pace_dt)
				_kingdom_colonize_cd[kid] = next_kcd
				if next_kcd > 0.0:
					any_cd = true
		_colonize_cd_active = any_cd
	if _exp_active_cnt <= 0:
		return
	var rem_exp: int = 0
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
		rem_exp += 1
		var next_pos: Vector2 = pos + (delta_v / dist) * step_dist
		_exp_pos[i] = next_pos
		_exp_step_accum[i] += pace_dt
		var foot_int: float = maxf(0.35, pace_dt * 3.0) if civ._sim_pace_mult >= 15.0 else 0.35
		if _exp_step_accum[i] >= foot_int:
			_exp_step_accum[i] = 0.0
			civ.record_foot_step(next_pos, src_cid)
			if civ._sim_pace_mult < 15.0 and civ._fx != null and civ._fx_has_spawn_burst:
				civ._fx.spawn_burst(next_pos, 1, Color(0.85, 0.80, 0.65, 0.55), 5.0, 0.35, -4.0)
	_exp_active_cnt = rem_exp


func _city_has_active_expedition(cid: int) -> bool:
	if _exp_active_cnt <= 0:
		return false
	for i in range(MAX_EXPEDITIONS):
		if _exp_active[i] != 0 and _exp_src_cid[i] == cid:
			return true
	return false


func _cancel_expeditions_from(cid: int) -> void:
	if _exp_active_cnt <= 0:
		return
	for i in range(MAX_EXPEDITIONS):
		if _exp_active[i] != 0 and _exp_src_cid[i] == cid:
			_exp_active[i] = 0
			_exp_active_cnt = maxi(0, _exp_active_cnt - 1)


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
	if civ._meta != null:
		var load_shore: Vector2 = civ._meta.get_city_loading_shore(cid)
		if load_shore.x >= 0.0:
			rally_pos = load_shore

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


func get_notables_count() -> int:
	var c: int = 0
	for i in range(MAX_NOTABLES):
		if _not_active[i] != 0:
			c += 1
	return c


func get_relics_count() -> int:
	var c: int = 0
	for i in range(MAX_RELICS):
		if _rel_active[i] != 0:
			c += 1
	return c


func get_feuds_count() -> int:
	var c: int = 0
	for i in range(MAX_FEUDS):
		if _feud_active[i] != 0:
			c += 1
	return c


func _find_notable_by_uid(uid: int) -> int:
	if uid <= 0:
		return -1
	for i in range(MAX_NOTABLES):
		if _not_active[i] != 0 and _not_uid[i] == uid:
			return i
	return -1


func _alloc_notable_slot() -> int:
	for i in range(MAX_NOTABLES):
		if _not_active[i] == 0:
			return i
	var worst_i: int = -1
	var worst_score: int = 1 << 29
	for i in range(MAX_NOTABLES):
		if _not_pinned[i] != 0 or int(_not_rank[i]) == RANK_RULER or int(_not_rank[i]) == RANK_HERALD:
			continue
		var sc: int = _not_renown[i] + (40 if _not_relic_id[i] >= 0 else 0)
		if sc < worst_score:
			worst_score = sc
			worst_i = i
	return worst_i


func _record_notable_mem(nid: int, verb: int, subj_uid: int, cid: int, t_sec: float) -> void:
	if nid < 0 or nid >= MAX_NOTABLES or _not_active[nid] == 0:
		return
	var cnt: int = int(_not_mem_count[nid])
	var head: int = int(_not_mem_head[nid]) % NOTABLE_MEM_SLOTS
	var base: int = nid * NOTABLE_MEM_SLOTS
	_not_mem_verb[base + head] = verb
	_not_mem_subj_uid[base + head] = subj_uid
	_not_mem_city[base + head] = cid
	_not_mem_time[base + head] = t_sec
	_not_mem_head[nid] = (head + 1) % NOTABLE_MEM_SLOTS
	if cnt < NOTABLE_MEM_SLOTS:
		_not_mem_count[nid] = cnt + 1


func _sync_physics_notable_idx(civ: Node2D, uid: int, nid: int) -> void:
	if civ._physics == null or uid <= 0:
		return
	var uid_map_v: Variant = civ._physics.get("_uid_to_idx")
	if not (uid_map_v is Dictionary):
		return
	var uid_map := uid_map_v as Dictionary
	if not uid_map.has(uid):
		return
	var u_idx: int = int(uid_map[uid])
	var n_arr_v: Variant = civ._physics.get("_u_notable_idx")
	if n_arr_v is PackedInt32Array:
		var n_arr := n_arr_v as PackedInt32Array
		if u_idx >= 0 and u_idx < n_arr.size():
			n_arr[u_idx] = nid


func _pick_notable_name(civ: Node2D, fac: int, nid: int) -> String:
	var pool: Array = NOTABLE_NAME_POOLS[clampi(fac, 0, NOTABLE_NAME_POOLS.size() - 1)]
	var base: int = (nid + civ._rng.randi()) % pool.size()
	for off in range(pool.size()):
		var cand: String = str(pool[(base + off) % pool.size()])
		var used: bool = false
		for i in range(MAX_NOTABLES):
			if _not_active[i] != 0 and _not_name[i] == cand:
				used = true
				break
		if not used:
			return cand
	return "%s-%d" % [str(pool[nid % pool.size()]), nid + 1]


func _promote_unit_notable(civ: Node2D, uid: int, u_idx: int, rank: int, traits: int) -> int:
	var existing: int = _find_notable_by_uid(uid)
	if existing >= 0:
		if rank == RANK_RULER or rank == RANK_HERALD or (rank == RANK_HERETIC and int(_not_rank[existing]) != RANK_RULER):
			_not_rank[existing] = rank
		_not_traits[existing] |= traits
		_sync_physics_notable_idx(civ, uid, existing)
		return existing
	var nid: int = _alloc_notable_slot()
	if nid < 0:
		return -1
	var phys: Node2D = civ._physics
	var cid: int = int(phys._u_city_id[u_idx]) if (phys != null and u_idx >= 0 and u_idx < phys._u_city_id.size()) else -1
	var fac: int = int(phys._u_faction_id[u_idx]) if (phys != null and u_idx >= 0 and u_idx < phys._u_faction_id.size()) else 0
	fac = clampi(fac, 0, 2)
	var pos := Vector2(phys._px[u_idx], phys._py[u_idx]) if (phys != null and u_idx >= 0 and u_idx < phys._px.size()) else Vector2.ZERO
	_not_active[nid] = 1
	_not_uid[nid] = uid
	_not_slot[nid] = u_idx
	_not_faction[nid] = fac
	_not_rank[nid] = rank
	_not_city_id[nid] = cid
	_not_kingdom_id[nid] = civ._city_kingdom_id[cid] if (cid >= 0 and cid < civ._max_cities) else -1
	_not_clan_id[nid] = (cid + 1) if cid >= 0 else (nid + 100)
	_not_traits[nid] = traits
	_not_relic_id[nid] = -1
	_not_state[nid] = NSTATE_DORMANT
	_not_pinned[nid] = 0
	_not_duel_uid[nid] = -1
	_not_renown[nid] = 10 if rank == RANK_RULER else 4
	_not_name[nid] = _pick_notable_name(civ, fac, nid)
	_not_last_pos[nid] = pos
	_not_mem_count[nid] = 0
	_not_mem_head[nid] = 0
	_sync_physics_notable_idx(civ, uid, nid)
	return nid


func _assign_plot_instigator(civ: Node2D, src_cid: int, kind: int) -> int:
	for i in range(MAX_NOTABLES):
		if _not_active[i] != 0 and _not_city_id[i] == src_cid and int(_not_rank[i]) != RANK_RULER and int(_not_rank[i]) != RANK_HERALD:
			_not_state[i] = NSTATE_RECRUITING
			_not_traits[i] |= TR_SCHISMATIC
			return i
	if civ._physics == null:
		return -1
	var phys: Node2D = civ._physics
	var u_cnt: int = int(phys._unit_count)
	var ruler_uid: int = -1
	for i in range(MAX_NOTABLES):
		if _not_active[i] != 0 and _not_city_id[i] == src_cid and int(_not_rank[i]) == RANK_RULER:
			ruler_uid = _not_uid[i]
			break
	for u in range(u_cnt):
		if phys._u_city_id[u] != src_cid:
			continue
		var uid: int = phys._u_uid[u]
		if uid == ruler_uid or uid <= 0:
			continue
		var nid: int = _promote_unit_notable(civ, uid, u, RANK_HERETIC if kind == PLOT_REBEL else RANK_BANNER, TR_SCHISMATIC)
		if nid >= 0:
			_not_state[nid] = NSTATE_RECRUITING
			return nid
	return -1


func _spawn_city_crown_relic(civ: Node2D, nid: int, cid: int, fac: int) -> void:
	if nid < 0 or _not_relic_id[nid] >= 0:
		return
	var r_slot: int = -1
	for r in range(MAX_RELICS):
		if _rel_active[r] == 0:
			r_slot = r
			break
	if r_slot < 0:
		return
	var pool: Array = RELIC_NAME_POOLS[clampi(fac, 0, RELIC_NAME_POOLS.size() - 1)]
	_rel_active[r_slot] = 1
	_rel_kind[r_slot] = r_slot % 4
	_rel_holder_uid[r_slot] = _not_uid[nid]
	_rel_holder_nid[r_slot] = nid
	_rel_pos[r_slot] = _not_last_pos[nid]
	_rel_origin_cid[r_slot] = cid
	_rel_name[r_slot] = str(pool[(cid + r_slot) % pool.size()])
	_rel_renown[r_slot] = 15
	_not_relic_id[nid] = r_slot
	_record_notable_mem(nid, MEM_CROWNED, _not_uid[nid], cid, civ._sim_time)


func sync_notables(civ: Node2D, _pace_dt: float) -> void:
	ensure_allocated()
	if civ._physics == null:
		return
	var phys: Node2D = civ._physics
	var uid_map_v: Variant = phys.get("_uid_to_idx")
	if not (uid_map_v is Dictionary):
		return
	var uid_map := uid_map_v as Dictionary
	var p_uid_v: Variant = phys.get("_possessed_uid")
	if p_uid_v is int and int(p_uid_v) > 0 and uid_map.has(int(p_uid_v)):
		var p_uid: int = int(p_uid_v)
		if _find_notable_by_uid(p_uid) < 0:
			var p_idx: int = int(uid_map[p_uid])
			var h_nid: int = _promote_unit_notable(civ, p_uid, p_idx, RANK_HERALD, TR_BLESSED_HALO)
			if h_nid >= 0:
				_record_notable_mem(h_nid, MEM_BLESSED, p_uid, _not_city_id[h_nid], civ._sim_time)

	for n in range(MAX_NOTABLES):
		if _not_active[n] == 0:
			continue
		var uid: int = _not_uid[n]
		if not uid_map.has(uid):
			_handle_notable_loss(civ, n, -1, _not_last_pos[n])
			continue
		var idx: int = int(uid_map[uid])
		if idx < 0 or idx >= phys._unit_count:
			_handle_notable_loss(civ, n, -1, _not_last_pos[n])
			continue
		_not_slot[n] = idx
		_not_last_pos[n] = Vector2(phys._px[idx], phys._py[idx])
		_not_city_id[n] = phys._u_city_id[idx]
		var rid: int = _not_relic_id[n]
		if rid >= 0 and rid < MAX_RELICS and _rel_active[rid] != 0:
			_rel_pos[rid] = _not_last_pos[n]
		_sync_physics_notable_idx(civ, uid, n)

	_ensure_city_rulers(civ)


func _ensure_city_rulers(civ: Node2D) -> void:
	var phys: Node2D = civ._physics
	if phys == null or phys._unit_count <= 0:
		return
	var active_nots: int = 0
	var has_ruler := PackedByteArray()
	has_ruler.resize(civ._max_cities)
	has_ruler.fill(0)
	for n in range(MAX_NOTABLES):
		if _not_active[n] != 0:
			active_nots += 1
			if int(_not_rank[n]) == RANK_RULER:
				var ncid: int = _not_city_id[n]
				if ncid >= 0 and ncid < civ._max_cities:
					has_ruler[ncid] = 1
	if active_nots >= MAX_NOTABLES:
		return
	var need_any: bool = false
	for cid in range(civ._max_cities):
		if civ._city_active[cid] != 0 and has_ruler[cid] == 0:
			need_any = true
			break
	if not need_any:
		return
	var best_u := PackedInt32Array()
	var best_sc := PackedInt32Array()
	best_u.resize(civ._max_cities)
	best_u.fill(-1)
	best_sc.resize(civ._max_cities)
	best_sc.fill(-1)
	for u in range(phys._unit_count):
		var cid: int = phys._u_city_id[u]
		if cid < 0 or cid >= civ._max_cities or has_ruler[cid] != 0 or civ._city_active[cid] == 0 or phys._u_uid[u] <= 0:
			continue
		var sc: int = phys._u_kills[u] * 4 + (8 if int(phys._u_role[u]) == 4 else 1)
		if sc > best_sc[cid]:
			best_sc[cid] = sc
			best_u[cid] = u
	for cid in range(civ._max_cities):
		var bu: int = best_u[cid]
		if bu >= 0:
			var nid: int = _promote_unit_notable(civ, phys._u_uid[bu], bu, RANK_RULER, 0)
			if nid >= 0:
				_spawn_city_crown_relic(civ, nid, cid, int(civ._city_faction[cid]))


func step_notables_and_relics(civ: Node2D, pace_dt: float) -> void:
	if civ._sim_time - _notable_last_sync_t >= 1.2:
		_notable_last_sync_t = civ._sim_time
		sync_notables(civ, pace_dt)

	for f in range(MAX_FEUDS):
		if _feud_active[f] != 0:
			_feud_ttl[f] -= pace_dt
			if _feud_ttl[f] <= 0.0:
				_feud_active[f] = 0

	var relic_int: float = 1.5 if civ._sim_pace_mult >= 10.0 else 0.45
	if civ._sim_time - _relic_last_scan_t >= relic_int:
		_relic_last_scan_t = civ._sim_time
		_step_ground_relics(civ, pace_dt)


func _step_ground_relics(civ: Node2D, pace_dt: float) -> void:
	var has_ground: bool = false
	for r in range(MAX_RELICS):
		if _rel_active[r] != 0 and _rel_holder_uid[r] < 0:
			has_ground = true
			break
	if not has_ground:
		return
	if civ._sim_pace_mult < 15.0 and civ._fx != null and civ._fx_has_spawn_reaction_strip:
		_relic_strip_cd -= pace_dt / maxf(1.0, civ._sim_pace_mult)
		if _relic_strip_cd <= 0.0:
			_relic_strip_cd = 1.2
			for r in range(MAX_RELICS):
				if _rel_active[r] != 0 and _rel_holder_uid[r] < 0:
					civ._fx.call("spawn_reaction_strip", _rel_pos[r] + Vector2(0.0, -4.0), STRIP_RELIC_DIAMOND)
	var phys: Node2D = civ._physics
	if phys == null or phys._unit_count <= 0:
		return
	var u_cnt: int = int(phys._unit_count)
	var u_px: PackedFloat32Array = phys._px
	var u_py: PackedFloat32Array = phys._py
	var u_uid: PackedInt32Array = phys._u_uid
	var cs: int = maxi(1, int(phys._cell_size))
	var gw: int = int(phys._grid_w)
	var gh: int = int(phys._grid_h)
	var cell_head: PackedInt32Array = phys._cell_head
	var unit_next: PackedInt32Array = phys._unit_next
	var use_grid: bool = cell_head.size() == gw * gh and unit_next.size() >= u_cnt
	for r in range(MAX_RELICS):
		if _rel_active[r] == 0 or _rel_holder_uid[r] >= 0:
			continue
		var rpos: Vector2 = _rel_pos[r]
		if use_grid:
			var cx0: int = clampi(int(rpos.x) / cs, 0, gw - 1)
			var cy0: int = clampi(int(rpos.y) / cs, 0, gh - 1)
			var picked: bool = false
			for oy in range(-1, 2):
				var cy: int = cy0 + oy
				if cy < 0 or cy >= gh or picked:
					continue
				var row_c: int = cy * gw
				for ox in range(-1, 2):
					var cx: int = cx0 + ox
					if cx < 0 or cx >= gw or picked:
						continue
					var u: int = cell_head[row_c + cx]
					var guard: int = 0
					while u >= 0 and u < u_cnt and guard < 128:
						var dx: float = u_px[u] - rpos.x
						var dy: float = u_py[u] - rpos.y
						if dx * dx + dy * dy <= 36.0:
							_assign_relic_to_unit(civ, r, u_uid[u], u)
							picked = true
							break
						u = unit_next[u]
						guard += 1
		else:
			for u in range(u_cnt):
				var dx: float = u_px[u] - rpos.x
				var dy: float = u_py[u] - rpos.y
				if dx * dx + dy * dy <= 36.0:
					_assign_relic_to_unit(civ, r, u_uid[u], u)
					break


func _assign_relic_to_unit(civ: Node2D, rid: int, uid: int, u_idx: int) -> int:
	if rid < 0 or rid >= MAX_RELICS or _rel_active[rid] == 0 or uid <= 0:
		return -1
	var nid: int = _find_notable_by_uid(uid)
	if nid < 0:
		nid = _promote_unit_notable(civ, uid, u_idx, RANK_HERO, TR_BLESSED_HALO)
	if nid < 0:
		return -1
	if _not_relic_id[nid] >= 0 and _not_relic_id[nid] != rid:
		var old_r: int = _not_relic_id[nid]
		_rel_holder_uid[old_r] = -1
		_rel_holder_nid[old_r] = -1
		_rel_pos[old_r] = _not_last_pos[nid]
	_not_relic_id[nid] = rid
	_not_renown[nid] += 8
	_rel_holder_uid[rid] = uid
	_rel_holder_nid[rid] = nid
	_rel_pos[rid] = _not_last_pos[nid]
	_record_notable_mem(nid, MEM_RELIC_TAKEN, uid, _not_city_id[nid], civ._sim_time)
	if civ._fx != null and civ._fx_has_spawn_reaction_strip:
		civ._fx.call("spawn_reaction_strip", _not_last_pos[nid] + Vector2(0.0, -8.0), STRIP_CROWN_BANNER)
	push_chronicle("%s поднял реликт %s" % [_not_name[nid], _rel_name[rid]], _not_last_pos[nid], Color("#FFD84A"))
	return nid


func _create_feud(src_clan: int, tgt_uid: int, tgt_clan: int, reason: int) -> void:
	if src_clan < 0:
		return
	for f in range(MAX_FEUDS):
		if _feud_active[f] != 0 and _feud_src_clan[f] == src_clan and _feud_tgt_uid[f] == tgt_uid:
			_feud_ttl[f] = FEUD_TTL_SEC
			return
	var slot: int = -1
	var min_ttl: float = 1e9
	for f in range(MAX_FEUDS):
		if _feud_active[f] == 0:
			slot = f
			break
		if _feud_ttl[f] < min_ttl:
			min_ttl = _feud_ttl[f]
			slot = f
	if slot >= 0:
		_feud_active[slot] = 1
		_feud_src_clan[slot] = src_clan
		_feud_tgt_uid[slot] = tgt_uid
		_feud_tgt_clan[slot] = tgt_clan
		_feud_ttl[slot] = FEUD_TTL_SEC
		_feud_reason[slot] = reason


func _handle_notable_loss(civ: Node2D, nid: int, killer_uid: int, pos: Vector2) -> void:
	if nid < 0 or nid >= MAX_NOTABLES or _not_active[nid] == 0:
		return
	var was_ruler: bool = int(_not_rank[nid]) == RANK_RULER
	var fac: int = int(_not_faction[nid])
	var clan: int = _not_clan_id[nid]
	var cid: int = _not_city_id[nid]
	var rid: int = _not_relic_id[nid]
	if rid >= 0 and rid < MAX_RELICS and _rel_active[rid] != 0:
		_rel_holder_uid[rid] = -1
		_rel_holder_nid[rid] = -1
		_rel_pos[rid] = pos
		if civ._fx != null and civ._fx_has_spawn_reaction_strip:
			civ._fx.call("spawn_reaction_strip", pos + Vector2(0.0, -5.0), STRIP_RELIC_DIAMOND)
	if killer_uid > 0:
		var k_nid: int = _find_notable_by_uid(killer_uid)
		var k_clan: int = _not_clan_id[k_nid] if k_nid >= 0 else -1
		_create_feud(clan, killer_uid, k_clan, MEM_FEUD_SWORN)
		if civ._fx != null and civ._fx_has_spawn_reaction_strip:
			civ._fx.call("spawn_reaction_strip", pos + Vector2(0.0, -9.0), STRIP_FEUD_SWORDS)
	if was_ruler or _not_pinned[nid] != 0:
		push_chronicle("Пал %s" % _not_name[nid], pos, Color("#FF6A5C"))
	if was_ruler and civ._meta != null and cid >= 0 and cid < civ._max_cities:
		civ._meta.on_ruler_died(civ, cid, civ._city_kingdom_id[cid])
	if was_ruler and fac == FACTION_HUMAN and cid >= 0 and cid < civ._max_cities and get_feuds_count() >= 2:
		var kid: int = civ._city_kingdom_id[cid]
		for oc in range(civ._max_cities):
			if oc != cid and civ._city_active[oc] != 0 and civ._city_kingdom_id[oc] == kid:
				civ._city_loyalty[oc] = maxf(0.0, civ._city_loyalty[oc] - 25.0)
	for p in range(MAX_PLOTS):
		if _plot_active[p] != 0 and _plot_instigator_nid[p] == nid:
			_plot_active[p] = 0
			_plot_instigator_nid[p] = -1
	_not_active[nid] = 0
	_not_uid[nid] = -1
	_not_relic_id[nid] = -1


func on_unit_killed(civ: Node2D, uid_pair: Vector2i, pos: Vector2) -> void:
	ensure_allocated()
	var victim_uid: int = uid_pair.x
	var killer_uid: int = uid_pair.y
	var v_nid: int = _find_notable_by_uid(victim_uid)
	var v_cid: int = _not_city_id[v_nid] if v_nid >= 0 else -1
	var k_cid: int = -1
	var phys: Node2D = civ._physics
	var uid_map: Dictionary = {}
	if phys != null:
		var uid_map_v: Variant = phys.get("_uid_to_idx")
		if uid_map_v is Dictionary:
			uid_map = uid_map_v as Dictionary
			if v_cid < 0 and victim_uid > 0 and uid_map.has(victim_uid):
				var v_idx: int = int(uid_map[victim_uid])
				if v_idx >= 0 and v_idx < phys._u_city_id.size():
					v_cid = phys._u_city_id[v_idx]
	if v_nid >= 0:
		_handle_notable_loss(civ, v_nid, killer_uid, pos)

	if phys != null and killer_uid > 0 and uid_map.has(killer_uid):
		var k_idx: int = int(uid_map[killer_uid])
		if k_idx >= 0 and k_idx < phys._u_city_id.size():
			k_cid = phys._u_city_id[k_idx]
		var k_nid: int = _find_notable_by_uid(killer_uid)
		if k_nid < 0 and (v_nid >= 0 or (k_idx >= 0 and k_idx < phys._u_kills.size() and phys._u_kills[k_idx] >= 3)):
			k_nid = _promote_unit_notable(civ, killer_uid, k_idx, RANK_HERO, TR_VENGEFUL)
		if k_nid >= 0:
			_not_renown[k_nid] += 10 if v_nid >= 0 else 3
			_record_notable_mem(k_nid, MEM_DUEL_WON, victim_uid, _not_city_id[k_nid], civ._sim_time)

	if civ._meta != null:
		civ._meta.on_unit_killed(civ, v_cid, k_cid)

	var zx: int = clampi(int(floor(pos.x / float(civ._zone_px))), 0, civ._zone_w - 1)
	var zy: int = clampi(int(floor(pos.y / float(civ._zone_px))), 0, civ._zone_h - 1)
	var zidx: int = zy * civ._zone_w + zx
	var zowner: int = civ._zone_city_id[zidx]
	if zowner >= 0 and zowner < civ._max_cities and civ._city_active[zowner] != 0:
		var zfac: int = int(civ._city_faction[zowner])
		if zfac == FACTION_SPORE:
			civ._city_food[zowner] = minf(civ._city_storage_cap[zowner], civ._city_food[zowner] + 3.0)
			civ._add_city_science(zowner, 1.5)
		elif zfac == FACTION_ROBOT:
			civ._zone_ore[zidx] += 2


func try_avatar_gesture(civ: Node2D, uid: int, world_pos: Vector2) -> int:
	ensure_allocated()
	var nid: int = _find_notable_by_uid(uid)
	if nid < 0 and civ._physics != null and uid > 0:
		var uid_map_v: Variant = civ._physics.get("_uid_to_idx")
		if uid_map_v is Dictionary and (uid_map_v as Dictionary).has(uid):
			nid = _promote_unit_notable(civ, uid, int((uid_map_v as Dictionary)[uid]), RANK_HERALD, TR_BLESSED_HALO)

	for p in range(MAX_PLOTS):
		if _plot_active[p] == 0:
			continue
		var src_cid: int = _plot_src_cid[p]
		var inst_nid: int = _plot_instigator_nid[p]
		var p_pos: Vector2 = _not_last_pos[inst_nid] if (inst_nid >= 0 and _not_active[inst_nid] != 0) else (civ._city_center[src_cid] if (src_cid >= 0 and src_cid < civ._max_cities) else Vector2(-9999.0, -9999.0))
		if world_pos.distance_squared_to(p_pos) <= 22.0 * 22.0:
			_clear_plot_slot(p)
			if src_cid >= 0 and src_cid < civ._max_cities and civ._city_active[src_cid] != 0:
				civ._city_loyalty[src_cid] = minf(100.0, civ._city_loyalty[src_cid] + 15.0)
				push_chronicle("Вестник сорвал заговор в %s" % civ._city_name[src_cid], p_pos, Color("#5AE88E"))
			if civ._fx != null and civ._fx_has_spawn_reaction_strip:
				civ._fx.call("spawn_reaction_strip", p_pos + Vector2(0.0, -8.0), STRIP_CROWN_BANNER)
			return 1

	for r in range(MAX_RELICS):
		if _rel_active[r] != 0 and _rel_holder_uid[r] < 0 and world_pos.distance_squared_to(_rel_pos[r]) <= 14.0 * 14.0:
			var u_idx: int = _not_slot[nid] if nid >= 0 else -1
			if u_idx >= 0 and _assign_relic_to_unit(civ, r, uid, u_idx) >= 0:
				return 2

	if civ.get_zone_owner_at(world_pos) < 0 and civ.can_settle_near(world_pos):
		var f_id: int = int(_not_faction[nid]) if nid >= 0 else 0
		var new_cid: int = civ.try_self_found_settlement(world_pos, f_id, PackedInt32Array([uid]) if uid > 0 else PackedInt32Array())
		if new_cid >= 0:
			if nid >= 0:
				_not_city_id[nid] = new_cid
				_not_kingdom_id[nid] = civ._city_kingdom_id[new_cid]
				_not_rank[nid] = RANK_RULER
				_record_notable_mem(nid, MEM_FOUNDED, uid, new_cid, civ._sim_time)
			return 3
	return 0


func pin_notable(uid: int, pinned: bool) -> bool:
	var nid: int = _find_notable_by_uid(uid)
	if nid < 0:
		return false
	_not_pinned[nid] = 1 if pinned else 0
	return true


func _build_notable_dict(n: int, civ: Node2D = null) -> Dictionary:
	var rid: int = _not_relic_id[n]
	var r_name: String = _rel_name[rid] if (rid >= 0 and rid < MAX_RELICS and _rel_active[rid] != 0) else ""
	var rk: int = clampi(int(_not_rank[n]), 0, RANK_NAMES_RU.size() - 1)
	var ncid: int = _not_city_id[n]
	var doc_id: int = int(civ._city_doctrine_id[ncid]) if (civ != null and ncid >= 0 and ncid < civ._max_cities) else DOC_NEUTRAL
	var mem_arr: Array[String] = []
	var cnt: int = mini(int(_not_mem_count[n]), NOTABLE_MEM_SLOTS)
	var head: int = int(_not_mem_head[n]) % NOTABLE_MEM_SLOTS
	var base: int = n * NOTABLE_MEM_SLOTS
	for k in range(cnt):
		var slot: int = (head - 1 - k + NOTABLE_MEM_SLOTS * 2) % NOTABLE_MEM_SLOTS
		var v: int = int(_not_mem_verb[base + slot])
		if v > 0 and v < MEM_VERBS_RU.size():
			mem_arr.append("[%dс] %s" % [int(_not_mem_time[base + slot]), MEM_VERBS_RU[v]])
	return {
		"notable_id": n,
		"uid": _not_uid[n],
		"name": _not_name[n],
		"faction": int(_not_faction[n]),
		"rank": rk,
		"rank_name": RANK_NAMES_RU[rk],
		"city_id": ncid,
		"kingdom_id": _not_kingdom_id[n],
		"clan_id": _not_clan_id[n],
		"doctrine": doc_id,
		"traits": _not_traits[n],
		"relic_id": rid,
		"relic_name": r_name,
		"state": int(_not_state[n]),
		"pinned": _not_pinned[n] != 0,
		"renown": _not_renown[n],
		"pos": _not_last_pos[n],
		"memory": mem_arr,
	}


func get_notables_summary(civ: Node2D = null) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for n in range(MAX_NOTABLES):
		if _not_active[n] != 0:
			out.append(_build_notable_dict(n, civ))
	return out


func on_city_doctrine_changed(civ: Node2D, cid: int, doc_id: int) -> void:
	ensure_allocated()
	if cid < 0 or cid >= civ._max_cities or civ._city_active[cid] == 0 or doc_id == DOC_NEUTRAL:
		return
	var target_rank: int = RANK_HERALD if doc_id == DOC_SOLAR_CULT else (RANK_HERETIC if doc_id == DOC_TECH_SKEPTICS else RANK_BANNER)
	var add_traits: int = TR_BLESSED_HALO if doc_id != DOC_TECH_SKEPTICS else (TR_SCHISMATIC | TR_VENGEFUL)
	var nid: int = _find_city_doctrine_notable(cid, target_rank)
	if nid < 0:
		var cand: Vector2i = _pick_doctrine_unit(civ, cid)
		if cand.x > 0 and cand.y >= 0:
			nid = _promote_unit_notable(civ, cand.x, cand.y, target_rank, add_traits)
	if nid < 0:
		return
	_not_traits[nid] |= add_traits
	_not_renown[nid] += 6 if doc_id != DOC_ORBITAL_WARDENS else 4
	if doc_id == DOC_TECH_SKEPTICS:
		_not_state[nid] = NSTATE_RECRUITING
		_record_notable_mem(nid, MEM_FEUD_SWORN, _not_uid[nid], cid, civ._sim_time)
		push_chronicle("Отступник %s отверг знамения (%s)" % [_not_name[nid], civ._city_name[cid]], _not_last_pos[nid], Color("#38F0FF"))
	elif doc_id == DOC_SOLAR_CULT:
		_record_notable_mem(nid, MEM_BLESSED, _not_uid[nid], cid, civ._sim_time)
		push_chronicle("Пророк %s возвышен (%s)" % [_not_name[nid], civ._city_name[cid]], _not_last_pos[nid], Color("#FFD84A"))
	else:
		_record_notable_mem(nid, MEM_BLESSED, _not_uid[nid], cid, civ._sim_time)
		push_chronicle("Страж неба %s (%s)" % [_not_name[nid], civ._city_name[cid]], _not_last_pos[nid], Color("#B86BFF"))
	if civ._fx != null and civ._fx_has_spawn_reaction_strip:
		civ._fx.call("spawn_reaction_strip", _not_last_pos[nid] + Vector2(0.0, -8.0), STRIP_CROWN_BANNER)


func _find_city_doctrine_notable(cid: int, target_rank: int) -> int:
	for n in range(MAX_NOTABLES):
		if _not_active[n] != 0 and _not_city_id[n] == cid and int(_not_rank[n]) == target_rank:
			return n
	return -1


func _pick_doctrine_unit(civ: Node2D, cid: int) -> Vector2i:
	var phys: Node2D = civ._physics
	if phys == null or phys._unit_count <= 0:
		return Vector2i(-1, -1)
	var uid_map_v: Variant = phys.get("_uid_to_idx")
	var uid_map: Dictionary = uid_map_v as Dictionary if (uid_map_v is Dictionary) else {}
	var ruler_uid: int = -1
	for n in range(MAX_NOTABLES):
		if _not_active[n] == 0 or _not_city_id[n] != cid:
			continue
		if int(_not_rank[n]) == RANK_RULER:
			ruler_uid = _not_uid[n]
		elif uid_map.has(_not_uid[n]):
			return Vector2i(_not_uid[n], int(uid_map[_not_uid[n]]))
	var best_u: int = -1
	var best_sc: int = -1
	for u in range(phys._unit_count):
		if phys._u_city_id[u] != cid or phys._hp[u] <= 0.0:
			continue
		var uid: int = phys._u_uid[u]
		if uid <= 0 or uid == ruler_uid:
			continue
		var sc: int = phys._u_kills[u] * 3 + (10 if int(phys._u_role[u]) == 4 else 1)
		if sc > best_sc:
			best_sc = sc
			best_u = u
	return Vector2i(phys._u_uid[best_u], best_u) if best_u >= 0 else Vector2i(-1, -1)


func rally_boss_hunters(civ: Node2D, boss_pos: Vector2, boss_uid: int) -> int:
	ensure_allocated()
	_boss_hunt_uid = boss_uid
	_boss_hunt_pos = boss_pos
	var phys: Node2D = civ._physics
	if phys == null or phys._unit_count <= 0:
		return 0
	var uid_map_v: Variant = phys.get("_uid_to_idx")
	if not (uid_map_v is Dictionary):
		return 0
	var uid_map := uid_map_v as Dictionary
	var mis_v: Variant = phys.get("_u_mission_pos")
	var emb_v: Variant = phys.get("_u_embarked")
	var hunters: int = 0
	var cands: Array[Vector2i] = []
	for n in range(MAX_NOTABLES):
		if _not_active[n] == 0:
			continue
		var uid: int = _not_uid[n]
		if not uid_map.has(uid):
			continue
		var u_idx: int = int(uid_map[uid])
		if u_idx < 0 or u_idx >= phys._unit_count or phys._hp[u_idx] <= 0.0:
			continue
		if emb_v is PackedByteArray and u_idx < (emb_v as PackedByteArray).size() and (emb_v as PackedByteArray)[u_idx] != 0:
			continue
		if int(_not_state[n]) == NSTATE_FEUD_HUNT:
			_apply_hunter_goal(phys, mis_v, n, u_idx, boss_pos, boss_uid)
			hunters += 1
			continue
		var rk: int = int(_not_rank[n])
		var ncid: int = _not_city_id[n]
		var is_warden_herald: bool = rk == RANK_HERALD and ncid >= 0 and ncid < civ._max_cities and int(civ._city_doctrine_id[ncid]) == DOC_ORBITAL_WARDENS
		if rk != RANK_HERO and rk != RANK_BANNER and not is_warden_herald:
			continue
		var d2: float = Vector2(phys._px[u_idx], phys._py[u_idx]).distance_squared_to(boss_pos)
		if d2 <= 260.0 * 260.0:
			cands.append(Vector2i(int(d2), n))
	cands.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x)
	for c in cands:
		if hunters >= 4:
			break
		var n: int = c.y
		var u_idx: int = int(uid_map[_not_uid[n]])
		_not_state[n] = NSTATE_FEUD_HUNT
		_apply_hunter_goal(phys, mis_v, n, u_idx, boss_pos, boss_uid)
		hunters += 1
		if civ._sim_pace_mult < 15.0 and civ._fx != null and civ._fx_has_spawn_reaction_strip:
			civ._fx.call("spawn_reaction_strip", _not_last_pos[n] + Vector2(0.0, -8.0), STRIP_FEUD_SWORDS)
	if hunters == 0:
		hunters = _promote_emergency_boss_hunter(civ, phys, mis_v, emb_v, boss_pos, boss_uid)
	return hunters


func _apply_hunter_goal(phys: Node2D, mis_v: Variant, nid: int, u_idx: int, boss_pos: Vector2, boss_uid: int) -> void:
	_not_slot[nid] = u_idx
	_not_last_pos[nid] = Vector2(phys._px[u_idx], phys._py[u_idx])
	_not_duel_uid[nid] = boss_uid
	phys._u_target_pos[u_idx] = boss_pos
	if mis_v is PackedVector2Array and u_idx < (mis_v as PackedVector2Array).size():
		(mis_v as PackedVector2Array)[u_idx] = boss_pos


func _promote_emergency_boss_hunter(civ: Node2D, phys: Node2D, mis_v: Variant, emb_v: Variant, boss_pos: Vector2, boss_uid: int) -> int:
	var best_u: int = -1
	var best_d2: float = 160.0 * 160.0
	for u in range(phys._unit_count):
		if phys._hp[u] <= 0.0 or phys._u_uid[u] <= 0 or phys._u_city_id[u] < 0:
			continue
		if emb_v is PackedByteArray and u < (emb_v as PackedByteArray).size() and (emb_v as PackedByteArray)[u] != 0:
			continue
		if _find_notable_by_uid(phys._u_uid[u]) >= 0:
			continue
		var d2: float = Vector2(phys._px[u], phys._py[u]).distance_squared_to(boss_pos)
		if d2 < best_d2:
			best_d2 = d2
			best_u = u
	if best_u < 0:
		return 0
	var nid: int = _promote_unit_notable(civ, phys._u_uid[best_u], best_u, RANK_HERO, TR_BLESSED_HALO)
	if nid < 0:
		return 0
	_not_state[nid] = NSTATE_FEUD_HUNT
	_apply_hunter_goal(phys, mis_v, nid, best_u, boss_pos, boss_uid)
	return 1


func clear_boss_hunt(civ: Node2D = null) -> void:
	_boss_hunt_uid = -1
	_boss_hunt_pos = Vector2.ZERO
	var uid_map: Dictionary = {}
	var mis_arr: Variant = null
	if civ != null and civ._physics != null:
		var uid_map_v: Variant = civ._physics.get("_uid_to_idx")
		if uid_map_v is Dictionary:
			uid_map = uid_map_v as Dictionary
		mis_arr = civ._physics.get("_u_mission_pos")
	for n in range(MAX_NOTABLES):
		if _not_active[n] == 0 or int(_not_state[n]) != NSTATE_FEUD_HUNT:
			continue
		_not_state[n] = NSTATE_DORMANT
		_not_duel_uid[n] = -1
		if mis_arr is PackedVector2Array and uid_map.has(_not_uid[n]):
			var u_idx: int = int(uid_map[_not_uid[n]])
			if u_idx >= 0 and u_idx < (mis_arr as PackedVector2Array).size():
				(mis_arr as PackedVector2Array)[u_idx] = Vector2(-1.0, -1.0)


func on_boss_slain(civ: Node2D, world_pos: Vector2, killer_uid: int, species_id: int) -> void:
	ensure_allocated()
	var nearest_cid: int = _find_nearest_active_city(civ, world_pos, 220.0)
	var killer_cid: int = nearest_cid
	var killer_nid: int = -1
	if killer_uid > 0 and civ._physics != null:
		var uid_map_v: Variant = civ._physics.get("_uid_to_idx")
		if uid_map_v is Dictionary and (uid_map_v as Dictionary).has(killer_uid):
			var u_idx: int = int((uid_map_v as Dictionary)[killer_uid])
			if u_idx >= 0 and u_idx < civ._physics._unit_count:
				var ucid: int = int(civ._physics._u_city_id[u_idx])
				if ucid >= 0 and ucid < civ._max_cities and civ._city_active[ucid] != 0:
					killer_cid = ucid
				killer_nid = _promote_unit_notable(civ, killer_uid, u_idx, RANK_HERO, TR_ASHBORN | TR_BLESSED_HALO)
				if killer_nid >= 0:
					_not_renown[killer_nid] += 25
					_record_notable_mem(killer_nid, MEM_SURVIVED, killer_uid, killer_cid, civ._sim_time)
	var r_slot: int = _spawn_boss_trophy_relic(world_pos, killer_cid, species_id)
	var t_name: String = _rel_name[r_slot] if r_slot >= 0 else "Трофей Титана"
	if r_slot >= 0 and killer_nid >= 0 and _not_relic_id[killer_nid] < 0 and _not_slot[killer_nid] >= 0:
		_assign_relic_to_unit(civ, r_slot, killer_uid, _not_slot[killer_nid])
	if killer_cid >= 0:
		civ._add_city_science(killer_cid, 60.0)
	for cid in range(civ._max_cities):
		if civ._city_active[cid] != 0 and civ._city_threat_pos[cid].distance_squared_to(world_pos) <= 165.0 * 165.0:
			civ._city_threat_pos[cid] = Vector2.ZERO
			civ._city_alerted[cid] = 0
			civ._city_alert_timer[cid] = 0.0
	_orders_dirty = true
	civ._light_goals_dirty = true
	clear_boss_hunt(civ)
	push_chronicle("Босс повержен! %s (+60 науки)" % t_name, world_pos, Color("#FFD84A"))
	if civ._fx != null and civ._fx_has_spawn_reaction_strip:
		civ._fx.call("spawn_reaction_strip", world_pos + Vector2(0.0, -8.0), STRIP_CROWN_BANNER)


func _find_nearest_active_city(civ: Node2D, world_pos: Vector2, max_r: float) -> int:
	var best_cid: int = -1
	var best_d2: float = max_r * max_r
	for cid in range(civ._max_cities):
		if civ._city_active[cid] == 0:
			continue
		var d2: float = civ._city_center[cid].distance_squared_to(world_pos)
		if d2 < best_d2:
			best_d2 = d2
			best_cid = cid
	return best_cid


func _spawn_boss_trophy_relic(world_pos: Vector2, origin_cid: int, species_id: int) -> int:
	var r_slot: int = -1
	for r in range(MAX_RELICS):
		if _rel_active[r] == 0:
			r_slot = r
			break
	if r_slot < 0:
		var low_r: int = 1 << 29
		for r in range(MAX_RELICS):
			if _rel_holder_uid[r] < 0 and _rel_renown[r] < low_r:
				low_r = _rel_renown[r]
				r_slot = r
	if r_slot < 0:
		return -1
	const TROPHY_NAMES := ["Сердце Левиафана", "Ядро Титана", "Хитин Матриарха", "Венец Бездны"]
	_rel_active[r_slot] = 1
	_rel_kind[r_slot] = 3
	_rel_holder_uid[r_slot] = -1
	_rel_holder_nid[r_slot] = -1
	_rel_pos[r_slot] = world_pos
	_rel_origin_cid[r_slot] = origin_cid
	_rel_name[r_slot] = TROPHY_NAMES[absi(species_id) % TROPHY_NAMES.size()]
	_rel_renown[r_slot] = 25
	return r_slot


func get_notable_card(uid: int) -> Dictionary:
	var n: int = _find_notable_by_uid(uid)
	if n < 0:
		return {"found": false}
	var d: Dictionary = _build_notable_dict(n)
	d["found"] = true
	return d


func pack_social_extensions(buf: StreamPeerBuffer) -> void:
	ensure_allocated()
	buf.put_u8(MAX_PLOTS)
	for i in range(MAX_PLOTS):
		buf.put_u8(_plot_active[i])
		if _plot_active[i] != 0:
			buf.put_u8(_plot_kind[i])
			buf.put_32(_plot_src_cid[i])
			buf.put_32(_plot_dst_cid[i])
			buf.put_float(_plot_elapsed[i])
			buf.put_float(_plot_dur[i])
			buf.put_32(_plot_instigator_nid[i])
	_pack_notables_and_relics(buf)


func _pack_notables_and_relics(buf: StreamPeerBuffer) -> void:
	buf.put_u8(MAX_NOTABLES)
	for n in range(MAX_NOTABLES):
		buf.put_u8(_not_active[n])
		if _not_active[n] == 0:
			continue
		buf.put_32(_not_uid[n])
		buf.put_32(_not_slot[n])
		buf.put_u8(_not_faction[n])
		buf.put_u8(_not_rank[n])
		buf.put_32(_not_city_id[n])
		buf.put_32(_not_kingdom_id[n])
		buf.put_32(_not_clan_id[n])
		buf.put_32(_not_traits[n])
		buf.put_32(_not_relic_id[n])
		buf.put_u8(_not_state[n])
		buf.put_u8(_not_pinned[n])
		buf.put_32(_not_duel_uid[n])
		buf.put_32(_not_renown[n])
		buf.put_utf8_string(_not_name[n])
		buf.put_float(_not_last_pos[n].x)
		buf.put_float(_not_last_pos[n].y)
		buf.put_u8(_not_mem_count[n])
		buf.put_u8(_not_mem_head[n])
		var base: int = n * NOTABLE_MEM_SLOTS
		for m in range(NOTABLE_MEM_SLOTS):
			buf.put_u8(_not_mem_verb[base + m])
			buf.put_32(_not_mem_subj_uid[base + m])
			buf.put_32(_not_mem_city[base + m])
			buf.put_float(_not_mem_time[base + m])
	buf.put_u8(MAX_RELICS)
	for r in range(MAX_RELICS):
		buf.put_u8(_rel_active[r])
		if _rel_active[r] != 0:
			buf.put_u8(_rel_kind[r])
			buf.put_32(_rel_holder_uid[r])
			buf.put_32(_rel_holder_nid[r])
			buf.put_float(_rel_pos[r].x)
			buf.put_float(_rel_pos[r].y)
			buf.put_32(_rel_origin_cid[r])
			buf.put_utf8_string(_rel_name[r])
			buf.put_32(_rel_renown[r])
	buf.put_u8(MAX_FEUDS)
	for f in range(MAX_FEUDS):
		buf.put_u8(_feud_active[f])
		if _feud_active[f] != 0:
			buf.put_32(_feud_src_clan[f])
			buf.put_32(_feud_tgt_uid[f])
			buf.put_32(_feud_tgt_clan[f])
			buf.put_float(_feud_ttl[f])
			buf.put_u8(_feud_reason[f])


func unpack_social_extensions(buf: StreamPeerBuffer) -> void:
	ensure_allocated()
	_notable_last_sync_t = -10.0
	_relic_last_scan_t = -10.0
	_exp_active_cnt = 0
	_colonize_cd_active = false
	_boss_hunt_uid = -1
	_boss_hunt_pos = Vector2.ZERO
	if buf.get_available_bytes() <= 0:
		return
	var p_cnt: int = buf.get_u8()
	for i in range(p_cnt):
		if buf.get_available_bytes() <= 0:
			return
		var act: int = buf.get_u8()
		if i < MAX_PLOTS:
			_plot_active[i] = act
		if act != 0:
			var k: int = buf.get_u8()
			var src: int = buf.get_32()
			var dst: int = buf.get_32()
			var el: float = buf.get_float()
			var dur: float = buf.get_float()
			var inst: int = buf.get_32()
			if i < MAX_PLOTS:
				_plot_kind[i] = k
				_plot_src_cid[i] = src
				_plot_dst_cid[i] = dst
				_plot_elapsed[i] = el
				_plot_dur[i] = dur
				_plot_instigator_nid[i] = inst
	if buf.get_available_bytes() > 0:
		_unpack_notables(buf)
	if buf.get_available_bytes() > 0:
		_unpack_relics_and_feuds(buf)


func _unpack_notables(buf: StreamPeerBuffer) -> void:
	var n_cnt: int = buf.get_u8()
	for n in range(n_cnt):
		if buf.get_available_bytes() <= 0:
			return
		var act: int = buf.get_u8()
		if act == 0:
			if n < MAX_NOTABLES:
				_not_active[n] = 0
			continue
		var uid: int = buf.get_32()
		var sl: int = buf.get_32()
		var fac: int = buf.get_u8()
		var rk: int = buf.get_u8()
		var cid: int = buf.get_32()
		var kid: int = buf.get_32()
		var cln: int = buf.get_32()
		var tr: int = buf.get_32()
		var rid: int = buf.get_32()
		var st: int = buf.get_u8()
		var pin: int = buf.get_u8()
		var du: int = buf.get_32()
		var ren: int = buf.get_32()
		var nm: String = buf.get_utf8_string()
		var lp := Vector2(buf.get_float(), buf.get_float())
		var mc: int = buf.get_u8()
		var mh: int = buf.get_u8()
		if n < MAX_NOTABLES:
			_not_active[n] = 1
			_not_uid[n] = uid
			_not_slot[n] = sl
			_not_faction[n] = fac
			_not_rank[n] = rk
			_not_city_id[n] = cid
			_not_kingdom_id[n] = kid
			_not_clan_id[n] = cln
			_not_traits[n] = tr
			_not_relic_id[n] = rid
			_not_state[n] = st
			_not_pinned[n] = pin
			_not_duel_uid[n] = du
			_not_renown[n] = ren
			_not_name[n] = nm
			_not_last_pos[n] = lp
			_not_mem_count[n] = mc
			_not_mem_head[n] = mh
		var base: int = n * NOTABLE_MEM_SLOTS
		for m in range(NOTABLE_MEM_SLOTS):
			var mv: int = buf.get_u8()
			var msu: int = buf.get_32()
			var mc2: int = buf.get_32()
			var mt: float = buf.get_float()
			if n < MAX_NOTABLES:
				_not_mem_verb[base + m] = mv
				_not_mem_subj_uid[base + m] = msu
				_not_mem_city[base + m] = mc2
				_not_mem_time[base + m] = mt


func _unpack_relics_and_feuds(buf: StreamPeerBuffer) -> void:
	var r_cnt: int = buf.get_u8()
	for r in range(r_cnt):
		if buf.get_available_bytes() <= 0:
			return
		var act: int = buf.get_u8()
		if r < MAX_RELICS:
			_rel_active[r] = act
		if act != 0:
			var rk: int = buf.get_u8()
			var hu: int = buf.get_32()
			var hn: int = buf.get_32()
			var rp := Vector2(buf.get_float(), buf.get_float())
			var oc: int = buf.get_32()
			var rn: String = buf.get_utf8_string()
			var rr: int = buf.get_32()
			if r < MAX_RELICS:
				_rel_kind[r] = rk
				_rel_holder_uid[r] = hu
				_rel_holder_nid[r] = hn
				_rel_pos[r] = rp
				_rel_origin_cid[r] = oc
				_rel_name[r] = rn
				_rel_renown[r] = rr
	if buf.get_available_bytes() <= 0:
		return
	var f_cnt: int = buf.get_u8()
	for f in range(f_cnt):
		if buf.get_available_bytes() <= 0:
			return
		var act: int = buf.get_u8()
		if f < MAX_FEUDS:
			_feud_active[f] = act
		if act != 0:
			var sc: int = buf.get_32()
			var tu: int = buf.get_32()
			var tc: int = buf.get_32()
			var tt: float = buf.get_float()
			var rs: int = buf.get_u8()
			if f < MAX_FEUDS:
				_feud_src_clan[f] = sc
				_feud_tgt_uid[f] = tu
				_feud_tgt_clan[f] = tc
				_feud_ttl[f] = tt
				_feud_reason[f] = rs
