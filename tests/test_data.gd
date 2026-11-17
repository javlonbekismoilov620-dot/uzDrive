extends TestCase


func test_vehicle_roster() -> void:
	var db = tree.root.get_node("/root/DB")
	check(db.vehicles.size() >= 50, "at least 50 vehicles (have %d)" % db.vehicles.size())
	eq(db.validate(), [], "DB.validate() reports no errors")
	var cats := {}
	var rar := {}
	for v in db.vehicles:
		cats[v.category] = int(cats.get(v.category, 0)) + 1
		rar[v.rarity] = true
	for c in K.CATEGORIES:
		check(cats.has(c), "category %s present" % c)
	for r in K.RARITIES:
		check(rar.has(r), "rarity %s present" % r)
	var gm: int = cats.get("gm", 0)
	for c in cats:
		if c != "gm":
			check(gm > int(cats[c]), "GM-inspired category is the primary (largest) one")


func test_branding_policy() -> void:
	var db = tree.root.get_node("/root/DB")
	var banned := ["chevrolet", "chevy", "gmc", "cadillac", "buick", "general motors"]
	for v in db.vehicles:
		var lic: Dictionary = v.get("license", {})
		check(lic.has("licensed") and lic.licensed == false, "%s ships unlicensed" % v.id)
		check(str(v.get("inspired_by", "")) != "", "%s has internal inspired_by" % v.id)
		var shown: String = (db.vehicle_display_name(v) + " " + db.vehicle_maker(v)).to_lower()
		for b in banned:
			check(not shown.contains(b), "%s display name must not use real brand '%s'" % [v.id, b])


func test_starter_and_prices() -> void:
	var db = tree.root.get_node("/root/DB")
	var starter: Dictionary = db.vehicle(db.starter_vehicle_id())
	eq(int(starter.price), 0, "starter is free")
	var avg := {}
	var cnt := {}
	for v in db.vehicles:
		if v.get("currency", "coins") != "coins":
			continue
		avg[v.rarity] = float(avg.get(v.rarity, 0.0)) + float(v.price)
		cnt[v.rarity] = int(cnt.get(v.rarity, 0)) + 1
	var prev := -1.0
	for r in K.RARITIES:
		var a: float = avg[r] / cnt[r]
		check(a > prev, "average price rises with rarity (%s)" % r)
		prev = a


func test_vehicle_geometry_builds() -> void:
	var db = tree.root.get_node("/root/DB")
	VehicleShape.clear_cache()
	for v in db.vehicles:
		var s := VehicleShape.get_for(v)
		check(s.hull.size() >= 3, "%s hull" % v.id)
		check(s.wheels.size() >= 2, "%s wheels" % v.id)
		check(s.roof_rect.size.x > 1.0 and s.roof_rect.size.y > 1.0, "%s roof sensor" % v.id)
		check(s.parts.size() > 3, "%s has artwork parts" % v.id)
		for w in s.wheels:
			check(float(w.r) > 4.0, "%s wheel radius" % v.id)
		var any_driven := false
		for w in s.wheels:
			any_driven = any_driven or w.driven
		check(any_driven, "%s has a driven wheel" % v.id)


func test_unique_visual_designs() -> void:
	var db = tree.root.get_node("/root/DB")
	var seen := {}
	for v in db.vehicles:
		var key := "%s|%s|%s|%s" % [v.body.type, JSON.stringify(v.style), v.body.get("L", ""), v.body.get("H", "")]
		check(not seen.has(key), "%s has a unique design (duplicate of %s)" % [v.id, seen.get(key, "")])
		seen[key] = v.id


func test_environments() -> void:
	var db = tree.root.get_node("/root/DB")
	eq(db.environments.size(), 8, "eight environments")
	var ids := []
	for e in db.environments:
		ids.append(e.id)
		check(int(e.goal_m) > 0, "%s goal" % e.id)
		check((e.visual.layers as Array).size() >= 3, "%s has parallax layers" % e.id)
		if e.requires != null:
			check(db.env_map.has(e.requires), "%s requires a valid map" % e.id)
	for want in ["green_hills", "desert_road", "snow_mountains", "forest", "city_roads", "rocky_mountains", "countryside", "night_highway"]:
		check(ids.has(want), "environment %s exists" % want)
