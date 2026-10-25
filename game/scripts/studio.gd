extends Node3D

var camera: Camera3D
var people: Array[Node3D] = []
var time := 0.0
var cinematic := true
var materials := {}
var shot := "wide"
var character_index := 0
var contestant_root: Node3D
var fill: OmniLight3D
var mood := Color("a39dff")
var reduced_motion := false
var spots: Array[SpotLight3D] = []
var stage_state := "question"

func mat(color: String, glow := false) -> StandardMaterial3D:
	var key := color + str(glow)
	if materials.has(key): return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = 0.48
	if glow:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.emission_enabled = true
		m.emission = Color(color)
	materials[key] = m
	return m

func mesh(parent: Node3D, shape: Mesh, pos: Vector3, material: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = shape
	n.material_override = material
	n.position = pos
	parent.add_child(n)
	return n

func box(parent: Node3D, pos: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var s := BoxMesh.new()
	s.size = size
	return mesh(parent, s, pos, mat(color))

func sphere(parent: Node3D, pos: Vector3, scale_value: Vector3, color: String) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 16
	s.rings = 8
	var n := mesh(parent, s, pos, mat(color))
	n.scale = scale_value
	return n

func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: String) -> MeshInstance3D:
	var s := CylinderMesh.new()
	s.top_radius = radius
	s.bottom_radius = radius
	s.height = height
	s.radial_segments = 48
	return mesh(parent, s, pos, mat(color))

func rod(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: String, glow := false) -> MeshInstance3D:
	var s := CylinderMesh.new()
	s.top_radius = radius
	s.bottom_radius = radius
	s.height = a.distance_to(b)
	s.radial_segments = 8
	var n := mesh(parent, s, (a + b) * 0.5, mat(color, glow))
	var direction := (b - a).normalized()
	n.quaternion = Quaternion(Vector3.UP, direction)
	return n

func ring(radius: float, y: float, color: String, thickness := 0.035) -> void:
	var s := TorusMesh.new()
	s.inner_radius = radius - thickness
	s.outer_radius = radius + thickness
	s.rings = 72
	s.ring_segments = 8
	mesh(self, s, Vector3(0, y, 0), mat(color, true))

func rear_arc(radius: float, y: float, color: String) -> void:
	for i in range(40):
		var a := PI + float(i) / 40.0 * PI
		var b := PI + float(i + 1) / 40.0 * PI
		rod(self, Vector3(cos(a) * radius, y, sin(a) * radius), Vector3(cos(b) * radius, y, sin(b) * radius), 0.025, color, true)

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("030611")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("9ca5e4")
	env.environment.ambient_light_energy = 0.32
	add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55, -25, 0)
	key.light_color = Color("d5dfff")
	key.light_energy = 0.95
	add_child(key)
	fill = OmniLight3D.new()
	fill.position = Vector3(0, 4, 2)
	fill.omni_range = 12
	fill.light_color = Color("a39dff")
	fill.light_energy = 1.5
	add_child(fill)
	# Two focused pools of light, no sweep or strobe. Compatibility renderer friendly.
	for side in [-1, 1]:
		var spot := SpotLight3D.new()
		spot.position = Vector3(side * 3.2, 6.0, 2.4)
		spot.light_color = Color("c7dbff") if side == -1 else Color("d8c7ff")
		spot.light_energy = 3.0
		spot.spot_range = 12.0
		spot.spot_angle = 25.0
		add_child(spot)
		spot.look_at(Vector3(side * 1.45, 1.2, 0))
		spots.append(spot)
	cylinder(self, Vector3(0, -0.16, 0), 13, 0.3, "080d20")
	cylinder(self, Vector3(0, 0.12, 0), 4.4, 0.24, "111831")
	cylinder(self, Vector3(0, 0.26, 0), 3.8, 0.12, "0a1228")
	for r in [3.8, 4.35, 5.6, 8.0, 10.5]: ring(r, 0.27, "4b50df")
	ring(3.65, 0.33, "8bbcff", 0.018)
	ring(1.35, 0.34, "bc9cf4", 0.015)
	for i in range(32):
		var a := i * TAU / 32.0
		var v := Vector3(cos(a), 0, sin(a))
		rod(self, v * 4.5 + Vector3.UP * 0.04, v * 10.5 + Vector3.UP * 0.04, 0.018, "444c9b", true)
		if i % 2 == 0 and v.z < 0:
			rod(self, v * 10.7, v * 10.7 + Vector3.UP * 6.0, 0.10, "171d3a")
			rod(self, v * 10.5 + Vector3.UP, v * 10.5 + Vector3.UP * 5.6, 0.028, "6555ef", true)
	for h in [3.5, 4.0, 5.6]: rear_arc(10.5, h, "5745b9")
	for i in range(13):
		var a := PI + 0.2 + float(i) / 12 * (PI - 0.4)
		for j in range(3):
			var v := Vector3(cos(a + j * 0.026) * 10.1, 0, sin(a + j * 0.026) * 10.1)
			for k in range(8):
				box(self, v + Vector3.UP * (2.7 + k * 0.15), Vector3(0.05, 0.065, 0.05), "637df9").material_override = mat("637df9", true)
	ring(5.7, 6.2, "5556b4", 0.06)
	# Light beams are translucent geometry, supported by the web renderer.
	for i in range(6):
		var a := i * TAU / 6.0
		var top := Vector3(cos(a) * 5.6, 6.1, sin(a) * 5.6)
		var end := Vector3(cos(a + 0.6) * 2.6, 0.3, sin(a + 0.6) * 2.6)
		var s := CylinderMesh.new()
		s.top_radius = 0.04
		s.bottom_radius = 0.65
		s.height = top.distance_to(end)
		s.radial_segments = 12
		var m := mat("6c65fa", true).duplicate() as StandardMaterial3D
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color.a = 0.024
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		var beam := mesh(self, s, (top + end) / 2, m)
		beam.quaternion = Quaternion(Vector3.UP, (top - end).normalized())
		sphere(self, top, Vector3.ONE * 0.18, "c8caff").material_override = mat("c8caff", true)
	# Tiered audience behind the hot seat.
	for tier in range(3):
		for i in range(17):
			var a := PI + 0.12 + float(i) / 16.0 * (PI - 0.24)
			var r := 6.6 + tier * 1.1
			var p := Vector3(cos(a) * r, 0.4 + tier * 0.43, sin(a) * r)
			box(self, p + Vector3(0, 0.45, 0), Vector3(0.45, 0.7, 0.5), "141d40")
			sphere(self, p + Vector3(0, 1.05, 0), Vector3(0.27, 0.34, 0.28), ["796878", "967d86", "5f586c"][i % 3])
			sphere(self, p + Vector3(0, 0.65, 0), Vector3(0.43, 0.58, 0.3), ["242747", "343351", "202c4c"][i % 3])
	seat(Vector3(-1.45, 0.35, 0), -PI / 2, false)
	seat(Vector3(1.45, 0.35, 0), PI / 2, true)
	cylinder(self, Vector3(0, 0.9, 0), 0.10, 1.2, "7d8fac")
	cylinder(self, Vector3(0, 0.38, 0), 0.5, 0.1, "384465")
	for side in [-1, 1]:
		var monitor := box(self, Vector3(side * 0.17, 1.72, 0), Vector3(0.10, 0.48, 0.72), "090e1f")
		monitor.rotation.z = side * 0.15
		box(self, Vector3(side * 0.23, 1.74, 0), Vector3(0.012, 0.38, 0.59), "506da8").material_override = mat("647ccb", true)
	camera = Camera3D.new()
	camera.fov = 49
	add_child(camera)
	camera.position = Vector3(9.5, 5.4, 12)
	camera.look_at(Vector3(0, 1.25, 0))
	camera.current = true

