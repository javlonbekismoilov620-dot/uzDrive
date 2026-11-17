## Labelled statistic bar with optional preview delta (upgrade / compare).
class_name StatBar
extends Control

var label := ""
var value := 0.0          ## 0..100
var preview := -1.0       ## 0..100, <0 = none
var value_text := ""
var icon_name := ""
var color := Color("3d8bff")


func _init() -> void:
	custom_minimum_size = Vector2(240, 46)


func set_data(lbl: String, v: float, txt: String, prev := -1.0, ic := "", c := Color("3d8bff")) -> void:
	label = lbl
	value = v
	value_text = txt
	preview = prev
	icon_name = ic
	color = c
	queue_redraw()


func _draw() -> void:
	var f := UI.font_bold
	var x := 0.0
	if icon_name != "":
		var tex := UI.icon(icon_name)
		if tex:
			draw_texture_rect(tex, Rect2(0, 2, 22, 22), false, UI.TEXT_DIM)
		x = 30.0
	draw_string(f, Vector2(x, 19), label, HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.6, 17, UI.TEXT_DIM)
	draw_string(UI.font_display, Vector2(0, 19), value_text, HORIZONTAL_ALIGNMENT_RIGHT, size.x, 18, UI.TEXT)
	var bar := Rect2(0, 28, size.x, 10)
	draw_rect(bar, Color(0, 0, 0, 0.35))
	var w := bar.size.x * clampf(value / 100.0, 0.0, 1.0)
	if preview >= 0.0 and preview > value:
		var pw := bar.size.x * clampf(preview / 100.0, 0.0, 1.0)
		draw_rect(Rect2(bar.position, Vector2(pw, bar.size.y)), Color("2bd576"))
	draw_rect(Rect2(bar.position, Vector2(w, bar.size.y)), color)
	if preview >= 0.0 and preview < value:
		var pw2 := bar.size.x * clampf(preview / 100.0, 0.0, 1.0)
		draw_rect(Rect2(bar.position + Vector2(pw2, 0), Vector2(w - pw2, bar.size.y)), Color("ff4d5a"))
