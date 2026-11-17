## Physics-driven vehicle.
##
## Model: a RigidBody2D chassis with shape-cast suspension. For every wheel a
## circle (the tyre) is swept along the suspension axis to find the ground; a
## spring-damper pushes the chassis up and a traction force (limited by
## grip x normal load) drives/brakes it at the contact patch. Because drive
## forces act below the centre of mass, accelerating naturally lifts the nose
## (wheelies) and braking dips it. While airborne the player can rotate the car
## (gas = lean back, brake = lean forward).
## All tunables come from VehicleSpec, so upgrades change the real physics.
class_name Vehicle
extends RigidBody2D

signal crashed(reason: String)
signal landed(airtime: float, impact: float, flips: int)
signal took_off

const GEAR_EDGES := [0.0, 0.16, 0.34, 0.54, 0.76, 1.3]

var spec: VehicleSpec
var shape: VehicleShape
var visual: VehicleVisual
var vdef: Dictionary

# ---- input (set by controller) ----
var gas := 0.0
var brake := 0.0
var boosting := false
var input_enabled := true

# ---- public state ----
var wheel_states: Array = []
var contacts := 0
var grounded := false
var air_time := 0.0
var air_rot := 0.0
var speed_ms := 0.0           ## forward speed along chassis axis (m/s)
var rpm := 0.0                ## 0..1
var gear := 1
var throttle_used := 0.0      ## 0..1 effective throttle (for fuel use)
var is_crashed := false
var last_impact := 0.0
var surface_provider: Callable  ## func(x_px: float) -> Dictionary {grip, roll}
var front_only := false
var rear_only := false

var _g := 480.0
var _query := PhysicsShapeQueryParameters2D.new()
var _wheel_shapes: Array[CircleShape2D] = []
var _landing_t := 0.0
var _upside_t := 0.0
var _was_grounded := true
var _roof: Area2D


func setup(def: Dictionary, levels: Dictionary) -> void:
	vdef = def
	spec = VehicleSpec.build(def, levels)
	shape = VehicleShape.get_for(def)
	mass = spec.mass
	gravity_scale = float(def.get("handling", {}).get("gravity_scale", 1.0))
	_g = float(ProjectSettings.get_setting("physics/2d/default_gravity", 480.0)) * gravity_scale
	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = shape.com
	collision_layer = K.LAYER_VEHICLE
	collision_mask = K.LAYER_TERRAIN | K.LAYER_PROPS
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	can_sleep = false
	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = 0.0
	angular_damp = 0.15
	var mat := PhysicsMaterial.new()
	mat.friction = 0.3
	mat.bounce = 0.02
	physics_material_override = mat

	var hull_cs := CollisionShape2D.new()
	var hull_shape := ConvexPolygonShape2D.new()
	hull_shape.points = shape.hull
	hull_cs.shape = hull_shape
	add_child(hull_cs)

	# Bump-stop circles: where the tyres sit at full compression.
	for w in shape.wheels:
		var cs := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = w.r * 0.9
		cs.shape = c
		cs.position = w.mount
		add_child(cs)
		var q := CircleShape2D.new()
		q.radius = w.r
		_wheel_shapes.append(q)

	_roof = Area2D.new()
	_roof.collision_layer = 0
	_roof.collision_mask = K.LAYER_TERRAIN
	_roof.monitorable = false
	var rcs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = shape.roof_rect.size
	rcs.shape = rect
	rcs.position = shape.roof_rect.get_center()
	_roof.add_child(rcs)
	add_child(_roof)
	_roof.body_entered.connect(_on_roof_hit)

	visual = VehicleVisual.new()
	visual.setup(def)
	add_child(visual)

	_init_wheels()
	_query.collision_mask = K.LAYER_TERRAIN
	_query.margin = 0.5


