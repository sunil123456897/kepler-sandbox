extends RefCounted

signal tool_requested(tool_id: int)
signal shape_changed(shape_id: int)
signal lens_changed(lens_id: int)
signal template_regen_requested(template_id: int)
signal speed_requested(speed_val: float)
signal selection_cleared()
signal follow_requested(kind: String, entity_id: int, world_pos: Vector2)
signal possess_requested(unit_uid: int)
signal pin_requested()
signal architect_mood_changed(mood_id: int, palette: Dictionary)

const UI_ATLAS_PNG_PATH: String = "res://assets/atlases/ui_icons_atlas.png"
const UI_ATLAS_JSON_PATH: String = "res://assets/atlases/ui_icons_atlas.json"

const TOOL_TERRAFORM: int = 0
const TOOL_CRYSTAL: int = 1
const TOOL_LAVA: int = 2
const TOOL_METEOR: int = 3
const TOOL_VORTEX: int = 4
const TOOL_CANAL: int = 5
const TOOL_ORBITAL_STRIKE: int = 6
const TOOL_COLONY: int = 100
const TOOL_BLESS: int = 101
const TOOL_INSPECT: int = 102
const TOOL_STORM_RAIN: int = 103
const TOOL_STORM_FIRE: int = 104
const TOOL_STORM_ION: int = 105
const TOOL_DIPLO_SPARK: int = 106
const TOOL_AI_GLITCH: int = 107
const TOOL_XENO_VIRUS: int = 108
const TOOL_BIO_SEEDER: int = 109
const TOOL_SETTLERS: int = 110

const TOOL_BIOME_LUSH: int = 201
const TOOL_BIOME_SCORCHED: int = 203
const TOOL_BIOME_XENO: int = 205
const TOOL_BIOME_CRYO: int = 206
const TOOL_BIOME_ACID: int = 207
const TOOL_BIOME_DUNES: int = 208
const TOOL_BIOME_OASIS: int = 209
const TOOL_BIOME_CREEP_MYC: int = 210
const TOOL_BIOME_CREEP_CYBER: int = 211

const TOOL_FAUNA_HERBIVORE: int = 300
const TOOL_FAUNA_PREDATOR: int = 301
const TOOL_FAUNA_INSECT: int = 302
const TOOL_BOSS_LEVIATHAN: int = 310
const TOOL_BOSS_UFO: int = 311
const TOOL_BOSS_NECRO: int = 312
const TOOL_BOSS_COLOSSUS: int = 313

const TOOL_MAGNET: int = 400
const TOOL_FLICK: int = 401
const TOOL_TRAIT_RAIN: int = 402
const TOOL_GEAR_RAIN: int = 403
const TOOL_MONOLITH: int = 404
const TOOL_GREY_GOO: int = 405
const TOOL_CONWAY: int = 406
const TOOL_BOMB: int = 407
const TOOL_TORNADO: int = 408
const TOOL_EARTHQUAKE: int = 409
const TOOL_GEYSER: int = 410
const TOOL_ERASER: int = 411
const TOOL_WALL: int = 412
const TOOL_DRAIN: int = 413

const TAB_EARTH: int = 0
const TAB_WEATHER: int = 1
const TAB_WAR: int = 2
const TAB_EVO: int = 3
const TAB_BIOMES: int = 4
const TAB_FAUNA: int = 5
const TAB_CREATOR: int = 6

const SHAPE_CIRCLE: int = 0
const SHAPE_SQUARE: int = 1
const SHAPE_DIAMOND: int = 2
const SHAPE_SPRAY: int = 3

const WIN_UNIT: int = 0
const WIN_CITY: int = 1
const WIN_WARS: int = 2
const WIN_LOG: int = 3
const WIN_GRAPHS: int = 4
const WIN_CODEX: int = 5

const SHAPE_DEFS: Array[Dictionary] = [
	{"id": SHAPE_CIRCLE, "icon": "shape_circle", "glyph": "●", "tip": "Форма кисти: Круг"},
	{"id": SHAPE_SQUARE, "icon": "shape_square", "glyph": "■", "tip": "Форма кисти: Квадрат"},
	{"id": SHAPE_DIAMOND, "icon": "shape_diamond", "glyph": "◆", "tip": "Форма кисти: Ромб"},
	{"id": SHAPE_SPRAY, "icon": "shape_spray", "glyph": "▒", "tip": "Форма кисти: Спрей-аэрозоль"},
]

const LENS_DEFS: Array[Dictionary] = [
	{"id": 0, "icon": "lens_kingdoms", "label": "Державы", "col": "#45E9FF", "tip": "Линза 1: Границы и центры держав"},
	{"id": 1, "icon": "lens_cities", "label": "Города", "col": "#5AE07E", "tip": "Линза 2: Зоны городов и форпостов"},
	{"id": 2, "icon": "lens_wars", "label": "Войны", "col": "#FF5B6B", "tip": "Линза 3: Фронты войн и альянсы"},
	{"id": 3, "icon": "lens_armies", "label": "Армии", "col": "#FFB347", "tip": "Линза 4: Полки, маршруты и флот"},
	{"id": 4, "icon": "lens_cultures", "label": "Культуры", "col": "#C275FF", "tip": "Линза 5: Культуры и идеологии"},
	{"id": 5, "icon": "lens_biomes", "label": "Биомы", "col": "#7EE89A", "tip": "Линза 6: Биомы и климат"},
	{"id": 6, "icon": "lens_tech", "label": "Техи", "col": "#5BC8FF", "tip": "Линза 7: Технологии и энергосеть"},
]

const WINDOW_DEFS: Array[Dictionary] = [
	{"id": WIN_UNIT, "icon": "win_unit", "label": "Юнит", "title": "КАРТОЧКА ЮНИТА", "tip": "Окно юнита: имя, черты, гены, снаряжение"},
	{"id": WIN_CITY, "icon": "win_city", "label": "Держава", "title": "ГОРОД И ДЕРЖАВА", "tip": "Окно города и королевства: ресурсы, армия, ноосфера"},
	{"id": WIN_WARS, "icon": "win_wars", "label": "Войны", "title": "ВОЙНЫ И АЛЬЯНСЫ", "tip": "Активные войны, потери, счёт и альянсы"},
	{"id": WIN_LOG, "icon": "win_log", "label": "Хроника", "title": "ХРОНИКА СЕКТОРА", "tip": "Полный фильтруемый журнал до 200 событий"},
	{"id": WIN_GRAPHS, "icon": "win_graphs", "label": "Графики", "title": "ИСТОРИЧЕСКИЕ ГРАФИКИ", "tip": "Динамика метрик мира на шкалах 10с / 60с / 600с"},
	{"id": WIN_CODEX, "icon": "win_codex", "label": "Кодекс", "title": "КОДЕКС И МИР", "tip": "40 достижений, 9 настроений Архитектора и 8 шаблонов карты"},
]

const BIOME_TOOL_DEFS: Array[Dictionary] = [
	{"id": TOOL_BIOME_LUSH, "icon": "bio_seeder", "label": "Луга", "tip": "Биом Луга: плодородная зелёная почва"},
	{"id": TOOL_BIOME_XENO, "icon": "xeno_virus", "label": "Ксенолес", "tip": "Биом Ксено-джунгли: густая ксенофлора"},
	{"id": TOOL_BIOME_CRYO, "icon": "lens_biomes", "label": "Тундра", "tip": "Биом Крио-тундра: ледяные хвойники"},
	{"id": TOOL_BIOME_ACID, "icon": "geyser", "label": "Кислота", "tip": "Биом Кислотные пустоши: едкая флора"},
	{"id": TOOL_BIOME_DUNES, "icon": "terraform", "label": "Дюны", "tip": "Биом Силикатные дюны: сухие пески"},
	{"id": TOOL_BIOME_OASIS, "icon": "crystal", "label": "Оазис", "tip": "Биом Биолюм-оазис: светящиеся споры"},
	{"id": TOOL_BIOME_SCORCHED, "icon": "fire", "label": "Пустошь", "tip": "Биом Выжженная пустошь: пепел и скалы"},
	{"id": TOOL_BIOME_CREEP_MYC, "icon": "spore", "label": "Мицелий", "tip": "Крип-биом Мицелий: расползается от узлов"},
	{"id": TOOL_BIOME_CREEP_CYBER, "icon": "ai_glitch", "label": "Киберкрип", "tip": "Крип-биом Кибер-сеть: техногенный крип"},
]

const FAUNA_TOOL_DEFS: Array[Dictionary] = [
	{"id": TOOL_FAUNA_HERBIVORE, "icon": "tab_fauna", "label": "Травоядн.", "tip": "Выпустить мирную/водную фауну (нажмите ещё раз или правее для смены вида)"},
	{"id": TOOL_FAUNA_PREDATOR, "icon": "xeno_virus", "label": "Хищники", "tip": "Выпустить хищных зверей (волк, медведь, раптор, кроко, скорпион)"},
	{"id": TOOL_FAUNA_INSECT, "icon": "bio_seeder", "label": "Рой", "tip": "Выпустить рои опылителей (пчела, жук, светляк)"},
	{"id": TOOL_BOSS_LEVIATHAN, "icon": "fire", "label": "Левиафан", "tip": "Мега-босс: Ксено-Левиафан с огненным дыханием"},
	{"id": TOOL_BOSS_UFO, "icon": "orbital", "label": "Дрон-НЛО", "tip": "Мега-босс: Орбитальный Дрон-Разрушитель"},
	{"id": TOOL_BOSS_NECRO, "icon": "diplo", "label": "Технонекр", "tip": "Мега-босс: Техно-Некромант (поднимает мутантов)"},
	{"id": TOOL_BOSS_COLOSSUS, "icon": "robot", "label": "Колосс", "tip": "Мега-босс: Кибер-Колосс"},
]

const CREATOR_TOOL_DEFS: Array[Dictionary] = [
	{"id": TOOL_MAGNET, "icon": "magnet", "label": "Магнит", "tip": "Грави-магнит: захват, перенос и бросок отряда"},
	{"id": TOOL_FLICK, "icon": "flick", "label": "Щелчок", "tip": "Кинетический щелчок: отбросить юнитов импульсом"},
	{"id": TOOL_TRAIT_RAIN, "icon": "trait_rain", "label": "Дождь черт", "tip": "Орбитальный дождь биочипов на юнитов"},
	{"id": TOOL_GEAR_RAIN, "icon": "gear_rain", "label": "Дождь снаряг", "tip": "Сброс оружия, брони и модулей на бойцов"},
	{"id": TOOL_MONOLITH, "icon": "monolith", "label": "Монолит", "tip": "Обелиск Возвышения: превращает фауну в разумный подвид"},
	{"id": TOOL_GREY_GOO, "icon": "grey_goo", "label": "Серая слизь", "tip": "Нано-слизь: поглощает сушу до шельфа"},
	{"id": TOOL_CONWAY, "icon": "conway", "label": "Conway", "tip": "Квантовый клеточный автомат Conway B3/S23"},
	{"id": TOOL_BOMB, "icon": "bomb", "label": "Бомба", "tip": "Плазмо-бомба с цепной детонацией"},
	{"id": TOOL_TORNADO, "icon": "tornado", "label": "Торнадо", "tip": "Блуждающий мега-вихрь стихии"},
	{"id": TOOL_EARTHQUAKE, "icon": "earthquake", "label": "Землетряс.", "tip": "Тектонический разлом земной коры"},
	{"id": TOOL_GEYSER, "icon": "geyser", "label": "Гейзер", "tip": "Открыть паровой или кислотный гейзер"},
	{"id": TOOL_WALL, "icon": "wall", "label": "Стена", "tip": "Энергостена / Скальный барьер"},
	{"id": TOOL_DRAIN, "icon": "drain", "label": "Осушитель", "tip": "Осушить воду, лаву или гарь"},
	{"id": TOOL_ERASER, "icon": "eraser", "label": "Ластик", "tip": "Очистить тайлы, огонь, постройки или юнитов"},
]

const HERBIVORE_SPECIES: Array[Dictionary] = [
	{"kind": 0, "name": "Олень"},
	{"kind": 1, "name": "Кролик"},
	{"kind": 2, "name": "Краб"},
	{"kind": 3, "name": "Рыба"},
	{"kind": 4, "name": "Черепаха"},
	{"kind": 5, "name": "Ксено-овца"},
]
const PREDATOR_SPECIES: Array[Dictionary] = [
	{"kind": 6, "name": "Волк"},
	{"kind": 7, "name": "Медведь"},
	{"kind": 8, "name": "Раптор"},
	{"kind": 9, "name": "Крокодил"},
	{"kind": 10, "name": "Скорпион"},
]
const INSECT_SPECIES: Array[Dictionary] = [
	{"kind": 11, "name": "Пчела"},
	{"kind": 12, "name": "Жук"},
	{"kind": 13, "name": "Светляк"},
]

const POSSESSION_CMDS: Array[Dictionary] = [
	{"cmd": "walk", "key": "WASD", "label": "Шаг"},
	{"cmd": "attack", "key": "ЛКМ", "label": "Атака"},
	{"cmd": "special", "key": "E", "label": "Реликт"},
	{"cmd": "yell", "key": "Space", "label": "Импульс"},
	{"cmd": "dash", "key": "Shift", "label": "Рывок"},
	{"cmd": "backstep", "key": "Q", "label": "Отскок"},
	{"cmd": "jump", "key": "R", "label": "Прыжок"},
	{"cmd": "kick", "key": "F", "label": "Удар"},
	{"cmd": "talk", "key": "T", "label": "Речь"},
	{"cmd": "exit", "key": "Esc", "label": "Выход ×"},
]

const TRAIT_DEFS: Array[Dictionary] = [
	{"id": 0, "name": "Мстительный", "tip": "Ищет кровную вендетту обидчику"},
	{"id": 1, "name": "Раскольник", "tip": "Склонен к расколам и мятежам"},
	{"id": 2, "name": "Пеплорождённый", "tip": "Выживает на лаве и в бурях"},
	{"id": 3, "name": "Ореол Демиурга", "tip": "Повышает мораль и стойкость союзников"},
	{"id": 4, "name": "Альфа-хищник", "tip": "Лидер стаи, усиливает натиск"},
	{"id": 5, "name": "Перегрузка ядра", "tip": "Взрыв реактора при гибели"},
	{"id": 6, "name": "Ион-купол", "tip": "Личный силовой щит"},
	{"id": 7, "name": "Гигантизм", "tip": "Крупный размер, +HP и урон"},
	{"id": 8, "name": "Микро-корпус", "tip": "Малый силуэт, высокое уклонение"},
	{"id": 9, "name": "Ускоритель", "tip": "+30% скорости движения"},
	{"id": 10, "name": "Ловкач", "tip": "Улучшенный уворот в бою"},
	{"id": 11, "name": "Регенератор", "tip": "Постоянное самовосстановление"},
	{"id": 12, "name": "Пироман", "tip": "Иммунитет к огню и зажигательные удары"},
	{"id": 13, "name": "Крио-кровь", "tip": "Охлаждает окружение и замедляет врагов"},
	{"id": 14, "name": "Вампиризм", "tip": "Восстанавливает HP от нанесённого урона"},
	{"id": 15, "name": "Бессмертный кор", "tip": "Не умирает от старости"},
	{"id": 16, "name": "Везунчик", "tip": "Повышенный шанс крита и уворота"},
	{"id": 17, "name": "Гений", "tip": "Ускоряет науку, заговоры и кодексы"},
	{"id": 18, "name": "Титан-мускул", "tip": "+35% к силе атаки"},
	{"id": 19, "name": "Бронекорпус", "tip": "+30% к поглощению урона"},
	{"id": 20, "name": "Отражатель", "tip": "Шанс вернуть вражеский выстрел"},
	{"id": 21, "name": "Псионик", "tip": "Волновые атаки по области"},
	{"id": 22, "name": "Заряд ядра", "tip": "Искры ЭМИ при атаках"},
	{"id": 23, "name": "Токсин-кровь", "tip": "Отравляет атакующих в ближнем бою"},
	{"id": 24, "name": "Шипы экзоскелета", "tip": "Возвращает часть контактного урона"},
	{"id": 25, "name": "Орлиный сканер", "tip": "+35% дальности стрельбы"},
	{"id": 26, "name": "Берсерк", "tip": "Урон растёт при низком HP"},
	{"id": 27, "name": "Пацифист", "tip": "Избегает агрессии, выше добыча"},
	{"id": 28, "name": "Рад-фильтр", "tip": "Иммунитет к радиационному урону"},
	{"id": 29, "name": "Сердце пустоты", "tip": "Высокая живучесть и пси-сопротивление"},
	{"id": 30, "name": "Разгон ядра", "tip": "Ускоренный темп работы и стрельбы"},
	{"id": 31, "name": "Хитин-панцирь", "tip": "Прочная природная броня"},
	{"id": 32, "name": "Маг-контур", "tip": "Устойчивость к магниту и отталкиванию"},
	{"id": 33, "name": "Ветеран", "tip": "Боевой опыт, повышенный урон и мораль"},
	{"id": 34, "name": "Чумной вектор", "tip": "Распространяет инфекцию при контакте"},
	{"id": 35, "name": "Шрам Творца", "tip": "Отметка прямого вмешательства Архитектора"},
]

const GENE_LABELS: Array[String] = [
	"Живучесть", "Мощь", "Ловкость", "Панцирь", "Интеллект",
	"Плодовитость", "Метаболизм", "Термостойкость", "Криостойкость", "Псионика",
]

const GRAPH_SCALES: Array[Dictionary] = [
	{"id": 0, "label": "10с"},
	{"id": 1, "label": "60с"},
	{"id": 2, "label": "600с"},
]

const GRAPH_METRICS: Array[Dictionary] = [
	{"key": "pop", "label": "Юниты", "col": "#45E9FF"},
	{"key": "cities", "label": "Города", "col": "#4BE898"},
	{"key": "wars", "label": "Войны", "col": "#FF5B6B"},
	{"key": "buildings", "label": "Постройки", "col": "#FFB347"},
	{"key": "science", "label": "Наука", "col": "#A86BFF"},
	{"key": "food", "label": "Еда", "col": "#88E852"},
	{"key": "ore", "label": "Руда", "col": "#5BC8FF"},
	{"key": "energy", "label": "Энергия", "col": "#FFE048"},
	{"key": "credits", "label": "Кредиты", "col": "#F0B121"},
	{"key": "deaths", "label": "Потери", "col": "#FF7A59"},
]

