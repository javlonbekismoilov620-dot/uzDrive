## A single run: builds the world for the selected map + vehicle and runs the
## rules (fuel, boost, tricks, pickups, checkpoints, map goal, crash/fuel end,
## revive, payout). Rewards are committed exactly once, and an in-progress
## run is snapshotted so it is still paid if the app is killed.
class_name GameScreen
extends Node

enum State { INTRO, RUNNING, ENDING, RESULTS }

const P := K.PPM

var params: Dictionary = {}
var env: Dictionary
var vdef: Dictionary
var map_id := ""
var vehicle_id := ""

var world: Node2D
var backdrop: Backdrop
var terrain: TerrainManager
var pickups: PickupLayer
var vehicle: Vehicle
var camera: Camera2D
var effects: Effects
var hud: Hud
var pause_menu: PauseMenu
var results: ResultsPanel
var engine_audio: AudioStreamPlayer
var headlight: PointLight2D

var state := State.INTRO
var run_id := ""
var start_x := 0.0
var distance := 0.0
var fuel := 1.0
var run_coins := 0
var run_gems := 0
var trick_coins := 0
var checkpoints := 0
var next_checkpoint := 500.0
var goal_reached := false
var jumps := 0
var flips := 0
var airtime_total := 0.0
var best_air := 0.0
var fuel_cans := 0
var boosts_used := 0
var wheelie_total := 0.0
var revives := 0
var end_reason := ""
var best_before := 0

var boost_energy := 50.0
var boost_active := 0.0
var boost_cooldown := 0.0
var _boost_cfg: Dictionary
var _tricks: Dictionary

var _wheelie_t := 0.0
var _wheelie_award := 0.0
var _stall_t := 0.0
var _end_timer := 0.0
var _shake := 0.0
var _coin_combo := 0
var _coin_combo_t := 0.0
var _last_dist_for_boost := 0.0
var _tutorial_step := -1
var _tutorial_t := 0.0
var _committed := false
var _low_fuel_warned := false
var _snapshot_t := 0.0


func _ready() -> void:
	map_id = params.get("map", Profile.selected_map())
	vehicle_id = params.get("vehicle", Profile.selected_vehicle())
	env = DB.env(map_id)
	vdef = DB.vehicle(vehicle_id)
	if env.is_empty():
		map_id = DB.first_env_id()
		env = DB.env(map_id)
	if vdef.is_empty() or not Profile.owns(vehicle_id):
		vehicle_id = Profile.selected_vehicle()
		vdef = DB.vehicle(vehicle_id)
	_boost_cfg = DB.eco("boost", {})
	_tricks = DB.eco("tricks", {})
	boost_energy = float(_boost_cfg.get("start", 50))
	best_before = Profile.best_distance(map_id)
	run_id = "%s_%d_%d" % [map_id, int(Time.get_unix_time_from_system()), randi() % 100000]
	next_checkpoint = float(env.get("checkpoint_every", 500))
	_build_world()
	_build_ui()
	Audio.music(env.get("music", "drive_a"))
	Events.run_started.emit(map_id, vehicle_id)
	if not bool(Profile.data.tutorial.get("done", false)):
		_tutorial_step = 0
	state = State.RUNNING


