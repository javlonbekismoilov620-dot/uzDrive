extends TestCase


func test_daily_missions() -> void:
	fresh_profile()
	var prog = tree.root.get_node("/root/Progress")
	var a: Array = prog.generate_daily("2026-05-01", 0)
	var b: Array = prog.generate_daily("2026-05-01", 0)
	eq(a, b, "deterministic for a date")
	eq(a.size(), 3, "three daily missions")
	var ids := {}
	for m in a:
		ids[m.tid] = true
	eq(ids.size(), 3, "distinct missions")
	var c: Array = prog.generate_daily("2026-05-02", 0)
	check(JSON.stringify(c) != JSON.stringify(a), "different days differ")
	var hard: Array = prog.generate_daily("2026-05-01", 2)
	check(float(hard[0].target) > float(a[0].target), "higher tier = bigger targets")


func test_mission_progress_and_claim() -> void:
	fresh_profile()
	var prog = tree.root.get_node("/root/Progress")
	var prof = tree.root.get_node("/root/Profile")
	prog.refresh_daily()
	prof.data.missions.list = [{"tid": "jumps", "metric": "jump", "mode": "add", "target": 3.0, "coins": 400, "progress": 0.0, "claimed": false},
		{"tid": "drive_single", "metric": "run_distance", "mode": "max", "target": 500.0, "coins": 450, "progress": 0.0, "claimed": false}]
	check(not prog.claim_mission(0), "cannot claim unfinished")
	Events.stat.emit("jump", 2)
	Events.stat.emit("jump", 5)
	eq(float(prof.data.missions.list[0].progress), 3.0, "progress capped at target")
	Events.stat.emit("run_distance", 300)
	Events.stat.emit("run_distance", 200)
	eq(float(prof.data.missions.list[1].progress), 300.0, "'max' missions track best single run")
	var c0: int = Economy.coins()
	check(prog.claim_mission(0), "claim done mission")
	check(not prog.claim_mission(0), "no double claim")
	eq(Economy.coins(), c0 + 400, "mission reward paid once")
	check(prof.stat("total_jumps") >= 7.0, "lifetime stat recorded")


func test_achievements() -> void:
	fresh_profile()
	var prog = tree.root.get_node("/root/Progress")
	var prof = tree.root.get_node("/root/Profile")
	var ach: Dictionary = {}
	for a in DB.achievements:
		if a.id == "vehicles":
			ach = a
	var st: Dictionary = prog.achievement_state(ach)
	check(not st.can_claim, "1 vehicle: nothing yet")
	prof.data.garage.owned.append_array(["sarbon_uchqun", "sarbon_lola", "sarbon_nafis", "sarbon_jasur"])
	st = prog.achievement_state(ach)
	eq(int(st.reached), 2, "5 vehicles reaches tiers 2 and 5")
	var g0 := Economy.coins()
	check(not prog.claim_achievement("vehicles").is_empty(), "claim tier 1")
	check(not prog.claim_achievement("vehicles").is_empty(), "claim tier 2")
	check(prog.claim_achievement("vehicles").is_empty(), "tier 3 not reached")
	check(Economy.coins() > g0, "rewards paid")
	prof.data.garage.upgrades["sarbon_mitti"] = {"engine": 5}
	eq(prog.metric_value("max_engine_level"), 5.0, "engine level metric")
