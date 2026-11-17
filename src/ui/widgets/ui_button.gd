## Game button: theme variant + optional icon + press/hover animation + click SFX.
class_name UIButton
extends Button

var sfx_name := "click"
var _tw: Tween


static func make(txt: String, variant := "BtnSecondary", icon_name := "", min_size := Vector2(0, 64)) -> UIButton:
	var b := UIButton.new()
	b.text = txt
	b.theme_type_variation = variant
	if icon_name != "":
		b.icon = UI.icon(icon_name)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 34)
	b.custom_minimum_size = min_size
	return b


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	pivot_offset = size * 0.5
	resized.connect(func(): pivot_offset = size * 0.5)
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	pressed.connect(func():
		if sfx_name != "":
			Audio.sfx(sfx_name))


func _on_down() -> void:
	if disabled:
		return
	_anim(Vector2(0.95, 0.95), 0.06)


func _on_up() -> void:
	_anim(Vector2.ONE, 0.12)


func _anim(target: Vector2, t: float) -> void:
	if _tw and _tw.is_valid():
		_tw.kill()
	_tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tw.tween_property(self, "scale", target, t)


## Gentle attention pulse (e.g. a claimable reward).
func pulse(on := true) -> void:
	if not on:
		scale = Vector2.ONE
		return
	var tw := create_tween().set_loops()
	tw.tween_property(self, "scale", Vector2(1.04, 1.04), 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_SINE)
