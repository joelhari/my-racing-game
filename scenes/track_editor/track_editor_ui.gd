extends Control


@onready var track_name_input: LineEdit = $HBoxContainer/TrackNameInput

signal select_road
signal save_track


func set_track_name_input_value(track_name: String) -> void:
    track_name_input.text = track_name


func _on_road_select_pressed(road_select: RoadSelect) -> void:
    select_road.emit(road_select.road_scene_idx)


func _on_save_button_pressed() -> void:
    if not track_name_input.text:
        return
    save_track.emit(track_name_input.text)
