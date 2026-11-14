extends CharacterBody2D

const SPEED := 95.0
const CHASE_RANGE := 520.0
const ATTACK_RANGE := 42.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var _player: Node2D


func _ready() -> void:
	add_to_group("monsters")
	collision_layer = 4
	collision_mask = 2  # walls only; damage is handled by the player's HurtBox
	anim.play("walk")


func _physics_process(_delta: float) -> void:
	if GameState.is_game_over:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if _player == null:
			return

	var to_player := _player.global_position - global_position
	var dist := to_player.length()

	if dist <= CHASE_RANGE and dist > 8.0:
		var dir := to_player / dist
		velocity = dir * SPEED
		# Sheet faces left by default.
		anim.flip_h = dir.x > 0.0
		var next := &"attack" if dist <= ATTACK_RANGE else &"walk"
		if anim.animation != next:
			anim.play(next)
	else:
		velocity = Vector2.ZERO
		if anim.animation != &"idle":
			anim.play(&"idle")

	move_and_slide()
