extends RefCounted

signal laws_changed(laws: Dictionary)
signal chronicle_focus_requested(world_pos: Vector2)
signal chronicle_event_logged(ev_kind: String)

const LAW_SPECS: Array[Dictionary] = [
	{
		"key": "self_founding",
		"label": "Самооснование",
		"tip": "Свободные поселенцы сами ставят лагеря и экспедиции",
		"default": true,
	},
	{
		"key": "diplomacy_wars",
		"label": "Дипломатия и войны",
		"tip": "Пакты, соперничество, войны и полковые походы",
		"default": true,
	},
	{
		"key": "rebellions",
		"label": "Мятежи колоний",
		"tip": "Восстания дальних поселений при низкой лояльности",
		"default": true,
	},
	{
		"key": "cosmic_ages",
		"label": "Космические эпохи",
		"tip": "Автоматическая смена орбитальных эпох планеты",
		"default": true,
	},
	{
		"key": "disasters",
		"label": "Катастрофы",
		"tip": "Орбитальные разряды и стихийные бедствия эпох",
		"default": true,
	},
	{
		"key": "rad_mutations",
		"label": "Мутации радиации",
		"tip": "Мутация юнитов при сильном облучении",
		"default": true,
	},
	{
		"key": "migrations",
		"label": "Миграции поселенцев",
		"tip": "Переселение жителей между колониями и освоение островов",
		"default": true,
	},
	{
		"key": "alliances",
		"label": "Альянсы держав",
		"tip": "Военно-торговые союзы и втягивание союзников в конфликты",
		"default": true,
	},
	{
		"key": "peace_treaties",
		"label": "Мирные договоры",
		"tip": "Заговоры перемирия и завершение затяжных войн",
		"default": true,
	},
	{
		"key": "biome_growth",
		"label": "Рост биомов",
		"tip": "Естественное распространение и конкуренция планетарных биомов",
		"default": true,
	},
	{
		"key": "creep_decay",
		"label": "Распад крипа",
		"tip": "Разрушение мицелия и кибер-сети без питающего ядра",
		"default": true,
	},
	{
		"key": "volcanoes_geysers",
		"label": "Вулканы и гейзеры",
		"tip": "Активные выбросы магмы, паровые и кислотные гейзеры",
		"default": true,
	},
	{
		"key": "unit_aging",
		"label": "Старение юнитов",
		"tip": "Возрастной цикл поколений и наследование власти",
		"default": true,
	},
	{
		"key": "unit_hunger",
		"label": "Голод и рационы",
		"tip": "Потребность в пище, любимые рационы и истощение при нехватке",
		"default": true,
	},
	{
		"key": "wild_fauna",
		"label": "Дикая ксенофауна",
		"tip": "Природное размножение мирных существ и роёв в биомах",
		"default": true,
	},
	{
		"key": "predators",
		"label": "Охота хищников",
		"tip": "Нападения хищных зверей на дичь и зазевавшихся разведчиков",
		"default": true,
	},
	{
		"key": "world_bosses",
		"label": "Мега-боссы сектора",
		"tip": "Пробуждение и рейды Левиафанов, НЛО и Кибер-Колоссов",
		"default": true,
	},
	{
		"key": "ships_docks",
		"label": "Верфи и флот",
		"tip": "Постройка береговых доков, рыболовецких, торговых и десантных судов",
		"default": true,
	},
	{
		"key": "army_campaigns",
		"label": "Армейские походы",
		"tip": "Сбор полков со знамёнами, осада городов и морские десанты",
		"default": true,
	},
	{
		"key": "noosphere_culture",
		"label": "Ноосфера и культура",
		"tip": "Развитие культур, доктрин, кодексов знаний и диалектов",
		"default": true,
	},
]

const MAX_CHRONICLE_LINES: int = 3
const MAX_HISTORY_LOG: int = 200
const CHRONICLE_HOLD_SEC: float = 8.5
const CHRONICLE_FADE_SEC: float = 3.5

var _laws: Dictionary = {}

