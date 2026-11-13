extends Node3D


@export var camera_speed: float = 50.0

@onready var camera: Camera3D = $Camera3D
@onready var track: Node3D = $Track

var road_scenes: Array[PackedScene] = [
    preload("uid://bx5ti6rwkjlh1"), # road_straight.tscn
    preload("uid://btp6wjgnb15e0"), # road_curve_left.tscn
    preload("uid://c2u52k3wlfhst"), # road_curve_right.tscn
    preload("uid://df0t1rv1jjebp"), # road_curve_left_wide.tscn
    preload("uid://72aeutt6a8d7"),  # road_curve_right_wide.tscn
    preload("uid://duflxn7t5dwr5"), # road_straight_up.tscn
    preload("uid://yj6fgmguhni0"),  # road_straight_down.tscn
    preload("uid://bpenkpn6cmci7"), # road_hairpin_left.tscn
    preload("uid://b82573xurgk0v"), # road_hairpin_right.tscn
]
var roads_placed: Dictionary[int, Road] = {}
var roads_placed_stack: Array[int] = []
var coords_blocked: Dictionary[int, bool] = {}
var location_blocked: bool = false
var start_finish_line: StartFinishLine

var start_finish_line_scene = preload("res://objects/timing/start_finish_line.tscn")

var MAIN_MENU_SCENE_UID: String = ""
var MAIN_MENU_UI_SCENE_UID: String = "uid://c57vu5s1u5v7t"

var cursor_coordinates: Vector3i = Vector3i(
    TrackEditorUtils.hex_coordinates_offset.x,
    TrackEditorUtils.hex_coordinates_offset.y,
    TrackEditorUtils.hex_coordinates_offset.z)
var cursor_rotation: int = 0
var selected_road_idx: int = 0
var camera_height: float = 100
var camera_target_position: Vector3 = Vector3(0.0, camera_height, 0.0)

var storage_service: StorageService
var loaded_track_uid: int = -1
var track_meta_data: Dictionary = {}
var ui_scene: Control


func on_select_road(idx: int) -> void:
    _place_road_at_cursor(idx)


func on_save_track(track_name: String) -> void:
    _save_track(track_name)


func pass_args(args: Array) -> void:
    assert(args.size() == 1)
    assert(args.get(0) is int)
    _load_saved_track(args.get(0))


func connect_signals(ui_scene_: Control) -> void:
    assert(ui_scene_ != null)
    ui_scene = ui_scene_
    if ui_scene.has_signal("select_road"):
        ui_scene.select_road.connect(on_select_road)
    if ui_scene.has_signal("save_track"):
        ui_scene.save_track.connect(on_save_track)


func _ready() -> void:
    for road_scene in road_scenes:
        assert(road_scene.can_instantiate())
    
    storage_service = StorageService.new()
    _place_start_finish_line_at_cursor()
    _place_road_at_cursor(0)


func _process(delta: float) -> void:
    camera.position = camera.position.move_toward(
        camera_target_position, camera_speed * delta)


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        Global.game_controller.change_ui_scene(MAIN_MENU_UI_SCENE_UID)
        Global.game_controller.change_3d_scene(MAIN_MENU_SCENE_UID)


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
        pass
    elif event.is_action_pressed("menu_cancel"):
        _remove_last_placed_road()


func _save_track(track_name: String) -> void:
        storage_service.save_track(
            track_name, start_finish_line, roads_placed,
            roads_placed_stack, coords_blocked, loaded_track_uid)


func _load_saved_track(uid: int) -> void:
    loaded_track_uid = uid
    var remove_roads: Array[Node] = track.get_children()
    
    var res: Array = storage_service.load_track(uid, track)
    if not res or res.size() != 5:
        print("Error loading saved track!")
        return
    
    for node in remove_roads:
        node.queue_free()
    
    track_meta_data = res.get(0)
    start_finish_line = res.get(1)
    roads_placed = res.get(2)
    roads_placed_stack = res.get(3)
    coords_blocked = res.get(4)

    var location_id: int = roads_placed_stack.back()
    if location_id:
        var hex_coords: Vector3i = TrackEditorUtils.location_id_to_hex_coordinates(location_id)
        var road: Road = roads_placed.get(location_id)
        _set_cursor_coordinates(hex_coords)
        _set_cursor_rotation(int(round(road.rotation_degrees.y)))
        _update_cursor_coordinates(road)
        _update_cursor_rotation(road.road_angle)
        _move_camera_to_cursor()
    
    if track_meta_data and track_meta_data.has("name"):
        ui_scene.set_track_name_input_value(track_meta_data.get("name"))


