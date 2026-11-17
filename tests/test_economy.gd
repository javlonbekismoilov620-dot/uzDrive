extends TestCase

var Eco
var Prof


func _setup() -> void:
	fresh_profile()
	Eco = tree.root.get_node("/root/Economy")
	Prof = tree.root.get_node("/root/Profile")


func test_balances_never_negative() -> void:
	_setup()
	Prof.data.wallet.coins = 100
	check(not Eco.spend(150, "coins"), "cannot overspend")
	eq(Eco.coins(), 100, "balance unchanged after failed spend")
	check(not Eco.spend(-50, "coins"), "negative spend rejected")
	eq(Eco.coins(), 100, "negative spend does not add money")
	Eco.add_coins(-500)
	eq(Eco.coins(), 100, "negative add ignored")
	check(Eco.spend(100, "coins"), "exact spend works")
	eq(Eco.coins(), 0, "zero balance")
	Prof.data.wallet.coins = -40
	Prof.ensure_integrity()
	eq(Eco.coins(), 0, "integrity repair clamps negative balance")


func test_buy_vehicle() -> void:
	_setup()
	Prof.data.wallet.coins = 5000
	eq(Eco.buy_vehicle("sarbon_uchqun"), Eco.Result.INSUFFICIENT, "too expensive")
	check(not Prof.owns("sarbon_uchqun"), "not owned after failed buy")
	eq(Eco.coins(), 5000, "no charge on failure")
	Prof.data.wallet.coins = 6500
	eq(Eco.buy_vehicle("sarbon_uchqun"), Eco.Result.OK, "purchase ok")
	eq(Eco.coins(), 500, "price deducted once")
	eq(Eco.buy_vehicle("sarbon_uchqun"), Eco.Result.ALREADY_OWNED, "no duplicate purchase")
	eq(Eco.coins(), 500, "no double charge")
	eq(Eco.buy_vehicle("not_a_car"), Eco.Result.INVALID, "invalid id")
	Prof.data.wallet.gems = 10
	eq(Eco.buy_vehicle("oy_rover"), Eco.Result.INSUFFICIENT, "gem car needs gems")
	Prof.data.wallet.gems = 500
	eq(Eco.buy_vehicle("oy_rover"), Eco.Result.OK, "gem purchase")
	eq(Eco.gems(), 320, "gems deducted")


func test_upgrades() -> void:
	_setup()
	var vid := "sarbon_mitti"
	Prof.data.wallet.coins = 10_000_000
	var mx := VehicleSpec.max_level(DB.vehicle(vid))
	var last := 0
	for i in mx:
		var c: int = Eco.upgrade_cost(vid, "engine")
		check(c > last, "upgrade cost rises each level")
		last = c
		eq(Eco.buy_upgrade(vid, "engine"), Eco.Result.OK, "upgrade %d" % i)
	eq(Prof.upgrade_level(vid, "engine"), mx, "reached max")
	eq(Eco.buy_upgrade(vid, "engine"), Eco.Result.MAXED, "cannot exceed max")
	eq(Eco.upgrade_cost(vid, "engine"), -1, "no price when maxed")
	eq(Eco.buy_upgrade("sarbon_burgut", "engine"), Eco.Result.INVALID, "cannot upgrade unowned car")
	Prof.data.wallet.coins = 0
	eq(Eco.buy_upgrade(vid, "tires"), Eco.Result.INSUFFICIENT, "needs coins")
	eq(Prof.upgrade_level(vid, "tires"), 0, "level unchanged")


func test_idempotent_rewards() -> void:
	_setup()
	var c0: int = Eco.coins()
	check(Eco.claim_reward("unit_test_reward", 300, 2), "first claim")
	check(not Eco.claim_reward("unit_test_reward", 300, 2), "second claim rejected")
	eq(Eco.coins(), c0 + 300, "paid once")


func test_run_payout() -> void:
	_setup()
	var s := {"map": "green_hills", "distance": 1000, "coins": 640, "trick_coins": 250, "checkpoints": 2, "gems": 1, "run_id": "t1"}
	var p: Dictionary = Eco.compute_run_payout(s)
	eq(int(p.collected), 640, "collected")
	eq(int(p.distance_bonus), 500, "0.5 coin per metre")
	eq(int(p.checkpoint_bonus), 150 + 300, "checkpoint bonus 150*(1+2)")
	eq(int(p.total), 640 + 500 + 450 + 250, "total")
	var c0: int = Eco.coins()
	check(Eco.commit_run("t1", p), "commit")
	check(not Eco.commit_run("t1", p), "run cannot be paid twice")
	eq(Eco.coins(), c0 + int(p.total), "paid exactly once")
	var harder: Dictionary = Eco.compute_run_payout({"map": "night_highway", "distance": 1000})
	check(int(harder.distance_bonus) > int(p.distance_bonus), "harder maps pay more per metre")


func test_daily_login_cycle() -> void:
	_setup()
	var c0: int = Eco.coins()
	var r1: Dictionary = Eco.claim_daily_login("2026-03-01")
	check(not r1.is_empty(), "day 1 claim")
	check(Eco.claim_daily_login("2026-03-01").is_empty(), "same day twice rejected")
	var r2: Dictionary = Eco.claim_daily_login("2026-03-02")
	eq(int(Prof.data.rewards.login.day), 1, "consecutive day advances streak")
	check(Eco.claim_daily_login("2026-02-27").is_empty(), "clock moved back: no claim")
	Eco.claim_daily_login("2026-03-05")
	eq(int(Prof.data.rewards.login.day), 0, "missed days reset the streak")
	check(Eco.coins() > c0, "login paid coins")


func test_maps_unlock_and_complete() -> void:
	_setup()
	check(Prof.map_unlocked("green_hills"), "first map unlocked")
	check(not Prof.map_unlocked("countryside"), "second locked")
	check(not Eco.can_buy_map("desert_road"), "cannot buy two steps ahead")
	Prof.data.wallet.coins = 7000
	eq(Eco.unlock_map("countryside"), Eco.Result.INSUFFICIENT, "needs 8000")
	var g0: int = Eco.gems()
	var r: Dictionary = Eco.complete_map("green_hills")
	check(not r.is_empty(), "completion reward")
	check(Prof.map_unlocked("countryside"), "completing a map unlocks the next one free")
	eq(Eco.coins(), 7000 + int(r.coins), "completion coins")
	eq(Eco.gems(), g0 + int(r.gems), "completion gems")
	check(Eco.complete_map("green_hills").is_empty(), "completion reward only once")


func test_gem_exchange() -> void:
	_setup()
	Prof.data.wallet.gems = 9
	eq(Eco.exchange_gems(0), Eco.Result.INSUFFICIENT, "not enough gems")
	Prof.data.wallet.gems = 10
	var c0: int = Eco.coins()
	eq(Eco.exchange_gems(0), Eco.Result.OK, "exchange")
	eq(Eco.gems(), 0, "gems spent")
	check(Eco.coins() > c0, "coins received")
	eq(Eco.exchange_gems(99), Eco.Result.INVALID, "invalid pack")
