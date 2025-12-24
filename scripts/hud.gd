extends CanvasLayer

## HUD scene that displays player health, score, and pause button

signal pause_requested
signal restart_requested
signal quit_requested

@onready var hearts_container: HBoxContainer = $MarginContainer/HBoxContainer/LeftContainer/HeartsContainer
@onready var score_label: Label = $MarginContainer/HBoxContainer/LeftContainer/ScoreLabel
@onready var pause_button: Button = $MarginContainer/HBoxContainer/PauseButton
@onready var gameover_popup: Panel = $GameoverPopup
@onready var restart_button: Button = $GameoverPopup/VBoxContainer/RestartButton
@onready var quit_button: Button = $GameoverPopup/VBoxContainer/QuitButton

const HEART_FULL: String = "♥"
const HEART_EMPTY: String = "♡"

var max_hearts: int = 3
var current_hearts: int = 3

func _ready() -> void:
	# Connect pause button
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)
	
	# Connect restart button
	if restart_button:
		restart_button.pressed.connect(_on_restart_button_pressed)
	
	# Connect quit button
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Hide gameover popup initially
	if gameover_popup:
		gameover_popup.visible = false
	
	# Initialize hearts display
	_update_hearts_display()
	_update_score_display(0)

func _on_pause_button_pressed() -> void:
	pause_requested.emit()

func update_health(new_health: int) -> void:
	current_hearts = new_health
	_update_hearts_display()

func update_score(new_score: int) -> void:
	_update_score_display(new_score)

func _update_hearts_display() -> void:
	if not hearts_container:
		return
	
	# Clear existing hearts
	for child in hearts_container.get_children():
		child.queue_free()
	
	# Create heart labels
	for i in range(max_hearts):
		var heart_label: Label = Label.new()
		if i < current_hearts:
			heart_label.text = HEART_FULL
		else:
			heart_label.text = HEART_EMPTY
		heart_label.add_theme_font_size_override("font_size", 24)
		hearts_container.add_child(heart_label)

func _update_score_display(score: int) -> void:
	if score_label:
		score_label.text = "Score: " + str(score)

func show_gameover() -> void:
	if gameover_popup:
		gameover_popup.visible = true

func hide_gameover() -> void:
	if gameover_popup:
		gameover_popup.visible = false

func _on_restart_button_pressed() -> void:
	restart_requested.emit()

func _on_quit_button_pressed() -> void:
	quit_requested.emit()

