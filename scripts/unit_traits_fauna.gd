extends RefCounted

# Xenofauna, 4 mega-bosses, 36 biochips/traits, 16 statuses, 10-locus genetics,
# 3-slot equipment + trophies, and unit liveliness (mood, fav food, sleep, idle chat).
# Zero class_name, zero preload, zero Node2D allocations, tab-indented only.

const MAX_FAUNA: int = 192
const MAX_SUBSPECIES: int = 16
const LOCUS_COUNT: int = 10
const TRAIT_COUNT: int = 36
const STATUS_COUNT: int = 16
const EQ_SLOTS: int = 3
const MAT_COUNT: int = 6
const RARITY_COUNT: int = 4

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
const TASK_HARVEST: int = 2
const TASK_HAUL_DEPOT: int = 3

const TIER_SHALLOW: int = 2
const TIER_SUMMIT: int = 8
const BIOME_LAVA: int = 4

const FAUNA_UID_BASE: int = 1000001
const FAUNA_ATLAS_START: int = 24
const SPECIES_COUNT: int = 18

const HABITAT_LAND: int = 0
const HABITAT_WATER: int = 1
const HABITAT_AMPHIB: int = 2
const HABITAT_AIR: int = 3

const SCLASS_HERBIVORE: int = 0
const SCLASS_PREDATOR: int = 1
const SCLASS_INSECT: int = 2
const SCLASS_BOSS: int = 3

const BOSS_LEVIATHAN: int = 14
const BOSS_UFO: int = 15
const BOSS_NECROMANCER: int = 16
const BOSS_COLOSSUS: int = 17

const TRAIT_VENGEFUL: int = 0
const TRAIT_SCHISMATIC: int = 1
const TRAIT_ASHBORN: int = 2
const TRAIT_BLESSED_HALO: int = 3
const TRAIT_FERAL_ALPHA: int = 4
const TRAIT_CORE_MELTDOWN: int = 5
const TRAIT_ION_SHIELD: int = 6
const TRAIT_GIGANTISM: int = 7
const TRAIT_TINY: int = 8
const TRAIT_FAST: int = 9
const TRAIT_AGILE: int = 10
const TRAIT_REGENERATOR: int = 11
const TRAIT_PYROMANIAC: int = 12
const TRAIT_CRYO_BLOOD: int = 13
const TRAIT_VAMPIRIC: int = 14
const TRAIT_IMMORTAL_CORE: int = 15
const TRAIT_LUCKY: int = 16
const TRAIT_GENIUS: int = 17
const TRAIT_STRONG: int = 18
const TRAIT_TOUGH: int = 19
const TRAIT_DEFLECTOR: int = 20
const TRAIT_PSYCHIC: int = 21
const TRAIT_ENERGIZED: int = 22
const TRAIT_TOXIC_BLOOD: int = 23
const TRAIT_THORNS: int = 24
const TRAIT_EAGLE_EYE: int = 25
const TRAIT_BERSERK: int = 26
const TRAIT_PACIFIST: int = 27
const TRAIT_RAD_IMMUNE: int = 28
const TRAIT_VOID_HEART: int = 29
const TRAIT_OVERCLOCK: int = 30
const TRAIT_HARD_SHELL: int = 31
const TRAIT_MAGNETIC: int = 32
const TRAIT_VETERAN: int = 33
const TRAIT_PLAGUE_CARRIER: int = 34
const TRAIT_CREATOR_SCAR: int = 35

const STATUS_BURNING: int = 0
const STATUS_POISONED: int = 1
const STATUS_CRYO_STASIS: int = 2
const STATUS_SHIELD: int = 3
const STATUS_RAGE: int = 4
const STATUS_STUNNED: int = 5
const STATUS_INSPIRED: int = 6
const STATUS_ENCHANTED: int = 7
const STATUS_POWERUP: int = 8
const STATUS_SLOWNESS: int = 9
const STATUS_HASTE: int = 10
const STATUS_SLEEPING: int = 11
const STATUS_STARVING: int = 12
const STATUS_CURSED: int = 13
const STATUS_INVINCIBLE: int = 14
const STATUS_MAGNETIZED: int = 15

const STRIP_DODGE: int = 0
const STRIP_BLOCK: int = 1
const STRIP_HAPPY: int = 2
const STRIP_ANGRY: int = 3
const STRIP_FOOD: int = 4
const STRIP_SHIELD: int = 5
const STRIP_LVLUP: int = 6
const STRIP_MUTATE: int = 7
const STRIP_TALK_FOOD: int = 18
const STRIP_TALK_WAR: int = 19
const STRIP_TALK_TECH: int = 20
const STRIP_TALK_FEAR: int = 21
const STRIP_SLEEP_ZZZ: int = 22
const STRIP_LEADER_STAR: int = 28
const STRIP_SCAR_DIVINITY: int = 29
const STRIP_TROPHY_GEAR: int = 30

const TRAIT_NAMES_RU: Array[String] = [
	"Мстительный", "Раскольник", "Пеплорождённый", "Ореол Демиурга", "Альфа-хищник",
	"Перегрузка ядра", "Ион-купол", "Гигантизм", "Микро-корпус", "Ускоритель",
	"Ловкач", "Регенератор", "Пироман", "Крио-кровь", "Вампиризм",
	"Бессмертный кор", "Везунчик", "Гений", "Титан-мускул", "Бронекорпус",
	"Отражатель", "Псионик", "Заряд ядра", "Токсин-кровь", "Шипы экзоскелета",
	"Орлиный сканер", "Берсерк", "Пацифист", "Рад-фильтр", "Сердце пустоты",
	"Разгон ядра", "Хитин-панцирь", "Маг-контур", "Ветеран", "Чумной вектор",
	"Шрам Творца",
]

const STATUS_NAMES_RU: Array[String] = [
	"Горение", "Отравление", "Крио-стазис", "Энергощит",
	"Ярость", "Оглушение", "Вдохновение", "Усиление ИИ",
	"Перегрузка", "Замедление", "Разгон", "Сон",
	"Голод", "Проклятие", "Неуязвимость", "Магнит",
]

const FAV_FOOD_NAMES_RU: Array[String] = [
	"Ксено-гриб", "Гидро-паёк", "Споровый нектар",
	"Белковый брикет", "Солнечный плод", "Крио-ягода",
]

const LOCUS_NAMES_RU: Array[String] = [
	"Живучесть", "Мощь", "Ловкость", "Панцирь", "Интеллект",
	"Плодовитость", "Метаболизм", "Термостойкость", "Криостойкость", "Псионика",
]

const SLOT_NAMES_RU: Array[String] = ["Оружие", "Броня", "Модуль"]
const MAT_NAMES_RU: Array[String] = ["Полимер", "Титан", "Крио-сплав", "Плазмит", "Ксеносталь", "Нейтроний"]
const RARITY_NAMES_RU: Array[String] = ["Обычн.", "Редк.", "Эпич.", "Легенд."]
const MOD_NAMES_RU: Array[String] = ["", "Заряженный", "Укреплённый", "Облегчённый", "Кровавый", "Огненный", "Крио", "Божественный"]
const WEAPON_BASES_RU: Array[String] = ["Карабин", "Импульс-клинок", "Рельсотрон", "Плазма-резак", "Копьё пустоты", "Аннигилятор"]
const ARMOR_BASES_RU: Array[String] = ["Комбинезон", "Экзо-кираса", "Термо-щиток", "Силовой каркас", "Ксено-латы", "Нейтрон-панцирь"]
const MODULE_BASES_RU: Array[String] = ["Сенсор", "Био-фильтр", "Гиро-стаб", "Кванто-чип", "Пси-резонатор", "Грави-ядро"]

# [name_ru, class(0..3), habitat(0..3), hp, spd, dmg, scale, tint]
const SPECIES_DATA: Array = [
	["Ксено-олень", 0, 0, 75.0, 20.0, 4.0, 1.0, Color("#D8B888")],
	["Свето-кролик", 0, 0, 42.0, 24.0, 2.0, 0.85, Color("#EEF2F8")],
	["Рифовый краб", 0, 2, 85.0, 13.0, 6.0, 0.95, Color("#E87250")],
	["Люм-рыба", 0, 1, 48.0, 20.0, 2.0, 0.92, Color("#60DCFF")],
	["Панцирь-черепаха", 0, 2, 135.0, 9.5, 5.0, 1.05, Color("#78BE7E")],
	["Ксено-ягнёнок", 0, 0, 65.0, 16.0, 3.0, 0.96, Color("#F2ECE2")],
	["Инеевый волк", 1, 0, 130.0, 25.0, 17.0, 1.08, Color("#B4CDE0")],
	["Бронемедведь", 1, 0, 220.0, 16.5, 24.0, 1.26, Color("#A48A74")],
	["Ксено-раптор", 1, 0, 145.0, 29.0, 20.0, 1.12, Color("#D66858")],
	["Болотный кроко", 1, 2, 175.0, 18.0, 21.0, 1.18, Color("#6EA864")],
	["Дюнный скорпион", 1, 0, 125.0, 22.0, 16.0, 1.05, Color("#E2AE48")],
	["Био-пчела", 2, 3, 24.0, 26.0, 2.0, 0.78, Color("#FFE055")],
	["Жук-скарабей", 2, 0, 28.0, 22.0, 2.0, 0.78, Color("#62D8B8")],
	["Ион-светляк", 2, 3, 22.0, 20.0, 1.0, 0.80, Color("#72F8FF")],
	["Ксено-Левиафан", 3, 3, 950.0, 28.0, 36.0, 1.95, Color("#FF7442")],
	["Орбитальный НЛО", 3, 3, 750.0, 32.0, 30.0, 1.85, Color("#62EEFF")],
	["Техно-Некромант", 3, 0, 600.0, 17.0, 26.0, 1.45, Color("#C662FF")],
	["Кибер-Колосс", 3, 2, 1400.0, 15.5, 48.0, 2.15, Color("#F04E4E")],
]

# Per-unit extended data (indexed by unit slot 0..unit_count-1)
var _u_status_timers: PackedFloat32Array = PackedFloat32Array()
var _u_custom_name: PackedStringArray = PackedStringArray()
var _u_fav_food: PackedByteArray = PackedByteArray()
var _u_mood: PackedFloat32Array = PackedFloat32Array()
var _u_sleep_timer: PackedFloat32Array = PackedFloat32Array()
var _u_talk_cd: PackedFloat32Array = PackedFloat32Array()
var _u_eq_packed: PackedInt32Array = PackedInt32Array()
var _u_eq_kills: PackedInt32Array = PackedInt32Array()
var _u_eq_name: PackedStringArray = PackedStringArray()
var _u_subspecies_id: PackedByteArray = PackedByteArray()
var _u_immortal_cd: PackedFloat32Array = PackedFloat32Array()

# Subspecies & genetics (16 subspecies x 10 loci)
var _sub_active: PackedByteArray = PackedByteArray()
var _sub_faction: PackedByteArray = PackedByteArray()
var _sub_species: PackedInt32Array = PackedInt32Array()
var _sub_name: PackedStringArray = PackedStringArray()
var _sub_genes: PackedByteArray = PackedByteArray()
var _sub_count: int = 4

# Xenofauna & 4 mega-bosses SoA pool (up to MAX_FAUNA = 192)
var _f_count: int = 0
var _f_uid: PackedInt32Array = PackedInt32Array()
var _f_species: PackedByteArray = PackedByteArray()
var _f_px: PackedFloat32Array = PackedFloat32Array()
var _f_py: PackedFloat32Array = PackedFloat32Array()
var _f_pz: PackedFloat32Array = PackedFloat32Array()
var _f_vx: PackedFloat32Array = PackedFloat32Array()
var _f_vy: PackedFloat32Array = PackedFloat32Array()
var _f_vz: PackedFloat32Array = PackedFloat32Array()
var _f_hp: PackedFloat32Array = PackedFloat32Array()
var _f_max_hp: PackedFloat32Array = PackedFloat32Array()
var _f_phase: PackedFloat32Array = PackedFloat32Array()
var _f_facing: PackedFloat32Array = PackedFloat32Array()
var _f_kb: PackedFloat32Array = PackedFloat32Array()
var _f_flash: PackedFloat32Array = PackedFloat32Array()
var _f_atk_cd: PackedFloat32Array = PackedFloat32Array()
var _f_ai_cd: PackedFloat32Array = PackedFloat32Array()
var _f_wander: PackedFloat32Array = PackedFloat32Array()
var _f_tgt_uid: PackedInt32Array = PackedInt32Array()
var _f_tgt_is_fauna: PackedByteArray = PackedByteArray()
var _f_trait_mask: PackedInt64Array = PackedInt64Array()
var _f_status_mask: PackedInt32Array = PackedInt32Array()
var _f_tint: PackedColorArray = PackedColorArray()
var _f_custom_name: PackedStringArray = PackedStringArray()
var _f_kills: PackedInt32Array = PackedInt32Array()
var _f_scale: PackedFloat32Array = PackedFloat32Array()
var _f_squash: PackedFloat32Array = PackedFloat32Array()
var _f_squash_v: PackedFloat32Array = PackedFloat32Array()
var _f_last_attacker_uid: PackedInt32Array = PackedInt32Array()
var _hostile_fauna_indices: PackedInt32Array = PackedInt32Array()
var _f_uid_to_idx: Dictionary = {}
var _next_fauna_uid: int = FAUNA_UID_BASE
var _last_unit_cnt_mm: int = -1
var _any_ext_active: bool = false


func _init() -> void:
	_init_subspecies_defaults()
	_allocate_fauna_arrays()


