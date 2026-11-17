## Lightweight CPU particle emitter drawn with plain canvas calls.
## Replaces CPUParticles2D because per-particle colours render black on some
## WebGL 2 / GLES3 drivers (seen in the iPhone Safari web build); canvas draw
## calls with vertex modulation work on every renderer. API mirrors the few
## CPUParticles2D properties the game uses.
class_name SimpleParticles
extends Node2D

var emitting := false
var amount := 20
var lifetime := 1.0
var direction := Vector2.RIGHT
var spread := 20.0                 ## degrees
var gravity := Vector2.ZERO
var initial_velocity_min := 20.0
var initial_velocity_max := 60.0
var scale_amount_min := 1.0
var scale_amount_max := 1.0
var color := Color.WHITE
var end_color := Color(1, 1, 1, 0)  ## colour at end of life (alpha fade by default)
var texture: Texture2D             ## null = draw dots of radius `scale`
var emission_rect_extents := Vector2.ZERO
var spin := 0.0                    ## max angular speed (rad/s), drawn as ellipse rotation

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _age := PackedFloat32Array()
var _size := PackedFloat32Array()
var _rot := PackedFloat32Array()
var _rotv := PackedFloat32Array()
var _acc := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


## Instantly emits `n` particles at a global position (one-shot burst).
func burst(at: Vector2, n: int) -> void:
	for i in n:
		_spawn(at, true)


## Simulates `seconds` so ambient effects (weather) start already populated.
func prewarm(seconds: float) -> void:
	var step := 1.0 / 30.0
	var t := 0.0
	while t < seconds:
		_step(step)
		t += step


func _spawn(at: Vector2, omni := false) -> void:
	if _pos.size() >= amount * 2:
		return
	var p := at
	if emission_rect_extents != Vector2.ZERO:
		p += Vector2(_rng.randf_range(-1, 1) * emission_rect_extents.x, _rng.randf_range(-1, 1) * emission_rect_extents.y)
	var ang := _rng.randf() * TAU if omni else direction.angle() + deg_to_rad(_rng.randf_range(-spread, spread))
	_pos.append(p)
	_vel.append(Vector2(cos(ang), sin(ang)) * _rng.randf_range(initial_velocity_min, initial_velocity_max))
	_age.append(0.0)
	_size.append(_rng.randf_range(scale_amount_min, scale_amount_max))
	_rot.append(_rng.randf() * TAU)
	_rotv.append(_rng.randf_range(-spin, spin))


func _process(delta: float) -> void:
	_step(delta)
	queue_redraw()


func _step(delta: float) -> void:
	if emitting and lifetime > 0.0:
		_acc += delta * float(amount) / lifetime
		var origin := global_position
		while _acc >= 1.0:
			_acc -= 1.0
			_spawn(origin)
	else:
		_acc = 0.0
	var i := 0
	while i < _pos.size():
		_age[i] += delta
		if _age[i] >= lifetime:
			_remove(i)
			continue
		_vel[i] += gravity * delta
		_pos[i] += _vel[i] * delta
		_rot[i] += _rotv[i] * delta
		i += 1


func _remove(i: int) -> void:
	var last := _pos.size() - 1
	_pos[i] = _pos[last]
	_vel[i] = _vel[last]
	_age[i] = _age[last]
	_size[i] = _size[last]
	_rot[i] = _rot[last]
	_rotv[i] = _rotv[last]
	_pos.resize(last)
	_vel.resize(last)
	_age.resize(last)
	_size.resize(last)
	_rot.resize(last)
	_rotv.resize(last)


func _draw() -> void:
	if _pos.is_empty():
		return
	draw_set_transform_matrix(get_global_transform().affine_inverse())
	var tex_size := texture.get_size() if texture else Vector2.ONE
	for i in _pos.size():
		var t := _age[i] / lifetime
		var c := color.lerp(end_color, t)
		var s := _size[i]
		if texture:
			var sz := tex_size * s
			draw_texture_rect(texture, Rect2(_pos[i] - sz * 0.5, sz), false, c)
		elif spin > 0.0:
			var d := Vector2(cos(_rot[i]), sin(_rot[i])) * s
			var n := d.orthogonal() * 0.5
			draw_colored_polygon(PackedVector2Array([_pos[i] - d, _pos[i] + n, _pos[i] + d, _pos[i] - n]), c)
		else:
			draw_circle(_pos[i], s, c)