const MOOD_DEFS: Array[Dictionary] = [
	{"id": 0, "key": "serene", "name": "Безмятежный", "main": "#45E9FF", "text": "#E4EEF7", "border": "#367A9E", "desc": "Ровный бирюзовый горизонт наблюдателя"},
	{"id": 1, "key": "trickster", "name": "Трикстер", "main": "#FFB347", "text": "#FFF4DC", "border": "#B87828", "desc": "Янтарный ритм шалостей и интриг"},
	{"id": 2, "key": "benevolent", "name": "Благодетель", "main": "#4BE898", "text": "#E4FAF0", "border": "#2E9C66", "desc": "Изумрудное покровительство садам и колониям"},
	{"id": 3, "key": "malevolent", "name": "Каратель", "main": "#FF5B6B", "text": "#FFE8EA", "border": "#AE3444", "desc": "Багровый фокус орбитальных ударов"},
	{"id": 4, "key": "chaotic", "name": "Хаотичный", "main": "#C26BFF", "text": "#F5E8FF", "border": "#843CC2", "desc": "Фиолетовые вспышки аномалий и мутаций"},
	{"id": 5, "key": "orderly", "name": "Порядок", "main": "#6CD4FF", "text": "#E8F6FF", "border": "#3E84B2", "desc": "Чёткая синяя геометрия уставов и доктрин"},
	{"id": 6, "key": "mysterious", "name": "Загадочный", "main": "#7E8CFF", "text": "#ECEFFF", "border": "#4C58B8", "desc": "Индиго глубин космоса и монолитов"},
	{"id": 7, "key": "apathetic", "name": "Апатичный", "main": "#8EA3B8", "text": "#DCE5EE", "border": "#52667A", "desc": "Холодный стальной тон далёкой орбиты"},
	{"id": 8, "key": "ethereal", "name": "Эфирный", "main": "#64F5DA", "text": "#E6FFF9", "border": "#36A896", "desc": "Мягкое мятное свечение ноосферы"},
]

const TEMPLATE_DEFS: Array[Dictionary] = [
	{"id": 0, "name": "Континенты", "desc": "Сбалансированные материки и проливы"},
	{"id": 1, "name": "Пангея", "desc": "Единый сверхконтинент в океане"},
	{"id": 2, "name": "Архипелаг", "desc": "Десятки островов для флота и верфей"},
	{"id": 3, "name": "Атолл", "desc": "Кольцевой материк вокруг лагуны"},
	{"id": 4, "name": "Кратер", "desc": "Глубокий ударный бассейн с хребтами"},
	{"id": 5, "name": "Разлом", "desc": "Два берега по краям тектонического рва"},
	{"id": 6, "name": "Два мира", "desc": "Две полусферы с перешейком-мостом"},
	{"id": 7, "name": "Ледяной полюс", "desc": "Холодные полярные шапки и льды"},
]

const CODEX_DEFS: Array[Dictionary] = [
	{"id": "first_colony", "name": "Первый форпост", "desc": "Основана первая колония в секторе", "cat": "Цивилизация"},
	{"id": "megapolis_3", "name": "Три столпа", "desc": "В секторе одновременно 3+ города", "cat": "Цивилизация"},
	{"id": "megapolis_8", "name": "Созвездие городов", "desc": "В секторе одновременно 8+ городов", "cat": "Цивилизация"},
	{"id": "pop_100", "name": "Сотня душ", "desc": "Население планеты достигло 100 юнитов", "cat": "Цивилизация"},
	{"id": "pop_300", "name": "Живая планета", "desc": "Население планеты достигло 300 юнитов", "cat": "Цивилизация"},
	{"id": "tier_1", "name": "Кремний и железо", "desc": "Достигнут техно-уровень T1", "cat": "Наука"},
	{"id": "tier_3", "name": "Биокупола Кеплера", "desc": "Достигнут техно-уровень T3", "cat": "Наука"},
	{"id": "tier_5", "name": "Сингулярный зенит", "desc": "Достигнут максимальный уровень T5", "cat": "Наука"},
	{"id": "first_ship", "name": "Спуск на воду", "desc": "Построено первое судно или верфь", "cat": "Флот"},
	{"id": "armada_5", "name": "Морская армада", "desc": "На воде одновременно 5+ кораблей", "cat": "Флот"},
	{"id": "portal_jump", "name": "Квантовый мост", "desc": "Использованы квантовые врата", "cat": "Флот"},
	{"id": "first_war", "name": "Искра конфликта", "desc": "Началась первая война держав", "cat": "Дипломатия"},
	{"id": "world_war", "name": "Галактический пожар", "desc": "Одновременно идут 3+ войны", "cat": "Дипломатия"},
	{"id": "first_alliance", "name": "Единый пакт", "desc": "Заключён первый альянс или пакт", "cat": "Дипломатия"},
	{"id": "peace_treaty", "name": "Сложенные клинки", "desc": "Война завершена мирным договором", "cat": "Дипломатия"},
	{"id": "rebellion", "name": "Бунт окраин", "desc": "Колония подняла мятеж против столицы", "cat": "Дипломатия"},
	{"id": "plot_scheme", "name": "Тени заговора", "desc": "Запущен тайный заговор правителя", "cat": "Дипломатия"},
	{"id": "relic_taken", "name": "Хранитель реликта", "desc": "Добыта или передана древняя корона-реликт", "cat": "Герои"},
	{"id": "hero_duel", "name": "Честь клинка", "desc": "Зафиксирована дуэль именных героев", "cat": "Герои"},
	{"id": "rename_unit", "name": "Наречённый", "desc": "Дайте собственное имя выбранному юниту", "cat": "Герои"},
	{"id": "trait_editor", "name": "Биоинженер", "desc": "Измените черту-биочип через Карточку юнита", "cat": "Герои"},
	{"id": "possess_avatar", "name": "Воплощение", "desc": "Возьмите прямое управление юнитом [P]", "cat": "Архитектор"},
	{"id": "pin_watch", "name": "Наблюдатель", "desc": "Закрепите юнит или город в закладки [B]", "cat": "Архитектор"},
	{"id": "all_lenses", "name": "Всевидящее око", "desc": "Осмотрите мир через разные линзы карты", "cat": "Архитектор"},
	{"id": "biome_painter", "name": "Садовник миров", "desc": "Создайте новые биомы на планете", "cat": "Стихии"},
	{"id": "creep_seed", "name": "Голос роя", "desc": "Засейте мицелий или кибер-крип", "cat": "Стихии"},
	{"id": "fauna_ark", "name": "Ковчег Кеплера", "desc": "Призовите дикую ксенофауну", "cat": "Фауна"},
	{"id": "boss_spawn", "name": "Пробуждение титана", "desc": "Призовите мега-босса в мир", "cat": "Фауна"},
	{"id": "monolith_uplift", "name": "Искра разума", "desc": "Возвысьте животных через Монолит", "cat": "Ноосфера"},
	{"id": "culture_codex", "name": "Скрижаль знаний", "desc": "Зафиксирована культура или кодекс", "cat": "Ноосфера"},
	{"id": "trait_rain", "name": "Звёздная манна", "desc": "Обрушьте орбитальный дождь черт", "cat": "Творец"},
	{"id": "gear_rain", "name": "Арсенал с неба", "desc": "Сбросьте снаряжение на колонию", "cat": "Творец"},
	{"id": "magnet_play", "name": "Грави-жест", "desc": "Используйте грави-магнит или щелчок", "cat": "Творец"},
	{"id": "grey_goo_run", "name": "Серая волна", "desc": "Выпустите нано-слизь Grey Goo", "cat": "Творец"},
	{"id": "conway_life", "name": "Квантовая жизнь", "desc": "Запустите клеточный автомат Conway", "cat": "Творец"},
	{"id": "orbital_fire", "name": "Гнев орбиты", "desc": "Нанесите орбитальный удар или метеорит", "cat": "Стихии"},
	{"id": "cataclysm", "name": "Тектоника", "desc": "Вызовите торнадо, землетрясение или гейзер", "cat": "Стихии"},
	{"id": "mood_shift", "name": "Смена палитры", "desc": "Переключите Настроение Архитектора", "cat": "Архитектор"},
	{"id": "world_builder", "name": "Картограф", "desc": "Сгенерируйте планету по шаблону", "cat": "Архитектор"},
	{"id": "forbidden_core", "name": "Запретный Протокол", "desc": "Открыто 12+ записей Кодекса — доступ к чёрной сингулярности", "cat": "Запрет"},
]

var _hud_root: Node
var _main: Node
var _world: Node
var _civ: Node
var _physics: Node
var _fx: Node
var _laws_ui: RefCounted
var _bottom_dock: PanelContainer
var _top_bar: PanelContainer

var _icons_tex: Texture2D
var _icon_index: Dictionary = {}
var _icon_cell_w: int = 16
var _icon_cell_h: int = 16
var _icon_cache: Dictionary = {}

var _scroll_theme: Theme
var _style_panel: StyleBoxFlat
var _style_modal: StyleBoxFlat
var _style_card: StyleBoxFlat
var _style_btn_norm: StyleBoxFlat
var _style_btn_hov: StyleBoxFlat
var _style_btn_prs: StyleBoxFlat
var _style_btn_gold: StyleBoxFlat
var _style_btn_danger: StyleBoxFlat
var _style_input: StyleBoxFlat
var _style_input_focus: StyleBoxFlat

var _active_tool_id: int = TOOL_INSPECT
var _active_shape_id: int = SHAPE_CIRCLE
var _active_lens_id: int = 0
var _active_new_tab: int = -1
var _active_window_id: int = -1
var _selected_fauna_herb: int = 0
var _selected_fauna_pred: int = 0
var _selected_fauna_insect: int = 0
var _selected_trait_rain_id: int = 0
var _selected_gear_tier: int = 2
var _selected_template_id: int = 0
var _active_mood_id: int = 0
var _forbidden_active: bool = false

var _btn_speed_05: Button
var _btn_speed_40: Button
var _legacy_speed_btns: Array[Button] = []
var _legacy_tab_btns: Array[Button] = []
var _legacy_groups: Array[Control] = []

var _new_tab_btns: Dictionary = {}
var _shape_btns: Dictionary = {}
var _new_tool_btns: Dictionary = {}
var _group_biomes: Control
var _group_fauna: Control
var _group_creator: Control
var _fauna_species_btn: Button
var _creator_mod_btn: Button

var _lens_panel: PanelContainer
var _lens_btns: Dictionary = {}
var _lens_collapsed: bool = false
var _lens_collapse_btn: Button

var _win_panel: PanelContainer
var _win_rail_btns: Dictionary = {}

var _selected_bar: PanelContainer
var _sel_badge_dot: ColorRect
var _sel_title_lbl: Label
var _sel_sub_lbl: Label
var _sel_bars: Array[Dictionary] = []
var _sel_btn_details: Button
var _sel_btn_follow: Button
var _sel_btn_possess: Button
var _sel_btn_pin: Button
var _sel_btn_close: Button

var _possess_bar: PanelContainer
var _possess_btns: Array[Button] = []

var _modal_backdrop: ColorRect
var _modal_panel: PanelContainer
var _modal_icon: TextureRect
var _modal_title_lbl: Label
var _modal_counter_lbl: Label
var _modal_prev_btn: Button
var _modal_next_btn: Button
var _modal_close_btn: Button
var _modal_tab_row: HBoxContainer
var _modal_tab_btns: Dictionary = {}
var _modal_scroll: ScrollContainer
var _modal_body: VBoxContainer

var _unit_inspect_idx: int = 0
var _city_inspect_idx: int = 0
var _war_inspect_idx: int = 0
var _log_filter_cat: String = "all"
var _log_search_text: String = ""
var _log_filter_btns: Dictionary = {}
var _graph_scale_id: int = 0
var _graph_active_metrics: Array[String] = ["pop", "cities"]
var _graph_canvas: Control
var _codex_subtab: int = 0
var _unit_rename_edit: LineEdit
var _log_search_edit: LineEdit
var _log_list_box: VBoxContainer

var _cur_unit_info: Dictionary = {}
var _cur_city_info: Dictionary = {}
var _unlocked_codex: Dictionary = {}
var _codex_badge_lbl: Label
var _lenses_seen: Dictionary = {}

var _fallback_history: Dictionary = {}
var _history_sample_accum: float = 0.0
var _live_accum: float = 0.0
var _modal_refresh_accum: float = 0.0
var _last_log_count: int = -1
var _last_codex_count: int = -1
var _last_viewport_size: Vector2 = Vector2.ZERO
var _tweens: Array[Tween] = []


func setup(hud_root: Node, host_refs: Dictionary) -> void:
	_hud_root = hud_root
	_main = host_refs.get("main", null)
	_world = host_refs.get("world", null)
	_civ = host_refs.get("civ", null)
	_physics = host_refs.get("physics", null)
	_fx = host_refs.get("fx", null)
	_laws_ui = host_refs.get("laws_ui", null)
	_bottom_dock = host_refs.get("bottom_dock", null) as PanelContainer
	_top_bar = host_refs.get("top_bar", null) as PanelContainer

	_init_styles()
	_load_ui_atlas()
	_init_fallback_history()
	_setup_speed_buttons()
	_decorate_and_extend_bottom_dock()
	_build_left_rails()
	_build_selection_and_possession_bars()
	_build_modal_shell()
	_connect_laws_hook()
	_apply_architect_mood(0)
	sync_layouts()


func dispose() -> void:
	for tw in _tweens:
		if tw != null and is_instance_valid(tw):
			tw.kill()
	_tweens.clear()
	_icon_cache.clear()
	_icon_index.clear()
	_icons_tex = null
	_new_tab_btns.clear()
	_shape_btns.clear()
	_new_tool_btns.clear()
	_lens_btns.clear()
	_win_rail_btns.clear()
	_modal_tab_btns.clear()
	_log_filter_btns.clear()
	_sel_bars.clear()
	_possess_btns.clear()
	_legacy_speed_btns.clear()
	_legacy_tab_btns.clear()
	_legacy_groups.clear()
	_cur_unit_info.clear()
	_cur_city_info.clear()
	_unlocked_codex.clear()
	_lenses_seen.clear()
	_fallback_history.clear()
	_scroll_theme = null
	_style_panel = null
	_style_modal = null
	_style_card = null
	_style_btn_norm = null
	_style_btn_hov = null
	_style_btn_prs = null
	_style_btn_gold = null
	_style_btn_danger = null
	_style_input = null
	_style_input_focus = null
	_graph_canvas = null
	_unit_rename_edit = null
	_log_search_edit = null
	_log_list_box = null
	_modal_body = null
	_modal_scroll = null
	_modal_panel = null
	_modal_backdrop = null
	_selected_bar = null
	_possess_bar = null
	_lens_panel = null
	_win_panel = null
	_bottom_dock = null
	_top_bar = null
	_laws_ui = null
	_fx = null
	_physics = null
	_civ = null
	_world = null
	_main = null
	_hud_root = null


func handle_escape() -> bool:
	if _active_window_id >= 0:
		close_window()
		_play_ui_sfx("ui")
		return true
	return false


func has_open_modal() -> bool:
	return _active_window_id >= 0


func refresh_live(dt: float) -> void:
	if _hud_root == null:
		return
	var vp_sz: Vector2 = _get_viewport_size()
	if vp_sz != _last_viewport_size and vp_sz.x > 10.0:
		sync_layouts()
	_history_sample_accum += maxf(dt, 0.0)
	if _history_sample_accum >= 1.0:
		_history_sample_accum = 0.0
		_record_fallback_history_sample()
	_live_accum += maxf(dt, 0.0)
	_modal_refresh_accum += maxf(dt, 0.0)
	if _live_accum < 0.25:
		return
	_live_accum = 0.0
	_scan_passive_codex()
	_refresh_open_modal_live()


func _refresh_open_modal_live() -> void:
	if _active_window_id < 0 or _modal_body == null:
		return
	if _active_window_id == WIN_GRAPHS:
		if _graph_canvas != null:
			_graph_canvas.queue_redraw()
		return
	if _active_window_id == WIN_LOG:
		if _log_search_edit != null and is_instance_valid(_log_search_edit) and _log_search_edit.has_focus():
			return
		var cur_log_n: int = _get_chronicle_count()
		if cur_log_n != _last_log_count:
			_refresh_chronicle_list_only()
		return
	if _active_window_id == WIN_CODEX:
		if _unlocked_codex.size() != _last_codex_count:
			_refresh_modal_preserving_scroll()
		return
	if _active_window_id == WIN_UNIT and _unit_rename_edit != null and is_instance_valid(_unit_rename_edit) and _unit_rename_edit.has_focus():
		return
	if _modal_refresh_accum < 0.75:
		return
	_modal_refresh_accum = 0.0
	_refresh_modal_preserving_scroll()


func _refresh_modal_preserving_scroll() -> void:
	var prev_scroll: int = _modal_scroll.scroll_vertical if _modal_scroll != null else 0
	_refresh_active_window_contents()
	if _modal_scroll != null:
		_modal_scroll.set_deferred("scroll_vertical", prev_scroll)


func _get_chronicle_count() -> int:
	if _laws_ui != null and _laws_ui.has_method("get_all_chronicle_entries"):
		var raw: Variant = _laws_ui.call("get_all_chronicle_entries")
		if raw is Array:
			return (raw as Array).size()
	return 0


func update_selection_context(unit_info: Dictionary, city_info: Dictionary) -> void:
	_cur_unit_info = unit_info.duplicate(true) if unit_info != null else {}
	_cur_city_info = city_info.duplicate(true) if city_info != null else {}
	_refresh_selected_bar()
	_refresh_possession_bar()
	_sync_bottom_context_positions()
	if _active_window_id == WIN_UNIT or _active_window_id == WIN_CITY:
		_refresh_active_window_contents()


