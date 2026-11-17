## Renders a vehicle (body layers + wheels) from a VehicleShape.
## Used in gameplay (driven by Vehicle physics) and in menus (idle animation).
class_name VehicleVisual
extends Node2D

var shape: VehicleShape
var wheel_nodes: Array[WheelVisual] = []
var _body: Node2D
var _front: Node2D
var preview_mode := false
var _t := 0.0
var preview_spin := 6.0


func setup(vdef: Dictionary) -> void:
	shape = VehicleShape.get_for(vdef)
	for c in get_children():
		c.queue_free()
	wheel_nodes.clear()
	_body = _Layer.new()
	_body.owner_visual = self
	_body.layer = 0
	add_child(_body)
	for w in shape.wheels:
		var wn := WheelVisual.new()
		wn.setup(w)
		wn.position = w.pos
		add_child(wn)
		wheel_nodes.append(wn)
	_front = _Layer.new()
	_front.owner_visual = self
	_front.layer = 1
	add_child(_front)


## Set wheel offsets (local positions) and rotation angles from physics.
func set_wheels(positions: Array, angles: Array) -> void:
	for i in wheel_nodes.size():
		wheel_nodes[i].position = positions[i]
		wheel_nodes[i].rotation = angles[i]


func _process(delta: float) -> void:
	if not preview_mode or shape == null:
		return
	_t += delta
	for i in wheel_nodes.size():
		var w: Dictionary = shape.wheels[i]
		wheel_nodes[i].rotation += delta * preview_spin * (16.0 / maxf(w.r, 4.0))
		wheel_nodes[i].position = w.pos
	# gentle idle bob of the body on its suspension
	_body.position.y = sin(_t * 9.0) * 0.6
	_front.position.y = _body.position.y


class _Layer:
	extends Node2D
	var owner_visual: VehicleVisual
	var layer := 0

	func _draw() -> void:
		var s := owner_visual.shape
		if s == null:
			return
		if layer == 0:
			for p in s.parts_back:
				draw_polygon(p.poly, p.cols)
			for p in s.parts:
				draw_polygon(p.poly, p.cols)
			if s.outline.size() > 2:
				draw_polyline(s.outline, s.outline_col, 1.6, true)
			for l in s.lines:
				if not l.front:
					draw_line(l.a, l.b, l.c, l.w, true)
		else:
			for p in s.parts_front:
				draw_polygon(p.poly, p.cols)
			for l in s.lines:
				if l.front:
					draw_line(l.a, l.b, l.c, l.w, true)
