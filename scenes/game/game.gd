extends Node3D

var main_menu_ui_scene_path: String = "res://ui/main_menu.tscn"

@onready var track: Node3D = $Track
@onready var car: Car = $Car3

var storage_service: StorageService


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        Global.game_controller.change_ui_scene(main_menu_ui_scene_path)
        Global.game_controller.change_3d_scene("")


func _ready() -> void:
    storage_service = StorageService.new()
    storage_service.load_track(track)


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
