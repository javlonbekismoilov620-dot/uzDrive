## The player's persistent state (coins, cars, upgrades, maps, stats, settings).
## Owns the save payload; every mutation calls touch() which schedules an
## auto-save. Economy is the only system allowed to change currencies.
extends Node

signal changed

var data: Dictionary = {}


func _ready() -> void:
	load_profile()
	Save.set_provider(func() -> Dictionary: return data)


func load_profile() -> void:
	var d := Save.read()
	data = migrate(d) if not d.is_empty() else default_data()
	ensure_integrity()


func default_data() -> Dictionary:
	var starter := DB.starter_vehicle_id()
	var now := int(Time.get_unix_time_from_system())
	return {
		"version": K.SAVE_VERSION,
		"created_at": now,
		"updated_at": now,
		"wallet": {"coins": int(DB.eco("start_coins", 500)), "gems": int(DB.eco("start_gems", 5)), "coins_earned": 0, "gems_earned": 0},
		"garage": {"owned": [starter], "selected": starter, "upgrades": {}},
		"maps": {"unlocked": [DB.first_env_id()], "completed": [], "best": {}, "selected": DB.first_env_id()},
		"stats": {},
		"missions": {"date": "", "list": [], "bonus_claimed": false},
		"achievements": {},
		"rewards": {"claimed": {}, "login": {"last": "", "day": -1}},
		"settings": {"language": K.DEFAULT_LANG, "sound": true, "music": true, "sfx_volume": 0.9, "music_volume": 0.7, "vibration": true, "quality": "high", "lang_chosen": false},
		"tutorial": {"done": false},
	}


## Fills missing keys from defaults (deep) and upgrades old schema versions.
func migrate(d: Dictionary) -> Dictionary:
	var def := default_data()
	var out := _deep_merge(def, d)
	var ver := int(out.get("version", 1))
	# Future schema changes: if ver < 2: ... ; ver = 2
	out.version = maxi(ver, K.SAVE_VERSION)
	return out


func _deep_merge(base: Dictionary, over: Dictionary) -> Dictionary:
	var out := base.duplicate(true)
	for k in over:
		if out.has(k) and out[k] is Dictionary and over[k] is Dictionary:
			out[k] = _deep_merge(out[k], over[k])
		else:
			out[k] = over[k]
	return out


## Repairs impossible states (negative money, unknown cars, bad levels).
func ensure_integrity() -> void:
	var w: Dictionary = data.wallet
	w.coins = maxi(int(w.coins), 0)
	w.gems = maxi(int(w.gems), 0)
	var g: Dictionary = data.garage
	var owned: Array = []
	for id in g.owned:
		if DB.vehicle_map.has(id) and not owned.has(id):
			owned.append(id)
	var starter := DB.starter_vehicle_id()
	if not owned.has(starter):
		owned.insert(0, starter)
	g.owned = owned
	if not owned.has(g.selected):
		g.selected = starter
	for vid in g.upgrades.keys():
		if not DB.vehicle_map.has(vid):
			g.upgrades.erase(vid)
			continue
		var mx := VehicleSpec.max_level(DB.vehicle(vid))
		for t in K.UPGRADE_TYPES:
			g.upgrades[vid][t] = clampi(int(g.upgrades[vid].get(t, 0)), 0, mx)
	var m: Dictionary = data.maps
	var first := DB.first_env_id()
	var unl: Array = []
	for id in m.unlocked:
		if DB.env_map.has(id) and not unl.has(id):
			unl.append(id)
	if not unl.has(first):
		unl.insert(0, first)
	m.unlocked = unl
	if not unl.has(m.selected):
		m.selected = first
	if not K.LANGS.has(data.settings.language):
		data.settings.language = K.DEFAULT_LANG


func touch() -> void:
	data.updated_at = int(Time.get_unix_time_from_system())
	changed.emit()
	Save.request_save()


func save_now() -> void:
	data.updated_at = int(Time.get_unix_time_from_system())
	Save.flush()


func reset_progress() -> void:
	var lang: String = data.settings.language
	data = default_data()
	data.settings.language = lang
	data.settings.lang_chosen = true
	ensure_integrity()
	save_now()
	changed.emit()


# ---------------- wallet (read-only here; Economy mutates) ----------------
func coins() -> int:
	return int(data.wallet.coins)


func gems() -> int:
	return int(data.wallet.gems)


# ---------------- garage ----------------
func owned() -> Array:
	return data.garage.owned


func owns(vid: String) -> bool:
	return data.garage.owned.has(vid)


func selected_vehicle() -> String:
	return data.garage.selected


func select_vehicle(vid: String) -> bool:
	if not owns(vid):
		return false
	data.garage.selected = vid
	touch()
	Events.vehicle_selected.emit(vid)
	return true


func levels(vid: String) -> Dictionary:
	var u: Dictionary = data.garage.upgrades.get(vid, {})
	var out := {}
	for t in K.UPGRADE_TYPES:
		out[t] = int(u.get(t, 0))
	return out


func upgrade_level(vid: String, type: String) -> int:
	return int(data.garage.upgrades.get(vid, {}).get(type, 0))


func _set_upgrade_level(vid: String, type: String, lv: int) -> void:
	if not data.garage.upgrades.has(vid):
		data.garage.upgrades[vid] = {}
	data.garage.upgrades[vid][type] = lv


func spec_for(vid: String) -> VehicleSpec:
	return VehicleSpec.build(DB.vehicle(vid), levels(vid))


func is_maxed(vid: String) -> bool:
	var mx := VehicleSpec.max_level(DB.vehicle(vid))
	for t in K.UPGRADE_TYPES:
		if upgrade_level(vid, t) < mx:
			return false
	return true


# ---------------- maps ----------------
func map_unlocked(id: String) -> bool:
	return data.maps.unlocked.has(id)


func map_completed(id: String) -> bool:
	return data.maps.completed.has(id)


func best_distance(id: String) -> int:
	return int(data.maps.best.get(id, 0))


func selected_map() -> String:
	return data.maps.selected


func select_map(id: String) -> void:
	if map_unlocked(id):
		data.maps.selected = id
		touch()


func record_distance(id: String, meters: int) -> bool:
	if meters > best_distance(id):
		data.maps.best[id] = meters
		touch()
		return true
	return false


# ---------------- stats ----------------
func stat(key: String) -> float:
	return float(data.stats.get(key, 0.0))


func add_stat(key: String, amount: float) -> void:
	data.stats[key] = stat(key) + amount


func max_stat(key: String, value: float) -> void:
	if value > stat(key):
		data.stats[key] = value


# ---------------- settings ----------------
func setting(key: String, fallback: Variant = null) -> Variant:
	return data.settings.get(key, fallback)


func set_setting(key: String, value: Variant) -> void:
	data.settings[key] = value
	touch()
	Events.settings_changed.emit()
