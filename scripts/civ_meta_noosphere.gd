extends RefCounted

## Persistent Naval Fleet, War/Alliance/Army/Clan Meta-Pools,
## Noosphere (Culture, Creed, Language, Syllabic Onomastics, Codex),
## Extended Plots (3..11), Loyalty/Opinion Factors, and HistoryRingBuffers.
## Strictly 0 class_name and 0 preload.

const MAX_CITIES: int = 64
const MAX_KINGDOMS: int = 64
const MAX_SHIPS: int = 32
const MAX_SHIP_TROOPS: int = 12
const MAX_WARS: int = 16
const MAX_ALLIANCES: int = 16
const MAX_CLANS: int = 32
const MAX_CULTURES: int = 32
const MAX_CREEDS: int = 24
const MAX_LANGUAGES: int = 24
const MAX_BOOKS: int = 48
const MAX_PAST_CAPTAINS: int = 6

const SHIP_FISHING: int = 0
const SHIP_TRADER: int = 1
const SHIP_TROOP: int = 2

const SHIP_STATE_IDLE: int = 0
const SHIP_STATE_SAIL_OUT: int = 1
const SHIP_STATE_LOADING: int = 2
const SHIP_STATE_MISSION: int = 3
const SHIP_STATE_RETURN: int = 4

const WAR_CONQUEST: int = 0
const WAR_REBELLION: int = 1
const WAR_SPITE: int = 2
const WAR_COALITION: int = 3
const WAR_TOTAL: int = 4

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

const BLD_CAMPFIRE: int = 0
const BLD_DOCK: int = 10
const BLD_BARRACKS: int = 11
const BLD_DEFENSE_TURRET: int = 12
const BLD_TRADE_HUB: int = 13
const BLD_ARCHIVE: int = 14
const BLD_MONOLITH: int = 15

const BLD_COL_SHIP_FISH: int = 53
const BLD_COL_SHIP_TRADE: int = 54
const BLD_COL_SHIP_TROOP: int = 55

const SUCC_HEREDITARY: int = 0
const SUCC_MERITOCRACY: int = 1
const SUCC_ELECTIVE: int = 2
const SUCC_SHATTERED: int = 3

const ETHOS_EXPANSION: int = 1
const ETHOS_SCHOLAR: int = 2
const ETHOS_SERENE: int = 4
const ETHOS_XENOPHILE: int = 8
const ETHOS_XENOPHOBE: int = 16
const ETHOS_FORTIFIED: int = 32
const ETHOS_MERCANTILE: int = 64
const ETHOS_SEAFARING: int = 128

const HIST_SAMPLES: int = 40
const HIST_SCALES: int = 3
const HIST_WORLD_METRICS: int = 10
const HIST_K_METRICS: int = 6
const HIST_SCALE_STEPS := [0.25, 1.5, 15.0]

const STRIP_PLOT_PEACE: int = 23
const STRIP_PLOT_ALLIANCE: int = 24
const STRIP_PLOT_SCHISM: int = 25
const STRIP_PLOT_CODEX: int = 26
const STRIP_KING_CROWN: int = 27
const STRIP_LEADER_STAR: int = 28
const STRIP_PORTAL: int = 11

const WAR_TYPE_NAMES_RU := ["Завоевание", "Мятеж", "Злоба", "Коалиция", "Тотальная"]
const SHIP_TYPE_NAMES_RU := ["Рыбак", "Торговец", "Десантный катер"]
const TOWN_PLAN_NAMES_RU := ["Решётка", "Кольца", "Гексы", "Перекрёсток", "Лабиринт", "Кластеры"]
const WEAPON_PREF_NAMES_RU := ["Баланс", "Лазерная точность", "Тяжёлая плазма", "Био-осколки", "Фаланга щитов"]
const SUCC_LAW_NAMES_RU := ["Династия", "Меритократия", "Совет", "Расколотая корона"]
const CREED_TENET_NAMES_RU := ["Солнечная Гармония", "Восход Машин", "Симбиоз Спор", "Звёздный Поход", "Бдение Пустоты", "Путь Монолита"]
const CREED_RITE_NAMES_RU := ["Орбитальный Щит", "Жатва", "Боевой Транс", "Зов Монолита", "Крио-Покой"]
const CLAN_TRAIT_NAMES_RU := ["Железная Воля", "Серебряный Язык", "Кровь Титанов", "Бич Пустоты", "Гении Кода", "Рождённые в Бою", "Морская Кровь", "Клятва Щита"]
const BOOK_KIND_NAMES_RU := ["История", "Тактика", "Экономика", "Генетика", "Дипломатия", "Хроника", "Кодекс Веры"]
const PLOT_NAMES_RU := [
	"Война", "Пакт", "Мятеж", "Мирный договор", "Создание альянса", "Вступление в альянс",
	"Разрыв альянса", "Культурный раскол", "Написание кодекса", "Ритуал щита", "Зов Монолита", "Реформа власти",
]
const HIST_METRIC_KEYS := ["population", "cities", "wars", "buildings", "science", "food", "ore", "energy", "credits", "deaths"]
const HIST_K_METRIC_KEYS := ["population", "cities", "zones", "science", "credits", "wars"]

const CULTURE_PALETTES := [
	Color("#4CE4FF"), Color("#56B8FF"), Color("#4BE8B0"), Color("#FFD166"),
	Color("#FF6B6B"), Color("#FF9F43"), Color("#B86BFF"), Color("#E066FF"),
	Color("#78E08F"), Color("#A4B0BE"), Color("#F8A5C2"), Color("#63CDDA"),
]

const ONO_ONSETS := [
	["Кеп", "Вес", "Ар", "Зар", "Та", "Се", "Ме", "О", "Нов", "Гар", "Ла", "Бер", "Ал", "Эг", "Кор", "Да"],
	["Фер", "Квар", "Ано", "Сиг", "Век", "Мат", "Тор", "Ом", "Рел", "Ска", "Им", "Ди", "Тек", "Зет", "Кро", "Би"],
	["Ми", "Ри", "Спо", "Кро", "Ги", "Ли", "Мхо", "Пы", "Сим", "Вен", "Ро", "Хор", "Ден", "Фло", "Тал", "Зев"],
]
const ONO_MIDS := [
	["ли", "ра", "ве", "то", "си", "но", "ро", "ка", "ми", "де", "ор", "ал"],
	["рит", "тек", "рон", "лис", "мег", "ак", "ин", "од", "ор", "уль", "кс", "ет"],
	["це", "зо", "ли", "на", "фо", "ра", "ша", "ве", "де", "со", "ма", "ти"],
]
const ONO_CODAS := [
	["град", "порт", "стан", "дор", "он", "ис", "ар", "ея", "ия", "аль", "ус", "а"],
	["-Узел", "-Цех", "-Луч", "-Ядро", "он", "ик", "ат", "ор", "-IX", "-7", "ум", "ек"],
	["лис", "вия", "ро", "ра", "дельта", "шпиль", "грот", "лог", "ос", "а", "он", "ис"],
]
const DIALECT_MUTATIONS := [
	["К", "Г"], ["Т", "Д"], ["П", "Б"], ["С", "З"], ["А", "О"], ["Е", "И"], ["Р", "Л"], ["В", "Ф"],
]

var _meta_rng := RandomNumberGenerator.new()
var _allocated: bool = false

# Persistent Fleet (MAX_SHIPS = 32)
var _ship_active: PackedByteArray
var _ship_kind: PackedByteArray
var _ship_state: PackedByteArray
var _ship_faction: PackedByteArray
var _ship_city_id: PackedInt32Array
var _ship_target_city: PackedInt32Array
var _ship_pos: PackedVector2Array
var _ship_home_pos: PackedVector2Array
var _ship_dst_pos: PackedVector2Array
var _ship_pickup_shore: PackedVector2Array
var _ship_dropoff_shore: PackedVector2Array
var _ship_hp: PackedFloat32Array
var _ship_max_hp: PackedFloat32Array
var _ship_cargo: PackedFloat32Array
var _ship_wait_t: PackedFloat32Array
var _ship_fire_cd: PackedFloat32Array
var _ship_phase: PackedFloat32Array
var _ship_facing: PackedFloat32Array
var _ship_troop_count: PackedInt32Array
var _ship_troop_uids: PackedInt32Array

# Wars (MAX_WARS = 16, 4x16-bit masks per side = 64 kingdoms)
var _war_active: PackedByteArray
var _war_type: PackedByteArray
var _war_name: PackedStringArray
var _war_main_att_kid: PackedInt32Array
var _war_main_def_kid: PackedInt32Array
var _war_att_mask: PackedInt32Array
var _war_def_mask: PackedInt32Array
var _war_start_t: PackedFloat32Array
var _war_duration: PackedFloat32Array
var _war_att_deaths: PackedInt32Array
var _war_def_deaths: PackedInt32Array
var _war_zones_flipped: PackedInt32Array
var _war_score: PackedFloat32Array

# Alliances (MAX_ALLIANCES = 16)
var _ally_active: PackedByteArray
var _ally_name: PackedStringArray
var _ally_motto: PackedStringArray
var _ally_founder_kid: PackedInt32Array
var _ally_member_mask: PackedInt32Array
var _ally_member_count: PackedInt32Array
var _ally_age_sec: PackedFloat32Array
var _ally_color: PackedColorArray

# Armies (MAX_CITIES = 64)
var _army_active: PackedByteArray
var _army_kingdom_id: PackedInt32Array
var _army_captain_uid: PackedInt32Array
var _army_captain_name: PackedStringArray
var _army_strength: PackedInt32Array
var _army_kills: PackedInt32Array
var _army_campaigns: PackedInt32Array
var _army_past_captains: Array[PackedStringArray] = []

# Clans & Kingdom dynastic fields
var _clan_active: PackedByteArray
var _clan_name: PackedStringArray
var _clan_motto: PackedStringArray
var _clan_faction: PackedByteArray
var _clan_home_cid: PackedInt32Array
var _clan_trait_id: PackedInt32Array
var _clan_renown: PackedInt32Array
var _clan_member_count: PackedInt32Array
var _clan_generation: PackedInt32Array

var _kingdom_royal_clan: PackedInt32Array
var _kingdom_king_uid: PackedInt32Array
var _kingdom_king_name: PackedStringArray
var _kingdom_king_intel: PackedInt32Array
var _kingdom_king_rule_sec: PackedFloat32Array
var _kingdom_alliance_id: PackedInt32Array
var _kingdom_culture_id: PackedInt32Array
var _kingdom_creed_id: PackedInt32Array
var _kingdom_truce: PackedFloat32Array

# Noosphere: Cultures, Creeds, Languages, Codices/Books
var _cul_active: PackedByteArray
var _cul_name: PackedStringArray
var _cul_faction: PackedByteArray
var _cul_parent_id: PackedInt32Array
var _cul_level: PackedInt32Array
var _cul_xp: PackedFloat32Array
var _cul_color: PackedColorArray
var _cul_town_plan: PackedByteArray
var _cul_weapon_pref: PackedByteArray
var _cul_succ_law: PackedByteArray
var _cul_ethos_flags: PackedInt32Array
var _cul_lang_id: PackedInt32Array
var _cul_creed_id: PackedInt32Array
var _cul_city_count: PackedInt32Array
var _cul_pop_count: PackedInt32Array

var _creed_active: PackedByteArray
var _creed_name: PackedStringArray
var _creed_tenet: PackedByteArray
var _creed_rite: PackedByteArray
var _creed_color: PackedColorArray
var _creed_followers: PackedInt32Array

var _lang_active: PackedByteArray
var _lang_name: PackedStringArray
var _lang_faction: PackedByteArray
var _lang_parent_id: PackedInt32Array
var _lang_mutation_gen: PackedInt32Array
var _lang_shift_idx: PackedInt32Array

var _book_active: PackedByteArray
var _book_title: PackedStringArray
var _book_kind: PackedByteArray
var _book_city_id: PackedInt32Array
var _book_culture_id: PackedInt32Array
var _book_creed_id: PackedInt32Array
var _book_author: PackedStringArray
var _book_reads: PackedInt32Array
var _book_trait_id: PackedInt32Array

# City-level meta attachments
var _city_culture_id: PackedInt32Array
var _city_creed_id: PackedInt32Array
var _city_lang_id: PackedInt32Array
var _city_clan_id: PackedInt32Array
var _city_ferry_cd: PackedFloat32Array
var _city_conquest_sec: PackedFloat32Array

# HistoryRingBuffers (3 scales x 10 world metrics x 40 samples + per-kingdom)
var _hist_world_buf: PackedFloat32Array
var _hist_world_head: PackedInt32Array
var _hist_world_cnt: PackedInt32Array
var _hist_world_acc: PackedFloat32Array
var _hist_k_buf: PackedFloat32Array
var _hist_k_head: PackedInt32Array
var _hist_k_cnt: PackedInt32Array
var _world_deaths_total: int = 0

# Budget timers & cursors
var _fleet_ai_raw_cd: float = 0.0
var _fleet_ai_pace_acc: float = 0.0
var _meta_raw_cd: float = 0.0
var _meta_pace_acc: float = 0.0
var _meta_city_cursor: int = 0
var _turret_raw_cd: float = 0.0
var _turret_pace_acc: float = 0.0
var _hist_raw_cd: float = 0.0
var _hist_pace_acc: float = 0.0
var _ship_active_count: int = 0
var _fleet_step_idx: int = 0
var _tmp_a_sol: PackedInt32Array
var _tmp_a_best_u: PackedInt32Array
var _tmp_a_best_sc: PackedInt32Array
var _tmp_a_cap_alive: PackedByteArray
var _tmp_k_pop: PackedInt32Array
var _tmp_k_cit: PackedInt32Array
var _tmp_k_zon: PackedInt32Array
var _tmp_k_sci: PackedFloat32Array
var _tmp_k_crd: PackedFloat32Array
var _tmp_k_war: PackedByteArray


func ensure_allocated() -> void:
	if _allocated:
		return
	_allocated = true
	_alloc_fleet_and_wars()
	_alloc_noosphere_and_clans()
	_alloc_history_buffers()
	reset_all(20261114)


func _alloc_fleet_and_wars() -> void:
	_ship_active.resize(MAX_SHIPS)
	_ship_kind.resize(MAX_SHIPS)
	_ship_state.resize(MAX_SHIPS)
	_ship_faction.resize(MAX_SHIPS)
	_ship_city_id.resize(MAX_SHIPS)
	_ship_target_city.resize(MAX_SHIPS)
	_ship_pos.resize(MAX_SHIPS)
	_ship_home_pos.resize(MAX_SHIPS)
	_ship_dst_pos.resize(MAX_SHIPS)
	_ship_pickup_shore.resize(MAX_SHIPS)
	_ship_dropoff_shore.resize(MAX_SHIPS)
	_ship_hp.resize(MAX_SHIPS)
	_ship_max_hp.resize(MAX_SHIPS)
	_ship_cargo.resize(MAX_SHIPS)
	_ship_wait_t.resize(MAX_SHIPS)
	_ship_fire_cd.resize(MAX_SHIPS)
	_ship_phase.resize(MAX_SHIPS)
	_ship_facing.resize(MAX_SHIPS)
	_ship_troop_count.resize(MAX_SHIPS)
	_ship_troop_uids.resize(MAX_SHIPS * MAX_SHIP_TROOPS)

	_war_active.resize(MAX_WARS)
	_war_type.resize(MAX_WARS)
	_war_name.resize(MAX_WARS)
	_war_main_att_kid.resize(MAX_WARS)
	_war_main_def_kid.resize(MAX_WARS)
	_war_att_mask.resize(MAX_WARS * 4)
	_war_def_mask.resize(MAX_WARS * 4)
	_war_start_t.resize(MAX_WARS)
	_war_duration.resize(MAX_WARS)
	_war_att_deaths.resize(MAX_WARS)
	_war_def_deaths.resize(MAX_WARS)
	_war_zones_flipped.resize(MAX_WARS)
	_war_score.resize(MAX_WARS)

	_ally_active.resize(MAX_ALLIANCES)
	_ally_name.resize(MAX_ALLIANCES)
	_ally_motto.resize(MAX_ALLIANCES)
	_ally_founder_kid.resize(MAX_ALLIANCES)
	_ally_member_mask.resize(MAX_ALLIANCES * 4)
	_ally_member_count.resize(MAX_ALLIANCES)
	_ally_age_sec.resize(MAX_ALLIANCES)
	_ally_color.resize(MAX_ALLIANCES)


func _alloc_noosphere_and_clans() -> void:
	_army_active.resize(MAX_CITIES)
	_army_kingdom_id.resize(MAX_CITIES)
	_army_captain_uid.resize(MAX_CITIES)
	_army_captain_name.resize(MAX_CITIES)
	_army_strength.resize(MAX_CITIES)
	_army_kills.resize(MAX_CITIES)
	_army_campaigns.resize(MAX_CITIES)
	_army_past_captains.clear()
	for _c in range(MAX_CITIES):
		_army_past_captains.append(PackedStringArray())

	_clan_active.resize(MAX_CLANS)
	_clan_name.resize(MAX_CLANS)
	_clan_motto.resize(MAX_CLANS)
	_clan_faction.resize(MAX_CLANS)
	_clan_home_cid.resize(MAX_CLANS)
	_clan_trait_id.resize(MAX_CLANS)
	_clan_renown.resize(MAX_CLANS)
	_clan_member_count.resize(MAX_CLANS)
	_clan_generation.resize(MAX_CLANS)

	_kingdom_royal_clan.resize(MAX_KINGDOMS)
	_kingdom_king_uid.resize(MAX_KINGDOMS)
	_kingdom_king_name.resize(MAX_KINGDOMS)
	_kingdom_king_intel.resize(MAX_KINGDOMS)
	_kingdom_king_rule_sec.resize(MAX_KINGDOMS)
	_kingdom_alliance_id.resize(MAX_KINGDOMS)
	_kingdom_culture_id.resize(MAX_KINGDOMS)
	_kingdom_creed_id.resize(MAX_KINGDOMS)
	_kingdom_truce.resize(MAX_KINGDOMS * MAX_KINGDOMS)

	_cul_active.resize(MAX_CULTURES)
	_cul_name.resize(MAX_CULTURES)
	_cul_faction.resize(MAX_CULTURES)
	_cul_parent_id.resize(MAX_CULTURES)
	_cul_level.resize(MAX_CULTURES)
	_cul_xp.resize(MAX_CULTURES)
	_cul_color.resize(MAX_CULTURES)
	_cul_town_plan.resize(MAX_CULTURES)
	_cul_weapon_pref.resize(MAX_CULTURES)
	_cul_succ_law.resize(MAX_CULTURES)
	_cul_ethos_flags.resize(MAX_CULTURES)
	_cul_lang_id.resize(MAX_CULTURES)
	_cul_creed_id.resize(MAX_CULTURES)
	_cul_city_count.resize(MAX_CULTURES)
	_cul_pop_count.resize(MAX_CULTURES)

	_creed_active.resize(MAX_CREEDS)
	_creed_name.resize(MAX_CREEDS)
	_creed_tenet.resize(MAX_CREEDS)
	_creed_rite.resize(MAX_CREEDS)
	_creed_color.resize(MAX_CREEDS)
	_creed_followers.resize(MAX_CREEDS)

	_lang_active.resize(MAX_LANGUAGES)
	_lang_name.resize(MAX_LANGUAGES)
	_lang_faction.resize(MAX_LANGUAGES)
	_lang_parent_id.resize(MAX_LANGUAGES)
	_lang_mutation_gen.resize(MAX_LANGUAGES)
	_lang_shift_idx.resize(MAX_LANGUAGES)

	_book_active.resize(MAX_BOOKS)
	_book_title.resize(MAX_BOOKS)
	_book_kind.resize(MAX_BOOKS)
	_book_city_id.resize(MAX_BOOKS)
	_book_culture_id.resize(MAX_BOOKS)
	_book_creed_id.resize(MAX_BOOKS)
	_book_author.resize(MAX_BOOKS)
	_book_reads.resize(MAX_BOOKS)
	_book_trait_id.resize(MAX_BOOKS)

	_city_culture_id.resize(MAX_CITIES)
	_city_creed_id.resize(MAX_CITIES)
	_city_lang_id.resize(MAX_CITIES)
	_city_clan_id.resize(MAX_CITIES)
	_city_ferry_cd.resize(MAX_CITIES)
	_city_conquest_sec.resize(MAX_CITIES)


