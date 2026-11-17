## Long-term tiered achievements with progress and claimable rewards.
extends ScreenBase

var _grid: GridContainer


func build() -> void:
	var sc := ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_grid)
	_rebuild()
	Events.achievements_changed.connect(func():
		if is_inside_tree():
			_rebuild())


func _rebuild() -> void:
	for c in _grid.get_children():
		c.queue_free()
	var list: Array = DB.achievements.duplicate()
	list.sort_custom(func(a, b):
		var sa := Progress.achievement_state(a)
		var sb := Progress.achievement_state(b)
		if sa.can_claim != sb.can_claim:
			return sa.can_claim
		if sa.complete != sb.complete:
			return not sa.complete
		return false)
	for a in list:
		_grid.add_child(_card(a))


func _card(a: Dictionary) -> Control:
	var st := Progress.achievement_state(a)
	var p := PanelContainer.new()
	p.theme_type_variation = "PanelCard"
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(590, 0)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	h.add_child(ScreenBase.icon_rect("trophy_gold" if st.complete or st.can_claim else "trophy", 52, Color.WHITE if st.complete or st.can_claim else UI.TEXT_MUTED))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var t := Label.new()
	t.text = Loc.t("ach_" + str(a.id))
	t.add_theme_font_override("font", UI.font_display)
	t.add_theme_font_size_override("font_size", 22)
	v.add_child(t)
	var d := Label.new()
	d.theme_type_variation = "Small"
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.text = Loc.t("achd_" + str(a.id), _fmt(str(a.metric), float(st.target)))
	v.add_child(d)
	var stars := _Stars.new()
	stars.total = int(st.tiers)
	stars.filled = int(st.claimed)
	stars.custom_minimum_size = Vector2(140, 22)
	v.add_child(stars)
	if not st.complete:
		var pr := ProgressBar.new()
		pr.show_percentage = false
		pr.custom_minimum_size = Vector2(0, 12)
		pr.max_value = float(st.target)
		pr.value = minf(float(st.value), float(st.target))
		v.add_child(pr)
		var pl := Label.new()
		pl.theme_type_variation = "Small"
		pl.text = "%s / %s" % [_fmt(str(a.metric), float(st.value)), _fmt(str(a.metric), float(st.target))]
		v.add_child(pl)
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(right)
	if st.complete:
		var l := Label.new()
		l.text = Loc.t("ach_done")
		l.add_theme_color_override("font_color", UI.GREEN)
		l.add_theme_font_override("font", UI.font_bold)
		right.add_child(l)
	else:
		var r: Dictionary = st.reward
		var rh := HBoxContainer.new()
		rh.alignment = BoxContainer.ALIGNMENT_CENTER
		var is_gem := int(r.get("gems", 0)) > 0
		rh.add_child(ScreenBase.icon_rect("gem" if is_gem else "coin", 26))
		var rl := Label.new()
		rl.theme_type_variation = "Number"
		rl.text = Loc.num(int(r.get("gems", 0)) if is_gem else int(r.get("coins", 0)))
		rh.add_child(rl)
		right.add_child(rh)
		var b := UIButton.make(Loc.t("btn_claim"), "BtnGold" if st.can_claim else "BtnSecondary", "", Vector2(150, 54))
		b.disabled = not st.can_claim
		if st.can_claim:
			b.pulse()
		b.pressed.connect(func():
			var got := Progress.claim_achievement(a.id)
			if not got.is_empty():
				Audio.sfx("reward")
				UI.toast(Loc.t("toast_reward"), "gold"))
		right.add_child(b)
	return p


func _fmt(metric: String, v: float) -> String:
	match metric:
		"total_distance", "best_run":
			return Loc.meters(v)
		"best_airtime":
			return Loc.t("unit_s_dec", v)
	return Loc.num(int(v))


func refresh_texts() -> void:
	title_label.text = Loc.t("title_achievements")
	if _grid:
		_rebuild()


class _Stars:
	extends Control
	var total := 3
	var filled := 0

	func _draw() -> void:
		var tex := UI.icon("star")
		for i in total:
			if tex:
				draw_texture_rect(tex, Rect2(i * 26, 0, 22, 22), false, UI.GOLD if i < filled else Color(1, 1, 1, 0.15))
