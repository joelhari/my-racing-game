class_name StorageService
extends Object

# ----- Storage Service ------------------------------------------------------ #
#
# Track save file:
#     line 1: Meta data => Dictionary[String, any]
#     line 2: Start Finish Line => Dictionary[String, any]
#     line 3: Roads Placed => Dictionary[int, Array] = {
#                 location_id: [scene_file_path, rotation_deg_y]
#             }
#     line 4: Roads Placed Stack => Array[int] = [location_id, ...]
#     line 5: Coords Blocked => Dictionary[int, bool] = {
#                 location_id: true
#             }
#
# Tracks save file:
#     line 1: uid;track_name
#     line 2: uid;track_name
#     line 3: ...
#


var track_list_file_name: String = "user://tracklist.save"
var track_file_name: String = "user://%d.save"

var road_scenes: Dictionary[String, PackedScene] = {
    "res://objects/roads/road_straight.tscn": preload("res://objects/roads/road_straight.tscn"),
    "res://objects/roads/road_curve_left.tscn": preload("res://objects/roads/road_curve_left.tscn"),
    "res://objects/roads/road_curve_right.tscn": preload("res://objects/roads/road_curve_right.tscn"),
    "res://objects/roads/road_curve_left_wide.tscn": preload("res://objects/roads/road_curve_left_wide.tscn"),
    "res://objects/roads/road_curve_right_wide.tscn": preload("res://objects/roads/road_curve_right_wide.tscn"),
    "res://objects/roads/road_straight_up.tscn": preload("res://objects/roads/road_straight_up.tscn"),
    "res://objects/roads/road_straight_down.tscn": preload("res://objects/roads/road_straight_down.tscn"),
    "res://objects/roads/road_hairpin_left.tscn": preload("res://objects/roads/road_hairpin_left.tscn"),
    "res://objects/roads/road_hairpin_right.tscn": preload("res://objects/roads/road_hairpin_right.tscn"),
}


func load_track_list() -> Dictionary[int, String]:
    if not FileAccess.file_exists(track_list_file_name):
        return {}
    
    var save_file: FileAccess = FileAccess.open(
        track_list_file_name, FileAccess.READ)
    var track_list: Dictionary[int, String] = {}
    
    while save_file.get_position() < save_file.get_length():
        var track_str: String = save_file.get_line()
        var track_str_split = track_str.split(";")
        assert(track_str_split.size() == 2)
        
        track_list.set(
            int(track_str_split.get(0)),
            track_str_split.get(1))
    
    save_file.close()
    
    return track_list


func save_track(
    track_name: String,
    start_finish_line: Node3D,
    roads_placed: Dictionary[int, Road],
    roads_placed_stack: Array[int],
    coords_blocked: Dictionary[int, bool],
    uid: int = -1
) -> void:
    if uid < 0:
        uid = ResourceUID.create_id()
    
    var track_list_file: FileAccess
    if FileAccess.file_exists(track_list_file_name):
        track_list_file = FileAccess.open(
            track_list_file_name, FileAccess.READ_WRITE)
    else:
        track_list_file = FileAccess.open(
            track_list_file_name, FileAccess.WRITE)
    track_list_file.seek_end()
    track_list_file.store_line("%d;%s" % [uid, track_name])
    track_list_file.close()
    
    var file_name: String = track_file_name % uid
    var save_file: FileAccess = FileAccess.open(file_name, FileAccess.WRITE)
    
    var meta_data: Dictionary = {
        "name": track_name
    }
    save_file.store_line(JSON.stringify(meta_data))

    if start_finish_line.scene_file_path.is_empty():
        print("persistent node '%s' is not an instanced scene, skipped" % start_finish_line.name)
        return
    var start_finish_line_data: Dictionary = {
        "scene_file_path": start_finish_line.scene_file_path,
        "global_position_x": start_finish_line.global_position.x,
        "global_position_y": start_finish_line.global_position.y,
        "global_position_z": start_finish_line.global_position.z,
        "global_rotation_y": start_finish_line.global_rotation.y
    }
    save_file.store_line(JSON.stringify(start_finish_line_data))

    var placed_roads_data: Dictionary[int, Array] = {}
    for location_id in roads_placed:
        var road: Road = roads_placed.get(location_id)
        if road.scene_file_path.is_empty():
            print("persistent node '%s' is not an instanced scene, skipped" % road.name)
            continue
        placed_roads_data.set(
            location_id,
            [road.scene_file_path, int(round(road.rotation_degrees.y))])
    save_file.store_line(JSON.stringify(placed_roads_data))
    
    save_file.store_line(JSON.stringify(roads_placed_stack))
    
    var coords_blocked_data: Array[int] = coords_blocked.keys()
    save_file.store_line(JSON.stringify(coords_blocked_data))
    
    save_file.close()


