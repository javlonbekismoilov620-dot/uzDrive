## Builds original procedural vehicle artwork + physics geometry from data.
##
## Every vehicle in data/vehicles.json has a `body` block (archetype + proportions)
## and a `style` block (paint, accessories, rims). This class turns those into:
##   * layered polygons for drawing (shared by gameplay, garage and shop previews)
##   * wheel/suspension mount points for the physics
##   * a convex collision hull and a roof crash sensor
## Work is done in "body space" (pixels, y-up, origin at rear-bottom of the body)
## and converted to node-local space (y-down, origin near the body centre).
class_name VehicleShape
extends RefCounted

const P := K.PPM

## Archetype proportions (metres). Per-vehicle `body` entries override any key.
const TYPES := {
	"micro": {"L": 3.5, "H": 1.5, "belt": 0.84, "nose": 0.62, "tail": 0.8, "hood": 0.55, "ws": 0.62, "rw": 0.3, "trunk": 0.03, "wr": 0.27, "clear": 0.14, "oh_r": 0.55, "oh_f": 0.62, "r_roof": 0.42, "r_nose": 0.28, "r_tail": 0.2},
	"hatch": {"L": 4.2, "H": 1.45, "belt": 0.86, "nose": 0.62, "tail": 0.83, "hood": 0.85, "ws": 0.78, "rw": 0.42, "trunk": 0.05, "wr": 0.3, "clear": 0.15, "oh_r": 0.7, "oh_f": 0.85, "r_roof": 0.45, "r_nose": 0.3, "r_tail": 0.2},
	"sedan": {"L": 4.5, "H": 1.45, "belt": 0.86, "nose": 0.66, "tail": 0.86, "hood": 1.05, "ws": 0.8, "rw": 0.58, "trunk": 0.65, "wr": 0.31, "clear": 0.15, "oh_r": 0.95, "oh_f": 0.9, "r_roof": 0.5, "r_nose": 0.3, "r_tail": 0.22},
	"coupe": {"L": 4.4, "H": 1.28, "belt": 0.78, "nose": 0.52, "tail": 0.74, "hood": 1.35, "ws": 0.85, "rw": 0.9, "trunk": 0.35, "wr": 0.33, "clear": 0.12, "oh_r": 0.9, "oh_f": 0.85, "r_roof": 0.45, "r_nose": 0.28, "r_tail": 0.2},
	"muscle": {"L": 4.8, "H": 1.32, "belt": 0.84, "nose": 0.68, "tail": 0.82, "hood": 1.55, "ws": 0.72, "rw": 0.8, "trunk": 0.5, "wr": 0.36, "clear": 0.14, "oh_r": 1.0, "oh_f": 0.95, "r_roof": 0.35, "r_nose": 0.16, "r_tail": 0.14},
	"super": {"L": 4.5, "H": 1.13, "belt": 0.72, "nose": 0.42, "tail": 0.76, "hood": 1.0, "ws": 1.05, "rw": 1.3, "trunk": 0.22, "wr": 0.34, "clear": 0.11, "oh_r": 0.9, "oh_f": 1.0, "r_roof": 0.4, "r_nose": 0.3, "r_tail": 0.16},
	"crossover": {"L": 4.4, "H": 1.66, "belt": 0.99, "nose": 0.8, "tail": 0.97, "hood": 0.95, "ws": 0.78, "rw": 0.36, "trunk": 0.05, "wr": 0.36, "clear": 0.2, "oh_r": 0.8, "oh_f": 0.85, "r_roof": 0.4, "r_nose": 0.3, "r_tail": 0.22},
	"suv": {"L": 4.9, "H": 1.86, "belt": 1.08, "nose": 0.92, "tail": 1.06, "hood": 1.05, "ws": 0.66, "rw": 0.18, "trunk": 0.03, "wr": 0.4, "clear": 0.24, "oh_r": 0.9, "oh_f": 0.85, "r_roof": 0.25, "r_nose": 0.22, "r_tail": 0.16},
	"mpv": {"L": 4.65, "H": 1.66, "belt": 0.96, "nose": 0.76, "tail": 0.96, "hood": 0.8, "ws": 0.98, "rw": 0.26, "trunk": 0.03, "wr": 0.33, "clear": 0.16, "oh_r": 0.85, "oh_f": 0.85, "r_roof": 0.35, "r_nose": 0.3, "r_tail": 0.2},
	"microvan": {"L": 3.5, "H": 1.92, "belt": 1.0, "nose": 0.82, "tail": 1.0, "hood": 0.2, "ws": 0.42, "rw": 0.08, "trunk": 0.03, "wr": 0.26, "clear": 0.17, "oh_r": 0.45, "oh_f": 0.5, "r_roof": 0.25, "r_nose": 0.2, "r_tail": 0.12},
	"van": {"L": 5.3, "H": 2.3, "belt": 1.15, "nose": 0.92, "tail": 1.15, "hood": 0.72, "ws": 0.48, "rw": 0.06, "trunk": 0.03, "wr": 0.37, "clear": 0.2, "oh_r": 0.9, "oh_f": 0.85, "r_roof": 0.2, "r_nose": 0.3, "r_tail": 0.1},
	"bus": {"L": 7.4, "H": 2.75, "belt": 1.2, "nose": 1.0, "tail": 1.2, "hood": 0.12, "ws": 0.3, "rw": 0.06, "trunk": 0.03, "wr": 0.46, "clear": 0.26, "oh_r": 1.6, "oh_f": 1.25, "r_roof": 0.3, "r_nose": 0.18, "r_tail": 0.14},
	"pickup": {"L": 5.4, "H": 1.86, "belt": 1.08, "nose": 0.96, "tail": 1.08, "hood": 1.25, "ws": 0.62, "rw": 0.07, "trunk": 1.85, "wr": 0.41, "clear": 0.25, "oh_r": 1.1, "oh_f": 0.92, "r_roof": 0.22, "r_nose": 0.2, "r_tail": 0.08},
	"micro_pickup": {"L": 3.5, "H": 1.86, "belt": 0.95, "nose": 0.8, "tail": 0.95, "hood": 0.18, "ws": 0.42, "rw": 0.05, "trunk": 1.62, "wr": 0.26, "clear": 0.17, "oh_r": 0.45, "oh_f": 0.5, "r_roof": 0.2, "r_nose": 0.18, "r_tail": 0.06},
	"beetle": {"L": 4.05, "H": 1.5, "belt": 0.8, "nose": 0.62, "tail": 0.72, "hood": 0.95, "ws": 0.62, "rw": 0.95, "trunk": 0.02, "wr": 0.32, "clear": 0.16, "oh_r": 0.75, "oh_f": 0.78, "r_roof": 1.0, "r_nose": 0.5, "r_tail": 0.5},
	"classic": {"L": 4.8, "H": 1.5, "belt": 0.86, "nose": 0.74, "tail": 0.86, "hood": 1.25, "ws": 0.6, "rw": 0.55, "trunk": 0.95, "wr": 0.33, "clear": 0.17, "oh_r": 1.0, "oh_f": 0.95, "r_roof": 0.28, "r_nose": 0.14, "r_tail": 0.12},
	"finned": {"L": 5.4, "H": 1.38, "belt": 0.8, "nose": 0.68, "tail": 0.82, "hood": 1.5, "ws": 0.62, "rw": 0.62, "trunk": 1.2, "wr": 0.36, "clear": 0.16, "oh_r": 1.25, "oh_f": 1.05, "r_roof": 0.3, "r_nose": 0.2, "r_tail": 0.1},
	"boxy4x4": {"L": 3.75, "H": 1.66, "belt": 0.98, "nose": 0.84, "tail": 0.98, "hood": 0.95, "ws": 0.56, "rw": 0.1, "trunk": 0.03, "wr": 0.37, "clear": 0.23, "oh_r": 0.65, "oh_f": 0.7, "r_roof": 0.14, "r_nose": 0.12, "r_tail": 0.08},
	"crawler": {"L": 3.9, "H": 1.6, "belt": 0.95, "nose": 0.8, "tail": 0.95, "hood": 0.95, "ws": 0.55, "rw": 0.12, "trunk": 0.03, "wr": 0.56, "clear": 0.55, "oh_r": 0.55, "oh_f": 0.6, "r_roof": 0.18, "r_nose": 0.14, "r_tail": 0.1},
	"trophy": {"L": 5.5, "H": 1.6, "belt": 0.9, "nose": 0.7, "tail": 0.9, "hood": 1.45, "ws": 0.72, "rw": 0.1, "trunk": 1.6, "wr": 0.48, "clear": 0.52, "oh_r": 1.05, "oh_f": 1.05, "r_roof": 0.25, "r_nose": 0.3, "r_tail": 0.1},
	"monster": {"L": 4.6, "H": 1.7, "belt": 1.0, "nose": 0.86, "tail": 1.0, "hood": 1.15, "ws": 0.6, "rw": 0.08, "trunk": 1.45, "wr": 0.88, "clear": 1.1, "oh_r": 0.75, "oh_f": 0.75, "r_roof": 0.25, "r_nose": 0.22, "r_tail": 0.1},
	"buggy": {"L": 3.6, "H": 1.55, "belt": 0.62, "nose": 0.5, "tail": 0.7, "hood": 0.9, "ws": 0.6, "rw": 0.5, "trunk": 0.4, "wr": 0.42, "clear": 0.4, "oh_r": 0.55, "oh_f": 0.55, "r_roof": 0.2, "r_nose": 0.25, "r_tail": 0.1},
	"kart": {"L": 2.3, "H": 1.0, "belt": 0.35, "nose": 0.28, "tail": 0.35, "hood": 0.7, "ws": 0.2, "rw": 0.2, "trunk": 0.3, "wr": 0.22, "clear": 0.08, "oh_r": 0.3, "oh_f": 0.32, "r_roof": 0.1, "r_nose": 0.12, "r_tail": 0.08},
	"tractor": {"L": 3.9, "H": 2.45, "belt": 1.15, "nose": 1.05, "tail": 1.0, "hood": 1.5, "ws": 0.08, "rw": 0.05, "trunk": 0.25, "wr": 0.78, "wr_f": 0.45, "clear": 0.5, "oh_r": 0.85, "oh_f": 0.55, "r_roof": 0.12, "r_nose": 0.2, "r_tail": 0.1},
	"rover": {"L": 4.0, "H": 1.25, "belt": 0.62, "nose": 0.5, "tail": 0.6, "hood": 0.9, "ws": 0.5, "rw": 0.5, "trunk": 0.3, "wr": 0.42, "clear": 0.45, "oh_r": 0.5, "oh_f": 0.5, "r_roof": 0.2, "r_nose": 0.3, "r_tail": 0.2},
}

