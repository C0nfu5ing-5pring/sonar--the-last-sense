extends Node2D

const ARENA_SIZE := Vector2(1600, 1100)
const WALL_THICKNESS := 40.0
const COIN_COUNT := 18
const KIT_COUNT := 5
const MONSTER_COUNT := 6

@onready var world: Node2D = $World
@onready var entities: Node2D = $Entities
@onready var player: CharacterBody2D = $Entities/Player
@onready var camera: Camera2D = $Entities/Player/Camera2D

var _coin_scene: PackedScene = preload("res://scenes/coin.tscn")
var _kit_scene: PackedScene = preload("res://scenes/health_kit.tscn")
var _monster_scene: PackedScene = preload("res://scenes/monster.tscn")
var _floor_tex: Texture2D = preload("res://assets/floor_tile.png")
var _cover_rects: Array[Rect2] = [
	Rect2(280, 220, 140, 40),
	Rect2(900, 180, 160, 40),
	Rect2(520, 520, 40, 180),
	Rect2(1100, 480, 40, 200),
	Rect2(700, 780, 220, 40),
	Rect2(360, 860, 120, 40),
]
var _survival_timer := 0.0


func _ready() -> void:
	randomize()
	_build_arena()
	_start_run()
	GameState.player_died.connect(_on_player_died)


func _process(delta: float) -> void:
	if GameState.is_game_over:
		return
	_survival_timer += delta
	if _survival_timer >= 2.0:
		_survival_timer = 0.0
		GameState.add_score(1)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		_start_run()


func _start_run() -> void:
	GameState.reset_run()
	_survival_timer = 0.0
	_clear_dynamic_entities()
	player.global_position = ARENA_SIZE * 0.5
	player.velocity = Vector2.ZERO
	player.modulate = Color.WHITE
	player.visible = true
	camera.enabled = true
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(ARENA_SIZE.x)
	camera.limit_bottom = int(ARENA_SIZE.y)
	_spawn_pickups()
	_spawn_monsters()


func _clear_dynamic_entities() -> void:
	var to_free: Array[Node] = []
	for child in entities.get_children():
		if child.is_in_group("pickups") or child.is_in_group("monsters"):
			to_free.append(child)
	for child in to_free:
		child.free()


func _build_arena() -> void:
	# Efficient tiled floor via TileMapLayer (replaces the old 800KB atlas dump)
	var tileset := TileSet.new()
	var atlas := TileSetAtlasSource.new()
	atlas.texture = _floor_tex
	atlas.texture_region_size = Vector2i(64, 64)
	atlas.create_tile(Vector2i(0, 0))
	tileset.add_source(atlas, 0)
	var floor_layer := TileMapLayer.new()
	floor_layer.name = "Floor"
	floor_layer.tile_set = tileset
	floor_layer.modulate = Color(0.75, 0.82, 1.0, 1.0)
	var cols := int(ceil(ARENA_SIZE.x / 64.0))
	var rows := int(ceil(ARENA_SIZE.y / 64.0))
	for y in rows:
		for x in cols:
			floor_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	world.add_child(floor_layer)

	# Dim overlay for atmosphere
	var dim_poly := Polygon2D.new()
	dim_poly.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(ARENA_SIZE.x, 0),
		ARENA_SIZE,
		Vector2(0, ARENA_SIZE.y),
	])
	dim_poly.color = Color(0.05, 0.08, 0.14, 0.35)
	world.add_child(dim_poly)

	_add_wall(Rect2(0, -WALL_THICKNESS, ARENA_SIZE.x, WALL_THICKNESS))
	_add_wall(Rect2(0, ARENA_SIZE.y, ARENA_SIZE.x, WALL_THICKNESS))
	_add_wall(Rect2(-WALL_THICKNESS, 0, WALL_THICKNESS, ARENA_SIZE.y))
	_add_wall(Rect2(ARENA_SIZE.x, 0, WALL_THICKNESS, ARENA_SIZE.y))

	for rect in _cover_rects:
		_add_wall(rect, Color(0.18, 0.28, 0.42, 1.0))


func _add_wall(rect: Rect2, color: Color = Color(0.12, 0.18, 0.28, 1.0)) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position
	body.collision_layer = 2
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = rect.size
	shape.shape = rect_shape
	shape.position = rect.size * 0.5
	body.add_child(shape)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(rect.size.x, 0),
		rect.size,
		Vector2(0, rect.size.y),
	])
	visual.color = color
	body.add_child(visual)
	world.add_child(body)


func _spawn_pickups() -> void:
	for i in COIN_COUNT:
		var coin := _coin_scene.instantiate() as Node2D
		coin.add_to_group("pickups")
		coin.position = _random_open_point(60.0)
		entities.add_child(coin)

	for i in KIT_COUNT:
		var kit := _kit_scene.instantiate() as Node2D
		kit.add_to_group("pickups")
		kit.position = _random_open_point(80.0)
		entities.add_child(kit)


func _spawn_monsters() -> void:
	for i in MONSTER_COUNT:
		var monster := _monster_scene.instantiate() as Node2D
		monster.position = _random_open_point(140.0, true)
		entities.add_child(monster)


func _random_open_point(min_player_dist: float, away_from_center: bool = false) -> Vector2:
	var center := ARENA_SIZE * 0.5
	for _attempt in 40:
		var p := Vector2(
			randf_range(80.0, ARENA_SIZE.x - 80.0),
			randf_range(80.0, ARENA_SIZE.y - 80.0)
		)
		if p.distance_to(center) < min_player_dist:
			continue
		if away_from_center and p.distance_to(center) < 280.0:
			continue
		if _is_inside_cover(p):
			continue
		return p
	return Vector2(randf_range(100, ARENA_SIZE.x - 100), randf_range(100, ARENA_SIZE.y - 100))


func _is_inside_cover(point: Vector2) -> bool:
	var padded := 28.0
	for rect in _cover_rects:
		if rect.grow(padded).has_point(point):
			return true
	return false


func _on_player_died() -> void:
	player.velocity = Vector2.ZERO