func _alloc_history_buffers() -> void:
	_hist_world_buf.resize(HIST_SCALES * HIST_WORLD_METRICS * HIST_SAMPLES)
	_hist_world_head.resize(HIST_SCALES)
	_hist_world_cnt.resize(HIST_SCALES)
	_hist_world_acc.resize(HIST_SCALES)
	_hist_k_buf.resize(MAX_KINGDOMS * HIST_SCALES * HIST_K_METRICS * HIST_SAMPLES)
	_hist_k_head.resize(MAX_KINGDOMS * HIST_SCALES)
	_hist_k_cnt.resize(MAX_KINGDOMS * HIST_SCALES)
	_tmp_a_sol.resize(MAX_CITIES)
	_tmp_a_best_u.resize(MAX_CITIES)
	_tmp_a_best_sc.resize(MAX_CITIES)
	_tmp_a_cap_alive.resize(MAX_CITIES)
	_tmp_k_pop.resize(MAX_KINGDOMS)
	_tmp_k_cit.resize(MAX_KINGDOMS)
	_tmp_k_zon.resize(MAX_KINGDOMS)
	_tmp_k_sci.resize(MAX_KINGDOMS)
	_tmp_k_crd.resize(MAX_KINGDOMS)
	_tmp_k_war.resize(MAX_KINGDOMS)


func reset_all(seed_val: int = 20261114) -> void:
	ensure_allocated()
	_meta_rng.seed = (seed_val ^ 0x4D455441) if seed_val != 0 else 0x4D455441
	_ship_active.fill(0)
	_ship_kind.fill(0)
	_ship_state.fill(SHIP_STATE_IDLE)
	_ship_faction.fill(0)
	_ship_city_id.fill(-1)
	_ship_target_city.fill(-1)
	_ship_pos.fill(Vector2.ZERO)
	_ship_home_pos.fill(Vector2.ZERO)
	_ship_dst_pos.fill(Vector2.ZERO)
	_ship_pickup_shore.fill(Vector2.ZERO)
	_ship_dropoff_shore.fill(Vector2.ZERO)
	_ship_hp.fill(100.0)
	_ship_max_hp.fill(100.0)
	_ship_cargo.fill(0.0)
	_ship_wait_t.fill(0.0)
	_ship_fire_cd.fill(0.0)
	_ship_phase.fill(0.0)
	_ship_facing.fill(1.0)
	_ship_troop_count.fill(0)
	_ship_troop_uids.fill(-1)
	_ship_active_count = 0

	_war_active.fill(0)
	_war_type.fill(0)
	for w in range(MAX_WARS):
		_war_name[w] = ""
	_war_main_att_kid.fill(-1)
	_war_main_def_kid.fill(-1)
	_war_att_mask.fill(0)
	_war_def_mask.fill(0)
	_war_start_t.fill(0.0)
	_war_duration.fill(0.0)
	_war_att_deaths.fill(0)
	_war_def_deaths.fill(0)
	_war_zones_flipped.fill(0)
	_war_score.fill(0.0)

	_ally_active.fill(0)
	for a in range(MAX_ALLIANCES):
		_ally_name[a] = ""
		_ally_motto[a] = ""
	_ally_founder_kid.fill(-1)
	_ally_member_mask.fill(0)
	_ally_member_count.fill(0)
	_ally_age_sec.fill(0.0)
	_ally_color.fill(Color.CYAN)
	_reset_noosphere_and_history()


func _reset_noosphere_and_history() -> void:
	_army_active.fill(0)
	_army_kingdom_id.fill(-1)
	_army_captain_uid.fill(-1)
	for c in range(MAX_CITIES):
		_army_captain_name[c] = ""
		_army_past_captains[c] = PackedStringArray()
	_army_strength.fill(0)
	_army_kills.fill(0)
	_army_campaigns.fill(0)

	_clan_active.fill(0)
	for cl in range(MAX_CLANS):
		_clan_name[cl] = ""
		_clan_motto[cl] = ""
	_clan_faction.fill(0)
	_clan_home_cid.fill(-1)
	_clan_trait_id.fill(0)
	_clan_renown.fill(0)
	_clan_member_count.fill(0)
	_clan_generation.fill(1)

	_kingdom_royal_clan.fill(-1)
	_kingdom_king_uid.fill(-1)
	for k in range(MAX_KINGDOMS):
		_kingdom_king_name[k] = ""
	_kingdom_king_intel.fill(4)
	_kingdom_king_rule_sec.fill(0.0)
	_kingdom_alliance_id.fill(-1)
	_kingdom_culture_id.fill(-1)
	_kingdom_creed_id.fill(-1)
	_kingdom_truce.fill(0.0)

	_cul_active.fill(0)
	for cu in range(MAX_CULTURES):
		_cul_name[cu] = ""
	_cul_parent_id.fill(-1)
	_cul_level.fill(1)
	_cul_xp.fill(0.0)
	_cul_color.fill(CULTURE_PALETTES[0])
	_cul_town_plan.fill(0)
	_cul_weapon_pref.fill(0)
	_cul_succ_law.fill(SUCC_HEREDITARY)
	_cul_ethos_flags.fill(0)
	_cul_lang_id.fill(-1)
	_cul_creed_id.fill(-1)
	_cul_city_count.fill(0)
	_cul_pop_count.fill(0)

	_creed_active.fill(0)
	for cr in range(MAX_CREEDS):
		_creed_name[cr] = ""
	_creed_tenet.fill(0)
	_creed_rite.fill(0)
	_creed_followers.fill(0)

	_lang_active.fill(0)
	for lg in range(MAX_LANGUAGES):
		_lang_name[lg] = ""
	_lang_parent_id.fill(-1)
	_lang_mutation_gen.fill(0)
	_lang_shift_idx.fill(0)

	_book_active.fill(0)
	for bk in range(MAX_BOOKS):
		_book_title[bk] = ""
		_book_author[bk] = ""
	_book_city_id.fill(-1)
	_book_culture_id.fill(-1)
	_book_creed_id.fill(-1)
	_book_reads.fill(0)
	_book_trait_id.fill(0)

	_city_culture_id.fill(-1)
	_city_creed_id.fill(-1)
	_city_lang_id.fill(-1)
	_city_clan_id.fill(-1)
	_city_ferry_cd.fill(0.0)
	_city_conquest_sec.fill(0.0)

	_hist_world_buf.fill(0.0)
	_hist_world_head.fill(0)
	_hist_world_cnt.fill(0)
	_hist_world_acc.fill(0.0)
	_hist_k_buf.fill(0.0)
	_hist_k_head.fill(0)
	_hist_k_cnt.fill(0)
	_world_deaths_total = 0

	_fleet_ai_raw_cd = 0.25
	_fleet_ai_pace_acc = 0.0
	_meta_raw_cd = 0.25
	_meta_pace_acc = 0.0
	_meta_city_cursor = 0
	_turret_raw_cd = 0.20
	_turret_pace_acc = 0.0
	_hist_raw_cd = 0.0
	_hist_pace_acc = 0.0


# --- Bitmask Helpers (4 x 16-bit chunks for 0..63 kingdoms, sign-safe) ---

func _mask_has(arr: PackedInt32Array, slot: int, kid: int) -> bool:
	if kid < 0 or kid >= MAX_KINGDOMS:
		return false
	return (arr[slot * 4 + (kid >> 4)] & (1 << (kid & 15))) != 0


func _mask_set(arr: PackedInt32Array, slot: int, kid: int) -> void:
	if kid >= 0 and kid < MAX_KINGDOMS:
		arr[slot * 4 + (kid >> 4)] |= (1 << (kid & 15))


func _mask_clear(arr: PackedInt32Array, slot: int, kid: int) -> void:
	if kid >= 0 and kid < MAX_KINGDOMS:
		arr[slot * 4 + (kid >> 4)] &= ~(1 << (kid & 15))


func _mask_clear_all(arr: PackedInt32Array, slot: int) -> void:
	var base: int = slot * 4
	for k in range(4):
		arr[base + k] = 0


func _mask_count(arr: PackedInt32Array, slot: int) -> int:
	var cnt: int = 0
	var base: int = slot * 4
	for w in range(4):
		var v: int = arr[base + w] & 0xFFFF
		while v != 0:
			cnt += (v & 1)
			v >>= 1
	return cnt


func _mask_list(arr: PackedInt32Array, slot: int) -> Array[int]:
	var out: Array[int] = []
	for kid in range(MAX_KINGDOMS):
		if _mask_has(arr, slot, kid):
			out.append(kid)
	return out


# --- Syllabic Onomastics & Dialect Mutation ---

func _mutate_syllable(syl: String, shift_idx: int, gen: int) -> String:
	if gen <= 0 or syl.is_empty():
		return syl
	var out: String = syl
	var mut: Array = DIALECT_MUTATIONS[posmod(shift_idx, DIALECT_MUTATIONS.size())]
	var src_c: String = str(mut[0])
	var dst_c: String = str(mut[1])
	out = out.replace(src_c, dst_c)
	out = out.replace(src_c.to_lower(), dst_c.to_lower())
	if gen >= 2:
		var mut2: Array = DIALECT_MUTATIONS[posmod(shift_idx + 3, DIALECT_MUTATIONS.size())]
		out = out.replace(str(mut2[0]).to_lower(), str(mut2[1]).to_lower())
	return out


func generate_onomastic_name(meta_kind: String, fac: int, lang_id: int = -1) -> String:
	ensure_allocated()
	var f_idx: int = clampi(fac, 0, 2)
	var onsets: Array = ONO_ONSETS[f_idx]
	var mids: Array = ONO_MIDS[f_idx]
	var codas: Array = ONO_CODAS[f_idx]
	var gen: int = 0
	var shift_idx: int = 0
	if lang_id >= 0 and lang_id < MAX_LANGUAGES and _lang_active[lang_id] != 0:
		gen = _lang_mutation_gen[lang_id]
		shift_idx = _lang_shift_idx[lang_id]

	var o1: String = _mutate_syllable(str(onsets[_meta_rng.randi() % onsets.size()]), shift_idx, gen)
	var m1: String = _mutate_syllable(str(mids[_meta_rng.randi() % mids.size()]), shift_idx, gen)
	var c1: String = _mutate_syllable(str(codas[_meta_rng.randi() % codas.size()]), shift_idx, gen)
	var root: String = o1 + m1 + c1 if (gen == 0 or _meta_rng.randf() < 0.6) else (o1 + c1)
	if meta_kind == "war":
		var w_prefixes := ["Война за ", "Конфликт: ", "Осада ", "Битва у "]
		return w_prefixes[_meta_rng.randi() % w_prefixes.size()] + root
	if meta_kind == "alliance":
		var a_prefixes := ["Пакт ", "Лига ", "Союз ", "Конкорд "]
		return a_prefixes[_meta_rng.randi() % a_prefixes.size()] + root
	if meta_kind == "clan":
		var cl_prefixes := ["Дом ", "Клан ", "Династия ", "Род "]
		return cl_prefixes[_meta_rng.randi() % cl_prefixes.size()] + root
	if meta_kind == "culture":
		return "Культура " + root
	if meta_kind == "creed":
		var cr_prefixes := ["Орден ", "Культ ", "Доктрина ", "Путь "]
		return cr_prefixes[_meta_rng.randi() % cr_prefixes.size()] + root
	if meta_kind == "language":
		return "Наречие " + root
	if meta_kind == "book":
		var b_prefixes := ["Кодекс ", "Трактат ", "Хроники ", "Атлас "]
		return b_prefixes[_meta_rng.randi() % b_prefixes.size()] + root
	return root


func _ensure_language_for_faction(fac: int) -> int:
	var f_id: int = clampi(fac, 0, 2)
	for i in range(MAX_LANGUAGES):
		if _lang_active[i] != 0 and int(_lang_faction[i]) == f_id and _lang_parent_id[i] < 0:
			return i
	for i in range(MAX_LANGUAGES):
		if _lang_active[i] == 0:
			_lang_active[i] = 1
			_lang_faction[i] = f_id
			_lang_parent_id[i] = -1
			_lang_mutation_gen[i] = 0
			_lang_shift_idx[i] = f_id
			var root_names := ["Солар-Лингва", "Бинарный Синтаксис", "Мицел-Речь"]
			_lang_name[i] = root_names[f_id]
			return i
	return -1


func evolve_dialect(parent_lang_id: int, fac: int) -> int:
	var f_id: int = clampi(fac, 0, 2)
	var slot: int = -1
	for i in range(MAX_LANGUAGES):
		if _lang_active[i] == 0:
			slot = i
			break
	if slot < 0:
		return parent_lang_id if parent_lang_id >= 0 else _ensure_language_for_faction(f_id)
	var p_gen: int = _lang_mutation_gen[parent_lang_id] if (parent_lang_id >= 0 and parent_lang_id < MAX_LANGUAGES) else 0
	_lang_active[slot] = 1
	_lang_faction[slot] = f_id
	_lang_parent_id[slot] = parent_lang_id
	_lang_mutation_gen[slot] = mini(4, p_gen + 1)
	_lang_shift_idx[slot] = (_meta_rng.randi() % DIALECT_MUTATIONS.size())
	_lang_name[slot] = generate_onomastic_name("language", f_id, slot)
	return slot


# --- Noosphere & Dynasty Creation / Lifecycle ---

func _ensure_creed(fac: int, force_new: bool = false) -> int:
	var f_id: int = clampi(fac, 0, 2)
	if not force_new:
		for i in range(MAX_CREEDS):
			if _creed_active[i] != 0 and int(_creed_tenet[i]) % 3 == f_id:
				return i
	for i in range(MAX_CREEDS):
		if _creed_active[i] == 0:
			_creed_active[i] = 1
			var tenet: int = f_id if not force_new else (_meta_rng.randi() % CREED_TENET_NAMES_RU.size())
			_creed_tenet[i] = tenet
			_creed_rite[i] = _meta_rng.randi() % CREED_RITE_NAMES_RU.size()
			_creed_color[i] = CULTURE_PALETTES[(i + f_id * 3) % CULTURE_PALETTES.size()]
			_creed_followers[i] = 0
			_creed_name[i] = generate_onomastic_name("creed", f_id, -1)
			return i
	return 0


func _create_culture(fac: int, parent_cul: int, lang_id: int, creed_id: int) -> int:
	var f_id: int = clampi(fac, 0, 2)
	var slot: int = -1
	for i in range(MAX_CULTURES):
		if _cul_active[i] == 0:
			slot = i
			break
	if slot < 0:
		return parent_cul if parent_cul >= 0 else 0
	_cul_active[slot] = 1
	_cul_faction[slot] = f_id
	_cul_parent_id[slot] = parent_cul
	_cul_level[slot] = 1
	_cul_xp[slot] = 0.0
	_cul_color[slot] = CULTURE_PALETTES[(slot + f_id * 2) % CULTURE_PALETTES.size()]
	_cul_town_plan[slot] = (f_id + _meta_rng.randi()) % TOWN_PLAN_NAMES_RU.size()
	_cul_weapon_pref[slot] = (f_id + _meta_rng.randi()) % WEAPON_PREF_NAMES_RU.size()
	_cul_succ_law[slot] = _meta_rng.randi() % SUCC_LAW_NAMES_RU.size()
	var ethos: int = ETHOS_SCHOLAR if f_id == 0 else (ETHOS_FORTIFIED if f_id == 1 else ETHOS_EXPANSION)
	if _meta_rng.randf() < 0.45:
		ethos |= ETHOS_SEAFARING
	if _meta_rng.randf() < 0.35:
		ethos |= ETHOS_MERCANTILE
	_cul_ethos_flags[slot] = ethos
	_cul_lang_id[slot] = lang_id if lang_id >= 0 else _ensure_language_for_faction(f_id)
	_cul_creed_id[slot] = creed_id if creed_id >= 0 else _ensure_creed(f_id, false)
	_cul_name[slot] = generate_onomastic_name("culture", f_id, _cul_lang_id[slot])
	return slot


func _ensure_culture_for_faction(fac: int) -> int:
	var f_id: int = clampi(fac, 0, 2)
	for i in range(MAX_CULTURES):
		if _cul_active[i] != 0 and int(_cul_faction[i]) == f_id and _cul_parent_id[i] < 0:
			return i
	var lid: int = _ensure_language_for_faction(f_id)
	var crid: int = _ensure_creed(f_id, false)
	return _create_culture(f_id, -1, lid, crid)