const DEFAULT_TRIM := Color("1c2129")
const DEFAULT_GLASS := Color("23384f")
const CHROME := Color("dfe7ee")
const TIRE := Color("1a1c20")

static var _cache := {}

# ---------------- outputs ----------------
var parts_back: Array = []     ## drawn before wheels: [{poly, cols}] (cols = PackedColorArray)
var parts: Array = []          ## body and details
var parts_front: Array = []    ## drawn after wheels (flares, guards)
var lines: Array = []          ## [{a, b, w, c}]
var wheels: Array = []         ## [{pos, r, mount, travel, driven, rim, tire, rim_col}]
var hull := PackedVector2Array()
var roof_rect := Rect2()
var bounds := Rect2()
var exhaust := Vector2()
var headlight := Vector2()
var com := Vector2()
var ground_y := 0.0            ## local y of the ground at static ride height
var wheelbase_px := 0.0
var outline := PackedVector2Array()
var outline_col := Color.BLACK

var _p: Dictionary
var _st: Dictionary
var _type := "sedan"
var _L := 4.0
var _H := 1.4
var _origin := Vector2()       ## body-space point mapped to local (0,0)


static func get_for(vdef: Dictionary) -> VehicleShape:
	var key: String = vdef.get("id", "")
	if key != "" and _cache.has(key):
		return _cache[key]
	var s := VehicleShape.new()
	s._build(vdef)
	if key != "":
		_cache[key] = s
	return s


