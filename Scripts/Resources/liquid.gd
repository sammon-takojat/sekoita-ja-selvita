class_name Liquid extends Reagents

var _fill_amount_ml := 0.0
var _max_fill_ml := 0.0

var _pH := 0.0
var _net_h_moles: float
var max_solubility_g_per_ml: float = 0.5
var _dissolved_solute_g: float = 0.0
var _undissolved_powder: Powder = null

func initialize(initial_ml: float, initial_ph: float, max_fill_ml: float, mesh: MeshInstance3D) -> void:
	_pH = initial_ph
	_max_fill_ml = max_fill_ml
	_mesh = mesh
	
	var source_mat = _mesh.get_active_material(0)
	if not source_mat is ShaderMaterial:
		push_error("Mesh surface 0 does not use a ShaderMaterial!")
		return
		
	_fill_amount_ml = clampf(initial_ml, 0.0, _max_fill_ml)
	
	if not setup_visual(mesh):
		return
	
	var h_concentration = pow(10.0, -_pH)
	var oh_concentration = pow(10.0, _pH - 14.0)
	
	var net_concentration = h_concentration - oh_concentration
	_net_h_moles = net_concentration * (_fill_amount_ml / 1000.0)
	
	update_visual()
	
func initialize_from_contents(amount_ml: float, net_h_moles: float, capacity_ml: float) -> void:
	_fill_amount_ml = amount_ml
	_net_h_moles = net_h_moles
	_max_fill_ml = maxf(capacity_ml, amount_ml)
	
	update_pH()
	update_visual()
	
func update_visual() -> void:
	if _shader_mat == null:
		return

	var fill_percent = _fill_amount_ml / _max_fill_ml
	_shader_mat.set_shader_parameter("fill_amount", fill_percent)
	

func change_fill_amount(amount_ml: float) -> void:
	_fill_amount_ml = clamp(
		_fill_amount_ml + amount_ml,
		0.0,
		_max_fill_ml
	)
	
	update_visual()
	
	
func add_reagent(amount_ml: float, molarity: float, is_base: bool):
	var added_moles = (amount_ml / 1000.0) * molarity
	
	if is_base:
		_net_h_moles -= added_moles
	else:
		_net_h_moles += added_moles
	
	change_fill_amount(amount_ml)
	
	update_pH()
	
func remove_liquid(amount_ml: float) -> Liquid:
	var removed_amount = min(amount_ml, _fill_amount_ml)
	
	var removed_moles := 0.0
	
	if _fill_amount_ml > 0.0:
		var fraction = removed_amount / _fill_amount_ml
		removed_moles = _net_h_moles * fraction
	
	_fill_amount_ml -= removed_amount
	_net_h_moles -= removed_moles
	
	update_pH()
	update_visual()
	
	var sample := Liquid.new()
	sample.initialize_from_contents(removed_amount, removed_moles, amount_ml)
	
	return sample

func add_liquid(other: Liquid) -> float:
	if other == self or other._fill_amount_ml <= 0.0:
		return 0.0
	
	var available_capacity = _max_fill_ml - _fill_amount_ml
	
	var accepted_amount = minf(other._fill_amount_ml, maxf(available_capacity, 0.0))
	
	if accepted_amount <= 0.0:
		return 0.0
		
	var fraction = accepted_amount / other._fill_amount_ml
	var transferred_moles = other._net_h_moles * fraction
	
	_fill_amount_ml += accepted_amount
	_net_h_moles += transferred_moles
	
	other._fill_amount_ml -= accepted_amount
	other._net_h_moles -= transferred_moles

	update_pH()
	other.update_pH()
	
	update_visual()
	other.update_visual()
	
	return accepted_amount

func update_pH():
	if _fill_amount_ml <= 0.0:
		_pH = 7.0
		return
	
	var volume_l = _fill_amount_ml / 1000.0
	var net_concentration = _net_h_moles / volume_l
	
	var kw = 1.0e-14
	var h_concentration = (
		net_concentration + sqrt(net_concentration * net_concentration + 4.0 * kw)
	) / 2.0
	
	_pH = -log(h_concentration) / log(10.0)
	
func dissolve_powder(incoming_powder: Powder) -> float:
	if incoming_powder == null or incoming_powder.get_mass_g() <= 0.0:
		return 0.0
		
	var total_incoming_g = incoming_powder.get_mass_g()
	var total_incoming_moles = incoming_powder.get_net_h_moles()
	
	var max_dissolvable_g = _fill_amount_ml * max_solubility_g_per_ml
	var remaining_capacity_g = maxf(max_dissolvable_g - _dissolved_solute_g, 0.0)
	
	var mass_to_dissolve = minf(total_incoming_g, remaining_capacity_g)
	
	if mass_to_dissolve > 0.0:
		var fraction = mass_to_dissolve / total_incoming_g
		var moles_to_dissolve = total_incoming_moles * fraction
		
		incoming_powder.remove_powder(mass_to_dissolve)
		
		_dissolved_solute_g += mass_to_dissolve
		_net_h_moles += moles_to_dissolve
		update_pH()
		
	if incoming_powder.get_mass_g() > 0.0:
		if _undissolved_powder == null:
			_undissolved_powder = Powder.new()
			_undissolved_powder.initialize(0.0, 1.0, 1.0, false, incoming_powder.get_color(), _max_fill_ml)
		_undissolved_powder.add_powder(incoming_powder)
		
	update_visual()
	return mass_to_dissolve
	
func get_total_contents_mass_g() -> float:
	var liquid_mass_g = _fill_amount_ml
	var precipitate_g = _undissolved_powder.get_mass_g() if _undissolved_powder != null else 0.0
	return liquid_mass_g + _dissolved_solute_g + precipitate_g
