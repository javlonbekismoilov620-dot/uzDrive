## One streamed slice of terrain: collision + ground art + props + bridges.
class_name TerrainChunk
extends Node2D

const P := K.PPM

var gen: TerrainGenerator
var env: Dictionary
var vis: Dictionary
var index := 0
var i0 := 0
var i1 := 0
var ground_tex: Texture2D


func build(generator: TerrainGenerator, environment: Dictionary, chunk_index: int, samples: int, tex: Texture2D) -> void:
	gen = generator
	env = environment
	vis = env.get("visual", {})
	index = chunk_index
	i0 = chunk_index * samples
	i1 = mini(i0 + samples, gen.ys.size() - 1)
	ground_tex = tex
	name = "Chunk%d" % index

	var top := PackedVector2Array()
	for i in range(i0, i1 + 1):
		top.append(Vector2(i * TerrainGenerator.STEP * P, -gen.ys[i] * P))

	_build_collision(top)
	_build_back_decor(top)
	_build_ground(top)
	_build_top_band(top)
	_build_ramps()
	_build_obstacles()
	_build_bridges()
	_build_front_decor(top)
	_build_checkpoints()


func x_range_m() -> Vector2:
	return Vector2(i0 * TerrainGenerator.STEP, i1 * TerrainGenerator.STEP)


# ------------------------------------------------------------------
func _build_collision(top: PackedVector2Array) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = K.LAYER_TERRAIN
	body.collision_mask = 0
	body.add_to_group("terrain")
	var mat := PhysicsMaterial.new()
	mat.friction = 0.8
	body.physics_material_override = mat
	var segs := PackedVector2Array()
	for i in top.size() - 1:
		segs.append(top[i])
		segs.append(top[i + 1])
	var shape := ConcavePolygonShape2D.new()
	shape.segments = segs
	var cs := CollisionShape2D.new()
	cs.shape = shape
	body.add_child(cs)
	add_child(body)


func _build_ground(top: PackedVector2Array) -> void:
	var lowest := -INF
	for p in top:
		lowest = maxf(lowest, p.y)
	var bottom := lowest + 30.0 * P
	var poly := top.duplicate()
	poly.append(Vector2(top[top.size() - 1].x, bottom))
	poly.append(Vector2(top[0].x, bottom))
	var g := Polygon2D.new()
	g.polygon = poly
	var c_top := Util.col(vis.get("ground", "#7b5a3c"))
	var c_bot := Util.col(vis.get("ground_dark", "#3d2a1a"))
	var cols := PackedColorArray()
	for i in poly.size():
		var depth := clampf((poly[i].y - (top[mini(i, top.size() - 1)].y)) / (12.0 * P), 0.0, 1.0)
		cols.append(c_top if i < top.size() else c_bot)
	g.vertex_colors = cols
	if ground_tex:
		g.texture = ground_tex
		g.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		g.texture_scale = Vector2.ONE
	add_child(g)


func _build_top_band(top: PackedVector2Array) -> void:
	var band_h := float(vis.get("top_h", 0.32)) * P
	var start := 0
	var n := top.size()
	while start < n - 1:
		var s := gen.surf[i0 + start]
		var end := start
		while end < n - 1 and gen.surf[i0 + end + 1] == s:
			end += 1
		end = mini(end + 1, n - 1)
		var c := Util.col(vis.get("top" if s == 0 else "patch_top", "#62b94a"))
		var cd := Util.col(vis.get("top_dark" if s == 0 else "patch_top_dark", "#3f8a32"))
		var band := PackedVector2Array()
		var dark := PackedVector2Array()
		for i in range(start, end + 1):
			band.append(top[i])
		for i in range(end, start - 1, -1):
			band.append(top[i] + Vector2(0, band_h))
		for i in range(start, end + 1):
			dark.append(top[i] + Vector2(0, band_h * 0.7))
		for i in range(end, start - 1, -1):
			dark.append(top[i] + Vector2(0, band_h * 1.25))
		var pd := Polygon2D.new()
		pd.polygon = dark
		pd.color = cd
		add_child(pd)
		var pb := Polygon2D.new()
		pb.polygon = band
		pb.color = c
		add_child(pb)
		var hl := Line2D.new()
		var pts := PackedVector2Array()
		for i in range(start, end + 1):
			pts.append(top[i] + Vector2(0, 1.5))
		hl.points = pts
		hl.width = 3.0
		hl.default_color = c.lightened(0.22)
		hl.joint_mode = Line2D.LINE_JOINT_ROUND
		add_child(hl)
		start = end
		if end >= n - 1:
			break


