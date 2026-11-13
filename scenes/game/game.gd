extends Node3D

const MAIN_MENU_SCENE_UID: String = ""
const MAIN_MENU_UI_SCENE_UID: String = "uid://c57vu5s1u5v7t"

@onready var track: Node3D = $Track
@onready var car: Car = $Car3

var storage_service: StorageService
var start_finish_line: StartFinishLine
var ui_scene: Control


func pass_args(args: Array) -> void:
    assert(args.size() == 1)
    assert(args.get(0) is int)
    _load_saved_track(args.get(0))


func connect_signals(ui_scene_: Control) -> void:
    assert(ui_scene_ != null)
    ui_scene = ui_scene_
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
    assert(ui_scene != null)
        
    var remove_roads: Array[Node] = track.get_children()
    
    var res: Array = storage_service.load_track(uid, track)
    if not res or res.size() != 5:
        print("Error loading saved track!")
        return
    
    for node in remove_roads:
        node.queue_free()
    
    #track_meta_data = res.get(0)
    start_finish_line = res.get(1)
    #roads_placed = res.get(2)
    #roads_placed_stack = res.get(3)
    #coords_blocked = res.get(4)
    
    if ui_scene.has_method("_on_lap_completed"):
        start_finish_line.lap_completed.connect(ui_scene._on_lap_completed)
