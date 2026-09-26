class_name Bullet extends Area2D

@export var speed: float = 200.0
@export var lifetime: float = 3.0


# Called once: when the node enters the scene for the first time
func _ready() -> void:
	body_entered.connect(_on_body_entered)


# Called every frame
func _process(delta: float) -> void:
	# "Forward" is transform.x (the sprite faces right)
	position += transform.x * speed * delta

	lifetime -= delta
	if lifetime <= 0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player or body is Zombie:
		body.die()
		queue_free()