func _init_wheels() -> void:
	wheel_states.clear()
	var n := shape.wheels.size()
	var xs: Array = []
	for w in shape.wheels:
		xs.append(w.pos.x)
	var x_r: float = xs[0]
	var x_f: float = xs[n - 1]
	var cx := shape.com.x
	var shares: Array = []
	if n == 2:
		var fr := clampf((cx - x_r) / maxf(x_f - x_r, 1.0), 0.15, 0.85)
		shares = [1.0 - fr, fr]
	else:
		for i in n:
			shares.append(1.0 / n)
	var travel_px := spec.travel * K.PPM
	for i in n:
		var w: Dictionary = shape.wheels[i]
		var m_share: float = mass * shares[i]
		var k := m_share * _g / (0.45 * travel_px)
		var c := 2.0 * spec.damping_ratio * sqrt(k * m_share)
		wheel_states.append({
			"mount": w.mount,
			"r": w.r,
			"travel": travel_px,
			"k": k,
			"c": c,
			"m_share": m_share,
			"driven": w.driven,
			"contact": false,
			"dist": travel_px * 0.55,
			"point": Vector2.ZERO,
			"normal": Vector2.UP,
			"spin": 0.0,
			"angle": 0.0,
			"load": 0.0,
			"slip": false,
		})


func _on_roof_hit(_body: Node) -> void:
	if is_crashed or not input_enabled:
		return
	_crash("crash")


