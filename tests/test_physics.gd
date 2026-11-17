extends TestCase
## Physics integration tests on a deterministic flat test track.


func _flat_env() -> Dictionary:
	return {"id": "test_flat", "terrain": {"seed": 1, "start_flat": 400, "amp": 0.0, "amp_max": 0.0, "features": {"flat": 1.0}},
		"visual": {}, "pickups": {"fuel_first": 99999, "gem_every": 99999, "boost_every": 99999, "coin_gap": [9999, 9999]}, "surface": {"grip": 1.0, "roll": 0.015}}


func _hill_env(slope: float) -> Dictionary:
	var e := _flat_env()
	e.terrain = {"seed": 2, "start_flat": 12, "amp": 0.0, "amp_max": 0.0, "features": {"flat": 1.0}}
	e["_ramp"] = slope
	return e


func _drive(vid: String, levels: Dictionary, seconds: float, env: Dictionary) -> float:
	var world := Node2D.new()
	tree.root.add_child(world)
	var terrain := TerrainManager.new()
	world.add_child(terrain)
	terrain.setup(env)
	if env.has("_ramp"):
		# replace the profile after 12 m by a constant slope
		var g: TerrainGenerator = terrain.gen
		g.ensure(400)
		var y := 0.0
		for i in range(int(12.0 / TerrainGenerator.STEP), g.ys.size()):
			y += env._ramp * TerrainGenerator.STEP
			g.ys[i] = y
	terrain.update(0)
	var v := Vehicle.new()
	v.setup(DB.vehicle(vid), levels)
	v.position = Vector2(4 * K.PPM, terrain.surface_y_px(4 * K.PPM) - v.shape.ground_y - 4)
	v.surface_provider = terrain.surface_for_x
	world.add_child(v)
	var frames := int(seconds * 60)
	for i in frames:
		v.gas = 1.0
		terrain.update(v.global_position.x)
		await tree.physics_frame
	var x := v.global_position.x / K.PPM
	tree.root.remove_child(world)
	world.queue_free()
	return x


func test_spec_upgrades_monotonic() -> void:
	for vid in ["sarbon_mitti", "sarbon_burgut", "dev_monster"]:
		var v: Dictionary = DB.vehicle(vid)
		var base := VehicleSpec.build(v, {})
		var mx := VehicleSpec.max_level(v)
		var e := VehicleSpec.build(v, {"engine": mx})
		var s := VehicleSpec.build(v, {"suspension": mx})
		var t := VehicleSpec.build(v, {"tires": mx})
		var f := VehicleSpec.build(v, {"fuel": mx})
		check(e.accel > base.accel * 1.3, "%s engine upgrade raises acceleration >30%%" % vid)
		check(e.top_speed > base.top_speed, "%s engine raises top speed" % vid)
		check(s.damping_ratio > base.damping_ratio and s.travel > base.travel, "%s suspension upgrade" % vid)
		check(t.grip > base.grip * 1.3, "%s tyres raise grip >30%%" % vid)
		check(f.fuel_time > base.fuel_time * 1.7, "%s fuel tank raises fuel time" % vid)


func test_vehicle_drives_forward() -> void:
	var x: float = await _drive("sarbon_mitti", {}, 5.0, _flat_env())
	check(x > 40.0, "starter covers >36 m in 5 s on flat ground (x=%.1f)" % x)


func test_engine_upgrade_is_noticeable() -> void:
	var x0: float = await _drive("sarbon_mitti", {}, 3.0, _flat_env())
	var x1: float = await _drive("sarbon_mitti", {"engine": 8}, 3.0, _flat_env())
	check(x1 > x0 + 3.0, "maxed engine is clearly faster over 3 s (%.1f vs %.1f m)" % [x1, x0])


func test_upgrades_help_climbing() -> void:
	var env := _hill_env(0.5)
	var x0: float = await _drive("sarbon_mitti", {}, 8.0, env)
	var x1: float = await _drive("sarbon_mitti", {"engine": 8, "tires": 8}, 8.0, env)
	check(x1 > x0 + 4.0, "engine+tyres climb a 27° slope much further (%.1f vs %.1f m)" % [x1, x0])


func test_awd_beats_fwd_on_slippery_climb() -> void:
	# Same car, only the drivetrain differs: AWD must out-climb FWD on a
	# slippery slope (traction-limited situation).
	var env := _hill_env(0.42)
	env.surface = {"grip": 0.55, "roll": 0.02}
	var fwd: float = await _drive("sarbon_nafis", {}, 8.0, env)
	var awd_def: Dictionary = DB.vehicle("sarbon_nafis").duplicate(true)
	awd_def.id = "nafis_awd_test"
	awd_def.specs.drive = "awd"
	DB.vehicle_map[awd_def.id] = awd_def
	var awd: float = await _drive("nafis_awd_test", {}, 8.0, env)
	DB.vehicle_map.erase(awd_def.id)
	check(awd > fwd + 2.0, "AWD out-climbs FWD on a slippery slope (%.1f vs %.1f m)" % [awd, fwd])
