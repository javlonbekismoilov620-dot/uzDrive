extends TestCase
## Full run lifecycle through the real GameScreen (world + HUD + rules).


func _start(vid := "sarbon_mitti", map_id := "green_hills") -> GameScreen:
	var gs := GameScreen.new()
	gs.params = {"map": map_id, "vehicle": vid}
	tree.root.add_child(gs)
	await wait_frames(3)
	return gs


func _stop(gs: GameScreen) -> void:
	tree.paused = false
	Input.action_release("gas")
	tree.root.remove_child(gs)
	gs.queue_free()
	await wait_frames(2)


func test_run_fuel_end_and_payout_once() -> void:
	fresh_profile()
	Profile.data.tutorial.done = true
	var gs: GameScreen = await _start()
	Input.action_press("gas")
	await wait_frames(300)
	check(gs.distance > 25.0, "car advanced (%.1f m)" % gs.distance)
	check(gs.fuel < 1.0, "fuel consumed")
	check(gs.vehicle.rpm > 0.1, "engine rpm reported")
	Input.action_release("gas")
	for i in 1500:
		if gs.state == GameScreen.State.RESULTS:
			break
		if gs.state == GameScreen.State.RUNNING:
			gs.fuel = 0.0   # keep the tank empty even if a can is reached
		await tree.physics_frame
	eq(gs.state, GameScreen.State.RESULTS, "out of fuel ends the run")
	eq(gs.end_reason, "fuel", "reason")
	check(gs.results.visible, "results shown")
	check(Profile.data.has("pending_run"), "run snapshotted before payout")
	var c0 := Economy.coins()
	var expected: int = Economy.compute_run_payout(gs.summary()).total
	gs.commit()
	eq(Economy.coins(), c0 + expected, "payout added")
	gs.commit()
	eq(Economy.coins(), c0 + expected, "payout not duplicated")
	check(not Profile.data.has("pending_run"), "pending snapshot cleared")
	eq(int(Profile.stat("total_runs")), 1, "run counted for missions/achievements")
	check(Profile.best_distance("green_hills") >= int(gs.distance), "best distance saved")
	await _stop(gs)


func test_revive_costs_gems() -> void:
	fresh_profile()
	Profile.data.tutorial.done = true
	Profile.data.wallet.gems = 30
	var gs: GameScreen = await _start()
	gs._end_run("crash")
	for i in 400:
		if gs.state == GameScreen.State.RESULTS:
			break
		await tree.physics_frame
	eq(gs.state, GameScreen.State.RESULTS, "crash ends run")
	check(gs.revive(), "revive allowed")
	eq(Economy.gems(), 25, "first revive costs 5 gems")
	eq(gs.state, GameScreen.State.RUNNING, "run continues")
	eq(gs.fuel, 1.0, "tank refilled")
	Profile.data.wallet.gems = 0
	gs._end_run("crash")
	for i in 400:
		if gs.state == GameScreen.State.RESULTS:
			break
		await tree.physics_frame
	check(not gs.revive(), "cannot revive without gems")
	await _stop(gs)


func test_pause_resume() -> void:
	fresh_profile()
	Profile.data.tutorial.done = true
	var gs: GameScreen = await _start()
	gs.pause()
	check(tree.paused, "tree paused")
	check(gs.pause_menu.visible, "pause menu visible")
	gs.pause_menu.resume()
	check(not tree.paused, "resumed")
	await _stop(gs)


func test_pickups_and_boost() -> void:
	fresh_profile()
	Profile.data.tutorial.done = true
	var gs: GameScreen = await _start()
	var fuel_before := 0.3
	gs.fuel = fuel_before
	gs._on_pickup("fuel", 0, Vector2.ZERO)
	eq(gs.fuel, 1.0, "fuel can refills")
	gs._on_pickup("coin", 25, Vector2.ZERO)
	gs._on_pickup("coin", 100, Vector2.ZERO)
	eq(gs.run_coins, 125, "coins counted")
	gs._on_pickup("gem", 1, Vector2.ZERO)
	eq(gs.run_gems, 1, "gem counted")
	gs.boost_energy = 100.0
	gs._try_boost()
	check(gs.vehicle.boosting, "boost active")
	eq(gs.boost_energy, 50.0, "boost costs energy")
	gs._try_boost()
	eq(gs.boost_energy, 50.0, "cannot stack boosts")
	await _stop(gs)


func test_pending_run_recovery() -> void:
	fresh_profile()
	var s := {"run_id": "crashed_app_run", "map": "green_hills", "vehicle": "sarbon_mitti", "distance": 640, "coins": 300, "gems": 0, "trick_coins": 0, "checkpoints": 1, "jumps": 3, "flips": 0, "airtime": 2.0, "best_air": 0.9, "fuel_cans": 2, "boosts": 1, "wheelie": 0.0}
	var c0 := Economy.coins()
	var p: Dictionary = GameScreen.commit_summary(s)
	check(not p.is_empty(), "interrupted run is paid on recovery")
	eq(Economy.coins(), c0 + int(p.total), "coins added")
	check(GameScreen.commit_summary(s).is_empty(), "recovery cannot pay twice")
