class_name Zombie extends CharacterBody2D

@export var move_speed: float = 15.0
@export var rotation_speed: float = 1.5

signal died

var is_dead: bool = false


# Called once: when the node enters the scene for the first time
func _ready() -> void:
	pass
	

# Called every frame
func _process(delta: float) -> void:
	if is_dead:
		return

	var target: Player = _find_closest_player()
	if target == null:
		velocity = Vector2.ZERO
		return

	# Turn gradually toward the target; "forward" is transform.x (the sprite faces right)
	var direction: Vector2 = global_position.direction_to(target.global_position)
	rotation = rotate_toward(rotation, direction.angle(), rotation_speed * delta)
	velocity = transform.x * move_speed


func _find_closest_player() -> Player:
	var closest: Player = null
	var closest_distance: float = INF
	for player: Player in get_tree().get_nodes_in_group("players"):
		var distance: float = global_position.distance_squared_to(player.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = player
	return closest


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	move_and_slide()

	for i in get_slide_collision_count():
		var collider: Object = get_slide_collision(i).get_collider()
		if collider is Player:
			collider.die()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	died.emit()
	# Keep colliding while the animation plays, then remove the body
	$AnimatedSprite2D.play("death")
	await $AnimatedSprite2D.animation_finished
	queue_free()
