# Zombies are Characters too: they get is_dead, the "died" signal and die() from there
class_name Zombie extends Character

@export var move_speed: float = 15.0
@export var rotation_speed: float = 1.5 # Radians per second


# Called once: when the node enters the scene for the first time
func _ready() -> void:
	pass


# Movement and collisions belong in _physics_process: it runs at a fixed rate
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var target: Character = _find_closest_human()
	if target == null:
		return

	# Turn gradually toward the target, then walk the way we face (transform.x)
	var direction: Vector2 = global_position.direction_to(target.global_position)
	rotation = rotate_toward(rotation, direction.angle(), rotation_speed * delta)
	velocity = transform.x * move_speed
	move_and_slide()

	# move_and_slide records everything we bumped into this step
	for i in get_slide_collision_count():
		var collider: Node = get_slide_collision(i).get_collider()
		if collider.is_in_group("humans"):
			collider.die()


func _find_closest_human() -> Character:
	var closest: Character = null
	var closest_distance: float = INF
	for human: Character in get_tree().get_nodes_in_group("humans"):
		# Squared distance is cheaper (no square root) and compares the same way
		var distance: float = global_position.distance_squared_to(human.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = human
	return closest
