## In-run heads-up display. Layout follows the two-thumb mobile convention:
## brake bottom-left, gas bottom-right, RPM + boost bottom-centre, fuel and
## currencies top-left, pause top-right, distance top-centre.
class_name Hud
extends CanvasLayer

signal pause_pressed
signal boost_pressed

var gas_pedal: Pedal
var brake_pedal: Pedal
var boost_btn: BoostButton
var pause_btn: TouchButton
var rpm_gauge: RpmGauge
var fuel_gauge: FuelGauge
var coin_label: Label
var gem_label: Label
var dist_label: Label
var best_label: Label
var progress: ProgressBar
var _root: Control
var _popups: Control
var _hint: PanelContainer
var _hint_label: Label
var _hint_arrow: Control
var _banner: VBoxContainer
var _low_fuel: Label


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var sm := UI.safe_margins()
	var ml: float = 22.0 + float(sm.left)
	var mr: float = 22.0 + float(sm.right)
	var mt: float = 16.0 + float(sm.top)
	var mb: float = 18.0 + float(sm.bottom)

	# ---- top-left: fuel + currencies ----
	var tl := VBoxContainer.new()
	tl.position = Vector2(ml, mt)
	tl.add_theme_constant_override("separation", 8)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(tl)
	fuel_gauge = FuelGauge.new()
	fuel_gauge.custom_minimum_size = Vector2(290, 56)
	tl.add_child(fuel_gauge)
	var cur := HBoxContainer.new()
	cur.add_theme_constant_override("separation", 10)
	tl.add_child(cur)
	coin_label = _currency_pill(cur, "coin")
	gem_label = _currency_pill(cur, "gem")

	# ---- top-centre: distance ----
	var tc := VBoxContainer.new()
	tc.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tc.position = Vector2(-170, mt - 4)
	tc.custom_minimum_size = Vector2(340, 0)
	tc.alignment = BoxContainer.ALIGNMENT_BEGIN
	tc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tc.add_theme_constant_override("separation", 2)
	_root.add_child(tc)
	dist_label = Label.new()
	dist_label.theme_type_variation = "HudNumber"
	dist_label.add_theme_font_size_override("font_size", 40)
	dist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tc.add_child(dist_label)
	progress = ProgressBar.new()
	progress.custom_minimum_size = Vector2(300, 10)
	progress.show_percentage = false
	progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tc.add_child(progress)
	best_label = Label.new()
	best_label.theme_type_variation = "Small"
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	best_label.add_theme_constant_override("outline_size", 4)
	tc.add_child(best_label)

	# ---- top-right: pause ----
	pause_btn = _PauseBtn.new()
	pause_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_btn.size = Vector2(76, 76)
	pause_btn.position = Vector2(-mr - 76, mt)
	pause_btn.pressed_down.connect(func(): pause_pressed.emit())
	_root.add_child(pause_btn)

	# ---- bottom: pedals, rpm, boost ----
	brake_pedal = Pedal.new()
	brake_pedal.kind = "brake"
	brake_pedal.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	brake_pedal.size = Vector2(170, 200)
	brake_pedal.position = Vector2(ml + 8, -mb - 200)
	_root.add_child(brake_pedal)
	gas_pedal = Pedal.new()
	gas_pedal.kind = "gas"
	gas_pedal.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	gas_pedal.size = Vector2(170, 228)
	gas_pedal.position = Vector2(-mr - 178, -mb - 228)
	_root.add_child(gas_pedal)
	rpm_gauge = RpmGauge.new()
	rpm_gauge.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	rpm_gauge.size = Vector2(230, 128)
	rpm_gauge.position = Vector2(-180, -mb - 128)
	rpm_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(rpm_gauge)
	boost_btn = BoostButton.new()
	boost_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	boost_btn.size = Vector2(118, 118)
	boost_btn.position = Vector2(70, -mb - 124)
	boost_btn.pressed_down.connect(func(): boost_pressed.emit())
	_root.add_child(boost_btn)

	# ---- popups / banners / hints ----
	_popups = Control.new()
	_popups.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_popups.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_popups)
	_low_fuel = Label.new()
	_low_fuel.theme_type_variation = "HudNumber"
	_low_fuel.add_theme_color_override("font_color", UI.RED)
	_low_fuel.position = Vector2(ml + 4, mt + 112)
	_low_fuel.visible = false
	_root.add_child(_low_fuel)
	_banner = VBoxContainer.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.position = Vector2(-400, -190)
	_banner.custom_minimum_size = Vector2(800, 0)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	_root.add_child(_banner)
	_hint = PanelContainer.new()
	_hint.theme_type_variation = "PanelGlass"
	_hint.set_anchors_preset(Control.PRESET_CENTER)
	_hint.position = Vector2(-300, -60)
	_hint.custom_minimum_size = Vector2(600, 0)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.visible = false
	_hint_label = Label.new()
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_override("font", UI.font_bold)
	_hint_label.add_theme_font_size_override("font_size", 26)
	_hint.add_child(_hint_label)
	_root.add_child(_hint)
	_hint_arrow = _Arrow.new()
	_hint_arrow.visible = false
	_hint_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_hint_arrow)


