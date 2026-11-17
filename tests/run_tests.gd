## Headless test runner. Usage:
##   godot --headless --path . -s tests/run_tests.gd [-- filter]
## Exit code 0 = all passed.
extends SceneTree

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var filter := ""
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		filter = args[0]
	var files: Array = []
	var d := DirAccess.open("res://tests")
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if n.begins_with("test_") and n.ends_with(".gd") and n != "test_case.gd":
			files.append("res://tests/" + n)
		n = d.get_next()
	files.sort()
	var total_checks := 0
	var total_fail: Array = []
	var tests_run := 0
	for f in files:
		if filter != "" and not f.contains(filter):
			continue
		var script: GDScript = load(f)
		var t: TestCase = script.new()
		t.tree = self
		for m in t.get_method_list():
			var mname: String = m.name
			if not mname.begins_with("test_"):
				continue
			t._current = "%s::%s" % [f.get_file().get_basename(), mname]
			var before := t.failures.size()
			await t.call(mname)
			tests_run += 1
			var ok := t.failures.size() == before
			print(("  PASS " if ok else "  FAIL ") + t._current)
		total_checks += t.checks
		total_fail.append_array(t.failures)
	print("")
	for fl in total_fail:
		print("FAILURE: ", fl)
	print("RESULT: %d tests, %d checks, %d failures" % [tests_run, total_checks, total_fail.size()])
	Engine.time_scale = 1.0
	quit(0 if total_fail.is_empty() else 1)