static func clear_cache() -> void:
	_cache.clear()


# ------------------------------------------------------------------
func _build(vdef: Dictionary) -> void:
	var body: Dictionary = vdef.get("body", {})
	_type = body.get("type", "sedan")
	_p = (TYPES.get(_type, TYPES["sedan"]) as Dictionary).duplicate()
	for k in body:
		if k != "type":
			_p[k] = body[k]
	_st = vdef.get("style", {})
	_L = float(_p.L)
	_H = float(_p.H)
	var travel := float(vdef.get("handling", {}).get("travel", 0.25))
	var drive: String = vdef.get("specs", {}).get("drive", "rwd")

	# Local origin: horizontally centred, vertically around the belt line.
	_origin = Vector2(_L * 0.5, float(_p.belt) * 0.7) * P

	var col := Util.col(_st.get("color", "#d23c3c"))
	var col2 := Util.col(_st.get("color2", ""), col.lightened(0.25))
	var trim := Util.col(_st.get("trim", ""), DEFAULT_TRIM)
	var glass := Util.col(_st.get("glass", ""), DEFAULT_GLASS)

	# ---- wheels (body space, metres) ----
	var wr := float(_p.wr)
	var wr_f := float(_p.get("wr_f", wr))
	var clear := float(_p.clear)
	var xr := float(_p.oh_r)
	var xf := _L - float(_p.oh_f)
	var wheel_specs := [[xr, wr], [xf, wr_f]]
	if _type == "rover":
		wheel_specs = [[xr, wr], [(xr + xf) * 0.5, wr], [xf, wr]]
	elif int(_p.get("axles", 2)) == 3:
		wheel_specs = [[xr, wr], [xr + wr * 2.25, wr], [xf, wr_f]]

	# ---- outline ----
	var ol := _outline()
	var body_poly := Util.rounded_poly(ol.pts, ol.radii, 5)

	# Wheel wells cut out of the body
	var wells: Array[PackedVector2Array] = []
	var body_cut := body_poly
	for ws in wheel_specs:
		var r_m: float = ws[1]
		var c := Vector2(ws[0], r_m - clear) * P
		var ra := (r_m + 0.05 + travel * 0.35) * P
		var circ := Util.circle_poly(c, ra, 28)
		var inter := Geometry2D.intersect_polygons(body_cut, circ)
		for ip in inter:
			wells.append(ip)
		var clipped := Geometry2D.clip_polygons(body_cut, circ)
		if clipped.size() > 0:
			body_cut = Util.largest(clipped)

	var well_col := trim.darkened(0.55)
	for w in wells:
		_add(parts_back, w, well_col)

	var open_top: bool = _st.get("open", false) or _type in ["buggy", "kart", "tractor", "rover"]
	var belt := float(_p.belt) * P

	# ---- special frames drawn behind body ----
	if _type == "buggy":
		_buggy_frame(trim, col2)
	elif _type == "rover":
		_rover_extras(col, col2, trim)

	# ---- main paint with vertical gradient ----
	var paint_poly := body_cut
	if open_top and _type != "tractor":
		var upper_cut := Geometry2D.clip_polygons(body_cut, Util.rect_poly(-50, belt + 0.06 * P, _L * P + 50, _H * P + 50))
		if upper_cut.size() > 0:
			paint_poly = Util.largest(upper_cut)
	_add_grad(parts, paint_poly, col.lightened(0.18), col, col.darkened(0.32))
	outline = _txp(paint_poly)
	outline.append(outline[0])
	outline_col = col.darkened(0.55)

	# Upper body (two-tone roof)
	if _st.has("two_tone") and not open_top:
		var tt := Util.col(_st.two_tone)
		for pp in Geometry2D.intersect_polygons(paint_poly, Util.rect_poly(-50, belt + 0.05 * P, _L * P + 50, _H * P + 50)):
			_add_grad(parts, pp, tt.lightened(0.15), tt, tt.darkened(0.2))

	# ---- glass ----
	if not open_top:
		_glass(paint_poly, glass, col)

	# ---- lower trim / bumpers ----
	var trim_h := float(_p.get("trim_h", 0.16)) * P
	var bumper_col := CHROME if _st.get("chrome", false) else trim
	for pp in Geometry2D.intersect_polygons(paint_poly, Util.rect_poly(-50, -50, _L * P + 50, trim_h)):
		_add_grad(parts, pp, bumper_col.lightened(0.15), bumper_col, bumper_col.darkened(0.3))

	# ---- stripes ----
	_stripes(paint_poly)

	# ---- belt highlight ----
	for pp in Geometry2D.intersect_polygons(paint_poly, Util.rect_poly(-50, belt - 0.05 * P, _L * P + 50, belt - 0.015 * P)):
		_add(parts, pp, Color(1, 1, 1, 0.16))

	# ---- lights, grille, handles, doors ----
	_lights_and_details(paint_poly, trim, col)

	# ---- accessories ----
	_accessories(col, col2, trim)

	# ---- driver ----
	_driver(open_top)

	# ---- wheels output (convert to local) ----
	for i in wheel_specs.size():
		var ws2 = wheel_specs[i]
		var r_m2: float = ws2[1]
		var static_c := Vector2(ws2[0], r_m2 - clear) * P
		var mount_c := static_c + Vector2(0, travel * 0.55 * P)
		var driven := true
		if drive == "fwd":
			driven = i == wheel_specs.size() - 1
		elif drive == "rwd":
			driven = i < wheel_specs.size() - 1
		wheels.append({
			"pos": _tx(static_c),
			"mount": _tx(mount_c),
			"r": r_m2 * P,
			"travel": travel * P,
			"driven": driven,
			"rim": _st.get("rims", "alloy5"),
			"tire": _st.get("tire", "street"),
			"rim_col": Util.col(_st.get("rim_color", ""), CHROME),
		})
	wheelbase_px = absf(wheels[-1].pos.x - wheels[0].pos.x)
	ground_y = _tx(Vector2(0, -clear * P)).y + 0.0
	# ground below wheels: wheel bottom
	ground_y = wheels[0].pos.y + wheels[0].r

	# ---- physics geometry ----
	var full := body_poly
	var hull_src := PackedVector2Array()
	for p in full:
		hull_src.append(_tx(p))
	hull = Geometry2D.convex_hull(hull_src)
	if hull.size() > 1 and hull[0] == hull[hull.size() - 1]:
		hull.remove_at(hull.size() - 1)
	bounds = _poly_bounds(hull)
	var roof_y := _H * P
	var cab_x0 := (float(_p.trunk) + float(_p.rw) * 0.3) * P
	var cab_x1 := (_L - float(_p.hood) - float(_p.ws) * 0.3) * P
	if _type in ["kart", "buggy", "tractor"]:
		cab_x0 = (_L * 0.3) * P
		cab_x1 = (_L * 0.6) * P
	var rr0 := _tx(Vector2(cab_x0, roof_y + 0.05 * P))
	var rr1 := _tx(Vector2(cab_x1, roof_y - 0.22 * P))
	roof_rect = Rect2(rr0, rr1 - rr0).abs()
	exhaust = _tx(Vector2(-0.05 * P, 0.14 * P))
	headlight = _tx(Vector2(_L * P, float(_p.nose) * P - 0.12 * P))
	# Centre of mass: between axles weighted by front bias, at com height.
	var hd: Dictionary = vdef.get("handling", {})
	var fb := float(hd.get("front_bias", 0.5))
	var com_h := float(hd.get("com_h", 0.45))
	var cx := lerpf(wheels[0].pos.x, wheels[-1].pos.x, fb)
	com = Vector2(cx, ground_y - com_h * P)


