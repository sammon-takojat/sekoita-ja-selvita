extends TextureRect
## Script for the needed functions for the instructions

var default_pos : Vector2 ## Default position that it resets to when closing
var default_scale : Vector2 = self.scale ## Default value for scale that it resets to when closing
const max_scale := Vector2(2, 2) ## Maximum zoom
const min_scale := Vector2(0.8, 0.8) ## Minimum zoom
const max_pos := 800 ## Maximum value for y so that the document always stays on screen
const min_pos := -800 ## Minimum value for y so that the document always stays on screen
var zoom := Vector2(0.05, 0.05) ## Zoom sensitivity
var sens := 0.5 ## Sensitivity for moving document

## Initialize the script to be processed only when the scene is paused, sets the
## instructions to be hidden at startup, initializes default position
func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	self.visible = false
	default_pos = self.position

## Function that handles inputs for zoom and moving the image
func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if self.scale < max_scale:
				self.scale += zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if self.scale > min_scale:
					self.scale -= zoom
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("Left_click") or Input.is_action_pressed("Right_click"):
			var new_y = self.position.y + event.relative.y * sens
			if new_y < max_pos and new_y > min_pos:
				self.position.y = new_y

## Resets the scale and position of the image
func reset_view():
	self.scale = default_scale
	self.position = default_pos