func _build_world() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	var quality: String = Profile.setting("quality", "high")
	backdrop = Backdrop.new()
	world.add_child(backdrop)
	backdrop.setup(env, world, quality)
	terrain = TerrainManager.new()
	world.add_child(terrain)
	terrain.setup(env)
	terrain.update(0.0)
	effects = Effects.new()
	world.add_child(effects)

	vehicle = Vehicle.new()
	vehicle.setup(vdef, Profile.levels(vehicle_id))
	start_x = 6.0 * P
	vehicle.position = Vector2(start_x, terrain.surface_y_px(start_x) - vehicle.shape.ground_y - 6.0)
	vehicle.surface_provider = terrain.surface_for_x
	world.add_child(vehicle)
	vehicle.crashed.connect(_on_crash)
	vehicle.landed.connect(_on_landed)

	# Pickups live on their own canvas layer that follows the camera, so night
	# darkness (CanvasModulate) never hides coins and fuel.
	var pl := CanvasLayer.new()
	pl.follow_viewport_enabled = true
	pl.layer = 1
	add_child(pl)
	pickups = PickupLayer.new()
	pl.add_child(pickups)
	pickups.setup(terrain.gen)
	pickups.vehicle = vehicle
	pickups.collected.connect(_on_pickup)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.zoom = Vector2.ONE
	world.add_child(camera)
	camera.global_position = vehicle.global_position + Vector2(220, -80)
	camera.reset_smoothing()

	if env.get("night", false):
		var cm := CanvasModulate.new()
		cm.color = Util.col(env.visual.get("ambient", "#56628f"))
		world.add_child(cm)
		headlight = PointLight2D.new()
		headlight.texture = _cone_texture()
		headlight.texture_scale = 1.6
		headlight.energy = 1.35
		headlight.color = Color("fff1c9")
		headlight.offset = Vector2(230, 0)
		headlight.position = vehicle.shape.headlight
		vehicle.add_child(headlight)
		var glow := PointLight2D.new()
		glow.texture = _radial_texture()
		glow.texture_scale = 3.0
		glow.energy = 0.55
		glow.color = Color("9fb4ff")
		vehicle.add_child(glow)

	engine_audio = AudioStreamPlayer.new()
	engine_audio.bus = "Engine"
	engine_audio.stream = Audio.engine_stream(vdef.get("engine_sound", {}).get("profile", "i4"))
	engine_audio.volume_db = -8.0
	add_child(engine_audio)
	engine_audio.play()


func _build_ui() -> void:
	hud = Hud.new()
	add_child(hud)
	hud.pause_pressed.connect(pause)
	hud.boost_pressed.connect(_try_boost)
	hud.fuel_gauge.electric = vdef.get("specs", {}).get("fuel_unit", "L") == "kWh"
	pause_menu = PauseMenu.new()
	pause_menu.game = self
	add_child(pause_menu)
	results = ResultsPanel.new()
	results.game = self
	add_child(results)
	_update_hud()


# ------------------------------------------------------------------ loop
func _physics_process(delta: float) -> void:
	if vehicle == null:
		return
	terrain.update(vehicle.global_position.x)
	match state:
		State.RUNNING:
			_run_step(delta)
		State.ENDING:
			_end_timer -= delta
			vehicle.gas = 0.0
			vehicle.brake = 0.0
			if _end_timer <= 0.0:
				_show_results()
	_update_camera(delta)
	_update_audio()
	_update_effects()


func _input_gas() -> float:
	return 1.0 if (hud.gas_pedal.is_down or Input.is_action_pressed("gas")) else 0.0


func _input_brake() -> float:
	return 1.0 if (hud.brake_pedal.is_down or Input.is_action_pressed("brake")) else 0.0


