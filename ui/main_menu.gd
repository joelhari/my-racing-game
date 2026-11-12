extends Control


var TRACK_SELECT_SCENE_UID: String = ""
var TRACK_SELECT_UI_SCENE_UID: String = "uid://b7lqttvs285ar"


func _on_button_play_pressed() -> void:
    Global.game_controller.change_ui_scene(TRACK_SELECT_UI_SCENE_UID, [TrackSelect.GAME])
    Global.game_controller.change_3d_scene(TRACK_SELECT_SCENE_UID)


func _on_button_editor_pressed() -> void:
    Global.game_controller.change_ui_scene(TRACK_SELECT_UI_SCENE_UID, [TrackSelect.EDITOR])
    Global.game_controller.change_3d_scene(TRACK_SELECT_SCENE_UID)
