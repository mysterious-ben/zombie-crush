# The root of the level: spawns zombies and player 2, counts kills, restarts on game over
extends Node2D

const ZOMBIE_SCENE: PackedScene = preload("res://scenes/zombie.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const PLAYER2_ACTIONS: Array[String] = ["p2_up", "p2_down", "p2_left", "p2_right", "p2_shoot"]

@export var spawn_interval: float = 3.0
# Every extra_spawn_interval seconds, each spawn brings one more zombie
@export var extra_spawn_interval: float = 10.0
# How far outside the visible area zombies appear (zombie sprite is 16x16)
@export var spawn_margin: float = 8.0

# Seconds between all players dying and the restart
@export var restart_delay: float = 5.0

# Color that replaces white on the second player's sprite
@export var player2_color: Color = Color(0.2, 0.4, 1.0)

# Countdowns: subtract delta every frame, act when they reach zero
var spawn_time_left: float = 0.0
var extra_spawn_time_left: float = 0.0
var zombies_per_spawn: int = 1
var zombies_killed: int = 0
var player2_joined: bool = false
var is_game_over: bool = false

@onready var hud: HUD = $HUD
# Where player 2 appears and which way they face; move it in the editor to change that
@onready var player2_spawn: Marker2D = $Player2Spawn


# Called once: when the node enters the scene for the first time
func _ready() -> void:
	extra_spawn_time_left = extra_spawn_interval
	hud.set_kills(zombies_killed)


# Called every frame
func _process(delta: float) -> void:
	if is_game_over:
		return
	# Dead players leave the group once their death animation ends
	if get_tree().get_nodes_in_group("players").is_empty():
		_game_over()
		return

	if not player2_joined:
		for action in PLAYER2_ACTIONS:
			if Input.is_action_just_pressed(action):
				_spawn_player2()
				break

	extra_spawn_time_left -= delta
	if extra_spawn_time_left <= 0:
		zombies_per_spawn += 1
		extra_spawn_time_left = extra_spawn_interval

	spawn_time_left -= delta
	if spawn_time_left <= 0:
		for i in zombies_per_spawn: # Repeats zombies_per_spawn times
			_spawn_zombie()
		spawn_time_left = spawn_interval


func _game_over() -> void:
	is_game_over = true
	hud.show_game_over()
	# A one-shot timer; await waits for it without freezing the game
	await get_tree().create_timer(restart_delay).timeout
	get_tree().reload_current_scene()


func _spawn_player2() -> void:
	player2_joined = true
	var player2: Player = PLAYER_SCENE.instantiate()
	player2.action_prefix = "p2_"
	player2.white_replacement = player2_color
	player2.global_position = player2_spawn.global_position
	player2.global_rotation = player2_spawn.global_rotation
	# A new node does nothing until it is added to the scene tree
	add_child(player2)


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


func _on_zombie_died() -> void:
	zombies_killed += 1
	hud.set_kills(zombies_killed)


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