# ------------------------------------------------------------------
func _outline() -> Dictionary:
	var L := _L
	var H := _H
	var belt := float(_p.belt)
	var nose := float(_p.nose)
	var tail := float(_p.tail)
	var hood := float(_p.hood)
	var ws := float(_p.ws)
	var rw := float(_p.rw)
	var trunk := maxf(float(_p.trunk), 0.03)
	var roof_x0 := trunk + rw
	var roof_x1 := L - hood - ws
	if roof_x1 - roof_x0 < 0.25:
		var mid := (roof_x0 + roof_x1) * 0.5
		roof_x0 = mid - 0.13
		roof_x1 = mid + 0.13
	var rb := 0.08
	var pts := PackedVector2Array([
		Vector2(0.04, 0.0),
		Vector2(0.0, tail),
		Vector2(trunk, belt if trunk > 0.2 else maxf(tail, belt * 0.98)),
		Vector2(roof_x0, H),
		Vector2(roof_x1, H),
		Vector2(L - hood, belt + float(_p.get("cowl", 0.0))),
		Vector2(L, nose),
		Vector2(L - 0.03, 0.0),
	])
	var radii := [rb, float(_p.r_tail), 0.08, float(_p.r_roof), float(_p.r_roof) * 0.8, 0.12, float(_p.r_nose), rb]
	if _type in ["pickup", "micro_pickup", "trophy", "monster"]:
		# Vertical cab back wall rising out of the bed.
		pts[2] = Vector2(trunk, belt)
		pts[3] = Vector2(trunk + rw, H)
		radii[2] = 0.02
	if _type == "kart":
		pts = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.0, 0.32), Vector2(0.55, 0.38), Vector2(0.9, 0.42), Vector2(1.5, 0.36), Vector2(L, 0.28), Vector2(L, 0.05)])
		radii = [0.04, 0.08, 0.1, 0.1, 0.1, 0.12, 0.04]
	elif _type == "tractor":
		pts = PackedVector2Array([Vector2(0.0, 0.25), Vector2(0.0, 1.05), Vector2(0.35, 1.08), Vector2(0.35, H), Vector2(1.55, H), Vector2(1.6, 1.1), Vector2(L - 0.1, 1.08), Vector2(L, 0.95), Vector2(L, 0.35), Vector2(1.6, 0.2)])
		radii = [0.05, 0.08, 0.04, 0.1, 0.1, 0.04, 0.15, 0.15, 0.08, 0.05]
	elif _type == "buggy":
		pts = PackedVector2Array([Vector2(0.15, 0.0), Vector2(0.0, 0.55), Vector2(0.9, 0.62), Vector2(2.2, 0.62), Vector2(L, 0.5), Vector2(L - 0.15, 0.12), Vector2(L - 0.6, 0.0)])
		radii = [0.08, 0.12, 0.05, 0.1, 0.25, 0.1, 0.05]
	elif _type == "rover":
		pts = PackedVector2Array([Vector2(0.0, 0.05), Vector2(0.0, 0.62), Vector2(L, 0.62), Vector2(L, 0.05)])
		radii = [0.06, 0.1, 0.1, 0.06]
	return {"pts": _scale_pts(pts), "radii": _scale_radii(radii)}


func _scale_pts(pts: PackedVector2Array) -> PackedVector2Array:
	var o := PackedVector2Array()
	for p in pts:
		o.append(p * P)
	return o


func _scale_radii(r: Array) -> Array:
	var o := []
	for v in r:
		o.append(float(v) * P)
	return o


func _tx(p: Vector2) -> Vector2:
	return Vector2(p.x - _origin.x, -(p.y - _origin.y))


func _txp(poly: PackedVector2Array) -> PackedVector2Array:
	var o := PackedVector2Array()
	o.resize(poly.size())
	for i in poly.size():
		o[i] = _tx(poly[i])
	return o


