group_uniforms PowderGrain;
uniform vec4 powder_color : source_color = vec4(0.4, 0.4, 0.4, 1.0);
uniform float grain_scale = 5000.0;
uniform float grain_strength : hint_range(0.0, 1.0) = 0.3;
uniform float grain_roughness_var : hint_range(0.0, 0.5) = 0.15;

float powder_hash31(vec3 p) {
	p = fract(p * vec3(443.8975, 397.2973, 491.1871));
	p += dot(p, p.yxz + 19.19);
	return fract((p.x + p.y) * p.z);
}

void apply_powder_grain(
    vec3 sample_pos,
    float shading_multiplier,
    out vec3 out_albedo,
    out float out_roughness
) {
    vec3 cell = floor(sample_pos * grain_scale);
    float grain = powder_hash31(cell);

    // Optional second micro-layer to break up any grid alignment
    float fine_grain = powder_hash31(floor(sample_pos * grain_scale * 2.13) + 17.0);
    grain = mix(grain, fine_grain, 0.35);

    float grain_shading = 1.0 + (grain - 0.5) * grain_strength;
    out_albedo = powder_color.rgb * shading_multiplier * grain_shading;
    out_roughness = clamp(1.0 - grain * grain_roughness_var, 0.0, 1.0);
}