extends Control


@onready var value_speed: Label = $GridContainer/ValueSpeed
@onready var value_gear: Label = $GridContainer/ValueGear
@onready var value_fps: Label = $GridContainer/ValueFPS


var gear_text_map: Dictionary[int, String] = {
    -1: 'R',
    0: 'N',
    1: '1',
    2: '2',
    3: '3',
    4: '4',
    5: '5',
}


func _process(_delta: float) -> void:
    value_fps.text = "%0.0f" % Engine.get_frames_per_second()


func _on_car_current_car_speed(velocity: int) -> void:
    if not is_node_ready():
        return
    value_speed.text = str(velocity)


func _on_car_current_car_gear(gear: int) -> void:
    if not is_node_ready():
        return
    value_gear.text = gear_text_map.get(gear)
