## Base for menu screens: background, header (back, title, currencies),
## Android back handling and live language refresh.
class_name ScreenBase
extends Control

var params: Dictionary = {}
var header: HBoxContainer
var title_label: Label
var body: Control
var back_target := "main_menu"
var show_back := true
var show_currencies := true
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sm := UI.safe_margins()
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 28 + int(sm.left))
	root.add_theme_constant_override("margin_right", 28 + int(sm.right))
	root.add_theme_constant_override("margin_top", 18 + int(sm.top))
	root.add_theme_constant_override("margin_bottom", 18 + int(sm.bottom))
	add_child(root)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	root.add_child(v)
	header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	header.custom_minimum_size = Vector2(0, 64)
	v.add_child(header)
	if show_back:
		var b := UIButton.make("", "BtnSecondary", "back", Vector2(64, 64))
		b.add_theme_constant_override("icon_max_width", 28)
		b.pressed.connect(on_back)
		header.add_child(b)
	title_label = Label.new()
	title_label.theme_type_variation = "Title"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title_label)
	if show_currencies:
		header.add_child(CurrencyChip.make("coins"))
		header.add_child(CurrencyChip.make("gems"))
	body = Control.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(body)
	build()
	refresh_texts()
	Events.language_changed.connect(func(_l): refresh_texts())


## Override: create the screen content inside `body`.
func build() -> void:
	pass


## Override: (re)apply translated strings.
func refresh_texts() -> void:
	pass


func on_back() -> void:
	if UI.close_top_dialog():
		return
	UI.go(back_target)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		on_back()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel") or (e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE):
		on_back()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_t += delta


func _draw() -> void:
	var r := get_rect()
	var top := UI.BG
	var bot := UI.BG_DEEP
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(r.size.x, 0), Vector2(r.size.x, r.size.y), Vector2(0, r.size.y)])
	draw_polygon(pts, PackedColorArray([top.lightened(0.04), top, bot, bot]))
	# subtle diagonal speed stripes
	var c := Color(1, 1, 1, 0.025)
	var x := -r.size.y
	while x < r.size.x:
		draw_colored_polygon(PackedVector2Array([Vector2(x, r.size.y), Vector2(x + 60, r.size.y), Vector2(x + 60 + r.size.y * 0.6, 0), Vector2(x + r.size.y * 0.6, 0)]), c)
		x += 220
	# glow
	for i in 5:
		var rr := 380.0 - i * 60
		draw_circle(Vector2(r.size.x * 0.82, r.size.y * 0.1), rr, Color(0.24, 0.45, 1.0, 0.025))


## Helper: section heading label.
static func heading(txt: String) -> Label:
	var l := Label.new()
	l.theme_type_variation = "Heading"
	l.text = txt
	return l


static func icon_rect(name: String, sz := 32, tint := Color.WHITE) -> TextureRect:
	var t := TextureRect.new()
	t.texture = UI.icon(name)
	t.custom_minimum_size = Vector2(sz, sz)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.modulate = tint
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t
