## Daily missions (3 per day + all-done bonus) with progress and claim.
extends ScreenBase

var _list: VBoxContainer
var _reset: Label
var _bonus_row: HBoxContainer


func build() -> void:
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 12)
	body.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	top.add_child(ScreenBase.icon_rect("calendar", 30, UI.TEXT_DIM))
	_reset = Label.new()
	_reset.theme_type_variation = "Dim"
	top.add_child(_reset)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 12)
	v.add_child(_list)
	_bonus_row = HBoxContainer.new()
	v.add_child(_bonus_row)
	_rebuild()
	Events.missions_changed.connect(func():
		if is_inside_tree():
			_rebuild())


func _process(delta: float) -> void:
	super(delta)
	if _reset:
		_reset.text = Loc.t("missions_reset", Util.fmt_duration(Util.seconds_until_midnight()))


func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	var ms := Progress.missions()
	for i in ms.size():
		_list.add_child(_row(i, ms[i]))
	for c in _bonus_row.get_children():
		c.queue_free()
	var b: Dictionary = DB.missions.get("all_done_bonus", {})
	var p := PanelContainer.new()
	p.theme_type_variation = "PanelGlass"
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bonus_row.add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)
	h.add_child(ScreenBase.icon_rect("gift", 44))
	var l := Label.new()
	l.text = Loc.t("missions_bonus", int(b.get("gems", 0)))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_override("font", UI.font_bold)
	h.add_child(l)
	var claimed := bool(Profile.data.missions.get("bonus_claimed", false))
	var btn := UIButton.make(Loc.t("btn_claimed") if claimed else Loc.t("btn_claim"), "BtnGold" if Progress.can_claim_bonus() else "BtnSecondary", "gem", Vector2(200, 58))
	btn.disabled = not Progress.can_claim_bonus()
	btn.pressed.connect(func():
		if Progress.claim_bonus():
			Audio.sfx("reward")
			UI.toast(Loc.t("toast_reward"), "gold"))
	h.add_child(btn)


func _row(i: int, mi: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.theme_type_variation = "PanelCard"
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	p.add_child(h)
	var done := Progress.mission_done(mi)
	h.add_child(ScreenBase.icon_rect("check" if mi.claimed else "missions", 44, UI.GREEN if done else UI.TEXT_DIM))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var t := Label.new()
	var target := float(mi.target)
	t.text = Loc.t("mission_" + str(mi.tid), _fmt_target(str(mi.metric), target))
	t.add_theme_font_override("font", UI.font_bold)
	t.add_theme_font_size_override("font_size", 22)
	v.add_child(t)
	var pr := ProgressBar.new()
	pr.show_percentage = false
	pr.custom_minimum_size = Vector2(0, 14)
	pr.max_value = target
	pr.value = float(mi.progress)
	v.add_child(pr)
	var pl := Label.new()
	pl.theme_type_variation = "Small"
	pl.text = "%s / %s" % [_fmt_target(str(mi.metric), float(mi.progress)), _fmt_target(str(mi.metric), target)]
	v.add_child(pl)
	var reward := HBoxContainer.new()
	reward.add_child(ScreenBase.icon_rect("coin", 28))
	var rl := Label.new()
	rl.theme_type_variation = "Number"
	rl.text = Loc.num(int(mi.coins))
	reward.add_child(rl)
	h.add_child(reward)
	var b := UIButton.make("", "BtnGold", "", Vector2(170, 58))
	if mi.claimed:
		b.text = Loc.t("btn_claimed")
		b.disabled = true
		b.theme_type_variation = "BtnSecondary"
	elif done:
		b.text = Loc.t("btn_claim")
		b.pulse()
	else:
		b.text = Loc.t("btn_in_progress")
		b.disabled = true
		b.theme_type_variation = "BtnSecondary"
	var idx := i
	b.pressed.connect(func():
		if Progress.claim_mission(idx):
			Audio.sfx("reward")
			UI.toast(Loc.t("toast_reward"), "gold"))
	h.add_child(b)
	return p


func _fmt_target(metric: String, v: float) -> String:
	match metric:
		"distance", "run_distance":
			return Loc.meters(v)
		"airtime", "wheelie":
			return Loc.t("unit_s", int(v))
	return Loc.num(int(v))


func refresh_texts() -> void:
	title_label.text = Loc.t("title_missions")
	if _list:
		_rebuild()
