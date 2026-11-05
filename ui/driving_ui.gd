extends Control


@onready var value_speed: Label = $GridContainer/ValueSpeed
@onready var value_gear: Label = $GridContainer/ValueGear
@onready var value_fps: Label = $GridContainer/ValueFPS

@onready var value_wheel_angle: Label = $GridContainer2/ValueWheelAngle
@onready var value_rpm: Label = $GridContainer2/ValueRPM

@onready var value_wheel_lateral_fl: Label = $GridContainer2/ValueWheelLateralFL
@onready var value_wheel_lateral_fr: Label = $GridContainer2/ValueWheelLateralFR
@onready var value_wheel_lateral_rl: Label = $GridContainer2/ValueWheelLateralRL
@onready var value_wheel_lateral_rr: Label = $GridContainer2/ValueWheelLateralRR


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


func _on_car_current_car_speed(velocity: float) -> void:
    if not is_node_ready():
        return
    value_speed.text = "%0.2f" % velocity


func _on_car_current_car_gear(gear: int) -> void:
    if not is_node_ready():
        return
    value_gear.text = gear_text_map.get(gear, 'NaN')


func _on_car_wheel_angle(angle: float) -> void:
    if not is_node_ready():
        return
    value_wheel_angle.text = "%0.2f°" % angle


func _on_car_rpm(rpm: float) -> void:
    if not is_node_ready():
        return
    value_rpm.text = "%0.0f" % rpm


func _on_car_wheel_lateral(l1: float, l2: float, l3: float, l4: float) -> void:
    if not is_node_ready():
        return
    value_wheel_lateral_fl.text = "%+06.2f" % l1
    value_wheel_lateral_fr.text = "%+06.2f" % l2
    value_wheel_lateral_rl.text = "%+06.2f" % l3
    value_wheel_lateral_rr.text = "%+06.2f" % l4
