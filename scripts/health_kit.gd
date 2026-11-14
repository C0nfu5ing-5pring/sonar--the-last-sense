extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

var _collected := false
var _bob_t := 0.0
var _base_y := 0.0


func _ready() -> void:
	_base_y = position.y
	_bob_t = randf() * TAU
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = false
	collision_layer = 8
	collision_mask = 1


func _process(delta: float) -> void:
	if _collected:
		return
	_bob_t += delta * 3.0
	position.y = _base_y + sin(_bob_t) * 2.5
	var pulse := 1.0 + sin(_bob_t * 2.0) * 0.06
	sprite.scale = Vector2(pulse, pulse)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	GameState.add_kit()
	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)