func _crash(reason: String) -> void:
	if is_crashed:
		return
	is_crashed = true
	crashed.emit(reason)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if spec == null:
		return
	var dt := state.step
	var space := state.get_space_state()
	var xf := state.transform
	var down := xf.y.normalized()
	var fwd := xf.x.normalized()
	var v := state.linear_velocity
	var w := state.angular_velocity
	var com_w := xf.origin + state.center_of_mass
	var ppm := K.PPM
	speed_ms = v.dot(fwd) / ppm

	var g_in := gas if input_enabled else 0.0
	var b_in := brake if input_enabled else 0.0
	var accel := spec.accel * (spec.boost_mult if boosting else 1.0)
	var top := spec.top_speed * (1.25 if boosting else 1.0)

	# ---- 1. suspension casts ----
	contacts = 0
	var driven_contacts := 0
	_query.exclude = [get_rid()]
	for i in wheel_states.size():
		var ws: Dictionary = wheel_states[i]
		var mount_w: Vector2 = xf * (ws.mount as Vector2)
		var cast_len: float = ws.travel
		# Godot's cast_motion ignores shapes the cast *starts* inside, so the
		# sweep begins above the mount: a fully compressed wheel still sees the
		# ground and the bump stop engages instead of the chassis grounding out.
		var lift: float = float(ws.r) * 0.9
		var start: Vector2 = mount_w - down * lift
		var total: float = cast_len + lift
		_query.shape = _wheel_shapes[i]
		_query.transform = Transform2D(0.0, start)
		_query.motion = down * total
		var res := space.cast_motion(_query)
		ws.contact = false
		var hit := false
		var dist := 0.0
		if res.size() == 2 and res[0] < 1.0:
			hit = true
			dist = total * res[0] - lift
			_query.transform = Transform2D(0.0, start + down * (total * res[1] + 0.5))
		else:
			# Deeply embedded (e.g. hard landing): detect plain overlap at the mount.
			_query.transform = Transform2D(0.0, mount_w)
			_query.motion = Vector2.ZERO
			var probe := space.get_rest_info(_query)
			if not probe.is_empty():
				hit = true
				dist = -lift * 0.5
		if hit:
			_query.motion = Vector2.ZERO
			var info := space.get_rest_info(_query)
			var n := -down
			var pt: Vector2 = mount_w + down * (maxf(dist, 0.0) + float(ws.r))
			if not info.is_empty():
				n = info.normal
				pt = info.point
				if n.dot(-down) < 0.2:
					n = -down
			ws.contact = true
			ws.dist = dist
			ws.point = pt
			ws.normal = n
			contacts += 1
			if ws.driven:
				driven_contacts += 1
		else:
			# extend toward full droop smoothly
			ws.dist = move_toward(ws.dist, cast_len, cast_len * dt * 8.0)

	grounded = contacts > 0
	rear_only = contacts > 0 and wheel_states[0].contact and not wheel_states[-1].contact
	front_only = contacts > 0 and wheel_states[-1].contact and not wheel_states[0].contact

	# ---- 2. engine / brake demand ----
	var drive_total := 0.0
	var braking := false
	var thr := 0.0
	if g_in > 0.01 and b_in < 0.01:
		var s := maxf(speed_ms, 0.0) / top
		var curve := clampf(1.3 * (1.0 - pow(s, 2.4)), 0.0, 1.0)
		drive_total = mass * accel * ppm * g_in * curve
		thr = g_in
	elif b_in > 0.01 and g_in < 0.01:
		if speed_ms > 0.8:
			braking = true
		else:
			var rtop := top * 0.35
			var s2 := maxf(-speed_ms, 0.0) / rtop
			var curve2 := clampf(1.2 * (1.0 - pow(s2, 2.0)), 0.0, 1.0)
			drive_total = -mass * accel * spec.reverse_ratio * ppm * b_in * curve2
			thr = b_in * 0.6
	throttle_used = thr

	# ---- 3. per-wheel forces ----
	var any_slip := false
	for i in wheel_states.size():
		var ws: Dictionary = wheel_states[i]
		var mount_w: Vector2 = xf * (ws.mount as Vector2)
		if not ws.contact:
			ws.load = 0.0
			ws.slip = false
			if ws.driven and absf(drive_total) > 0.0:
				ws.spin = lerpf(ws.spin, signf(drive_total) * top * ppm / ws.r * 1.1, 1.0 - exp(-dt * 3.0))
			else:
				ws.spin *= exp(-dt * 0.7)
			continue
		var comp: float = ws.travel - ws.dist
		var r_m := mount_w - com_w
		var v_m := v + Vector2(-w * r_m.y, w * r_m.x)
		var comp_vel := v_m.dot(down)
		var f_s: float = ws.k * comp + ws.c * comp_vel
		# progressive bump stop in the last 12% of travel
		if comp > ws.travel * 0.88:
			f_s += ws.k * 4.0 * (comp - ws.travel * 0.88)
		f_s = maxf(f_s, 0.0)
		state.apply_force(-down * f_s, mount_w - xf.origin)

		var n: Vector2 = ws.normal
		var t := Vector2(-n.y, n.x)
		if t.dot(fwd) < 0.0:
			t = -t
		var normal_load := f_s * maxf((-down).dot(n), 0.0)
		ws.load = normal_load
		var surf := _surface_at((ws.point as Vector2).x)
		var mu := spec.grip * float(surf.get("grip", 1.0))
		var f_max := mu * normal_load
		var r_c: Vector2 = (ws.point as Vector2) - com_w
		var v_c := v + Vector2(-w * r_c.y, w * r_c.x)
		var v_t := v_c.dot(t)
		var m_share: float = ws.m_share
		var stop_cap := absf(v_t) * m_share / dt
		var desired := 0.0
		if ws.driven and driven_contacts > 0 and drive_total != 0.0:
			desired = drive_total / driven_contacts
		if braking:
			var bf := mass * spec.brake * ppm * b_in / contacts
			desired = -signf(v_t) * minf(bf, stop_cap)
		# rolling resistance
		var roll := float(surf.get("roll", 0.015)) * normal_load
		desired += -signf(v_t) * minf(roll, stop_cap * 0.5)
		var slip := absf(desired) > f_max
		var f_t := clampf(desired, -f_max, f_max)
		state.apply_force(t * f_t, (ws.point as Vector2) - xf.origin)
		ws.slip = slip and ws.driven and not braking
		if ws.slip:
			any_slip = true
		# wheel visual spin
		var roll_spin: float = v_t / float(ws.r)
		if ws.slip:
			roll_spin += signf(desired) * 18.0 * maxf(g_in, b_in)
		if braking and absf(v_t) > 1.0 and b_in > 0.9 and slip:
			roll_spin *= 0.2
		ws.spin = roll_spin

	# ---- 4. rotation control ----
	var lean := g_in - b_in
	var inv_i := state.inverse_inertia
	if inv_i > 0.0:
		var inertia := 1.0 / inv_i
		if contacts == 0:
			var alpha := -lean * spec.air_alpha
			if (w < -spec.air_spin_max and alpha < 0.0) or (w > spec.air_spin_max and alpha > 0.0):
				alpha = 0.0
			state.apply_torque(alpha * inertia)
		else:
			state.apply_torque(-lean * spec.air_alpha * spec.ground_tilt * inertia)
			if _landing_t > 0.0:
				state.apply_torque(-w * spec.landing_stab * 6.0 * inertia)

	# ---- 5. aero drag ----
	var vms := v.length() / ppm
	if vms > 0.1:
		state.apply_central_force(-v.normalized() * 0.0011 * vms * vms * ppm * mass)

	# ---- 6. bookkeeping: air time, flips, landings ----
	if contacts == 0:
		if _was_grounded:
			air_time = 0.0
			air_rot = 0.0
			took_off.emit()
		air_time += dt
		air_rot += w * dt
	else:
		if not _was_grounded and air_time > 0.05:
			var flips := int((absf(air_rot) + 0.9) / TAU) * (1 if air_rot > 0.0 else -1)
			var impact := absf(v.dot(-down)) / ppm
			last_impact = impact
			_landing_t = 0.35
			landed.emit(air_time, impact, flips)
		air_time = 0.0
		air_rot = 0.0
	_was_grounded = contacts > 0
	_landing_t = maxf(_landing_t - dt, 0.0)

	# ---- 7. upside-down safety ----
	var up_dot := (-down).dot(Vector2.UP)
	if up_dot < -0.3 and v.length() < 2.0 * ppm:
		_upside_t += dt
		if _upside_t > 1.2 and input_enabled:
			_crash("flipped")
	else:
		_upside_t = 0.0

	# ---- 8. engine rpm & gears (audio / HUD) ----
	var sp := absf(speed_ms) / maxf(top, 1.0)
	var target_rpm := 0.16
	if any_slip or (contacts == 0 and thr > 0.0):
		target_rpm = 0.9 + 0.08 * randf()
	else:
		gear = 1
		for gi in range(1, GEAR_EDGES.size()):
			if sp >= GEAR_EDGES[gi - 1]:
				gear = gi
		var lo: float = GEAR_EDGES[gear - 1]
		var hi: float = GEAR_EDGES[gear]
		var frac := clampf((sp - lo) / (hi - lo), 0.0, 1.0)
		target_rpm = 0.24 + 0.68 * frac
		if thr < 0.05:
			target_rpm = maxf(0.16, target_rpm * 0.75)
	rpm = lerpf(rpm, target_rpm, 1.0 - exp(-dt * 10.0))


func _surface_at(x_px: float) -> Dictionary:
	if surface_provider.is_valid():
		return surface_provider.call(x_px)
	return {"grip": 1.0, "roll": 0.015}


func _process(delta: float) -> void:
	if visual == null:
		return
	var pos: Array = []
	var ang: Array = []
	for ws in wheel_states:
		ws.angle = fmod(ws.angle + ws.spin * delta, TAU)
		var m: Vector2 = ws.mount
		pos.append(Vector2(m.x, m.y + clampf(float(ws.dist), -float(ws.r) * 0.25, float(ws.travel))))
		ang.append(ws.angle)
	visual.set_wheels(pos, ang)


## Distance travelled in metres (x of chassis).
func distance_m() -> float:
	return global_position.x / K.PPM


func wheel_contact_points() -> Array:
	var out: Array = []
	for ws in wheel_states:
		if ws.contact:
			out.append(ws.point)
	return out
