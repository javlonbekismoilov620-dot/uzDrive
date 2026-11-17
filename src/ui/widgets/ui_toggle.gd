## Pill on/off switch.
class_name UIToggle
extends Button

var _knob := 0.0


func _init() -> void:
	toggle_mode = true
	flat = true
	custom_minimum_size = Vector2(84, 44)
	focus_mode = Control.FOCUS_NONE
	toggled.connect(func(on: bool):
		Audio.sfx("click")
		var tw := create_tween()
		tw.tween_method(func(v: float):
			_knob = v
			queue_redraw(), _knob, 1.0 if on else 0.0, 0.14))


func set_on(on: bool) -> void:
	set_pressed_no_signal(on)
	_knob = 1.0 if on else 0.0
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, custom_minimum_size)
	var bg := UI.STROKE.lerp(UI.GREEN, _knob)
	var sb := UI.flat(bg, int(r.size.y * 0.5))
	draw_style_box(sb, r)
	var kx := lerpf(r.size.y * 0.5, r.size.x - r.size.y * 0.5, _knob)
	draw_circle(Vector2(kx, r.size.y * 0.5), r.size.y * 0.5 - 5, Color.WHITE)
