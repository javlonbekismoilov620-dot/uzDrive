## Sky, sun/moon, stars, clouds, parallax scenery layers and weather for an
## environment. Everything is generated vector art (seamless, tiled by Parallax2D).
class_name Backdrop
extends Node2D

const LAYER_W := 2560.0

var env: Dictionary
var vis: Dictionary
var quality := "high"
var _sky_layer: CanvasLayer
var _weather: SimpleParticles


func setup(environment: Dictionary, world: Node2D, q := "high") -> void:
	env = environment
	vis = env.get("visual", {})
	quality = q
	_build_sky()
	_build_clouds(world)
	var layers: Array = vis.get("layers", [])
	for i in layers.size():
		_build_layer(world, layers[i], i)
	if quality != "low":
		_build_weather()


# ------------------------------------------------------------------ sky
func _build_sky() -> void:
	_sky_layer = CanvasLayer.new()
	_sky_layer.layer = -100
	add_child(_sky_layer)
	var sky := _SkyDraw.new()
	sky.vis = vis
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sky_layer.add_child(sky)


class _SkyDraw:
	extends Control
	var vis: Dictionary
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		if vis.has("stars"):
			queue_redraw()

	func _draw() -> void:
		var s: Array = vis.get("sky", ["#5fb8f0", "#d7f1ff"])
		var top := Util.col(s[0])
		var bot := Util.col(s[1])
		var r := get_rect()
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(r.size.x, 0), r.size, Vector2(0, r.size.y)]),
			PackedColorArray([top, top, bot, bot]))
		if vis.has("stars"):
			var rng := RandomNumberGenerator.new()
			rng.seed = 99
			for i in int(vis.stars):
				var p := Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y * 0.6)
				var tw := 0.55 + 0.45 * sin(_t * (1.0 + rng.randf() * 2.0) + i)
				draw_circle(p, 1.0 + rng.randf() * 1.4, Color(1, 1, 1, 0.85 * tw))
		for key in ["sun", "moon"]:
			if vis.has(key):
				var b: Dictionary = vis[key]
				var c := Util.col(b.color)
				var pos := Vector2(float(b.x) * r.size.x, float(b.y) * r.size.y)
				var rad := float(b.r)
				for i in 6:
					draw_circle(pos, rad * (1.0 + i * 0.45), Color(c, 0.07 - i * 0.01))
				draw_circle(pos, rad, c)
				if key == "moon":
					draw_circle(pos + Vector2(rad * 0.3, -rad * 0.15), rad * 0.22, c.darkened(0.08))
					draw_circle(pos + Vector2(-rad * 0.35, rad * 0.3), rad * 0.15, c.darkened(0.08))


func _build_clouds(world: Node2D) -> void:
	var cl: Dictionary = vis.get("clouds", {})
	if cl.is_empty() or quality == "low":
		return
	var px := Parallax2D.new()
	px.scroll_scale = Vector2(0.03, 0.02)
	px.repeat_size = Vector2(LAYER_W * 1.5, 0)
	px.repeat_times = 3
	px.autoscroll = Vector2(-12, 0)
	px.z_index = -90
	world.add_child(px)
	var d := _CloudDraw.new()
	d.color = Util.col(cl.get("color", "#ffffff"))
	d.count = int(cl.get("count", 5))
	d.width = LAYER_W * 1.5
	d.position = Vector2(0, 30)
	px.add_child(d)


class _CloudDraw:
	extends Node2D
	var color := Color.WHITE
	var count := 5
	var width := 3000.0

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in count:
			var x := (i + rng.randf() * 0.6) * width / count
			var y := rng.randf_range(0.0, 260.0)
			var s := rng.randf_range(0.7, 1.4)
			var c := Color(color, rng.randf_range(0.65, 0.95))
			for k in 5:
				var off := Vector2((k - 2) * 38 * s, -absf(k - 2) * -6 * s - (12 if k == 2 else 0) * s)
				draw_circle(Vector2(x, y) + off, (34 - absf(k - 2) * 7) * s, c)
			draw_rect(Rect2(x - 80 * s, y, 160 * s, 22 * s), c)


