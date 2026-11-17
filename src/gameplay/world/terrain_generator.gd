## Deterministic, streaming terrain generator.
##
## Produces a height profile (metres, y-up) sampled every STEP metres, plus
## features that sit on it: bridges, obstacles, surface patches and pickups.
## Generation is append-only and seeded per environment, so every map is the
## same each time you play it (players can learn it), while difficulty grows
## with distance. Pure logic: no nodes, fully unit-testable.
class_name TerrainGenerator
extends RefCounted

const STEP := 0.5
const SURF_BASE := 0
const SURF_PATCH := 1

var env: Dictionary
var tp: Dictionary
var rng := RandomNumberGenerator.new()

var ys := PackedFloat32Array()
var surf := PackedByteArray()
var flags := PackedByteArray()         ## 1 = feature/cliff sample (no decor)
var bridges: Array = []                ## {x0, x1, y0, y1, sag, water}
var obstacles: Array = []              ## {kind, x, y, size, rot}
var pickups: Array = []                ## {id, kind, x, y, value}
var ramps: Array = []                  ## {x0, x1} kicker ramps (decor)
var checkpoints: Array = []            ## metres

var _last_slope := 0.0
var _next_fuel := 0.0
var _next_gem := 0.0
var _next_boost := 0.0
var _next_coins := 0.0
var _pickup_id := 0
var _seg_count := 0
var _patch_active := false


func _init(environment: Dictionary) -> void:
	env = environment
	tp = env.get("terrain", {})
	rng.seed = int(tp.get("seed", 1))
	var start_flat := float(tp.get("start_flat", 30.0))
	var n := int(start_flat / STEP)
	for i in n + 1:
		_push(0.0, SURF_BASE, 1)
	_last_slope = 0.0
	var pk: Dictionary = env.get("pickups", {})
	_next_fuel = float(pk.get("fuel_first", 160.0))
	_next_gem = float(pk.get("gem_every", 650.0)) * 0.8
	_next_boost = float(pk.get("boost_every", 260.0)) * 0.6
	_next_coins = start_flat * 0.6
	var cp_every := float(env.get("checkpoint_every", 500.0))
	for i in range(1, 60):
		checkpoints.append(cp_every * i)


# ------------------------------------------------------------------ queries
func length_m() -> float:
	return (ys.size() - 1) * STEP


func ensure(x_m: float) -> void:
	var guard := 0
	while length_m() < x_m and guard < 500:
		_gen_segment()
		guard += 1


func height_at(x_m: float) -> float:
	if x_m <= 0.0:
		return ys[0]
	var fi := x_m / STEP
	var i := int(fi)
	if i >= ys.size() - 1:
		return ys[ys.size() - 1]
	return lerpf(ys[i], ys[i + 1], fi - i)


## Height of the drivable surface (bridge decks included).
func surface_height_at(x_m: float) -> float:
	for b in bridges:
		if x_m >= b.x0 and x_m <= b.x1:
			return deck_height(b, x_m)
	return height_at(x_m)


func deck_height(b: Dictionary, x_m: float) -> float:
	var t := clampf((x_m - b.x0) / maxf(b.x1 - b.x0, 0.01), 0.0, 1.0)
	return lerpf(b.y0, b.y1, t) - sin(t * PI) * float(b.sag)


func slope_at(x_m: float) -> float:
	return (height_at(x_m + STEP) - height_at(x_m - STEP)) / (2.0 * STEP)


func surface_at(x_m: float) -> int:
	var i := clampi(int(x_m / STEP), 0, surf.size() - 1)
	return surf[i]


func difficulty(x_m: float) -> float:
	return clampf(x_m / float(tp.get("difficulty_dist", 3000.0)), 0.0, 1.0)


# ------------------------------------------------------------------ build helpers
func _x() -> float:
	return (ys.size() - 1) * STEP


func _y() -> float:
	return ys[ys.size() - 1]


func _push(y: float, s: int, f := 0) -> void:
	ys.append(y)
	surf.append(s)
	flags.append(f)