func reset_all() -> void:
	_f_count = 0
	_f_uid_to_idx.clear()
	_hostile_fauna_indices.resize(0)
	_next_fauna_uid = FAUNA_UID_BASE
	_last_unit_cnt_mm = -1
	_any_ext_active = false
	_init_subspecies_defaults()


func _init_subspecies_defaults() -> void:
	_sub_active.resize(MAX_SUBSPECIES)
	_sub_active.fill(0)
	_sub_faction.resize(MAX_SUBSPECIES)
	_sub_faction.fill(0)
	_sub_species.resize(MAX_SUBSPECIES)
	_sub_species.fill(-1)
	_sub_name.resize(MAX_SUBSPECIES)
	_sub_genes.resize(MAX_SUBSPECIES * LOCUS_COUNT)
	_sub_genes.fill(2)
	var base_names := ["Человек Кеплера", "Синт-Шасси", "Споро-Симбионт", "Кристалл-Мутант"]
	var base_genes := [
		[2, 2, 2, 2, 3, 3, 2, 2, 2, 2],
		[3, 3, 1, 4, 3, 1, 0, 3, 3, 1],
		[2, 2, 3, 1, 2, 4, 3, 1, 2, 3],
		[4, 4, 3, 3, 1, 1, 2, 3, 3, 3],
	]
	for s in range(4):
		_sub_active[s] = 1
		_sub_faction[s] = s
		_sub_name[s] = base_names[s]
		var g_off := s * LOCUS_COUNT
		for l in range(LOCUS_COUNT):
			_sub_genes[g_off + l] = base_genes[s][l]
	_sub_count = 4


func _allocate_fauna_arrays() -> void:
	_f_uid.resize(MAX_FAUNA)
	_f_species.resize(MAX_FAUNA)
	_f_px.resize(MAX_FAUNA)
	_f_py.resize(MAX_FAUNA)
	_f_pz.resize(MAX_FAUNA)
	_f_vx.resize(MAX_FAUNA)
	_f_vy.resize(MAX_FAUNA)
	_f_vz.resize(MAX_FAUNA)
	_f_hp.resize(MAX_FAUNA)
	_f_max_hp.resize(MAX_FAUNA)
	_f_phase.resize(MAX_FAUNA)
	_f_facing.resize(MAX_FAUNA)
	_f_kb.resize(MAX_FAUNA)
	_f_flash.resize(MAX_FAUNA)
	_f_atk_cd.resize(MAX_FAUNA)
	_f_ai_cd.resize(MAX_FAUNA)
	_f_wander.resize(MAX_FAUNA)
	_f_tgt_uid.resize(MAX_FAUNA)
	_f_tgt_is_fauna.resize(MAX_FAUNA)
	_f_trait_mask.resize(MAX_FAUNA)
	_f_status_mask.resize(MAX_FAUNA)
	_f_tint.resize(MAX_FAUNA)
	_f_custom_name.resize(MAX_FAUNA)
	_f_kills.resize(MAX_FAUNA)
	_f_scale.resize(MAX_FAUNA)
	_f_squash.resize(MAX_FAUNA)
	_f_squash.fill(1.0)
	_f_squash_v.resize(MAX_FAUNA)
	_f_squash_v.fill(0.0)
	_f_last_attacker_uid.resize(MAX_FAUNA)
	_f_last_attacker_uid.fill(-1)


func resize_unit_ext(count: int) -> void:
	_u_status_timers.resize(count * STATUS_COUNT)
	_u_custom_name.resize(count)
	_u_fav_food.resize(count)
	_u_mood.resize(count)
	_u_sleep_timer.resize(count)
	_u_talk_cd.resize(count)
	_u_eq_packed.resize(count * EQ_SLOTS)
	_u_eq_kills.resize(count * EQ_SLOTS)
	_u_eq_name.resize(count * EQ_SLOTS)
	_u_subspecies_id.resize(count)
	_u_immortal_cd.resize(count)


func copy_unit_ext_slot(src: int, dst: int) -> void:
	var sb := src * STATUS_COUNT
	var db := dst * STATUS_COUNT
	for s in range(STATUS_COUNT):
		_u_status_timers[db + s] = _u_status_timers[sb + s]
	_u_custom_name[dst] = _u_custom_name[src]
	_u_fav_food[dst] = _u_fav_food[src]
	_u_mood[dst] = _u_mood[src]
	_u_sleep_timer[dst] = _u_sleep_timer[src]
	_u_talk_cd[dst] = _u_talk_cd[src]
	var es := src * EQ_SLOTS
	var ed := dst * EQ_SLOTS
	for k in range(EQ_SLOTS):
		_u_eq_packed[ed + k] = _u_eq_packed[es + k]
		_u_eq_kills[ed + k] = _u_eq_kills[es + k]
		_u_eq_name[ed + k] = _u_eq_name[es + k]
	_u_subspecies_id[dst] = _u_subspecies_id[src]
	_u_immortal_cd[dst] = _u_immortal_cd[src]


func init_unit_ext_slot(up: Node2D, idx: int, fac: int, role: int) -> void:
	var rng: RandomNumberGenerator = up._ext_rng
	var sb := idx * STATUS_COUNT
	for s in range(STATUS_COUNT):
		_u_status_timers[sb + s] = 0.0
	_u_custom_name[idx] = ""
	_u_fav_food[idx] = rng.randi_range(0, FAV_FOOD_NAMES_RU.size() - 1)
	_u_mood[idx] = float(rng.randi_range(62, 78))
	_u_sleep_timer[idx] = -rng.randf_range(0.0, 14.0)
	_u_talk_cd[idx] = rng.randf_range(1.5, 6.0)
	_u_subspecies_id[idx] = clampi(fac, 0, 3) if fac <= FACTION_MUTANT else 0
	_u_immortal_cd[idx] = 0.0
	var eb := idx * EQ_SLOTS
	for k in range(EQ_SLOTS):
		_u_eq_packed[eb + k] = 0
		_u_eq_kills[eb + k] = 0
		_u_eq_name[eb + k] = ""
	if role == ROLE_SOLDIER:
		var mat := 1 if fac == FACTION_ROBOT else 0
		_u_eq_packed[eb] = _pack_item(mat, 0, 0)
		_u_eq_name[eb] = _make_item_name(0, mat, 0, 0, rng)
	up._u_pos_z[idx] = 0.0
	up._u_vel_z[idx] = 0.0
	up._u_trait_mask[idx] = 0
	up._u_status_mask[idx] = 0
	recompute_unit_cached_stats(up, idx)


func _pack_item(mat: int, rarity: int, mod_id: int) -> int:
	return (1 << 11) | (clampi(mat, 0, 5) & 7) | ((clampi(rarity, 0, 3) & 3) << 3) | ((clampi(mod_id, 0, 7) & 7) << 5)


func _item_power(packed: int) -> int:
	if packed == 0:
		return 0
	var mat := packed & 7
	var rar := (packed >> 3) & 3
	var mod_id := (packed >> 5) & 7
	return 10 + mat * 8 + rar * 7 + (4 if mod_id > 0 else 0)


func _make_item_name(slot: int, mat: int, rar: int, mod_id: int, rng: RandomNumberGenerator) -> String:
	var base_pool: Array = WEAPON_BASES_RU if slot == 0 else (ARMOR_BASES_RU if slot == 1 else MODULE_BASES_RU)
	var base_s: String = str(base_pool[clampi(mat, 0, base_pool.size() - 1)])
	var mat_s: String = str(MAT_NAMES_RU[clampi(mat, 0, MAT_NAMES_RU.size() - 1)])
	var mod_s: String = str(MOD_NAMES_RU[clampi(mod_id, 0, MOD_NAMES_RU.size() - 1)])
	if rar >= 3:
		var suffixes: Array[String] = ["Зари", "Кеплера", "Пустоты", "Ориона", "Титана", "Горизонта"]
		var suf: String = suffixes[rng.randi_range(0, suffixes.size() - 1)]
		return "%s %s «%s»" % [mod_s if mod_s != "" else mat_s, base_s, suf]
	if mod_s != "":
		return "%s %s (%s)" % [mod_s, base_s, mat_s]
	return "%s (%s)" % [base_s, mat_s]


func recompute_unit_cached_stats(up: Node2D, idx: int) -> void:
	if idx < 0 or idx >= up._unit_count:
		return
	var tmask: int = up._u_trait_mask[idx]
	var smask: int = up._u_status_mask[idx]
	var dmg_m: float = 1.0
	var spd_m: float = 1.0
	var arm_m: float = 1.0
	var hp_b: float = 0.0
	var dodge_b: float = 0.0
	var crit_p: float = 0.05

	var g_res := _eval_trait_stats(tmask)
	dmg_m += g_res.x
	spd_m += g_res.y
	hp_b += g_res.z
	arm_m -= g_res.w

	if (tmask & (1 << TRAIT_LUCKY)) != 0:
		crit_p += 0.18
		dodge_b += 0.08
	if (tmask & (1 << TRAIT_AGILE)) != 0:
		dodge_b += 0.14
	if (tmask & (1 << TRAIT_GIGANTISM)) != 0 or (tmask & (1 << TRAIT_TINY)) != 0:
		up._any_scale_traits = true
	if (tmask & (1 << TRAIT_TINY)) != 0:
		dodge_b += 0.12
	if (tmask & (1 << TRAIT_EAGLE_EYE)) != 0:
		crit_p += 0.12
	if (tmask & (1 << TRAIT_BLESSED_HALO)) != 0:
		crit_p += 0.10

	var eb := idx * EQ_SLOTS
	if eb + 2 < _u_eq_packed.size():
		var eq_res := _eval_eq_stats(_u_eq_packed[eb], _u_eq_packed[eb + 1], _u_eq_packed[eb + 2])
		dmg_m += eq_res.x
		spd_m += eq_res.y
		hp_b += eq_res.z
		arm_m -= eq_res.w

	var sub_id := int(_u_subspecies_id[idx]) if idx < _u_subspecies_id.size() else 0
	if sub_id >= 4 and sub_id < MAX_SUBSPECIES and _sub_active[sub_id] != 0:
		var g_off := sub_id * LOCUS_COUNT
		hp_b += float(int(_sub_genes[g_off + 0]) - 2) * 8.0
		dmg_m += float(int(_sub_genes[g_off + 1]) - 2) * 0.08
		spd_m += float(int(_sub_genes[g_off + 2]) - 2) * 0.06
		arm_m -= float(int(_sub_genes[g_off + 3]) - 2) * 0.04
		crit_p += float(maxi(0, int(_sub_genes[g_off + 4]) - 2)) * 0.03

	if smask != 0:
		if (smask & (1 << STATUS_RAGE)) != 0:
			dmg_m += 0.35
			spd_m += 0.20
		if (smask & (1 << STATUS_INSPIRED)) != 0:
			dmg_m += 0.25
		if (smask & (1 << STATUS_ENCHANTED)) != 0:
			dmg_m += 0.30
			spd_m += 0.15
			crit_p += 0.10
		if (smask & (1 << STATUS_POWERUP)) != 0:
			dmg_m += 0.40
			arm_m -= 0.20
		if (smask & (1 << STATUS_SLOWNESS)) != 0:
			spd_m -= 0.45
		if (smask & (1 << STATUS_HASTE)) != 0:
			spd_m += 0.45
		if (smask & (1 << STATUS_STARVING)) != 0:
			spd_m -= 0.25
		if (smask & (1 << STATUS_CURSED)) != 0:
			dmg_m -= 0.30
			spd_m -= 0.20
		if (smask & (1 << STATUS_SHIELD)) != 0:
			arm_m *= 0.20

	up._u_dmg_mul[idx] = clampf(dmg_m, 0.25, 4.5)
	up._u_spd_mul[idx] = clampf(spd_m, 0.25, 3.0)
	up._u_hp_bonus[idx] = clampf(hp_b, -50.0, 400.0)
	up._u_armor_mul[idx] = clampf(arm_m, 0.15, 1.5)
	up._u_dodge_bonus[idx] = clampf(dodge_b, 0.0, 0.45)
	up._u_crit_chance[idx] = clampf(crit_p, 0.0, 0.65)
	up._u_cp_key[idx] = -1
	var max_hp: float = float(up.get_unit_max_hp(idx))
	if up._hp[idx] > max_hp:
		up._hp[idx] = max_hp


func _eval_trait_stats(tmask: int) -> Vector4:
	if tmask == 0:
		return Vector4.ZERO
	var dmg := 0.0
	var spd := 0.0
	var hp := 0.0
	var arm := 0.0
	if (tmask & (1 << TRAIT_VENGEFUL)) != 0:
		dmg += 0.18
	if (tmask & (1 << TRAIT_SCHISMATIC)) != 0:
		spd += 0.10
	if (tmask & (1 << TRAIT_ASHBORN)) != 0:
		hp += 20.0
	if (tmask & (1 << TRAIT_BLESSED_HALO)) != 0:
		dmg += 0.25
		spd += 0.15
		hp += 35.0
	if (tmask & (1 << TRAIT_FERAL_ALPHA)) != 0:
		dmg += 0.30
		spd += 0.12
		hp += 40.0
	if (tmask & (1 << TRAIT_GIGANTISM)) != 0:
		dmg += 0.30
		spd -= 0.18
		hp += 65.0
	if (tmask & (1 << TRAIT_TINY)) != 0:
		spd += 0.25
		hp -= 25.0
	if (tmask & (1 << TRAIT_FAST)) != 0:
		spd += 0.30
	if (tmask & (1 << TRAIT_AGILE)) != 0:
		spd += 0.15
	if (tmask & (1 << TRAIT_IMMORTAL_CORE)) != 0:
		hp += 80.0
	if (tmask & (1 << TRAIT_STRONG)) != 0:
		dmg += 0.35
	if (tmask & (1 << TRAIT_TOUGH)) != 0:
		hp += 30.0
		arm += 0.22
	if (tmask & (1 << TRAIT_ENERGIZED)) != 0:
		spd += 0.45
	if (tmask & (1 << TRAIT_BERSERK)) != 0:
		dmg += 0.25
		spd += 0.12
	if (tmask & (1 << TRAIT_PACIFIST)) != 0:
		dmg -= 0.40
	if (tmask & (1 << TRAIT_VOID_HEART)) != 0:
		dmg += 0.22
	if (tmask & (1 << TRAIT_OVERCLOCK)) != 0:
		spd += 0.15
	if (tmask & (1 << TRAIT_HARD_SHELL)) != 0:
		hp += 25.0
		arm += 0.16
	if (tmask & (1 << TRAIT_VETERAN)) != 0:
		dmg += 0.20
		hp += 25.0
	if (tmask & (1 << TRAIT_PLAGUE_CARRIER)) != 0:
		dmg -= 0.20
		spd -= 0.15
	return Vector4(dmg, spd, hp, arm)


