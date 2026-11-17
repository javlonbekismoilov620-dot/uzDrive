## Prints cumulative collectible coin value / fuel cans / gems by distance for
## every map, straight from the terrain generator (input for the economy model).
extends SceneTree

func _initialize() -> void:
	_go.call_deferred()

func _go() -> void:
	var marks := [250, 500, 750, 1000, 1500, 2000, 2500, 3000, 4000, 5000]
	var out := {}
	for e in root.get_node("/root/DB").environments:
		var g := TerrainGenerator.new(e)
		g.ensure(5100)
		var row := {}
		for m in marks:
			var coins := 0
			var fuel := 0
			var gems := 0
			for p in g.pickups:
				if p.x > m:
					continue
				match p.kind:
					"coin":
						coins += int(p.value)
					"fuel":
						fuel += 1
					"gem":
						gems += 1
			row[str(m)] = {"coins": coins, "fuel": fuel, "gems": gems}
		out[e.id] = row
	print("COINCURVE " + JSON.stringify(out))
	quit()