## Cubic Hermite from current point/slope to (x+len, y1) with end slope m1.
func _hermite(length: float, y1: float, m1: float, s: int, max_slope: float, f := 0) -> void:
	var y0 := _y()
	var m0 := _last_slope
	var n := maxi(int(round(length / STEP)), 1)
	var prev := y0
	for k in range(1, n + 1):
		var t := float(k) / n
		var t2 := t * t
		var t3 := t2 * t
		var y := (2 * t3 - 3 * t2 + 1) * y0 + (t3 - 2 * t2 + t) * length * m0 + (-2 * t3 + 3 * t2) * y1 + (t3 - t2) * length * m1
		var lim := max_slope * STEP
		y = clampf(y, prev - lim, prev + lim)
		_push(y, s, f)
		prev = y
	_last_slope = (ys[ys.size() - 1] - ys[ys.size() - 2]) / STEP


func _linear(length: float, dy: float, s: int, f := 1) -> void:
	var y0 := _y()
	var n := maxi(int(round(length / STEP)), 1)
	for k in range(1, n + 1):
		_push(y0 + dy * float(k) / n, s, f)
	_last_slope = dy / (n * STEP)


func _rf(a: float, b: float) -> float:
	return rng.randf_range(a, b)


# ------------------------------------------------------------------ segments
func _gen_segment() -> void:
	_seg_count += 1
	var x0 := _x()
	var d := difficulty(x0)
	var amp := lerpf(float(tp.get("amp", 2.5)), float(tp.get("amp_max", 7.0)), d)
	var max_slope := lerpf(float(tp.get("max_slope", 0.55)), float(tp.get("max_slope_late", 0.85)), d)
	var weights: Dictionary = tp.get("features", {"hills": 1.0})
	var kind := _pick(weights, d)
	# surface patch decision for this segment
	var patch: Dictionary = env.get("patch", {})
	var s := SURF_BASE
	if not patch.is_empty() and x0 > 80.0 and rng.randf() < float(patch.get("chance", 0.0)) * (0.6 + d):
		s = SURF_PATCH
	var start_idx := ys.size()
	match kind:
		"flat":
			_hermite(_rf(10, 22), _y() + _rf(-0.6, 0.6), 0.0, s, max_slope)
		"bumps":
			var nb := rng.randi_range(4, 8)
			var bamp := lerpf(0.25, 0.6, d) * float(tp.get("bump_scale", 1.0))
			for i in nb:
				var up := (i % 2 == 0)
				_hermite(_rf(1.6, 2.6), _y() + (bamp if up else -bamp) * _rf(0.6, 1.0), 0.0, s, max_slope * 1.2)
			_hermite(4.0, _y(), 0.0, s, max_slope)
		"jump":
			_jump(d, max_slope)
		"bridge":
			_bridge(d, max_slope)
		"trench":
			_trench(d, max_slope)
		"climb":
			var h := amp * _rf(1.4, 2.4)
			var len := h / (max_slope * _rf(0.5, 0.62))
			_hermite(len, _y() + h, 0.0, s, max_slope)
			_hermite(_rf(8, 16), _y() + _rf(-0.5, 0.5), 0.0, s, max_slope)
		"valley":
			var h2 := amp * _rf(1.0, 1.8)
			var len2 := h2 / (max_slope * _rf(0.5, 0.65))
			_hermite(len2, _y() - h2, 0.0, s, max_slope)
			_hermite(_rf(4, 10), _y(), 0.0, s, max_slope)
			_hermite(len2 * _rf(0.9, 1.2), _y() + h2 * _rf(0.7, 1.05), 0.0, s, max_slope)
		"steps":
			var ns := rng.randi_range(3, 5)
			for i in ns:
				var sh := _rf(0.5, 1.1) * lerpf(0.8, 1.3, d)
				_hermite(_rf(1.2, 2.0), _y() + sh, 0.0, s, max_slope * 1.6)
				_hermite(_rf(2.0, 4.0), _y() + _rf(-0.1, 0.1), 0.0, s, max_slope)
		"dunes":
			var nd := rng.randi_range(2, 3)
			for i in nd:
				var dh := amp * _rf(0.8, 1.4)
				_hermite(_rf(14, 22), _y() + dh, _rf(-0.1, 0.1), s, max_slope)
				_hermite(_rf(14, 22), _y() - dh * _rf(0.85, 1.1), 0.0, s, max_slope)
		_:  # hills
			var k := rng.randi_range(3, 6)
			var sp: Array = tp.get("spacing", [8.0, 16.0])
			for i in k:
				var dx := _rf(float(sp[0]), float(sp[1]))
				var base := float(tp.get("trend", 0.0)) * (_x() + dx)
				var target := _y() + _rf(-amp, amp) - (_y() - base) * 0.3
				var lim := max_slope * 0.62 * dx
				target = clampf(target, _y() - lim, _y() + lim)
				var m1 := (target - _y()) / dx * _rf(-0.2, 0.7)
				_hermite(dx, target, m1, s, max_slope)
			_hermite(_rf(4, 8), _y() + _rf(-0.3, 0.3), 0.0, s, max_slope)
	if s == SURF_PATCH:
		pass
	_place_obstacles(start_idx, kind, d)
	_place_pickups(x0, _x(), kind)


