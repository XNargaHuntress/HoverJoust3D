extends Control

class_name JoystickPanel

onready var left_stick: Joystick = $LeftStick
onready var right_stick: Joystick = $RightStick

func _ready():
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag or event is InputEventScreenTouch:
		if event.index == left_stick.touch_index:
			left_stick.update_stick(event)
		elif event.index == right_stick.touch_index:
			right_stick.update_stick(event)
		else:
			if event.position.x < rect_size.x * 0.5:
				if !left_stick.update_stick(event):
					right_stick.update_stick(event)
			if event.position.x > rect_size.x * 0.5:
				if !right_stick.update_stick(event):
					left_stick.update_stick(event)
	return

func get_axis(axis: String) -> Vector2:
	match axis.to_lower():
		"left", "left_stick":
			return left_stick.output
		"right", "right_stick":
			return right_stick.output
	return Vector2.ZERO