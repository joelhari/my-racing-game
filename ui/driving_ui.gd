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

@onready var value_current_lap: Label = $GridContainer3/ValueCurrentLap
@onready var value_last_lap: Label = $GridContainer3/ValueLastLap
@onready var value_best_lap: Label = $GridContainer3/ValueBestLap

var current_lap_start_time: float = 0.0

const best_lap_color: Color = Color("#771db7")


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
    value_current_lap.text = _format_time(
        Time.get_unix_time_from_system() - current_lap_start_time)


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


func _on_lap_completed(
    now: float,
    lap_time: float = -1.0,
    new_best: bool = false
) -> void:
    current_lap_start_time = now
    if lap_time < 0:
        return
    
    var lap_time_str: String = _format_time(lap_time)
    value_last_lap.text = lap_time_str
    if new_best:
        value_best_lap.text = lap_time_str
        value_last_lap.add_theme_color_override("font_color", best_lap_color)
    else:
        value_last_lap.remove_theme_color_override("font_color")


func _format_time(time: float) -> String:
    var minutes = int(time / 60.0)
    var seconds = int(time) % 60
    var thousends = int((time - int(time)) * 1_000)
    return "%02d:%02d.%03d" % [minutes, seconds, thousends]
