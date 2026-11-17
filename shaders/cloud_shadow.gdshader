shader_type canvas_item;

uniform float day_phase = 0.0;
uniform float night_mix : hint_range(0.0, 1.0) = 0.0;
uniform vec2 quad_size = vec2(96.0, 48.0);

varying vec4 v_custom;
varying vec2 v_world_pos;
varying vec2 v_world_center;
varying vec2 v_half_world;

float bayer4(vec2 p) {
	int x = int(mod(floor(p.x), 4.0));
	int y = int(mod(floor(p.y), 4.0));
	int x0 = x & 1;
	int y0 = y & 1;
	int x1 = (x >> 1) & 1;
	int y1 = (y >> 1) & 1;
	int m = (((x0 ^ y0) << 3) | (y0 << 2) | ((x1 ^ y1) << 1) | y1);
	return (float(m) + 0.5) / 16.0;
}

float cloud_lobe(vec2 q, vec2 center, vec2 radii) {
	vec2 d = (q - center) / radii;
	return 1.0 - dot(d, d);
}

float cloud_shape(vec2 q, float t) {
	float l0 = cloud_lobe(q, vec2(-0.28 + 0.03 * sin(t), 0.04 * cos(t * 0.8)), vec2(0.42, 0.46));
	float l1 = cloud_lobe(q, vec2(0.04, -0.06 + 0.04 * sin(t * 1.1)), vec2(0.50, 0.52));
	float l2 = cloud_lobe(q, vec2(0.34 + 0.03 * cos(t * 0.9), 0.06), vec2(0.38, 0.42));
	float l3 = cloud_lobe(q, vec2(-0.06, 0.18), vec2(0.44, 0.34));
	return max(max(l0, l1), max(l2, l3));
}

void vertex() {
	v_custom = INSTANCE_CUSTOM;
	vec4 wp = MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0);
	vec4 wc = MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	v_world_pos = wp.xy;
	v_world_center = wc.xy;
	float ref_x = (abs(VERTEX.x) > 0.001) ? abs(VERTEX.x) : quad_size.x * 0.5;
	float ref_y = (abs(VERTEX.y) > 0.001) ? abs(VERTEX.y) : quad_size.y * 0.5;
	v_half_world = vec2(
		max(length(MODEL_MATRIX[0].xy) * ref_x, 1.0),
		max(length(MODEL_MATRIX[1].xy) * ref_y, 1.0)
	);
}

void fragment() {
	// Snap strictly to 1:1 world pixel grid (640x360) regardless of instance scale
	vec2 world_px = floor(v_world_pos);
	vec2 snapped_world = world_px + 0.5;
	vec2 rel_world = snapped_world - v_world_center;
	float dither = bayer4(world_px);

	float phase = v_custom.r * 6.2831853;
	float is_haze = step(0.5, v_custom.g);
	float density_scale = v_custom.b > 0.05 ? v_custom.b : 1.0;
	float opacity_mul = v_custom.a > 0.05 ? v_custom.a : 1.0;
	float t = TIME * 0.35 + phase;
	float nm = clamp(night_mix, 0.0, 1.0);
	float dusk = sin(nm * 3.14159265);

	if (is_haze >= 0.5) {
		// Subtle 1:1 world-pixel atmospheric exoplanet haze wisp
		vec2 p_haze = rel_world / (v_half_world * 0.90);
		float field = cloud_shape(p_haze, t) * density_scale;
		float soft_edge = smoothstep(0.14, 0.78, field);
		if (soft_edge <= dither * 0.84 + 0.08) {
			discard;
		}
		vec3 haze_col = mix(vec3(0.48, 0.38, 0.30), vec3(0.38, 0.56, 0.70), fract(v_custom.r * 3.7));
		haze_col = mix(haze_col, haze_col * vec3(0.50, 0.56, 0.78), nm);
		float alpha = 0.08 * smoothstep(0.10, 0.90, soft_edge) * opacity_mul;
		COLOR = vec4(haze_col, alpha);
	} else {
		// 1) Volumetric NW bright cream-lit cloud canopy (offset NW by -3, -4 world px)
		vec2 body_half = v_half_world * 0.80;
		vec2 p_canopy = (rel_world - vec2(-3.0, -4.0)) / body_half;
		float f_canopy = cloud_shape(p_canopy, t) * density_scale;
		float canopy_edge = smoothstep(0.24, 0.64, f_canopy);

		if (canopy_edge > dither * 0.42 + 0.26) {
			// Volumetric NW-to-SE 3-tone pixel shading (strictly <= 0.95 non-HDR!)
			float nw_lit = clamp(0.54 - p_canopy.x * 0.34 - p_canopy.y * 0.52 + f_canopy * 0.44, 0.0, 1.0);
			vec3 hi_col = vec3(0.94, 0.92, 0.87); // warm sunlit cream
			vec3 mid_col = vec3(0.80, 0.84, 0.90); // cloud body
			vec3 under_col = vec3(0.52, 0.59, 0.70); // SE underbelly shadow

			vec3 cloud_rgb = mid_col;
			if (nw_lit > 0.62 + (dither - 0.5) * 0.14) {
				cloud_rgb = hi_col;
			} else if (nw_lit < 0.36 + (dither - 0.5) * 0.14) {
				cloud_rgb = under_col;
			}

			// Sunset/Eclipse cloud tinting
			float orb = 0.94 + 0.06 * sin(day_phase * 6.2831853 + phase);
			vec3 dusk_tint = mix(cloud_rgb, cloud_rgb * vec3(1.06, 0.84, 0.78), dusk * 0.52);
			cloud_rgb = min(mix(dusk_tint, cloud_rgb * vec3(0.42, 0.50, 0.74), nm) * orb, vec3(0.95));

			float canopy_alpha = mix(0.46, 0.58, smoothstep(0.28, 0.80, f_canopy)) * opacity_mul;
			COLOR = vec4(cloud_rgb, canopy_alpha);
		} else {
			// 2) Crisp dark SE ground shadow (offset SE by +5, +7 world px)
			vec2 p_shadow = (rel_world - vec2(5.0, 7.0)) / body_half;
			float f_shadow = cloud_shape(p_shadow, t) * density_scale;
			float shadow_edge = smoothstep(0.20, 0.68, f_shadow);
			if (shadow_edge <= dither * 0.54 + 0.22) {
				discard;
			}
			vec3 shadow_col = vec3(0.025, 0.045, 0.10);
			float shadow_alpha = 0.26 * smoothstep(0.15, 0.85, shadow_edge) * opacity_mul * (1.0 - 0.35 * nm);
			COLOR = vec4(shadow_col, shadow_alpha);
		}
	}
}
