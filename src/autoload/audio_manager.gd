## Audio: music (cross-faded), pooled one-shot SFX and looping engine streams.
## Buses: Master > Music, Master > SFX > Engine. Sound and music can be
## disabled/adjusted independently (Settings). Missing files never crash.
extends Node

const SFX_DIR := "res://assets/audio/sfx/%s.wav"
const MUSIC_DIR := "res://assets/audio/music/%s.ogg"
const ENGINE_DIR := "res://assets/audio/engine/%s.wav"
const POOL := 12

var _pool: Array[AudioStreamPlayer] = []
var _pool_i := 0
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_current := ""
var _cache := {}
var _last_play := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music", "Master")
	_ensure_bus("SFX", "Master")
	_ensure_bus("Engine", "SFX")
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_music_a = AudioStreamPlayer.new()
	_music_b = AudioStreamPlayer.new()
	for m in [_music_a, _music_b]:
		m.bus = "Music"
		add_child(m)
	apply_settings()
	Events.settings_changed.connect(apply_settings)


func _ensure_bus(bus_name: String, send: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, bus_name)
		AudioServer.set_bus_send(i, send)


func apply_settings() -> void:
	var sfx := AudioServer.get_bus_index("SFX")
	var mus := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_mute(sfx, not bool(Profile.setting("sound", true)))
	AudioServer.set_bus_mute(mus, not bool(Profile.setting("music", true)))
	AudioServer.set_bus_volume_db(sfx, linear_to_db(maxf(float(Profile.setting("sfx_volume", 0.9)), 0.001)))
	AudioServer.set_bus_volume_db(mus, linear_to_db(maxf(float(Profile.setting("music_volume", 0.7)), 0.001)))


func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	_cache[path] = s
	return s


## Fire-and-forget sound effect. Rapid repeats of the same sound are throttled.
func sfx(sfx_name: String, volume_db := 0.0, pitch := 1.0) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_last_play.get(sfx_name, -1000)) < 35:
		return
	_last_play[sfx_name] = now
	var s := _load(SFX_DIR % sfx_name)
	if s == null:
		return
	var p := _pool[_pool_i]
	_pool_i = (_pool_i + 1) % POOL
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


func music(track: String, fade := 0.8) -> void:
	if track == _music_current:
		return
	_music_current = track
	var s := _load(MUSIC_DIR % track)
	var old := _music_a if _music_a.playing else _music_b
	var nw := _music_b if old == _music_a else _music_a
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	if old.playing:
		var tw := create_tween()
		tw.tween_property(old, "volume_db", -40.0, fade)
		tw.tween_callback(old.stop)
	if s:
		nw.stream = s
		nw.volume_db = -40.0
		nw.play()
		var tw2 := create_tween()
		tw2.tween_property(nw, "volume_db", 0.0, fade)


func stop_music(fade := 0.6) -> void:
	_music_current = ""
	for m in [_music_a, _music_b]:
		if m.playing:
			var tw := create_tween()
			tw.tween_property(m, "volume_db", -40.0, fade)
			tw.tween_callback(m.stop)


## Looping engine sample for a profile (i3, i4, v8, electric ...).
func engine_stream(profile: String) -> AudioStream:
	var s := _load(ENGINE_DIR % profile)
	if s == null:
		s = _load(ENGINE_DIR % "i4")
	if s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		if w.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = int(w.get_length() * w.mix_rate)
	return s


func vibrate(ms := 40) -> void:
	if bool(Profile.setting("vibration", true)) and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)
