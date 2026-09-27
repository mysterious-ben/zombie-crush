class_name IceCube extends RigidBody2D

# Seconds until the cube has melted away completely
@export var melt_time: float = 60.0

@onready var sprite: Sprite2D = $Sprite2D


# Called once: when the node enters the scene for the first time
func _ready() -> void:
	# Two one-shot timers: halfway it looks melted, at the end it disappears.
	# If the cube is freed early (e.g. the level restarts), Godot drops these connections
	get_tree().create_timer(melt_time / 2).timeout.connect(_half_melt)
	get_tree().create_timer(melt_time).timeout.connect(queue_free)


func _half_melt() -> void:
	# The texture has two frames side by side (hframes = 2); the second one looks melted
	sprite.frame = 1
