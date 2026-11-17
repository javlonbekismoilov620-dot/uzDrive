## Boost button: energy ring, cooldown sweep and active glow.
class_name BoostButton
extends TouchButton

var energy := 0.0     ## 0..max
var max_energy := 100.0
var cost := 50.0
var cooldown := 0.0   ## 0..1 remaining fraction
var active := 0.0     ## 0..1 remaining fraction
var _t := 0.0


func ready_to_fire() -> bool:
	return energy >= cost and cooldown <= 0.0 and active <= 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var rad := minf(size.x, size.y) * 0.5 - 6
	var ok := ready_to_fire()
	var base := Color("2f6bff") if ok or active > 0.0 else Color("2a3446")
	if active > 0.0:
		for i in 4:
			draw_circle(c, rad + 6 + i * 5 + sin(_t * 18.0) * 2, Color(1.0, 0.6, 0.2, 0.12))
	elif ok:
		draw_circle(c, rad + 6 + sin(_t * 5.0) * 3, Color(0.3, 0.55, 1.0, 0.2))
	draw_circle(c + Vector2(0, 5), rad, Color(0, 0, 0, 0.35))
	draw_circle(c, rad, base.darkened(0.25 if is_down else 0.0))
	draw_arc(c, rad - 4, 0, TAU, 48, Color(0, 0, 0, 0.35), 8)
	var frac := clampf(energy / max_energy, 0.0, 1.0)
	draw_arc(c, rad - 4, -PI * 0.5, -PI * 0.5 + TAU * frac, 48, Color("fff36b"), 8, true)
	# cost tick
	var ta := -PI * 0.5 + TAU * (cost / max_energy)
	draw_line(c + Vector2(cos(ta), sin(ta)) * (rad - 10), c + Vector2(cos(ta), sin(ta)) * (rad + 2), Color.WHITE, 3)
	var s := rad * 0.55
	var bolt := PackedVector2Array([c + Vector2(s * 0.15, -s), c + Vector2(-s * 0.55, s * 0.15), c + Vector2(-s * 0.05, s * 0.15), c + Vector2(-s * 0.25, s), c + Vector2(s * 0.55, -s * 0.2), c + Vector2(s * 0.05, -s * 0.2)])
	draw_colored_polygon(bolt, Color("fff36b") if ok or active > 0.0 else Color(1, 1, 1, 0.35))
	if cooldown > 0.0:
		draw_arc(c, rad * 0.5, -PI * 0.5, -PI * 0.5 + TAU * cooldown, 32, Color(1, 1, 1, 0.5), rad, false)
