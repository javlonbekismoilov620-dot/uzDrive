## Loads every .gd under res://src, res://tests and res://tools to surface parse errors.
extends SceneTree

func _initialize() -> void:
	var bad := 0
	var total := 0
	for root in ["res://src", "res://tests", "res://tools"]:
		for f in _walk(root):
			total += 1
			var s = load(f)
			if s == null or (s is GDScript and not s.can_instantiate()):
				print("FAILED: ", f)
				bad += 1
	print("checked %d scripts, %d failed" % [total, bad])
	quit(1 if bad > 0 else 0)

func _walk(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		var p := dir + "/" + n
		if d.current_is_dir():
			if not n.begins_with("."):
				out.append_array(_walk(p))
		elif n.ends_with(".gd"):
			out.append(p)
		n = d.get_next()
	return out
