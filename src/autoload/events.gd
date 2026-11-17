## Global signal bus. Systems communicate through these signals instead of
## holding references to each other (keeps gameplay, economy, missions and UI decoupled).
extends Node

signal coins_changed(total: int, delta: int)
signal gems_changed(total: int, delta: int)
signal vehicle_purchased(id: String)
signal vehicle_selected(id: String)
signal upgrade_purchased(id: String, type: String, level: int)
signal map_unlocked(id: String)
signal map_completed(id: String)
signal run_started(map_id: String, vehicle_id: String)
signal run_finished(summary: Dictionary)
## Gameplay statistics feed for missions/achievements: kind = distance, coins,
## jump, flip, fuel, boost, airtime, wheelie, gem, checkpoint, upgrade, run ...
signal stat(kind: String, amount: float)
signal missions_changed
signal achievements_changed
signal language_changed(lang: String)
signal settings_changed
signal toast(text: String, kind: String)
