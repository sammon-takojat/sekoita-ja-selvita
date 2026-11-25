shader_type spatial;
render_mode cull_disabled;

#include "res://Shaders/powder_grain.gdshaderinc"

group_uniforms PhysicsSetByScript;

uniform vec3 bounds_center;
uniform vec3 bounds_half_extent;

uniform float fill_amount : hint_range(0.0, 1.0) = 0.5;

// These matrices are provided by GDScript.
uniform mat4 body_model_matrix;
uniform mat4 body_inverse_model_matrix;

// Radius of the cylindrical powder volume in body-local coordinates.
uniform float opening_radius = 0.5;

// Small offset to prevent z-fighting.
uniform float surface_offset = 0.001;

varying vec3 body_local_pos;


float hash31(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 33.33);

    return fract((p.x + p.y) * p.z);
}


void vertex() {
    // The top mesh is world-horizontal.
    // Its MODEL_MATRIX contains only its world translation.
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Get the body origin.
    vec3 body_origin = body_model_matrix[3].xyz;

    // This is equivalent to:
    // mat3(BODY_MODEL_MATRIX) * BODY_LOCAL_VERTEX
    // in the original body shader.
    vec3 pos = world_pos - body_origin;

    mat3 body_model = mat3(body_model_matrix);

    float center_y = (body_model * bounds_center).y;

    float vertical_half_extent =
        abs(body_model[0].y) * bounds_half_extent.x +
        abs(body_model[1].y) * bounds_half_extent.y +
        abs(body_model[2].y) * bounds_half_extent.z;

    float liquid_line = center_y +
        (fill_amount * 2.0 - 1.0) *
        vertical_half_extent;

    world_pos.y = body_origin.y + liquid_line + surface_offset;

    body_local_pos = (
        body_inverse_model_matrix * vec4(world_pos, 1.0)
    ).xyz;

    VERTEX = (
        inverse(MODEL_MATRIX) * vec4(world_pos, 1.0)
    ).xyz;

    NORMAL = vec3(0.0, 1.0, 0.0);
}


void fragment() {
    vec2 radial_pos = body_local_pos.xz - bounds_center.xz;

    if (length(radial_pos) > opening_radius) {
        discard;
    }

    // Don't render outside the cylinder's height.
    if (
        body_local_pos.y < bounds_center.y - bounds_half_extent.y ||
        body_local_pos.y > bounds_center.y + bounds_half_extent.y
    ) {
        discard;
    }

	vec3 final_albedo;
	float final_roughness;
	apply_powder_grain(body_local_pos, 1.0, final_albedo, final_roughness);
	
	ALBEDO = final_albedo;
	ROUGHNESS = final_roughness;
}
