# Shared base for everything that can die (players, civilians, zombies):
# "extends Character" gives a script all of this code, so death lives in one place
class_name Character extends CharacterBody2D

# Signals announce that something happened; the game connects to zombies' one to count kills
signal died

var is_dead: bool = false

# This makes using AnimatedSprite2D more convenient
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func die() -> void:
	# A bullet and a zombie can hit on the same frame; die only once
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	died.emit()
	# Keep colliding while the animation plays, then remove the body.
	# await pauses this function until the signal fires; the game keeps running
	sprite.play("death")
	await sprite.animation_finished
	# Deletes the node safely at the end of the current frame (this also removes it from its groups)
	queue_free()
