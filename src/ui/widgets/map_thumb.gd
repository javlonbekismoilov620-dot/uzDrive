## Static miniature of an environment (sky, scenery layers, ground strip).
class_name MapThumb
extends Control

var env: Dictionary
var dim := false


func _draw() -> void:
	if env.is_empty():
		return
	var vis: Dictionary = env.get("visual", {})
	var r := Rect2(Vector2.ZERO, size)
	var sky: Array = vis.get("sky", ["#5fb8f0", "#d7f1ff"])
	var top := Util.col(sky[0])
	var bot := Util.col(sky[1])
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(r.size.x, 0), r.size, Vector2(0, r.size.y)]), PackedColorArray([top, top, bot, bot]))
	for key in ["sun", "moon"]:
		if vis.has(key):
			var b: Dictionary = vis[key]
			draw_circle(Vector2(float(b.x) * r.size.x, float(b.y) * r.size.y * 1.4), float(b.r) * 0.45, Util.col(b.color))
	var layers: Array = vis.get("layers", [])
	for li in layers.size():
		var spec: Dictionary = layers[li]
		var col := Util.col(spec.get("color", "#88aa77"))
		var base_y := r.size.y * (0.45 + 0.12 * li)
		var h := r.size.y * (0.32 - 0.06 * li)
		var rng := RandomNumberGenerator.new()
		rng.seed = int(spec.get("seed", 1))
		var pts := PackedVector2Array()
		var n := 24
		var ph := [rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU]
		for k in n + 1:
			var x := r.size.x * k / n
			var t := float(k) / n
			var y := sin(t * TAU + ph[0]) * 0.5 + sin(t * TAU * 2.0 + ph[1]) * 0.3 + sin(t * TAU * 5.0 + ph[2]) * 0.2
			if spec.get("kind", "") in ["mountains", "rocks"]:
				y = 1.0 - absf(y) * 1.6
			if spec.get("kind", "") == "city":
				y = rng.randf_range(-0.2, 1.0)
				pts.append(Vector2(x, base_y - (y * 0.5 + 0.5) * h))
				pts.append(Vector2(minf(x + r.size.x / n, r.size.x), base_y - (y * 0.5 + 0.5) * h))
				continue
			pts.append(Vector2(x, base_y - (y * 0.5 + 0.5) * h))
		pts.append(Vector2(r.size.x, r.size.y))
		pts.append(Vector2(0, r.size.y))
		draw_colored_polygon(pts, col)
	var gy := r.size.y * 0.82
	var ground := PackedVector2Array()
	for k in 13:
		ground.append(Vector2(r.size.x * k / 12.0, gy + sin(k * 0.9) * 6.0))
	var gpoly := ground.duplicate()
	gpoly.append(Vector2(r.size.x, r.size.y))
	gpoly.append(Vector2(0, r.size.y))
	draw_colored_polygon(gpoly, Util.col(vis.get("ground", "#7b5a3c")))
	draw_polyline(ground, Util.col(vis.get("top", "#62b94a")), 7.0)
	if env.get("night", false):
		draw_rect(r, Color(0.05, 0.07, 0.2, 0.25))
	if dim:
		draw_rect(r, Color(0.02, 0.04, 0.1, 0.55))
		var lk := UI.icon("lock")
		if lk:
			draw_texture_rect(lk, Rect2(r.get_center() - Vector2(28, 28), Vector2(56, 56)), false, Color(1, 1, 1, 0.9))