func notify_chronicle_event(ev_kind: String) -> void:
	var low: String = ev_kind.strip_edges().to_lower()
	if low == "":
		return
	if low.find("city") >= 0 or low.find("colony") >= 0 or low.find("found") >= 0:
		_unlock_codex("first_colony")
	if low.find("war") >= 0:
		_unlock_codex("first_war")
	if low.find("pact") >= 0 or low.find("alliance") >= 0:
		_unlock_codex("first_alliance")
	if low.find("peace") >= 0:
		_unlock_codex("peace_treaty")
	if low.find("rebel") >= 0:
		_unlock_codex("rebellion")
	if low.find("plot") >= 0:
		_unlock_codex("plot_scheme")
	if low.find("relic") >= 0:
		_unlock_codex("relic_taken")
	if low.find("duel") >= 0:
		_unlock_codex("hero_duel")
	if low.find("portal") >= 0:
		_unlock_codex("portal_jump")
	if low.find("ship") >= 0 or low.find("dock") >= 0:
		_unlock_codex("first_ship")
	if low.find("monolith") >= 0 or low.find("uplift") >= 0:
		_unlock_codex("monolith_uplift")
	if low.find("culture") >= 0 or low.find("codex") >= 0 or low.find("schism") >= 0:
		_unlock_codex("culture_codex")
	if low.find("boss") >= 0:
		_unlock_codex("boss_spawn")
	if low.find("tornado") >= 0 or low.find("earth") >= 0 or low.find("geyser") >= 0:
		_unlock_codex("cataclysm")
	if low.find("orbital") >= 0 or low.find("meteor") >= 0:
		_unlock_codex("orbital_fire")
	if low.find("goo") >= 0:
		_unlock_codex("grey_goo_run")
	if low.find("conway") >= 0:
		_unlock_codex("conway_life")


func get_active_brush_shape() -> int:
	return _active_shape_id


func get_active_map_lens() -> int:
	return _active_lens_id


func get_active_tool_id() -> int:
	return _active_tool_id


func get_selected_fauna_kind() -> int:
	if _active_tool_id == TOOL_FAUNA_PREDATOR:
		return int(PREDATOR_SPECIES[_selected_fauna_pred]["kind"])
	if _active_tool_id == TOOL_FAUNA_INSECT:
		return int(INSECT_SPECIES[_selected_fauna_insect]["kind"])
	if _active_tool_id == TOOL_BOSS_LEVIATHAN:
		return 14
	if _active_tool_id == TOOL_BOSS_UFO:
		return 15
	if _active_tool_id == TOOL_BOSS_NECRO:
		return 16
	if _active_tool_id == TOOL_BOSS_COLOSSUS:
		return 17
	return int(HERBIVORE_SPECIES[_selected_fauna_herb]["kind"])


func get_selected_trait_rain_id() -> int:
	return _selected_trait_rain_id


func get_selected_gear_tier() -> int:
	return _selected_gear_tier


func get_architect_mood_info() -> Dictionary:
	return MOOD_DEFS[clampi(_active_mood_id, 0, MOOD_DEFS.size() - 1)].duplicate()


func get_unlocked_codex_count() -> int:
	return _unlocked_codex.size()


func is_forbidden_unlocked() -> bool:
	return _unlocked_codex.size() >= 12 or _forbidden_active


func sync_active_tool(tool_id: int) -> void:
	_active_tool_id = tool_id
	for tid_v in _new_tool_btns.keys():
		var tid: int = int(tid_v)
		var btn: Button = _new_tool_btns[tid_v]
		if btn != null:
			btn.set_pressed_no_signal(tid == tool_id)
	var owner_new_tab: int = _new_tab_for_tool(tool_id)
	if owner_new_tab >= 0 and owner_new_tab != _active_new_tab:
		_select_new_tab(owner_new_tab)
	elif owner_new_tab < 0 and _active_new_tab >= 0 and _is_legacy_tab_owned_tool(tool_id):
		_hide_new_tab_groups()


func _is_legacy_tab_owned_tool(tool_id: int) -> bool:
	return (
		(tool_id >= TOOL_TERRAFORM and tool_id <= TOOL_ORBITAL_STRIKE)
		or (tool_id >= TOOL_STORM_RAIN and tool_id <= TOOL_BIO_SEEDER)
	)


func sync_sim_speed(speed_val: float) -> void:
	if _btn_speed_05 != null:
		_btn_speed_05.set_pressed_no_signal(is_equal_approx(speed_val, 0.5))
	if _btn_speed_40 != null:
		_btn_speed_40.set_pressed_no_signal(is_equal_approx(speed_val, 40.0))
	if not is_equal_approx(speed_val, 0.5) and not is_equal_approx(speed_val, 40.0):
		return
	for b in _legacy_speed_btns:
		if b != null:
			b.set_pressed_no_signal(false)


func open_window(win_id: int) -> void:
	var clamped: int = clampi(win_id, WIN_UNIT, WIN_CODEX)
	if _active_window_id == clamped and _modal_panel != null and _modal_panel.visible:
		close_window()
		return
	_active_window_id = clamped
	if _modal_backdrop != null:
		_modal_backdrop.visible = true
	if _modal_panel != null:
		_modal_panel.visible = true
	_sync_window_rail_buttons()
	_sync_modal_tab_buttons()
	_refresh_active_window_contents()
	sync_layouts()
	_play_ui_sfx("ui_tab")


func close_window() -> void:
	_active_window_id = -1
	if _modal_backdrop != null:
		_modal_backdrop.visible = false
	if _modal_panel != null:
		_modal_panel.visible = false
	_sync_window_rail_buttons()


func sync_layouts() -> void:
	if _hud_root == null:
		return
	var vp_sz: Vector2 = _get_viewport_size()
	_last_viewport_size = vp_sz
	if _top_bar != null:
		_top_bar.reset_size()
	if _bottom_dock != null:
		_bottom_dock.reset_size()
		var half_w: float = _bottom_dock.size.x * 0.5
		_bottom_dock.offset_left = -half_w
		_bottom_dock.offset_right = half_w
	var top_bottom: float = 46.0
	if _top_bar != null:
		top_bottom = _top_bar.position.y + _top_bar.size.y + 8.0
	if _lens_panel != null:
		_lens_panel.reset_size()
		_lens_panel.position = Vector2(12.0, roundf(top_bottom))
	if _win_panel != null and _lens_panel != null:
		_win_panel.reset_size()
		_win_panel.position = Vector2(12.0, roundf(_lens_panel.position.y + _lens_panel.size.y + 8.0))
	_sync_bottom_context_positions()
	if _modal_panel != null and _modal_panel.visible and vp_sz.x > 64.0 and vp_sz.y > 64.0:
		var mw: float = clampf(vp_sz.x - 160.0, 480.0, 680.0)
		var mh: float = clampf(vp_sz.y - 130.0, 320.0, 480.0)
		_modal_panel.custom_minimum_size = Vector2(mw, mh)
		_modal_panel.size = Vector2(mw, mh)
		_modal_panel.position = ((vp_sz - Vector2(mw, mh)) * 0.5).round()


func _sync_bottom_context_positions() -> void:
	var vp_sz: Vector2 = _get_viewport_size()
	var bottom_y: float = vp_sz.y - 70.0
	if _bottom_dock != null:
		bottom_y = vp_sz.y - _bottom_dock.size.y - 14.0
		if _bottom_dock.position.y > 40.0:
			bottom_y = _bottom_dock.position.y - 6.0
	if _selected_bar != null and _selected_bar.visible:
		_selected_bar.reset_size()
		var sw: float = _selected_bar.size.x
		var sh: float = _selected_bar.size.y
		_selected_bar.position = Vector2(roundf((vp_sz.x - sw) * 0.5), roundf(bottom_y - sh))
		bottom_y = _selected_bar.position.y - 6.0
	if _possess_bar != null and _possess_bar.visible:
		_possess_bar.reset_size()
		var pw: float = _possess_bar.size.x
		var ph: float = _possess_bar.size.y
		_possess_bar.position = Vector2(roundf((vp_sz.x - pw) * 0.5), roundf(bottom_y - ph))


func _get_viewport_size() -> Vector2:
	if _hud_root is Control:
		return (_hud_root as Control).get_viewport_rect().size
	if _top_bar != null:
		return _top_bar.get_viewport_rect().size
	return Vector2(1280.0, 720.0)


func _init_styles() -> void:
	_style_panel = _make_flat(Color(0.047, 0.075, 0.122, 0.90), Color(0.22, 0.42, 0.58, 0.78), 4, 7.0, 5.0)
	_style_panel.shadow_color = Color(0.01, 0.02, 0.05, 0.52)
	_style_panel.shadow_size = 6
	_style_panel.shadow_offset = Vector2(0.0, 3.0)

	_style_modal = _make_flat(Color(0.051, 0.082, 0.133, 0.96), Color(0.28, 0.56, 0.76, 0.88), 5, 12.0, 10.0)
	_style_modal.shadow_color = Color(0.01, 0.02, 0.04, 0.65)
	_style_modal.shadow_size = 10
	_style_modal.shadow_offset = Vector2(0.0, 5.0)

	_style_card = _make_flat(Color(0.075, 0.118, 0.184, 0.88), Color(0.18, 0.34, 0.48, 0.62), 3, 8.0, 6.0)
	_style_btn_norm = _make_flat(Color(0.082, 0.129, 0.196, 0.92), Color(0.20, 0.35, 0.48, 0.65), 3, 5.0, 3.0)
	_style_btn_hov = _make_flat(Color(0.129, 0.204, 0.302, 0.96), Color(0.36, 0.70, 0.88, 0.90), 3, 5.0, 3.0)
	_style_btn_prs = _make_flat(Color(0.094, 0.278, 0.376, 0.96), Color(0.28, 0.88, 0.98, 1.0), 3, 5.0, 3.0)
	_style_btn_gold = _make_flat(Color(0.30, 0.21, 0.06, 0.96), Color(0.98, 0.78, 0.28, 1.0), 3, 5.0, 3.0)
	_style_btn_danger = _make_flat(Color(0.32, 0.10, 0.13, 0.96), Color(0.92, 0.34, 0.40, 1.0), 3, 5.0, 3.0)
	_style_input = _make_flat(Color(0.039, 0.063, 0.102, 0.96), Color(0.22, 0.40, 0.56, 0.78), 3, 6.0, 4.0)
	_style_input_focus = _make_flat(Color(0.055, 0.090, 0.145, 0.98), Color(0.32, 0.86, 0.98, 1.0), 3, 6.0, 4.0)

	_scroll_theme = Theme.new()
	var sb_track: StyleBoxFlat = _make_flat(Color(0.035, 0.058, 0.098, 0.90), Color(0.16, 0.28, 0.40, 0.45), 3, 2.0, 2.0)
	var sb_grab: StyleBoxFlat = _make_flat(Color(0.24, 0.48, 0.68, 0.88), Color(0.40, 0.76, 0.92, 0.65), 3, 2.0, 2.0)
	var sb_hov: StyleBoxFlat = _make_flat(Color(0.36, 0.74, 0.92, 0.98), Color(0.54, 0.88, 0.98, 0.95), 3, 2.0, 2.0)
	_scroll_theme.set_stylebox("scroll", "VScrollBar", sb_track)
	_scroll_theme.set_stylebox("grabber", "VScrollBar", sb_grab)
	_scroll_theme.set_stylebox("grabber_highlight", "VScrollBar", sb_hov)
	_scroll_theme.set_stylebox("grabber_pressed", "VScrollBar", sb_hov)


