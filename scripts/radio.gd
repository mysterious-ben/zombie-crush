class_name Radio extends AnimatableBody2D

# Pixels around our collision shape that still count as touching
const TOUCH_MARGIN: float = 1.0

var is_on: bool = false

@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _physics_process(_delta: float) -> void:
	# We never move, so we get no slide collisions. Instead we ask the physics
	# world what overlaps our own collision shape, grown by TOUCH_MARGIN
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = collision_shape.global_transform
	query.margin = TOUCH_MARGIN
	query.collide_with_areas = true # Bullets are Area2Ds
	query.exclude = [get_rid()] # Don't report ourselves

	for result in get_world_2d().direct_space_state.intersect_shape(query):
		var other: Object = result.collider
		if other is Bullet:
			# Shot: destroy the bullet and ourselves. The music player is our child, so the music stops too
			other.queue_free()
			queue_free()
			return
		if other is Character:
			turn_on()


func turn_on() -> void:
	if is_on:
		return
	is_on = true
	animated_sprite_2d.play()
	audio_stream_player_2d.play()
