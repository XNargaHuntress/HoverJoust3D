extends Node

export(NodePath) var hover_bike_path
export(NodePath) var controls_path

var hover_bike
var joysticks: JoystickPanel
var thrust_vector = Vector2.ZERO
var steer_vector = Vector2.ZERO
var throttle = 0.0

func _ready():
	hover_bike = get_node(hover_bike_path)
	joysticks = get_node(controls_path) as JoystickPanel
	thrust_vector = Vector2.ZERO
	steer_vector = Vector2.ZERO
	throttle = 0.0
	pass

func _physics_process(delta):
	#thrust_vector.y = Input.get_action_strength("ctrl_forward") - Input.get_action_strength("ctrl_backward")
	#thrust_vector.x = Input.get_action_strength("ctrl_left") - Input.get_action_strength("ctrl_right")
	#steer_vector.x = Input.get_action_strength("ctrl_steer_left") - Input.get_action_strength("ctrl_steer_right")
	
	thrust_vector = joysticks.get_axis("left");
	thrust_vector.x = -thrust_vector.x
	steer_vector.x = -joysticks.get_axis("right").x;
	
	if (thrust_vector.length() > 1):
		thrust_vector = thrust_vector.normalized()
	
	hover_bike.thrust_vector = thrust_vector
	hover_bike.steer_vector = steer_vector