func _pick(weights: Dictionary, d: float) -> String:
	var total := 0.0
	var items: Array = []
	for k in weights:
		var w := float(weights[k])
		if k in ["jump", "bridge", "trench", "climb", "steps"]:
			w *= lerpf(0.6, 1.5, d)
		if _seg_count < 3 and k != "hills" and k != "flat":
			w = 0.0
		items.append([k, w])
		total += w
	var r := rng.randf() * total
	for it in items:
		r -= it[1]
		if r <= 0.0:
			return it[0]
	return "hills"


func _jump(d: float, max_slope: float) -> void:
	_hermite(_rf(6, 10), _y(), 0.0, SURF_BASE, max_slope)
	var rx0 := _x()
	var rh := _rf(1.0, 1.8) * lerpf(1.0, 1.5, d)
	var rl := rh / _rf(0.32, 0.5)
	_linear(rl, rh, SURF_BASE, 1)
	ramps.append({"x0": rx0, "x1": _x(), "h": rh})
	_linear(0.5, 0.0, SURF_BASE, 1)
	var drop := _rf(1.5, 3.5) * lerpf(1.0, 1.6, d)
	_linear(1.5, -drop, SURF_BASE, 1)
	_last_slope = -0.15
	_hermite(_rf(10, 16), _y() - _rf(0.5, 1.5), -0.05, SURF_BASE, max_slope)
	_hermite(_rf(6, 10), _y(), 0.0, SURF_BASE, max_slope)


func _bridge(d: float, max_slope: float) -> void:
	_hermite(_rf(6, 10), _y(), 0.0, SURF_BASE, max_slope)
	var x0 := _x()
	var y0 := _y()
	var depth := _rf(4.0, 7.0)
	var span := _rf(10.0, 18.0) * lerpf(1.0, 1.3, d)
	_linear(2.5, -depth, SURF_BASE, 1)
	_linear(maxf(span - 5.0, 2.0), _rf(-0.4, 0.4), SURF_BASE, 1)
	var y1 := y0 + _rf(-0.6, 0.6)
	_linear(2.5, y1 - _y(), SURF_BASE, 1)
	var x1 := _x()
	_last_slope = 0.0
	bridges.append({"x0": x0, "x1": x1, "y0": y0, "y1": y1, "sag": minf(0.15 + span * 0.02, 0.5), "water": bool(env.get("bridge_water", false))})
	_hermite(_rf(6, 10), _y(), 0.0, SURF_BASE, max_slope)


func _trench(d: float, max_slope: float) -> void:
	_hermite(_rf(5, 8), _y(), 0.0, SURF_BASE, max_slope)
	var depth := _rf(1.0, 1.8) * lerpf(1.0, 1.4, d)
	_linear(depth / 0.8, -depth, SURF_BASE, 1)
	_linear(_rf(2.0, 4.0), 0.0, SURF_BASE, 1)
	_linear(depth / 0.55, depth, SURF_BASE, 1)
	_last_slope = 0.0
	_hermite(_rf(5, 8), _y(), 0.0, SURF_BASE, max_slope)