var _hud_root: Node
var _btn_laws: Button
var _btn_led: ColorRect
var _laws_panel: PanelContainer
var _laws_scroll: ScrollContainer
var _laws_open: bool = false
var _law_buttons: Dictionary = {}
var _law_dots: Dictionary = {}
var _law_states: Dictionary = {}

var _chronicle_panel: PanelContainer
var _chronicle_box: VBoxContainer
var _chronicle_entries: Array[Dictionary] = []
var _chronicle_rows: Array[Button] = []
var _chronicle_dirty: bool = false
var _chronicle_collapsed: bool = false

var _history_log: Array[Dictionary] = []
var _history_seq: int = 0
var _history_clock: float = 0.0

var _style_popover: StyleBoxFlat
var _style_row_normal: StyleBoxFlat
var _style_row_hover: StyleBoxFlat
var _style_chronicle: StyleBoxFlat
var _style_chronicle_row: StyleBoxFlat
var _style_chronicle_hover: StyleBoxFlat
var _scroll_theme: Theme


func _init() -> void:
	_init_default_laws()


func _init_default_laws() -> void:
	for spec in LAW_SPECS:
		var k: String = str(spec["key"])
		_laws[k] = bool(spec.get("default", true))


func setup(hud_root: Node, btn_laws: Button, base_panel: StyleBoxFlat) -> void:
	_hud_root = hud_root
	_btn_laws = btn_laws
	if _laws.is_empty():
		_init_default_laws()
	_init_styles(base_panel)
	_setup_laws_button()
	_build_laws_popover()
	_build_chronicle_panel()
	_refresh_laws_ui()
	_refresh_chronicle_ui()


func dispose() -> void:
	_law_buttons.clear()
	_law_dots.clear()
	_law_states.clear()
	_chronicle_entries.clear()
	_chronicle_rows.clear()
	_history_log.clear()
	_style_popover = null
	_style_row_normal = null
	_style_row_hover = null
	_style_chronicle = null
	_style_chronicle_row = null
	_style_chronicle_hover = null
	_scroll_theme = null
	_laws_scroll = null
	_btn_led = null
	_laws_panel = null
	_chronicle_panel = null
	_chronicle_box = null
	_btn_laws = null
	_hud_root = null


func get_laws() -> Dictionary:
	return _laws.duplicate()


func set_laws(laws: Dictionary) -> void:
	for spec in LAW_SPECS:
		var k: String = str(spec["key"])
		if laws.has(k):
			_laws[k] = bool(laws[k])
	_refresh_laws_ui()


func reset_all_laws_default() -> void:
	_init_default_laws()
	_refresh_laws_ui()
	laws_changed.emit(get_laws())


func is_laws_panel_open() -> bool:
	return _laws_open


func toggle_laws_panel() -> void:
	set_laws_panel_open(not _laws_open)


func set_laws_panel_open(open: bool) -> void:
	_laws_open = open
	if _laws_panel != null:
		_laws_panel.visible = open
	if _btn_laws != null:
		_btn_laws.button_pressed = open
	_refresh_button_indicator()


func hide_laws_for_capture() -> void:
	set_laws_panel_open(false)
	_chronicle_collapsed = false
	_refresh_chronicle_ui()


func hide_all_for_capture() -> void:
	hide_laws_for_capture()
	clear_chronicle()


func toggle_chronicle_collapsed() -> bool:
	_chronicle_collapsed = not _chronicle_collapsed
	_refresh_chronicle_ui()
	return not _chronicle_collapsed


func clear_chronicle() -> void:
	_chronicle_entries.clear()
	_chronicle_dirty = true
	_refresh_chronicle_ui()


func clear_history_log() -> void:
	_history_log.clear()
	_history_seq = 0
	_history_clock = 0.0
	clear_chronicle()


func get_all_chronicle_entries() -> Array[Dictionary]:
	return _history_log.duplicate(true)


