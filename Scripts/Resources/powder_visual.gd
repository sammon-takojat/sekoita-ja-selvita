
extends Node3D
class_name PowderSurfaceController


const TOP_SHADER: Shader = preload("res://Shaders/powder_pile.gdshader")


const BODY_PARAMETERS = [
	&"coeff",
	&"fill_amount",
	&"scale",
	&"wave_intensity",
	&"waves_noise",
	&"powder_color"
]


@export_group("Mesh references")

@export var liquid_body: MeshInstance3D
var powder_top: MeshInstance3D


@export_group("Powder")

@export_range(0.0, 1.0, 0.001)
var powder_amount: float = 0.0

@export_range(0.001, 0.5, 0.001)
var max_height: float = 0.04

@export_range(0.001, 0.02, 0.001)
var surface_offset: float = 0.001

@export_range(0.1, 2.0, 0.01)
var top_radius: float = 1.0


@export_group("Grain")

@export_range(1.0, 500.0, 1.0)
var grain_scale: float = 180.0

@export_range(0.0, 1.0, 0.01)
var grain_strength: float = 0.3


@export_group("Geometry")

@export_range(8, 256, 1)
var subdivisions: int = 96


var _bounds_center: Vector3
var _bounds_half_extent: Vector3

var _liquid_material: ShaderMaterial
var _top_material: ShaderMaterial



func _ready() -> void:
	if not _initialize():
		set_process(false)
		return

	_update_top_material()



func _initialize() -> bool:
	# Validate references.
	if liquid_body == null:
		push_error("PowderSurfaceController: LiquidBody is not assigned.")
		return false

	powder_top = MeshInstance3D.new()
	powder_top.name = "PowderTop"
	add_child(powder_top)

	if liquid_body.mesh == null:
		push_error("PowderSurfaceController: LiquidBody has no mesh.")
		return false


	# Get the existing body material.
	var active_material = liquid_body.get_active_material(0)

	if not (active_material is ShaderMaterial):
		push_error("PowderSurfaceController: LiquidBody needs a ShaderMaterial.")
		return false

	_liquid_material = active_material as ShaderMaterial


	# -------------------------------------------------
	# Calculate mesh bounds.
	# -------------------------------------------------

	var aabb: AABB = liquid_body.mesh.get_aabb()

	_bounds_center = aabb.position + aabb.size * 0.5
	_bounds_half_extent = aabb.size * 0.5


	# -------------------------------------------------
	# Create the top mesh.
	# -------------------------------------------------

	var plane := PlaneMesh.new()

	plane.size = Vector2(
		_bounds_half_extent.x * 2.0,
		_bounds_half_extent.z * 2.0
	)

	# More vertices are needed for the dome geometry.
	plane.subdivide_width = subdivisions
	plane.subdivide_depth = subdivisions

	# Center the plane on the original mesh bounds.
	plane.center_offset = _bounds_center

	# The shader moves vertices outside the original flat
	# plane bounds, so expand its culling bounds.
	var margin = max_height + 0.1

	plane.custom_aabb = AABB(
		_bounds_center - _bounds_half_extent - Vector3.ONE * margin,
		_bounds_half_extent * 2.0 + Vector3.ONE * margin * 2.0
	)

	powder_top.mesh = plane


	# The body and top must have identical transforms.
	powder_top.global_transform = liquid_body.global_transform


	# -------------------------------------------------
	# Create and assign the top material.
	# -------------------------------------------------

	_top_material = ShaderMaterial.new()
	_top_material.shader = TOP_SHADER

	powder_top.material_override = _top_material


	# Set bounds on both materials.
	_liquid_material.set_shader_parameter(
		"bounds_center",
		_bounds_center
	)

	_liquid_material.set_shader_parameter(
		"bounds_half_extent",
		_bounds_half_extent
	)

	_top_material.set_shader_parameter(
		"bounds_center",
		_bounds_center
	)

	_top_material.set_shader_parameter(
		"bounds_half_extent",
		_bounds_half_extent
	)

	return true



func _process(_delta: float) -> void:
	if _top_material == null or _liquid_material == null:
		return

	# Keep the transforms synchronized.
	powder_top.global_transform = liquid_body.global_transform

	_update_top_material()



func _update_top_material() -> void:
	# Copy the important uniforms from the body shader.
	for parameter in BODY_PARAMETERS:
		var value: Variant = _liquid_material.get_shader_parameter(parameter)

		if value != null:
			_top_material.set_shader_parameter(parameter, value)


	# Top-specific parameters.
	_top_material.set_shader_parameter(
		"powder_amount",
		clampf(powder_amount, 0.0, 1.0)
	)

	_top_material.set_shader_parameter(
		"max_height",
		max_height
	)

	_top_material.set_shader_parameter(
		"surface_offset",
		surface_offset
	)

	_top_material.set_shader_parameter(
		"top_radius",
		top_radius
	)

	_top_material.set_shader_parameter(
		"grain_scale",
		grain_scale
	)

	_top_material.set_shader_parameter(
		"grain_strength",
		grain_strength
	)



func set_powder_amount(amount: float) -> void:
	powder_amount = clampf(amount, 0.0, 1.0)