func _create_clan(fac: int, home_cid: int, lang_id: int) -> int:
	var f_id: int = clampi(fac, 0, 2)
	for i in range(MAX_CLANS):
		if _clan_active[i] == 0:
			_clan_active[i] = 1
			_clan_faction[i] = f_id
			_clan_home_cid[i] = home_cid
			_clan_trait_id[i] = _meta_rng.randi() % CLAN_TRAIT_NAMES_RU.size()
			_clan_renown[i] = 10
			_clan_member_count[i] = 1
			_clan_generation[i] = 1
			_clan_name[i] = generate_onomastic_name("clan", f_id, lang_id)
			var mottos := ["Свет над бездной", "Сталь и расчёт", "Единство роя", "За горизонт Кеплера", "Щит не падёт"]
			_clan_motto[i] = mottos[_meta_rng.randi() % mottos.size()]
			return i
	return 0


func on_kingdom_created(civ: Node2D, kid_and_cap: Vector2i, is_rebel: bool) -> void:
	ensure_allocated()
	var kid: int = kid_and_cap.x
	var cap_cid: int = kid_and_cap.y
	if kid < 0 or kid >= MAX_KINGDOMS:
		return
	var fac: int = int(civ._kingdom_faction[kid])
	var cul_id: int = _city_culture_id[cap_cid] if (cap_cid >= 0 and _city_culture_id[cap_cid] >= 0) else _ensure_culture_for_faction(fac)
	var lang_id: int = _cul_lang_id[cul_id] if cul_id >= 0 else _ensure_language_for_faction(fac)
	var creed_id: int = _city_creed_id[cap_cid] if (cap_cid >= 0 and _city_creed_id[cap_cid] >= 0) else _ensure_creed(fac, false)
	if is_rebel and _meta_rng.randf() < 0.65:
		lang_id = evolve_dialect(lang_id, fac)
		cul_id = _create_culture(fac, cul_id, lang_id, creed_id)
		if cap_cid >= 0 and cap_cid < MAX_CITIES:
			_city_culture_id[cap_cid] = cul_id
			_city_lang_id[cap_cid] = lang_id
	_kingdom_culture_id[kid] = cul_id
	_kingdom_creed_id[kid] = creed_id
	_kingdom_alliance_id[kid] = -1
	_kingdom_king_rule_sec[kid] = 0.0
	_kingdom_king_intel[kid] = _meta_rng.randi_range(4, 9)
	_kingdom_king_name[kid] = generate_onomastic_name("notable", fac, lang_id)
	var cl_id: int = _create_clan(fac, cap_cid, lang_id)
	_kingdom_royal_clan[kid] = cl_id
	if cap_cid >= 0 and cap_cid < MAX_CITIES:
		_city_clan_id[cap_cid] = cl_id


func on_city_created(civ: Node2D, cid: int, parent_cid: int) -> void:
	ensure_allocated()
	if cid < 0 or cid >= MAX_CITIES:
		return
	var fac: int = int(civ._city_faction[cid])
	var kid: int = civ._city_kingdom_id[cid]
	var cul_id: int = -1
	var creed_id: int = -1
	var lang_id: int = -1
	if parent_cid >= 0 and parent_cid < MAX_CITIES and _city_culture_id[parent_cid] >= 0:
		cul_id = _city_culture_id[parent_cid]
		creed_id = _city_creed_id[parent_cid]
		lang_id = _city_lang_id[parent_cid]
	elif kid >= 0 and kid < MAX_KINGDOMS and _kingdom_culture_id[kid] >= 0:
		cul_id = _kingdom_culture_id[kid]
		creed_id = _kingdom_creed_id[kid]
		lang_id = _cul_lang_id[cul_id]
	else:
		cul_id = _ensure_culture_for_faction(fac)
		lang_id = _cul_lang_id[cul_id]
		creed_id = _cul_creed_id[cul_id]
	_city_culture_id[cid] = cul_id
	_city_creed_id[cid] = creed_id
	_city_lang_id[cid] = lang_id
	_city_clan_id[cid] = _kingdom_royal_clan[kid] if (kid >= 0 and kid < MAX_KINGDOMS) else -1
	_city_ferry_cd[cid] = 0.0
	_city_conquest_sec[cid] = 0.0

	_army_active[cid] = 1
	_army_kingdom_id[cid] = kid
	_army_captain_uid[cid] = -1
	_army_captain_name[cid] = ""
	_army_strength[cid] = 0
	_army_kills[cid] = 0
	_army_campaigns[cid] = 0
	_army_past_captains[cid] = PackedStringArray()

	if _hist_world_cnt[0] == 0:
		_record_history_sample(civ, 0)


func on_city_collapsed(_civ: Node2D, cid: int) -> void:
	ensure_allocated()
	if cid < 0 or cid >= MAX_CITIES:
		return
	_army_active[cid] = 0
	_army_strength[cid] = 0
	_city_culture_id[cid] = -1
	_city_creed_id[cid] = -1
	_city_lang_id[cid] = -1
	for s in range(MAX_SHIPS):
		if _ship_active[s] != 0 and _ship_city_id[s] == cid:
			_ship_active[s] = 0
			_ship_troop_count[s] = 0
			_ship_active_count = maxi(0, _ship_active_count - 1)


# --- Wars & Alliances Lifecycle ---

func get_active_war_count() -> int:
	var n: int = 0
	for w in range(MAX_WARS):
		if _war_active[w] != 0:
			n += 1
	return n


func get_active_alliance_count() -> int:
	var n: int = 0
	for a in range(MAX_ALLIANCES):
		if _ally_active[a] != 0:
			n += 1
	return n


func _find_war_between_kingdoms(ka: int, kb: int) -> int:
	if ka < 0 or kb < 0 or ka == kb:
		return -1
	for w in range(MAX_WARS):
		if _war_active[w] == 0:
			continue
		var a_att: bool = _mask_has(_war_att_mask, w, ka)
		var b_def: bool = _mask_has(_war_def_mask, w, kb)
		var b_att: bool = _mask_has(_war_att_mask, w, kb)
		var a_def: bool = _mask_has(_war_def_mask, w, ka)
		if (a_att and b_def) or (b_att and a_def):
			return w
	return -1


func on_diplomacy_changed(civ: Node2D, pair: Vector2i, st: int) -> void:
	ensure_allocated()
	var city_a: int = pair.x
	var city_b: int = pair.y
	var ka: int = civ._city_kingdom_id[city_a]
	var kb: int = civ._city_kingdom_id[city_b]
	if ka < 0 or kb < 0 or ka == kb:
		return
	if st == 2 or st == 3:
		var war_type: int = WAR_REBELLION if st == 3 else WAR_CONQUEST
		_ensure_kingdom_war(civ, ka, kb, war_type)
	elif st == 0 or st == 1:
		var w_idx: int = _find_war_between_kingdoms(ka, kb)
		if w_idx >= 0 and not _kingdoms_still_hostile(civ, ka, kb):
			_end_war_if_settled(civ, w_idx)


func _kingdoms_still_hostile(civ: Node2D, ka: int, kb: int) -> bool:
	for ca in range(civ._max_cities):
		if civ._city_active[ca] == 0 or civ._city_kingdom_id[ca] != ka:
			continue
		for cb in range(civ._max_cities):
			if civ._city_active[cb] == 0 or civ._city_kingdom_id[cb] != kb:
				continue
			if int(civ._diplo_matrix[ca * civ._max_cities + cb]) >= 2:
				return true
	return false


func _ensure_kingdom_war(civ: Node2D, ka: int, kb: int, war_type: int) -> int:
	var existing: int = _find_war_between_kingdoms(ka, kb)
	if existing >= 0:
		return existing
	var slot: int = -1
	for w in range(MAX_WARS):
		if _war_active[w] == 0:
			slot = w
			break
	if slot < 0:
		return -1
	_war_active[slot] = 1
	_war_type[slot] = war_type
	_war_main_att_kid[slot] = ka
	_war_main_def_kid[slot] = kb
	_mask_clear_all(_war_att_mask, slot)
	_mask_clear_all(_war_def_mask, slot)
	_mask_set(_war_att_mask, slot, ka)
	_mask_set(_war_def_mask, slot, kb)
	_war_start_t[slot] = civ._sim_time
	_war_duration[slot] = 0.0
	_war_att_deaths[slot] = 0
	_war_def_deaths[slot] = 0
	_war_zones_flipped[slot] = 0
	_war_score[slot] = 0.0
	var fac: int = int(civ._kingdom_faction[ka])
	_war_name[slot] = generate_onomastic_name("war", fac, _kingdom_culture_id[ka])
	if war_type == WAR_CONQUEST or war_type == WAR_REBELLION or war_type == WAR_COALITION:
		_pull_allies_into_war(civ, slot, ka, kb)
	return slot


func _pull_allies_into_war(civ: Node2D, w_idx: int, ka: int, kb: int) -> void:
	var aa: int = _kingdom_alliance_id[ka]
	var ab: int = _kingdom_alliance_id[kb]
	var pulled: bool = false
	for k in range(MAX_KINGDOMS):
		if civ._kingdom_active[k] == 0 or k == ka or k == kb:
			continue
		var ak: int = _kingdom_alliance_id[k]
		if aa >= 0 and ak == aa and not _mask_has(_war_def_mask, w_idx, k):
			_mask_set(_war_att_mask, w_idx, k)
			pulled = true
		elif ab >= 0 and ak == ab and not _mask_has(_war_att_mask, w_idx, k):
			_mask_set(_war_def_mask, w_idx, k)
			pulled = true
	if pulled and _mask_count(_war_att_mask, w_idx) + _mask_count(_war_def_mask, w_idx) >= 3:
		_war_type[w_idx] = WAR_COALITION


func _end_war_if_settled(civ: Node2D, w_idx: int) -> void:
	var atts: Array[int] = _mask_list(_war_att_mask, w_idx)
	var defs: Array[int] = _mask_list(_war_def_mask, w_idx)
	for ka in atts:
		for kb in defs:
			if civ._kingdom_active[ka] != 0 and civ._kingdom_active[kb] != 0:
				if _kingdoms_still_hostile(civ, ka, kb):
					return
	_war_active[w_idx] = 0


func end_war_with_peace(civ: Node2D, w_idx: int) -> void:
	if w_idx < 0 or w_idx >= MAX_WARS or _war_active[w_idx] == 0:
		return
	var atts: Array[int] = _mask_list(_war_att_mask, w_idx)
	var defs: Array[int] = _mask_list(_war_def_mask, w_idx)
	for ka in atts:
		for kb in defs:
			_kingdom_truce[ka * MAX_KINGDOMS + kb] = 45.0
			_kingdom_truce[kb * MAX_KINGDOMS + ka] = 45.0
			_set_kingdom_pair_diplo(civ, ka, kb, 0)
	var w_name: String = _war_name[w_idx]
	_war_active[w_idx] = 0
	var main_a: int = _war_main_att_kid[w_idx]
	var pos: Vector2 = civ._city_center[civ._kingdom_capital_cid[main_a]] if (main_a >= 0 and civ._kingdom_capital_cid[main_a] >= 0) else Vector2(320.0, 180.0)
	civ._diplomacy.push_chronicle("Мир: завершена %s" % w_name, pos, Color("#5AE88E"))


func _set_kingdom_pair_diplo(civ: Node2D, ka: int, kb: int, st: int) -> void:
	for ca in range(civ._max_cities):
		if civ._city_active[ca] == 0 or civ._city_kingdom_id[ca] != ka:
			continue
		for cb in range(civ._max_cities):
			if civ._city_active[cb] == 0 or civ._city_kingdom_id[cb] != kb:
				continue
			civ._diplomacy.apply_diplomacy_state(civ, Vector2i(ca, cb), Vector2i(st, 1))


func create_alliance(civ: Node2D, ka: int, kb: int) -> int:
	if ka < 0 or kb < 0 or ka == kb or civ._kingdom_active[ka] == 0 or civ._kingdom_active[kb] == 0:
		return -1
	if _kingdom_alliance_id[ka] >= 0 or _kingdom_alliance_id[kb] >= 0:
		return -1
	var slot: int = -1
	for a in range(MAX_ALLIANCES):
		if _ally_active[a] == 0:
			slot = a
			break
	if slot < 0:
		return -1
	_ally_active[slot] = 1
	_ally_founder_kid[slot] = ka
	_mask_clear_all(_ally_member_mask, slot)
	_mask_set(_ally_member_mask, slot, ka)
	_mask_set(_ally_member_mask, slot, kb)
	_ally_member_count[slot] = 2
	_ally_age_sec[slot] = 0.0
	var fac: int = int(civ._kingdom_faction[ka])
	_ally_name[slot] = generate_onomastic_name("alliance", fac, _kingdom_culture_id[ka])
	var mottos := ["Единая орбита", "Щит союзников", "Общий вектор", "Стальной пакт"]
	_ally_motto[slot] = mottos[_meta_rng.randi() % mottos.size()]
	_ally_color[slot] = civ._kingdom_color[ka].lerp(Color("#48E5B5"), 0.45)
	_kingdom_alliance_id[ka] = slot
	_kingdom_alliance_id[kb] = slot
	_set_kingdom_pair_diplo(civ, ka, kb, 1)
	var cap: int = civ._kingdom_capital_cid[ka]
	var pos: Vector2 = civ._city_center[cap] if cap >= 0 else Vector2(320.0, 180.0)
	civ._diplomacy.push_chronicle("Альянс: %s (%s + %s)" % [_ally_name[slot], civ._kingdom_name[ka], civ._kingdom_name[kb]], pos, _ally_color[slot])
	return slot


func join_alliance(civ: Node2D, kid: int, ally_id: int) -> bool:
	if kid < 0 or kid >= MAX_KINGDOMS or ally_id < 0 or ally_id >= MAX_ALLIANCES:
		return false
	if civ._kingdom_active[kid] == 0 or _ally_active[ally_id] == 0 or _kingdom_alliance_id[kid] >= 0:
		return false
	_mask_set(_ally_member_mask, ally_id, kid)
	_ally_member_count[ally_id] = _mask_count(_ally_member_mask, ally_id)
	_kingdom_alliance_id[kid] = ally_id
	for other in range(MAX_KINGDOMS):
		if other != kid and _mask_has(_ally_member_mask, ally_id, other) and civ._kingdom_active[other] != 0:
			_set_kingdom_pair_diplo(civ, kid, other, 1)
	return true


func leave_alliance(civ: Node2D, kid: int) -> bool:
	if kid < 0 or kid >= MAX_KINGDOMS:
		return false
	var aid: int = _kingdom_alliance_id[kid]
	if aid < 0 or aid >= MAX_ALLIANCES or _ally_active[aid] == 0:
		return false
	_mask_clear(_ally_member_mask, aid, kid)
	_kingdom_alliance_id[kid] = -1
	var rem: int = _mask_count(_ally_member_mask, aid)
	_ally_member_count[aid] = rem
	if rem < 2:
		for other in range(MAX_KINGDOMS):
			if _kingdom_alliance_id[other] == aid:
				_kingdom_alliance_id[other] = -1
		_ally_active[aid] = 0
		var l_cap: int = civ._kingdom_capital_cid[kid]
		var l_pos: Vector2 = civ._city_center[l_cap] if (l_cap >= 0 and civ._city_active[l_cap] != 0) else Vector2(320.0, 180.0)
		civ._diplomacy.push_chronicle("Распад альянса %s" % _ally_name[aid], l_pos, Color("#FFB84D"))
	return true


func on_zone_captured(civ: Node2D, prev_owner: int, new_owner: int) -> void:
	if prev_owner < 0 or new_owner < 0:
		return
	var ka: int = civ._city_kingdom_id[new_owner]
	var kb: int = civ._city_kingdom_id[prev_owner]
	var w_idx: int = _find_war_between_kingdoms(ka, kb)
	if w_idx >= 0:
		_war_zones_flipped[w_idx] += 1
		if _mask_has(_war_att_mask, w_idx, ka):
			_war_score[w_idx] += 5.0
		else:
			_war_score[w_idx] -= 5.0


func on_unit_killed(civ: Node2D, victim_cid: int, killer_cid: int) -> void:
	ensure_allocated()
	_world_deaths_total += 1
	if killer_cid >= 0 and killer_cid < MAX_CITIES and _army_active[killer_cid] != 0:
		_army_kills[killer_cid] += 1
	if victim_cid >= 0 and killer_cid >= 0 and victim_cid < MAX_CITIES and killer_cid < MAX_CITIES:
		var ka: int = civ._city_kingdom_id[killer_cid]
		var kv: int = civ._city_kingdom_id[victim_cid]
		var w_idx: int = _find_war_between_kingdoms(ka, kv)
		if w_idx >= 0:
			if _mask_has(_war_att_mask, w_idx, kv):
				_war_att_deaths[w_idx] += 1
				_war_score[w_idx] -= 1.0
			else:
				_war_def_deaths[w_idx] += 1
				_war_score[w_idx] += 1.0


func on_ruler_died(civ: Node2D, cid: int, kid: int) -> void:
	if kid < 0 or kid >= MAX_KINGDOMS or civ._kingdom_active[kid] == 0:
		return
	var cul_id: int = _kingdom_culture_id[kid]
	var succ_law: int = int(_cul_succ_law[cul_id]) if (cul_id >= 0 and cul_id < MAX_CULTURES) else SUCC_HEREDITARY
	var fac: int = int(civ._kingdom_faction[kid])
	_kingdom_king_rule_sec[kid] = 0.0
	_kingdom_king_intel[kid] = clampi(_meta_rng.randi_range(3, 10), 2, 12)
	_kingdom_king_name[kid] = generate_onomastic_name("notable", fac, _kingdom_culture_id[kid])
	if succ_law == SUCC_SHATTERED and civ._kingdom_city_count[kid] >= 3 and civ._law_rebellions:
		var cap_cid: int = civ._kingdom_capital_cid[kid]
		for oc in range(civ._max_cities):
			if oc != cap_cid and oc != cid and civ._city_active[oc] != 0 and civ._city_kingdom_id[oc] == kid:
				civ._diplomacy.trigger_city_rebellion(civ, oc, false)
				break


# --- Persistent Naval Fleet (MAX_SHIPS = 32) ---

func get_ship_count() -> int:
	return _ship_active_count


func get_city_ship_count(cid: int) -> int:
	var n: int = 0
	for s in range(MAX_SHIPS):
		if _ship_active[s] != 0 and _ship_city_id[s] == cid:
			n += 1
	return n


func _is_water_px(civ: Node2D, px: int, py: int) -> bool:
	if px < 2 or px >= civ._map_w - 2 or py < 2 or py >= civ._map_h - 2:
		return false
	if civ._world == null:
		return false
	var t: int = int(civ._world.get_tier(px, py))
	return t <= 2