func _make_flat(bg: Color, border: Color, rad: int, pad_x: float, pad_y: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(1 if border.a > 0.01 else 0)
	box.set_corner_radius_all(rad)
	box.content_margin_left = pad_x
	box.content_margin_right = pad_x
	box.content_margin_top = pad_y
	box.content_margin_bottom = pad_y
	return box


func _load_ui_atlas() -> void:
	_icon_index.clear()
	_icon_cache.clear()
	_icons_tex = null
	if FileAccess.file_exists(UI_ATLAS_JSON_PATH):
		var jf: FileAccess = FileAccess.open(UI_ATLAS_JSON_PATH, FileAccess.READ)
		if jf != null:
			var parsed: Variant = JSON.parse_string(jf.get_as_text())
			jf.close()
			if parsed is Dictionary:
				var d: Dictionary = parsed as Dictionary
				var cell_fallback: int = maxi(int(d.get("cell", d.get("tile_w", 16))), 8)
				var raw_csz: Variant = d.get("cell_size", null)
				if raw_csz is Array and (raw_csz as Array).size() >= 2:
					_icon_cell_w = maxi(int((raw_csz as Array)[0]), 8)
					_icon_cell_h = maxi(int((raw_csz as Array)[1]), 8)
				else:
					_icon_cell_w = maxi(int(d.get("cell_w", cell_fallback)), 8)
					_icon_cell_h = maxi(int(d.get("cell_h", cell_fallback)), 8)
				var raw_icons: Variant = d.get("icons", d.get("cols", {}))
				if raw_icons is Dictionary:
					for k in (raw_icons as Dictionary).keys():
						_icon_index[str(k)] = int((raw_icons as Dictionary)[k])
	if ResourceLoader.exists(UI_ATLAS_PNG_PATH):
		var res: Resource = ResourceLoader.load(UI_ATLAS_PNG_PATH)
		if res is Texture2D:
			_icons_tex = res as Texture2D
	elif FileAccess.file_exists(UI_ATLAS_PNG_PATH):
		var abs_path: String = ProjectSettings.globalize_path(UI_ATLAS_PNG_PATH)
		var img := Image.new()
		if img.load(abs_path) == OK and not img.is_empty():
			_icons_tex = ImageTexture.create_from_image(img)


func _get_icon(key: String) -> AtlasTexture:
	if _icons_tex == null or _icon_index.is_empty():
		return null
	if _icon_cache.has(key):
		return _icon_cache[key] as AtlasTexture
	var resolved_key: String = key
	if not _icon_index.has(resolved_key):
		var fallbacks: Dictionary = {
			"tab_creator": "monolith",
			"spore": "xeno_virus",
			"bio_seeder": "terraform",
		}
		resolved_key = str(fallbacks.get(key, ""))
		if resolved_key == "" or not _icon_index.has(resolved_key):
			return null
	var idx: int = int(_icon_index[resolved_key])
	if idx < 0:
		return null
	var tex_w: int = maxi(int(_icons_tex.get_width()), _icon_cell_w)
	var sheet_cols: int = maxi(tex_w / maxi(_icon_cell_w, 1), 1)
	var col_x: int = (idx % sheet_cols) * _icon_cell_w
	var row_y: int = (idx / sheet_cols) * _icon_cell_h
	var tex := AtlasTexture.new()
	tex.atlas = _icons_tex
	tex.region = Rect2(float(col_x), float(row_y), float(_icon_cell_w), float(_icon_cell_h))
	_icon_cache[key] = tex
	return tex


func _style_button(btn: Button, font_sz: int, pressed_box: StyleBoxFlat = null) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_color_override("font_color", Color("#E4EEF7"))
	btn.add_theme_color_override("font_hover_color", Color("#F5FAFF"))
	btn.add_theme_color_override("font_pressed_color", Color("#F8FCFF"))
	btn.add_theme_color_override("font_disabled_color", Color("#64788C"))
	btn.add_theme_stylebox_override("normal", _style_btn_norm)
	btn.add_theme_stylebox_override("hover", _style_btn_hov)
	btn.add_theme_stylebox_override("pressed", pressed_box if pressed_box != null else _style_btn_prs)
	btn.add_theme_stylebox_override("disabled", _style_card)


func _attach_hover_motion(btn: Button, tilt_deg: float) -> void:
	if btn == null or btn.has_meta("_hud_motion"):
		return
	btn.set_meta("_hud_motion", true)
	btn.mouse_entered.connect(_on_btn_hover_state.bind(btn, true, tilt_deg))
	btn.mouse_exited.connect(_on_btn_hover_state.bind(btn, false, 0.0))
	btn.pressed.connect(_on_btn_click_bounce.bind(btn))


func _kill_button_tween(btn: Button) -> void:
	if btn == null or not is_instance_valid(btn) or not btn.has_meta("_hud_tw"):
		return
	var old_tw: Variant = btn.get_meta("_hud_tw")
	if old_tw is Tween and is_instance_valid(old_tw):
		(old_tw as Tween).kill()


func _on_btn_hover_state(btn: Button, hovered: bool, tilt_deg: float) -> void:
	if btn == null or not is_instance_valid(btn) or not btn.is_inside_tree():
		return
	btn.pivot_offset = btn.size * 0.5
	_kill_button_tween(btn)
	var tw: Tween = btn.create_tween()
	tw.set_parallel(true)
	var target_scale: Vector2 = Vector2(1.07, 1.07) if hovered else Vector2.ONE
	var target_rot: float = deg_to_rad(tilt_deg) if hovered else 0.0
	tw.tween_property(btn, "scale", target_scale, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "rotation", target_rot, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	btn.set_meta("_hud_tw", tw)
	_tweens.append(tw)
	if _tweens.size() > 32:
		_tweens.remove_at(0)


func _on_btn_click_bounce(btn: Button) -> void:
	if btn == null or not is_instance_valid(btn) or not btn.is_inside_tree():
		return
	btn.pivot_offset = btn.size * 0.5
	_kill_button_tween(btn)
	btn.scale = Vector2(0.92, 0.92)
	var tw: Tween = btn.create_tween()
	tw.tween_property(btn, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	btn.set_meta("_hud_tw", tw)
	_tweens.append(tw)
	if _tweens.size() > 32:
		_tweens.remove_at(0)


func _setup_speed_buttons() -> void:
	if _top_bar == null:
		return
	var speed_row: HBoxContainer = _top_bar.get_node_or_null("TopRow/SpeedRow") as HBoxContainer
	if speed_row == null:
		return
	_legacy_speed_btns.clear()
	for child in speed_row.get_children():
		if child is Button:
			var b: Button = child as Button
			_legacy_speed_btns.append(b)
			b.pressed.connect(_on_legacy_speed_clicked)
			_attach_hover_motion(b, 0.0)

	_btn_speed_05 = Button.new()
	_btn_speed_05.name = "BtnSpeed05"
	_btn_speed_05.text = "0.5x"
	_btn_speed_05.toggle_mode = true
	_btn_speed_05.tooltip_text = "Замедление времени 0.5x (слоу-мо)"
	_style_button(_btn_speed_05, 11, _style_btn_prs)
	_btn_speed_05.pressed.connect(_on_extra_speed_clicked.bind(0.5))
	_attach_hover_motion(_btn_speed_05, 0.0)
	speed_row.add_child(_btn_speed_05)
	if speed_row.get_child_count() > 2:
		speed_row.move_child(_btn_speed_05, 1)

	_btn_speed_40 = Button.new()
	_btn_speed_40.name = "BtnSpeed40"
	_btn_speed_40.text = "40x"
	_btn_speed_40.toggle_mode = true
	_btn_speed_40.tooltip_text = "Гипер-ускорение времени 40x"
	_style_button(_btn_speed_40, 11, _style_btn_gold)
	_btn_speed_40.pressed.connect(_on_extra_speed_clicked.bind(40.0))
	_attach_hover_motion(_btn_speed_40, 0.0)
	speed_row.add_child(_btn_speed_40)


func _on_legacy_speed_clicked() -> void:
	if _btn_speed_05 != null:
		_btn_speed_05.set_pressed_no_signal(false)
	if _btn_speed_40 != null:
		_btn_speed_40.set_pressed_no_signal(false)


func _on_extra_speed_clicked(val: float) -> void:
	sync_sim_speed(val)
	speed_requested.emit(val)
	if speed_requested.get_connections().is_empty() and _main != null and _main.has_method("_set_sim_speed"):
		_main.call("_set_sim_speed", val)
	_play_ui_sfx("ui")


func _decorate_and_extend_bottom_dock() -> void:
	if _bottom_dock == null:
		return
	var icon_map: Dictionary = {
		"DockCols/RowTop/TabsRow/BtnTabEarth": ["tab_earth", -2.5],
		"DockCols/RowTop/TabsRow/BtnTabWeather": ["tab_weather", -2.5],
		"DockCols/RowTop/TabsRow/BtnTabWar": ["tab_war", -2.5],
		"DockCols/RowTop/TabsRow/BtnTabEvo": ["tab_evo", -2.5],
		"DockCols/RowTop/FactionRow/BtnFactionHuman": ["human", -3.0],
		"DockCols/RowTop/FactionRow/BtnFactionRobot": ["robot", -3.0],
		"DockCols/RowTop/FactionRow/BtnFactionSpore": ["spore", -3.0],
		"DockCols/RowBottom/GroupEarth/BtnTerraform": ["terraform", -3.5],
		"DockCols/RowBottom/GroupEarth/BtnCanal": ["canal", -3.5],
		"DockCols/RowBottom/GroupEarth/BtnCrystal": ["crystal", -3.5],
		"DockCols/RowBottom/GroupEarth/BtnLava": ["lava", -3.5],
		"DockCols/RowBottom/GroupWeather/BtnRain": ["rain", -3.5],
		"DockCols/RowBottom/GroupWeather/BtnFirestorm": ["fire", -3.5],
		"DockCols/RowBottom/GroupWeather/BtnIonStorm": ["ion", -3.5],
		"DockCols/RowBottom/GroupWar/BtnDiplo": ["diplo", -3.5],
		"DockCols/RowBottom/GroupWar/BtnOrbitalStrike": ["orbital", -3.5],
		"DockCols/RowBottom/GroupWar/BtnMeteor": ["meteor", -3.5],
		"DockCols/RowBottom/GroupWar/BtnVortex": ["vortex", -3.5],
		"DockCols/RowBottom/GroupEvo/BtnAiGlitch": ["ai_glitch", -3.5],
		"DockCols/RowBottom/GroupEvo/BtnXenoVirus": ["xeno_virus", -3.5],
		"DockCols/RowBottom/GroupEvo/BtnBioSeeder": ["bio_seeder", -3.5],
		"DockCols/RowBottom/BtnColony": ["colony", -3.5],
		"DockCols/RowBottom/BtnBless": ["bless", -3.5],
		"DockCols/RowBottom/BtnInspect": ["inspect", -3.5],
		"DockCols/RowBottom/BtnRegen": ["regen", -3.5],
	}
	for rel_path in icon_map.keys():
		var btn: Button = _bottom_dock.get_node_or_null(str(rel_path)) as Button
		if btn != null:
			var cfg: Array = icon_map[rel_path]
			var tex: AtlasTexture = _get_icon(str(cfg[0]))
			if tex != null:
				btn.icon = tex
				btn.expand_icon = false
			_attach_hover_motion(btn, float(cfg[1]))
	_hook_legacy_dock_controls()
	_add_new_tabs_and_shapes()
	_add_new_tool_groups()


func _hook_legacy_dock_controls() -> void:
	var tabs_row: HBoxContainer = _bottom_dock.get_node_or_null("DockCols/RowTop/TabsRow") as HBoxContainer
	_legacy_tab_btns.clear()
	if tabs_row != null:
		for child in tabs_row.get_children():
			if child is Button:
				var tb: Button = child as Button
				_legacy_tab_btns.append(tb)
				tb.pressed.connect(_on_legacy_tab_clicked)
	var row_bottom: HBoxContainer = _bottom_dock.get_node_or_null("DockCols/RowBottom") as HBoxContainer
	_legacy_groups.clear()
	if row_bottom != null:
		for g_name in ["GroupEarth", "GroupWeather", "GroupWar", "GroupEvo"]:
			var grp: Control = row_bottom.get_node_or_null(g_name) as Control
			if grp != null:
				_legacy_groups.append(grp)
		for child in row_bottom.get_children():
			if child is Button:
				(child as Button).pressed.connect(_on_legacy_tool_clicked)
			elif child is HBoxContainer:
				for sub in child.get_children():
					if sub is Button:
						(sub as Button).pressed.connect(_on_legacy_tool_clicked)
	var fac_row: HBoxContainer = _bottom_dock.get_node_or_null("DockCols/RowTop/FactionRow") as HBoxContainer
	if fac_row != null:
		for fb in fac_row.get_children():
			if fb is Button:
				(fb as Button).pressed.connect(_on_legacy_tool_clicked)
	var size_row: HBoxContainer = _bottom_dock.get_node_or_null("DockCols/RowTop/SizeRow") as HBoxContainer
	if size_row != null:
		for sb in size_row.get_children():
			if sb is Button:
				_attach_hover_motion(sb as Button, 0.0)


func _on_legacy_tab_clicked() -> void:
	_hide_new_tab_groups()
	sync_layouts()


func _on_legacy_tool_clicked() -> void:
	for tid_v in _new_tool_btns.keys():
		var btn: Button = _new_tool_btns[tid_v]
		if btn != null:
			btn.set_pressed_no_signal(false)


func _unpress_legacy_tool_buttons() -> void:
	if _bottom_dock == null:
		return
	var row_bottom: HBoxContainer = _bottom_dock.get_node_or_null("DockCols/RowBottom") as HBoxContainer
	if row_bottom != null:
		for child in row_bottom.get_children():
			if child is Button and (child as Button).toggle_mode:
				(child as Button).set_pressed_no_signal(false)
			elif child in _legacy_groups:
				for sub in child.get_children():
					if sub is Button and (sub as Button).toggle_mode:
						(sub as Button).set_pressed_no_signal(false)
	var fac_row: HBoxContainer = _bottom_dock.get_node_or_null("DockCols/RowTop/FactionRow") as HBoxContainer
	if fac_row != null:
		for fb in fac_row.get_children():
			if fb is Button and (fb as Button).toggle_mode:
				(fb as Button).set_pressed_no_signal(false)


func _add_new_tabs_and_shapes() -> void:
	var row_top: HBoxContainer = _bottom_dock.get_node_or_null("DockCols/RowTop") as HBoxContainer
	var tabs_row: HBoxContainer = _bottom_dock.get_node_or_null("DockCols/RowTop/TabsRow") as HBoxContainer
	if tabs_row != null:
		var tab_specs: Array[Dictionary] = [
			{"id": TAB_BIOMES, "name": "BtnTabBiomes", "text": "Биомы", "icon": "tab_biomes", "tip": "Вкладка: 7 биомов и крип-покрытия"},
			{"id": TAB_FAUNA, "name": "BtnTabFauna", "text": "Фауна", "icon": "tab_fauna", "tip": "Вкладка: травоядные, хищники, рои и боссы"},
			{"id": TAB_CREATOR, "name": "BtnTabCreator", "text": "Творец", "icon": "tab_creator", "tip": "Вкладка: Магнит, Монолит, Conway, Grey Goo, стихии"},
		]
		for spec in tab_specs:
			var tbtn := Button.new()
			tbtn.name = str(spec["name"])
			tbtn.text = str(spec["text"])
			tbtn.toggle_mode = true
			tbtn.tooltip_text = str(spec["tip"])
			_style_button(tbtn, 10, _style_btn_prs)
			var tex: AtlasTexture = _get_icon(str(spec["icon"]))
			if tex != null:
				tbtn.icon = tex
			var tid: int = int(spec["id"])
			tbtn.pressed.connect(_on_new_tab_clicked.bind(tid))
			_attach_hover_motion(tbtn, -2.5)
			tabs_row.add_child(tbtn)
			_new_tab_btns[tid] = tbtn

	if row_top != null:
		var sep_shape := VSeparator.new()
		sep_shape.name = "SepShape"
		row_top.add_child(sep_shape)
		var shape_row := HBoxContainer.new()
		shape_row.name = "ShapeRow"
		shape_row.add_theme_constant_override("separation", 2)
		row_top.add_child(shape_row)
		for sh in SHAPE_DEFS:
			var sid: int = int(sh["id"])
			var sbtn := Button.new()
			sbtn.toggle_mode = true
			sbtn.custom_minimum_size = Vector2(24.0, 22.0)
			sbtn.tooltip_text = str(sh["tip"])
			_style_button(sbtn, 11, _style_btn_prs)
			var stex: AtlasTexture = _get_icon(str(sh["icon"]))
			if stex != null:
				sbtn.icon = stex
				sbtn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			else:
				sbtn.text = str(sh["glyph"])
			sbtn.button_pressed = (sid == _active_shape_id)
			sbtn.pressed.connect(_on_shape_clicked.bind(sid))
			_attach_hover_motion(sbtn, 0.0)
			shape_row.add_child(sbtn)
			_shape_btns[sid] = sbtn


func _add_new_tool_groups() -> void:
	var row_bottom: HBoxContainer = _bottom_dock.get_node_or_null("DockCols/RowBottom") as HBoxContainer
	if row_bottom == null:
		return
	var sep_tools: Node = row_bottom.get_node_or_null("SepTools")
	var insert_idx: int = sep_tools.get_index() if sep_tools != null else row_bottom.get_child_count()

	_group_biomes = GridContainer.new()
	_group_biomes.name = "GroupBiomes"
	_group_biomes.visible = false
	(_group_biomes as GridContainer).columns = 5
	(_group_biomes as GridContainer).add_theme_constant_override("h_separation", 2)
	(_group_biomes as GridContainer).add_theme_constant_override("v_separation", 2)
	row_bottom.add_child(_group_biomes)
	row_bottom.move_child(_group_biomes, insert_idx)
	_populate_tool_container(_group_biomes, BIOME_TOOL_DEFS, _style_btn_prs)

	_group_fauna = GridContainer.new()
	_group_fauna.name = "GroupFauna"
	_group_fauna.visible = false
	(_group_fauna as GridContainer).columns = 4
	(_group_fauna as GridContainer).add_theme_constant_override("h_separation", 2)
	(_group_fauna as GridContainer).add_theme_constant_override("v_separation", 2)
	row_bottom.add_child(_group_fauna)
	row_bottom.move_child(_group_fauna, insert_idx + 1)
	_populate_tool_container(_group_fauna, FAUNA_TOOL_DEFS, _style_btn_gold)
	_fauna_species_btn = Button.new()
	_fauna_species_btn.text = "Вид: Олень ↻"
	_fauna_species_btn.tooltip_text = "Переключить подвид животных для выбранной категории"
	_style_button(_fauna_species_btn, 10, _style_btn_prs)
	_fauna_species_btn.pressed.connect(_on_cycle_fauna_species)
	_group_fauna.add_child(_fauna_species_btn)

	_group_creator = GridContainer.new()
	_group_creator.name = "GroupCreator"
	_group_creator.visible = false
	(_group_creator as GridContainer).columns = 7
	(_group_creator as GridContainer).add_theme_constant_override("h_separation", 2)
	(_group_creator as GridContainer).add_theme_constant_override("v_separation", 2)
	row_bottom.add_child(_group_creator)
	row_bottom.move_child(_group_creator, insert_idx + 2)
	_populate_tool_container(_group_creator, CREATOR_TOOL_DEFS, _style_btn_prs)

	_creator_mod_btn = Button.new()
	_creator_mod_btn.visible = false
	_creator_mod_btn.tooltip_text = "Выбрать черту для Дождя черт или тир для Дождя снаряжения"
	_style_button(_creator_mod_btn, 10, _style_btn_gold)
	_creator_mod_btn.pressed.connect(_on_cycle_creator_modifier)
	row_bottom.add_child(_creator_mod_btn)
	row_bottom.move_child(_creator_mod_btn, insert_idx + 3)


func _populate_tool_container(parent: Control, defs: Array[Dictionary], active_style: StyleBoxFlat) -> void:
	for spec in defs:
		var tid: int = int(spec["id"])
		var btn := Button.new()
		btn.text = str(spec["label"])
		btn.toggle_mode = true
		btn.tooltip_text = str(spec["tip"])
		_style_button(btn, 10, active_style)
		var tex: AtlasTexture = _get_icon(str(spec["icon"]))
		if tex != null:
			btn.icon = tex
		btn.pressed.connect(_on_new_tool_clicked.bind(tid))
		_attach_hover_motion(btn, -3.5)
		parent.add_child(btn)
		_new_tool_btns[tid] = btn


func _hide_new_tab_groups() -> void:
	_active_new_tab = -1
	if _group_biomes != null:
		_group_biomes.visible = false
	if _group_fauna != null:
		_group_fauna.visible = false
	if _group_creator != null:
		_group_creator.visible = false
	if _creator_mod_btn != null:
		_creator_mod_btn.visible = false
	for k in _new_tab_btns.keys():
		var b: Button = _new_tab_btns[k]
		if b != null:
			b.set_pressed_no_signal(false)


func _select_new_tab(tab_id: int) -> void:
	_active_new_tab = tab_id
	for grp in _legacy_groups:
		if grp != null:
			grp.visible = false
	for tb in _legacy_tab_btns:
		if tb != null:
			tb.set_pressed_no_signal(false)
	for k in _new_tab_btns.keys():
		var b: Button = _new_tab_btns[k]
		if b != null:
			b.set_pressed_no_signal(int(k) == tab_id)
	if _group_biomes != null:
		_group_biomes.visible = (tab_id == TAB_BIOMES)
	if _group_fauna != null:
		_group_fauna.visible = (tab_id == TAB_FAUNA)
	if _group_creator != null:
		_group_creator.visible = (tab_id == TAB_CREATOR)
	_refresh_creator_modifier_chip()
	sync_layouts()


func _on_new_tab_clicked(tab_id: int) -> void:
	_select_new_tab(tab_id)
	_play_ui_sfx("ui_tab")


func _on_shape_clicked(shape_id: int) -> void:
	_active_shape_id = clampi(shape_id, SHAPE_CIRCLE, SHAPE_SPRAY)
	for sid_v in _shape_btns.keys():
		var sb: Button = _shape_btns[sid_v]
		if sb != null:
			sb.set_pressed_no_signal(int(sid_v) == _active_shape_id)
	shape_changed.emit(_active_shape_id)
	_play_ui_sfx("ui")


func _on_new_tool_clicked(tool_id: int) -> void:
	if _active_tool_id == tool_id:
		if tool_id == TOOL_FAUNA_HERBIVORE or tool_id == TOOL_FAUNA_PREDATOR or tool_id == TOOL_FAUNA_INSECT:
			_on_cycle_fauna_species()
			var same_btn: Button = _new_tool_btns.get(tool_id, null)
			if same_btn != null:
				same_btn.set_pressed_no_signal(true)
			return
		sync_active_tool(TOOL_INSPECT)
		tool_requested.emit(TOOL_INSPECT)
		_play_ui_sfx("ui")
		return
	sync_active_tool(tool_id)
	_unpress_legacy_tool_buttons()
	_refresh_fauna_species_chip()
	_refresh_creator_modifier_chip()
	_track_tool_codex(tool_id)
	tool_requested.emit(tool_id)
	_play_ui_sfx("ui")


func _on_cycle_fauna_species() -> void:
	if _active_tool_id == TOOL_FAUNA_PREDATOR:
		_selected_fauna_pred = (_selected_fauna_pred + 1) % PREDATOR_SPECIES.size()
	elif _active_tool_id == TOOL_FAUNA_INSECT:
		_selected_fauna_insect = (_selected_fauna_insect + 1) % INSECT_SPECIES.size()
	else:
		_selected_fauna_herb = (_selected_fauna_herb + 1) % HERBIVORE_SPECIES.size()
	_refresh_fauna_species_chip()
	_play_ui_sfx("ui")


func _refresh_fauna_species_chip() -> void:
	if _fauna_species_btn == null:
		return
	var label_name: String = str(HERBIVORE_SPECIES[_selected_fauna_herb]["name"])
	if _active_tool_id == TOOL_FAUNA_PREDATOR:
		label_name = str(PREDATOR_SPECIES[_selected_fauna_pred]["name"])
	elif _active_tool_id == TOOL_FAUNA_INSECT:
		label_name = str(INSECT_SPECIES[_selected_fauna_insect]["name"])
	_fauna_species_btn.text = "Вид: %s ↻" % label_name


func _on_cycle_creator_modifier() -> void:
	if _active_tool_id == TOOL_TRAIT_RAIN:
		_selected_trait_rain_id = (_selected_trait_rain_id + 1) % TRAIT_DEFS.size()
	elif _active_tool_id == TOOL_GEAR_RAIN:
		_selected_gear_tier = (_selected_gear_tier + 1) % 6
	_refresh_creator_modifier_chip()
	_play_ui_sfx("ui")


func _refresh_creator_modifier_chip() -> void:
	if _creator_mod_btn == null:
		return
	if _active_new_tab != TAB_CREATOR:
		_creator_mod_btn.visible = false
		return
	if _active_tool_id == TOOL_TRAIT_RAIN:
		var tname: String = str(TRAIT_DEFS[clampi(_selected_trait_rain_id, 0, TRAIT_DEFS.size() - 1)]["name"])
		_creator_mod_btn.text = "Чип: %s ↻" % tname
		_creator_mod_btn.visible = true
	elif _active_tool_id == TOOL_GEAR_RAIN:
		_creator_mod_btn.text = "Тир: T%d ↻" % _selected_gear_tier
		_creator_mod_btn.visible = true
	else:
		_creator_mod_btn.visible = false


func _new_tab_for_tool(tool_id: int) -> int:
	if tool_id >= 200 and tool_id < 300:
		return TAB_BIOMES
	if tool_id >= 300 and tool_id < 400:
		return TAB_FAUNA
	if tool_id >= 400 and tool_id < 500:
		return TAB_CREATOR
	return -1


func _track_tool_codex(tool_id: int) -> void:
	if tool_id >= 201 and tool_id <= 209:
		_unlock_codex("biome_painter")
	elif tool_id == TOOL_BIOME_CREEP_MYC or tool_id == TOOL_BIOME_CREEP_CYBER:
		_unlock_codex("creep_seed")
	elif tool_id >= 300 and tool_id <= 302:
		_unlock_codex("fauna_ark")
	elif tool_id >= 310 and tool_id <= 313:
		_unlock_codex("boss_spawn")
	elif tool_id == TOOL_TRAIT_RAIN:
		_unlock_codex("trait_rain")
	elif tool_id == TOOL_GEAR_RAIN:
		_unlock_codex("gear_rain")
	elif tool_id == TOOL_MAGNET or tool_id == TOOL_FLICK:
		_unlock_codex("magnet_play")
	elif tool_id == TOOL_MONOLITH:
		_unlock_codex("monolith_uplift")
	elif tool_id == TOOL_GREY_GOO:
		_unlock_codex("grey_goo_run")
	elif tool_id == TOOL_CONWAY:
		_unlock_codex("conway_life")
	elif tool_id == TOOL_TORNADO or tool_id == TOOL_EARTHQUAKE or tool_id == TOOL_GEYSER:
		_unlock_codex("cataclysm")


func _build_left_rails() -> void:
	_lens_panel = PanelContainer.new()
	_lens_panel.name = "MapLensesPanel"
	_lens_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_lens_panel.add_theme_stylebox_override("panel", _style_panel)
	_hud_root.add_child(_lens_panel)

	var l_vbox := VBoxContainer.new()
	l_vbox.add_theme_constant_override("separation", 3)
	_lens_panel.add_child(l_vbox)

	var l_hdr := HBoxContainer.new()
	l_hdr.add_theme_constant_override("separation", 4)
	l_vbox.add_child(l_hdr)
	var l_title := Label.new()
	l_title.text = "ЛИНЗЫ"
	l_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_title.add_theme_font_size_override("font_size", 9)
	l_title.add_theme_color_override("font_color", Color("#7CE7FF"))
	l_hdr.add_child(l_title)
	_lens_collapse_btn = Button.new()
	_lens_collapse_btn.text = "«"
	_lens_collapse_btn.tooltip_text = "Свернуть или развернуть подписи линз"
	_style_button(_lens_collapse_btn, 10, _style_btn_prs)
	_lens_collapse_btn.custom_minimum_size = Vector2(20.0, 18.0)
	_lens_collapse_btn.pressed.connect(_on_toggle_lens_collapse)
	l_hdr.add_child(_lens_collapse_btn)

	for lens in LENS_DEFS:
		var lid: int = int(lens["id"])
		var btn := Button.new()
		btn.text = str(lens["label"])
		btn.toggle_mode = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.tooltip_text = str(lens["tip"])
		btn.custom_minimum_size = Vector2(92.0, 22.0)
		_style_button(btn, 10, _style_btn_prs)
		var ltex: AtlasTexture = _get_icon(str(lens["icon"]))
		if ltex != null:
			btn.icon = ltex
		btn.button_pressed = (lid == _active_lens_id)
		btn.pressed.connect(_on_lens_clicked.bind(lid))
		_attach_hover_motion(btn, 0.0)
		l_vbox.add_child(btn)
		_lens_btns[lid] = btn

	_win_panel = PanelContainer.new()
	_win_panel.name = "WindowsRailPanel"
	_win_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_win_panel.add_theme_stylebox_override("panel", _style_panel)
	_hud_root.add_child(_win_panel)

	var w_vbox := VBoxContainer.new()
	w_vbox.add_theme_constant_override("separation", 3)
	_win_panel.add_child(w_vbox)
	var w_hdr := HBoxContainer.new()
	w_hdr.add_theme_constant_override("separation", 4)
	w_vbox.add_child(w_hdr)
	var w_title := Label.new()
	w_title.text = "ОКНА"
	w_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	w_title.add_theme_font_size_override("font_size", 9)
	w_title.add_theme_color_override("font_color", Color("#7CE7FF"))
	w_hdr.add_child(w_title)
	_codex_badge_lbl = Label.new()
	_codex_badge_lbl.text = "0/40"
	_codex_badge_lbl.add_theme_font_size_override("font_size", 9)
	_codex_badge_lbl.add_theme_color_override("font_color", Color("#FFB347"))
	w_hdr.add_child(_codex_badge_lbl)

	for win in WINDOW_DEFS:
		var wid: int = int(win["id"])
		var wbtn := Button.new()
		wbtn.text = str(win["label"])
		wbtn.toggle_mode = true
		wbtn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		wbtn.tooltip_text = str(win["tip"])
		wbtn.custom_minimum_size = Vector2(92.0, 22.0)
		_style_button(wbtn, 10, _style_btn_prs)
		var wtex: AtlasTexture = _get_icon(str(win["icon"]))
		if wtex != null:
			wbtn.icon = wtex
		wbtn.pressed.connect(open_window.bind(wid))
		_attach_hover_motion(wbtn, 0.0)
		w_vbox.add_child(wbtn)
		_win_rail_btns[wid] = wbtn


func _on_toggle_lens_collapse() -> void:
	_lens_collapsed = not _lens_collapsed
	if _lens_collapse_btn != null:
		_lens_collapse_btn.text = "»" if _lens_collapsed else "«"
	for lens in LENS_DEFS:
		var lid: int = int(lens["id"])
		var btn: Button = _lens_btns.get(lid, null)
		if btn != null:
			btn.text = "" if _lens_collapsed else str(lens["label"])
			btn.custom_minimum_size = Vector2(28.0, 22.0) if _lens_collapsed else Vector2(92.0, 22.0)
	for win in WINDOW_DEFS:
		var wid: int = int(win["id"])
		var wbtn: Button = _win_rail_btns.get(wid, null)
		if wbtn != null:
			wbtn.text = "" if _lens_collapsed else str(win["label"])
			wbtn.custom_minimum_size = Vector2(28.0, 22.0) if _lens_collapsed else Vector2(92.0, 22.0)
	sync_layouts()
	_play_ui_sfx("ui")


func _on_lens_clicked(lens_id: int) -> void:
	_active_lens_id = clampi(lens_id, 0, LENS_DEFS.size() - 1)
	for lid_v in _lens_btns.keys():
		var lb: Button = _lens_btns[lid_v]
		if lb != null:
			lb.set_pressed_no_signal(int(lid_v) == _active_lens_id)
	_lenses_seen[_active_lens_id] = true
	if _lenses_seen.size() >= 3:
		_unlock_codex("all_lenses")
	lens_changed.emit(_active_lens_id)
	if lens_changed.get_connections().is_empty() and _civ != null and _civ.has_method("set_map_lens"):
		_civ.call("set_map_lens", _active_lens_id)
	_play_ui_sfx("ui_tab")


func _sync_window_rail_buttons() -> void:
	for wid_v in _win_rail_btns.keys():
		var wb: Button = _win_rail_btns[wid_v]
		if wb != null:
			wb.set_pressed_no_signal(int(wid_v) == _active_window_id)


func _build_selection_and_possession_bars() -> void:
	_selected_bar = PanelContainer.new()
	_selected_bar.name = "SelectedBar"
	_selected_bar.visible = false
	_selected_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_selected_bar.add_theme_stylebox_override("panel", _style_panel)
	_hud_root.add_child(_selected_bar)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_selected_bar.add_child(row)

	_sel_badge_dot = ColorRect.new()
	_sel_badge_dot.custom_minimum_size = Vector2(8.0, 26.0)
	_sel_badge_dot.color = Color("#45E9FF")
	row.add_child(_sel_badge_dot)

	var name_col := VBoxContainer.new()
	name_col.add_theme_constant_override("separation", 1)
	row.add_child(name_col)
	_sel_title_lbl = Label.new()
	_sel_title_lbl.add_theme_font_size_override("font_size", 11)
	_sel_title_lbl.add_theme_color_override("font_color", Color("#E4EEF7"))
	name_col.add_child(_sel_title_lbl)
	_sel_sub_lbl = Label.new()
	_sel_sub_lbl.add_theme_font_size_override("font_size", 9)
	_sel_sub_lbl.add_theme_color_override("font_color", Color("#9AB3C9"))
	name_col.add_child(_sel_sub_lbl)

	_sel_bars.clear()
	var bar_specs: Array[Dictionary] = [
		{"key": "hp", "label": "HP", "col": Color("#4BE898")},
		{"key": "hunger", "label": "Сыт.", "col": Color("#FFB347")},
		{"key": "moral", "label": "Мор.", "col": Color("#7CE7FF")},
		{"key": "shield", "label": "Щит", "col": Color("#A86BFF")},
	]
	for bs in bar_specs:
		_sel_bars.append(_create_micro_bar(row, str(bs["label"]), bs["col"] as Color))

	_sel_btn_details = Button.new()
	_sel_btn_details.text = "Детали"
	_style_button(_sel_btn_details, 10, _style_btn_prs)
	_sel_btn_details.pressed.connect(_on_selected_details)
	row.add_child(_sel_btn_details)

	_sel_btn_follow = Button.new()
	_sel_btn_follow.text = "Следить"
	_style_button(_sel_btn_follow, 10, _style_btn_prs)
	_sel_btn_follow.pressed.connect(_on_selected_follow)
	row.add_child(_sel_btn_follow)

	_sel_btn_possess = Button.new()
	_sel_btn_possess.text = "Аватар [P]"
	_style_button(_sel_btn_possess, 10, _style_btn_gold)
	_sel_btn_possess.pressed.connect(_on_selected_possess)
	row.add_child(_sel_btn_possess)

	_sel_btn_pin = Button.new()
	_sel_btn_pin.text = "В закл. [B]"
	_style_button(_sel_btn_pin, 10, _style_btn_prs)
	_sel_btn_pin.pressed.connect(_on_selected_pin)
	row.add_child(_sel_btn_pin)

	_sel_btn_close = Button.new()
	_sel_btn_close.text = "×"
	_sel_btn_close.tooltip_text = "Снять выделение [Esc]"
	_sel_btn_close.custom_minimum_size = Vector2(22.0, 22.0)
	_style_button(_sel_btn_close, 12, _style_btn_danger)
	_sel_btn_close.pressed.connect(_on_selected_clear)
	row.add_child(_sel_btn_close)

	_build_possession_hints_bar()


func _build_possession_hints_bar() -> void:
	_possess_bar = PanelContainer.new()
	_possess_bar.name = "PossessionHints"
	_possess_bar.visible = false
	_possess_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_possess_bar.add_theme_stylebox_override("panel", _style_panel)
	_hud_root.add_child(_possess_bar)

	var p_row := HBoxContainer.new()
	p_row.add_theme_constant_override("separation", 3)
	_possess_bar.add_child(p_row)
	var tag := Label.new()
	tag.text = "АВАТАР:"
	tag.add_theme_font_size_override("font_size", 10)
	tag.add_theme_color_override("font_color", Color("#FFB347"))
	p_row.add_child(tag)

	_possess_btns.clear()
	for spec in POSSESSION_CMDS:
		var cmd: String = str(spec["cmd"])
		var btn := Button.new()
		btn.text = "[%s] %s" % [str(spec["key"]), str(spec["label"])]
		_style_button(btn, 9, _style_btn_danger if cmd == "exit" else _style_btn_prs)
		btn.pressed.connect(_on_possession_cmd_clicked.bind(cmd))
		p_row.add_child(btn)
		_possess_btns.append(btn)


func _create_micro_bar(parent: Control, title_str: String, fill_col: Color) -> Dictionary:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.custom_minimum_size = Vector2(54.0, 0.0)
	parent.add_child(box)

	var lbl := Label.new()
	lbl.text = "%s: --" % title_str
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color("#C5D6E6"))
	box.add_child(lbl)

	var track := ColorRect.new()
	track.custom_minimum_size = Vector2(54.0, 5.0)
	track.color = Color(0.06, 0.10, 0.16, 0.95)
	box.add_child(track)

	var fill := ColorRect.new()
	fill.anchor_right = 1.0
	fill.anchor_bottom = 1.0
	fill.color = fill_col
	track.add_child(fill)
	return {"box": box, "track": track, "label": lbl, "title": title_str, "fill": fill, "color": fill_col}


func _set_micro_bar_val(bar: Dictionary, ratio: float, val_txt: String) -> void:
	var lbl: Label = bar.get("label", null) as Label
	var fill: ColorRect = bar.get("fill", null) as ColorRect
	if lbl != null:
		lbl.text = "%s: %s" % [str(bar.get("title", "")), val_txt]
	if fill != null:
		fill.anchor_right = clampf(ratio, 0.0, 1.0)


func _is_selection_locked() -> bool:
	if _main != null:
		var lu: Variant = _main.get("_locked_unit_uid")
		var lc: Variant = _main.get("_locked_city_id")
		var pu: Variant = _main.get("_possessing_uid")
		if (lu != null and int(lu) >= 0) or (lc != null and int(lc) >= 0) or (pu != null and int(pu) >= 0):
			return true
		if lu != null or lc != null or pu != null:
			return false
	return bool(_cur_unit_info.get("locked", false)) or bool(_cur_city_info.get("locked", false)) or bool(_cur_unit_info.get("possessed", false))


func _is_possessing_active() -> bool:
	if bool(_cur_unit_info.get("possessed", false)):
		return true
	if _main != null:
		var pu: Variant = _main.get("_possessing_uid")
		if pu != null and int(pu) >= 0:
			return true
	return false


func _refresh_selected_bar() -> void:
	if _selected_bar == null:
		return
	var u_ok: bool = bool(_cur_unit_info.get("found", false))
	var c_ok: bool = bool(_cur_city_info.get("found", false))
	var locked: bool = _is_selection_locked()
	if not locked or (not u_ok and not c_ok):
		_selected_bar.visible = false
		return
	_selected_bar.visible = true
	if u_ok:
		var uname: String = _resolve_unit_display_name(_cur_unit_info)
		_sel_title_lbl.text = uname
		_sel_sub_lbl.text = "%s · %s" % [str(_cur_unit_info.get("faction_name", "Юнит")), str(_cur_unit_info.get("role_name", "Скиталец"))]
		_sel_badge_dot.color = _faction_color(int(_cur_unit_info.get("faction", 0)))
		var hp: float = float(_cur_unit_info.get("hp", 100.0))
		var max_hp: float = maxf(float(_cur_unit_info.get("max_hp", 100.0)), 1.0)
		var sat: float = float(_cur_unit_info.get("satiety", 100.0 - float(_cur_unit_info.get("hunger", 15.0))))
		var mood_v: float = float(_cur_unit_info.get("mood", 75.0))
		var sh_v: float = float(_cur_unit_info.get("shield", 100.0 if _unit_has_trait(_cur_unit_info, 6) else 0.0))
		_set_micro_bar_val(_sel_bars[0], hp / max_hp, "%d" % int(round(hp)))
		_set_micro_bar_val(_sel_bars[1], sat / 100.0, "%d%%" % int(round(clampf(sat, 0.0, 100.0))))
		_set_micro_bar_val(_sel_bars[2], mood_v / 100.0, "%d%%" % int(round(clampf(mood_v, 0.0, 100.0))))
		_set_micro_bar_val(_sel_bars[3], sh_v / 100.0, "%d%%" % int(round(clampf(sh_v, 0.0, 100.0))))
		_sel_btn_possess.disabled = false
		_sel_btn_possess.text = "Выйти [P]" if _is_possessing_active() else "Аватар [P]"
	else:
		_sel_title_lbl.text = str(_cur_city_info.get("name", "Колония"))
		_sel_sub_lbl.text = "%s · Т%d/5 · Нас:%d" % [
			str(_cur_city_info.get("faction_name", "")),
			int(_cur_city_info.get("tech_tier", 0)),
			int(_cur_city_info.get("pop", 0)),
		]
		_sel_badge_dot.color = _faction_color(int(_cur_city_info.get("faction", 0)))
		var pop_f: float = float(_cur_city_info.get("pop", 0))
		var cap_f: float = maxf(float(_cur_city_info.get("housing_cap", 8)), 1.0)
		var food_f: float = float(_cur_city_info.get("food", 0.0))
		var loy_f: float = float(_cur_city_info.get("loyalty", 100.0))
		var has_sh: bool = bool(_cur_city_info.get("has_shield", false))
		_set_micro_bar_val(_sel_bars[0], pop_f / cap_f, "%d/%d" % [int(pop_f), int(cap_f)])
		_set_micro_bar_val(_sel_bars[1], minf(food_f / 120.0, 1.0), "%d" % int(round(food_f)))
		_set_micro_bar_val(_sel_bars[2], loy_f / 100.0, "%d%%" % int(round(loy_f)))
		_set_micro_bar_val(_sel_bars[3], 1.0 if has_sh else 0.0, "ВКЛ" if has_sh else "НЕТ")
		_sel_btn_possess.disabled = true
		_sel_btn_possess.text = "Аватар [P]"


func _refresh_possession_bar() -> void:
	if _possess_bar == null:
		return
	var active: bool = _is_possessing_active()
	_possess_bar.visible = active
	if active:
		_unlock_codex("possess_avatar")


func _on_selected_details() -> void:
	if bool(_cur_unit_info.get("found", false)):
		open_window(WIN_UNIT)
	elif bool(_cur_city_info.get("found", false)):
		open_window(WIN_CITY)


func _on_selected_follow() -> void:
	if bool(_cur_unit_info.get("found", false)):
		var uid: int = int(_cur_unit_info.get("uid", -1))
		var pos: Vector2 = _cur_unit_info.get("pos", Vector2(320.0, 180.0))
		follow_requested.emit("unit", uid, pos)
		if follow_requested.get_connections().is_empty() and _main != null:
			_main.set("_locked_unit_uid", uid)
			_main.set("_follow_locked_unit", true)
	elif bool(_cur_city_info.get("found", false)):
		var cid: int = int(_cur_city_info.get("city_id", -1))
		var cpos: Vector2 = _cur_city_info.get("center", Vector2(320.0, 180.0))
		follow_requested.emit("city", cid, cpos)
		if follow_requested.get_connections().is_empty() and _main != null:
			_main.set("_cam_focus_target", cpos)
			_main.set("_cam_focus_active", true)
	_play_ui_sfx("ui")


func _on_selected_possess() -> void:
	var uid: int = int(_cur_unit_info.get("uid", -1))
	if uid < 0:
		return
	possess_requested.emit(uid)
	if possess_requested.get_connections().is_empty() and _main != null and _main.has_method("_toggle_possession_hotkey"):
		_main.call("_toggle_possession_hotkey")
	_unlock_codex("possess_avatar")


func _on_selected_pin() -> void:
	pin_requested.emit()
	if pin_requested.get_connections().is_empty() and _main != null and _main.has_method("_pin_current_selection"):
		_main.call("_pin_current_selection")
	_unlock_codex("pin_watch")


func _on_selected_clear() -> void:
	selection_cleared.emit()
	if selection_cleared.get_connections().is_empty() and _main != null and _main.has_method("_clear_inspector_lock"):
		_main.call("_clear_inspector_lock")
	_cur_unit_info.clear()
	_cur_city_info.clear()
	_refresh_selected_bar()
	_refresh_possession_bar()
	_play_ui_sfx("ui")


func _on_possession_cmd_clicked(cmd: String) -> void:
	if cmd == "exit":
		if _main != null and _main.has_method("_exit_possession"):
			_main.call("_exit_possession")
		possess_requested.emit(-1)
		_refresh_possession_bar()
		_play_ui_sfx("ui")
		return
	if _physics != null and _physics.has_method("trigger_possession_command"):
		_physics.call("trigger_possession_command", cmd)
	elif cmd == "special" and _main != null:
		_main.set("_possess_alt_queued", true)
	elif cmd == "yell" and _main != null:
		_main.set("_possess_pulse_queued", true)
	elif cmd == "attack" and _main != null:
		_main.set("_possess_action_queued", true)
	_play_ui_sfx("ui")


func _build_modal_shell() -> void:
	_modal_backdrop = ColorRect.new()
	_modal_backdrop.name = "ScrollWindowBackdrop"
	_modal_backdrop.visible = false
	_modal_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_backdrop.color = Color(0.02, 0.035, 0.065, 0.42)
	_modal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_backdrop.gui_input.connect(_on_backdrop_gui_input)
	_hud_root.add_child(_modal_backdrop)

	_modal_panel = PanelContainer.new()
	_modal_panel.name = "ScrollWindowPanel"
	_modal_panel.visible = false
	_modal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_panel.add_theme_stylebox_override("panel", _style_modal)
	_hud_root.add_child(_modal_panel)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 6)
	_modal_panel.add_child(root_box)

	_build_modal_header(root_box)
	_build_modal_nav_tabs(root_box)
	_add_divider(root_box)

	_modal_scroll = ScrollContainer.new()
	_modal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_modal_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_modal_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_modal_scroll.theme = _scroll_theme
	root_box.add_child(_modal_scroll)

	_modal_body = VBoxContainer.new()
	_modal_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_body.add_theme_constant_override("separation", 8)
	_modal_scroll.add_child(_modal_body)


func _build_modal_header(parent: VBoxContainer) -> void:
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 6)
	parent.add_child(hdr)

	_modal_icon = TextureRect.new()
	_modal_icon.custom_minimum_size = Vector2(18.0, 18.0)
	_modal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hdr.add_child(_modal_icon)

	_modal_title_lbl = Label.new()
	_modal_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal_title_lbl.add_theme_font_size_override("font_size", 14)
	_modal_title_lbl.add_theme_color_override("font_color", Color("#7CE7FF"))
	hdr.add_child(_modal_title_lbl)

	_modal_prev_btn = Button.new()
	_modal_prev_btn.text = "<"
	_modal_prev_btn.tooltip_text = "Предыдущий объект / страница"
	_modal_prev_btn.custom_minimum_size = Vector2(26.0, 22.0)
	_style_button(_modal_prev_btn, 12, _style_btn_prs)
	_modal_prev_btn.pressed.connect(_on_modal_prev_next.bind(-1))
	hdr.add_child(_modal_prev_btn)

	_modal_counter_lbl = Label.new()
	_modal_counter_lbl.text = "1 / 1"
	_modal_counter_lbl.add_theme_font_size_override("font_size", 11)
	_modal_counter_lbl.add_theme_color_override("font_color", Color("#9AB3C9"))
	hdr.add_child(_modal_counter_lbl)

	_modal_next_btn = Button.new()
	_modal_next_btn.text = ">"
	_modal_next_btn.tooltip_text = "Следующий объект / страница"
	_modal_next_btn.custom_minimum_size = Vector2(26.0, 22.0)
	_style_button(_modal_next_btn, 12, _style_btn_prs)
	_modal_next_btn.pressed.connect(_on_modal_prev_next.bind(1))
	hdr.add_child(_modal_next_btn)

	_modal_close_btn = Button.new()
	_modal_close_btn.text = "×"
	_modal_close_btn.tooltip_text = "Закрыть окно [Esc]"
	_modal_close_btn.custom_minimum_size = Vector2(26.0, 22.0)
	_style_button(_modal_close_btn, 14, _style_btn_danger)
	_modal_close_btn.pressed.connect(_on_modal_close_pressed)
	hdr.add_child(_modal_close_btn)


