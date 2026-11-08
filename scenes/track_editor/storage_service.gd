class_name StorageService
extends Object

# ----- Storage Service ------------------------------------------------------ #
#
# Save file format:
#     line 1: Start Finish Line => Dictionary[String, any]
#     line 2: Roads Placed => Dictionary[int, Array] = {
#                 location_id: [scene_file_path, rotation_deg_y]
#             }
#     line 3: Roads Placed Stack => Array[int] = [location_id, ...]
#     line 4: Coords Blocked => Dictionary[int, bool] = {
#                 location_id: true
#             }



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


func save_track(
    start_finish_line: Node3D,
    roads_placed: Dictionary[int, Road],
    roads_placed_stack: Array[int],
    coords_blocked: Dictionary[int, bool]
) -> void:
    var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)

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


func load_track(track_node: Node3D) -> Array:
    if not FileAccess.file_exists("user://savegame.save"):
        return [] # Error! We don't have a save to load.
    
    var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)

    # ----- Line 1: start_finish_line
    var json_string = save_file.get_line()
    var json = JSON.new()
    var parse_result = json.parse(json_string)
    if not parse_result == OK:
        print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
        return []
    
    var start_finish_line: Node3D = _load_start_finish_line(track_node, json)
    
    # ----- Line 2: roads_placed
    json_string = save_file.get_line()
    json = JSON.new()
    parse_result = json.parse(json_string)
    if not parse_result == OK:
        print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
        return []
    
    var roads_placed: Dictionary[int, Road] = _load_roads_placed(track_node, json)
    
    # ----- Line 3: roads_placed_stack
    json_string = save_file.get_line()
    json = JSON.new()
    parse_result = json.parse(json_string)
    if not parse_result == OK:
        print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
        return []

    var roads_placed_stack: Array[int] = _load_roads_placed_stack(json)

    # ----- Line 4: coords_blocked
    json_string = save_file.get_line()
    json = JSON.new()
    parse_result = json.parse(json_string)
    if not parse_result == OK:
        print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
        return []
    
    var coords_blocked: Dictionary[int, bool] = _load_coords_blocked(json)

    return [start_finish_line, roads_placed, roads_placed_stack, coords_blocked]


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
