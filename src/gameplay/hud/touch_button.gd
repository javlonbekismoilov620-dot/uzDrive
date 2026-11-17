## Multi-touch aware button. Unlike regular GUI buttons (which only see the
## first touch), each instance tracks its own finger index, so the player can
## hold GAS with one thumb and tap BOOST/BRAKE with another simultaneously.
## Also supports the mouse (desktop) and is hit-tested in global coordinates.
class_name TouchButton
extends Control

signal pressed_down
signal released

var is_down := false
var _touch_index := -1
var _mouse_down := false
var hit_margin := 14.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _hit(p: Vector2) -> bool:
	return get_global_rect().grow(hit_margin).has_point(p) and is_visible_in_tree()


func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		var pos := _to_canvas(e.position)
		if e.pressed and _touch_index == -1 and _hit(pos):
			_touch_index = e.index
			_set_down(true)
			get_viewport().set_input_as_handled()
		elif not e.pressed and e.index == _touch_index:
			_touch_index = -1
			_set_down(_mouse_down)
	elif e is InputEventScreenDrag:
		if e.index == _touch_index and not _hit(_to_canvas(e.position)) and not get_global_rect().grow(80).has_point(_to_canvas(e.position)):
			_touch_index = -1
			_set_down(_mouse_down)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if e.pressed and _hit(_to_canvas(e.position)):
			_mouse_down = true
			_set_down(true)
			get_viewport().set_input_as_handled()
		elif not e.pressed and _mouse_down:
			_mouse_down = false
			_set_down(_touch_index != -1)


## Event positions in _input are in viewport coordinates; convert to the
## canvas this control lives in (identity for an untransformed CanvasLayer).
func _to_canvas(p: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * p


func _set_down(v: bool) -> void:
	if v == is_down:
		return
	is_down = v
	if v:
		pressed_down.emit()
	else:
		released.emit()
	queue_redraw()


func force_release() -> void:
	_touch_index = -1
	_mouse_down = false
	_set_down(false)