func _build_modal_nav_tabs(parent: VBoxContainer) -> void:
	_modal_tab_row = HBoxContainer.new()
	_modal_tab_row.add_theme_constant_override("separation", 3)
	parent.add_child(_modal_tab_row)
	_modal_tab_btns.clear()
	for win in WINDOW_DEFS:
		var wid: int = int(win["id"])
		var tb := Button.new()
		tb.text = str(win["label"])
		tb.toggle_mode = true
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(tb, 10, _style_btn_prs)
		var tex: AtlasTexture = _get_icon(str(win["icon"]))
		if tex != null:
			tb.icon = tex
		tb.pressed.connect(open_window.bind(wid))
		_modal_tab_row.add_child(tb)
		_modal_tab_btns[wid] = tb


func _sync_modal_tab_buttons() -> void:
	for wid_v in _modal_tab_btns.keys():
		var tb: Button = _modal_tab_btns[wid_v]
		if tb != null:
			tb.set_pressed_no_signal(int(wid_v) == _active_window_id)
	if _active_window_id >= 0 and _active_window_id < WINDOW_DEFS.size():
		var wdef: Dictionary = WINDOW_DEFS[_active_window_id]
		_modal_title_lbl.text = str(wdef["title"])
		if _modal_icon != null:
			_modal_icon.texture = _get_icon(str(wdef["icon"]))