func sync_anchors(top_bar: Control, inspector_panel: Control) -> void:
	if _laws_panel != null and _btn_laws != null and top_bar != null:
		var vp_sz: Vector2 = top_bar.get_viewport_rect().size
		var py: float = top_bar.position.y + top_bar.size.y + 6.0
		if _laws_scroll != null:
			var max_scroll_h: float = clampf(vp_sz.y - py - 140.0, 170.0, 336.0)
			_laws_scroll.custom_minimum_size = Vector2(246.0, max_scroll_h)
		_laws_panel.reset_size()
		var btn_rect: Rect2 = _btn_laws.get_global_rect()
		var pw: float = maxf(_laws_panel.size.x, 268.0)
		var px: float = clampf(btn_rect.position.x + btn_rect.size.x - pw, 12.0, vp_sz.x - pw - 12.0)
		_laws_panel.position = Vector2(roundf(px), roundf(py))
	if _chronicle_panel != null and inspector_panel != null:
		var iw: float = clampf(inspector_panel.size.x, 252.0, 276.0)
		_chronicle_panel.offset_right = -12.0
		_chronicle_panel.offset_left = -12.0 - iw
		var cy: float = inspector_panel.position.y + inspector_panel.size.y + 8.0
		_chronicle_panel.offset_top = roundf(cy)
		_chronicle_panel.reset_size()


func push_chronicle_events(events: Array) -> void:
	if events.is_empty():
		return
	for raw_ev in events:
		if not (raw_ev is Dictionary):
			continue
		var ev: Dictionary = raw_ev
		var txt: String = str(ev.get("text", "")).strip_edges()
		if txt == "":
			continue
		var pos_v: Variant = ev.get("pos", Vector2(320.0, 180.0))
		var pos: Vector2 = pos_v if pos_v is Vector2 else Vector2(320.0, 180.0)
		var col_v: Variant = ev.get("color", Color("#7CE7FF"))
		var col: Color = col_v if col_v is Color else Color("#7CE7FF")
		var ev_kind: String = str(ev.get("kind", "")).strip_edges()
		var cat: String = _resolve_event_category(str(ev.get("category", "")), ev_kind, txt)
		var inferred_kind: String = ev_kind if ev_kind != "" else _infer_event_kind(cat, txt)
		_chronicle_entries.append({
			"text": txt,
			"pos": pos,
			"color": col,
			"age": 0.0,
		})
		_history_seq += 1
		_history_log.append({
			"seq": _history_seq,
			"text": txt,
			"pos": pos,
			"color": col,
			"category": cat,
			"kind": inferred_kind,
			"time_sec": _history_clock,
		})
		while _history_log.size() > MAX_HISTORY_LOG:
			_history_log.remove_at(0)
		chronicle_event_logged.emit(inferred_kind)
	while _chronicle_entries.size() > MAX_CHRONICLE_LINES:
		_chronicle_entries.remove_at(0)
	_chronicle_dirty = true
	_refresh_chronicle_ui()


func step_ui(dt: float) -> void:
	_history_clock += maxf(dt, 0.0)
	if _chronicle_entries.is_empty():
		return
	var total_life: float = CHRONICLE_HOLD_SEC + CHRONICLE_FADE_SEC
	var changed: bool = false
	var i: int = _chronicle_entries.size() - 1
	while i >= 0:
		var age: float = float(_chronicle_entries[i]["age"]) + dt
		if age >= total_life:
			_chronicle_entries.remove_at(i)
			changed = true
		else:
			_chronicle_entries[i]["age"] = age
			if age > CHRONICLE_HOLD_SEC:
				changed = true
		i -= 1
	if changed or _chronicle_dirty:
		_refresh_chronicle_ui()


