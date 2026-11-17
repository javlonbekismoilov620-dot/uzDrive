extends TestCase


func test_roundtrip() -> void:
	fresh_profile()
	var save = tree.root.get_node("/root/Save")
	var prof = tree.root.get_node("/root/Profile")
	prof.data.wallet.coins = 1234567
	prof.data.garage.owned.append("sarbon_lola")
	prof.data.garage.upgrades["sarbon_mitti"] = {"engine": 3, "suspension": 1, "tires": 0, "fuel": 2}
	prof.data.settings.language = "ru"
	check(save.write(prof.data), "write ok")
	var back: Dictionary = save.read()
	eq(int(back.wallet.coins), 1234567, "coins survive (no float precision loss)")
	check((back.garage.owned as Array).has("sarbon_lola"), "owned survives")
	eq(int(back.garage.upgrades.sarbon_mitti.engine), 3, "upgrades survive")
	eq(back.settings.language, "ru", "settings survive")


func test_corruption_falls_back_to_backup() -> void:
	fresh_profile()
	var save = tree.root.get_node("/root/Save")
	var prof = tree.root.get_node("/root/Profile")
	prof.data.wallet.coins = 111
	save.write(prof.data)
	prof.data.wallet.coins = 222
	save.write(prof.data)   # previous save becomes the backup
	var f := FileAccess.open(save.main_path(), FileAccess.WRITE)
	f.store_string("{\"data\": {\"wallet\": {\"coins\": 999999}}, \"checksum\": \"forged\"}")
	f.close()
	var back: Dictionary = save.read()
	eq(int(back.wallet.coins), 111, "tampered/corrupt main save ignored, backup used")
	var f2 := FileAccess.open(save.main_path(), FileAccess.WRITE)
	f2.store_string("{ truncated")
	f2.close()
	eq(int(save.read().wallet.coins), 111, "truncated file ignored")


func test_interrupted_write_recovers_tmp() -> void:
	fresh_profile()
	var save = tree.root.get_node("/root/Save")
	var prof = tree.root.get_node("/root/Profile")
	prof.data.wallet.coins = 777
	var env: Dictionary = save.make_envelope(prof.data)
	# simulate a crash after the temp file was written but before the rename
	var f := FileAccess.open(save.tmp_path(), FileAccess.WRITE)
	f.store_string(JSON.stringify(env, "", true, true))
	f.close()
	eq(int(save.read().wallet.coins), 777, "verified temp file is used when main is missing")


func test_migration_and_integrity() -> void:
	fresh_profile()
	var prof = tree.root.get_node("/root/Profile")
	var old := {"version": 1, "wallet": {"coins": 50, "gems": 1}, "garage": {"owned": ["ghost_car"], "selected": "ghost_car", "upgrades": {"sarbon_mitti": {"engine": 99}}}}
	prof.data = prof.migrate(old)
	prof.ensure_integrity()
	check(prof.data.has("missions") and prof.data.has("settings"), "missing sections filled from defaults")
	check(prof.owns(DB.starter_vehicle_id()), "starter car always owned")
	check(not prof.owns("ghost_car"), "unknown cars removed")
	eq(prof.selected_vehicle(), DB.starter_vehicle_id(), "invalid selection repaired")
	eq(prof.upgrade_level("sarbon_mitti", "engine"), VehicleSpec.max_level(DB.vehicle("sarbon_mitti")), "upgrade level clamped to max")
	eq(prof.data.settings.language, "uz", "default language is Uzbek")


func test_cloud_snapshot_validation() -> void:
	fresh_profile()
	var save = tree.root.get_node("/root/Save")
	var snap: Dictionary = save.export_snapshot()
	check(not save.validate_snapshot(snap).is_empty(), "own snapshot validates")
	snap.data.wallet.coins = 1_000_000_000
	check(save.validate_snapshot(snap).is_empty(), "tampered snapshot rejected")
	var a := {"wallet": {"coins_earned": 10}, "stats": {"total_distance": 5}, "updated_at": 1}
	var b := {"wallet": {"coins_earned": 500}, "stats": {"total_distance": 900}, "updated_at": 0}
	eq(Services.resolve_conflict(a, b), b, "conflict resolution keeps the more progressed save")
