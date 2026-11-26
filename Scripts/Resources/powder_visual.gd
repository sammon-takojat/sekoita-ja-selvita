extends Node3D
class_name PowderSurfaceController


const TOP_SHADER: Shader = preload(
    "res://Shaders/powder_top.gdshader"
)

@export_group("Mesh references")
@export var powder_body: MeshInstance3D

var powder_top: MeshInstance3D

@export_group("Grain")

@export_range(1.0, 5000.0, 1.0)
var grain_scale: float = 180.0

@export_range(0.0, 1.0, 0.01)
var grain_strength: float = 0.3

@export var powder_color: Color = Color(0.7, 0.7, 0.7, 1.0);

@export_range(0.0, 0.5) 
var grain_roughness_var: float = 0.3

@export_range(0.0, 1.0)
var fill_amount: float = 0.5

@export_group("Geometry")

@export_range(16, 256, 1)
var subdivisions: int = 128

var _bounds_center: Vector3
var _bounds_half_extent: Vector3

var _opening_radius: float

var _body_material: ShaderMaterial
var _top_material: ShaderMaterial

var _top_plane: PlaneMesh

var _previous_plane_size := Vector2.ZERO



func _ready() -> void:

	if not _initialize():
		set_process(false)
		return

	_update_top_geometry()
	_update_top_material()



func _initialize() -> bool:
	if powder_body == null:
		push_error("PowderSurfaceController: Body mesh is not assigned.")
		return false

	if powder_body.mesh == null:
		push_error("PowderSurfaceController: Body has no mesh.")
		return false

	var active_material = powder_body.get_active_material(0)

	if not active_material is ShaderMaterial:
		push_error("PowderSurfaceController: Body requires a ShaderMaterial.")
		return false

	_body_material = active_material as ShaderMaterial
	
	var aabb: AABB = powder_body.mesh.get_aabb()

	_bounds_center = aabb.position + aabb.size * 0.5
	_bounds_half_extent = aabb.size * 0.5

	_body_material.set_shader_parameter(
		"bounds_center",
		_bounds_center
	)

	_body_material.set_shader_parameter(
		"bounds_half_extent",
		_bounds_half_extent
	)

	_opening_radius = minf(
		_bounds_half_extent.x,
		_bounds_half_extent.z
	)

	powder_top = MeshInstance3D.new()
	powder_top.name = "PowderTop"

	add_child(powder_top)

	# The top must NOT inherit the bottle's rotation or scale.
	powder_top.set_as_top_level(true)

	_top_plane = PlaneMesh.new()

	_top_plane.subdivide_width = subdivisions
	_top_plane.subdivide_depth = subdivisions

	powder_top.mesh = _top_plane

	_top_material = ShaderMaterial.new()
	_top_material.shader = TOP_SHADER

	powder_top.material_override = _top_material
	
	for mesh in [powder_body, powder_top]:
		var mat := mesh.get_active_material(0) as ShaderMaterial
		mat.set_shader_parameter("powder_color", powder_color)
		mat.set_shader_parameter("grain_scale", grain_scale)
		mat.set_shader_parameter("grain_strength", grain_strength)
		mat.set_shader_parameter("grain_roughness_var", grain_roughness_var)
		mat.set_shader_parameter("fill_amount", fill_amount)
		
	return true

func _update_top_geometry() -> void:

	var body_transform: Transform3D = powder_body.global_transform
	var basis: Basis = body_transform.basis

	var radius := _opening_radius
	var half_height := _bounds_half_extent.y

	var radial_projection_x = Vector2(
		basis.x.x,
		basis.z.x
	).length()

	var radial_projection_z = Vector2(
		basis.x.z,
		basis.z.z
	).length()
	
	var extent_x = (
		radius * radial_projection_x +
		half_height * absf(basis.y.x)
	)

	var extent_z = (
		radius * radial_projection_z +
		half_height * absf(basis.y.z)
	)

	var desired_size := Vector2(
		extent_x * 2,
		extent_z * 2
	)

	if desired_size.distance_to(_previous_plane_size) > 0.001:
		_top_plane.size = desired_size
		_previous_plane_size = desired_size

	var world_center: Vector3 = body_transform * _bounds_center

	powder_top.global_transform = Transform3D(
		Basis.IDENTITY,
		world_center
	)

	var vertical_extent = (
		absf(basis.x.y) * _bounds_half_extent.x +
		absf(basis.y.y) * _bounds_half_extent.y +
		absf(basis.z.y) * _bounds_half_extent.z
	)

	var culling_y = vertical_extent

	_top_plane.custom_aabb = AABB(
		Vector3(
			-desired_size.x * 0.5,
			-culling_y,
			-desired_size.y * 0.5
		),
		Vector3(
			desired_size.x,
			culling_y * 2.0,
			desired_size.y
		)
	)

func _update_top_material() -> void:
	var body_transform: Transform3D = powder_body.global_transform

	_top_material.set_shader_parameter(
		"body_model_matrix",
		body_transform
	)

	_top_material.set_shader_parameter(
		"body_inverse_model_matrix",
		body_transform.affine_inverse()
	)

	_top_material.set_shader_parameter(
		"bounds_center",
		_bounds_center
	)

	_top_material.set_shader_parameter(
		"bounds_half_extent",
		_bounds_half_extent
	)

	_top_material.set_shader_parameter(
		"opening_radius",
		_opening_radius
	)

func set_powder_state(new_fill: float, new_color: Color):
	fill_amount = new_fill
	powder_color = new_color
	for mesh in [powder_body, powder_top]:
		if mesh != null:
			var mat := mesh.get_active_material(0) as ShaderMaterial
			if mat != null:
				mat.set_shader_parameter("fill_amount", fill_amount)
				mat.set_shader_parameter("powder_color", powder_color)

func _process(_delta: float) -> void:

	if _top_material == null or _body_material == null:
		return

	_update_top_geometry()
	_update_top_material()