func _resolve_event_category(raw_cat: String, ev_kind: String, txt: String) -> String:
	var c: String = raw_cat.strip_edges().to_lower()
	if c != "":
		return c
	var low: String = (ev_kind + " " + txt).to_lower()
	if low.find("войн") >= 0 or low.find("war") >= 0 or low.find("осад") >= 0 or low.find("битв") >= 0:
		return "war"
	if low.find("мятеж") >= 0 or low.find("заговор") >= 0 or low.find("альянс") >= 0 or low.find("мир") >= 0 or low.find("пакт") >= 0 or low.find("plot") >= 0:
		return "diplo"
	if low.find("город") >= 0 or low.find("колон") >= 0 or low.find("основ") >= 0 or low.find("верф") >= 0 or low.find("корабл") >= 0:
		return "city"
	if low.find("культур") >= 0 or low.find("кодекс") >= 0 or low.find("книг") >= 0 or low.find("монолит") >= 0 or low.find("раскол") >= 0:
		return "noosphere"
	if low.find("буря") >= 0 or low.find("вулкан") >= 0 or low.find("метеор") >= 0 or low.find("землетр") >= 0 or low.find("торнадо") >= 0 or low.find("босс") >= 0:
		return "world"
	return "world"


func _infer_event_kind(cat: String, txt: String) -> String:
	var low: String = txt.to_lower()
	if low.find("мятеж") >= 0 or low.find("восстан") >= 0:
		return "rebel"
	if low.find("заговор") >= 0 or low.find("интриг") >= 0:
		return "plot"
	if low.find("мирн") >= 0 or low.find("перемир") >= 0:
		return "peace"
	if low.find("альянс") >= 0 or low.find("союз") >= 0 or low.find("пакт") >= 0:
		return "alliance"
	if low.find("войн") >= 0 or low.find("осад") >= 0:
		return "war"
	if low.find("реликт") >= 0 or low.find("корон") >= 0:
		return "relic"
	if low.find("дуэл") >= 0:
		return "duel"
	if low.find("портал") >= 0 or low.find("врат") >= 0:
		return "portal"
	if low.find("корабл") >= 0 or low.find("верф") >= 0 or low.find("флот") >= 0:
		return "ship"
	if low.find("монолит") >= 0 or low.find("возвыс") >= 0:
		return "monolith"
	if low.find("кодекс") >= 0 or low.find("культур") >= 0 or low.find("книг") >= 0:
		return "culture"
	if low.find("основ") >= 0 or low.find("колон") >= 0 or low.find("город") >= 0:
		return "city"
	return cat


func _init_styles(base_panel: StyleBoxFlat) -> void:
	if base_panel != null:
		_style_popover = base_panel.duplicate() as StyleBoxFlat
		_style_popover.bg_color = Color(0.055, 0.086, 0.133, 0.95)
		_style_popover.border_color = Color(0.24, 0.42, 0.56, 0.82)
		_style_popover.shadow_size = 7
		_style_popover.shadow_offset = Vector2(0.0, 4.0)
		_style_popover.content_margin_left = 10.0
		_style_popover.content_margin_right = 10.0
		_style_popover.content_margin_top = 8.0
		_style_popover.content_margin_bottom = 8.0
	else:
		_style_popover = _make_flat_style(Color(0.055, 0.086, 0.133, 0.95), Color(0.24, 0.42, 0.56, 0.82), 4, 10.0, 8.0)

	_style_row_normal = _make_flat_style(Color(0.08, 0.125, 0.185, 0.58), Color(0.18, 0.30, 0.42, 0.0), 3, 8.0, 5.0)
	_style_row_hover = _make_flat_style(Color(0.125, 0.20, 0.295, 0.90), Color(0.32, 0.64, 0.82, 0.65), 3, 8.0, 5.0)

	_style_chronicle = _make_flat_style(Color(0.043, 0.068, 0.108, 0.56), Color(0.20, 0.34, 0.48, 0.38), 4, 8.0, 6.0)
	_style_chronicle_row = _make_flat_style(Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0), 2, 4.0, 3.0)
	_style_chronicle_row.content_margin_left = 10.0
	_style_chronicle_hover = _make_flat_style(Color(0.13, 0.21, 0.31, 0.68), Color(0.34, 0.68, 0.86, 0.45), 2, 4.0, 3.0)
	_style_chronicle_hover.content_margin_left = 10.0

	_scroll_theme = Theme.new()
	var sb_track: StyleBoxFlat = _make_flat_style(Color(0.04, 0.065, 0.105, 0.85), Color(0.16, 0.28, 0.40, 0.40), 3, 2.0, 2.0)
	var sb_grab: StyleBoxFlat = _make_flat_style(Color(0.24, 0.46, 0.64, 0.88), Color(0.38, 0.72, 0.88, 0.60), 3, 2.0, 2.0)
	var sb_grab_hov: StyleBoxFlat = _make_flat_style(Color(0.36, 0.70, 0.88, 0.96), Color(0.50, 0.86, 0.98, 0.90), 3, 2.0, 2.0)
	_scroll_theme.set_stylebox("scroll", "VScrollBar", sb_track)
	_scroll_theme.set_stylebox("grabber", "VScrollBar", sb_grab)
	_scroll_theme.set_stylebox("grabber_highlight", "VScrollBar", sb_grab_hov)
	_scroll_theme.set_stylebox("grabber_pressed", "VScrollBar", sb_grab_hov)


