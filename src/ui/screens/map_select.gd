## Map selection: 8 environments with progress, unlock options and DRIVE.
extends ScreenBase

var _scroll: ScrollContainer
var _row: HBoxContainer
var _drive: UIButton
var _car_btn: UIButton
var _cards := {}


func build() -> void:
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 14)
	body.add_child(v)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	v.add_child(_scroll)
	_row = HBoxContainer.new()
	_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_row.add_theme_constant_override("separation", 18)
	_scroll.add_child(_row)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 14)
	v.add_child(bottom)
	_car_btn = UIButton.make("", "BtnSecondary", "car", Vector2(0, 76))
	_car_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_car_btn.pressed.connect(func(): UI.go("garage"))
	bottom.add_child(_car_btn)
	_drive = UIButton.make("", "BtnAccent", "play", Vector2(380, 84))
	_drive.add_theme_font_override("font", UI.font_display_italic)
	_drive.add_theme_font_size_override("font_size", 38)
	_drive.sfx_name = "whoosh"
	_drive.pressed.connect(_start)
	bottom.add_child(_drive)
	_rebuild()
	Events.coins_changed.connect(func(_a, _b): _rebuild())
	await get_tree().process_frame
	var idx := 0
	for e in DB.environments:
		if e.id == Profile.selected_map():
			break
		idx += 1
	_scroll.scroll_horizontal = maxi(0, idx * 318 - 300)


func _rebuild() -> void:
	for c in _row.get_children():
		c.queue_free()
	_cards.clear()
	for e in DB.environments:
		_row.add_child(_card(e))
	refresh_texts()


func _card(e: Dictionary) -> Control:
	var id: String = e.id
	var unlocked := Profile.map_unlocked(id)
	var selected := Profile.selected_map() == id
	var card := Button.new()
	card.flat = true
	card.focus_mode = Control.FOCUS_NONE
	card.custom_minimum_size = Vector2(300, 0)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.clip_contents = true
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override("panel", UI.flat(UI.CARD_HI if selected else UI.CARD, 22, UI.ORANGE if selected else Color(1, 1, 1, 0.08), 4 if selected else 2, 0, 8))
	card.add_child(bg)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(v)
	var th := MapThumb.new()
	th.env = e
	th.dim = not unlocked
	th.custom_minimum_size = Vector2(264, 170)
	th.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(th)
	var name := Label.new()
	name.text = Loc.t(e.name_key)
	name.add_theme_font_override("font", UI.font_display)
	name.add_theme_font_size_override("font_size", 26)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name)
	var desc := Label.new()
	desc.text = Loc.t(e.desc_key)
	desc.theme_type_variation = "Small"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(264, 44)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(desc)
	var info := HBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_theme_constant_override("separation", 6)
	v.add_child(info)
	if unlocked:
		info.add_child(ScreenBase.icon_rect("flag", 22, UI.TEXT_DIM))
		var best := Label.new()
		best.text = Loc.t("map_best", Loc.meters(Profile.best_distance(id)))
		best.theme_type_variation = "Dim"
		info.add_child(best)
		var prog := ProgressBar.new()
		prog.show_percentage = false
		prog.custom_minimum_size = Vector2(264, 10)
		prog.max_value = float(e.goal_m)
		prog.value = minf(Profile.best_distance(id), float(e.goal_m))
		prog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(prog)
		var st := Label.new()
		st.theme_type_variation = "Small"
		st.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if Profile.map_completed(id):
			st.text = Loc.t("map_completed")
			st.add_theme_color_override("font_color", UI.GREEN)
		else:
			st.text = Loc.t("map_goal", Loc.meters(float(e.goal_m)))
		v.add_child(st)
	else:
		var req = e.get("requires", null)
		var lbl := Label.new()
		lbl.theme_type_variation = "Small"
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.custom_minimum_size = Vector2(264, 0)
		lbl.text = Loc.t("map_unlock_hint", Loc.t(DB.env(str(req)).get("name_key", ""))) if req != null else ""
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(lbl)
		if Economy.can_buy_map(id):
			var cost := Economy.map_unlock_cost(id)
			var b := UIButton.make(Loc.num(cost), "BtnGold", "coin", Vector2(0, 54))
			b.disabled = not Economy.can_afford(cost)
			b.pressed.connect(func(): _buy_map(e))
			v.add_child(b)
	card.pressed.connect(func():
		Audio.sfx("click")
		if Profile.map_unlocked(id):
			Profile.select_map(id)
			_rebuild()
		elif Economy.can_buy_map(id):
			_buy_map(e)
		else:
			UI.toast(Loc.t("toast_map_locked"), "bad"))
	_cards[id] = card
	return card


func _buy_map(e: Dictionary) -> void:
	var cost := Economy.map_unlock_cost(e.id)
	if not Economy.can_afford(cost):
		UI.toast(Loc.t("toast_not_enough_coins"), "bad")
		Audio.sfx("error")
		return
	UI.confirm(Loc.t("map_unlock_title"), Loc.t("map_unlock_body", [Loc.t(e.name_key), Loc.num(cost)]), Loc.t("btn_unlock"), func():
		var r := Economy.unlock_map(e.id)
		if r == Economy.Result.OK:
			Audio.sfx("unlock")
			UI.toast(Loc.t("toast_map_unlocked", Loc.t(e.name_key)), "good")
			Profile.select_map(e.id)
			_rebuild()
		else:
			Audio.sfx("error")
			UI.toast(Loc.t("toast_not_enough_coins"), "bad"), "BtnGold")


func _start() -> void:
	UI.go("game", {"map": Profile.selected_map(), "vehicle": Profile.selected_vehicle()})


func refresh_texts() -> void:
	title_label.text = Loc.t("title_maps")
	_drive.text = Loc.t("btn_drive")
	var v := DB.vehicle(Profile.selected_vehicle())
	_car_btn.text = "%s  •  %s" % [DB.vehicle_display_name(v), Loc.t("btn_change_car")]
