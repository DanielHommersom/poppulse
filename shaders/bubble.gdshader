shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;

// One glowing dome-shaped bubble, drawn on a square quad.
// The body sits in the centre; the rest of the quad is room for the glow halo.

uniform vec4 base_color : source_color = vec4(1.0, 0.3, 0.6, 1.0);
uniform float lit : hint_range(0.0, 1.0) = 0.0;     // 0 = dark, 1 = fully lit target
uniform float press = 0.0;                           // 0 = dome, 1 = pushed in (concave)
uniform float flash : hint_range(0.0, 1.0) = 0.0;   // white/red hit flash
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float body_ratio = 0.6;                      // body radius / half quad
uniform float pulse = 0.0;                           // breathing on lit targets
// Theme look (defaults = Neon).
uniform float dim_mix = 0.16;      // brightness of an unlit bubble
uniform float hot_add = 0.18;      // white added when lit
uniform float rim_lo = 0.12;
uniform float rim_hi = 0.5;
uniform float spec_lo = 0.35;
uniform float spec_hi = 0.95;
uniform float glow_lo = 0.05;
uniform float glow_hi = 0.85;
// Bubble design (US-25): 0 round, 1 tile, 2 heart, 3 star, 4 jelly, 5 hex, 6 pearl (drop).
// Purely visual — the hitbox stays the same circle for every design.
uniform int shape = 0;

float dot2(vec2 v) { return dot(v, v); }

// Signed distance to the outline in quad space (negative inside). r = body radius.
float shape_sdf(vec2 p, float r) {
	if (shape == 1) {  // rounded square ("tile")
		float rr = r * 0.32;
		vec2 q = abs(p) - vec2(r * 0.86 - rr);
		return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - rr;
	} else if (shape == 2) {  // heart (Inigo Quilez), y flipped for UV space
		float k = r * 1.32;
		vec2 h = vec2(abs(p.x), -p.y) / k + vec2(0.0, 0.56);
		float dd;
		if (h.y + h.x > 1.0) {
			dd = sqrt(dot2(h - vec2(0.25, 0.75))) - sqrt(2.0) / 4.0;
		} else {
			dd = sqrt(min(dot2(h - vec2(0.0, 1.0)), dot2(h - 0.5 * max(h.x + h.y, 0.0)))) * sign(h.x - h.y);
		}
		return dd * k;
	} else if (shape == 3) {  // five-point star with soft corners
		vec2 q = vec2(p.x, -p.y);
		float rs = r * 1.12;
		const vec2 k1 = vec2(0.809016994375, -0.587785252292);
		const vec2 k2 = vec2(-0.809016994375, -0.587785252292);
		q.x = abs(q.x);
		q -= 2.0 * max(dot(k1, q), 0.0) * k1;
		q -= 2.0 * max(dot(k2, q), 0.0) * k2;
		q.x = abs(q.x);
		q.y -= rs;
		vec2 ba = 0.52 * vec2(-k1.y, k1.x) - vec2(0.0, 1.0);
		float hh = clamp(dot(q, ba) / dot(ba, ba), 0.0, rs);
		return length(q - ba * hh) * sign(q.y * ba.x - q.x * ba.y) - r * 0.07;
	} else if (shape == 4) {  // jelly: a slowly wobbling blob
		float a = atan(p.y, p.x);
		float w = 1.0 + 0.055 * sin(a * 3.0 + TIME * 2.6) + 0.03 * sin(a * 5.0 - TIME * 1.7);
		return length(p) - r * w;
	} else if (shape == 5) {  // hexagon gem
		const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
		vec2 q = abs(p);
		float rr = r * 0.12;
		float hr = r * 0.92 - rr;
		q -= 2.0 * min(dot(k.xy, q), 0.0) * k.xy;
		q -= vec2(clamp(q.x, -k.z * hr, k.z * hr), hr);
		return length(q) * sign(q.y) - rr;
	}
	if (shape == 6) {  // pearl / water drop: circle + cone tangent to it, tip up
		float rr = r * 0.08;  // tip rounding
		float R = r * 0.8 - rr;
		float T = r * 1.75;   // circle centre -> tip
		vec2 q = vec2(abs(p.x), -p.y + r * 0.22);  // y up, circle centre lowered
		float sn = R / T;
		float cs = sqrt(1.0 - sn * sn);
		if (q.y * cs - q.x * sn <= 0.0) {
			return length(q) - R - rr;
		}
		vec2 tip = vec2(0.0, T);
		if (dot(q - tip, vec2(-sn, cs)) > 0.0) {
			return length(q - tip) - rr;
		}
		return dot(q, vec2(cs, sn)) - R - rr;
	}
	return length(p) - r;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float r = body_ratio * (1.0 - press * 0.06);
	float aa = fwidth(d) * 1.2;
	float body = 1.0 - smoothstep(r - aa, r, d);

	// Fake 3D dome normal; pressing flips it so the bubble reads as pushed in.
	vec2 q = p / r;
	float qq = clamp(dot(q, q), 0.0, 1.0);
	float bulge = mix(1.0, -0.7, press);
	float sd = d - r;
	if (shape != 0) {
		// Same dome model on any outline: depth from the edge + outline normal.
		sd = shape_sdf(p, r);
		body = 1.0 - smoothstep(-aa, 0.0, sd);
		float e = clamp(1.0 + sd / r, 0.0, 1.0);
		vec2 gdir = vec2(dFdx(sd), dFdy(sd));
		gdir = gdir / max(length(gdir), 1e-5);
		q = gdir * e;
		qq = e * e;
	}
	float h = sqrt(1.0 - qq);
	vec3 n = normalize(vec3(q * bulge, h + 0.001));
	vec3 L = normalize(vec3(-0.45, -0.65, 0.9));
	float diff = clamp(dot(n, L), 0.0, 1.0);
	vec3 R = reflect(-L, n);
	float spec = pow(clamp(R.z, 0.0, 1.0), 28.0);

	float energy = clamp(lit * (1.0 + pulse * 0.12 * sin(TIME * 9.0)), 0.0, 1.0);
	vec3 c = base_color.rgb;
	vec3 dim = c * dim_mix + vec3(0.02);
	vec3 hot = c * 1.05 + vec3(hot_add);
	vec3 col = mix(dim, hot, energy);
	col *= 0.45 + 0.75 * diff;
	col += c * energy * (1.0 - sqrt(qq)) * 0.55;          // light from within
	float rim = smoothstep(0.55, 1.0, sqrt(qq));
	col += c * rim * mix(rim_lo, rim_hi, energy);               // rim light
	col += vec3(spec) * mix(spec_lo, spec_hi, energy) * (1.0 - clamp(press, 0.0, 1.0) * 0.7);
	col = mix(col, flash_color.rgb, flash);

	// Outer glow halo (mostly additive thanks to premultiplied alpha).
	float edge_fade = smoothstep(1.0, 0.85, d);
	float g = exp(-max(sd, 0.0) * 7.0) * (1.0 - body) * edge_fade;
	float glow_amt = mix(glow_lo, glow_hi, energy) + flash * 0.6;
	vec3 glow_col = mix(c, flash_color.rgb, flash) * g * glow_amt;

	COLOR = vec4(col * body + glow_col, body + g * glow_amt * 0.25);
}
