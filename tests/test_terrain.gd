extends TestCase


func test_deterministic() -> void:
	for e in DB.environments:
		var a := TerrainGenerator.new(e)
		var b := TerrainGenerator.new(e)
		a.ensure(1500)
		b.ensure(1500)
		eq(a.ys.size(), b.ys.size(), "%s same length" % e.id)
		var same := true
		for i in mini(a.ys.size(), b.ys.size()):
			if a.ys[i] != b.ys[i]:
				same = false
				break
		check(same, "%s heights identical for same seed" % e.id)
		eq(a.pickups.size(), b.pickups.size(), "%s pickups identical" % e.id)


func test_slopes_and_pickups() -> void:
	for e in DB.environments:
		var g := TerrainGenerator.new(e)
		g.ensure(3000)
		var max_s: float = float(e.terrain.max_slope_late) * 1.25 + 0.05
		var bad := 0
		for i in range(1, g.ys.size()):
			if g.flags[i] != 0 or g.flags[i - 1] != 0:
				continue
			if absf(g.ys[i] - g.ys[i - 1]) / TerrainGenerator.STEP > max_s:
				bad += 1
		check(bad == 0, "%s smooth terrain respects slope limit (%d violations)" % [e.id, bad])
		# warm-up: first 150 m gentle
		var steep_start := 0.0
		for i in range(1, int(150.0 / TerrainGenerator.STEP)):
			steep_start = maxf(steep_start, absf(g.ys[i] - g.ys[i - 1]) / TerrainGenerator.STEP)
		check(steep_start < 0.62, "%s warm-up section is gentle (max slope %.2f)" % [e.id, steep_start])
		var fuel_xs: Array = []
		for p in g.pickups:
			if p.kind == "coin":
				check(K.COIN_VALUES.has(int(p.value)), "coin value %d allowed" % int(p.value))
			elif p.kind == "fuel":
				fuel_xs.append(float(p.x))
		check(fuel_xs.size() >= 5, "%s has fuel cans over 3 km" % e.id)
		for i in range(1, fuel_xs.size()):
			var gap: float = fuel_xs[i] - fuel_xs[i - 1]
			check(gap <= float(e.pickups.fuel_max) * 1.1, "%s fuel gap %.0f m within max" % [e.id, gap])
		for o in g.obstacles:
			check(float(o.size) <= float(e.obstacles.max) * 1.3, "%s obstacle size bounded" % e.id)


func test_high_value_coins_appear_far_out() -> void:
	var e: Dictionary = DB.env("green_hills")
	var g := TerrainGenerator.new(e)
	g.ensure(4600)
	var seen := {}
	for p in g.pickups:
		if p.kind == "coin":
			seen[int(p.value)] = true
	for v in [5, 10, 25, 50, 100, 250, 500]:
		check(seen.has(v), "coin value %d appears within 4.6 km" % v)
