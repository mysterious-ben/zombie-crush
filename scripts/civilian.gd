class_name Civilian extends Character

# Emitted once, the first time a player bumps into the civilian; the game starts the zombies on it
signal zombies_are_alarmed

@export_multiline var scream_text: String = "AAAAAAA\nTHEY ARE COMING"
@export_multiline var celebrate_text: String = "WOOOOOW\nTHANK YOU"
# Seconds the speech stays on screen
@export var scream_duration: float = 3.0

var has_screamed: bool = false
var has_celebrated: bool = false

@onready var speech: Label = $Speech
@onready var talk_zone: Area2D = $TalkZone

# Called once: when the node enters the scene for the first time
func _ready() -> void:
	# Groups are tags: zombies find everyone they can chase through this one
	add_to_group("humans")
	# TalkZone is an Area2D a bit larger than our body: it notices a player
	# touching us even though we stand still (only a moving body gets slide collisions)
	talk_zone.body_entered.connect(_talk_when_someone_is_close)


# Called when any physics body enters the TalkZone
func _talk_when_someone_is_close(body: Node2D) -> void:
	if body is Player:
		scream()

func scream() -> void:
	if is_dead:
		return
	if not has_screamed:
		has_screamed = true
		zombies_are_alarmed.emit()
		speech.text = scream_text
		# Speech is "top_level": it ignores our rotation, so the text stays upright.
		# That also means we place it ourselves: centered, just above the civilian
		speech.global_position = global_position + Vector2(-speech.size.x / 2, -speech.size.y - 8)
		speech.show()
		# When the timer fires, it calls speech.hide(). If the civilian (and its
		# Speech label) is freed first, Godot drops the connection automatically
		get_tree().create_timer(scream_duration).timeout.connect(speech.hide)
		return
	var game: Game = get_tree().current_scene as Game
	if not has_celebrated and game and game.is_won:
		has_celebrated = true
		speech.text = celebrate_text
		speech.show()
		get_tree().create_timer(scream_duration).timeout.connect(speech.hide)
		
