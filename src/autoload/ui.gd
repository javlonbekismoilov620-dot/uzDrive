## Design system + global UI services: theme, fonts, colour tokens, icons,
## screen transitions, toasts and modal dialogs.
extends Node

# ---- colour tokens ----
const BG_DEEP := Color("0c1424")
const BG := Color("111c31")
const PANEL := Color("172540")
const CARD := Color("1e2f50")
const CARD_HI := Color("27406b")
const STROKE := Color("2f4772")
const TEXT := Color("f4f7fb")
const TEXT_DIM := Color("9db0cc")
const TEXT_MUTED := Color("6c7f9e")
const GREEN := Color("2bd576")
const GREEN_D := Color("17a454")
const ORANGE := Color("ff8a1f")
const ORANGE_D := Color("d8590c")
const BLUE := Color("3d8bff")
const BLUE_D := Color("2160c9")
const RED := Color("ff4d5a")
const RED_D := Color("c22834")
const GOLD := Color("ffc93c")
const GEM := Color("38d9f5")

var theme: Theme
var font_body: FontVariation
var font_bold: FontVariation
var font_display: FontVariation
var font_display_italic: FontVariation
var router: Node
var _icons := {}
var _overlay: CanvasLayer
var _fade: ColorRect
var _toast_box: VBoxContainer
var busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_fonts()
	theme = build_theme()
	get_tree().root.theme = theme
	_overlay = CanvasLayer.new()
	_overlay.layer = 100
	add_child(_overlay)
	_fade = ColorRect.new()
	_fade.color = Color(BG_DEEP, 0.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(_fade)
	_toast_box = VBoxContainer.new()
	_toast_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_box.position = Vector2(-260, 90)
	_toast_box.custom_minimum_size = Vector2(520, 0)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.add_theme_constant_override("separation", 8)
	_overlay.add_child(_toast_box)
	Events.toast.connect(toast)


# ------------------------------------------------------------------ fonts
func _var_font(path: String, weight: int) -> FontVariation:
	var f := FontVariation.new()
	var base: FontFile = load(path)
	f.base_font = base
	var ts := TextServerManager.get_primary_interface()
	f.variation_opentype = {ts.name_to_tag("wght"): weight}
	return f


func _build_fonts() -> void:
	font_body = _var_font("res://assets/fonts/Nunito-Variable.ttf", 700)
	font_bold = _var_font("res://assets/fonts/Nunito-Variable.ttf", 900)
	font_display = _var_font("res://assets/fonts/Exo2-Variable.ttf", 800)
	font_display_italic = _var_font("res://assets/fonts/Exo2-Italic-Variable.ttf", 900)


# ------------------------------------------------------------------ theme
func flat(bg: Color, radius := 18, border := Color.TRANSPARENT, bw := 0, bottom := 0, shadow := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.corner_detail = 6
	if bw > 0:
		s.border_color = border
		s.set_border_width_all(bw)
	if bottom > 0:
		s.border_color = border if bw > 0 else bg.darkened(0.35)
		s.border_width_bottom = bottom
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, shadow * 0.4)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.anti_aliasing = true
	return s


func _btn_variant(t: Theme, name: String, base: Color, dark: Color, fg := TEXT) -> void:
	if name != "Button":
		t.set_type_variation(name, "Button")
	var n := flat(base, 18, dark, 0, 6, 6)
	n.border_color = dark
	var h := flat(base.lightened(0.1), 18, dark, 0, 6, 8)
	h.border_color = dark
	var p := flat(base.darkened(0.06), 18, dark, 0, 2, 2)
	p.border_color = dark
	p.content_margin_top = 14
	var d := flat(Color(base, 0.35).darkened(0.4), 18, dark, 0, 4, 0)
	d.border_color = Color(dark, 0.4)
	var f := flat(Color.TRANSPARENT, 18, Color(1, 1, 1, 0.75), 3)
	t.set_stylebox("normal", name, n)
	t.set_stylebox("hover", name, h)
	t.set_stylebox("pressed", name, p)
	t.set_stylebox("hover_pressed", name, p)
	t.set_stylebox("disabled", name, d)
	t.set_stylebox("focus", name, f)
	t.set_color("font_color", name, fg)
	t.set_color("font_hover_color", name, fg)
	t.set_color("font_pressed_color", name, fg)
	t.set_color("font_hover_pressed_color", name, fg)
	t.set_color("font_focus_color", name, fg)
	t.set_color("font_disabled_color", name, Color(fg, 0.45))
	# Icons keep their own colours (coins, gems are full-colour artwork).
	t.set_color("icon_normal_color", name, Color.WHITE)
	t.set_color("icon_hover_color", name, Color.WHITE)
	t.set_color("icon_pressed_color", name, Color.WHITE)
	t.set_color("icon_disabled_color", name, Color(1, 1, 1, 0.45))
	t.set_font("font", name, font_display)
	t.set_font_size("font_size", name, 26)
	t.set_constant("outline_size", name, 0)
	t.set_constant("h_separation", name, 10)


func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font_body
	t.default_font_size = 22
	# Label
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0))
	# Default button = secondary
	_btn_variant(t, "Button", CARD_HI, STROKE.darkened(0.2))
	_btn_variant(t, "BtnPrimary", GREEN, GREEN_D, Color("06281a"))
	_btn_variant(t, "BtnAccent", ORANGE, ORANGE_D, Color.WHITE)
	_btn_variant(t, "BtnBlue", BLUE, BLUE_D, Color.WHITE)
	_btn_variant(t, "BtnDanger", RED, RED_D, Color.WHITE)
	_btn_variant(t, "BtnGold", GOLD, Color("c8961a"), Color("3a2a00"))
	_btn_variant(t, "BtnSecondary", CARD_HI, Color("16243f"))
	# Ghost: transparent with outline
	t.set_type_variation("BtnGhost", "Button")
	var gn := flat(Color(1, 1, 1, 0.04), 16, Color(1, 1, 1, 0.18), 2)
	var gh := flat(Color(1, 1, 1, 0.1), 16, Color(1, 1, 1, 0.3), 2)
	var gp := flat(Color(1, 1, 1, 0.16), 16, Color(1, 1, 1, 0.35), 2)
	for st in [["normal", gn], ["hover", gh], ["pressed", gp], ["hover_pressed", gp], ["disabled", gn], ["focus", StyleBoxEmpty.new()]]:
		t.set_stylebox(st[0], "BtnGhost", st[1])
	t.set_font("font", "BtnGhost", font_display)
	t.set_font_size("font_size", "BtnGhost", 22)
	t.set_color("font_color", "BtnGhost", TEXT)
	t.set_color("font_disabled_color", "BtnGhost", TEXT_MUTED)
	# Chip / tab toggles
	t.set_type_variation("BtnChip", "Button")
	var cn := flat(Color(1, 1, 1, 0.05), 22, Color(1, 1, 1, 0.12), 2)
	cn.content_margin_left = 16
	cn.content_margin_right = 16
	cn.content_margin_top = 6
	cn.content_margin_bottom = 6
	var cp := flat(BLUE, 22, BLUE.lightened(0.2), 2)
	cp.content_margin_left = 16
	cp.content_margin_right = 16
	cp.content_margin_top = 6
	cp.content_margin_bottom = 6
	var ch := cn.duplicate()
	ch.bg_color = Color(1, 1, 1, 0.1)
	for st in [["normal", cn], ["hover", ch], ["pressed", cp], ["hover_pressed", cp], ["disabled", cn], ["focus", StyleBoxEmpty.new()]]:
		t.set_stylebox(st[0], "BtnChip", st[1])
	t.set_font("font", "BtnChip", font_bold)
	t.set_font_size("font_size", "BtnChip", 18)
	t.set_color("font_color", "BtnChip", TEXT_DIM)
	t.set_color("font_hover_color", "BtnChip", TEXT)
	t.set_color("font_pressed_color", "BtnChip", Color.WHITE)
	t.set_color("font_hover_pressed_color", "BtnChip", Color.WHITE)
	# Panels
	t.set_stylebox("panel", "Panel", flat(PANEL, 22, STROKE, 2))
	t.set_stylebox("panel", "PanelContainer", flat(PANEL, 22, STROKE, 2))
	t.set_type_variation("PanelCard", "PanelContainer")
	t.set_stylebox("panel", "PanelCard", flat(CARD, 20, STROKE, 2, 0, 6))
	t.set_type_variation("PanelGlass", "PanelContainer")
	t.set_stylebox("panel", "PanelGlass", flat(Color(0.05, 0.08, 0.15, 0.72), 22, Color(1, 1, 1, 0.08), 2))
	t.set_type_variation("PanelFlat", "PanelContainer")
	t.set_stylebox("panel", "PanelFlat", flat(Color(1, 1, 1, 0.04), 16))
	t.set_type_variation("PanelDialog", "PanelContainer")
	var dl := flat(PANEL, 28, STROKE.lightened(0.15), 2, 0, 24)
	dl.content_margin_left = 34
	dl.content_margin_right = 34
	dl.content_margin_top = 28
	dl.content_margin_bottom = 28
	t.set_stylebox("panel", "PanelDialog", dl)
	# Progress bar
	var pb_bg := flat(Color(0, 0, 0, 0.35), 10)
	pb_bg.content_margin_top = 0
	pb_bg.content_margin_bottom = 0
	var pb_fg := flat(GREEN, 10)
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill", "ProgressBar", pb_fg)
	t.set_font_size("font_size", "ProgressBar", 14)
	t.set_color("font_color", "ProgressBar", TEXT)
	# Slider
	var sl := flat(Color(0, 0, 0, 0.4), 8)
	sl.content_margin_top = 6
	sl.content_margin_bottom = 6
	t.set_stylebox("slider", "HSlider", sl)
	var sla := flat(BLUE, 8)
	sla.content_margin_top = 6
	sla.content_margin_bottom = 6
	t.set_stylebox("grabber_area", "HSlider", sla)
	t.set_stylebox("grabber_area_highlight", "HSlider", sla)
	t.set_icon("grabber", "HSlider", _circle_tex(26, Color.WHITE))
	t.set_icon("grabber_highlight", "HSlider", _circle_tex(28, Color.WHITE))
	# Scroll bars (thin)
	var sb := flat(Color(1, 1, 1, 0.05), 6)
	sb.content_margin_left = 3
	sb.content_margin_right = 3
	var gr := flat(Color(1, 1, 1, 0.25), 6)
	for sbt in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", sbt, sb)
		t.set_stylebox("grabber", sbt, gr)
		t.set_stylebox("grabber_highlight", sbt, gr)
		t.set_stylebox("grabber_pressed", sbt, gr)
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	# Labels variants
	t.set_type_variation("Title", "Label")
	t.set_font("font", "Title", font_display_italic)
	t.set_font_size("font_size", "Title", 40)
	t.set_type_variation("Heading", "Label")
	t.set_font("font", "Heading", font_display)
	t.set_font_size("font_size", "Heading", 28)
	t.set_type_variation("Dim", "Label")
	t.set_color("font_color", "Dim", TEXT_DIM)
	t.set_font_size("font_size", "Dim", 19)
	t.set_type_variation("Small", "Label")
	t.set_color("font_color", "Small", TEXT_DIM)
	t.set_font_size("font_size", "Small", 16)
	t.set_type_variation("Number", "Label")
	t.set_font("font", "Number", font_display)
	t.set_font_size("font_size", "Number", 24)
	t.set_type_variation("HudNumber", "Label")
	t.set_font("font", "HudNumber", font_display)
	t.set_font_size("font_size", "HudNumber", 28)
	t.set_color("font_outline_color", "HudNumber", Color(0, 0, 0, 0.55))
	t.set_constant("outline_size", "HudNumber", 6)
	# Tooltip
	t.set_stylebox("panel", "TooltipPanel", flat(Color(0.05, 0.08, 0.15, 0.95), 10))
	return t


