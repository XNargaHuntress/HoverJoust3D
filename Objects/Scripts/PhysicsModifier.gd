extends Area
class_name PhysicsModifier

export(bool) var gravity_to_surface = false
export(float) var boost_thrust = 0.0
export(float) var brake_amount = 0.0
export(bool) var limit_speed = false
export(float) var speed_limit = 0.0

var limit_tracker = []

func _ready():
	self.connect('body_entered', self, '_on_body_entered')
	self.connect('body_exited', self, '_on_body_exited')
	pass

func _physics_process(delta):
	for body in limit_tracker:
		if limit_speed == true:
			body.limit_speed(speed_limit)

func _on_body_entered(body):
	if gravity_to_surface == true and body.has_method('surface_gravity'):
		body.surface_gravity(gravity_to_surface)
	
	if boost_thrust > 0.0 and body.has_method('boost_thrust'):
		body.boost_thrust(boost_thrust * global_transform.basis.z)
	
	if brake_amount > 0.0 and body.has_method('apply_brake'):
		body.apply_brake(brake_amount)
	
	if limit_speed == true and body.has_method('limit_speed'):
		limit_tracker.append(body)
		body.limit_speed(speed_limit)


func _on_body_exited(body):
	if gravity_to_surface == true and body.has_method('surface_gravity'):
		body.surface_gravity(false)
	
	if limit_speed == true and body.has_method('limit_speed'):
		limit_tracker.erase(body)