# ------------------------------------------------------------------ parallax layers
func _build_layer(world: Node2D, spec: Dictionary, index: int) -> void:
	var px := Parallax2D.new()
	var sc := float(spec.get("scroll", 0.2))
	px.scroll_scale = Vector2(sc, sc * 0.4)
	px.repeat_size = Vector2(LAYER_W, 0)
	px.repeat_times = 4
	px.z_index = -80 + index * 5
	world.add_child(px)
	var d := _LayerDraw.new()
	d.spec = spec
	d.width = LAYER_W
	# Low scroll_scale makes Parallax2D content behave almost like screen
	# space, so the baseline is expressed relative to the top of the screen.
	d.position = Vector2(0, float(spec.get("y", 0)) + 520.0)
	px.add_child(d)


class _LayerDraw:
	extends Node2D
	var spec: Dictionary
	var width := 2560.0

	func _profile(n: int, rough: float, seed: int, kind: String) -> PackedFloat32Array:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var harm: Array = []
		var count := 6
		for i in count:
			var freq: int = [1, 2, 3, 5, 7, 11][i]
			var amp := 1.0 / (1.0 + i * (1.6 - rough))
			harm.append([freq, amp, rng.randf() * TAU])
		var out := PackedFloat32Array()
		var mn := INF
		var mx := -INF
		for k in n + 1:
			var x := float(k) / n
			var y := 0.0
			for h in harm:
				var v := sin(TAU * h[0] * x + h[2])
				if kind == "mountains" or kind == "rocks":
					v = 1.0 - absf(v) * 2.0 if rough > 0.5 else v
				y += v * h[1]
			out.append(y)
			mn = minf(mn, y)
			mx = maxf(mx, y)
		for k in out.size():
			out[k] = (out[k] - mn) / maxf(mx - mn, 0.001)
		return out

	func _draw() -> void:
		var kind: String = spec.get("kind", "hills")
		var col := Util.col(spec.get("color", "#88aa77"))
		var h := float(spec.get("h", 200))
		var seed := int(spec.get("seed", 1))
		var n := 128
		var prof: PackedFloat32Array
		match kind:
			"mountains", "rocks":
				prof = _profile(n, float(spec.get("rough", 0.5)), seed, kind)
			"mesa":
				prof = _profile(n, 0.3, seed, kind)
				for k in prof.size():
					prof[k] = 0.85 if prof[k] > 0.55 else prof[k] * 0.6
			"city":
				prof = PackedFloat32Array()
				prof.resize(n + 1)
			_:
				prof = _profile(n, 0.2, seed, kind)
		if kind == "city":
			_draw_city(col, h, seed)
			return
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for k in n + 1:
			var x := width * k / n
			var y := -prof[k] * h
			pts.append(Vector2(x, y))
			cols.append(col.lightened(0.06 * prof[k]))
		pts.append(Vector2(width, 3000))
		cols.append(col.darkened(0.15))
		pts.append(Vector2(0, 3000))
		cols.append(col.darkened(0.15))
		draw_polygon(pts, cols)
		# snow caps
		if spec.get("snow", false):
			for k in n:
				if prof[k] > 0.72 and prof[k + 1] > 0.72:
					var a := pts[k]
					var b := pts[k + 1]
					var drop := (prof[k] - 0.72) * h * 0.7
					var drop2 := (prof[k + 1] - 0.72) * h * 0.7
					draw_colored_polygon(PackedVector2Array([a, b, b + Vector2(0, drop2), a + Vector2(0, drop)]), Color(1, 1, 1, 0.85))
		# fields stripes
		if kind == "fields":
			var c2 := Util.col(spec.get("color2", "#bfd56a"))
			for i in 8:
				var y0 := 40.0 + i * 46.0
				draw_rect(Rect2(0, y0, width, 18), Color(c2, 0.35))
		# decor silhouettes on the ridge
		var dec: String = spec.get("decor", "none")
		if dec != "none":
			var dc := Util.col(spec.get("decor_color", "#557744"))
			var rng := RandomNumberGenerator.new()
			rng.seed = seed * 13
			var step := 26
			for k in range(2, n - 2, 1):
				if rng.randf() > (0.35 if dec != "lamps" else 0.12):
					continue
				var p := pts[k] + Vector2(rng.randf() * 10.0, 6)
				var s := rng.randf_range(0.6, 1.1)
				match dec:
					"trees":
						draw_rect(Rect2(p.x - 2, p.y - 18 * s, 4, 18 * s), dc.darkened(0.3))
						draw_circle(p + Vector2(0, -24 * s), 14 * s, dc)
					"pines", "snowpines":
						draw_colored_polygon(PackedVector2Array([p + Vector2(-11 * s, 0), p + Vector2(11 * s, 0), p + Vector2(0, -46 * s)]), dc)
						if dec == "snowpines":
							draw_colored_polygon(PackedVector2Array([p + Vector2(-5 * s, -26 * s), p + Vector2(5 * s, -26 * s), p + Vector2(0, -46 * s)]), Color(1, 1, 1, 0.9))
					"poplars":
						draw_colored_polygon(PackedVector2Array([p + Vector2(-6 * s, 0), p + Vector2(6 * s, 0), p + Vector2(3 * s, -58 * s), p + Vector2(0, -66 * s), p + Vector2(-3 * s, -58 * s)]), dc)
					"lamps":
						draw_rect(Rect2(p.x - 1.5, p.y - 60, 3, 60), Color("2a2f45"))
						draw_circle(p + Vector2(0, -60), 4, dc)
						draw_circle(p + Vector2(0, -60), 12, Color(dc, 0.2))

	func _draw_city(col: Color, h: float, seed: int) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var x := 0.0
		var wc := Util.col(spec.get("windows", "#d9e6f2"))
		var lit: bool = spec.get("lit", false)
		while x < width:
			var bw := rng.randf_range(60, 150)
			if x + bw > width:
				bw = width - x
			var bh := rng.randf_range(0.35, 1.0) * h
			var c := col.lightened(rng.randf_range(-0.05, 0.08))
			draw_rect(Rect2(x, -bh, bw - 4, bh + 3000), c)
			if rng.randf() < 0.3:
				draw_rect(Rect2(x + bw * 0.4, -bh - 24, 4, 24), c)
			# windows
			var wy := -bh + 14
			while wy < -12:
				var wx := x + 10
				while wx < x + bw - 18:
					if rng.randf() < (0.45 if lit else 0.7):
						var a := 0.9 if lit else 0.35
						draw_rect(Rect2(wx, wy, 8, 10), Color(wc, a))
					wx += 16
				wy += 20
			x += bw


