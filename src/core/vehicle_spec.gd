## Effective vehicle statistics = base data (vehicles.json) + upgrade levels.
## Pure data object: used by the physics (Vehicle), the garage UI and tests,
## so what the player sees in the garage is exactly what the car does.
class_name VehicleSpec
extends RefCounted

var id := ""
var def: Dictionary = {}
var levels := {"engine": 0, "suspension": 0, "tires": 0, "fuel": 0}

# --- Display stats (real-world-like units, include upgrades) ---
var power_hp := 0.0
var top_kmh := 0.0
var weight_kg := 0.0
var fuel_l := 0.0

# --- Physics parameters (SI units: m, s, kg-ish) ---
var mass := 1.0             ## Godot mass units (tonnes)
var accel := 6.0            ## peak drive acceleration, m/s^2
var top_speed := 20.0       ## m/s
var brake := 10.0           ## m/s^2
var reverse_ratio := 0.45
var drive := "rwd"          ## rwd | fwd | awd
var grip := 1.0             ## tire friction coefficient
var air_alpha := 7.0        ## rad/s^2 of air control
var air_spin_max := 5.5     ## rad/s cap while airborne
var ground_tilt := 0.35     ## fraction of air control usable on the ground
var damping_ratio := 0.45
var travel := 0.25          ## suspension travel, m
var landing_stab := 0.0     ## extra angular damping right after landing
var fuel_time := 50.0       ## seconds of full-throttle driving per tank
var com_h := 0.45           ## centre of mass height above ground (m)
var front_bias := 0.5       ## static weight on the front axle
var boost_mult := 1.45


static func build(vdef: Dictionary, lv: Dictionary = {}) -> VehicleSpec:
	var s := VehicleSpec.new()
	s.def = vdef
	s.id = vdef.get("id", "")
	for k in K.UPGRADE_TYPES:
		s.levels[k] = int(lv.get(k, 0))
	s._compute()
	return s


static func max_level(vdef: Dictionary) -> int:
	return int(vdef.get("upgrades", {}).get("max", 8))


func _compute() -> void:
	var sp: Dictionary = def.get("specs", {})
	var hd: Dictionary = def.get("handling", {})
	var le: int = levels.engine
	var ls: int = levels.suspension
	var lt: int = levels.tires
	var lf: int = levels.fuel

	var base_hp := float(sp.get("power_hp", 80))
	weight_kg = float(sp.get("weight_kg", 1000))
	power_hp = base_hp * (1.0 + K.UPG_ENGINE_POWER * le)
	top_kmh = float(sp.get("top_kmh", 150)) * (1.0 + K.UPG_ENGINE_TOP * le)
	fuel_l = float(sp.get("fuel_l", 45)) * (1.0 + K.UPG_FUEL_CAP * lf)
	drive = sp.get("drive", "rwd")

	mass = weight_kg / 1000.0
	# Power-to-weight (hp per tonne) compressed into a playable acceleration range.
	var pw := base_hp / maxf(mass, 0.2)
	var t := clampf((pw - 35.0) / 320.0, 0.0, 1.4)
	accel = (5.6 + 5.4 * pow(t, 0.7)) * float(hd.get("accel_mult", 1.0))
	accel *= 1.0 + K.UPG_ENGINE_ACCEL * le
	top_speed = (9.0 + float(sp.get("top_kmh", 150)) * 0.078) * (1.0 + K.UPG_ENGINE_TOP * le)
	brake = 11.0
	grip = float(hd.get("grip", 1.0)) * K.GRIP_SCALE * (1.0 + K.UPG_TIRES_GRIP * lt)
	var susp_q := float(hd.get("suspension", 1.0))
	damping_ratio = clampf(0.30 + 0.12 * susp_q + K.UPG_SUSP_DAMP * ls, 0.25, 0.95)
	travel = maxf(float(hd.get("travel", 0.25)), 0.1) * (1.0 + K.UPG_SUSP_TRAVEL * ls)
	landing_stab = susp_q * 0.5 + K.UPG_SUSP_LANDING * ls * 4.0
	air_alpha = 7.5 * float(hd.get("air_control", 1.0))
	air_spin_max = 5.0 + 1.0 * float(hd.get("air_control", 1.0))
	com_h = float(hd.get("com_h", 0.45))
	fuel_time = float(hd.get("fuel_time", 50.0)) * (1.0 + K.UPG_FUEL_CAP * lf)
	front_bias = float(hd.get("front_bias", 0.5))


## 0..100 ratings for garage bars. Ranges chosen to spread the roster.
func rating(stat: String) -> float:
	match stat:
		"power":
			return clampf((accel - 5.0) / 9.5 * 100.0, 3.0, 100.0)
		"speed":
			return clampf((top_speed - 16.0) / 30.0 * 100.0, 3.0, 100.0)
		"grip":
			return clampf((grip - 0.75) / 1.75 * 100.0, 3.0, 100.0)
		"suspension":
			return clampf((damping_ratio - 0.3) / 0.65 * 60.0 + (travel - 0.15) / 0.6 * 40.0, 3.0, 100.0)
		"fuel":
			return clampf((fuel_time - 30.0) / 120.0 * 100.0, 3.0, 100.0)
	return 0.0
