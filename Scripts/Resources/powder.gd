class_name Powder
extends Reagents

const TOP_SHADER: Shader = preload("res://Shaders/powder_top.gdshader")

var _mass_g: float = 0.0
var _max_fill_ml: float = 250.0
var _bulk_volume_ml: float = 0.0
var _net_h_moles: float = 0.0
var _color: Color = Color(0.85, 0.85, 0.85, 1.0)

# Grain visual parameters (editable at runtime)
var _grain_scale: float = 180.0
var _grain_strength: float = 0.3
var _grain_roughness_var: float = 0.3
var _subdivisions: int = 128

# Internal visual state (only allocated if a mesh is provided)
var _top_mesh: MeshInstance3D
var _top_material: ShaderMaterial
var _top_plane: PlaneMesh
var _opening_radius: float
var _previous_plane_size := Vector2.ZERO

var _dissolution_rate: float = 0.35

var _weak_species: Array[Dictionary] = []

func initialize(
	initial_mass_g: float,
	molar_mass: float,
	density_g_per_ml: float,
	is_base: bool,
	color: Color,
	max_fill_ml: float,
	mesh: MeshInstance3D = null,
	is_strong: bool = true,
	pka: float = 7.0
) -> void:
	_max_fill_ml = max_fill_ml
	_color = color
	_mesh = mesh
	

	if _mesh != null:
		_setup_powder_visual()

	if initial_mass_g > 0.0:
		add_powder_amount(
			initial_mass_g, 
			molar_mass, 
			density_g_per_ml, 
			is_base,
			color,
			is_strong, 
			pka
		)
	else:
		update_visual()


func initialize_from_contents(
	mass_g: float,
	net_h_moles: float,
	bulk_volume_ml: float,
	color: Color,
	capacity_ml: float
) -> void:
	_mass_g = mass_g
	_net_h_moles = net_h_moles
	_bulk_volume_ml = bulk_volume_ml
	_color = color
	_max_fill_ml = maxf(capacity_ml, bulk_volume_ml)
	update_visual()


func add_powder_amount(
	mass_g: float,
	molar_mass: float,
	density_g_per_ml: float,
	is_base: bool,
	added_color: Color = _color,
	is_strong: bool = true,
	pka: float = 7.0
) -> float:
	if mass_g <= 0.0:
		return 0.0

	var safe_density := maxf(density_g_per_ml, 0.001)
	var added_vol := mass_g / safe_density
	var available_vol := maxf(_max_fill_ml - _bulk_volume_ml, 0.0)
	var accepted_vol := minf(added_vol, available_vol)

	if accepted_vol <= 0.0:
		return 0.0

	var accepted_mass := accepted_vol * safe_density
	var moles := accepted_mass / maxf(molar_mass, 0.001)

	if _mass_g + accepted_mass > 0.0:
		_color = _color.lerp(added_color, accepted_mass / (_mass_g + accepted_mass))

	_mass_g += accepted_mass
	_bulk_volume_ml += accepted_vol
	
	if is_strong:
		_net_h_moles += -moles if is_base else moles
	else:
		_merge_weak_species(moles, pka, is_base)
		

	update_visual()
	return accepted_mass


func remove_powder(amount_g: float) -> Powder:
	var removed_mass := minf(amount_g, _mass_g)
	var removed_moles := 0.0
	var removed_vol := 0.0
	var removed_weak: Array[Dictionary] = []

	if _mass_g > 0.0:
		var fraction := removed_mass / _mass_g
		removed_moles = _net_h_moles * fraction
		removed_vol = _bulk_volume_ml * fraction
		
		for i in range(_weak_species.size() - 1, -1, -1):
			var sp := _weak_species[i]
			var take_moles: float = sp.moles * fraction
			sp.moles -= take_moles
			if take_moles > 0.0:
				removed_weak.append({
					"moles": take_moles,
					"pka": sp.pka,
					"is_base": sp.is_base
				})
			if sp.moles <= 1e-12:
				_weak_species.remove_at(i)

	_mass_g -= removed_mass
	_net_h_moles -= removed_moles
	_bulk_volume_ml -= removed_vol

	update_visual()

	var sample := Powder.new()
	sample.initialize_from_contents(
		removed_mass,
		removed_moles,
		removed_vol,
		_color,
		maxf(removed_vol, 1.0),
	)
	sample._weak_species = removed_weak
	return sample


