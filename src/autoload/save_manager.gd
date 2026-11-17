## Crash-safe persistence.
##
## * Atomic writes: data goes to save.tmp, is read back and verified, then the
##   previous save is rotated to save.bak.json and the temp file is renamed.
## * Integrity: every file carries a SHA-256 checksum of its payload; a corrupt
##   or truncated file is ignored and the next candidate (tmp, backup) is used.
## * Auto-save: changes are debounced (0.6 s) and flushed immediately when the
##   app is paused, loses focus or is closed, so progress survives a kill.
## * Cloud-ready: export_snapshot()/import_snapshot() exchange a self-validating
##   envelope that a future cloud provider (see Services) can upload/download.
extends Node

signal saved
signal save_failed(reason: String)

const FORMAT := 1
const DEBOUNCE := 0.6

var dir := "user://"
var file_name := "save.json"
var _provider: Callable
var _dirty := false
var _timer := 0.0
var last_load_source := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_provider(c: Callable) -> void:
	_provider = c


func main_path() -> String:
	return dir.path_join(file_name)


func tmp_path() -> String:
	return dir.path_join(file_name.get_basename() + ".tmp")


func bak_path() -> String:
	return dir.path_join(file_name.get_basename() + ".bak.json")


## Returns the newest valid payload, or {} when there is no usable save.
func read() -> Dictionary:
	for p in [main_path(), tmp_path(), bak_path()]:
		var env := _read_envelope(p)
		if not env.is_empty():
			last_load_source = p
			return env.data
	last_load_source = ""
	return {}


func _read_envelope(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {}
	var text := FileAccess.get_file_as_string(p)
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save: unreadable file %s" % p)
		return {}
	if not parsed.has("data") or not parsed.has("checksum") or typeof(parsed.data) != TYPE_DICTIONARY:
		return {}
	if checksum(parsed.data) != str(parsed.checksum):
		push_warning("Save: checksum mismatch in %s" % p)
		return {}
	return parsed


static func checksum(data: Dictionary) -> String:
	return JSON.stringify(data, "", true, true).sha256_text()


## Normalises a payload exactly like a JSON round trip (ints become floats),
## so the checksum computed before writing equals the one after reading.
static func normalize(data: Dictionary) -> Dictionary:
	var rt = JSON.parse_string(JSON.stringify(data, "", true, true))
	return rt if rt is Dictionary else {}


func make_envelope(data: Dictionary) -> Dictionary:
	var norm := normalize(data)
	return {
		"format": FORMAT,
		"saved_at": int(Time.get_unix_time_from_system()),
		"checksum": checksum(norm),
		"data": norm,
	}


func write(data: Dictionary) -> bool:
	var env := make_envelope(data)
	var text := JSON.stringify(env, "", true, true)
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(tmp_path(), FileAccess.WRITE)
	if f == null:
		save_failed.emit("open tmp: %d" % FileAccess.get_open_error())
		return false
	f.store_string(text)
	f.flush()
	f.close()
	# Verify the temp file before replacing the real save.
	if _read_envelope(tmp_path()).is_empty():
		save_failed.emit("verify failed")
		return false
	var d := DirAccess.open(dir)
	if d == null:
		save_failed.emit("dir access")
		return false
	var main_name := file_name
	var bak_name := bak_path().get_file()
	var tmp_name := tmp_path().get_file()
	if d.file_exists(main_name):
		if d.file_exists(bak_name):
			d.remove(bak_name)
		d.rename(main_name, bak_name)
	var err := d.rename(tmp_name, main_name)
	if err != OK:
		save_failed.emit("rename: %d" % err)
		return false
	saved.emit()
	return true


func request_save() -> void:
	_dirty = true
	_timer = DEBOUNCE


func flush() -> void:
	if not _provider.is_valid():
		return
	_dirty = false
	write(_provider.call())


func _process(delta: float) -> void:
	if not _dirty:
		return
	_timer -= delta
	if _timer <= 0.0:
		flush()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_PREDELETE:
			if _dirty:
				flush()


func delete_all() -> void:
	for p in [main_path(), tmp_path(), bak_path()]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


# ---------------- cloud-sync hooks ----------------
func export_snapshot() -> Dictionary:
	if not _provider.is_valid():
		return {}
	return make_envelope(_provider.call())


## Validates a snapshot (e.g. downloaded from the cloud). Returns its payload or {}.
func validate_snapshot(env: Dictionary) -> Dictionary:
	if not env.has("data") or not env.has("checksum") or typeof(env.data) != TYPE_DICTIONARY:
		return {}
	if checksum(env.data) != str(env.checksum):
		return {}
	return env.data
