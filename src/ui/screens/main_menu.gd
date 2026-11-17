## Main menu: live scenery, logo, PLAY, Garage / Shop / Missions / Achievements,
## Settings and the daily login reward.
extends Control

var params: Dictionary = {}
var _showcase: Showcase
var _play: UIButton
var _play_sub: Label
var _tiles := {}
var _badges := {}
var _gift: UIButton
var _gift_badge: Badge
var _sub_title: Label
var _car_name: Label
var _car_rarity: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_showcase = Showcase.new()
	_showcase.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_showcase)
	var shade := _Shade.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var sm := UI.safe_margins()
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 40 + int(sm.left))
	m.add_theme_constant_override("margin_right", 32 + int(sm.right))
	m.add_theme_constant_override("margin_top", 24 + int(sm.top))
	m.add_theme_constant_override("margin_bottom", 26 + int(sm.bottom))
	add_child(m)
	var root := HBoxContainer.new()
	m.add_child(root)

	# ---- left column ----
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(520, 0)
	left.add_theme_constant_override("separation", 16)
	root.add_child(left)
	var logo := _Logo.new()
	logo.custom_minimum_size = Vector2(520, 150)
	left.add_child(logo)
	_sub_title = Label.new()
	_sub_title.visible = false
	left.add_child(_sub_title)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(spacer)
	_play = UIButton.make("", "BtnAccent", "play", Vector2(520, 104))
	_play.add_theme_font_override("font", UI.font_display_italic)
	_play.add_theme_font_size_override("font_size", 46)
	_play.add_theme_constant_override("icon_max_width", 44)
	_play.sfx_name = "whoosh"
	_play.pressed.connect(func(): UI.go("maps"))
	left.add_child(_play)
	_play_sub = Label.new()
	_play_sub.theme_type_variation = "Dim"
	_play_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_play_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	_play_sub.add_theme_constant_override("outline_size", 4)
	left.add_child(_play_sub)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	left.add_child(grid)
	for t in [["garage", "garage", "BtnBlue"], ["shop", "shop", "BtnSecondary"], ["missions", "missions", "BtnSecondary"], ["achievements", "trophy", "BtnSecondary"]]:
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(253, 74)
		var b := UIButton.make("", t[2], t[1], Vector2(253, 74))
		b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var target: String = t[0]
		b.pressed.connect(func(): UI.go(target))
		holder.add_child(b)
		var bd := Badge.new()
		bd.position = Vector2(232, -8)
		holder.add_child(bd)
		grid.add_child(holder)
		_tiles[t[0]] = b
		_badges[t[0]] = bd

	# ---- right column ----
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(right)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	top.add_theme_constant_override("separation", 12)
	right.add_child(top)
	var gift_holder := Control.new()
	gift_holder.custom_minimum_size = Vector2(64, 64)
	_gift = UIButton.make("", "BtnSecondary", "gift", Vector2(64, 64))
	_gift.add_theme_constant_override("icon_max_width", 36)
	_gift.pressed.connect(_open_daily)
	gift_holder.add_child(_gift)
	_gift_badge = Badge.new()
	_gift_badge.position = Vector2(44, -8)
	gift_holder.add_child(_gift_badge)
	top.add_child(gift_holder)
	top.add_child(CurrencyChip.make("coins"))
	top.add_child(CurrencyChip.make("gems"))
	var settings := UIButton.make("", "BtnSecondary", "settings", Vector2(64, 64))
	settings.add_theme_constant_override("icon_max_width", 34)
	settings.pressed.connect(func(): UI.go("settings"))
	top.add_child(settings)
	var sp2 := Control.new()
	sp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(sp2)
	var car_box := VBoxContainer.new()
	car_box.alignment = BoxContainer.ALIGNMENT_END
	car_box.add_theme_constant_override("separation", 0)
	right.add_child(car_box)
	_car_rarity = Label.new()
	_car_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_car_rarity.add_theme_font_override("font", UI.font_bold)
	_car_rarity.add_theme_font_size_override("font_size", 18)
	car_box.add_child(_car_rarity)
	_car_name = Label.new()
	_car_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_car_name.add_theme_font_override("font", UI.font_display_italic)
	_car_name.add_theme_font_size_override("font_size", 40)
	_car_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	_car_name.add_theme_constant_override("outline_size", 8)
	car_box.add_child(_car_name)

	_refresh()
	Events.language_changed.connect(func(_l): _refresh())
	Events.missions_changed.connect(_refresh_badges)
	Events.achievements_changed.connect(_refresh_badges)
	Progress.refresh_daily()
	if Economy.login_state().can_claim:
		get_tree().create_timer(0.6).timeout.connect(func():
			if is_inside_tree() and not UI.has_dialog():
				_open_daily())


func _refresh() -> void:
	_play.text = Loc.t("btn_play")
	_tiles.garage.text = Loc.t("btn_garage")
	_tiles.shop.text = Loc.t("btn_shop")
	_tiles.missions.text = Loc.t("btn_missions")
	_tiles.achievements.text = Loc.t("btn_achievements")
	var e := DB.env(Profile.selected_map())
	var v := DB.vehicle(Profile.selected_vehicle())
	_play_sub.text = "%s  •  %s" % [Loc.t(e.get("name_key", "")), DB.vehicle_display_name(v)]
	_car_name.text = DB.vehicle_display_name(v)
	_car_rarity.text = "%s  •  %s" % [DB.vehicle_maker(v).to_upper(), Loc.t("rarity_" + v.get("rarity", "common")).to_upper()]
	_car_rarity.add_theme_color_override("font_color", UI.rarity_color(v.get("rarity", "common")))
	_refresh_badges()