func add_powder(other: Powder) -> float:
	if other == self or other == null or other._mass_g <= 0.0 or other._bulk_volume_ml <= 0.0:
		return 0.0

	var available_vol := maxf(_max_fill_ml - _bulk_volume_ml, 0.0)
	var accepted_vol := minf(other._bulk_volume_ml, available_vol)

	if accepted_vol <= 0.0:
		return 0.0

	var fraction := accepted_vol / other._bulk_volume_ml
	var transferred_mass := other._mass_g * fraction
	var transferred_moles := other._net_h_moles * fraction

	if _mass_g + transferred_mass > 0.0:
		_color = _color.lerp(other._color, transferred_mass / (_mass_g + transferred_mass))

	_mass_g += transferred_mass
	_bulk_volume_ml += accepted_vol
	_net_h_moles += transferred_moles

	other._mass_g -= transferred_mass
	other._bulk_volume_ml -= accepted_vol
	other._net_h_moles -= transferred_moles
	
	for i in range(other._weak_species.size() -1, -1, -1):
		var sp := other._weak_species[i]
		var moved: float = sp.moles * fraction
		sp.moles -= moved
		if moved > 0.0:
			_merge_weak_species(moved, sp.pka, sp.is_base)
		if sp.moles <= 1e-12:
			other._weak_species.remove_at(i)

	update_visual()
	other.update_visual()
	return transferred_mass


func set_color(new_color: Color) -> void:
	_color = new_color
	update_visual()


func set_grain_parameters(scale: float, strength: float, roughness_var: float) -> void:
	_grain_scale = scale
	_grain_strength = strength
	_grain_roughness_var = roughness_var
	_sync_shader_constants()


func get_mass_g() -> float:
	return _mass_g


func get_bulk_volume_ml() -> float:
	return _bulk_volume_ml


func get_net_h_moles() -> float:
	return _net_h_moles


func get_color() -> Color:
	return _color

func set_dissolution_rate(rate: float) -> void:
	_dissolution_rate = maxf(rate, 0.001)
	
func get_dissolution_rate() -> float:
	return _dissolution_rate
	
func get_weak_species() -> Array[Dictionary]:
	return _weak_species
	
func _merge_weak_species(moles: float, pka: float, is_base: bool) -> void:
	if moles <= 0.0:
		return
	for sp in _weak_species:
		if sp.is_base == is_base and is_equal_approx(sp.pka, pka):
			sp.moles += moles
			return
	_weak_species.append({ "moles": moles, "pka": pka, "is_base": is_base })

func update_visual() -> void:
	if _shader_mat == null or _top_material == null:
		return

	var fill_percent := clampf(_bulk_volume_ml / maxf(_max_fill_ml, 0.001), 0.0, 1.0)
	var is_visible := fill_percent > 0.0001

	if is_instance_valid(_mesh):
		_mesh.visible = is_visible
	if is_instance_valid(_top_mesh):
		_top_mesh.visible = is_visible

	for mat in [_shader_mat, _top_material]:
		mat.set_shader_parameter("fill_amount", fill_percent)
		mat.set_shader_parameter("powder_color", _color)