func _make_flat_style(bg: Color, border: Color, rad: int, pad_x: float, pad_y: float) -> StyleBoxFlat:
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


func _setup_laws_button() -> void:
	if _btn_laws == null:
		return
	var st_norm := _make_flat_style(Color(0.082, 0.129, 0.192, 0.90), Color(0.20, 0.34, 0.46, 0.65), 3, 6.0, 3.0)
	st_norm.content_margin_left = 15.0
	var st_hov := _make_flat_style(Color(0.125, 0.200, 0.294, 0.96), Color(0.36, 0.69, 0.86, 0.88), 3, 6.0, 3.0)
	st_hov.content_margin_left = 15.0
	var st_prs := _make_flat_style(Color(0.094, 0.278, 0.369, 0.96), Color(0.28, 0.87, 0.96, 1.0), 3, 6.0, 3.0)
	st_prs.content_margin_left = 15.0

	_btn_laws.toggle_mode = true
	_btn_laws.focus_mode = Control.FOCUS_NONE
	_btn_laws.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_laws.add_theme_font_size_override("font_size", 11)
	_btn_laws.add_theme_color_override("font_color", Color("#E2ECF5"))
	_btn_laws.add_theme_color_override("font_hover_color", Color("#F4FAFF"))
	_btn_laws.add_theme_color_override("font_pressed_color", Color("#F7FCFF"))
	_btn_laws.add_theme_stylebox_override("normal", st_norm)
	_btn_laws.add_theme_stylebox_override("hover", st_hov)
	_btn_laws.add_theme_stylebox_override("pressed", st_prs)

	_btn_led = ColorRect.new()
	_btn_led.name = "LawLed"
	_btn_led.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn_led.anchor_top = 0.5
	_btn_led.anchor_bottom = 0.5
	_btn_led.offset_left = 6.0
	_btn_led.offset_right = 11.0
	_btn_led.offset_top = -2.5
	_btn_led.offset_bottom = 2.5
	_btn_led.color = Color("#4BE898")
	_btn_laws.add_child(_btn_led)


