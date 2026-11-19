extends RigidBody3D
class_name FilterPaper
## Script for filter paper functions

@onready var filter = $"."
signal drop_object ## Signal for removing the filter paper from the players hand

## 
func use(object_in_los: Node3D, _collision_point: Vector3) -> void:
	if object_in_los == null:
		return
	if object_in_los is not Funnel:
		return
	
	filter.reparent(object_in_los)
	#filter.set_physics_process(false)
	filter.collision_mask = 0
	filter.global_position = object_in_los.hold_point.global_position
	filter.global_rotation = object_in_los.global_rotation
	filter.freeze = true
	
	drop_object.emit()