func seat(pos: Vector3, angle: float, contestant: bool) -> void:
	var root := Node3D.new()
	add_child(root)
	root.position = pos
	root.rotation.y = angle
	cylinder(root, Vector3(0, 0.06, 0), 0.40, 0.10, "77819e")
	cylinder(root, Vector3(0, 0.51, 0), 0.07, 0.88, "8596b1")
	box(root, Vector3(0, 1.0, 0), Vector3(0.75, 0.15, 0.66), "121831")
	box(root, Vector3(0, 1.40, 0.29), Vector3(0.70, 0.72, 0.12), "17233e")
	for x in [-0.43, 0.43]:
		rod(root, Vector3(x, 1.02, 0.15), Vector3(x, 1.38, 0.15), 0.035, "8d9cb5")
		box(root, Vector3(x, 1.4, -0.02), Vector3(0.12, 0.08, 0.5), "26314e")
	if contestant: contestant_root = root
	create_person(root, contestant)

func create_person(root: Node3D, contestant: bool) -> void:
	var person := Node3D.new()
	root.add_child(person)
	people.append(person)
	var skin: String = ["bc8969", "d8ad8b", "795744"][character_index] if contestant else "d8b395"
	var suit: String = ["385984", "843f63", "38756f"][character_index] if contestant else "26314a"
	sphere(person, Vector3(0, 1.49, 0.04), Vector3(0.64, 0.84, 0.4), suit)
	box(person, Vector3(0, 1.64, -0.165), Vector3(0.17, 0.38, 0.06), "e7e6ef")
	box(person, Vector3(0, 1.58, -0.204), Vector3(0.052, 0.30, 0.025), "303251")
	cylinder(person, Vector3(0, 1.98, 0), 0.09, 0.2, skin)
	sphere(person, Vector3(0, 2.19, 0), Vector3(0.37, 0.47, 0.37), skin)
	sphere(person, Vector3(0, 2.35, 0.035), Vector3(0.39, 0.22, 0.36), ["342934", "211f2a", "251e21"][character_index] if contestant else "55505a")
	sphere(person, Vector3(0, 2.19, -0.19), Vector3(0.08, 0.10, 0.075), skin)
	for x in [-0.079, 0.079]:
		sphere(person, Vector3(x, 2.23, -0.165), Vector3(0.055, 0.032, 0.025), "ede9e2")
		sphere(person, Vector3(x, 2.23, -0.181), Vector3(0.025, 0.028, 0.016), "292739")
		rod(person, Vector3(x - 0.033, 2.267, -0.158), Vector3(x + 0.025, 2.275, -0.16), 0.012, "39303a")
		sphere(person, Vector3(sign(x) * 0.184, 2.18, 0), Vector3(0.065, 0.10, 0.068), skin)
	rod(person, Vector3(-0.052, 2.105, -0.153), Vector3(0.052, 2.105, -0.153), 0.011, "815652")
	for side in [-1, 1]:
		var lapel := box(person, Vector3(side * 0.11, 1.73, -0.165), Vector3(0.074, 0.26, 0.045), "d2d6e2")
		lapel.rotation.z = side * 0.25
	if contestant and character_index == 1:
		for side in [-1, 1]:
			sphere(person, Vector3(side * 0.165, 2.22, 0.048), Vector3(0.15, 0.43, 0.25), "211f2a")
	if contestant and character_index == 2:
		for side in [-1, 1]:
			box(person, Vector3(side * 0.084, 2.23, -0.185), Vector3(0.12, 0.07, 0.016), "ac9873")
			sphere(person, Vector3(side * 0.084, 2.23, -0.199), Vector3(0.085, 0.044, 0.012), "303544")
	for side in [-1, 1]:
		var shoulder := Vector3(side * 0.30, 1.79, 0.04)
		var elbow := Vector3(side * 0.36, 1.38, -0.04)
		var wrist := Vector3(side * 0.25, 1.28, -0.44)
		rod(person, shoulder, elbow, 0.10, suit)
		rod(person, elbow, wrist, 0.085, suit)
		sphere(person, wrist, Vector3(0.14, 0.10, 0.20), skin)
		var knee := Vector3(side * 0.2, 0.98, -0.58)
		var ankle := Vector3(side * 0.2, 0.23, -0.55)
		rod(person, Vector3(side * 0.18, 1.05, 0), knee, 0.14, suit)
		rod(person, knee, ankle, 0.105, suit)
		sphere(person, ankle + Vector3(0, -0.09, -0.12), Vector3(0.23, 0.18, 0.43), "131824")

