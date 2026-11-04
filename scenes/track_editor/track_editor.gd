extends Node3D


@export var camera_speed: float = 50.0

@onready var camera: Camera3D = $Camera3D
@onready var track: Node3D = $Track

var road_scenes: Array[PackedScene] = [
    preload("res://objects/roads/road_straight.tscn"),
    preload("res://objects/roads/road_curve_left.tscn"),
    preload("res://objects/roads/road_curve_right.tscn"),
]
var roads_placed: Dictionary[int, Road] = {}
var roads_placed_stack: Array[int] = []
var location_blocked: bool = false
var start_finish_line: Node3D

var start_finish_line_scene = preload("res://objects/timing/start_finish_line.tscn")

var cursor_coordinates: Vector2i = Vector2i(
    TrackEditorUtils.hex_coordinates_offset.x,
    TrackEditorUtils.hex_coordinates_offset.y)
var cursor_rotation: int = 0
var selected_road_idx: int = 0
var camera_height: float = 4.0
var camera_target_position: Vector3 = Vector3(0.0, camera_height, 0.0)

var storage_service: StorageService

var rotation_to_next_coords_map: Dictionary[int, Vector2i] = {
    0: Vector2i(1, 0),
    60: Vector2i(1, -1),
    120: Vector2i(0, -1),
    180: Vector2i(-1, 0),
    240: Vector2i(-1, 1),
    300: Vector2i(0, 1)
}


func on_select_road(idx: int) -> void:
    _place_road_at_cursor(idx)


func _ready() -> void:
    for road_scene in road_scenes:
        assert(road_scene.can_instantiate())
    
    storage_service = StorageService.new()        
    _place_start_finish_line_at_cursor()
    _place_road_at_cursor(0)


func _process(delta: float) -> void:
    camera.position = camera.position.move_toward(
        camera_target_position, camera_speed * delta)


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("menu_left"):
        pass
    elif event.is_action_pressed("menu_right"):
        print(track.get_child_count())
        pass
    elif event.is_action_pressed("menu_up"):
        storage_service.save_track(start_finish_line, roads_placed, roads_placed_stack)
    elif event.is_action_pressed("menu_down"):
        _load_saved_track()
    elif event.is_action_pressed("menu_confirm"):
        pass
    elif event.is_action_pressed("menu_cancel"):
        _remove_last_placed_road()
        #var viewport = camera.get_viewport()
        #var img = viewport.get_texture().get_image()
        #img.save_png('res://road_curve_left.png')


func _load_saved_track() -> void:
    var remove_roads: Array[Node] = track.get_children()
    
    var res: Array = storage_service.load_track(track)
    if not res or res.size() != 3:
        print("Error loading saved track!")
        return
    
    for node in remove_roads:
        node.queue_free()
    
    start_finish_line = res.get(0)
    roads_placed = res.get(1)
    roads_placed_stack = res.get(2)

    var location_id: int = roads_placed_stack.back()
    if location_id:
        var hex_coords: Vector2i = TrackEditorUtils.location_id_to_hex_coordinates(location_id)
        var road: Road = roads_placed.get(location_id)
        _set_cursor_coordinates(hex_coords)
        _set_cursor_rotation(int(round(road.rotation_degrees.y)))
        _update_cursor_rotation(road.road_angle)
        _update_cursor_coordinates()
        _move_camera_to_cursor()


func _place_start_finish_line_at_cursor() -> void:
    start_finish_line = start_finish_line_scene.instantiate()
    track.add_child(start_finish_line)
    start_finish_line.global_position = TrackEditorUtils.hex_coords_to_world_coords(cursor_coordinates)
    start_finish_line.global_rotation = Vector3(0.0, cursor_rotation + PI/2.0, 0.0)


func _place_road_at_cursor(road_idx: int) -> void:
    if location_blocked:
        return
    var road: Road = road_scenes.get(road_idx).instantiate()
    
    print(road_scenes.get(road_idx).resource_path)
    print(road.scene_file_path)
    
    track.add_child(road)
    road.global_position = TrackEditorUtils.hex_coords_to_world_coords(cursor_coordinates)
    road.global_rotation = Vector3(0.0, deg_to_rad(cursor_rotation), 0.0)
    _add_road_to_placed_roads(road, cursor_coordinates)
    _update_cursor_rotation(road.road_angle)
    _update_cursor_coordinates()
    _move_camera_to_cursor()
    

func _remove_last_placed_road() -> void:
    var res = _pop_road_from_placed_roads()
    if not res:
        print("No road to remove!")
        return
    
    var road: Road = res.get("road")
    var hex_coords: Vector2i = res.get("hex_coords")
    
    _set_cursor_coordinates(hex_coords)
    _update_cursor_rotation(-road.road_angle)
    _move_camera_to_cursor()
    
    road.queue_free()


func _add_road_to_placed_roads(road: Road, hex_coords: Vector2i) -> void:
    var location_id: int = TrackEditorUtils.hex_coordinates_to_location_id(hex_coords)
    assert(not roads_placed.has(location_id))
    roads_placed.set(location_id, road)
    roads_placed_stack.push_back(location_id)


func _pop_road_from_placed_roads() -> Dictionary:
    if roads_placed_stack.size() <= 1:
        return {}

    var location_id: int = roads_placed_stack.pop_back()
    assert(roads_placed.has(location_id))
    var hex_coords: Vector2i = TrackEditorUtils.location_id_to_hex_coordinates(location_id)
    var road: Road = roads_placed.get(location_id)
    roads_placed.erase(location_id)
    return {
        "road": road,
        "hex_coords": hex_coords
    }

func _update_cursor_rotation(road_angle: int) -> void:
    _set_cursor_rotation(cursor_rotation + road_angle)


func _set_cursor_rotation(rotation: int) -> void:
    cursor_rotation = rotation
    if cursor_rotation < 0:
        cursor_rotation += 360
    elif cursor_rotation > 359:
        cursor_rotation -= 360


func _update_cursor_coordinates() -> void:
    cursor_coordinates += rotation_to_next_coords_map.get(int(cursor_rotation))
    location_blocked = _is_location_blocked(cursor_coordinates)


func _set_cursor_coordinates(hex_coords: Vector2i) -> void:
    cursor_coordinates = hex_coords
    location_blocked = _is_location_blocked(cursor_coordinates)


func _is_location_blocked(hex_coords: Vector2i) -> bool:
    var location_id: int = TrackEditorUtils.hex_coordinates_to_location_id(hex_coords)
    return roads_placed.has(location_id)


func _move_camera_to_cursor() -> void:
    camera_target_position = TrackEditorUtils.hex_coords_to_world_coords(cursor_coordinates)
    camera_target_position.y = camera_height
