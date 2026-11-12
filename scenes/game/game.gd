extends Node3D

var MAIN_MENU_SCENE_UID: String = ""
var MAIN_MENU_UI_SCENE_UID: String = "uid://c57vu5s1u5v7t"

@onready var track: Node3D = $Track
@onready var car: Car = $Car3

var storage_service: StorageService


func pass_args(args: Array) -> void:
    assert(args.size() == 1)
    assert(args.get(0) is int)
    _load_saved_track(args.get(0))


func connect_signals(ui_scene: Control) -> void:
    assert(ui_scene != null)
    if ui_scene.has_method("_on_car_current_car_gear"):
        car.current_car_gear.connect(ui_scene._on_car_current_car_gear)
    if ui_scene.has_method("_on_car_current_car_speed"):
        car.current_car_speed.connect(ui_scene._on_car_current_car_speed)
    if ui_scene.has_method("_on_car_wheel_angle"):
        car.current_car_wheel_angle.connect(ui_scene._on_car_wheel_angle)
    if ui_scene.has_method("_on_car_rpm"):
        car.current_car_rpm.connect(ui_scene._on_car_rpm)
    if ui_scene.has_method("_on_car_wheel_lateral"):
        car.current_car_wheel_lateral.connect(ui_scene._on_car_wheel_lateral)


func _ready() -> void:
    storage_service = StorageService.new()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        Global.game_controller.change_ui_scene(MAIN_MENU_UI_SCENE_UID)
        Global.game_controller.change_3d_scene(MAIN_MENU_SCENE_UID)


func _load_saved_track(uid: int) -> void:
    storage_service.load_track(uid, track)
