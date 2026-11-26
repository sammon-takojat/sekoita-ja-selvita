extends RigidBody3D
class_name PowderSpoon

@export var capacity_ml: float = 10.0
@export var dispense_amount_ml: float = 10.0
@export var mesh: MeshInstance3D
var powder: Powder

func use(object_in_los, collision_point: Vector3) -> void:
	var inLOS: bool = (object_in_los and "reagent" in object_in_los)
	if  inLOS and !powder and !object_in_los.is_liquid():
		powder = object_in_los.reagent.remove_powder(capacity_ml)
		powder._mesh = mesh
		
	elif inLOS and powder and !object_in_los.is_liquid():
		var sample = powder.remove_powder(dispense_amount_ml)
		object_in_los.add_powder(sample)
		
		powder = null
	elif inLOS and powder and object_in_los.is_liquid():
		if powder == null:
			return
		
		var sample = powder.remove_powder(dispense_amount_ml)

		object_in_los.add_powder(sample)
		if powder._mass_g <= 0.0001:
			powder = null