func _find_water_near(civ: Node2D, origin: Vector2, min_r: float, max_r: float) -> Vector2:
	var best := Vector2(-1.0, -1.0)
	var best_d2: float = 1e18
	for ring_i in range(5):
		var r: float = lerpf(min_r, max_r, float(ring_i) / 4.0)
		for k in range(16):
			var ang: float = float(k) * (TAU / 16.0)
			var cx: int = int(round(origin.x + cos(ang) * r))
			var cy: int = int(round(origin.y + sin(ang) * r))
			if _is_water_px(civ, cx, cy):
				var p := Vector2(float(cx) + 0.5, float(cy) + 0.5)
				var d2: float = p.distance_squared_to(origin)
				if d2 < best_d2:
					best_d2 = d2
					best = p
		if best.x >= 0.0:
			return best
	return best


func _find_shore_landing_near(civ: Node2D, dst_pos: Vector2, from_water: Vector2) -> Vector2:
	var fac: int = 0
	var dir: Vector2 = (from_water - dst_pos).normalized() if from_water.distance_squared_to(dst_pos) > 4.0 else Vector2.RIGHT
	for s in range(16):
		var ang: float = dir.angle() + float(s - 8) * 0.28
		for r in [6.0, 12.0, 20.0, 28.0, 38.0]:
			var cand: Vector2 = dst_pos + Vector2(cos(ang), sin(ang)) * r
			var px: int = int(floor(cand.x))
			var py: int = int(floor(cand.y))
			if px >= 6 and px < civ._map_w - 6 and py >= 6 and py < civ._map_h - 6:
				if civ._territory.is_pixel_walkable(civ, Vector2i(px, py), fac):
					var w_check: Vector2 = _find_water_near(civ, cand, 3.0, 12.0)
					if w_check.x >= 0.0:
						return cand
	return civ._territory.find_walkable_near(civ, dst_pos, Vector2i(18, fac))


func _spawn_ship(civ: Node2D, cid: int, kind: int, water_pos: Vector2) -> int:
	if cid < 0 or cid >= MAX_CITIES or civ._city_active[cid] == 0:
		return -1
	var slot: int = -1
	for s in range(MAX_SHIPS):
		if _ship_active[s] == 0:
			slot = s
			break
	if slot < 0:
		return -1
	_ship_active[slot] = 1
	_ship_kind[slot] = kind
	_ship_state[slot] = SHIP_STATE_IDLE
	_ship_faction[slot] = civ._city_faction[cid]
	_ship_city_id[slot] = cid
	_ship_target_city[slot] = -1
	_ship_pos[slot] = water_pos
	_ship_home_pos[slot] = water_pos
	_ship_dst_pos[slot] = water_pos
	_ship_pickup_shore[slot] = civ._city_center[cid]
	_ship_dropoff_shore[slot] = civ._city_center[cid]
	var max_hp: float = 160.0 if kind == SHIP_TROOP else (120.0 if kind == SHIP_TRADER else 80.0)
	_ship_hp[slot] = max_hp
	_ship_max_hp[slot] = max_hp
	_ship_cargo[slot] = 0.0
	_ship_wait_t[slot] = 0.0
	_ship_fire_cd[slot] = 0.0
	_ship_phase[slot] = _meta_rng.randf_range(0.0, TAU)
	_ship_facing[slot] = 1.0
	_ship_troop_count[slot] = 0
	var base: int = slot * MAX_SHIP_TROOPS
	for k in range(MAX_SHIP_TROOPS):
		_ship_troop_uids[base + k] = -1
	_ship_active_count += 1
	civ._buildings_dirty = true
	return slot


func _find_city_dock_pos(civ: Node2D, cid: int) -> Vector2:
	for bi in range(civ._bld_count):
		if civ._bld_city_id[bi] == cid and int(civ._bld_type[bi]) == BLD_DOCK:
			return civ._bld_pos[bi]
	return civ._city_center[cid]


func request_troop_ferry(civ: Node2D, city_id: int, dst_pos: Vector2) -> bool:
	ensure_allocated()
	if city_id < 0 or city_id >= MAX_CITIES or civ._city_active[city_id] == 0:
		return false
	var home_anchor: Vector2 = _find_city_dock_pos(civ, city_id)
	var home_water: Vector2 = _find_water_near(civ, home_anchor, 4.0, 42.0)
	if home_water.x < 0.0:
		return false
	var drop_shore: Vector2 = _find_shore_landing_near(civ, dst_pos, home_water)
	if drop_shore.x < 0.0:
		return false
	var drop_water: Vector2 = _find_water_near(civ, drop_shore, 3.0, 26.0)
	if drop_water.x < 0.0:
		drop_water = home_water
	var pick_shore: Vector2 = civ._territory.find_walkable_near(civ, home_water, Vector2i(16, int(civ._city_faction[city_id])))
	if pick_shore.x < 0.0:
		pick_shore = home_anchor

	var ship_idx: int = -1
	for s in range(MAX_SHIPS):
		if _ship_active[s] != 0 and _ship_city_id[s] == city_id and int(_ship_kind[s]) == SHIP_TROOP:
			if int(_ship_state[s]) == SHIP_STATE_IDLE:
				ship_idx = s
				break
	if ship_idx < 0:
		ship_idx = _spawn_ship(civ, city_id, SHIP_TROOP, home_water)
	if ship_idx < 0:
		return false

	_ship_state[ship_idx] = SHIP_STATE_LOADING
	_ship_home_pos[ship_idx] = home_water
	_ship_dst_pos[ship_idx] = drop_water
	_ship_pickup_shore[ship_idx] = pick_shore
	_ship_dropoff_shore[ship_idx] = drop_shore
	_ship_wait_t[ship_idx] = 0.0
	_ship_troop_count[ship_idx] = 0
	return true


func _steer_ship_water(civ: Node2D, s: int, goal: Vector2, speed: float, pace_dt: float) -> float:
	var pos: Vector2 = _ship_pos[s]
	var delta: Vector2 = goal - pos
	var dist: float = delta.length()
	if dist <= 3.0:
		return dist
	var base_ang: float = delta.angle()
	var step_len: float = minf(dist, minf(speed * pace_dt, 20.0))
	var probe_len: float = maxf(step_len + 1.5, 4.0)
	var chosen_dir: Vector2 = Vector2.ZERO
	for off_deg in [0.0, 35.0, -35.0, 72.0, -72.0, 115.0, -115.0]:
		var ang: float = base_ang + deg_to_rad(off_deg)
		var test_p: Vector2 = pos + Vector2(cos(ang), sin(ang)) * probe_len
		if _is_water_px(civ, int(round(test_p.x)), int(round(test_p.y))):
			chosen_dir = Vector2(cos(ang), sin(ang))
			break
	if chosen_dir == Vector2.ZERO:
		_ship_wait_t[s] += pace_dt
		return dist
	_ship_pos[s] = pos + chosen_dir * step_len
	if absf(chosen_dir.x) > 0.08:
		_ship_facing[s] = 1.0 if chosen_dir.x >= 0.0 else -1.0
	return _ship_pos[s].distance_to(goal)


func _board_troops_onto_ship(civ: Node2D, s: int) -> int:
	var phys: Node2D = civ._physics
	if phys == null or phys._unit_count <= 0:
		return 0
	var cid: int = _ship_city_id[s]
	var shore: Vector2 = _ship_pickup_shore[s]
	var cur_n: int = _ship_troop_count[s]
	var base: int = s * MAX_SHIP_TROOPS
	var boarded_now: int = 0
	for u in range(phys._unit_count):
		if cur_n >= MAX_SHIP_TROOPS:
			break
		if phys._hp[u] <= 0.0 or phys._u_city_id[u] != cid:
			continue
		if int(phys._u_role[u]) != 4 and (u >= phys._u_in_regiment.size() or phys._u_in_regiment[u] == 0):
			continue
		var uid: int = phys._u_uid[u]
		if _is_uid_embarked(s, uid, cur_n):
			continue
		var d2: float = Vector2(phys._px[u], phys._py[u]).distance_squared_to(shore)
		if d2 <= 38.0 * 38.0 or boarded_now < 4:
			_ship_troop_uids[base + cur_n] = uid
			cur_n += 1
			boarded_now += 1
			phys._px[u] = shore.x
			phys._py[u] = shore.y
			phys._vx[u] = 0.0
			phys._vy[u] = 0.0
			if u < phys._u_invuln_timer.size():
				phys._u_invuln_timer[u] = maxf(phys._u_invuln_timer[u], 1.0)
	_ship_troop_count[s] = cur_n
	return cur_n


func _is_uid_embarked(s: int, uid: int, cur_n: int) -> bool:
	var base: int = s * MAX_SHIP_TROOPS
	for k in range(cur_n):
		if _ship_troop_uids[base + k] == uid:
			return true
	return false


func _hold_embarked_units(civ: Node2D, s: int) -> void:
	var phys: Node2D = civ._physics
	if phys == null or _ship_troop_count[s] <= 0:
		return
	var uid_map_v: Variant = phys.get("_uid_to_idx")
	if not (uid_map_v is Dictionary):
		return
	var uid_map := uid_map_v as Dictionary
	var shore: Vector2 = _ship_pickup_shore[s]
	var base: int = s * MAX_SHIP_TROOPS
	for k in range(_ship_troop_count[s]):
		var uid: int = _ship_troop_uids[base + k]
		if uid_map.has(uid):
			var u: int = int(uid_map[uid])
			if u >= 0 and u < phys._unit_count:
				phys._px[u] = shore.x
				phys._py[u] = shore.y
				phys._vx[u] = 0.0
				phys._vy[u] = 0.0
				if u < phys._u_invuln_timer.size():
					phys._u_invuln_timer[u] = maxf(phys._u_invuln_timer[u], 0.4)


func _disembark_ship_troops(civ: Node2D, s: int, use_home: bool = false) -> void:
	var phys: Node2D = civ._physics
	var cnt: int = _ship_troop_count[s]
	if phys == null or cnt <= 0:
		_ship_troop_count[s] = 0
		return
	var uid_map_v: Variant = phys.get("_uid_to_idx")
	if not (uid_map_v is Dictionary):
		_ship_troop_count[s] = 0
		return
	var uid_map := uid_map_v as Dictionary
	var shore: Vector2 = _ship_pickup_shore[s] if use_home else _ship_dropoff_shore[s]
	var fac: int = int(_ship_faction[s])
	var vel_z_v: Variant = phys.get("_u_vel_z")
	var base: int = s * MAX_SHIP_TROOPS
	for k in range(cnt):
		var uid: int = _ship_troop_uids[base + k]
		_ship_troop_uids[base + k] = -1
		if not uid_map.has(uid):
			continue
		var u: int = int(uid_map[uid])
		if u < 0 or u >= phys._unit_count or phys._hp[u] <= 0.0:
			continue
		var ang: float = float(k) * (TAU / float(maxi(1, cnt)))
		var off := Vector2(cos(ang), sin(ang)) * 4.0
		var spot: Vector2 = civ._territory.find_walkable_near(civ, shore + off, Vector2i(14, fac))
		if spot.x < 0.0:
			spot = shore
		phys._px[u] = spot.x
		phys._py[u] = spot.y
		phys._u_target_pos[u] = _ship_dropoff_shore[s]
		if vel_z_v is PackedFloat32Array:
			var vz := vel_z_v as PackedFloat32Array
			if u < vz.size():
				vz[u] = 16.0
	_ship_troop_count[s] = 0
	if civ._fx != null and civ._fx_has_spawn_burst:
		civ._fx.spawn_burst(shore, 8, Color(0.55, 0.92, 1.0, 0.9), 20.0, 0.4, 8.0)


func _step_fleet(civ: Node2D, safe_dt: float, pace_dt: float) -> void:
	_fleet_ai_raw_cd = maxf(0.0, _fleet_ai_raw_cd - safe_dt)
	_fleet_ai_pace_acc += pace_dt
	var run_ai: bool = (_fleet_ai_pace_acc >= 1.2 and _fleet_ai_raw_cd <= 0.0)
	if run_ai:
		_fleet_ai_raw_cd = 0.70 if civ._sim_pace_mult >= 10.0 else 0.10
		_fleet_ai_pace_acc = 0.0
		_spawn_city_fleet_and_auto_ferries(civ)

	if _ship_active_count <= 0:
		return
	_fleet_step_idx += 1
	var hi_pace: bool = civ._sim_pace_mult >= 10.0
	var active_cnt: int = 0
	for s in range(MAX_SHIPS):
		if _ship_active[s] == 0:
			continue
		var cid: int = _ship_city_id[s]
		if cid < 0 or cid >= MAX_CITIES or civ._city_active[cid] == 0 or _ship_hp[s] <= 0.0:
			_disembark_ship_troops(civ, s, true)
			_ship_active[s] = 0
			continue
		active_cnt += 1
		if not hi_pace or ((s + _fleet_step_idx) & 3) == 0:
			_step_single_ship(civ, s, pace_dt * 4.0 if hi_pace else pace_dt)
	_ship_active_count = active_cnt


func _spawn_city_fleet_and_auto_ferries(civ: Node2D) -> void:
	var orders_loaded: bool = false
	var orders: Dictionary = {}
	for cid in range(civ._max_cities):
		if civ._city_active[cid] == 0:
			continue
		if _city_ferry_cd[cid] > 0.0:
			_city_ferry_cd[cid] = maxf(0.0, _city_ferry_cd[cid] - 1.2)
		var base_b: int = cid * civ.BLD_TYPE_COUNT
		var docks: int = civ._city_bld_counts[base_b + BLD_DOCK]
		var tier: int = int(civ._city_tech_tier[cid])
		var target_ships: int = mini(4, docks * 2 + (1 if (docks > 0 or (tier >= 1 and civ._is_city_coastal(cid))) else 0))
		if target_ships > 0 and get_city_ship_count(cid) < target_ships and _ship_active_count < MAX_SHIPS:
			var anchor: Vector2 = _find_city_dock_pos(civ, cid)
			var wpos: Vector2 = _find_water_near(civ, anchor, 4.0, 38.0)
			if wpos.x >= 0.0:
				var cur_n: int = get_city_ship_count(cid)
				var kind: int = SHIP_FISHING if cur_n == 0 else (SHIP_TRADER if (cur_n == 1 or docks == 0) else SHIP_TROOP)
				_spawn_ship(civ, cid, kind, wpos)
		if int(civ._city_war_state[cid]) >= 2 and _city_ferry_cd[cid] <= 0.0:
			if not orders_loaded:
				orders_loaded = true
				orders = civ._diplomacy.get_army_orders(civ)
			_check_city_auto_ferry(civ, cid, orders)


func _check_city_auto_ferry(civ: Node2D, cid: int, orders: Dictionary) -> void:
	var has_gate: bool = civ._city_bld_counts[cid * civ.BLD_TYPE_COUNT + 9] > 0 and civ._city_energy[cid] >= 2.0 and civ._city_emp_timer[cid] <= 0.0
	if has_gate:
		return
	if not orders.has(cid):
		return
	var ord: Dictionary = orders[cid]
	var tgt_pos: Vector2 = Vector2(ord.get("target_pos", civ._city_center[cid]))
	if civ._diplomacy._count_water_hops(civ, civ._city_center[cid], tgt_pos) >= 2:
		if request_troop_ferry(civ, cid, tgt_pos):
			_city_ferry_cd[cid] = 9.0


func _step_single_ship(civ: Node2D, s: int, pace_dt: float) -> void:
	var kind: int = int(_ship_kind[s])
	var st: int = int(_ship_state[s])
	var cid: int = _ship_city_id[s]
	if _ship_fire_cd[s] > 0.0:
		_ship_fire_cd[s] = maxf(0.0, _ship_fire_cd[s] - pace_dt)
	else:
		_fire_ship_board_laser(civ, s, kind)

	if kind == SHIP_FISHING:
		_step_fishing_ship(civ, s, cid, st, pace_dt)
	elif kind == SHIP_TRADER:
		_step_trader_ship(civ, s, cid, st, pace_dt)
	else:
		_step_troop_ship(civ, s, st, pace_dt)


func _step_fishing_ship(civ: Node2D, s: int, cid: int, st: int, pace_dt: float) -> void:
	if st == SHIP_STATE_IDLE:
		var ang: float = _meta_rng.randf_range(0.0, TAU)
		var cand: Vector2 = _ship_home_pos[s] + Vector2(cos(ang), sin(ang)) * _meta_rng.randf_range(18.0, 56.0)
		var wp: Vector2 = _find_water_near(civ, cand, 0.0, 20.0)
		_ship_dst_pos[s] = wp if wp.x >= 0.0 else _ship_home_pos[s]
		_ship_state[s] = SHIP_STATE_SAIL_OUT
		_ship_wait_t[s] = 0.0
	elif st == SHIP_STATE_SAIL_OUT:
		var d: float = _steer_ship_water(civ, s, _ship_dst_pos[s], 16.0, pace_dt)
		_ship_cargo[s] += pace_dt * 0.65
		if d <= 5.0 or _ship_wait_t[s] >= 8.0:
			_ship_state[s] = SHIP_STATE_RETURN
			_ship_wait_t[s] = 0.0
	else:
		var d_h: float = _steer_ship_water(civ, s, _ship_home_pos[s], 18.0, pace_dt)
		if d_h <= 5.0 or _ship_wait_t[s] >= 10.0:
			civ._city_food[cid] = minf(civ._city_storage_cap[cid], civ._city_food[cid] + clampf(_ship_cargo[s], 2.0, 7.0))
			civ._city_credits[cid] += 1.5
			_ship_cargo[s] = 0.0
			_ship_state[s] = SHIP_STATE_IDLE


