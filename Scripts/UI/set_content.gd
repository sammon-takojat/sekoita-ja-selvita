extends PanelContainer

@onready var textfield = $VBoxContainer/TextField
@onready var button = $VBoxContainer/CenterContainer2/Button
@onready var control = $".."

@onready var object_in_los : RigidBody3D


func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	self.visible = false
	button.pressed.connect(set_liquid_content)
	button.pressed.connect(control.hide_set_content)

func set_liquid_content():
	var content = textfield.get_text()
	object_in_los.content = content
