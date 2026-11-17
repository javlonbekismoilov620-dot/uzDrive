## Vehicle dealership (browse / filter / sort / compare / buy) + gem exchange.
extends ScreenBase

const SORTS := ["sort_price_asc", "sort_price_desc", "sort_rarity", "sort_power"]

var _tab_vehicles: Button
var _tab_exchange: Button
var _vehicles_view: HBoxContainer
var _exchange_view: CenterContainer
var _chips: HBoxContainer
var _grid: GridContainer
var _sort_btn: UIButton
var _sort_i := 0
var _filter := "all"
var _sel := ""
var _cards := {}
# detail panel
var _d_preview: VehiclePreview
var _d_name: Label
var _d_meta: Label
var _d_desc: Label
var _d_stats := {}
var _d_buy: UIButton
var _d_cmp: Label


func build() -> void:
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 10)
	body.add_child(v)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	v.add_child(tabs)
	var group := ButtonGroup.new()
	_tab_vehicles = _chip("", group, true)
	_tab_vehicles.pressed.connect(func(): _show_tab(true))
	tabs.add_child(_tab_vehicles)
	_tab_exchange = _chip("", group, false)
	_tab_exchange.pressed.connect(func(): _show_tab(false))
	tabs.add_child(_tab_exchange)

	_vehicles_view = HBoxContainer.new()
	_vehicles_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vehicles_view.add_theme_constant_override("separation", 16)
	v.add_child(_vehicles_view)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	_vehicles_view.add_child(left)
	var fr := HBoxContainer.new()
	fr.add_theme_constant_override("separation", 8)
	left.add_child(fr)
	var chip_scroll := ScrollContainer.new()
	chip_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	chip_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	chip_scroll.custom_minimum_size = Vector2(0, 48)
	fr.add_child(chip_scroll)
	_chips = HBoxContainer.new()
	_chips.add_theme_constant_override("separation", 8)
	chip_scroll.add_child(_chips)
	_sort_btn = UIButton.make("", "BtnGhost", "sort", Vector2(0, 46))
	_sort_btn.add_theme_constant_override("icon_max_width", 22)
	_sort_btn.add_theme_font_size_override("font_size", 17)
	_sort_btn.pressed.connect(func():
		_sort_i = (_sort_i + 1) % SORTS.size()
		_rebuild_grid())
	fr.add_child(_sort_btn)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(sc)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	sc.add_child(_grid)

	var detail := PanelContainer.new()
	detail.theme_type_variation = "PanelCard"
	detail.custom_minimum_size = Vector2(430, 0)
	_vehicles_view.add_child(detail)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 2)
	detail.add_child(dv)
	detail.add_theme_stylebox_override("panel", _detail_style())
	_d_meta = Label.new()
	_d_meta.add_theme_font_override("font", UI.font_bold)
	_d_meta.add_theme_font_size_override("font_size", 16)
	dv.add_child(_d_meta)
	_d_name = Label.new()
	_d_name.add_theme_font_override("font", UI.font_display_italic)
	_d_name.add_theme_font_size_override("font_size", 30)
	dv.add_child(_d_name)
	_d_preview = VehiclePreview.new()
	_d_preview.custom_minimum_size = Vector2(390, 118)
	dv.add_child(_d_preview)
	_d_desc = Label.new()
	_d_desc.theme_type_variation = "Small"
	_d_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_d_desc.custom_minimum_size = Vector2(390, 0)
	dv.add_child(_d_desc)
	_d_cmp = Label.new()
	_d_cmp.theme_type_variation = "Small"
	_d_cmp.add_theme_color_override("font_color", UI.TEXT_MUTED)
	dv.add_child(_d_cmp)
	for st in ["power", "speed", "grip", "suspension", "fuel"]:
		var bar := StatBar.new()
		bar.custom_minimum_size = Vector2(390, 36)
		dv.add_child(bar)
		_d_stats[st] = bar
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dv.add_child(spacer)
	_d_buy = UIButton.make("", "BtnGold", "coin", Vector2(0, 60))
	_d_buy.sfx_name = ""
	_d_buy.pressed.connect(_on_buy)
	dv.add_child(_d_buy)

	_exchange_view = CenterContainer.new()
	_exchange_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_exchange_view.visible = false
	v.add_child(_exchange_view)

	_build_chips()
	_rebuild_grid()
	var first := ""
	for id in _sorted_ids():
		if not Profile.owns(id):
			first = id
			break
	_select(params.get("vehicle", first if first != "" else Profile.selected_vehicle()))
	Events.coins_changed.connect(func(_a, _b): _refresh_cards())
	Events.gems_changed.connect(func(_a, _b): _refresh_cards())


func _detail_style() -> StyleBoxFlat:
	var sb := UI.flat(UI.CARD, 20, UI.STROKE, 2, 0, 6)
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


