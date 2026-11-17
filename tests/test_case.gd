## Minimal test base class (no external addons needed).
class_name TestCase
extends RefCounted

var tree: SceneTree
var failures: Array = []
var checks := 0
var _current := ""


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append("%s: %s" % [_current, msg])


func eq(a: Variant, b: Variant, msg := "") -> void:
	check(a == b, "%s (got %s, expected %s)" % [msg, str(a), str(b)])


func near(a: float, b: float, eps: float, msg := "") -> void:
	check(absf(a - b) <= eps, "%s (got %s, expected %s ± %s)" % [msg, a, b, eps])


## Isolated, empty profile stored in a throw-away save folder.
func fresh_profile() -> void:
	var save = tree.root.get_node("/root/Save")
	var profile = tree.root.get_node("/root/Profile")
	save.dir = "user://test_saves/"
	DirAccess.make_dir_recursive_absolute(save.dir)
	save.delete_all()
	profile.data = profile.default_data()
	profile.data.settings.lang_chosen = true
	profile.ensure_integrity()


func wait_frames(n: int) -> void:
	for i in n:
		await tree.physics_frame
