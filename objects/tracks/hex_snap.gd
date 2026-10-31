
@tool
extends Node3D

@export var hex_size: float = 8.0

func _process(_delta: float) -> void:
    if not Engine.is_editor_hint():
        return

    for child in get_children():
        if child is not Node3D:
            continue

        var pos: Vector3 = child.position
        var snapped := snap_to_hex(Vector2(pos.x, pos.z))

        if Vector2(pos.x, pos.z).distance_to(snapped) > 0.001:
            child.position = Vector3(
                snapped.x,
                pos.y,
                snapped.y
            )


func snap_to_hex(point: Vector2) -> Vector2:
    # Pointy-top hexagons
    var q := (sqrt(3.0) / 3.0 * point.x - point.y / 3.0) / hex_size
    var r := (2.0 / 3.0 * point.y) / hex_size

    # Round cube coordinates
    var x := roundf(q)
    var z := roundf(r)
    var y := roundf(-q - r)

    var dx := absf(x - q)
    var dy := absf(y + q + r)
    var dz := absf(z - r)

    if dx > dy and dx > dz:
        x = -y - z
    elif dy > dz:
        y = -x - z
    else:
        z = -x - y

    return Vector2(
        hex_size * sqrt(3.0) * (x + z / 2.0),
        hex_size * 1.5 * z
    )
