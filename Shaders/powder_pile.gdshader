
shader_type spatial;
render_mode cull_disabled;

group_uniforms PhysicsSetByScript;

uniform vec2 coeff = vec2(0.0);
uniform vec3 bounds_center;
uniform vec3 bounds_half_extent;

uniform float fill_amount : hint_range(0.0, 1.0) = 0.5;
uniform float scale = 1.0;
uniform float wave_intensity = 0.05;
uniform sampler2D waves_noise;

group_uniforms Visuals;

uniform vec4 powder_color : source_color =
    vec4(0.4, 0.4, 0.4, 1.0);

uniform float grain_scale = 180.0;
uniform float grain_strength = 0.3;

varying vec3 local_pos;


float hash31(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}


void vertex() {
    local_pos = VERTEX;

    mat3 model = mat3(MODEL_MATRIX);

    // Position in world space.
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Same wave calculation as the body.
    float wave_noise_1 = textureLod(
        waves_noise,
        (2.0 * world_pos.xz +
        0.5 * TIME * vec2(1.0)) * scale,
        0.0
    ).r;

    float wave_noise_2 = textureLod(
        waves_noise,
        (2.0 * world_pos.xz -
        0.5 * TIME * vec2(1.0)) * scale,
        0.0
    ).g;

    float wave = wave_intensity * length(coeff) *
        (wave_noise_1 - 0.5 + wave_noise_2 - 0.5)
        + dot(world_pos.xz, coeff);

    wave *= smoothstep(0.05, 0.25, fill_amount);

    float center_y = (model * bounds_center).y;

    float vertical_half_extent =
        abs(model[0].y) * bounds_half_extent.x +
        abs(model[1].y) * bounds_half_extent.y +
        abs(model[2].y) * bounds_half_extent.z;

    float liquid_line = center_y +
        (fill_amount * 2.0 - 1.0 + wave) *
        vertical_half_extent;

    // Move every vertex onto the same world-space
    // surface used by the body shader.
    world_pos.y = liquid_line + 0.001;

    // Convert back to local coordinates.
    VERTEX = (inverse(MODEL_MATRIX) *
        vec4(world_pos, 1.0)).xyz;

    // Flat world-up normal.
    NORMAL = normalize(
        transpose(inverse(model)) * vec3(0.0, 1.0, 0.0)
    );
}


void fragment() {
    // Only render inside the original mesh bounds.
    if (
        abs(local_pos.x - bounds_center.x) >
            bounds_half_extent.x ||
        abs(local_pos.z - bounds_center.z) >
            bounds_half_extent.z
    ) {
        discard;
    }

    float grain = hash31(floor(local_pos * grain_scale));

    float grain_shading =
        1.0 + (grain - 0.5) * grain_strength;

    ALBEDO = powder_color.rgb * grain_shading;
    ROUGHNESS = 1.0;
}
