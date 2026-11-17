## Vector drawing routines for scenery props (trees, rocks, lamps, ...).
## All props are original flat-style artwork drawn at runtime.
class_name DecorPainter
extends RefCounted

const P := K.PPM


static func draw(ci: CanvasItem, kind: String, pos: Vector2, s: float, rng: RandomNumberGenerator, tint: Color) -> void:
	match kind:
		"tree_round":
			_tree_round(ci, pos, s, rng, tint)
		"poplar":
			_poplar(ci, pos, s, tint)
		"pine":
			_pine(ci, pos, s, tint, false)
		"pine_snow":
			_pine(ci, pos, s, tint, true)
		"bush":
			_bush(ci, pos, s, tint)
		"grass":
			_grass(ci, pos, s, tint, rng)
		"flowers":
			_flowers(ci, pos, s, rng)
		"rock":
			_rock(ci, pos, s, tint, rng)
		"saxaul":
			_saxaul(ci, pos, s, tint, rng)
		"fence":
			_fence(ci, pos, s, tint)
		"haystack":
			_haystack(ci, pos, s)
		"house":
			_house(ci, pos, s, tint, rng)
		"sunflower":
			_sunflower(ci, pos, s)
		"lamp":
			_lamp(ci, pos, s, tint, false)
		"lamp_lit":
			_lamp(ci, pos, s, tint, true)
		"sign":
			_sign(ci, pos, s, tint)
		"cone":
			_cone(ci, pos, s)
		"bench":
			_bench(ci, pos, s, tint)
		"hydrant":
			_hydrant(ci, pos, s)
		"mushroom":
			_mushroom(ci, pos, s, rng)
		"fern":
			_fern(ci, pos, s, tint)
		"snowman":
			_snowman(ci, pos, s)
		"snow_mound":
			_snow_mound(ci, pos, s)
		"boulder":
			_rock(ci, pos, s * 2.0, tint, rng)
		"cairn":
			_cairn(ci, pos, s, tint)
		"reflector":
			_reflector(ci, pos, s)
		"rail":
			_rail(ci, pos, s, tint)
		"billboard":
			_billboard(ci, pos, s, tint)
		"skull":
			_bones(ci, pos, s)
		"cactus":
			_saxaul(ci, pos, s, tint, rng)


static func _tree_round(ci: CanvasItem, p: Vector2, s: float, rng: RandomNumberGenerator, tint: Color) -> void:
	var h := 3.2 * P * s
	var trunk := Color("6b4a2f")
	ci.draw_rect(Rect2(p.x - 0.12 * P * s, p.y - h * 0.55, 0.24 * P * s, h * 0.55 + 6), trunk)
	var c1 := tint
	var c2 := tint.darkened(0.18)
	var c3 := tint.lightened(0.15)
	var cy := p.y - h * 0.7
	var r := 1.0 * P * s
	ci.draw_circle(Vector2(p.x - r * 0.55, cy + r * 0.25), r * 0.75, c2)
	ci.draw_circle(Vector2(p.x + r * 0.6, cy + r * 0.3), r * 0.7, c2)
	ci.draw_circle(Vector2(p.x, cy), r, c1)
	ci.draw_circle(Vector2(p.x - r * 0.3, cy - r * 0.35), r * 0.45, c3)


static func _poplar(ci: CanvasItem, p: Vector2, s: float, tint: Color) -> void:
	var h := 6.0 * P * s
	var w := 0.75 * P * s
	ci.draw_rect(Rect2(p.x - 0.08 * P * s, p.y - h * 0.25, 0.16 * P * s, h * 0.25 + 6), Color("7a6248"))
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI * i / 16.0
		pts.append(Vector2(p.x + cos(a) * w * (0.75 + 0.25 * sin(a)), p.y - h * 0.2 - sin(a) * 0.0 - (1.0 - cos(a)) * 0.0))
	var poly := PackedVector2Array()
	for i in 21:
		var t := i / 20.0
		var ww := sin(t * PI) * w * (1.0 - t * 0.35)
		poly.append(Vector2(p.x + ww, p.y - h * (0.18 + 0.82 * t)))
	for i in range(20, -1, -1):
		var t := i / 20.0
		var ww := sin(t * PI) * w * (1.0 - t * 0.35)
		poly.append(Vector2(p.x - ww, p.y - h * (0.18 + 0.82 * t)))
	ci.draw_colored_polygon(poly, tint)
	var hl := PackedVector2Array()
	for i in 21:
		var t := i / 20.0
		hl.append(Vector2(p.x - sin(t * PI) * w * 0.15, p.y - h * (0.2 + 0.78 * t)))
	for i in range(20, -1, -1):
		var t := i / 20.0
		hl.append(Vector2(p.x - sin(t * PI) * w * (1.0 - t * 0.35) * 0.85, p.y - h * (0.2 + 0.78 * t)))
	ci.draw_colored_polygon(hl, tint.lightened(0.14))


