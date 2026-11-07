class_name Road
extends Node3D


@export var road_name: String
@export_range(-60, 60, 60) var road_angle: int
@export var road_offset_coords: Dictionary[int, Vector3i] = {
    0: Vector3i(0, 0, 0),
    60: Vector3i(0, 0, 0),
    120: Vector3i(0, 0, 0),
    180: Vector3i(0, 0, 0),
    240: Vector3i(0, 0, 0),
    300: Vector3i(0, 0, 0)
}
@export var road_next_coords: Dictionary[int, Vector3i] = {
    0: Vector3i(1, 0, 0),
    60: Vector3i(1, 0, -1),
    120: Vector3i(0, 0, -1),
    180: Vector3i(-1, 0, 0),
    240: Vector3i(-1, 0, 1),
    300: Vector3i(0, 0, 1)
}
