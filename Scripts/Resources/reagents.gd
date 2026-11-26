@abstract
class_name Reagents
extends Resource

var _mesh: MeshInstance3D
var _shader_mat: ShaderMaterial

var _bounds_center: Vector3
var _bounds_half_extent: Vector3

func setup_visual(mesh: MeshInstance3D) -> bool:
	_mesh = mesh

	var source_mat = _mesh.get_active_material(0)

	if not source_mat is ShaderMaterial:
		push_error("Mesh surface 0 does not use a ShaderMaterial!")
		return false

	_shader_mat = source_mat.duplicate() as ShaderMaterial
	_mesh.set_surface_override_material(0, _shader_mat)

	var aabb = _mesh.get_aabb()

	_bounds_center = aabb.position + aabb.size * 0.5
	_bounds_half_extent = aabb.size * 0.5

	_shader_mat.set_shader_parameter("bounds_center", _bounds_center)
	_shader_mat.set_shader_parameter("bounds_half_extent", _bounds_half_extent)

	return true
	
@abstract
func update_visual() -> void
