## Fuel (or battery) bar with low-fuel warning blink.
class_name FuelGauge
extends Control

var fuel := 1.0
var electric := false
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_style_box(UI.flat(Color(0.03, 0.06, 0.12, 0.72), 18, Color(1, 1, 1, 0.08), 2), r)
	var ic := UI.icon("fuel")
	if ic:
		draw_texture_rect(ic, Rect2(8, (size.y - 40) * 0.5, 40, 40), false)
	var bar := Rect2(56, size.y * 0.5 - 10, size.x - 70, 20)
	draw_style_box(UI.flat(Color(0, 0, 0, 0.45), 10), bar)
	var f := clampf(fuel, 0.0, 1.0)
	var col := Color("2bd576")
	if f < 0.5:
		col = Color("ffc93c")
	if f < 0.22:
		col = Color("ff4d5a")
		if fmod(_t, 0.6) < 0.3:
			col = col.lightened(0.35)
	if f > 0.005:
		draw_style_box(UI.flat(col, 10), Rect2(bar.position, Vector2(maxf(bar.size.x * f, 20), bar.size.y)))
	for i in range(1, 4):
		var x := bar.position.x + bar.size.x * i / 4.0
		draw_line(Vector2(x, bar.position.y + 3), Vector2(x, bar.end.y - 3), Color(0, 0, 0, 0.35), 2)