func _run_step(delta: float) -> void:
	var g := _input_gas()
	var b := _input_brake()
	if fuel <= 0.0:
		g = 0.0
	vehicle.gas = g
	vehicle.brake = b
	if Input.is_action_just_pressed("boost"):
		_try_boost()
	if Input.is_action_just_pressed("pause"):
		pause()
		return

	# distance
	var x_m := (vehicle.global_position.x - start_x) / P
	if x_m > distance:
		var gained := x_m - distance
		distance = x_m
		boost_energy = minf(boost_energy + gained * float(_boost_cfg.get("per_meter", 0.15)), float(_boost_cfg.get("max", 100)))

	# fuel
	var burn := (0.22 + 0.78 * vehicle.throttle_used) / maxf(vehicle.spec.fuel_time, 5.0)
	if boost_active > 0.0:
		burn *= 1.5
	fuel = maxf(fuel - burn * delta, 0.0)
	if fuel < 0.2 and not _low_fuel_warned:
		_low_fuel_warned = true
		Audio.sfx("low_fuel")
	hud.set_low_fuel(fuel < 0.2 and fuel > 0.0)

	# boost timers
	if boost_active > 0.0:
		boost_active = maxf(boost_active - delta, 0.0)
		if boost_active <= 0.0:
			vehicle.boosting = false
			boost_cooldown = float(_boost_cfg.get("cooldown", 3.0))
	elif boost_cooldown > 0.0:
		boost_cooldown = maxf(boost_cooldown - delta, 0.0)

	# wheelie
	if vehicle.rear_only and vehicle.speed_ms > 2.0:
		_wheelie_t += delta
		wheelie_total += delta
		if _wheelie_t - _wheelie_award >= float(_tricks.get("wheelie_time", 2.0)):
			_wheelie_award = _wheelie_t
			_award_trick(Loc.t("trick_wheelie"), int(_tricks.get("wheelie", 75)), float(_boost_cfg.get("wheelie", 12)))
	else:
		_wheelie_t = 0.0
		_wheelie_award = 0.0

	# checkpoints / goal
	if distance >= next_checkpoint:
		checkpoints += 1
		var bonus := int(round(float(DB.eco("checkpoint_bonus", 150)) * checkpoints * float(env.get("reward_mult", 1.0))))
		hud.banner(Loc.t("hud_checkpoint"), Loc.t("hud_checkpoint_bonus", Loc.num(bonus)), Color("2bd576"), 1.4)
		Audio.sfx("checkpoint")
		next_checkpoint += float(env.get("checkpoint_every", 500))
		fuel = maxf(fuel, 0.0)
		_snapshot_pending()
	if not goal_reached and distance >= float(env.get("goal_m", 1500)):
		goal_reached = true
		var r := Economy.complete_map(map_id)
		var sub := ""
		if not r.is_empty():
			sub = Loc.t("hud_map_reward", [Loc.num(int(r.get("coins", 0))), int(r.get("gems", 0))])
		hud.banner(Loc.t("hud_map_complete"), sub, Color("ffc93c"), 2.6)
		Audio.sfx("complete")
		Audio.vibrate(80)

	# out of fuel → wait until the car stops
	if fuel <= 0.0:
		if absf(vehicle.speed_ms) < 0.6 or not vehicle.grounded and false:
			_stall_t += delta
		else:
			_stall_t = maxf(_stall_t - delta * 0.5, 0.0)
		if _stall_t > 1.6:
			_end_run("fuel")
	# fell off the world (safety)
	if vehicle.global_position.y > terrain.surface_y_px(vehicle.global_position.x) + 40.0 * P:
		_end_run("crash")

	_tutorial(delta)
	_coin_combo_t -= delta
	_snapshot_t += delta
	_update_hud()


func _update_hud() -> void:
	hud.fuel_gauge.fuel = fuel
	hud.coin_label.text = Loc.num(run_coins)
	hud.gem_label.text = str(run_gems)
	hud.dist_label.text = Loc.meters(distance)
	var goal := float(env.get("goal_m", 1500))
	if goal_reached:
		hud.progress.max_value = float(env.get("checkpoint_every", 500))
		hud.progress.value = fmod(distance, hud.progress.max_value)
	else:
		hud.progress.max_value = goal
		hud.progress.value = distance
	var best := maxi(best_before, int(distance))
	hud.best_label.text = Loc.t("hud_best", Loc.meters(best)) + ("" if goal_reached else "  •  " + Loc.t("hud_goal", Loc.meters(goal)))
	hud.rpm_gauge.rpm = vehicle.rpm
	hud.rpm_gauge.gear = vehicle.gear
	hud.rpm_gauge.speed_kmh = absf(vehicle.speed_ms) * 3.6
	hud.boost_btn.energy = boost_energy
	hud.boost_btn.max_energy = float(_boost_cfg.get("max", 100))
	hud.boost_btn.cost = float(_boost_cfg.get("cost", 50))
	hud.boost_btn.cooldown = boost_cooldown / maxf(float(_boost_cfg.get("cooldown", 3.0)), 0.01)
	hud.boost_btn.active = boost_active / maxf(float(_boost_cfg.get("duration", 2.5)), 0.01)


func _update_camera(delta: float) -> void:
	var v := vehicle.linear_velocity
	var ahead := clampf(v.x * 0.32, -140.0, 320.0)
	var target := vehicle.global_position + Vector2(140.0 + ahead, -70.0 + clampf(v.y * 0.08, -60, 80))
	camera.global_position = target
	var spd := absf(vehicle.speed_ms)
	var z := lerpf(1.0, 0.74, clampf((spd - 6.0) / 26.0, 0.0, 1.0))
	if not vehicle.grounded and vehicle.air_time > 0.4:
		z = minf(z, 0.82)
	if boost_active > 0.0:
		z *= 0.94
	camera.zoom = camera.zoom.lerp(Vector2(z, z), 1.0 - exp(-delta * 2.0))
	if _shake > 0.0:
		_shake = maxf(_shake - delta * 2.5, 0.0)
		camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 14.0 * _shake
	else:
		camera.offset = Vector2.ZERO


