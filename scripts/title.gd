extends CanvasLayer

## Title screen that displays play and quit buttons

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

@onready var play_button: Button = $MarginContainer/VBoxContainer/PlayButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	# Connect buttons
	if play_button:
		play_button.pressed.connect(_on_play_button_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)

func _on_play_button_pressed() -> void:
	if MAIN_SCENE:
		get_tree().change_scene_to_packed(MAIN_SCENE)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