func _chip(txt: String, group: ButtonGroup, pressed_on: bool) -> Button:
	var b := Button.new()
	b.theme_type_variation = "BtnChip"
	b.toggle_mode = true
	b.button_group = group
	b.button_pressed = pressed_on
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 44)
	return b


func _show_tab(vehicles: bool) -> void:
	Audio.sfx("click")
	_vehicles_view.visible = vehicles
	_exchange_view.visible = not vehicles
	if not vehicles:
		_build_exchange()


func _build_chips() -> void:
	for c in _chips.get_children():
		c.queue_free()
	var g := ButtonGroup.new()
	for cat in ["all"] + K.CATEGORIES:
		var b := _chip(Loc.t("cat_" + cat), g, cat == _filter)
		var cc: String = cat
		b.pressed.connect(func():
			Audio.sfx("click")
			_filter = cc
			_rebuild_grid())
		_chips.add_child(b)


func _sorted_ids() -> Array:
	var list: Array = []
	for v in DB.vehicles:
		if _filter == "all" or v.category == _filter:
			list.append(v)
	var key: String = SORTS[_sort_i]
	var price_of := func(v: Dictionary) -> float:
		return float(v.price) * (6000.0 if v.get("currency", "coins") == "gems" else 1.0)
	match key:
		"sort_price_asc":
			list.sort_custom(func(a, b): return price_of.call(a) < price_of.call(b))
		"sort_price_desc":
			list.sort_custom(func(a, b): return price_of.call(a) > price_of.call(b))
		"sort_rarity":
			list.sort_custom(func(a, b):
				var ra := K.RARITIES.find(a.rarity)
				var rb := K.RARITIES.find(b.rarity)
				return ra > rb if ra != rb else price_of.call(a) > price_of.call(b))
		"sort_power":
			list.sort_custom(func(a, b): return float(a.specs.power_hp) > float(b.specs.power_hp))
	var ids: Array = []
	for v in list:
		ids.append(v.id)
	return ids


func _rebuild_grid() -> void:
	for c in _grid.get_children():
		c.queue_free()
	_cards.clear()
	for id in _sorted_ids():
		var card := VehicleCard.new()
		card.setup(id)
		card.selected = id == _sel
		card.chosen.connect(_select)
		_grid.add_child(card)
		_cards[id] = card
	_sort_btn.text = Loc.t(SORTS[_sort_i])


func _refresh_cards() -> void:
	if not is_inside_tree():
		return
	for k in _cards:
		_cards[k].refresh()
	_refresh_detail()


func _select(id: String) -> void:
	if DB.vehicle(id).is_empty():
		return
	_sel = id
	for k in _cards:
		_cards[k].selected = k == id
	_d_preview.set_vehicle(DB.vehicle(id))
	_refresh_detail()


func _refresh_detail() -> void:
	var v := DB.vehicle(_sel)
	if v.is_empty():
		return
	var rc := UI.rarity_color(v.rarity)
	_d_meta.text = "%s  •  %s  •  %s" % [DB.vehicle_maker(v).to_upper(), Loc.t("cat_" + v.category).to_upper(), Loc.t("rarity_" + v.rarity).to_upper()]
	_d_meta.add_theme_color_override("font_color", rc)
	_d_name.text = DB.vehicle_display_name(v)
	_d_desc.text = Loc.t(v.get("desc_key", ""))
	var owned := Profile.owns(_sel)
	var spec := Profile.spec_for(_sel) if owned else VehicleSpec.build(v, {})
	var cur := Profile.spec_for(Profile.selected_vehicle())
	var comparing := _sel != Profile.selected_vehicle()
	_d_cmp.text = Loc.t("shop_compare", DB.vehicle_display_name(DB.vehicle(Profile.selected_vehicle()))) if comparing else ""
	var unit: String = v.specs.get("fuel_unit", "L")
	var defs := [
		["power", Loc.t("stat_power"), "%d %s" % [int(spec.power_hp), Loc.t("unit_hp")], "engine"],
		["speed", Loc.t("stat_speed"), "%d %s" % [int(spec.top_kmh), Loc.t("unit_kmh")], "speed"],
		["grip", Loc.t("stat_grip"), "%.2f" % spec.grip, "grip"],
		["suspension", Loc.t("stat_suspension"), "%d" % int(spec.rating("suspension")), "suspension"],
		["fuel", Loc.t("stat_battery") if unit == "kWh" else Loc.t("stat_fuel"), "%d %s" % [int(spec.fuel_l), Loc.t("unit_kwh") if unit == "kWh" else Loc.t("unit_l")], "tank"],
	]
	for d in defs:
		var key: String = d[0]
		if comparing:
			_d_stats[key].set_data(d[1], cur.rating(key), d[2], spec.rating(key), d[3], UI.TEXT_MUTED)
		else:
			_d_stats[key].set_data(d[1], spec.rating(key), d[2], -1.0, d[3], UI.BLUE)
	var cur_kind: String = v.get("currency", "coins")
	if owned:
		var eq := Profile.selected_vehicle() == _sel
		_d_buy.text = Loc.t("tag_equipped") if eq else Loc.t("btn_equip")
		_d_buy.icon = UI.icon("check")
		_d_buy.theme_type_variation = "BtnSecondary" if eq else "BtnPrimary"
		_d_buy.disabled = eq
	else:
		var price := int(v.price)
		var afford := Economy.can_afford(price, cur_kind)
		_d_buy.icon = UI.icon("coin" if cur_kind == "coins" else "gem")
		_d_buy.disabled = false
		if afford:
			_d_buy.text = Loc.t("btn_buy_for", Loc.num(price))
			_d_buy.theme_type_variation = "BtnGold" if cur_kind == "coins" else "BtnBlue"
		else:
			var have := Economy.coins() if cur_kind == "coins" else Economy.gems()
			_d_buy.text = Loc.t("shop_need_more", Loc.num(price - have))
			_d_buy.theme_type_variation = "BtnSecondary"