func _eval_eq_stats(w: int, a: int, m: int) -> Vector4:
	var dmg := 0.0
	var spd := 0.0
	var hp := 0.0
	var arm := 0.0
	if w != 0:
		var wm := w & 7
		var wr := (w >> 3) & 3
		var wmod := (w >> 5) & 7
		dmg += 0.10 + float(wm) * 0.09 + float(wr) * 0.08 + (0.12 if wmod == 1 else 0.0)
	if a != 0:
		var am := a & 7
		var ar := (a >> 3) & 3
		var amod := (a >> 5) & 7
		hp += 12.0 + float(am) * 10.0 + float(ar) * 8.0
		arm += 0.04 + float(am) * 0.04 + (0.08 if amod == 2 else 0.0)
	if m != 0:
		var mm := m & 7
		var mr := (m >> 3) & 3
		var mmod := (m >> 5) & 7
		spd += 0.04 + float(mm) * 0.03 + (0.10 if mmod == 3 else 0.0)
		dmg += float(mr) * 0.05
		hp += float(mm) * 4.0
	return Vector4(dmg, spd, hp, arm)


func apply_status(up: Node2D, idx: int, status_id: int, duration: float) -> void:
	if idx < 0 or idx >= up._unit_count or status_id < 0 or status_id >= STATUS_COUNT:
		return
	var tmask: int = int(up._u_trait_mask[idx])
	if status_id == STATUS_CRYO_STASIS and ((tmask & (1 << TRAIT_CRYO_BLOOD)) != 0 or (up._u_status_mask[idx] & (1 << STATUS_SHIELD)) != 0):
		return
	if status_id == STATUS_BURNING and ((tmask & (1 << TRAIT_PYROMANIAC)) != 0 or (tmask & (1 << TRAIT_ASHBORN)) != 0):
		return
	if status_id == STATUS_STUNNED and (tmask & (1 << TRAIT_TOUGH)) != 0:
		return
	var slot: int = idx * STATUS_COUNT + status_id
	if slot >= _u_status_timers.size():
		return
	_u_status_timers[slot] = maxf(_u_status_timers[slot], duration)
	var old_m: int = int(up._u_status_mask[idx])
	var new_m: int = old_m | (1 << status_id)
	if status_id == STATUS_HASTE:
		new_m &= ~(1 << STATUS_CRYO_STASIS)
		_u_status_timers[idx * STATUS_COUNT + STATUS_CRYO_STASIS] = 0.0
	up._u_status_mask[idx] = new_m
	_any_ext_active = true
	if status_id == STATUS_CRYO_STASIS or status_id == STATUS_SLEEPING:
		up._any_unit_frozen = true
	if status_id == STATUS_SLEEPING:
		_u_sleep_timer[idx] = duration
	elif status_id == STATUS_BURNING:
		up._u_fire_now[idx] = maxf(up._u_fire_now[idx], minf(duration, 1.5))
		up._u_has_status[idx] = 1
	elif status_id == STATUS_INVINCIBLE:
		up._u_invuln_timer[idx] = maxf(up._u_invuln_timer[idx], duration)
		up._u_has_status[idx] = 1
	if old_m != new_m:
		recompute_unit_cached_stats(up, idx)


func clear_status(up: Node2D, idx: int, status_id: int) -> void:
	if idx < 0 or idx >= up._unit_count or status_id < 0 or status_id >= STATUS_COUNT:
		return
	var slot: int = idx * STATUS_COUNT + status_id
	if slot < _u_status_timers.size():
		_u_status_timers[slot] = 0.0
	var old_m: int = int(up._u_status_mask[idx])
	var new_m: int = old_m & ~(1 << status_id)
	up._u_status_mask[idx] = new_m
	if old_m != new_m:
		recompute_unit_cached_stats(up, idx)


func step_unit_statuses_and_traits(up: Node2D, n: int, safe_dt: float) -> void:
	var tick: int = int(up._tick_idx)
	if (tick & 3) != 0:
		return
	if (tick & 63) == 16:
		_sync_notable_traits_from_civ(up)
	if not _any_ext_active:
		return
	var dt4: float = safe_dt * 4.0
	var st_masks: PackedInt32Array = up._u_status_mask
	var tr_masks: PackedInt64Array = up._u_trait_mask
	var hp_arr: PackedFloat32Array = up._hp
	var rng: RandomNumberGenerator = up._ext_rng
	var still_any: bool = false
	var any_frozen: bool = false
	var freeze_bits: int = (1 << STATUS_CRYO_STASIS) | (1 << STATUS_SLEEPING)
	var imm_sz: int = _u_immortal_cd.size()

	for i in range(n):
		if up._u_step_alive[i] == 0:
			continue
		var sm: int = st_masks[i]
		var tm: int = tr_masks[i]
		var has_imm: bool = i < imm_sz and _u_immortal_cd[i] > 0.0
		if sm == 0 and tm == 0 and not has_imm:
			continue
		still_any = true
		if has_imm:
			_u_immortal_cd[i] = maxf(0.0, _u_immortal_cd[i] - dt4)
		if sm != 0:
			_tick_single_unit_statuses(up, i, sm, dt4)
			if (st_masks[i] & freeze_bits) != 0:
				any_frozen = true
		if tm != 0:
			if (tm & (1 << TRAIT_REGENERATOR)) != 0:
				var mhp: float = float(up.get_unit_max_hp(i))
				if hp_arr[i] > 0.0 and hp_arr[i] < mhp:
					hp_arr[i] = minf(mhp, hp_arr[i] + 5.5 * dt4)
			if ((i + (tick >> 2)) & 3) == 0:
				if (tm & (1 << TRAIT_PYROMANIAC)) != 0 and rng.randf() < 0.14 and up._fx != null:
					up._fx.emit_campfire_ember(Vector2(up._px[i], up._py[i] - 2.0), Vector2.ZERO, Color(1.0, 0.52, 0.14, 0.9))
				if (tm & (1 << TRAIT_PLAGUE_CARRIER)) != 0 and rng.randf() < 0.22:
					_spread_plague_aura(up, i)
	_any_ext_active = still_any
	up._any_unit_frozen = any_frozen


func _tick_single_unit_statuses(up: Node2D, i: int, sm: int, safe_dt: float) -> void:
	var sb: int = i * STATUS_COUNT
	var expired: bool = false
	for s in range(STATUS_COUNT):
		if (sm & (1 << s)) == 0:
			continue
		if s == STATUS_MAGNETIZED:
			continue
		var t: float = _u_status_timers[sb + s] - safe_dt
		if t <= 0.0:
			_u_status_timers[sb + s] = 0.0
			sm &= ~(1 << s)
			expired = true
			continue
		_u_status_timers[sb + s] = t
		if s == STATUS_POISONED and (up._u_status_mask[i] & (1 << STATUS_INVINCIBLE)) == 0:
			up._hp[i] -= 3.5 * safe_dt
		elif s == STATUS_CURSED and (up._u_status_mask[i] & (1 << STATUS_INVINCIBLE)) == 0:
			up._hp[i] -= 1.2 * safe_dt
		elif s == STATUS_SLEEPING:
			var mhp: float = float(up.get_unit_max_hp(i))
			up._hp[i] = minf(mhp, up._hp[i] + 3.0 * safe_dt)
			_u_mood[i] = minf(100.0, _u_mood[i] + 2.5 * safe_dt)
			if up._fx != null and up._zoom_lod_val > 1.85 and up._strip_fx_budget > 0 and ((i + up._tick_idx) & 31) == 0:
				up._strip_fx_budget -= 1
				if up._fx.has_method("spawn_reaction_strip"):
					up._fx.call("spawn_reaction_strip", Vector2(up._px[i], up._py[i] - 7.0), STRIP_SLEEP_ZZZ)
	up._u_status_mask[i] = sm
	if expired:
		recompute_unit_cached_stats(up, i)
	if up._hp[i] <= 0.0:
		up._u_step_alive[i] = 0
		up._cur_any_died = true


func _spread_plague_aura(up: Node2D, src_idx: int) -> void:
	var sx: float = float(up._px[src_idx])
	var sy: float = float(up._py[src_idx])
	var cx: int = clampi(int(sx) >> 4, 0, int(up._grid_w) - 1)
	var cy: int = clampi(int(sy) >> 4, 0, int(up._grid_h) - 1)
	var j: int = int(up._cell_head[cy * int(up._grid_w) + cx])
	while j != -1:
		if j != src_idx and up._hp[j] > 0.0 and int(up._u_faction_id[j]) != FACTION_ROBOT:
			if (up._u_trait_mask[j] & (1 << TRAIT_PLAGUE_CARRIER)) == 0 and (up._u_trait_mask[j] & (1 << TRAIT_RAD_IMMUNE)) == 0:
				var dx: float = float(up._px[j]) - sx
				var dy: float = float(up._py[j]) - sy
				if dx * dx + dy * dy <= 100.0:
					apply_status(up, j, STATUS_POISONED, 4.0)
					break
		j = up._unit_next[j]


func _sync_notable_traits_from_civ(up: Node2D) -> void:
	if up._civ == null or not up._civ.has_method("get_notables_summary"):
		return
	var raw: Variant = up._civ.call("get_notables_summary")
	if not (raw is Array):
		return
	var uid_map: Dictionary = up._uid_to_idx
	for item in raw:
		if not (item is Dictionary):
			continue
		var d: Dictionary = item
		var uid := int(d.get("uid", -1))
		if not uid_map.has(uid):
			continue
		var idx := int(uid_map[uid])
		if idx < 0 or idx >= up._unit_count:
			continue
		var tr_bits: int = int(d.get("traits", 0)) & 31
		var cur: int = int(up._u_trait_mask[idx])
		if (cur & tr_bits) != tr_bits:
			up._u_trait_mask[idx] = cur | tr_bits
			_any_ext_active = true
			var eb: int = idx * EQ_SLOTS
			if eb < _u_eq_packed.size() and _u_eq_packed[eb] == 0:
				var mat: int = clampi(1 + int(d.get("rank", 0)), 1, 4)
				_u_eq_packed[eb] = _pack_item(mat, 1, 1)
				_u_eq_name[eb] = _make_item_name(0, mat, 1, 1, up._ext_rng)
			recompute_unit_cached_stats(up, idx)


func step_liveliness_slice(up: Node2D, n: int, safe_dt: float) -> void:
	if n <= 0 or float(up._sim_pace_mult) >= 12.0:
		return
	var tick: int = int(up._tick_idx)
	var rng: RandomNumberGenerator = up._ext_rng
	var step_dt: float = safe_dt * 8.0
	var show_fx: bool = up._fx != null and float(up._zoom_lod_val) > 1.85 and bool(up._fx.has_method("spawn_reaction_strip"))

	for i in range(tick & 7, n, 8):
		if up._u_step_alive[i] != 1:
			continue
		if _u_talk_cd[i] > 0.0:
			_u_talk_cd[i] = maxf(0.0, _u_talk_cd[i] - step_dt)
		if _u_sleep_timer[i] > -30.0 and (up._u_status_mask[i] & (1 << STATUS_SLEEPING)) == 0:
			_u_sleep_timer[i] -= step_dt
		if int(up._u_alert_layer[i]) != 0 or up._u_in_regiment[i] != 0:
			continue
		if (up._u_status_mask[i] & ((1 << STATUS_SLEEPING) | (1 << STATUS_CRYO_STASIS))) != 0:
			continue

		var cid: int = int(up._u_city_id[i])
		var busy_builder: bool = (int(up._u_role[i]) == ROLE_BUILDER and cid >= 0 and cid < up._city_build_pos.size() and up._city_build_pos[cid].x >= 0.0 and up._city_build_pos[cid].distance_squared_to(up._u_depot_pos[i]) > 1.0)
		if cid >= 0 and not busy_builder and int(up._u_task[i]) != TASK_HARVEST and _u_sleep_timer[i] <= -22.0 and up._is_near_building(Vector2(up._px[i], up._py[i])):
			apply_status(up, i, STATUS_SLEEPING, rng.randf_range(4.0, 6.5))
			continue

		if _u_talk_cd[i] <= 0.0 and rng.randf() < 0.14:
			var partner: int = _find_social_partner(up, i)
			if partner >= 0:
				_u_talk_cd[i] = rng.randf_range(10.0, 18.0)
				_u_talk_cd[partner] = rng.randf_range(10.0, 18.0)
				_u_mood[i] = minf(100.0, _u_mood[i] + 4.0)
				_u_mood[partner] = minf(100.0, _u_mood[partner] + 4.0)
				up._facing[i] = 1.0 if up._px[partner] >= up._px[i] else -1.0
				up._facing[partner] = -up._facing[i]
				if show_fx and up._strip_fx_budget > 0:
					up._strip_fx_budget -= 1
					var topic: int = _pick_chat_topic(up, i)
					up._fx.call("spawn_reaction_strip", Vector2(up._px[i], up._py[i] - 7.5), topic)


