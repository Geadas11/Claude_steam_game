class_name Sea
## The sea, the rain and the fishing boats, made in code.

static var _water: ShaderMaterial


## A big plane of moving water at height `y` (Gerstner-like swell, two
## scrolling normal maps for ripples, darker in the deep, foam on crests).
static func water(parent: Node3D, center: Vector3, size: float, subdiv := 220) -> MeshInstance3D:
	var pm := PlaneMesh.new()
	pm.size = Vector2(size, size)
	pm.subdivide_width = subdiv
	pm.subdivide_depth = subdiv
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.position = center
	mi.material_override = material()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func material() -> ShaderMaterial:
	if _water:
		return _water
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode cull_disabled, depth_draw_always;
uniform vec3 deep : source_color = vec3(0.004, 0.018, 0.028);
uniform vec3 shallow : source_color = vec3(0.02, 0.07, 0.08);
uniform sampler2D ripple_a : hint_normal;
uniform sampler2D ripple_b : hint_normal;
uniform float swell = 1.0;
uniform vec3 sky_glow : source_color = vec3(0.5, 0.45, 0.42);
varying float crest;
varying vec3 wpos;

vec3 wave(vec2 p, vec2 dir, float amp, float len, float speed, float t) {
	float k = 6.2831 / len;
	float f = k * dot(dir, p) - speed * t;
	return vec3(dir.x * amp * 0.6 * cos(f), amp * sin(f), dir.y * amp * 0.6 * cos(f));
}
vec3 displace(vec2 p, float t) {
	vec3 d = vec3(0.0);
	d += wave(p, normalize(vec2(0.3, 1.0)), 0.32 * swell, 34.0, 1.1, t);
	d += wave(p, normalize(vec2(-0.6, 0.8)), 0.16 * swell, 15.0, 1.6, t);
	d += wave(p, normalize(vec2(0.9, 0.4)), 0.07 * swell, 6.5, 2.4, t);
	return d;
}
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME;
	vec3 d = displace(w.xz, t);
	float e = 0.4;
	vec3 dx = displace(w.xz + vec2(e, 0.0), t) - d + vec3(e, 0.0, 0.0);
	vec3 dz = displace(w.xz + vec2(0.0, e), t) - d + vec3(0.0, 0.0, e);
	NORMAL = normalize(cross(dz, dx));
	VERTEX += d;
	crest = d.y;
	wpos = w + d;
}
void fragment() {
	vec2 uv = wpos.xz;
	vec3 na = texture(ripple_a, uv * 0.045 + TIME * vec2(0.012, 0.02)).xyz;
	vec3 nb = texture(ripple_b, uv * 0.11 - TIME * vec2(0.02, 0.01)).xyz;
	NORMAL_MAP = normalize(mix(na, nb, 0.5));
	NORMAL_MAP_DEPTH = 0.6;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	vec3 c = mix(deep, shallow, clamp(crest * 1.5 + 0.3, 0.0, 1.0));
	float foam = smoothstep(0.28, 0.42, crest) * (0.6 + 0.4 * nb.x);
	ALBEDO = mix(c, vec3(0.55, 0.58, 0.6), foam * 0.35) + fres * vec3(0.02, 0.03, 0.04);
	ROUGHNESS = mix(0.04, 0.35, foam);
	EMISSION = sky_glow * fres * 0.06;
	METALLIC = 0.0;
	SPECULAR = 0.7;
}"""
	_water = ShaderMaterial.new()
	_water.shader = sh
	for slot in ["ripple_a", "ripple_b"]:
		var nt := NoiseTexture2D.new()
		nt.width = 256
		nt.height = 256
		nt.seamless = true
		nt.as_normal_map = true
		nt.bump_strength = 6.0 if slot == "ripple_a" else 3.0
		var fn := FastNoiseLite.new()
		fn.frequency = 0.03 if slot == "ripple_a" else 0.06
		fn.fractal_octaves = 4
		nt.noise = fn
		_water.set_shader_parameter(slot, nt)
	return _water


## Rain that follows a node (the player): streaks in a box around it.
static func rain(follow: Node3D, amount := 3500) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = 1.2
	p.visibility_aabb = AABB(Vector3(-14, -12, -14), Vector3(28, 24, 28))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(13, 0.5, 13)
	pm.direction = Vector3(0.12, -1, 0.05)
	pm.spread = 3.0
	pm.initial_velocity_min = 13.0
	pm.initial_velocity_max = 16.0
	pm.gravity = Vector3(0, -9.8, 0)
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.008, 0.38)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.62, 0.66, 0.7, 0.1)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	q.material = m
	p.draw_pass_1 = q
	p.position = Vector3(0, 10, 0)
	p.set_meta("rain", true)
	follow.add_child(p)
	p.top_level = false
	return p


## A Portuguese fishing boat: a lofted wooden hull painted in stripes, a
## bench, sitting at `pos` turned `yaw`. Returns the boat node.
static func boat(parent: Node3D, pos: Vector3, yaw: float, length: float, colors: Array, rng: RandomNumberGenerator) -> Node3D:
	var b := Node3D.new()
	b.position = pos
	b.rotation_degrees.y = yaw
	parent.add_child(b)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sections := 14
	var ring := 10
	var beam := length * 0.34
	var depth := length * 0.16
	var pts: Array = []
	for i in sections + 1:
		var t := float(i) / sections
		var taper := pow(sin(PI * clampf(t * 0.92 + 0.04, 0.0, 1.0)), 0.55)
		var row: Array = []
		for j in ring + 1:
			var a := PI * float(j) / ring          # 0..PI, port to starboard under the keel
			var x := cos(a) * beam * 0.5 * taper
			var y := -sin(a) * depth * (0.55 + 0.45 * taper) + (0.12 * pow(absf(t - 0.5) * 2.0, 3.0)) * depth * 2.0
			row.append(Vector3(x, y, (t - 0.5) * length))
		pts.append(row)
	for i in sections:
		for j in ring:
			var a: Vector3 = pts[i][j]
			var b2: Vector3 = pts[i + 1][j]
			var c: Vector3 = pts[i + 1][j + 1]
			var d: Vector3 = pts[i][j + 1]
			var v := float(j) / ring
			for tri in [[a, b2, c], [a, c, d]]:
				for vert in tri:
					st.set_uv(Vector2(vert.z / length + 0.5, -vert.y / depth))
					st.add_vertex(vert)
	st.generate_normals()
	var hull := MeshInstance3D.new()
	hull.mesh = st.commit()
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode cull_disabled;
uniform vec3 top_col : source_color;
uniform vec3 mid_col : source_color;
uniform vec3 low_col : source_color;
void fragment() {
	float v = UV.y;
	vec3 c = v < 0.18 ? top_col : (v < 0.32 ? mid_col : low_col);
	if (!FRONT_FACING) c *= 0.55;
	ALBEDO = c;
	ROUGHNESS = 0.6;
}"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("top_col", colors[0])
	m.set_shader_parameter("mid_col", colors[1])
	m.set_shader_parameter("low_col", colors[2])
	hull.material_override = m
	b.add_child(hull)
	var wood := WB.mat("weathered_planks", 1.0, Color(0.7, 0.62, 0.5))
	WB.box(b, Vector3(-beam * 0.42, -depth * 0.35, -0.12), Vector3(beam * 0.42, -depth * 0.3, 0.12), wood, false)
	WB.box(b, Vector3(-beam * 0.3, -depth * 0.95, -length * 0.35), Vector3(beam * 0.3, -depth * 0.9, length * 0.35), wood, false)
	return b
