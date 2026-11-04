extends Node3D


@onready var track: Node3D = $Track
@onready var car: Car = $Car3

var storage_service: StorageService


func _ready() -> void:
    storage_service = StorageService.new()
    storage_service.load_track(track)


func connect_signals(ui_scene: Control) -> void:
    assert(ui_scene != null)
    if ui_scene.has_method("_on_car_current_car_gear"):
        car.current_car_gear.connect(ui_scene._on_car_current_car_gear)
    if ui_scene.has_method("_on_car_current_car_speed"):
        car.current_car_speed.connect(ui_scene._on_car_current_car_speed)