func _update_audio() -> void:
	if engine_audio == null:
		return
	var es: Dictionary = vdef.get("engine_sound", {})
	var base := float(es.get("pitch", 1.0))
	var target_pitch := base * (0.55 + vehicle.rpm * 1.25)
	engine_audio.pitch_scale = lerpf(engine_audio.pitch_scale, maxf(target_pitch, 0.3), 0.25)
	var vol := -11.0 + vehicle.throttle_used * 6.0
	if state != State.RUNNING:
		vol = -30.0 if fuel <= 0.0 else -16.0
	engine_audio.volume_db = lerpf(engine_audio.volume_db, vol, 0.15)


func _update_effects() -> void:
	var slipping := false
	var contact := Vector2.ZERO
	for ws in vehicle.wheel_states:
		if ws.contact and ws.driven:
			contact = ws.point
			if ws.slip or (absf(vehicle.speed_ms) > 4.0 and vehicle.throttle_used > 0.5):
				slipping = true
	effects.dust.emitting = slipping and contact != Vector2.ZERO
	if contact != Vector2.ZERO:
		effects.dust.global_position = contact
		effects.dust.direction = Vector2(-signf(vehicle.speed_ms + 0.01), -0.7)
	effects.smoke.emitting = state == State.RUNNING and fuel > 0.0
	effects.smoke.global_position = vehicle.to_global(vehicle.shape.exhaust)
	effects.smoke.direction = -vehicle.global_transform.x
	effects.flame.emitting = boost_active > 0.0
	effects.flame.global_position = vehicle.to_global(vehicle.shape.exhaust)
	effects.flame.direction = -vehicle.global_transform.x


# ------------------------------------------------------------------ events
func _on_pickup(kind: String, value: int, pos: Vector2) -> void:
	match kind:
		"coin":
			run_coins += value
			if _coin_combo_t > 0.0:
				_coin_combo = mini(_coin_combo + 1, 10)
			else:
				_coin_combo = 0
			_coin_combo_t = 0.45
			Audio.sfx("coin" if value < 100 else "coin_big", -4.0, 1.0 + _coin_combo * 0.04)
			effects.burst(pos, Color("ffd23f"), 8)
		"gem":
			run_gems += value
			Audio.sfx("gem")
			effects.burst(pos, Color("38d9f5"), 20)
			hud.popup("+%d %s" % [value, Loc.t("word_gem")], Color("38d9f5"))
		"fuel":
			fuel = 1.0
			fuel_cans += 1
			_low_fuel_warned = false
			Audio.sfx("fuel")
			effects.burst(pos, Color("ff6b6b"), 16)
			hud.popup(Loc.t("hud_refuel"), Color("ff6b6b"), 50)
		"boost":
			boost_energy = minf(boost_energy + float(_boost_cfg.get("pickup", 40)), float(_boost_cfg.get("max", 100)))
			Audio.sfx("boost_pickup")
			effects.burst(pos, Color("4d8bff"), 16)


func _on_landed(airtime: float, impact: float, f: int) -> void:
	if state != State.RUNNING:
		return
	if airtime >= 0.6:
		jumps += 1
	airtime_total += airtime
	best_air = maxf(best_air, airtime)
	if impact > 7.0:
		Audio.sfx("land_hard", -2.0)
		_shake = minf(0.3 + impact * 0.03, 1.0)
		Audio.vibrate(35)
	elif airtime > 0.35:
		Audio.sfx("land", -6.0)
	if f != 0 or airtime >= float(_tricks.get("big_air_time", 1.4)):
		# Confirm the landing was survived before paying the trick.
		await get_tree().create_timer(0.3).timeout
		if state != State.RUNNING or vehicle.is_crashed:
			return
		if f != 0:
			var n := absi(f)
			flips += n
			var word := Loc.t("trick_backflip") if f < 0 else Loc.t("trick_frontflip")
			var reward := int(_tricks.get("flip", 150)) * n if n < 2 else int(_tricks.get("double_flip", 450)) * (n - 1)
			if n >= 2:
				word = Loc.t("trick_multiflip", n)
			_award_trick(word, reward, float(_boost_cfg.get("flip", 30)) * n)
			Audio.sfx("flip")
		if airtime >= float(_tricks.get("huge_air_time", 2.4)):
			_award_trick(Loc.t("trick_huge_air"), int(_tricks.get("huge_air", 250)), float(_boost_cfg.get("air", 12)) * 2.0, 60)
		elif airtime >= float(_tricks.get("big_air_time", 1.4)):
			_award_trick(Loc.t("trick_big_air"), int(_tricks.get("big_air", 100)), float(_boost_cfg.get("air", 12)), 60)


