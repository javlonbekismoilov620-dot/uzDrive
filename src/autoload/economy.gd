## All currency movement goes through here.
## Guarantees: balances never go negative, prices are re-validated at purchase
## time, one-off rewards are idempotent (claim ids), and every transaction is
## saved immediately.
extends Node

enum Result { OK, INSUFFICIENT, ALREADY_OWNED, LOCKED, MAXED, INVALID, ALREADY_CLAIMED, NOT_AVAILABLE }

const KEEP_RUN_CLAIMS := 30


func coins() -> int:
	return Profile.coins()


func gems() -> int:
	return Profile.gems()


func add_coins(amount: int, _source := "") -> void:
	if amount <= 0:
		return
	var w: Dictionary = Profile.data.wallet
	w.coins = int(w.coins) + amount
	w.coins_earned = int(w.get("coins_earned", 0)) + amount
	Profile.touch()
	Events.coins_changed.emit(int(w.coins), amount)


func add_gems(amount: int, _source := "") -> void:
	if amount <= 0:
		return
	var w: Dictionary = Profile.data.wallet
	w.gems = int(w.gems) + amount
	w.gems_earned = int(w.get("gems_earned", 0)) + amount
	Profile.touch()
	Events.gems_changed.emit(int(w.gems), amount)


func can_afford(price: int, currency := "coins") -> bool:
	if price < 0:
		return false
	return (gems() if currency == "gems" else coins()) >= price


func spend(price: int, currency := "coins", _reason := "") -> bool:
	if price < 0 or not can_afford(price, currency):
		return false
	var w: Dictionary = Profile.data.wallet
	if currency == "gems":
		w.gems = int(w.gems) - price
		Events.gems_changed.emit(int(w.gems), -price)
	else:
		w.coins = int(w.coins) - price
		Events.coins_changed.emit(int(w.coins), -price)
	Profile.touch()
	return true


# ---------------- idempotent rewards ----------------
func is_claimed(reward_id: String) -> bool:
	return Profile.data.rewards.claimed.has(reward_id)


func claim_reward(reward_id: String, coin_amount := 0, gem_amount := 0) -> bool:
	if reward_id.is_empty() or is_claimed(reward_id):
		return false
	Profile.data.rewards.claimed[reward_id] = int(Time.get_unix_time_from_system())
	_prune_claims()
	add_coins(coin_amount, reward_id)
	add_gems(gem_amount, reward_id)
	Profile.save_now()
	return true


func _prune_claims() -> void:
	var claimed: Dictionary = Profile.data.rewards.claimed
	var runs: Array = []
	for k in claimed:
		if str(k).begins_with("run_"):
			runs.append([k, claimed[k]])
	if runs.size() > KEEP_RUN_CLAIMS:
		runs.sort_custom(func(a, b): return a[1] < b[1])
		for i in runs.size() - KEEP_RUN_CLAIMS:
			claimed.erase(runs[i][0])


# ---------------- vehicles ----------------
func vehicle_price(vid: String) -> Dictionary:
	var v := DB.vehicle(vid)
	return {"price": int(v.get("price", 0)), "currency": v.get("currency", "coins")}


func buy_vehicle(vid: String) -> int:
	var v := DB.vehicle(vid)
	if v.is_empty():
		return Result.INVALID
	if Profile.owns(vid):
		return Result.ALREADY_OWNED
	var p := vehicle_price(vid)
	if not spend(p.price, p.currency, "vehicle:" + vid):
		return Result.INSUFFICIENT
	Profile.data.garage.owned.append(vid)
	Profile.save_now()
	Events.vehicle_purchased.emit(vid)
	Events.stat.emit("vehicle", 1)
	return Result.OK


func upgrade_cost(vid: String, type: String) -> int:
	return UpgradeRules.cost(DB.vehicle(vid), type, Profile.upgrade_level(vid, type))


func buy_upgrade(vid: String, type: String) -> int:
	if not Profile.owns(vid) or not type in K.UPGRADE_TYPES:
		return Result.INVALID
	var cost := upgrade_cost(vid, type)
	if cost < 0:
		return Result.MAXED
	if not spend(cost, "coins", "upgrade:%s:%s" % [vid, type]):
		return Result.INSUFFICIENT
	var lv := Profile.upgrade_level(vid, type) + 1
	Profile._set_upgrade_level(vid, type, lv)
	Profile.save_now()
	Events.upgrade_purchased.emit(vid, type, lv)
	Events.stat.emit("upgrade", 1)
	return Result.OK


# ---------------- maps ----------------
func map_unlock_cost(map_id: String) -> int:
	return int(DB.env(map_id).get("unlock_cost", 0))


## A map can be bought once the previous map is unlocked; finishing the previous
## map unlocks it for free (see complete_map).
func can_buy_map(map_id: String) -> bool:
	var e := DB.env(map_id)
	if e.is_empty() or Profile.map_unlocked(map_id):
		return false
	var req = e.get("requires", null)
	return req == null or Profile.map_unlocked(str(req))