func _add(arr: Array, poly: PackedVector2Array, c: Color) -> void:
	if poly.size() < 3:
		return
	if Geometry2D.is_polygon_clockwise(poly) and false:
		return
	var cols := PackedColorArray()
	cols.resize(poly.size())
	cols.fill(c)
	arr.append({"poly": _txp(poly), "cols": cols})


## Vertical gradient (top/mid/bottom colours) using vertex colours.
func _add_grad(arr: Array, poly: PackedVector2Array, top: Color, mid: Color, bot: Color) -> void:
	if poly.size() < 3:
		return
	var y0 := INF
	var y1 := -INF
	for p in poly:
		y0 = minf(y0, p.y)
		y1 = maxf(y1, p.y)
	var cols := PackedColorArray()
	cols.resize(poly.size())
	for i in poly.size():
		var t := 1.0 - (poly[i].y - y0) / maxf(y1 - y0, 0.001)
		cols[i] = Util.lerp_color3(top, mid, bot, t)
	arr.append({"poly": _txp(poly), "cols": cols})


func _line(a: Vector2, b: Vector2, w: float, c: Color, front := false) -> void:
	lines.append({"a": _tx(a), "b": _tx(b), "w": w, "c": c, "front": front})


func _poly_bounds(poly: PackedVector2Array) -> Rect2:
	if poly.is_empty():
		return Rect2()
	var r := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		r = r.expand(p)
	return r


# ------------------------------------------------------------------
func _glass(paint_poly: PackedVector2Array, glass: Color, body_col: Color) -> void:
	var belt := float(_p.belt) * P
	var inset := Geometry2D.offset_polygon(paint_poly, -0.075 * P)
	if inset.is_empty():
		return
	var inner := Util.largest(inset)
	var x0 := (maxf(float(_p.trunk), 0.03) - 0.05) * P
	var x1 := (_L - float(_p.hood) + 0.05) * P
	if _type in ["pickup", "micro_pickup", "trophy", "monster"]:
		x0 = (float(_p.trunk) + 0.02) * P
	var band := Util.rect_poly(x0, belt + 0.06 * P, x1, _H * P + 10)
	var glass_polys := Geometry2D.intersect_polygons(inner, band)
	# Pillars: B pillar (and C pillar for long cabins / buses)
	var pillar_w := 0.09 * P
	var cab0 := x0
	var cab1 := x1
	var pillars: Array = []
	var cab_len := (cab1 - cab0) / P
	if _type == "bus":
		var n := int(cab_len / 1.1)
		for i in range(1, n):
			pillars.append(cab0 + (cab1 - cab0) * i / n)
	elif _type in ["van"]:
		pillars.append(cab1 - 1.0 * P)
		pillars.append(cab1 - 1.25 * P)
	elif cab_len > 1.6:
		var doors := int(_st.get("doors", 4))
		if doors >= 4 and cab_len > 2.0:
			pillars.append(cab0 + (cab1 - cab0) * 0.52)
			if cab_len > 3.0:
				pillars.append(cab0 + (cab1 - cab0) * 0.22)
		else:
			pillars.append(cab0 + (cab1 - cab0) * 0.42)
	var final_glass: Array = glass_polys
	for px in pillars:
		var cut := Util.rect_poly(px - pillar_w * 0.5, -100, px + pillar_w * 0.5, _H * P + 100)
		var next: Array = []
		for gp in final_glass:
			for cp in Geometry2D.clip_polygons(gp, cut):
				next.append(cp)
		final_glass = next
	var top_col := glass.lightened(0.28)
	var bot_col := glass.darkened(0.25)
	for gp in final_glass:
		if Geometry2D.is_polygon_clockwise(gp) != Geometry2D.is_polygon_clockwise(paint_poly):
			continue
		_add_grad(parts, gp, top_col, glass, bot_col)
		# reflection streak
		var streak := PackedVector2Array([
			Vector2(cab0 + 0.4 * P, _H * P + 10), Vector2(cab0 + 0.75 * P, _H * P + 10),
			Vector2(cab0 + 0.35 * P, belt), Vector2(cab0 + 0.0 * P, belt)])
		for sp in Geometry2D.intersect_polygons(gp, streak):
			_add(parts, sp, Color(1, 1, 1, 0.13))
		var streak2 := PackedVector2Array([
			Vector2(cab1 - 0.9 * P, _H * P + 10), Vector2(cab1 - 0.75 * P, _H * P + 10),
			Vector2(cab1 - 1.1 * P, belt), Vector2(cab1 - 1.25 * P, belt)])
		for sp in Geometry2D.intersect_polygons(gp, streak2):
			_add(parts, sp, Color(1, 1, 1, 0.09))
	if _st.get("sunroof", false):
		var sx := (_L - float(_p.hood) - float(_p.ws) - 0.8) * P
		_add(parts, Util.rect_poly(sx, _H * P - 0.03 * P, sx + 0.55 * P, _H * P + 0.01 * P), glass.darkened(0.3))