func _step_trader_ship(civ: Node2D, s: int, cid: int, st: int, pace_dt: float) -> void:
	if st == SHIP_STATE_IDLE:
		var dst_cid: int = _pick_trade_partner(civ, cid)
		if dst_cid < 0:
			_ship_wait_t[s] += pace_dt
			return
		var dw: Vector2 = _find_water_near(civ, _find_city_dock_pos(civ, dst_cid), 4.0, 42.0)
		if dw.x < 0.0:
			return
		_ship_target_city[s] = dst_cid
		_ship_dst_pos[s] = dw
		_ship_state[s] = SHIP_STATE_SAIL_OUT
		_ship_wait_t[s] = 0.0
	elif st == SHIP_STATE_SAIL_OUT:
		var d: float = _steer_ship_water(civ, s, _ship_dst_pos[s], 22.0, pace_dt)
		if d <= 6.0 or _ship_wait_t[s] >= 14.0:
			var tcid: int = _ship_target_city[s]
			if tcid >= 0 and tcid < MAX_CITIES and civ._city_active[tcid] != 0:
				var bonus: float = 12.0 if civ._city_bld_counts[tcid * civ.BLD_TYPE_COUNT + BLD_TRADE_HUB] > 0 else 8.0
				civ._city_credits[tcid] += bonus
				civ._city_credits[cid] += bonus
				civ._add_city_science(cid, 1.5)
			_ship_state[s] = SHIP_STATE_RETURN
			_ship_wait_t[s] = 0.0
	else:
		var d_h: float = _steer_ship_water(civ, s, _ship_home_pos[s], 22.0, pace_dt)
		if d_h <= 6.0 or _ship_wait_t[s] >= 14.0:
			_ship_state[s] = SHIP_STATE_IDLE
			_ship_target_city[s] = -1


func _pick_trade_partner(civ: Node2D, src_cid: int) -> int:
	var best_cid: int = -1
	var best_sc: float = -1e9
	for other in range(civ._max_cities):
		if other == src_cid or civ._city_active[other] == 0:
			continue
		if civ._are_cities_hostile(src_cid, other):
			continue
		if not civ._is_city_coastal(other):
			continue
		var sc: float = 20.0 if civ._city_kingdom_id[other] != civ._city_kingdom_id[src_cid] else 8.0
		if civ._city_bld_counts[other * civ.BLD_TYPE_COUNT + BLD_TRADE_HUB] > 0:
			sc += 18.0
		sc += _meta_rng.randf_range(0.0, 6.0)
		if sc > best_sc:
			best_sc = sc
			best_cid = other
	return best_cid


func _step_troop_ship(civ: Node2D, s: int, st: int, pace_dt: float) -> void:
	if st == SHIP_STATE_IDLE:
		return
	if st == SHIP_STATE_LOADING:
		_steer_ship_water(civ, s, _ship_home_pos[s], 22.0, pace_dt)
		_ship_wait_t[s] += pace_dt
		var cnt: int = _board_troops_onto_ship(civ, s)
		if cnt >= 6 or (cnt >= 1 and _ship_wait_t[s] >= 2.2):
			_ship_state[s] = SHIP_STATE_MISSION
			_ship_wait_t[s] = 0.0
		elif _ship_wait_t[s] >= 8.0:
			_disembark_ship_troops(civ, s, true)
			_ship_state[s] = SHIP_STATE_IDLE
	elif st == SHIP_STATE_MISSION:
		_hold_embarked_units(civ, s)
		var d: float = _steer_ship_water(civ, s, _ship_dst_pos[s], 24.0, pace_dt)
		if d <= 7.0 or _ship_wait_t[s] >= 12.0:
			_disembark_ship_troops(civ, s, false)
			_ship_state[s] = SHIP_STATE_RETURN
			_ship_wait_t[s] = 0.0
	else:
		var d_h: float = _steer_ship_water(civ, s, _ship_home_pos[s], 22.0, pace_dt)
		if d_h <= 6.0 or _ship_wait_t[s] >= 12.0:
			_ship_state[s] = SHIP_STATE_IDLE


func _fire_ship_board_laser(civ: Node2D, s: int, kind: int) -> void:
	var cid: int = _ship_city_id[s]
	if cid < 0 or cid >= MAX_CITIES:
		_ship_fire_cd[s] = 1.6
		return
	var war_on: bool = int(civ._city_war_state[cid]) >= 2
	_ship_fire_cd[s] = (0.90 if kind == SHIP_TROOP else 1.25) if war_on else 1.85
	var pos: Vector2 = _ship_pos[s]
	var rng: float = 40.0 if kind == SHIP_TROOP else 30.0
	var r2: float = rng * rng
	if war_on:
		for os in range(MAX_SHIPS):
			if os != s and _ship_active[os] != 0 and civ._are_cities_hostile(cid, _ship_city_id[os]):
				if pos.distance_squared_to(_ship_pos[os]) <= r2:
					_ship_fire_cd[s] = 1.25
					_ship_hp[os] -= 16.0 if kind == SHIP_TROOP else 9.0
					if civ._fx != null and civ._fx.has_method("emit_laser_tracer"):
						civ._fx.emit_laser_tracer(pos, _ship_pos[os], civ._get_city_border_color(cid))
					return
	var phys: Node2D = civ._physics
	if phys == null or phys._unit_count <= 0 or not phys.has_method("apply_external_damage"):
		return
	var best_u: int = _find_nearest_hostile_unit(civ, cid, pos, r2)
	if best_u >= 0:
		_ship_fire_cd[s] = 1.35 if kind == SHIP_TROOP else 1.85
		var tpos := Vector2(phys._px[best_u], phys._py[best_u])
		var dmg: float = 15.0 if kind == SHIP_TROOP else 9.0
		phys.apply_external_damage(tpos, 8.0, {"damage": dmg, "impulse": 22.0, "unit_idx": best_u, "friendly_city": cid})
		if civ._fx != null and civ._fx.has_method("emit_laser_tracer"):
			civ._fx.emit_laser_tracer(pos, tpos, civ._get_city_border_color(cid))


func _find_nearest_hostile_unit(civ: Node2D, friendly_cid: int, pos: Vector2, max_r2: float) -> int:
	var phys: Node2D = civ._physics
	if phys == null:
		return -1
	var u_cnt: int = int(phys._unit_count)
	if u_cnt <= 0:
		return -1
	var u_hp: PackedFloat32Array = phys._hp
	var u_cid_arr: PackedInt32Array = phys._u_city_id
	var u_role_arr: PackedByteArray = phys._u_role
	var u_px: PackedFloat32Array = phys._px
	var u_py: PackedFloat32Array = phys._py
	var d_mat: PackedByteArray = civ._diplo_matrix
	var row_off: int = friendly_cid * civ._max_cities
	var war_on: bool = friendly_cid >= 0 and friendly_cid < MAX_CITIES and int(civ._city_war_state[friendly_cid]) >= 2
	var px0: float = pos.x
	var py0: float = pos.y
	var best_u: int = -1
	var best_d2: float = max_r2
	for u in range(u_cnt):
		if u_hp[u] <= 0.0:
			continue
		var is_mut: bool = int(u_role_arr[u]) == 5
		if not is_mut:
			if not war_on:
				continue
			var u_cid: int = u_cid_arr[u]
			if u_cid < 0 or u_cid == friendly_cid or int(d_mat[row_off + u_cid]) < 2:
				continue
		var dx: float = u_px[u] - px0
		var dy: float = u_py[u] - py0
		var d2: float = dx * dx + dy * dy
		if d2 < best_d2:
			best_d2 = d2
			best_u = u
	return best_u


# --- Defense Turrets & Step Loop ---

func _step_defense_turrets(civ: Node2D, safe_dt: float, pace_dt: float) -> void:
	_turret_raw_cd = maxf(0.0, _turret_raw_cd - safe_dt)
	_turret_pace_acc += pace_dt
	if _turret_pace_acc < 1.35 or _turret_raw_cd > 0.0:
		return
	_turret_raw_cd = 0.45 if civ._sim_pace_mult >= 10.0 else 0.12
	_turret_pace_acc = 0.0
	var any_turret: bool = false
	var bcnt: int = civ.BLD_TYPE_COUNT
	for cid in range(civ._max_cities):
		if civ._city_active[cid] != 0 and civ._city_bld_counts[cid * bcnt + BLD_DEFENSE_TURRET] > 0:
			any_turret = true
			break
	if not any_turret:
		return
	var phys: Node2D = civ._physics
	if phys == null or phys._unit_count <= 0 or not phys.has_method("apply_external_damage"):
		return
	var r2: float = 46.0 * 46.0
	var shots: int = 0
	for bi in range(civ._bld_count):
		if int(civ._bld_type[bi]) != BLD_DEFENSE_TURRET or civ._bld_hp[bi] <= 0.0:
			continue
		var cid: int = civ._bld_city_id[bi]
		if cid < 0 or cid >= MAX_CITIES or civ._city_active[cid] == 0 or civ._city_emp_timer[cid] > 0.0:
			continue
		var pos: Vector2 = civ._bld_pos[bi] + Vector2(0.0, -4.0)
		var best_u: int = _find_nearest_hostile_unit(civ, cid, pos, r2)
		if best_u >= 0:
			var tpos := Vector2(phys._px[best_u], phys._py[best_u])
			var dmg: float = 20.0 + float(civ._city_tech_tier[cid]) * 3.0
			phys.apply_external_damage(tpos, 8.0, {"damage": dmg, "impulse": 26.0, "unit_idx": best_u, "friendly_city": cid})
			if civ._fx != null and civ._fx.has_method("emit_laser_tracer"):
				civ._fx.emit_laser_tracer(pos, tpos, civ._get_city_border_color(cid))
			shots += 1
			if shots >= 6:
				break


func has_defense_turret_near_zone(civ: Node2D, zpt: Vector2i, owner_cid: int) -> bool:
	var zx: int = zpt.x
	var zy: int = zpt.y
	var base_b: int = owner_cid * civ.BLD_TYPE_COUNT
	if civ._city_bld_counts[base_b + BLD_DEFENSE_TURRET] <= 0:
		return false
	var zc := Vector2((float(zx) + 0.5) * float(civ._zone_px), (float(zy) + 0.5) * float(civ._zone_px))
	for bi in range(civ._bld_count):
		if civ._bld_city_id[bi] == owner_cid and int(civ._bld_type[bi]) == BLD_DEFENSE_TURRET and civ._bld_hp[bi] > 0.0:
			if civ._bld_pos[bi].distance_squared_to(zc) <= 40.0 * 40.0:
				return true
	return false


func step_meta_and_fleet(civ: Node2D, safe_dt: float, pace_dt: float) -> void:
	ensure_allocated()
	_step_fleet(civ, safe_dt, pace_dt)
	_step_defense_turrets(civ, safe_dt, pace_dt)
	_step_noosphere_and_politics(civ, safe_dt, pace_dt)
	_step_history_sampling(civ, safe_dt, pace_dt)


func _step_noosphere_and_politics(civ: Node2D, safe_dt: float, pace_dt: float) -> void:
	_meta_raw_cd = maxf(0.0, _meta_raw_cd - safe_dt)
	_meta_pace_acc += pace_dt
	if _meta_pace_acc < 1.25 or _meta_raw_cd > 0.0:
		return
	var dt_step: float = _meta_pace_acc
	_meta_raw_cd = 0.90 if civ._sim_pace_mult >= 10.0 else 0.15
	_meta_pace_acc = 0.0

	for k in range(MAX_KINGDOMS):
		if civ._kingdom_active[k] != 0:
			_kingdom_king_rule_sec[k] += dt_step
	for w in range(MAX_WARS):
		if _war_active[w] != 0:
			_war_duration[w] += dt_step
	for a in range(MAX_ALLIANCES):
		if _ally_active[a] != 0:
			_ally_age_sec[a] += dt_step
	for i in range(MAX_KINGDOMS * MAX_KINGDOMS):
		if _kingdom_truce[i] > 0.0:
			_kingdom_truce[i] = maxf(0.0, _kingdom_truce[i] - dt_step)

	_sync_all_armies_single_pass(civ)
	var slice_sz: int = 8
	for _s in range(slice_sz):
		var cid: int = _meta_city_cursor % MAX_CITIES
		_meta_city_cursor = (_meta_city_cursor + 1) % MAX_CITIES
		if civ._city_active[cid] != 0:
			_step_city_meta_slice(civ, cid, dt_step * 8.0)

	_consider_meta_plots(civ)


func _step_city_meta_slice(civ: Node2D, cid: int, slice_dt: float) -> void:
	var base_b: int = cid * civ.BLD_TYPE_COUNT
	var cul_id: int = _city_culture_id[cid]
	if cul_id >= 0 and cul_id < MAX_CULTURES and _cul_active[cul_id] != 0:
		var archives: int = civ._city_bld_counts[base_b + BLD_ARCHIVE]
		var xp_gain: float = (0.35 + float(archives) * 0.85) * minf(slice_dt, 8.0)
		_cul_xp[cul_id] += xp_gain
		if _cul_level[cul_id] < 5 and _cul_xp[cul_id] >= float(_cul_level[cul_id]) * 120.0:
			_cul_level[cul_id] += 1
	var trade_hubs: int = civ._city_bld_counts[base_b + BLD_TRADE_HUB]
	if trade_hubs > 0:
		civ._city_credits[cid] += (0.25 * float(trade_hubs) + float(civ._city_pop[cid]) * 0.02) * minf(slice_dt, 8.0)
	_try_upgrade_city_hq(civ, cid)


func _sync_all_armies_single_pass(civ: Node2D) -> void:
	var phys: Node2D = civ._physics
	if phys == null:
		return
	var u_cnt: int = int(phys._unit_count)
	_tmp_a_sol.fill(0)
	_tmp_a_best_u.fill(-1)
	_tmp_a_best_sc.fill(-1)
	_tmp_a_cap_alive.fill(0)
	if u_cnt > 0:
		var u_hp: PackedFloat32Array = phys._hp
		var u_cid_arr: PackedInt32Array = phys._u_city_id
		var u_role_arr: PackedByteArray = phys._u_role
		var u_reg_arr: PackedByteArray = phys._u_in_regiment
		var u_kills_arr: PackedInt32Array = phys._u_kills
		var u_uid_arr: PackedInt32Array = phys._u_uid
		var has_reg: bool = u_reg_arr.size() >= u_cnt
		for u in range(u_cnt):
			if u_hp[u] <= 0.0:
				continue
			var cid: int = u_cid_arr[u]
			if cid < 0 or cid >= MAX_CITIES:
				continue
			var is_sol: bool = int(u_role_arr[u]) == 4
			var in_reg: bool = has_reg and u_reg_arr[u] != 0
			if not is_sol and not in_reg:
				continue
			_tmp_a_sol[cid] += 1
			var cap_uid: int = _army_captain_uid[cid]
			var uid: int = u_uid_arr[u]
			if uid == cap_uid:
				_tmp_a_cap_alive[cid] = 1
			var sc: int = u_kills_arr[u] * 3 + (4 if is_sol else 0) + (2 if uid == cap_uid else 0)
			if sc > _tmp_a_best_sc[cid]:
				_tmp_a_best_sc[cid] = sc
				_tmp_a_best_u[cid] = u
	var uid_ref: PackedInt32Array = phys._u_uid if u_cnt > 0 else PackedInt32Array()
	for cid in range(civ._max_cities):
		if civ._city_active[cid] == 0:
			continue
		_army_active[cid] = 1
		_army_kingdom_id[cid] = civ._city_kingdom_id[cid]
		_army_strength[cid] = _tmp_a_sol[cid]
		var cap_uid: int = _army_captain_uid[cid]
		var alive: bool = _tmp_a_cap_alive[cid] != 0
		if not alive and cap_uid > 0 and _army_captain_name[cid] != "":
			_push_past_captain(cid, _army_captain_name[cid])
			_army_captain_uid[cid] = -1
			_army_captain_name[cid] = ""
		var best_u: int = _tmp_a_best_u[cid]
		if best_u >= 0 and (_army_captain_uid[cid] <= 0 or not alive):
			var new_uid: int = uid_ref[best_u]
			_army_captain_uid[cid] = new_uid
			var card: Dictionary = civ._diplomacy.get_notable_card(new_uid)
			_army_captain_name[cid] = str(card.get("name", "")) if bool(card.get("found", false)) else generate_onomastic_name("notable", int(civ._city_faction[cid]), _city_lang_id[cid])


func _push_past_captain(cid: int, cap_name: String) -> void:
	var arr: PackedStringArray = _army_past_captains[cid]
	arr.append(cap_name)
	if arr.size() > MAX_PAST_CAPTAINS:
		var trimmed := PackedStringArray()
		for i in range(arr.size() - MAX_PAST_CAPTAINS, arr.size()):
			trimmed.append(arr[i])
		arr = trimmed
	_army_past_captains[cid] = arr


func _try_upgrade_city_hq(civ: Node2D, cid: int) -> void:
	var tier: int = int(civ._city_tech_tier[cid])
	var target_lvl: int = 2 if (tier >= 3 and civ._city_pop[cid] >= 12) else (1 if tier >= 2 else 0)
	if target_lvl <= 0 or int(civ._city_hq_level[cid]) >= target_lvl:
		return
	for bi in range(civ._bld_count):
		if civ._bld_city_id[bi] == cid and int(civ._bld_type[bi]) == BLD_CAMPFIRE:
			if int(civ._bld_level[bi]) < target_lvl:
				civ._bld_level[bi] = target_lvl
				civ._city_hq_level[cid] = maxi(int(civ._city_hq_level[cid]), target_lvl)
				civ._bld_hp[bi] = civ._building_max_hp(BLD_CAMPFIRE, int(civ._city_faction[cid]), target_lvl)
				civ._city_storage_cap[cid] += 60.0 * float(target_lvl)
				civ._bld_spring[bi] = 1.24
				civ._has_bld_springs = true
				civ._spring_cache_dirty = true
				civ._buildings_dirty = true
				if target_lvl >= 2:
					civ._diplomacy.push_chronicle("%s возводит Штаб L2" % civ._city_name[cid], civ._bld_pos[bi], civ._get_city_border_color(cid))
			break


# --- Extended Plots (3..11) & Intelligence Speed ---

func get_plot_speed_mult(civ: Node2D, src_cid: int) -> float:
	if src_cid < 0 or src_cid >= MAX_CITIES:
		return 1.0
	var kid: int = civ._city_kingdom_id[src_cid]
	var intel: int = _kingdom_king_intel[kid] if (kid >= 0 and kid < MAX_KINGDOMS) else 4
	var archives: int = civ._city_bld_counts[src_cid * civ.BLD_TYPE_COUNT + BLD_ARCHIVE]
	return 1.0 + float(intel + archives) * 0.09


func _consider_meta_plots(civ: Node2D) -> void:
	if civ._diplomacy.get_active_plot_count() >= 6:
		return
	var roll: float = _meta_rng.randf()
	if roll < 0.25:
		_try_auto_peace_plot(civ)
	elif roll < 0.50:
		_try_auto_alliance_plot(civ)
	elif roll < 0.72:
		_try_auto_codex_plot(civ)
	elif roll < 0.88:
		_try_auto_schism_or_rite_plot(civ)


