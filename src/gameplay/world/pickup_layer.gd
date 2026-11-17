## Draws and collects pickups (coins, fuel, gems, boost canisters).
## Uses simple distance checks in vehicle space instead of one Area2D per coin:
## hundreds of coins cost almost nothing.
class_name PickupLayer
extends Node2D

signal collected(kind: String, value: int, pos: Vector2)

const P := K.PPM
const COIN_COLORS := {
	5: [Color("c98a4b"), Color("8a5a2b")],
	10: [Color("dfe6ee"), Color("8e9aa8")],
	25: [Color("ffd23f"), Color("c8961a")],
	50: [Color("9be564"), Color("4f9a2a")],
	100: [Color("5ac8fa"), Color("1f7fb8")],
	250: [Color("c58bff"), Color("7a3fc4")],
	500: [Color("ff5d73"), Color("b8233a")],
}

var gen: TerrainGenerator
var vehicle: Vehicle
var active: Array = []
var _t := 0.0
var _scan_i := 0
var _font: Font
var magnet_m := 1.6


func setup(generator: TerrainGenerator) -> void:
	gen = generator
	_font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_t += delta
	if gen == null or vehicle == null or not is_instance_valid(vehicle):
		return
	var vx := vehicle.global_position.x / P
	_refresh_active(vx)
	_collect(delta)
	queue_redraw()


func _refresh_active(vx: float) -> void:
	active.clear()
	for p in gen.pickups:
		if p.get("taken", false):
			continue
		if p.x > vx - 25.0 and p.x < vx + 45.0:
			active.append(p)


func _collect(delta: float) -> void:
	var inv := vehicle.global_transform.affine_inverse()
	var b := vehicle.shape.bounds
	for w in vehicle.shape.wheels:
		b = b.expand(w.pos + Vector2(0, w.r))
		b = b.expand(w.pos + Vector2(w.r, 0))
		b = b.expand(w.pos - Vector2(w.r, 0))
	var grown := b.grow(0.45 * P)
	var magnet := b.grow(magnet_m * P)
	for p in active:
		var world := Vector2(p.x * P, -p.y * P)
		if p.has("fly"):
			world = p.fly
		var local := inv * world
		if grown.has_point(local):
			p.taken = true
			collected.emit(p.kind, int(p.value), world)
		elif p.kind == "coin" and magnet.has_point(local):
			var target := vehicle.global_position
			p.fly = world.lerp(target, 1.0 - exp(-delta * 9.0))


func _draw() -> void:
	for p in active:
		var pos := Vector2(p.x * P, -p.y * P)
		if p.has("fly"):
			pos = p.fly
		match p.kind:
			"coin":
				_draw_coin(pos, int(p.value), float(p.x))
			"fuel":
				_draw_fuel(pos)
			"gem":
				_draw_gem(pos)
			"boost":
				_draw_boost(pos)


func _draw_coin(pos: Vector2, value: int, phase: float) -> void:
	var cols: Array = COIN_COLORS.get(value, COIN_COLORS[5])
	var r := (0.36 + 0.03 * COIN_COLORS.keys().find(value)) * P
	var sx := absf(cos(_t * 3.0 + phase * 0.7))
	sx = maxf(sx, 0.18)
	draw_set_transform(pos, 0.0, Vector2(sx, 1.0))
	draw_circle(Vector2.ZERO, r, cols[1])
	draw_circle(Vector2(0, -1.5), r * 0.86, cols[0])
	draw_circle(Vector2(0, -1.5), r * 0.62, cols[0].darkened(0.08))
	if sx > 0.55:
		var txt := str(value)
		var fs := 15 if value < 100 else 13
		draw_string(_font, Vector2(-r, fs * 0.36 - 1.5), txt, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs, cols[1].darkened(0.35))
	draw_set_transform(Vector2.ZERO)
	draw_circle(pos + Vector2(-r * 0.35 * sx, -r * 0.45), r * 0.14, Color(1, 1, 1, 0.75))


func _draw_fuel(pos: Vector2) -> void:
	var bob := sin(_t * 3.0) * 4.0
	var p := pos + Vector2(0, bob)
	var w := 0.75 * P
	var h := 0.95 * P
	draw_circle(p, 0.9 * P, Color(1.0, 0.4, 0.3, 0.18 + 0.08 * sin(_t * 5.0)))
	var body := Rect2(p.x - w * 0.5, p.y - h * 0.5, w, h)
	draw_rect(body, Color("e63946"))
	draw_rect(Rect2(body.position + Vector2(3, 3), Vector2(w * 0.35, h - 6)), Color("ff6b6b"))
	draw_rect(Rect2(p.x - w * 0.15, p.y - h * 0.5 - 7, w * 0.3, 8), Color("2b2d42"))
	draw_rect(Rect2(p.x + w * 0.12, p.y - h * 0.5 - 4, w * 0.3, 6), Color("2b2d42"))
	draw_string(_font, Vector2(body.position.x, p.y + 8), "F", HORIZONTAL_ALIGNMENT_CENTER, w, 22, Color.WHITE)


func _draw_gem(pos: Vector2) -> void:
	var p := pos + Vector2(0, sin(_t * 2.5) * 5.0)
	var s := 0.45 * P
	draw_circle(p, s * 1.6, Color(0.4, 0.9, 1.0, 0.15 + 0.1 * sin(_t * 4.0)))
	var pts := PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.85, -s * 0.3), p + Vector2(0, s * 1.1), p + Vector2(-s * 0.85, -s * 0.3)])
	draw_colored_polygon(pts, Color("38d9f5"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(s * 0.85, -s * 0.3), p + Vector2(0, -s * 0.15)]), Color("a5f3ff"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 0.85, -s * 0.3), p + Vector2(0, -s * 0.15), p + Vector2(0, s * 1.1)]), Color("1aa6c8"))
	var tw := absf(sin(_t * 3.0))
	draw_line(p + Vector2(s * 0.9, -s * 1.1) - Vector2(5, 0) * tw, p + Vector2(s * 0.9, -s * 1.1) + Vector2(5, 0) * tw, Color.WHITE, 2.0)
	draw_line(p + Vector2(s * 0.9, -s * 1.1) - Vector2(0, 5) * tw, p + Vector2(s * 0.9, -s * 1.1) + Vector2(0, 5) * tw, Color.WHITE, 2.0)


func _draw_boost(pos: Vector2) -> void:
	var p := pos + Vector2(0, sin(_t * 3.5) * 4.0)
	var r := 0.48 * P
	draw_circle(p, r * 1.5, Color(0.3, 0.6, 1.0, 0.18))
	draw_circle(p, r, Color("2f6bff"))
	draw_circle(p, r * 0.82, Color("4d8bff"))
	var bolt := PackedVector2Array([p + Vector2(-2, -r * 0.7), p + Vector2(r * 0.35, -r * 0.7), p + Vector2(r * 0.05, -r * 0.1), p + Vector2(r * 0.4, -r * 0.1), p + Vector2(-r * 0.25, r * 0.75), p + Vector2(-r * 0.05, r * 0.08), p + Vector2(-r * 0.4, r * 0.08)])
	draw_colored_polygon(bolt, Color("fff36b"))
