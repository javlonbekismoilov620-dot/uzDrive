## Lightweight particle effects built on SimpleParticles (portable to every GPU and WebGL 2).
class_name Effects
extends Node2D

static var _soft: Texture2D

var dust: SimpleParticles
var smoke: SimpleParticles
var flame: SimpleParticles
var sparks: SimpleParticles


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
	flame = _make(40, 0.35, Color(1.0, 0.95, 0.6, 1.0))
	flame.end_color = Color(1.0, 0.3, 0.05, 0.0)
	flame.direction = Vector2(-1, 0)
	flame.spread = 8
	flame.initial_velocity_min = 220
	flame.initial_velocity_max = 380
	flame.scale_amount_min = 0.5
	flame.scale_amount_max = 1.1
	sparks = _make(160, 0.6, Color.WHITE)
	sparks.initial_velocity_min = 60
	sparks.initial_velocity_max = 220
	sparks.gravity = Vector2(0, 260)
	sparks.scale_amount_min = 0.25
	sparks.scale_amount_max = 0.6


func _make(amount: int, life: float, c: Color) -> SimpleParticles:
	var p := SimpleParticles.new()
	p.amount = amount
	p.lifetime = life
	p.texture = soft_tex()
	p.color = c
	p.end_color = Color(c, 0.0)
	add_child(p)
	return p


func burst(pos: Vector2, c: Color, amount := 18) -> void:
	sparks.color = c
	sparks.end_color = Color(c, 0.0)
	sparks.burst(pos, amount)
