shader_type canvas_item;

uniform int sprite_mode : hint_range(0, 3) = 3;
uniform int motion_mode : hint_range(0, 2) = 0;
uniform int atlas_cols : hint_range(1, 64) = 4;
uniform vec2 sprite_size = vec2(8.0, 8.0);
uniform sampler2D mask_tex : filter_nearest, repeat_disable;
uniform float wind_speed = 2.6;
uniform float wind_amp = 1.15;
uniform float shake_freq = 48.0;
uniform float shake_amp = 2.2;
uniform float hdr_visor = 2.2;
uniform float hdr_flame = 2.8;
uniform float hdr_crystal = 2.4;
uniform float hdr_lava = 2.6;
uniform float hdr_emissive = 2.6;
uniform float burn_amount : hint_range(0.0, 1.0) = 0.0;
uniform float blueprint_col : hint_range(-1.0, 64.0) = 18.0;
uniform float blueprint_col_hi : hint_range(-1.0, 64.0) = 19.0;
uniform float day_phase = 0.0;
uniform float night_mix : hint_range(0.0, 1.0) = 0.0;
uniform vec3 age_tint = vec3(1.0, 1.0, 1.0);
uniform float age_tint_strength : hint_range(0.0, 1.0) = 0.0;

varying vec4 v_custom;
varying vec2 v_local_uv;
varying vec4 v_inst_col;

float flora_sway_weight(float col_idx) {
	if (col_idx > 4.5 && col_idx < 6.5) {
		return 0.0; // boulder, magma_vent
	}
	if (abs(col_idx - 9.0) < 0.25) {
		return 0.0; // ash_stump
	}
	if (abs(col_idx - 3.0) < 0.25 || abs(col_idx - 4.0) < 0.25 || abs(col_idx - 11.0) < 0.25) {
		return 0.12; // crystals sway very subtly
	}
	return 1.0;
}

void vertex() {
	v_custom = INSTANCE_CUSTOM;
	v_inst_col = COLOR;

	float pivot_y = sprite_size.y * 0.5;
	float top_t = clamp((pivot_y - VERTEX.y) / max(sprite_size.y, 1.0), 0.0, 1.0);

	if (sprite_mode == 0) {
		float phase = INSTANCE_CUSTOM.r;
		float speed_norm = INSTANCE_CUSTOM.g;
		float facing_squash = INSTANCE_CUSTOM.b;
		float flip_x = (facing_squash < 0.0) ? -1.0 : 1.0;
		float sy = clamp(abs(facing_squash), 0.65, 1.35);
		float sx = 1.0 / sqrt(sy);
		float bob = sin(phase * 2.0) * 0.25 * clamp(speed_norm, 0.0, 1.0);

		VERTEX.x *= sx;
		VERTEX.y = pivot_y + (VERTEX.y - pivot_y) * sy + bob;
		VERTEX.x += flip_x * clamp(speed_norm - 0.85, 0.0, 0.75) * 1.1 * top_t;
		v_local_uv = vec2((flip_x < 0.0) ? (1.0 - UV.x) : UV.x, 1.0 - UV.y);
	} else if (sprite_mode == 1) {
		float sway_phase = INSTANCE_CUSTOM.r;
		float shake = clamp(INSTANCE_CUSTOM.g, 0.0, 1.5);
		float spawn_spring = clamp(INSTANCE_CUSTOM.b, 0.08, 1.35);
		float col_idx = floor(INSTANCE_CUSTOM.a + 0.5);

		float sx = 1.0 / sqrt(clamp(spawn_spring, 0.35, 1.35));
		VERTEX.x *= sx;
		VERTEX.y = pivot_y + (VERTEX.y - pivot_y) * spawn_spring;

		float sway_w = flora_sway_weight(col_idx);
		float sway = sin(TIME * wind_speed + sway_phase) * wind_amp * sway_w * top_t;
		float jitter = sin(TIME * shake_freq + sway_phase * 5.0) * shake * shake_amp * top_t;
		VERTEX.x += sway + jitter;
		v_local_uv = vec2(UV.x, 1.0 - UV.y);
	} else if (sprite_mode == 3) {
		float phase = INSTANCE_CUSTOM.r;
		float raw_g = INSTANCE_CUSTOM.g;
		float raw_b = INSTANCE_CUSTOM.b;
		float col_idx = floor(INSTANCE_CUSTOM.a + 0.5);

		if (motion_mode == 2) {
			// Units: flip_x via negative b, squash-and-stretch, walk bob & sprint lean
			float speed_norm = (raw_g <= -1.9) ? 0.55 : ((raw_g >= 2.0) ? 0.65 : clamp(raw_g, 0.0, 1.8));
			float flip_x = (raw_b < -0.001) ? -1.0 : 1.0;
			float abs_b = abs(raw_b);
			float sy = (abs_b <= 0.001) ? 1.0 : clamp(abs_b, 0.65, 1.35);
			float sx = 1.0 / sqrt(sy);
			float bob = sin(phase * 2.0) * 0.25 * clamp(speed_norm, 0.0, 1.0);
			float burn_jitter = (raw_g >= 2.0) ? sin(TIME * shake_freq + phase * 5.0) * 0.35 * top_t : 0.0;

			VERTEX.x *= sx;
			VERTEX.y = pivot_y + (VERTEX.y - pivot_y) * sy + bob;
			VERTEX.x += flip_x * clamp(speed_norm - 0.85, 0.0, 0.75) * 1.1 * top_t + burn_jitter;
			v_local_uv = vec2((flip_x < 0.0) ? (1.0 - UV.x) : UV.x, 1.0 - UV.y);
		} else if (motion_mode == 1) {
			// Flora: wind sway, chop shake, spawn spring, burning quiver
			float shake = (raw_g < 0.0) ? 0.0 : ((raw_g >= 2.0) ? clamp(raw_g - 2.0, 0.0, 1.0) * 0.25 : raw_g);
			float spawn_spring = (raw_b <= 0.001) ? 1.0 : clamp(raw_b, 0.08, 1.35);
			float sx = 1.0 / sqrt(clamp(spawn_spring, 0.35, 1.35));
			VERTEX.x *= sx;
			VERTEX.y = pivot_y + (VERTEX.y - pivot_y) * spawn_spring;

			float sway_w = flora_sway_weight(col_idx);
			float sway = sin(TIME * wind_speed + phase) * wind_amp * sway_w * top_t;
			float jitter = sin(TIME * shake_freq + phase * 5.0) * shake * shake_amp * top_t;
			VERTEX.x += sway + jitter;
			v_local_uv = vec2(UV.x, 1.0 - UV.y);
		} else {
			// Buildings / Shuttles: spawn spring, hit shake, optional flip_x
			float flip_x = (raw_b < -0.001) ? -1.0 : 1.0;
			float abs_b = abs(raw_b);
			float spawn_spring = (abs_b <= 0.001) ? 1.0 : clamp(abs_b, 0.08, 1.35);
			float shake = (raw_g < 0.0) ? 0.0 : ((raw_g >= 2.0) ? clamp(raw_g - 2.0, 0.0, 1.0) * 0.25 : raw_g);

			float sx = 1.0 / sqrt(clamp(spawn_spring, 0.35, 1.35));
			VERTEX.x *= sx;
			VERTEX.y = pivot_y + (VERTEX.y - pivot_y) * spawn_spring;

			float jitter = sin(TIME * shake_freq + phase * 5.0) * shake * shake_amp * top_t;
			VERTEX.x += jitter;
			v_local_uv = vec2((flip_x < 0.0) ? (1.0 - UV.x) : UV.x, 1.0 - UV.y);
		}
	} else {
		v_local_uv = vec2(UV.x, 1.0 - UV.y);
	}
}