static func _pine(ci: CanvasItem, p: Vector2, s: float, tint: Color, snow: bool) -> void:
	var h := 4.6 * P * s
	var w := 1.25 * P * s
	ci.draw_rect(Rect2(p.x - 0.12 * P * s, p.y - h * 0.2, 0.24 * P * s, h * 0.2 + 6), Color("5a3e28"))
	for i in 4:
		var t0 := 0.15 + i * 0.2
		var ww := w * (1.0 - i * 0.2)
		var y0 := p.y - h * t0
		var y1 := p.y - h * (t0 + 0.38)
		var tri := PackedVector2Array([Vector2(p.x - ww, y0), Vector2(p.x + ww, y0), Vector2(p.x, y1)])
		ci.draw_colored_polygon(tri, tint.darkened(0.06 * i))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - ww, y0), Vector2(p.x, y0), Vector2(p.x, y1)]), tint.lightened(0.08))
		if snow:
			var sw := ww * 0.55
			ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - sw, lerpf(y0, y1, 0.45)), Vector2(p.x + sw, lerpf(y0, y1, 0.45)), Vector2(p.x, y1)]), Color("f4f9ff"))


static func _bush(ci: CanvasItem, p: Vector2, s: float, tint: Color) -> void:
	var r := 0.55 * P * s
	ci.draw_circle(Vector2(p.x - r * 0.7, p.y - r * 0.4), r * 0.75, tint.darkened(0.12))
	ci.draw_circle(Vector2(p.x + r * 0.7, p.y - r * 0.35), r * 0.7, tint.darkened(0.12))
	ci.draw_circle(Vector2(p.x, p.y - r * 0.7), r, tint)
	ci.draw_circle(Vector2(p.x - r * 0.25, p.y - r * 1.0), r * 0.4, tint.lightened(0.15))


static func _grass(ci: CanvasItem, p: Vector2, s: float, tint: Color, rng: RandomNumberGenerator) -> void:
	for i in 5:
		var x := p.x + (i - 2) * 3.0 * s
		var h := (8.0 + rng.randf() * 8.0) * s
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 2 * s, p.y), Vector2(x + 2 * s, p.y), Vector2(x + (i - 2) * 1.5 * s, p.y - h)]), tint)


static func _flowers(ci: CanvasItem, p: Vector2, s: float, rng: RandomNumberGenerator) -> void:
	var cols := [Color("ff6b8b"), Color("ffd23f"), Color("ffffff"), Color("b28dff")]
	for i in 3:
		var x := p.x + (i - 1) * 7.0 * s
		var h := (10.0 + rng.randf() * 6.0) * s
		ci.draw_line(Vector2(x, p.y), Vector2(x, p.y - h), Color("3f8a3a"), 1.5)
		ci.draw_circle(Vector2(x, p.y - h), 3.0 * s, cols[rng.randi() % cols.size()])


static func _rock(ci: CanvasItem, p: Vector2, s: float, tint: Color, rng: RandomNumberGenerator) -> void:
	var r := 0.5 * P * s
	var pts := PackedVector2Array()
	var n := 7
	for i in n + 1:
		var a := PI + PI * i / n
		var rr := r * (0.75 + rng.randf() * 0.35)
		pts.append(Vector2(p.x + cos(a) * rr * 1.3, p.y + sin(a) * rr * 0.9 + 4))
	ci.draw_colored_polygon(pts, tint)
	var hl := PackedVector2Array([pts[1], pts[2], pts[3], Vector2(p.x, p.y - r * 0.2)])
	ci.draw_colored_polygon(hl, tint.lightened(0.15))


