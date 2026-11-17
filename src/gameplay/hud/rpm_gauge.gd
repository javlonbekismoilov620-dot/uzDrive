## Semi-circular tachometer with gear indicator and speed readout.
class_name RpmGauge
extends Control

var rpm := 0.0
var gear := 1
var speed_kmh := 0.0
var _needle := 0.0


func _process(delta: float) -> void:
	_needle = lerpf(_needle, rpm, 1.0 - exp(-delta * 14.0))
	queue_redraw()


func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y - 14)
	var r := minf(size.x * 0.5, size.y) - 10
	draw_circle(c, r + 6, Color(0.03, 0.05, 0.1, 0.72))
	var a0 := PI
	var a1 := TAU
	draw_arc(c, r - 6, a0, a1, 48, Color(1, 1, 1, 0.12), 10)
	# red zone
	draw_arc(c, r - 6, lerpf(a0, a1, 0.82), a1, 16, Color("ff4d5a"), 10)
	# active arc
	var col := Color("2bd576").lerp(Color("ffc93c"), clampf((_needle - 0.5) * 2.5, 0.0, 1.0))
	if _needle > 0.82:
		col = Color("ff4d5a")
	draw_arc(c, r - 6, a0, lerpf(a0, a1, clampf(_needle, 0.0, 1.0)), 48, col, 10, true)
	for i in 9:
		var a := lerpf(a0, a1, i / 8.0)
		var d := Vector2(cos(a), sin(a))
		draw_line(c + d * (r - 20), c + d * (r - 14), Color(1, 1, 1, 0.5), 2)
	var na := lerpf(a0, a1, clampf(_needle, 0.0, 1.05))
	draw_line(c, c + Vector2(cos(na), sin(na)) * (r - 18), Color("ff8a1f"), 4, true)
	draw_circle(c, 8, Color("ff8a1f"))
	draw_string(UI.font_display, Vector2(c.x - 40, c.y - r * 0.32), str(gear), HORIZONTAL_ALIGNMENT_CENTER, 80, 30, Color.WHITE)
	draw_string(UI.font_bold, Vector2(c.x - 60, c.y - 2), "%d %s" % [int(speed_kmh), Loc.t("unit_kmh")], HORIZONTAL_ALIGNMENT_CENTER, 120, 15, UI.TEXT_DIM)