func _build_laws_popover() -> void:
	_laws_panel = PanelContainer.new()
	_laws_panel.name = "WorldLawsPanel"
	_laws_panel.visible = false
	_laws_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_laws_panel.custom_minimum_size = Vector2(268.0, 0.0)
	_laws_panel.add_theme_stylebox_override("panel", _style_popover)
	_hud_root.add_child(_laws_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_laws_panel.add_child(vbox)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 6)
	vbox.add_child(hdr)

	var title := Label.new()
	title.text = "ЗАКОНЫ СЕКТОРА (20)"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color("#7CE7FF"))
	hdr.add_child(title)

	var btn_reset := Button.new()
	btn_reset.text = "Все ВКЛ"
	btn_reset.focus_mode = Control.FOCUS_NONE
	btn_reset.tooltip_text = "Включить все 20 законов по умолчанию"
	btn_reset.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_reset.add_theme_font_size_override("font_size", 10)
	btn_reset.add_theme_color_override("font_color", Color("#9EB4C8"))
	btn_reset.add_theme_color_override("font_hover_color", Color("#4BE898"))
	btn_reset.add_theme_stylebox_override("normal", _style_chronicle_row)
	btn_reset.add_theme_stylebox_override("hover", _style_chronicle_hover)
	btn_reset.pressed.connect(reset_all_laws_default)
	hdr.add_child(btn_reset)

	var btn_close := Button.new()
	btn_close.text = "×"
	btn_close.tooltip_text = "Закрыть [Esc]"
	btn_close.focus_mode = Control.FOCUS_NONE
	btn_close.custom_minimum_size = Vector2(22.0, 20.0)
	btn_close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_close.add_theme_font_size_override("font_size", 12)
	btn_close.add_theme_color_override("font_color", Color("#9EB4C8"))
	btn_close.add_theme_color_override("font_hover_color", Color("#F4FAFF"))
	btn_close.add_theme_stylebox_override("normal", _style_chronicle_row)
	btn_close.add_theme_stylebox_override("hover", _style_chronicle_hover)
	btn_close.pressed.connect(func() -> void: set_laws_panel_open(false))
	hdr.add_child(btn_close)

	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0.0, 1.0)
	div.color = Color(0.20, 0.34, 0.46, 0.55)
	vbox.add_child(div)

	_laws_scroll = ScrollContainer.new()
	_laws_scroll.custom_minimum_size = Vector2(246.0, 310.0)
	_laws_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_laws_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_laws_scroll.theme = _scroll_theme
	vbox.add_child(_laws_scroll)

	var list_box := VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 3)
	_laws_scroll.add_child(list_box)

	for spec in LAW_SPECS:
		_add_law_toggle_row(list_box, spec)


func _add_law_toggle_row(parent_box: VBoxContainer, spec: Dictionary) -> void:
	var key: String = str(spec["key"])
	var btn := Button.new()
	btn.toggle_mode = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(232.0, 24.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.tooltip_text = str(spec["tip"])
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal", _style_row_normal)
	btn.add_theme_stylebox_override("hover", _style_row_hover)
	btn.add_theme_stylebox_override("pressed", _style_row_normal)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8.0
	row.offset_right = -8.0
	row.add_theme_constant_override("separation", 6)
	btn.add_child(row)

	var dot := ColorRect.new()
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.custom_minimum_size = Vector2(6.0, 6.0)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot)

	var lbl := Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.text = str(spec["label"])
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color("#E2ECF5"))
	row.add_child(lbl)

	var state_lbl := Label.new()
	state_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	state_lbl.add_theme_font_size_override("font_size", 10)
	row.add_child(state_lbl)

	btn.toggled.connect(func(pressed: bool) -> void: _on_law_toggled(key, pressed))
	parent_box.add_child(btn)
	_law_buttons[key] = btn
	_law_dots[key] = dot
	_law_states[key] = state_lbl


func _on_law_toggled(key: String, pressed: bool) -> void:
	if bool(_laws.get(key, true)) == pressed:
		return
	_laws[key] = pressed
	_refresh_laws_ui()
	laws_changed.emit(get_laws())


func _refresh_laws_ui() -> void:
	for spec in LAW_SPECS:
		var key: String = str(spec["key"])
		var on: bool = bool(_laws.get(key, true))
		var btn: Button = _law_buttons.get(key, null)
		if btn != null:
			btn.set_pressed_no_signal(on)
		var dot: ColorRect = _law_dots.get(key, null)
		if dot != null:
			dot.color = Color("#4BE898") if on else Color("#5E7085")
		var st: Label = _law_states.get(key, null)
		if st != null:
			st.text = "ВКЛ" if on else "ВЫКЛ"
			st.add_theme_color_override("font_color", Color("#4BE898") if on else Color("#7F93A8"))
	_refresh_button_indicator()


func _refresh_button_indicator() -> void:
	if _btn_laws == null:
		return
	var active_n: int = 0
	for spec in LAW_SPECS:
		if bool(_laws.get(str(spec["key"]), true)):
			active_n += 1
	var total_n: int = LAW_SPECS.size()
	_btn_laws.text = "Законы" if active_n == total_n else ("Законы %d/%d" % [active_n, total_n])
	if _btn_led != null:
		if _laws_open:
			_btn_led.color = Color("#7CE7FF")
		elif active_n == total_n:
			_btn_led.color = Color("#4BE898")
		else:
			_btn_led.color = Color("#FFB347")


