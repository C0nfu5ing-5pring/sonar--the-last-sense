extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var max_health = 100
var health = 100
var is_dead = false

func take_damage(amount: int):
	if is_dead:
		return

	health -= amount
	health = max(health, 0)

	print("Health:", health)

	if health <= 0:
		die()

func die():
	is_dead = true
	print("Player died!")
	get_tree().reload_current_scene()


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