func _award_trick(label: String, coins: int, energy: float, y := 0.0) -> void:
	trick_coins += coins
	boost_energy = minf(boost_energy + energy, float(_boost_cfg.get("max", 100)))
	hud.popup("%s  +%s" % [label, Loc.num(coins)], Color("ffc93c"), y)


func _on_crash(reason: String) -> void:
	if state != State.RUNNING:
		return
	Audio.sfx("crash")
	Audio.vibrate(120)
	_shake = 1.0
	effects.burst(vehicle.global_position, Color("ffcf6b"), 24)
	_end_run(reason)


func _try_boost() -> void:
	if state != State.RUNNING or fuel <= 0.0:
		return
	var cost := float(_boost_cfg.get("cost", 50))
	if boost_energy < cost or boost_cooldown > 0.0 or boost_active > 0.0:
		return
	boost_energy -= cost
	boost_active = float(_boost_cfg.get("duration", 2.5))
	vehicle.boosting = true
	boosts_used += 1
	Audio.sfx("boost")
	Audio.vibrate(25)
	_shake = 0.25


# ------------------------------------------------------------------ end / revive
func _end_run(reason: String) -> void:
	if state != State.RUNNING:
		return
	end_reason = reason
	state = State.ENDING
	vehicle.input_enabled = false
	vehicle.boosting = false
	boost_active = 0.0
	hud.set_controls_visible(false)
	hud.clear_hint()
	hud.set_low_fuel(false)
	if reason == "fuel":
		hud.banner(Loc.t("end_fuel"), "", Color("ff4d5a"), 1.0)
		_end_timer = 1.2
	else:
		hud.banner(Loc.t("end_crash"), "", Color("ff4d5a"), 1.0)
		_end_timer = 1.4
		Engine.time_scale = 0.45
		get_tree().create_timer(0.6, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)


func summary() -> Dictionary:
	return {
		"run_id": run_id,
		"map": map_id,
		"vehicle": vehicle_id,
		"distance": int(distance),
		"coins": run_coins,
		"gems": run_gems,
		"trick_coins": trick_coins,
		"checkpoints": checkpoints,
		"jumps": jumps,
		"flips": flips,
		"airtime": airtime_total,
		"best_air": best_air,
		"fuel_cans": fuel_cans,
		"boosts": boosts_used,
		"wheelie": wheelie_total,
		"reason": end_reason,
		"goal": goal_reached,
	}


func _show_results() -> void:
	state = State.RESULTS
	Engine.time_scale = 1.0
	_snapshot_pending()
	var s := summary()
	var payout := Economy.compute_run_payout(s)
	var new_best := int(distance) > best_before
	results.show_results(s, payout, new_best, _can_revive(), Economy.revive_cost(revives))
	Audio.sfx("reward" if payout.total > 0 else "click")


func _can_revive() -> bool:
	return revives < 3


func revive() -> bool:
	var cost := Economy.revive_cost(revives)
	if not _can_revive() or not Economy.spend(cost, "gems", "revive"):
		return false
	revives += 1
	fuel = 1.0
	_low_fuel_warned = false
	var x := vehicle.global_position.x
	var y := terrain.surface_y_px(x)
	vehicle.linear_velocity = Vector2.ZERO
	vehicle.angular_velocity = 0.0
	vehicle.global_transform = Transform2D(0.0, Vector2(x, y - vehicle.shape.ground_y - 24.0))
	vehicle.is_crashed = false
	vehicle.input_enabled = true
	_stall_t = 0.0
	hud.set_controls_visible(true)
	state = State.RUNNING
	Audio.sfx("upgrade")
	return true


## Pays the run (idempotent) and reports statistics. Called when leaving results.
func commit() -> void:
	if _committed:
		return
	_committed = true
	commit_summary(summary())
	Profile.data.erase("pending_run")
	Profile.save_now()


