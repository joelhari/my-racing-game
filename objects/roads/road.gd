class_name Road
extends Node3D


@export var road_name: String
@export_range(-180, 180, 60) var road_angle: int
@export var road_next_coords: Vector3i = Vector3i(1, 0, 0)
@export var road_coords_blocked: Array[Vector3i] = [
    Vector3i(0, 0, 0),
]