func _try_auto_peace_plot(civ: Node2D) -> void:
	if not civ.is_law_enabled("peace_treaties"):
		return
	for w in range(MAX_WARS):
		if _war_active[w] != 0 and _war_duration[w] >= 40.0 and int(_war_type[w]) != WAR_SPITE:
			var ka: int = _war_main_att_kid[w]
			var kb: int = _war_main_def_kid[w]
			var ca: int = civ._kingdom_capital_cid[ka] if (ka >= 0 and ka < MAX_KINGDOMS) else -1
			var cb: int = civ._kingdom_capital_cid[kb] if (kb >= 0 and kb < MAX_KINGDOMS) else -1
			if ca >= 0 and cb >= 0 and not civ._diplomacy.has_plot_for(ca, cb, PLOT_PEACE):
				civ._diplomacy.start_plot(civ, PLOT_PEACE, Vector2i(ca, cb))
				return


func _try_auto_alliance_plot(civ: Node2D) -> void:
	if not civ.is_law_enabled("alliances"):
		return
	for ka in range(MAX_KINGDOMS):
		if civ._kingdom_active[ka] == 0 or _kingdom_alliance_id[ka] >= 0:
			continue
		var ca: int = civ._kingdom_capital_cid[ka]
		if ca < 0 or civ._city_war_state[ca] >= 2:
			continue
		for kb in range(ka + 1, MAX_KINGDOMS):
			if civ._kingdom_active[kb] == 0:
				continue
			var cb: int = civ._kingdom_capital_cid[kb]
			if cb < 0 or civ._city_war_state[cb] >= 2:
				continue
			if int(civ._diplo_matrix[ca * civ._max_cities + cb]) == 1:
				var aid_b: int = _kingdom_alliance_id[kb]
				var kind: int = PLOT_ALLIANCE_JOIN if aid_b >= 0 else PLOT_ALLIANCE_FORM
				if not civ._diplomacy.has_plot_for(ca, cb, kind):
					civ._diplomacy.start_plot(civ, kind, Vector2i(ca, cb))
					return


func _try_auto_codex_plot(civ: Node2D) -> void:
	for cid in range(civ._max_cities):
		if civ._city_active[cid] == 0:
			continue
		var has_lib: bool = civ._city_bld_counts[cid * civ.BLD_TYPE_COUNT + BLD_ARCHIVE] > 0 or int(civ._city_hq_level[cid]) >= 2
		if has_lib and int(civ._city_tech_tier[cid]) >= 2 and not civ._diplomacy.has_plot_for(cid, -1, PLOT_CODEX):
			if _meta_rng.randf() < 0.25:
				civ._diplomacy.start_plot(civ, PLOT_CODEX, Vector2i(cid, -1))
				return


func _try_auto_schism_or_rite_plot(civ: Node2D) -> void:
	for cid in range(civ._max_cities):
		if civ._city_active[cid] == 0 or int(civ._city_tech_tier[cid]) < 2:
			continue
		if civ._city_loyalty[cid] < 55.0 and not civ._diplomacy.has_plot_for(cid, -1, PLOT_SCHISM):
			civ._diplomacy.start_plot(civ, PLOT_SCHISM, Vector2i(cid, -1))
			return
		if civ._city_bld_counts[cid * civ.BLD_TYPE_COUNT + BLD_MONOLITH] > 0 and not civ._diplomacy.has_plot_for(cid, -1, PLOT_ASCEND_MONOLITH):
			civ._diplomacy.start_plot(civ, PLOT_ASCEND_MONOLITH, Vector2i(cid, -1))
			return


func resolve_extended_plot(civ: Node2D, kind: int, pair: Vector2i) -> void:
	var src: int = pair.x
	var dst: int = pair.y
	var pos: Vector2 = civ._city_center[src] if (src >= 0 and src < MAX_CITIES) else Vector2(320.0, 180.0)
	var ka: int = civ._city_kingdom_id[src] if (src >= 0 and src < MAX_CITIES) else -1
	var kb: int = civ._city_kingdom_id[dst] if (dst >= 0 and dst < MAX_CITIES) else -1
	match kind:
		PLOT_PEACE:
			var w_idx: int = _find_war_between_kingdoms(ka, kb)
			if w_idx >= 0:
				end_war_with_peace(civ, w_idx)
			elif src >= 0 and dst >= 0:
				civ._diplomacy.apply_diplomacy_state(civ, Vector2i(src, dst), Vector2i(0, 1))
				civ._diplomacy.push_chronicle("Мир: %s и %s" % [civ._city_name[src], civ._city_name[dst]], pos, Color("#5AE88E"))
		PLOT_ALLIANCE_FORM:
			create_alliance(civ, ka, kb)
		PLOT_ALLIANCE_JOIN:
			if kb >= 0 and _kingdom_alliance_id[kb] >= 0:
				join_alliance(civ, ka, _kingdom_alliance_id[kb])
				civ._diplomacy.push_chronicle("%s вступил в альянс" % civ._kingdom_name[ka], pos, Color("#48E5B5"))
		PLOT_ALLIANCE_BREAK:
			leave_alliance(civ, ka)
		PLOT_SCHISM:
			_resolve_schism_plot(civ, src, pos)
		PLOT_CODEX:
			_resolve_codex_plot(civ, src, pos)
		PLOT_ORBITAL_SHIELD:
			for bi in range(civ._bld_count):
				if civ._bld_city_id[bi] == src and int(civ._bld_type[bi]) == 8:
					civ._bld_shield_charge[bi] = 1.0
					civ._bld_shield_flash[bi] = 1.0
			civ._diplomacy.push_chronicle("Ритуал щита в %s" % civ._city_name[src], pos, Color("#38F0FF"))
		PLOT_ASCEND_MONOLITH:
			civ._add_city_science(src, 45.0)
			civ._city_loyalty[src] = minf(100.0, civ._city_loyalty[src] + 20.0)
			civ._diplomacy.push_chronicle("Возвышение Монолита: %s" % civ._city_name[src], pos, Color("#B86BFF"))
		PLOT_REFORM_SUCCESSION:
			var cul_id: int = _city_culture_id[src]
			if cul_id >= 0 and cul_id < MAX_CULTURES:
				_cul_succ_law[cul_id] = (_cul_succ_law[cul_id] + 1) % SUCC_LAW_NAMES_RU.size()
			civ._diplomacy.push_chronicle("Реформа наследования: %s" % civ._city_name[src], pos, Color("#FFD84A"))


func _resolve_schism_plot(civ: Node2D, src: int, pos: Vector2) -> void:
	if src < 0 or src >= MAX_CITIES or civ._city_active[src] == 0:
		return
	var fac: int = int(civ._city_faction[src])
	var old_cul: int = _city_culture_id[src]
	var new_lang: int = evolve_dialect(_city_lang_id[src], fac)
	var new_creed: int = _ensure_creed(fac, true)
	var new_cul: int = _create_culture(fac, old_cul, new_lang, new_creed)
	_city_culture_id[src] = new_cul
	_city_lang_id[src] = new_lang
	_city_creed_id[src] = new_creed
	civ._city_name[src] = generate_onomastic_name("city", fac, new_lang)
	civ._territory.mark_all_borders_dirty(civ)
	civ._diplomacy.push_chronicle("Раскол культуры: %s (%s)" % [civ._city_name[src], _cul_name[new_cul]], pos, _cul_color[new_cul])


func _resolve_codex_plot(civ: Node2D, src: int, pos: Vector2) -> void:
	if src < 0 or src >= MAX_CITIES or civ._city_active[src] == 0:
		return
	var slot: int = -1
	for b in range(MAX_BOOKS):
		if _book_active[b] == 0:
			slot = b
			break
	if slot < 0:
		slot = _meta_rng.randi() % MAX_BOOKS
	var fac: int = int(civ._city_faction[src])
	var cul_id: int = _city_culture_id[src]
	_book_active[slot] = 1
	_book_kind[slot] = _meta_rng.randi() % BOOK_KIND_NAMES_RU.size()
	_book_city_id[slot] = src
	_book_culture_id[slot] = cul_id
	_book_creed_id[slot] = _city_creed_id[src]
	_book_reads[slot] = 1
	_book_trait_id[slot] = _meta_rng.randi() % 8
	_book_author[slot] = _army_captain_name[src] if _army_captain_name[src] != "" else generate_onomastic_name("notable", fac, _city_lang_id[src])
	_book_title[slot] = generate_onomastic_name("book", fac, _city_lang_id[src])
	civ._add_city_science(src, 22.0)
	if cul_id >= 0 and cul_id < MAX_CULTURES:
		_cul_xp[cul_id] += 40.0
	civ._diplomacy.push_chronicle("Кодекс написан: %s (%s)" % [_book_title[slot], civ._city_name[src]], pos, Color("#7CE7FF"))


# --- Loyalty & Diplomatic Opinion Factors ---

func calc_extra_loyalty_bonus_fast(civ: Node2D, cid: int) -> float:
	var kid: int = civ._city_kingdom_id[cid]
	var cap_cid: int = civ._kingdom_capital_cid[kid] if (kid >= 0 and kid < MAX_KINGDOMS) else -1
	if cap_cid == cid:
		return 2.0
	var net_bonus: float = 0.0
	if kid >= 0 and kid < MAX_KINGDOMS:
		var max_c: int = 4 + (_kingdom_king_intel[kid] / 2)
		if civ._kingdom_city_count[kid] > max_c:
			net_bonus -= float(civ._kingdom_city_count[kid] - max_c) * 0.45
		if cap_cid >= 0 and civ._city_active[cap_cid] != 0:
			net_bonus += 0.25 if _city_culture_id[cid] == _city_culture_id[cap_cid] else -0.40
			net_bonus += 0.20 if _city_creed_id[cid] == _city_creed_id[cap_cid] else -0.45
			if civ._city_pop[cid] > civ._city_pop[cap_cid] + 6:
				net_bonus -= 0.35
	if int(civ._city_war_state[cid]) >= 2:
		net_bonus += 0.30
	return net_bonus


func calc_extra_loyalty_stress(civ: Node2D, cid: int) -> Dictionary:
	var kid: int = civ._city_kingdom_id[cid]
	var cap_cid: int = civ._kingdom_capital_cid[kid] if (kid >= 0 and kid < MAX_KINGDOMS) else -1
	var net_bonus: float = 0.0
	var factors: Array[Dictionary] = []
	if cap_cid == cid:
		factors.append({"label": "Столица", "delta": 100.0})
		return {"bonus": 2.0, "factors": factors}
	if kid >= 0 and kid < MAX_KINGDOMS:
		var max_c: int = 4 + (_kingdom_king_intel[kid] / 2)
		if civ._kingdom_city_count[kid] > max_c:
			var pen: float = -float(civ._kingdom_city_count[kid] - max_c) * 0.45
			net_bonus += pen
			factors.append({"label": "Лимит городов", "delta": pen * 20.0})
		if cap_cid >= 0 and civ._city_active[cap_cid] != 0:
			if _city_culture_id[cid] == _city_culture_id[cap_cid]:
				net_bonus += 0.25
				factors.append({"label": "Общая культура", "delta": 15.0})
			else:
				net_bonus -= 0.40
				factors.append({"label": "Иная культура", "delta": -25.0})
			if _city_creed_id[cid] == _city_creed_id[cap_cid]:
				net_bonus += 0.20
				factors.append({"label": "Общая вера", "delta": 15.0})
			else:
				net_bonus -= 0.45
				factors.append({"label": "Иная вера", "delta": -30.0})
			if civ._city_pop[cid] > civ._city_pop[cap_cid] + 6:
				net_bonus -= 0.35
				factors.append({"label": "Крупнее столицы", "delta": -20.0})
	if int(civ._city_war_state[cid]) >= 2:
		net_bonus += 0.30
		factors.append({"label": "Сплочение в войне", "delta": 20.0})
	return {"bonus": net_bonus, "factors": factors}


func calc_diplomacy_factors(civ: Node2D, city_a: int, city_b: int) -> Dictionary:
	ensure_allocated()
	if city_a < 0 or city_a >= MAX_CITIES or city_b < 0 or city_b >= MAX_CITIES:
		return {"found": false}
	if civ._city_active[city_a] == 0 or civ._city_active[city_b] == 0:
		return {"found": false}
	var loy_d: Dictionary = calc_extra_loyalty_stress(civ, city_a)
	var op_factors: Array[Dictionary] = []
	var op_total: float = 0.0
	var ka: int = civ._city_kingdom_id[city_a]
	var kb: int = civ._city_kingdom_id[city_b]
	var st: int = int(civ._diplo_matrix[city_a * civ._max_cities + city_b])
	if st >= 2:
		op_total -= 500.0
		op_factors.append({"label": "В состоянии войны", "delta": -500.0})
	elif st == 1:
		op_total += 40.0
		op_factors.append({"label": "Действующий пакт", "delta": 40.0})
	if ka >= 0 and kb >= 0:
		if _kingdom_alliance_id[ka] >= 0 and _kingdom_alliance_id[ka] == _kingdom_alliance_id[kb]:
			op_total += 30.0
			op_factors.append({"label": "В одном альянсе", "delta": 30.0})
		var truce: float = _kingdom_truce[ka * MAX_KINGDOMS + kb]
		if truce > 0.0:
			op_total += 100.0
			op_factors.append({"label": "Перемирие", "delta": 100.0})
	if int(civ._city_faction[city_a]) == int(civ._city_faction[city_b]):
		op_total += 15.0
		op_factors.append({"label": "Родственный вид", "delta": 15.0})
	else:
		op_total -= 10.0
		op_factors.append({"label": "Иной вид", "delta": -10.0})
	if _city_culture_id[city_a] >= 0 and _city_culture_id[city_a] == _city_culture_id[city_b]:
		op_total += 15.0
		op_factors.append({"label": "Общая культура", "delta": 15.0})
	else:
		op_total -= 15.0
		op_factors.append({"label": "Разные культуры", "delta": -15.0})
	if _city_creed_id[city_a] >= 0 and _city_creed_id[city_a] == _city_creed_id[city_b]:
		op_total += 15.0
		op_factors.append({"label": "Общая вера", "delta": 15.0})
	else:
		op_total -= 15.0
		op_factors.append({"label": "Разная вера", "delta": -15.0})
	var dist: float = civ._city_center[city_a].distance_to(civ._city_center[city_b])
	if dist <= 120.0:
		op_total -= 25.0
		op_factors.append({"label": "Трение границ", "delta": -25.0})
	else:
		op_total += 25.0
		op_factors.append({"label": "Дальние земли", "delta": 25.0})
	var st_names := ["Нейтралитет", "Пакт", "Тотальная война", "Мятеж"]
	return {
		"found": true,
		"city_a": city_a,
		"city_b": city_b,
		"kingdom_a": ka,
		"kingdom_b": kb,
		"state": st,
		"state_name": st_names[clampi(st, 0, 3)],
		"tension": snappedf(civ._diplo_tension[city_a * civ._max_cities + city_b], 0.1),
		"opinion_total": op_total,
		"loyalty_a": snappedf(civ._city_loyalty[city_a], 0.1),
		"loyalty_factors": loy_d["factors"],
		"opinion_factors": op_factors,
	}


# --- HistoryRingBuffers (Zero SQLite, PackedFloat32Array) ---

func _step_history_sampling(civ: Node2D, safe_dt: float, pace_dt: float) -> void:
	_hist_raw_cd = maxf(0.0, _hist_raw_cd - safe_dt)
	_hist_pace_acc += pace_dt
	if _hist_raw_cd > 0.0:
		return
	var sampled_any: bool = false
	var cached_snap: Dictionary = {}
	for sc in range(HIST_SCALES):
		_hist_world_acc[sc] += _hist_pace_acc
		if _hist_world_acc[sc] >= float(HIST_SCALE_STEPS[sc]):
			_hist_world_acc[sc] = fmod(_hist_world_acc[sc], float(HIST_SCALE_STEPS[sc]))
			if cached_snap.is_empty():
				cached_snap = _gather_history_snapshot_once(civ)
			_write_world_history_sc(sc, cached_snap)
			_record_kingdom_history(civ, sc)
			sampled_any = true
	_hist_pace_acc = 0.0
	if sampled_any:
		_hist_raw_cd = 0.55 if civ._sim_pace_mult >= 10.0 else 0.05


func _record_history_sample(civ: Node2D, sc: int) -> void:
	var snap: Dictionary = _gather_history_snapshot_once(civ)
	_write_world_history_sc(sc, snap)
	_record_kingdom_history(civ, sc)


func _gather_history_snapshot_once(civ: Node2D) -> Dictionary:
	var pop_sum: int = 0
	var cities_sum: int = 0
	var sci_sum: float = 0.0
	var food_sum: float = 0.0
	var ore_sum: float = 0.0
	var ene_sum: float = 0.0
	var cred_sum: float = 0.0
	_tmp_k_pop.fill(0)
	_tmp_k_cit.fill(0)
	_tmp_k_zon.fill(0)
	_tmp_k_sci.fill(0.0)
	_tmp_k_crd.fill(0.0)
	_tmp_k_war.fill(0)
	for cid in range(civ._max_cities):
		if civ._city_active[cid] == 0:
			continue
		var cpop: int = civ._city_pop[cid]
		var csci: float = civ._city_science[cid]
		var ccrd: float = civ._city_credits[cid]
		cities_sum += 1
		pop_sum += cpop
		sci_sum += csci
		food_sum += civ._city_food[cid]
		ore_sum += civ._city_ore[cid]
		ene_sum += civ._city_energy[cid]
		cred_sum += ccrd
		var kid: int = civ._city_kingdom_id[cid]
		if kid >= 0 and kid < MAX_KINGDOMS:
			_tmp_k_cit[kid] += 1
			_tmp_k_pop[kid] += cpop
			_tmp_k_zon[kid] += civ._city_zones_count[cid]
			_tmp_k_sci[kid] += csci
			_tmp_k_crd[kid] += ccrd
			if int(civ._city_war_state[cid]) >= 2:
				_tmp_k_war[kid] = 1
	var wars_n: int = maxi(get_active_war_count(), civ._count_active_diplo_pairs().x)
	return {
		"pop": float(pop_sum), "cities": float(cities_sum), "wars": float(wars_n),
		"blds": float(civ._bld_count), "sci": sci_sum, "food": food_sum,
		"ore": ore_sum, "ene": ene_sum, "cred": cred_sum, "deaths": float(_world_deaths_total),
	}