func unlock_map(map_id: String) -> int:
	if DB.env(map_id).is_empty():
		return Result.INVALID
	if Profile.map_unlocked(map_id):
		return Result.ALREADY_OWNED
	if not can_buy_map(map_id):
		return Result.LOCKED
	if not spend(map_unlock_cost(map_id), "coins", "map:" + map_id):
		return Result.INSUFFICIENT
	_grant_map(map_id)
	return Result.OK


func _grant_map(map_id: String) -> void:
	if not Profile.data.maps.unlocked.has(map_id):
		Profile.data.maps.unlocked.append(map_id)
		Profile.save_now()
		Events.map_unlocked.emit(map_id)


## Called when the goal distance is reached. Returns reward dict (empty if repeat).
func complete_map(map_id: String) -> Dictionary:
	var e := DB.env(map_id)
	if e.is_empty():
		return {}
	var first_time := not Profile.map_completed(map_id)
	if first_time:
		Profile.data.maps.completed.append(map_id)
	# unlock the next map for free
	for other in DB.environments:
		if other.get("requires", null) == map_id:
			_grant_map(other.id)
	var r: Dictionary = e.get("complete_reward", {})
	var got := claim_reward("map_" + map_id, int(r.get("coins", 0)), int(r.get("gems", 0)))
	if first_time:
		Events.map_completed.emit(map_id)
	Profile.save_now()
	return r if got else {}


# ---------------- runs ----------------
## Turns a finished run into a coin payout. Pure calculation.
func compute_run_payout(summary: Dictionary) -> Dictionary:
	var env := DB.env(summary.get("map", ""))
	var mult := float(env.get("reward_mult", 1.0))
	var dist := int(summary.get("distance", 0))
	var per_m := float(DB.eco("distance_coins_per_m", 0.5))
	var distance_bonus := int(round(dist * per_m * mult))
	var cps := int(summary.get("checkpoints", 0))
	var cp_bonus := 0
	for i in cps:
		cp_bonus += int(DB.eco("checkpoint_bonus", 150)) * (i + 1)
	cp_bonus = int(round(cp_bonus * mult))
	var trick := int(summary.get("trick_coins", 0))
	var collected := int(summary.get("coins", 0))
	return {
		"collected": collected,
		"distance_bonus": distance_bonus,
		"checkpoint_bonus": cp_bonus,
		"trick_bonus": trick,
		"total": collected + distance_bonus + cp_bonus + trick,
		"gems": int(summary.get("gems", 0)),
	}


## Pays a run exactly once (run_id is unique per run).
func commit_run(run_id: String, payout: Dictionary) -> bool:
	return claim_reward("run_" + run_id, int(payout.get("total", 0)), int(payout.get("gems", 0)))


func revive_cost(times_used: int) -> int:
	var costs: Array = DB.eco("revive_gems", [5, 10, 20])
	return int(costs[mini(times_used, costs.size() - 1)])


# ---------------- daily login ----------------
func login_state(today := "") -> Dictionary:
	if today.is_empty():
		today = Util.today_str()
	var lg: Dictionary = Profile.data.rewards.login
	var last: String = lg.get("last", "")
	var day := int(lg.get("day", -1))
	var rewards: Array = DB.eco("daily_login", [])
	var n := maxi(rewards.size(), 1)
	if last == today:
		return {"can_claim": false, "day": day, "next_day": (day + 1) % n}
	var gap := Util.days_between(last, today) if last != "" else 1
	if gap < 0:
		return {"can_claim": false, "day": day, "next_day": (day + 1) % n}
	var next := (day + 1) % n if gap == 1 else 0
	return {"can_claim": true, "day": day, "next_day": next}


func claim_daily_login(today := "") -> Dictionary:
	if today.is_empty():
		today = Util.today_str()
	var st := login_state(today)
	if not st.can_claim:
		return {}
	var rewards: Array = DB.eco("daily_login", [])
	if rewards.is_empty():
		return {}
	var r: Dictionary = rewards[st.next_day]
	if not claim_reward("login_" + today, int(r.get("coins", 0)), int(r.get("gems", 0))):
		return {}
	Profile.data.rewards.login = {"last": today, "day": st.next_day}
	Profile.save_now()
	return r


# ---------------- gem exchange ----------------
func exchange_gems(index: int) -> int:
	var packs: Array = DB.eco("gem_exchange", [])
	if index < 0 or index >= packs.size():
		return Result.INVALID
	var p: Dictionary = packs[index]
	if not spend(int(p.gems), "gems", "exchange"):
		return Result.INSUFFICIENT
	add_coins(int(p.coins), "exchange")
	Profile.save_now()
	return Result.OK
