extends Control


var game_scene_path: String = "res://scenes/game/game.tscn"
var game_ui_scene_path: String = "res://ui/driving_ui.tscn"
var editor_scene_path: String = "res://scenes/track_editor/track_editor.tscn"
var editor_ui_scene_path: String = "res://scenes/track_editor/track_editor_ui.tscn"



func _on_button_play_pressed() -> void:
    Global.game_controller.change_ui_scene(game_ui_scene_path)
    Global.game_controller.change_3d_scene(game_scene_path)


func _on_button_editor_pressed() -> void:
    Global.game_controller.change_ui_scene(editor_ui_scene_path)
    Global.game_controller.change_3d_scene(editor_scene_path)