func _on_backdrop_gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			close_window()
			_play_ui_sfx("ui")


func _on_modal_close_pressed() -> void:
	close_window()
	_play_ui_sfx("ui")


func _on_modal_prev_next(delta_idx: int) -> void:
	if _active_window_id == WIN_UNIT:
		_unit_inspect_idx += delta_idx
		_cur_unit_info.clear()
	elif _active_window_id == WIN_CITY:
		_city_inspect_idx += delta_idx
		_cur_city_info.clear()
	elif _active_window_id == WIN_WARS:
		_war_inspect_idx += delta_idx
	elif _active_window_id == WIN_LOG:
		var cats: Array[String] = ["all", "war", "diplo", "city", "noosphere", "world"]
		var cur_i: int = maxi(cats.find(_log_filter_cat), 0)
		_log_filter_cat = cats[posmod(cur_i + delta_idx, cats.size())]
	elif _active_window_id == WIN_GRAPHS:
		_graph_scale_id = posmod(_graph_scale_id + delta_idx, GRAPH_SCALES.size())
	elif _active_window_id == WIN_CODEX:
		_codex_subtab = posmod(_codex_subtab + delta_idx, 3)
	_refresh_active_window_contents()
	_play_ui_sfx("ui_tab")


func _clear_modal_body() -> void:
	if _modal_body == null:
		return
	_unit_rename_edit = null
	_log_search_edit = null
	_log_list_box = null
	_graph_canvas = null
	_log_filter_btns.clear()
	for child in _modal_body.get_children():
		_modal_body.remove_child(child)
		child.queue_free()


func _refresh_active_window_contents() -> void:
	if _active_window_id < 0 or _modal_body == null:
		return
	_clear_modal_body()
	match _active_window_id:
		WIN_UNIT:
			_build_unit_window()
		WIN_CITY:
			_build_city_window()
		WIN_WARS:
			_build_wars_window()
		WIN_LOG:
			_build_chronicle_window()
		WIN_GRAPHS:
			_build_graphs_window()
		WIN_CODEX:
			_build_codex_window()


func _resolve_active_unit_dict() -> Dictionary:
	if bool(_cur_unit_info.get("found", false)):
		var uid: int = int(_cur_unit_info.get("uid", -1))
		if uid >= 0 and _physics != null and _physics.has_method("inspect_unit_by_id"):
			var live_u: Dictionary = _physics.call("inspect_unit_by_id", uid)
			if bool(live_u.get("found", false)):
				_modal_counter_lbl.text = "ID %d" % uid
				return live_u
		return _cur_unit_info
	if _physics != null:
		var u_cnt_v: Variant = _physics.get("_unit_count")
		var u_uids_v: Variant = _physics.get("_u_uid")
		if u_cnt_v != null and int(u_cnt_v) > 0 and u_uids_v is PackedInt32Array:
			var u_cnt: int = mini(int(u_cnt_v), (u_uids_v as PackedInt32Array).size())
			if u_cnt > 0:
				var idx: int = posmod(_unit_inspect_idx, u_cnt)
				var pick_uid: int = (u_uids_v as PackedInt32Array)[idx]
				if _physics.has_method("inspect_unit_by_id"):
					var picked_u: Dictionary = _physics.call("inspect_unit_by_id", pick_uid)
					if bool(picked_u.get("found", false)):
						_modal_counter_lbl.text = "%d / %d" % [idx + 1, u_cnt]
						return picked_u
	if _physics != null and _physics.has_method("get_first_unit_pos") and _physics.has_method("inspect_unit_at"):
		var pos_v: Variant = _physics.call("get_first_unit_pos")
		if pos_v is Vector2 and (pos_v as Vector2).x >= 0.0:
			var first_u: Dictionary = _physics.call("inspect_unit_at", pos_v)
			if bool(first_u.get("found", false)):
				_modal_counter_lbl.text = "1 / 1"
				return first_u
	_modal_counter_lbl.text = "0 / 0"
	return {"found": false}


func _build_unit_window() -> void:
	var u: Dictionary = _resolve_active_unit_dict()
	if not bool(u.get("found", false)):
		_add_empty_notice(_modal_body, "Юнит не выбран. Кликните по существу инструментом Инсп или нажмите > для поиска.")
		return
	var uid: int = int(u.get("uid", -1))
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	_modal_body.add_child(name_row)

	_unit_rename_edit = LineEdit.new()
	_unit_rename_edit.text = _resolve_unit_display_name(u)
	_unit_rename_edit.placeholder_text = "Имя юнита..."
	_unit_rename_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_unit_rename_edit.add_theme_font_size_override("font_size", 12)
	_unit_rename_edit.add_theme_color_override("font_color", Color("#E4EEF7"))
	_unit_rename_edit.add_theme_color_override("caret_color", Color("#45E9FF"))
	_unit_rename_edit.add_theme_color_override("selection_color", Color(0.22, 0.56, 0.74, 0.65))
	_unit_rename_edit.add_theme_stylebox_override("normal", _style_input)
	_unit_rename_edit.add_theme_stylebox_override("focus", _style_input_focus)
	_unit_rename_edit.text_submitted.connect(_on_unit_name_submitted.bind(uid))
	name_row.add_child(_unit_rename_edit)

	var btn_save := Button.new()
	btn_save.text = "Переименовать"
	_style_button(btn_save, 10, _style_btn_prs)
	btn_save.pressed.connect(_on_unit_rename_btn.bind(uid))
	name_row.add_child(btn_save)

	var btn_focus := Button.new()
	btn_focus.text = "Камера"
	_style_button(btn_focus, 10, _style_btn_prs)
	var upos: Vector2 = u.get("pos", Vector2(320.0, 180.0))
	btn_focus.pressed.connect(_focus_camera_on.bind(upos))
	name_row.add_child(btn_focus)

	_add_unit_stats_section(u)
	_add_unit_traits_section(u, uid)
	_add_unit_gear_section(u)
	_add_unit_genes_section(u)
	_add_unit_memory_section(u)


func _on_unit_name_submitted(new_text: String, uid: int) -> void:
	var clean: String = new_text.strip_edges()
	if clean == "" or uid < 0:
		return
	if _physics != null and _physics.has_method("set_unit_custom_name"):
		_physics.call("set_unit_custom_name", uid, clean)
	_cur_unit_info["custom_name"] = clean
	_cur_unit_info["notable_name"] = clean
	_unlock_codex("rename_unit")
	_refresh_selected_bar()
	_play_ui_sfx("ui_pin")


func _on_unit_rename_btn(uid: int) -> void:
	if _unit_rename_edit != null:
		_on_unit_name_submitted(_unit_rename_edit.text, uid)


func _add_unit_stats_section(u: Dictionary) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style_card)
	_modal_body.add_child(card)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	card.add_child(grid)
	var lines: Array[String] = [
		"Роль: %s" % str(u.get("role_name", "Скиталец")),
		"Фракция: %s" % str(u.get("faction_name", "Люди")),
		"Подвид: %s" % str(u.get("subspecies", u.get("faction_name", "Базовый"))),
		"HP: %d / %d" % [int(round(float(u.get("hp", 100.0)))), int(round(float(u.get("max_hp", 100.0))))],
		"Фраги: %d · Уклон: %d" % [int(u.get("kills", 0)), int(u.get("dodges", 0))],
		"Настр.: %d%% · Голод: %d%%" % [int(round(float(u.get("mood", 75.0)))), int(round(float(u.get("hunger", 15.0))))],
		"Радиация: %.2f" % float(u.get("rad_exposure", 0.0)),
		"Урон x%.2f" % float(u.get("dmg_mul", 1.0)),
		"Задача: %s" % str(u.get("task_name", "Idle")),
	]
	for s in lines:
		var lbl := Label.new()
		lbl.text = s
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color("#E4EEF7"))
		grid.add_child(lbl)


func _add_unit_traits_section(u: Dictionary, uid: int) -> void:
	_add_section_header(_modal_body, "ЧЕРТЫ И БИОЧИПЫ (клик: выдать / снять)")
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	_modal_body.add_child(grid)

	for spec in TRAIT_DEFS:
		var tid: int = int(spec["id"])
		var has_t: bool = _unit_has_trait(u, tid)
		var btn := Button.new()
		btn.text = str(spec["name"])
		btn.toggle_mode = true
		btn.button_pressed = has_t
		btn.tooltip_text = str(spec["tip"])
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(btn, 10, _style_btn_gold if tid == 35 else _style_btn_prs)
		btn.pressed.connect(_on_unit_trait_toggled.bind(uid, tid))
		grid.add_child(btn)


func _on_unit_trait_toggled(uid: int, trait_id: int) -> void:
	if uid < 0:
		return
	if _physics != null and _physics.has_method("toggle_unit_trait"):
		_physics.call("toggle_unit_trait", uid, trait_id)
	else:
		var mask: int = int(_cur_unit_info.get("trait_mask", 0))
		mask = mask ^ (1 << trait_id)
		_cur_unit_info["trait_mask"] = mask
	_unlock_codex("trait_editor")
	_refresh_active_window_contents()
	_play_ui_sfx("ui_pin")


func _add_unit_gear_section(u: Dictionary) -> void:
	_add_section_header(_modal_body, "СНАРЯЖЕНИЕ (3 слота)")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_modal_body.add_child(row)
	var slot_titles: Array[String] = ["Оружие", "Броня", "Модуль"]
	var raw_eq: Variant = u.get("equipment", [])
	for i in range(3):
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _style_card)
		row.add_child(card)
		var slot_text: String = "— Пусто —"
		if raw_eq is Array and i < (raw_eq as Array).size():
			var entry: Variant = (raw_eq as Array)[i]
			if entry is Dictionary:
				var ed: Dictionary = entry as Dictionary
				if not bool(ed.get("empty", false)):
					var ename: String = str(ed.get("name", ""))
					if ename != "" and ename != "Пусто":
						var mat_n: String = str(ed.get("material_name", ""))
						var rar_n: String = str(ed.get("rarity_name", "R%d" % int(ed.get("rarity", 0))))
						slot_text = "%s\n[%s · %s · %dф]" % [ename, mat_n, rar_n, int(ed.get("kills", 0))]
			elif str(entry) != "":
				slot_text = str(entry)
		elif raw_eq is Dictionary and (raw_eq as Dictionary).has(slot_titles[i]):
			slot_text = str((raw_eq as Dictionary)[slot_titles[i]])
		var lbl := Label.new()
		lbl.text = "%s: %s" % [slot_titles[i], slot_text]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color("#E4EEF7") if slot_text != "— Пусто —" else Color("#7F96AC"))
		card.add_child(lbl)


func _add_unit_genes_section(u: Dictionary) -> void:
	_add_section_header(_modal_body, "ГЕНОМ ПОДВИДА (10 локусов)")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	_modal_body.add_child(grid)
	var raw_genes: Variant = u.get("genes", [])
	var fac: int = int(u.get("faction", 0))
	for i in range(10):
		var val: float = float(1 + ((fac * 2 + i) % 4))
		var g_label: String = GENE_LABELS[i]
		var syn: bool = false
		if raw_genes is Array and i < (raw_genes as Array).size():
			var gv: Variant = (raw_genes as Array)[i]
			if gv is Dictionary:
				var gd: Dictionary = gv as Dictionary
				g_label = str(gd.get("name", g_label))
				val = float(gd.get("value", gd.get("val", val)))
				syn = bool(gd.get("synergy", false))
			else:
				val = float(gv)
		var bar := _create_micro_bar(grid, g_label, Color("#4BE898") if syn else Color("#7CE7FF"))
		var box_node: VBoxContainer = bar.get("box", null) as VBoxContainer
		if box_node != null:
			box_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var track_node: ColorRect = bar.get("track", null) as ColorRect
		if track_node != null:
			track_node.custom_minimum_size = Vector2(180.0, 5.0)
			track_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ratio: float = clampf(val / 5.0, 0.0, 1.0) if val <= 6.0 else clampf(val / 100.0, 0.0, 1.0)
		var val_txt: String = ("%d/5%s" % [int(round(val)), " ★" if syn else ""]) if val <= 6.0 else ("%d" % int(round(val)))
		_set_micro_bar_val(bar, ratio, val_txt)


