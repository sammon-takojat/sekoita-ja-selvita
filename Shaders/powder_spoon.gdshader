shader_type spatial;

#include "res://Shaders/powder_grain.gdshaderinc"

uniform vec2 radius;
varying vec3 pos;

void vertex() {
	pos = VERTEX;
}

void fragment() {
	vec2 centered_uv = UV * 2.0 - 1.0;
	float d = length(centered_uv / radius);
	float mask = 1.0 - step(1.0, d);
	if (mask < 1.0) {
		discard;
	}
	
	vec3 final_albedo;
	float final_roughness;
	apply_powder_grain(pos, 1.0, final_albedo, final_roughness);
	
	ALBEDO = final_albedo;
	ROUGHNESS = final_roughness;
}