func load_track(uid: int, track_node: Node3D) -> Array:
    var file_name: String = track_file_name % uid
    
    if not FileAccess.file_exists(file_name):
        return [] # Error! We don't have a save to load.
    
    var save_file: FileAccess = FileAccess.open(file_name, FileAccess.READ)

    # ----- Line 1: meta data
    var json_string: String = save_file.get_line()
    var json: JSON = JSON.new()
    var parse_result: Error = json.parse(json_string)
    if not parse_result == OK:
        print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
        return []
    
    var meta_data: Dictionary = json.data

    # ----- Line 2: start_finish_line
    json_string = save_file.get_line()
    json = JSON.new()
    parse_result = json.parse(json_string)
    if not parse_result == OK:
        print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
        return []
    
    var start_finish_line: Node3D = _load_start_finish_line(track_node, json)
    
    # ----- Line 3: roads_placed
    json_string = save_file.get_line()
    json = JSON.new()
    parse_result = json.parse(json_string)
    if not parse_result == OK:
        print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
        return []
    
    var roads_placed: Dictionary[int, Road] = _load_roads_placed(track_node, json)
    
    # ----- Line 4: roads_placed_stack
    json_string = save_file.get_line()
    json = JSON.new()
    parse_result = json.parse(json_string)
    if not parse_result == OK:
        print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
        return []

    var roads_placed_stack: Array[int] = _load_roads_placed_stack(json)

    # ----- Line 5: coords_blocked
    json_string = save_file.get_line()
    json = JSON.new()
    parse_result = json.parse(json_string)
    if not parse_result == OK:
        print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
        return []
    
    var coords_blocked: Dictionary[int, bool] = _load_coords_blocked(json)
    
    save_file.close()

    return [
        meta_data, start_finish_line, roads_placed,
        roads_placed_stack, coords_blocked
    ]


func _load_start_finish_line(track_node: Node3D, json: JSON) -> Node3D:
    var save_data: Dictionary = json.data
    
    var start_finish_line: Node3D = load(save_data.get("scene_file_path")).instantiate()
    track_node.add_child(start_finish_line)
    start_finish_line.global_position.x = float(save_data.get("global_position_x"))
    start_finish_line.global_position.y = float(save_data.get("global_position_y"))
    start_finish_line.global_position.z = float(save_data.get("global_position_z"))
    start_finish_line.global_rotation.y = float(save_data.get("global_rotation_y"))
    
    return start_finish_line


func _load_roads_placed(track_node: Node3D, json: JSON) -> Dictionary[int, Road]:
    var save_data: Dictionary = json.data
    var roads_placed: Dictionary[int, Road] = {}

    for location_id_str in save_data:
        var scene_file_path: String = save_data.get(location_id_str).get(0)
        var rotation_deg_y: int = save_data.get(location_id_str).get(1)
        
        var road: Road = road_scenes.get(scene_file_path).instantiate()
        track_node.add_child(road)
        road.global_rotation_degrees.y = rotation_deg_y
        road.global_position = TrackEditorUtils.hex_coords_to_world_coords(
            TrackEditorUtils.location_id_to_hex_coordinates(
                int(location_id_str)))
        
        roads_placed.set(int(location_id_str), road)
        
    return roads_placed


func _load_roads_placed_stack(json: JSON) -> Array[int]:
    var save_data: Array = json.data
    var roads_placed_stack: Array[int] = []
    
    for location_id_str in save_data:
        roads_placed_stack.append(int(location_id_str))
    
    return roads_placed_stack


func _load_coords_blocked(json: JSON) -> Dictionary[int, bool]:
    var save_data: Array = json.data
    var coords_blocked: Dictionary[int, bool] = {}
    
    for location_id_str in save_data:
        coords_blocked.set(int(location_id_str), true)
    
    return coords_blocked
