extends Control
## A script for controlling ui elements

@onready var instructions = $Instructions
@onready var set_content = $SetContent

## Sets the script to run even when the tree is paused
func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS

## Runs the handler every frame
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Show_instructions"):
		toggle_instructions()

## Handles showing and hiding instructions
func toggle_instructions() -> void:
	if instructions.visible:
		hide_instructions()
	else:
		show_instructions()

## Pauses the scene and displays the instructions
func show_instructions() -> void:
	get_tree().paused = true
	instructions.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED

## Hides the instructions, calls the reset function and unpauses the scene
func hide_instructions() -> void:
	instructions.visible = false
	instructions.reset_view()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false

func show_set_content():
	set_content.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED
