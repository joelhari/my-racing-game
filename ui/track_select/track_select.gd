class_name TrackSelect
extends Control


@onready var item_list: ItemList = $VBoxContainer/ItemList
@onready var new_button: Button = $VBoxContainer/HBoxContainer/NewButton
@onready var load_button: Button = $VBoxContainer/HBoxContainer/LoadButton

var storage_service: StorageService
var selected_track: int
var tracks: Dictionary[int, String]
var next_scene: int = 0

const GAME_SCENE_UID: String = "uid://bjtvbf3odn1oi"
const GAME_UI_SCENE_UID: String = "uid://c7jp40jn36g3m"
const EDITOR_SCENE_UID: String = "uid://b3td1630p1env"
const EDITOR_UI_SCENE_UID: String = "uid://h8om2uebr1i5"

enum {GAME, EDITOR}


func pass_args(args: Array) -> void:
    assert(args.size() == 1)
    assert(args.get(0) is int)
    next_scene = args.get(0)
    new_button.visible = next_scene == EDITOR


func _ready() -> void:
    new_button.visible = next_scene == EDITOR
    load_button.disabled = true
    storage_service = StorageService.new()
    tracks = storage_service.load_track_list()
    for uid in tracks:
        item_list.add_item(tracks.get(uid))


func _on_item_list_item_selected(index: int) -> void:
    selected_track = tracks.keys().get(index)
    load_button.disabled = false


func _on_load_button_pressed() -> void:
    if not selected_track or selected_track < 0:
        load_button.disabled = true
        return
    if next_scene == GAME:
        Global.game_controller.change_ui_scene(GAME_UI_SCENE_UID)
        Global.game_controller.change_3d_scene(GAME_SCENE_UID, [selected_track])
    else:
        Global.game_controller.change_ui_scene(EDITOR_UI_SCENE_UID)
        Global.game_controller.change_3d_scene(EDITOR_SCENE_UID, [selected_track])


func _on_new_button_pressed() -> void:
    assert(next_scene == EDITOR)
    Global.game_controller.change_ui_scene(EDITOR_UI_SCENE_UID)
    Global.game_controller.change_3d_scene(EDITOR_SCENE_UID)