func _find_social_partner(up: Node2D, idx: int) -> int:
	var px_f: float = float(up._px[idx])
	var py_f: float = float(up._py[idx])
	var cx: int = clampi(int(px_f) >> 4, 0, int(up._grid_w) - 1)
	var cy: int = clampi(int(py_f) >> 4, 0, int(up._grid_h) - 1)
	var j: int = int(up._cell_head[cy * int(up._grid_w) + cx])
	while j != -1:
		if j != idx and up._hp[j] > 0.0 and int(up._u_alert_layer[j]) == 0 and _u_talk_cd[j] <= 0.0:
			var dx: float = float(up._px[j]) - px_f
			var dy: float = float(up._py[j]) - py_f
			if dx * dx + dy * dy <= 100.0 and not up._are_units_hostile(idx, j):
				return j
		j = up._unit_next[j]
	return -1


func _pick_chat_topic(up: Node2D, idx: int) -> int:
	var cid: int = int(up._u_city_id[idx])
	if cid >= 0 and cid < up._city_hunger_cache.size() and up._city_hunger_cache[cid] >= 0.4:
		return STRIP_TALK_FOOD
	if (up._u_step_flags[idx] & up.ST_WAR) != 0:
		return STRIP_TALK_WAR
	if up._u_rad_now[idx] > 0.12 or up._hp[idx] < 55.0:
		return STRIP_TALK_FEAR
	var r: int = int(up._u_role[idx])
	if r == ROLE_MINER or r == ROLE_BUILDER or int(up._u_faction_id[idx]) == FACTION_ROBOT:
		return STRIP_TALK_TECH
	return STRIP_TALK_FOOD


func on_food_eaten(up: Node2D, idx: int, food_kind: int, base_amt: float) -> float:
	if idx < 0 or idx >= up._unit_count:
		return base_amt
	var fav: int = int(_u_fav_food[idx])
	var is_fav: bool = (food_kind == fav) or (food_kind < 0 and up._ext_rng.randf() < 0.25)
	var mult: float = 2.0 if is_fav else 1.0
	var mhp: float = float(up.get_unit_max_hp(idx))
	up._hp[idx] = minf(mhp, up._hp[idx] + 8.0 * mult)
	_u_mood[idx] = minf(100.0, _u_mood[idx] + 7.0 * mult)
	clear_status(up, idx, STATUS_STARVING)
	if is_fav and up._fx != null and up._zoom_lod_val > 1.85 and up._strip_fx_budget > 0 and up._fx.has_method("spawn_reaction_strip"):
		up._strip_fx_budget -= 1
		up._fx.call("spawn_reaction_strip", Vector2(up._px[idx], up._py[idx] - 7.5), STRIP_HAPPY)
	return base_amt * mult


func on_unit_killed_hooks(up: Node2D, attacker: int, victim: int) -> void:
	if attacker >= 0 and attacker < up._unit_count:
		var ae := attacker * EQ_SLOTS
		if ae < _u_eq_packed.size() and _u_eq_packed[ae] != 0:
			_u_eq_kills[ae] += 1
		if up._u_kills[attacker] >= 3 and (up._u_trait_mask[attacker] & (1 << TRAIT_VETERAN)) == 0:
			up._u_trait_mask[attacker] |= (1 << TRAIT_VETERAN)
			_any_ext_active = true
			recompute_unit_cached_stats(up, attacker)
		_u_mood[attacker] = minf(100.0, _u_mood[attacker] + 8.0)
		if victim >= 0 and victim < up._unit_count:
			_loot_better_gear(up, attacker, victim)


func _loot_better_gear(up: Node2D, winner: int, loser: int) -> void:
	var we := winner * EQ_SLOTS
	var le := loser * EQ_SLOTS
	if we + 2 >= _u_eq_packed.size() or le + 2 >= _u_eq_packed.size():
		return
	var took := false
	for s in range(EQ_SLOTS):
		var l_item := _u_eq_packed[le + s]
		if l_item == 0:
			continue
		if _item_power(l_item) > _item_power(_u_eq_packed[we + s]):
			_u_eq_packed[we + s] = l_item
			_u_eq_kills[we + s] = _u_eq_kills[le + s]
			_u_eq_name[we + s] = _u_eq_name[le + s]
			_u_eq_packed[le + s] = 0
			took = true
	if took:
		recompute_unit_cached_stats(up, winner)
		if up._fx != null and up._zoom_lod_val > 1.85 and up._strip_fx_budget > 0 and up._fx.has_method("spawn_reaction_strip"):
			up._strip_fx_budget -= 1
			up._fx.call("spawn_reaction_strip", Vector2(up._px[winner], up._py[winner] - 7.5), STRIP_TROPHY_GEAR)


func handle_unit_death_traits(up: Node2D, idx: int) -> bool:
	var tm: int = int(up._u_trait_mask[idx])
	var pos := Vector2(up._px[idx], up._py[idx])
	if (tm & (1 << TRAIT_IMMORTAL_CORE)) != 0 and _u_immortal_cd[idx] <= 0.0:
		_u_immortal_cd[idx] = 28.0
		up._hp[idx] = float(up.get_unit_max_hp(idx)) * 0.45
		apply_status(up, idx, STATUS_SHIELD, 4.0)
		up._hit_flash_timer[idx] = 0.30
		if up._fx != null:
			up._fx.spawn_shockwave(pos, 18.0, Color(0.45, 0.95, 1.0, 1.0), 0.28)
			if up._fx.has_method("spawn_reaction_strip"):
				up._fx.call("spawn_reaction_strip", pos + Vector2(0.0, -7.0), STRIP_SHIELD)
		return true
	if (tm & (1 << TRAIT_CORE_MELTDOWN)) != 0:
		up._u_trait_mask[idx] &= ~(1 << TRAIT_CORE_MELTDOWN)
		if up._world != null and up._world.has_method("apply_brush"):
			up._world.apply_brush(pos, 3, 12)
		up.trigger_impulse(pos, 32.0, 115.0, true)
		if up._fx != null:
			up._fx.play_sfx("meltdown", pos.x)
	if (tm & (1 << TRAIT_ENERGIZED)) != 0:
		if up._fx != null:
			up._fx.emit_spark_arc(pos, Vector2.UP, Color(0.45, 0.96, 1.0, 1.0))
			up._fx.spawn_shockwave(pos, 22.0, Color(0.42, 0.92, 1.0, 1.0), 0.26)
		up.apply_ai_glitch_units(pos, 18.0)
	return false


func toggle_unit_trait(up: Node2D, uid: int, trait_id: int) -> bool:
	if trait_id < 0 or trait_id >= TRAIT_COUNT:
		return false
	if up._uid_to_idx.has(uid):
		var idx := int(up._uid_to_idx[uid])
		if idx >= 0 and idx < up._unit_count:
			var bit := 1 << trait_id
			if trait_id == TRAIT_CREATOR_SCAR:
				up._u_trait_mask[idx] |= bit
			elif (up._u_trait_mask[idx] & bit) != 0:
				up._u_trait_mask[idx] &= ~bit
				up._u_trait_mask[idx] |= (1 << TRAIT_CREATOR_SCAR)
			else:
				if trait_id == TRAIT_GIGANTISM:
					up._u_trait_mask[idx] &= ~(1 << TRAIT_TINY)
				elif trait_id == TRAIT_TINY:
					up._u_trait_mask[idx] &= ~(1 << TRAIT_GIGANTISM)
				up._u_trait_mask[idx] |= bit | (1 << TRAIT_CREATOR_SCAR)
			_any_ext_active = true
			recompute_unit_cached_stats(up, idx)
			up._hit_flash_timer[idx] = maxf(up._hit_flash_timer[idx], 0.18)
			return true
	if _f_uid_to_idx.has(uid):
		var fi := int(_f_uid_to_idx[uid])
		if fi >= 0 and fi < _f_count:
			var fbit := 1 << trait_id
			_f_trait_mask[fi] = (_f_trait_mask[fi] ^ fbit) | (1 << TRAIT_CREATOR_SCAR)
			_apply_fauna_trait_cache(fi)
			return true
	return false


func apply_trait_rain(up: Node2D, world_pos: Vector2, radius: float, trait_id: int) -> int:
	var r := maxf(radius, 6.0)
	var r2 := r * r
	var hits := 0
	var rng: RandomNumberGenerator = up._ext_rng
	if up._spatial_hash_dirty:
		up._rebuild_spatial_hash()
	var x0: int = clampi(int(world_pos.x - r) >> 4, 0, int(up._grid_w) - 1)
	var x1: int = clampi(int(world_pos.x + r) >> 4, 0, int(up._grid_w) - 1)
	var y0: int = clampi(int(world_pos.y - r) >> 4, 0, int(up._grid_h) - 1)
	var y1: int = clampi(int(world_pos.y + r) >> 4, 0, int(up._grid_h) - 1)
	for cy in range(y0, y1 + 1):
		var roff: int = cy * int(up._grid_w)
		for cx in range(x0, x1 + 1):
			var u: int = int(up._cell_head[roff + cx])
			while u != -1:
				var dx: float = float(up._px[u]) - world_pos.x
				var dy: float = float(up._py[u]) - world_pos.y
				if dx * dx + dy * dy <= r2 and up._hp[u] > 0.0:
					var tid := trait_id if (trait_id >= 0 and trait_id < TRAIT_COUNT) else rng.randi_range(0, TRAIT_COUNT - 2)
					if tid == TRAIT_GIGANTISM:
						up._u_trait_mask[u] &= ~(1 << TRAIT_TINY)
					elif tid == TRAIT_TINY:
						up._u_trait_mask[u] &= ~(1 << TRAIT_GIGANTISM)
					up._u_trait_mask[u] |= (1 << tid) | (1 << TRAIT_CREATOR_SCAR)
					_any_ext_active = true
					recompute_unit_cached_stats(up, u)
					up._hit_flash_timer[u] = maxf(up._hit_flash_timer[u], 0.22)
					up._u_vel_z[u] = maxf(up._u_vel_z[u], 14.0)
					up._any_z_active = true
					hits += 1
				u = up._unit_next[u]
	for fi in range(_f_count):
		var fdx := _f_px[fi] - world_pos.x
		var fdy := _f_py[fi] - world_pos.y
		if fdx * fdx + fdy * fdy <= r2 and _f_hp[fi] > 0.0:
			var ftid := trait_id if (trait_id >= 0 and trait_id < TRAIT_COUNT) else rng.randi_range(0, TRAIT_COUNT - 2)
			_f_trait_mask[fi] |= (1 << ftid) | (1 << TRAIT_CREATOR_SCAR)
			_apply_fauna_trait_cache(fi)
			_f_flash[fi] = maxf(_f_flash[fi], 0.22)
			hits += 1
	if up._fx != null:
		up._fx.spawn_shockwave(world_pos, clampf(r, 10.0, 54.0), Color(0.84, 0.56, 1.0, 1.0), 0.30)
		up._fx.spawn_burst(world_pos, 14, Color(0.88, 0.62, 1.0, 0.95), 36.0, 0.45, -12.0)
		if hits > 0 and up._fx.has_method("spawn_reaction_strip"):
			up._fx.call("spawn_reaction_strip", world_pos + Vector2(0.0, -7.0), STRIP_SCAR_DIVINITY)
	return hits


func apply_gear_rain(up: Node2D, world_pos: Vector2, radius: float, tier_hint: int) -> int:
	var r := maxf(radius, 6.0)
	var r2 := r * r
	var hits := 0
	var rng: RandomNumberGenerator = up._ext_rng
	if up._spatial_hash_dirty:
		up._rebuild_spatial_hash()
	var x0: int = clampi(int(world_pos.x - r) >> 4, 0, int(up._grid_w) - 1)
	var x1: int = clampi(int(world_pos.x + r) >> 4, 0, int(up._grid_w) - 1)
	var y0: int = clampi(int(world_pos.y - r) >> 4, 0, int(up._grid_h) - 1)
	var y1: int = clampi(int(world_pos.y + r) >> 4, 0, int(up._grid_h) - 1)
	for cy in range(y0, y1 + 1):
		var roff: int = cy * int(up._grid_w)
		for cx in range(x0, x1 + 1):
			var u: int = int(up._cell_head[roff + cx])
			while u != -1:
				var dx: float = float(up._px[u]) - world_pos.x
				var dy: float = float(up._py[u]) - world_pos.y
				if dx * dx + dy * dy <= r2 and up._hp[u] > 0.0:
					var slot: int = rng.randi_range(0, EQ_SLOTS - 1)
					var mat: int = clampi(tier_hint, 0, MAT_COUNT - 1) if tier_hint >= 0 else rng.randi_range(1, MAT_COUNT - 1)
					var rar: int = rng.randi_range(1, RARITY_COUNT - 1)
					var mod_id: int = 7 if rar >= 3 else rng.randi_range(1, 6)
					var packed: int = _pack_item(mat, rar, mod_id)
					var eb: int = u * EQ_SLOTS + slot
					if _item_power(packed) >= _item_power(_u_eq_packed[eb]):
						_u_eq_packed[eb] = packed
						_u_eq_kills[eb] = 0
						_u_eq_name[eb] = _make_item_name(slot, mat, rar, mod_id, rng)
						recompute_unit_cached_stats(up, u)
					up._hit_flash_timer[u] = maxf(up._hit_flash_timer[u], 0.18)
					up._u_vel_z[u] = maxf(up._u_vel_z[u], 12.0)
					up._any_z_active = true
					hits += 1
				u = up._unit_next[u]
	if up._fx != null:
		up._fx.spawn_shockwave(world_pos, clampf(r, 10.0, 52.0), Color(1.0, 0.84, 0.36, 1.0), 0.28)
		up._fx.spawn_burst(world_pos, 12, Color(1.0, 0.88, 0.44, 0.95), 32.0, 0.42, -10.0)
		if hits > 0 and up._fx.has_method("spawn_reaction_strip"):
			up._fx.call("spawn_reaction_strip", world_pos + Vector2(0.0, -7.0), STRIP_TROPHY_GEAR)
	return hits


