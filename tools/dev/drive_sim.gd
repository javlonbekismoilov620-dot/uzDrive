## Dev tool: headless driving simulation with a simple bot driver.
## Usage: godot --headless --fixed-fps 60 -s tools/dev/drive_sim.gd -- <vehicle_id|json> <env_id> <seconds> [shot.png] [levels]
extends SceneTree

var veh: Vehicle
var terrain: TerrainManager
var cam: Camera2D
var t := 0.0
var dur := 40.0
var shots: Array = []
var shot_base := ""
var log_every := 2.0
var _next_log := 0.0
var crashed_reason := ""
var max_air := 0.0
var flips := 0
var landings := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var vid: String = args[0] if args.size() > 0 else "sarbon_mitti"
	var eid: String = args[1] if args.size() > 1 else "green_hills"
	dur = float(args[2]) if args.size() > 2 else 40.0
	shot_base = args[3] if args.size() > 3 else ""
	var lv := int(args[4]) if args.size() > 4 else 0
	var vdef: Dictionary
	var envs: Dictionary = Util.load_json("res://data/environments.json")
	var env: Dictionary = {}
	for e in envs.environments:
		if e.id == eid:
			env = e
	var vehicles: Dictionary = Util.load_json("res://data/vehicles.json")
	for v in vehicles.vehicles:
		if v.id == vid:
			vdef = v
	var world := Node2D.new()
	get_root().add_child(world)
	terrain = TerrainManager.new()
	world.add_child(terrain)
	terrain.setup(env)
	terrain.update(0)
	veh = Vehicle.new()
	veh.setup(vdef, {"engine": lv, "suspension": lv, "tires": lv, "fuel": lv})
	veh.position = Vector2(6 * K.PPM, terrain.surface_y_px(6 * K.PPM) - 60)
	veh.surface_provider = terrain.surface_for_x
	world.add_child(veh)
	veh.crashed.connect(func(r): crashed_reason = r)
	veh.landed.connect(func(a, i, f):
		landings += 1
		max_air = maxf(max_air, a)
		flips += absi(f))
	if shot_base != "":
		cam = Camera2D.new()
		cam.zoom = Vector2(0.85, 0.85)
		world.add_child(cam)
		var bg := CanvasLayer.new()
		bg.layer = -5
		var sky := ColorRect.new()
		sky.color = Color("9fd3f2")
		sky.size = Vector2(4000, 3000)
		bg.add_child(sky)
		world.add_child(bg)
		DisplayServer.window_set_size(Vector2i(1280, 720))
		shots = [3.0, 8.0, 15.0, 25.0]

func _physics_process(delta: float) -> bool:
	t += delta
	if veh == null:
		return false
	terrain.update(veh.global_position.x)
	# bot: full gas; balance in air; ease off if nose too high on ground
	var ang := wrapf(veh.rotation, -PI, PI)
	veh.gas = 1.0
	veh.brake = 0.0
	if not veh.grounded:
		var slope := 0.0
		if ang < -0.35:
			veh.gas = 0.0; veh.brake = 1.0
		elif ang > 0.45:
			veh.gas = 1.0
		else:
			veh.gas = 0.4
	else:
		if ang < -0.9:
			veh.gas = 0.0
	if cam:
		cam.global_position = veh.global_position + Vector2(250, -60)
	if t >= _next_log:
		_next_log += log_every
		print("t=%5.1f x=%7.1fm v=%5.1fm/s ang=%5.2f contacts=%d rpm=%.2f gear=%d" % [t, veh.global_position.x / K.PPM, veh.speed_ms, ang, veh.contacts, veh.rpm, veh.gear])
	if crashed_reason != "" or t >= dur:
		print("RESULT dist=%.1f crashed=%s max_air=%.2f flips=%d landings=%d" % [veh.global_position.x / K.PPM, crashed_reason, max_air, flips, landings])
		quit()
	return false

func _process(_d: float) -> bool:
	if shots.size() > 0 and t >= shots[0]:
		var st: float = shots.pop_front()
		_shot.call_deferred(st)
	return false

func _shot(st: float) -> void:
	await RenderingServer.frame_post_draw
	var path := shot_base.replace(".png", "_%d.png" % int(st))
	get_root().get_texture().get_image().save_png(path)
	print("shot ", path)
