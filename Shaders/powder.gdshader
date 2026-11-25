shader_type spatial;
render_mode cull_disabled;

#include "res://Shaders/powder_grain.gdshaderinc"

uniform vec3 bounds_center;
uniform vec3 bounds_half_extent;

group_uniforms Visuals;
uniform float fill_amount     : hint_range(0.0, 1.0, 0.001) = 0.5;

varying lowp vec3 pos;
varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
	pos = mat3(MODEL_MATRIX)*VERTEX;
}

void fragment() {	
	mat3 model = mat3(MODEL_MATRIX);
	
	float center_y = (model * bounds_center).y;
	
	float vertical_half_extent =
		abs(model[0].y) * bounds_half_extent.x +
		abs(model[1].y) * bounds_half_extent.y +
		abs(model[2].y) * bounds_half_extent.z;
	
	lowp float powder_line = center_y + (fill_amount * 2.0 - 1.0) * vertical_half_extent;
	if (pos.y > powder_line) discard;

	vec2 radial_pos = (local_pos.xz - bounds_center.xz) / max(bounds_half_extent.xz, vec2(0.001));

	float radius = length(radial_pos);
	float edge = smoothstep(0.65, 1.0, radius);

	float edge_shading = mix(1.0, 0.7, edge);
	vec3 final_albedo;
	float final_roughness;
	apply_powder_grain(local_pos, edge_shading, final_albedo, final_roughness);
	
	ALBEDO =  final_albedo;
	ROUGHNESS = final_roughness;
}