func _place_start_finish_line_at_cursor() -> void:
    start_finish_line = start_finish_line_scene.instantiate()
    track.add_child(start_finish_line)
    start_finish_line.global_position = TrackEditorUtils.hex_coords_to_world_coords(cursor_coordinates)
    start_finish_line.global_rotation = Vector3(0.0, cursor_rotation + PI/2.0, 0.0)


func _place_road_at_cursor(road_idx: int) -> void:
    var road: Road = road_scenes.get(road_idx).instantiate()
    
    if not _block_coords_for_road(road, cursor_coordinates, cursor_rotation):
        road.queue_free()
        return
    
    track.add_child(road)
    road.global_position = TrackEditorUtils.hex_coords_to_world_coords(cursor_coordinates)
    road.global_rotation = Vector3(0.0, deg_to_rad(cursor_rotation), 0.0)
    _add_road_to_placed_roads(road, cursor_coordinates)
    _update_cursor_coordinates(road)
    _update_cursor_rotation(road.road_angle)
    _move_camera_to_cursor()
    

func _remove_last_placed_road() -> void:
    var road: Road = _pop_road_from_placed_roads()
    if not road:
        print("No road to remove!")
        return
    
    _update_cursor_rotation(-road.road_angle)
    _update_cursor_coordinates(road, false)
    _remove_coords_blocked_for_road(road, cursor_coordinates, cursor_rotation)
    _move_camera_to_cursor()
    
    road.queue_free()


func _add_road_to_placed_roads(road: Road, hex_coords: Vector3i) -> void:
    var location_id: int = TrackEditorUtils.hex_coordinates_to_location_id(hex_coords)
    assert(not roads_placed.has(location_id))
    roads_placed.set(location_id, road)
    roads_placed_stack.push_back(location_id)


func _block_coords_for_road(
    road: Road,
    hex_coords: Vector3i,
    rotation_deg: int
) -> bool:
    var coords_to_block: Array[int] = []
    var rotate_clock_wise: bool = rotation_deg < 0
    var rotate_steps: int = absi(rotation_deg)/60
    for block in road.road_coords_blocked:
        var coords: Vector3i = TrackEditorUtils.rotate_hex_coords_around_origin(
            block, rotate_clock_wise, rotate_steps)
        coords += hex_coords
        var location_id: int = TrackEditorUtils.hex_coordinates_to_location_id(coords)
        if coords_blocked.has(location_id):
            return false
        coords_to_block.append(location_id)
    for loc_id in coords_to_block:
        coords_blocked.set(loc_id, true)
    return true


func _pop_road_from_placed_roads() -> Road:
    if roads_placed_stack.size() <= 1:
        return null

    var location_id: int = roads_placed_stack.pop_back()
    assert(roads_placed.has(location_id))
    var road: Road = roads_placed.get(location_id)
    roads_placed.erase(location_id)
    return road


func _remove_coords_blocked_for_road(
    road: Road,
    hex_coords: Vector3i,
    rotation_deg: int
) -> void:
    var rotate_clock_wise: bool = rotation_deg < 0
    var rotate_steps: int = absi(rotation_deg)/60
    for block in road.road_coords_blocked:
        var coords: Vector3i = TrackEditorUtils.rotate_hex_coords_around_origin(
            block, rotate_clock_wise, rotate_steps)
        coords += hex_coords
        var location_id: int = TrackEditorUtils.hex_coordinates_to_location_id(coords)
        if not coords_blocked.erase(location_id):
            print("Could not remove location_id %d from blocked coords." % location_id)


func _update_cursor_coordinates(road: Road, forward: bool = true) -> void:
    var rotate_clock_wise: bool = cursor_rotation < 0
    var rotate_steps: int = absi(cursor_rotation)/60
    var next_coords = TrackEditorUtils.rotate_hex_coords_around_origin(
            road.road_next_coords, rotate_clock_wise, rotate_steps)
    cursor_coordinates += next_coords if forward else -next_coords


func _set_cursor_coordinates(hex_coords: Vector3i) -> void:
    cursor_coordinates = hex_coords


func _update_cursor_rotation(road_angle: int) -> void:
    _set_cursor_rotation(cursor_rotation + road_angle)


func _set_cursor_rotation(rotation_deg: int) -> void:
    cursor_rotation = rotation_deg
    if cursor_rotation < 0:
        cursor_rotation += 360
    elif cursor_rotation >= 360:
        cursor_rotation -= 360


func _is_location_blocked(hex_coords: Vector3i) -> bool:
    var location_id: int = TrackEditorUtils.hex_coordinates_to_location_id(hex_coords)
    return roads_placed.has(location_id)


func _move_camera_to_cursor() -> void:
    camera_target_position = TrackEditorUtils.hex_coords_to_world_coords(cursor_coordinates)
    camera_target_position.y = camera_height
