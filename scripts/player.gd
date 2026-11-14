extends CharacterBody2D

const SPEED := 220.0
const HURT_COOLDOWN := 0.85

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_box: Area2D = $HurtBox

var _hurt_timer := 0.0
var _facing := Vector2.DOWN


func _ready() -> void:
	add_to_group("player")
	hurt_box.body_entered.connect(_on_hurt_box_body_entered)
	if not anim.is_playing():
		anim.play("idle_down")


func _physics_process(delta: float) -> void:
	if GameState.is_game_over:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_hurt_timer = maxf(0.0, _hurt_timer - delta)

	if Input.is_action_just_pressed("use_kit"):
		GameState.try_consume_kit()

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	velocity = input_dir * SPEED
	move_and_slide()
	_update_animation(input_dir)

	# Continuous damage while a monster stays inside the hurt box
	for body in hurt_box.get_overlapping_bodies():
		if body.is_in_group("monsters"):
			_try_take_hit(20)
			break


func _update_animation(input_dir: Vector2) -> void:
	var next := &"idle_down"
	if input_dir != Vector2.ZERO:
		if absf(input_dir.x) > absf(input_dir.y):
			_facing = Vector2.RIGHT if input_dir.x > 0.0 else Vector2.LEFT
			anim.flip_h = input_dir.x < 0.0
			next = &"walk_side"
		elif input_dir.y < 0.0:
			_facing = Vector2.UP
			anim.flip_h = false
			next = &"walk_up"
		else:
			_facing = Vector2.DOWN
			anim.flip_h = false
			next = &"walk_down"
	else:
		anim.flip_h = _facing == Vector2.LEFT
		match _facing:
			Vector2.UP:
				next = &"idle_up"
			Vector2.LEFT, Vector2.RIGHT:
				next = &"idle_side"
			_:
				next = &"idle_down"
	if anim.animation != next:
		anim.play(next)


func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("monsters"):
		_try_take_hit(22)


func _try_take_hit(amount: int) -> void:
	if _hurt_timer > 0.0 or GameState.is_game_over:
		return
	_hurt_timer = HURT_COOLDOWN
	GameState.apply_damage(amount)
	modulate = Color(1.0, 0.45, 0.45)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.35)
