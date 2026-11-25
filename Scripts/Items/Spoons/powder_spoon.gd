extends RigidBody3D
class_name PowderSpoon

@export var capacity_ml: float = 10.0
@export var dispense_amount_ml: float = 10.0
@export var mesh: MeshInstance3D
var powder: Powder

func use(object_in_los) -> void:
	if object_in_los and "reagent" in object_in_los and !powder:
		powder = object_in_los.reagent.remove_powder(capacity_ml)
		powder._mesh = mesh
	elif object_in_los and "reagent" in object_in_los:
		if powder == null:
			return
		
		var sample = powder.remove_powder(dispense_amount_ml)

		object_in_los.reagent.dissolve_powder(sample)
		if powder._mass_g <= 0.0001:
			powder = null
