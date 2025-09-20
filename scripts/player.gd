extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0
const DOUBLE_TAP_TIME = 0.3  # max seconds between taps to count as double tap
const ROLL_SPEED = 225.0
const ROLL_DURATION = 0.3

var CUR_HP = 50

var time_since_last_left_press := 0.0
var time_since_last_right_press := 0.0
var tapped_once_right := false
var tapped_once_left := false

var is_rolling := false
var roll_timer := 0.0
var roll_direction := 0  # -1 for left, +1 for right

var is_taking_damage := false
var is_dying := false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer
@onready var invincibility: Timer = $Invincibility


func perform_double_roll(direction: int):
	is_rolling = true
	roll_timer = ROLL_DURATION
	roll_direction = direction
	animated_sprite.play("roll")

func die():
	print("You died!!!")
	is_dying = true
	Engine.time_scale = 0.5
	animated_sprite.play("die")
	timer.start()

func get_damaged(amount: int):
	invincibility.start()
	if !is_taking_damage:
		CUR_HP -= amount
		if CUR_HP <= 0:
			die()
		else:
			print("I'm took damage!!")
			animated_sprite.play("hurt")
			is_taking_damage = true

func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Handle roll double tap
	if Input.is_action_just_pressed("move_left") and is_on_floor() and not is_rolling:
		if tapped_once_left and time_since_last_left_press <= DOUBLE_TAP_TIME:
			perform_double_roll(-1)
			tapped_once_left = false
		else:
			tapped_once_left = true
			tapped_once_right = false
			time_since_last_left_press = 0.0

	if Input.is_action_just_pressed("move_right") and is_on_floor() and not is_rolling:
		if tapped_once_right and time_since_last_right_press <= DOUBLE_TAP_TIME:
			perform_double_roll(1)
			tapped_once_right = false
		else:
			tapped_once_right = true
			tapped_once_left = false
			time_since_last_right_press = 0.0

	# Timer for double tap tracking
	if tapped_once_left:
		time_since_last_left_press += delta
		if time_since_last_left_press > DOUBLE_TAP_TIME:
			tapped_once_left = false

	if tapped_once_right:
		time_since_last_right_press += delta
		if time_since_last_right_press > DOUBLE_TAP_TIME:
			tapped_once_right = false

	# Handle roll state
	if is_rolling:
		velocity.x = roll_direction * ROLL_SPEED
		roll_timer -= delta
		if roll_timer <= 0:
			is_rolling = false
	else:
		# Normal movement
		var direction := Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		# Play animations
		if is_dying or is_taking_damage:
			pass
		elif is_on_floor():
			if direction == 0:
				animated_sprite.play("idle")
			else:
				animated_sprite.play("run")
		else:
			animated_sprite.play("jump")

	# Flip sprite
	if velocity.x > 0:
		animated_sprite.flip_h = false
	elif velocity.x < 0:
		animated_sprite.flip_h = true

	move_and_slide()

func _on_invincibility_timeout() -> void:
	is_taking_damage = false