func _circle_tex(size: int, c: Color) -> Texture2D:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var r := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			var a := clampf(r - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(c, a))
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ icons
func icon(icon_name: String) -> Texture2D:
	if _icons.has(icon_name):
		return _icons[icon_name]
	var path := "res://assets/icons/%s.svg" % icon_name
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_icons[icon_name] = tex
	return tex


func rarity_color(r: String) -> Color:
	return K.RARITY_COLORS.get(r, TEXT_DIM)


# ------------------------------------------------------------------ transitions
func fade_out(time := 0.18) -> void:
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, time)
	await tw.finished


func fade_in(time := 0.22) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, time)
	await tw.finished
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE


func go(screen: String, params := {}) -> void:
	if router:
		router.go(screen, params)


# ------------------------------------------------------------------ toasts
func toast(text: String, kind := "info") -> void:
	var p := PanelContainer.new()
	var col: Color = {"info": BLUE, "good": GREEN, "bad": RED, "gold": GOLD}.get(kind, BLUE)
	var sb := flat(Color(0.06, 0.1, 0.19, 0.95), 18, col, 2, 0, 10)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", font_bold)
	l.add_theme_font_size_override("font_size", 21)
	p.add_child(l)
	_toast_box.add_child(p)
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.18)
	tw.tween_interval(2.2)
	tw.tween_property(p, "modulate:a", 0.0, 0.3)
	tw.tween_callback(p.queue_free)


