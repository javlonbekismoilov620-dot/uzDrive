## Grid card for a vehicle (garage / shop).
class_name VehicleCard
extends Button

signal chosen(vid: String)

var vid := ""
var vdef: Dictionary
var selected := false:
	set(v):
		selected = v
		queue_redraw()
var _preview: VehiclePreview
var _name: Label
var _sub: Label
var _status: HBoxContainer


func setup(id: String) -> void:
	vid = id
	vdef = DB.vehicle(id)
	custom_minimum_size = Vector2(236, 176)
	focus_mode = Control.FOCUS_NONE
	flat = true
	clip_contents = true
	_preview = VehiclePreview.new()
	_preview.animated = false
	_preview.show_platform = false
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.position = Vector2(8, 22)
	_preview.size = Vector2(220, 98)
	add_child(_preview)
	_preview.set_vehicle(vdef)
	_name = Label.new()
	_name.add_theme_font_override("font", UI.font_display)
	_name.add_theme_font_size_override("font_size", 20)
	_name.position = Vector2(14, 116)
	_name.size = Vector2(210, 26)
	_name.clip_text = true
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name)
	_status = HBoxContainer.new()
	_status.position = Vector2(14, 142)
	_status.size = Vector2(210, 26)
	_status.add_theme_constant_override("separation", 6)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_status)
	pressed.connect(func():
		Audio.sfx("click")
		chosen.emit(vid))
	refresh()


func refresh() -> void:
	_name.text = DB.vehicle_display_name(vdef)
	for c in _status.get_children():
		c.queue_free()
	var owned := Profile.owns(vid)
	if owned:
		var l := Label.new()
		var equipped := Profile.selected_vehicle() == vid
		l.text = Loc.t("tag_equipped") if equipped else Loc.t("tag_owned")
		l.add_theme_color_override("font_color", UI.GREEN if equipped else UI.TEXT_DIM)
		l.add_theme_font_override("font", UI.font_bold)
		l.add_theme_font_size_override("font_size", 16)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_status.add_child(l)
	else:
		var cur: String = vdef.get("currency", "coins")
		var ic := TextureRect.new()
		ic.texture = UI.icon("coin" if cur == "coins" else "gem")
		ic.custom_minimum_size = Vector2(22, 22)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_status.add_child(ic)
		var l2 := Label.new()
		l2.text = Loc.num(int(vdef.price))
		var afford := Economy.can_afford(int(vdef.price), cur)
		l2.add_theme_color_override("font_color", UI.GOLD if afford else UI.TEXT_MUTED)
		l2.add_theme_font_override("font", UI.font_display)
		l2.add_theme_font_size_override("font_size", 17)
		l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_status.add_child(l2)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var rc := UI.rarity_color(vdef.get("rarity", "common"))
	var bg := UI.CARD if not selected else UI.CARD_HI
	draw_style_box(UI.flat(bg, 18, rc if selected else Color(1, 1, 1, 0.07), 3 if selected else 2), r)
	# rarity glow at top
	var glow := UI.flat(Color(rc, 0.16), 18)
	glow.corner_radius_bottom_left = 0
	glow.corner_radius_bottom_right = 0
	draw_style_box(glow, Rect2(3, 3, size.x - 6, 92))
	draw_rect(Rect2(14, 12, 64, 5), rc)
	draw_string(UI.font_bold, Vector2(84, 19), Loc.t("rarity_" + vdef.get("rarity", "common")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, rc)
	if not Profile.owns(vid):
		var lk := UI.icon("lock")
		if lk:
			draw_texture_rect(lk, Rect2(size.x - 38, 8, 26, 26), false, Color(1, 1, 1, 0.75))