func _stripes(paint_poly: PackedVector2Array) -> void:
	var s = _st.get("stripe", null)
	if s == null or not (s is Dictionary):
		return
	var c := Util.col(s.get("color", "#ffffff"))
	var kind: String = s.get("type", "side")
	var belt := float(_p.belt) * P
	match kind:
		"side":
			var y := belt * 0.62
			for pp in Geometry2D.intersect_polygons(paint_poly, Util.rect_poly(-50, y - 0.05 * P, _L * P + 50, y + 0.05 * P)):
				_add(parts, pp, c)
		"double":
			for yy in [belt * 0.55, belt * 0.72]:
				for pp in Geometry2D.intersect_polygons(paint_poly, Util.rect_poly(-50, yy - 0.03 * P, _L * P + 50, yy + 0.03 * P)):
					_add(parts, pp, c)
		"rally":
			var band := PackedVector2Array([Vector2(_L * 0.25 * P, -10), Vector2(_L * 0.42 * P, -10), Vector2(_L * 0.62 * P, _H * P + 10), Vector2(_L * 0.45 * P, _H * P + 10)])
			for pp in Geometry2D.intersect_polygons(paint_poly, band):
				_add(parts, pp, c)
		"lower":
			for pp in Geometry2D.intersect_polygons(paint_poly, Util.rect_poly(-50, 0.12 * P, _L * P + 50, belt * 0.45)):
				_add_grad(parts, pp, c.lightened(0.1), c, c.darkened(0.25))
		"swoosh":
			var sw := PackedVector2Array()
			for i in 13:
				var t := i / 12.0
				sw.append(Vector2(t * _L * P, belt * (0.35 + 0.35 * t)))
			for i in range(12, -1, -1):
				var t := i / 12.0
				sw.append(Vector2(t * _L * P, belt * (0.35 + 0.35 * t) + 0.09 * P))
			for pp in Geometry2D.intersect_polygons(paint_poly, sw):
				_add(parts, pp, c)
		"cross":
			# Emergency band + cross (ambulance)
			for pp in Geometry2D.intersect_polygons(paint_poly, Util.rect_poly(-50, belt * 0.55, _L * P + 50, belt * 0.75)):
				_add(parts, pp, c)
			var cx := _L * 0.42 * P
			var cy := belt + (_H * P - belt) * 0.45
			var a := 0.16 * P
			var b := 0.05 * P
			_add(parts, Util.rect_poly(cx - a, cy - b, cx + a, cy + b), c)
			_add(parts, Util.rect_poly(cx - b, cy - a, cx + b, cy + a), c)
	if s.has("number"):
		var nc := Vector2(_L * 0.45 * P, belt * 0.55)
		_add(parts, Util.circle_poly(nc, 0.2 * P, 20), Color.WHITE)
		_add(parts, Util.circle_poly(nc, 0.16 * P, 20), c)


func _lights_and_details(paint_poly: PackedVector2Array, trim: Color, body_col: Color) -> void:
	var nose := float(_p.nose) * P
	var tail := float(_p.tail) * P
	var L := _L * P
	var belt := float(_p.belt) * P
	var hl := Util.col(_st.get("headlight", "#fff4c8"))
	# headlight
	var hl_rect := Util.rect_poly(L - 0.32 * P, nose - 0.2 * P, L + 10, nose - 0.05 * P)
	if _type in ["microvan", "bus", "van", "micro_pickup"]:
		hl_rect = Util.rect_poly(L - 0.2 * P, 0.25 * P, L + 10, 0.42 * P)
	for pp in Geometry2D.intersect_polygons(paint_poly, hl_rect):
		_add(parts, pp, hl)
	# tail light
	var tl_rect := Util.rect_poly(-10, tail - 0.22 * P, 0.14 * P, tail - 0.06 * P)
	for pp in Geometry2D.intersect_polygons(paint_poly, tl_rect):
		_add(parts, pp, Color("e5262e"))
	# grille / intake
	if not _type in ["kart", "rover", "buggy"]:
		var gr := Util.rect_poly(L - 0.07 * P, 0.2 * P, L + 10, maxf(nose - 0.24 * P, 0.28 * P))
		for pp in Geometry2D.intersect_polygons(paint_poly, gr):
			_add(parts, pp, trim.darkened(0.2))
	# door lines & handles
	if _type in ["kart", "rover", "buggy", "tractor", "bus"]:
		return
	var cab0 := maxf(float(_p.trunk), 0.03) * P
	var cab1 := (_L - float(_p.hood)) * P
	if _type in ["pickup", "micro_pickup", "trophy", "monster"]:
		# bed / cab split line
		var bx := float(_p.trunk) * P + 0.02 * P
		_line(Vector2(bx, 0.12 * P), Vector2(bx, belt), 2.0, body_col.darkened(0.45))
		cab0 = bx
	var doors := int(_st.get("doors", 4))
	var cab_len := (cab1 - cab0) / P
	var door_xs: Array = []
	if doors >= 4 and cab_len > 2.0:
		door_xs = [cab0 + (cab1 - cab0) * 0.08, cab0 + (cab1 - cab0) * 0.52, cab1 - 0.04 * P]
	else:
		door_xs = [cab0 + (cab1 - cab0) * 0.4, cab1 - 0.04 * P]
	var dc := body_col.darkened(0.42)
	dc.a = 0.85
	for dx in door_xs:
		_line(Vector2(dx, 0.17 * P), Vector2(dx, belt + 0.06 * P), 1.6, dc)
	for i in range(door_xs.size() - 1):
		var hx: float = door_xs[i + 1] - 0.3 * P
		var hy := belt - 0.12 * P
		_add(parts, Util.rect_poly(hx, hy - 0.025 * P, hx + 0.18 * P, hy + 0.02 * P), body_col.darkened(0.5))
	# mirror
	var mx := cab1 - 0.08 * P
	var my := belt + 0.06 * P
	_add(parts, Util.rounded_poly(Util.rect_poly(mx - 0.12 * P, my, mx + 0.04 * P, my + 0.13 * P), 3.0, 2), trim)