func apply_monolith_uplift(up: Node2D, world_pos: Vector2, radius: float) -> int:
	var r := maxf(radius, 18.0)
	var r2 := r * r
	var rng: RandomNumberGenerator = up._ext_rng
	var candidates: Array[int] = []
	var target_sp := -1
	for fi in range(_f_count):
		var sp := int(_f_species[fi])
		if sp >= BOSS_LEVIATHAN:
			continue
		var dx := _f_px[fi] - world_pos.x
		var dy := _f_py[fi] - world_pos.y
		if dx * dx + dy * dy <= r2 and _f_hp[fi] > 0.0:
			if target_sp < 0:
				target_sp = sp
			if sp == target_sp:
				candidates.append(fi)
				if candidates.size() >= 6:
					break
	if candidates.is_empty():
		return 0
	var sub_id := _alloc_uplift_subspecies(target_sp, rng)
	var fac := FACTION_SPORE if (target_sp == 11 or target_sp == 12 or target_sp == 13) else FACTION_HUMAN
	var tint := Color(0.62, 0.94, 1.0, 1.0) if fac == FACTION_HUMAN else Color(0.64, 1.0, 0.56, 1.0)
	var uplifted := 0
	candidates.sort()
	for idx_rev in range(candidates.size() - 1, -1, -1):
		if up._unit_count >= up.MAX_UNITS:
			break
		var fi: int = candidates[idx_rev]
		var fpos := Vector2(_f_px[fi], _f_py[fi])
		var fhp: float = _f_hp[fi]
		var fname: String = _f_custom_name[fi]
		_remove_fauna_slot(fi)
		var u: int = int(up._unit_count)
		up._unit_count += 1
		up._resize_unit_arrays(up._unit_count)
		up._init_unit_slot(u, fpos, -1, fac, ROLE_FREE, fpos, tint)
		up._hp[u] = maxf(fhp, 100.0)
		up._u_vel_z[u] = 28.0
		up._any_z_active = true
		up._hit_flash_timer[u] = 0.35
		up._u_trait_mask[u] |= (1 << TRAIT_GENIUS) | (1 << TRAIT_PSYCHIC)
		_any_ext_active = true
		_u_subspecies_id[u] = sub_id
		if fname != "":
			_u_custom_name[u] = fname
		else:
			_u_custom_name[u] = "%s-%d" % [_sub_name[sub_id], uplifted + 1]
		var eb: int = u * EQ_SLOTS
		_u_eq_packed[eb] = _pack_item(2, 1, 1)
		_u_eq_name[eb] = _make_item_name(0, 2, 1, 1, rng)
		recompute_unit_cached_stats(up, u)
		uplifted += 1
	if uplifted > 0:
		up._unit_colors_dirty = true
		up._spatial_hash_dirty = true
		if up._fx != null:
			up._fx.spawn_shockwave(world_pos, clampf(r, 18.0, 56.0), Color(0.62, 0.94, 1.0, 1.0), 0.38)
			up._fx.spawn_burst(world_pos, 20, Color(0.75, 0.95, 1.0, 0.95), 42.0, 0.55, -16.0)
			if up._fx.has_method("spawn_reaction_strip"):
				up._fx.call("spawn_reaction_strip", world_pos + Vector2(0.0, -8.0), STRIP_LVLUP)
	return uplifted


func _alloc_uplift_subspecies(species_idx: int, rng: RandomNumberGenerator) -> int:
	for s in range(4, MAX_SUBSPECIES):
		if _sub_active[s] != 0 and _sub_species[s] == species_idx:
			return s
	var slot := -1
	for s in range(4, MAX_SUBSPECIES):
		if _sub_active[s] == 0:
			slot = s
			break
	if slot < 0:
		slot = 4 + (species_idx % (MAX_SUBSPECIES - 4))
	_sub_active[slot] = 1
	_sub_faction[slot] = FACTION_HUMAN
	_sub_species[slot] = species_idx
	var sp_name: String = str(SPECIES_DATA[clampi(species_idx, 0, SPECIES_COUNT - 1)][0])
	_sub_name[slot] = "%s Возвыш." % sp_name
	var g_off := slot * LOCUS_COUNT
	for l in range(LOCUS_COUNT):
		var v := rng.randi_range(2, 5) if (l == 4 or l == 9 or l == 1) else rng.randi_range(1, 4)
		_sub_genes[g_off + l] = v
	return slot


func spawn_fauna(up: Node2D, world_pos: Vector2, kind_id: int, count: int) -> int:
	var rng: RandomNumberGenerator = up._ext_rng
	var sp := kind_id
	if kind_id >= FAUNA_ATLAS_START and kind_id < FAUNA_ATLAS_START + SPECIES_COUNT:
		sp = kind_id - FAUNA_ATLAS_START
	elif kind_id < 0:
		sp = rng.randi_range(0, 13)
	sp = clampi(sp, 0, SPECIES_COUNT - 1)
	var want := clampi(count, 1, MAX_FAUNA - _f_count)
	if want <= 0:
		return 0
	var info: Array = SPECIES_DATA[sp]
	var hab: int = int(info[2])
	var spawned := 0
	for k in range(want):
		var pt := _find_fauna_spawn_pos(up, world_pos, hab, rng)
		var fi := _f_count
		_f_count += 1
		var uid := _next_fauna_uid
		_next_fauna_uid += 1
		_f_uid[fi] = uid
		_f_uid_to_idx[uid] = fi
		_f_species[fi] = sp
		_f_px[fi] = pt.x
		_f_py[fi] = pt.y
		_f_pz[fi] = 12.0 if hab == HABITAT_AIR else 0.0
		var ang := rng.randf_range(0.0, TAU)
		_f_vx[fi] = cos(ang) * 6.0
		_f_vy[fi] = sin(ang) * 6.0
		_f_vz[fi] = 0.0
		_f_hp[fi] = float(info[3])
		_f_max_hp[fi] = float(info[3])
		_f_phase[fi] = rng.randf_range(0.0, TAU)
		_f_facing[fi] = 1.0 if _f_vx[fi] >= 0.0 else -1.0
		_f_kb[fi] = 0.0
		_f_flash[fi] = 0.22
		_f_atk_cd[fi] = 0.0
		_f_ai_cd[fi] = rng.randf_range(0.0, 0.4)
		_f_wander[fi] = ang
		_f_tgt_uid[fi] = -1
		_f_tgt_is_fauna[fi] = 0
		_f_trait_mask[fi] = (1 << TRAIT_FERAL_ALPHA) if int(info[1]) == SCLASS_BOSS else 0
		_f_status_mask[fi] = 0
		_f_tint[fi] = info[7] as Color
		_f_custom_name[fi] = ""
		_f_kills[fi] = 0
		_f_scale[fi] = float(info[6])
		_f_squash[fi] = 1.0
		_f_squash_v[fi] = 0.0
		_f_last_attacker_uid[fi] = -1
		spawned += 1
	if spawned > 0:
		_rebuild_hostile_fauna_cache()
	_last_unit_cnt_mm = -1
	if spawned > 0 and up._fx != null:
		up._fx.spawn_burst(world_pos, 6, info[7] as Color, 20.0, 0.32, -8.0)
	return spawned


func _rebuild_hostile_fauna_cache() -> void:
	_hostile_fauna_indices.resize(0)
	for i in range(_f_count):
		var sp := int(_f_species[i])
		var sc := int(SPECIES_DATA[sp][1]) if sp < SPECIES_COUNT else 0
		if sc == SCLASS_PREDATOR or sc == SCLASS_BOSS:
			_hostile_fauna_indices.append(i)


func get_hostile_fauna_indices() -> PackedInt32Array:
	return _hostile_fauna_indices


func get_active_boss_snapshots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k in range(_hostile_fauna_indices.size()):
		var fi := _hostile_fauna_indices[k]
		if fi < 0 or fi >= _f_count or _f_hp[fi] <= 0.0:
			continue
		var sp := int(_f_species[fi])
		if sp < SPECIES_COUNT and int(SPECIES_DATA[sp][1]) == SCLASS_BOSS:
			out.append({
				"uid": _f_uid[fi],
				"species": sp,
				"pos": Vector2(_f_px[fi], _f_py[fi]),
				"hp": _f_hp[fi],
			})
	return out


func _find_fauna_spawn_pos(up: Node2D, center: Vector2, hab: int, rng: RandomNumberGenerator) -> Vector2:
	var mw := float(up._map_w - 5)
	var mh := float(up._map_h - 5)
	for _t in range(16):
		var ang := rng.randf_range(0.0, TAU)
		var rad := rng.randf_range(0.0, 14.0)
		var cand := Vector2(clampf(center.x + cos(ang) * rad, 4.0, mw), clampf(center.y + sin(ang) * rad, 4.0, mh))
		var tier: int = int(up._get_tile_tier(int(cand.x), int(cand.y)))
		if hab == HABITAT_AIR or hab == HABITAT_AMPHIB:
			return cand
		if hab == HABITAT_WATER and tier <= TIER_SHALLOW:
			return cand
		if hab == HABITAT_LAND and tier > TIER_SHALLOW and tier < TIER_SUMMIT:
			return cand
	return Vector2(clampf(center.x, 4.0, mw), clampf(center.y, 4.0, mh))


func _apply_fauna_trait_cache(fi: int) -> void:
	var sp := int(_f_species[fi])
	var info: Array = SPECIES_DATA[clampi(sp, 0, SPECIES_COUNT - 1)]
	var base_sc := float(info[6])
	var tm := _f_trait_mask[fi]
	if (tm & (1 << TRAIT_GIGANTISM)) != 0:
		base_sc *= 1.32
		_f_max_hp[fi] = float(info[3]) * 1.65
		_f_hp[fi] = minf(_f_max_hp[fi], _f_hp[fi] + 50.0)
	elif (tm & (1 << TRAIT_TINY)) != 0:
		base_sc *= 0.76
	_f_scale[fi] = base_sc


func _remove_fauna_slot(fi: int) -> void:
	if fi < 0 or fi >= _f_count:
		return
	var uid := _f_uid[fi]
	_f_uid_to_idx.erase(uid)
	var last := _f_count - 1
	if fi != last:
		_f_uid[fi] = _f_uid[last]
		_f_species[fi] = _f_species[last]
		_f_px[fi] = _f_px[last]
		_f_py[fi] = _f_py[last]
		_f_pz[fi] = _f_pz[last]
		_f_vx[fi] = _f_vx[last]
		_f_vy[fi] = _f_vy[last]
		_f_vz[fi] = _f_vz[last]
		_f_hp[fi] = _f_hp[last]
		_f_max_hp[fi] = _f_max_hp[last]
		_f_phase[fi] = _f_phase[last]
		_f_facing[fi] = _f_facing[last]
		_f_kb[fi] = _f_kb[last]
		_f_flash[fi] = _f_flash[last]
		_f_atk_cd[fi] = _f_atk_cd[last]
		_f_ai_cd[fi] = _f_ai_cd[last]
		_f_wander[fi] = _f_wander[last]
		_f_tgt_uid[fi] = _f_tgt_uid[last]
		_f_tgt_is_fauna[fi] = _f_tgt_is_fauna[last]
		_f_trait_mask[fi] = _f_trait_mask[last]
		_f_status_mask[fi] = _f_status_mask[last]
		_f_tint[fi] = _f_tint[last]
		_f_custom_name[fi] = _f_custom_name[last]
		_f_kills[fi] = _f_kills[last]
		_f_scale[fi] = _f_scale[last]
		_f_squash[fi] = _f_squash[last]
		_f_squash_v[fi] = _f_squash_v[last]
		_f_last_attacker_uid[fi] = _f_last_attacker_uid[last]
		_f_uid_to_idx[_f_uid[fi]] = fi
	_f_count = last
	_last_unit_cnt_mm = -1
	_rebuild_hostile_fauna_cache()


func step_and_pack_fauna(up: Node2D, safe_dt: float, unit_offset: int) -> int:
	if _f_count <= 0:
		return 0
	var tick: int = int(up._tick_idx)
	var rng: RandomNumberGenerator = up._ext_rng
	var i := 0
	while i < _f_count:
		if _f_hp[i] <= 0.0:
			_handle_fauna_death(up, i)
			continue
		_step_single_fauna(up, i, safe_dt, tick, rng)
		i += 1
	if _f_count <= 0:
		return 0
	_pack_fauna_mm(up, unit_offset)
	return _f_count