func _refresh_badges() -> void:
	if not is_inside_tree():
		return
	_badges.missions.set_count(Progress.claimable_missions())
	_badges.achievements.set_count(Progress.claimable_achievements())
	_badges.garage.set_count(0)
	_badges.shop.set_count(0)
	_gift_badge.set_count(1 if Economy.login_state().can_claim else 0)


func _open_daily() -> void:
	var st := Economy.login_state()
	var rewards: Array = DB.eco("daily_login", [])
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 8)
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in rewards.size():
		var r: Dictionary = rewards[i]
		var cell := PanelContainer.new()
		var today: bool = st.can_claim and i == st.next_day
		var done: bool = (not st.can_claim and i <= int(st.day)) or (st.can_claim and i < int(st.next_day))
		var sb := UI.flat(UI.CARD_HI if today else UI.CARD, 14, UI.GOLD if today else Color(1, 1, 1, 0.08), 3 if today else 2)
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		cell.add_theme_stylebox_override("panel", sb)
		cell.custom_minimum_size = Vector2(84, 118)
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_child(v)
		var d := Label.new()
		d.text = Loc.t("daily_day", i + 1)
		d.theme_type_variation = "Small"
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(d)
		var is_gem := int(r.get("gems", 0)) > 0 and int(r.get("coins", 0)) == 0
		var ic := ScreenBase.icon_rect("check" if done else ("gem" if is_gem else "coin"), 34, UI.GREEN if done else Color.WHITE)
		v.add_child(ic)
		var amt := Label.new()
		amt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amt.add_theme_font_override("font", UI.font_display)
		amt.add_theme_font_size_override("font_size", 16)
		var parts: Array = []
		if int(r.get("coins", 0)) > 0:
			parts.append(Util.fmt_short(int(r.coins)))
		if int(r.get("gems", 0)) > 0:
			parts.append("+%d" % int(r.gems))
		amt.text = " ".join(parts)
		if int(r.get("coins", 0)) > 0 and int(r.get("gems", 0)) > 0 and not done:
			ic.texture = UI.icon("gift")
		v.add_child(amt)
		grid.add_child(cell)
	if st.can_claim:
		UI.confirm(Loc.t("daily_title"), Loc.t("daily_body"), Loc.t("btn_claim"), func():
			var got := Economy.claim_daily_login()
			if not got.is_empty():
				Audio.sfx("reward")
				UI.toast(Loc.t("toast_daily_claimed"), "gold")
			_refresh_badges()
		, "BtnGold", Loc.t("btn_later"), grid)
	else:
		UI.alert(Loc.t("daily_title"), Loc.t("daily_come_back", Util.fmt_duration(Util.seconds_until_midnight())), grid)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if not UI.close_top_dialog():
			UI.confirm(Loc.t("quit_title"), "", Loc.t("btn_quit"), func():
				Save.flush()
				get_tree().quit(), "BtnDanger")


class _Shade:
	extends Control

	func _draw() -> void:
		var r := get_rect()
		var c0 := Color(0.04, 0.07, 0.14, 0.82)
		var c1 := Color(0.04, 0.07, 0.14, 0.0)
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(r.size.x * 0.55, 0), Vector2(r.size.x * 0.55, r.size.y), Vector2(0, r.size.y)]),
			PackedColorArray([c0, c1, c1, c0]))
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(r.size.x, 0), Vector2(r.size.x, 110), Vector2(0, 110)]),
			PackedColorArray([Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), Color(0, 0, 0, 0)]))


class _Logo:
	extends Control
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _draw() -> void:
		var f := UI.font_display_italic
		var y := 86.0
		# speed lines
		for i in 3:
			var w := 70.0 - i * 18
			draw_rect(Rect2(0, y - 52 + i * 16, w, 6), Color(1, 0.54, 0.12, 0.85 - i * 0.2))
		draw_string(f, Vector2(88, y + 4), "UZ", HORIZONTAL_ALIGNMENT_LEFT, -1, 92, Color(0, 0, 0, 0.35))
		draw_string(f, Vector2(84, y), "UZ", HORIZONTAL_ALIGNMENT_LEFT, -1, 92, Color("ff8a1f"))
		var uzw := f.get_string_size("UZ", HORIZONTAL_ALIGNMENT_LEFT, -1, 92).x
		draw_string(f, Vector2(100 + uzw, y + 4), "DRIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 92, Color(0, 0, 0, 0.35))
		draw_string(f, Vector2(96 + uzw, y), "DRIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 92, Color.WHITE)
		var sub := Loc.t("logo_sub").to_upper()
		draw_rect(Rect2(92, y + 18, 380, 34), Color("2bd576"))
		draw_string(UI.font_display, Vector2(92, y + 44), sub, HORIZONTAL_ALIGNMENT_CENTER, 380, 26, Color("06281a"))
