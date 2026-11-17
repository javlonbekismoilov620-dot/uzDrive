## End-of-run results: reason, distance, payout breakdown, optional revive.
class_name ResultsPanel
extends CanvasLayer

var game: GameScreen
var _root: Control
var _content: VBoxContainer


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.09, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var card := PanelContainer.new()
	card.theme_type_variation = "PanelDialog"
	card.custom_minimum_size = Vector2(640, 0)
	center.add_child(card)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	card.add_child(_content)


func show_results(s: Dictionary, payout: Dictionary, new_best: bool, can_revive: bool, revive_cost: int) -> void:
	for c in _content.get_children():
		c.queue_free()
	var reason: String = s.get("reason", "fuel")
	var title := Label.new()
	title.theme_type_variation = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = Loc.t("end_fuel") if reason == "fuel" else Loc.t("end_crash")
	title.add_theme_color_override("font_color", UI.RED if reason != "fuel" else UI.ORANGE)
	_content.add_child(title)
	var dist := Label.new()
	dist.add_theme_font_override("font", UI.font_display_italic)
	dist.add_theme_font_size_override("font_size", 58)
	dist.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dist.text = Loc.meters(float(s.distance))
	_content.add_child(dist)
	if new_best:
		var nb := Label.new()
		nb.text = Loc.t("res_new_best")
		nb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nb.add_theme_color_override("font_color", UI.GOLD)
		nb.add_theme_font_override("font", UI.font_display)
		nb.add_theme_font_size_override("font_size", 24)
		_content.add_child(nb)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 4)
	var rows := [
		[Loc.t("res_coins"), payout.collected],
		[Loc.t("res_distance_bonus"), payout.distance_bonus],
		[Loc.t("res_checkpoint_bonus"), payout.checkpoint_bonus],
		[Loc.t("res_trick_bonus"), payout.trick_bonus],
	]
	for r in rows:
		var l := Label.new()
		l.text = r[0]
		l.theme_type_variation = "Dim"
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(l)
		var n := Label.new()
		n.text = "+" + Loc.num(int(r[1]))
		n.theme_type_variation = "Number"
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(n)
	var gc := CenterContainer.new()
	gc.add_child(grid)
	grid.custom_minimum_size = Vector2(460, 0)
	_content.add_child(gc)
	var total := HBoxContainer.new()
	total.alignment = BoxContainer.ALIGNMENT_CENTER
	total.add_theme_constant_override("separation", 10)
	total.add_child(ScreenBase.icon_rect("coin", 44))
	var tl := Label.new()
	tl.add_theme_font_override("font", UI.font_display)
	tl.add_theme_font_size_override("font_size", 44)
	tl.add_theme_color_override("font_color", UI.GOLD)
	total.add_child(tl)
	if int(payout.gems) > 0:
		total.add_child(ScreenBase.icon_rect("gem", 38))
		var gl := Label.new()
		gl.text = "+%d" % int(payout.gems)
		gl.add_theme_font_override("font", UI.font_display)
		gl.add_theme_font_size_override("font_size", 36)
		gl.add_theme_color_override("font_color", UI.GEM)
		total.add_child(gl)
	_content.add_child(total)
	var tw := create_tween()
	tw.tween_method(func(v: float): tl.text = "+" + Loc.num(int(v)), 0.0, float(payout.total), 0.9).set_delay(0.25)
	if can_revive:
		var rv := UIButton.make(Loc.t("btn_revive", revive_cost), "BtnBlue", "gem", Vector2(0, 62))
		rv.disabled = not Economy.can_afford(revive_cost, "gems")
		rv.pressed.connect(func():
			UI.confirm(Loc.t("revive_title"), Loc.t("revive_body", revive_cost), Loc.t("btn_confirm"), func():
				if game.revive():
					close()
				else:
					UI.toast(Loc.t("toast_not_enough_gems"), "bad")
			, "BtnBlue"))
		_content.add_child(rv)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_content.add_child(row)
	var restart := UIButton.make(Loc.t("btn_restart"), "BtnPrimary", "restart", Vector2(0, 66))
	restart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart.pressed.connect(func(): game.restart())
	row.add_child(restart)
	var garage := UIButton.make(Loc.t("btn_garage"), "BtnSecondary", "garage", Vector2(0, 66))
	garage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	garage.pressed.connect(func(): game.exit_to("garage"))
	row.add_child(garage)
	var maps := UIButton.make(Loc.t("btn_maps"), "BtnSecondary", "map", Vector2(0, 66))
	maps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	maps.pressed.connect(func(): game.exit_to("maps"))
	row.add_child(maps)
	visible = true
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.25)


func close() -> void:
	visible = false
