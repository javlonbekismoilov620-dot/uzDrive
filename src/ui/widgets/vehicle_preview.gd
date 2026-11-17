## Showroom-style vehicle display: scales the procedural car to fit, adds a
## turntable platform + shadow, idles on its suspension and revs when tapped.
class_name VehiclePreview
extends Control

var vdef: Dictionary = {}
var animated := true
var show_platform := true
var tint := Color.WHITE
var _holder: Node2D
var _visual: VehicleVisual
var _engine: AudioStreamPlayer
var _rev_t := 0.0
var _t := 0.0


func _init() -> void:
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_PASS


func set_vehicle(def: Dictionary) -> void:
	vdef = def
	if _holder:
		_holder.queue_free()
	_holder = Node2D.new()
	add_child(_holder)
	_visual = VehicleVisual.new()
	_visual.setup(def)
	_visual.preview_mode = animated
	_visual.preview_spin = 0.0
	_visual.modulate = tint
	_holder.add_child(_visual)
	_layout()
	queue_redraw()


func _ready() -> void:
	resized.connect(_layout)
	if animated:
		gui_input.connect(_on_input)


func _on_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		rev()


func rev() -> void:
	_rev_t = 0.9
	if vdef.is_empty():
		return
	if _engine == null:
		_engine = AudioStreamPlayer.new()
		_engine.bus = "Engine"
		add_child(_engine)
	var es: Dictionary = vdef.get("engine_sound", {})
	_engine.stream = Audio.engine_stream(es.get("profile", "i4"))
	var base := float(es.get("pitch", 1.0))
	_engine.pitch_scale = base * 0.7
	_engine.volume_db = -6.0
	_engine.play()
	var tw := create_tween()
	tw.tween_property(_engine, "pitch_scale", base * 1.7, 0.35).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_engine, "pitch_scale", base * 0.75, 0.55).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(_engine.stop)


func _layout() -> void:
	if _visual == null or _visual.shape == null:
		return
	var s := _visual.shape
	var b := s.bounds
	for w in s.wheels:
		b = b.expand(w.pos + Vector2(w.r, w.r))
		b = b.expand(w.pos - Vector2(w.r, w.r))
	var avail := size * Vector2(0.86, 0.78)
	if avail.x <= 1 or avail.y <= 1:
		return
	var sc := minf(avail.x / b.size.x, avail.y / b.size.y)
	sc = minf(sc, 2.6)
	_holder.scale = Vector2(sc, sc)
	var ground_y := size.y * (0.84 if show_platform else 0.9)
	_holder.position = Vector2(size.x * 0.5 - (b.position.x + b.size.x * 0.5) * sc, ground_y - s.ground_y * sc)
	queue_redraw()


func _process(delta: float) -> void:
	if not animated or _visual == null:
		return
	_t += delta
	if _rev_t > 0.0:
		_rev_t -= delta
		var k := clampf(_rev_t / 0.9, 0.0, 1.0)
		_visual.preview_spin = 14.0 * k
		_visual.rotation = -0.035 * sin(k * PI)
	else:
		_visual.preview_spin = 0.0
		_visual.rotation = 0.0


func _draw() -> void:
	if not show_platform:
		return
	var gy := size.y * 0.84
	var cx := size.x * 0.5
	var w := size.x * 0.42
	# turntable glow
	for i in 6:
		var k := 1.0 - i / 6.0
		_draw_ellipse(Vector2(cx, gy + 6), Vector2(w * (0.7 + 0.06 * i), 18 + i * 3), Color(0.24, 0.55, 1.0, 0.05 * k))
	_draw_ellipse(Vector2(cx, gy + 4), Vector2(w * 0.78, 16), Color(0.1, 0.16, 0.3, 0.9))
	_draw_ellipse(Vector2(cx, gy + 2), Vector2(w * 0.72, 12), Color(0.16, 0.25, 0.45, 1.0))
	_draw_ellipse(Vector2(cx, gy + 2), Vector2(w * 0.55, 6), Color(0, 0, 0, 0.45))


func _draw_ellipse(c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, col)
