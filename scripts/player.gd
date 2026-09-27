# class_name registers "Player" as a type, so other scripts can write "body is Player"
class_name Player extends Character

# A scene is a reusable blueprint; preload loads it once, when this script loads
const BULLET_SCENE: PackedScene = preload("res://scenes/bullet.tscn")
const RECOLOR_SHADER: Shader = preload("res://shaders/recolor_white.gdshader")

# @export makes a variable editable in the Inspector (speeds are in pixels per second)
@export var move_speed: float = 70.0
@export var back_speed: float = 30.0
@export var rotation_speed: float = 3.0 # Radians per second

@export var bullet_spawn_distance: float = 8.0
@export var shoot_delay: float = 1.0

# Input actions are read as action_prefix + "up", "down", "left", "right", "shoot"
# (actions are defined in Project > Project Settings > Input Map)
@export var action_prefix: String = ""
# White pixels of the sprite are drawn in this color
@export var white_replacement: Color = Color.WHITE

@export var from_screen_radius: float = -5.0

var _shoot_cooldown_left: float = 0.0

# Called once: when the node enters the scene for the first time
func _ready() -> void:
	# Groups are tags: zombies chase "humans"; the game checks "players" for game over
	add_to_group("humans")
	add_to_group("players")

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


func _shoot() -> void:
	var bullet: Bullet = BULLET_SCENE.instantiate()
	# Spawn in front of the player so it doesn't hit the shooter
	bullet.global_position = global_position + global_transform.x * bullet_spawn_distance
	bullet.global_rotation = global_rotation
	# Add to the level, not to the player: a child would move and turn with the player
	get_tree().current_scene.add_child(bullet)


# Clamp the position so the whole collision circle stays inside the visible area
func _stay_on_screen() -> void:
	# The screen rectangle converted to world coordinates (accounts for the camera)
	var visible_rect: Rect2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()
	var allowed: Rect2 = visible_rect.grow(from_screen_radius)
	global_position = global_position.clamp(allowed.position, allowed.end)
