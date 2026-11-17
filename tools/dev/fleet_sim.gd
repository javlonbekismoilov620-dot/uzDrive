## Dev/QA tool: drives EVERY vehicle with a bot on a map and reports distance,
## crashes and anomalies (stuck, fell through ground, NaN).
## Usage: godot --headless --fixed-fps 60 -s tools/dev/fleet_sim.gd -- <env_id> <seconds> [level] [filter]
extends SceneTree

var env: Dictionary
var dur := 30.0
var lv := 0
var queue: Array = []
var results: Array = []
var cur: Dictionary = {}

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var eid: String = a[0] if a.size() > 0 else "green_hills"
	dur = float(a[1]) if a.size() > 1 else 30.0
	lv = int(a[2]) if a.size() > 2 else 0
	var filt: String = a[3] if a.size() > 3 else ""
	for e in (Util.load_json("res://data/environments.json") as Dictionary).environments:
		if e.id == eid:
			env = e
	for v in (Util.load_json("res://data/vehicles.json") as Dictionary).vehicles:
		if filt == "" or v.id.contains(filt):
			queue.append(v)
	_next()

func _next() -> void:
	if cur.has("world"):
		# remove from the tree immediately so old bodies leave the physics space
		get_root().remove_child(cur.world)
		cur.world.queue_free()
	if queue.is_empty():
		_report()
		return
	var v: Dictionary = queue.pop_front()
	var world := Node2D.new()
	get_root().add_child(world)
	var terrain := TerrainManager.new()
	world.add_child(terrain)
	terrain.setup(env)
	terrain.update(0)
	var veh := Vehicle.new()
	var mx := VehicleSpec.max_level(v)
	var l := mini(lv, mx) if lv >= 0 else mx
	veh.setup(v, {"engine": l, "suspension": l, "tires": l, "fuel": l})
	veh.position = Vector2(6 * K.PPM, terrain.surface_y_px(6 * K.PPM) - veh.shape.ground_y - 6)
	veh.surface_provider = terrain.surface_for_x
	world.add_child(veh)
	cur = {"v": v, "world": world, "terrain": terrain, "veh": veh, "t": 0.0, "crash": "", "flips": 0, "air": 0.0, "max_x": 0.0, "stuck": 0.0, "nan": false, "below": false}
	veh.crashed.connect(func(r): cur.crash = r)
	veh.landed.connect(func(a, i, f):
		cur.flips += absi(f)
		cur.air = maxf(cur.air, a))

func _physics_process(delta: float) -> bool:
	if not cur.has("veh"):
		return false
	var veh: Vehicle = cur.veh
	cur.t += delta
	cur.terrain.update(veh.global_position.x)
	var ang := wrapf(veh.rotation, -PI, PI)
	veh.gas = 1.0
	veh.brake = 0.0
	if not veh.grounded:
		if ang < -0.35:
			veh.gas = 0.0
			veh.brake = 1.0
		elif ang < 0.3:
			veh.gas = 0.35
	elif ang < -0.75:
		veh.gas = 0.0
	if is_nan(veh.global_position.x) or is_nan(veh.global_position.y):
		cur.nan = true
	var x := veh.global_position.x / K.PPM
	if x > cur.max_x + 0.5:
		cur.max_x = x
		cur.stuck = 0.0
	else:
		cur.stuck += delta
	if veh.global_position.y > cur.terrain.surface_y_px(veh.global_position.x) + 3.0 * K.PPM:
		cur.below = true
	if cur.stuck > 7.9 and cur.stuck < 7.95:
		print("STUCK %s x=%.1f y=%.1f ang=%.2f contacts=%d v=%s grounded=%s gas=%.1f sleeping=%s freeze=%s surf_y=%.1f inside_tree=%s pm=%s" % [cur.v.id, x, veh.global_position.y, ang, veh.contacts, veh.linear_velocity, veh.grounded, veh.gas, veh.sleeping, veh.freeze, cur.terrain.surface_y_px(veh.global_position.x), veh.is_inside_tree(), veh.process_mode])
		var g: TerrainGenerator = cur.terrain.gen
		var near: Array = []
		for o in g.obstacles:
			if absf(o.x - x) < 6.0:
				near.append("%s@%.1f h%.2f" % [o.kind, o.x, o.size])
		for b in g.bridges:
			if x > b.x0 - 6 and x < b.x1 + 6:
				near.append("bridge %.0f-%.0f" % [b.x0, b.x1])
		for r in g.ramps:
			if x > r.x0 - 6 and x < r.x1 + 6:
				near.append("ramp %.0f-%.0f" % [r.x0, r.x1])
		var slopes: Array = []
		for dx in [-2, 0, 2, 4, 6]:
			slopes.append("%.2f" % g.slope_at(x + dx))
		print("  near: ", near, " slopes(x-2..x+6): ", slopes, " h: %.2f %.2f %.2f" % [g.height_at(x), g.height_at(x + 3), g.height_at(x + 6)])
		var space := veh.get_world_2d().direct_space_state
		var q := PhysicsPointQueryParameters2D.new()
		q.position = veh.global_position
		q.collision_mask = 0xFFFF
		print("  bodies at point: ", space.intersect_point(q).map(func(r): return r.collider.get_path() if r.collider else null))
		print("  world count: ", get_root().get_child_count())
	if cur.crash != "" or cur.t >= dur or cur.nan or cur.below or cur.stuck > 8.0:
		results.append({"id": cur.v.id, "dist": cur.max_x - 6.0, "crash": cur.crash, "stuck": cur.stuck > 8.0, "nan": cur.nan, "below": cur.below, "t": cur.t, "flips": cur.flips, "air": cur.air})
		_next()
	return false

func _report() -> void:
	var bad := 0
	for r in results:
		var flag := ""
		if r.nan or r.below:
			flag = "  <-- BROKEN"
			bad += 1
		elif r.stuck:
			flag = "  (stuck)"
		elif r.crash != "":
			flag = "  (%s @ %.0fs)" % [r.crash, r.t]
		print("%-22s %7.1f m  air %.1fs flips %d%s" % [r.id, r.dist, r.air, r.flips, flag])
	print("FLEET %s: %d vehicles, %d broken" % [env.id, results.size(), bad])
	quit()
