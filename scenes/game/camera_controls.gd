extends Node3D


@export var look_at_node: Node3D
@export var distance: float = 3.0
@export var height: float = 0.8

@onready var camera: Camera3D = $Camera3D


func _physics_process(_delta: float) -> void:
    _update_camera()


func _update_camera() -> void:
    look_at(look_at_node.global_position, Vector3.UP)
    var move: Vector3 = look_at_node.global_position - global_position
    var dist: Vector3 = move.normalized() * distance
    position += Vector3(move.x - dist.x, 0, move.z - dist.z)
    global_position.y = look_at_node.global_position.y + height
    
    var look_input: Vector3 = Vector3(
        Input.get_axis("look_left", "look_right"),
        0.0,
        Input.get_axis("look_forward", "look_back")
    )
    if is_zero_approx(look_input.x) and is_zero_approx(look_input.z):
        camera.position = Vector3.ZERO
        camera.rotation = Vector3.ZERO
    else:
        var rotate_angle: float = Vector3.FORWARD.signed_angle_to(
            look_input, Vector3.UP)
        var dir: Vector3 = Vector3(
            look_at_node.global_position.x - global_position.x,
            0.0,
            look_at_node.global_position.z - global_position.z
        ).rotated(Vector3.UP, rotate_angle)
        camera.global_position.x = look_at_node.global_position.x - dir.x
        camera.global_position.z = look_at_node.global_position.z - dir.z
        camera.look_at(look_at_node.global_position, Vector3.UP)
