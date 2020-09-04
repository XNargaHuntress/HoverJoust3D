extends Spatial

export(NodePath) var target

var target_node:Spatial

func _ready():
	target_node = get_node(target)
	pass

func _physics_process(delta):
	look_at(target_node.global_transform.origin, Vector3.UP)