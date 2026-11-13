class_name Road
extends Node3D


@export var road_name: String
@export_range(-180, 180, 60) var road_angle: int
@export var road_next_coords: Vector3i = Vector3i(1, 0, 0)
@export var road_coords_blocked: Array[Vector3i] = [
    Vector3i(0, 0, 0),
]
@export var place_dist_sings_before: bool = false
@export var has_dist_signs: bool = false
@export var dist_sign_positions: Array[Vector3] = []

const DIST_SIGN_SCENE_UIDS: Array[String] = [
    "uid://c1nwpj6vtmfdo", # distance_sign_50.tscn
    "uid://dragxi8ceupd4", # distance_sign_100.tscn
    "uid://c1fo38lcjakf0", # distance_sign_150.tscn
    "uid://dtlv7sjjng21c", # distance_sign_200.tscn
]


func place_dist_signs(start: int, gap: int, left: bool, signs_placed: int) -> Array[int]:
    var road: Node3D = get_child(0)
    while start < dist_sign_positions.size():
        var dist_sign_scene: PackedScene = load(DIST_SIGN_SCENE_UIDS.get(signs_placed if signs_placed < DIST_SIGN_SCENE_UIDS.size() else 0))
        var dist_sign: Node3D = dist_sign_scene.instantiate()
        var dist_sign_position = dist_sign_positions.get(start)
        road.add_child(dist_sign)
        dist_sign.position.x = -dist_sign_position.x if left else dist_sign_position.x
        dist_sign.position.y = dist_sign_position.y
        dist_sign.position.z = dist_sign_position.z
        start += gap
        signs_placed += 1
    start -= dist_sign_positions.size()
    return [start, signs_placed]