func _step_single_fauna(up: Node2D, i: int, safe_dt: float, tick: int, rng: RandomNumberGenerator) -> void:
	var sp := int(_f_species[i])
	var info: Array = SPECIES_DATA[clampi(sp, 0, SPECIES_COUNT - 1)]
	var sclass := int(info[1])
	var hab := int(info[2])
	var spd := float(info[4])
	var tm := _f_trait_mask[i]
	if (tm & (1 << TRAIT_FAST)) != 0:
		spd *= 1.30
	if (tm & (1 << TRAIT_REGENERATOR)) != 0 and _f_hp[i] < _f_max_hp[i]:
		_f_hp[i] = minf(_f_max_hp[i], _f_hp[i] + 5.0 * safe_dt)
	_f_flash[i] = maxf(0.0, _f_flash[i] - safe_dt)
	_f_kb[i] = maxf(0.0, _f_kb[i] - safe_dt)
	_f_atk_cd[i] = maxf(0.0, _f_atk_cd[i] - safe_dt)
	_f_ai_cd[i] = maxf(0.0, _f_ai_cd[i] - safe_dt)
	if (_f_status_mask[i] & (1 << STATUS_CRYO_STASIS)) != 0:
		_f_vx[i] = 0.0
		_f_vy[i] = 0.0
		_step_fauna_z(up, i, sp, hab, safe_dt, rng)
		return
	var is_mag: bool = (_f_status_mask[i] & (1 << STATUS_MAGNETIZED)) != 0
	var is_poss: bool = (_f_uid[i] == up._possessed_uid)
	if is_mag:
		_f_vx[i] *= exp(-4.0 * safe_dt)
		_f_vy[i] *= exp(-4.0 * safe_dt)
	else:
		if is_poss:
			_step_possessed_boss(up, i, spd)
		elif sclass != SCLASS_INSECT and ((i + tick) & 7) == 0:
			_fauna_ai_sense(up, i, sp, sclass, hab, rng)
		elif sclass == SCLASS_INSECT and ((i + tick) & 7) == 0:
			_f_wander[i] += rng.randf_range(-1.1, 1.1)

		if sclass == SCLASS_BOSS and _f_atk_cd[i] <= 0.0 and not is_poss:
			_step_boss_ability(up, i, sp, rng)

		var des_vx := cos(_f_wander[i]) * spd * (0.45 if sclass == SCLASS_INSECT else 1.0)
		var des_vy := sin(_f_wander[i]) * spd * (0.45 if sclass == SCLASS_INSECT else 1.0)
		if is_poss:
			if up._possess_move.length_squared() > 0.01:
				des_vx = up._possess_move.x * spd * 1.85
				des_vy = up._possess_move.y * spd * 1.85
			else:
				des_vx = 0.0
				des_vy = 0.0
		if _f_pz[i] > 0.5 and hab != HABITAT_AIR:
			var air_drag := exp(-0.28 * safe_dt)
			_f_vx[i] *= air_drag
			_f_vy[i] *= air_drag
		elif _f_kb[i] > 0.0:
			_f_vx[i] *= exp(-3.2 * safe_dt)
			_f_vy[i] *= exp(-3.2 * safe_dt)
		else:
			var bl := 1.0 - exp(-6.0 * safe_dt)
			_f_vx[i] += (des_vx - _f_vx[i]) * bl
			_f_vy[i] += (des_vy - _f_vy[i]) * bl

	var nx := _f_px[i] + _f_vx[i] * safe_dt
	var ny := _f_py[i] + _f_vy[i] * safe_dt
	var max_x := float(up._map_w - 4)
	var max_y := float(up._map_h - 4)
	if nx < 3.0 or nx > max_x:
		nx = clampf(nx, 3.0, max_x)
		_f_vx[i] = -_f_vx[i]
		_f_wander[i] = atan2(_f_vy[i], _f_vx[i])
	if ny < 3.0 or ny > max_y:
		ny = clampf(ny, 3.0, max_y)
		_f_vy[i] = -_f_vy[i]
		_f_wander[i] = atan2(_f_vy[i], _f_vx[i])
	if not is_mag and (hab == HABITAT_LAND or hab == HABITAT_WATER):
		var nt: int = int(up._get_tile_tier(int(nx), int(ny)))
		var valid: bool = (nt <= TIER_SHALLOW) if hab == HABITAT_WATER else (nt > TIER_SHALLOW and nt < TIER_SUMMIT)
		if not valid and _f_pz[i] < 1.5:
			nx = _f_px[i]
			ny = _f_py[i]
			_f_wander[i] += 1.9
			_f_vx[i] = cos(_f_wander[i]) * spd * 0.5
			_f_vy[i] = sin(_f_wander[i]) * spd * 0.5
	_f_px[i] = nx
	_f_py[i] = ny
	if absf(_f_vx[i]) > 0.3:
		_f_facing[i] = 1.0 if _f_vx[i] >= 0.0 else -1.0
	_step_fauna_z(up, i, sp, hab, safe_dt, rng)


func _step_fauna_z(up: Node2D, i: int, sp: int, hab: int, safe_dt: float, rng: RandomNumberGenerator) -> void:
	if (_f_status_mask[i] & (1 << STATUS_MAGNETIZED)) != 0:
		_f_pz[i] = _f_pz[i] + (15.0 - _f_pz[i]) * (1.0 - exp(-16.0 * safe_dt))
		_f_vz[i] = 0.0
		_f_squash[i] = 1.08
		_f_squash_v[i] = 0.0
		return
	if hab == HABITAT_AIR:
		var base_h := 13.0 if sp == BOSS_LEVIATHAN else (19.0 if sp == BOSS_UFO else 4.5)
		_f_pz[i] = base_h + sin(up._sim_time * 3.2 + _f_phase[i]) * 2.2
		_f_vz[i] = 0.0
		_relax_fauna_squash(i, safe_dt)
		return
	if sp == 1 and _f_pz[i] <= 0.0 and _f_ai_cd[i] <= 0.0 and rng.randf() < 0.06:
		_f_vz[i] = 18.0
		_f_ai_cd[i] = 1.2
	if _f_pz[i] > 0.0 or _f_vz[i] != 0.0:
		var pre_vz := _f_vz[i]
		_f_vz[i] -= 120.0 * safe_dt
		var nz := _f_pz[i] + _f_vz[i] * safe_dt
		if nz <= 0.0:
			_f_pz[i] = 0.0
			_f_vz[i] = 0.0
			if pre_vz <= -18.0:
				_f_squash[i] = 0.66
				_f_squash_v[i] = 0.0
				_on_fauna_hard_landing(up, i, sp, pre_vz)
				return
		else:
			_f_pz[i] = minf(nz, 64.0)
			_f_squash[i] = clampf(1.0 + absf(_f_vz[i]) * 0.0048, 1.0, 1.34)
			_f_squash_v[i] = 0.0
			return
	_relax_fauna_squash(i, safe_dt)


func _relax_fauna_squash(i: int, safe_dt: float) -> void:
	var sy := _f_squash[i]
	var sv := _f_squash_v[i]
	if absf(sy - 1.0) <= 0.002 and absf(sv) <= 0.002:
		_f_squash[i] = 1.0
		_f_squash_v[i] = 0.0
		return
	var steps := maxi(1, int(ceilf(safe_dt / 0.0125)))
	var sub_dt := safe_dt / float(steps)
	for _s in range(steps):
		var force := -324.0 * (sy - 1.0) - 9.0 * sv
		sv += force * sub_dt
		sy += sv * sub_dt
	if absf(sy - 1.0) < 0.002 and absf(sv) < 0.01:
		_f_squash[i] = 1.0
		_f_squash_v[i] = 0.0
	else:
		_f_squash[i] = clampf(sy, 0.55, 1.35)
		_f_squash_v[i] = sv


func _on_fauna_hard_landing(up: Node2D, fi: int, sp: int, _pre_vz: float) -> void:
	var pos := Vector2(_f_px[fi], _f_py[fi])
	var tier := int(up._get_tile_tier(clampi(int(pos.x), 0, up._map_w - 1), clampi(int(pos.y), 0, up._map_h - 1)))
	if tier <= TIER_SHALLOW and not up._is_ice_bridge_tile(int(pos.x), int(pos.y)):
		if up._fx != null and up._cur_splash_budget > 0:
			up._cur_splash_budget -= 1
			up._fx.spawn_burst(pos, 6, Color(0.55, 0.90, 1.0, 0.90), 24.0, 0.34, 30.0)
			up._fx.play_sfx("drop_rain", pos.x)
		return
	var v_imp := sqrt(_f_vx[fi] * _f_vx[fi] + _f_vy[fi] * _f_vy[fi])
	if v_imp >= 140.0:
		var sclass := int(SPECIES_DATA[clampi(sp, 0, SPECIES_COUNT - 1)][1])
		up.apply_toss_impact_at(pos, v_imp, sclass == SCLASS_BOSS)
		if sclass != SCLASS_BOSS:
			var dmg := clampf((v_imp - 140.0) * 0.18, 0.0, 85.0)
			if v_imp < 280.0 and _f_hp[fi] >= 80.0:
				dmg = minf(dmg, _f_hp[fi] - 5.0)
			_f_hp[fi] -= maxf(dmg, 0.0)
			_f_flash[fi] = 0.18


func _fauna_ai_sense(up: Node2D, i: int, sp: int, sclass: int, hab: int, rng: RandomNumberGenerator) -> void:
	if sclass == SCLASS_HERBIVORE:
		var flee_pos := _find_nearest_threat_for_herb(i)
		if flee_pos.x >= 0.0:
			_f_wander[i] = atan2(_f_py[i] - flee_pos.y, _f_px[i] - flee_pos.x)
		elif rng.randf() < 0.35:
			_f_wander[i] += rng.randf_range(-0.9, 0.9)
		return
	var tgt := _find_fauna_prey(up, i, sclass)
	if tgt.x >= 0.0:
		var dx := tgt.x - _f_px[i]
		var dy := tgt.y - _f_py[i]
		_f_wander[i] = atan2(dy, dx)
		var d2 := dx * dx + dy * dy
		if sp == 8 and d2 < 400.0 and d2 > 36.0 and _f_pz[i] <= 0.1 and rng.randf() < 0.45:
			_f_vz[i] = 22.0
		var atk_r := 26.0 if sclass == SCLASS_BOSS else 9.0
		if d2 <= atk_r * atk_r and _f_atk_cd[i] <= 0.0:
			_fauna_melee_attack(up, i, sp, sclass, int(tgt.z))
	elif rng.randf() < 0.4:
		_f_wander[i] += rng.randf_range(-0.85, 0.85)


func _find_nearest_threat_for_herb(fi: int) -> Vector2:
	var px := _f_px[fi]
	var py := _f_py[fi]
	var best_d2 := 784.0
	var out := Vector2(-1.0, -1.0)
	for k in range(_hostile_fauna_indices.size()):
		var j := _hostile_fauna_indices[k]
		if j == fi or j < 0 or j >= _f_count or _f_hp[j] <= 0.0:
			continue
		var dx := _f_px[j] - px
		var dy := _f_py[j] - py
		var d2 := dx * dx + dy * dy
		if d2 < best_d2:
			best_d2 = d2
			out = Vector2(_f_px[j], _f_py[j])
	return out


func _find_fauna_prey(up: Node2D, fi: int, sclass: int) -> Vector3:
	var px := _f_px[fi]
	var py := _f_py[fi]
	var max_r := 64.0 if sclass == SCLASS_BOSS else 38.0
	var best_d2 := max_r * max_r
	var best_res := Vector3(-1.0, -1.0, -1.0)
	if up._unit_count > 0:
		var cr: int = 3 if sclass == SCLASS_BOSS else 2
		var cx0: int = clampi((int(px) >> 4) - cr, 0, int(up._grid_w) - 1)
		var cx1: int = clampi((int(px) >> 4) + cr, 0, int(up._grid_w) - 1)
		var cy0: int = clampi((int(py) >> 4) - cr, 0, int(up._grid_h) - 1)
		var cy1: int = clampi((int(py) >> 4) + cr, 0, int(up._grid_h) - 1)
		for cy in range(cy0, cy1 + 1):
			var roff: int = cy * int(up._grid_w)
			for cx in range(cx0, cx1 + 1):
				var u: int = int(up._cell_head[roff + cx])
				while u != -1:
					if up._hp[u] > 0.0:
						var d2: float = (float(up._px[u]) - px) * (float(up._px[u]) - px) + (float(up._py[u]) - py) * (float(up._py[u]) - py)
						if d2 < best_d2:
							best_d2 = d2
							best_res = Vector3(up._px[u], up._py[u], float(u))
					u = up._unit_next[u]
	if best_res.x >= 0.0:
		return best_res
	for j in range(_f_count):
		if j == fi or _f_hp[j] <= 0.0:
			continue
		var jc := int(SPECIES_DATA[int(_f_species[j])][1])
		if jc == SCLASS_HERBIVORE:
			var d2f := (_f_px[j] - px) * (_f_px[j] - px) + (_f_py[j] - py) * (_f_py[j] - py)
			if d2f < best_d2:
				best_d2 = d2f
				best_res = Vector3(_f_px[j], _f_py[j], float(-10 - j))
	return best_res


