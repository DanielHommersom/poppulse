shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.06, 0.03, 0.13, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.01, 0.01, 0.04, 1.0);
uniform vec4 accent : source_color = vec4(0.7, 0.25, 1.0, 1.0);
uniform float energy = 0.0; // rises with combo
uniform float grid = 0.045;
uniform float vignette = 0.6;

void fragment() {
	vec2 uv = UV;
	vec3 col = mix(top_color.rgb, bottom_color.rgb, uv.y);

	// Soft coloured wash behind the board, stronger during a combo.
	float d = length((uv - vec2(0.5, 0.55)) * vec2(1.0, 1.4));
	col += accent.rgb * exp(-d * d * 6.0) * (0.10 + energy * 0.28);

	// Faint dot grid for depth.
	vec2 g = fract(FRAGCOORD.xy / 28.0) - 0.5;
	col += vec3(smoothstep(0.08, 0.0, length(g)) * grid);

	// Vignette.
	col *= 1.0 - smoothstep(0.4, 1.1, length(uv - 0.5) * 1.3) * vignette;
	COLOR = vec4(col, 1.0);
}