func sync_visual_transform() -> void:
	if not is_instance_valid(_mesh) or not is_instance_valid(_top_mesh) or _top_material == null:
		return
	if not _mesh.visible:
		return

	var body_transform: Transform3D = _mesh.global_transform
	var basis: Basis = body_transform.basis
	var radius := _opening_radius
	var half_height := _bounds_half_extent.y

	var radial_proj_x := Vector2(basis.x.x, basis.z.x).length()
	var radial_proj_z := Vector2(basis.x.z, basis.z.z).length()

	var extent_x := radius * radial_proj_x + half_height * absf(basis.y.x)
	var extent_z := radius * radial_proj_z + half_height * absf(basis.y.z)
	var desired_size := Vector2(extent_x * 2.0, extent_z * 2.0)

	if desired_size.distance_to(_previous_plane_size) > 0.001:
		_top_plane.size = desired_size
		_previous_plane_size = desired_size

	var world_center: Vector3 = body_transform * _bounds_center
	_top_mesh.global_transform = Transform3D(Basis.IDENTITY, world_center)

	var vertical_extent := (
		absf(basis.x.y) * _bounds_half_extent.x +
		absf(basis.y.y) * _bounds_half_extent.y +
		absf(basis.z.y) * _bounds_half_extent.z
	)

	_top_plane.custom_aabb = AABB(
		Vector3(-desired_size.x * 0.5, -vertical_extent, -desired_size.y * 0.5),
		Vector3(desired_size.x, vertical_extent * 2.0, desired_size.y)
	)

	_top_material.set_shader_parameter("body_model_matrix", body_transform)
	_top_material.set_shader_parameter("body_inverse_model_matrix", body_transform.affine_inverse())


func _setup_powder_visual() -> void:
	if _mesh.mesh == null:
		push_error("Powder: Assigned MeshInstance3D has no mesh.")
		return

	var source_mat := _mesh.get_active_material(0)
	if not source_mat is ShaderMaterial:
		push_error("Powder: Mesh surface 0 does not use a ShaderMaterial!")
		return

	if not setup_visual(_mesh):
		return

	if _bounds_half_extent == Vector3.ZERO:
		var aabb: AABB = _mesh.mesh.get_aabb()
		_bounds_center = aabb.position + aabb.size * 0.5
		_bounds_half_extent = aabb.size * 0.5

	_opening_radius = minf(_bounds_half_extent.x, _bounds_half_extent.z)

	_top_plane = PlaneMesh.new()
	_top_plane.subdivide_width = _subdivisions
	_top_plane.subdivide_depth = _subdivisions

	_top_material = ShaderMaterial.new()
	_top_material.shader = TOP_SHADER

	_top_mesh = MeshInstance3D.new()
	_top_mesh.name = "PowderTop"
	_top_mesh.mesh = _top_plane
	_top_mesh.material_override = _top_material
	_mesh.add_child(_top_mesh)
	_top_mesh.set_as_top_level(true)

	_sync_shader_constants()

	if not _mesh.tree_exiting.is_connected(_cleanup_visual):
		_mesh.tree_exiting.connect(_cleanup_visual)


func _sync_shader_constants() -> void:
	if _shader_mat == null or _top_material == null:
		return

	for mat in [_shader_mat, _top_material]:
		mat.set_shader_parameter("bounds_center", _bounds_center)
		mat.set_shader_parameter("bounds_half_extent", _bounds_half_extent)
		mat.set_shader_parameter("powder_color", _color)
		mat.set_shader_parameter("grain_scale", _grain_scale)
		mat.set_shader_parameter("grain_strength", _grain_strength)
		mat.set_shader_parameter("grain_roughness_var", _grain_roughness_var)

	_top_material.set_shader_parameter("opening_radius", _opening_radius)


func _cleanup_visual() -> void:
	if is_instance_valid(_top_mesh):
		_top_mesh.material_override = null
		_top_mesh.mesh = null
		_top_mesh.queue_free()
	if is_instance_valid(_mesh):
		_mesh.material_override = null

	_top_mesh = null
	_top_material = null
	_shader_mat = null
	
func is_liquid() -> bool:
	return true