func _fauna_melee_attack(up: Node2D, fi: int, sp: int, sclass: int, tgt_encoded: int) -> void:
	_f_atk_cd[fi] = 0.85 if sclass == SCLASS_BOSS else 0.95
	var dmg: float = float(SPECIES_DATA[sp][5])
	var pos := Vector2(_f_px[fi], _f_py[fi])
	if tgt_encoded >= 0 and tgt_encoded < up._unit_count:
		var u := tgt_encoded
		if (up._u_status_mask[u] & (1 << STATUS_INVINCIBLE)) == 0:
			up._hp[u] -= dmg * up._u_armor_mul[u]
			up._hit_flash_timer[u] = maxf(up._hit_flash_timer[u], 0.16)
			if sp == 10:
				apply_status(up, u, STATUS_POISONED, 5.0)
			if sclass == SCLASS_BOSS or sp == 7:
				up._u_vel_z[u] = maxf(up._u_vel_z[u], 22.0)
				up._any_z_active = true
			if up._hp[u] <= 0.0:
				_f_kills[fi] += 1
				up._cur_any_died = true
		if up._fx != null and up._skirmish_fx_budget > 0:
			up._skirmish_fx_budget -= 1
			up._fx.emit_spark_arc(Vector2(up._px[u], up._py[u]), Vector2(up._px[u] - pos.x, up._py[u] - pos.y), _f_tint[fi])
	elif tgt_encoded <= -10:
		var jf := -10 - tgt_encoded
		if jf >= 0 and jf < _f_count:
			_f_hp[jf] -= dmg
			_f_flash[jf] = 0.18
			if _f_hp[jf] <= 0.0:
				_f_kills[fi] += 1


func _step_boss_ability(up: Node2D, fi: int, sp: int, rng: RandomNumberGenerator) -> void:
	var pos := Vector2(_f_px[fi], _f_py[fi])
	var tgt := _find_fauna_prey(up, fi, SCLASS_BOSS)
	var has_tgt := tgt.x >= 0.0
	var aim := Vector2(tgt.x, tgt.y) if has_tgt else (pos + Vector2(cos(_f_wander[fi]), sin(_f_wander[fi])) * 26.0)
	if sp == BOSS_LEVIATHAN:
		_f_atk_cd[fi] = 1.65
		up.queue_projectile(Rect2(pos, aim), Vector2(2.0, 34.0), -1)
		if up._world != null and up._world.has_method("apply_brush"):
			up._world.apply_brush(aim, 4, 5)
	elif sp == BOSS_UFO:
		_f_atk_cd[fi] = 1.45
		if has_tgt:
			up._beam_starts.append(pos + Vector2(0.0, -10.0))
			up._beam_ends.append(aim)
			up._beam_colors.append(Color(0.38, 0.96, 1.0, 1.0))
			up._beam_widths.append(2.4)
			up._beam_heavy.append(1)
			up.apply_external_damage(aim, 12.0, {"damage": 24.0, "impulse": 55.0})
			var tu := int(tgt.z)
			if tu >= 0 and tu < up._unit_count:
				up._u_vel_z[tu] = maxf(up._u_vel_z[tu], 42.0)
				up._any_z_active = true
	elif sp == BOSS_NECROMANCER:
		_f_atk_cd[fi] = 2.2
		if has_tgt:
			up.queue_projectile(Rect2(pos, aim), Vector2(0.0, 22.0), -1)
		if up._unit_count < up.MAX_UNITS - 2 and rng.randf() < 0.45:
			var spot: Vector2 = up._find_walkable_near(pos, 14.0)
			var u: int = int(up._unit_count)
			up._unit_count += 1
			up._resize_unit_arrays(up._unit_count)
			up._init_unit_slot(u, spot, -1, FACTION_MUTANT, ROLE_MUTANT, spot, Color(0.84, 0.44, 1.0, 1.0))
			up._u_vel_z[u] = 20.0
			up._any_z_active = true
			up._spatial_hash_dirty = true
			if up._fx != null:
				up._fx.spawn_burst(spot, 8, Color(0.84, 0.44, 1.0, 0.95), 24.0, 0.36, -12.0)
	elif sp == BOSS_COLOSSUS:
		_f_atk_cd[fi] = 1.85
		if has_tgt:
			up.trigger_impulse(pos, 26.0, 88.0, false)
			up.apply_external_damage(pos, 22.0, {"damage": 38.0, "impulse": 75.0})


func _step_possessed_boss(up: Node2D, fi: int, _spd: float) -> void:
	if up._possess_pulse and up._possess_pulse_cd <= 0.0:
		up._possess_pulse_cd = 1.6
		up._possess_pulse = false
		var pos := Vector2(_f_px[fi], _f_py[fi])
		up.trigger_impulse(pos, 30.0, 110.0, false)
		up.apply_external_damage(pos, 24.0, {"damage": 48.0, "impulse": 80.0})
		if up._fx != null:
			up._fx.spawn_shockwave(pos, 28.0, Color(1.0, 0.42, 0.28, 1.0), 0.32)
			up._fx.play_sfx("meteor", pos.x)


func boss_avatar_action(up: Node2D, uid: int, aim_pos: Vector2, is_alt: bool) -> int:
	if not _f_uid_to_idx.has(uid):
		return 0
	var fi := int(_f_uid_to_idx[uid])
	if fi < 0 or fi >= _f_count or _f_hp[fi] <= 0.0:
		return 0
	var pos := Vector2(_f_px[fi], _f_py[fi])
	if is_alt:
		up.trigger_impulse(pos, 32.0, 115.0, false)
		return 1
	up.queue_projectile(Rect2(pos, aim_pos), Vector2(2.0, 42.0), -1)
	up._beam_starts.append(pos + Vector2(0.0, -4.0))
	up._beam_ends.append(aim_pos)
	up._beam_colors.append(Color(1.0, 0.32, 0.28, 1.0))
	up._beam_widths.append(2.5)
	up._beam_heavy.append(1)
	return up.apply_external_damage(aim_pos, 18.0, {"damage": 45.0, "impulse": 70.0})


func _handle_fauna_death(up: Node2D, fi: int) -> void:
	var pos := Vector2(_f_px[fi], _f_py[fi])
	var tm := _f_trait_mask[fi]
	var col := _f_tint[fi]
	var dead_uid := _f_uid[fi]
	var sp := int(_f_species[fi])
	var was_boss := sp < SPECIES_COUNT and int(SPECIES_DATA[sp][1]) == SCLASS_BOSS
	var killer_uid := _f_last_attacker_uid[fi] if fi < _f_last_attacker_uid.size() else -1
	_remove_fauna_slot(fi)
	if dead_uid == up._possessed_uid:
		up._possessed_uid = -1
	if was_boss and up._civ != null and up._civ.has_method("on_boss_slain"):
		up._civ.call("on_boss_slain", pos, killer_uid, sp)
	if (tm & (1 << TRAIT_CORE_MELTDOWN)) != 0:
		up.trigger_impulse(pos, 30.0, 110.0, true)
	if up._fx != null:
		up._fx.spawn_burst(pos, 8, col, 26.0, 0.42, 14.0)


func damage_fauna_at(up: Node2D, world_pos: Vector2, radius: float, damage: float, killer_idx: int = -1) -> int:
	if _f_count <= 0:
		return 0
	var r2 := radius * radius
	var hits := 0
	var killer_uid: int = up._u_uid[killer_idx] if (killer_idx >= 0 and killer_idx < up._unit_count) else -1
	var i := _f_count - 1
	while i >= 0:
		var dx := _f_px[i] - world_pos.x
		var dy := _f_py[i] - world_pos.y
		if dx * dx + dy * dy <= r2:
			_f_hp[i] -= damage
			_f_flash[i] = 0.18
			_f_kb[i] = maxf(_f_kb[i], 0.18)
			_f_vz[i] = maxf(_f_vz[i], 14.0)
			if i < _f_last_attacker_uid.size():
				_f_last_attacker_uid[i] = killer_uid
			if _f_hp[i] <= 0.0:
				var was_boss := int(SPECIES_DATA[int(_f_species[i])][1]) == SCLASS_BOSS
				if killer_idx >= 0 and killer_idx < up._unit_count:
					up._u_kills[killer_idx] += (5 if was_boss else 1)
					if was_boss:
						up._u_trait_mask[killer_idx] |= (1 << TRAIT_BLESSED_HALO) | (1 << TRAIT_VETERAN)
						recompute_unit_cached_stats(up, killer_idx)
				_handle_fauna_death(up, i)
			hits += 1
		i -= 1
	return hits


func _pack_fauna_mm(up: Node2D, unit_offset: int) -> void:
	var mm_buf: PackedFloat32Array = up._unit_mm_buf
	var max_slots: int = mm_buf.size() >> 4
	var max_col: int = maxi(1, int(up._unit_atlas_cols) - 1)
	var count := mini(_f_count, max_slots - unit_offset)
	for i in range(count):
		var slot := unit_offset + i
		var off := slot * 16
		var sp := int(_f_species[i])
		var sc := _f_scale[i]
		if up._zoom_lod_val <= 1.85 and int(SPECIES_DATA[sp][1]) == SCLASS_INSECT:
			sc = 0.001
		mm_buf[off] = sc
		mm_buf[off + 5] = sc
		mm_buf[off + 3] = _f_px[i]
		mm_buf[off + 7] = _f_py[i] - 3.2
		var c := _f_tint[i]
		mm_buf[off + 8] = c.r
		mm_buf[off + 9] = c.g
		mm_buf[off + 10] = c.b
		mm_buf[off + 11] = c.a
		var spd := sqrt(_f_vx[i] * _f_vx[i] + _f_vy[i] * _f_vy[i])
		_f_phase[i] = fmod(_f_phase[i] + (2.0 + spd * 0.25) * 0.016, TAU * 4.0)
		mm_buf[off + 12] = _f_phase[i]
		var pz := _f_pz[i]
		var custom_g := clampf(spd * 0.025, 0.0, 1.5)
		if pz >= 1.0:
			custom_g += floorf(clampf(pz, 0.0, 64.0)) * 4.0
		elif _f_flash[i] > 0.005:
			custom_g = -2.0 - clampf(_f_flash[i] / 0.18, 0.2, 1.0)
		mm_buf[off + 13] = custom_g
		mm_buf[off + 14] = _f_facing[i] * clampf(_f_squash[i], 0.65, 1.35)
		mm_buf[off + 15] = float(mini(FAUNA_ATLAS_START + sp, max_col))
	_last_unit_cnt_mm = unit_offset


func inspect_fauna_at(world_pos: Vector2, search_r: float) -> Dictionary:
	var best_i := -1
	var best_d2 := search_r * search_r
	for i in range(_f_count):
		var dx := _f_px[i] - world_pos.x
		var dy := _f_py[i] - world_pos.y
		var d2 := dx * dx + dy * dy
		if d2 <= best_d2:
			best_d2 = d2
			best_i = i
	if best_i < 0:
		return {"found": false}
	return build_fauna_inspect_dict(best_i)


func has_fauna_uid(uid: int) -> bool:
	return _f_uid_to_idx.has(uid)


func get_fauna_pos_by_uid(uid: int) -> Vector2:
	if not _f_uid_to_idx.has(uid):
		return Vector2(-1.0, -1.0)
	var fi := int(_f_uid_to_idx[uid])
	if fi < 0 or fi >= _f_count:
		return Vector2(-1.0, -1.0)
	return Vector2(_f_px[fi], _f_py[fi])


func set_fauna_custom_name(uid: int, new_name: String) -> bool:
	if not _f_uid_to_idx.has(uid):
		return false
	var fi := int(_f_uid_to_idx[uid])
	if fi < 0 or fi >= _f_count:
		return false
	_f_custom_name[fi] = new_name
	return true


func inspect_fauna_by_id(uid: int) -> Dictionary:
	if not _f_uid_to_idx.has(uid):
		return {"found": false}
	var fi := int(_f_uid_to_idx[uid])
	return build_fauna_inspect_dict(fi)


func find_nearest_hostile_fauna(world_pos: Vector2, max_range: float, include_peaceful: bool = false) -> Dictionary:
	if _f_count <= 0:
		return {"found": false}
	var best_i := -1
	var best_d2 := max_range * max_range
	if not include_peaceful:
		for k in range(_hostile_fauna_indices.size()):
			var i := _hostile_fauna_indices[k]
			if i < 0 or i >= _f_count or _f_hp[i] <= 0.0:
				continue
			var dx := _f_px[i] - world_pos.x
			var dy := _f_py[i] - world_pos.y
			var d2 := dx * dx + dy * dy
			if d2 <= best_d2:
				best_d2 = d2
				best_i = i
	else:
		for i in range(_f_count):
			if _f_hp[i] <= 0.0:
				continue
			var dx := _f_px[i] - world_pos.x
			var dy := _f_py[i] - world_pos.y
			var d2 := dx * dx + dy * dy
			if d2 <= best_d2:
				best_d2 = d2
				best_i = i
	if best_i < 0:
		return {"found": false}
	return {"found": true, "fauna_idx": best_i, "pos": Vector2(_f_px[best_i], _f_py[best_i]), "d2": best_d2}


func apply_magnet_fauna(up: Node2D, world_pos: Vector2, radius: float, impulse_and_hold: Vector3) -> int:
	if _f_count <= 0:
		return 0
	var r2 := radius * radius
	var hold := impulse_and_hold.z > 0.5
	var imp := Vector2(impulse_and_hold.x, impulse_and_hold.y).limit_length(360.0)
	var raw_dt := up.get_process_delta_time()
	var eff_dt := clampf(raw_dt, 0.005, 0.05) if raw_dt > 0.0 else 0.016667
	var pull_k := 1.0 - exp(-18.0 * eff_dt)
	var lift_k := 1.0 - exp(-16.0 * eff_dt)
	var cnt := 0
	var mw := float(up._map_w - 4)
	var mh := float(up._map_h - 4)
	for i in range(_f_count):
		var dx := _f_px[i] - world_pos.x
		var dy := _f_py[i] - world_pos.y
		if dx * dx + dy * dy <= r2 or (not hold and (_f_status_mask[i] & (1 << STATUS_MAGNETIZED)) != 0):
			if hold:
				_f_px[i] = clampf(lerpf(_f_px[i], world_pos.x, pull_k), 3.0, mw)
				_f_py[i] = clampf(lerpf(_f_py[i], world_pos.y, pull_k), 3.0, mh)
				_f_pz[i] = lerpf(_f_pz[i], 15.0, lift_k)
				_f_vz[i] = 0.0
				_f_vx[i] = imp.x * 0.45
				_f_vy[i] = imp.y * 0.45
				_f_kb[i] = maxf(_f_kb[i], 0.25)
				_f_status_mask[i] |= (1 << STATUS_MAGNETIZED)
			else:
				var throw_v := imp if imp.length_squared() > 4.0 else Vector2(_f_vx[i], _f_vy[i])
				_f_vx[i] = throw_v.x
				_f_vy[i] = throw_v.y
				_f_vz[i] = maxf(_f_vz[i], clampf(32.0 + throw_v.length() * 0.25, 28.0, 62.0))
				_f_kb[i] = maxf(_f_kb[i], 0.65)
				_f_status_mask[i] &= ~(1 << STATUS_MAGNETIZED)
			cnt += 1
	return cnt


