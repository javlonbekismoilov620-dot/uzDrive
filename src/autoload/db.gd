## Read-only game data loaded from res://data/*.json (vehicles, maps, missions,
## achievements, economy). Nothing here is hard-coded: designers edit the JSON.
extends Node

var vehicles: Array = []
var vehicle_map := {}
var environments: Array = []
var env_map := {}
var missions: Dictionary = {}
var achievements: Array = []
var economy: Dictionary = {}
var load_errors: Array = []


func _ready() -> void:
	reload()


func reload() -> void:
	load_errors.clear()
	var vj = Util.load_json("res://data/vehicles.json")
	vehicles = vj.get("vehicles", []) if vj is Dictionary else []
	vehicles.sort_custom(func(a, b): return int(a.get("order", 0)) < int(b.get("order", 0)))
	vehicle_map.clear()
	for v in vehicles:
		vehicle_map[v.id] = v
	var ej = Util.load_json("res://data/environments.json")
	environments = ej.get("environments", []) if ej is Dictionary else []
	environments.sort_custom(func(a, b): return int(a.order) < int(b.order))
	env_map.clear()
	for e in environments:
		env_map[e.id] = e
	var mj = Util.load_json("res://data/missions.json")
	missions = mj if mj is Dictionary else {}
	var aj = Util.load_json("res://data/achievements.json")
	achievements = aj.get("achievements", []) if aj is Dictionary else []
	var ecj = Util.load_json("res://data/economy.json")
	economy = ecj if ecj is Dictionary else {}
	load_errors = validate()
	for e in load_errors:
		push_warning("DB: " + e)


func vehicle(id: String) -> Dictionary:
	return vehicle_map.get(id, {})


func env(id: String) -> Dictionary:
	return env_map.get(id, {})


func starter_vehicle_id() -> String:
	for v in vehicles:
		if v.get("unlock", "") == "default":
			return v.id
	return vehicles[0].id if vehicles.size() > 0 else ""


func first_env_id() -> String:
	return environments[0].id if environments.size() > 0 else ""


func eco(key: String, fallback: Variant = null) -> Variant:
	return economy.get(key, fallback)


## Display name; uses licensed branding only if the license block allows it.
func vehicle_display_name(v: Dictionary) -> String:
	var lic: Dictionary = v.get("license", {})
	if lic.get("licensed", false) and str(lic.get("model", "")) != "":
		return "%s %s" % [lic.get("brand", ""), lic.get("model", "")]
	return v.get("name", "?")


func vehicle_maker(v: Dictionary) -> String:
	var lic: Dictionary = v.get("license", {})
	if lic.get("licensed", false) and str(lic.get("brand", "")) != "":
		return lic.brand
	return v.get("maker", "")


## Data validation — also executed by the automated test-suite.
func validate() -> Array:
	var errs: Array = []
	var ids := {}
	for v in vehicles:
		var id: String = v.get("id", "")
		if id == "" or ids.has(id):
			errs.append("vehicle id missing/duplicate: %s" % id)
		ids[id] = true
		if not v.get("rarity", "") in K.RARITIES:
			errs.append("%s: bad rarity" % id)
		if not v.get("category", "") in K.CATEGORIES:
			errs.append("%s: bad category" % id)
		if int(v.get("price", -1)) < 0:
			errs.append("%s: negative price" % id)
		for k in ["specs", "handling", "upgrades", "body", "style"]:
			if not v.has(k):
				errs.append("%s: missing %s" % [id, k])
		if v.get("license", {}).get("licensed", false) == false and v.has("inspired_by") == false:
			errs.append("%s: missing inspired_by reference" % id)
	for e in environments:
		for k in ["terrain", "visual", "pickups", "goal_m"]:
			if not e.has(k):
				errs.append("env %s: missing %s" % [e.get("id", "?"), k])
	return errs