static func _saxaul(ci: CanvasItem, p: Vector2, s: float, tint: Color, rng: RandomNumberGenerator) -> void:
	var trunk := Color("8a6a4a")
	var top := Vector2(p.x, p.y - 1.2 * P * s)
	ci.draw_line(p, top, trunk, 4.0 * s)
	for i in 5:
		var a := -PI * 0.5 + (i - 2) * 0.45
		var e := top + Vector2(cos(a), sin(a)) * (0.9 + rng.randf() * 0.4) * P * s
		ci.draw_line(lerp(p, top, 0.5 + i * 0.1), e, trunk, 2.5 * s)
		ci.draw_circle(e, 0.32 * P * s, tint)


static func _fence(ci: CanvasItem, p: Vector2, s: float, tint: Color) -> void:
	var w := 2.4 * P * s
	var h := 1.0 * P * s
	for i in 3:
		var x := p.x - w * 0.5 + i * w * 0.5
		ci.draw_rect(Rect2(x - 3, p.y - h, 6, h + 6), tint)
	ci.draw_rect(Rect2(p.x - w * 0.5, p.y - h * 0.8, w, 4), tint.lightened(0.1))
	ci.draw_rect(Rect2(p.x - w * 0.5, p.y - h * 0.4, w, 4), tint.lightened(0.1))


static func _haystack(ci: CanvasItem, p: Vector2, s: float) -> void:
	var r := 0.9 * P * s
	var c := Color("e8c35a")
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		pts.append(Vector2(p.x + cos(a) * r * 1.2, p.y + sin(a) * r * 1.3 + 4))
	ci.draw_colored_polygon(pts, c)
	for i in 4:
		ci.draw_arc(Vector2(p.x, p.y + 4), r * (0.4 + i * 0.22), PI * 1.15, PI * 1.85, 10, c.darkened(0.18), 2.0)


static func _house(ci: CanvasItem, p: Vector2, s: float, tint: Color, rng: RandomNumberGenerator) -> void:
	var w := 4.0 * P * s
	var h := 2.6 * P * s
	var wall := tint
	ci.draw_rect(Rect2(p.x - w * 0.5, p.y - h, w, h + 8), wall)
	var roof := Color("b8553f") if rng.randf() < 0.5 else Color("4f6d8f")
	ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - w * 0.6, p.y - h), Vector2(p.x + w * 0.6, p.y - h), Vector2(p.x + w * 0.35, p.y - h - 1.2 * P * s), Vector2(p.x - w * 0.35, p.y - h - 1.2 * P * s)]), roof)
	ci.draw_rect(Rect2(p.x - w * 0.32, p.y - h * 0.65, w * 0.2, h * 0.3), Color("7cc4e8"))
	ci.draw_rect(Rect2(p.x + w * 0.12, p.y - h * 0.65, w * 0.2, h * 0.3), Color("7cc4e8"))
	ci.draw_rect(Rect2(p.x - w * 0.08, p.y - h * 0.5, w * 0.16, h * 0.5 + 8), Color("8a5a3a"))


static func _sunflower(ci: CanvasItem, p: Vector2, s: float) -> void:
	var h := 1.6 * P * s
	ci.draw_line(p, Vector2(p.x, p.y - h), Color("4c8a2e"), 3.0 * s)
	var c := Vector2(p.x, p.y - h)
	for i in 10:
		var a := TAU * i / 10.0
		ci.draw_circle(c + Vector2(cos(a), sin(a)) * 7.0 * s, 5.0 * s, Color("ffc928"))
	ci.draw_circle(c, 6.0 * s, Color("6b3f1f"))


static func _lamp(ci: CanvasItem, p: Vector2, s: float, tint: Color, lit: bool) -> void:
	var h := 4.2 * P * s
	ci.draw_rect(Rect2(p.x - 3 * s, p.y - h, 6 * s, h + 6), tint)
	ci.draw_line(Vector2(p.x, p.y - h), Vector2(p.x + 0.8 * P * s, p.y - h - 0.2 * P * s), tint, 5 * s)
	var head := Vector2(p.x + 0.8 * P * s, p.y - h - 0.12 * P * s)
	ci.draw_rect(Rect2(head.x - 0.3 * P * s, head.y, 0.6 * P * s, 0.12 * P * s), tint.darkened(0.3))
	if lit:
		ci.draw_circle(head + Vector2(0, 0.14 * P * s), 0.18 * P * s, Color("fff3c4"))
		var cone := PackedVector2Array([head + Vector2(-0.25 * P * s, 0.15 * P * s), head + Vector2(0.25 * P * s, 0.15 * P * s), Vector2(head.x + 1.8 * P * s, p.y), Vector2(head.x - 1.8 * P * s, p.y)])
		ci.draw_colored_polygon(cone, Color(1.0, 0.92, 0.6, 0.12))