void fragment() {
	float cols = max(float(atlas_cols), 1.0);
	float col = clamp(floor(v_custom.a + 0.5), 0.0, cols - 1.0);
	vec2 atlas_uv = vec2(
		(col + clamp(v_local_uv.x, 0.002, 0.998)) / cols,
		clamp(v_local_uv.y, 0.002, 0.998)
	);
	vec4 tex = texture(TEXTURE, atlas_uv);
	if (tex.a < 0.05) {
		discard;
	}

	if (sprite_mode == 0) {
		float chroma = max(abs(tex.r - tex.g), abs(tex.g - tex.b));
		vec3 rgb = tex.rgb;
		if (chroma < 0.09 && tex.r > 0.32) {
			rgb *= v_inst_col.rgb;
		} else if (tex.b > 0.72 && tex.g > 0.60 && tex.r < 0.45) {
			rgb *= hdr_visor;
		} else if (tex.r > 0.90 && tex.g > 0.36 && tex.b < 0.22) {
			rgb *= hdr_flame;
		}
		float heat_flash = clamp(v_custom.g - 1.25, 0.0, 1.0);
		rgb = mix(rgb, vec3(2.4, 1.1, 0.35), heat_flash * 0.25);
		COLOR = vec4(rgb, tex.a * v_inst_col.a);
	} else if (sprite_mode == 1) {
		vec3 rgb = tex.rgb;
		if (tex.b > 0.88 && tex.g > 0.80 && tex.r < 0.45) {
			float pulse = 0.85 + 0.25 * sin(TIME * 3.0 + v_custom.r);
			rgb *= hdr_crystal * pulse;
		} else if (tex.r > 0.92 && tex.g > 0.30 && tex.g < 0.66 && tex.b < 0.18) {
			float pulse = 0.85 + 0.30 * sin(TIME * 4.8 + v_custom.r);
			rgb *= hdr_lava * pulse;
		} else if (tex.g > 0.85 && tex.b > 0.60 && tex.r < 0.42) {
			rgb *= 1.65;
		} else {
			rgb *= v_inst_col.rgb;
		}
		COLOR = vec4(rgb, tex.a * v_inst_col.a);
	} else if (sprite_mode == 3) {
		vec4 mask = texture(mask_tex, atlas_uv);
		float tint_w = clamp(mask.r, 0.0, 1.0);
		float glow_w = clamp(mask.g, 0.0, 1.0);
		float spec_w = clamp(mask.b, 0.0, 1.0);
		float solid_px = smoothstep(0.55, 0.95, tex.a);

		vec3 base_rgb = tex.rgb * mix(vec3(1.0), v_inst_col.rgb, tint_w);
		if (spec_w > 0.02 && solid_px > 0.05) {
			float shimmer = 0.5 + 0.5 * sin(TIME * 1.6 + v_custom.r + v_local_uv.x * 6.0);
			base_rgb += vec3(0.08, 0.12, 0.16) * spec_w * shimmer * solid_px;
		}
		base_rgb = min(base_rgb, vec3(0.95));

		// Optional world-age atmospheric tint + orbital day/sunset/night tint on non-emissive surfaces only
		float at_str = clamp(age_tint_strength, 0.0, 1.0);
		if (at_str > 0.001) {
			base_rgb = min(mix(base_rgb, base_rgb * max(age_tint, vec3(0.0)), at_str), vec3(0.95));
		}
		float nm = clamp(night_mix, 0.0, 1.0);
		float dusk = sin(nm * 3.14159265);
		if (nm > 0.001) {
			float orb = 0.94 + 0.06 * sin(day_phase * 6.2831853 + v_custom.r * 0.1);
			vec3 dusk_rgb = mix(base_rgb, base_rgb * vec3(1.06, 0.82, 0.70), dusk * 0.36);
			base_rgb = min(mix(dusk_rgb, base_rgb * vec3(0.42, 0.50, 0.74), nm) * orb, vec3(0.95));
		}

		// Construction blueprint hologram scanline pulse
		bool is_blueprint = (motion_mode == 0) && (
			v_custom.g < -0.02 ||
			(blueprint_col >= 0.0 && abs(col - blueprint_col) < 0.25) ||
			(blueprint_col_hi >= 0.0 && abs(col - blueprint_col_hi) < 0.25)
		);
		float bp_scan = 1.0;
		float out_alpha = tex.a * v_inst_col.a;
		if (is_blueprint && solid_px > 0.05) {
			float prog_rate = (v_custom.g < -0.02) ? 6.5 : 4.8;
			float wave = 0.5 + 0.5 * sin(TIME * prog_rate - v_local_uv.y * 16.0 + v_custom.r);
			bp_scan = 0.72 + 0.44 * wave;
			if (glow_w > 0.02) {
				out_alpha *= mix(0.86, 1.0, wave);
			}
		}

		vec3 out_rgb = base_rgb;
		if (glow_w > 0.02 && solid_px > 0.05) {
			float pulse = (0.90 + 0.12 * sin(TIME * 3.8 + v_custom.r)) * bp_scan;
			float night_boost = 1.0 + 0.24 * nm;
			float gain = mix(1.0, hdr_emissive * pulse * night_boost, glow_w);
			vec3 emit_src = mix(tex.rgb, base_rgb, tint_w * 0.65);
			out_rgb = min(emit_src * gain, vec3(4.5));
		}

		// Burning ember flicker (custom.g >= 2.0 or burn_amount uniform or burning flora columns 8/13)
		float inst_burn = (v_custom.g >= 2.0) ? clamp(v_custom.g - 2.0, 0.0, 1.0) : 0.0;
		float flora_auto_burn = (motion_mode == 1 && (abs(col - 8.0) < 0.25 || abs(col - 13.0) < 0.25)) ? 0.55 : 0.0;
		float burn = clamp(max(max(burn_amount, inst_burn), flora_auto_burn), 0.0, 1.0);
		if (burn > 0.01 && solid_px > 0.05) {
			vec2 cell_px = floor(v_local_uv * sprite_size);
			float cell_hash = fract(sin(dot(cell_px, vec2(12.9898, 78.233)) + floor(TIME * 11.0) * 0.37) * 43758.5453);
			float f_wave = 0.62 + 0.38 * sin(TIME * 22.0 + v_custom.r * 5.3 + v_local_uv.y * 14.0);
			float ember_mask = step(0.58, cell_hash) * (1.0 - 0.35 * v_local_uv.y) + glow_w * 0.6;
			out_rgb = mix(out_rgb, out_rgb * vec3(0.45, 0.30, 0.24), burn * 0.45 * (1.0 - glow_w));
			out_rgb += vec3(2.35, 0.88, 0.18) * burn * f_wave * ember_mask * solid_px;
			out_rgb = min(out_rgb, vec3(4.5));
		}

		// Crisp hit-flash / possession glow on active units & flora (motion_mode != 0 keeps blueprint scanline intact)
		if (motion_mode != 0 && v_custom.g <= -1.9) {
			float lum = clamp(dot(out_rgb, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);
			float flash = clamp(-v_custom.g - 2.0, 0.0, 1.0) * 0.58 * mix(0.55, 1.0, smoothstep(0.18, 0.45, lum));
			out_rgb = mix(out_rgb, vec3(1.95, 1.85, 1.45), flash);
		}

		COLOR = vec4(out_rgb, out_alpha);
	} else {
		float hdr_mult = max(v_custom.r, 0.1);
		COLOR = vec4(tex.rgb * v_inst_col.rgb * hdr_mult, tex.a * v_inst_col.a);
	}
}
