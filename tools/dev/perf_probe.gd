## CPU cost probe: drives a run headlessly and reports average/peak frame cost
## of game logic + physics (rendering excluded). Usage:
##   godot --headless --fixed-fps 60 --path . -s tools/dev/perf_probe.gd -- <map> <vehicle> <seconds>
extends SceneTree

func _initialize() -> void:
	_go.call_deferred()

func _go() -> void:
	var a := OS.get_cmdline_user_args()
	var map_id: String = a[0] if a.size() > 0 else "green_hills"
	var vid: String = a[1] if a.size() > 1 else "sarbon_mitti"
	var secs := float(a[2]) if a.size() > 2 else 30.0
	var prof = root.get_node("/root/Profile")
	prof.data.tutorial.done = true
	if not prof.owns(vid):
		prof.data.garage.owned.append(vid)
	# loaded at runtime: GameScreen depends on autoloads that are not yet
	# registered when this tool script itself is compiled
	var gs = load("res://src/gameplay/game_screen.gd").new()
	gs.params = {"map": map_id, "vehicle": vid}
	root.add_child(gs)
	Input.action_press("gas")
	var frames := int(secs * 60)
	var total := 0.0
	var peak := 0.0
	var phys_total := 0.0
	var t0 := Time.get_ticks_usec()
	var worst_wall := 0.0
	var last := t0
	for i in frames:
		gs.fuel = 1.0
		await process_frame
		var p := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		var ph := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		total += p
		phys_total += ph
		peak = maxf(peak, p + ph)
		var now := Time.get_ticks_usec()
		worst_wall = maxf(worst_wall, (now - last) / 1000.0)
		last = now
	var wall_ms := (Time.get_ticks_usec() - t0) / 1000.0 / frames
	print("WALL %s: %.2f ms per frame (worst %.2f ms) incl. physics+logic, headless" % [map_id, wall_ms, worst_wall])
	# Note: Performance TIME_* monitors are not meaningful under --fixed-fps
	# headless runs, so wall-clock time is the reported figure.
	print("PERF %s %s: %.0f m driven, objects %d, nodes %d" % [map_id, vid, gs.distance, Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	quit()
