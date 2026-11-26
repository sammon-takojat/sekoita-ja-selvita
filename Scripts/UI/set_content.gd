extends PanelContainer
## Script for handling inputs in set container content window

@onready var textfield = $VBoxContainer/TextField
@onready var enter = $VBoxContainer/CenterContainer2/Enter
@onready var close = $VBoxContainer/HBoxContainer/Close
@onready var control = $".."

@onready var object_in_los : RigidBody3D ## The object that we want to set content for

## Sets the process mode to only process when paused, initializes self as invisible,
## starts listening to the signal of buttons being pressed and calls the 
## appropriate function when signal is emitted.
func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	self.visible = false
	enter.pressed.connect(set_liquid_content)
	enter.pressed.connect(control.hide_set_content)
	close.pressed.connect(control.hide_set_content)

## Sets the content of the text field as content of the object in sight
func set_liquid_content():
	var content = textfield.get_text()
	object_in_los.content = content
