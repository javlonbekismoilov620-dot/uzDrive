## Daily missions + long-term achievements + lifetime statistics.
## Gameplay reports facts through Events.stat(kind, amount); this system turns
## them into stats, mission progress and claimable rewards.
extends Node

## stat kind -> [profile stat key, mode]
const STAT_KEYS := {
	"distance": ["total_distance", "add"],
	"coins": ["total_coins", "add"],
	"jump": ["total_jumps", "add"],
	"flip": ["total_flips", "add"],
	"fuel": ["total_fuel", "add"],
	"boost": ["total_boosts", "add"],
	"airtime": ["total_airtime", "add"],
	"air_single": ["best_airtime", "max"],
	"run_distance": ["best_run", "max"],
	"run": ["total_runs", "add"],
	"checkpoint": ["total_checkpoints", "add"],
	"wheelie": ["total_wheelie", "add"],
	"gem": ["total_gems_found", "add"],
	"upgrade": ["total_upgrades", "add"],
	"daily_done": ["daily_done", "add"],
}


func _ready() -> void:
	Events.stat.connect(_on_stat)
	refresh_daily()


# ---------------- daily missions ----------------
func refresh_daily(today := "") -> void:
	if today.is_empty():
		today = Util.today_str()
	var m: Dictionary = Profile.data.missions
	if m.get("date", "") == today and (m.get("list", []) as Array).size() > 0:
		return
	m.date = today
	m.bonus_claimed = false
	m.list = generate_daily(today, player_tier())
	Profile.touch()
	Events.missions_changed.emit()


func player_tier() -> int:
	var best := Profile.stat("best_run")
	var done: int = Profile.data.maps.completed.size()
	if best >= 2000.0 or done >= 3:
		return 2
	if best >= 700.0 or done >= 1:
		return 1
	return 0


func generate_daily(date: String, tier: int) -> Array:
	var tpls: Array = (DB.missions.get("templates", []) as Array).duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = Util.stable_hash("daily:" + date)
	for i in range(tpls.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = tpls[i]
		tpls[i] = tpls[j]
		tpls[j] = tmp
	var out: Array = []
	var count := int(DB.missions.get("daily_count", 3))
	for t in tpls.slice(0, count):
		var ti := clampi(tier, 0, (t.targets as Array).size() - 1)
		out.append({"tid": t.id, "metric": t.metric, "mode": t.get("mode", "add"), "target": float(t.targets[ti]), "coins": int(t.coins[ti]), "progress": 0.0, "claimed": false})
	return out


func missions() -> Array:
	refresh_daily()
	return Profile.data.missions.list


func mission_done(mi: Dictionary) -> bool:
	return float(mi.progress) >= float(mi.target)


func claim_mission(index: int) -> bool:
	var list := missions()
	if index < 0 or index >= list.size():
		return false
	var mi: Dictionary = list[index]
	if mi.claimed or not mission_done(mi):
		return false
	var rid := "mission_%s_%d_%s" % [Profile.data.missions.date, index, mi.tid]
	if not Economy.claim_reward(rid, int(mi.coins), 0):
		mi.claimed = true
		return false
	mi.claimed = true
	Events.stat.emit("daily_done", 1)
	Profile.save_now()
	Events.missions_changed.emit()
	return true


func all_missions_claimed() -> bool:
	for mi in missions():
		if not mi.claimed:
			return false
	return missions().size() > 0


func can_claim_bonus() -> bool:
	return all_missions_claimed() and not bool(Profile.data.missions.get("bonus_claimed", false))


func claim_bonus() -> bool:
	if not can_claim_bonus():
		return false
	var b: Dictionary = DB.missions.get("all_done_bonus", {})
	var ok := Economy.claim_reward("mission_bonus_" + str(Profile.data.missions.date), int(b.get("coins", 0)), int(b.get("gems", 0)))
	Profile.data.missions.bonus_claimed = true
	Profile.save_now()
	Events.missions_changed.emit()
	return ok


# ---------------- stats feed ----------------
func _on_stat(kind: String, amount: float) -> void:
	if STAT_KEYS.has(kind):
		var sk: Array = STAT_KEYS[kind]
		if sk[1] == "max":
			Profile.max_stat(sk[0], amount)
		else:
			Profile.add_stat(sk[0], amount)
	refresh_daily()
	for mi in Profile.data.missions.list:
		if mi.claimed or mi.metric != kind:
			continue
		if mi.mode == "max":
			mi.progress = minf(maxf(float(mi.progress), amount), float(mi.target))
		else:
			mi.progress = minf(float(mi.progress) + amount, float(mi.target))
	Profile.touch()
	Events.missions_changed.emit()
	Events.achievements_changed.emit()


# ---------------- achievements ----------------
func metric_value(metric: String) -> float:
	match metric:
		"vehicles_owned":
			return Profile.owned().size()
		"gm_owned":
			var n := 0
			for id in Profile.owned():
				if DB.vehicle(id).get("category", "") == "gm":
					n += 1
			return n
		"legendary_owned":
			var n2 := 0
			for id in Profile.owned():
				if DB.vehicle(id).get("rarity", "") == "legendary":
					n2 += 1
			return n2
		"max_engine_level":
			var m := 0
			for id in Profile.owned():
				m = maxi(m, Profile.upgrade_level(id, "engine"))
			return m
		"vehicles_maxed":
			var n3 := 0
			for id in Profile.owned():
				if Profile.is_maxed(id):
					n3 += 1
			return n3
		"maps_completed":
			return Profile.data.maps.completed.size()
	return Profile.stat(metric)


func achievement_state(a: Dictionary) -> Dictionary:
	var value := metric_value(a.metric)
	var tiers: Array = a.tiers
	var reached := 0
	for t in tiers:
		if value >= float(t):
			reached += 1
	var claimed := int(Profile.data.achievements.get(a.id, 0))
	var next_i := mini(claimed, tiers.size() - 1)
	return {
		"value": value,
		"reached": reached,
		"claimed": claimed,
		"tiers": tiers.size(),
		"target": float(tiers[next_i]),
		"can_claim": claimed < reached,
		"complete": claimed >= tiers.size(),
		"reward": a.rewards[next_i] if next_i < (a.rewards as Array).size() else {},
	}


func claim_achievement(id: String) -> Dictionary:
	for a in DB.achievements:
		if a.id != id:
			continue
		var st := achievement_state(a)
		if not st.can_claim:
			return {}
		var tier: int = st.claimed
		var r: Dictionary = a.rewards[tier]
		Economy.claim_reward("ach_%s_%d" % [id, tier], int(r.get("coins", 0)), int(r.get("gems", 0)))
		Profile.data.achievements[id] = tier + 1
		Profile.save_now()
		Events.achievements_changed.emit()
		return r
	return {}


func claimable_missions() -> int:
	var n := 0
	for mi in missions():
		if not mi.claimed and mission_done(mi):
			n += 1
	if can_claim_bonus():
		n += 1
	return n


func claimable_achievements() -> int:
	var n := 0
	for a in DB.achievements:
		if achievement_state(a).can_claim:
			n += 1
	return n