func _currency_pill(parent: Control, icon_name: String) -> Label:
	var p := PanelContainer.new()
	var sb := UI.flat(Color(0.03, 0.06, 0.12, 0.65), 20, Color(1, 1, 1, 0.08), 2)
	sb.content_margin_left = 6
	sb.content_margin_right = 14
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	p.add_child(h)
	h.add_child(ScreenBase.icon_rect(icon_name, 32))
	var l := Label.new()
	l.theme_type_variation = "Number"
	l.text = "0"
	h.add_child(l)
	parent.add_child(p)
	return l


func set_controls_visible(v: bool) -> void:
	for c in [gas_pedal, brake_pedal, boost_btn]:
		c.visible = v
		if not v:
			c.force_release()


func popup(text: String, color := Color("ffc93c"), y_offset := 0.0) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UI.font_display_italic)
	l.add_theme_font_size_override("font_size", 40)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(700, 0)
	var vs := _root.get_viewport_rect().size
	l.position = Vector2(vs.x * 0.5 - 350, vs.y * 0.3 + y_offset)
	l.pivot_offset = Vector2(350, 24)
	l.scale = Vector2(0.4, 0.4)
	_popups.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.7)
	tw.parallel().tween_property(l, "position:y", l.position.y - 60, 1.0)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)


func banner(title: String, subtitle := "", color := Color("ffc93c"), hold := 2.0) -> void:
	for c in _banner.get_children():
		c.queue_free()
	var t := Label.new()
	t.text = title
	t.add_theme_font_override("font", UI.font_display_italic)
	t.add_theme_font_size_override("font_size", 64)
	t.add_theme_color_override("font_color", color)
	t.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.65))
	t.add_theme_constant_override("outline_size", 14)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(t)
	if subtitle != "":
		var s := Label.new()
		s.text = subtitle
		s.add_theme_font_override("font", UI.font_bold)
		s.add_theme_font_size_override("font_size", 28)
		s.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
		s.add_theme_constant_override("outline_size", 8)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_banner.add_child(s)
	_banner.visible = true
	_banner.modulate.a = 0.0
	_banner.pivot_offset = Vector2(400, 50)
	_banner.scale = Vector2(1.3, 1.3)
	var tw := _banner.create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(_banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.4)


func show_hint(text: String, target: Control = null) -> void:
	_hint_label.text = text
	_hint.visible = true
	_hint.modulate.a = 0.0
	_hint.create_tween().tween_property(_hint, "modulate:a", 1.0, 0.25)
	_hint_arrow.visible = target != null
	if target:
		(_hint_arrow as _Arrow).target = target


func clear_hint() -> void:
	_hint.visible = false
	_hint_arrow.visible = false


func set_low_fuel(on: bool) -> void:
	_low_fuel.visible = on
	_low_fuel.text = Loc.t("hud_low_fuel")


class _PauseBtn:
	extends TouchButton

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_style_box(UI.flat(Color(0.03, 0.06, 0.12, 0.7 if not is_down else 0.9), 22, Color(1, 1, 1, 0.12), 2), r)
		var ic := UI.icon("pause")
		if ic:
			draw_texture_rect(ic, Rect2(size * 0.25, size * 0.5), false)


class _Arrow:
	extends Control
	var target: Control
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		if target and is_instance_valid(target):
			var r := target.get_global_rect()
			position = Vector2(r.get_center().x - 30, r.position.y - 90 + sin(_t * 6.0) * 10)
			size = Vector2(60, 70)
		queue_redraw()

	func _draw() -> void:
		var pts := PackedVector2Array([Vector2(18, 0), Vector2(42, 0), Vector2(42, 34), Vector2(60, 34), Vector2(30, 68), Vector2(0, 34), Vector2(18, 34)])
		draw_colored_polygon(pts, Color("ffc93c"))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0, 0, 0, 0.5), 3)
