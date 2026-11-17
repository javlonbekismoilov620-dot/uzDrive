## Garage: owned vehicles, live preview, statistics and the 4 upgrade tracks.
## Upgrades use a two-tap confirm (tap → "Confirm?" → tap) to prevent
## accidental purchases while staying quick.
extends ScreenBase

const UPG_ICONS := {"engine": "engine", "suspension": "suspension", "tires": "tire", "fuel": "tank"}

var _list: VBoxContainer
var _preview: VehiclePreview
var _name: Label
var _maker: Label
var _desc: Label
var _equip: UIButton
var _stats := {}
var _upg_rows := {}
var _armed := ""
var _armed_t := 0.0
var _vid := ""
var _cards := {}
var _shop_btn: UIButton


func build() -> void:
	_vid = params.get("vehicle", Profile.selected_vehicle())
	if not Profile.owns(_vid):
		_vid = Profile.selected_vehicle()
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", 18)
	body.add_child(h)

	# ---- owned list ----
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(250, 0)
	left.add_theme_constant_override("separation", 10)
	h.add_child(left)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(sc)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	sc.add_child(_list)
	_shop_btn = UIButton.make("", "BtnSecondary", "shop", Vector2(0, 58))
	_shop_btn.pressed.connect(func(): UI.go("shop"))
	left.add_child(_shop_btn)

	# ---- centre ----
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 6)
	h.add_child(mid)
	_maker = Label.new()
	_maker.add_theme_font_override("font", UI.font_bold)
	_maker.add_theme_font_size_override("font_size", 18)
	mid.add_child(_maker)
	_name = Label.new()
	_name.add_theme_font_override("font", UI.font_display_italic)
	_name.add_theme_font_size_override("font_size", 44)
	mid.add_child(_name)
	_preview = VehiclePreview.new()
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview.custom_minimum_size = Vector2(420, 250)
	mid.add_child(_preview)
	_desc = Label.new()
	_desc.theme_type_variation = "Dim"
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(_desc)
	_equip = UIButton.make("", "BtnPrimary", "check", Vector2(0, 70))
	_equip.pressed.connect(_on_equip)
	mid.add_child(_equip)

	# ---- right: stats + upgrades ----
	var right := PanelContainer.new()
	right.theme_type_variation = "PanelCard"
	right.custom_minimum_size = Vector2(420, 0)
	h.add_child(right)
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 6)
	right.add_child(rv)
	for st in ["power", "speed", "grip", "suspension", "fuel"]:
		var bar := StatBar.new()
		bar.custom_minimum_size = Vector2(380, 40)
		rv.add_child(bar)
		_stats[st] = bar
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 10)
	rv.add_child(sep)
	for t in K.UPGRADE_TYPES:
		var row := _UpgradeRow.new()
		row.type = t
		row.screen = self
		rv.add_child(row)
		row.build_row()
		_upg_rows[t] = row

	_rebuild_list()
	_select(_vid)
	Events.coins_changed.connect(func(_a, _b): _refresh_upgrades())


func _rebuild_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	_cards.clear()
	for id in Profile.owned():
		var card := VehicleCard.new()
		card.setup(id)
		card.chosen.connect(_select)
		_list.add_child(card)
		_cards[id] = card


func _select(id: String) -> void:
	_vid = id
	_armed = ""
	for k in _cards:
		_cards[k].selected = k == id
	var v := DB.vehicle(id)
	_preview.set_vehicle(v)
	refresh_texts()


func _on_equip() -> void:
	if Profile.selected_vehicle() == _vid:
		UI.go("maps")
		return
	Profile.select_vehicle(_vid)
	Audio.sfx("upgrade")
	_preview.rev()
	for k in _cards:
		_cards[k].refresh()
	refresh_texts()


func refresh_texts() -> void:
	title_label.text = Loc.t("title_garage")
	_shop_btn.text = Loc.t("btn_shop")
	var v := DB.vehicle(_vid)
	if v.is_empty():
		return
	_name.text = DB.vehicle_display_name(v)
	var rc := UI.rarity_color(v.rarity)
	_maker.text = "%s  •  %s  •  %s" % [DB.vehicle_maker(v).to_upper(), Loc.t("cat_" + v.category).to_upper(), Loc.t("rarity_" + v.rarity).to_upper()]
	_maker.add_theme_color_override("font_color", rc)
	_desc.text = Loc.t(v.get("desc_key", ""))
	var equipped := Profile.selected_vehicle() == _vid
	_equip.text = Loc.t("btn_drive_this") if equipped else Loc.t("btn_equip")
	_equip.theme_type_variation = "BtnAccent" if equipped else "BtnPrimary"
	_equip.icon = UI.icon("play" if equipped else "check")
	_refresh_upgrades()


func _refresh_upgrades() -> void:
	if not is_inside_tree():
		return
	var v := DB.vehicle(_vid)
	var lv := Profile.levels(_vid)
	var spec := VehicleSpec.build(v, lv)
	var prev: VehicleSpec = null
	if _armed != "":
		var lv2 := lv.duplicate()
		lv2[_armed] = int(lv2[_armed]) + 1
		prev = VehicleSpec.build(v, lv2)
	_set_stat("power", Loc.t("stat_power"), spec, prev, "%d %s" % [int(spec.power_hp), Loc.t("unit_hp")], "engine")
	_set_stat("speed", Loc.t("stat_speed"), spec, prev, "%d %s" % [int(spec.top_kmh), Loc.t("unit_kmh")], "speed")
	_set_stat("grip", Loc.t("stat_grip"), spec, prev, "%.2f" % spec.grip, "grip")
	_set_stat("suspension", Loc.t("stat_suspension"), spec, prev, "%d" % int(spec.rating("suspension")), "suspension")
	var unit: String = v.specs.get("fuel_unit", "L")
	_set_stat("fuel", Loc.t("stat_battery") if unit == "kWh" else Loc.t("stat_fuel"), spec, prev, "%d %s" % [int(spec.fuel_l), Loc.t("unit_kwh") if unit == "kWh" else Loc.t("unit_l")], "tank")
	for t in _upg_rows:
		_upg_rows[t].refresh(v, spec)


