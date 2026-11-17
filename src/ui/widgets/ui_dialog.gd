## Modal dialog with dimmed backdrop. Used for every purchase confirmation so
## nothing can be bought by an accidental tap.
class_name UIDialog
extends Control

signal accepted
signal cancelled

var _card: PanelContainer
var _ok: UIButton
var _closing := false


func setup(title: String, body: String, ok_text: String, cancel_text: String, ok_variant: String, extra: Control) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.09, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and cancel_text != "":
			cancel())
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_card = PanelContainer.new()
	_card.theme_type_variation = "PanelDialog"
	_card.custom_minimum_size = Vector2(560, 0)
	center.add_child(_card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	_card.add_child(v)
	var t := Label.new()
	t.theme_type_variation = "Heading"
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	if body != "":
		var b := Label.new()
		b.theme_type_variation = "Dim"
		b.text = body
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(480, 0)
		v.add_child(b)
	if extra:
		v.add_child(extra)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	if cancel_text != "":
		var c := UIButton.make(cancel_text, "BtnSecondary", "", Vector2(200, 64))
		c.pressed.connect(cancel)
		row.add_child(c)
	_ok = UIButton.make(ok_text, ok_variant, "", Vector2(220, 64))
	_ok.pressed.connect(_accept)
	row.add_child(_ok)
	_card.pivot_offset = Vector2(280, 120)
	_card.scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.15)
	tw.tween_property(_card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().process_frame
	_card.pivot_offset = _card.size * 0.5


func _accept() -> void:
	if _closing:
		return
	_close()
	accepted.emit()


func cancel() -> void:
	if _closing:
		return
	_close()
	cancelled.emit()


func _close() -> void:
	_closing = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.tween_callback(queue_free)
