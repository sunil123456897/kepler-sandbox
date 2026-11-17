shader_type canvas_item;
render_mode blend_add, unshaded;

// Procedural 16-segment Bezier portal arc shader for MultiMeshInstance2D
// (`use_colors = true`, `use_custom_data = true`).
//
// Mesh & Transform2D contract (`combat_and_beams.gd`):
// - ArrayMesh ribbon strip: local VERTEX.x in [0.0, 1.0], UV.x = t in [0.0, 1.0] along src -> dst;
//   local VERTEX.y in [-half_width, +half_width] is perpendicular ribbon width, UV.y in [0.0, 1.0].
// - Instance Transform2D: (delta.angle(), Vector2(dist, 1.0), 0.0, src_pos).
//
// INSTANCE_CUSTOM contract:
// - .r = arc_lift_px  (quadratic Bezier lift: VERTEX.y += -4.0 * t * (1.0 - t) * arc_lift_px)
// - .g = phase_offset (per-arc animation phase offset)
// - .b = fade_alpha   (envelope opacity [0.0..1.0]; <= 0.001 discards)
// - .a = pulse_freq   (packet travel speed along UV.x from 0 -> 1; falls back to default_pulse_freq if 0)
//
// COLOR contract:
// - RGB = faction / portal tint color; Alpha = instance opacity multiplier.
// - Final output RGB is strictly clamped to vec3(3.4) so AgX white = 6.0 never blows out to flat white.

uniform float hdr_sheath_boost : hint_range(0.2, 3.4) = 1.15;
uniform float hdr_packet_boost : hint_range(0.0, 3.4) = 1.45;
uniform float packet_count : hint_range(1.0, 24.0) = 5.0;
uniform float default_pulse_freq : hint_range(0.1, 12.0) = 2.4;
uniform float ribbon_jitter_px : hint_range(0.0, 2.0) = 0.50;
uniform vec3 portal_aura_tint = vec3(0.74, 0.26, 1.0);
uniform vec3 packet_cyan_tint = vec3(0.30, 0.95, 1.0);

varying vec4 v_custom;
varying vec4 v_inst_col;

void vertex() {
	v_custom = INSTANCE_CUSTOM;
	v_inst_col = COLOR;

	float t = clamp(UV.x, 0.0, 1.0);
	float arch_t = 4.0 * t * (1.0 - t);
	float arc_lift_px = INSTANCE_CUSTOM.r;
	float phase_offset = INSTANCE_CUSTOM.g;

	float ripple = sin(t * 15.707963 + TIME * 9.0 + phase_offset * 6.2831853) * ribbon_jitter_px * arch_t;
	VERTEX.y += -arch_t * arc_lift_px + ripple;
}

void fragment() {
	float fade_alpha = clamp(v_custom.b, 0.0, 1.0) * clamp(v_inst_col.a, 0.0, 1.0);
	if (fade_alpha <= 0.001) {
		discard;
	}

	float t = clamp(UV.x, 0.0, 1.0);
	float phase_offset = v_custom.g;
	float pulse_freq = (abs(v_custom.a) > 0.001) ? v_custom.a : default_pulse_freq;

	// Smooth endpoint taper so ribbon anchors cleanly at both Quantum Gates
	float taper = smoothstep(0.0, 0.09, t) * smoothstep(1.0, 0.91, t);

	// Wide soft violet-magenta sheath + crisp core across abs(UV.y - 0.5)
	float micro_wave = sin(t * 22.0 - TIME * 11.0 + phase_offset * 6.2831853) * 0.052 * taper;
	float dist_center = abs((UV.y - 0.5) - micro_wave);
	float core = 1.0 - smoothstep(0.015, 0.14, dist_center);
	float corona = 1.0 - smoothstep(0.04, 0.31, dist_center);
	float aura = 1.0 - smoothstep(0.06, 0.49, dist_center);

	// Quantized bright cyan singularity packets traveling from 0 -> 1 along UV.x
	float q_t = floor(t * 48.0) / 48.0;
	float pkt_phase = fract(q_t * packet_count - TIME * pulse_freq + phase_offset * 3.0);
	float pkt_wave = smoothstep(0.38, 0.78, pkt_phase) * (1.0 - smoothstep(0.84, 0.99, pkt_phase));
	float packet = floor(pkt_wave * 4.0 + 0.5) / 4.0;

	// Separate portal look from flat HUD cyan: violet-magenta conduit + cyan traveling packets
	vec3 base_col = max(v_inst_col.rgb, vec3(0.0));
	vec3 sheath_col = mix(portal_aura_tint, base_col, 0.36);
	vec3 core_col = mix(vec3(0.84, 0.56, 1.0), base_col, 0.42);
	vec3 packet_col = mix(packet_cyan_tint, vec3(0.78, 0.98, 1.0), core * 0.55);

	vec3 conduit_rgb = (sheath_col * (0.48 * aura + 0.62 * corona) + core_col * (0.85 * core)) * hdr_sheath_boost;
	vec3 packet_rgb = packet_col * (0.55 * corona + 1.05 * core) * packet * hdr_packet_boost;

	vec3 rgb = (conduit_rgb + packet_rgb) * taper * fade_alpha;

	// Strict HDR cap under AgX white = 6.0 so portals stay vividly saturated without white clipping
	rgb = min(rgb, vec3(3.4));
	COLOR = vec4(rgb, 1.0);
}
