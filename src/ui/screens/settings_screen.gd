## Settings: language, sound, music, volumes, vibration, graphics quality,
## privacy & credits, progress reset (double confirmation).
extends ScreenBase

var _rows: VBoxContainer
var _lang_btns := {}


func build() -> void:
	var sc := ScrollContainer.new()
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(sc)
	var c := CenterContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(c)
	_rows = VBoxContainer.new()
	_rows.custom_minimum_size = Vector2(820, 0)
	_rows.add_theme_constant_override("separation", 12)
	c.add_child(_rows)


func refresh_texts() -> void:
	title_label.text = Loc.t("title_settings")
	if _rows == null:
		return
	for ch in _rows.get_children():
		ch.queue_free()
	# language
	var lang := _panel("globe", Loc.t("set_language"))
	var lh := HBoxContainer.new()
	lh.add_theme_constant_override("separation", 10)
	lang.add_child(lh)
	for l in K.LANGS:
		var b := UIButton.make(Loc.NAMES[l], "BtnPrimary" if Loc.lang == l else "BtnSecondary", "", Vector2(180, 56))
		b.pressed.connect(func():
			if Loc.lang != l:
				Loc.set_language(l))
		lh.add_child(b)
	# audio
	var snd := _panel("sound_on", Loc.t("set_sound"))
	snd.add_child(_toggle("sound"))
	snd.add_child(_slider("sfx_volume"))
	var mus := _panel("music_on", Loc.t("set_music"))
	mus.add_child(_toggle("music"))
	mus.add_child(_slider("music_volume"))
	var vib := _panel("vibration", Loc.t("set_vibration"))
	vib.add_child(_toggle("vibration"))
	# quality
	var q := _panel("quality", Loc.t("set_quality"))
	var qh := HBoxContainer.new()
	qh.add_theme_constant_override("separation", 10)
	q.add_child(qh)
	for qq in ["high", "low"]:
		var b2 := UIButton.make(Loc.t("quality_" + qq), "BtnPrimary" if Profile.setting("quality", "high") == qq else "BtnSecondary", "", Vector2(160, 52))
		b2.pressed.connect(func():
			Profile.set_setting("quality", qq)
			refresh_texts())
		qh.add_child(b2)
	# about / privacy
	var ab := _panel("privacy", Loc.t("set_privacy"))
	var pb := UIButton.make(Loc.t("btn_view"), "BtnGhost", "", Vector2(160, 52))
	pb.pressed.connect(func(): UI.alert(Loc.t("set_privacy"), Loc.t("privacy_text")))
	ab.add_child(pb)
	var cr := _panel("info", Loc.t("set_about"))
	var cb := UIButton.make(Loc.t("btn_view"), "BtnGhost", "", Vector2(160, 52))
	cb.pressed.connect(func(): UI.alert(Loc.t("set_about"), Loc.t("about_text", ProjectSettings.get_setting("application/config/version", "1.0.0"))))
	cr.add_child(cb)
	# reset
	var rs := _panel("reset", Loc.t("set_reset"))
	var rb := UIButton.make(Loc.t("btn_reset"), "BtnDanger", "", Vector2(160, 52))
	rb.pressed.connect(_reset)
	rs.add_child(rb)


func _panel(icon_name: String, title: String) -> HBoxContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = "PanelCard"
	_rows.add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	p.add_child(h)
	h.add_child(ScreenBase.icon_rect(icon_name, 34, UI.TEXT_DIM))
	var l := Label.new()
	l.text = title
	l.add_theme_font_override("font", UI.font_bold)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return h


func _toggle(key: String) -> UIToggle:
	var t := UIToggle.new()
	t.set_on(bool(Profile.setting(key, true)))
	t.toggled.connect(func(on): Profile.set_setting(key, on))
	return t


func _slider(key: String) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = float(Profile.setting(key, 0.8))
	s.custom_minimum_size = Vector2(220, 30)
	s.value_changed.connect(func(v): Profile.set_setting(key, v))
	return s


func _reset() -> void:
	UI.confirm(Loc.t("reset_title"), Loc.t("reset_body"), Loc.t("btn_reset"), func():
		UI.confirm(Loc.t("reset_title2"), Loc.t("reset_body2"), Loc.t("btn_reset_confirm"), func():
			Profile.reset_progress()
			Progress.refresh_daily()
			UI.toast(Loc.t("toast_reset"), "info")
			UI.go("main_menu")
		, "BtnDanger")
	, "BtnDanger")
