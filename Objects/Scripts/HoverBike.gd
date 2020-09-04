extends KinematicBody

export(float) var turning_speed
export(float) var thrust
export(float) var top_speed
export(float) var inertial_damping
export(float) var burst_speed
export(float) var burst_time
export(float) var local_gravity
export(float) var float_height
export(float) var bob_amount
export(float) var bob_thresh
export(NodePath) var bike_path
export(Curve) var curve : Curve

var current_velocity = Vector3.ZERO
var hover_points = []

var _current_speed = 0.0
var _previous_speed = 0.0

var _hovering_on_floor = false
var _hover_normals = []
var _hover_distance = 0.0
var bike : Spatial

var sin_timer = 0.0

var throttle = 0.0
var thrust_vector = Vector2.ZERO
var steer_vector = Vector2.ZERO

var use_surface_gravity = false
var surface_grav_tracker = 0

# TODO
# Controls (thrust, left, right)
# Physics (collision with other bikes)
# Network???
# Allow for network or AI control

# NOTES:
# A McLaren has an acceleration of ~9 m/s^2

func _ready():
	current_velocity = Vector3.ZERO
	sin_timer = 0.0
	bike = get_node(bike_path)
	
	throttle = 0.0
	thrust_vector = Vector2.ZERO
	steer_vector = Vector2.ZERO
	
	# Setup raycasts for hover calcs
	for node in get_children():
		if node is RayCast and node.get_name().begins_with('OrientationCast'):
			hover_points.push_back(node)
			_hover_normals.push_back(Vector3.UP)

func _process(delta):
	pass

func _physics_process(delta):
	_previous_speed = _current_speed
	set_hovering_on_floor()
	sin_timer = (sin_timer + delta)
	if sin_timer > 2 * PI:
		sin_timer = sin_timer - (2 * PI)
	
	handle_floaters(delta)
	rotate_object_local(Vector3.UP, steer_vector.x * turning_speed * delta)
	
	process_thrust(delta)
	handle_bike_tilt()
	
	if use_surface_gravity == true and _hovering_on_floor:
		current_velocity += local_gravity * delta * global_transform.basis.y
	else:
		current_velocity.y += local_gravity * delta
		pass
	
	current_velocity = move_and_slide(current_velocity, Vector3.UP)
	_current_speed = current_velocity.length()
	
	if _previous_speed >= bob_thresh and _current_speed < bob_thresh:
		sin_timer = 1.5 * PI
	
	if _hovering_on_floor and _hover_distance < float_height:
		var tmp_float = float_height
		if (_current_speed < bob_thresh):
			tmp_float = float_height - (1 + sin(sin_timer)) * bob_amount * 0.5
		var diff = tmp_float - _hover_distance
		var excess_v = current_velocity.project(transform.basis.y)
		current_velocity -= excess_v * 0.3
		move_and_collide(transform.basis.y * diff * 0.15)
	
	pass

func handle_bike_tilt():
	if bike == null:
		return
	
	bike.transform.basis = Basis(Vector3.RIGHT, Vector3.UP, -Vector3.FORWARD)
	var tilt = current_velocity.normalized().dot(transform.basis.x.normalized())
	tilt *= curve.interpolate_baked(min(_current_speed, top_speed) / top_speed)
	
	bike.rotate_object_local(Vector3.FORWARD, -PI * 0.25 * tilt)
	
	pass

func set_hovering_on_floor():
	_hovering_on_floor = false
	if is_on_floor():
		_hovering_on_floor = true
	else:
		if $HoverCast.is_colliding():
			var point = $HoverCast.get_collision_point()
			var length = ($HoverCast.global_transform.origin - point).length()
			_hover_distance = length
			_hovering_on_floor = true
		
		for index in range(hover_points.size()):
			var cast = hover_points[index] as RayCast
			if cast.is_colliding():
				var point = cast.get_collision_point()
				_hover_normals[index] = cast.get_collision_normal()
				_hovering_on_floor = true
	
	if _hovering_on_floor == false:
		for index in range(hover_points.size()):
			_hover_normals[index] = Vector3.UP

func handle_floaters(delta):
	if _hovering_on_floor == true:
		var avg_normal = Vector3.ZERO
		for normal in _hover_normals:
			avg_normal += normal
		avg_normal = avg_normal * (1.0 / _hover_normals.size())
		
		var lerp_speed = (max(current_velocity.length(), top_speed) / top_speed) * 10
		avg_normal = transform.basis.y.linear_interpolate(avg_normal, (5 + lerp_speed) * delta).normalized()
		
		var right = avg_normal.cross(transform.basis.z)
		var forward = -avg_normal.cross(right)
		
		var basis = Basis(right, avg_normal, forward)
		
		transform.basis = basis.orthonormalized()
	else:
		var up = transform.basis.y.linear_interpolate(Vector3.UP, delta * 5).normalized()
		var right = up.cross(transform.basis.z)
		var forward = -up.cross(right)
		
		var basis = Basis(right, up, forward)
		transform.basis = basis.orthonormalized()
		pass

func process_thrust(delta):
	if _hovering_on_floor == true:
		var stopping_power = 1 - abs((current_velocity.normalized().dot(transform.basis.z.normalized())))
		stopping_power *= (1 - abs(thrust_vector.x))
		current_velocity -= stopping_power * inertial_damping * current_velocity.normalized() * delta
	
	var current_thrust = ((transform.basis.z * thrust_vector.y) + (transform.basis.x * thrust_vector.x)) * thrust * delta
	var extra_velocity = Vector3.ZERO
	
	var thrust_velocity = current_velocity
	
	if current_velocity.length() > top_speed:
		thrust_velocity = current_velocity.normalized() * top_speed
		extra_velocity = current_velocity - thrust_velocity
	
	thrust_velocity += current_thrust
	if thrust_velocity.length() > top_speed:
		thrust_velocity = thrust_velocity.normalized() * top_speed
	
	current_velocity = thrust_velocity + extra_velocity

func surface_gravity(enable):
	if (enable):
		surface_grav_tracker += 1
	else:
		surface_grav_tracker -= 1
	
	surface_grav_tracker = max(surface_grav_tracker, 0)
	use_surface_gravity = surface_grav_tracker > 0

func boost_thrust(boost_velocity):
	current_velocity += boost_velocity

func apply_brake(amount):
	current_velocity -= current_velocity.normalized() * min(current_velocity.length(), amount)

func limit_speed(speed_limit):
	if current_velocity.length() > speed_limit:
		current_velocity = current_velocity.normalized() * speed_limit