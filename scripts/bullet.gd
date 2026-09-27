class_name Bullet extends Area2D

@export var speed: float = 200.0
# Seconds before a bullet that hit nothing is removed
@export var lifetime: float = 3.0

var lifetime_left: float = 0.0


# Called once: when the node enters the scene for the first time
func _ready() -> void:
	lifetime_left = lifetime
	# An Area2D detects bodies without pushing them; call _on_body_entered on each hit
	body_entered.connect(_on_body_entered)


# Moving a collision area belongs in _physics_process, so hits are checked at a fixed rate
func _physics_process(delta: float) -> void:
	# Fly the way we face; the player set our rotation when shooting
	position += transform.x * speed * delta

	lifetime_left -= delta
	if lifetime_left <= 0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Players, civilians and zombies are all Characters
	if body is Character:
		body.die()
	queue_free()