# ------------------------------------------------------------------ weather
func _build_weather() -> void:
	var kind: String = vis.get("weather", "none")
	if kind == "none":
		return
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	var p := SimpleParticles.new()
	p.position = Vector2(700, -20)
	p.emission_rect_extents = Vector2(1100, 10)
	match kind:
		"snow":
			p.amount = 140
			p.lifetime = 7.0
			p.direction = Vector2(-0.3, 1)
			p.spread = 20
			p.gravity = Vector2(-10, 40)
			p.initial_velocity_min = 30
			p.initial_velocity_max = 70
			p.scale_amount_min = 1.2
			p.scale_amount_max = 2.6
			p.color = Color(1, 1, 1, 0.9)
			p.end_color = Color(1, 1, 1, 0.6)
		"dust":
			p.amount = 50
			p.lifetime = 6.0
			p.position = Vector2(1400, 360)
			p.emission_rect_extents = Vector2(20, 380)
			p.direction = Vector2(-1, 0.05)
			p.spread = 10
			p.gravity = Vector2(0, 5)
			p.initial_velocity_min = 140
			p.initial_velocity_max = 260
			p.scale_amount_min = 1.2
			p.scale_amount_max = 3.0
			p.color = Color(0.95, 0.85, 0.65, 0.35)
			p.end_color = Color(0.95, 0.85, 0.65, 0.0)
		"leaves":
			p.amount = 28
			p.lifetime = 8.0
			p.direction = Vector2(-0.4, 1)
			p.spread = 30
			p.gravity = Vector2(-15, 25)
			p.initial_velocity_min = 20
			p.initial_velocity_max = 60
			p.spin = 2.0
			p.scale_amount_min = 4.0
			p.scale_amount_max = 7.0
			p.color = Color("d9a441")
			p.end_color = Color(0.85, 0.64, 0.25, 0.4)
	p.emitting = true
	layer.add_child(p)
	p.prewarm(p.lifetime)
	_weather = p
