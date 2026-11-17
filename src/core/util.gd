## Small stateless helpers (JSON IO, formatting, math).
class_name Util
extends RefCounted


static func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("JSON not found: %s" % path)
		return null
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("JSON parse error in %s line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


static func col(v: Variant, fallback := Color.WHITE) -> Color:
	if v is Color:
		return v
	if v is String and (v as String).length() > 0:
		return Color.from_string(v, fallback)
	return fallback


## Integer formatting with locale-appropriate thousands separator.
static func fmt_int(n: int, sep := " ") -> String:
	var neg := n < 0
	var s := str(absi(n))
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = sep + out
	return ("-" if neg else "") + out


## Compact formatting: 12.5K, 1.2M
static func fmt_short(n: int) -> String:
	if absi(n) >= 1_000_000:
		return ("%.1fM" % (n / 1_000_000.0)).replace(".0M", "M")
	if absi(n) >= 10_000:
		return ("%.1fK" % (n / 1000.0)).replace(".0K", "K")
	return str(n)


static func today_str() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


## Days between two YYYY-MM-DD strings (b - a). Returns 0 on parse failure.
static func days_between(a: String, b: String) -> int:
	if a.is_empty() or b.is_empty():
		return 0
	var ta := Time.get_unix_time_from_datetime_string(a + "T00:00:00")
	var tb := Time.get_unix_time_from_datetime_string(b + "T00:00:00")
	return int(round((tb - ta) / 86400.0))


static func seconds_until_midnight() -> int:
	var t := Time.get_time_dict_from_system()
	return 86400 - (int(t.hour) * 3600 + int(t.minute) * 60 + int(t.second))


static func fmt_duration(sec: int) -> String:
	sec = maxi(sec, 0)
	return "%02d:%02d:%02d" % [sec / 3600, (sec % 3600) / 60, sec % 60]


## Deterministic string hash → int (stable across platforms, unlike hash()).
static func stable_hash(s: String) -> int:
	var h := 2166136261
	for i in s.length():
		h = (h ^ s.unicode_at(i)) * 16777619
		h &= 0x7fffffff
	return h


## Rounded polygon from corner points; radii per corner (same length as pts) or single float.
static func rounded_poly(pts: PackedVector2Array, radii: Variant, seg := 5) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	for i in n:
		var p := pts[i]
		var a := pts[(i - 1 + n) % n]
		var b := pts[(i + 1) % n]
		var r: float = radii[i] if radii is Array or radii is PackedFloat32Array else float(radii)
		if r <= 0.0001:
			out.append(p)
			continue
		var da := a - p
		var db := b - p
		var la := da.length()
		var lb := db.length()
		if la < 0.0001 or lb < 0.0001:
			out.append(p)
			continue
		var rr := minf(r, minf(la, lb) * 0.45)
		var p0 := p + da / la * rr
		var p1 := p + db / lb * rr
		for s in seg + 1:
			var t := float(s) / seg
			var q := p0.lerp(p, t).lerp(p.lerp(p1, t), t)
			out.append(q)
	return out


static func circle_poly(c: Vector2, r: float, seg := 24) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in seg:
		var a := TAU * i / seg
		out.append(c + Vector2(cos(a), sin(a)) * r)
	return out


static func rect_poly(x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])


## Largest polygon from a Geometry2D result (ignores holes).
static func largest(polys: Array) -> PackedVector2Array:
	var best := PackedVector2Array()
	var best_a := -1.0
	for p in polys:
		if Geometry2D.is_polygon_clockwise(p) and polys.size() > 1:
			pass
		var a := absf(poly_area(p))
		if a > best_a:
			best_a = a
			best = p
	return best


static func poly_area(p: PackedVector2Array) -> float:
	var a := 0.0
	var n := p.size()
	for i in n:
		var q := p[(i + 1) % n]
		a += p[i].x * q.y - q.x * p[i].y
	return a * 0.5


static func lerp_color3(a: Color, b: Color, c: Color, t: float) -> Color:
	if t < 0.5:
		return a.lerp(b, t * 2.0)
	return b.lerp(c, (t - 0.5) * 2.0)