func _write_world_history_sc(sc: int, snap: Dictionary) -> void:
	var head: int = _hist_world_head[sc]
	var vals: Array[float] = [
		float(snap["pop"]), float(snap["cities"]), float(snap["wars"]), float(snap["blds"]),
		float(snap["sci"]), float(snap["food"]), float(snap["ore"]), float(snap["ene"]),
		float(snap["cred"]), float(snap["deaths"]),
	]
	for m in range(HIST_WORLD_METRICS):
		_hist_world_buf[sc * HIST_WORLD_METRICS * HIST_SAMPLES + m * HIST_SAMPLES + head] = vals[m]
	_hist_world_head[sc] = (head + 1) % HIST_SAMPLES
	if _hist_world_cnt[sc] < HIST_SAMPLES:
		_hist_world_cnt[sc] += 1


func _record_kingdom_history(civ: Node2D, sc: int) -> void:
	for kid in range(MAX_KINGDOMS):
		if civ._kingdom_active[kid] == 0 or _tmp_k_cit[kid] <= 0:
			continue
		var ks_idx: int = kid * HIST_SCALES + sc
		var kh: int = _hist_k_head[ks_idx]
		var k_base: int = (kid * HIST_SCALES + sc) * HIST_K_METRICS * HIST_SAMPLES
		_hist_k_buf[k_base + 0 * HIST_SAMPLES + kh] = float(_tmp_k_pop[kid])
		_hist_k_buf[k_base + 1 * HIST_SAMPLES + kh] = float(_tmp_k_cit[kid])
		_hist_k_buf[k_base + 2 * HIST_SAMPLES + kh] = float(_tmp_k_zon[kid])
		_hist_k_buf[k_base + 3 * HIST_SAMPLES + kh] = _tmp_k_sci[kid]
		_hist_k_buf[k_base + 4 * HIST_SAMPLES + kh] = _tmp_k_crd[kid]
		_hist_k_buf[k_base + 5 * HIST_SAMPLES + kh] = float(_tmp_k_war[kid])
		_hist_k_head[ks_idx] = (kh + 1) % HIST_SAMPLES
		if _hist_k_cnt[ks_idx] < HIST_SAMPLES:
			_hist_k_cnt[ks_idx] += 1


func _resolve_world_metric_idx(metric_key: String) -> int:
	var k: String = metric_key.to_lower()
	match k:
		"population", "pop", "население":
			return 0
		"cities", "города":
			return 1
		"wars", "wars_active", "войны":
			return 2
		"buildings", "постройки":
			return 3
		"science", "наука":
			return 4
		"food", "еда":
			return 5
		"ore", "руда":
			return 6
		"energy", "энергия":
			return 7
		"credits", "кредиты":
			return 8
		"deaths", "mortality", "deaths_total", "смертность":
			return 9
		_:
			return 0


func get_history_series(scale_id: int, metric_key: String) -> PackedFloat32Array:
	ensure_allocated()
	if metric_key.begins_with("k:"):
		var parts: PackedStringArray = metric_key.split(":")
		if parts.size() >= 3:
			return get_kingdom_history_series(int(parts[1]), scale_id, parts[2])
	var sc: int = clampi(scale_id, 0, HIST_SCALES - 1)
	var m_idx: int = _resolve_world_metric_idx(metric_key)
	var cnt: int = _hist_world_cnt[sc]
	var out := PackedFloat32Array()
	if cnt <= 0:
		return out
	out.resize(cnt)
	var head: int = _hist_world_head[sc]
	var start: int = (head - cnt + HIST_SAMPLES) % HIST_SAMPLES
	var base: int = sc * HIST_WORLD_METRICS * HIST_SAMPLES + m_idx * HIST_SAMPLES
	for i in range(cnt):
		out[i] = _hist_world_buf[base + ((start + i) % HIST_SAMPLES)]
	return out


func get_kingdom_history_series(kingdom_id: int, scale_id: int, metric_key: String) -> PackedFloat32Array:
	ensure_allocated()
	var out := PackedFloat32Array()
	if kingdom_id < 0 or kingdom_id >= MAX_KINGDOMS:
		return out
	var sc: int = clampi(scale_id, 0, HIST_SCALES - 1)
	var m_idx: int = 0
	var k: String = metric_key.to_lower()
	if k == "cities":
		m_idx = 1
	elif k == "zones":
		m_idx = 2
	elif k == "science":
		m_idx = 3
	elif k == "credits":
		m_idx = 4
	elif k == "wars":
		m_idx = 5
	var ks_idx: int = kingdom_id * HIST_SCALES + sc
	var cnt: int = _hist_k_cnt[ks_idx]
	if cnt <= 0:
		return out
	out.resize(cnt)
	var head: int = _hist_k_head[ks_idx]
	var start: int = (head - cnt + HIST_SAMPLES) % HIST_SAMPLES
	var base: int = ks_idx * HIST_K_METRICS * HIST_SAMPLES + m_idx * HIST_SAMPLES
	for i in range(cnt):
		out[i] = _hist_k_buf[base + ((start + i) % HIST_SAMPLES)]
	return out


# --- Rendering & Read-Only Summaries for UI ---

func write_ships_mm(civ: Node2D, mm: MultiMesh, slot_and_cap: Vector2i) -> int:
	var slot_i: int = slot_and_cap.x
	var cap_inst: int = slot_and_cap.y
	if _ship_active_count <= 0:
		return slot_i
	var max_col: int = maxi(0, civ._bld_atlas_cols - 1)
	for s in range(MAX_SHIPS):
		if slot_i >= cap_inst:
			break
		if _ship_active[s] == 0:
			continue
		var kind: int = int(_ship_kind[s])
		var raw_col: int = BLD_COL_SHIP_FISH + kind
		var col_idx: int = raw_col if raw_col <= max_col else 32
		var bob: float = sin(civ._sim_time * 3.2 + _ship_phase[s]) * 0.65
		var pos: Vector2 = _ship_pos[s] + Vector2(0.0, -3.0 + bob)
		var cid: int = _ship_city_id[s]
		var tint: Color = civ._get_city_border_color(cid) if cid >= 0 else Color.CYAN
		mm.set_instance_transform_2d(slot_i, Transform2D(0.0, pos))
		mm.set_instance_color(slot_i, tint)
		mm.set_instance_custom_data(slot_i, Color(_ship_phase[s], 0.0, _ship_facing[s], float(col_idx)))
		slot_i += 1
	return slot_i


func get_wars_summary(civ: Node2D) -> Array[Dictionary]:
	ensure_allocated()
	var out: Array[Dictionary] = []
	for w in range(MAX_WARS):
		if _war_active[w] == 0:
			continue
		var ka: int = _war_main_att_kid[w]
		var kd: int = _war_main_def_kid[w]
		var cap_a: int = civ._kingdom_capital_cid[ka] if (ka >= 0 and ka < MAX_KINGDOMS) else -1
		var anchor: Vector2 = civ._city_center[cap_a] if (cap_a >= 0 and civ._city_active[cap_a] != 0) else Vector2(320.0, 180.0)
		var wtype: int = clampi(int(_war_type[w]), 0, WAR_TYPE_NAMES_RU.size() - 1)
		out.append({
			"war_id": w,
			"name": _war_name[w],
			"type": wtype,
			"type_name": WAR_TYPE_NAMES_RU[wtype],
			"main_attacker_kid": ka,
			"main_defender_kid": kd,
			"attacker_name": civ._kingdom_name[ka] if ka >= 0 else "",
			"defender_name": civ._kingdom_name[kd] if kd >= 0 else "",
			"attackers": _mask_list(_war_att_mask, w),
			"defenders": _mask_list(_war_def_mask, w),
			"duration": snappedf(_war_duration[w], 0.1),
			"attacker_deaths": _war_att_deaths[w],
			"defender_deaths": _war_def_deaths[w],
			"casualties": _war_att_deaths[w] + _war_def_deaths[w],
			"zones_flipped": _war_zones_flipped[w],
			"score": snappedf(_war_score[w], 0.1),
			"pos": anchor,
		})
	return out


func get_alliances_summary(civ: Node2D) -> Array[Dictionary]:
	ensure_allocated()
	var out: Array[Dictionary] = []
	for a in range(MAX_ALLIANCES):
		if _ally_active[a] == 0:
			continue
		var members: Array[int] = _mask_list(_ally_member_mask, a)
		var member_names: Array[String] = []
		var total_pop: int = 0
		var anchor := Vector2(320.0, 180.0)
		for mk in members:
			if mk >= 0 and mk < MAX_KINGDOMS and civ._kingdom_active[mk] != 0:
				member_names.append(civ._kingdom_name[mk])
				var cap: int = civ._kingdom_capital_cid[mk]
				if cap >= 0 and civ._city_active[cap] != 0:
					anchor = civ._city_center[cap]
		for cid in range(civ._max_cities):
			if civ._city_active[cid] != 0 and members.has(civ._city_kingdom_id[cid]):
				total_pop += civ._city_pop[cid]
		out.append({
			"alliance_id": a,
			"name": _ally_name[a],
			"motto": _ally_motto[a],
			"color": _ally_color[a],
			"members": members,
			"member_names": member_names,
			"member_count": members.size(),
			"total_pop": total_pop,
			"age": snappedf(_ally_age_sec[a], 0.1),
			"pos": anchor,
		})
	return out


func get_cultures_summary(civ: Node2D) -> Array[Dictionary]:
	ensure_allocated()
	_cul_city_count.fill(0)
	_cul_pop_count.fill(0)
	for cid in range(civ._max_cities):
		if civ._city_active[cid] == 0:
			continue
		var cu: int = _city_culture_id[cid]
		if cu >= 0 and cu < MAX_CULTURES and _cul_active[cu] != 0:
			_cul_city_count[cu] += 1
			_cul_pop_count[cu] += civ._city_pop[cid]
	var out: Array[Dictionary] = []
	for i in range(MAX_CULTURES):
		if _cul_active[i] == 0:
			continue
		var lid: int = _cul_lang_id[i]
		var crid: int = _cul_creed_id[i]
		out.append({
			"culture_id": i,
			"name": _cul_name[i],
			"faction": int(_cul_faction[i]),
			"parent_id": _cul_parent_id[i],
			"level": _cul_level[i],
			"xp": snappedf(_cul_xp[i], 0.1),
			"color": _cul_color[i],
			"town_plan": int(_cul_town_plan[i]),
			"town_plan_name": TOWN_PLAN_NAMES_RU[clampi(int(_cul_town_plan[i]), 0, TOWN_PLAN_NAMES_RU.size() - 1)],
			"weapon_pref": int(_cul_weapon_pref[i]),
			"weapon_pref_name": WEAPON_PREF_NAMES_RU[clampi(int(_cul_weapon_pref[i]), 0, WEAPON_PREF_NAMES_RU.size() - 1)],
			"succ_law": int(_cul_succ_law[i]),
			"succ_law_name": SUCC_LAW_NAMES_RU[clampi(int(_cul_succ_law[i]), 0, SUCC_LAW_NAMES_RU.size() - 1)],
			"language_name": _lang_name[lid] if (lid >= 0 and lid < MAX_LANGUAGES) else "",
			"creed_name": _creed_name[crid] if (crid >= 0 and crid < MAX_CREEDS) else "",
			"cities": _cul_city_count[i],
			"pop": _cul_pop_count[i],
		})
	return out


func get_ships_summary() -> Array[Dictionary]:
	ensure_allocated()
	var out: Array[Dictionary] = []
	for s in range(MAX_SHIPS):
		if _ship_active[s] == 0:
			continue
		var k: int = clampi(int(_ship_kind[s]), 0, 2)
		out.append({
			"ship_id": s,
			"kind": k,
			"kind_name": SHIP_TYPE_NAMES_RU[k],
			"city_id": _ship_city_id[s],
			"target_city": _ship_target_city[s],
			"state": int(_ship_state[s]),
			"hp": snappedf(_ship_hp[s], 0.1),
			"max_hp": _ship_max_hp[s],
			"troops": _ship_troop_count[s],
			"pos": _ship_pos[s],
		})
	return out


func get_clans_summary() -> Array[Dictionary]:
	ensure_allocated()
	var out: Array[Dictionary] = []
	for i in range(MAX_CLANS):
		if _clan_active[i] == 0:
			continue
		var tid: int = clampi(_clan_trait_id[i], 0, CLAN_TRAIT_NAMES_RU.size() - 1)
		out.append({
			"clan_id": i,
			"name": _clan_name[i],
			"motto": _clan_motto[i],
			"faction": int(_clan_faction[i]),
			"trait_name": CLAN_TRAIT_NAMES_RU[tid],
			"renown": _clan_renown[i],
			"generation": _clan_generation[i],
		})
	return out


func get_codices_summary(city_id: int = -1) -> Array[Dictionary]:
	ensure_allocated()
	var out: Array[Dictionary] = []
	for b in range(MAX_BOOKS):
		if _book_active[b] == 0:
			continue
		if city_id >= 0 and _book_city_id[b] != city_id:
			continue
		var k: int = clampi(int(_book_kind[b]), 0, BOOK_KIND_NAMES_RU.size() - 1)
		out.append({
			"book_id": b,
			"title": _book_title[b],
			"kind": k,
			"kind_name": BOOK_KIND_NAMES_RU[k],
			"city_id": _book_city_id[b],
			"author": _book_author[b],
			"reads": _book_reads[b],
		})
	return out


# --- Binary Serialization (Pack / Unpack) ---

func pack_meta_state(buf: StreamPeerBuffer) -> void:
	ensure_allocated()
	buf.put_32(_world_deaths_total)
	_pack_ships(buf)
	_pack_wars_and_alliances(buf)
	_pack_noosphere_tables(buf)
	_pack_history_buffers(buf)


func _pack_ships(buf: StreamPeerBuffer) -> void:
	buf.put_u8(MAX_SHIPS)
	for s in range(MAX_SHIPS):
		buf.put_u8(_ship_active[s])
		if _ship_active[s] == 0:
			continue
		buf.put_u8(_ship_kind[s])
		buf.put_u8(_ship_state[s])
		buf.put_u8(_ship_faction[s])
		buf.put_32(_ship_city_id[s])
		buf.put_32(_ship_target_city[s])
		buf.put_float(_ship_pos[s].x)
		buf.put_float(_ship_pos[s].y)
		buf.put_float(_ship_home_pos[s].x)
		buf.put_float(_ship_home_pos[s].y)
		buf.put_float(_ship_dst_pos[s].x)
		buf.put_float(_ship_dst_pos[s].y)
		buf.put_float(_ship_pickup_shore[s].x)
		buf.put_float(_ship_pickup_shore[s].y)
		buf.put_float(_ship_dropoff_shore[s].x)
		buf.put_float(_ship_dropoff_shore[s].y)
		buf.put_float(_ship_hp[s])
		buf.put_float(_ship_max_hp[s])
		buf.put_float(_ship_cargo[s])
		buf.put_float(_ship_wait_t[s])
		buf.put_float(_ship_facing[s])
		buf.put_u8(_ship_troop_count[s])
		var base: int = s * MAX_SHIP_TROOPS
		for k in range(_ship_troop_count[s]):
			buf.put_32(_ship_troop_uids[base + k])


func _pack_wars_and_alliances(buf: StreamPeerBuffer) -> void:
	buf.put_u8(MAX_WARS)
	for w in range(MAX_WARS):
		buf.put_u8(_war_active[w])
		if _war_active[w] == 0:
			continue
		buf.put_u8(_war_type[w])
		buf.put_utf8_string(_war_name[w])
		buf.put_32(_war_main_att_kid[w])
		buf.put_32(_war_main_def_kid[w])
		for m in range(4):
			buf.put_32(_war_att_mask[w * 4 + m])
			buf.put_32(_war_def_mask[w * 4 + m])
		buf.put_float(_war_start_t[w])
		buf.put_float(_war_duration[w])
		buf.put_32(_war_att_deaths[w])
		buf.put_32(_war_def_deaths[w])
		buf.put_32(_war_zones_flipped[w])
		buf.put_float(_war_score[w])

	buf.put_u8(MAX_ALLIANCES)
	for a in range(MAX_ALLIANCES):
		buf.put_u8(_ally_active[a])
		if _ally_active[a] == 0:
			continue
		buf.put_utf8_string(_ally_name[a])
		buf.put_utf8_string(_ally_motto[a])
		buf.put_32(_ally_founder_kid[a])
		for m in range(4):
			buf.put_32(_ally_member_mask[a * 4 + m])
		buf.put_32(_ally_member_count[a])
		buf.put_float(_ally_age_sec[a])
		buf.put_float(_ally_color[a].r)
		buf.put_float(_ally_color[a].g)
		buf.put_float(_ally_color[a].b)


func _pack_noosphere_tables(buf: StreamPeerBuffer) -> void:
	buf.put_u8(MAX_CLANS)
	for i in range(MAX_CLANS):
		buf.put_u8(_clan_active[i])
		if _clan_active[i] != 0:
			buf.put_utf8_string(_clan_name[i])
			buf.put_utf8_string(_clan_motto[i])
			buf.put_u8(_clan_faction[i])
			buf.put_32(_clan_home_cid[i])
			buf.put_32(_clan_trait_id[i])
			buf.put_32(_clan_renown[i])
			buf.put_32(_clan_generation[i])

	buf.put_u8(MAX_CULTURES)
	for i in range(MAX_CULTURES):
		buf.put_u8(_cul_active[i])
		if _cul_active[i] != 0:
			buf.put_utf8_string(_cul_name[i])
			buf.put_u8(_cul_faction[i])
			buf.put_32(_cul_parent_id[i])
			buf.put_32(_cul_level[i])
			buf.put_float(_cul_xp[i])
			buf.put_float(_cul_color[i].r)
			buf.put_float(_cul_color[i].g)
			buf.put_float(_cul_color[i].b)
			buf.put_u8(_cul_town_plan[i])
			buf.put_u8(_cul_weapon_pref[i])
			buf.put_u8(_cul_succ_law[i])
			buf.put_32(_cul_ethos_flags[i])
			buf.put_32(_cul_lang_id[i])
			buf.put_32(_cul_creed_id[i])

	_pack_creeds_langs_books(buf)
	for k in range(MAX_KINGDOMS):
		buf.put_32(_kingdom_royal_clan[k])
		buf.put_32(_kingdom_alliance_id[k])
		buf.put_32(_kingdom_culture_id[k])
		buf.put_32(_kingdom_creed_id[k])
		buf.put_32(_kingdom_king_intel[k])
		buf.put_utf8_string(_kingdom_king_name[k])
		buf.put_float(_kingdom_king_rule_sec[k])
	for c in range(MAX_CITIES):
		buf.put_32(_city_culture_id[c])
		buf.put_32(_city_creed_id[c])
		buf.put_32(_city_lang_id[c])
		buf.put_32(_city_clan_id[c])
		buf.put_u8(_army_active[c])
		buf.put_32(_army_strength[c])
		buf.put_32(_army_kills[c])
		buf.put_utf8_string(_army_captain_name[c])


