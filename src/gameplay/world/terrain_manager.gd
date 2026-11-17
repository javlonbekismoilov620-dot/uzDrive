## Streams TerrainChunks around the camera and answers terrain queries.
class_name TerrainManager
extends Node2D

const CHUNK_SAMPLES := 128   ## 64 m per chunk
const P := K.PPM

var gen: TerrainGenerator
var env: Dictionary
var chunks := {}
var ground_tex: Texture2D
var _surfaces: Array = []


func setup(environment: Dictionary) -> void:
	env = environment
	gen = TerrainGenerator.new(env)
	var tex_name: String = env.get("visual", {}).get("texture", "")
	if tex_name != "":
		var path := "res://assets/textures/%s.png" % tex_name
		if ResourceLoader.exists(path):
			ground_tex = load(path)
	var base: Dictionary = env.get("surface", {"grip": 1.0, "roll": 0.015})
	var patch: Dictionary = env.get("patch", {})
	_surfaces = [base, patch if not patch.is_empty() else base]


func chunk_len_m() -> float:
	return CHUNK_SAMPLES * TerrainGenerator.STEP


func update(x_px: float) -> void:
	var x_m := x_px / P
	var cl := chunk_len_m()
	var ci := int(floor(x_m / cl))
	gen.ensure((ci + 4) * cl + 2.0)
	for i in range(maxi(ci - 1, 0), ci + 3):
		if not chunks.has(i):
			var c := TerrainChunk.new()
			c.build(gen, env, i, CHUNK_SAMPLES, ground_tex)
			add_child(c)
			chunks[i] = c
	for k in chunks.keys():
		if k < ci - 2 or k > ci + 4:
			chunks[k].queue_free()
			chunks.erase(k)


func surface_for_x(x_px: float) -> Dictionary:
	return _surfaces[gen.surface_at(x_px / P)]


func surface_y_px(x_px: float) -> float:
	return -gen.surface_height_at(x_px / P) * P
