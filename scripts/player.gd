# class_name registers "Player" as a type, so other scripts can write "body is Player"
class_name Player extends Character

# Reference to the bullet scene
# Needed because bullets are created dynamically
const BULLET_SCENE: PackedScene = preload("res://scenes/bullet.tscn")
# Used to recolor the second player
const RECOLOR_SHADER: Shader = preload("res://shaders/recolor_white.gdshader")

const ACTIONS: Array[String] = ["up", "down", "left", "right", "shoot"]

# @export makes a variable editable in the Inspector (speeds are in pixels per second)
@export var move_speed: float = 70.0
@export var back_speed: float = 30.0
@export var rotation_speed: float = 3.0 # Radians per second

# Fire a bullet logic
@export var bullet_spawn_distance: float = 8.0
@export var shoot_delay: float = 1.0

# Input actions are read as action_prefix + "up", "down", "left", "right", "shoot"
# (actions are defined in Project > Project Settings > Input Map)
@export var action_prefix: String = ""
# White pixels of the sprite are drawn in this color
@export var white_replacement: Color = Color.WHITE
# Players cannot leave the sceen area (margin)
@export var screen_lock_margin: float = -5.0

# Countdown until the player can fire again
var _shoot_cooldown_left: float = 0.0
# Until one of our controls is pressed we are invisible and out of the game
var has_joined: bool = false

# @onready fills the variable once child nodes exist, just before _ready
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

# Called once: when the node enters the scene for the first time
func _ready() -> void:
	hide()
	collision_shape.disabled = true

	if white_replacement != Color.WHITE:
		var recolor: ShaderMaterial = ShaderMaterial.new()
		recolor.shader = RECOLOR_SHADER
		recolor.set_shader_parameter("white_replacement", white_replacement)
		# $Name gets a child node by name
		sprite.material = recolor


# Movement, collisions and input that drives them belong in _physics_process:
# it runs at a fixed rate, so the game behaves the same at any frame rate.
# delta is the time since the last call, in seconds
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	# Wait for any of our controls; that press only joins, it doesn't move or shoot
	if not has_joined:
		for action in ACTIONS:
			if Input.is_action_just_pressed(action_prefix + action):
				_join()
				break
		return

	# get_axis returns -1, 0 or 1 (or in between for a gamepad stick)
	var rotation_direction: float = Input.get_axis(action_prefix + "left", action_prefix + "right")
	var move_direction: float = Input.get_axis(action_prefix + "down", action_prefix + "up")
	var speed: float = move_speed if move_direction > 0 else back_speed
	rotation += rotation_direction * rotation_speed * delta
	# transform.x is the direction the node faces (the sprite faces right)
	velocity = transform.x * move_direction * speed
	# Moves by velocity and slides along anything it bumps into
	move_and_slide()
	_stay_on_screen()

	_shoot_cooldown_left -= delta
	if Input.is_action_just_pressed(action_prefix + "shoot") and _shoot_cooldown_left <= 0:
		_shoot()
		_shoot_cooldown_left = shoot_delay


func _join() -> void:
	has_joined = true
	show()
	collision_shape.disabled = false
	# Groups are tags: zombies chase "humans"; the game checks "players" for game over.
	# We join them only now, so a player who hasn't joined is ignored by both
	add_to_group("humans")
	add_to_group("players")


func _shoot() -> void:
	var bullet: Bullet = BULLET_SCENE.instantiate()
	# Spawn in front of the player so it doesn't hit the shooter
	bullet.global_position = global_position + global_transform.x * bullet_spawn_distance
	bullet.global_rotation = global_rotation
	# Add to the level, not to the player: a child would move and turn with the player
	get_tree().current_scene.add_child(bullet)
	audio_stream_player_2d.play()


# Clamp the position so the whole collision circle stays inside the visible area
func _stay_on_screen() -> void:
	# The screen rectangle converted to world coordinates (accounts for the camera)
	var visible_rect: Rect2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()
	var allowed: Rect2 = visible_rect.grow(screen_lock_margin)
	global_position = global_position.clamp(allowed.position, allowed.end)
