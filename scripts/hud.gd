class_name HUD extends CanvasLayer

# A CanvasLayer is drawn on top of the game and ignores the camera, so the HUD stays put.
# The HUD only displays things. The game decides *when*, and calls these methods
# ("call down, signal up": parents call methods on children, children emit signals)

# @onready fills the variable once child nodes exist, just before _ready
@onready var kill_label: Label = $KillCount
@onready var game_over_overlay: ColorRect = $GameOverOverlay


func set_kills(count: int) -> void:
	kill_label.text = str(count)


func show_game_over() -> void:
	game_over_overlay.visible = true
