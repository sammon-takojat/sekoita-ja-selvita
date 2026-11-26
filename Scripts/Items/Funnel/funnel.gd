extends RigidBody3D
class_name Funnel
## Script for funnel functions

@export var hold_point : Marker3D

@onready var world_scene = get_tree().root
@onready var funnel = $"."
signal drop_object ## Signal for removing the funnel from the players hand

## The function looks for get_hold_position method in the target object and
## calls it if found. Then sets the position of the funnel to the returned
## position and freezes it.
func use(object_in_los: Node3D, _collision_point: Vector3) -> void:	
	if object_in_los == null:
		return
	if object_in_los is MeasuringCylinder:
		funnel.reparent(object_in_los)
		funnel.collision_mask = 0
		funnel.global_position = object_in_los.hold_point.global_position
		funnel.global_rotation = object_in_los.global_rotation
		funnel.freeze = true
		
		drop_object.emit()
	
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

func reset():
	funnel.reparent(world_scene.get_child(0))
	funnel.collision_mask = 1