func apply_flick_fauna(world_pos: Vector2, radius: float, impulse: Vector2) -> int:
	if _f_count <= 0:
		return 0
	var r2 := radius * radius
	var cnt := 0
	var base_dir := impulse
	if base_dir.length_squared() >= 0.01 and base_dir.length() <= 2.0:
		base_dir = base_dir.normalized() * 95.0
	base_dir = base_dir.limit_length(220.0)
	for i in range(_f_count):
		var dx := _f_px[i] - world_pos.x
		var dy := _f_py[i] - world_pos.y
		if dx * dx + dy * dy <= r2:
			var push := base_dir
			if push.length_squared() < 0.01:
				var d := Vector2(dx, dy)
				push = (d.normalized() if d.length_squared() > 0.01 else Vector2.RIGHT) * 85.0
			_f_vx[i] += push.x
			_f_vy[i] += push.y
			_f_vz[i] = maxf(_f_vz[i], clampf(34.0 + push.length() * 0.25, 34.0, 64.0))
			_f_kb[i] = maxf(_f_kb[i], 0.38)
			_f_flash[i] = maxf(_f_flash[i], 0.14)
			cnt += 1
	return cnt


func build_fauna_inspect_dict(fi: int) -> Dictionary:
	if fi < 0 or fi >= _f_count:
		return {"found": false}
	var sp := int(_f_species[fi])
	var info: Array = SPECIES_DATA[clampi(sp, 0, SPECIES_COUNT - 1)]
	var t_res := build_trait_arrays(_f_trait_mask[fi])
	var sp_name: String = str(info[0])
	var cname := _f_custom_name[fi] if fi < _f_custom_name.size() else ""
	return {
		"found": true,
		"uid": _f_uid[fi],
		"unit_idx": fi,
		"is_fauna": true,
		"is_boss": int(info[1]) == SCLASS_BOSS,
		"species_id": sp,
		"name": cname if cname != "" else sp_name,
		"custom_name": cname,
		"pos": Vector2(_f_px[fi], _f_py[fi]),
		"pos_z": _f_pz[fi],
		"vel": Vector2(_f_vx[fi], _f_vy[fi]),
		"hp": _f_hp[fi],
		"max_hp": _f_max_hp[fi],
		"faction": FACTION_NONE,
		"faction_name": "Ксенофауна",
		"role": ROLE_MUTANT if int(info[1]) == SCLASS_BOSS else ROLE_FREE,
		"role_name": sp_name,
		"city_id": -1,
		"task": TASK_IDLE,
		"task_name": "Охота" if int(info[1]) >= SCLASS_PREDATOR else "Выпас",
		"kills": _f_kills[fi],
		"traits": t_res[0],
		"trait_names": t_res[1],
		"trait_mask": _f_trait_mask[fi],
		"equipment": [],
		"mood": 70,
		"fav_food": FAV_FOOD_NAMES_RU[sp % FAV_FOOD_NAMES_RU.size()],
		"genes": build_subspecies_genes(0),
		"subspecies": sp_name,
		"memory": [],
	}


func build_trait_arrays(tmask: int) -> Array:
	var ids: Array[int] = []
	var names: Array[String] = []
	for t in range(TRAIT_COUNT):
		if (tmask & (1 << t)) != 0:
			ids.append(t)
			names.append(TRAIT_NAMES_RU[t])
	return [ids, names]


func build_equipment_list(idx: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var eb := idx * EQ_SLOTS
	for s in range(EQ_SLOTS):
		var p := _u_eq_packed[eb + s] if (eb + s) < _u_eq_packed.size() else 0
		if p == 0:
			out.append({"slot": s, "slot_name": SLOT_NAMES_RU[s], "empty": true, "name": "Пусто", "material": -1, "rarity": 0, "kills": 0})
		else:
			var mat := p & 7
			var rar := (p >> 3) & 3
			var mod_id := (p >> 5) & 7
			out.append({
				"slot": s,
				"slot_name": SLOT_NAMES_RU[s],
				"empty": false,
				"name": _u_eq_name[eb + s],
				"material": mat,
				"material_name": MAT_NAMES_RU[clampi(mat, 0, MAT_NAMES_RU.size() - 1)],
				"rarity": rar,
				"rarity_name": RARITY_NAMES_RU[clampi(rar, 0, RARITY_NAMES_RU.size() - 1)],
				"mod": mod_id,
				"kills": _u_eq_kills[eb + s],
			})
	return out


func build_subspecies_genes(sub_id: int) -> Array[Dictionary]:
	var sid := clampi(sub_id, 0, MAX_SUBSPECIES - 1)
	var g_off := sid * LOCUS_COUNT
	var out: Array[Dictionary] = []
	for l in range(LOCUS_COUNT):
		var v := int(_sub_genes[g_off + l]) if (g_off + l) < _sub_genes.size() else 2
		var syn := (l > 0 and v >= 3 and int(_sub_genes[g_off + l - 1]) >= 3) or (l < LOCUS_COUNT - 1 and v >= 3 and int(_sub_genes[g_off + l + 1]) >= 3)
		out.append({"id": l, "name": LOCUS_NAMES_RU[l], "val": v, "value": v, "synergy": syn})
	return out


func enrich_unit_inspect(up: Node2D, idx: int, base: Dictionary) -> Dictionary:
	var t_res := build_trait_arrays(up._u_trait_mask[idx])
	var sub_id := int(_u_subspecies_id[idx]) if idx < _u_subspecies_id.size() else 0
	var cname := _u_custom_name[idx] if idx < _u_custom_name.size() else ""
	var fav_id := int(_u_fav_food[idx]) if idx < _u_fav_food.size() else 0
	var st_names: Array[String] = []
	var sm: int = int(up._u_status_mask[idx])
	for s in range(STATUS_COUNT):
		if (sm & (1 << s)) != 0:
			st_names.append(STATUS_NAMES_RU[s])
	base["name"] = cname if cname != "" else ("%s #%d" % [str(base.get("role_name", "Юнит")), up._u_uid[idx]])
	base["custom_name"] = cname
	base["pos_z"] = up._u_pos_z[idx]
	base["traits"] = t_res[0]
	base["trait_names"] = t_res[1]
	base["trait_mask"] = up._u_trait_mask[idx]
	base["statuses"] = st_names
	base["status_mask"] = sm
	base["equipment"] = build_equipment_list(idx)
	base["mood"] = int(roundf(_u_mood[idx])) if idx < _u_mood.size() else 65
	base["fav_food"] = FAV_FOOD_NAMES_RU[clampi(fav_id, 0, FAV_FOOD_NAMES_RU.size() - 1)]
	base["fav_food_id"] = fav_id
	base["genes"] = build_subspecies_genes(sub_id)
	base["subspecies"] = _sub_name[clampi(sub_id, 0, MAX_SUBSPECIES - 1)]
	base["subspecies_id"] = sub_id
	base["is_fauna"] = false
	base["is_boss"] = false
	return base


func pack_ext_state(up: Node2D, buf: StreamPeerBuffer) -> void:
	var n: int = mini(int(up._unit_count), int(up.MAX_UNITS))
	buf.put_u32(_next_fauna_uid)
	for i in range(n):
		buf.put_float(up._u_pos_z[i])
		buf.put_float(up._u_vel_z[i])
		buf.put_64(up._u_trait_mask[i])
		buf.put_32(up._u_status_mask[i])
		for s in range(STATUS_COUNT):
			buf.put_float(_u_status_timers[i * STATUS_COUNT + s])
		buf.put_utf8_string(_u_custom_name[i])
		buf.put_u8(_u_fav_food[i])
		buf.put_float(_u_mood[i])
		buf.put_float(_u_sleep_timer[i])
		buf.put_float(_u_talk_cd[i])
		buf.put_u8(_u_subspecies_id[i])
		for k in range(EQ_SLOTS):
			var eb := i * EQ_SLOTS + k
			buf.put_32(_u_eq_packed[eb])
			buf.put_32(_u_eq_kills[eb])
			buf.put_utf8_string(_u_eq_name[eb])
	buf.put_u8(_sub_count)
	for s in range(MAX_SUBSPECIES):
		buf.put_u8(_sub_active[s])
		buf.put_u8(_sub_faction[s])
		buf.put_32(_sub_species[s])
		buf.put_utf8_string(_sub_name[s])
		for l in range(LOCUS_COUNT):
			buf.put_u8(_sub_genes[s * LOCUS_COUNT + l])
	buf.put_u16(_f_count)
	for f in range(_f_count):
		buf.put_32(_f_uid[f])
		buf.put_u8(_f_species[f])
		buf.put_float(_f_px[f])
		buf.put_float(_f_py[f])
		buf.put_float(_f_pz[f])
		buf.put_float(_f_vx[f])
		buf.put_float(_f_vy[f])
		buf.put_float(_f_vz[f])
		buf.put_float(_f_hp[f])
		buf.put_float(_f_max_hp[f])
		buf.put_float(_f_facing[f])
		buf.put_64(_f_trait_mask[f])
		buf.put_utf8_string(_f_custom_name[f])
		buf.put_32(_f_kills[f])


func unpack_ext_state(up: Node2D, buf: StreamPeerBuffer) -> bool:
	if buf.get_available_bytes() < 4:
		return false
	_next_fauna_uid = maxi(FAUNA_UID_BASE, buf.get_32())
	var n: int = int(up._unit_count)
	for i in range(n):
		if buf.get_available_bytes() < 20:
			return false
		up._u_pos_z[i] = buf.get_float()
		up._u_vel_z[i] = buf.get_float()
		up._u_trait_mask[i] = buf.get_64()
		up._u_status_mask[i] = buf.get_32()
		for s in range(STATUS_COUNT):
			_u_status_timers[i * STATUS_COUNT + s] = buf.get_float()
		_u_custom_name[i] = buf.get_utf8_string()
		_u_fav_food[i] = buf.get_u8()
		_u_mood[i] = buf.get_float()
		_u_sleep_timer[i] = buf.get_float()
		_u_talk_cd[i] = buf.get_float()
		_u_subspecies_id[i] = buf.get_u8()
		for k in range(EQ_SLOTS):
			var eb := i * EQ_SLOTS + k
			_u_eq_packed[eb] = buf.get_32()
			_u_eq_kills[eb] = buf.get_32()
			_u_eq_name[eb] = buf.get_utf8_string()
		recompute_unit_cached_stats(up, i)
	_any_ext_active = n > 0
	up._any_z_active = n > 0
	up._any_unit_frozen = n > 0
	if buf.get_available_bytes() < 1:
		return false
	_sub_count = buf.get_u8()
	for s in range(MAX_SUBSPECIES):
		_sub_active[s] = buf.get_u8()
		_sub_faction[s] = buf.get_u8()
		_sub_species[s] = buf.get_32()
		_sub_name[s] = buf.get_utf8_string()
		for l in range(LOCUS_COUNT):
			_sub_genes[s * LOCUS_COUNT + l] = buf.get_u8()
	if buf.get_available_bytes() < 2:
		return false
	_f_count = mini(buf.get_u16(), MAX_FAUNA)
	_f_uid_to_idx.clear()
	for f in range(_f_count):
		var uid := buf.get_32()
		var sp := clampi(buf.get_u8(), 0, SPECIES_COUNT - 1)
		_f_uid[f] = uid
		_f_uid_to_idx[uid] = f
		_f_species[f] = sp
		_f_px[f] = buf.get_float()
		_f_py[f] = buf.get_float()
		_f_pz[f] = buf.get_float()
		_f_vx[f] = buf.get_float()
		_f_vy[f] = buf.get_float()
		_f_vz[f] = buf.get_float()
		_f_hp[f] = buf.get_float()
		_f_max_hp[f] = buf.get_float()
		_f_facing[f] = buf.get_float()
		_f_trait_mask[f] = buf.get_64()
		_f_custom_name[f] = buf.get_utf8_string()
		_f_kills[f] = buf.get_32()
		_f_tint[f] = SPECIES_DATA[sp][7] as Color
		_f_phase[f] = 0.0
		_f_kb[f] = 0.0
		_f_flash[f] = 0.0
		_f_atk_cd[f] = 0.0
		_f_ai_cd[f] = 0.0
		_f_wander[f] = 0.0
		_f_tgt_uid[f] = -1
		_f_tgt_is_fauna[f] = 0
		_f_status_mask[f] = 0
		_f_squash[f] = 1.0
		_f_squash_v[f] = 0.0
		_f_last_attacker_uid[f] = -1
		_apply_fauna_trait_cache(f)
	_rebuild_hostile_fauna_cache()
	return true
