## Gas / brake pedal drawn as a chunky metal pedal with grip grooves.
class_name Pedal
extends TouchButton

var kind := "gas"
var _press := 0.0


func _process(delta: float) -> void:
	var target := 1.0 if is_down else 0.0
	if absf(_press - target) > 0.001:
		_press = move_toward(_press, target, delta * 10.0)
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var sq := 1.0 - 0.06 * _press
	var w := r.size.x * sq
	var h := r.size.y * sq
	var rect := Rect2((r.size.x - w) * 0.5, (r.size.y - h) * 0.5 + 6 * _press, w, h)
	var base := Color("2bd576") if kind == "gas" else Color("ff4d5a")
	var face := Color("2a3446").lerp(base.darkened(0.2), 0.25 + 0.55 * _press)
	# drop shadow
	draw_style_box(UI.flat(Color(0, 0, 0, 0.35), 26), Rect2(rect.position + Vector2(0, 8), rect.size))
	draw_style_box(UI.flat(face, 26, base, 4), rect)
	# grooves
	var n := 5 if kind == "gas" else 3
	for i in n:
		if kind == "gas":
			var x := rect.position.x + rect.size.x * (0.22 + 0.56 * i / (n - 1))
			draw_line(Vector2(x, rect.position.y + rect.size.y * 0.16), Vector2(x, rect.position.y + rect.size.y * 0.66), Color(1, 1, 1, 0.18 + 0.2 * _press), 7.0, true)
		else:
			var y := rect.position.y + rect.size.y * (0.18 + 0.24 * i)
			draw_line(Vector2(rect.position.x + rect.size.x * 0.18, y), Vector2(rect.end.x - rect.size.x * 0.18, y), Color(1, 1, 1, 0.18 + 0.2 * _press), 8.0, true)
	var label := Loc.t("hud_gas") if kind == "gas" else Loc.t("hud_brake")
	draw_string(UI.font_display, Vector2(rect.position.x, rect.end.y - 18), label.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 22, Color(1, 1, 1, 0.9))
