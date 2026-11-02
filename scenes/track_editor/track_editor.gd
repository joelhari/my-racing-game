extends Node3D


@export var grid_size: float = 8.0
@export var camera_speed: float = 50.0

@onready var camera: Camera3D = $Camera3D
@onready var track: Node3D = $Track

var roads: Array[PackedScene] = [
    preload("res://objects/roads/road_straight.tscn"),
    preload("res://objects/roads/road_curve_left.tscn"),
    preload("res://objects/roads/road_curve_right.tscn"),
]

var start_finish_line_scene = preload("res://objects/timing/start_finish_line.tscn")

var cursor_coordinates: Vector2i = Vector2i.ZERO
var cursor_rotation: int = 0
var selected_road_idx: int = 0
var sqrt_three: float = sqrt(3)
var camera_height: float = 4.0
var camera_target_position: Vector3 = Vector3(0.0, camera_height, 0.0)

var rotation_to_next_coords_map: Dictionary[int, Vector2i] = {
    0: Vector2i(1, 0),
    60: Vector2i(1, -1),
    120: Vector2i(0, -1),
    180: Vector2i(-1, 0),
    240: Vector2i(-1, 1),
    300: Vector2i(0, 1)
}


func on_select_road(idx: int) -> void:
    selected_road_idx = idx


func _ready() -> void:
    for road in roads:
        assert(road.can_instantiate())
    _place_start_finish_line_at_cursor()
    _place_selected_road_at_cursor()


func _process(delta: float) -> void:
    camera.position = camera.position.move_toward(
        camera_target_position, camera_speed * delta)


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("menu_left"):
        pass
    elif event.is_action_pressed("menu_right"):
        pass
    elif event.is_action_pressed("menu_up"):
        pass
    elif event.is_action_pressed("menu_down"):
        pass
    elif event.is_action_pressed("menu_confirm"):
        _place_selected_road_at_cursor()
    elif event.is_action_pressed("menu_cancel"):
        pass
        #var viewport = camera.get_viewport()
        #var img = viewport.get_texture().get_image()
        #img.save_png('res://road_curve_left.png')


func _place_start_finish_line_at_cursor() -> void:
    var sf_line: Node3D = start_finish_line_scene.instantiate()
    track.add_child(sf_line)
    sf_line.global_position = _get_world_coordinates(cursor_coordinates)
    sf_line.global_rotation = Vector3(0.0, cursor_rotation + PI/2.0, 0.0)


func _place_selected_road_at_cursor() -> void:
    var road: Road = roads.get(selected_road_idx).instantiate()
    track.add_child(road)
    road.global_position = _get_world_coordinates(cursor_coordinates)
    road.global_rotation = Vector3(0.0, deg_to_rad(cursor_rotation), 0.0)
    _update_cursor_rotation(road.road_angle)
    _update_cursor_coordinates()
    _move_camera_to_cursor()


func _update_cursor_rotation(road_angle: int) -> void:
    cursor_rotation += road_angle
    if cursor_rotation < 0:
        cursor_rotation += 360
    elif cursor_rotation > 359:
        cursor_rotation -= 360


func _update_cursor_coordinates() -> void:
    cursor_coordinates += rotation_to_next_coords_map.get(int(cursor_rotation))


func _move_camera_to_cursor() -> void:
    camera_target_position = _get_world_coordinates(cursor_coordinates)
    camera_target_position.y = camera_height


func _get_world_coordinates(coordinates: Vector2i) -> Vector3:
    var world_coordinates: Vector3 = Vector3.ZERO
    world_coordinates.x = (coordinates.x + coordinates.y / 2.0) * grid_size * sqrt_three
    world_coordinates.z = coordinates.y * 1.5 * grid_size
    return world_coordinates
