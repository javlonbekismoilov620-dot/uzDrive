## Integration points for optional platform services. Every provider ships as a
## safe "null" implementation that reports itself unavailable, so the UI never
## shows a button for a feature that does not work. Real SDK adapters (AdMob /
## AppLovin rewarded ads, Play Billing / StoreKit cosmetics, Play Games / Game
## Center cloud saves & leaderboards) can be dropped in later without touching
## gameplay code. No real-money purchase is ever required to progress.
extends Node


class AdsProvider:
	extends RefCounted
	func is_rewarded_available() -> bool:
		return false
	## Calls `done(granted: bool)` when the ad closes.
	func show_rewarded(_placement: String, done: Callable) -> void:
		done.call(false)


class StoreProvider:
	extends RefCounted
	## Only cosmetic products are allowed by design (no loot boxes, no pay-to-win).
	func is_available() -> bool:
		return false
	func products() -> Array:
		return []
	func purchase(_product_id: String, done: Callable) -> void:
		done.call(false)


class CloudSaveProvider:
	extends RefCounted
	func is_available() -> bool:
		return false
	func upload(_snapshot: Dictionary, done: Callable) -> void:
		done.call(false)
	func download(done: Callable) -> void:
		done.call({})


class LeaderboardProvider:
	extends RefCounted
	func is_available() -> bool:
		return false
	func submit(_board: String, _score: int) -> void:
		pass


var ads: AdsProvider = AdsProvider.new()
var store: StoreProvider = StoreProvider.new()
var cloud: CloudSaveProvider = CloudSaveProvider.new()
var leaderboards: LeaderboardProvider = LeaderboardProvider.new()


## Chooses the newer of two save snapshots (for future cloud sync conflicts).
static func resolve_conflict(local_data: Dictionary, remote_data: Dictionary) -> Dictionary:
	if remote_data.is_empty():
		return local_data
	if local_data.is_empty():
		return remote_data
	var lp := float(local_data.get("wallet", {}).get("coins_earned", 0)) + float(local_data.get("stats", {}).get("total_distance", 0))
	var rp := float(remote_data.get("wallet", {}).get("coins_earned", 0)) + float(remote_data.get("stats", {}).get("total_distance", 0))
	if absf(lp - rp) > 0.5:
		return local_data if lp > rp else remote_data
	return local_data if int(local_data.get("updated_at", 0)) >= int(remote_data.get("updated_at", 0)) else remote_data
