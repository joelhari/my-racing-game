extends Control


signal select_road


func _on_road_select_pressed(road_select: RoadSelect) -> void:
    select_road.emit(road_select.road_scene_idx)
