class_name Civilian extends Character

# Emitted once, the first time a player bumps into the civilian; the game starts the zombies on it
signal zombies_are_alarmed

@export_multiline var scream_text: String = "AAAAAAAH\nTHEY ARE COMING"
# Seconds the speech stays on screen
@export var scream_duration: float = 3.0

var has_screamed: bool = false
var speech_time_left: float = 0.0

@onready var speech: Label = $Speech
@onready var talk_zone: Area2D = $TalkZone


# Called once: when the node enters the scene for the first time
func _ready() -> void:
	# Groups are tags: zombies find everyone they can chase through this one
	add_to_group("humans")
	# TouchZone is an Area2D a bit larger than our body: it notices a player
	# touching us even though we stand still (only a moving body gets slide collisions)
	talk_zone.body_entered.connect(_on_touch_zone_body_entered)


# Called every frame
func _process(delta: float) -> void:
	# Countdown: hide the speech after scream_duration seconds
	if speech.visible:
		speech_time_left -= delta
		if speech_time_left <= 0:
			speech.hide()


# Called when any physics body enters the TouchZone
func _on_touch_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		scream()


func scream() -> void:
	if has_screamed or is_dead:
		return
	has_screamed = true
	zombies_are_alarmed.emit()
	speech.text = scream_text
	# Speech is "top_level": it ignores our rotation, so the text stays upright.
	# That also means we place it ourselves: centered, just above the civilian
	speech.global_position = global_position + Vector2(-speech.size.x / 2, -speech.size.y - 8)
	speech.show()
	speech_time_left = scream_duration