func _build_chronicle_panel() -> void:
	_chronicle_panel = PanelContainer.new()
	_chronicle_panel.name = "MiniChroniclePanel"
	_chronicle_panel.visible = false
	_chronicle_panel.anchor_left = 1.0
	_chronicle_panel.anchor_right = 1.0
	_chronicle_panel.offset_left = -276.0
	_chronicle_panel.offset_top = 72.0
	_chronicle_panel.offset_right = -12.0
	_chronicle_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_chronicle_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_chronicle_panel.add_theme_stylebox_override("panel", _style_chronicle)
	_hud_root.add_child(_chronicle_panel)

	_chronicle_box = VBoxContainer.new()
	_chronicle_box.add_theme_constant_override("separation", 2)
	_chronicle_panel.add_child(_chronicle_box)

	for idx in range(MAX_CHRONICLE_LINES):
		var row_btn := Button.new()
		row_btn.visible = false
		row_btn.focus_mode = Control.FOCUS_NONE
		row_btn.custom_minimum_size = Vector2(244.0, 0.0)
		row_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		row_btn.add_theme_font_size_override("font_size", 10)
		row_btn.add_theme_color_override("font_color", Color("#E2ECF5"))
		row_btn.add_theme_color_override("font_hover_color", Color("#F5FAFF"))
		row_btn.add_theme_color_override("font_pressed_color", Color("#F8FCFF"))
		row_btn.add_theme_stylebox_override("normal", _style_chronicle_row)
		row_btn.add_theme_stylebox_override("hover", _style_chronicle_hover)
		row_btn.add_theme_stylebox_override("pressed", _style_chronicle_hover)

		var tick := ColorRect.new()
		tick.name = "AccentTick"
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick.anchor_top = 0.0
		tick.anchor_bottom = 1.0
		tick.offset_left = 3.0
		tick.offset_right = 5.0
		tick.offset_top = 3.0
		tick.offset_bottom = -3.0
		row_btn.add_child(tick)

		row_btn.pressed.connect(func() -> void: _on_chronicle_row_clicked(idx))
		_chronicle_box.add_child(row_btn)
		_chronicle_rows.append(row_btn)


func _on_chronicle_row_clicked(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= _chronicle_entries.size():
		return
	var entry: Dictionary = _chronicle_entries[_chronicle_entries.size() - 1 - slot_idx]
	var target_pos: Vector2 = entry.get("pos", Vector2(320.0, 180.0))
	chronicle_focus_requested.emit(target_pos)


func _refresh_chronicle_ui() -> void:
	_chronicle_dirty = false
	if _chronicle_panel == null:
		return
	if _chronicle_collapsed or _chronicle_entries.is_empty():
		_chronicle_panel.visible = false
		return

	_chronicle_panel.visible = true
	var max_alpha: float = 0.0
	var count: int = _chronicle_entries.size()
	for slot in range(MAX_CHRONICLE_LINES):
		var row_btn: Button = _chronicle_rows[slot]
		if slot >= count:
			row_btn.visible = false
			continue
		var entry: Dictionary = _chronicle_entries[count - 1 - slot]
		var age: float = float(entry["age"])
		var fade_t: float = clampf((age - CHRONICLE_HOLD_SEC) / CHRONICLE_FADE_SEC, 0.0, 1.0)
		var alpha: float = 1.0 - fade_t * fade_t
		max_alpha = maxf(max_alpha, alpha)
		row_btn.visible = true
		row_btn.text = str(entry["text"])
		row_btn.modulate = Color(1.0, 1.0, 1.0, alpha)
		var tick: ColorRect = row_btn.get_node_or_null("AccentTick") as ColorRect
		if tick != null:
			tick.color = entry.get("color", Color("#7CE7FF"))
	_chronicle_panel.modulate = Color(1.0, 1.0, 1.0, max_alpha)
	_chronicle_panel.reset_size()
