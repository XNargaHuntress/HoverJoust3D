extends Control

class_name Joystick

enum Stick_Mode { MOUSE, JOYSTICK }

export(Stick_Mode) var mode := Stick_Mode.JOYSTICK
export(bool) var stick_visible := true
export(float, 0, 1) var dead_zone := 0.2
export(float, 0, 2) var outer_range := 1.0
export(float, 0, 2) var nub_clamp := 0.7
export(float, 0, 1) var stick_size := 0.3

onready var stick_range := $Range
onready var stick_nub := $Nub

var output := Vector2.ZERO
var touch_index := -5

func _ready() -> void:
	set_stick_visibile(stick_visible)
	stick_range.visible = false
	stick_nub.visible = false
	
	# 1-frame trick to ensure sizes are correctly initialized
	yield(get_tree(), "idle_frame")
	
	set_stick_scale(stick_size)
	return

func set_stick_visibile(visible: bool) -> void:
	stick_visible = visible
	return

func set_stick_scale(scale: float) -> void:
	var min_dimension = min(rect_size.x, rect_size.y)
	var size = scale * min_dimension
	
	var stick_scale = size / stick_range.rect_size.x
	stick_range.rect_scale.x = stick_scale
	stick_range.rect_scale.y = stick_scale
	stick_nub.rect_scale.x = stick_scale
	stick_nub.rect_scale.y = stick_scale
	return

func update_stick(event: InputEvent) -> bool:
	if _ignore_event(event):
		return false
	
	output = _get_output(event)
	if event is InputEventScreenTouch:
		if !event.pressed:
			touch_index = -5
		else:
			touch_index = event.index
	
	if !stick_visible:
		return true
	
	var relative_position = _get_event_position(event)
	if event is InputEventScreenTouch:
		if !event.pressed:
			stick_range.visible = false
			stick_nub.visible = false
		else:
			stick_nub.visible = true
			if mode == Stick_Mode.JOYSTICK:
				stick_range.visible = true
			
			stick_range.rect_position = relative_position - (stick_range.rect_size * 0.5)
			stick_nub.rect_position = relative_position - (stick_nub.rect_size * 0.5)
	
	if event is InputEventScreenDrag:
		stick_nub.rect_position = relative_position - (stick_nub.rect_size * 0.5)
		
		if mode == Stick_Mode.JOYSTICK:
			var value = output
			value.y = -value.y
			if value.length() > 1:
				value = value.normalized()
			
			var center = stick_range.rect_position + stick_range.rect_size * 0.5 
			var length = stick_range.rect_size.x * 0.5 * stick_range.rect_scale.x
			var pos = length * nub_clamp * value + center - stick_nub.rect_size * 0.5
			stick_nub.rect_position = pos
	return true

func _get_output(event: InputEvent) -> Vector2:
	var value := Vector2.ZERO
	
	if event is InputEventScreenDrag or (event is InputEventScreenTouch and event.pressed):
		if mode == Stick_Mode.MOUSE:
			if event is InputEventScreenDrag:
				value = event.relative
		else:
			var diff = _get_event_position(event) - (stick_range.rect_position + stick_range.rect_size * 0.5)
			diff.y = -diff.y
			var scale = stick_range.rect_size.x * 0.5 * stick_range.rect_scale.x
			var dead_zone_test = diff.normalized() * min(1, diff.length() / scale)
			
			if dead_zone_test.length() > dead_zone:
				value = diff.normalized() * min(outer_range, diff.length() / (scale * nub_clamp))
	
	return value

func _ignore_event(event: InputEvent) -> bool:
	if event is InputEventScreenDrag:
		return event.index != touch_index
	elif event is InputEventScreenTouch:
		return touch_index >= 0 and event.index != touch_index
	
	return true

func _get_event_position(event: InputEvent) -> Vector2:
	return event.position - rect_position