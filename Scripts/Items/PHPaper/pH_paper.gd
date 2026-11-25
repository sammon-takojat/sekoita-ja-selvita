extends RigidBody3D
class_name PH_Paper

@onready var mesh: MeshInstance3D = $MeshInstance3D3

var shader : ShaderMaterial

func _ready() -> void:
	shader = mesh.material_overlay as ShaderMaterial
	shader.set_shader_parameter("base_color", Color.DARK_ORANGE)
	shader.set_shader_parameter("hit_position", Vector3.INF)

func changeColor(pH : float, position: Vector3) -> void:
	if pH <= 4.0:
		var t := inverse_lerp(0.0, 4.0, pH)
		shader.set_shader_parameter("set_color", Color.RED.lerp(Color.YELLOW, t))
	elif pH <= 7.0:
		var t := inverse_lerp(4.0, 7.0, pH)
		shader.set_shader_parameter("set_color", Color.YELLOW.lerp(Color.GREEN, t))
	elif pH <= 10.0:
		var t := inverse_lerp(7.0, 10.0, pH)
		shader.set_shader_parameter("set_color", Color.GREEN.lerp(Color.BLUE, t))
	else:
		var t := inverse_lerp(10.0, 14.0, pH)
		shader.set_shader_parameter("set_color", Color.BLUE.lerp(Color.PURPLE, t))
	shader.set_shader_parameter("hit_position", mesh.to_local(position))
	shader.set_shader_parameter("start_time", Time.get_ticks_msec() / 1000)
	
