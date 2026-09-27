class_name Civilian extends Character


# Called once: when the node enters the scene for the first time
func _ready() -> void:
	# Groups are tags: zombies find everyone they can chase through this one
	add_to_group("humans")