func _accessories(col: Color, col2: Color, trim: Color) -> void:
	var L := _L * P
	var H := _H * P
	var belt := float(_p.belt) * P
	var roof_x0 := (maxf(float(_p.trunk), 0.03) + float(_p.rw)) * P
	var roof_x1 := L - (float(_p.hood) + float(_p.ws)) * P
	var acc: Array = _st.get("acc", [])
	for a in acc:
		match a:
			"spoiler":
				var sx := 0.02 * P
				var sy := float(_p.tail) * P
				_add(parts, PackedVector2Array([Vector2(sx, sy), Vector2(sx + 0.45 * P, sy + 0.02 * P), Vector2(sx + 0.42 * P, sy + 0.1 * P), Vector2(sx - 0.02 * P, sy + 0.1 * P)]), col.darkened(0.25))
			"wing":
				var sx := 0.05 * P
				var sy := float(_p.tail) * P
				_add(parts, Util.rect_poly(sx + 0.18 * P, sy, sx + 0.24 * P, sy + 0.22 * P), trim)
				_add(parts, PackedVector2Array([Vector2(sx - 0.05 * P, sy + 0.22 * P), Vector2(sx + 0.55 * P, sy + 0.25 * P), Vector2(sx + 0.5 * P, sy + 0.32 * P), Vector2(sx - 0.08 * P, sy + 0.3 * P)]), col2)
			"roof_rack":
				var y := H + 0.02 * P
				_add(parts, Util.rect_poly(roof_x0 + 0.1 * P, y + 0.07 * P, roof_x1 - 0.05 * P, y + 0.11 * P), trim)
				for x in [roof_x0 + 0.2 * P, roof_x1 - 0.15 * P]:
					_add(parts, Util.rect_poly(x, y - 0.02 * P, x + 0.06 * P, y + 0.08 * P), trim)
			"cargo_box":
				var y := H + 0.02 * P
				_add(parts, Util.rounded_poly(Util.rect_poly(roof_x0 + 0.15 * P, y, roof_x1 - 0.15 * P, y + 0.3 * P), 6.0, 3), trim.lightened(0.15))
			"light_bar":
				var y := H + 0.02 * P
				_add(parts, Util.rect_poly(roof_x1 - 0.9 * P, y, roof_x1 - 0.05 * P, y + 0.12 * P), trim)
				for i in 4:
					var x := roof_x1 - 0.85 * P + i * 0.2 * P
					_add(parts, Util.circle_poly(Vector2(x + 0.07 * P, y + 0.06 * P), 0.045 * P, 10), Color("fff7cf"))
			"beacon":
				var y := H + 0.02 * P
				var x := (roof_x0 + roof_x1) * 0.5
				_add(parts, Util.rounded_poly(Util.rect_poly(x - 0.25 * P, y, x + 0.25 * P, y + 0.14 * P), 4.0, 2), Color("ff3344"))
				_add(parts, Util.rect_poly(x - 0.05 * P, y, x + 0.05 * P, y + 0.14 * P), Color("4aa3ff"))
			"snorkel":
				var x := L - float(_p.hood) * P + 0.05 * P
				_add(parts_front, Util.rect_poly(x, belt - 0.3 * P, x + 0.08 * P, H - 0.05 * P), trim)
				_add(parts_front, Util.rect_poly(x - 0.04 * P, H - 0.1 * P, x + 0.16 * P, H), trim)
			"spare":
				var c := Vector2(-0.12 * P, belt * 0.68)
				_add(parts_back, Util.circle_poly(c, 0.36 * P, 22), TIRE)
				_add(parts_back, Util.circle_poly(c, 0.2 * P, 18), trim.lightened(0.3))
			"bull_bar":
				_add(parts_front, Util.rect_poly(L - 0.02 * P, 0.15 * P, L + 0.12 * P, float(_p.nose) * P + 0.05 * P), trim)
				_add(parts_front, Util.rect_poly(L - 0.05 * P, float(_p.nose) * P - 0.05 * P, L + 0.12 * P, float(_p.nose) * P + 0.05 * P), trim.lightened(0.2))
			"hood_scoop":
				var x := L - float(_p.hood) * P * 0.65
				var y := float(_p.belt) * P + float(_p.get("cowl", 0.0)) * P
				var hy := lerpf(y, float(_p.nose) * P, 0.35)
				_add(parts, PackedVector2Array([Vector2(x - 0.3 * P, hy), Vector2(x + 0.15 * P, hy + 0.14 * P), Vector2(x + 0.25 * P, hy + 0.14 * P), Vector2(x + 0.25 * P, hy - 0.02 * P)]), trim)
			"fins":
				var y := float(_p.tail) * P
				_add(parts, PackedVector2Array([Vector2(0.0, y - 0.05 * P), Vector2(-0.05 * P, y + 0.22 * P), Vector2(1.1 * P, y + 0.02 * P), Vector2(1.1 * P, y - 0.05 * P)]), col)
				_add(parts, Util.rect_poly(-0.03 * P, y + 0.02 * P, 0.1 * P, y + 0.16 * P), Color("e5262e"))
			"side_pipes":
				_add(parts_front, Util.rounded_poly(Util.rect_poly(float(_p.oh_r) * P + 0.5 * P, 0.03 * P, L - float(_p.oh_f) * P - 0.5 * P, 0.11 * P), 4.0, 2), CHROME)
			"ladder":
				var x := 0.08 * P
				for i in 5:
					_line(Vector2(x, belt * 0.4 + i * 0.25 * P), Vector2(x + 0.2 * P, belt * 0.4 + i * 0.25 * P), 2.0, trim, true)
				_line(Vector2(x, belt * 0.35), Vector2(x, H - 0.1 * P), 2.0, trim, true)
				_line(Vector2(x + 0.2 * P, belt * 0.35), Vector2(x + 0.2 * P, H - 0.1 * P), 2.0, trim, true)
			"cargo_hay":
				var x0 := 0.15 * P
				var x1 := float(_p.trunk) * P - 0.05 * P
				for i in 2:
					var bx := x0 + i * (x1 - x0) * 0.5
					_add(parts_back, Util.rounded_poly(Util.rect_poly(bx, belt - 0.05 * P, bx + (x1 - x0) * 0.48, belt + 0.45 * P), 5.0, 2), Color("e2b850"))
			"cargo_crates":
				var x0 := 0.2 * P
				_add(parts_back, Util.rect_poly(x0, belt - 0.05 * P, x0 + 0.6 * P, belt + 0.45 * P), Color("9b6b3d"))
				_add(parts_back, Util.rect_poly(x0 + 0.65 * P, belt - 0.05 * P, x0 + 1.05 * P, belt + 0.3 * P), Color("b5804b"))
			"spare_bed":
				var c := Vector2(float(_p.trunk) * P * 0.45, belt + 0.12 * P)
				_add(parts_back, Util.circle_poly(c, 0.42 * P, 22), TIRE)
				_add(parts_back, Util.circle_poly(c, 0.22 * P, 18), trim.lightened(0.35))
			"roll_bar":
				var x := float(_p.trunk) * P - 0.2 * P
				_line(Vector2(x, belt), Vector2(x + 0.15 * P, H + 0.15 * P), 4.0, trim)
				_line(Vector2(x + 0.15 * P, H + 0.15 * P), Vector2(x + 0.55 * P, H + 0.15 * P), 4.0, trim)
			"ice_cream":
				var x := (roof_x0 + roof_x1) * 0.5
				var y := H + 0.02 * P
				_add(parts, PackedVector2Array([Vector2(x - 0.18 * P, y + 0.3 * P), Vector2(x + 0.18 * P, y + 0.3 * P), Vector2(x, y - 0.0 * P)]), Color("d9a05b"))
				_add(parts, Util.circle_poly(Vector2(x, y + 0.42 * P), 0.2 * P, 18), Color("ff9ec8"))
				_add(parts, Util.circle_poly(Vector2(x + 0.05 * P, y + 0.55 * P), 0.12 * P, 14), Color("fff3e0"))
			"dish":
				var x := 0.6 * P
				var y := 0.62 * P
				_line(Vector2(x, y), Vector2(x, y + 0.9 * P), 3.0, CHROME)
				_add(parts, PackedVector2Array([Vector2(x - 0.35 * P, y + 1.15 * P), Vector2(x + 0.35 * P, y + 0.95 * P), Vector2(x + 0.25 * P, y + 0.82 * P), Vector2(x - 0.2 * P, y + 0.9 * P)]), CHROME)
			"antenna":
				var x := roof_x0 + 0.15 * P
				_line(Vector2(x, H), Vector2(x - 0.3 * P, H + 0.6 * P), 1.5, trim)
			"exhaust_stack":
				var x := 1.5 * P
				_add(parts, Util.rect_poly(x, float(_p.H) * P - 0.6 * P, x + 0.08 * P, H + 0.2 * P), trim)