func set_character(index: int) -> void:
	character_index = index
	if contestant_root == null: return
	if people.size() > 1:
		var old: Node3D = people.pop_back()
		old.get_parent().remove_child(old)
		old.queue_free()
	create_person(contestant_root, true)

func set_mood(value: String) -> void:
	stage_state = value
	mood = Color("ffbd68") if value == "locked" else Color("72deb6") if value == "correct" else Color("ef6d8d") if value == "wrong" else Color("a39dff")

func cycle_camera() -> void:
	if cinematic: return
	var shots := ["wide", "contestant", "host"]
	shot = shots[(shots.find(shot) + 1) % shots.size()]

func _process(delta: float) -> void:
	time += delta
	var target := Vector3(4.5, 3.5, 8.8)
	var focus := Vector3(0, 0.45, 0)
	var offset := 1.0
	if cinematic:
		target = Vector3(-2.8, 2.9, 5.0)
		focus = Vector3(1.45, 1.9, 0)
		offset = -3.15
	elif shot == "contestant":
		target = Vector3(-1.3, 2.8, 4.2)
		focus = Vector3(1.45, 1.95, 0)
		offset = 0.75
	elif shot == "host":
		target = Vector3(1.3, 2.8, 4.2)
		focus = Vector3(-1.45, 1.95, 0)
		offset = 0.75
	if not reduced_motion: target.x += sin(time * 0.12) * 0.07
	var blend := 1.0 if reduced_motion else minf(delta * 2.4, 1.0)
	camera.position = camera.position.lerp(target, blend)
	camera.h_offset = lerpf(camera.h_offset, offset, blend)
	var facing := camera.global_transform.looking_at(focus, Vector3.UP).basis.get_rotation_quaternion()
	camera.quaternion = camera.quaternion.slerp(facing, blend)
	fill.light_color = fill.light_color.lerp(mood, 1.0 if reduced_motion else minf(delta * 2, 1.0))
	fill.light_energy = lerpf(fill.light_energy, 0.6 if stage_state == "locked" else 1.5, blend)
	for spot in spots:
		spot.light_energy = lerpf(spot.light_energy, 4.0 if stage_state == "locked" else 3.0, blend)
	for i in range(people.size()):
		people[i].rotation.x = 0.0 if reduced_motion else sin(time * 1.35 + i * 2) * 0.008