func _on_buy() -> void:
	var v := DB.vehicle(_sel)
	if Profile.owns(_sel):
		Profile.select_vehicle(_sel)
		Audio.sfx("upgrade")
		_refresh_cards()
		return
	var cur_kind: String = v.get("currency", "coins")
	var price := int(v.price)
	if not Economy.can_afford(price, cur_kind):
		Audio.sfx("error")
		UI.toast(Loc.t("toast_not_enough_gems") if cur_kind == "gems" else Loc.t("toast_not_enough_coins"), "bad")
		return
	Audio.sfx("click")
	var pv := VehiclePreview.new()
	pv.animated = false
	pv.show_platform = false
	pv.custom_minimum_size = Vector2(420, 130)
	pv.set_vehicle(v)
	var price_txt := "%s %s" % [Loc.num(price), Loc.t("word_coins") if cur_kind == "coins" else Loc.t("word_gems")]
	UI.confirm(Loc.t("buy_title"), Loc.t("buy_body", [DB.vehicle_display_name(v), price_txt]), Loc.t("btn_buy"), func():
		var r := Economy.buy_vehicle(_sel)
		if r == Economy.Result.OK:
			Audio.sfx("purchase")
			Profile.select_vehicle(_sel)
			UI.toast(Loc.t("toast_bought", DB.vehicle_display_name(v)), "good")
			_d_preview.rev()
		else:
			Audio.sfx("error")
			UI.toast(Loc.t("toast_not_enough_coins"), "bad")
		_refresh_cards()
	, "BtnGold" if cur_kind == "coins" else "BtnBlue", "", pv)


func _build_exchange() -> void:
	for c in _exchange_view.get_children():
		c.queue_free()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	_exchange_view.add_child(v)
	var t := Label.new()
	t.theme_type_variation = "Dim"
	t.text = Loc.t("exchange_hint")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	v.add_child(h)
	var packs: Array = DB.eco("gem_exchange", [])
	for i in packs.size():
		var p: Dictionary = packs[i]
		var card := PanelContainer.new()
		card.theme_type_variation = "PanelCard"
		card.custom_minimum_size = Vector2(280, 300)
		h.add_child(card)
		var cv := VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.add_theme_constant_override("separation", 10)
		card.add_child(cv)
		var ic := ScreenBase.icon_rect("coin", 90)
		cv.add_child(ic)
		var amt := Label.new()
		amt.text = Loc.num(int(p.coins))
		amt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amt.add_theme_font_override("font", UI.font_display)
		amt.add_theme_font_size_override("font_size", 40)
		amt.add_theme_color_override("font_color", UI.GOLD)
		cv.add_child(amt)
		var w := Label.new()
		w.text = Loc.t("word_coins")
		w.theme_type_variation = "Dim"
		w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(w)
		var b := UIButton.make(str(int(p.gems)), "BtnBlue", "gem", Vector2(0, 62))
		b.disabled = not Economy.can_afford(int(p.gems), "gems")
		var idx := i
		b.pressed.connect(func():
			UI.confirm(Loc.t("exchange_title"), Loc.t("exchange_body", [int(p.gems), Loc.num(int(p.coins))]), Loc.t("btn_confirm"), func():
				if Economy.exchange_gems(idx) == Economy.Result.OK:
					Audio.sfx("purchase")
					UI.toast(Loc.t("toast_exchanged"), "good")
				else:
					Audio.sfx("error")
				_build_exchange()
			, "BtnBlue"))
		cv.add_child(b)


func refresh_texts() -> void:
	title_label.text = Loc.t("title_shop")
	_tab_vehicles.text = Loc.t("tab_vehicles")
	_tab_exchange.text = Loc.t("tab_exchange")
	_build_chips()
	_sort_btn.text = Loc.t(SORTS[_sort_i])
	for k in _cards:
		_cards[k].refresh()
	_refresh_detail()
	if _exchange_view.visible:
		_build_exchange()
