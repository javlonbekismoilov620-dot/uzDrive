## Live "attract mode" scenery for the main menu: the real map renderer in a
## SubViewport with the player's car cruising over the terrain (kinematic).
class_name Showcase
extends SubViewportContainer

var env_id := ""
var vid := ""
var _vp: SubViewport
var _cam: Camera2D
var _terrain: TerrainManager
var _car: VehicleVisual
var _x := 0.0
var speed := 9.0


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp = SubViewport.new()
	_vp.handle_input_locally = false
	_vp.disable_3d = true
	add_child(_vp)
	build()


func build() -> void:
	for c in _vp.get_children():
		c.queue_free()
	var env := DB.env(env_id if env_id != "" else Profile.selected_map())
	var world := Node2D.new()
	_vp.add_child(world)
	var bd := Backdrop.new()
	world.add_child(bd)
	bd.setup(env, world, "low")
	_terrain = TerrainManager.new()
	world.add_child(_terrain)
	_terrain.setup(env)
	_x = 20.0 * K.PPM
	_terrain.update(_x)
	if env.get("night", false):
		var cm := CanvasModulate.new()
		cm.color = Util.col(env.visual.get("ambient", "#56628f")).lightened(0.25)
		world.add_child(cm)
	_car = VehicleVisual.new()
	_car.setup(DB.vehicle(vid if vid != "" else Profile.selected_vehicle()))
	world.add_child(_car)
	_cam = Camera2D.new()
	_cam.zoom = Vector2(1.05, 1.05)
	world.add_child(_cam)
	_place(0.0)


func _process(delta: float) -> void:
	if _car == null or _terrain == null:
		return
	_x += speed * K.PPM * delta
	_terrain.update(_x)
	_place(delta)


func _place(delta: float) -> void:
	var s := _car.shape
	var w0: Dictionary = s.wheels[0]
	var w1: Dictionary = s.wheels[-1]
	var xr: float = _x + float(w0.pos.x)
	var xf: float = _x + float(w1.pos.x)
	var yr: float = _terrain.surface_y_px(xr) - float(w0.r)
	var yf: float = _terrain.surface_y_px(xf) - float(w1.r)
	var ang := atan2(yf - yr, xf - xr)
	var target_rot := ang
	_car.rotation = lerp_angle(_car.rotation, target_rot, 1.0 - exp(-delta * 10.0)) if delta > 0.0 else target_rot
	var mid_y: float = (yr + yf) * 0.5
	var wheel_mid: Vector2 = (w0.pos + w1.pos) * 0.5
	var target: Vector2 = Vector2(_x, mid_y) - wheel_mid.rotated(_car.rotation)
	_car.global_position = Vector2(_x, target.y)
	var pos: Array = []
	var ang_arr: Array = []
	for i in _car.wheel_nodes.size():
		var w: Dictionary = s.wheels[i]
		pos.append(w.pos)
		ang_arr.append(_car.wheel_nodes[i].rotation + delta * speed * K.PPM / w.r)
	_car.set_wheels(pos, ang_arr)
	_cam.global_position = Vector2(_x - 300.0, mid_y - 90.0)