func _add_unit_memory_section(u: Dictionary) -> void:
	_add_section_header(_modal_body, "ВОСПОМИНАНИЯ (до 8 слотов)")
	var mem_raw: Variant = u.get("memory", [])
	var lines: Array[String] = []
	if mem_raw is Array:
		for m in (mem_raw as Array):
			var s: String = str(m).strip_edges()
			if s != "":
				lines.append(s)
	if lines.is_empty():
		_add_empty_notice(_modal_body, "У этого юнита пока нет значимых воспоминаний.")
		return
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style_card)
	_modal_body.add_child(card)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)
	var limit: int = mini(lines.size(), 8)
	for i in range(limit):
		var lbl := Label.new()
		lbl.text = "• %s" % lines[lines.size() - 1 - i]
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color("#C5D6E6"))
		vbox.add_child(lbl)


func _resolve_active_city_dict() -> Dictionary:
	if bool(_cur_city_info.get("found", false)):
		var cpos: Vector2 = _cur_city_info.get("center", Vector2(-1.0, -1.0))
		if cpos.x >= 0.0 and _civ != null and _civ.has_method("inspect_city_at"):
			var live_c: Dictionary = _civ.call("inspect_city_at", cpos)
			if bool(live_c.get("found", false)):
				_modal_counter_lbl.text = "Город #%d" % int(live_c.get("city_id", 0))
				return live_c
		return _cur_city_info
	if _civ != null and _civ.has_method("get_city_roster"):
		var roster: Variant = _civ.call("get_city_roster")
		if roster is Array and not (roster as Array).is_empty():
			var r_arr: Array = roster as Array
			var idx: int = posmod(_city_inspect_idx, r_arr.size())
			_modal_counter_lbl.text = "%d / %d" % [idx + 1, r_arr.size()]
			if r_arr[idx] is Dictionary:
				return r_arr[idx] as Dictionary
	if _civ != null and _civ.has_method("get_primary_city_pos") and _civ.has_method("inspect_city_at"):
		var ppos: Variant = _civ.call("get_primary_city_pos")
		if ppos is Vector2 and (ppos as Vector2) != Vector2.ZERO:
			var pc: Dictionary = _civ.call("inspect_city_at", ppos)
			if bool(pc.get("found", false)):
				_modal_counter_lbl.text = "1 / 1"
				return pc
	_modal_counter_lbl.text = "0 / 0"
	return {"found": false}


func _build_city_window() -> void:
	var c: Dictionary = _resolve_active_city_dict()
	if not bool(c.get("found", false)):
		_add_empty_notice(_modal_body, "В секторе пока нет основанных колоний и держав.")
		return
	var cid: int = int(c.get("city_id", -1))
	var c_pos: Vector2 = c.get("center", Vector2(320.0, 180.0))

	var top_card := PanelContainer.new()
	top_card.add_theme_stylebox_override("panel", _style_card)
	_modal_body.add_child(top_card)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	top_card.add_child(hbox)
	var title_lbl := Label.new()
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.text = "%s (%s) · Держава: %s · Т%d/5" % [
		str(c.get("name", "Колония")),
		str(c.get("faction_name", "Люди")),
		str(c.get("kingdom_name", "—")),
		int(c.get("tech_tier", 0)),
	]
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", Color("#7CE7FF"))
	hbox.add_child(title_lbl)
	var btn_cam := Button.new()
	btn_cam.text = "К городу"
	_style_button(btn_cam, 10, _style_btn_prs)
	btn_cam.pressed.connect(_focus_camera_on.bind(c_pos))
	hbox.add_child(btn_cam)

	_add_section_header(_modal_body, "РЕСУРСЫ ГОРОДА И ТЕХНОЛОГИИ")
	var res_grid := GridContainer.new()
	res_grid.columns = 5
	res_grid.add_theme_constant_override("h_separation", 8)
	_modal_body.add_child(res_grid)
	var res_items: Array[Array] = [
		["Еда", int(round(float(c.get("food", 0.0))))],
		["Руда", int(round(float(c.get("ore", 0.0))))],
		["Энергия", int(round(float(c.get("energy", 0.0))))],
		["Наука", int(round(float(c.get("science", 0.0))))],
		["Кредиты", int(round(float(c.get("credits", 0.0))))],
	]
	for ri in res_items:
		var box := PanelContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_stylebox_override("panel", _style_card)
		res_grid.add_child(box)
		var l := Label.new()
		l.text = "%s\n%d" % [str(ri[0]), int(ri[1])]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 11)
		l.add_theme_color_override("font_color", Color("#E4EEF7"))
		box.add_child(l)

	_add_city_kingdom_meta_section(c, cid)
	_add_city_roster_chips(c)


func _add_city_kingdom_meta_section(c: Dictionary, cid: int) -> void:
	_add_section_header(_modal_body, "АРМИИ, КЛАН, НООСФЕРА И ДИПЛОМАТИЯ")
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style_card)
	_modal_body.add_child(card)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var clan_n: String = str(c.get("clan_name", ""))
	var cult_n: String = str(c.get("culture_name", ""))
	var creed_n: String = str(c.get("creed_name", ""))
	var ships_n: int = int(c.get("ships", 0))
	var armies_n: int = int(c.get("armies", c.get("army_count", 0)))
	var kid: int = int(c.get("kingdom_id", -1))
	if kid >= 0 and _civ != null and _civ.has_method("get_kingdom_roster"):
		var kr: Variant = _civ.call("get_kingdom_roster")
		if kr is Array:
			for kitem in (kr as Array):
				if kitem is Dictionary and int((kitem as Dictionary).get("kingdom_id", -2)) == kid:
					var kd: Dictionary = kitem as Dictionary
					if clan_n == "":
						clan_n = str(kd.get("clan_name", "Основатели"))
					if cult_n == "":
						cult_n = str(kd.get("culture_name", "Доктрина"))
					if creed_n == "":
						creed_n = str(kd.get("creed_name", "Гармония"))
					ships_n = maxi(ships_n, int(kd.get("ships", 0)))
					armies_n = maxi(armies_n, int(kd.get("armies", 0)))
					break
	var lines: Array[String] = [
		"Население: %d / %d · Здания: %d (Доки:%d Каз:%d Тур:%d Арх:%d) · Стройка: %s" % [
			int(c.get("pop", 0)), int(c.get("housing_cap", 0)),
			int(c.get("buildings", 0)), int(c.get("docks", 0)),
			int(c.get("barracks", 0)), int(c.get("turrets", 0)),
			int(c.get("archives", 0)), str(c.get("project", "Нет")),
		],
		"Армии и флот: Полки=%d · Корабли=%d · Энергия Δ=%.1f" % [
			armies_n, ships_n, float(c.get("energy_net", 0.0)),
		],
		"Клан: %s · Культура: %s · Идеология: %s" % [
			clan_n if clan_n != "" else "Основатели",
			cult_n if cult_n != "" else "Доктрина Сектора",
			creed_n if creed_n != "" else "Гармония Орбиты",
		],
		"Лояльность: %.0f%% (%s) · Войны: %d · Пакты: %d" % [
			float(c.get("loyalty", 100.0)),
			str(c.get("loyalty_reason", "Стабильно")),
			int(c.get("war_partners", 0)),
			int(c.get("pact_partners", 0)),
		],
	]
	_append_city_diplomacy_lines(lines, cid)
	for s in lines:
		var lbl := Label.new()
		lbl.text = s
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color("#C5D6E6"))
		vbox.add_child(lbl)


func _append_city_diplomacy_lines(lines: Array[String], cid: int) -> void:
	if cid < 0 or _civ == null or not _civ.has_method("get_diplomacy_factors") or not _civ.has_method("get_city_roster"):
		return
	var raw_r: Variant = _civ.call("get_city_roster")
	if not (raw_r is Array):
		return
	var other_cid: int = -1
	var other_name: String = ""
	for item in (raw_r as Array):
		if item is Dictionary:
			var ocid: int = int((item as Dictionary).get("city_id", -1))
			if ocid >= 0 and ocid != cid:
				other_cid = ocid
				other_name = str((item as Dictionary).get("name", "Сосед"))
				break
	if other_cid < 0:
		return
	var df_v: Variant = _civ.call("get_diplomacy_factors", cid, other_cid)
	if not (df_v is Dictionary) or not bool((df_v as Dictionary).get("found", false)):
		return
	var df: Dictionary = df_v as Dictionary
	var parts: PackedStringArray = []
	var op_f: Variant = df.get("opinion_factors", [])
	if op_f is Array:
		for f in (op_f as Array):
			if f is Dictionary:
				parts.append("%s (%+.0f)" % [str((f as Dictionary).get("label", "")), float((f as Dictionary).get("delta", 0.0))])
	lines.append("Отношения с %s [%s, мнение %+.0f]: %s" % [
		other_name, str(df.get("state_name", "—")), float(df.get("opinion_total", 0.0)), ", ".join(parts)
	])


func _add_city_roster_chips(active_city: Dictionary) -> void:
	if _civ == null or not _civ.has_method("get_city_roster"):
		return
	var raw: Variant = _civ.call("get_city_roster")
	if not (raw is Array) or (raw as Array).is_empty():
		return
	_add_section_header(_modal_body, "ГОРОДА СЕКТОРА")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	_modal_body.add_child(grid)
	var active_cid: int = int(active_city.get("city_id", -1))
	var arr: Array = raw as Array
	for idx in range(mini(arr.size(), 18)):
		var item: Variant = arr[idx]
		if not (item is Dictionary):
			continue
		var d: Dictionary = item as Dictionary
		var btn := Button.new()
		btn.text = "%s (Н:%d)" % [str(d.get("name", "Город")), int(d.get("pop", 0))]
		btn.toggle_mode = true
		btn.button_pressed = (int(d.get("city_id", -2)) == active_cid)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(btn, 10, _style_btn_prs)
		btn.pressed.connect(_on_city_chip_picked.bind(idx, d))
		grid.add_child(btn)


func _on_city_chip_picked(idx: int, city_d: Dictionary) -> void:
	_city_inspect_idx = idx
	_cur_city_info = city_d.duplicate(true)
	_refresh_active_window_contents()


func _build_wars_window() -> void:
	var wars: Array = _fetch_wars_list()
	var alliances: Array = _fetch_alliances_list()
	_modal_counter_lbl.text = "В:%d · С:%d" % [wars.size(), alliances.size()]

	_add_section_header(_modal_body, "АКТИВНЫЕ ВОЙНЫ (%d)" % wars.size())
	if wars.is_empty():
		_add_empty_notice(_modal_body, "В секторе сейчас царит мир — активных войн нет.")
	else:
		for w in wars:
			if w is Dictionary:
				_add_war_row(_modal_body, w as Dictionary)

	_add_section_header(_modal_body, "АЛЬЯНСЫ И СОЮЗЫ (%d)" % alliances.size())
	if alliances.is_empty():
		_add_empty_notice(_modal_body, "Междержавные альянсы пока не сформированы.")
	else:
		for al in alliances:
			if al is Dictionary:
				_add_alliance_row(_modal_body, al as Dictionary)


func _fetch_wars_list() -> Array:
	if _civ != null and _civ.has_method("get_wars_summary"):
		var raw: Variant = _civ.call("get_wars_summary")
		if raw is Array:
			return raw as Array
	var fallback: Array = []
	if _civ != null and _civ.has_method("get_diplomacy_links"):
		var links: Variant = _civ.call("get_diplomacy_links")
		if links is Array:
			for item in (links as Array):
				if item is Dictionary and int((item as Dictionary).get("state", 0)) >= 2:
					var d: Dictionary = item as Dictionary
					fallback.append({
						"name": "Вооружённый конфликт",
						"type": "Мятеж" if int(d.get("state", 0)) == 3 else "Тотальная",
						"attackers": str(d.get("name_a", "Сторона A")),
						"defenders": str(d.get("name_b", "Сторона B")),
						"score": 0,
						"casualties": 0,
						"duration_sec": 0.0,
						"focus_pos": d.get("pos_a", Vector2(320.0, 180.0)),
					})
	return fallback


func _fetch_alliances_list() -> Array:
	if _civ != null and _civ.has_method("get_alliances_summary"):
		var raw: Variant = _civ.call("get_alliances_summary")
		if raw is Array:
			return raw as Array
	var fallback: Array = []
	if _civ != null and _civ.has_method("get_diplomacy_links"):
		var links: Variant = _civ.call("get_diplomacy_links")
		if links is Array:
			for item in (links as Array):
				if item is Dictionary and int((item as Dictionary).get("state", 0)) == 1:
					var d: Dictionary = item as Dictionary
					fallback.append({
						"name": "Пакт %s — %s" % [str(d.get("name_a", "A")), str(d.get("name_b", "B"))],
						"members": 2,
						"age_sec": 0.0,
						"focus_pos": d.get("pos_a", Vector2(320.0, 180.0)),
					})
	return fallback


func _add_war_row(parent: Control, w: Dictionary) -> void:
	var btn := Button.new()
	var wtype: String = str(w.get("type_name", w.get("kind_name", w.get("type", "Война"))))
	var atk: String = str(w.get("attacker_name", w.get("attackers", "Агрессор")))
	var defn: String = str(w.get("defender_name", w.get("defenders", "Защитник")))
	var score: float = float(w.get("score", 0.0))
	var loss: int = int(w.get("casualties", 0))
	var dur: float = float(w.get("duration", w.get("duration_sec", w.get("age_sec", 0.0))))
	btn.text = "[%s] %s vs %s  |  Счёт: %+.0f · Потери: %d · %.0fс" % [wtype, atk, defn, score, loss, dur]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.tooltip_text = "Клик: сфокусировать камеру на очаге войны"
	_style_button(btn, 10, _style_btn_danger)
	var fpos: Vector2 = w.get("pos", w.get("focus_pos", Vector2(320.0, 180.0)))
	btn.pressed.connect(_focus_camera_on.bind(fpos))
	parent.add_child(btn)


func _add_alliance_row(parent: Control, al: Dictionary) -> void:
	var btn := Button.new()
	var aname: String = str(al.get("name", "Альянс Сектора"))
	var cnt: int = int(al.get("member_count", 2))
	var age: float = float(al.get("age", al.get("age_sec", 0.0)))
	btn.text = "%s  |  Держав: %d · Срок: %.0fс" % [aname, cnt, age]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.tooltip_text = "Клик: сфокусировать камеру на столице альянса"
	_style_button(btn, 10, _style_btn_prs)
	var fpos: Vector2 = al.get("pos", al.get("focus_pos", Vector2(320.0, 180.0)))
	btn.pressed.connect(_focus_camera_on.bind(fpos))
	parent.add_child(btn)


func _build_chronicle_window() -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	_modal_body.add_child(bar)
	var filters: Array[Array] = [
		["all", "Все"],
		["war", "Войны"],
		["diplo", "Интриги"],
		["city", "Города"],
		["noosphere", "Ноосфера"],
		["world", "Мир"],
	]
	for f in filters:
		var fkey: String = str(f[0])
		var fbtn := Button.new()
		fbtn.text = str(f[1])
		fbtn.toggle_mode = true
		fbtn.button_pressed = (_log_filter_cat == fkey)
		_style_button(fbtn, 10, _style_btn_prs)
		fbtn.pressed.connect(_on_log_filter_clicked.bind(fkey))
		bar.add_child(fbtn)
		_log_filter_btns[fkey] = fbtn

	_log_search_edit = LineEdit.new()
	_log_search_edit.text = _log_search_text
	_log_search_edit.placeholder_text = "Фильтр текста..."
	_log_search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_search_edit.add_theme_font_size_override("font_size", 11)
	_log_search_edit.add_theme_color_override("font_color", Color("#E4EEF7"))
	_log_search_edit.add_theme_color_override("caret_color", Color("#45E9FF"))
	_log_search_edit.add_theme_stylebox_override("normal", _style_input)
	_log_search_edit.add_theme_stylebox_override("focus", _style_input_focus)
	_log_search_edit.text_changed.connect(_on_log_search_changed)
	bar.add_child(_log_search_edit)

	_log_list_box = VBoxContainer.new()
	_log_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_list_box.add_theme_constant_override("separation", 3)
	_modal_body.add_child(_log_list_box)
	_refresh_chronicle_list_only()


func _refresh_chronicle_list_only() -> void:
	if _log_list_box == null:
		return
	for ch in _log_list_box.get_children():
		_log_list_box.remove_child(ch)
		ch.queue_free()

	var entries: Array[Dictionary] = []
	if _laws_ui != null and _laws_ui.has_method("get_all_chronicle_entries"):
		var raw: Variant = _laws_ui.call("get_all_chronicle_entries")
		if raw is Array:
			for e in (raw as Array):
				if e is Dictionary:
					entries.append(e as Dictionary)
	_last_log_count = entries.size()

	var matched: Array[Dictionary] = []
	var q: String = _log_search_text.strip_edges().to_lower()
	for i in range(entries.size() - 1, -1, -1):
		var ev: Dictionary = entries[i]
		if _log_filter_cat != "all" and str(ev.get("category", "world")) != _log_filter_cat:
			continue
		var txt: String = str(ev.get("text", ""))
		if q != "" and txt.to_lower().find(q) < 0:
			continue
		matched.append(ev)

	_modal_counter_lbl.text = "%d / %d" % [matched.size(), entries.size()]
	if matched.is_empty():
		_add_empty_notice(_log_list_box, "В журнале нет событий под выбранный фильтр.")
		return
	for ev in matched:
		var tsec: int = int(round(float(ev.get("time_sec", 0.0))))
		var row_btn := Button.new()
		row_btn.text = "[%02d:%02d] %s" % [tsec / 60, tsec % 60, str(ev.get("text", ""))]
		row_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_button(row_btn, 10, _style_btn_prs)
		var col: Color = ev.get("color", Color("#E4EEF7"))
		row_btn.add_theme_color_override("font_color", col.lightened(0.25))
		var epos: Vector2 = ev.get("pos", Vector2(320.0, 180.0))
		row_btn.pressed.connect(_focus_camera_on.bind(epos))
		_log_list_box.add_child(row_btn)


func _on_log_filter_clicked(cat_key: String) -> void:
	_log_filter_cat = cat_key
	for k in _log_filter_btns.keys():
		var fb: Button = _log_filter_btns[k]
		if fb != null:
			fb.set_pressed_no_signal(str(k) == _log_filter_cat)
	_refresh_chronicle_list_only()


func _on_log_search_changed(new_txt: String) -> void:
	_log_search_text = new_txt
	_refresh_chronicle_list_only()


