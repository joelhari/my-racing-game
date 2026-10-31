extends Camera3D


@export var look_at_node: Node3D

var speed: float = 10.0
var acceleration: float = 10.0
var distance: float = 4.0


func _physics_process(_delta: float) -> void:
    look_at(look_at_node.global_position, Vector3.UP)
    var move: Vector3 = look_at_node.global_position - global_position
    var dist: Vector3 = move.normalized() * distance
    position += Vector3(move.x - dist.x, 0, move.z - dist.z)
