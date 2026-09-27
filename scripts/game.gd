# The root of the level: starts the zombies when the civilian is alarmed or shot,
# spawns zombies, counts kills, ends well at kills_to_win, restarts on game over
class_name Game extends Node2D

# Reference to the zombie scene
# Needed because zombies are created dynamically
const ZOMBIE_SCENE: PackedScene = preload("res://scenes/zombie.tscn")

# Zombies spawn every spawn_interval seconds
@export var spawn_interval: float = 3.0
# Every extra_spawn_interval seconds, each spawn brings one more zombie
@export var extra_spawn_interval: float = 10.0
# How far outside the visible area zombies appear
@export var spawn_margin: float = 8.0
# Kill this many zombies for the good ending
@export var kills_to_win: int = 100
# Seconds between all players dying and the restart
@export var restart_delay: float = 5.0

# Countdowns: subtract delta every frame, act when they reach zero
var spawn_time_left: float = 0.0
var extra_spawn_time_left: float = 0.0

# Other
# Becomes true once any player has joined; before that nobody can lose
var someone_joined: bool = false
var zombies_per_spawn: int = 1
var zombies_killed: int = 0
# Zombies only spawn after the civilian screams or dies
var zombies_coming: bool = false
# All players are dead
var is_game_over: bool = false
# All zombies are killed
var is_won: bool = false

# These variables access other game components in a convenient way
@onready var hud: HUD = $HUD
@onready var civilian: Civilian = $Civilian


# Called once: when the node enters the scene for the first time
func _ready() -> void:
	extra_spawn_time_left = extra_spawn_interval
	hud.set_kills(zombies_killed)
	# Two different events, one reaction: both start the zombies
	civilian.zombies_are_alarmed.connect(_start_zombies)
	civilian.died.connect(_start_zombies)


# Called every frame
func _process(delta: float) -> void:
	# Endings
	if is_game_over or is_won:
		return

	# No players alive -> game over (but only after someone has joined)
	var players: Array[Node] = get_tree().get_nodes_in_group("players")
	if not players.is_empty():
		someone_joined = true
	elif someone_joined:
		_game_over()
		return

	# Zombie spawn logic
	if zombies_coming:
		extra_spawn_time_left -= delta
		if extra_spawn_time_left <= 0:
			zombies_per_spawn += 1
			extra_spawn_time_left = extra_spawn_interval
		spawn_time_left -= delta
		if spawn_time_left <= 0:
			for i in zombies_per_spawn: # Repeats zombies_per_spawn times
				_spawn_zombie()
			spawn_time_left = spawn_interval


# Zombies start coming after civilian screams
func _start_zombies() -> void:
	zombies_coming = true


# Create zombies outside of the screen
func _spawn_zombie() -> void:
	# The screen rectangle converted to world coordinates (accounts for the camera)
	var visible_rect: Rect2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()
	var zombie: Zombie = ZOMBIE_SCENE.instantiate()
	zombie.global_position = _random_point_on_edge(visible_rect.grow(spawn_margin))
	# Face into the screen so it doesn't wander off while turning toward a player
	zombie.global_rotation = (visible_rect.get_center() - zombie.global_position).angle()
	# Run _on_zombie_died whenever this zombie emits "died"
	zombie.died.connect(_on_zombie_died)
	add_child(zombie)


# Uniformly random point on the perimeter of rect
func _random_point_on_edge(rect: Rect2) -> Vector2:
	# Walk a random distance along the perimeter: top, right, bottom, left
	var t: float = randf() * 2 * (rect.size.x + rect.size.y)
	if t < rect.size.x:
		return rect.position + Vector2(t, 0)
	t -= rect.size.x
	if t < rect.size.y:
		return Vector2(rect.end.x, rect.position.y + t)
	t -= rect.size.y
	if t < rect.size.x:
		return Vector2(rect.end.x - t, rect.end.y)
	t -= rect.size.x
	return Vector2(rect.position.x, rect.end.y - t)


func _on_zombie_died() -> void:
	zombies_killed += 1
	hud.set_kills(zombies_killed)
	if zombies_killed >= kills_to_win and not is_won:
		_win()
	
	
func _game_over() -> void:
	is_game_over = true
	hud.show_game_over()
	# A one-shot timer; await waits for it without freezing the game
	await get_tree().create_timer(restart_delay).timeout
	get_tree().reload_current_scene()
	
	
func _win() -> void:
	# Set the flag first: the zombies we kill below emit "died" and land back in _on_zombie_died
	is_won = true
	for zombie: Zombie in get_tree().get_nodes_in_group("zombies"):
		zombie.die()
	hud.show_victory()