static func _sign(ci: CanvasItem, p: Vector2, s: float, tint: Color) -> void:
	var h := 2.0 * P * s
	ci.draw_rect(Rect2(p.x - 2, p.y - h, 4, h + 6), Color("8d99a6"))
	var c := Vector2(p.x, p.y - h)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -0.45 * P * s), c + Vector2(0.45 * P * s, 0.3 * P * s), c + Vector2(-0.45 * P * s, 0.3 * P * s)]), Color.WHITE)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -0.32 * P * s), c + Vector2(0.33 * P * s, 0.22 * P * s), c + Vector2(-0.33 * P * s, 0.22 * P * s)]), tint)


static func _cone(ci: CanvasItem, p: Vector2, s: float) -> void:
	var h := 0.7 * P * s
	ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x - 0.25 * P * s, p.y), Vector2(p.x + 0.25 * P * s, p.y), Vector2(p.x + 0.06 * P * s, p.y - h), Vector2(p.x - 0.06 * P * s, p.y - h)]), Color("ff7a1a"))
	ci.draw_rect(Rect2(p.x - 0.17 * P * s, p.y - h * 0.55, 0.34 * P * s, h * 0.15), Color.WHITE)
	ci.draw_rect(Rect2(p.x - 0.32 * P * s, p.y - 4, 0.64 * P * s, 6), Color("e05a00"))


static func _bench(ci: CanvasItem, p: Vector2, s: float, tint: Color) -> void:
	var w := 1.6 * P * s
	ci.draw_rect(Rect2(p.x - w * 0.5, p.y - 0.45 * P * s, w, 5 * s), tint)
	ci.draw_rect(Rect2(p.x - w * 0.5, p.y - 0.8 * P * s, w, 4 * s), tint)
	ci.draw_rect(Rect2(p.x - w * 0.45, p.y - 0.45 * P * s, 4, 0.45 * P * s + 4), Color("3a3f47"))
	ci.draw_rect(Rect2(p.x + w * 0.45 - 4, p.y - 0.45 * P * s, 4, 0.45 * P * s + 4), Color("3a3f47"))


static func _hydrant(ci: CanvasItem, p: Vector2, s: float) -> void:
	var c := Color("e63946")
	ci.draw_rect(Rect2(p.x - 0.15 * P * s, p.y - 0.65 * P * s, 0.3 * P * s, 0.65 * P * s + 4), c)
	ci.draw_circle(Vector2(p.x, p.y - 0.65 * P * s), 0.15 * P * s, c)
	ci.draw_rect(Rect2(p.x - 0.25 * P * s, p.y - 0.45 * P * s, 0.5 * P * s, 0.1 * P * s), c.darkened(0.2))


static func _mushroom(ci: CanvasItem, p: Vector2, s: float, rng: RandomNumberGenerator) -> void:
	var h := 0.45 * P * s
	ci.draw_rect(Rect2(p.x - 0.07 * P * s, p.y - h, 0.14 * P * s, h + 4), Color("f1e9d8"))
	var cap := Color("d9372b") if rng.randf() < 0.6 else Color("b07a43")
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		pts.append(Vector2(p.x + cos(a) * 0.28 * P * s, p.y - h + sin(a) * 0.22 * P * s))
	ci.draw_colored_polygon(pts, cap)
	ci.draw_circle(Vector2(p.x - 0.1 * P * s, p.y - h - 0.1 * P * s), 2.5 * s, Color.WHITE)
	ci.draw_circle(Vector2(p.x + 0.08 * P * s, p.y - h - 0.06 * P * s), 2.0 * s, Color.WHITE)


static func _fern(ci: CanvasItem, p: Vector2, s: float, tint: Color) -> void:
	for i in 5:
		var a := -PI * 0.5 + (i - 2) * 0.38
		var e := p + Vector2(cos(a), sin(a)) * 0.9 * P * s
		ci.draw_line(p, e, tint, 3.0 * s)
		for k in 4:
			var q := p.lerp(e, 0.3 + k * 0.17)
			ci.draw_line(q, q + Vector2(cos(a - 0.9), sin(a - 0.9)) * 7 * s, tint.lightened(0.1), 2.0)
			ci.draw_line(q, q + Vector2(cos(a + 0.9), sin(a + 0.9)) * 7 * s, tint.lightened(0.1), 2.0)