func _set_stat(key: String, label: String, spec: VehicleSpec, prev: VehicleSpec, txt: String, ic: String) -> void:
	var cur := spec.rating(key)
	var pv := prev.rating(key) if prev else -1.0
	var col := UI.BLUE
	_stats[key].set_data(label, cur, txt, pv, ic, col)


func _process(delta: float) -> void:
	super(delta)
	if _armed != "":
		_armed_t -= delta
		if _armed_t <= 0.0:
			_armed = ""
			_refresh_upgrades()


func arm_or_buy(type: String) -> void:
	var cost := Economy.upgrade_cost(_vid, type)
	if cost < 0:
		return
	if not Economy.can_afford(cost):
		Audio.sfx("error")
		UI.toast(Loc.t("toast_not_enough_coins"), "bad")
		return
	if _armed != type:
		_armed = type
		_armed_t = 3.0
		_refresh_upgrades()
		return
	_armed = ""
	var r := Economy.buy_upgrade(_vid, type)
	if r == Economy.Result.OK:
		Audio.sfx("upgrade")
		_preview.rev()
		UI.toast(Loc.t("toast_upgraded", [Loc.t("upg_" + type), Profile.upgrade_level(_vid, type)]), "good")
	else:
		Audio.sfx("error")
	_refresh_upgrades()


func value_text(type: String, s: VehicleSpec) -> String:
	match type:
		"engine":
			return "%d %s" % [int(s.power_hp), Loc.t("unit_hp")]
		"suspension":
			return "%d" % int(s.rating("suspension"))
		"tires":
			return "%.2f" % s.grip
		"fuel":
			var unit: String = s.def.specs.get("fuel_unit", "L")
			return "%d %s" % [int(s.fuel_l), Loc.t("unit_kwh") if unit == "kWh" else Loc.t("unit_l")]
	return ""


class _UpgradeRow:
	extends HBoxContainer
	var type := ""
	var screen
	var _name: Label
	var _pips: Control
	var _vals: Label
	var _btn: UIButton
	var _level := 0
	var _max := 8

	func build_row() -> void:
		add_theme_constant_override("separation", 8)
		custom_minimum_size = Vector2(380, 62)
		add_child(ScreenBase.icon_rect(UPG_ICONS[type], 36, UI.TEXT_DIM))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 0)
		add_child(v)
		_name = Label.new()
		_name.add_theme_font_override("font", UI.font_bold)
		_name.add_theme_font_size_override("font_size", 18)
		v.add_child(_name)
		_pips = _Pips.new()
		_pips.custom_minimum_size = Vector2(150, 12)
		v.add_child(_pips)
		_vals = Label.new()
		_vals.theme_type_variation = "Small"
		v.add_child(_vals)
		_btn = UIButton.make("", "BtnGold", "coin", Vector2(140, 56))
		_btn.add_theme_font_size_override("font_size", 20)
		_btn.add_theme_constant_override("icon_max_width", 24)
		_btn.sfx_name = ""
		_btn.pressed.connect(func(): screen.arm_or_buy(type))
		add_child(_btn)

	func refresh(vdef: Dictionary, spec: VehicleSpec) -> void:
		_level = Profile.upgrade_level(screen._vid, type)
		_max = VehicleSpec.max_level(vdef)
		_pips.level = _level
		_pips.max_level = _max
		_pips.queue_redraw()
		_name.text = "%s  %s" % [Loc.t("upg_" + type), Loc.t("lvl_short", [_level, _max])]
		var cost := UpgradeRules.cost(vdef, type, _level)
		if cost < 0:
			_vals.text = screen.value_text(type, spec) + "  •  " + Loc.t("upg_max")
			_btn.text = Loc.t("upg_max")
			_btn.icon = UI.icon("check")
			_btn.disabled = true
			_btn.theme_type_variation = "BtnSecondary"
			return
		var lv2 := Profile.levels(screen._vid)
		lv2[type] = _level + 1
		var nxt := VehicleSpec.build(vdef, lv2)
		_vals.text = "%s → %s" % [screen.value_text(type, spec), screen.value_text(type, nxt)]
		var armed: bool = screen._armed == type
		_btn.disabled = false
		_btn.icon = UI.icon("check" if armed else "coin")
		_btn.text = Loc.t("btn_confirm_short") if armed else Util.fmt_short(cost)
		_btn.theme_type_variation = "BtnPrimary" if armed else ("BtnGold" if Economy.can_afford(cost) else "BtnSecondary")


class _Pips:
	extends Control
	var level := 0
	var max_level := 8

	func _draw() -> void:
		var n := maxi(max_level, 1)
		var gap := 3.0
		var w := (size.x - gap * (n - 1)) / n
		for i in n:
			var c := UI.GREEN if i < level else Color(1, 1, 1, 0.12)
			draw_rect(Rect2(i * (w + gap), 2, w, 8), c)
