extends RigidBody3D
class_name Funnel
## Script for funnel functions

@export var hold_point : Marker3D

@onready var funnel = $"."
signal drop_object ## Signal for removing the funnel from the players hand

## The function looks for get_hold_position method in the target object and
## calls it if found. Then sets the position of the funnel to the returned
## position and freezes it.
func use(object_in_los: Node3D, _collision_point: Vector3) -> void:
	if object_in_los == null:
		return
	
	var parent_node = object_in_los
	
	while parent_node != null:
		if parent_node.has_method("get_hold_position"):
			var target_pos = parent_node.get_hold_position()
			drop_object.emit()
			funnel.freeze = true
			funnel.global_position = target_pos
			funnel.global_rotation = Vector3(0, 0, 0)
			return
		parent_node = parent_node.get_parent()

func get_hold_position():
	var target_pos = self.global_position
	return target_pos
