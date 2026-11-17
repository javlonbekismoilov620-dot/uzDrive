## Small red notification badge with a count.
class_name Badge
extends Control

var count := 0


func set_count(n: int) -> void:
	count = n
	visible = n > 0
	queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(30, 30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if count <= 0:
		return
	draw_circle(Vector2(15, 15), 15, UI.RED)
	draw_arc(Vector2(15, 15), 15, 0, TAU, 24, Color.WHITE, 2.0, true)
	draw_string(UI.font_bold, Vector2(0, 21), str(mini(count, 9)), HORIZONTAL_ALIGNMENT_CENTER, 30, 17, Color.WHITE)