# ------------------------------------------------------------------ placement
func _place_obstacles(start_idx: int, kind: String, d: float) -> void:
	var ob: Dictionary = env.get("obstacles", {})
	if ob.is_empty() or kind in ["jump", "bridge", "trench"]:
		return
	var chance := float(ob.get("chance", 0.0)) * lerpf(0.6, 1.4, d)
	var kinds: Array = ob.get("kinds", ["rock"])
	var i := start_idx + 8
	var end := ys.size() - 8
	while i < end:
		if rng.randf() < chance * 0.04:
			var x := i * STEP
			if absf(slope_at(x)) < 0.28 and flags[i] == 0 and not _in_bridge(x):
				var k: String = kinds[rng.randi() % kinds.size()]
				var size := _rf(float(ob.get("min", 0.25)), float(ob.get("max", 0.5))) * lerpf(1.0, 1.25, d)
				obstacles.append({"kind": k, "x": x, "y": height_at(x), "size": size, "rot": rng.randf() * TAU, "seed": rng.randi()})
				i += 30
		i += 1


func _in_bridge(x: float) -> bool:
	for b in bridges:
		if x >= b.x0 - 2.0 and x <= b.x1 + 2.0:
			return true
	return false


func _coin_value(x: float) -> int:
	var tiers: Array = env.get("coin_tiers", [[0, 5, 10], [300, 10, 25], [800, 25, 50], [1500, 50, 100], [2500, 100, 250], [4000, 250, 500]])
	var lo := 5
	var hi := 10
	for t in tiers:
		if x >= float(t[0]):
			lo = int(t[1])
			hi = int(t[2])
	return hi if rng.randf() < 0.3 else lo


func _add_pickup(kind: String, x: float, y: float, value := 0) -> void:
	_pickup_id += 1
	pickups.append({"id": _pickup_id, "kind": kind, "x": x, "y": y, "value": value})


func _place_pickups(x0: float, x1: float, kind: String) -> void:
	var pk: Dictionary = env.get("pickups", {})
	# Fuel: spacing grows with distance (core tension of the run).
	while _next_fuel < x1:
		var fx := _next_fuel
		_add_pickup("fuel", fx, surface_height_at(fx) + 1.0)
		var sp := float(pk.get("fuel_base", 220.0)) + float(pk.get("fuel_growth", 0.06)) * fx
		_next_fuel += minf(sp, float(pk.get("fuel_max", 520.0))) * _rf(0.92, 1.08)
	while _next_gem < x1:
		var gx := _next_gem
		_add_pickup("gem", gx, surface_height_at(gx) + 2.2, 1)
		_next_gem += float(pk.get("gem_every", 650.0)) * _rf(0.8, 1.3)
	while _next_boost < x1:
		var bx := _next_boost
		_add_pickup("boost", bx, surface_height_at(bx) + 1.4)
		_next_boost += float(pk.get("boost_every", 260.0)) * _rf(0.8, 1.25)
	# Coin groups
	var gap: Array = pk.get("coin_gap", [26.0, 44.0])
	while _next_coins < x1:
		var cx := _next_coins
		var count := rng.randi_range(5, 9)
		var val := _coin_value(cx)
		var spacing := 1.15
		var arc := kind == "jump" and rng.randf() < 0.5
		for c in count:
			var x := cx + c * spacing
			if x > x1:
				break
			if _near_other_pickup(x):
				continue
			var y := surface_height_at(x) + 1.1
			if arc:
				y += sin(float(c) / maxf(count - 1, 1) * PI) * 1.6
			_add_pickup("coin", x, y, val)
		_next_coins += _rf(float(gap[0]), float(gap[1]))


func _near_other_pickup(x: float) -> bool:
	for i in range(pickups.size() - 1, maxi(pickups.size() - 12, -1), -1):
		var p: Dictionary = pickups[i]
		if p.kind != "coin" and absf(p.x - x) < 1.6:
			return true
	return false
