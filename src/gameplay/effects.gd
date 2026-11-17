## Lightweight particle effects (CPUParticles2D: safe on every mobile GPU).
class_name Effects
extends Node2D

static var _soft: Texture2D

var dust: CPUParticles2D
var smoke: CPUParticles2D
var flame: CPUParticles2D
var _burst_pool: Array[CPUParticles2D] = []
var _bi := 0


static func soft_tex() -> Texture2D:
	if _soft:
		return _soft
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length() / 16.0
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0) ** 1.6))
	_soft = ImageTexture.create_from_image(img)
	return _soft


func _ready() -> void:
	dust = _make(40, 0.8, Color(0.75, 0.62, 0.45, 0.55))
	dust.direction = Vector2(-1, -0.6)
	dust.spread = 25
	dust.initial_velocity_min = 40
	dust.initial_velocity_max = 140
	dust.gravity = Vector2(0, 120)
	dust.scale_amount_min = 0.5
	dust.scale_amount_max = 1.3
	smoke = _make(18, 1.1, Color(0.6, 0.62, 0.66, 0.35))
	smoke.direction = Vector2(-1, -0.4)
	smoke.spread = 15
	smoke.initial_velocity_min = 20
	smoke.initial_velocity_max = 50
	smoke.gravity = Vector2(0, -30)
	smoke.scale_amount_min = 0.4
	smoke.scale_amount_max = 1.0
	flame = _make(40, 0.35, Color(1.0, 0.6, 0.15, 0.9))
	flame.direction = Vector2(-1, 0)
	flame.spread = 8
	flame.initial_velocity_min = 220
	flame.initial_velocity_max = 380
	flame.gravity = Vector2.ZERO
	flame.scale_amount_min = 0.5
	flame.scale_amount_max = 1.1
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.95, 0.6, 1.0))
	g.set_color(1, Color(1.0, 0.3, 0.05, 0.0))
	flame.color_ramp = g
	flame.color = Color.WHITE
	for i in 6:
		var b := _make(24, 0.6, Color.WHITE)
		b.one_shot = true
		b.explosiveness = 1.0
		b.emitting = false
		b.spread = 180
		b.initial_velocity_min = 60
		b.initial_velocity_max = 220
		b.gravity = Vector2(0, 260)
		b.scale_amount_min = 0.25
		b.scale_amount_max = 0.6
		_burst_pool.append(b)


func _make(amount: int, life: float, c: Color) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = amount
	p.lifetime = life
	p.texture = soft_tex()
	p.color = c
	p.emitting = false
	p.local_coords = false
	var fade := Gradient.new()
	fade.set_color(0, c)
	fade.set_color(1, Color(c, 0.0))
	p.color_ramp = fade
	add_child(p)
	return p


func burst(pos: Vector2, c: Color, amount := 18) -> void:
	var b := _burst_pool[_bi]
	_bi = (_bi + 1) % _burst_pool.size()
	b.global_position = pos
	b.amount = amount
	b.color = c
	var fade := Gradient.new()
	fade.set_color(0, c)
	fade.set_color(1, Color(c, 0.0))
	b.color_ramp = fade
	b.restart()
	b.emitting = true