## Shared by normal runs and by crash-recovery of a pending run on startup.
static func commit_summary(s: Dictionary) -> Dictionary:
	var payout := Economy.compute_run_payout(s)
	if not Economy.commit_run(str(s.run_id), payout):
		return {}
	Profile.record_distance(str(s.map), int(s.distance))
	Events.stat.emit("run", 1)
	Events.stat.emit("distance", float(s.distance))
	Events.stat.emit("run_distance", float(s.distance))
	Events.stat.emit("coins", float(s.coins))
	Events.stat.emit("jump", float(s.jumps))
	Events.stat.emit("flip", float(s.flips))
	Events.stat.emit("airtime", float(s.airtime))
	Events.stat.emit("air_single", float(s.best_air))
	Events.stat.emit("fuel", float(s.fuel_cans))
	Events.stat.emit("boost", float(s.boosts))
	Events.stat.emit("checkpoint", float(s.checkpoints))
	Events.stat.emit("wheelie", float(s.wheelie))
	Events.stat.emit("gem", float(s.gems))
	Events.run_finished.emit(s)
	return payout


func _snapshot_pending() -> void:
	if _committed:
		return
	Profile.data["pending_run"] = summary()
	Profile.save_now()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if state == State.RUNNING:
				pause()
			if state != State.INTRO:
				_snapshot_pending()
		NOTIFICATION_WM_CLOSE_REQUEST:
			if state != State.INTRO and not _committed:
				_snapshot_pending()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if state == State.RUNNING:
				pause()
			elif get_tree().paused:
				pause_menu.resume()


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false


# ------------------------------------------------------------------ navigation
func pause() -> void:
	if state != State.RUNNING or get_tree().paused:
		return
	hud.gas_pedal.force_release()
	hud.brake_pedal.force_release()
	get_tree().paused = true
	pause_menu.open()


func restart() -> void:
	commit()
	get_tree().paused = false
	UI.go("game", {"map": map_id, "vehicle": vehicle_id})


func exit_to(screen: String) -> void:
	commit()
	get_tree().paused = false
	UI.go(screen)


# ------------------------------------------------------------------ tutorial
func _tutorial(delta: float) -> void:
	if _tutorial_step < 0:
		return
	_tutorial_t += delta
	match _tutorial_step:
		0:
			if _tutorial_t > 0.4 and not hud._hint.visible:
				hud.show_hint(Loc.t("tut_gas"), hud.gas_pedal)
			if distance > 12.0:
				_next_tut()
		1:
			if _tutorial_t > 0.5 and not hud._hint.visible:
				hud.show_hint(Loc.t("tut_brake"), hud.brake_pedal)
			if _tutorial_t > 4.5 or (_input_brake() > 0.0 and _tutorial_t > 1.0):
				_next_tut()
		2:
			if _tutorial_t > 0.5 and not hud._hint.visible:
				hud.show_hint(Loc.t("tut_air"))
			if _tutorial_t > 6.0:
				_next_tut()
		3:
			if distance > 110.0 and not hud._hint.visible:
				hud.show_hint(Loc.t("tut_fuel"), hud.fuel_gauge)
				_tutorial_t = 0.0
			if hud._hint.visible and _tutorial_t > 5.0:
				_next_tut()
		4:
			if boost_energy >= float(_boost_cfg.get("cost", 50)) and not hud._hint.visible and _tutorial_t > 2.0:
				hud.show_hint(Loc.t("tut_boost"), hud.boost_btn)
				_tutorial_t = 0.0
			if hud._hint.visible and (_tutorial_t > 5.0 or boost_active > 0.0):
				hud.clear_hint()
				_tutorial_step = -1
				Profile.data.tutorial.done = true
				Profile.touch()


func _next_tut() -> void:
	hud.clear_hint()
	_tutorial_step += 1
	_tutorial_t = 0.0


# ------------------------------------------------------------------ textures
func _cone_texture() -> Texture2D:
	var w := 256
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var dx := float(x) / w
			var dy := absf(float(y) - h * 0.5) / (h * 0.5)
			var spread := 0.15 + dx * 0.85
			var a := clampf(1.0 - dy / spread, 0.0, 1.0) * clampf(1.0 - dx, 0.0, 1.0) * clampf(dx * 6.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _radial_texture() -> Texture2D:
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var d := Vector2(x - s * 0.5, y - s * 0.5).length() / (s * 0.5)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)
