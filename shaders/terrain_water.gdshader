shader_type canvas_item;

uniform sampler2D mask_tex : filter_nearest, repeat_disable;
uniform vec2 map_size = vec2(640.0, 360.0);
uniform float water_caustic_strength = 0.24;
uniform float foam_wave_speed = 2.4;
uniform float lava_glow_strength = 1.95;
uniform float crystal_glow_strength = 1.55;
uniform float day_phase = 0.0;
uniform float night_mix : hint_range(0.0, 1.0) = 0.0;
uniform vec3 age_tint = vec3(1.0, 1.0, 1.0);
uniform float age_tint_strength : hint_range(0.0, 1.0) = 0.0;

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

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec4 mask = texture(mask_tex, UV);
	vec2 px = floor(UV * map_size);
	float dither = bayer4(px);
	float t = TIME;
	float nm = clamp(night_mix, 0.0, 1.0);
	float dusk = sin(nm * 3.14159265);
	vec3 out_rgb = base.rgb;

	// mask.r: water depth tier (0 = land, ~0.33 = deep, ~0.66 = close, 1.0 = shallow/river)
	// mask.g: coastal foam / river flow intensity (water) OR active wildfire heat (land)
	// mask.b: active lava / magma fissure heat glow (0..1)
	// mask.a: crystal shard tip glow (0..1)

	if (mask.r > 0.10) {
		// Clean WorldBox-style depth steps without blotchy pelagic current spots
		float depth_w = smoothstep(0.35, 1.0, mask.r);
		float tier_mid = smoothstep(0.45, 0.55, mask.r);
		float tier_shal = smoothstep(0.80, 0.90, mask.r);
		vec3 tier_tint = mix(vec3(0.96, 0.98, 1.02), vec3(1.00, 1.03, 1.06), tier_mid);
		tier_tint = mix(tier_tint, vec3(1.03, 1.06, 1.05), tier_shal);
		out_rgb *= tier_tint;

		// Crisp shallow-water caustics confined to coastal shelf & rivers (keeps deep ocean serene)
		if (depth_w > 0.04) {
			vec2 wp = px * 0.21;
			float w1 = sin(wp.x * 1.10 + wp.y * 0.72 + t * 1.65);
			float w2 = cos(wp.x * 0.65 - wp.y * 1.18 - t * 1.35);
			float caustic_raw = (w1 * w2) * 0.5 + 0.5;
			float caustic = smoothstep(0.68, 0.86, caustic_raw) * depth_w;
			vec3 caustic_col = mix(vec3(0.03, 0.10, 0.18), vec3(0.11, 0.28, 0.40), tier_shal);
			out_rgb += caustic_col * caustic * water_caustic_strength * (0.45 + 0.55 * tier_shal);
		}

		// Subtle sparkling glints near sunlit shallows only (safely below HDR bloom threshold)
		float glint_wave = sin((px.x - px.y) * 0.29 + t * 2.1) * cos((px.x + px.y) * 0.23 - t * 1.7);
		float glint = step(0.975, hash21(px + floor(t * 1.5) * 0.13)) * step(0.35, glint_wave) * tier_shal;
		out_rgb += vec3(0.06, 0.14, 0.20) * glint * (1.0 - 0.65 * nm);
		out_rgb = min(out_rgb, vec3(0.82));

		// Clean lapping coastal foam band (preserves dark 1px WorldLayerEdges rim)
		float base_luma = dot(base.rgb, vec3(0.299, 0.587, 0.114));
		float rim_guard = smoothstep(0.26, 0.40, base_luma);
		if (mask.g > 0.04 && rim_guard > 0.05) {
			float shore_wave = sin(t * foam_wave_speed - mask.g * 4.6 + (px.x + px.y) * 0.14) * 0.5 + 0.5;
			float ripple = cos(t * foam_wave_speed * 0.68 + px.x * 0.18 - px.y * 0.21) * 0.5 + 0.5;
			float wave_crest = shore_wave * 0.65 + ripple * 0.35;
			float foam_density = mask.g * (0.68 + 0.42 * wave_crest);
			float foam_band = smoothstep(0.34, 0.78, foam_density) * step(0.24, mask.g + wave_crest * 0.20);
			if (foam_band > 0.01) {
				vec3 foam_col = mix(vec3(0.42, 0.74, 0.88), vec3(0.76, 0.92, 0.95), clamp(foam_band * 1.15, 0.0, 1.0));
				out_rgb = mix(out_rgb, foam_col, 0.78 * foam_band * rim_guard);
			}
		}
	} else {
		// Crisp wet-sand / shoreline contact darkening right next to coastal water (mask.r > 0.10)
		vec2 texel = 1.0 / max(map_size, vec2(1.0));
		float water_adj = max(
			max(texture(mask_tex, UV + vec2(texel.x, 0.0)).r, texture(mask_tex, UV - vec2(texel.x, 0.0)).r),
			max(texture(mask_tex, UV + vec2(0.0, texel.y)).r, texture(mask_tex, UV - vec2(0.0, texel.y)).r)
		);
		if (water_adj > 0.10 && mask.b <= 0.02 && mask.a <= 0.04 && base.r >= base.b * 0.92) {
			float shore_damp = smoothstep(0.10, 0.65, water_adj);
			float wet_sand = (base.r > 0.42 && base.g > 0.34) ? 1.0 : 0.45;
			out_rgb = mix(out_rgb, out_rgb * vec3(0.76, 0.75, 0.72), 0.38 * shore_damp * wet_sand);
		}
	}

	// World-age atmospheric tint + orbital time-of-day grading (applied strictly <= 0.95 BEFORE emissives)
	float at_str = clamp(age_tint_strength, 0.0, 1.0);
	if (at_str > 0.001) {
		out_rgb = mix(out_rgb, out_rgb * max(age_tint, vec3(0.0)), at_str);
	}
	out_rgb = min(out_rgb, vec3(0.95));
	if (nm > 0.001 || dusk > 0.001) {
		float orb = 0.92 + 0.08 * sin(UV.x * 3.14159265 + day_phase * 6.2831853);
		vec3 dusk_col = out_rgb * vec3(1.10, 0.79, 0.65);
		vec3 night_col = max(out_rgb * vec3(0.28, 0.36, 0.62), vec3(0.030, 0.042, 0.072));
		vec3 lit_rgb = mix(out_rgb, dusk_col, dusk * 0.46);
		lit_rgb = mix(lit_rgb, night_col, nm) * mix(1.0, orb, max(nm, dusk));
		out_rgb = min(lit_rgb, vec3(0.95));
	}

	// Emissives added AFTER day/night grading so magma, fire & crystals blaze at dusk/night
	float night_pop = 1.0 + 0.28 * nm + 0.14 * dusk;

	// Active lava fissures & smooth flowing magma veins (mask.b > 0.02): pulsing HDR emission (rgb > 1.0)
	if (mask.b > 0.02) {
		float heat = mask.b;
		vec2 mp = px * 0.11;
		float warp_x = sin(mp.y * 1.45 + t * 0.85) * 0.65 + cos(mp.x * 0.75 - t * 0.55) * 0.35;
		float warp_y = cos(mp.x * 1.35 - t * 0.75) * 0.65 + sin(mp.y * 0.85 + t * 0.60) * 0.35;
		float vein_a = 1.0 - abs(sin(mp.x + warp_x + t * 0.35));
		float vein_b = 1.0 - abs(cos(mp.y + warp_y - t * 0.28));
		float vein = smoothstep(0.32, 0.92, vein_a * 0.62 + vein_b * 0.38);

		float lava_pool = smoothstep(0.32, 0.55, heat);
		float pulse_l = 0.86 + 0.14 * sin(t * 2.2 + mp.x * 1.2 + mp.y * 0.9);
		vec3 crust_col = vec3(0.16, 0.08, 0.08);
		vec3 molten_base = mix(crust_col, vec3(0.88, 0.26, 0.04), smoothstep(0.20, 0.78, vein * 0.75 + heat * 0.35));
		out_rgb = mix(out_rgb, molten_base, lava_pool * 0.88);

		float core_vein = smoothstep(0.42, 0.94, vein * 0.70 + heat * 0.45);
		vec3 magma_hdr = mix(vec3(1.18, 0.25, 0.03), vec3(2.32, 1.00, 0.20), core_vein);
		out_rgb += magma_hdr * heat * (0.35 + 0.65 * vein) * pulse_l * lava_glow_strength * 0.52 * night_pop;
	}

	// Active wildfire glow on land (mask.r <= 0.10 && mask.g > 0.04)
	if (mask.r <= 0.10 && mask.g > 0.04) {
		float fire_v = mask.g;
		float flicker = 0.68 + 0.32 * sin(t * 15.0 + px.x * 0.9 - px.y * 1.3 + hash21(px) * 4.5);
		vec3 fire_hdr = mix(vec3(1.45, 0.36, 0.04), vec3(2.35, 1.05, 0.22), fire_v);
		out_rgb += fire_hdr * fire_v * flicker * 1.25 * night_pop;
	}

	// Cyan crystal tips & veins (mask.a > 0.04): pulsing HDR emission
	if (mask.a > 0.04) {
		float c_str = mask.a;
		float pulse = 0.76 + 0.28 * sin(t * 2.7 + px.x * 0.45 - px.y * 0.42);
		float tip = step(0.42, c_str);
		float glint_c = smoothstep(0.75, 0.98, c_str) * step(0.72, sin(t * 4.1 + px.x * 0.8 + px.y * 0.7));
		vec3 crystal_hdr = mix(vec3(0.05, 0.22, 0.32), vec3(0.24, 1.45, 2.05), tip);
		crystal_hdr += vec3(0.45, 0.85, 1.0) * glint_c;
		out_rgb += crystal_hdr * c_str * pulse * crystal_glow_strength * 0.58 * night_pop;
	}

	COLOR = vec4(out_rgb, base.a);
}
