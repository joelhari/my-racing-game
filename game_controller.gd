class_name GameController
extends Node


@export var node_3d: Node3D
@export var node_ui: Control

var current_3d_scene: Node3D
var current_ui_scene: Control


func _ready() -> void:
    Global.game_controller = self
    current_ui_scene = $UI/MainMenu


func change_3d_scene(
    new_3d_scene_path: String,
    delete: bool = true,
    keep_running: bool = false
) -> void:
    if current_3d_scene != null:
        if delete:
            current_3d_scene.queue_free()
        elif keep_running:
            current_3d_scene.visible = false
        else:
            node_3d.remove_child(current_3d_scene)
    if not new_3d_scene_path:
        current_3d_scene = null
        node_ui.process_mode = Node.PROCESS_MODE_DISABLED
        return
    var new_3d_scene = load(new_3d_scene_path).instantiate()
    node_3d.add_child(new_3d_scene)
    current_3d_scene = new_3d_scene
    _connect_signals()


func change_ui_scene(
    new_ui_scene_path: String,
    delete: bool = true,
    keep_running: bool = false
) -> void:
    if current_ui_scene != null:
        if delete:
            current_ui_scene.queue_free()
        elif keep_running:
            current_ui_scene.visible = false
        else:
            node_ui.remove_child(current_ui_scene)
    if not new_ui_scene_path:
        current_ui_scene = null
        node_ui.process_mode = Node.PROCESS_MODE_DISABLED
        return
    var new_ui_scene = load(new_ui_scene_path).instantiate()
    node_ui.add_child(new_ui_scene)
    current_ui_scene = new_ui_scene
    _connect_signals()


func _connect_signals() -> void:
    if current_3d_scene == null or current_ui_scene == null:
        return
    if current_3d_scene.has_method("connect_signals"):
        current_3d_scene.connect_signals(current_ui_scene)