func _build_graphs_window() -> void:
	var scale_row := HBoxContainer.new()
	scale_row.add_theme_constant_override("separation", 4)
	_modal_body.add_child(scale_row)
	var s_lbl := Label.new()
	s_lbl.text = "Шкала:"
	s_lbl.add_theme_font_size_override("font_size", 11)
	s_lbl.add_theme_color_override("font_color", Color("#9AB3C9"))
	scale_row.add_child(s_lbl)
	for sc in GRAPH_SCALES:
		var sid: int = int(sc["id"])
		var btn := Button.new()
		btn.text = str(sc["label"])
		btn.toggle_mode = true
		btn.button_pressed = (_graph_scale_id == sid)
		_style_button(btn, 10, _style_btn_prs)
		btn.pressed.connect(_on_graph_scale_clicked.bind(sid))
		scale_row.add_child(btn)

	var legend_lbl := Label.new()
	legend_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legend_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	legend_lbl.text = "Серий: %d / 3" % _graph_active_metrics.size()
	legend_lbl.add_theme_font_size_override("font_size", 10)
	legend_lbl.add_theme_color_override("font_color", Color("#7CE7FF"))
	scale_row.add_child(legend_lbl)
	_modal_counter_lbl.text = str(GRAPH_SCALES[clampi(_graph_scale_id, 0, GRAPH_SCALES.size() - 1)]["label"])

	var met_grid := GridContainer.new()
	met_grid.columns = 5
	met_grid.add_theme_constant_override("h_separation", 4)
	met_grid.add_theme_constant_override("v_separation", 4)
	_modal_body.add_child(met_grid)
	for m in GRAPH_METRICS:
		var mkey: String = str(m["key"])
		var mbtn := Button.new()
		mbtn.text = str(m["label"])
		mbtn.toggle_mode = true
		mbtn.button_pressed = (_graph_active_metrics.has(mkey))
		mbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(mbtn, 10, _style_btn_prs)
		if mbtn.button_pressed:
			mbtn.add_theme_color_override("font_color", Color(str(m["col"])))
		mbtn.pressed.connect(_on_graph_metric_clicked.bind(mkey))
		met_grid.add_child(mbtn)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _style_card)
	_modal_body.add_child(frame)
	_graph_canvas = Control.new()
	_graph_canvas.custom_minimum_size = Vector2(520.0, 210.0)
	_graph_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph_canvas.draw.connect(_on_graph_canvas_draw)
	frame.add_child(_graph_canvas)
	_graph_canvas.queue_redraw()


func _on_graph_scale_clicked(scale_id: int) -> void:
	_graph_scale_id = scale_id
	_refresh_active_window_contents()


func _on_graph_metric_clicked(metric_key: String) -> void:
	var idx: int = _graph_active_metrics.find(metric_key)
	if idx >= 0:
		if _graph_active_metrics.size() > 1:
			_graph_active_metrics.remove_at(idx)
	else:
		if _graph_active_metrics.size() >= 3:
			_graph_active_metrics.remove_at(0)
		_graph_active_metrics.append(metric_key)
	_refresh_active_window_contents()


func _on_graph_canvas_draw() -> void:
	if _graph_canvas == null:
		return
	var sz: Vector2 = _graph_canvas.size
	if sz.x < 40.0 or sz.y < 40.0:
		return
	var pad_l: float = 42.0
	var pad_r: float = 12.0
	var pad_t: float = 16.0
	var pad_b: float = 20.0
	var gw: float = maxf(sz.x - pad_l - pad_r, 16.0)
	var gh: float = maxf(sz.y - pad_t - pad_b, 16.0)

	_graph_canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.039, 0.063, 0.102, 0.96), true)
	for g in range(5):
		var gy: float = pad_t + gh * (float(g) / 4.0)
		_graph_canvas.draw_line(Vector2(pad_l, gy), Vector2(pad_l + gw, gy), Color(0.16, 0.28, 0.40, 0.45), 1.0)

	var series_list: Array[PackedFloat32Array] = []
	var max_val: float = 1.0
	for mkey in _graph_active_metrics:
		var arr: PackedFloat32Array = _fetch_history_series(_graph_scale_id, mkey)
		series_list.append(arr)
		for v in arr:
			max_val = maxf(max_val, v)

	var font: Font = ThemeDB.fallback_font
	_graph_canvas.draw_string(font, Vector2(4.0, pad_t + 8.0), "%.0f" % max_val, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#9AB3C9"))
	_graph_canvas.draw_string(font, Vector2(4.0, pad_t + gh), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#9AB3C9"))

	var colors: Array[Color] = [Color("#45E9FF"), Color("#FFB347"), Color("#A86BFF")]
	for s_idx in range(series_list.size()):
		var arr: PackedFloat32Array = series_list[s_idx]
		var col: Color = colors[s_idx % colors.size()]
		var n: int = arr.size()
		if n < 2:
			continue
		var pts := PackedVector2Array()
		pts.resize(n)
		for i in range(n):
			var px: float = pad_l + gw * (float(i) / float(n - 1))
			var py: float = pad_t + gh * (1.0 - clampf(arr[i] / max_val, 0.0, 1.0))
			pts[i] = Vector2(px, py)
		_graph_canvas.draw_polyline(pts, col, 2.0, true)
		var m_lbl: String = _metric_display_label(_graph_active_metrics[s_idx])
		_graph_canvas.draw_string(font, Vector2(pad_l + float(s_idx) * 140.0, sz.y - 4.0), "%s: %.0f" % [m_lbl, arr[n - 1]], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)


func _fetch_history_series(scale_id: int, metric_key: String) -> PackedFloat32Array:
	if _civ != null and _civ.has_method("get_history_series"):
		var raw: Variant = _civ.call("get_history_series", scale_id, metric_key)
		if raw is PackedFloat32Array and (raw as PackedFloat32Array).size() >= 2:
			return raw as PackedFloat32Array
	var buf: Array = _fallback_history.get(metric_key, [])
	var out := PackedFloat32Array()
	for v in buf:
		out.append(float(v))
	return out


func _metric_display_label(mkey: String) -> String:
	for m in GRAPH_METRICS:
		if str(m["key"]) == mkey:
			return str(m["label"])
	return mkey


func _init_fallback_history() -> void:
	_fallback_history.clear()
	for m in GRAPH_METRICS:
		_fallback_history[str(m["key"])] = []


func _record_fallback_history_sample() -> void:
	var pop_v: float = float(_physics.call("get_unit_count")) if (_physics != null and _physics.has_method("get_unit_count")) else 0.0
	var stats: Dictionary = _civ.call("get_civ_stats") if (_civ != null and _civ.has_method("get_civ_stats")) else {}
	var sample: Dictionary = {
		"pop": pop_v,
		"cities": float(stats.get("cities", 0)),
		"wars": float(stats.get("wars_active", 0)),
		"buildings": float(stats.get("buildings", 0)),
		"science": float(stats.get("science", stats.get("total_science", stats.get("tech_tier", 0)))),
		"food": float(stats.get("food", stats.get("total_food", 0.0))),
		"ore": float(stats.get("ore", stats.get("total_ore", 0.0))),
		"energy": float(stats.get("energy", stats.get("total_energy", 0.0))),
		"credits": float(stats.get("credits", stats.get("total_credits", 0.0))),
		"deaths": float(stats.get("deaths_total", stats.get("casualties", 0.0))),
	}
	for k in sample.keys():
		var arr: Array = _fallback_history.get(k, [])
		arr.append(sample[k])
		while arr.size() > 48:
			arr.remove_at(0)
		_fallback_history[k] = arr


func _build_codex_window() -> void:
	var sub_row := HBoxContainer.new()
	sub_row.add_theme_constant_override("separation", 4)
	_modal_body.add_child(sub_row)
	var subs: Array[String] = [
		"Кодекс (%d/40)" % _unlocked_codex.size(),
		"Настроение (9)",
		"Шаблоны карты (8)",
	]
	for idx in range(subs.size()):
		var b := Button.new()
		b.text = subs[idx]
		b.toggle_mode = true
		b.button_pressed = (_codex_subtab == idx)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(b, 10, _style_btn_prs)
		b.pressed.connect(_on_codex_subtab_clicked.bind(idx))
		sub_row.add_child(b)

	_modal_counter_lbl.text = "%d / 3" % (_codex_subtab + 1)
	if _codex_subtab == 0:
		_render_codex_achievements_tab()
	elif _codex_subtab == 1:
		_render_architect_moods_tab()
	else:
		_render_map_templates_tab()


func _on_codex_subtab_clicked(idx: int) -> void:
	_codex_subtab = idx
	_refresh_active_window_contents()


func _render_codex_achievements_tab() -> void:
	_last_codex_count = _unlocked_codex.size()
	var forbidden_open: bool = is_forbidden_unlocked()
	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", _style_card)
	_modal_body.add_child(banner)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 8)
	banner.add_child(bh)
	var b_lbl := Label.new()
	b_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_lbl.text = "Запретные Протоколы: %s (%d/40 открыто)" % ["ДОСТУПНЫ" if forbidden_open else "Требуется 12 открытий", _unlocked_codex.size()]
	b_lbl.add_theme_font_size_override("font_size", 11)
	b_lbl.add_theme_color_override("font_color", Color("#C275FF") if forbidden_open else Color("#9AB3C9"))
	bh.add_child(b_lbl)
	var b_act := Button.new()
	b_act.text = "Активировать протокол" if forbidden_open else "Заблокировано"
	b_act.disabled = not forbidden_open
	_style_button(b_act, 10, _style_btn_gold)
	b_act.pressed.connect(_on_activate_forbidden_protocol)
	bh.add_child(b_act)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)
	_modal_body.add_child(grid)
	for spec in CODEX_DEFS:
		var cid: String = str(spec["id"])
		var unlocked: bool = _unlocked_codex.has(cid)
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _style_card)
		grid.add_child(card)
		var lbl := Label.new()
		var mark: String = "★" if unlocked else "○"
		lbl.text = "%s [%s] %s\n%s" % [mark, str(spec["cat"]), str(spec["name"]), str(spec["desc"])]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color("#FFE066") if unlocked else Color("#7F96AC"))
		card.add_child(lbl)


func _on_activate_forbidden_protocol() -> void:
	_forbidden_active = true
	_unlock_codex("forbidden_core")
	if _world != null and _world.has_method("trigger_world_disaster"):
		_world.call("trigger_world_disaster", Vector2(320.0, 180.0), 4)
	_play_ui_sfx("ui_pin")
	_refresh_active_window_contents()


func _render_architect_moods_tab() -> void:
	_add_section_header(_modal_body, "НАСТРОЕНИЕ АРХИТЕКТОРА (цветовой акцент HUD)")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	_modal_body.add_child(grid)
	for m in MOOD_DEFS:
		var mid: int = int(m["id"])
		var btn := Button.new()
		btn.text = "%s\n%s" % [str(m["name"]), str(m["desc"])]
		btn.toggle_mode = true
		btn.button_pressed = (_active_mood_id == mid)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(btn, 10, _style_btn_prs)
		btn.add_theme_color_override("font_color", Color(str(m["main"])))
		btn.pressed.connect(_on_mood_selected.bind(mid))
		grid.add_child(btn)


func _on_mood_selected(mood_id: int) -> void:
	_apply_architect_mood(mood_id)
	_unlock_codex("mood_shift")
	_refresh_active_window_contents()
	_play_ui_sfx("ui_pin")


func _apply_architect_mood(mood_id: int) -> void:
	_active_mood_id = clampi(mood_id, 0, MOOD_DEFS.size() - 1)
	var m: Dictionary = MOOD_DEFS[_active_mood_id]
	var border_col: Color = Color(str(m["border"]))
	var main_col: Color = Color(str(m["main"]))
	if _style_panel != null:
		_style_panel.border_color = border_col
	if _style_modal != null:
		_style_modal.border_color = main_col
	if _modal_title_lbl != null:
		_modal_title_lbl.add_theme_color_override("font_color", main_col)
	architect_mood_changed.emit(_active_mood_id, m.duplicate())


func _render_map_templates_tab() -> void:
	_add_section_header(_modal_body, "ШАБЛОН ГЕНЕРАЦИИ ПЛАНЕТЫ (8 режимов)")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	_modal_body.add_child(grid)
	for tpl in TEMPLATE_DEFS:
		var tid: int = int(tpl["id"])
		var btn := Button.new()
		btn.text = "%s — %s" % [str(tpl["name"]), str(tpl["desc"])]
		btn.toggle_mode = true
		btn.button_pressed = (_selected_template_id == tid)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(btn, 10, _style_btn_prs)
		btn.pressed.connect(_on_template_selected.bind(tid))
		grid.add_child(btn)

	var gen_btn := Button.new()
	gen_btn.text = "Пересоздать мир по шаблону: %s" % str(TEMPLATE_DEFS[_selected_template_id]["name"])
	_style_button(gen_btn, 12, _style_btn_gold)
	gen_btn.pressed.connect(_on_template_regen_clicked)
	_modal_body.add_child(gen_btn)


func _on_template_selected(tid: int) -> void:
	_selected_template_id = clampi(tid, 0, TEMPLATE_DEFS.size() - 1)
	_refresh_active_window_contents()
	_play_ui_sfx("ui")


func _on_template_regen_clicked() -> void:
	_unlock_codex("world_builder")
	template_regen_requested.emit(_selected_template_id)
	if template_regen_requested.get_connections().is_empty():
		var new_seed: int = int(Time.get_ticks_usec()) & 0x7FFFFFFF
		if _world != null and _world.has_method("generate_planet_with_template"):
			_world.call("generate_planet_with_template", new_seed, _selected_template_id)
		elif _world != null and _world.has_method("generate_planet"):
			_world.call("generate_planet", new_seed)
		if _civ != null and _civ.has_method("reset_civ"):
			_civ.call("reset_civ")
		if _physics != null and _physics.has_method("rebuild_population"):
			_physics.call("rebuild_population", 0)
	close_window()
	_play_ui_sfx("ui_pin")


func _scan_passive_codex() -> void:
	if _physics != null and _physics.has_method("get_unit_count"):
		var u_n: int = int(_physics.call("get_unit_count"))
		if u_n >= 100:
			_unlock_codex("pop_100")
		if u_n >= 300:
			_unlock_codex("pop_300")
	if _civ != null and _civ.has_method("get_civ_stats"):
		var st: Dictionary = _civ.call("get_civ_stats")
		var c_n: int = int(st.get("cities", 0))
		var t_n: int = maxi(int(st.get("max_tech_tier", 0)), int(st.get("tech_tier", 0)))
		var w_n: int = int(st.get("wars_active", 0))
		if c_n >= 1:
			_unlock_codex("first_colony")
		if c_n >= 3:
			_unlock_codex("megapolis_3")
		if c_n >= 8:
			_unlock_codex("megapolis_8")
		if t_n >= 1:
			_unlock_codex("tier_1")
		if t_n >= 3:
			_unlock_codex("tier_3")
		if t_n >= 5:
			_unlock_codex("tier_5")
		if w_n >= 1:
			_unlock_codex("first_war")
		if w_n >= 3:
			_unlock_codex("world_war")
	if _civ != null and _civ.has_method("get_ship_count"):
		var sh_n: int = int(_civ.call("get_ship_count"))
		if sh_n >= 1:
			_unlock_codex("first_ship")
		if sh_n >= 5:
			_unlock_codex("armada_5")


func _unlock_codex(codex_id: String) -> void:
	if _unlocked_codex.has(codex_id):
		return
	_unlocked_codex[codex_id] = true
	if _unlocked_codex.size() >= 12 and not _unlocked_codex.has("forbidden_core"):
		_unlocked_codex["forbidden_core"] = true
	if _codex_badge_lbl != null:
		_codex_badge_lbl.text = "%d/40" % _unlocked_codex.size()


func _connect_laws_hook() -> void:
	if _laws_ui != null and _laws_ui.has_signal("chronicle_event_logged"):
		_laws_ui.connect("chronicle_event_logged", notify_chronicle_event)


func _focus_camera_on(world_pos: Vector2) -> void:
	if _laws_ui != null and _laws_ui.has_signal("chronicle_focus_requested"):
		_laws_ui.emit_signal("chronicle_focus_requested", world_pos)
	elif _main != null:
		_main.set("_follow_locked_unit", false)
		_main.set("_cam_focus_target", world_pos)
		_main.set("_cam_focus_active", true)
	_play_ui_sfx("ui")


func _play_ui_sfx(kind: String) -> void:
	if _fx != null and _fx.has_method("play_sfx"):
		_fx.call("play_sfx", kind)


func _add_section_header(parent: Control, text_str: String) -> void:
	var lbl := Label.new()
	lbl.text = text_str
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color("#7CE7FF"))
	parent.add_child(lbl)


func _add_empty_notice(parent: Control, text_str: String) -> void:
	var lbl := Label.new()
	lbl.text = text_str
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color("#7F96AC"))
	parent.add_child(lbl)


func _add_divider(parent: Control) -> void:
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0.0, 1.0)
	div.color = Color(0.22, 0.40, 0.56, 0.55)
	parent.add_child(div)


func _resolve_unit_display_name(u: Dictionary) -> String:
	var cname: String = str(u.get("custom_name", "")).strip_edges()
	if cname != "":
		return cname
	var nname: String = str(u.get("notable_name", "")).strip_edges()
	if nname != "":
		return nname
	return "%s #%d" % [str(u.get("role_name", "Юнит")), maxi(int(u.get("uid", 0)), 0)]


func _unit_has_trait(u: Dictionary, trait_id: int) -> bool:
	var mask: int = int(u.get("trait_mask", 0))
	if (mask & (1 << trait_id)) != 0:
		return true
	var t_raw: Variant = u.get("traits", 0)
	if t_raw is int and (int(t_raw) & (1 << trait_id)) != 0:
		return true
	if t_raw is Array and (t_raw as Array).has(trait_id):
		return true
	var tnames: Variant = u.get("trait_names", [])
	if tnames is Array and trait_id >= 0 and trait_id < TRAIT_DEFS.size():
		var target: String = str(TRAIT_DEFS[trait_id]["name"])
		return (tnames as Array).has(target)
	return false


func _faction_color(fac: int) -> Color:
	var cols: Array[Color] = [Color("#38F0FF"), Color("#E63B3B"), Color("#B84DFF"), Color("#D264FF")]
	return cols[posmod(fac, cols.size())]
