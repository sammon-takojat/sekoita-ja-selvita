class_name PowderContainer
extends RigidBody3D

@export var initial_mass_g: float = 100.0
@export var molar_mass: float = 40.0
@export var density_g_per_ml: float = 1.0
@export var is_base: bool = false
@export var powder_color: Color = Color(0.85, 0.85, 0.85, 1.0)

@export var MAX_FILL_ML: float = 250.0
@export var EMPTY_MASS: float = 0.100

@export var mesh: MeshInstance3D

var reagent: Reagents

signal mass_changed


func _ready() -> void:
	var powder := Powder.new()
	powder.initialize(
		initial_mass_g,
		molar_mass,
		density_g_per_ml,
		is_base,
		powder_color,
		MAX_FILL_ML,
		mesh
	)
	reagent = powder
	update_mass()

func _process(_delta: float) -> void:
	var powder := reagent as Powder
	if powder != null:
		powder.sync_visual_transform()

func update_mass() -> void:
	var powder := reagent as Powder
	var powder_kg := (powder.get_mass_g() / 1000.0) if powder != null else 0.0
	mass = EMPTY_MASS + powder_kg
	emit_signal("mass_changed")


func add_reagent(
	amount_g: float,
	added_molar_mass: float,
	added_density: float,
	added_is_base: bool,
	added_color: Color = powder_color
) -> float:
	var powder := reagent as Powder
	if powder == null:
		return 0.0
	var accepted := powder.add_powder_amount(
		amount_g,
		added_molar_mass,
		added_density,
		added_is_base,
		added_color
	)
	update_mass()
	return accepted


func add_powder(other: Powder) -> float:
	var powder := reagent as Powder
	if powder == null:
		return 0.0
	var accepted := powder.add_powder(other)
	update_mass()
	return accepted


func remove_powder(amount_g: float) -> Powder:
	var powder := reagent as Powder
	if powder == null:
		return null
	var sample := powder.remove_powder(amount_g)
	update_mass()
	return sample