func _driver(open_top: bool) -> void:
	var helmet := Util.col(_st.get("helmet", "#f2f2f2"))
	var belt := float(_p.belt) * P
	var hx: float
	var hy: float
	if _type in ["kart", "buggy", "tractor", "rover"]:
		match _type:
			"kart":
				hx = 0.85 * P
				hy = 0.95 * P
			"buggy":
				hx = 1.55 * P
				hy = 1.12 * P
			"tractor":
				hx = 0.95 * P
				hy = 1.85 * P
			_:
				hx = 1.7 * P
				hy = 1.12 * P
		# torso
		var torso_c := Util.col(_st.get("suit", "#2b6cd6"))
		_add(parts_back, Util.rounded_poly(Util.rect_poly(hx - 0.2 * P, hy - 0.62 * P, hx + 0.16 * P, hy - 0.12 * P), 6.0, 3), torso_c)
	else:
		var roof_x1 := (_L - float(_p.hood) - float(_p.ws)) * P
		hx = roof_x1 - 0.3 * P
		if _type in ["microvan", "bus", "micro_pickup", "van"]:
			hx = (_L - float(_p.hood) - 0.45) * P
		hy = belt + (_H * P - belt) * 0.42
		if open_top:
			hy = belt + 0.3 * P
	var r := 0.17 * P
	var c := Vector2(hx, hy)
	# shoulders
	_add(parts, Util.rounded_poly(Util.rect_poly(hx - 0.24 * P, hy - 0.42 * P, hx + 0.12 * P, hy - 0.1 * P), 0.1 * P, 3), Color("2a3442"))
	# helmet shell
	_add_grad(parts, Util.circle_poly(c, r, 22), helmet.lightened(0.25), helmet, helmet.darkened(0.25))
	# visor covering the front of the helmet
	var visor := PackedVector2Array()
	for i in 9:
		var a := lerpf(-0.75, 0.55, i / 8.0)
		visor.append(c + Vector2(cos(a), sin(a)) * (r + 0.5))
	visor.append(c + Vector2(r * 0.15, r * 0.35))
	visor.append(c + Vector2(r * 0.15, -r * 0.45))
	_add(parts, visor, Color("17202b"))
	_add(parts, PackedVector2Array([c + Vector2(r * 0.45, -r * 0.25), c + Vector2(r * 0.8, -r * 0.4), c + Vector2(r * 0.85, -r * 0.25)]), Color(1, 1, 1, 0.35))
	# helmet stripe
	_add(parts, PackedVector2Array([c + Vector2(-r * 0.95, -r * 0.1), c + Vector2(-r * 0.2, r * 0.95), c + Vector2(r * 0.05, r * 0.9), c + Vector2(-r * 0.8, -r * 0.35)]), Util.col(_st.get("helmet_stripe", ""), helmet.darkened(0.35)))


func _buggy_frame(trim: Color, col2: Color) -> void:
	var c := trim.lightened(0.15)
	var pts := [Vector2(0.6, 0.55), Vector2(1.05, 1.5), Vector2(2.1, 1.5), Vector2(2.7, 0.62), Vector2(1.6, 1.5), Vector2(1.6, 0.6), Vector2(0.25, 0.9)]
	_line(pts[0] * P, pts[1] * P, 5.0, c)
	_line(pts[1] * P, pts[2] * P, 5.0, c)
	_line(pts[2] * P, pts[3] * P, 5.0, c)
	_line(pts[4] * P, pts[5] * P, 4.0, c)
	_line(pts[0] * P, pts[6] * P, 4.0, c)
	_line(pts[1] * P, pts[5] * P, 3.0, c)


func _rover_extras(col: Color, col2: Color, trim: Color) -> void:
	_line(Vector2(0.4, 0.62) * P, Vector2(0.4, 1.0) * P, 3.0, trim)
	_line(Vector2(3.4, 0.62) * P, Vector2(3.4, 1.0) * P, 3.0, trim)
	_add(parts_back, Util.rect_poly(1.1 * P, 0.6 * P, 2.4 * P, 0.9 * P), col2)