func _pack_creeds_langs_books(buf: StreamPeerBuffer) -> void:
	buf.put_u8(MAX_CREEDS)
	for i in range(MAX_CREEDS):
		buf.put_u8(_creed_active[i])
		if _creed_active[i] != 0:
			buf.put_utf8_string(_creed_name[i])
			buf.put_u8(_creed_tenet[i])
			buf.put_u8(_creed_rite[i])
			buf.put_float(_creed_color[i].r)
			buf.put_float(_creed_color[i].g)
			buf.put_float(_creed_color[i].b)
	buf.put_u8(MAX_LANGUAGES)
	for i in range(MAX_LANGUAGES):
		buf.put_u8(_lang_active[i])
		if _lang_active[i] != 0:
			buf.put_utf8_string(_lang_name[i])
			buf.put_u8(_lang_faction[i])
			buf.put_32(_lang_parent_id[i])
			buf.put_32(_lang_mutation_gen[i])
			buf.put_32(_lang_shift_idx[i])
	buf.put_u8(MAX_BOOKS)
	for i in range(MAX_BOOKS):
		buf.put_u8(_book_active[i])
		if _book_active[i] != 0:
			buf.put_utf8_string(_book_title[i])
			buf.put_u8(_book_kind[i])
			buf.put_32(_book_city_id[i])
			buf.put_32(_book_culture_id[i])
			buf.put_32(_book_creed_id[i])
			buf.put_utf8_string(_book_author[i])
			buf.put_32(_book_reads[i])
			buf.put_32(_book_trait_id[i])


func _pack_history_buffers(buf: StreamPeerBuffer) -> void:
	for sc in range(HIST_SCALES):
		buf.put_32(_hist_world_head[sc])
		buf.put_32(_hist_world_cnt[sc])
		buf.put_float(_hist_world_acc[sc])
		var cnt: int = _hist_world_cnt[sc]
		for m in range(HIST_WORLD_METRICS):
			var base: int = sc * HIST_WORLD_METRICS * HIST_SAMPLES + m * HIST_SAMPLES
			var start: int = (_hist_world_head[sc] - cnt + HIST_SAMPLES) % HIST_SAMPLES
			for i in range(cnt):
				buf.put_float(_hist_world_buf[base + ((start + i) % HIST_SAMPLES)])


func unpack_meta_state(buf: StreamPeerBuffer) -> void:
	ensure_allocated()
	if buf.get_available_bytes() < 4:
		return
	_world_deaths_total = buf.get_32()
	_unpack_ships(buf)
	_unpack_wars_and_alliances(buf)
	_unpack_noosphere_tables(buf)
	_unpack_history_buffers(buf)


func _unpack_ships(buf: StreamPeerBuffer) -> void:
	if buf.get_available_bytes() <= 0:
		return
	var n: int = buf.get_u8()
	_ship_active_count = 0
	for s in range(n):
		if buf.get_available_bytes() <= 0:
			return
		var act: int = buf.get_u8()
		if act == 0:
			if s < MAX_SHIPS:
				_ship_active[s] = 0
			continue
		var k: int = buf.get_u8()
		var st: int = buf.get_u8()
		var fac: int = buf.get_u8()
		var cid: int = buf.get_32()
		var tcid: int = buf.get_32()
		var pos := Vector2(buf.get_float(), buf.get_float())
		var hpos := Vector2(buf.get_float(), buf.get_float())
		var dpos := Vector2(buf.get_float(), buf.get_float())
		var psh := Vector2(buf.get_float(), buf.get_float())
		var dsh := Vector2(buf.get_float(), buf.get_float())
		var hp: float = buf.get_float()
		var mhp: float = buf.get_float()
		var crg: float = buf.get_float()
		var wt: float = buf.get_float()
		var fcg: float = buf.get_float()
		var tr_n: int = buf.get_u8()
		if s < MAX_SHIPS:
			_ship_active[s] = 1
			_ship_kind[s] = k
			_ship_state[s] = st
			_ship_faction[s] = fac
			_ship_city_id[s] = cid
			_ship_target_city[s] = tcid
			_ship_pos[s] = pos
			_ship_home_pos[s] = hpos
			_ship_dst_pos[s] = dpos
			_ship_pickup_shore[s] = psh
			_ship_dropoff_shore[s] = dsh
			_ship_hp[s] = hp
			_ship_max_hp[s] = mhp
			_ship_cargo[s] = crg
			_ship_wait_t[s] = wt
			_ship_facing[s] = fcg
			_ship_troop_count[s] = mini(tr_n, MAX_SHIP_TROOPS)
			_ship_active_count += 1
		var base: int = s * MAX_SHIP_TROOPS
		for t in range(tr_n):
			var uid: int = buf.get_32()
			if s < MAX_SHIPS and t < MAX_SHIP_TROOPS:
				_ship_troop_uids[base + t] = uid


func _unpack_wars_and_alliances(buf: StreamPeerBuffer) -> void:
	if buf.get_available_bytes() <= 0:
		return
	var wn: int = buf.get_u8()
	for w in range(wn):
		if buf.get_available_bytes() <= 0:
			return
		var act: int = buf.get_u8()
		if act == 0:
			if w < MAX_WARS:
				_war_active[w] = 0
			continue
		var wt: int = buf.get_u8()
		var wnm: String = buf.get_utf8_string()
		var ma: int = buf.get_32()
		var md: int = buf.get_32()
		var am := [0, 0, 0, 0]
		var dm := [0, 0, 0, 0]
		for m in range(4):
			am[m] = buf.get_32()
			dm[m] = buf.get_32()
		var st_t: float = buf.get_float()
		var dur: float = buf.get_float()
		var ad: int = buf.get_32()
		var dd: int = buf.get_32()
		var zf: int = buf.get_32()
		var sc: float = buf.get_float()
		if w < MAX_WARS:
			_war_active[w] = 1
			_war_type[w] = wt
			_war_name[w] = wnm
			_war_main_att_kid[w] = ma
			_war_main_def_kid[w] = md
			for m in range(4):
				_war_att_mask[w * 4 + m] = int(am[m])
				_war_def_mask[w * 4 + m] = int(dm[m])
			_war_start_t[w] = st_t
			_war_duration[w] = dur
			_war_att_deaths[w] = ad
			_war_def_deaths[w] = dd
			_war_zones_flipped[w] = zf
			_war_score[w] = sc

	if buf.get_available_bytes() <= 0:
		return
	var an: int = buf.get_u8()
	for a in range(an):
		if buf.get_available_bytes() <= 0:
			return
		var act: int = buf.get_u8()
		if act == 0:
			if a < MAX_ALLIANCES:
				_ally_active[a] = 0
			continue
		var nm: String = buf.get_utf8_string()
		var mt: String = buf.get_utf8_string()
		var fkd: int = buf.get_32()
		var mm := [0, 0, 0, 0]
		for m in range(4):
			mm[m] = buf.get_32()
		var mc: int = buf.get_32()
		var age: float = buf.get_float()
		var col := Color(buf.get_float(), buf.get_float(), buf.get_float(), 1.0)
		if a < MAX_ALLIANCES:
			_ally_active[a] = 1
			_ally_name[a] = nm
			_ally_motto[a] = mt
			_ally_founder_kid[a] = fkd
			for m in range(4):
				_ally_member_mask[a * 4 + m] = int(mm[m])
			_ally_member_count[a] = mc
			_ally_age_sec[a] = age
			_ally_color[a] = col


func _unpack_noosphere_tables(buf: StreamPeerBuffer) -> void:
	if buf.get_available_bytes() <= 0:
		return
	var cln: int = buf.get_u8()
	for i in range(cln):
		var act: int = buf.get_u8()
		if act == 0:
			if i < MAX_CLANS:
				_clan_active[i] = 0
			continue
		var nm: String = buf.get_utf8_string()
		var mt: String = buf.get_utf8_string()
		var fac: int = buf.get_u8()
		var hc: int = buf.get_32()
		var tr: int = buf.get_32()
		var rn: int = buf.get_32()
		var gn: int = buf.get_32()
		if i < MAX_CLANS:
			_clan_active[i] = 1
			_clan_name[i] = nm
			_clan_motto[i] = mt
			_clan_faction[i] = fac
			_clan_home_cid[i] = hc
			_clan_trait_id[i] = tr
			_clan_renown[i] = rn
			_clan_generation[i] = gn

	var cun: int = buf.get_u8()
	for i in range(cun):
		var act: int = buf.get_u8()
		if act == 0:
			if i < MAX_CULTURES:
				_cul_active[i] = 0
			continue
		var nm: String = buf.get_utf8_string()
		var fac: int = buf.get_u8()
		var pr: int = buf.get_32()
		var lv: int = buf.get_32()
		var xp: float = buf.get_float()
		var col := Color(buf.get_float(), buf.get_float(), buf.get_float(), 1.0)
		var tp: int = buf.get_u8()
		var wp: int = buf.get_u8()
		var sl: int = buf.get_u8()
		var ef: int = buf.get_32()
		var li: int = buf.get_32()
		var ci: int = buf.get_32()
		if i < MAX_CULTURES:
			_cul_active[i] = 1
			_cul_name[i] = nm
			_cul_faction[i] = fac
			_cul_parent_id[i] = pr
			_cul_level[i] = lv
			_cul_xp[i] = xp
			_cul_color[i] = col
			_cul_town_plan[i] = tp
			_cul_weapon_pref[i] = wp
			_cul_succ_law[i] = sl
			_cul_ethos_flags[i] = ef
			_cul_lang_id[i] = li
			_cul_creed_id[i] = ci

	_unpack_creeds_langs_books(buf)
	for k in range(MAX_KINGDOMS):
		if buf.get_available_bytes() <= 0:
			return
		_kingdom_royal_clan[k] = buf.get_32()
		_kingdom_alliance_id[k] = buf.get_32()
		_kingdom_culture_id[k] = buf.get_32()
		_kingdom_creed_id[k] = buf.get_32()
		_kingdom_king_intel[k] = buf.get_32()
		_kingdom_king_name[k] = buf.get_utf8_string()
		_kingdom_king_rule_sec[k] = buf.get_float()
	for c in range(MAX_CITIES):
		if buf.get_available_bytes() <= 0:
			return
		_city_culture_id[c] = buf.get_32()
		_city_creed_id[c] = buf.get_32()
		_city_lang_id[c] = buf.get_32()
		_city_clan_id[c] = buf.get_32()
		_army_active[c] = buf.get_u8()
		_army_strength[c] = buf.get_32()
		_army_kills[c] = buf.get_32()
		_army_captain_name[c] = buf.get_utf8_string()


func _unpack_creeds_langs_books(buf: StreamPeerBuffer) -> void:
	var crn: int = buf.get_u8()
	for i in range(crn):
		var act: int = buf.get_u8()
		if act == 0:
			if i < MAX_CREEDS:
				_creed_active[i] = 0
			continue
		var nm: String = buf.get_utf8_string()
		var tn: int = buf.get_u8()
		var rt: int = buf.get_u8()
		var col := Color(buf.get_float(), buf.get_float(), buf.get_float(), 1.0)
		if i < MAX_CREEDS:
			_creed_active[i] = 1
			_creed_name[i] = nm
			_creed_tenet[i] = tn
			_creed_rite[i] = rt
			_creed_color[i] = col

	var lgn: int = buf.get_u8()
	for i in range(lgn):
		var act: int = buf.get_u8()
		if act == 0:
			if i < MAX_LANGUAGES:
				_lang_active[i] = 0
			continue
		var nm: String = buf.get_utf8_string()
		var fac: int = buf.get_u8()
		var pr: int = buf.get_32()
		var mg: int = buf.get_32()
		var sh: int = buf.get_32()
		if i < MAX_LANGUAGES:
			_lang_active[i] = 1
			_lang_name[i] = nm
			_lang_faction[i] = fac
			_lang_parent_id[i] = pr
			_lang_mutation_gen[i] = mg
			_lang_shift_idx[i] = sh

	var bkn: int = buf.get_u8()
	for i in range(bkn):
		var act: int = buf.get_u8()
		if act == 0:
			if i < MAX_BOOKS:
				_book_active[i] = 0
			continue
		var tt: String = buf.get_utf8_string()
		var kd: int = buf.get_u8()
		var cid: int = buf.get_32()
		var cul: int = buf.get_32()
		var crd: int = buf.get_32()
		var au: String = buf.get_utf8_string()
		var rd: int = buf.get_32()
		var tr: int = buf.get_32()
		if i < MAX_BOOKS:
			_book_active[i] = 1
			_book_title[i] = tt
			_book_kind[i] = kd
			_book_city_id[i] = cid
			_book_culture_id[i] = cul
			_book_creed_id[i] = crd
			_book_author[i] = au
			_book_reads[i] = rd
			_book_trait_id[i] = tr


func _unpack_history_buffers(buf: StreamPeerBuffer) -> void:
	for sc in range(HIST_SCALES):
		if buf.get_available_bytes() < 12:
			return
		var hd: int = buf.get_32()
		var cnt: int = clampi(buf.get_32(), 0, HIST_SAMPLES)
		var acc: float = buf.get_float()
		_hist_world_head[sc] = cnt % HIST_SAMPLES
		_hist_world_cnt[sc] = cnt
		_hist_world_acc[sc] = acc
		for m in range(HIST_WORLD_METRICS):
			var base: int = sc * HIST_WORLD_METRICS * HIST_SAMPLES + m * HIST_SAMPLES
			for i in range(cnt):
				_hist_world_buf[base + i] = buf.get_float()
		var _unused_hd: int = hd


func get_city_culture_id(cid: int) -> int:
	if cid < 0 or cid >= MAX_CITIES:
		return -1
	return _city_culture_id[cid]


func get_city_culture_color(cid: int) -> Color:
	var cu: int = get_city_culture_id(cid)
	if cu >= 0 and cu < MAX_CULTURES and _cul_active[cu] != 0:
		return _cul_color[cu]
	return Color("#4CE4FF")


func get_city_culture_name(cid: int) -> String:
	var cu: int = get_city_culture_id(cid)
	if cu >= 0 and cu < MAX_CULTURES and _cul_active[cu] != 0:
		return _cul_name[cu]
	return ""


func get_city_creed_name(cid: int) -> String:
	if cid < 0 or cid >= MAX_CITIES:
		return ""
	var cr: int = _city_creed_id[cid]
	if cr >= 0 and cr < MAX_CREEDS and _creed_active[cr] != 0:
		return _creed_name[cr]
	return ""


func get_city_town_plan(cid: int) -> int:
	var cu: int = get_city_culture_id(cid)
	if cu >= 0 and cu < MAX_CULTURES and _cul_active[cu] != 0:
		return int(_cul_town_plan[cu])
	return 0


func get_kingdom_alliance_id(kid: int) -> int:
	if kid < 0 or kid >= MAX_KINGDOMS:
		return -1
	return _kingdom_alliance_id[kid]


func get_alliance_color(aid: int) -> Color:
	if aid >= 0 and aid < MAX_ALLIANCES and _ally_active[aid] != 0:
		return _ally_color[aid]
	return Color("#48E5B5")


func get_city_army_info(cid: int) -> Dictionary:
	if cid < 0 or cid >= MAX_CITIES:
		return {"strength": 0, "kills": 0, "captain": "", "past_captains": []}
	var past: Array[String] = []
	for p in _army_past_captains[cid]:
		past.append(p)
	return {
		"strength": _army_strength[cid],
		"kills": _army_kills[cid],
		"captain": _army_captain_name[cid],
		"past_captains": past,
	}


func get_kingdom_meta_info(kid: int) -> Dictionary:
	if kid < 0 or kid >= MAX_KINGDOMS:
		return {}
	var aid: int = _kingdom_alliance_id[kid]
	var clid: int = _kingdom_royal_clan[kid]
	var cuid: int = _kingdom_culture_id[kid]
	var crid: int = _kingdom_creed_id[kid]
	var sl: int = int(_cul_succ_law[cuid]) if (cuid >= 0 and cuid < MAX_CULTURES) else 0
	var ctid: int = _clan_trait_id[clid] if (clid >= 0 and clid < MAX_CLANS) else 0
	return {
		"alliance_id": aid,
		"alliance_name": _ally_name[aid] if (aid >= 0 and _ally_active[aid] != 0) else "",
		"clan_id": clid,
		"clan_name": _clan_name[clid] if (clid >= 0 and _clan_active[clid] != 0) else "",
		"clan_trait": CLAN_TRAIT_NAMES_RU[clampi(ctid, 0, CLAN_TRAIT_NAMES_RU.size() - 1)],
		"king_name": _kingdom_king_name[kid],
		"king_intel": _kingdom_king_intel[kid],
		"culture_id": cuid,
		"culture_name": _cul_name[cuid] if (cuid >= 0 and _cul_active[cuid] != 0) else "",
		"creed_id": crid,
		"creed_name": _creed_name[crid] if (crid >= 0 and _creed_active[crid] != 0) else "",
		"succ_law": SUCC_LAW_NAMES_RU[clampi(sl, 0, SUCC_LAW_NAMES_RU.size() - 1)],
	}


func get_plot_name_ru(kind: int) -> String:
	return PLOT_NAMES_RU[clampi(kind, 0, PLOT_NAMES_RU.size() - 1)]


func get_active_clan_count() -> int:
	var n: int = 0
	for i in range(MAX_CLANS):
		if _clan_active[i] != 0:
			n += 1
	return n


func get_active_culture_count() -> int:
	var n: int = 0
	for i in range(MAX_CULTURES):
		if _cul_active[i] != 0:
			n += 1
	return n


func get_active_creed_count() -> int:
	var n: int = 0
	for i in range(MAX_CREEDS):
		if _creed_active[i] != 0:
			n += 1
	return n


func get_active_book_count() -> int:
	var n: int = 0
	for i in range(MAX_BOOKS):
		if _book_active[i] != 0:
			n += 1
	return n


func get_city_book_count(cid: int) -> int:
	var n: int = 0
	for i in range(MAX_BOOKS):
		if _book_active[i] != 0 and _book_city_id[i] == cid:
			n += 1
	return n

