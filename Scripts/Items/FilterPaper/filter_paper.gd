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
	
	object_in_los.add_child(self)
	drop_object.emit()
