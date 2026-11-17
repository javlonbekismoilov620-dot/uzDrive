## Global constants shared by every system.
class_name K
extends RefCounted

const PPM := 40.0                       ## pixels per meter
const LAYER_TERRAIN := 1                ## physics layer bit: ground, obstacles, bridges
const LAYER_VEHICLE := 2
const LAYER_PROPS := 4

const SAVE_VERSION := 1
const DEFAULT_LANG := "uz"
const LANGS := ["uz", "ru", "en"]

const RARITIES := ["common", "rare", "epic", "legendary"]
const CATEGORIES := ["gm", "sports", "suv", "pickup", "offroad", "classic", "special", "premium"]
const UPGRADE_TYPES := ["engine", "suspension", "tires", "fuel"]

const COIN_VALUES := [5, 10, 25, 50, 100, 250, 500]

## Per-level effect of upgrades (fractions). Kept here so UI and physics agree.
const UPG_ENGINE_ACCEL := 0.06
const UPG_ENGINE_POWER := 0.06
const UPG_ENGINE_TOP := 0.04
const UPG_SUSP_DAMP := 0.05
const UPG_SUSP_TRAVEL := 0.025
const UPG_SUSP_LANDING := 0.08
const UPG_TIRES_GRIP := 0.05
const UPG_FUEL_CAP := 0.10
## Arcade tyre grip multiplier applied on top of the per-vehicle value
## (keeps the starter engine-limited rather than traction-limited).
const GRIP_SCALE := 1.25

const RARITY_COLORS := {
	"common": Color("9fb1c6"),
	"rare": Color("3d9bff"),
	"epic": Color("b05cff"),
	"legendary": Color("ffb627"),
}