func _rng(salt: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = int(env.get("terrain", {}).get("seed", 1)) * 7919 + index * 104729 + salt
	return r


func _place_decor(top: PackedVector2Array, list: Array, rng: RandomNumberGenerator, ci: CanvasItem, sink: float) -> void:
	var length_m := (i1 - i0) * TerrainGenerator.STEP
	for entry in list:
		var kind: String = entry[0]
		var density := float(entry[1])
		var tint := Util.col(entry[2] if entry.size() > 2 else "#ffffff")
		var smin := float(entry[3]) if entry.size() > 3 else 0.8
		var smax := float(entry[4]) if entry.size() > 4 else 1.2
		var count := int(density * length_m / 10.0 + rng.randf())
		for k in count:
			var xi := rng.randi_range(0, top.size() - 2)
			var gi := i0 + xi
			if gi < gen.flags.size() and gen.flags[gi] != 0:
				continue
			var x_m := gi * TerrainGenerator.STEP
			if _in_bridge_pit(x_m):
				continue
			var p := top[xi] + Vector2(rng.randf() * TerrainGenerator.STEP * P, sink)
			var t2 := tint.lerp(tint.darkened(0.15), rng.randf())
			DecorPainter.draw(ci, kind, p, rng.randf_range(smin, smax), rng, t2)


func _in_bridge_pit(x_m: float) -> bool:
	for b in gen.bridges:
		if x_m > b.x0 - 1.0 and x_m < b.x1 + 1.0:
			return true
	return false


func _build_back_decor(top: PackedVector2Array) -> void:
	var list: Array = vis.get("decor_back", [])
	if list.is_empty():
		return
	var n := _DrawNode.new()
	var rng := _rng(11)
	n.painter = func(ci: CanvasItem) -> void:
		var r2 := RandomNumberGenerator.new()
		r2.seed = rng.seed
		_place_decor(top, list, r2, ci, 0.35 * P)
	add_child(n)


func _build_front_decor(top: PackedVector2Array) -> void:
	var list: Array = vis.get("decor_front", [])
	if list.is_empty():
		return
	var n := _DrawNode.new()
	var rng := _rng(23)
	n.painter = func(ci: CanvasItem) -> void:
		var r2 := RandomNumberGenerator.new()
		r2.seed = rng.seed
		_place_decor(top, list, r2, ci, 2.0)
	add_child(n)


func _build_ramps() -> void:
	var style: String = vis.get("ramp_style", "dirt")
	if style == "dirt":
		return
	var x0m := i0 * TerrainGenerator.STEP
	var x1m := i1 * TerrainGenerator.STEP
	for r in gen.ramps:
		if r.x0 < x0m or r.x0 >= x1m:
			continue
		var n := _DrawNode.new()
		var rr: Dictionary = r
		n.painter = func(ci: CanvasItem) -> void:
			var wood := Color("a8743f") if style == "wood" else Color("8e9aa6")
			var a := Vector2(rr.x0 * P, -gen.height_at(rr.x0) * P)
			var b := Vector2(rr.x1 * P, -gen.height_at(rr.x1) * P)
			var lip := Vector2(b.x + 0.5 * P, b.y)
			ci.draw_colored_polygon(PackedVector2Array([a, b, lip, lip + Vector2(0, 8), b + Vector2(0, 8), a + Vector2(0, 8)]), wood)
			var segs := int((b.x - a.x) / (0.5 * P))
			for i in segs:
				var q := a.lerp(b, float(i) / segs)
				ci.draw_line(q, q + Vector2(0, 8), wood.darkened(0.35), 1.5)
			# hazard stripes on lip
			ci.draw_rect(Rect2(lip.x - 6, lip.y - 1, 6, 10), Color("ffcf33"))
		add_child(n)


func _build_obstacles() -> void:
	var x0m := i0 * TerrainGenerator.STEP
	var x1m := i1 * TerrainGenerator.STEP
	var tint := Util.col(vis.get("rock", "#8d8f93"))
	for o in gen.obstacles:
		if o.x < x0m or o.x >= x1m:
			continue
		var body := StaticBody2D.new()
		body.collision_layer = K.LAYER_TERRAIN
		body.collision_mask = 0
		body.add_to_group("terrain")
		# Obstacles are rollable: low, wide mounds whose faces stay under ~50°,
		# so every wheel size can climb them with a satisfying bump.
		var size: float = o.size * P
		var base := Vector2(o.x * P, -o.y * P)
		var r := RandomNumberGenerator.new()
		r.seed = int(o.seed)
		var col := tint
		var poly := PackedVector2Array()
		match o.kind:
			"log":
				var rad := size * 0.48
				var center := base + Vector2(0, -rad * 0.85)
				poly = Util.circle_poly(center, rad, 14)
				var dn := _DrawNode.new()
				dn.painter = func(ci: CanvasItem) -> void:
					ci.draw_circle(center, rad, Color("7a5232"))
					ci.draw_circle(center, rad * 0.78, Color("c79a64"))
					ci.draw_arc(center, rad * 0.5, 0, TAU, 14, Color("9c7148"), 2.0)
					ci.draw_arc(center, rad * 0.25, 0, TAU, 10, Color("9c7148"), 1.5)
				var cp0 := CollisionPolygon2D.new()
				cp0.polygon = poly
				body.add_child(cp0)
				add_child(body)
				add_child(dn)
				continue
			"bump":
				poly = _cos_mound(base, size * 1.8, size * 0.45, 0.0, r)
				col = Color("ffcf33")
			"crate":
				# low pallet with chamfered ends
				var hw := size * 1.4
				var h := size * 0.6
				poly = PackedVector2Array([base + Vector2(-hw - h, 3), base + Vector2(hw + h, 3), base + Vector2(hw, -h), base + Vector2(-hw, -h)])
				col = Color("b98149")
			"bale":
				poly = _cos_mound(base, size * 1.7, size * 0.75, 0.0, r)
				col = Color("e3bd55")
			_:
				# rock / ice: irregular low mound
				poly = _cos_mound(base, size * 1.7, size * 0.7, 0.12, r)
				if o.kind == "ice":
					col = Color("bfe6ff")
		var cp := CollisionPolygon2D.new()
		cp.polygon = poly
		body.add_child(cp)
		add_child(body)
		var vis_poly := Polygon2D.new()
		vis_poly.polygon = poly
		var vc := PackedColorArray()
		var top_y := INF
		for p in poly:
			top_y = minf(top_y, p.y)
		for p in poly:
			var t2 := clampf((p.y - top_y) / maxf(size * 0.7, 1.0), 0.0, 1.0)
			vc.append(col.lightened(0.18).lerp(col.darkened(0.3), t2))
		vis_poly.vertex_colors = vc
		add_child(vis_poly)
		if o.kind == "bump":
			var stripes := _DrawNode.new()
			var bb := base
			var ss := size
			stripes.painter = func(ci: CanvasItem) -> void:
				for i in 3:
					var x := bb.x + (i - 1) * ss * 1.0
					ci.draw_line(Vector2(x - 4, bb.y - ss * 0.05), Vector2(x + 4, bb.y - ss * 0.38), Color("1d1d1d"), 5.0)
			add_child(stripes)
		elif o.kind == "crate":
			var planks := _DrawNode.new()
			var bb2 := base
			var ss2 := size
			planks.painter = func(ci: CanvasItem) -> void:
				for i in 3:
					var y := bb2.y - ss2 * 0.6 * (0.2 + 0.3 * i)
					ci.draw_line(Vector2(bb2.x - ss2 * 1.4, y), Vector2(bb2.x + ss2 * 1.4, y), Color("8a5a2b"), 2.0)
			add_child(planks)
		elif o.kind == "bale":
			var lines := _DrawNode.new()
			var bb3 := base
			var ss3 := size
			lines.painter = func(ci: CanvasItem) -> void:
				for i in 3:
					ci.draw_arc(bb3 + Vector2(0, 3), ss3 * (0.5 + 0.35 * i), PI * 1.1, PI * 1.9, 10, Color("c9a03a"), 2.0)
			add_child(lines)


## Smooth cosine mound (zero slope at both ends, max face slope ~35°).
func _cos_mound(base: Vector2, half_w: float, h: float, jitter: float, r: RandomNumberGenerator) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := 12
	for i in n + 1:
		var t := float(i) / n
		var x := lerpf(-half_w, half_w, t)
		var y := h * (0.5 + 0.5 * cos(PI * x / half_w))
		if i > 0 and i < n:
			y *= 1.0 + r.randf_range(-jitter, jitter)
		pts.append(base + Vector2(x, -y + 3.0))
	return pts


func _build_bridges() -> void:
	var x0m := i0 * TerrainGenerator.STEP
	var x1m := i1 * TerrainGenerator.STEP
	for b in gen.bridges:
		if b.x0 < x0m or b.x0 >= x1m:
			continue
		var body := StaticBody2D.new()
		body.collision_layer = K.LAYER_TERRAIN
		body.collision_mask = 0
		body.add_to_group("terrain")
		var segs := PackedVector2Array()
		var deck := PackedVector2Array()
		var n := int((b.x1 - b.x0) / 0.5) + 1
		for i in n + 1:
			var x := lerpf(b.x0 - 0.3, b.x1 + 0.3, float(i) / n)
			deck.append(Vector2(x * P, -gen.deck_height(b, clampf(x, b.x0, b.x1)) * P))
		for i in deck.size() - 1:
			segs.append(deck[i])
			segs.append(deck[i + 1])
		var shape := ConcavePolygonShape2D.new()
		shape.segments = segs
		var cs := CollisionShape2D.new()
		cs.shape = shape
		body.add_child(cs)
		add_child(body)
		var wood := Util.col(vis.get("bridge", "#9b6a3f"))
		var water := Util.col(vis.get("water", "#3fa7d6"))
		var has_water: bool = b.water
		var bb: Dictionary = b
		var dn := _DrawNode.new()
		dn.painter = func(ci: CanvasItem) -> void:
			var pit_y := -gen.height_at((bb.x0 + bb.x1) * 0.5) * P
			if has_water:
				var wy := pit_y - 1.4 * P
				ci.draw_rect(Rect2(bb.x0 * P + 0.8 * P, wy, (bb.x1 - bb.x0) * P - 1.6 * P, pit_y - wy + 4), water)
				ci.draw_rect(Rect2(bb.x0 * P + 0.8 * P, wy, (bb.x1 - bb.x0) * P - 1.6 * P, 4), water.lightened(0.35))
			# support posts at ends
			for xe in [bb.x0, bb.x1]:
				var top_y := -gen.deck_height(bb, xe) * P
				ci.draw_rect(Rect2(xe * P - 7, top_y - 1.6 * P, 14, 1.6 * P + 2.5 * P), wood.darkened(0.3))
			# rope rails
			var rail := PackedVector2Array()
			for p in deck:
				rail.append(p + Vector2(0, -1.25 * P))
			ci.draw_polyline(rail, Color("d9c08f"), 3.0, true)
			for i in range(0, deck.size(), 4):
				ci.draw_line(deck[i], deck[i] + Vector2(0, -1.25 * P), Color("d9c08f").darkened(0.2), 2.0)
			# planks
			for i in deck.size() - 1:
				var a: Vector2 = deck[i]
				var c: Vector2 = deck[i + 1]
				var dir := (c - a).normalized()
				var nrm := Vector2(-dir.y, dir.x)
				var pc := wood if i % 2 == 0 else wood.darkened(0.12)
				ci.draw_colored_polygon(PackedVector2Array([a, c - dir * 1.5, c - dir * 1.5 + nrm * 9, a + nrm * 9]), pc)
		add_child(dn)


func _build_checkpoints() -> void:
	var x0m := i0 * TerrainGenerator.STEP
	var x1m := i1 * TerrainGenerator.STEP
	for cp in gen.checkpoints:
		if cp < x0m or cp >= x1m:
			continue
		var dn := _DrawNode.new()
		var cpx: float = cp
		dn.painter = func(ci: CanvasItem) -> void:
			var y := -gen.surface_height_at(cpx) * P
			var x := cpx * P
			var pole := Color("e8edf2")
			ci.draw_rect(Rect2(x - 4, y - 3.6 * P, 8, 3.6 * P + 10), pole)
			var flag := PackedVector2Array([Vector2(x + 4, y - 3.6 * P), Vector2(x + 1.6 * P, y - 3.25 * P), Vector2(x + 4, y - 2.9 * P)])
			ci.draw_colored_polygon(flag, Color("ff4d5a"))
			var font := ThemeDB.fallback_font
			var txt := "%d m" % int(cpx)
			ci.draw_rect(Rect2(x - 1.3 * P, y - 2.4 * P, 2.6 * P, 0.75 * P), Color(0.08, 0.1, 0.15, 0.85))
			ci.draw_string(font, Vector2(x - 1.3 * P, y - 1.83 * P), txt, HORIZONTAL_ALIGNMENT_CENTER, 2.6 * P, 20, Color.WHITE)
		add_child(dn)


class _DrawNode:
	extends Node2D
	var painter: Callable

	func _draw() -> void:
		if painter.is_valid():
			painter.call(self)
