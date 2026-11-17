## Draws one tyre + rim. Rotated by the owner to show wheel spin.
class_name WheelVisual
extends Node2D

var radius := 12.0
var rim := "alloy5"
var tire := "street"
var rim_col := Color("dfe7ee")


func setup(w: Dictionary) -> void:
	radius = w.r
	rim = w.rim
	tire = w.tire
	rim_col = w.rim_col
	queue_redraw()


func _draw() -> void:
	var r := radius
	var tire_col := Color("1b1d22")
	draw_circle(Vector2.ZERO, r, tire_col)
	# Tread blocks for off-road tyres
	if tire == "offroad" or tire == "mud":
		var n := 14 if tire == "offroad" else 10
		for i in n:
			var a := TAU * i / n
			var d := Vector2(cos(a), sin(a))
			var t := d.orthogonal()
			var o := d * r
			var bw := r * (0.16 if tire == "offroad" else 0.24)
			draw_colored_polygon(PackedVector2Array([o - t * bw, o + t * bw, o + t * bw * 0.8 + d * r * 0.1, o - t * bw * 0.8 + d * r * 0.1]), tire_col)
	draw_arc(Vector2.ZERO, r * 0.93, 0, TAU, 32, Color("2b2f36"), r * 0.08)
	var rr := r * (0.62 if tire != "slick" else 0.68)
	if tire == "whitewall":
		draw_circle(Vector2.ZERO, rr * 1.18, Color("f1efe6"))
	var c := rim_col
	var dark := c.darkened(0.45)
	match rim:
		"steel":
			draw_circle(Vector2.ZERO, rr, c.darkened(0.15))
			draw_circle(Vector2.ZERO, rr * 0.82, c.darkened(0.3))
			for i in 6:
				var a := TAU * i / 6.0
				draw_circle(Vector2(cos(a), sin(a)) * rr * 0.55, rr * 0.11, dark)
			draw_circle(Vector2.ZERO, rr * 0.3, c)
		"multi":
			draw_circle(Vector2.ZERO, rr, dark)
			for i in 10:
				var a := TAU * i / 10.0
				draw_line(Vector2.ZERO, Vector2(cos(a), sin(a)) * rr * 0.95, c, maxf(1.5, rr * 0.12))
			draw_circle(Vector2.ZERO, rr * 0.25, c.lightened(0.2))
		"sport":
			draw_circle(Vector2.ZERO, rr, Color("15171b"))
			for i in 5:
				var a := TAU * i / 5.0
				var d := Vector2(cos(a), sin(a))
				var t := d.orthogonal()
				draw_colored_polygon(PackedVector2Array([t * rr * 0.12, d * rr * 0.97 + t * rr * 0.22, d * rr * 0.97 - t * rr * 0.04, -t * rr * 0.12]), c)
			draw_circle(Vector2.ZERO, rr * 0.22, c.darkened(0.2))
			draw_arc(Vector2.ZERO, rr * 0.98, 0, TAU, 28, c, maxf(1.0, rr * 0.08))
		"offroad":
			draw_circle(Vector2.ZERO, rr, c.darkened(0.1))
			draw_arc(Vector2.ZERO, rr * 0.85, 0, TAU, 24, dark, rr * 0.12)
			for i in 8:
				var a := TAU * i / 8.0
				draw_circle(Vector2(cos(a), sin(a)) * rr * 0.86, rr * 0.07, c.lightened(0.3))
			for i in 5:
				var a := TAU * i / 5.0
				draw_circle(Vector2(cos(a), sin(a)) * rr * 0.45, rr * 0.16, dark)
			draw_circle(Vector2.ZERO, rr * 0.22, c.lightened(0.1))
		"chrome":
			draw_circle(Vector2.ZERO, rr, c.lightened(0.15))
			draw_circle(Vector2.ZERO, rr * 0.75, c.darkened(0.15))
			for i in 12:
				var a := TAU * i / 12.0
				draw_line(Vector2(cos(a), sin(a)) * rr * 0.3, Vector2(cos(a), sin(a)) * rr * 0.74, c.lightened(0.3), maxf(1.0, rr * 0.06))
			draw_circle(Vector2.ZERO, rr * 0.3, c.lightened(0.3))
		"classic":
			draw_circle(Vector2.ZERO, rr, c.darkened(0.25))
			draw_circle(Vector2.ZERO, rr * 0.7, c.lightened(0.1))
			draw_circle(Vector2.ZERO, rr * 0.35, c.darkened(0.1))
			draw_line(Vector2(-rr * 0.6, 0), Vector2(rr * 0.6, 0), dark, maxf(1.0, rr * 0.08))
		"turbine":
			draw_circle(Vector2.ZERO, rr, c.darkened(0.2))
			for i in 9:
				var a := TAU * i / 9.0
				var d := Vector2(cos(a), sin(a))
				draw_colored_polygon(PackedVector2Array([d * rr * 0.25, d.rotated(0.5) * rr * 0.95, d.rotated(0.75) * rr * 0.95]), c.lightened(0.15))
			draw_circle(Vector2.ZERO, rr * 0.22, dark)
		"kart":
			draw_circle(Vector2.ZERO, rr, c)
			draw_circle(Vector2.ZERO, rr * 0.4, dark)
		_:  # alloy5
			draw_circle(Vector2.ZERO, rr, dark)
			for i in 5:
				var a := TAU * i / 5.0
				var d := Vector2(cos(a), sin(a))
				var t := d.orthogonal()
				draw_colored_polygon(PackedVector2Array([t * rr * 0.16, d * rr * 0.96 + t * rr * 0.2, d * rr * 0.96 - t * rr * 0.2, -t * rr * 0.16]), c)
			draw_circle(Vector2.ZERO, rr * 0.25, c.lightened(0.15))
	# hub nut + subtle highlight (rotates with the wheel, adds motion read)
	draw_circle(Vector2.ZERO, maxf(1.5, rr * 0.09), dark)
	draw_arc(Vector2.ZERO, r * 0.98, -2.4, -1.2, 10, Color(1, 1, 1, 0.08), r * 0.05)
