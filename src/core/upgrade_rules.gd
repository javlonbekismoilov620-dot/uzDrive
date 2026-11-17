## Upgrade pricing. All economy numbers for upgrades live here (single source).
class_name UpgradeRules
extends RefCounted

const TYPE_MULT := {"engine": 1.25, "suspension": 1.0, "tires": 0.95, "fuel": 0.8}
## Last level costs ~LAST_TO_FIRST times the first one, whatever the track length.
const LAST_TO_FIRST := 12.0


## Price to go from `level` to `level + 1`. Returns -1 when already maxed.
static func cost(vdef: Dictionary, type: String, level: int) -> int:
	var mx := VehicleSpec.max_level(vdef)
	if level >= mx or level < 0:
		return -1
	var base := float(vdef.get("upgrades", {}).get("cost_base", 300))
	var growth := pow(LAST_TO_FIRST, 1.0 / maxf(mx - 1, 1))
	var raw := base * float(TYPE_MULT.get(type, 1.0)) * pow(growth, level)
	return nice_round(raw)


static func total_cost_to_max(vdef: Dictionary, type: String) -> int:
	var total := 0
	for l in VehicleSpec.max_level(vdef):
		total += cost(vdef, type, l)
	return total


static func nice_round(v: float) -> int:
	if v < 1000.0:
		return int(round(v / 10.0) * 10)
	if v < 10000.0:
		return int(round(v / 50.0) * 50)
	if v < 100000.0:
		return int(round(v / 250.0) * 250)
	return int(round(v / 1000.0) * 1000)
