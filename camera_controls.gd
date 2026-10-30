extends Camera3D


func _process(delta: float) -> void:
    var look_input: float = Input.get_axis("look_left", "look_right")
    if not is_zero_approx(look_input):
        transform = transform.rotated(Vector3.UP, look_input * PI * delta)