static func _snowman(ci: CanvasItem, p: Vector2, s: float) -> void:
	var w := Color("f7fbff")
	ci.draw_circle(Vector2(p.x, p.y - 0.45 * P * s), 0.5 * P * s, w)
	ci.draw_circle(Vector2(p.x, p.y - 1.15 * P * s), 0.35 * P * s, w)
	ci.draw_circle(Vector2(p.x, p.y - 1.65 * P * s), 0.25 * P * s, w)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(p.x + 0.08 * P * s, p.y - 1.68 * P * s), Vector2(p.x + 0.45 * P * s, p.y - 1.63 * P * s), Vector2(p.x + 0.08 * P * s, p.y - 1.58 * P * s)]), Color("ff8c1a"))
	ci.draw_rect(Rect2(p.x - 0.28 * P * s, p.y - 1.95 * P * s, 0.56 * P * s, 0.08 * P * s), Color("2b2d42"))
	ci.draw_rect(Rect2(p.x - 0.18 * P * s, p.y - 2.3 * P * s, 0.36 * P * s, 0.36 * P * s), Color("2b2d42"))
	ci.draw_rect(Rect2(p.x - 0.36 * P * s, p.y - 1.42 * P * s, 0.72 * P * s, 0.1 * P * s), Color("e63946"))


static func _snow_mound(ci: CanvasItem, p: Vector2, s: float) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		pts.append(Vector2(p.x + cos(a) * 1.2 * P * s, p.y + sin(a) * 0.5 * P * s + 4))
	ci.draw_colored_polygon(pts, Color("eef6ff"))


static func _cairn(ci: CanvasItem, p: Vector2, s: float, tint: Color) -> void:
	var y := p.y
	for i in 4:
		var w := (0.6 - i * 0.12) * P * s
		var h := (0.28 - i * 0.03) * P * s
		ci.draw_rect(Rect2(p.x - w * 0.5, y - h, w, h + 2), tint.lightened(i * 0.06))
		y -= h


static func _reflector(ci: CanvasItem, p: Vector2, s: float) -> void:
	ci.draw_rect(Rect2(p.x - 3, p.y - 0.9 * P * s, 6, 0.9 * P * s + 4), Color("e9eef3"))
	ci.draw_rect(Rect2(p.x - 3, p.y - 0.85 * P * s, 6, 0.12 * P * s), Color("ff9f1c"))


static func _rail(ci: CanvasItem, p: Vector2, s: float, tint: Color) -> void:
	var w := 3.0 * P * s
	ci.draw_rect(Rect2(p.x - w * 0.5, p.y - 0.75 * P * s, w, 0.22 * P * s), tint)
	for i in 3:
		ci.draw_rect(Rect2(p.x - w * 0.5 + i * w * 0.48, p.y - 0.75 * P * s, 5, 0.75 * P * s + 4), tint.darkened(0.25))


static func _billboard(ci: CanvasItem, p: Vector2, s: float, tint: Color) -> void:
	var h := 5.0 * P * s
	ci.draw_rect(Rect2(p.x - 4, p.y - h, 8, h + 6), Color("39424e"))
	ci.draw_rect(Rect2(p.x - 2.2 * P * s, p.y - h - 1.4 * P * s, 4.4 * P * s, 1.6 * P * s), Color("39424e"))
	ci.draw_rect(Rect2(p.x - 2.05 * P * s, p.y - h - 1.28 * P * s, 4.1 * P * s, 1.36 * P * s), tint)
	ci.draw_rect(Rect2(p.x - 1.8 * P * s, p.y - h - 1.0 * P * s, 2.2 * P * s, 0.25 * P * s), Color(1, 1, 1, 0.8))
	ci.draw_rect(Rect2(p.x - 1.8 * P * s, p.y - h - 0.6 * P * s, 1.5 * P * s, 0.18 * P * s), Color(1, 1, 1, 0.55))


static func _bones(ci: CanvasItem, p: Vector2, s: float) -> void:
	var c := Color("efe6d2")
	ci.draw_line(Vector2(p.x - 0.4 * P * s, p.y - 4), Vector2(p.x + 0.4 * P * s, p.y - 4), c, 4 * s)
	ci.draw_circle(Vector2(p.x - 0.42 * P * s, p.y - 4), 4 * s, c)
	ci.draw_circle(Vector2(p.x + 0.42 * P * s, p.y - 4), 4 * s, c)
