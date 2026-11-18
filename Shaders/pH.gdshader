shader_type spatial;

uniform vec3 hit_position;
uniform vec4 set_color;
uniform vec4 base_color;
uniform float radius = 0.02;
uniform float fade = 0.01;


varying vec3 local_position;

void vertex() {
    local_position = VERTEX;
}

void fragment() {
	float dist = distance(local_position, hit_position);

	float strength = 1.0 - smoothstep(radius - fade, radius, dist);

	ALBEDO = mix(base_color.rgb, set_color.rgb, strength);
}