# ------------------------------------------------------------------ dialogs
## Modal confirm dialog. Returns the dialog node; callbacks fire on choice.
func confirm(title: String, body: String, ok_text: String, on_ok: Callable, ok_variant := "BtnPrimary", cancel_text := "", extra: Control = null) -> UIDialog:
	var d := UIDialog.new()
	_overlay.add_child(d)
	d.setup(title, body, ok_text, cancel_text if cancel_text != "" else Loc.t("btn_cancel"), ok_variant, extra)
	d.accepted.connect(on_ok)
	return d


func alert(title: String, body: String, extra: Control = null) -> UIDialog:
	var d := UIDialog.new()
	_overlay.add_child(d)
	d.setup(title, body, Loc.t("btn_ok"), "", "BtnPrimary", extra)
	return d


func has_dialog() -> bool:
	for c in _overlay.get_children():
		if c is UIDialog and not c.is_queued_for_deletion():
			return true
	return false


func close_top_dialog() -> bool:
	for i in range(_overlay.get_child_count() - 1, -1, -1):
		var c := _overlay.get_child(i)
		if c is UIDialog and not c.is_queued_for_deletion():
			c.cancel()
			return true
	return false


func close_all_dialogs() -> void:
	for c in _overlay.get_children():
		if c is UIDialog:
			c.queue_free()


func overlay_layer() -> CanvasLayer:
	return _overlay


## Safe-area margins (notches / rounded corners) in viewport units.
func safe_margins() -> Dictionary:
	var vp := get_tree().root
	var win := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	var vs := vp.get_visible_rect().size
	if win.x <= 0 or safe.size.x <= 0 or not OS.has_feature("mobile"):
		return {"left": 0.0, "right": 0.0, "top": 0.0, "bottom": 0.0}
	var sx := vs.x / win.x
	var sy := vs.y / win.y
	return {
		"left": maxf(safe.position.x * sx, 0.0),
		"top": maxf(safe.position.y * sy, 0.0),
		"right": maxf((win.x - safe.end.x) * sx, 0.0),
		"bottom": maxf((win.y - safe.end.y) * sy, 0.0),
	}
