shader_type spatial;

uniform vec3 hit_position;
uniform float start_time;
uniform vec4 set_color;
uniform vec4 base_color;

uniform float radius = 0.01;
uniform float fade = 0.005;


varying vec3 local_position;

void vertex() {
    local_position = VERTEX;
}

void fragment() {
	float dist = distance(local_position, hit_position);
	
	float radius_mult = smoothstep(0.0, 3.0, TIME - start_time);
	float curr_radius = radius + radius * radius_mult;
	
	float strength = 1.0 - smoothstep(curr_radius - fade, curr_radius, dist);

	ALBEDO = mix(base_color.rgb, set_color.rgb, strength);
}
