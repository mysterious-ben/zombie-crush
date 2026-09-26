class_name Player extends CharacterBody2D

@export var move_speed: float = 70.0
@export var back_speed: float = 30.0
@export var rotation_speed: float = 3.0

@export var bullet_spawn_distance: float = 8.0
@export var shoot_delay: float = 1.0

# Input actions are read as action_prefix + "up", "down", "left", "right", "shoot"
@export var action_prefix: String = ""
# White pixels of the sprite are drawn in this color
@export var white_replacement: Color = Color.WHITE

const BULLET_SCENE: PackedScene = preload("res://scenes/bullet.tscn")
const RECOLOR_SHADER: Shader = preload("res://shaders/recolor_white.gdshader")

signal died

var is_dead: bool = false
var shoot_cooldown_left: float = 0.0


# Called once: when the node enters the scene for the first time
func _ready() -> void:
	add_to_group("players")

	if white_replacement != Color.WHITE:
		var recolor: ShaderMaterial = ShaderMaterial.new()
		recolor.shader = RECOLOR_SHADER
		recolor.set_shader_parameter("white_replacement", white_replacement)
		$AnimatedSprite2D.material = recolor
	

# Called every frame
func _process(delta: float) -> void:
	if is_dead:
		return

	#var direction: Vector2 = Input.get_vector("left", "right", "up", "down")
	#velocity = direction * move_speed
	
	var rotation_direction: float = Input.get_axis(action_prefix + "left", action_prefix + "right")
	# Positive axis ("up") is forward, negative ("down") is backward
	var move_direction: float = Input.get_axis(action_prefix + "down", action_prefix + "up")
	var speed: float = move_speed if move_direction > 0 else back_speed
	velocity = transform.x * move_direction * speed
	rotation += rotation_direction * rotation_speed * delta

	shoot_cooldown_left -= delta
	if Input.is_action_just_pressed(action_prefix + "shoot") and shoot_cooldown_left <= 0:
		_shoot()
		shoot_cooldown_left = shoot_delay


func _shoot() -> void:
	var bullet: Node2D = BULLET_SCENE.instantiate()
	# Spawn in front of the player (forward is transform.x) so it doesn't hit the shooter
	bullet.global_position = global_position + global_transform.x * bullet_spawn_distance
	bullet.global_rotation = global_rotation
	get_tree().current_scene.add_child(bullet)


func _physics_process(delta: float) -> void:
	move_and_slide()
	_stay_on_screen()


# Clamp the position so the whole collision circle stays inside the visible area
func _stay_on_screen() -> void:
	var radius: float = ($CollisionShape2D.shape as CircleShape2D).radius
	var visible_rect: Rect2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()
	var allowed: Rect2 = visible_rect.grow(-radius)
	global_position = global_position.clamp(allowed.position, allowed.end)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	died.emit()
	# Keep colliding while the animation plays, then remove the body
	$AnimatedSprite2D.play("death")
	await $AnimatedSprite2D.animation_finished
	remove_from_group("players")
	queue_free()
