extends Area

export(NodePath) var lance
export(float) var h_limit
export(float) var v_limit

# TODO: deal with limiting targeting to one side

var _lance:Spatial
var _target
var _h_radians
var _v_radians
var _bike

func _ready():
	_lance = get_node(lance) as Spatial
	_h_radians = deg2rad(h_limit)
	_v_radians = deg2rad(v_limit)
	_bike = get_parent() as Spatial
	pass

func _physics_process(delta):
	if _target != null:
		var dangle:Vector3 = (_lance.global_transform.origin - _target.global_transform.origin).normalized()
		var basis_x = -dangle.project(_bike.global_transform.basis.x)
		var basis_z = -dangle.project(_bike.global_transform.basis.z)
		var basis_y = -dangle.project(_bike.global_transform.basis.y)
		
		var horiz_angle = (basis_x + basis_z).normalized().angle_to(_bike.global_transform.basis.z)
		var vert_angle = (basis_z + basis_y).normalized().angle_to(_bike.global_transform.basis.z)
		
		if (horiz_angle <= _h_radians) && (vert_angle <= _v_radians):
			look_at_lerped(dangle, 0.2)
		else:
			look_at_lerped(-_bike.global_transform.basis.z, 0.2)
	else:
		look_at_lerped(-_bike.global_transform.basis.z, 0.2)

func _on_LanceTargeting_body_entered(body):
	if !(body is StaticBody) && get_parent() != body && body.get_parent() != _lance:
		_target = body as Spatial

func _on_LanceTargeting_body_exited(body):
	if _target == body:
		_target = null

func look_at_lerped(direction, amt):
	var forward = _lance.global_transform.basis.z.linear_interpolate(direction, amt).normalized()
	var right = forward.cross(_lance.global_transform.basis.y)
	var up = -forward.cross(right)
	
	var basis = Basis(right, up, forward)
	_lance.global_transform.basis = basis.orthonormalized()
	
	pass