extends Control


@onready var value_speed: Label = $GridContainer/ValueSpeed
@onready var value_gear: Label = $GridContainer/ValueGear


var gear_text_map: Dictionary[int, String] = {
    -1: 'R',
    0: 'N',
    1: '1',
    2: '2',
    3: '3',
    4: '4',
    5: '5',
}


func _on_car_current_car_speed(velocity: int) -> void:
    if not is_node_ready():
        return
    value_speed.text = str(velocity)


func _on_car_current_car_gear(gear: int) -> void:
    if not is_node_ready():
        return
    value_gear.text = gear_text_map.get(gear)
